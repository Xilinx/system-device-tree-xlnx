#
# (C) Copyright 2018-2021 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

proc generate_aie_array_device_info {node drv_handle bus_node} {
	set aie_array_id 0
	set compatible [get_comp_str $drv_handle]
	set keyval [pldt append $node compatible "\ \, \"xlnx,ai_engine-v2.0\""]
	
	append shimrows "/bits/ 8 <0 1>"
	add_prop "${node}" "xlnx,shim-rows" $shimrows noformating "pl.dtsi"
	append corerows "/bits/ 8 <1 8>"
	add_prop "${node}" "xlnx,core-rows" $corerows noformating "pl.dtsi"
	set power_domain "&versal_firmware 0x18224072"
	add_prop "${node}" "power-domains" $power_domain intlist "pl.dtsi"
	add_prop "${node}" "#address-cells" "2" intlist "pl.dtsi"
	add_prop "${node}" "#size-cells" "2" intlist "pl.dtsi"
	add_prop "${node}" "ranges" "" boolean "pl.dtsi"

	set ai_clk_node [create_node -n "aie_core_ref_clk_0" -l "aie_core_ref_clk_0" -p ${bus_node}]
	set clk_freq [hsi get_property CONFIG.AIE_CORE_REF_CTRL_FREQMHZ [hsi get_cells -hier $drv_handle]]
	set clk_freq [expr ${clk_freq} * 1000000]
	add_prop "${ai_clk_node}" "compatible" "fixed-clock" stringlist "pl.dtsi"
	add_prop "${ai_clk_node}" "#clock-cells" 0 int "pl.dtsi"
	add_prop "${ai_clk_node}" "clock-frequency" $clk_freq int "pl.dtsi"

	set clocks "aie_core_ref_clk_0"
	set_drv_prop $drv_handle clocks "$clocks" reference
	add_prop "${node}" "clock-names" "aclk0" stringlist "pl.dtsi"

	return ${node}
}


proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set dt_overlay [hsi get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set RpRm [get_rp_rm_for_drv $drv_handle]
		regsub -all { } $RpRm "" RpRm
		if {[llength $RpRm]} {
			set bus_node "overlay2_$RpRm"
		} else  {
			set bus_node "overlay2"
		}
	} else {
		set bus_node "amba_pl"
	}
	generate_aie_array_device_info ${node} ${drv_handle} ${bus_node}
	set ip [hsi get_cells -hier $drv_handle]
	set unit_addr [get_baseaddr ${ip} no_prefix]
	set aperture_id 0
	set aperture_node [create_node -n "aie_aperture" -u "${unit_addr}" -l "aie_aperture_${aperture_id}" -p ${node} -d "pl.dtsi"]
	set reg [hsi get_property CONFIG.reg ${drv_handle}]
	add_prop "${aperture_node}" "reg" $reg noformat "pl.dtsi"

	set intr_names "interrupt1"
	set intr_num "<0x0 0x94 0x1>, <0x0 0x95 0x1>, <0x0 0x96 0x1>"
	set power_domain "&versal_firmware 0x18224072"
	add_prop "${aperture_node}" "interrupt-names" $intr_names stringlist "pl.dtsi"
	add_prop "${aperture_node}" "interrupts" $intr_num intlist "pl.dtsi"
	add_prop "${aperture_node}" "interrupt-parent" gic reference "pl.dtsi"
	add_prop "${aperture_node}" "power-domains" $power_domain intlist "pl.dtsi"
	add_prop "${aperture_node}" "#address-cells" "2" intlist "pl.dtsi"
	add_prop "${aperture_node}" "#size-cells" "2" intlist "pl.dtsi"

	set aperture_nodeid 0x18800000
	add_prop "${aperture_node}" "xlnx,columns" "0 50" intlist "pl.dtsi"
	add_prop "${aperture_node}" "xlnx,node-id" "${aperture_nodeid}" intlist "pl.dtsi"

}
