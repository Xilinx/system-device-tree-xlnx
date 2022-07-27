#
# (C) Copyright 2019-2021 Xilinx, Inc.
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

proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

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

	set is_xxv [get_connected_ip $drv_handle "M_AXIS_MM2S"]
        set is_mrmac [is_mrmac_connected $drv_handle "M_AXIS_MM2S"]
	set tsn_inst_name [hsi get_cells -filter {IP_NAME =~ "*tsn*"}]
	if { $axiethernetfound || $is_xxv == 1 || $is_mrmac == 1 || [llength $tsn_inst_name] } {
		pldt append $node compatible "\ \, \"xlnx,eth-dma\""	
	}
        if { $axiethernetfound != 1 && $is_xxv != 1 && $is_mrmac != 1} {
                set ip_prop CONFIG.c_include_mm2s_dre
                add_cross_property $drv_handle $ip_prop $drv_handle "xlnx,include-dre" boolean
		set_drv_conf_prop $drv_handle c_addr_width xlnx,addrwidth
		set baseaddr [get_baseaddr $mcdma_ip no_prefix]
		set tx_chan [get_ip_param_value $mcdma_ip C_INCLUDE_MM2S]
		if { $tx_chan == 1 } {
			set tx_chan_node [add_dma_channel $drv_handle $node "axi-dma" $baseaddr "MM2S" $dma_count ]
			set num_mm2s_channles [hsi get_property CONFIG.c_num_mm2s_channels [hsi::get_cells -hier $drv_handle]]
			set intr_info [get_interrupt_info $drv_handle "MM2S"]
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
			add_dma_coherent_prop $drv_handle "M_AXI_MM2S"
		}
		set rx_chan [get_ip_param_value $mcdma_ip C_INCLUDE_S2MM]
		if { $rx_chan ==1 } {
			set rx_bassaddr [format %08x [expr 0x$baseaddr + 0x30]]
			set rx_chan_node [add_dma_channel $drv_handle $node "axi-dma" $rx_bassaddr "S2MM" $dma_count]
			set intr_info [get_interrupt_info $drv_handle "S2MM"]
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
			add_dma_coherent_prop $drv_handle "M_AXI_S2MM"
		}
	} else {
		set ip_prop CONFIG.c_include_mm2s_dre
		add_cross_property $drv_handle $ip_prop $drv_handle "xlnx,include-dre" boolean
		set addr_width [hsi get_property CONFIG.c_addr_width $mcdma_ip]
		set inhex [format %x $addr_width]
		append addrwidth "/bits/ 8 <0x$inhex>"
		add_prop $node "xlnx,addrwidth" $addrwidth noformating "pl.dtsi"
	}
	incr dma_count
	set_drv_conf_prop $drv_handle C_M_AXI_MM2S_DATA_WIDTH xlnx,mm2s-data-width hexint
	set_drv_conf_prop $drv_handle C_M_AXI_S2MM_DATA_WIDTH xlnx,s2mm-data-width hexint
}	

proc get_interrupt_info {drv_handle chan_name} {
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

proc get_connected_ip {drv_handle dma_pin} {
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
		get_connected_ip $connected_ip $dma_pin
	} elseif {[lsearch -nocase $valid_eth_list $iptype] >= 0 } {
		# dma connected to 10G/25G MAC, 1G or 10G
		return 1
	} else {
		# dma connected via interconnects
		set dma_pin "M_AXIS"
		get_connected_ip $connected_ip $dma_pin
	}
}

proc is_mrmac_connected {drv_handle dma_pin} {
	set intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $drv_handle] $dma_pin]
        if {[llength $intf]} {
       		set connected_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]
               	if {[llength $connected_ip]} {
        	       if {[string match -nocase [hsi get_property IP_NAME $connected_ip] "axis_data_fifo"]} {
                	       set mux_ip [get_connected_stream_ip [hsi::get_cells -hier $connected_ip] "M_AXIS"]
                       		if {[llength $mux_ip]} {
                               		if {[string match -nocase [hsi get_property IP_NAME $mux_ip] "mrmac_10g_mux"]} {
                                       		set data_fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mux_ip] "tx_m_axis_tdata"]]
	                                        set data_fifo_per [hsi::get_cells -of_objects $data_fifo_pin]
        	                               	if {[string match -nocase [hsi get_property IP_NAME $data_fifo_per] "axis_data_fifo"]} {
                	                               set fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $data_fifo_per] "m_axis_tdata"]]
                        	                       set mrmac_per [hsi::get_cells -of_objects $fifo_pin]
                                	               if {[string match -nocase [hsi get_property IP_NAME $mrmac_per] "mrmac"]} {
                                        	               return 1
                                               		}
                                       		}
                               		}
                       		}
               		}
       		}
	}
}

proc add_dma_channel {drv_handle parent_node xdma addr mode devid} {

	set modellow [string tolower $mode]
	set modeIndex [string index $mode 0]
	set dts_file [set_drv_def_dts $drv_handle]
	set dma_channel [create_node -n "dma-channel" -u $addr -p $parent_node -d $dts_file]
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

proc add_dma_coherent_prop {drv_handle intf} {

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
