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

namespace eval pmups {
proc generate {drv_handle} {
	#set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	#set node [create_node -n cpu -l "cpu2" -d $dts_file -p "cpus_microblaze: cpus_microblaze" -u 2]
	set ip_name [get_property IP_NAME [hsi::get_cells $drv_handle]]
	if {[string match -nocase $ip_name "psu_pmu"]} {
		set node "&cpu6"
	} elseif {[string match -nocase $ip_name "psv_pmc"]} {
		set node "&cpu2"
	} else {
		set node "&cpu3"
	}
	global env
        set path $env(REPO)

#	set dts_file [set_drv_def_dts $drv_handle]
        set drvname [get_drivers $drv_handle]
        #puts "drvname $drvname"

        set common_file "$path/device_tree/data/config.yaml"
        if {[file exists $common_file]} {
                #error "file not found: $common_file"
        }
        set mainline_ker [get_user_config $common_file -mainline_kernel]
	global dtsi_fname
        set proc_type [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
	#set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
 	if {0} {
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
	}
	set master_root_node [gen_root_node $drv_handle]
	set nodes [gen_cpu_nodes $drv_handle]
	set ip [hsi::get_cells -hier $drv_handle]
	set clk ""
	set clkhandle [hsi::get_pins -of_objects $ip "CLK"]
	if { [string compare -nocase $clkhandle ""] != 0 } {
		set clk [get_property CLK_FREQ $clkhandle]
	}
	if { [llength $ip]  } {
		if {$clk != ""} {
		add_prop $node "clock-freqeuency" $clk int $dts_file
		add_prop $node "timebase-frequency" $clk int $dts_file
		}
#		set_property CONFIG.clock-frequency    "$clk" $drv_handle
#		set_property CONFIG.timebase-frequency "$clk" $drv_handle
	}
	if {[string match -nocase $proc_type "psu_pmu"] } {
		add_prop $node "clock-frequency" [get_property CONFIG.C_FREQ $ip] hexint $dts_file
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
        add_prop $node "i-cache-baseaddr"  "$icache_base" hexint $dts_file
        add_prop $node "i-cache-highaddr" $icache_high hexint $dts_file
        add_prop $node "i-cache-size" $icache_size int $dts_file
        add_prop $node "i-cache-line-size" $icache_line_size int $dts_file
    }
    if { [llength $dcache_size] != 0 } {
        add_prop $node "d-cache-baseaddr"  "$dcache_base" hexint $dts_file
        add_prop $node "d-cache-highaddr" $dcache_high hexint $dts_file
        add_prop $node "d-cache-size" $dcache_size int $dts_file
        add_prop $node "d-cache-line-size" $dcache_line_size int $dts_file

    }



#	set root_node [add_or_get_dt_node -n / -d ${default_dts}]
#	if {[string match -nocase $proc_type "psv_pmu"] } {
#		add_prop "${root_node}" model "Versal PLM" string ""
#	} else {
#		add_prop "${root_node}" model "ZynqMP PMUFW" string ""
#	}
	# create root node

}
}
