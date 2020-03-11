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
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}
	set handle [get_cells -hier -filter {IP_NAME==ps7_nand}]
	set reg [get_baseaddr [get_cells -hier $handle]]
	hsi::utils::add_new_property $drv_handle "flashbase" int $reg
	set bus_width [get_property CONFIG.C_NAND_WIDTH [get_cells -hier $handle]]
	hsi::utils::add_new_property $drv_handle "nand-bus-width" int $bus_width
}
