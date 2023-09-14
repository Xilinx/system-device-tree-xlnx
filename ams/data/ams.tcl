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

    proc ams_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set drvname [get_drivers $drv_handle]
        set zynq_ultra_ps_handle [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
        if {[llength $zynq_ultra_ps_handle]} {
                set nr_freq [hsi get_property CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ $zynq_ultra_ps_handle]
                if {![string_is_empty $nr_freq]} {
                        set value [scan [expr $nr_freq * 1000000] "%d"]
                        add_prop $node "xlnx,clock-freq" $value int "pcw.dtsi"
                }
        }
        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
        if {[string match -nocase $mainline_ker "none"]} {
          set ams_list "ams_ps ams_pl"
        set family [hsi get_property FAMILY [hsi::current_hw_design]]
        set dts [set_drv_def_dts $drv_handle]
        if {[string match -nocase $family "versal"]} {
        } elseif {[is_zynqmp_platform $family]} {
        }
          foreach ams_name ${ams_list} {
                set node [create_node -n "&${ams_name}" -p root -d "pcw.dtsi"]
                add_prop $node "status" "okay" string "pcw.dtsi"
          }
        }
    }
