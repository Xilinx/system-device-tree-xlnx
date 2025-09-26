#
# (C) Copyright 2020-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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
        set path $env(CUSTOM_SDT_REPO)
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
        set part_num [hsi get_property DEVICE [hsi::current_hw_design]]
        set iochnames "io-channel-names = \"sysmon-temp-channel\""
        set num_aie_sats 0
        if {$part_num == "xcvc1902" || $part_num == "xc2ve3858"} {
            for {set temp_sat_num 0} {$temp_sat_num < 63} {incr temp_sat_num} {
                set temp_sat "SAT_${temp_sat_num}_DESC"
                set value [get_ip_property $drv_handle CONFIG.$temp_sat]
                if {[llength $value] != 0} {
                    set local_value [string tolower [get_ip_property $drv_handle CONFIG.$temp_sat]]
                    if {$local_value == "me satellite"} {
                        set temp_node [create_node -n "temp@$temp_sat_num" -p $node -d $dts_file]
                        add_prop "$temp_node" "reg" "$temp_sat_num" int $dts_file
                        incr num_aie_sats
                        append iochnames ", \"aie-temp-ch$num_aie_sats\""
                        add_prop "$temp_node" "xlnx,name" "aie-temp-ch$num_aie_sats" string $dts_file
                        add_prop "$temp_node" "xlnx,aie-temp" noformating $dts_file
                    }
                }
            }
        }

        proc label_exists {label filename} {
            set search_pattern "$label"
            set fh [open $filename r]
            set content [read $fh]
            close $fh
            if {[regexp "\\m$search_pattern\\M" $content]} {
                return 1
            }
            return 0
        }

        set label "sensor0"
        set common_file "$path/device_tree/data/config.yaml"
        set release [get_user_config $common_file -kernel_ver]
        if {[info exists ::dtsi_fname]} {
            set filename "$path/device_tree/data/kernel_dtsi/$release/$dtsi_fname"
            if {[label_exists $label $filename]} {
                set thermal_sensor [create_node -n "&sensor0" -d "pcw.dtsi" -p root]
                add_prop $thermal_sensor "$iochnames" stringlist "pcw.dtsi"
                add_prop $node "#io-channel-cells" 1 int pcw.dtsi
                set aie_temp_index $num_supply_channels
                set temp_index [expr {$num_supply_channels + $num_aie_sats}]
                set ioch "io-channels = <&sysmon0 $temp_index>"
                if {$num_aie_sats > 0} {
                    for {} {$aie_temp_index < $temp_index} {incr aie_temp_index} {
                        append ioch ", <&sysmon0 $aie_temp_index>"
                    }
                }
                add_prop $thermal_sensor "$ioch" noformating "pcw.dtsi"
            }
        }
    }


