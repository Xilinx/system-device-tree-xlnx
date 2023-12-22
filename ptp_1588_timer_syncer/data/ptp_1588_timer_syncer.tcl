#
# (C) Copyright 2021-2022 Xilinx, Inc.
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

    proc ptp_1588_timer_syncer_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        set compatible [get_comp_str $drv_handle]
        set ip_ver     [get_comp_ver $drv_handle]
        if {[string match -nocase $ip_ver "3.0"] || [string match -nocase $ip_ver "2.0"]} {
                set keyval [pldt append $node compatible "\ \, \"xlnx,timer-syncer-1588-3.0\""]
        } elseif  {[string match -nocase $ip_ver "1.0"]} {
                set keyval [pldt append $node compatible "\ \, \"xlnx,timer-syncer-1588-1.0\""]
        }
        set_drv_prop $drv_handle compatible "$compatible" $node noformating
    }



