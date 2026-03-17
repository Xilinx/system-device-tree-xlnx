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
    proc tsn_generate {drv_handle} {
        set proc_type [get_hw_family]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        set eth_ip [hsi::get_cells -hier $drv_handle]
        set ip_name [hsi get_property IP_NAME $eth_ip]

        global tsn_ep_node
        global tsn_emac0_node
        global tsn_emac1_node
        global tsn_ex_ep_node
        set tsn_ep_node "tsn_ep"
        set tsn_emac0_node "tsn_emac_0"
        set tsn_emac1_node "tsn_emac_1"
        set tsn_ex_ep_node "tsn_ex_ep"
        set end_point_ip ""
        set end1 ""
        set connectrx_ip ""
        set connecttx_ip ""
        array set queue_channel_map {}
        set channel_type ""
	set compatible [pldt get $node "compatible"]
	if {$compatible eq "xlnx,tsn-endpoint-ethernet-mac-1.0"} {
		pldt set $node compatible "\"xlnx,tsn-endpoint-ethernet-mac-1.0\""
	} else {
		pldt set $node compatible "\"xlnx,tsn-endpoint-ethernet-mac-2.0\""
	}
        set num_priorites [hsi get_property CONFIG.NUM_PRIORITIES $eth_ip]
        if {$num_priorites > 3} {
            set start_i [expr {8 - $num_priorites}]
            for {set i $start_i} {$i < 8} {incr i} {
                set j [expr {$i - $start_i}]
                set connected_ip [get_connected_stream_ip $eth_ip "tx_axis_pri_$i"]
                set connected_intf [get_connected_intf $eth_ip "tx_axis_pri_$i"]
                # Extract number from M05_AXIS (M followed by digits)
                if {[regexp {M(\d+)_AXIS} $connected_intf match channel]} {
                    set channel [expr {$channel + 1}]
                    set channel_type "MXX"
                } elseif {[string equal $connected_intf "M_AXIS_RES_INTF"]} {
                    set channel 1
                    set channel_type "M_AXIS"
                } elseif {[string equal $connected_intf "M_AXIS_ST_INTF"]} {
                    set channel 0
                    set channel_type "M_AXIS"
                } elseif {[string equal $connected_intf "M_AXIS_BE_INTF"]} {
                    set channel 2
                    set channel_type "M_AXIS"
                } else {
                    puts "Queue $i has no valid connection"
                }
                if {[llength $connected_ip] != 0} {
                    set end1_ip [get_connected_stream_ip $connected_ip "S00_AXIS"]
                    if {[llength $end1_ip] != 0} {
                        set end1 [lappend end1 $end1_ip]
                    } else {
                        set connecttx_ip [lappend connecttx_ip $connected_ip]
                    }
                }
                set connect_ip [get_connected_stream_ip $eth_ip "rx_axis_pri_$i"]
                if {[llength $connect_ip] != 0} {
                    set end_ip [get_connected_stream_ip $connect_ip "M00_AXIS"]
                    if {[llength $end_ip] != 0} {
                        set end_point_ip [lappend end_point_ip $end_ip]
                    } else {
                        set connectrx_ip [lappend connectrx_ip $connect_ip]
                    }
                }
                set queue_channel_map($j) "$channel_type:$channel"
            }
        }
        if {$num_priorites <= 3} {
            set tx_pin_names "tx_axis_be tx_axis_res tx_axis_st"
            foreach  tx_pin $tx_pin_names {
                set connected_ip [get_connected_stream_ip $eth_ip "$tx_pin"]
                if {[llength $connected_ip] != 0} {
                    set end1_ip [get_connected_stream_ip $connected_ip "S00_AXIS"]
                    if {[llength $end1_ip] != 0} {
                        set end1 [lappend end1 $end1_ip]
                    } else {
                        set connecttx_ip [lappend connecttx_ip $connected_ip]
                    }
                }
            }
            set rx_pin_names "rx_axis_be rx_axis_res rx_axis_st"
            foreach rx_pin  $rx_pin_names {
                set connect_ip [get_connected_stream_ip $eth_ip "$rx_pin"]
                if {[llength $connect_ip] != 0} {
                    set end_ip [get_connected_stream_ip $connect_ip "M00_AXIS"]
                    if {[llength $end_ip]!= 0} {
                        set end_point_ip [lappend end_point_ip $end_ip]
                    } else {
                        set connectrx_ip [lappend connectrx_ip $connect_ip]
                    }
                }
            }
        }
        foreach ip [get_drivers 1] {
                if {[string compare -nocase $ip $end_ip] == 0} {
                        set target_handle $ip
                }
        }
        set connectedrx_ipname [hsi get_property IP_NAME $end_ip]
        set id 1
        set queue ""
        if {$connectedrx_ipname == "axi_mcdma"} {
                set num_queues [hsi get_property CONFIG.c_num_s2mm_channels $end_ip]
                set rx_queues  [hsi get_property CONFIG.c_num_mm2s_channels $end_ip]
                if {$num_queues > $rx_queues} {
                        set queue $num_queues
                } else {
                        set queue $rx_queues
                }
                for {set i 2} {$i <= $num_queues} {incr i} {
                        set i [format "%x" $i]
                        append id " " $i
                        set i [expr 0x$i]
                }
        }

        set ipnode [get_node $target_handle]
        lassign [get_interrupt_properties $ipnode] intr_val intr_parent intr_names

        set int1 $intr_val
        set int2 $intr_parent
        set int3 $intr_names

        set inhex [format %x $queue]
        append queues "/bits/ 16 <0x$inhex>"

        set baseaddr [get_baseaddr $eth_ip no_prefix]
        set num_queues [hsi get_property CONFIG.NUM_PRIORITIES $eth_ip]
        if {[is_zynqmp_platform $proc_type]} {
                add_prop $node "#address-cells" 2 int $dts_file
                add_prop $node "#size-cells" 2 int $dts_file
                add_prop "${node}" "ranges" boolean $dts_file
        } elseif {[string match -nocase $proc_type "zynq"]} {
                add_prop $node "#address-cells" 1 int $dts_file
                add_prop $node "#size-cells" 1 int $dts_file
                add_prop "${node}" "ranges" boolean $dts_file
        }
        set freq ""
        set clk [hsi::get_pins -of_objects $eth_ip "S_AXI_ACLK"]
        if {[llength $clk] } {
                set freq [hsi get_property CLK_FREQ $clk]
        }
        set inhex [format %x $num_queues]
        append numqueues "/bits/ 16 <0x$inhex>"
        set node_intr [get_interrupt_properties $node]
        lassign $node_intr intr_val intr_parent intr_names

        set mac0intr ""
        set mac1intr ""
        set ep_sched_irq ""
        foreach intr1 $intr_names {
                set num [regexp -all -inline -- {[0-9]+} $intr1]
                if {$num == 1} {
                        lappend mac0intr $intr1
                }
                if {$num == 2 && ![string match -nocase $intr1 "interrupt_ptp_timer_2"]} {
                        lappend mac1intr $intr1
                }
                if {[string match -nocase $intr1 "interrupt_ptp_timer"] || [string match -nocase $intr1 "interrupt_ptp_timer_2"]} {
                        lappend mac0intr $intr1
                }
                if {[string match -nocase $intr1 "tsn_ep_scheduler_irq"]} {
                        lappend ep_sched_irq $intr1
                }
        }
        set switch_present ""
        set periph_list [hsi::get_cells -hier]
        set tsn_inst_name [hsi::get_cells -filter {IP_NAME =~ "*tsn*"}]
        foreach periph $periph_list {
                if {[string match -nocase "${tsn_inst_name}_switch_core_top_0" $periph] } {
                        set switch_offset [hsi get_property CONFIG.SWITCH_OFFSET $eth_ip]
                        set high_addr [hsi get_property CONFIG.C_HIGHADDR $eth_ip]
                        set one 0x1
                        set switch_present 0x1
                        set switch_addr [format %08x [expr 0x$baseaddr + $switch_offset]]
                        set switch_size [format %08x [expr $high_addr - 0x$switch_addr]]
                        set switch_size [format %08x [expr 0x${switch_size} + 1]]
                        tsn_gen_switch_node $periph $switch_addr $switch_size $numqueues $node $drv_handle $proc_type $eth_ip
                }
                if {[string match -nocase "${tsn_inst_name}" $periph] } {
                        set baseaddr [get_baseaddr $eth_ip no_prefix]
                        set tmac0_size [hsi get_property CONFIG.TEMAC_1_SIZE $eth_ip]
                        if { $switch_present != 1 } {
                                tsn_gen_mac0_node $periph $baseaddr $tmac0_size $node $proc_type $drv_handle $numqueues $freq $intr_parent $mac0intr $eth_ip $queues $id $end1 $end_point_ip $connectrx_ip $connecttx_ip $tsn_inst_name
                        } else {
                                set end_point_ip ""
                                set connectrx_ip ""
                                set connecttx_ip ""
                                tsn_gen_mac0_node $periph $baseaddr $tmac0_size $node $proc_type $drv_handle $numqueues $freq $intr_parent $mac0intr $eth_ip $queues $id $end1 $end_point_ip $connectrx_ip $connecttx_ip $tsn_inst_name
                        }
                }
                if {[string match -nocase "${tsn_inst_name}_tsn_temac_2" $periph] } {
                        set baseaddr [get_baseaddr $eth_ip no_prefix]
                        set tmac1_offset [hsi get_property CONFIG.TEMAC_2_OFFSET $eth_ip]
                        set tmac1_size [hsi get_property CONFIG.TEMAC_2_SIZE $eth_ip]
                        set addr_off [format %08x [expr 0x$baseaddr + $tmac1_offset]]
                        tsn_gen_mac1_node $periph $addr_off $tmac1_size $numqueues $intr_parent $node $drv_handle $proc_type $freq $eth_ip $mac1intr $baseaddr $queues $tsn_inst_name
                }
                if {[string match -nocase "${tsn_inst_name}_tsn_endpoint_block_0" $periph]} {
                        set ep_offset [hsi get_property CONFIG.EP_SCHEDULER_OFFSET $eth_ip]
                        if {[llength $ep_offset] != 0} {
                                set ep_addr [format %08x [expr 0x$baseaddr + $ep_offset]]
                                set ep_size [hsi get_property CONFIG.EP_SCHEDULER_SIZE $eth_ip]
                                if { $switch_present == 1 } {
                                        tsn_gen_ep_node $periph $ep_addr $ep_size $numqueues $node $drv_handle $proc_type $ep_sched_irq $eth_ip $intr_parent $int3 $int1 $id $end1 $end_point_ip $connectrx_ip $connecttx_ip
                                } else {
                                        set end_point_ip ""
                                        set connectrx_ip ""
                                        set connecttx_ip ""
                                        tsn_gen_ep_node $periph $ep_addr $ep_size $numqueues $node $drv_handle $proc_type $ep_sched_irq $eth_ip $intr_parent $int3 $int1 $id $end1 $end_point_ip $connectrx_ip $connecttx_ip
                                }
                        }
                }
        }
        tsn_gen_tx_config_node queue_channel_map $dts_file $node
    }

    # Function to extract and format interrupt properties
    proc get_interrupt_properties {node} {
        set values [pldt getall $node]
        set intr_parent ""
        set intr_val ""
        set intr_names ""

        if {[regexp "interrupt*" $values match]} {
            set intr_val [pldt get $node interrupts]
            set intr_val [string trim $intr_val "< >"]

            set intr_parent [pldt get $node interrupt-parent]
            set intr_parent [string trim $intr_parent "<>&"]

            set intr_names [pldt get $node interrupt-names]
            set names [split $intr_names ","]
            set intr_names ""

            foreach name $names {
                set name [string trim $name "\" "]
                append intr_names "$name "
            }
        set intr_names [string trim $intr_names]
    }
    return [list $intr_val $intr_parent $intr_names]
    }

    #The below addresses are derived based on the assumption that an Ethernet FMC card is connected.
    #If the user connects a different PHY, they must manually update the PHY node accordingly.
    proc tsn_ethernetfmc_phy_node {slave tsn_inst_name} {
        if {[string match -nocase $slave "${tsn_inst_name}_tsn_temac_2"]} {
                set phyaddr "2"
        } else {
                set phyaddr "1"
        }
        set phymode "phy$phyaddr"
        return "$phyaddr $phymode"
    }

    #This code is being added to support backward compatibility with DTG.
    #Here, #PHY1 and #PHY2 are hardcoded to temac1 and temac2, respectively.
    proc tsn_gen_phy_node args {
        set mdio_node [lindex $args 0]
        set phy_name [lindex $args 1]
        set phya [lindex $args 2]
        set dts_file [lindex $args 3]
        set phy_node [create_node -l ${phy_name} -n phy -u $phya -p $mdio_node -d $dts_file]
        add_prop "${phy_node}" "reg" 0 int $dts_file
        add_prop "${phy_node}" "device_type" "ethernet-phy" string $dts_file
        return $phy_node
    }

    proc tsn_gen_tx_config_node {queue_channel_map dts_file node} {
       upvar 1 $queue_channel_map queue_map
       set tx_config_node [create_node -l "tsn_tx_config" -n "tx-queues-config" -p $node -d $dts_file]
        # Get the number of queues from the array (number of keys)
        set num_queues [array size queue_map]
        add_prop $tx_config_node "xlnx,num-tx-queues" $num_queues int $dts_file
        foreach queue [lsort -integer [array names queue_map]] {
            set queue_node [create_node -l "queue$queue" -n "queue$queue" -p $tx_config_node -d $dts_file]
            set value $queue_map($queue)
            set parts [split $value ":"]
            set type [lindex $parts 0]
            set channel [lindex $parts 1]
            add_prop $queue_node "xlnx,dma-channel-num" $channel int $dts_file
            if {[string equal $type "M_AXIS"]} {
                add_prop $queue_node "xlnx,is-tadma" boolean $dts_file
            }
        }
        return $tx_config_node
    }
    proc tsn_gen_ep_node {periph ep_addr ep_size numqueues parent_node drv_handle proc_type ep_sched_irq eth_ip intr_parent int3 int1 id end1 end_point_ip connectrx_ip connecttx_ip} {
        global tsn_ep_node
        set dts_file [set_drv_def_dts $drv_handle]
        set ep_node [create_node -n "tsn_ep" -l $tsn_ep_node -u $ep_addr -p $parent_node -d $dts_file]
        if {[string match -nocase $proc_type "zynq"]} {
                set ep_reg "0x$ep_addr $ep_size"
        } else {
                set ep_reg "0x0 0x$ep_addr 0x0 $ep_size"
        }
        foreach intr $int3 {
                lappend ep_sched_irq $intr
        }
        if {[llength $ep_sched_irq] != 0} {
                set intr_num [get_intr_id $eth_ip [lindex $ep_sched_irq 0]]
        }
        foreach int $int1 {
                lappend intr_num $int
        }
        add_prop "${ep_node}" "interrupt-names" $ep_sched_irq stringlist $dts_file
        add_prop ${ep_node} "interrupts" $intr_num intlist $dts_file
        add_prop "${ep_node}" "interrupt-parent" $intr_parent reference $dts_file
        add_prop "${ep_node}" "reg" $ep_reg hexlist $dts_file
        add_prop "${ep_node}" "compatible" "xlnx,tsn-ep" string $dts_file
        add_prop "${ep_node}" "xlnx,num-tc" $numqueues noformating $dts_file
        add_prop "${ep_node}" "xlnx,channel-ids" $id stringlist $dts_file
        set mac_addr "00 0A 35 00 01 05"
        add_prop $ep_node "local-mac-address" ${mac_addr} hexbytesequence $dts_file
        add_prop "$ep_node" "xlnx,eth-hasnobuf" boolean $dts_file
	add_prop "$ep_node" "xlnx,tsn-tx-config" "tsn_tx_config" reference $dts_file
        global tsn_ex_ep_node
        set tsn_ex_ep [hsi get_property CONFIG.EN_EP_PORT_EXTN $eth_ip]
        if {[string match -nocase $tsn_ex_ep "true"]} {
                set tsn_ex_ep_node [create_node -n "tsn_ex_ep" -l $tsn_ex_ep_node -p $parent_node -d $dts_file]
                add_prop "${tsn_ex_ep_node}" "compatible" "xlnx,tsn-ex-ep" string $dts_file
                set mac_addr "00 0A 35 00 01 06"
                set en_pkt_switch [hsi get_property CONFIG.EN_EP_PKT_SWITCH $eth_ip]
                if {[string match -nocase $en_pkt_switch "true"]} {
                        add_prop "$tsn_ex_ep_node" "packet-switch" 1 int $dts_file
                }
                add_prop $tsn_ex_ep_node "local-mac-address" ${mac_addr} hexbytesequence $dts_file
                add_prop "$tsn_ex_ep_node" "tsn,endpoint" $tsn_ep_node reference $dts_file
        }
        set len [llength $end1]
        for {set len_index 0} {$len_index < $len} {incr len_index} {
                if {$len_index == "0"} {
                        set ref_id [lindex $end1 $len_index]
                } else {
                        append ref_id ">, <&[lindex $end1 $len_index]"
                }
        }
        set len3 [llength $connecttx_ip]
        for {set len3_index 0} {$len3_index < $len3} {incr len3_index} {
                if {$len3_index == "0" && $len == "0"} {
                        set ref_id [lindex $connecttx_ip $len3_index]
                } else {
                        append ref_id ">, <&[lindex $connecttx_ip $len3_index]"
                }
        }
        if {$len || $len3} {
            add_prop "${ep_node}" "axistream-connected-tx" "$ref_id" reference $dts_file
        }

        set len1 [llength $end_point_ip]
        for {set len1_index 0} {$len1_index < $len1} {incr len1_index} {
                if {$len1_index == "0"} {
                        set ref_id [lindex $end_point_ip $len1_index]
                } else {
                        append ref_id ">, <&[lindex $end_point_ip $len1_index]"
                }
        }

        set len2 [llength $connectrx_ip]
        for {set len2_index 0} {$len2_index < $len2} {incr len2_index} {
                if {$len1 == "0" && $len2_index == "0"} {
                        set ref_id [lindex $connectrx_ip $len2_index]
                } else {
                        append ref_id ">, <&[lindex $connectrx_ip $len2_index]"
                }
        }

        if {$len1 > 0 || $len2 > 0} {
            add_prop "${ep_node}" "axistream-connected-rx" "$ref_id" reference $dts_file
        }
    }

    proc tsn_gen_switch_node {periph addr size numqueues parent_node drv_handle proc_type eth_ip} {
        set dts_file [set_drv_def_dts $drv_handle]
        set switch_node [create_node -n "tsn_switch" -l epswitch -u $addr -p $parent_node -d $dts_file]
        set hwaddr_learn [hsi get_property CONFIG.EN_HW_ADDR_LEARNING $eth_ip]
        set mgmt_tag [hsi get_property CONFIG.EN_INBAND_MGMT_TAG $eth_ip]
        set en_pkt_switch [hsi get_property CONFIG.EN_EP_PKT_SWITCH $eth_ip]
        if {[string match -nocase $proc_type "zynq"]} {
                set switch_reg "0x$addr 0x$size"
        } else {
                set switch_reg "0x0 0x$addr 0x0 0x$size"
        }
        add_prop "${switch_node}" "reg" $switch_reg hexlist $dts_file
        add_prop "${switch_node}" "compatible" "xlnx,tsn-switch" string $dts_file
        add_prop "${switch_node}" "xlnx,num-tc" $numqueues noformating $dts_file
        if {[string match -nocase $hwaddr_learn "true"]} {
                add_prop "${switch_node}" "xlnx,has-hwaddr-learning" boolean $dts_file
        }
        if {[string match -nocase $mgmt_tag "true"]} {
                add_prop "${switch_node}" "xlnx,has-inband-mgmt-tag" boolean $dts_file
        }
        set inhex [format %x 3]
        append numports "/bits/ 16 <0x$inhex>"
        add_prop "${switch_node}" "xlnx,num-ports" $numports noformating $dts_file
        if {[string match -nocase $en_pkt_switch "true"]} {
            add_prop "$switch_node" "xlnx,packet-switch" boolean $dts_file
        }
        global tsn_ep_node
        global tsn_emac0_node
        global tsn_emac1_node
        set end1 ""
        set end1 [lappend end1 $tsn_ep_node]
        set end1 [lappend end1 $tsn_emac0_node]
        set end1 [lappend end1 $tsn_emac1_node]
        set len [llength $end1]
        if {$len > 0} {
            set ref_id [lindex $end1 0]
            for {set i 1} {$i < $len} {incr i} {
                append ref_id ">, <&[lindex $end1 $i]"
            }
            add_prop "${switch_node}" "ports" "$ref_id" reference $dts_file
        }
    }

    proc tsn_gen_mac0_node {periph addr size parent_node proc_type drv_handle numqueues freq intr_parent mac0intr eth_ip queues id end1 end_point_ip connectrx_ip connecttx_ip tsn_inst_name} {
        set dts_file [set_drv_def_dts $drv_handle]
        global tsn_emac0_node
        set tsn_mac_node [create_node -n "tsn_emac_0" -l $tsn_emac0_node -u $addr -p $parent_node -d $dts_file]
        if {[string match -nocase $proc_type "zynq"]} {
                set tsnreg "0x$addr $size"
        } else {
                set tsnreg "0x0 0x$addr 0x0 $size"
        }
        add_prop "${tsn_mac_node}" "reg" $tsnreg hexlist $dts_file
        set tsn_comp "xlnx,tsn-ethernet-1.00.a"
        add_prop "${tsn_mac_node}" "compatible" $tsn_comp stringlist $dts_file
        set mdionode [create_node -l ${drv_handle}_mdio0 -n mdio -p $tsn_mac_node -d $dts_file]
        add_prop "${mdionode}" "#address-cells" 1 int $dts_file
        add_prop "${mdionode}" "#size-cells" 0 int $dts_file
        set phytype [string tolower [hsi get_property CONFIG.PHYSICAL_INTERFACE $periph]]
        set phymode $phytype
        if {$phytype == "rgmii"} {
            set phymode "rgmii-id"
        }
        set txcsum "0"
        set rxcsum "0"
        set mac_addr "00 0A 35 00 01 0e"
        set qbv_offset [hsi get_property CONFIG.TEMAC_1_SCHEDULER_OFFSET $periph]
        set qbv_size [hsi get_property CONFIG.TEMAC_1_SCHEDULER_SIZE $periph]
        add_prop $tsn_mac_node "local-mac-address" ${mac_addr} hexbytesequence $dts_file
        add_prop "$tsn_mac_node" "xlnx,txsum" $txcsum int $dts_file
        add_prop "$tsn_mac_node" "xlnx,rxsum" $rxcsum int $dts_file
        add_prop "$tsn_mac_node" "xlnx,tsn" boolean $dts_file
        add_prop "$tsn_mac_node" "xlnx,eth-hasnobuf" boolean $dts_file
        add_prop "$tsn_mac_node" "phy-mode" $phymode string $dts_file
        add_prop "$tsn_mac_node" "xlnx,num-tc" $numqueues noformating $dts_file
        add_prop "$tsn_mac_node" "xlnx,channel-ids" $id stringlist $dts_file
        add_prop "$tsn_mac_node" "xlnx,num-queues" $queues noformating $dts_file
	add_prop "$tsn_mac_node" "xlnx,tsn-tx-config" "tsn_tx_config" reference $dts_file
        global tsn_ep_node
        add_prop "$tsn_mac_node" "tsn,endpoint" $tsn_ep_node reference $dts_file
        if {[llength $qbv_offset] != 0} {
                set qbv_addr 0x[format %08x [expr 0x$addr + $qbv_offset]]
                add_prop "$tsn_mac_node" "xlnx,qbv-addr" $qbv_addr int $dts_file
                add_prop "$tsn_mac_node" "xlnx,qbv-size" $qbv_size int $dts_file
        }
        set intr_len [llength $mac0intr]
        for {set i 0} {$i < $intr_len} {incr i} {
                lappend intr [lindex $mac0intr $i]
                lappend intr_num [get_intr_id $eth_ip [lindex $mac0intr $i]]
        }
        regsub -all "\{||\t" $intr_num {} intr_num
        regsub -all "\}||\t" $intr_num {} intr_num
        add_prop $tsn_mac_node "interrupts" $intr_num intlist $dts_file
        add_prop "${tsn_mac_node}" "interrupt-parent" $intr_parent reference $dts_file
        add_prop "${tsn_mac_node}" "interrupt-names" $mac0intr stringlist $dts_file
        add_prop "${tsn_mac_node}" "clock-frequency" $freq int $dts_file
        set dts_fil [set_drv_def_dts $dts_file]
        if {$phytype == "rgmii" || $phytype == "gmii"} {
                set phynode [tsn_ethernetfmc_phy_node $periph $tsn_inst_name]
                set phya [lindex $phynode 0]
                if { $phya != "-1"} {
                        set phy_name "[lindex $phynode 1]"
                        add_prop "${tsn_mac_node}" "phy-handle" $phy_name reference $dts_file
                        tsn_gen_phy_node $mdionode $phy_name $phya $dts_file

                }
        }
        set len [llength $end1]
        for {set len_index 0} {$len_index < $len} {incr len_index} {
                if {$len_index == "0"} {
                        set ref_id [lindex $end1 $len_index]
                } else {
                        append ref_id ">, <&[lindex $end1 $len_index]"
                }
        }
        set len3 [llength $connecttx_ip]
        for {set len3_index 0} {$len3_index < $len3} {incr len3_index} {
                if {$len3_index == "0" && $len == "0"} {
                        set ref_id [lindex $connecttx_ip $len3_index]
                } else {
                        append ref_id ">, <&[lindex $connecttx_ip $len3_index]"
                }
        }
        if { $len || $len3} {
            add_prop "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference $dts_file
        }
        set len1 [llength $end_point_ip]
        for {set len1_index 0} {$len1_index < $len1} {incr len1_index} {
                if {$len1_index == "0"} {
                        set ref_id [lindex $end_point_ip $len1_index]
                } else {
                        append ref_id ">, <&[lindex $end_point_ip $len1_index]"
                }
        }

        set len2 [llength $connectrx_ip]
        for {set len2_index 0} {$len2_index < $len2} {incr len2_index} {
                if {$len1 == "0" && $len2_index == "0"} {
                        set ref_id [lindex $connectrx_ip $len2_index]
                } else {
                        append ref_id ">, <&[lindex $connectrx_ip $len2_index]"
                }
        }
        if {$len1 > 0 || $len2 > 0} {
            add_prop "${tsn_mac_node}" "axistream-connected-rx" "$ref_id" reference $dts_file
        }
    }

    proc tsn_gen_mac1_node {periph addr size numqueues intr_parent parent_node drv_handle proc_type freq eth_ip mac1intr baseaddr queues tsn_inst_name} {
        global tsn_emac1_node
        set dts_file [set_drv_def_dts $drv_handle]
        set tsn_mac_node [create_node -n "tsn_emac_1" -l $tsn_emac1_node -u $addr -p $parent_node -d $dts_file]
        if {[string match -nocase $proc_type "zynq"]} {
                set tsn_reg "0x$addr $size"
        } else {
                set tsn_reg "0x0 0x$addr 0x0 $size"
        }
        set tsn_comp "xlnx,tsn-ethernet-1.00.a"
        add_prop "${tsn_mac_node}" "reg" $tsn_reg hexlist $dts_file
        add_prop "${tsn_mac_node}" "compatible" $tsn_comp stringlist $dts_file
        set mdionode [create_node -l ${drv_handle}_mdio1 -n mdio -p $tsn_mac_node -d $dts_file]
        add_prop "${mdionode}" "#address-cells" 1 int $dts_file
        add_prop "${mdionode}" "#size-cells" 0 int $dts_file
        set tsn_emac2_ip [hsi get_property IP_NAME $periph]
        set tsn_ip [hsi::get_cells -hier -filter {IP_NAME == $tsn_emac2_ip}]
        set phytype [string tolower [hsi get_property CONFIG.Physical_Interface $periph]]
        set phymode $phytype
        if {$phytype == "rgmii"} {
            set phymode "rgmii-id"
        }
        set txcsum "0"
        set rxcsum "0"
        set mac_addr "00 0A 35 00 01 0f"
        set qbv_offset [hsi get_property CONFIG.TEMAC_2_SCHEDULER_OFFSET $eth_ip]
        set qbv_size [hsi get_property CONFIG.TEMAC_2_SCHEDULER_SIZE $eth_ip]
        add_prop $tsn_mac_node "local-mac-address" ${mac_addr} hexbytesequence $dts_file
        add_prop "$tsn_mac_node" "xlnx,txsum" $txcsum int $dts_file
        add_prop "$tsn_mac_node" "xlnx,rxsum" $rxcsum int $dts_file
        add_prop "$tsn_mac_node" "xlnx,tsn" boolean $dts_file
        add_prop "$tsn_mac_node" "xlnx,tsn-slave" boolean $dts_file
        add_prop "$tsn_mac_node" "xlnx,eth-hasnobuf" boolean $dts_file
        add_prop "$tsn_mac_node" "phy-mode" $phymode string $dts_file
        add_prop "$tsn_mac_node" "xlnx,num-tc" $numqueues noformating $dts_file
        add_prop "$tsn_mac_node" "xlnx,num-queues" $queues noformating $dts_file
        global tsn_ep_node
        add_prop "$tsn_mac_node" "tsn,endpoint" $tsn_ep_node reference $dts_file
        if {[llength $qbv_offset] != 0} {
                set qbv_addr 0x[format %08x [expr 0x$baseaddr + $qbv_offset]]
                add_prop "$tsn_mac_node" "xlnx,qbv-addr" $qbv_addr int $dts_file
                add_prop "$tsn_mac_node" "xlnx,qbv-size" $qbv_size int $dts_file
        }
        set intr_len [llength $mac1intr]
        for {set i 0} {$i < $intr_len} {incr i} {
                lappend intr [lindex $mac1intr $i]
                lappend intr_num [get_intr_id $eth_ip [lindex $mac1intr $i]]
        }
        regsub -all "\{||\t" $intr_num {} intr_num
        regsub -all "\}||\t" $intr_num {} intr_num
        add_prop $tsn_mac_node "interrupts" $intr_num intlist $dts_file
        add_prop "${tsn_mac_node}" "interrupt-parent" $intr_parent reference $dts_file
        add_prop "${tsn_mac_node}" "interrupt-names" $mac1intr stringlist $dts_file
        add_prop "${tsn_mac_node}" "clock-frequency" $freq int $dts_file
        if {$phytype == "rgmii" || $phytype == "gmii"} {
                set phynode [tsn_ethernetfmc_phy_node $periph $tsn_inst_name]
                set phya [lindex $phynode 0]
                if { $phya != "-1"} {
                        set phy_name "[lindex $phynode 1]"
                        add_prop "${tsn_mac_node}" "phy-handle" $phy_name reference $dts_file
                        tsn_gen_phy_node $mdionode $phy_name $phya $dts_file
                }
        }
    }
