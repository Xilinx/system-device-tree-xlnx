#
# (C) Copyright 2014-2021 Xilinx, Inc.
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
namespace eval ::tclapp::xilinx::devicetree::axi_emc { 
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
		global env
		global dtsi_fname
		set path $env(REPO)

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}


		set ip [hsi::get_cells -hier $drv_handle]
		pldt append $node compatible "\ \, \"cfi-flash\""
		set count [get_ip_param_value $ip "C_NUM_BANKS_MEM"]
		if { [llength $count] == 0 } {
			set count 1
		}
		for {set x 0} { $x < $count} {incr x} {
			set datawidth [get_ip_param_value $ip [format "C_MEM%d_WIDTH" $x]]
			add_prop $node "bank-width" [expr ($datawidth/8)] int "pl.dtsi"
		}
	}
}
