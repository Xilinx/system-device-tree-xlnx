    proc cpu_cortexa72_generate {drv_handle} {
        global env
        global dtsi_fname
        set dtsi_fname "versal/versal.dtsi"
        set path $env(REPO)
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