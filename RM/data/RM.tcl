#
# (C) Copyright 2017-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc RM_generate {drv_handle} {
        set val [hsi get_property FAMILY [hsi::get_hw_designs]]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts]
        switch -glob $val {
                "zynq" {
                        add_prop $node "fpga-mgr" "<&devcfg>" string $dts_file
                }
        }
    }

