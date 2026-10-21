proc psdpdc_av_pat_gen_clkx5_wiz_index {ip src_pin} {
	# Return the clkx5_wiz output index that drives $src_pin, or -1 if it
	# cannot be determined. Mirrors the index resolution used by axi_mmi_dc.
	set clkout_list [split [hsi get_property CONFIG.CLKOUT_PORT $ip] ","]
	set idx [lsearch -exact $clkout_list $src_pin]
	if {$idx < 0} {
		# Handle MBUFGCE fanout ports named "<clk>_o<N>" (N=1-4).
		if {[string match "*_o\[1-4\]" $src_pin]} {
			set cleaned [string range $src_pin 0 end-3]
			set idx_list [lsearch -all $clkout_list $cleaned]
			set drives_list [split [hsi get_property CONFIG.CLKOUT_DRIVES $ip] ","]
			foreach i $idx_list {
				if {[lindex $drives_list $i] eq "MBUFGCE"} {
					set idx $i
				}
			}
		}
	}
	return $idx
}

proc psdpdc_av_pat_gen_get_clkx5_wiz {pin_name} {
	# Trace a ps_wizard clock input pin (e.g. pl_mmi_dc_2x_clk / pl_mmi_dc_1x_clk)
	# through to the driving clkx5_wiz and return "clkx5_wiz_cell index". The
	# clkx5_wiz (e.g. mmi_vid_clk_wiz) is the real clock provider; ps_wizard
	# itself is only a wrapper and has no #clock-cells, so it must never be used
	# as a clock reference. Returns "" if the clkx5_wiz cannot be resolved.
	set ps_wiz_cells {}
	foreach cell_name {ps_wizard_0 ps_wizard_0_mmi_0} {
		set cell [hsi::get_cells -hier $cell_name -quiet]
		if {$cell ne ""} {
			lappend ps_wiz_cells $cell
		}
	}
	set src_pin ""
	foreach cell $ps_wiz_cells {
		set candidate_pin [hsi::get_pins $pin_name -of_objects $cell -quiet]
		if {$candidate_pin eq ""} {
			continue
		}
		set candidate_src [get_source_pins [hsi::get_pins -of_objects $cell $candidate_pin]]
		if {[llength $candidate_src] == 0} {
			continue
		}
		set src_pin $candidate_src
		break
	}
	if {[llength $src_pin] == 0} {
		return ""
	}
	set pinobj [hsi::get_pins $src_pin]
	if {$pinobj eq ""} {
		return ""
	}
	set ip [hsi::get_cells -of_objects $pinobj -quiet]
	if {$ip eq "" || [hsi get_property IP_NAME $ip] != "clkx5_wiz"} {
		return ""
	}
	set idx [psdpdc_av_pat_gen_clkx5_wiz_index $ip $src_pin]
	if {$idx < 0} {
		return ""
	}
	return "$ip $idx"
}

proc psdpdc_av_pat_gen_emit_mmi_dc_overlay {port_idx in_label out_label} {
	# Contribute one av_pat_gen <-> mmi_dc link to pl_overlay.dtso using the SDT
	# overlay DT support (create_node/add_prop with -d pl_overlay.dtso), the same
	# way pcw/pl nodes are built. av_pat_gen is the only writer of these
	# port/endpoint nodes and each port index is emitted once, so the per-index
	# nodes are simply created; the shared &mmi_dc fragment and its "ports"
	# container are found-or-created by create_node.
	#
	# The av_pat_gen output endpoint itself is defined in the base pl.dtsi
	# (labelled but with no remote-endpoint); its remote-endpoint is supplied
	# here through a &avpg_out_N fixup fragment, so the base never references a
	# label it does not define (which dtc rejects). All &<label> targets resolve
	# as overlay fixups on apply, while the dc_live_in label is defined here.
	set ovl "pl_overlay.dtso"

	set mmi_frag [create_node -n "&mmi_dc" -p root -d $ovl]
	set ports_node [create_node -n "ports" -p $mmi_frag -d $ovl]
	set port_node [create_node -n "port" -u $port_idx -p $ports_node -d $ovl]
	set ep_node [create_node -n "endpoint" -l $in_label -p $port_node -d $ovl]
	add_prop $ep_node "remote-endpoint" $out_label reference $ovl

	set fixup_node [create_node -n "&$out_label" -p root -d $ovl]
	add_prop $fixup_node "remote-endpoint" $in_label reference $ovl
}

