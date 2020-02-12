#
# (C) Copyright 2014-2015 Xilinx, Inc.
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

proc generate {drv_handle} {
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
        if { [string match -nocase $proctype "ps7_cortexa9"] }  {
                return
        }
	global dtsi_fname
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
		break
		}
	}
        set proc_type [get_sw_proc_prop IP_NAME]
	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	if {[string match -nocase "$mainline_ker" "v4.17"]} {
		if {[string match -nocase $proc_type "psv_pmc"] } {
                        set dtsi_fname "versal/versal.dtsi"
                } else {
			set dtsi_fname "zynqmp/zynqmp.dtsi"
		}
	} else {
		if {[string match -nocase $proc_type "psv_pmc"] } {
                        set dtsi_fname "versal/versal.dtsi"
                } else {
			set dtsi_fname "zynqmp/zynqmp.dtsi"
		}
	}

	set ip [get_cells -hier $drv_handle]
	set clk ""
	set clkhandle [get_pins -of_objects $ip "CLK"]
	if { [string compare -nocase $clkhandle ""] != 0 } {
		set clk [get_property CLK_FREQ $clkhandle]
	}
	if { [llength $ip]  } {
		set_property CONFIG.clock-frequency    "$clk" $drv_handle
		set_property CONFIG.timebase-frequency "$clk" $drv_handle
	}
	if {[string match -nocase $proc_type "psu_pmu"] } {
		hsi::utils::add_new_property $drv_handle "clock-frequency" hexint [get_property CONFIG.C_FREQ $ip]
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
		set_property CONFIG.i-cache-baseaddr  "$icache_base"      $drv_handle
		set_property CONFIG.i-cache-highaddr  "$icache_high"      $drv_handle
		set_property CONFIG.i-cache-size      "$icache_size"      $drv_handle
		set_property CONFIG.i-cache-line-size "$icache_line_size" $drv_handle
	}
	if { [llength $dcache_size] != 0 } {
		set_property CONFIG.d-cache-baseaddr  "$dcache_base"      $drv_handle
		set_property CONFIG.d-cache-highaddr  "$dcache_high"      $drv_handle
		set_property CONFIG.d-cache-size      "$dcache_size"      $drv_handle
		set_property CONFIG.d-cache-line-size "$dcache_line_size" $drv_handle
	}

	set default_dts [set_drv_def_dts $drv_handle]
	set root_node [add_or_get_dt_node -n / -d ${default_dts}]
	if {[string match -nocase $proc_type "psv_pmu"] } {
		hsi::utils::add_new_dts_param "${root_node}" model "Versal PLM" string ""
	} else {
		hsi::utils::add_new_dts_param "${root_node}" model "ZynqMP PMUFW" string ""
	}
	# create root node
	set master_root_node [gen_root_node $drv_handle]
	set nodes [gen_cpu_nodes $drv_handle]
}
