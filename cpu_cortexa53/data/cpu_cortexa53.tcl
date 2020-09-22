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

namespace eval cpu_cortexa53 {
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
	proc generate {drv_handle} {
		global dtsi_fname
		global env
		set path $env(REPO)
		set common_file "$path/device_tree/data/config.yaml"
		if {[file exists $common_file]} {
			#error "file not found: $common_file"
		}
		set mainline_ker [get_user_config $common_file -mainline_kernel]
		set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
		if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
			set dtsi_fname "zynqmp/zynqmp.dtsi"
		} else {
			set dtsi_fname "zynqmp/zynqmp.dtsi"
		}
		# create root node
		set master_root_node [gen_root_node $drv_handle]
		set nodes [gen_cpu_nodes $drv_handle]
	}
	namespace export psdt
	namespace export systemdt
	namespace export pldt
	namespace export pcwdt
	namespace export clkdt
}
