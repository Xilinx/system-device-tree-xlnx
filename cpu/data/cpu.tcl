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

namespace eval cpu {
	proc generate {drv_handle} {
	    set node [get_node $drv_handle]
	    set dts_file [set_drv_def_dts $drv_handle]
	    set ip [hsi::get_cells -hier $drv_handle]
	    set clk ""
	    set clkhandle [hsi::get_pins -of_objects $ip "CLK"]
	    if { [string compare -nocase $clkhandle ""] != 0 } {
		set clk [get_property CLK_FREQ $clkhandle]
	    }
	    if { [llength $ip]  } {
		add_prop $node "clock-frequency" $clk" int $dts_file
		add_prop $node "timebase-frequency" int $dts_file
	    }

	    set icache_size [hsi::utils::get_ip_param_value $ip "C_CACHE_BYTE_SIZE"]
	    set icache_base [hsi::utils::get_ip_param_value $ip "C_ICACHE_BASEADDR"]
	    set icache_high [hsi::utils::get_ip_param_value $ip "C_ICACHE_HIGHADDR"]
	    set dcache_size [hsi::utils::get_ip_param_value $ip "C_DCACHE_BYTE_SIZE"]
	    set dcache_base [hsi::utils::get_ip_param_value $ip "C_DCACHE_BASEADDR"]
	    set dcache_high [hsi::utils::get_ip_param_value $ip "C_DCACHE_HIGHADDR"]
	    set icache_line_size [expr 4*[hsi::utils::get_ip_param_value $ip "C_ICACHE_LINE_LEN"]]
	    set dcache_line_size [expr 4*[hsi::utils::get_ip_param_value $ip "C_DCACHE_LINE_LEN"]]


	    if { [llength $icache_size] != 0 } {
		add_prop $node "i-cache-baseaddr"  "$icache_base" hexint $dtsfile
		add_prop $node "i-cache-highaddr" $icache_high hexint $dtsfile
		add_prop $node "i-cache-size" $icache_size int $dtsfile
		add_prop $node "i-cache-line-size" $icache_line_size int $dtsfile
	    }
	    if { [llength $dcache_size] != 0 } {
		add_prop $node "d-cache-baseaddr"  "$dcache_base" hexint $dtsfile
		add_prop $node "d-cache-highaddr" $dcache_high hexint $dtsfile
		add_prop $node "d-cache-size" $dcache_size int $dtsfile
		add_prop $node "d-cache-line-size" $dcache_line_size int $dtsfile

	    }

	    set model "[get_property IP_NAME $ip],[hsi::utils::get_ip_version $ip]"
	    add_prop $node "model" $model string $dtsfile
	    set_drv_conf_prop $drv_handle C_FAMILY "xlnx,family" string

	    # create root node
	    set master_root_node [gen_root_node $drv_handle]
	    set nodes [gen_cpu_nodes $drv_handle]
	}
}
