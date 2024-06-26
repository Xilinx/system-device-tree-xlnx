#
# (C) Copyright 2014-2022 Xilinx, Inc.
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

    proc ramps_generate {drv_handle} {
        # Currently only running it for Zynq, need to extend it for other platforms as well.
        set slave [hsi::get_cells -hier ${drv_handle}]
        set addr [get_baseaddr $drv_handle noprefix]
        set memory_node [create_node -n "memory" -l "${drv_handle}_memory" -u $addr -p root -d "system-top.dts"]
        add_prop "${memory_node}" "device_type" "memory" string "system-top.dts"
        add_prop "${memory_node}" "compatible" [gen_compatible_string $slave] string "system-top.dts"
        set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
        set proc_scanned ""
        foreach procc $proclist {
                set proc_ip [hsi get_property IP_NAME $procc]
                if {[lsearch $proc_scanned $proc_ip] >= 0} {
                        continue
                } else {
                        lappend proc_scanned $proc_ip
                }

                set ip_mem_handle_list [hsi::get_mem_ranges -of_objects $procc [hsi::get_cells -hier $slave]]
                if { [string_is_empty $ip_mem_handle_list] } {
                        continue
                }

                foreach bank ${ip_mem_handle_list} {
                        set base [format 0x%x [hsi get_property BASE_VALUE $bank]]
                        set high [format 0x%x [hsi get_property HIGH_VALUE $bank]]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
                        set regval "0x0 ${base} 0x0 ${size}"
                        set_memmap "${drv_handle}_memory" a53 $regval
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "ps7_cortexa9"]} {
                                set regval "$base $size"
                        }
                }
        }
        add_prop "${memory_node}" "reg" "$regval" hexlist "system-top.dts"
        add_prop "${memory_node}" "xlnx,ip-name" [get_ip_property $drv_handle IP_NAME] string "system-top.dts"
        add_prop "${memory_node}" "memory_type" "memory" string "system-top.dts"
    }


