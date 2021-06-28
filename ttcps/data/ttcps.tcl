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

namespace eval ::tclapp::xilinx::devicetree::ttcps {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
		set_drv_conf_prop $drv_handle C_TTC_CLK0_FREQ_HZ xlnx,clock-freq int
	}
}
