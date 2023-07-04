proc dfeprach_generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set count 0
	foreach handle [hsi::get_cells -hier] {
		set ip_name [hsi get_property IP_NAME $handle]
		if {[string match -nocase $ip_name "xdfe_cc_mixer"] } {
			set count [expr $count + 1]
		}
	}
	add_prop $node "num-insts" $count hexlist $dts_file
	set start "{ 0x"
	set delim ",0x"
	set term " }"

	set val0 [format %x [hsi get_property "CONFIG.C_NUM_ANTENNA0" $drv_handle]]
	set val1 [format %x [hsi get_property "CONFIG.C_NUM_ANTENNA1" $drv_handle]]
	set val2 [format %x [hsi get_property "CONFIG.C_NUM_ANTENNA1" $drv_handle]]
	set val $start$val0$delim$val1$delim$val2$term
	add_prop $node "xlnx,num-antenna" $val string $dts_file

	set val0 [format %x [hsi get_property "CONFIG.C_NUM_CC_PER_ANTENNA0" $drv_handle]]
	set val1 [format %x [hsi get_property "CONFIG.C_NUM_CC_PER_ANTENNA1" $drv_handle]]
	set val2 [format %x [hsi get_property "CONFIG.C_NUM_CC_PER_ANTENNA1" $drv_handle]]
	set val $start$val0$delim$val1$delim$val2$term
	add_prop $node "xlnx,num-cc-per-antenna" $val string $dts_file

	set val0 [format %x [hsi get_property "CONFIG.C_NUM_SLOT_CHANNELS0" $drv_handle]]
	set val1 [format %x [hsi get_property "CONFIG.C_NUM_SLOT_CHANNELS1" $drv_handle]]
	set val2 [format %x [hsi get_property "CONFIG.C_NUM_SLOT_CHANNELS1" $drv_handle]]
	set val $start$val0$delim$val1$delim$val2$term
	add_prop $node "xlnx,num-slot-channels" $val string $dts_file

	set val0 [format %x [hsi get_property "CONFIG.C_NUM_SLOTS0" $drv_handle]]
	set val1 [format %x [hsi get_property "CONFIG.C_NUM_SLOTS1" $drv_handle]]
	set val2 [format %x [hsi get_property "CONFIG.C_NUM_SLOTS1" $drv_handle]]
	set val $start$val0$delim$val1$delim$val2$term
	add_prop $node "xlnx,num-slots" $val string $dts_file
}
