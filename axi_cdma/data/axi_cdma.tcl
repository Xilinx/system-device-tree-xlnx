    proc axi_cdma_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        set_drv_conf_prop $drv_handle C_INCLUDE_SG xlnx,include-sg $node boolean
        set_drv_conf_prop $drv_handle C_NUM_FSTORES xlnx,num-fstores $node
        set_drv_conf_prop $drv_handle C_USE_FSYNC xlnx,flush-fsync $node
        set_drv_conf_prop $drv_handle C_ADDR_WIDTH xlnx,addrwidth $node
        set_drv_conf_prop $drv_handle C_INCLUDE_DRE xlnx,include-dre $node
        set_drv_conf_prop $drv_handle C_M_AXI_MAX_BURST_LEN xlnx,max-burst-len $node
        set_drv_conf_prop $drv_handle C_USE_DATAMOVER_LITE xlnx,lite-mode $node
        set_drv_conf_prop $drv_handle C_M_AXI_DATA_WIDTH xlnx,datawidth $node
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set keyval [pldt append $node compatible "\ \, \"xlnx,axi-cdma-1.00.a\""]
        set dma_ip [hsi::get_cells -hier $drv_handle]
        set cdma_count [get_count "cdma_count"]
        if { [llength $cdma_count] == 0 } {
                set cdma_count 0
        }

        set baseaddr [get_baseaddr $dma_ip no_prefix]
        set tx_chan [axi_cdma_add_dma_channel $drv_handle $node "axi-cdma" $baseaddr "MM2S" $cdma_count ]
        incr cdma_count
        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]

        if {[string match -nocase $mainline_ker "none"]} {
                set proc_type [get_hw_family]
                if {[regexp "microblaze" $proc_type match]} {
                        gen_dev_ccf_binding $drv_handle "s_axi_lite_aclk m_axi_aclk"
                        set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" $node stringlist
                }
        } else {
                axi_cdma_generate_clk_nodes $drv_handle
        }
    }

    proc axi_cdma_add_dma_channel {drv_handle parent_node xdma addr mode devid} {
        set modellow [string tolower $mode]
        set modeIndex [string index $mode 0]
        set dma_channel [create_node -n "dma-channel" -u $addr -p $parent_node -d "pl.dtsi"] 

        add_prop $dma_channel "compatible" [format "xlnx,%s-channel" $xdma] stringlist "pl.dtsi"
        add_prop $dma_channel "xlnx,device-id" $devid hexint "pl.dtsi"
        add_cross_property_to_dtnode $drv_handle "CONFIG.C_INCLUDE_DRE" $dma_channel "xlnx,include-dre" boolean
        add_cross_property_to_dtnode $drv_handle "CONFIG.C_M_AXI_DATA_WIDTH" $dma_channel "xlnx,datawidth"
        add_cross_property_to_dtnode $drv_handle "CONFIG.C_USE_DATAMOVER_LITE" $dma_channel "xlnx,lite-mode" boolean
        add_cross_property_to_dtnode $drv_handle "CONFIG.C_M_AXI_MAX_BURST_LEN" $dma_channel "xlnx,max-burst-len"

        set intr_info [get_intr_id $drv_handle "cdma_introut" ]
        if { [llength $intr_info] && ![string match -nocase $intr_info "-1"] } {
                add_prop $dma_channel "interrupts" $intr_info intlist "pl.dtsi"
        } else {
                dtg_warning "ERROR: ${drv_handle}: cdma_introut port is not connected"
        }
        return $dma_channel
    }

    proc axi_cdma_generate_clk_nodes {drv_handle} {
        set proc_type [get_hw_family]
        set node [get_node $drv_handle]
        if {[string match -nocase $proc_type "zynq"]} {
            set_drv_prop_if_empty $drv_handle "clocks" "clkc 15>, <&clkc 15" $node reference
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" $node stringlist
        } elseif if {[is_zynqmp_platform $proc_type]} {
            set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "s_axi_lite_aclk"]
            if {![string equal $clk_freq ""]} {
                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                    set bus_clk_list [lappend bus_clk_list $clk_freq]
                }
            }
            set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                set dts_file [set_drv_def_dts $drv_handle]
            set bus_node [add_or_get_bus_node $drv_handle $dts_file]
            set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                -d ${dts_file} -p ${bus_node} -d $dts_file]
                add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist "pl.dtsi"
                add_prop "${misc_clk_node}" "#clock-cells" 0 int "pl.dtsi"
                add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int "pl.dtsi"
            set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
            set_drv_prop_if_empty $drv_handle "clocks" "$clk_refs>, <&$clk_refs" $node reference
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" $node stringlist
        } elseif {[regexp "microblaze" $proc_type match]} {
            gen_dev_ccf_binding $drv_handle "s_axi_lite_aclk m_axi_aclk"
            set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_lite_aclk m_axi_aclk" $node stringlist
        } else {
            error "Unknown arch"
        }
    }


