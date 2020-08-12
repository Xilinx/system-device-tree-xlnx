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

namespace eval axi_cdma { 
proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

	#set node [gen_peripheral_nodes $drv_handle]
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

	set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg boolean
	set_drv_conf_prop $drv_handle C_NUM_FSTORES xlnx,num-fstores
	set_drv_conf_prop $drv_handle C_USE_FSYNC xlnx,flush-fsync
	set_drv_conf_prop $drv_handle C_ADDR_WIDTH xlnx,addrwidth
	set_drv_conf_prop $drv_handle C_INCLUDE_DRE xlnx,include-dre
	set_drv_conf_prop $drv_handle C_M_AXI_MAX_BURST_LEN xlnx,max-burst-len
	set_drv_conf_prop $drv_handle C_USE_DATAMOVER_LITE xlnx,lite-mode
	set_drv_conf_prop $drv_handle C_M_AXI_DATA_WIDTH xlnx,datawidth
	set node [get_node $drv_handle]
#	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
 #       set compatible [get_comp_str $drv_handle]
  #      set compatible [append compatible " " "xlnx,axi-cdma-1.00.a"]
   #     set_drv_prop $drv_handle compatible "$compatible" stringlist
	set keyval [pldt append $node compatible "\ \, \"xlnx,axi-cdma-1.00.a\""
	set dma_ip [hsi::get_cells -hier $drv_handle]
#	set cdma_count [hsi::utils::get_os_parameter_value "cdma_count"]
	set cdma_count [get_count "cdma_count"]
	if { [llength $cdma_count] == 0 } {
		set cdma_count 0
	}

	set baseaddr [get_baseaddr $dma_ip no_prefix]
	set tx_chan [create_node -n 
	set tx_chan [add_dma_channel $drv_handle $node "axi-cdma" $baseaddr "MM2S" $cdma_count ]
	incr cdma_count
#	hsi::utils::set_os_parameter_value "cdma_count" $cdma_count
#	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set drvname [get_drivers $drv_handle]
        #puts "drvname $drvname"

        set common_file "$path/device_tree/data/config.yaml"
        if {[file exists $common_file]} {
                #error "file not found: $common_file"
        }
        #set file "$path/${drvname}/data/config.yaml"
        puts "==============> file $common_file"
        set mainline_ker [get_user_config $common_file -mainline_kernel]

	if {[string match -nocase $mainline_ker "none"]} {
	#	set proc_type [get_sw_proc_prop IP_NAME]
		set proc_type [get_hw_family]
#		set proc_type "psv_cortexa72"
		if {[regexp "kintex*" $proc_type match]} {
				gen_dev_ccf_binding $drv_handle "s_axi_lite_aclk m_axi_aclk"
				set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
		}
	} else {
		generate_clk_nodes $drv_handle
	}
}

proc add_dma_channel {drv_handle parent_node xdma addr mode devid} {
	#set ip [get_cells -hier $drv_handle]
	set modellow [string tolower $mode]
	set modeIndex [string index $mode 0]
	#set node_name [format "dma-channel@%x" $addr]
#	set dma_channel [add_or_get_dt_node -n "dma-channel" -u $addr -p $parent_node]
	set dma_channel [create_node -n "dma-channel" -u $addr -p $parent_node] 

	add_prop $dma_channel "compatible" [format "xlnx,%s-channel" $xdma] stringlist "pl.dtsi"
#	hsi::utils::add_new_dts_param $dma_channel "compatible" [format "xlnx,%s-channel" $xdma] stringlist
	add_prop $dma_channel "xlnx,device-id" $devid hexint "pl.dtsi"
#	hsi::utils::add_new_dts_param $dma_channel "xlnx,device-id" $devid hexint
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_INCLUDE_DRE" $dma_channel "xlnx,include-dre" boolean
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_M_AXI_DATA_WIDTH" $dma_channel "xlnx,datawidth"
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_USE_DATAMOVER_LITE" $dma_channel "xlnx,lite-mode" boolean
	add_cross_property_to_dtnode $drv_handle "CONFIG.C_M_AXI_MAX_BURST_LEN" $dma_channel "xlnx,max-burst-len"

	set intr_info [get_intr_id $drv_handle "cdma_introut" ]
	if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
		add_prop $dma_channel "interrupts" $intr_info intlist "pl.dtsi"
#		hsi::utils::add_new_dts_param $dma_channel "interrupts" $intr_info intlist
	} else {
		dtg_warning "ERROR: ${drv_handle}: cdma_introut port is not connected"
	}
	return $dma_channel
}

proc generate_clk_nodes {drv_handle} {
#    set proc_type [get_sw_proc_prop IP_NAME]
	set proc_type [get_hw_family]

    	if {[string match -nocase $proc_type "zynq"]} {
            set_drv_prop_if_empty $drv_handle "clocks" "clkc 15>, <&clkc 15" reference
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
        } elseif if {[string match -nocase $proc_type "zynqmp"] || [string match -nocase $proc_type "zynquplus"]} {
#            foreach i [get_sw_cores device_tree] {
 #               set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
  #              if {[file exists $common_tcl_file]} {
   #                 source $common_tcl_file
    #                break
   #             }
    #        }
            set clk_freq [get_clock_frequency [get_cells -hier $drv_handle] "s_axi_lite_aclk"]
            if {![string equal $clk_freq ""]} {
                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                    set bus_clk_list [lappend bus_clk_list $clk_freq]
                }
            }
            set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
     #       set dts_file [current_dt_tree]
		set dts_file [set_drv_def_dts $drv_handle]
            set bus_node [add_or_get_bus_node $drv_handle $dts_file]
            set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                -d ${dts_file} -p ${bus_node} -d $dts_file]
		add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist "pl.dtsi"
		add_prop "${misc_clk_node}" "#clock-cells" 0 int "pl.dtsi"
		add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int "pl.dtsi"
#	     hsi::utils::add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
#	     hsi::utils::add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
#	     hsi::utils::add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
            set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
            set_drv_prop_if_empty $drv_handle "clocks" "$clk_refs>, <&$clk_refs" reference
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
        } elseif {[regexp "kintex*" $proc_type match]} {
            gen_dev_ccf_binding $drv_handle "s_axi_lite_aclk m_axi_aclk"
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" stringlist
        } else {
            error "Unknown arch"
        }
}
}
