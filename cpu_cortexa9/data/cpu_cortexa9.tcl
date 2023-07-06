    proc cpu_cortexa9_generate {drv_handle} {
        global dtsi_fname
        set dtsi_fname "zynq/zynq-7000.dtsi"
        update_system_dts_include [file tail ${dtsi_fname}]
        set bus_name "amba"
        # TODO: Figure out a way to get the current number of processor
        set cpu_nr [string index [get_ip_property $drv_handle NAME] end]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        set cpu_node [pcwdt insert root end "&ps7_cortexa9_${cpu_nr}"]
        add_prop $cpu_node "xlnx,ip-name" $ip_name string "pcw.dtsi"
        add_prop $cpu_node "bus-handle" $bus_name reference "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle
        set amba_node [create_node -n "&${bus_name}" -d "pcw.dtsi" -p root]
    }

