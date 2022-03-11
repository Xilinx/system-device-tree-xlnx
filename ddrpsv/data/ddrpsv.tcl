#
# (C) Copyright 2019-2021 Xilinx, Inc.
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
	set a72 0
	set r5 0
	set psm 0
	set pmc 0
	set slave [hsi::get_cells -hier ${drv_handle}]
	set dts_file "system-top.dts"
	set slave [hsi::get_cells -hier ${drv_handle}]
	set vlnv [split [hsi get_property VLNV $slave] ":"]
	set name [lindex $vlnv 2]
	set ver [lindex $vlnv 3]
	set comp_prop "xlnx,${name}-${ver}"
	regsub -all {_} $comp_prop {-} comp_prop
	set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
        foreach procc $proclist {
		set is_ddr_low_0 0
		set is_ddr_low_1 0
		set is_ddr_low_2 0
		set is_ddr_low_3 0
		set is_ddr_ch_1 0
		set is_ddr_ch_2 0
		set is_ddr_ch_3 0
		
		set periph [hsi::get_cells -hier $drv_handle]
		if {[catch {set interface_block_names [hsi get_property ADDRESS_BLOCK [hsi::get_mem_ranges -of_objects $procc $periph]]} msg]} {
			if {[catch {set interface_block_names [hsi get_property ADDRESS_BLOCK [hsi::get_mem_ranges $procc $periph]]} msg]} {
				set interface_block_names ""
			} 
		}
		if {$a72 == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"]} {
			continue
		}
	    	if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"]} {
		       set a72 1
		}
		if {$r5 == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"]} {
			continue
		}
	        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"]} {
		      set r5 1
		}
		if {$pmc == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"]} {
			continue
		}
		if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"]} {
			set pmc 1
		}
		if {$psm == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"]} {
			continue
		}
		if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"]} {
			set psm 1
		}
		set i 0
		foreach block_name $interface_block_names {
			if {[string match "C*_DDR_LOW0*" $block_name]} {
				if {$is_ddr_low_0 == 0} {
					if {[catch {set base_value_0 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
						set base_value_0 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
					}
				}
				if {[catch {set high_value_0 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
					set high_value_0 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
				}
				set is_ddr_low_0 1
			} elseif {[string match "C*_DDR_LOW1*" $block_name]} {
				if {$is_ddr_low_1 == 0} {
					if {[catch {set base_value_1 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
						set base_value_1 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
					}
				}
				if {[catch {set high_value_1 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
					set high_value_1 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
				}
				set is_ddr_low_1 1
			} elseif {[string match "C*_DDR_LOW2*" $block_name]} {
				if {$is_ddr_low_2 == 0} {
					if {[catch {set base_value_2 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
						set base_value_2 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
					}
				}
				if {[catch {set high_value_2 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
					set high_value_2 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
				}
				set is_ddr_low_2 1
			} elseif {[string match "C*_DDR_LOW3*" $block_name] } {
				if {$is_ddr_low_3 == "0"} {
					if {[catch {set base_value_3 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
						set base_value_3 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
					}
				}
				if {[catch {set high_value_3 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
					set high_value_3 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
				}
				set is_ddr_low_3 1
			} elseif {[string match "C*_DDR_CH1*" $block_name]} {
				if {$is_ddr_ch_1 == "0"} {
					if {[catch {set base_value_4 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
						set base_value_4 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
					}
				}
				if {[catch {set high_value_4 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
					set high_value_4 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
				}
				set is_ddr_ch_1 1
			} elseif {[string match "C*_DDR_CH2*" $block_name]} {
				if {$is_ddr_ch_2 == "0"} {
					if {[catch {set base_value_5 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
						set base_value_5 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
					}
				}
				if {[catch {set high_value_5 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
					set high_value_5 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
				}
				set is_ddr_ch_2 1
			} elseif {[string match "C*_DDR_CH3*" $block_name]} {
				if {$is_ddr_ch_3 == "0"} {
					if {[catch {set base_value_6 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
						set base_value_6 [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
					}
				}
				if {[catch {set high_value_6 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc $periph] $i]]} msg]} {
					set high_value_6 [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges $procc $periph] $i]]
				}
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
			set reg_val_6 [generate_reg_property $base_value_6 $high_value_6]
			set updat [lappend updat $reg_val_6]
		}
		set len [llength $updat]
		switch $len {
			"1" {
				set reg_val [lindex $updat 0]
				update_mc_ranges $drv_handle $reg_val
			}
			"2" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]"
				update_mc_ranges $drv_handle $reg_val
			}
			"3" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]"
				update_mc_ranges $drv_handle $reg_val
			}
			"4" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]"
				update_mc_ranges $drv_handle $reg_val
			}
			"5" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]"
				update_mc_ranges $drv_handle $reg_val
			}
			"6" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]"
				update_mc_ranges $drv_handle $reg_val
			}
			"7" {
				set reg_val [lindex $updat 0]
				append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]"
				update_mc_ranges $drv_handle $reg_val
			}
			}

		if {[llength $reg_val]} {
			set higheraddr [expr [lindex $reg_val 0] << 32]
			set loweraddr [lindex $reg_val 1]
			set baseaddr [format 0x%x [expr {${higheraddr} + ${loweraddr}}]]
			regsub -all {^0x} $baseaddr {} baseaddr
			set memory_node [create_node -n memory -l "${drv_handle}_memory" -u $baseaddr -p root -d "system-top.dts"]
			if {[catch {set dev_type [hsi get_property CONFIG.device_type $drv_handle]} msg]} {
				set dev_type memory
			}
			if {[string_is_empty $dev_type]} {set dev_type memory}
			add_prop "${memory_node}" "compatible" $comp_prop string $dts_file
			add_prop "${memory_node}" "device_type" $dev_type string $dts_file
			add_prop "${memory_node}" "reg" $reg_val inthexlist $dts_file
		}


			if {$len} {
				if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"]} {
					set val [get_count "psv_cortexr5"]
					set map [get_mc_map $drv_handle]
					if {$val == 0 || $map == 1} {
						set_memmap "${drv_handle}_memory" r5 $reg_val
					}
				}
				if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"] } {
					set val [get_count "psv_cortexa72"]
					set map [get_mc_map $drv_handle]
					if {$val == 0 || $map == 1} {
						set_memmap "${drv_handle}_memory" a53 $reg_val
					}
				}
				if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"] } {
					set val [get_count "psv_pmc"]
					set map [get_mc_map $drv_handle]
					if {$val == 0 || $map == 1} {
						set_memmap "${drv_handle}_memory" pmc $reg_val
					}
				}
				if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"] } {
					set val [get_count "psv_psm"]
					set map [get_mc_map $drv_handle]
					if {$val == 0 || $map == 1} {
						set_memmap "${drv_handle}_memory" psm $reg_val
					}
				}
				if {[string match -nocase [hsi get_property IP_NAME $procc] "microblaze"] } {
					set val [get_count "microblaze"]
					set map [get_mc_map $drv_handle]
					if {$val == 0 || $map == 1} {
						set_memmap "${drv_handle}_memory" $procc $reg_val
					}
				}
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
		} else {
			set high_base $base
			set low_base 0x0
		}
		if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
			set temp $size
			set temp [string trimleft [string trimleft $temp 0] x]
			set len [string length $temp]
			set rem [expr {${len} - 8}]
			set high_size "0x[string range $temp $rem $len]"
			set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
			set low_size [format 0x%08x $low_size]
		} else {
			set high_size $size
			set low_size 0x0
		}
		set reg "$low_base $high_base $low_size $high_size"
	} else {
		set reg "0x0 $base 0x0 $size"
	}
	return $reg
}

proc update_mc_ranges {drv_handle reg} {
	set num_mc [hsi get_property CONFIG.NUM_MC [hsi::get_cells -hier $drv_handle]]
	set intrleave_size [hsi get_property CONFIG.MC_INTERLEAVE_SIZE [hsi::get_cells -hier $drv_handle]]
	if {$num_mc >= 1} {
		if {[catch {set value [pcwdt get "&mc0" ranges]} msg]} {
			set node [create_node -n "&mc0" -d "pcw.dtsi" -p root]		
			add_prop $node ranges $reg hexlist "pcw.dtsi" 1
			add_prop $node "status" "okay" string "pcw.dtsi" 1
			set mcnode [create_node -n "&ddrmc_xmpu_0" -d "pcw.dtsi" -p root]		
			add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
		} else {
			set reg_val $value
			set reg_val [string trimleft $reg_val "<"]
			set reg_val [string trimright $reg_val ">"]
			append reg_val ">, <$reg"
			pcwdt unset "&mc0" ranges
			set reg_val [remove_dup $reg_val]
			add_prop "&mc0" ranges $reg_val hexlist "pcw.dtsi" 1
			add_prop "&mc0" "status" "okay" string "pcw.dtsi" 1
		}
		
	}

	if {$num_mc >= 2} {
		if {[catch {set value [pcwdt get "&mc1" ranges]} msg]} {
			set node [create_node -n "&mc1" -d "pcw.dtsi" -p root]		
			add_prop $node ranges $reg hexlist "pcw.dtsi" 1
			add_prop $node "status" "okay" string "pcw.dtsi" 1
			set mcnode [create_node -n "&ddrmc_xmpu_1" -d "pcw.dtsi" -p root]		
			add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
		} else {
			set reg_val $value
			set reg_val [string trimleft $reg_val "<"]
			set reg_val [string trimright $reg_val ">"]
			append reg_val ">, <$reg"
			pcwdt unset "&mc1" ranges
			set reg_val [remove_dup $reg_val]
			add_prop "&mc1" ranges $reg_val hexlist "pcw.dtsi" 1			
			add_prop "&mc1" "status" "okay" string "pcw.dtsi" 1
		}
		add_prop "&mc0" interleave "$intrleave_size 0" hexlist "pcw.dtsi" 1
		add_prop "&mc1" interleave "$intrleave_size 1" hexlist "pcw.dtsi" 1
		
	}
	
	if {$num_mc >= 4} {
		if {[catch {set value [pcwdt get "&mc2" ranges]} msg]} {
			set node [create_node -n "&mc2" -d "pcw.dtsi" -p root]		
			add_prop $node ranges $reg hexlist "pcw.dtsi" 1
			add_prop $node "status" "okay" string "pcw.dtsi" 1
			set mcnode [create_node -n "&ddrmc_xmpu_2" -d "pcw.dtsi" -p root]		
			add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
		} else {
			set reg_val $value
			set reg_val [string trimleft $reg_val "<"]
			set reg_val [string trimright $reg_val ">"]
			append reg_val ">, <$reg"
			pcwdt unset "&mc2" ranges
			set reg_val [remove_dup $reg_val]
			add_prop "&mc2" ranges $reg_val hexlist "pcw.dtsi" 1				
			add_prop "&mc2" "status" "okay" string "pcw.dtsi" 1
		}
		add_prop "&mc2" interleave "$intrleave_size 2" hexlist "pcw.dtsi" 1
		if {[catch {set value [pcwdt get "&mc3" ranges]} msg]} {
			set node [create_node -n "&mc3" -d "pcw.dtsi" -p root]		
			add_prop $node ranges $reg hexlist "pcw.dtsi" 1
			set mcnode [create_node -n "&ddrmc_xmpu_3" -d "pcw.dtsi" -p root]		
			add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
		} else {
			set reg_val $value
			set reg_val [string trimleft $reg_val "<"]
			set reg_val [string trimright $reg_val ">"]
			append reg_val ">, <$reg"
			pcwdt unset "&mc3" ranges
			set reg_val [remove_dup $reg_val]
			add_prop "&mc3" ranges $reg_val hexlist "pcw.dtsi" 1				
			add_prop "&mc3" "status" "okay" string "pcw.dtsi" 1
		}

		add_prop "&mc3" interleave "$intrleave_size 3" hexlist "pcw.dtsi" 1
	}

}

proc remove_dup {reg} {
	set list [multisplit $reg ">, <"]
	set list [lsort -unique $list]
	set len [llength $list]
	if {$len == 1} {
		return $list
	}
	set first [lindex $list 0]
	set list [lreplace $list 0 0]
	foreach val $list {
		append first ">, <$val"
	}
	return $first
	
}

proc multisplit "str splitStr {mc {\x00}}" {
	return [split [string map [list $splitStr $mc] $str] $mc]
}                                                                                                                                                                           

