#
# (C) Copyright 2019-2021 Xilinx, Inc.
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

namespace eval ::tclapp::xilinx::devicetree::ospips {
namespace import ::tclapp::xilinx::devicetree::common::\*
proc generate {drv_handle} {
	set node [get_node $drv_handle]
        set_drv_conf_prop $drv_handle C_OSPI_CLK_FREQ_HZ xlnx,clock-freq int
	set ospi_handle [hsi::get_cells -hier $drv_handle]
        set ospi_mode [get_ip_param_value $ospi_handle "C_OSPI_MODE"]
        set is_stacked 0
        set is_dual 0
        if {$ospi_mode == 1} {
             set is_stacked 1
        }
	add_prop $node "is-dual" $is_dual int "pcw.dtsi"
	add_prop $node "is-stacked" $is_stacked int "pcw.dtsi"
}
}
