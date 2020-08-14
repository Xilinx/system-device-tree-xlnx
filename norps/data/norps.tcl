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

namespace eval norps {
	proc generate {drv_handle} {
	  
	    # TODO: if addr25 is used, should we consider set the reg size to 64MB?
	    # enable reg generation for ps ip
	    gen_reg_property $drv_handle "enable_ps_ip"
	}
}
