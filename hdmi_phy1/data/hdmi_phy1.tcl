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

    proc hdmi_phy1_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
	set board_dts [hdmi_sdt_get_board_dts]
	hdmi_sdt_gen_xfmc_node $dts_file
	add_prop "${node}" "xlnx,hdmi-connector" "xfmc" reference $dts_file 1
	if {[hdmi_sdt_is_zcu102_board $board_dts] || [hdmi_sdt_is_zcu106_board $board_dts]} {
		hdmi_phy1_sdt_gen_zcu_hdmi_phy1_i2c_nodes $dts_file
	}
	hdmi_sdt_apply_zcu_phy_overrides $node $dts_file $board_dts
	set afreq  0
	set rfreq  0
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

	set dru_refclk2_min_hz 399990000
	set dru_refclk2_max_hz 400010000
	add_prop "${node}" "xlnx,dru-refclk2-min-hz" $dru_refclk2_min_hz int $dts_file 1
	add_prop "${node}" "xlnx,dru-refclk2-max-hz" $dru_refclk2_max_hz int $dts_file 1

	set linerate [hsi get_property CONFIG.Tx_Max_GT_Line_Rate [hsi get_cells -hier $drv_handle]]
	scan $linerate %d tx_gt_linerate
	add_prop "${node}" "xlnx,tx-max-gt-line-rate" $tx_gt_linerate hexint $dts_file 1
	set linerate [hsi get_property CONFIG.Rx_Max_GT_Line_Rate [hsi get_cells -hier $drv_handle]]
	scan $linerate %d rx_gt_linerate
	add_prop "${node}" "xlnx,rx-max-gt-line-rate" $rx_gt_linerate hexint $dts_file 1

        set gt_direction [hsi get_property CONFIG.C_GT_DIRECTION [hsi get_cells -hier $drv_handle]]
        switch $gt_direction {
                        "SIMPLEX_TX" {
                                add_prop "${node}" "xlnx,gt-direction" $gt_direction  stringlist $dts_file 1
                        }
                        "SIMPLEX_RX" {
                                add_prop "${node}" "xlnx,gt-direction" $gt_direction  stringlist $dts_file 1
                        }
                        "DUPLEX" {
                                add_prop "${node}" "xlnx,gt-direction" $gt_direction  stringlist $dts_file 1
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
	set pinname "vid_phy_${channel_type}_axi4s_ch$ch"
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

proc hdmi_sdt_is_zcu102_board {board_dts} {
	if {[string match "*zcu102*" $board_dts]} {
		return 1
	}
	set hw_part [hdmi_sdt_get_hw_part]
	if {[string match "*xczu9*" $hw_part]} {
		return 1
	}
	return 0
}

proc hdmi_sdt_is_zcu106_board {board_dts} {
	if {[string match "*zcu106*" $board_dts]} {
		return 1
	}
	set hw_part [hdmi_sdt_get_hw_part]
	if {[string match "*xczu7*" $hw_part]} {
		return 1
	}
	return 0
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
	puts "INFO: HDMI SDT: generated xfmc node (board='$board_dts', xlnx,board-type=[$board_type])"
}

proc hdmi_sdt_apply_zcu_phy_overrides {node dts_file board_dts} {
	if {![hdmi_sdt_is_zcu102_board $board_dts] && ![hdmi_sdt_is_zcu106_board $board_dts]} {
		return
	}
	pldt unset $node "clock-names"
	pldt unset $node "clocks"
	add_prop "$node" "clock-names" "vid_phy_axi4lite_aclk drpclk tmds_clock frl_clock" stringlist $dts_file 1
	set zcu_phy_clocks "<&zynqmp_clk 71>, <&zynqmp_clk 71>, <&idt_241 1>, <&si5344 1>"
	add_prop "$node" "clocks" $zcu_phy_clocks noformating $dts_file 1
	add_prop "$node" "rxch4-sel-gpios" "vfmc_ctlr_ss_0_vfmc_gpio 18 0 1" reference $dts_file 1
}

# Return 1 if design has v_hdmi_phy or v_hdmi_phy1
proc hdmi_phy1_sdt_has_hdmi_phy1 {} {
	set hdmi_phy_cells [hsi::get_cells -hier -filter {IP_NAME == v_hdmi_phy}]
	set hdmi_phy1_cells [hsi::get_cells -hier -filter {IP_NAME == v_hdmi_phy1}]
	return [expr {[llength $hdmi_phy_cells] > 0 || [llength $hdmi_phy1_cells] > 0}]
}

# Return 1 if this (node, cell) is the PS I2C1 instance
proc hdmi_phy1_sdt_is_i2c1_instance {node cell} {
	set inst_name [string tolower [hsi get_property NAME $cell]]
	set node_lc [string tolower $node]
	if {[string match "*&i2c1*" $node_lc]} {
		return 1
	}
	if {[string match "*i2c@ff030000*" $node_lc]} {
		return 1
	}
	if {[string match "*i2c@b0141000*" $node_lc]} {
		return 1
	}
	if {[string match "*i2c_1*" $inst_name]} {
		return 1
	}
	return 0
}

# Find primary PS I2C (iicps) node that is I2C1; return [list node dts_file] or ""
proc hdmi_phy1_sdt_get_i2c1_node {} {
	foreach ip_name {"psu_i2c" "ps7_i2c"} {
		set i2c_cells [hsi::get_cells -hier -filter "IP_NAME == $ip_name"]
		foreach cell $i2c_cells {
			set i2c_node [get_node $cell]
			if {$i2c_node != 0 && [hdmi_phy1_sdt_is_i2c1_instance $i2c_node $cell]} {
				set dts_file [set_drv_def_dts $cell]
				return [list $i2c_node $dts_file]
			}
		}
	}
	return ""
}

# Generate ZCU HDMI PHY1 FMC I2C child nodes under the given I2C node (si5344, onsemi_tx, idt_241, expanders)
proc hdmi_phy1_sdt_gen_zcu_i2c1_nodes_under {i2c_node dts_file} {
	set si5344 [create_node -n "clock-generator" -l "si5344" -u 0x68 -p $i2c_node -d $dts_file]
	add_prop $si5344 "compatible" "si5344" string $dts_file 1
	add_prop $si5344 "#clock-cells" 1 int $dts_file 1
	add_prop $si5344 "reg" 0x68 int $dts_file
	add_prop $si5344 "clocks" "ref40" reference $dts_file 1
	add_prop $si5344 "clock-names" "xtal" string $dts_file 1

	set onsemi_tx [create_node -n "onsemi-tx" -l "onsemi_tx" -u 0x5b -p $i2c_node -d $dts_file]
	add_prop $onsemi_tx "compatible" "onsemi,onsemi-tx" string $dts_file 1
	add_prop $onsemi_tx "#clock-cells" 1 int $dts_file 1
	add_prop $onsemi_tx "reg" 0x5b int $dts_file
	add_prop $onsemi_tx "clocks" "ref40" reference $dts_file 1
	add_prop $onsemi_tx "clock-frequency" 148500000 int $dts_file
	add_prop $onsemi_tx "clock-names" "input-xtal" string $dts_file 1

	set onsemi_rx [create_node -n "onsemi-rx" -l "onsemi_rx" -u 0x5c -p $i2c_node -d $dts_file]
	add_prop $onsemi_rx "compatible" "onsemi,onsemi-rx" string $dts_file 1
	add_prop $onsemi_rx "#clock-cells" 1 int $dts_file 1
	add_prop $onsemi_rx "reg" 0x5c int $dts_file
	add_prop $onsemi_rx "clocks" "ref40" reference $dts_file 1
	add_prop $onsemi_rx "clock-frequency" 148500000 int $dts_file
	add_prop $onsemi_rx "clock-names" "input-xtal" string $dts_file 1

	set idt_241 [create_node -n "clock-generator" -l "idt_241" -u 0x7c -p $i2c_node -d $dts_file]
	add_prop $idt_241 "compatible" "idt,idt8t49" string $dts_file 1
	add_prop $idt_241 "#clock-cells" 1 int $dts_file 1
	add_prop $idt_241 "reg" 0x7c int $dts_file
	add_prop $idt_241 "clocks" "ref40" reference $dts_file 1
	add_prop $idt_241 "clock-frequency" 148500000 int $dts_file
	add_prop $idt_241 "clock-names" "input-xtal" string $dts_file 1

	set expander_75 [create_node -n "expander" -u 0x75 -p $i2c_node -d $dts_file]
	add_prop $expander_75 "compatible" "expander-fmc" string $dts_file 1
	add_prop $expander_75 "reg" 0x75 int $dts_file

	set expander_74 [create_node -n "expander" -u 0x74 -p $i2c_node -d $dts_file]
	add_prop $expander_74 "compatible" "expander-fmc74" string $dts_file 1
	add_prop $expander_74 "reg" 0x74 int $dts_file

	set expander_64 [create_node -n "expander" -u 0x64 -p $i2c_node -d $dts_file]
	add_prop $expander_64 "compatible" "expander-fmc64" string $dts_file 1
	add_prop $expander_64 "reg" 0x64 int $dts_file

	set expander_65 [create_node -n "expander" -u 0x65 -p $i2c_node -d $dts_file]
	add_prop $expander_65 "compatible" "expander-fmc65" string $dts_file 1
	add_prop $expander_65 "reg" 0x65 int $dts_file

	set expander_51 [create_node -n "expander" -u 0x51 -p $i2c_node -d $dts_file]
	add_prop $expander_51 "compatible" "expander-tipower" string $dts_file 1
	add_prop $expander_51 "reg" 0x51 int $dts_file
}

# Generate ZCU HDMI PHY1 I2C client nodes on PS I2C1; called from hdmi_phy1_generate when board is ZCU102/106
proc hdmi_phy1_sdt_gen_zcu_hdmi_phy1_i2c_nodes {dts_file} {
	global env
	if {[info exists env(hdmi_phy1_zcu_i2c1_nodes_generated)] && $env(hdmi_phy1_zcu_i2c1_nodes_generated) eq "1"} {
		return
	}
	if {![hdmi_phy1_sdt_has_hdmi_phy1]} {
		return
	}
	set primary_i2c [hdmi_phy1_sdt_get_i2c1_node]
	if {![llength $primary_i2c]} {
		puts "WARNING: hdmi_phy1: no PS I2C1 node found for ZCU HDMI PHY1 FMC helper"
		return
	}
	lassign $primary_i2c i2c_node i2c_dts_file
	hdmi_phy1_sdt_gen_zcu_i2c1_nodes_under $i2c_node $i2c_dts_file
	set env(hdmi_phy1_zcu_i2c1_nodes_generated) "1"
	puts "INFO: hdmi_phy1: generated HDMI PHY1 ZCU client nodes on $i2c_node"
}
