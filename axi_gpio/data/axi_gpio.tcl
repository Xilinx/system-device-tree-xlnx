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

namespace eval axi_gpio {
proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

#	set compatible [get_comp_str $drv_handle]
#	set compatible [append compatible " " "xlnx,xps-gpio-1.00.a"]
#	set_drv_prop $drv_handle compatible "$compatible" stringlist
	pldt append $node compatible "\ \, \"xlnx,xps-gpio-1.00.a\""
	set intr_present [get_property CONFIG.C_INTERRUPT_PRESENT [hsi::get_cells -hier $drv_handle]]
	if {[string match $intr_present "1"]} {
#		set node [gen_peripheral_nodes $drv_handle]
		if {$node != 0} {
			add_prop $node "#interrupt-cells" 2 int "pl.dtsi"
#			hsi::utils::add_new_dts_param "${node}" "#interrupt-cells" 2 int ""
		}
		add_prop $node "interrupt-controller" boolean "pl.dtsi"
#		hsi::utils::add_new_property $drv_handle "interrupt-controller" boolean ""
	}
#	set proc_type [get_sw_proc_prop IP_NAME]
	set proc_type [get_hw_family]
#	set proc_type "psv_cortexa72"
	if {[regexp "kintex*" $proc_type match]} {
			gen_dev_ccf_binding $drv_handle "s_axi_aclk"
			set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_aclk" stringlist
	}
}
}
