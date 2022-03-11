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
	set clocks "aie_core_ref_clk_0"
	set_drv_prop $drv_handle clocks "$clocks" reference
	set keyval [pldt append $node compatible "\ \, \"xlnx,ai_engine-v1.0\""]	
	set intr_names "interrupt1"
	set intr_num "<0x0 0x94 0x1>, <0x0 0x95 0x1>, <0x0 0x96 0x1>"
	set power_domain "&versal_firmware 0x18224072"
	add_prop $node "interrupt-names" $intr_names stringlist "pl.dtsi"
	set keyval [pldt append $node "interrupt-names" "\ \, \"interrupt2\""]  
	set keyval [pldt append $node "interrupt-names" "\ \, \"interrupt3\""]
	add_prop $node "interrupts" $intr_num intlist "pl.dtsi"
	add_prop $node "power-domains" $power_domain hexlist "pl.dtsi"
	add_prop $node "#address-cells" 2 intlist "pl.dtsi"
	add_prop $node "#size-cells" 2 intlist "pl.dtsi"
	# Add one AI engine partition child node
       	set ai_part_id 0
	set ai_part_nid 1
	set ai_part_node [create_node -n "aie_partition" -u "${ai_part_id}" -l "aie_partition${ai_part_id}" -p ${node} -d "pl.dtsi"]
	add_prop "${ai_part_node}" "reg" "0 0 50 9" intlist "pl.dtsi"
	add_prop "${ai_part_node}" "xlnx,partition-id" "${ai_part_nid}" intlist "pl.dtsi"
	set ai_clk_node [add_or_get_dt_node -n "aie_core_ref_clk_0" -l "aie_core_ref_clk_0" -p ${bus_node}]
	set clk_freq [hsi get_property CONFIG.AIE_CORE_REF_CTRL_FREQMHZ [hsi get_cells -hier $drv_handle]]
	add_prop "${ai_clk_node}" "compatible" "fixed-clock" stringlist "pl.dtsi"
	add_prop "${ai_clk_node}" "#clock-cells" 0 int "pl.dtsi"
	add_prop "${ai_clk_node}" "clock-frequency" $clk_freq int "pl.dtsi"
}
