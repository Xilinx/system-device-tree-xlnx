#
# (C) Copyright 2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc linear_spi_generate {drv_handle} {
	set baseaddr [get_baseaddr $drv_handle no_prefix]
	set memory_node [create_node -n "memory" -l "${drv_handle}_memory" -u $baseaddr -p root -d "system-top.dts"]
	add_prop "${memory_node}" "device_type" "memory" string "system-top.dts" 1
	set mem_compatible_string [gen_compatible_string $drv_handle]
	if {![string_is_empty $mem_compatible_string]} {
		add_prop ${memory_node} "compatible" "${mem_compatible_string}-memory" string "system-top.dts"
	}
	set reg [gen_reg_property $drv_handle "skip_ps_check" 0]
	if {![string_is_empty $reg]} {
		add_prop "${memory_node}" "reg" $reg hexlist "system-top.dts" 1
	}
	add_prop "${memory_node}" "xlnx,ip-name" [get_ip_property $drv_handle IP_NAME] string "system-top.dts"
	add_prop "${memory_node}" "memory_type" "linear_flash" string "system-top.dts"
}
