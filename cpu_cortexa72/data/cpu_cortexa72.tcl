#
# (C) Copyright 2018-2019 Xilinx, Inc.
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

namespace eval ::tclapp::xilinx::devicetree::cpu_cortexa72 {
if {0} {
	if {[catch {set tmp [::struct::tree psdt]} msg]} {
	}
	if {[catch {set tmp [::struct::tree pldt]} msg]} {
	}
	if {[catch {set tmp [::struct::tree pcwdt]} msg]} {
	}
	if {[catch {set tmp [::struct::tree systemdt]} msg]} {
	}
	if {[catch {set tmp [::struct::tree clkdt]} msg]} {
	}
}
	namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
		global env
		global dtsi_fname
		set dtsi_fname "versal/versal.dtsi"
		set path $env(REPO)
		set common_tcl_file "$path/device_tree/data/common_proc.tcl"
		set hw_file "$path/device_tree/data/xillib_hw.tcl"
		if {[file exists $common_tcl_file]} {
		    source -notrace $common_tcl_file
		    source -notrace $hw_file
		}

		# create root node
		set master_root_node [gen_root_node $drv_handle]
		set nodes [gen_cpu_nodes $drv_handle]
	}
if {0} {
	namespace export psdt
	namespace export systemdt
	namespace export pldt
	namespace export pcwdt
	namespace export clkdt
}
}
