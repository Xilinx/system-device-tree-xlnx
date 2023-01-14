    proc cpu_cortexa9_generate {drv_handle} {
        global dtsi_fname
        set dtsi_fname "zynq/zynq-7000.dtsi"

        #foreach i [get_sw_cores device_tree] {
        #       set common_tcl_file "[hsi get_property "REPOSITORY" $i]/data/common_proc.tcl"
        #       if {[file exists $common_tcl_file]} {
        #               source $common_tcl_file
        #               break
        #       }
        #}
        set path $::env(REPO)
        #set common_tcl_file "$path/device_tree/data/common_proc.tcl"
        #set hw_file "$path/device_tree/data/xillib_hw.tcl"
        #if {[file exists $common_tcl_file]} {
        #    source $common_tcl_file
        #    source $hw_file
        #}

        # create root node
        set master_root_node [gen_root_node $drv_handle]
        set nodes [gen_cpu_nodes $drv_handle]
    }

