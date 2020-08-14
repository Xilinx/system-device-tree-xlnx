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

namespace eval axi_timebase_wdt {
	proc generate {drv_handle} {
		global env
		global dtsi_fname
		set path $env(REPO)

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		pldt append $node compatible "\ \, \"xlnx,xps-timebase-wdt-1.00.a\""
		# get bus clock frequency
		set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "S_AXI_ACLK"]
		if {![string equal $clk_freq ""]} {
			add_prop $node "clock-frequency" $clk_freq int "pl.dtsi"
		}
		set_drv_conf_prop $drv_handle "C_WDT_ENABLE_ONCE" "xlnx,wdt-enable-once"
		set_drv_conf_prop $drv_handle "C_WDT_INTERVAL" "xlnx,wdt-interval"
		set_drv_conf_prop $drv_handle "C_ENABLE_WINDOW_WDT" "xlnx,enable-window-wdt"

	}
}
