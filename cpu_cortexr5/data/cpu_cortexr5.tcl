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

proc generate {drv_handle} {
	set nr [string index $drv_handle end]
	set dts_file [set_drv_def_dts $drv_handle]
	global dtsi_fname
	global env
	set path $env(REPO)

	set drvname [get_drivers $drv_handle]

	set common_file "$path/device_tree/data/config.yaml"
	set mainline_ker [get_user_config $common_file --mainline_kernel]
	set ip [hsi::get_cells -hier $drv_handle]
	set default_dts [set_drv_def_dts $drv_handle]
	# create root node
	set master_root_node [gen_root_node $drv_handle]
	set nodes [gen_cpu_nodes $drv_handle]
}
