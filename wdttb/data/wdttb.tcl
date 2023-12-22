#
# (C) Copyright 2023-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc wdttb_generate {drv_handle} {
		set dts_file [set_drv_def_dts $drv_handle]
        set node [get_node $drv_handle]
		#Add a node to enable winwdt examples in PS and PL
		add_prop $node "xlnx,winwdt-example" 1 int $dts_file

	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		add_prop $node compatible "xlnx,versal-wwdt-1.0 xlnx,versal-wwdt" stringlist $dts_file
	}
    }
