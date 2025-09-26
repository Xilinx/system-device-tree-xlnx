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
proc dp_rxss12_generate {drv_handle} {
	set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
	dp_rx_12_add_hier_instances $drv_handle
	set dts_file [set_drv_def_dts $drv_handle]
	set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1
}


proc dp_rx_12_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	set ip_subcores [dict create]
	dict set ip_subcores "axi_iic" "iic"
	dict set ip_subcores "clk_wiz" "clkWiz"
	dict set ip_subcores "displayport" "dp12"
	dict set ip_subcores "hdcp" "hdcp14"


	foreach ip [dict keys $ip_subcores] {
		set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}

	set timers [set_ip_handles_for_ss_subcores axi_timer $drv_handle]
	#hsi::get_cells -hier -filter {IP_NAME==axi_timer}
	#processor_hier_0_axi_timer_0 dp_rx_hier_0_v_dp_rxss1_0_timer dp_tx_hier_0_v_dp_txss1_0_timer

	if {[string_is_empty $timers]} {
		add_prop "$node" "hdcptimer-present" 0 int $dts_file
	} else {
		foreach timer $timers {
			set name [hsi get_property NAME [hsi::get_cells -hier $timer]]
			if {[regexp "rx" $name match]} {
				add_prop "$node" "hdcptimer-present" 1 int $dts_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dts_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dts_file
			}
		}
	}

}
