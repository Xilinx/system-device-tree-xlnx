#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

