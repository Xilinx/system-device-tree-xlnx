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

		pldt append $node compatible "\ \, \"xlnx,xps-gpio-1.00.a\""
		set intr_present [get_property CONFIG.C_INTERRUPT_PRESENT [hsi::get_cells -hier $drv_handle]]
		if {[string match $intr_present "1"]} {
			if {$node != 0} {
				add_prop $node "#interrupt-cells" 2 int "pl.dtsi"
			}
			add_prop $node "interrupt-controller" boolean "pl.dtsi"
		}
		set proc_type [get_hw_family]
		if {[regexp "kintex*" $proc_type match]} {
				gen_dev_ccf_binding $drv_handle "s_axi_aclk"
				set_drv_prop_if_empty $drv_handle "clock-names" "s_axi_aclk" stringlist
		}
	}
}
