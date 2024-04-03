#
# (C) Copyright 2014-2021 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc cpu_cortexr5_generate {drv_handle} {
        set ip_name [get_ip_property $drv_handle IP_NAME]
        set fields [split [get_ip_property $drv_handle NAME] "_"]
        set cpu_nr [lindex $fields end]
        if {[string match -nocase $ip_name "psu_cortexr5"]} {
                set node [create_node -n "&psu_cortexr5_${cpu_nr}" -d "pcw.dtsi" -p root -h $drv_handle]
        } elseif {[string match -nocase $ip_name "psv_cortexr5"]} {
                set node [create_node -n "&psv_cortexr5_${cpu_nr}" -d "pcw.dtsi" -p root -h $drv_handle]
        } elseif {[string match -nocase $ip_name "psx_cortexr52"]} {
                set node [create_node -n "&psx_cortexr52_${cpu_nr}" -d "pcw.dtsi" -p root -h $drv_handle]
        } else {
                error "Driver cpu_cortexr5 is not valid for given handle $drv_handle"
        }
        add_prop $node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $drv_handle] int "pcw.dtsi"
        add_prop $node "xlnx,ip-name" $ip_name string "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle

        gen_pss_ref_clk_freq $drv_handle $node $ip_name
        add_prop $node "bus-handle" "amba" reference "pcw.dtsi"
    }