proc psdpdc_av_pat_gen_find_bridge_vtc {avpg_ip} {
	# Resolve the v_tc that bridges this av_pat_gen by the hierarchy-prefix name
	# match (<prefix>_av_pat_gen_N -> <prefix>_v_tc_*), or "" when none is found.
	set avpg_name [hsi get_property NAME $avpg_ip]
	set avpg_prefix ""
	if {[regexp {^(.*)_av_pat_gen_} $avpg_name -> avpg_prefix]} {
		foreach vtc [hsi get_cells -hier -filter {IP_NAME == "v_tc"}] {
			if {[string match "${avpg_prefix}_v_tc_*" [hsi get_property NAME $vtc]]} {
				return $vtc
			}
		}
	}
	return ""
}

proc psdpdc_av_pat_gen_generate {drv_handle} {
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

	set dts_file [set_drv_def_dts $drv_handle]
	add_prop "$node" "xlnx,video-format" 0 int $dts_file

	set avpg_ip [hsi::get_cells -hier $drv_handle]

	# Connect the vid_out_axi4s clock to the clkx5_wiz that actually drives it.
	set vid_out_clk_ref ""
	set vid_out_clk_pin [hsi::get_pins -of_objects $avpg_ip "vid_out_axi4s_aclk"]
	if {![llength $vid_out_clk_pin]} {
		set clk_in_pins [hsi::get_pins -of_objects $avpg_ip -filter {TYPE==clk && DIRECTION==I}]
		foreach p $clk_in_pins {
			set p_name [hsi get_property NAME $p]
			if {[string match "*vid_out_axi4s_aclk" $p_name]} {
				set vid_out_clk_pin $p
				break
			}
		}
	}
	if {[llength $vid_out_clk_pin]} {
		# The video-out clock must reference the clkx5_wiz clock provider
		# (e.g. mmi_vid_clk_wiz), not the ps_wizard wrapper the clock is routed
		# through (ps_wizard has no #clock-cells and is not a valid clock ref).
		# Functional mode locks vid_out to the 2x video clock, bypass mode to
		# the 1x video clock.
		set mmi_dc_cell [hsi::get_cells -hier -filter IP_NAME==mmi_dc -quiet]
		set operating_mode ""
		if {[llength $mmi_dc_cell]} {
			set operating_mode [hsi get_property CONFIG.C_DPDC_OPERATING_MODE $mmi_dc_cell]
		}
		if {[string equal $operating_mode "DC_Bypass"]} {
			set vid_clk_pin_name "pl_mmi_dc_1x_clk"
		} else {
			set vid_clk_pin_name "pl_mmi_dc_2x_clk"
		}
		set vid_out_clk_ref [psdpdc_av_pat_gen_get_clkx5_wiz $vid_clk_pin_name]

		# Fall back to the direct driver only if the clkx5_wiz trace failed and
		# that driver is itself a real clocking wizard (never emit ps_wizard).
		if {[string equal $vid_out_clk_ref ""]} {
			set vid_out_src_pins [get_source_pins $vid_out_clk_pin]
			foreach src_pin $vid_out_src_pins {
				set src_clk_ip [hsi::get_cells -of_objects $src_pin]
				if {![llength $src_clk_ip]} {
					continue
				}
				if {![string match "*clk*wiz*" [hsi get_property IP_NAME $src_clk_ip]]} {
					continue
				}
				set src_idx [psdpdc_av_pat_gen_clkx5_wiz_index $src_clk_ip $src_pin]
				if {$src_idx < 0} {
					set src_idx 0
				}
				set vid_out_clk_ref "$src_clk_ip $src_idx"
				break
			}
		}
	}
	if {![string equal $vid_out_clk_ref ""]} {
		set curr_clk_names [pldt get $node "clock-names"]
		set curr_clocks_raw [pldt get $node "clocks"]

		# Parse the serialized "clocks" value into complete "<...>" specifiers.
		# A single clock may be multi-cell (e.g. "<&clk 0>"), so the value must
		# not be split on whitespace: extract each angle-bracketed group so a
		# phandle and its argument cells stay together as one entry and stay
		# aligned with the one-per-clock "clock-names" list.
		set curr_clocks [regexp -all -inline {<[^>]*>} $curr_clocks_raw]

		set vid_out_clk_idx -1
		set clock_slot_idx 0
		foreach clk_name $curr_clk_names {
			set norm_clk_name [string trim $clk_name " \t\n\r\","]
			if {[string equal $norm_clk_name ""]} {
				continue
			}
			if {[string equal $norm_clk_name "vid_out_axi4s_aclk"]} {
				set vid_out_clk_idx $clock_slot_idx
				break
			}
			incr clock_slot_idx
		}
		set clocks_len [llength $curr_clocks]
		if {$vid_out_clk_idx >= 0 && $vid_out_clk_idx < $clocks_len} {
			# Replace only the vid_out specifier with the clkx5_wiz reference and
			# re-serialize; every other specifier (including multi-cell ones) is
			# preserved verbatim.
			set new_clocks [lreplace $curr_clocks $vid_out_clk_idx $vid_out_clk_idx "<&$vid_out_clk_ref>"]
			add_prop "$node" "clocks" "[join $new_clocks ", "]" noformating $dts_file 1
		}
	}

	# xlnx,bridge: the v_tc that bridges this av_pat_gen's live path.
	set vtc_bridge_ip [psdpdc_av_pat_gen_find_bridge_vtc $avpg_ip]
	if {![string equal $vtc_bridge_ip ""]} {
		add_prop "$node" "xlnx,bridge" "$vtc_bridge_ip" reference $dts_file
	}

	set mmi_dc_cell [hsi::get_cells -hier -filter {IP_NAME == "mmi_dc"} -quiet]
	if {![llength $mmi_dc_cell]} {
		return
	}

	global avpg_mmi_dc_plugin_ports
	if {![info exists avpg_mmi_dc_plugin_ports]} {
		set avpg_mmi_dc_plugin_ports [dict create]
	}
	set mmi_dc_port_idx [dict size $avpg_mmi_dc_plugin_ports]
	set avpg_out_label avpg_out_$mmi_dc_port_idx
	set mmi_dc_in_label dc_live_in_$mmi_dc_port_idx

	# The av_pat_gen output endpoint lives in the base (pl.dtsi) as a labelled but
	# otherwise empty endpoint. Its remote-endpoint is deliberately NOT set here:
	# a base tree must not reference a label defined only in the overlay. The
	# overlay (pl_overlay.dtso) supplies the mmi_dc input endpoint and this
	# endpoint's remote-endpoint via the &avpg_out_N label, where both resolve as
	# fixups when the overlay is applied.
	#
	# av_pat_gen has a single output port, so use the of-graph single-port form.
	set avpg_port [create_node -n "port" -l avpg_port_$mmi_dc_port_idx -u 0 -p $node -d $dts_file]
	create_node -n "endpoint" -l $avpg_out_label -p $avpg_port -d $dts_file

	dict set avpg_mmi_dc_plugin_ports $mmi_dc_port_idx [list $mmi_dc_in_label $avpg_out_label]

	# Contribute this av_pat_gen's connection to the pl_overlay.dtso overlay
	# (written by the SDT framework's overlay DT support).
	psdpdc_av_pat_gen_emit_mmi_dc_overlay $mmi_dc_port_idx $mmi_dc_in_label $avpg_out_label
}
