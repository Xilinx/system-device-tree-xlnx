#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Michal SIMEK <monstr@monstr.eu>
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

    proc cpu_generate {drv_handle} {
        global mb_dict_64_bit
        set proctype [get_hw_family]
        set bus_name [add_or_get_bus_node $drv_handle "pl.dtsi"]
        set nr [get_microblaze_nr $drv_handle]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        set node [create_node -n "cpus_${ip_name}" -l "cpus_${ip_name}_${nr}" -u $nr -d "pl.dtsi" -p $bus_name]
        add_prop $node "compatible" "cpus,cluster" string "pl.dtsi"
        add_prop $node "#cpu-mask-cells" 1 int "pl.dtsi"
        add_prop $node #address-cells 1 int "pl.dtsi"
        add_prop $node #size-cells 0 int "pl.dtsi"
        set node [create_node -n "cpu" -l "$drv_handle" -u $nr -d "pl.dtsi" -p $node]
        set comp_prop [gen_compatible_string $drv_handle]
        add_prop $node compatible "$comp_prop xlnx,${ip_name}" stringlist "pl.dtsi"
        add_prop $node "xlnx,ip-name" $ip_name string "pl.dtsi"
        set model "$ip_name,[get_ip_version $drv_handle]"
        add_prop $node "model" $model string "pl.dtsi"
	if {[string match -nocase $ip_name "microblaze"]} {
		set family [hsi get_property CONFIG.C_FAMILY $drv_handle]
		add_prop $node "xlnx,family" $family string "pl.dtsi"
	}
        add_prop $node "reg" $nr hexint "pl.dtsi"
        add_prop $node "bus-handle" "amba_pl" reference "pl.dtsi"

        set clk ""
        set clkhandle [hsi::get_pins -of_objects $drv_handle "CLK"]

        if { [string compare -nocase $clkhandle ""] != 0 } {
                set clk [hsi get_property CLK_FREQ $clkhandle]
        }
        if { [llength $drv_handle]  } {
                add_prop $node "clock-frequency" $clk int "pl.dtsi"
                add_prop $node "timebase-frequency" $clk int "pl.dtsi"
        }

        set icache_size [get_ip_param_value $drv_handle "C_CACHE_BYTE_SIZE"]
        set isize  [cpu_check_64bit $icache_size]
        set icache_base [get_ip_param_value $drv_handle "C_ICACHE_BASEADDR"]
        set ibase  [cpu_check_64bit $icache_base]
        set icache_high [get_ip_param_value $drv_handle "C_ICACHE_HIGHADDR"]
        set ihigh_base  [cpu_check_64bit $icache_high]
        set dcache_size [get_ip_param_value $drv_handle "C_DCACHE_BYTE_SIZE"]
        set dsize  [cpu_check_64bit $dcache_size]
        set dcache_base [get_ip_param_value $drv_handle "C_DCACHE_BASEADDR"]
        set dbase  [cpu_check_64bit $dcache_base]
        set dcache_high [get_ip_param_value $drv_handle "C_DCACHE_HIGHADDR"]
        set dhigh_base  [cpu_check_64bit $dcache_high]
        set icache_line_size [expr 4*[get_ip_param_value $drv_handle "C_ICACHE_LINE_LEN"]]
        set dcache_line_size [expr 4*[get_ip_param_value $drv_handle "C_DCACHE_LINE_LEN"]]


        if { [llength $icache_size] != 0 } {
                add_prop $node "i-cache-baseaddr"  "$ibase" hexint "pl.dtsi"
                add_prop $node "i-cache-highaddr" $ihigh_base hexint "pl.dtsi"
                add_prop $node "i-cache-size" $isize int "pl.dtsi"
                add_prop $node "i-cache-line-size" $icache_line_size int "pl.dtsi"
        }
        if { [llength $dcache_size] != 0 } {
                add_prop $node "d-cache-baseaddr"  "$dbase" hexint "pl.dtsi"
                add_prop $node "d-cache-highaddr" $dhigh_base hexint "pl.dtsi"
                add_prop $node "d-cache-size" $dsize int "pl.dtsi"
                add_prop $node "d-cache-line-size" $dcache_line_size int "pl.dtsi"
        }

        gen_mb_interrupt_property $drv_handle
        gen_drv_prop_from_ip $drv_handle
        generate_mb_ccf_node $drv_handle

        set addr_size [get_ip_property $drv_handle CONFIG.C_ADDR_SIZE]
        if {![string_is_empty $addr_size]} {
                set cell_size 1
                if {[expr $addr_size] > 32} {
                        set cell_size 2
                }
                dict set mb_dict_64_bit $drv_handle $cell_size
        }
    }

    proc cpu_check_64bit {base} {
        if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                        set temp $base
                   set temp [string trimleft [string trimleft $temp 0] x]
                   set len [string length $temp]
                   set rem [expr {${len} - 8}]
                   set high_base "0x[string range $temp $rem $len]"
                   set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                   set low_base [format 0x%08x $low_base]
               if {$low_base == 0x0} {
                   set reg "$high_base"
                } else {
                        set reg "$low_base $high_base"
                }
           } else {
                set reg "$base"
        }
           return $reg
    }
