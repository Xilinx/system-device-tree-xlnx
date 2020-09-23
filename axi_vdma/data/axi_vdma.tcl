#
# (C) Copyright 2014-2015 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
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

namespace eval axi_vdma {
	proc generate {drv_handle} {

	    set node [get_node $drv_handle]
	    if {$node == 0} {
		   return
	    }
		global env
		set path $env(REPO)

		set drvname [get_drivers $drv_handle]

		set common_file "$path/device_tree/data/config.yaml"
		if {[file exists $common_file]} {
			#error "file not found: $common_file"
		}
		set mainline_ker [get_user_config $common_file -mainline_kernel]
		pldt append $node compatible "\ \, \"xlnx,axi-vdma-1.00.a\""
		set dma_ip [hsi::get_cells -hier $drv_handle]
		set vdma_count [get_count "vdma_count"]
		if { [llength $vdma_count] == 0 } {
			set vdma_count 0
		}
		set dts_file [set_drv_def_dts $drv_handle]

		# check for C_ENABLE_DEBUG parameters
		# C_ENABLE_DEBUG_INFO_15 - Enable S2MM Frame Count Interrupt bit
		# C_ENABLE_DEBUG_INFO_14 - Enable S2MM Delay Counter Interrupt bit
		# C_ENABLE_DEBUG_INFO_7 - Enable MM2S Frame Count Interrupt bit
		# C_ENABLE_DEBUG_INFO_6 - Enable MM2S Delay Counter Interrupt bit
		set dbg15 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_15]
		set dbg14 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_14]
		set dbg07 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_7]
		set dbg06 [hsi::utils::get_ip_param_value $dma_ip C_ENABLE_DEBUG_INFO_6]

		if { $dbg15 != 1 || $dbg14 != 1 || $dbg07 != 1 || $dbg06 != 1 } {
			puts "ERROR: Failed to generate AXI VDMA node,"
			puts "ERROR: Essential VDMA Debug parameters for driver are not enabled in IP"
			return;
		}

		set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
		set_drv_conf_prop $drv_handle c_num_fstores xlnx,num-fstores
		set_drv_conf_prop $drv_handle C_USE_FSYNC xlnx,flush-fsync
		set_drv_conf_prop $drv_handle c_addr_width xlnx,addrwidth
		set_drv_conf_prop $drv_handle C_INCLUDE_MM2S xlnx,include-mm2s
		set_drv_conf_prop $drv_handle C_INCLUDE_MM2S_DRE xlnx,include-mm2s-dre
		set_drv_conf_prop $drv_handle C_M_AXI_MM2S_DATA_WIDTH xlnx,mm2s-data-width
		set_drv_conf_prop $drv_handle C_INCLUDE_S2MM xlnx,include-s2mm
		set_drv_conf_prop $drv_handle C_INCLUDE_S2MM_DRE xlnx,include-s2mm-dre
		set_drv_conf_prop $drv_handle C_M_AXI_S2MM_DATA_WIDTH xlnx,s2mm-data-width
		set_drv_conf_prop $drv_handle C_ENABLE_VIDPRMTR_READS xlnx,enable-vidparam-reads
		set_drv_conf_prop $drv_handle C_FLUSH_ON_FSYNC xlnx,flush-on-fsync
		set_drv_conf_prop $drv_handle C_MM2S_LINEBUFFER_DEPTH xlnx,mm2s-linebuffer-depth
		set_drv_conf_prop $drv_handle C_S2MM_LINEBUFFER_DEPTH xlnx,s2mm-linebuffer-depth
		set_drv_conf_prop $drv_handle C_MM2S_GENLOCK_MODE xlnx,mm2s-genlock-mode
		set_drv_conf_prop $drv_handle C_S2MM_GENLOCK_MODE xlnx,s2mm-genlock-mode
		set_drv_conf_prop $drv_handle C_INCLUDE_INTERNAL_GENLOCK xlnx,include-internal-genlock
		set_drv_conf_prop $drv_handle C_S2MM_SOF_ENABLE xlnx,s2mm-sof-enable
		set_drv_conf_prop $drv_handle C_M_AXIS_MM2S_TDATA_WIDTH xlnx,mm2s-tdata-width
		set_drv_conf_prop $drv_handle C_S_AXIS_S2MM_TDATA_WIDTH xlnx,s2mm-tdata-width
		set_drv_conf_prop $drv_handle c_enable_vert_flip xlnx,enable-vert-flip
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_1 xlnx,enable-debug-info-1
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_5 xlnx,enable-debug-info-5
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_6 xlnx,enable-debug-info-6
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_7 xlnx,enable-debug-info-7
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_9 xlnx,enable-debug-info-9
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_13 xlnx,enable-debug-info-13
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_14 xlnx,enable-debug-info-14
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_INFO_15 xlnx,enable-debug-info-15
		set_drv_conf_prop $drv_handle C_ENABLE_DEBUG_ALL xlnx,enable-debug-all

		set baseaddr [get_baseaddr $dma_ip no_prefix]
		set tx_chan [hsi::utils::get_ip_param_value $dma_ip C_INCLUDE_MM2S]
		if { $tx_chan == 1 } {
			set connected_ip [hsi::utils::get_connected_stream_ip $dma_ip "M_AXIS_MM2S"]
			set tx_chan_node [add_dma_channel $drv_handle $node "axi-vdma" $baseaddr "MM2S" $vdma_count ]
			set intr_info [get_intr_id $drv_handle "mm2s_introut"]
			if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
				add_prop $tx_chan_node "interrupts" $intr_info intlist $dts_file
			} else {
				dtg_warning "ERROR: ${drv_handle}: mm2s_introut port is not connected"
			}
		}
		set rx_chan [hsi::utils::get_ip_param_value $dma_ip C_INCLUDE_S2MM]
		if { $rx_chan ==1 } {
			set connected_ip [hsi::utils::get_connected_stream_ip $dma_ip "S_AXIS_S2MM"]
			set rx_bassaddr [format %08x [expr 0x$baseaddr + 0x30]]
			set rx_chan_node [add_dma_channel $drv_handle $node "axi-vdma" $rx_bassaddr "S2MM" $vdma_count]
			set intr_info [get_intr_id $drv_handle "s2mm_introut"]
			if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
				add_prop $rx_chan_node "interrupts" $intr_info intlist $dts_file
			} else {
				dtg_warning "ERROR: ${drv_handle}: s2mm_introut port is not connected"
			}
		}
	#	incr vdma_count
		if {[string match -nocase $mainline_ker "none"]} {
			set proc_type [get_sw_proc_prop IP_NAME]
			set clocknames "s_axi_lite_aclk"
			if { $tx_chan ==1 } {
				append clocknames " " "m_axi_mm2s_aclk"
				append clocknames " " "m_axi_mm2s_aclk"
			}
			if { $rx_chan ==1 } {
				append clocknames " " "m_axi_s2mm_aclk"
				append clocknames " " "m_axi_s2mm_aclk"
			}
			switch $proc_type {
				"microblaze"  {
					gen_dev_ccf_binding $drv_handle "$clocknames"
					set_drv_prop_if_empty $drv_handle "clock-names" "$clocknames" stringlist
				}
			}
		} else {
				generate_clk_nodes $drv_handle $tx_chan $rx_chan
		}
	}

	proc add_dma_channel {drv_handle parent_node xdma addr mode devid} {
		set ip [hsi::get_cells -hier $drv_handle]
		set modellow [string tolower $mode]
		set modeIndex [string index $mode 0]
		set dma_channel [create_node -n "dma-channel" -u $addr -p $parent_node]
		set dts_file [set_drv_def_dts $drv_handle]
		add_prop $dma_channel "compatible" [format "xlnx,%s-%s-channel" $xdma $modellow] stringlist $dts_file
		add_prop $dma_channel "xlnx,device-id" $devid hexint $dts_file
		if {[string match -nocase $mode "S2MM"]} {
			set vert_flip  [hsi::utils::get_ip_param_value $ip C_ENABLE_VERT_FLIP]
			if {$vert_flip == 1} {
				add_prop $dma_channel "xlnx,enable-vert-flip" boolean $dts_file
			}
		}
		add_cross_property_to_dtnode $drv_handle [format "CONFIG.C_INCLUDE_%s_DRE" $mode] $dma_channel "xlnx,include-dre" boolean
		# detection based on two property
		set datawidth_list "[format "CONFIG.C_%s_AXIS_%s_DATA_WIDTH" $modeIndex $mode] [format "CONFIG.C_%s_AXIS_%s_TDATA_WIDTH" $modeIndex $mode]"
		add_cross_property_to_dtnode $drv_handle $datawidth_list $dma_channel "xlnx,datawidth"
		add_cross_property_to_dtnode $drv_handle [format "CONFIG.C_%s_GENLOCK_MODE" $mode] $dma_channel "xlnx,genlock-mode" boolean

		return $dma_channel
	}

	proc generate_clk_nodes {drv_handle tx_chan rx_chan} {
	#    set proc_type [get_sw_proc_prop IP_NAME]
		set proc_type [get_hw_family]
	    set clocknames "s_axi_lite_aclk"
		if {[string match -nocase $proc_type "zynq"]} {
		set clocks "clkc 15"
		    if { $tx_chan ==1 } {
			append clocknames " " "m_axi_mm2s_aclk"
			append clocknames " " "m_axi_mm2s_aclk"
			append clocks "" ">, <&clkc 15"
			append clocks "" ">, <&clkc 15"
		    }
		    if { $rx_chan ==1 } {
			append clocknames " " "m_axi_s2mm_aclk"
			append clocknames " " "m_axi_s2mm_aclk"
			append clocks "" ">, <&clkc 15"
			append clocks "" ">, <&clkc 15"
		    }
		    set_drv_prop_if_empty $drv_handle "clocks" $clocks reference
		    set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
		} elseif {[string match -nocase $proc_type "zynqmp"] || [string match -nocase $proc_type "zynquplus"]} {
		    foreach i [get_sw_cores device_tree] {
			set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
			if {[file exists $common_tcl_file]} {
			    source $common_tcl_file
			    break
			}
		    }
		    set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "s_axi_lite_aclk"]
		    if {![string equal $clk_freq ""]} {
			if {[lsearch $bus_clk_list $clk_freq] < 0} {
			    set bus_clk_list [lappend bus_clk_list $clk_freq]
			}
		    }
		    set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
		    set bus_node [add_or_get_bus_node $drv_handle $dts_file]
		    set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
			-d ${dts_file} -p ${bus_node} -d $dts_file]
		     add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
		     add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
		     add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
		    # create the node and assuming reg 0 is taken by cpu
		    set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
		    set clocks "$clk_refs"
		    if { $tx_chan ==1 } {
			append clocknames " " "m_axi_mm2s_aclk"
			append clocknames " " "m_axi_mm2s_aclk"
			append clocks "" ">, <&$clk_refs"
			append clocks "" ">, <&$clk_refs"
		    }
		    if { $rx_chan ==1 } {
			append clocknames " " "m_axi_s2mm_aclk"
			append clocknames " " "m_axi_s2mm_aclk"
			append clocks "" ">, <&$clk_refs"
			append clocks "" ">, <&$clk_refs"
		    }
		    set_drv_prop_if_empty $drv_handle "clocks" $clocks reference
		    set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
		} elseif {[regexp "kintex*" $proctype match]} {
		    if { $tx_chan ==1 } {
			append clocknames " " "m_axi_mm2s_aclk"
			append clocknames " " "m_axi_mm2s_aclk"
		    }
		    if { $rx_chan ==1 } {
			append clocknames " " "m_axi_s2mm_aclk"
			append clocknames " " "m_axi_s2mm_aclk"
		    }
		    gen_dev_ccf_binding $drv_handle "$clocknames"
		    set_drv_prop_if_empty $drv_handle "clock-names" "$clocknames" stringlist
		} else {
		    error "Unknown arch"
		}
	}
}
