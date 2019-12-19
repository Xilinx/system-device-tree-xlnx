#
# (C) Copyright 2014-2019 Xilinx, Inc.
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

        set slave [get_cells -hier $drv_handle]
	set pit_used ""
	set dev_type [get_property CONFIG.dev_type $drv_handle]
	set unit_addr [get_baseaddr ${slave} no_prefix]
	set default_dts [set_drv_def_dts $drv_handle]
        set bus_node [add_or_get_bus_node $slave $default_dts]
	set node [add_or_get_dt_node -n $dev_type -l $drv_handle -u $unit_addr -p $bus_node]
	for {set i 1} {$i < 5} {incr i} {
	        set val [hsi::utils::get_ip_param_value $slave "C_USE_PIT${i}"]
		if {[string match -nocase $pit_used ""]} {
			set pit_used $val
		} else {
			append pit_used " " $val
		}
        }
	hsi::utils::add_new_dts_param $node "xlnx,pit-used" $pit_used intlist

	set pit_size ""
	set pit_mask ""
	for {set i 1} {$i < 5} {incr i} {
	        set val [hsi::utils::get_ip_param_value $slave "C_PIT${i}_SIZE"]
		set msk_val [expr pow(2, $val) - 1]
		set msk_val [format "%.0f" $msk_val]
		set msk_val [format "0x%08X" $msk_val]
		if {[string match -nocase $pit_size ""]} {
			set pit_size $val
		} else {
			append pit_size " " $val
		}
		if {[string match -nocase $pit_mask ""]} {
			set pit_mask $msk_val
		} else {
			append pit_mask " " $msk_val
		}
        }
	hsi::utils::add_new_dts_param $node "xlnx,pit-size" $pit_size intlist
	hsi::utils::add_new_dts_param $node "xlnx,pit-mask" $pit_mask hexlist

	set pit_prescaler ""
	for {set i 1} {$i < 5} {incr i} {
	        set val [hsi::utils::get_ip_param_value $slave "C_PIT${i}_PRESCALER"]
		if {[string match -nocase $pit_prescaler ""]} {
			set pit_prescaler $val
		} else {
			append pit_prescaler " " $val
		}
        }
	hsi::utils::add_new_dts_param $node "xlnx,pit-prescaler" $pit_prescaler intlist

	set pit_readable ""
	for {set i 1} {$i < 5} {incr i} {
	        set val [hsi::utils::get_ip_param_value $slave "C_PIT${i}_READABLE"]
		if {[string match -nocase $pit_readable ""]} {
			set pit_readable $val
		} else {
			append pit_readable " " $val
		}
        }
	hsi::utils::add_new_dts_param $node "xlnx,pit-readable" $pit_readable intlist

	set gpo_init ""
	for {set i 1} {$i < 5} {incr i} {
	        set val [hsi::utils::get_ip_param_value $slave "C_GPO${i}_INIT"]
		if {[string match -nocase $gpo_init ""]} {
			set gpo_init $val
		} else {
			append gpo_init " " $val
		}
        }
	hsi::utils::add_new_dts_param $node "xlnx,gpo-init" $gpo_init intlist

	set param_list "C_INTC_HAS_FAST C_INTC_ADDR_WIDTH C_INTC_LEVEL_EDGE C_UART_BAUDRATE"
	foreach param $param_list {
		ip2drv_prop $drv_handle "CONFIG.$param"
	}
	set val [hsi::utils::get_ip_param_value $slave "C_FREQ"]
	hsi::utils::add_new_dts_param $node "xlnx,clock-freq" $val int
	set val [hsi::utils::get_ip_param_value $slave "C_INTC_INTR_SIZE"]
	hsi::utils::add_new_dts_param $node "xlnx,max-intr-size" $val int
	hsi::utils::add_new_dts_param $node "xlnx,options" 1 int
	set val [hsi::utils::get_ip_param_value $slave "C_INTC_BASE_VECTORS"]
	hsi::utils::add_new_dts_param $node "xlnx,intc-base-vectors" $val hex
}
