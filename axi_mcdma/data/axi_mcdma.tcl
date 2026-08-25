#
# (C) Copyright 2019-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
#
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
    proc axi_mcdma_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(CUSTOM_SDT_REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        pldt append $node compatible "\ \, \"xlnx,axi-mcdma-1.00.a\""
        set mcdma_ip [hsi::get_cells -hier $drv_handle]
        set dma_count [get_count "dma_count"]
        if { [llength $dma_count] == 0 } {
                set dma_count 0
        }
        add_prop "$node" "#dma-cells" 1 int "pl.dtsi"
        set axiethernetfound 0
        set connected_ip [get_connected_stream_ip $mcdma_ip "M_AXIS_MM2S"]
        if { [llength $connected_ip] } {
                set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                if { [string match -nocase $connected_ip_type axi_ethernet ] || [string match -nocase $connected_ip_type axi_ethernet_buffer ] } {
                        set axiethernetfound 1
                }
        } else {
                dtg_warning "$drv_handle connected ip is NULL for the pin M_AXIS_MM2S"
        }

        set is_xxv [axi_mcdma_get_connected_ip $drv_handle "M_AXIS_MM2S"]
            set is_mrmac [axi_mcdma_is_mrmac_connected $drv_handle "M_AXIS_MM2S"]
        set tsn_inst_name [hsi get_cells -filter {IP_NAME =~ "*tsn*"}]
        if { $axiethernetfound || $is_xxv == 1 || $is_mrmac == 1 || [llength $tsn_inst_name] } {
                pldt set $node compatible "\"xlnx,eth-mcdma\""
        }
            if { $axiethernetfound != 1 && $is_xxv != 1 && $is_mrmac != 1} {
                set ip_prop CONFIG.c_include_mm2s_dre
                add_cross_property $drv_handle $ip_prop $drv_handle "xlnx,include-dre" $node boolean
                set_drv_conf_prop $drv_handle c_addr_width xlnx,addrwidth $node
                set baseaddr [get_baseaddr $mcdma_ip no_prefix]
                set tx_chan [get_ip_param_value $mcdma_ip C_INCLUDE_MM2S]
                if { $tx_chan == 1 } {
                        set tx_chan_node [axi_mcdma_add_dma_channel $drv_handle $node "axi-dma" $baseaddr "MM2S" $dma_count ]
                        set num_mm2s_channles [hsi get_property CONFIG.c_num_mm2s_channels [hsi::get_cells -hier $drv_handle]]
                        set intr_info [axi_mcdma_get_interrupt_info $drv_handle "MM2S"]
                        if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
                                add_prop $tx_chan_node "interrupts" $intr_info intlist "pl.dtsi"
                        } else {
                                dtg_warning "ERROR: ${drv_handle}: mm2s_introut port is not connected"
                        }
                        set intr_parent ""
                        if {[catch {set intr_parent [pldt get $node "interrupt-parent"]} msg]} {
                        } else {
                                set intr_parent [string trimright $intr_parent ">"]
                                set intr_parent [string trimleft $intr_parent "<&"]
                        }
                        if {[llength $intr_parent]} {
                                add_prop $tx_chan_node "interrupt-parent" $intr_parent reference "pl.dtsi"
                        }
                        axi_mcdma_add_dma_coherent_prop $drv_handle "M_AXI_MM2S"
                }
                set rx_chan [get_ip_param_value $mcdma_ip C_INCLUDE_S2MM]
                if { $rx_chan ==1 } {
                        set rx_bassaddr [format %08x [expr 0x$baseaddr + 0x30]]
                        set rx_chan_node [axi_mcdma_add_dma_channel $drv_handle $node "axi-dma" $rx_bassaddr "S2MM" $dma_count]
                        set intr_info [axi_mcdma_get_interrupt_info $drv_handle "S2MM"]
                        if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
                                add_prop $rx_chan_node "interrupts" $intr_info intlist "pl.dtsi"
                        } else {
                                dtg_warning "ERROR: ${drv_handle}: s2mm_introut port is not connected"
                        }
                        set intr_parent ""
                        if {[catch {set intr_parent [pldt get $node "interrupt-parent"]} msg]} {
                        } else {
                                set intr_parent [pldt get $node "interrupt-parent"]
                                set intr_parent [string trimright $intr_parent ">"]
                                set intr_parent [string trimleft $intr_parent "<&"]
                        }
                        if {[llength $intr_parent]} {
                                add_prop $rx_chan_node "interrupt-parent" $intr_parent reference "pl.dtsi"
                        }
                        axi_mcdma_add_dma_coherent_prop $drv_handle "M_AXI_S2MM"
                }
        } else {
                set ip_prop CONFIG.c_include_mm2s_dre
                add_cross_property $drv_handle $ip_prop $drv_handle "xlnx,include-dre" $node boolean
                set_drv_conf_prop $drv_handle c_addr_width xlnx,addrwidth $node
        }
        incr dma_count
        set_drv_conf_prop $drv_handle C_M_AXI_MM2S_DATA_WIDTH xlnx,mm2s-data-width $node hexint
        set_drv_conf_prop $drv_handle C_M_AXI_S2MM_DATA_WIDTH xlnx,s2mm-data-width $node hexint
    }   

    proc axi_mcdma_get_interrupt_info {drv_handle chan_name} {
        if {[string match -nocase $chan_name "MM2S"]} {
                set num_channles [hsi get_property CONFIG.c_num_mm2s_channels [hsi::get_cells -hier $drv_handle]]
        } else {
                set num_channles [hsi get_property CONFIG.c_num_s2mm_channels [hsi::get_cells -hier $drv_handle]]
        }
        set intr_info ""
        for {set i 1} {$i <= $num_channles} {incr i} {
                set intr_pin_name [format "%s_%s_introut" [string tolower $chan_name] ch$i]
                set intr1_info [get_intr_id $drv_handle $intr_pin_name]
                if {[string match -nocase $intr1_info "-1"]} {
                        continue
                }
                lappend intr_info $intr1_info
        }
        if {[llength $intr_info]} {
                regsub -all "\{||\t" $intr_info {} intr_info
                regsub -all "\}||\t" $intr_info {} intr_info
                return $intr_info
        }
    }

    proc axi_mcdma_get_connected_ip {drv_handle dma_pin} {
        global connected_ip
        # Check whether dma is connected to 10G/25G MAC
        # currently we are handling only data fifo
        set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $drv_handle] $dma_pin]
        set valid_eth_list "xxv_ethernet axi_ethernet axi_10g_ethernet usxgmii"
        if {[string_is_empty ${intf}]} {
                return 0
        }
        set connected_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]

        if {[string_is_empty ${connected_ip}]} {
                dtg_warning "$drv_handle connected ip is NULL for the pin $intf"
                return 0
        }
        set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $connected_ip]]
        if {[string match -nocase $iptype "axis_data_fifo"] } {
                # here dma connected to data fifo
                set dma_pin "M_AXIS"
                axi_mcdma_get_connected_ip $connected_ip $dma_pin
        } elseif {[lsearch -nocase $valid_eth_list $iptype] >= 0 } {
                # dma connected to 10G/25G MAC, 1G or 10G
                return 1
        } else {
                # dma connected via interconnects
                set dma_pin "M_AXIS"
		if {$iptype == "ethernet_offload"} {
                      set dma_pin "tx_axis"
                }
                axi_mcdma_get_connected_ip $connected_ip $dma_pin
        }
    }

    # Breadth-first walk of the downstream AXI-Stream graph from $start_ip,
    # returning 1 if an IP whose IP_NAME matches $target is reachable. It
    # follows AXIS master/initiator interfaces and raw output data pins, so it
    # crosses signal-level blocks (xlconcat/xlslice), the 10G mux, PTP-edit
    # blocks, and custom hierarchies with no AXIS interface.
    proc axi_mcdma_find_stream_ip {start_ip target {max_hops 16}} {

         set queue [list $start_ip]
         set visited {}

         for {set hop 0} {$hop < $max_hops && [llength $queue]} {incr hop} {
                 set next_queue {}
                 foreach cur $queue {
                         if {![llength $cur] || [lsearch -exact $visited $cur] >= 0} {
                                 continue
                         }
                         lappend visited $cur

                         if {[string match -nocase $target [hsi get_property IP_NAME $cur]]} {
                                 return 1
                         }

                         # Descend into hierarchical wrapper internals.
                         # HIER_NAME may resolve to multiple values; iterate
                         # each individually so a space-separated list is never
                         # injected into the -filter expression.
                         set cur_hier_names ""
                         catch {set cur_hier_names [hsi get_property HIER_NAME [hsi::get_cells -hier $cur]]}
                         foreach cur_hier_name $cur_hier_names {
                                 if {[string_is_empty $cur_hier_name]} {
                                         continue
                                 }
                                 foreach child [hsi::get_cells -hier -filter "HIER_NAME=~${cur_hier_name}/*"] {
                                         if {[lsearch -exact $visited $child] < 0} {
                                                 lappend next_queue $child
                                         }
                                 }
                         }

                         set downstream {}

                         # Follow AXIS master/initiator interfaces (stream blocks).
                         set intfs [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $cur] \
                                    -filter {TYPE==MASTER || TYPE==INITIATOR}]
                         foreach intf $intfs {
                                 foreach peer [get_connected_stream_ip [hsi::get_cells -hier $cur] $intf] {
                                         if {[llength $peer]} {
                                                 lappend downstream $peer
                                         }
                                 }
                         }

                         # Follow only stream data-bus output pins at the net
                         # level (tdata / m_axis / concat-slice dout). This crosses
                         # signal-level blocks (xlconcat/xlslice) that carry the AXIS
                         # bus on raw pins, while avoiding wide shared control nets.
                         set out_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $cur] \
                                       -filter {DIRECTION==O}]
                         foreach opin $out_pins {
                                 if {![regexp -nocase {tdata|m_axis|dout} [hsi get_property NAME $opin]]} {
                                         continue
                                 }
                                 foreach sp [get_sink_pins $opin] {
                                         foreach sp_cell [hsi::get_cells -of_objects $sp] {
                                                 if {[llength $sp_cell]} {
                                                         lappend downstream $sp_cell
                                                 }
                                         }
                                 }
                         }

                         foreach peer $downstream {
                                 if {![llength $peer] || [regexp -nocase "ila" $peer]} {
                                         continue
                                 }
                                 if {[string match -nocase $target [hsi get_property IP_NAME $peer]]} {
                                         return 1
                                 }
                                 if {[lsearch -exact $visited $peer] < 0} {
                                         lappend next_queue $peer
                                 }
                         }
                 }
                 set queue $next_queue
         }

         return 0
    }

    proc axi_mcdma_is_mrmac_connected {drv_handle dma_pin} {

         # Discover an mrmac reachable from the MM2S stream output generically.
         # This crosses FIFOs, converters, concat/slice, the 10G mux, PTP edit
         # blocks, ethernet_offload, and custom hierarchies without any
         # design-specific parsing.
         set mcdma [hsi::get_cells -hier $drv_handle]
         set start {}

         set connected_ip [get_connected_stream_ip $mcdma $dma_pin]
         if {[llength $connected_ip]} {
                 lappend start $connected_ip
         } else {
                 set dpath_pin [get_sink_pins [hsi::get_pins -of_objects $mcdma "m_axis_mm2s_tdata"]]
                 foreach p $dpath_pin {
                         set c [hsi::get_cells -of_objects $p]
                         if {[llength $c]} {
                                 lappend start $c
                         } else {
                                 puts "Warning: The $p is not connected to any IP within the Block Design. Is this intentional?"
                         }
                 }
         }

         foreach s $start {
                 if {[axi_mcdma_find_stream_ip $s "mrmac"]} {
                         return 1
                 }
         }

         return 0
    }

    proc axi_mcdma_add_dma_channel {drv_handle parent_node xdma addr mode devid} {

        set modellow [string tolower $mode]
        set modeIndex [string index $mode 0]
        set dts_file [set_drv_def_dts $drv_handle]
        set dma_channel [create_node -n "dma-channel" -l "dma_channel_$addr" -u $addr -p $parent_node -d $dts_file]
        add_prop $dma_channel "compatible" [format "xlnx,%s-%s-channel" $xdma $modellow] stringlist "pl.dtsi"
        add_prop $dma_channel "xlnx,device-id" $devid hexint "pl.dtsi"

        add_cross_property_to_dtnode $drv_handle [format "CONFIG.C_INCLUDE_%s_DRE" $mode] $dma_channel "xlnx,include-dre" boolean
        # detection based on two property
        set datawidth_list "[format "CONFIG.C_%s_AXIS_%s_DATA_WIDTH" $modeIndex $mode] [format "CONFIG.C_%s_AXIS_%s_TDATA_WIDTH" $modeIndex $mode]"
        add_cross_property_to_dtnode $drv_handle $datawidth_list $dma_channel "xlnx,datawidth"
        if {[string match -nocase $mode "MM2S"]} {
                set num_channles [hsi get_property CONFIG.c_num_mm2s_channels [hsi::get_cells -hier $drv_handle]]
        } else {
                set num_channles [hsi get_property CONFIG.c_num_s2mm_channels [hsi::get_cells -hier $drv_handle]]
        }
        add_prop $dma_channel "dma-channels" $num_channles hexint "pl.dtsi"
        return $dma_channel
    }

    proc axi_mcdma_add_dma_coherent_prop {drv_handle intf} {

        set ip_name [hsi::get_cells -hier -filter "NAME==$drv_handle"]
        set connectedip [get_connected_stream_ip $drv_handle $intf]
        if {[llength $connectedip] == 0} {
                return
        }
        set intrconnect [hsi get_property IP_NAME [hsi::get_cells -hier $connectedip]]
        set num_master [hsi get_property CONFIG.NUM_MI $connectedip]
        set done 0

        # check whether dma connected to interconnect ip, loop until you get the
        # port name ACP or HP
        while {[string match -nocase $intrconnect "axi_interconnect"]} {
                # loop over number of master interfaces
                set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectedip] -filter {TYPE==MASTER}]
                if {[llength $master_intf] == 0} {
                        break
                }
                foreach interface ${master_intf} {
                        set intf_port [get_connected_intf $connectedip $interface]
                        set intrconnect [get_connected_stream_ip $connectedip $interface]
                        if {![string_is_empty $intf_port] && [string match -nocase $intf_port "S_AXI_ACP"]} {
                                set node [get_node $drv_handle]
                                add_prop $node "dma-coherent" "" boolean "pl.dtsi"
                                # here dma connected to ACP port
                                set done 1
                                break;
                        }
                        if {$done} {
                                break
                        }
                }
        }
    }


