    proc cpu_cortexa53_generate {drv_handle} {
        global dtsi_fname
        set dtsi_fname "zynqmp/zynqmp.dtsi"
        update_system_dts_include [file tail ${dtsi_fname}]
        update_system_dts_include [file tail "zynqmp-clk-ccf.dtsi"]
        set amba_node [create_node -n "&amba" -d "pcw.dtsi" -p root]
        set nodes [gen_cpu_nodes $drv_handle]
    }

