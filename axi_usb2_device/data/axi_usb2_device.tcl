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

namespace eval axi_usb2_device {
	proc generate {drv_handle} {
		global env
		global dtsi_fname
		set path $env(REPO)

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		pldt append $node compatible "\ \, \"xlnx,usb2-device-4.00.a\""
		set ip [hsi::get_cells -hier $drv_handle]
		set include_dma [get_property CONFIG.C_INCLUDE_DMA $ip]
		if { $include_dma eq "1"} {
			set_drv_conf_prop $drv_handle C_INCLUDE_DMA xlnx,has-builtin-dma boolean
		}

	}
}
