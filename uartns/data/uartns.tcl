#
# (C) Copyright 2014-2015 Xilinx, Inc.
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

namespace eval ::tclapp::xilinx::devicetree::uartns {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
	    set node [get_node $drv_handle]
	    set dts_file [set_drv_def_dts $drv_handle]
	    set ip [hsi::get_cells -hier $drv_handle]
	    set has_xin [get_ip_param_value $ip C_HAS_EXTERNAL_XIN]
	    set clock_port "S_AXI_ACLK"
	    if { [string match -nocase "$has_xin" "1"] } {
		set_drv_conf_prop $drv_handle C_EXTERNAL_XIN_CLK_HZ clock-frequency
		# TODO: update the clock-names and clocks properties and create a
		# fixed clock node. Currently this is causing any issue as the
		# driver only uses clock-frequency property

	    } else {
		set freq [get_clk_pin_freq $ip "$clock_port"]
		add_prop $node "clock-frequency" hexint $dts_file
	    }

#	    set_os_parameter_value "console" "ttyS0,115200"

	    set proctype [get_hw_family]
	    if {[regexp "kintex*" $proctype match]} {
			 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
	    }
	}
}
