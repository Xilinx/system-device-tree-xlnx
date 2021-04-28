#
# (C) Copyright 2014-2015 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
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

namespace eval ::tclapp::xilinx::devicetree::cpu {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
	set proctype [get_hw_family]
	set bus_name [detect_bus_name $drv_handle]
	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		set node [create_node -n "cpus_microblaze" -l "cpus_microblaze_2" -u 2 -d "pl.dtsi" -p $bus_name]
	} elseif {[string match -nocase $proctype "versal"]} {
		set node [create_node -n "cpus_microblaze" -l "cpus_microblaze_3" -u 3 -d "pl.dtsi" -p $bus_name]
	}
	set node [create_node -n "cpu" -u 0 -d "pl.dtsi" -p $node]
        set dts_file [set_drv_def_dts $drv_handle]
	set ip [hsi::get_cells -hier $drv_handle]
	set clk ""
	set clkhandle [hsi::get_pins -of_objects $ip "CLK"]
	if { [string compare -nocase $clkhandle ""] != 0 } {
		set clk [get_property CLK_FREQ $clkhandle]
	}
	if { [llength $ip]  } {
		add_prop $node "clock-frequency" $clk int $dts_file
		add_prop $node "timebase-frequency" $clk int $dts_file
	}
	set icache_size [get_ip_param_value $ip "C_CACHE_BYTE_SIZE"]
	set isize  [check_64bit $icache_size]
	set icache_base [get_ip_param_value $ip "C_ICACHE_BASEADDR"]
	set ibase  [check_64bit $icache_base]
	set icache_high [get_ip_param_value $ip "C_ICACHE_HIGHADDR"]
	set ihigh_base  [check_64bit $icache_high]
	set dcache_size [get_ip_param_value $ip "C_DCACHE_BYTE_SIZE"]
	set dsize  [check_64bit $dcache_size]
	set dcache_base [get_ip_param_value $ip "C_DCACHE_BASEADDR"]
	set dbase  [check_64bit $dcache_base]
	set dcache_high [get_ip_param_value $ip "C_DCACHE_HIGHADDR"]
	set dhigh_base  [check_64bit $dcache_high]
	set icache_line_size [expr 4*[get_ip_param_value $ip "C_ICACHE_LINE_LEN"]]
	set dcache_line_size [expr 4*[get_ip_param_value $ip "C_DCACHE_LINE_LEN"]]


	if { [llength $icache_size] != 0 } {
		add_prop $node "i-cache-baseaddr"  "$ibase" hexint $dts_file
		add_prop $node "i-cache-highaddr" $ihigh_base hexint $dts_file
		add_prop $node "i-cache-size" $isize int $dts_file
		add_prop $node "i-cache-line-size" $icache_line_size int $dts_file
	}
	if { [llength $dcache_size] != 0 } {
		add_prop $node "d-cache-baseaddr"  "$dbase" hexint $dts_file
		add_prop $node "d-cache-highaddr" $dhigh_base hexint $dts_file
		add_prop $node "d-cache-size" $dsize int $dts_file
		add_prop $node "d-cache-line-size" $dcache_line_size int $dts_file
	}
	set model "[get_property IP_NAME $ip],[get_ip_version $ip]"
	add_prop $node "model" $model string $dts_file
	#set_drv_conf_prop $drv_handle C_FAMILY "xlnx,family" string
        set family [get_property C_FAMILY [hsi::get_cells -hier $drv_handle]]
	add_prop $node "xlnx,family" $family string $dts_file
	# create root node
	set master_root_node [gen_root_node $drv_handle]
	set nodes [gen_cpu_nodes $drv_handle]
   }

	proc check_64bit {base} {
       		if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
               		set temp $base
	               set temp [string trimleft [string trimleft $temp 0] x]
	               set len [string length $temp]
	               set rem [expr {${len} - 8}]
	               set high_base "0x[string range $temp $rem $len]"
	               set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
	               set low_base [format 0x%08x $low_base]
	               set reg "$low_base $high_base"
	       } else {
        		set reg "$base"
       		}
	       return $reg
	}

}
