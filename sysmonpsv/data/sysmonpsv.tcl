#
# (C) Copyright 2020-2022 Xilinx, Inc.
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

    proc sysmonpsv_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        
        set num_supply_channels 0
        add_prop $node "#address-cells" 2 int $dts_file
        add_prop $node "#size-cells" 2 int $dts_file

        for {set supply_num 0} {$supply_num < 160} {incr supply_num} {
            set meas "C_MEAS_${supply_num}"
            set id "${meas}_ROOT_ID"
            set value [hsi get_property CONFIG.$meas [hsi::get_cells -hier $drv_handle]]
            if {[llength $value] != 0} {
                    set local_value [string tolower [hsi get_property CONFIG.$meas [hsi::get_cells -hier $drv_handle]]]
                    set id_value [hsi get_property CONFIG.$id [hsi::get_cells -hier $drv_handle]]
                    set supply_node [create_node -n "supply@$id_value" -p $node -d $dts_file]
                    add_prop "$supply_node" "reg" "$id_value" int $dts_file
                    add_prop "$supply_node" "xlnx,name" "$local_value" string $dts_file
                    incr num_supply_channels
            }
        }
        append numsupplies "/bits/8 <$num_supply_channels>"
        add_prop $node "xlnx,numchannels" $numsupplies noformating $dts_file
    }


