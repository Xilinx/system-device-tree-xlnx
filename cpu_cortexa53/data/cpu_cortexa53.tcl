    proc cpu_cortexa53_generate {drv_handle} {
        global dtsi_fname
        set dtsi_fname "zynqmp/zynqmp.dtsi"
        update_system_dts_include [file tail ${dtsi_fname}]
        update_system_dts_include [file tail "zynqmp-clk-ccf.dtsi"]
        set bus_name "amba"
        set ip_name [get_ip_property $drv_handle IP_NAME]
        set cpu_nr [string index [get_ip_property $drv_handle NAME] end]
        set cpu_node [pcwdt insert root end "&psu_cortexa53_${cpu_nr}"]
        add_prop $cpu_node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $drv_handle] int "pcw.dtsi"
        add_prop $cpu_node "stamp-frequency" [hsi get_property CONFIG.C_TIMESTAMP_CLK_FREQ $drv_handle] int "pcw.dtsi"
        add_prop $cpu_node "xlnx,ip-name" $ip_name string "pcw.dtsi"
        add_prop $cpu_node "bus-handle" $bus_name reference "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle
        gen_pss_ref_clk_freq $drv_handle $cpu_node $ip_name

        set amba_node [create_node -n "&${bus_name}" -d "pcw.dtsi" -p root]
    }

