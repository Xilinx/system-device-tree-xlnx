#
# (C) Copyright 2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc ufspsxc_generate {drv_handle} {
	set dts_file [set_drv_def_dts $drv_handle]
	set ip [hsi::get_cells -hier $drv_handle]
	set ref [hsi get_property CONFIG.C_REF_PAD_CLK_FREQ_HZ $ip]
	if {[string_is_empty $ref] || $ref == "-1"} {
		return
	}

	set nref "&ufs_ref_clk"
	if {[lsearch -exact [pcwdt children root] $nref] < 0} {
		set nref [pcwdt insert root end $nref]
	}
	add_prop $nref "clock-frequency" $ref int $dts_file 1
}
