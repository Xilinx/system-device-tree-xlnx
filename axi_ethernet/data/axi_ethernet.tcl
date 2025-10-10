#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Michal SIMEK <monstr@monstr.eu>
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
    set rxethmem 0

    proc axi_ethernet_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(CUSTOM_SDT_REPO)
        set common_file "$path/device_tree/data/config.yaml"
        set bus_node [detect_bus_name $drv_handle]

        set node [get_node $drv_handle]
        if {$node == 0} {
            return
        }
        global rxethmem
        set rxethmem 0
        global ddrv_handle
        set ddrv_handle $drv_handle
        set hw_design [hsi::current_hw_design]
        set board_name ""
        if {[llength $hw_design]} {
            set board [split [hsi get_property BOARD $hw_design] ":"]
            set board_name [lindex $board 1]
        }
        set dts_file [set_drv_def_dts $drv_handle]
        update_eth_mac_addr $drv_handle
        set compatible [get_comp_str $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,axi-ethernet-1.00.a\""

        #adding stream connectivity
        set eth_ip [hsi::get_cells -hier $drv_handle]
        set ip_mem_handles [hsi::get_mem_ranges $eth_ip]
        if {[llength $ip_mem_handles] == 0} {
            return
        }
        # search for a valid bus interface name
        # This is required to work with Vivado 2015.1 due to IP PIN naming change
        set hasbuf [hsi get_property CONFIG.processor_mode $eth_ip]
        set ip_name [hsi get_property IP_NAME $eth_ip]
        if {$ip_name == "axi_ethernet"} {
            pldt append $node compatible "\ \, \"xlnx,axi-ethernet-1.00.a\""
        }
        set num_cores 1
        if {$ip_name == "xxv_ethernet" || $ip_name == "ethernet_1_10_25g"} {
            set ip_mem_handles [hsi::get_mem_ranges [hsi::get_cells -hier $drv_handle]]
            set num 0
            axi_ethernet_generate_reg_property $node $ip_mem_handles $num
            set num_cores [hsi get_property CONFIG.NUM_OF_CORES [hsi::get_cells -hier $drv_handle]]
        }
        lappend xxv_list "$node"
        set new_label ""
        set clk_label ""
        set connected_ip ""
        set eth_node ""
        for {set core 0} {$core < $num_cores} {incr core} {
                if {(($ip_name == "xxv_ethernet") || (($ip_name == "ethernet_1_10_25g")))  && $core != 0} {
                    set bus_node "amba_pl: amba_pl"
                    set dts_file "pl.dtsi"
                set ipmem_len [llength $ip_mem_handles]
                if {$ipmem_len > 1} {
                    set base_addr [string tolower [hsi get_property BASE_VALUE [lindex $ip_mem_handles $core]]]
                    regsub -all {^0x} $base_addr {} base_addr
                    append new_label $drv_handle "_" $core
                    append clk_label $drv_handle "_" $core
                    set eth_node [create_node -n "ethernet" -l "$new_label" -u $base_addr -d $dts_file -p $bus_node]
                    lappend xxv_list "$eth_node"
                    add_prop $eth_node "status" "okay" string $dts_file
                    axi_ethernet_generate_reg_property $eth_node $ip_mem_handles $core
                }
            }
        if {$hasbuf == "true" || $hasbuf == "" && $ip_name != "axi_10g_ethernet" && $ip_name != "ten_gig_eth_mac"
            && $ip_name != "xxv_ethernet" && $ip_name != "ethernet_1_10_25g" && $ip_name != "usxgmii"} {
            foreach n "AXI_STR_RXD m_axis_rxd" {
                set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
                if {[string_is_empty ${intf}] != 1} {
                    break
                }
            }
            if { [llength $intf] } {
                set intf_net [hsi::get_intf_nets -of_objects $intf ]
                if { [llength $intf_net]  } {
                    set target_intf [get_other_intf_pin $intf_net $intf]
                    if { [llength $target_intf] } {
                        set connected_ip [axi_ethernet_get_connectedip $intf]
                if {[llength $connected_ip]} {
                    add_prop $node axistream-connected "$connected_ip" reference $dts_file 1
                    add_prop $node axistream-control-connected "$connected_ip" reference $dts_file 1
                    set ip_prop CONFIG.c_include_mm2s_dre
                    add_cross_property $connected_ip $ip_prop $drv_handle "xlnx,include-dre" $node boolean
                } else {
                    dtg_warning "$drv_handle connected ip is NULL for the interface $intf"
                }
                        set ip_prop CONFIG.Enable_1588
                        add_cross_property $eth_ip $ip_prop $drv_handle "xlnx,eth-hasptp" $node boolean
                    }
                }
            }
            foreach n "AXI_STR_RXD m_axis_tx_ts" {
                set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
                if {[string_is_empty ${intf}] != 1} {
                    break
                }
            }
    
            if {[string_is_empty ${intf}] != 1} {
                set tx_tsip [axi_ethernet_get_connectedip $intf]
                if {[llength $tx_tsip]} {
                    set_drv_prop $drv_handle axififo-connected "$tx_tsip" $node reference
                }
            }
        } else {
            foreach n "AXI_STR_RXD m_axis_rx" {
                set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
                if {[string_is_empty ${intf}] != 1} {
                    break
                }
            }
    
            if {$ip_name == "xxv_ethernet" || $ip_name == "ethernet_1_10_25g" || $ip_name == "usxgmii"} {
                foreach n "AXI_STR_RXD axis_rx_0" {
                    set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
                    if {[string_is_empty ${intf}] != 1} {
                        break
                    }
                }
            }
    
            if { [llength $intf] } {
                set connected_ip [axi_ethernet_get_connectedip $intf]
            }
    
            foreach n "AXI_STR_RXD m_axis_tx_ts" {
                set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
                if {[string_is_empty ${intf}] != 1} {
                    break
                }
            }
    
            if {[string_is_empty ${intf}] != 1} {
                set tx_tsip [axi_ethernet_get_connectedip $intf]
            if {[llength $tx_tsip]} {
                   set_drv_prop $drv_handle axififo-connected "$tx_tsip" $node reference
            }
            } else {
                set port_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $eth_ip] "tx_ptp_tag_field_in_0"]]
            if {[llength $port_pins]} {
                    set periph [::hsi::get_cells -of_objects $port_pins]
                    if {[llength $periph]} {
                        if {[get_ip_property $periph IP_NAME] in {"xlslice" "ilslice"}}  {
                            set intf "Din"
                            set in1_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intf"]
                            set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $periph] $in1_pin]]
                            if {[llength $sink_pins]} {
                                set per [::hsi::get_cells -of_objects $sink_pins]
                                if {[string match -nocase [hsi get_property IP_NAME $per] "axis_clock_converter"]} {
                                    set pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $per] "s_axis_tdata"]]
                                    if {[llength $pins]} {
                                        set txfifo [hsi get_cells -of_objects $pins]
                                        if {[llength $txfifo]} {
                                            set_drv_prop $drv_handle axififo-connected "$txfifo" $node reference
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            set rxfifo_port_pins [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $eth_ip] "rx_ptp_tstamp_out_0"]]
            if {[llength $rxfifo_port_pins]} {
                set periph [::hsi::get_cells -of_objects $rxfifo_port_pins]
                if {[llength $periph]} {
                    if {[get_ip_property $periph IP_NAME] in {"xlconcat" "ilconcat"}} {
                        set intf "dout"
                        set in1_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intf"]
                        set sink_pins [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $periph] $in1_pin]]
                        if {[llength $sink_pins]} {
                            set per [::hsi::get_cells -of_objects $sink_pins]
                            if {[llength $per]} {
                                if {[string match -nocase [hsi get_property IP_NAME $per] "axis_dwidth_converter"]} {
                                    set con_ip [get_connected_stream_ip [hsi get_cells -hier $per] "M_AXIS"]
                                    if {[llength $con_ip]} {
                                        if {[string match -nocase [hsi get_property IP_NAME $con_ip] "axis_clock_converter"]} {
                                            set rxtsfifo_ip [get_connected_stream_ip [hsi get_cells -hier $con_ip] "M_AXIS"]
                                            if {[llength $rxtsfifo_ip]} {
                                                set_drv_prop $drv_handle xlnx,rxtsfifo "$rxtsfifo_ip" $node reference
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if {![string_is_empty $connected_ip]} {
                add_prop $node axistream-connected "$connected_ip" reference $dts_file 1
                add_prop $node axistream-control-connected "$connected_ip" reference $dts_file 1
                set ip_prop CONFIG.c_include_mm2s_dre
                add_cross_property $connected_ip $ip_prop $drv_handle "xlnx,include-dre" $node boolean
            }
            add_prop $node xlnx,rxmem "$rxethmem" hexint $dts_file
            if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && $core != 0} {
                set intf [hsi::get_intf_pins -of_objects $eth_ip "axis_rx_${core}"]
                if {[llength $intf] && [llength $eth_node]} {
                        set connected_ip [axi_ethernet_get_connectedip $intf]
                        if {![string_is_empty $connected_ip]} {
                            add_prop $eth_node "axistream-connected" "$connected_ip" reference "pl.dtsi"
                            add_prop $eth_node "axistream-control-connected" "$connected_ip" reference "pl.dtsi"
                        }
                        add_prop $eth_node "xlnx,include-dre" boolean "pl.dtsi"
                        add_prop $eth_node xlnx,rxmem "$rxethmem" hexint $dts_file
                }
            }
        }

        if {$ip_name == "axi_ethernet"} {
        set txcsum [hsi get_property CONFIG.TXCSUM $eth_ip]
        set txcsum [axi_ethernet_get_checksum $txcsum]
        set rxcsum [hsi get_property CONFIG.RXCSUM $eth_ip]
        set rxcsum [axi_ethernet_get_checksum $rxcsum]
        set phytype [hsi get_property CONFIG.PHY_TYPE $eth_ip]
        set phytype [axi_ethernet_get_phytype $phytype]
        set phyaddr [hsi get_property CONFIG.PHYADDR $eth_ip]
        set rxmem [hsi get_property CONFIG.RXMEM $eth_ip]
        set rxmem [axi_ethernet_get_memrange $rxmem]
        add_prop $node "xlnx,txcsum" $txcsum hexint "pl.dtsi" 1
        add_prop $node "xlnx,rxcsum" $rxcsum hexint "pl.dtsi" 1
        pldt unset $node "xlnx,phy-type"
        add_prop $node "xlnx,phyaddr" $phyaddr hexint "pl.dtsi" 1
        add_prop $node "xlnx,rxmem" $rxmem hexint "pl.dtsi" 1
        add_prop $node "xlnx,speed-1-2p5" "1000" int "pl.dtsi" 1
        add_prop $node "max-speed" "1000" int "pl.dtsi" 1
        }

        set is_nobuf 0
        if {$ip_name == "axi_ethernet"} {
            set avail_param [hsi list_property [hsi::get_cells -hier $drv_handle]]
            if {[lsearch -nocase $avail_param "CONFIG.speed_1_2p5"] >= 0} {
                if {[hsi get_property CONFIG.speed_1_2p5 [hsi::get_cells -hier $drv_handle]] == "2p5G"} {
                    set is_nobuf 1
                    add_prop $node "xlnx,speed-1-2p5" "2500" int "pl.dtsi" 1
                    pldt append $node compatible "\ \, \"xlnx,axi-2_5-gig-ethernet-1.0\""
                    add_prop $node "max-speed" "2500" int "pl.dtsi" 1
                }
            }
        }

	if {$ip_name == "xxv_ethernet"} {
	    set auto_neg [hsi get_property CONFIG.C_INCLUDE_AUTO_NEG_LT_LOGIC $eth_ip]
	    if {$auto_neg eq "Include AN/LT Logic"} {
		    add_prop $node "xlnx,has-auto-neg" boolean "pl.dtsi"
	    }
	}

        if { $hasbuf == "false" && $is_nobuf == 0} {
            set ip_prop CONFIG.processor_mode
            add_cross_property $eth_ip $ip_prop $drv_handle "xlnx,eth-hasnobuf" $node boolean
        }

        #adding clock frequency
        set clk [hsi::get_pins -of_objects $eth_ip "S_AXI_ACLK"]
        if {[llength $clk] } {
            set freq [hsi get_property CLK_FREQ $clk]
            add_prop $node clock-frequency "$freq" int "pl.dtsi"
            if {$ip_name == "xxv_ethernet" && [llength $eth_node]} {
                add_prop $eth_node "clock-frequency" "$freq" int "pl.dtsi"
            }
        }

        # node must be created before child node
        set node [gen_peripheral_nodes $drv_handle]
        if {$ip_name == "axi_ethernet"} {
        set hier_params [axi_ethernet_gen_hierip_params $drv_handle]
        }
        set mdio_node [gen_mdio_node $drv_handle $node]


        set phytype [string tolower [hsi get_property CONFIG.PHY_TYPE $eth_ip]]
        if {$phytype == "rgmii" && $board_name == "kc705"} {
            set phytype "rgmii-rxid"
        } elseif {$phytype == "1000basex"} {
            set phytype "1000base-x"
        }
        # phytype should be 2500base-x if IP is configured for 2.5G
        if {[hsi get_property CONFIG.speed_1_2p5 [hsi::get_cells -hier $drv_handle]] == "2p5G"} {
            set phytype "2500base-x"
        }
        if {![string match -nocase $phytype ""]} {
            add_prop $node phy-mode "$phytype" string "pl.dtsi" 1
        }
        if {$phytype == "sgmii" || $phytype == "1000base-x" || $phytype == "2500base-x"} {
            add_prop $node phy-mode "$phytype" string "pl.dtsi" 1
            set phynode [axi_ethernet_pcspma_phy_node $eth_ip]
            set phya [lindex $phynode 0]
            if { $phya != "-1"} {
                set phy_name "[lindex $phynode 1]"
                set_drv_prop $drv_handle pcs-handle "$drv_handle$phy_name" $node reference
                axi_ethernet_gen_phy_node $mdio_node $phy_name $phya $drv_handle
		if {[llength $node]} {
			add_prop $node "managed" "in-band-status" string "pl.dtsi"
			add_prop $node "xlnx,switch-x-sgmii" boolean "pl.dtsi"
		}
            }
        }
        if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g"))  && $core != 0 && [llength $eth_node]} {
            append new_label "_" mdio
            set mdionode [create_node -l "$new_label" -n mdio -p $eth_node -d $dts_file]
            add_prop $mdionode "#address-cells" 1 int $dts_file
            add_prop "${mdionode}" "#size-cells" 0 int $dts_file
            set new_label ""
        }
        if {$ip_name == "axi_10g_ethernet"} {
            set phytype [string tolower [hsi get_property CONFIG.base_kr $eth_ip]]
            add_prop $node "phy-mode" $phytype string "pl.dtsi"
            pldt append $node compatible "\ \, \"xlnx,ten-gig-eth-mac\""
        }
        if {$ip_name == "xxv_ethernet"} {
            add_prop $node "managed" "in-band-status" string $dts_file
            set phytype [string tolower [hsi get_property CONFIG.BASE_R_KR $eth_ip]]
            set linerate [hsi get_property CONFIG.LINE_RATE $eth_ip]
            add_prop $node phy-mode "${linerate}g$phytype" string $dts_file
            if {$core == 0} {
                pldt set $node compatible "\"xlnx,xxv-ethernet-1.0\""
            }
            if { $core!= 0 && [llength $eth_node]} {
                set compatible [pldt get $node compatible]
                    set compatible [string trimright $compatible "\""]
                    set compatible [string trimleft $compatible "\""]
                    add_prop $eth_node "compatible" $compatible string "pl.dtsi"
                add_prop $eth_node "managed" "in-band-status" string $dts_file
                add_prop $eth_node "phy-mode" "${linerate}g$phytype" string "pl.dtsi"
            }
        }
        if {$ip_name == "ethernet_1_10_25g"} {
            add_prop $node "managed" "in-band-status" string $dts_file
            set phytype [string tolower [hsi get_property CONFIG.BASE_R_KR $eth_ip]]
            set linerate [hsi get_property CONFIG.LINE_RATE $eth_ip]
            if {$phytype == "1000base-x"} {
                add_prop $node phy-mode "$phytype" string $dts_file
            } else {
                add_prop $node phy-mode "${linerate}g$phytype" string $dts_file
            }
            if {$core == 0} {
                pldt set $node compatible "\"xlnx,ethernet-1-10-25g-2.7\""
            }
            if { $core!= 0 && [llength $eth_node]} {
                set compatible [pldt get $node compatible]
                set compatible [string trimright $compatible "\""]
                set compatible [string trimleft $compatible "\""]
                add_prop $eth_node "compatible" $compatible string "pl.dtsi"
                add_prop $eth_node "managed" "in-band-status" string $dts_file
                if {$phytype == "1000base-x"} {
                    add_prop $eth_node "phy-mode" "$phytype" string $dts_file
                } else {
                    add_prop $eth_node "phy-mode" "${linerate}g$phytype" string "pl.dtsi"
                }
            }
        }
        if {$ip_name == "usxgmii"} {
            pldt set $node compatible "\"xlnx,xxv-usxgmii-ethernet-1.0\""
            # phy-mode is usxgmii in this case ip_name also same
            add_prop $node phy-mode "$ip_name" string "pl.dtsi"
            add_prop $node "xlnx,usxgmii-rate" 1000 int "pl.dtsi"
        }
        set ips [hsi::get_cells -hier $drv_handle]
        foreach ip [get_drivers 1] {
            if {[string compare -nocase $ip $connected_ip] == 0} {
                set target_handle $ip
            }
        }
        set hsi_version [get_hsi_version]
        set ver [split $hsi_version "."]
        set version [lindex $ver 0]
        if {![string_is_empty $connected_ip]} {
            set connected_ipname [hsi get_property IP_NAME $connected_ip]
            if {$connected_ipname == "axi_mcdma" || $connected_ipname == "axi_dma"} {
	    set num_queues [hsi get_property CONFIG.c_num_mm2s_channels $connected_ip]
		    set inhex [format %x $num_queues]
		    set numqueues "/bits/ 16 <0x$inhex>"
		    add_prop $node "xlnx,num-queues" $numqueues noformating "pl.dtsi"
		    if {$version < 2018} {
			 dtg_warning "quotes to be removed or use 2018.1 version for $node param xlnx,num-queues"
		    }
		    set id 1
		    for {set i 2} {$i <= $num_queues} {incr i} {
				set i [format "%x" $i]
				append id "\""
				append id " ,\"" $i
				set i [expr 0x$i]
		    }
		    add_prop $node "xlnx,channel-ids" $id intlist "pl.dtsi"
		if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g"))
            && $core!= 0 && [llength $eth_node]} {
			add_prop $eth_node "xlnx,num-queues" $numqueues noformating $dts_file
			add_prop $eth_node "xlnx,channel-ids" $id intlist $dts_file
		}
                set ipnode [get_node $target_handle]
                set values [pldt getall $ipnode]
                set intr_parent ""
                if {[regexp "interrupt*" $values match]} {
                    set intr_val [pldt get $ipnode interrupts]
                    set intr_val [string trimright $intr_val " >"]
                    set intr_val [string trimleft $intr_val "< "]
                    set intr_parent [pldt get $ipnode interrupt-parent]
                    set intr_parent [string trimright $intr_parent ">"]
                    set intr_parent [string trimleft $intr_parent "<"]
                    set intr_parent [string trimleft $intr_parent "&"]
                    set int_names  [pldt get $ipnode interrupt-names]
                    set names [split $int_names ","]
                    if {[llength $names] >= 1} {
                        set int1 [string trimright [lindex $names 0] "\" "]
                        set int1 [string trimleft $int1 "\""]
                    }
                    if {[llength $names] >= 2} {
                        set int2 [string trimright [lindex $names 1] "\" "]
                        set int2 [string trimleft $int2 "\" "]
                    }
                }
                if {[regexp "interrupt*" $values match]} {
                    if { $hasbuf == "true" && $ip_name == "axi_ethernet"} {
                        set intr_val1 [pldt get $node interrupts]
                        set intr_val1 [string trimright $intr_val1 " >"]
                        set intr_val1 [string trimleft $intr_val1 "< "]
                        lappend intr_val1 $intr_val
                        set intr_name [pldt get $node interrupt-names]
                        append intr_names $intr_name " , \"$int1\" , \"$int2\""
                    } else {
                        set intr_names $int_names
                    }
                }

            set default_dts "pl.dtsi"
            set nodep [get_node $drv_handle]
                if {![string_is_empty $intr_parent]} {
                    if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g"))
                        && $core!= 0 && [llength $eth_node]} {
                        add_prop "${eth_node}" "interrupts" $intr_val intlist $dts_file
                        add_prop "${eth_node}" "interrupt-parent" $intr_parent reference $dts_file
                        add_prop "${eth_node}" "interrupt-names" $intr_names noformating $dts_file
                    } else {
                if { $hasbuf == "true" && $ip_name == "axi_ethernet"} {
                    regsub -all "\{||\t" $intr_val1 {} intr_val1
                    regsub -all "\}||\t" $intr_val1 {} intr_val1
                    set proctype [get_hw_family]
                    if {![regexp "microblaze" $proctype match]} {
                        add_prop "${nodep}" "interrupts" $intr_val1 intlist "pl.dtsi" 1
                    }
                } else {
                    add_prop "${nodep}" "interrupts" $intr_val intlist "pl.dtsi"
                }
                add_prop "${nodep}" "interrupt-parent" $intr_parent reference "pl.dtsi"
                add_prop "${nodep}" "interrupt-names" $intr_names noformating "pl.dtsi" 1
            }
            }
            }
            if {$connected_ipname == "axi_dma" || $connected_ipname == "axi_mcdma"} {
                set proctype [get_hw_family]
                if {![regexp "microblaze" $proctype match]} {
                    set eth_clk_names [pldt get $node clock-names]
                    set eth_clks [pldt get $node clocks]
                    set eth_clks [string trimright $eth_clks ">"]
                    set eth_clks [string trimleft $eth_clks "<"]
                    set eth_clks [string trimleft $eth_clks "&"]
                    set eth_clk_names [split $eth_clk_names " , "]
                    set eth_clkname_len [llength $eth_clk_names]
                    for {set i 0 } {$i < $eth_clkname_len} {incr i} {
                        set trimvar [lindex $eth_clk_names $i]
                        set trimvar [string trimright $trimvar "\""]
                        set trimvar [string trimleft $trimvar "\""]
                        append temp "$trimvar "
                    }
                    if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) && $core == 0} {
                        add_prop "${nodep}" "zclocks" $eth_clks reference "pl.dtsi"
                        set_drv_prop $drv_handle "zclock-names" $temp $node stringlist
                    }
                    if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g"))&& $core != 0} {
                        set eth_clks [pldt get $nodep zclocks]
                        set eth_clk_names [pldt get $nodep zclock-names]
                        set eth_clks [string trimright $eth_clks ">"]
                        set eth_clks [string trimleft $eth_clks "<"]
                        set eth_clks [string trimleft $eth_clks "&"]
                        set eth_clk_names [split $eth_clk_names " , "]
                        set eth_clkname_len [llength $eth_clk_names]
                        set temp ""
                        for {set i 0 } {$i < $eth_clkname_len} {incr i} {
                            set trimvar [lindex $eth_clk_names $i]
                            set trimvar [string trimright $trimvar "\""]
                            set trimvar [string trimleft $trimvar "\""]
                            append temp "$trimvar "
                        }
                    }
                    set eth_clk_names $temp

                    set eth_clkname_len [llength $eth_clk_names]
                    set i 0
                    set dclk ""
                    while {$i < $eth_clkname_len} {
                        set clkname [lindex $eth_clk_names $i]
                        for {set corenum 0} {$corenum < $num_cores} {incr corenum} {
                                if {[string match -nocase $clkname "rx_core_clk_$corenum"]} {
                                        set core_clk_$corenum "rx_core_clk"
                                        set index_$corenum $i
                                }
                                if {[string match -nocase $clkname "s_axi_aclk_$corenum"]} {
                                        set axi_aclk_$corenum "s_axi_aclk"
                                        set axi_index_$corenum $i
                                }
                                if {[string match -nocase $clkname "dclk"]} {
                                        set dclk "dclk"
                                        set dclk_index $i
                                }
                      }
                    incr i
                }
                set eth_clk_len [expr {[llength [split $eth_clks ","]]}]
                set clk_list [split $eth_clks ","]
                set ipnode [get_node $target_handle]
                set clk_names [pldt get $ipnode clock-names]
                set clk_names [split $clk_names " , "]

                set len [llength $clk_names]
                set temp ""
                for {set i 0 } {$i < $len} {incr i} {
                    set trimvar [lindex $clk_names $i]
                    set trimvar [string trimright $trimvar "\""]
                    set trimvar [string trimleft $trimvar "\""]
                    append temp "$trimvar "
                }
                set clk_names $temp
                set clks [pldt get $ipnode clocks]
                append names "$eth_clk_names" "$clk_names"
                set names ""
                append clk  "$eth_clks>," " $clks"
                set clks [string trimright $clks ">"]
                set null ""
                if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g"))  && $core== 0} {
                            if {[llength $dclk]} {
                                append clknames "$core_clk_0 " "$dclk " "$axi_aclk_0"
                            } else {
                                append clknames "$core_clk_0 " "$axi_aclk_0"
                            }
                            append clk_names0 " $clknames" " $clk_names"
                            set index0 [lindex $clk_list $axi_index_0]
                            regsub -all "\>||\t" $index0 {} index0
                            set ini0 [lindex $clk_list $index_0]
                            regsub -all " " $ini0 "" ini0
                            regsub -all "\<&||\t" $ini0 {} ini0
                            if {[llength $dclk]} {
                                set dclk_ini [lindex $clk_list $dclk_index]
                                set dclk_ini [string trim $dclk_ini]
                                if {![string match -nocase "<&*" "$dclk_ini"]} {
                                    set dclk_ini "<&$dclk_ini"
                                }
                                append clkvals  "$ini0, $dclk_ini, $index0>, $clks"
                            } else {
                                append clkvals  "$ini0, $index0>, $clks"
                            }

                            add_prop "${nodep}" "clocks" $clkvals reference "pl.dtsi" 1
                            add_prop "${nodep}" "clock-names" $clk_names0 stringlist "pl.dtsi" 1
                            set clknames1 ""
                        }
                        if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g"))
                             && $core == 1 && [llength $eth_node]} {
                            if {[llength $dclk]} {
                                append clknames1 "$core_clk_1 " "$dclk " "$axi_aclk_1"
                            } else {
                                append clknames1 "$core_clk_1 " "$axi_aclk_1"
                            }
                            append clk_names1 " $clknames1" " $clk_names"
                            set index1 [lindex $clk_list $axi_index_1]
                            regsub -all "\>||\t" $index1 {} index1
                            set ini1 [lindex $clk_list $index_1]
                            regsub -all " " $ini1 "" ini1
                            regsub -all "\<&||\t" $ini1 {} ini1
                            if {[llength $dclk]} {
                                set dclk_ini1 [lindex $clk_list $dclk_index]
                                set dclk_ini1 [string trim $dclk_ini1]
                                if {![string match -nocase "<&*" "$dclk_ini1"]} {
                                    set dclk_ini1 "<&$dclk_ini1"
                                }
                                append clkvals1  "$ini1, $dclk_ini1, $index1>, $clks"
                            } else {
                                append clkvals1  "$ini1, $index1>, $clks"
                            }
                            add_prop "${eth_node}" "clocks" $clkvals1 reference "pl.dtsi" 1
                            add_prop "${eth_node}" "clock-names" $clk_names1 stringlist "pl.dtsi" 1
                            set clk_names1 ""
                            set clkvals1 ""
                        }
                        if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g"))
                             && $core == 2 && [llength $eth_node]} {
                            if {[llength $dclk]} {
                                append clknames2 "$core_clk_2 " "$dclk " "$axi_aclk_2"
                            } else {
                                append clknames2 "$core_clk_2 " "$axi_aclk_2"
                            }
                            append clk_names2 " $clknames2" " $clk_names"
                            set index2 [lindex $clk_list $axi_index_2]
                            regsub -all "\>||\t" $index2 {} index2
                            set ini2 [lindex $clk_list $index_2]
                            regsub -all " " $ini2 "" ini2
                            regsub -all "\<&||\t" $ini2 {} ini2
                            if {[llength $dclk]} {
                                set dclk_ini2 [lindex $clk_list $dclk_index]
                                set dclk_ini2 [string trim $dclk_ini2]
                                if {![string match -nocase "<&*" "$dclk_ini2"]} {
                                    set dclk_ini2 "<&$dclk_ini2"
                                }
                                append clkvals2  "$ini2, $dclk_ini2, $index2>, $clks"
                            } else {
                                append clkvals2  "$ini2, $index2>, $clks"
                            }
                            append clk_label2 $drv_handle "_" $core
                            add_prop "${eth_node}" "clocks" $clkvals2 reference "pl.dtsi" 1
                            add_prop "${eth_node}" "clock-names" $clk_names2 stringlist "pl.dtsi" 1
                            set clk_names2 ""
                            set clkvals2 ""
                        }
                        if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) &&
                            $core == 3 && [llength $eth_node]} {
                            if {[llength $dclk]} {
                                append clknames3 "$core_clk_3 " "$dclk " "$axi_aclk_3"
                            } else {
                                append clknames3 "$core_clk_3 " "$axi_aclk_3"
                            }
                            append  clk_names3 " $clknames3" " $clk_names"
                            set index3 [lindex $clk_list $axi_index_3]
                            regsub -all "\>||\t" $index3 {} index3
                            set ini [lindex $clk_list $index_3]
                            regsub -all " " $ini "" ini
                            regsub -all "\<&||\t" $ini {} ini
                            if {[llength $dclk]} {
                                set dclk_ini3 [lindex $clk_list $dclk_index]
                                set dclk_ini3 [string trim $dclk_ini3]
                                if {![string match -nocase "<&*" "$dclk_ini3"]} {
                                    set dclk_ini3 "<&$dclk_ini3"
                                }
                                append clkvals3 "$ini, $dclk_ini3, $index3>, $clks"
                            } else {
                                append clkvals3 "$ini, $index3>, $clks"
                            }
                            append clk_label3 $drv_handle "_" $core
                            add_prop "${eth_node}" "clocks" $clkvals3 reference "pl.dtsi" 1
                            add_prop "${eth_node}" "clock-names" $clk_names3 stringlist "pl.dtsi" 1
                            set clk_names3 ""
                            set clkvals3 ""
                        }
                    }
                }
            }
        if {(($ip_name == "xxv_ethernet") || ($ip_name == "ethernet_1_10_25g")) &&
            $core!= 0 && [llength $eth_node]} {
                axi_ethernet_gen_drv_prop_eth_ip $drv_handle $eth_node
        }
        gen_dev_ccf_binding $drv_handle "s_axi_aclk"

        set eoe_tcl_file "$path/axi_eoe/data/axi_eoe.tcl"
        if {[file exists $eoe_tcl_file]} {
            source $eoe_tcl_file
            set tx_pin "axis_tx_$core"
            set fifo_periph [get_connected_stream_ip [hsi get_cells -hier $eth_ip] $tx_pin]
            if {[llength $fifo_periph]} {
                 if {[hsi get_property IP_NAME [hsi::get_cells -hier $fifo_periph]] == "axis_data_fifo"} {
                       set eoe_ip [get_connected_stream_ip [hsi get_cells -hier $fifo_periph] "S_AXIS"]
                       if {[hsi get_property IP_NAME [hsi::get_cells -hier $eoe_ip]] == "ethernet_offload"} {
                             set mcdma_ip [get_connected_stream_ip [hsi get_cells -hier $eoe_ip] "s2mm_axis"]
                             set eth_dma [hsi get_property CONFIG.C_ETHERNET_DMA $mcdma_ip]
                             if {$eth_dma == 1} {
                                 set target_node [expr {$core == 0 ? $node : [lindex $xxv_list $core]}]
                                 if {[info exists target_node] && $target_node ne ""} {
                                      axi_eoe_generate $eoe_ip $target_node $dts_file
                                 } else {
                                      error "ERROR: Ethernet Offload is not Supported"
                                 }
                             }
                       }
                 }
            }
        }
      }
    }

    proc axi_ethernet_pcspma_phy_node {slave} {
        set phyaddr [hsi get_property CONFIG.PHYADDR $slave]
        set phymode "phy$phyaddr"

        return "$phyaddr $phymode"
    }

    proc axi_ethernet_get_checksum {value} {
            if {[string compare -nocase $value "None"] == 0} {
                    set value 0
            } elseif {[string compare -nocase $value "Partial"] == 0} {
                    set value 1
            } else {
                    set value 2
            }

            return $value
    }

    proc axi_ethernet_get_memrange {value} {
        set values [split $value "k"]
        lassign $values value1 value2

        return [expr $value1 * 1024]
    }

    proc axi_ethernet_get_phytype {value} {
            if {[string compare -nocase $value "MII"] == 0} {
                    set value 0
            } elseif {[string compare -nocase $value "GMII"] == 0} {
                    set value 1
            } elseif {[string compare -nocase $value "RGMII"] == 0} {
                    set value 3
            } elseif {[string compare -nocase $value "SGMII"] == 0} {
                    set value 4
            } else {
                    set value 5
            }

            return $value
    }

    proc axi_ethernet_gen_hierip_params {drv_handle} {
        set prop_name_list [axi_ethernet_deault_parameters $drv_handle]
        ip2drv_prop $drv_handle $prop_name_list
    }

    proc axi_ethernet_deault_parameters {ip_handle {dont_generate ""}} {
        set par_handles [get_ip_conf_prop_list $ip_handle "CONFIG.*"]
        set valid_prop_names {}
        foreach par $par_handles {
                regsub -all {CONFIG.} $par {} tmp_par
                # Ignore some parameters that are always handled specially
                switch -glob $tmp_par {
                        $dont_generate - \
                        "Component_Name" - \
            "DIFFCLK_BOARD_INTERFACE" - \
            "EDK_IPTYPE" - \
            "ETHERNET_BOARD_INTERFACE" - \
            "Include_IO" - \
            "PHY_TYPE" - \
            "RXCSUM" - \
            "TXCSUM" - \
            "TXMEM" - \
            "RXMEM" - \
            "PHYADDR" - \
            "C_BASEADDR" - \
            "C_HIGHADDR" - \
            "processor_mode" - \
            "ENABLE_AVB" - \
            "ENABLE_LVDS" - \
            "Enable_1588_1step" - \
            "Enable_1588" - \
            "speed_1_2p5" - \
            "lvdsclkrate" - \
            "gtrefclkrate" - \
            "drpclkrate" - \
            "Enable_Pfc" - \
            "Frame_Filter" - \
            "MCAST_EXTEND" - \
            "MDIO_BOARD_INTERFACE" - \
            "Number_of_Table_Entries" - \
            "PHYRST_BOARD_INTERFACE" - \
            "RXVLAN_STRP" - \
            "RXVLAN_TAG" - \
            "RXVLAN_TRAN" - \
            "TXVLAN_STRP" - \
            "TXVLAN_TAG" - \
            "TXVLAN_TRAN" - \
            "SIMULATION_MODE" - \
            "Statistics_Counters" - \
            "Statistics_Reset" - \
            "Statistics_Width" - \
            "SupportLevel" - \
            "TIMER_CLK_PERIOD" - \
            "Timer_Format" - \
            "SupportLevel" - \
            "TransceiverControl" - \
            "USE_BOARD_FLOW" - \
                        "HW_VER" { } \
                        default {
                                lappend valid_prop_names $par
                        }
                }
        }
        return $valid_prop_names
    }

    proc axi_ethernet_gen_phy_node args {
        set mdio_node [lindex $args 0]
        set phy_name [lindex $args 1]
        set phya [lindex $args 2]
        set drv  [lindex $args 3]

        set phy_node [create_node -l $drv$phy_name -n phy -u $phya -p $mdio_node -d "pl.dtsi"]
        add_prop "${phy_node}" "reg" $phya int "pl.dtsi"
        add_prop "${phy_node}" "device_type" "ethernet-phy" string "pl.dtsi"

        return $phy_node
    }

    proc axi_ethernet_is_ethsupported_target {connected_ip} {
        set connected_ipname [hsi get_property IP_NAME $connected_ip]
        if {$connected_ipname == "axi_dma" || $connected_ipname == "axi_fifo_mm_s" || $connected_ipname == "axi_mcdma"} {
          return "true"
        } else {
          return "false"
        }
    }

    proc axi_ethernet_get_targetip {ip} {
        global ddrv_handle
        if {[string_is_empty $ip] != 0} {
           return
        }
        set p2p_busifs_i [hsi::get_intf_pins -of_objects $ip -filter "TYPE==INITIATOR || TYPE==MASTER"]
        set target_periph ""
        foreach p2p_busif $p2p_busifs_i {
            set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $ip]]
            if {$ip_name == "ethernet_offload" && $p2p_busif == "tx_axis"} {
                   continue;
            }

            set busif_name [string toupper [hsi get_property NAME  $p2p_busif]]
            set conn_busif_handle [get_connected_intf $ip $busif_name]
            if {[string_is_empty $conn_busif_handle] != 0} {
                continue
            }
        set target_periph [hsi::get_cells -of_objects $conn_busif_handle]
        set cell_name [hsi::get_cells -hier $target_periph]
        set target_name [hsi get_property IP_NAME [hsi::get_cells -hier $target_periph]]
        if {$target_name == "axis_data_fifo" || $target_name == "Ethernet_filter"} {
            #set target_periph [hsi::get_cells -of_objects $conn_busif_handle]
            set master_slaves [hsi::get_intf_pins -of [hsi::get_cells -hier $cell_name]]
            if {[llength $master_slaves] == 0} {
                return
            }
            set master_intf ""
            foreach periph_intf $master_slaves {
                set prop [hsi get_property TYPE $periph_intf]
                if {$prop == "INITIATOR"} {
                    set master_intf $periph_intf
                }
            }
            if {[llength $master_intf] == 0} {
                return
            }
            set intf [hsi::get_intf_pins -of_objects $cell_name $master_intf]
            set intf_net [hsi::get_intf_nets -of_objects $intf]
            set intf_pins [get_other_intf_pin $intf_net $intf]
            foreach intf $intf_pins {
                set target_intf [hsi::get_intf_pins -of_objects $intf_net -filter "TYPE==TARGET" $intf]
                if {[llength $target_intf]} {
                    set connected_ip [hsi::get_cells -of_objects $target_intf]
                    if {[llength $connected_ip]} {
                            set cell [hsi::get_cells -hier $connected_ip]
                            set target_name [hsi get_property IP_NAME [hsi::get_cells -hier $cell]]
                            if {$target_name == "axis_data_fifo"} {
                                return [axi_ethernet_get_targetip $connected_ip]
                            }
                            if {![string_is_empty $connected_ip] && [axi_ethernet_is_ethsupported_target $connected_ip] == "true"} {
                                return $connected_ip
                            }
                       } else {
                            dtg_warning "$ddrv_handle connected ip is NULL for the target intf $target_intf"
                    }
                } else {
                        dtg_warning "$ddrv_handle target interface is NULL for the intf pin $intf"
                }
            }
        }
        }
        return $target_periph
    }

    proc axi_ethernet_get_connectedip {intf} {
        global rxethmem
        if { [llength $intf]} {
        set connected_ip ""
        set intf_net [hsi::get_intf_nets -of_objects $intf ]
        if { [llength $intf_net]  } {
            set target_intf [get_other_intf_pin $intf_net $intf]
            if { [llength $target_intf] } {
                set connected_ip [hsi::get_cells -of_objects $target_intf]
                if {[llength $connected_ip]} {
                    set target_ipname [hsi get_property IP_NAME $connected_ip]
                    if {$target_ipname == "ila"} {
                            return
                    }
                    if {$target_ipname == "axis_data_fifo"} {
                            set fifo_width_bytes [hsi get_property CONFIG.TDATA_NUM_BYTES $connected_ip]
                            if {[string_is_empty $fifo_width_bytes]} {
                                set fifo_width_bytes 1
                            }
                            set rxethmem [hsi get_property CONFIG.FIFO_DEPTH $connected_ip]
                            # FIFO can be other than 8 bits, and we need the rxmem in bytes
                            set rxethmem [expr $rxethmem * $fifo_width_bytes]
                    } else {
                        # In 10G MAC case if the rx_stream interface is not connected to
                        # a Stream-fifo set the rxethmem value to a default jumbo MTU size
                        set rxethmem 9600
                }
                } else {
                        dtg_warning "$drv_handle connected_ip is NULL for the target_intf $target_intf"
                }
            }
        if {[string_is_empty $connected_ip]} {
            return ""
        }
            set target_ip [axi_ethernet_is_ethsupported_target $connected_ip]
            if { $target_ip == "true"} {
                return $connected_ip
            } else {
                set i 0
                set retries 5
                # When AXI Ethernet Configured in Non-Buf mode or In case of 10G MAC
                # The Ethernet MAC won't directly got connected to fifo or dma
                # We need to traverse through stream data fifo's and axi interconnects
                # Inorder to find the target IP(AXI DMA or AXI FIFO)
                while {$i < $retries} {
                    set target_ip "false"
                    set target_periph [axi_ethernet_get_targetip $connected_ip]
                    if {[string_is_empty $target_periph] == 0} {
                        set target_ip [axi_ethernet_is_ethsupported_target $target_periph]
                    }
                    if { $target_ip == "true"} {
                        return $target_periph
                    }
                    set connected_ip $target_periph
                    incr i
                }
                dtg_warning "Couldn't find a valid target_ip Please cross check hw design"
            }
            }
        }
    }

    proc axi_ethernet_generate_reg_property {node ip_mem_handles num} {
        if {[llength $ip_mem_handles] == 0} {
            return
        }
        set base [string tolower [hsi get_property BASE_VALUE [lindex $ip_mem_handles $num]]]
        set high [string tolower [hsi get_property HIGH_VALUE [lindex $ip_mem_handles $num]]]
        set size [format 0x%x [expr {${high} - ${base} + 1}]]

        set proctype [get_hw_family]
        if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                set temp $base
                set temp [string trimleft [string trimleft $temp 0] x]
                set len [string length $temp]
                set rem [expr {${len} - 8}]
                set high_base "0x[string range $temp $rem $len]"
                set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                set low_base [format 0x%08x $low_base]
                if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                        set temp $size
                        set temp [string trimleft [string trimleft $temp 0] x]
                        set len [string length $temp]
                        set rem [expr {${len} - 8}]
                        set high_size "0x[string range $temp $rem $len]"
                        set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
                        set low_size [format 0x%08x $low_size]
                        set reg "$low_base $high_base $low_size $high_size"
                } else {
			set reg "$low_base $high_base 0x0 $size"
                }
        } else {
		if {[string match -nocase $proctype "microblaze"] } {
			set reg "$base $size"
                } else {
			set reg "0x0 $base 0x0 $size"
                }
        }
        add_prop $node "reg" $reg hexlist "pl.dtsi"
        set label [split $node ":"]
        set label [lindex $label 0]
        set design_handles [hsi::get_cells -hier]
        if {[lsearch $design_handles $label] >= 0} {
            return
        }
        set family [get_hw_family]
        if {[is_zynqmp_platform $family]} {
            set_memmap $label a53 $reg
            set_memmap $label pmu $reg
        } else {
            set_memmap $label a53 $reg
        }
        set r5_procs [hsi::get_cells -hier -filter {IP_NAME==psv_cortexr5 || IP_NAME==psu_cortexr5}]
        set_memmap $label [lindex $r5_procs 0] $reg
        set_memmap $label [lindex $r5_procs 1] $reg
    }

    proc axi_ethernet_gen_drv_prop_eth_ip {drv_handle ipname} {
        set prop_name_list [default_parameters $drv_handle]
        foreach prop_name ${prop_name_list} {
            axi_ethernet_ip2_prop $ipname $prop_name $drv_handle
        }
    }

    proc axi_ethernet_ip2_prop {ip_name ip_prop_name drv_handle} {
        set drv_prop_name $ip_prop_name
        regsub -all {CONFIG.C_} $drv_prop_name {xlnx,} drv_prop_name
        regsub -all {_} $drv_prop_name {-} drv_prop_name
        set drv_prop_name [string tolower $drv_prop_name]
        set prop [hsi get_property ${ip_prop_name} [hsi::get_cells -hier $drv_handle]]
        if {[llength $prop]} {
            if {$prop != "-1" && [llength $prop] !=0} {
                if {[regexp -nocase {0x([0-9a-f])} $prop match]} {
                    set type "hexint"
                } elseif {[string is integer -strict $prop]} {
                    set type "int"
                } elseif {[string is boolean -strict $prop]} {
                    set type "boolean"
                } elseif {[string is wordchar -strict $prop]} {
                    set type "string"
                } else {
                    set type "mixed"
                }
                add_prop $ip_name "$drv_prop_name" $prop $type "pl.dtsi"
            }
        }
    }


