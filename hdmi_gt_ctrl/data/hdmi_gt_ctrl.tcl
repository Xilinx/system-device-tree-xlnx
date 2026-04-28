#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc hdmi_gt_ctrl_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
	set board_dts [hdmi_sdt_get_board_dts]
	set is_vek280_board [hdmi_sdt_is_vek280_board $board_dts]
	set is_vek385_board [hdmi_sdt_is_vek385_board $board_dts]
	hdmi_sdt_gen_xfmc_node $dts_file
	if {$is_vek280_board || $is_vek385_board} {
		hdmi_sdt_gen_vek_hdmi_fmc_i2c_nodes $dts_file
	}
	add_prop "${node}" "xlnx,hdmi-connector" "xfmc" reference $dts_file 1
	hdmi_sdt_apply_vek_gt_overrides $node $dts_file $board_dts
	set rx_max_gt_line_rate [hsi get_property CONFIG.Rx_Max_GT_Line_Rate [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,rx-max-gt-line-rate" $rx_max_gt_line_rate string $dts_file 1

	set tx_max_gt_line_rate [hsi get_property CONFIG.Tx_Max_GT_Line_Rate [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,tx-max-gt-line-rate" $tx_max_gt_line_rate string $dts_file 1
	if {$rx_max_gt_line_rate > 5.94 || $tx_max_gt_line_rate > 5.94 } {
		pldt append $node compatible "\ \, \"xlnx,v-hdmi-gt-controller-1.0\""
	} else {
		pldt append $node compatible "\ \, \"xlnx,hdmi-gt-controller-1.0\""
	}

	set afreq  0
	set rfreq  0
	if {$is_vek385_board} {
		puts "INFO: hdmi_gt_ctrl: vek385 DRU widened values enabled for board '$board_dts'"
	} else {
		puts "INFO: hdmi_gt_ctrl: vek385 DRU widened values disabled for board '$board_dts'"
	}

	set transceiver [hsi get_property CONFIG.Transceiver [hsi get_cells -hier $drv_handle]]
        switch $transceiver {
                        "GTXE2" {
                                add_prop "${node}" "xlnx,transceiver" 1 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 1 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTHE2" {
                                add_prop "${node}" "xlnx,transceiver" 2 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 2 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTPE2" {
                                add_prop "${node}" "xlnx,transceiver" 3 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 3 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTHE3" {
                                add_prop "${node}" "xlnx,transceiver" 4 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 4 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTHE4" {
                                add_prop "${node}" "xlnx,transceiver" 5 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 5 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTYE4" {
                                add_prop "${node}" "xlnx,transceiver" 6 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 6 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTYE5" {
                                add_prop "${node}" "xlnx,transceiver" 7 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 7 hexint $dts_file 1
				set afreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
				set rfreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
                        }
                        "GTYP" {
                                add_prop "${node}" "xlnx,transceiver" 8 hexint $dts_file 1
                                add_prop "${node}" "xlnx,transceiver-type" 8 hexint $dts_file 1
				set afreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
				set rfreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
                        }
			default {
				puts "#error Video PHY currently supports only GTYP, GTYE5, GTYE4, GTHE4, GTHE3, GTHE2, GTPE2 and GTXE2; $transceiver not supported "
				set afreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
			}
        }

	if {$afreq == 0} {
		set afreq "100000000"
		puts "WARNING: AXIlite clock frequency information is not available in the design, \
		      for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		      If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
	if {$rfreq == 0} {
		set rfreq "100000000"
		puts "WARNING: AXIlite clock frequency information is not available in the design, \
		      for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		      If this is incorrect, the peripheral $drv_handle will be non-functional"
	}

	set axi_lite_freq [format "%X" $afreq]
	add_prop "${node}" "xlnx,axi-lite-freq-hz" $axi_lite_freq hexint $dts_file 1

	set drpclk_freq [format "%X" $rfreq]
        add_prop "${node}" "xlnx,drpclk-freq" $drpclk_freq hexint $dts_file 1

	set speedgrade [hsi get_property CONFIG.C_SPEEDGRADE [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,speedgrade" $speedgrade stringlist $dts_file 1

	if {$transceiver == "GTYP" && $is_vek385_board} {
		set dru_refclk2_min_hz 399970000
		set dru_refclk2_max_hz 400050000
		add_prop "${node}" "xlnx,dru-refclk2-min-hz" $dru_refclk2_min_hz int $dts_file 1
		add_prop "${node}" "xlnx,dru-refclk2-max-hz" $dru_refclk2_max_hz int $dts_file 1
	}

	# Add DT properties for clk primitive
	foreach dir {rx tx} {
		set clk_primitive [hsi get_property CONFIG.C_[string totitle $dir]_Clk_Primitive [hsi get_cells -hier $drv_handle]]
		set clk_primitive_val [expr {$clk_primitive == 1 ? 2 : 0}]
		add_prop "${node}" "xlnx,${dir}-clk-primitive" $clk_primitive_val hexint $dts_file 1
	}
	set linerate [hsi get_property CONFIG.Tx_Max_GT_Line_Rate [hsi get_cells -hier $drv_handle]]
	scan $linerate %d tx_gt_linerate
	add_prop "${node}" "xlnx,tx-max-gt-line-rate" $tx_gt_linerate hexint $dts_file 1
	set linerate [hsi get_property CONFIG.Rx_Max_GT_Line_Rate [hsi get_cells -hier $drv_handle]]
	scan $linerate %d rx_gt_linerate
	add_prop "${node}" "xlnx,rx-max-gt-line-rate" $rx_gt_linerate hexint $dts_file 1

        set gt_direction [hsi get_property CONFIG.C_GT_DIRECTION [hsi get_cells -hier $drv_handle]]
        switch $gt_direction {
                        "SIMPLEX_TX" {
                                add_prop "${node}" "xlnx,gt-direction" 1 hexint $dts_file 1
                        }
                        "SIMPLEX_RX" {
                                add_prop "${node}" "xlnx,gt-direction" 2 hexint $dts_file 1
                        }
                        "DUPLEX" {
                                add_prop "${node}" "xlnx,gt-direction" 3 hexint $dts_file 1
                        }
        }
	# Get the number of Rx and Tx channels
	set Rx_No_Of_Channels [hsi get_property CONFIG.C_Rx_No_Of_Channels [hsi::get_cells -hier $drv_handle]]
	set Tx_No_Of_Channels [hsi get_property CONFIG.C_Tx_No_Of_Channels [hsi::get_cells -hier $drv_handle]]

	# Create PHY nodes for both Rx and Tx channels
	for {set ch 0} {$ch < $Rx_No_Of_Channels} {incr ch} {
		create_phy_node "rx" $ch $drv_handle $node $dts_file
	}

	for {set ch 0} {$ch < $Tx_No_Of_Channels} {incr ch} {
		create_phy_node "tx" $ch $drv_handle $node $dts_file
	}
    }


proc create_phy_node {channel_type ch drv_handle node dts_file} {
	set pinname "${channel_type}_axi4s_ch$ch"
	set channelip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $pinname]
	if {[llength $channelip] && [llength [hsi::get_mem_ranges $channelip]]} {
		set phy_node [create_node -n "${pinname}${channelip}" -l "${drv_handle}${channel_type}phy_lane${ch}" -p $node -d $dts_file]
		add_prop "$phy_node" "#phy-cells" 4 int $dts_file 1
	}
}

proc hdmi_sdt_get_board_dts {} {
	set board_dts ""
	set board_hsi ""
	if {[info exists ::env(sdt_board_dts)]} {
		set board_dts $::env(sdt_board_dts)
	}
	set hw_design [hsi::current_hw_design]
	if {[llength $hw_design]} {
		set board_hsi [hsi get_property BOARD $hw_design]
	}
	if {![llength $board_dts] && [llength $board_hsi]} {
		set board_parts [split $board_hsi ":"]
		if {[llength $board_parts] > 1} {
			set board_dts [lindex $board_parts 1]
		} else {
			set board_dts $board_hsi
		}
	}
	return [string tolower $board_dts]
}

proc hdmi_sdt_get_hw_part {} {
	set hw_part ""
	set hw_design [hsi::current_hw_design]
	if {[llength $hw_design]} {
		set hw_part [hsi get_property PART $hw_design]
	}
	return [string tolower $hw_part]
}

proc hdmi_sdt_is_vek280_board {board_dts} {
	if {[string match "*vek280*" $board_dts]} {
		return 1
	}
	set hw_part [hdmi_sdt_get_hw_part]
	if {[string match "*ve280*" $hw_part]} {
		return 1
	}
	return 0
}

proc hdmi_sdt_is_vek385_board {board_dts} {
	if {[string match "*vek385*" $board_dts]} {
		return 1
	}
	set hw_part [hdmi_sdt_get_hw_part]
	if {[string match "*ve385*" $hw_part]} {
		return 1
	}
	return 0
}

proc hdmi_sdt_get_xfmc_board_type {board_dts} {
	set detected_board $board_dts
	if {![llength $detected_board]} {
		set hw_part [hdmi_sdt_get_hw_part]
		if {[string match "*ve280*" $hw_part]} {
			set detected_board "vek280"
		} elseif {[string match "*ve385*" $hw_part]} {
			set detected_board "vek385"
		} elseif {[string match "*xczu9*" $hw_part]} {
			set detected_board "zcu102"
		} elseif {[string match "*xczu7*" $hw_part]} {
			set detected_board "zcu106"
		} elseif {[string match "*xcvc1902*" $hw_part]} {
			set detected_board "vck190"
		}
	}

	if {[string match "*vek280*" $detected_board]} {
		return "00"
	}
	if {[string match "*vek385*" $detected_board]} {
		return "00"
	}
	if {[string match "*zcu102*" $detected_board]} {
		return "01"
	}
	if {[string match "*zcu106*" $detected_board]} {
		return "02"
	}
	if {[string match "*vck190*" $detected_board]} {
		return "03"
	}
	return "00"
}

proc hdmi_sdt_gen_xfmc_node {dts_file} {
	global env
	if {[info exists env(hdmi_xfmc_node_generated)] && $env(hdmi_xfmc_node_generated) eq "1"} {
		return
	}
	set board_dts [hdmi_sdt_get_board_dts]
	set board_type [hdmi_sdt_get_xfmc_board_type $board_dts]
	set bus_node "amba_pl: amba_pl"
	if {![info exists env(hdmi_ref40_node_generated)] || $env(hdmi_ref40_node_generated) ne "1"} {
		set ref40_node [create_node -n "ref40m" -l "ref40" -p $bus_node -d $dts_file]
		add_prop $ref40_node "compatible" "fixed-clock" string $dts_file 1
		add_prop $ref40_node "#clock-cells" 0 int $dts_file 1
		add_prop $ref40_node "clock-frequency" 40000000 int $dts_file
		set env(hdmi_ref40_node_generated) "1"
	}
	set xfmc_node [create_node -n "xv_fmc" -l "xfmc" -p $bus_node -d $dts_file]
	add_prop $xfmc_node "compatible" "vfmc" string $dts_file 1
	set board_type_dt "\[$board_type\]"
	add_prop $xfmc_node "xlnx,board-type" $board_type_dt noformating $dts_file 1
	set env(hdmi_xfmc_node_generated) "1"
	# Move ref40 and xfmc to the beginning of amba_pl (before i2c and other nodes)
	foreach child [pldt children $bus_node] {
		if {[string match "xfmc:*" $child]} {
			pldt move $bus_node 0 $child
		}
	}
	foreach child [pldt children $bus_node] {
		if {[string match "ref40:*" $child]} {
			pldt move $bus_node 0 $child
		}
	}
	puts "INFO: HDMI SDT: generated xfmc node (board='$board_dts', xlnx,board-type=[$board_type])"
}

proc hdmi_sdt_apply_vek_gt_overrides {node dts_file board_dts} {
	if {![hdmi_sdt_is_vek280_board $board_dts] && ![hdmi_sdt_is_vek385_board $board_dts]} {
		return
	}
	set axi4lite_clk_ref [hdmi_sdt_get_gt_axi4lite_clock_ref $node]
	pldt append $node "clock-names" " , \"vid_phy_axi4lite_aclk\" , \"drpclk\" , \"tmds_clock\""
	pldt append $node "clocks" " , $axi4lite_clk_ref , $axi4lite_clk_ref , <&idt_241 1>"
}

proc hdmi_sdt_get_gt_axi4lite_clock_ref {node} {
	set fallback_ref "<&versal_clk 65>"
	if {[catch {set clock_names_raw [pldt get $node "clock-names"]}]} {
		return $fallback_ref
	}
	if {[catch {set clocks_raw [pldt get $node "clocks"]}]} {
		return $fallback_ref
	}

	set clock_names {}
	foreach name_token [regexp -all -inline {"[^"]+"} $clock_names_raw] {
		lappend clock_names [string trim $name_token "\""]
	}
	set clock_refs [regexp -all -inline {<[^>]+>} $clocks_raw]
	if {[llength $clock_names] == 0 || [llength $clock_refs] == 0} {
		return $fallback_ref
	}

	set axi4lite_idx [lsearch -exact $clock_names "axi4lite_aclk"]
	if {$axi4lite_idx < 0 || $axi4lite_idx >= [llength $clock_refs]} {
		return $fallback_ref
	}
	return [lindex $clock_refs $axi4lite_idx]
}

# Get primary axi_iic node and its dts_file (for VEK HDMI FMC I2C child nodes)
proc hdmi_sdt_get_axi_iic_primary_node {} {
	set iic_cells [hsi::get_cells -hier -filter {IP_NAME == axi_iic}]
	foreach iic_cell $iic_cells {
		set iic_node [get_node $iic_cell]
		if {$iic_node != 0} {
			set dts_file [set_drv_def_dts $iic_cell]
			return [list $iic_node $dts_file]
		}
	}
	return ""
}

# Generate VEK HDMI FMC I2C child nodes under the given axi_iic node (idt_241, tmds1204 tx/rx)
proc hdmi_sdt_gen_vek_hdmi_fmc_i2c_nodes_under {iic_node dts_file} {
	set idt_241 [create_node -n "clock-generator" -l "idt_241" -u 0x6c -p $iic_node -d $dts_file]
	add_prop $idt_241 "compatible" "idt,idt8t49" string $dts_file 1
	add_prop $idt_241 "#clock-cells" 1 int $dts_file 1
	add_prop $idt_241 "reg" 0x6c int $dts_file
	add_prop $idt_241 "clocks" "ref40" reference $dts_file 1
	add_prop $idt_241 "clock-frequency" 148500000 int $dts_file
	add_prop $idt_241 "clock-names" "input-xtal" string $dts_file 1

	set tmds1204_tx [create_node -n "ti_tmds1204-tx" -l "ti_tmds1204_tx" -u 0x5e -p $iic_node -d $dts_file]
	add_prop $tmds1204_tx "compatible" "ti_tmds1204,ti_tmds1204-tx" string $dts_file 1
	add_prop $tmds1204_tx "#clock-cells" 1 int $dts_file 1
	add_prop $tmds1204_tx "reg" 0x5e int $dts_file
	add_prop $tmds1204_tx "clocks" "ref40" reference $dts_file 1
	add_prop $tmds1204_tx "clock-frequency" 148500000 int $dts_file
	add_prop $tmds1204_tx "clock-names" "input-xtal" string $dts_file 1

	set tmds1204_rx [create_node -n "ti_tmds1204-rx" -l "ti_tmds1204_rx" -u 0x5b -p $iic_node -d $dts_file]
	add_prop $tmds1204_rx "compatible" "ti_tmds1204,ti_tmds1204-rx" string $dts_file 1
	add_prop $tmds1204_rx "#clock-cells" 1 int $dts_file 1
	add_prop $tmds1204_rx "reg" 0x5b int $dts_file
	add_prop $tmds1204_rx "clocks" "ref40" reference $dts_file 1
	add_prop $tmds1204_rx "clock-frequency" 148500000 int $dts_file
	add_prop $tmds1204_rx "clock-names" "input-xtal" string $dts_file 1
}

# Generate VEK HDMI FMC I2C nodes (finds primary axi_iic and creates child nodes); called from gt controller
proc hdmi_sdt_gen_vek_hdmi_fmc_i2c_nodes {dts_file} {
	global env
	if {[info exists env(hdmi_gt_vek_fmc_i2c_generated)] && $env(hdmi_gt_vek_fmc_i2c_generated) eq "1"} {
		return
	}
	set primary_iic [hdmi_sdt_get_axi_iic_primary_node]
	if {![llength $primary_iic]} {
		puts "WARNING: hdmi_gt_ctrl: no axi_iic node found for HDMI FMC I2C helper"
		return
	}
	lassign $primary_iic iic_node iic_dts_file
	hdmi_sdt_gen_vek_hdmi_fmc_i2c_nodes_under $iic_node $iic_dts_file
	set env(hdmi_gt_vek_fmc_i2c_generated) "1"
	puts "INFO: hdmi_gt_ctrl: generated HDMI FMC I2C nodes for VEK280/VEK385 on $iic_node"
}
