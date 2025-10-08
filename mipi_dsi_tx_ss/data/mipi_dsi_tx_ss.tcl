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

    proc mipi_dsi_tx_ss_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

	set compatible [get_comp_str $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,dsi\""
	set dphy_en_reg_if [hsi get_property CONFIG.DPHY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]
	set dsi_num_lanes [hsi get_property CONFIG.DSI_LANES [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,dsi-num-lanes" $dsi_num_lanes int $dts_file 1
        if  {[string match -nocase "true" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dphy-en-reg-if" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dphy-en-reg-if" 0 int $dts_file 1
	}
	set dphymode [hsi get_property CONFIG.C_DPHY_MODE [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "master" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 1 int $dts_file 1
        } elseif {[string match -nocase "slave" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 0 int $dts_file 1
	}

        set dsi_datatype [hsi get_property CONFIG.DSI_DATATYPE [hsi::get_cells -hier $drv_handle]]
	set pixel [pixel_format $dsi_datatype]
        add_prop "$node" "xlnx,dsi-datatype" $pixel hexint $dts_file 1
	if {[string match -nocase $dsi_datatype "RGB888"]} {
		add_prop "$node" "xlnx,dsi-data-type" 0 int $dts_file 1
	} elseif {[string match -nocase $dsi_datatype "RGB666_L"]} {
		add_prop "$node" "xlnx,dsi-data-type" 1 int $dts_file 1
	} elseif {[string match -nocase $dsi_datatype "RGB666_P"]} {
		add_prop "$node" "xlnx,dsi-data-type" 2 int $dts_file 1
	} elseif {[string match -nocase $dsi_datatype "RGB565"]} {
		add_prop "$node" "xlnx,dsi-data-type" 3 int $dts_file 1
	}

	set highaddr [hsi get_property CONFIG.C_HIGHADDR  [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,highaddr" $highaddr hexint $dts_file 1

	set panel_node [create_node -n "simple_panel" -l simple_panel$drv_handle -u 0 -p $node -d $dts_file]
#	add_prop "${panel_node}" "/* User needs to add the panel node based on their requirement */" "" comment $dts_file 1
	add_prop "$panel_node" "reg" 0 int $dts_file 1
	add_prop "$panel_node" "compatible" "auo,b101uan01" string $dts_file 1

        dsitx_add_hier_instances $drv_handle
}

proc mipi_dsi_tx_ss_update_endpoints {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {[string_is_empty $node]} {
                return
        }

        global end_mappings
        global remo_mappings

        set dsitx_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]
        if {![llength $dsitx_inip]} {
            dtg_warning "$drv_handle pin S_AXIS is not connected ..check your design"
        }
        set port_node [create_node -n "port" -l encoder_dsi_port$drv_handle -u 0 -p $node -d $dts_file]
        add_prop "$port_node" "reg" 0 int $dts_file
        set inip ""
        foreach inip $dsitx_inip {
            if {[llength $inip]} {
                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                set ip_mem_handles [hsi::get_mem_ranges $inip]
                if {[llength $ip_mem_handles]} {
                    set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                    if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                        gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
                    }
                } else {
                    if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                        continue
                    }
                    set inip [get_in_connect_ip $inip $master_intf]
                    if {[llength $inip]} {
                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                            gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
                        }
                    }
                }
            }
        }

        if {[llength $inip]} {
            set dsitx_in_end ""
            set dsitx_remo_in_end ""
            if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                set dsitx_in_end [dict get $end_mappings $inip]
                dtg_verbose "dsitx_in_end:$dsitx_in_end"
            }
            if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                set dsitx_remo_in_end [dict get $remo_mappings $inip]
                dtg_verbose "dsitx_remo_in_end:$dsitx_remo_in_end"
            }
            if {[llength $dsitx_remo_in_end]} {
                set dsitx_node [create_node -n "endpoint" -l $dsitx_remo_in_end -p $port_node -d $dts_file]
            }
            if {[llength $dsitx_in_end]} {
                add_prop "$dsitx_node" "remote-endpoint" $dsitx_in_end reference $dts_file
            }
        } else {
            puts "No valid input source connected to $drv_handle ..check your design"
        }

    }

    proc dsitx_add_hier_instances {drv_handle} {
        set node [get_node $drv_handle]
        set subsystem_base_addr [get_baseaddr $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set dphy_en_reg_if [hsi get_property CONFIG.DPHY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]

        #Example :
        #hsi::get_cells -hier -filter {IP_NAME==mipi_dsi2_tx_ctrl}
        #dsitx_0_tx
        #

        set ip_subcores [dict create]
        dict set ip_subcores "mipi_dsi_tx_ctrl" "dsi-tx"
        dict set ip_subcores "mipi_dphy" "dphy"

        foreach ip [dict keys $ip_subcores] {
            if { $ip eq "mipi_dphy"} {
                if {[string match -nocase "false" $dphy_en_reg_if]} {
                    puts "INFO: skipping dphy instance creation as dphy_en_reg_if is false"
                    continue
                }
            }
            set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
            set ip_prefix [dict get $ip_subcores $ip]
            if {![string_is_empty $ip_handle]} {
                add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
                add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
                update_subcore_absolute_addr $drv_handle $ip_handle $dts_file
            } else {
                add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
            }
        }

    }

    proc pixel_format {pxl_format} {
        set pixel_format ""
        switch $pxl_format {
            "RGB565" {
                set pixel_format 0x0E
            }
            "RGB666_P" {
                set pixel_format 0x1E
            }
            "RGB666_L" {
                set pixel_format 0x2E
            }
            "RGB888" {
                set pixel_format 0x3E
            }
            "Compressed" {
                set pixel_format 0x0B
            }
        }
	return $pixel_format
    }
