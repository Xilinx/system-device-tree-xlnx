#
# (C) Copyright 2014-2022 Xilinx, Inc.
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

    proc ddrcps_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set par_handles [get_ip_conf_prop_list $drv_handle "CONFIG.C_.*"]
        set valid_prop_names {}
        foreach par $par_handles {
                regsub -all {CONFIG.} $par {} tmp_par
                lappend valid_prop_names $par
        }
        set proplist $valid_prop_names
        set proctype [get_hw_family]
        if { [string match -nocase $proctype "zynq"] }  {
                return
        }
        set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
        set avail_param [hsi list_property [hsi::get_cells -hier $zynq_periph]]
        if {[lsearch -nocase $avail_param "CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING"] >= 0} {
                set val [hsi get_property CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING [hsi::get_cells -hier $zynq_periph]]
                if {[string match -nocase $val "NA"]} {
                } else {
                        add_prop $node "xlnx,addr-mapping" $val hexint $dts_file
                }
        }
        if {[lsearch -nocase $avail_param "CONFIG.PSU__ACT_DDR_FREQ_MHZ"] >= 0} {
                set val [hsi get_property CONFIG.PSU__ACT_DDR_FREQ_MHZ [hsi::get_cells -hier $zynq_periph]]
                add_prop $node "xlnx,ddr-freq" [scan [expr $val * 1000000] "%d"] int $dts_file
        }
        if {[lsearch -nocase $avail_param "CONFIG.PSU__DDRC__VIDEO_BUFFER_SIZE"] >= 0} {
                set val [hsi get_property CONFIG.PSU__DDRC__VIDEO_BUFFER_SIZE [hsi::get_cells -hier $zynq_periph]]
                add_prop $node "xlnx,video-buf-size" $val hexint $dts_file
        }
        if {[lsearch -nocase $avail_param "CONFIG.PSU__DDRC__BRC_MAPPING"] >= 0} {
                set val [hsi get_property CONFIG.PSU__DDRC__BRC_MAPPING [hsi::get_cells -hier $zynq_periph]]
                if { [string match -nocase $val "ROW_BANK_COL"] } {
                        add_prop $node "xlnx,brc-mapping" "0" hexint $dts_file
                } else {
                        add_prop $node "xlnx,brc-mapping" "1" hexint $dts_file
                }
        }
    }


