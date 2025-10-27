#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

    proc cpu_cortexa72_generate {drv_handle} {
        global dtsi_fname
        global is_versal_2vp_platform
        set dtsi_fname "versal/versal.dtsi"
        if {$is_versal_2vp_platform} {
                set dtsi_fname "versal/versal2vp.dtsi"
        }
        update_system_dts_include [file tail ${dtsi_fname}]
        update_system_dts_include "versal-clk.dtsi"
        set bus_name "amba"
        set cpu_nr [string index [get_ip_property $drv_handle NAME] end]
        set cpu_node [create_node -n "&psv_cortexa72_${cpu_nr}" -d "pcw.dtsi" -p root -h $drv_handle]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        add_prop $cpu_node "xlnx,ip-name" $ip_name string "pcw.dtsi"
        add_prop $cpu_node "bus-handle" $bus_name reference "pcw.dtsi"
        add_prop $cpu_node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $drv_handle] int "pcw.dtsi"
        add_prop $cpu_node "stamp-frequency" [hsi get_property CONFIG.C_TIMESTAMP_CLK_FREQ $drv_handle] int "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle
        gen_pss_ref_clk_freq $drv_handle $cpu_node $ip_name
        set amba_node [create_node -n "&${bus_name}" -d "pcw.dtsi" -p root]

        global 64_bit_processor_list
        lappend 64_bit_processor_list $drv_handle
    }