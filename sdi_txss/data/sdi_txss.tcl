#
# (C) Copyright 2020-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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
proc sdi_txss_generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	sdi_tx_add_hier_instances $drv_handle

	set line_rate [hsi get_property CONFIG.C_LINE_RATE [hsi get_cells -hier $drv_handle]]
	switch $line_rate {
		"3G_SDI" {
			add_prop "${node}" "xlnx,line-rate" 0 int $dts_file 1
		}
		"6G_SDI" {
			add_prop "${node}" "xlnx,line-rate" 1 int $dts_file 1
		}
		"12G_SDI_8DS" {
			add_prop "${node}" "xlnx,line-rate" 2 int $dts_file 1
		}
		"12G_SDI_16DS" {
			add_prop "${node}" "xlnx,line-rate" 3 int $dts_file 1
		}
		default {
			add_prop "${node}" "xlnx,line-rate" 4 int $dts_file 1
		}
	}
	set Isstd_352 [hsi get_property CONFIG.C_TX_INSERT_C_STR_ST352 [hsi get_cells -hier $drv_handle]]
	if {$Isstd_352 == "flase"} {
		add_prop "${node}" "xlnx,Isstd_352" 0 int $dts_file 1
	} else {
		add_prop "${node}" "xlnx,Isstd_352" 1 int $dts_file 1
	}
}

proc sdi_tx_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	hsi::current_hw_instance $drv_handle

	set ip_subcores [dict create]
	#dict set ip_subcores "v_smpte_uhdsdi_tx" "sditx"
	dict set ip_subcores "v_tc" "sdivtc"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [hsi::get_cells -filter "IP_NAME==$ip"]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}
	hsi::current_hw_instance

}
