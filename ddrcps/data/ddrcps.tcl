#
# (C) Copyright 2014-2015 Xilinx, Inc.
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
	foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
                source $common_tcl_file
                break
                }
        }


        set par_handles [get_ip_conf_prop_list $drv_handle "CONFIG.C_.*"]
        set valid_prop_names {}
        foreach par $par_handles {
                regsub -all {CONFIG.} $par {} tmp_par
                lappend valid_prop_names $par
        }
        set proplist $valid_prop_names
        foreach prop_name ${proplist} {
                ip2drv_prop $drv_handle $prop_name
        }
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if { [string match -nocase $proctype "ps7_cortexa9"] }  {
		return
	}
	set zynq_periph [get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
        set avail_param [list_property [get_cells -hier $zynq_periph]]
        if {[lsearch -nocase $avail_param "CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING"] >= 0} {
		set val [get_property CONFIG.PSU__DDRC__DDR4_ADDR_MAPPING [get_cells -hier $zynq_periph]]
		hsi::utils::add_new_property $drv_handle "xlnx,addr-mapping" hexint $val
        }
	if {[lsearch -nocase $avail_param "CONFIG.PSU__ACT_DDR_FREQ_MHZ"] >= 0} {
		set val [get_property CONFIG.PSU__ACT_DDR_FREQ_MHZ [get_cells -hier $zynq_periph]]
		hsi::utils::add_new_property $drv_handle "xlnx,ddr-freq" int [scan [expr $val * 1000000] "%d"]
	}
	if {[lsearch -nocase $avail_param "CONFIG.PSU__DDRC__VIDEO_BUFFER_SIZE"] >= 0} {
		set val [get_property CONFIG.PSU__DDRC__VIDEO_BUFFER_SIZE [get_cells -hier $zynq_periph]]
		hsi::utils::add_new_property $drv_handle "xlnx,video-buf-size" hexint $val
	}
	if {[lsearch -nocase $avail_param "CONFIG.PSU__DDRC__BRC_MAPPING"] >= 0} {
		set val [get_property CONFIG.PSU__DDRC__BRC_MAPPING [get_cells -hier $zynq_periph]]
		if { [string match -nocase $val "ROW_BANK_COL"] } {
			hsi::utils::add_new_property $drv_handle "xlnx,brc-mapping" hexint "0"
		} else {
			hsi::utils::add_new_property $drv_handle "xlnx,brc-mapping" hexint "1"
		}
	}
}
