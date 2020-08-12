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

namespace eval axi_iic {
proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

   # set compatible [get_comp_str $drv_handle]
   # set compatible [append compatible " " "xlnx,xps-iic-2.00.a"]
   # set_drv_prop $drv_handle compatible "$compatible" stringlist
    pldt append $node compatible "$compatible" stringlist "pl.dtsi"
#    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	set proctype [get_hw_family]
	if {[regexp "kintex*" $proctype match]} {
        gen_dev_ccf_binding $drv_handle "s_axi_aclk"
    }
}
}
