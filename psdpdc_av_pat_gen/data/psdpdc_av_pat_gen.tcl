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
