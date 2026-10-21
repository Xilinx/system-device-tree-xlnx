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

proc psdpdc_av_pat_gen_get_tpg_en_gpio {avpg_ip} {
	# Return the axi_gpio cell that drives the av_pat_gen TPG_GEN_EN enable pin,
	# or "" if none is connected. The gpio gates pattern generation on the live
	# path and is referenced through clk-enable-gpios.
	set en_pin [hsi::get_pins -of_objects $avpg_ip "TPG_GEN_EN" -quiet]
	if {![llength $en_pin]} {
		set avpg_in_pins [hsi::get_pins -of_objects $avpg_ip -filter {DIRECTION==I} -quiet]
		foreach p $avpg_in_pins {
			if {[string match "*TPG_GEN_EN" [hsi get_property NAME $p]]} {
				set en_pin $p
				break
			}
		}
	}
	if {![llength $en_pin]} {
		return ""
	}
	foreach en_src [get_source_pins $en_pin] {
		set en_src_ip [hsi::get_cells -of_objects $en_src -quiet]
		if {![llength $en_src_ip]} {
			continue
		}
		if {[hsi get_property IP_NAME $en_src_ip] eq "axi_gpio"} {
			return $en_src_ip
		}
	}
	return ""
}

proc psdpdc_av_pat_gen_intf_other_ends {intf_pin} {
	# Return the interface pins on the far side of $intf_pin's interface net(s).
	# This is the primitive used to walk the block-design interface connectivity
	# (the same connections captured by the design .tcl connect_bd_intf_net calls)
	# on the flattened hsi netlist.
	set others {}
	foreach n [hsi::get_intf_nets -of_objects $intf_pin -quiet] {
		foreach p [hsi::get_intf_pins -of_objects $n -quiet] {
			if {![string equal "$p" "$intf_pin"]} {
				lappend others $p
			}
		}
	}
	return $others
}

proc psdpdc_av_pat_gen_vid_out_sink {avpg_ip} {
	# Follow the av_pat_gen video-stream master (vid_out_axi4s) one hop and return
	# "<sink_intf_pin> <sink_cell> <sink_ip_name>" for what it drives, or "".
	#  - native designs: the sink is a v_axi4s_vid_out (video_in).
	#  - axistream designs: the sink is the ps_wizard live input (vpN_axi_video).
	set vout [hsi::get_intf_pins -of_objects [hsi::get_cells $avpg_ip] "*vid_out_axi4s" -quiet]
	if {![llength $vout]} {
		return ""
	}
	foreach oe [psdpdc_av_pat_gen_intf_other_ends [lindex $vout 0]] {
		set cell [hsi::get_cells -of_objects $oe -quiet]
		if {[llength $cell]} {
			return [list $oe $cell [hsi get_property IP_NAME $cell]]
		}
	}
	return ""
}

proc psdpdc_av_pat_gen_pswiz_port_index {pin_name} {
	# Map a ps_wizard live-input interface pin name to the mmi_dc port index (its
	# numeric suffix). Covers the axistream (vpN_axi_video), native-live
	# (live_videoN) and native-bypass (video_sN) namings. live_video* and
	# video_s* never coexist, so the single numeric space is unambiguous.
	foreach re {{vp(\d+)_axi_video} {live_video(\d+)} {video_s(\d+)}} {
		if {[regexp $re $pin_name -> idx]} {
			return $idx
		}
	}
	return -1
}

proc psdpdc_av_pat_gen_resolve_port_index {avpg_ip} {
	# Resolve, by connectivity, the mmi_dc input port index this av_pat_gen feeds:
	#  - native:    vid_out_axi4s -> v_axi4s_vid_out -> vid_io_out ->
	#               ps_wizard live_videoN / video_sN          => N
	#  - axistream: vid_out_axi4s -> ps_wizard vpN_axi_video   => N
	# Falls back to the "vpN" token in the av_pat_gen name, then -1.
	set sink [psdpdc_av_pat_gen_vid_out_sink $avpg_ip]
	if {[llength $sink]} {
		set sink_pin [lindex $sink 0]
		set sink_cell [lindex $sink 1]
		set sink_ip [lindex $sink 2]
		if {[string equal $sink_ip "v_axi4s_vid_out"]} {
			set vio [hsi::get_intf_pins -of_objects [hsi::get_cells $sink_cell] "*vid_io_out" -quiet]
			if {[llength $vio]} {
				foreach oe [psdpdc_av_pat_gen_intf_other_ends [lindex $vio 0]] {
					set idx [psdpdc_av_pat_gen_pswiz_port_index [hsi get_property NAME $oe]]
					if {$idx >= 0} {
						return $idx
					}
				}
			}
		} else {
			set idx [psdpdc_av_pat_gen_pswiz_port_index [hsi get_property NAME $sink_pin]]
			if {$idx >= 0} {
				return $idx
			}
		}
	}
	set avpg_name [hsi get_property NAME $avpg_ip]
	if {[regexp {vp(\d+)} $avpg_name -> idx]} {
		return $idx
	}
	return -1
}

