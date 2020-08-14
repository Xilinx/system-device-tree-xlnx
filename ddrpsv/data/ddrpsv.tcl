#
# (C) Copyright 2019 Xilinx, Inc.
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

namespace eval ddrpsv {
	proc generate {drv_handle} {
		set slave [hsi::get_cells -hier ${drv_handle}]
		set addr [get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $drv_handle]]
		set dts_file "system-top.dts"
		regsub -all {^0x} $addr {} addr
		set memory_node [create_node -n memory -u $addr -p root -d "system-top.dts"]
			set dev_type memory
		if {[string_is_empty $dev_type]} {set dev_type memory}
		add_prop "${memory_node}" "device_type" $dev_type string $dts_file
		set slave [hsi::get_cells -hier ${drv_handle}]
		set vlnv [split [get_property VLNV $slave] ":"]
		set name [lindex $vlnv 2]
		set ver [lindex $vlnv 3]
		set comp_prop "xlnx,${name}-${ver}"
		regsub -all {_} $comp_prop {-} comp_prop
		add_prop "${memory_node}" "compatible" $comp_prop string $dts_file
		set is_ddr_low_0 0
		set is_ddr_low_1 0
		set is_ddr_low_2 0
		set is_ddr_low_3 0
		set is_ddr_ch_1 0
		set is_ddr_ch_2 0
		set is_ddr_ch_3 0

		set periph [hsi::get_cells -hier $drv_handle]
		set interface_block_names ""
		if {[catch {set interface_block_names [get_property ADDRESS_BLOCK [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph]]} msg]} {
		}
		set i 0
		foreach block_name $interface_block_names {
			if {[string match "C0_DDR_LOW0*" $block_name] || [string match "C1_DDR_LOW0*" $block_name]} {
				if {$is_ddr_low_0 == 0} {
					set base_value_0 [common::get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				}
				set high_value_0 [common::get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				set is_ddr_low_0 1
			} elseif {[string match "C0_DDR_LOW1*" $block_name] || [string match "C1_DDR_LOW1*" $block_name]} {
				if {$is_ddr_low_1 == 0} {
					set base_value_1 [common::get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				}
				set high_value_1 [common::get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				set is_ddr_low_1 1
			} elseif {[string match "C0_DDR_LOW2*" $block_name] || [string match "C1_DDR_LOW2*" $block_name]} {
				if {$is_ddr_low_2 == 0} {
					set base_value_2 [common::get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				}
				set high_value_2 [common::get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				set is_ddr_low_2 1
			} elseif {[string match "C0_DDR_LOW3*" $block_name] || [string match "C1_DDR_LOW3*" $block_name]} {
				if {$is_ddr_low_3 == "0"} {
					set base_value_3 [common::get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				}
				set high_value_3 [common::get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				set is_ddr_low_3 1
			} elseif {[string match "C0_DDR_CH1*" $block_name]} {
				if {$is_ddr_ch_1 == "0"} {
					set base_value_4 [common::get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				}
				set high_value_4 [common::get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				set is_ddr_ch_1 1
			} elseif {[string match "C0_DDR_CH2*" $block_name]} {
				if {$is_ddr_ch_2 == "0"} {
					set base_value_5 [common::get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				}
				set high_value_5 [common::get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				set is_ddr_ch_2 1
			} elseif {[string match "C0_DDR_CH3*" $block_name]} {
				if {$is_ddr_ch_3 == "0"} {
					set base_value_6 [common::get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				}
				set high_value_6 [common::get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
				set is_ddr_ch_3 1
			}
			incr i
		}
		set updat ""
		if {$is_ddr_low_0 == 1} {
			set reg_val_0 [generate_reg_property $base_value_0 $high_value_0]
			set updat [lappend updat $reg_val_0]
		}
		if {$is_ddr_low_1 == 1} {
			set reg_val_1 [generate_reg_property $base_value_1 $high_value_1]
			set updat [lappend updat $reg_val_1]
		}
		if {$is_ddr_low_2 == 1} {
			set reg_val_2 [generate_reg_property $base_value_2 $high_value_2]
			set updat [lappend updat $reg_val_2]
		}
		if {$is_ddr_low_3 == 1} {
			set reg_val_3 [generate_reg_property $base_value_3 $high_value_3]
			set updat [lappend updat $reg_val_3]
		}
		if {$is_ddr_ch_1 == 1} {
			set reg_val_4 [generate_reg_property $base_value_4 $high_value_4]
			set updat [lappend updat $reg_val_4]
		}
		if {$is_ddr_ch_2 == 1} {
			set reg_val_5 [generate_reg_property $base_value_5 $high_value_5]
			set updat [lappend updat $reg_val_5]
		}
		if {$is_ddr_ch_3 == 1} {
			set reg_val_6 [generate_reg_property $base_value_6 $hiagh_value_6]
			set updat [lappend updat $reg_val_6]
		}
		set len [llength $updat]
		switch $len {
			"1" {
				set reg_val [lindex $updat 0]
				add_prop "${memory_node}" "reg" $reg_val hexlist $dts_file
			}
			"2" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]"
				add_prop "${memory_node}" "reg" $reg_val hexlist $dts_file
			}
			"3" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]"
				add_prop "${memory_node}" "reg" $reg_val hexlist $dts_file
			}
			"4" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]"
				add_prop "${memory_node}" "reg" $reg_val hexlist $dts_file
			}
			"5" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]"
				add_prop "${memory_node}" "reg" $reg_val hexlist $dts_file
			}
			"6" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]"
				add_prop "${memory_node}" "reg" $reg_val hexlist $dts_file
			}
			"7" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]"
				add_prop "${memory_node}" "reg" $reg_val hexlist $dts_file
			}
		}
	}

	proc generate_reg_property {base high} {
		set size [format 0x%x [expr {${high} - ${base} + 1}]]

		set proctype [get_hw_family]
		if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [string match -nocase $proctype "psv_cortexr5"]} {
			if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
				set temp $base
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_base "0x[string range $temp $rem $len]"
				set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_base [format 0x%08x $low_base]
				if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
					set temp $size
					set temp [string trimleft [string trimleft $temp 0] x]
					set len [string length $temp]
					set rem [expr {${len} - 8}]
					set high_size "0x[string range $temp $rem $len]"
					set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
					set low_size [format 0x%08x $low_size]
					set reg "$low_base $high_base $low_size $high_size"
				} else {
					set reg "$low_base $high_base 0x0 $size"
				}
			} else {
				set reg "0x0 $base 0x0 $size"
			}
		} 
		return $reg
	}
}
