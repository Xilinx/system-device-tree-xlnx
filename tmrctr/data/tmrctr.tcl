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

namespace eval ::tclapp::xilinx::devicetree::tmrctr {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
	     set node [get_node $drv_handle]
	     set dts_file [set_drv_def_dts $drv_handle]
	     pldt append $node compatible "\ \, \"xlnx,xps-timer-1.00.a\""
	    #adding clock frequency
	    set ip [hsi::get_cells -hier $drv_handle]
	    set clk [hsi::get_pins -of_objects $ip "S_AXI_ACLK"]
	    if {[llength $clk] } {
		set freq [get_property CLK_FREQ $clk]
		add_prop $node "clock-frequency" $freq hexint $dts_file
	    }
	    set proctype [get_hw_family]
	    if {[regexp "kintex*" $proctype match]} {
			 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
	    }
	}
}