proc psdpdc_av_pat_gen_find_bridge_vtc {avpg_ip} {
	# Resolve the v_tc that bridges this av_pat_gen by DESIGN CONNECTIVITY (the
	# block-design connections in the design .tcl), or "" when none drives it.
	# Two topologies are supported:
	#  - native (functional_live / mixed / bypass .tcl): the av_pat_gen video
	#    stream (vid_out_axi4s) and the v_tc timing (vtiming_out) meet at the same
	#    v_axi4s_vid_out (video_in / vtiming_in). The bridge is the v_tc on that
	#    cell's vtiming_in.
	#  - axistream: the av_pat_gen streams straight into ps_wizard/vpN_axi_video
	#    (mmi_dc input port N) and the v_tc timing goes to ps_wizard/sN_timing_in.
	#    The bridge is the v_tc at the SAME index N. An av_pat_gen that reuses the
	#    first v_tc's timing has no v_tc at its index, so it correctly gets none.
	# Falls back to the hierarchy-prefix name match if connectivity is unavailable.
	set sink [psdpdc_av_pat_gen_vid_out_sink $avpg_ip]
	if {[llength $sink]} {
		set sink_cell [lindex $sink 1]
		set sink_ip [lindex $sink 2]
		if {[string equal $sink_ip "v_axi4s_vid_out"]} {
			set vtin [hsi::get_intf_pins -of_objects [hsi::get_cells $sink_cell] "*vtiming_in" -quiet]
			if {[llength $vtin]} {
				foreach oe [psdpdc_av_pat_gen_intf_other_ends [lindex $vtin 0]] {
					set src_cell [hsi::get_cells -of_objects $oe -quiet]
					if {[llength $src_cell] && [string equal [hsi get_property IP_NAME $src_cell] "v_tc"]} {
						return $src_cell
					}
				}
			}
			return ""
		} else {
			set port_idx [psdpdc_av_pat_gen_resolve_port_index $avpg_ip]
			if {$port_idx >= 0} {
				foreach vtc [hsi get_cells -hier -filter {IP_NAME == "v_tc"}] {
					set vtout [hsi::get_intf_pins -of_objects [hsi::get_cells $vtc] "*vtiming_out" -quiet]
					if {![llength $vtout]} {
						continue
					}
					foreach oe [psdpdc_av_pat_gen_intf_other_ends [lindex $vtout 0]] {
						if {[regexp {s(\d+)_timing_in} [hsi get_property NAME $oe] -> tidx] && $tidx == $port_idx} {
							return $vtc
						}
					}
				}
			}
			return ""
		}
	}
	# Fallback: hierarchy-prefix name match (<prefix>_av_pat_gen_N -> <prefix>_v_tc_*).
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

proc psdpdc_av_pat_gen_reset_state {} {
	# The generator accumulates per-design state in globals: the mmi_dc input
	# port assignments and the bridge v_tc mappings. Reset that state when a new
	# design is processed so a later design does not inherit stale port and v_tc
	# mappings. The guard on cur_hw_design keeps the state across the multiple
	# av_pat_gen instances of a single design while still clearing it for the
	# next design.
	global cur_hw_design
	global avpg_state_design
	global avpg_mmi_dc_plugin_ports
	global avpg_bridge_vtc_dict
	if {![info exists avpg_state_design] || ![string equal $avpg_state_design $cur_hw_design]} {
		set avpg_state_design $cur_hw_design
		set avpg_mmi_dc_plugin_ports [dict create]
		set avpg_bridge_vtc_dict [dict create]
	}
}

proc psdpdc_av_pat_gen_generate {drv_handle} {
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

	# Reset per-design state before touching the accumulation globals so stale
	# mappings are not inherited across designs.
	psdpdc_av_pat_gen_reset_state

	set dts_file [set_drv_def_dts $drv_handle]
	add_prop "$node" "xlnx,video-format" 0 int $dts_file

	set avpg_ip [hsi::get_cells -hier $drv_handle]
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

	# Resolve the v_tc that bridges this av_pat_gen (or "" when the instance
	# has no bridge, e.g. a bypass-stream av_pat_gen). This must not gate the
	# rest of the generation: every av_pat_gen still contributes its mmi_dc
	# endpoint below, whether or not it has a bridge.
	set vtc_bridge_ip [psdpdc_av_pat_gen_find_bridge_vtc $avpg_ip]

	if {![string equal $vtc_bridge_ip ""]} {
		add_prop "$node" "xlnx,bridge" "$vtc_bridge_ip" reference $dts_file

		# The bridged (live-path) av_pat_gen has its pattern generation gated by
		# an axi_gpio driving the TPG_GEN_EN pin. Emit clk-enable-gpios pointing
		# at that gpio so the driver can gate the stream. The bypass-stream
		# instance (no v_tc bridge) is not gated and must not get this property.
		set gpio_cell [psdpdc_av_pat_gen_get_tpg_en_gpio $avpg_ip]
		if {![string equal $gpio_cell ""]} {
			set gpio_label [get_label $gpio_cell]
			if {![string equal $gpio_label ""]} {
				set clk_en_val "$gpio_label 0x0 0x0 $gpio_label 0x10 0x0"
				add_prop "$node" "clk-enable-gpios" $clk_en_val special $dts_file
			}
		}

		# Record the bridge v_tc so it can be enabled (and have its unused
		# arbitrary-res-en dropped) after vtc_generate has run. This is done in
		# psdpdc_av_pat_gen_update_endpoints, which the generator framework calls
		# once every IP node already exists.
		global avpg_bridge_vtc_dict
		dict set avpg_bridge_vtc_dict $drv_handle $vtc_bridge_ip
	}

	set mmi_dc_cell [hsi::get_cells -hier -filter {IP_NAME == "mmi_dc"} -quiet]
	if {![llength $mmi_dc_cell]} {
		return
	}

	global avpg_mmi_dc_plugin_ports

	# Resolve the mmi_dc input port index for this av_pat_gen instance by
	# connectivity (its video stream -> ps_wizard live input).
	set mmi_dc_port_idx [psdpdc_av_pat_gen_resolve_port_index $avpg_ip]

	# A resolved index that is already taken would duplicate the avpg_out_N /
	# dc_live_in_N labels and overwrite the recorded port, so reject it and fall
	# back to a free index instead.
	if {$mmi_dc_port_idx >= 0 && [dict exists $avpg_mmi_dc_plugin_ports $mmi_dc_port_idx]} {
		dtg_warning "psdpdc_av_pat_gen: mmi_dc port index $mmi_dc_port_idx already in use; allocating next free index for $avpg_ip"
		set mmi_dc_port_idx -1
	}

	# Fall back to the lowest unused index. dict size is not necessarily free
	# when the resolved indices are sparse, so scan for the first gap.
	if {$mmi_dc_port_idx < 0} {
		set mmi_dc_port_idx 0
		while {[dict exists $avpg_mmi_dc_plugin_ports $mmi_dc_port_idx]} {
			incr mmi_dc_port_idx
		}
	}
	set avpg_out_label avpg_out_$mmi_dc_port_idx
	set mmi_dc_in_label dc_live_in_$mmi_dc_port_idx

	# The av_pat_gen output endpoint node lives in the base (pl.dtsi) as a
	# labelled but otherwise empty endpoint. Its remote-endpoint is deliberately
	# NOT set here: a base tree must not reference a label defined only in the
	# overlay. The overlay (pl_overlay.dtso) supplies the mmi_dc input
	# endpoint and this endpoint's remote-endpoint via the &avpg_out_N label,
	# where both resolve as fixups when the overlay is applied.
	#
	# av_pat_gen has a single output port, so use the of-graph single-port form
	# (a lone "port@0" node, no "ports" wrapper / #address-cells / #size-cells /
	# reg) per the Linux graph binding.
	set avpg_port [create_node -n "port" -l avpg_port_$mmi_dc_port_idx -u 0 -p $node -d $dts_file]
	create_node -n "endpoint" -l $avpg_out_label -p $avpg_port -d $dts_file

	dict set avpg_mmi_dc_plugin_ports $mmi_dc_port_idx [list $mmi_dc_in_label $avpg_out_label]

	# Contribute this av_pat_gen's connection to the pl_overlay.dtso overlay
	# (written by the SDT framework's overlay DT support).
	psdpdc_av_pat_gen_emit_mmi_dc_overlay $mmi_dc_port_idx $mmi_dc_in_label $avpg_out_label
}

proc psdpdc_av_pat_gen_update_endpoints {drv_handle} {
	# Runs after every IP node has been generated (post vtc_generate), so the
	# bridge v_tc node already carries the xlnx,arbitrary-res-en property. The
	# v_tc is already status="okay" by default, so only drop arbitrary-res-en,
	# which does not apply to the generator v_tc that bridges this av_pat_gen's
	# live path.
	global avpg_bridge_vtc_dict
	if {![info exists avpg_bridge_vtc_dict]} {
		return
	}
	if {![dict exists $avpg_bridge_vtc_dict $drv_handle]} {
		return
	}
	set vtc_bridge_ip [dict get $avpg_bridge_vtc_dict $drv_handle]
	if {[string equal $vtc_bridge_ip ""]} {
		return
	}
	set vtc_node [get_node $vtc_bridge_ip]
	if {[string_is_empty $vtc_node]} {
		return
	}
	set vtc_dts [set_drv_def_dts $vtc_bridge_ip]
	catch {pldt unset $vtc_node "xlnx,arbitrary-res-en"}
}
