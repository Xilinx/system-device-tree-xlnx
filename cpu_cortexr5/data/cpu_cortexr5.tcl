    proc cpu_cortexr5_generate {drv_handle} {
        set nr [string index $drv_handle end]
        set dts_file [set_drv_def_dts $drv_handle]
        global dtsi_fname
        global env
        set path $env(REPO)

        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
        set ip [hsi::get_cells -hier $drv_handle]
        set default_dts [set_drv_def_dts $drv_handle]
        # create root node
        set master_root_node [gen_root_node $drv_handle]
        set nodes [gen_cpu_nodes $drv_handle]
    }

