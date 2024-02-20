#
# (C) Copyright 2018-2022 Xilinx, Inc.
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

proc dp_hdcp22_tx_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

	#hsi::get_cells -hier -filter {IP_NAME==v_tc}
	#hsi get_property IP_NAME [hsi::get_cells -hier v_hdmi_txss1_hdcp_1_4]

	set ip_subcores [dict create]
	dict set ip_subcores "hdcp22_cipher_dp" "cipher"
	dict set ip_subcores "hdcp22_rng" "rng"
	dict set ip_subcores "axi_timer" "hdcp22_timer"

	foreach ip [dict keys $ip_subcores] {
		set ip_handles [hsi::get_cells -hier -filter "IP_NAME==$ip"]
		set ip_prefix [dict get $ip_subcores $ip]

		foreach ip_handle $ip_handles {
			if { $ip eq "axi_timer" } {
				if { [regexp $drv_handle $ip_handle match] && [regexp $ip_prefix $ip_handle match] } {
					add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
				}
			} elseif { [regexp $drv_handle $ip_handle match] && [regexp $ip $ip_handle match] } {
				add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
			}
		}
	}

}
