#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc cpu_cortexa78_generate {drv_handle} {
	global dtsi_fname
	set dtsi_fname "versal-net/versal-net.dtsi"
	update_system_dts_include [file tail ${dtsi_fname}]
	update_system_dts_include [file tail "versal-net-clk-ccf.dtsi"]

	set bus_name "amba"
	set fields [split [get_ip_property $drv_handle NAME] "_"]
        set cpu_nr [lindex $fields end]
        set cpu_node [pcwdt insert root end "&psx_cortexa78_${cpu_nr}"]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        add_prop $cpu_node "xlnx,ip-name" $ip_name string "pcw.dtsi"
        add_prop $cpu_node "bus-handle" $bus_name reference "pcw.dtsi"
        add_prop $cpu_node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $drv_handle] int "pcw.dtsi"
        add_prop $cpu_node "stamp-frequency" [hsi get_property CONFIG.C_TIMESTAMP_CLK_FREQ $drv_handle] int "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle
        set amba_node [create_node -n "&${bus_name}" -d "pcw.dtsi" -p root]
}
