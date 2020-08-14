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

namespace eval axi_clk_wiz {  
	proc generate {drv_handle} {
		global env
		global dtsi_fname
		set path $env(REPO)

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		set keyval [pldt append $node compatible "\ \, \"xlnx,clocking-wizard\""]
		set ip [hsi::get_cells -hier $drv_handle]
		gen_speedgrade $drv_handle
		set output_names ""
		for {set i 1} {$i < 8} {incr i} {
			if {[get_property CONFIG.C_CLKOUT${i}_USED $ip] != 0} {
				set freq [get_property CONFIG.C_CLKOUT${i}_OUT_FREQ $ip]
				set pin_name [get_property CONFIG.C_CLK_OUT${i}_PORT $ip]
				set basefrq [string tolower [get_property CONFIG.C_BASEADDR $ip]]
				set pin_name "$basefrq-$pin_name"
				lappend output_names $pin_name
			}
		}
		if {![string_is_empty $output_names]} {
			add_prop $node "clock-output-names" $output_names string "pl.dtsi"
		}


		gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
		set proc_ip [hsi::get_cells -hier $sw_proc]
		set proctype [get_property IP_NAME $proc_ip]
		if {[string match -nocase $proctype "microblaze"] } {
			gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
		}
	}

	proc gen_speedgrade {drv_handle} {
		set speedgrade [get_property SPEEDGRADE [hsi::get_hw_designs]]
		set num [regexp -all -inline -- {[0-9]} $speedgrade]
		if {![string equal $num ""]} {
			set node [get_node $drv_handle]
			add_prop $node "speed-grade" $num int "pl.dtsi"
		}
	}
}
