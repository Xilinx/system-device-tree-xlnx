#
# (C) Copyright 2014-2021 Xilinx, Inc.
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

namespace eval ::tclapp::xilinx::devicetree::sdps {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
	    set ip [hsi::get_cells -hier $drv_handle]
	    set node [get_node $drv_handle]
	    set dts_file [set_drv_def_dts $drv_handle]
	    set clk_freq [get_ip_param_value $ip C_SDIO_CLK_FREQ_HZ]
	    add_prop $node "clock-frequency" $clk_freq hexint $dts_file
	    set_drv_conf_prop $drv_handle C_MIO_BANK xlnx,mio-bank hexint
	    set_drv_conf_prop $drv_handle C_HAS_CD xlnx,card-detect int
	    set_drv_conf_prop $drv_handle C_HAS_WP xlnx,write-protect int
	}
}

