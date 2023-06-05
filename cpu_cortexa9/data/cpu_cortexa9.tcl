    proc cpu_cortexa9_generate {drv_handle} {
        global dtsi_fname
        set dtsi_fname "zynq/zynq-7000.dtsi"
        set path $::env(REPO)
        # create root node
        set master_root_node [gen_root_node $drv_handle]
        set nodes [gen_cpu_nodes $drv_handle]
    }

