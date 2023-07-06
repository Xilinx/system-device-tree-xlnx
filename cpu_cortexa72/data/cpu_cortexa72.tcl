    proc cpu_cortexa72_generate {drv_handle} {
        global dtsi_fname
        set dtsi_fname "versal/versal.dtsi"
        update_system_dts_include [file tail ${dtsi_fname}]
        update_system_dts_include "versal-clk.dtsi"
        set bus_name "amba"
        set cpu_nr [string index [get_ip_property $drv_handle NAME] end]
        set cpu_node [pcwdt insert root end "&psv_cortexa72_${cpu_nr}"]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        add_prop $cpu_node "xlnx,ip-name" $ip_name string "pcw.dtsi"
        add_prop $cpu_node "bus-handle" $bus_name reference "pcw.dtsi"
        add_prop $cpu_node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $drv_handle] int "pcw.dtsi"
        add_prop $cpu_node "stamp-frequency" [hsi get_property CONFIG.C_TIMESTAMP_CLK_FREQ $drv_handle] int "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle
        set amba_node [create_node -n "&${bus_name}" -d "pcw.dtsi" -p root]
    }