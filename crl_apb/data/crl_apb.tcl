#
# (C) Copyright 2020 Xilinx, Inc.
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

namespace eval crl_apb {
proc generate {drv_handle} {
    set node [get_node $drv_handle]
    set dts_file [set_drv_def_dts $drv_handle]
    set node [create_node -l "&zynqmp_reset" -d $dts_file -p root "pcw.dtsi"]
    add_prop $node "status" "okay" string $dts_file
#    hsi::utils::add_new_dts_param "$node" "status" "okay" string
}
}
