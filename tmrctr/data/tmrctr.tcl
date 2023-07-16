    proc tmrctr_generate {drv_handle} {
         set node [get_node $drv_handle]
         set dts_file [set_drv_def_dts $drv_handle]
         pldt append $node compatible "\ \, \"xlnx,xps-timer-1.00.a\""
        #adding clock frequency
        set ip [hsi::get_cells -hier $drv_handle]
        set clk [hsi::get_pins -of_objects $ip "S_AXI_ACLK"]
        if {[llength $clk] } {
        set freq [hsi get_property CLK_FREQ $clk]
        add_prop $node "clock-frequency" $freq hexint $dts_file
        }
        set proctype [get_hw_family]
        if {[regexp "microblaze" $proctype match]} {
                 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
        }
    }


