    proc cpu_cortexa53_generate {drv_handle} {
        global dtsi_fname
        global env
        set path $env(REPO)
        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
        set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
        if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
                set dtsi_fname "zynqmp/zynqmp.dtsi"
        } else {
                set dtsi_fname "zynqmp/zynqmp.dtsi"
        }
        # create root node
        set master_root_node [gen_root_node $drv_handle]
        set nodes [gen_cpu_nodes $drv_handle]
    }

