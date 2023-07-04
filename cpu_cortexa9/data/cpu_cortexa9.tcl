    proc cpu_cortexa9_generate {drv_handle} {
        global dtsi_fname
        set dtsi_fname "zynq/zynq-7000.dtsi"
        update_system_dts_include [file tail ${dtsi_fname}]
        set amba_node [create_node -n "&amba" -d "pcw.dtsi" -p root]
        set nodes [gen_cpu_nodes $drv_handle]
    }

