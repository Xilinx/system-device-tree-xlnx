#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Michal SIMEK <monstr@monstr.eu>
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

global def_string zynq_soc_dt_tree bus_clk_list pl_ps_irq1 pl_ps_irq0 pstree include_list count intrpin_width
global or_id
global or_cnt
global mainlist
global addrlist


global driver_param
set driver_param [dict create dev_type {items {}} alias {items {}}]
dict with driver_param dev_type {
	lappend items psv_cortexa72 cpu
	lappend items psu_cortexa53 cpu
	lappend items psv_cortexr5 cpu
	lappend items psu_cortexr5 cpu
	lappend items psu_pmu cpu
	lappend items psv_pmc cpu
	lappend items microblaze cpu
	lappend items microblaze_riscv cpu
}

dict with driver_param alias {
	lappend items axi_ethernet ethernet
	lappend items axi_ethernet_buffer ethernet
	lappend items axi_10g_ethernet ethernet
	lappend items xxv_ethernet ethernet
	lappend items usxgmii ethernet
	lappend items axi_iic i2c
	lappend items axi_quad_spi spi
	lappend items axi_ethernetlite ethernet
	lappend items ps7_ethernet ethernet
	lappend items psu_ethernet ethernet
	lappend items psv_ethernet ethernet
	lappend items ps7_i2c i2c
	lappend items psu_i2c i2c
	lappend items psv_i2c i2c
	lappend items psu_ospi spi
	lappend items psv_pmc_ospi spi
	lappend items psx_pmc_ospi spi
	lappend items pmc_ospi spi
	lappend items pmcl_ospi spi
	lappend items ps7_qspi spi
	lappend items psu_qspi spi
	lappend items psv_pmc_qspi spi
	lappend items psx_pmc_qspi spi
	lappend items pmc_qspi spi
	lappend items mdm serial
	lappend items axi_uartlite serial
	lappend items axi_uart16550 serial
	lappend items ps7_uart serial
	lappend items psu_uart serial
	lappend items psu_sbsauart serial
	lappend items psv_uart serial
	lappend items psv_sbsauart serial
	lappend items psx_sbsauart serial
	lappend items sbsauart serial
	lappend items ps7_coresight_comp serial
	lappend items psu_coresight_0 serial
	lappend items psv_coresight serial
	lappend items psx_coresight serial
	lappend items coresight serial
}

global set osmap [dict create]
global set microblaze_map [dict create]
global set mc_map [dict create]
global set memmap [dict create]
global set label_addr [dict create]
global set label_type [dict create]

if {[catch {set tmp [::struct::tree psdt]} msg]} {
}
if {[catch {set tmp [::struct::tree pldt]} msg]} {
}
if {[catch {set tmp [::struct::tree pcwdt]} msg]} {
}
if {[catch {set tmp [::struct::tree systemdt]} msg]} {
}
if {[catch {set tmp [::struct::tree clkdt]} msg]} {
}

#namespace export get_drivers
#namespace export gen_root_node
#namespace export gen_cpu_nodes
namespace export psdt
namespace export systemdt
namespace export pldt
namespace export pcwdt
namespace export clkdt
namespace export *
#global def_string zynq_soc_dt_tree bus_clk_list pl_ps_irq1 pl_ps_irq0 pstree include_list count
set count 0
set pl_ps_irq1 0
set pl_ps_irq0 0
set intrpin_width 0
set def_string "__def_none"
set zynq_soc_dt_tree "dummy.dtsi"
set bus_clk_list ""

set or_id 0
set or_cnt 0
set tree {}
set include_list ""
set pstree 0

global node_dict
global nodename_dict
global ip_type_dict
global property_dict
global intr_id_dict
global comp_ver_dict
global comp_str_dict
global cur_hw_design
global intr_type_dict
global cur_hw_iss_data
global cur_hw_is_smmu_en
global monitor_ip_exclusion_list
global node_name_dict


set node_dict [dict create]
set nodename_dict [dict create]
set ip_type_dict [dict create]
set property_dict [dict create]
set intr_id_dict [dict create]
set comp_ver_dict [dict create]
set comp_str_dict [dict create]
set cur_hw_design ""
set intr_type_dict [dict create]
set cur_hw_iss_data [dict create]
set cur_hw_is_smmu_en ""
set monitor_ip_exclusion_list {"axi_perf_mon" "exdes_rfadc_data_bram_capture"}
set node_name_dict [dict create]

package require Tcl 8.5.14
package require yaml

proc destroy_tree {} {
	pldt destroy
	psdt destroy
	pcwdt destroy
	systemdt destroy
}

proc get_type args {
	set prop [lindex $args 1]
	set handle [lindex $args 0]
	set value [hsi get_property $prop [hsi::get_cells -hier $handle]]
	if {[regexp -nocase {0x([0-9a-f])} $value match]} {
		set type "hexint"
	} elseif {[string is integer -strict $value]} {
		set type "int"
	} elseif {[string is boolean -strict $value]} {
		set type "boolean"
	} elseif {[string is wordchar -strict $value]} {
		set type "string"
	} else {
		set type "mixed"
	}
	return $type
}


proc is_zynqmp_platform {proctype} {
      	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] ||
		[string match -nocase $proctype "zynquplusRFSOC"] } {
		return 1
	} else {
		return 0
	}
}

proc set_microblaze_list {} {
	global design_family
	global is_versal_net_platform
	global microblaze_list
	set microblaze_list ""
	if {[string match -nocase $design_family "versal"]} {
		if {$is_versal_net_platform} {
			set microblaze_list "psx_pmc psx_psm pmc psm"
		} else {
			set microblaze_list "psv_pmc psv_psm pmc psm"
		}
	} elseif {[string match -nocase $design_family "zynqmp"]} {
		set microblaze_list "psu_pmu"
	}
	set soft_mb_handles [hsi::get_cells -hier -filter {IP_NAME==microblaze}]
	if {![string_is_empty soft_mb_handles]} {
		append microblaze_list " $soft_mb_handles"
	}
}

proc set_microblaze_riscv_list {} {
        global design_family
        global microblaze_riscv_list
        set microblaze_riscv_list ""

	set soft_mb_riscv_handles [hsi::get_cells -hier -filter {IP_NAME==microblaze_riscv}]
        if {![string_is_empty soft_mb_riscv_handles]} {
                append microblaze_riscv_list " $soft_mb_riscv_handles"
        }
}

# Saves the number of microblaze/microblaze_riscv processors in
# microblaze_map dict and returns the microblaze/microblaze_riscv numbers
# found during a particular cmd execution.
proc get_microblaze_nr {drv_handle} {
	set proc_name [hsi get_property IP_NAME $drv_handle]
	global microblaze_list
	global microblaze_riscv_list

	if {[string match -nocase "microblaze_riscv" $proc_name]} {
		set proc_list [lrange $microblaze_riscv_list 0 end]
	} else {
		set proc_list [lrange $microblaze_list 0 end]
	}
	set proc_index [lsearch $proc_list $drv_handle]
	if {$proc_index >= 0} {
		return $proc_index
	} else {
		error "$drv_handle couldn't be found in the ${proc_name} list: ${proc_list}"
	}
}

proc get_driver_param args {
	global driver_param
	set drv_handle [lindex $args 0]
	set type [lindex $args 1]
	set val ""
	set ip_name [get_ip_property $drv_handle IP_NAME]
	if {[catch {set val [dict get $driver_param $type items $ip_name]} msg]} {
	}
	return $val
}

proc get_count args {
	set param [lindex $args 0]
	global osmap
	if {[catch {set rt [dict get $osmap $param]} msg]} {
		dict append osmap $param 0
		set value 0
	} else {
		set value [expr $rt + 1]
		dict unset osmap $param
		dict append osmap $param $value
	}

	return $value
}

proc get_mc_map args {
	set param [lindex $args 0]
	global mc_map
	if {[catch {set rt [dict get $mc_map $param]} msg]} {
		dict append mc_map $param
		return 1
	} else {
		return 0
	}
}

proc get_label_addr args {
	set name [lindex $args 0]
	set label [lindex $args 1]
	global label_addr
	global label_type
	set count 0
	if {[catch {set tmp [dict get $label_addr $label value ]} msg]} {
		if {[catch {set tmp [dict get $label_type $name type]} msg]} {
			if {[catch {set val [dict get $label_type]} msg]} {
			} else {
				dict for {id info} $label_type {
					set temp [dict get $info type]
					if {[string match -nocase $temp $name]} {
						set count [expr $count + 1]
					}
				}
			}
			dict set label_addr $label value $count
			dict set label_type $label type $name
			set value $count
		} else {
			set value $tmp
		}
	} else {
		set value $tmp
	}

	return $value
}

# Get the reference label needed to refer this node
proc get_label {drv_handle} {
	set node_entry [get_node $drv_handle]
	if {[string_is_empty $node_entry]} {
		return ""
	}
	if {[string match "&*" $node_entry]} {
		return $node_entry
	} else {
		set node_label [lindex [split $node_entry ": "] 0]
		return "&$node_label"
	}
}

proc get_valid_proc_list {} {
	set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR && IP_NAME != "tmr_inject"}]
	return $proclist
}

proc get_proc_list_without_pmc {} {
	set proclist [get_valid_proc_list]
	set req_proc_handle_list [list]
	foreach proc_entry $proclist {
		set proc_ipname [get_ip_property $proc_entry IP_NAME]
		# Using regular expression to avoid slv*_pmc IPs as well.
		if {![string match *pmc $proc_ipname]} {
			lappend req_proc_handle_list $proc_entry
		}
	}
	return $req_proc_handle_list
}
#Fixme: For the remove_duplicate_addr API dup_periph_handle variable is now obsolete,
#will be completely removed in next release
global dup_periph_handle
set dup_periph_handle [dict create]
proc remove_duplicate_addr args {
	set peri_list [lindex $args 0]
	set non_val_list [lindex $args 1]
	global dup_periph_handle
	set dup_periph_handle [dict create]
	set addr_dict [dict create]
	foreach drv_handle $peri_list {
		set periph_addr [get_baseaddr $drv_handle]
		set ip_name [get_ip_property $drv_handle IP_NAME]
		set hier_name [get_ip_property $drv_handle HIER_NAME]
		if {![string_is_empty $hier_name] && [llength [split $hier_name "/"]] > 1} {
			continue
		}
		# Ignore bram_cntrl, it will create issues in case of multiple microblazes having a
		# bram cntrl each. bram specific logic is moved to axi_bram tcl
		if {[string match -nocase $ip_name "lmb_bram_if_cntlr"]} {
			continue
		}
		if {[string match -nocase $ip_name "mailbox"]} {
			continue
		}
		if { $periph_addr ne "" && [is_ps_ip $drv_handle] != 1 && [lsearch $non_val_list $ip_name] < 0 } {
			set periph_addr [format "0x%lx" $periph_addr]
			if { [dict exists $addr_dict $periph_addr $ip_name] } {
				dict set dup_periph_handle $drv_handle [dict get $addr_dict $periph_addr $ip_name]
			} else {
				dict set addr_dict $periph_addr $ip_name $drv_handle
			}
		}
	}
}


proc set_memmap args {
	global memmap
	set mem_ip [lindex $args 0]
	set proc_ip [lindex $args 1]
	set val [lindex $args 2]

	# Initialize memmap if it doesn't exist
	if {[catch {dict size $memmap}]} {
		set memmap [dict create]
	}

	# Check if this memory entry already exists
	if {[dict exists $memmap $mem_ip $proc_ip]} {
		set existing_val [dict get $memmap $mem_ip $proc_ip]
		set list_existing_val [::textutil::split::splitx $existing_val " , "]

		# Only append if the new value is different
		if {!($val in $list_existing_val)} {
			set combined_val "$existing_val , $val"
			dict set memmap $mem_ip $proc_ip $combined_val
		}
	} else {
		# New entry - just set it
		dict set memmap $mem_ip $proc_ip $val
	}
}

proc get_memmap args {
	global memmap
	set mem [lindex $args 0]
	set proc [lindex $args 1]
	dict for {memory procs} $memmap {
		if {[string match -nocase $memory $mem]} {
	        dict with procs {
			if {[dict exists $memmap $memory $proc]} {
				set val [dict get $procs $proc]
				return $val
			}
        	}
		}
	}
}

proc set_hw_family {proclist} {
	global pl_design
	global design_family
	global is_versal_net_platform
	global is_versal_2ve_2vm_platform
	global is_versal_2ve_2vm_small_platform
	global is_versal_2vp_platform
	global apu_proc_ip
	set apu_proc_ip ""
	set design_family ""
	set pl_design 0
	set ps_design 0
	set is_versal_net_platform 0
	set is_versal_2ve_2vm_platform 0
	set is_versal_2ve_2vm_small_platform 0
	set is_versal_2vp_platform 0
	set part_num [hsi get_property DEVICE [hsi::current_hw_design]]
	foreach procperiph $proclist {
		set proc_drv_handle [hsi::get_cells -hier $procperiph]
        	set ip_name [hsi get_property IP_NAME $proc_drv_handle]
		switch $ip_name {
			"psx_cortexa78" - "cortexa78" {
				set design_family "versal"
				set ps_design 1
				set is_versal_net_platform 1
				set apu_proc_ip $ip_name
				if {[llength [hsi::get_cells -hier -filter {IP_NAME==ps11 || IP_NAME==ps11xgui}]]} {
					set is_versal_2ve_2vm_platform 1
				}
				if {[llength [hsi::get_cells -hier -filter {IP_NAME==psxt}]]} {
					set is_versal_2ve_2vm_platform 1
					set is_versal_2ve_2vm_small_platform 1
				}
			} "psv_cortexa72" {
				set design_family "versal"
				set ps_design 1
				set apu_proc_ip "psv_cortexa72"
				if {$part_num in {"xc2vp3602" "xc2vp3202"}} {
					set is_versal_2vp_platform 1
				}
			} "psu_cortexa53" {
				set design_family "zynqmp"
				set ps_design 1
				set apu_proc_ip "psu_cortexa53"
			} "ps7_cortexa9" {
				set design_family "zynq"
				set ps_design 1
				set apu_proc_ip "ps7_cortexa9"
			} "microblaze" - "microblaze_riscv" {
				set pl_design 1
			}
		}
	}
	if { !$ps_design && $pl_design} {
		set design_family "microblaze"
	} elseif {[string_is_empty $design_family]} {
		error "Couldn't determine the hardware family, may lead to unforeseen issues"
	}
}


proc get_hw_family {} {
	global design_family
	return $design_family
}


proc get_node args {
	global node_dict
	global cur_hw_design
	global monitor_ip_exclusion_list

	proc_called_by
	set handle [lindex $args 0]
	if { [dict exists $node_dict $cur_hw_design $handle] } {
		return [dict get $node_dict $cur_hw_design $handle]
	}
	set handle [hsi::get_cells -hier $handle]
	set non_val_list "versal_cips noc_nmu noc_nsu ila zynq_ultra_ps_e psu_iou_s smart_connect noc_nsw"
	set non_val_ip_types "MONITOR BUS PROCESSOR"
	set ip_name [hsi get_property IP_NAME $handle]
	set ip_type [hsi get_property IP_TYPE $handle]
	if {[lsearch -nocase $non_val_list $ip_name] >= 0} {
		dict set node_dict $cur_hw_design $handle {}
		return ""
	}
	if {[lsearch -nocase $non_val_ip_types $ip_type] >= 0 &&
	    [lsearch -nocase $monitor_ip_exclusion_list $ip_name] == -1 && ![string match -nocase $ip_name "tmr_inject"]} {
		dict set node_dict $cur_hw_design $handle {}
		return ""
	}

	if {[is_ps_ip $handle]} {
		set dts_file "versal.dtsi"
	} else {
		set dts_file [set_drv_def_dts $handle]
	}
	set dts_file [set_drv_def_dts $handle]
	set ip_type [hsi get_property IP_TYPE $handle]
	set addr [get_baseaddr $handle noprefix]
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
	} elseif {[string match -nocase $dts_file "versal.dtsi"]} {
		set treeobj "psdt"
	} else {
		set treeobj "systemdt"
	}
	set ps_mapping [gen_ps_mapping]
	if {[catch {set tmp [dict get $ps_mapping $addr label]} msg]} {
		if {[string match -nocase $treeobj "pcwdt"]} {
		set busname "&amba"
		} else {
			set busname [detect_bus_name $handle]
		}
	} elseif {[string match -nocase $ip_type "PROCESSOR"] || [string match -nocase $treeobj "pcwdt"]} {
		set busname root
	} else {
		set busname [detect_bus_name $handle]
	}
	#set childs [$treeobj children $busname]
	#foreach child $childs {
	#}
	set dev_type [hsi get_property IP_NAME $handle]
	if {[string match -nocase $dev_type "psv_fpd_smmutcu"]} {
		set dev_type "psv_fpd_maincci"
	}
	if {[string_is_empty $dev_type] || [string_is_empty $addr]} {
		return ""
	}
	if {[is_ps_ip $handle]} {
		set ps_mapping [gen_ps_mapping]
		if {[catch {set tmp [dict get $ps_mapping $addr label]} msg]} {
			set node [create_node -n $dev_type -l $handle -u $addr -p $busname -d $dts_file]	
		} else {
			set value [split $tmp ": "]
			set node_label [lindex $value 0]
			set node_name [lindex $value 2]
			set node [create_node -n $node_name -l $node_label -u $addr -p $busname -d $dts_file]
		}
	} else {
		set node [create_node -n $dev_type -l $handle -u $addr -p $busname -d $dts_file]
	}
	set node [string trimleft $node "\{"]
	set node [string trimright $node "\}"]
	dict set node_dict $cur_hw_design $handle $node

	return $node
}

proc get_prop args {
	proc_called_by
	set handle [lindex $args 0]
	set property [lindex $args 1]
	set dts_file [set_drv_def_dts $handle]]
	set ip_type [hsi get_property IP_TYPE [hsi::get_cells -hier $handle]]

	#if {[string match -nocase $ip_type "PROCESSOR"]} {
	#	set busname root
	#} else {
	#	set busname [detect_bus_name $handle]
	#}
	#set addr [get_baseaddr $handle]
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
	} elseif {[string match -nocase $dts_file "versal.dtsi"]} {
		set treeobj "psdt"
	} else {
		set treeobj "systemdt"
	}
	#set childs [$treeobj children $busname]
	#foreach child $childs {
	#}
	#set label [hsi get_property IP_NAME [hsi::get_cells -hier $handle]]
	set dts [set_drv_def_dts $handle]
	set node [get_node $drv_handle]
	set val [$treeobj get $node $property]
	return $val
}

proc get_driver_config args {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set drv_handle [lindex $args 0]
	set type [lindex $args 1]
	set param [get_driver_param $drv_handle $type]

	return $param
}

proc write_value {type value} {
        if {[catch {
                if {$type in {"hexint" "int"}} {
			set val $value
			if {[string_is_empty $val]} {
				set val "\"\""
			} elseif {$val < 0} {
				set val "<[format 0x%.8x [expr {$value & 0xFFFFFFFF}]]>"
			} elseif {$type == "int" && ![regexp -nocase {^0x} "$val" match]} {
				# FIXME: Below format call is put as a hack in interest of time
				# It is a dummy call to trap the same exception that we were getting earlier
				# xlnx,pss-ref-clk-freq = <33.330> is added in its absence.
				set dummy [format %x $value]
				set val "<$value>"
			} else {
				if {![regexp -nocase {^0x} "$value" match]} {
					# When $value is not starting with 0x, $value can be a hex or an integer or a binary number starting with 0b.
					# check if the $value can be converted into a hex using format
					if {[catch {set val [format 0x%x $value]} msg]} {
						# format expects either an integer, a binary number with 0b or a hex number starting with 0x
						# When none of the above is found i.e. when the value only has hex alphabets without 0x prefix
						# e.g. value = abcdef
						set val "0x$value"
					}
				}

				set val [format 0x%x $val]

				regsub -all {^0x} $val {} temp
				if {[regexp -nocase {([0-9a-f]{9})} "$temp" match]} {
					set len [string length $temp]
					set hex_list ""

					while {$len > 0} {
						# Get the rightmost 8 characters
						set part [string range $temp [expr {$len - 8}] [expr {$len - 1}]]
						# Prepend the part to the result
						set hex_list "$part $hex_list"
						# Shorten the input string
						set len [expr {$len - 8}]
					}

					if {[string_is_empty $hex_list]} {
						set val "0x0"
					} else {
						set val ""
						foreach element $hex_list {
							append val "0x$element" " "
						}
						set val [string trimright $val " "]
					}
				}
				set val "<$val>"
			}
                } elseif {$type == "empty"} {
                } elseif {$type == "inttuple" || $type == "intlist"} {
                        set val "< "
                        foreach element $value {
                                set val [append val "[format %d $element] "]
                        }
                        set val [append val ">"]
                } elseif {$type == "hexinttuple"} {
                        set val "< "
                        foreach element $value {
                                set val [append val "0x[format %x $element] "]
                        }
                        set val [append val ">"]
                } elseif {$type == "hexlist"} {
                        set val "<"
                        foreach element $value {
				append val "$element" " "
                               # set val [append $val "$element "]
                        }
			set val [string trimright $val " "]
                        set val [append val ">"]
		} elseif {$type == "special"} {
                        set val "<$value>"
                } elseif {$type == "bytesequence"} {
                        set val "\[ "
                        foreach element $value {
				if {[catch {set tmp [expr $element > 255]} msg ]} {
				}
                                if {$tmp} {
                                        error {"Value $element is not a byte!"}
                                }
                                set val [append val "[format %02x $element] "]
                        }
                        set val [append val "\]"]
                } elseif {$type == "hexbytesequence"} {
                    set val "\[$value\]"
                } elseif {$type == "labelref" || $type == "reference"} {
                        set val "<&$value>"
                } elseif {$type == "referencelist"} {
                        set val "<"
                        foreach element $value {
                                append val "&$element" " "
                        }
                        set val [string trimright $val " "]
                        set val [append val ">"]
                } elseif {$type == "aliasref"} {
                        set val "$value"
                } elseif {$type == "string"} {
                        set val "\"$value\""
                } elseif {$type == "stringtuple" || $type == "stringlist"} {
                        set val ""
                        set first true
                        foreach element $value {
                                if {$first != true} { 
                                	set val [append val "\ \,\ \"$element\""]
				} else {
                                	set val [append val "\"$element\""]
				}
                               set first false
                        }
                } elseif {$type == "boolean"} { 
			set val ""
		} elseif {$type == "mixed"} {
                        set val ""
                        set first true
			if {[catch {set t [expr int($value)]} msg]} {
				set non_double 1
			} else {
				set non_double 0
			}
			if {[string is double $value]} {
				set tmp [expr [scan [lindex [split $value "."] 1] %d] + 1]
				if {$tmp == 1} {
					set tmp [lindex [split $value "."] 0]
                        		set val "<[format %d $tmp]>"
				} else {
					set val [append val "<"]
					set tmp [scan [expr $value * 1000000] "%d"]
					set base [format 0x%x $tmp]
					set temp $base
					set temp [string trimleft [string trimleft $temp 0] x]
					set len [string length $temp]
					set rem [expr {${len} - 8}]
					set high_base "0x[string range $temp $rem $len]"
					set low "[string range $temp 0 [expr {${rem} - 1}]]"
					if {$low != ""} {
						set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
						set low_base [format 0x%08x $low_base]
					}
					set val "<"
					if {$low != ""} {
						append val "$low_base" " "
		                        	set val [append val "$high_base>"]
					} else {
			                        set val "<$high_base>"
					}
				}
			} else {
				foreach element $value {
					if {$first != true} { 
						set val [append val "\ \,\ $element"]
					} else {
						set val [append val "\"$element"]
					}
				       set first false
				}
				set val [append val "\""]
			}
		} elseif {$type == "comment"} {
			set val "$value"
		} elseif {$type == "noformating"} {
			set val $value
		} else {
                        puts "unknown type $type"
                }
        } {error}]} {
		dtg_warning $error
                set val "\"$value\""
        }
        return $val
}

proc create_node args {
	global node_dict
	global cur_hw_design

	set node_name ""
	set node_unit_addr ""
	set node_label ""
	set drv_handle ""
	while {[string match -* [lindex $args 0]]} {
		switch -glob -- [lindex $args 0] {
			-force {set force_create 1}
			-disable_auto_ref {set auto_ref 0}
			-auto_ref_parent {set auto_ref_parent 1}
			-n* {set node_name [Pop args 1]
				}
			-l* {set node_label [Pop args 1]}
			-u* {set node_unit_addr [Pop args 1]}
			-p* {set parent_obj [Pop args 1]
				}
			-d* {set dts_file [Pop args 1]}
			-h* {set drv_handle [Pop args 1]}
			--  {Pop args ; break}
			default {
				error "add_or_get_dt_node bad option - [lindex $args 0]"
			}
		}
		Pop args
	}
	set ignore_list "fifo_generator clk_wiz clk_wizard xlconcat ilconcat xlconstant ilconstant \
		util_vector_logic ilvector_logic xlslice ilslice util_ds_buf proc_sys_reset axis_data_fifo \
		v_vid_in_axi4s bufg_gt axis_tdest_editor util_reduced_logic ilreduced_logic \
		gt_quad_base noc_nsw blk_mem_gen emb_mem_gen lmb_bram_if_cntlr \
		perf_axi_tg noc_mc_ddr4 c_counter_binary timer_sync_1588 oddr \
		axi_noc dp_videoaxi4s_bridge axi4svideo_bridge axi_vip \
		xpm_cdc_gen bufgmux axi_apb_bridge gig_ethernet_pcs_pma \
		dfe_rfsoc_adc_quadndual_io dfe_vec_fifo"
	set temp [lsearch $ignore_list $node_name]
	if {$temp >= 0  && [string match -nocase $node_unit_addr ""]} {
		set val_lab [string match -nocase $node_label ""]
		set val_name [string match -nocase $node_name ""]
		if {$val_lab != 1 && $val_name != 1} {
			set node_unit_addr [get_label_addr $node_name $node_label]
		}
	}
	if {[string match -nocase $node_name "lmb_bram_if_cntlr"]} {
		set val_lab [string match -nocase $node_label ""]
		set val_name [string match -nocase $node_name ""]
		set node_unit_addr [get_label_addr $node_name $node_label]
		
	}
	if {[string match -nocase $node_name "aliases"]} {
		set interconnect [systemdt insert root end aliases]
		return $interconnect
	}
	if {[string match -nocase $node_name "chosen"]} {
		set interconnect [systemdt insert root end chosen]
		return $interconnect
	}
	if {[string match -nocase $node_name "displayport"] || [string match -nocase $node_name "v_tc"]} {
		set addr_val [get_label_addr $node_name $node_label]
		set node_name "${node_name}_${addr_val}"
	}
	if {[string match -nocase $node_name "reserved-memory"]} {
		set interconnect [systemdt insert root end reserved-memory]
		return $interconnect
	}
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
		set root "pcwroot"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
		set root "plroot"
	} elseif {[string match -nocase $dts_file "versal.dtsi"]} {
		set treeobj "psdt"
		set root "psroot"
	} elseif {[string match -nocase $dts_file "versal-clk.dtsi"]} {
		set treeobj "clkdt"
		set root "psroot"
	} else {
		set treeobj "systemdt"
		set root "systemroot"
	}
	if {[string match -nocase $treeobj "pcwdt"]} {
		set ps_mapping [gen_ps_mapping]
		if {![dict exists $ps_mapping $node_unit_addr label]} {
			set new_name "&$node_name"
		}
	}
	if {[string match -nocase $node_name "amba_pl: amba_pl"] || 
		[string match -nocase $node_name "amba: axi"] ||
		[string match -nocase $node_name "amba_apu: apu-bus"] ||
                [string match -nocase $node_name "amba_rpu: rpu-bus"]} {
	} else {
		set busname [detect_bus_name $node_name]
	}
	if {[string match -nocase $node_name "amba_pl: amba_pl"] || 
		[string match -nocase $node_name "amba: axi"] ||
		[string match -nocase $node_name "amba_rpu: rpu-bus"] ||
		[string match -nocase $node_name "amba_apu: apu-bus"] || [string match -nocase $node_name "root"]} {
		set mainroot [$treeobj children root]

		if {[string match -nocase $mainroot ""]} {
			if {[string match $node_name "amba_pl: amba_pl"]} {
				set interconnect [$treeobj insert root end "amba_pl: amba_pl"]
			}	
			if {[string match $node_name "amba: axi"]} {
				set interconnect [$treeobj insert root end "amba: axi"]
			}	
			if {[string match $node_name "amba_apu: apu-bus"]} {
				set interconnect [$treeobj insert root end "amba_apu: apu-bus"]
			}
			if {[string match $node_name "amba_rpu: rpu-bus"]} {
                                set interconnect [$treeobj insert root end "amba_rpu: rpu-bus"]
                        }
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "amba_pl: amba_pl"]} {
				set interconnect [$treeobj insert root end "amba_pl: amba_pl"]
			}	
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "amba: axi"]} {
				set interconnect [$treeobj insert root end "amba: axi"]
			}	
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "apu-bus"]} {
				set interconnect [$treeobj insert root end "amba_apu: apu-bus"]
			}	
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "rpu-bus"]} {
                                set interconnect [$treeobj insert root end "amba_rpu: rpu-bus"]
                        }
			return $interconnect
		} else {
			if {[string match -nocase $node_name "root"]} {
				return root
			}
			foreach childnodes $mainroot {
				if {[string match $childnodes "$node_name"]} {
					return $childnodes
				}	
			}
			if {[string match -nocase $node_unit_addr ""]} {
				if {[catch {set temp [string match -nocase $node_label ""]} msg]} {
					set interconnect [$treeobj insert root end "$node_name"]
				} else {
					set interconnect [$treeobj insert root end "$node_label: $node_name"]
				}
			} else {
				if {[string match -nocase $node_label ""]} {
					set interconnect [$treeobj insert root end "$node_name@$node_unit_addr"]
				}  else {
					set interconnect [$treeobj insert root end "$node_label: $node_name@$node_unit_addr"]
				}
			}
			return $interconnect
		}
	}
	set main_childs ""	
	if {[catch {set main_childs [$treeobj children $parent_obj]} msg] } {
	}
	if {[string match -nocase $treeobj "pcwdt"]} {
		set ps_mapping [gen_ps_mapping]
		if {[catch {set tmp [dict get $ps_mapping $node_unit_addr label]} msg]} {
			
		} else {
			set node_name "&$node_label"
			set node_label ""
			set node_unit_addr ""
		}
	}
	if {[string match -nocase $main_childs ""]} {
		if {[string match -nocase $node_unit_addr ""]} {
			if {[string match -nocase $node_label ""]} {
				set drvnode [$treeobj insert $parent_obj end "$node_name"]	
			} else {
				set drvnode [$treeobj insert $parent_obj end "$node_label: $node_name"]
			}
		} else {
			if {[string match -nocase $node_label ""]} {
				set drvnode [$treeobj insert $parent_obj end "$node_name@$node_unit_addr"]	
			} else {
				set drvnode [$treeobj insert $parent_obj end "$node_label: $node_name@$node_unit_addr"]	

				set drvnode [string trimleft $drvnode "\{"]
				set drvnode [string trimright $drvnode "\}"]
			}
		}
	} else {
		foreach childnodes $main_childs {
			if {[catch {set temp [[string match -nocase $childnodes "$node_label: $node_name@$node_unit_addr"]]} msg]} {
				if {[string match -nocase $childnodes "$node_name: $node_label"]} {
				      return $childnodes
				} else {
				      if {[catch {set temp [string match -nocase $node_unit_addr ""]} msg]} {
						if {[string match -nocase $node_label ""]} {
							set drvnode [$treeobj insert $parent_obj end "$node_name"]
						} else {
							set drvnode [$treeobj insert $parent_obj end "$node_label: $node_name"]
						}
					} else {
						if {[string match -nocase $node_label ""]} {
							set drvnode [$treeobj insert $parent_obj end "$node_name@$node_unit_addr"]
						} else {
							set drvnode [$treeobj insert $parent_obj end "$node_label: $node_name@$node_unit_addr"]
						}
					}
					return $drvnode
			      }
			}
                }
		if {[string match -nocase $node_unit_addr ""]} {
			if {[string match -nocase $node_label ""]} {
	        	        set drvnode [$treeobj insert $parent_obj end "$node_name"]
			} else {
	        	        set drvnode [$treeobj insert $parent_obj end "$node_label: $node_name"]
			}
		} else {
			if {[string match -nocase $node_label ""]} {
                		set drvnode [$treeobj insert $parent_obj end "$node_name@$node_unit_addr"]
			} else {
                		set drvnode [$treeobj insert $parent_obj end "$node_label: $node_name@$node_unit_addr"]
			}
		}
        }
	set drvnode [string trimleft $drvnode "\{"]
	set drvnode [string trimright $drvnode "\}"]

	if {![string_is_empty $node_label]} {
		dict set node_dict $cur_hw_design $node_label $drvnode
	} elseif {![string_is_empty $drv_handle]} {
		dict set node_dict $cur_hw_design $drv_handle $drvnode
	}

        return $drvnode
}

proc add_prop args {
	proc_called_by
	set keyval ""
	set bypass 0
	set incr 0
	set overwrite 0
	#foreach val $args {
	#	incr count
	#}
	set count [llength $args]
	set node [lindex $args 0]
	set prop [lindex $args 1]

	# revisit this
	if {$count <= 4} {
		set val ""
		set type [lindex $args 2]
		set dts_file [lindex $args 3]
	} else {
		set val [lindex $args 2]
		set type [lindex $args 3]
		set dts_file [lindex $args 4]
	}
	if {$count > 5} {
		set overwrite [lindex $args 5]
	}

	#if {[string match -nocase $node "&gic"]} {
	#}
	#if {[string match -nocase $dts_file "pcw.dtsi"]} {
	#
	#}

	set val [write_value $type $val]
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
	} elseif {[string match -nocase $dts_file "versal.dtsi"] || [string match -nocase $dts_file "zynqmp.dtsi"]} {
		set treeobj "psdt"
	} else {
		set treeobj "systemdt"
	}

	if {[catch {set already_key [$treeobj get $node $prop]} msg]} {
		set node [string trimleft $node "\{"]
		set node [string trimright $node "\}"]
		if {$bypass == 0} {
			set keyval [$treeobj set $node $prop $val]
		}
	} else {
		if {[string match -nocase $prop "status"] || $overwrite == 1} {
			set keyval [$treeobj set $node $prop $val]
		} else {
			if {[string match -nocase $type "hexlist"]} {
				set val ", $val"
			}
			if {[string match -nocase $already_key $val]} {
			} elseif {[string match -nocase $type "noformating"]} {
				set keyval $val
			} else {
				set keyval [$treeobj append $node $prop " $val"]
			}
		}
	}
	if {$bypass == 0} {
		return $keyval
	}
}

proc create_ps_tree args {
	global pstree

	if {$pstree == 1} {
		return
	}

	set ps_mapping [gen_ps_mapping]
	set psfile [lindex $args 0]
	set psdt [lindex $args 1]
	set a [open $psfile]
	set lines [split [read $a] "\n"]
	close $a;                          # Saves a few bytes :-)
	set levels {}
	set temp 0
	set parent "root"
	set next_cmd 0
	set next_prop ""
	set chain_list ""
	foreach line $lines {
		if {[string match *\\\{* $line]} {
			if {$temp == "0"} {
			} else {
				regsub -all {^[ \t]+} $line {} line
				regsub -all {[ \{]$} $line {} line
				set line [string trimleft $line " "]
				set line [string trimright $line " "]
				set parent [regsub -all {\{|\}} $parent ""]
				regsub -all "\{| |\t" $line {} line
				set node_label ""
				set node_name ""
				set node_unit_addr ""
		
				set node_data [split $line ":"]
				set node_data_size [llength $node_data]
				if {$node_data_size == 2} {
					set node_label [lindex $node_data 0]
					set tmp_data [split [lindex $node_data 1] "@"]
					set node_name [lindex $tmp_data 0]
					if {[llength $tmp_data] >= 2} {
						set node_unit_addr [lindex $tmp_data 1]
					}
				} elseif {$node_data_size == 1} {
					set node_name [lindex $node_data 0]
				} else {
					error "invalid node found - $line"
				}
				if {[string match -nocase $psdt "psdt"]} {
					set tempfile "versal.dtsi"
				} else {
					set tempfile "versal-clk.dtsi"
				}
				if {[string match -nocase $node_name ""]} {
				
				} else {
					
					if {[catch {set tmp [dict get $ps_mapping $node_unit_addr label]} msg]} {
						set parent [create_node -n $node_name -l $node_label -u $node_unit_addr -p $parent -d $tempfile]
					} else {
						set value [split $tmp ": "]
						set node_label [lindex $value 0]
						set node_name [lindex $value 2]
						set dummy [split $line ":"]
						set dummy [lindex $dummy 0]
						if {[string match -nocase $dummy "gic_r5"] } {
							set node_label "gic_r5"
						} elseif {[string match -nocase $dummy "gic_r52"] } {
							set node_label "gic_r52"
						}
						set parent [create_node -n $node_name -l $node_label -u $node_unit_addr -p $parent -d $tempfile]
						if {[string match -nocase $dummy "gic_a72"] } {
							set map "0 0xf9000000 0 0x80000> , <0x0 0xf9080000 0 0x80000"
							add_prop $parent reg $map hexlist $tempfile
						}

					}
					lappend levels $parent
				}
			}
			set temp [expr $temp + 1]
		} elseif {[string match *\\\}* $line]} {
			set levels [lreplace $levels [expr [llength $levels] - 1] [expr [llength $levels] - 1]]
			set line [string trimleft $line " "]
			set line [string trimright $line " "]
			set parent [regsub -all {\{|\}} $parent ""]
			if {[string match -nocase $parent ""] || [string match -nocase $parent "root"]} {
			} else {
				set parent [$psdt parent $parent]
			}
			set temp [expr $temp - 1]
		} else {
			regsub -all {^[ \t]+} $line {} line
			set val [regexp -all {[\=]} $line matched]

			if {$val == 0 && [string match $next_cmd 0]} {
				if {[regexp -all {[\#]} $line matched]} {
				} elseif {[regexp -all {[\/][\/]} $line matched]} {
				} elseif {[regexp -all {[\/][\*]} $line matched]} {
				} elseif {[regexp -all {[\*]} $line matched]} {
				} elseif {[string match -nocase $line ""]} {
				} else {			
					set parent [regsub -all {\{|\}} $parent ""]
					$psdt set $parent $line ""
				}
			} else {
				if {[regexp -all {[\/][\/]} $line matched]} {
				} elseif {[regexp -all {[\/][\*]} $line matched]} {
				} elseif {[regexp -all {[\*]} $line matched]} {
				} elseif {[string match -nocase $line ""]} {
				} else {
					if {[string match $next_cmd 1]} {
						if {[string match [string index $line end] ";"]} {
							set comval [string trimright $line ";"]
							if {[regexp -all {^[\"]} $line] } {
								set inner [split $line " "]
								foreach inn $inner {
									set inn [string trimright $inn ","]
									set inn [string trimright $inn ";"]
									append chain_list " " $inn
								}
							} else {
								append chain_list " " $comval
							}
							set next_cmd 0
							set prop $next_prop 
						} else {
							if {[regexp -all {^[\"]} $line] } {
								set inner [split $line " "]
								foreach inn $inner {
									set inn [string trimright $inn ","]
									set inn [string trimright $inn ";"]
									append chain_list " " $inn
								}
							} else {
								set comval [string trimright $line ","]
								append chain_list " " $comval
							}
							continue
						
						}
						set dtval $chain_list
						set chain_list ""
					} else {
						set parent [regsub -all {\{|\}} $parent ""]
						set dtval [split $line "="]
						set comma [string index [lindex $dtval 1] end]
						set multival [regsub -all {\{|\}} [lindex $dtval 1] ""]
						set multival [string trimleft $multival " "]
						set spl [split $multival " "]
						if {[llength $spl] >= 1 && [string match $comma ","] || [string match $next_cmd 1]} {
							if {[regexp -all {^[\"]} $multival] } {
								set inner [split $multival " " ]
								set tempin ""
								foreach inn $inner {
									set inn [string trimright $inn ","]
									if {[string match -nocase $next_cmd 0]} {
										set next_prop [lindex $dtval 0]
										append tempin " " $inn
									} else {
										append chain_list " " $inn
									}
								}
								if {[string match -nocase $next_cmd 0]} {
									set chain_list $tempin
								}
								set next_cmd 1
								continue
							} else {
								set comval [string trimright [lindex $dtval 1] ","]
								if {[string match -nocase $next_cmd 0]} {
									set next_prop [lindex $dtval 0]
									set chain_list $comval
								} else {
									append chain_list " " $comval
								}
								set next_cmd 1

								continue
							}
						}
						if {[llength $spl] > 1 && [regexp -all {[\,]} $multival matched] && ![string match -nocase [string index $multival 0] "<"]} {
							set prop [regsub -all {\{|\}} [lindex $dtval 0] ""]
							set va [split $multival " "]
							set len [expr [llength $va]]
							for {set i 0} {$i < $len} {incr i} {
								set ind [string index [lindex $va $i] end]
								if {[string match $ind ";"]} {
									set temp_va [string trimright [lindex $va $i] ";"]
								} elseif {[string match $ind ","]} {
									set temp_va [string trimright [lindex $va $i] ","]
								}
								if {$i == 0} {
									set dtval $temp_va
								} else {
									append dtval " " $temp_va
								}
							}
						} else {
							##TODO for multiple values
							set value [lindex $dtval 1]
							set prop [regsub -all {\{|\}} [lindex $dtval 0] ""]
							set prop [string trimright $prop " "]
							set dtval [string trimright $value ";"]
						}
					}
					if {[string match -nocase $parent ""]} {
					} else {
						set prop [string trimright $prop " "]
						$psdt set $parent $prop $dtval
					}
				} 
			}	
		}
	}
}

proc create_busmap args {
	set dt [lindex $args 0]
	set bool_col 0
	if {[string match -nocase $dt "psdt"]} {
		set bool_col 1
	}
	set valid 0
	if {[string match -nocase $dt "pldt"]} {
		set valid 1
	}
	set rootn [lindex $args 1]
	set mainroot [$dt children $rootn]
	set values ""
	foreach children $mainroot {
		append values "$children\n"
		set childs [$dt children $children]
		foreach child $childs {
			append values "$child\n"
			set nestchilds [$dt children $child]
			foreach child $nestchilds {
				append values "$child\n"
				set innerchilds [$dt children $child]
				foreach child $innerchilds {
					append values "$child\n"
					set nextinner [$dt children $child]
					foreach child $nextinner {
						set temp [split $child ":"]
						append values "[lindex $temp 0]\n"
					}
				}
			}
		}
	}
	return $values
}

proc write_dt args {
	set dt [lindex $args 0]
	set bool_col 0
	if {[string match -nocase $dt "psdt"]} {
		set bool_col 1
	}
	set valid 0
	if {[string match -nocase $dt "pldt"]} {
		set valid 1
	}
	set rootn [lindex $args 1]
	set file [lindex $args 2]
	set mainroot [$dt children $rootn]
	if {[catch {set rt [exec touch $file]} msg]} {
#		error "file creation error"
	}
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	# Windows treats an empty env variable as not defined
	if {[catch {set board_dtsi_file $env(sdt_board_dts)} msg]} {
		set board_dtsi_file ""
	}
	set fd [open $file w]
	if {[string match -nocase $dt "systemdt"]} {
		puts $fd "\/dts-v1\/\;"
		global include_list
		set includelist [split $include_list ","]
		foreach val $includelist {
			if {$val == "${board_dtsi_file}.dtsi"} {
				continue
			}
			puts $fd "#include \"$val\""
		}
	}
	set dtcheck [string match -nocase $dt "pcwdt"]
	if {$dtcheck != 1} {
		puts $fd "/ \{"
	}
	set proplist [$dt getall $rootn]

	if {[string match -nocase $proplist ""]} {
	} else {

		set lenact [llength $proplist]
		set len [expr $lenact / 2]
		for {set pr 0} {$pr <= $lenact} {} {
			set prop [lindex $proplist $pr]
			if {[string match -nocase $prop ""] || [string match -nocase $prop "data"]} {
			} else {
				set val [$dt get $rootn $prop]
				set val_temp [string trimright $val " "]
				set val_temp [string trimleft $val_temp " "]
				if {[llength $val] > 1} {
					puts $fd "\t$prop = $val;"
				} else {
					if {[string match -nocase $val ""]} {
						if {$bool_col} {
							puts $fd "\t$prop"
						} else {
							puts $fd "\t$prop"
						}
					} else {
						puts $fd "\t$prop = $val;"
					}
				}
			}
			set pr [expr $pr + 2]
		}
	}
	foreach children $mainroot {
		puts $fd "\t$children {"
		set childs [$dt children $children]
		set proplist [$dt getall $children]
		if {[string match -nocase $valid "1"]} {
		}
		if {[string match -nocase $proplist ""]} {
		} else {
			set lenact [llength $proplist]
			set len [expr $lenact / 2]
			for {set pr 0} {$pr <= $lenact} {} {
				set prop [lindex $proplist $pr]
				if {[string match -nocase $prop ""] || [string match -nocase $prop "data"]} {
				} else {
					set val [$dt get $children $prop]
					set val_temp [string trimright $val " "]
					set val_temp [string trimleft $val_temp " "]
					if {[llength $val] > 1} {

						if {[regexp -all {^[\<]} $val_temp matched] && [regexp -all {[\>]$} $val_temp matched]} {
							puts $fd "\t\t$prop = $val_temp;"

						} else {	
							set first_str "\"[lindex $val 0]\""
							set first_str "\"[lindex $val 0]\""
							set first_str ""
							set first true
       		         				foreach element $val {
       	        	 					if {$first != true} {
                						} 
								set first false
							}
							puts $fd "\t\t$prop = $val;"
						} 
					} else {
						if {[string match -nocase $val ""]} {
							if {$bool_col} {
								puts $fd "\t\t$prop"
							} else {
								puts $fd "\t\t$prop;"
							}
						} else {
							puts $fd "\t\t$prop = $val;"
						}
					}
				}
				set pr [expr $pr + 2]
			}
		}
		foreach child $childs {
			puts $fd "\t\t$child {"
			set nestchilds [$dt children $child]
			set proplist [$dt getall $child]
			if {[string match -nocase $proplist ""]} {
			} else {
				set lenact [llength $proplist]
				set len [expr $lenact / 2]
				for {set pr 0} {$pr <= $lenact} {} {
					if {[string match -nocase $child "can0: can@ff060000"]} {
					}
					set prop [lindex $proplist $pr]
					if {[string match -nocase $prop ""] || [string match -nocase $prop "data"]} {
					} else {
						set val [$dt get $child $prop]
						set val_temp [string trimright $val " "]
						set val_temp [string trimleft $val_temp " "]
						if {[llength $val] > 1} {
							if {[regexp -all {^[\<]} $val_temp matched] && [regexp -all {[\>]$} $val_temp matched]} {
								puts $fd "\t\t\t$prop = $val_temp;"
							} else {
								set first_str "\"[lindex $val 0]\""
								set first_str "\"[lindex $val 0]\""
								set first_str ""
								set first true
       				         			foreach element $val {
       			        	 				if {$first != true} {
       			         					} 
									set first false
								}
								puts $fd "\t\t\t$prop = $val;"
							} 
						} else {
							if {[string match -nocase $val ""]} {
								if {$bool_col} {
									puts $fd "\t\t\t$prop"
								} else {
									puts $fd "\t\t\t$prop;"
								}
							} else {
								puts $fd "\t\t\t$prop = $val;"
							}
						} 
					}
					set pr [expr $pr + 2]
				}
			}
			
			foreach child $nestchilds {
				puts $fd "\t\t\t$child {"
				set innerchilds [$dt children $child]
				set proplist [$dt getall $child]
				if {[string match -nocase $proplist ""]} {
				} else {
					set lenact [llength $proplist]
					set len [expr $lenact / 2]
					for {set pr 0} {$pr <= $lenact} {} {
						set prop [lindex $proplist $pr]
						if {[string match -nocase $prop ""] || [string match -nocase $prop "data"]} {
						} else {
							set val [$dt get $child $prop]
							set val_temp [string trimright $val " "]
							set val_temp [string trimleft $val_temp " "]
							if {[llength $val] > 1} {
								if {[regexp -all {^[\<]} $val_temp matched] && [regexp -all {[\>]$} $val_temp matched]} {
									puts $fd "\t\t\t\t$prop = $val_temp;"
								} else {
									set first_str "\"[lindex $val 0]\""
									set first_str "\"[lindex $val 0]\""
									set first_str ""
									set first true
                							foreach element $val {
                      			 		 			if {$first != true} {
                								} 
										set first false
									}
									puts $fd "\t\t\t\t$prop = $val;"
								}
							} else {
								if {[string match -nocase $val ""]} {
									if {$bool_col} {
										puts $fd "\t\t\t\t$prop"
									} else {
										puts $fd "\t\t\t\t$prop;"
									}
								} else {
									puts $fd "\t\t\t\t$prop = $val;"
								}
							}
						}
						set pr [expr $pr + 2]
					}
				}
				foreach child $innerchilds {
					puts $fd "\t\t\t\t$child {"
					set nextinner [$dt children $child]
					set proplist [$dt getall $child]
					if {[string match -nocase $proplist ""]} {
					} else {
						set lenact [llength $proplist]
						set len [expr $lenact / 2]
						for {set pr 0} {$pr <= $lenact} {} {
							set prop [lindex $proplist $pr]
							if {[string match -nocase $prop ""] || [string match -nocase $prop "data"]} {
							} else {
								set val [$dt get $child $prop]
								set val_temp [string trimright $val " "]
								set val_temp [string trimleft $val_temp " "]
								if {[llength $val] > 1} {
									if {[regexp -all {^[\<]} $val_temp matched] && [regexp -all {[\>]$} $val_temp matched]} {
										puts $fd "\t\t\t\t\t$prop = $val_temp;"
									} else {
										set first_str "\"[lindex $val 0]\""
										set first_str "\"[lindex $val 0]\""
										set first_str ""
										set first true
		        							foreach element $val {
		              			 		 			if {$first != true} {
		        								} 
											set first false
										}
										puts $fd "\t\t\t\t\t$prop = $val;"
									}
								} else {
									if {[string match -nocase $val ""]} {
										if {$bool_col} {
											puts $fd "\t\t\t\t\t$prop"
										} else {
											puts $fd "\t\t\t\t\t$prop;"
										}
									} else {
										puts $fd "\t\t\t\t\t$prop = $val;"
									}
								}
							}
							set pr [expr $pr + 2]
						}
					}
					foreach child $nextinner {
						puts $fd "\t\t\t\t\t$child {"
						set proplist [$dt getall $child]
						if {[string match -nocase $proplist ""]} {
						} else {
							set lenact [llength $proplist]
							set len [expr $lenact / 2]
							for {set pr 0} {$pr <= $lenact} {} {
								set prop [lindex $proplist $pr]
								if {[string match -nocase $prop ""] || [string match -nocase $prop "data"]} {
								} else {
									set val [$dt get $child $prop]
									set val_temp [string trimright $val " "]
									set val_temp [string trimleft $val_temp " "]
									if {[llength $val] > 1} {
										if {[regexp -all {^[\<]} $val_temp matched] && [regexp -all {[\>]$} $val_temp matched]} {
											puts $fd "\t\t\t\t\t\t$prop = $val_temp;"
										} else {
											set first_str "\"[lindex $val 0]\""
											set first_str "\"[lindex $val 0]\""
											set first_str ""
											set first true
											foreach element $val {
				      			 		 			if {$first != true} {
												} 
												set first false
											}
											puts $fd "\t\t\t\t\t\t$prop = $first_str;"
										}
									} else {
										if {[string match -nocase $val ""]} {
											if {$bool_col} {
												puts $fd "\t\t\t\t\t\t$prop"
											} else {
												puts $fd "\t\t\t\t\t\t$prop;"
											}
										} else {
											puts $fd "\t\t\t\t\t\t$prop = $val;"
										}
									}
								}
								set pr [expr $pr + 2]
							}
					}
					puts $fd "\t\t\t\t\t};"
				}
					puts $fd "\t\t\t\t};"
				}
				puts $fd "\t\t\t};"
			}
			
			puts $fd "\t\t};"
		}
		puts $fd "\t};"

	}
	if {$dtcheck != 1} {
		puts $fd "\};"
	}
	# Windows treats an empty env variable as not defined
	if {[catch {set user_dts $env(user_dts)} msg]} {
		set user_dts ""
	}
	if {[string match -nocase $dt "systemdt"]} {
		if {![string_is_empty $board_dtsi_file]} {
			puts $fd "#include \"${board_dtsi_file}.dtsi\""
		}
		foreach include_dts_file [split $user_dts] {
			set include_dts_filename [file tail $include_dts_file]
			puts $fd "#include \"$include_dts_filename\""
		}
	}

	close $fd
}

proc get_repo_path args {
	if { [info exists ::env(CUSTOM_SDT_REPO) ] } {
		set path $env(repo_path)
		return $path
	} else {
		error "No repo found, please set it using ser env(CUSTOM_SDT_REPO) PATH"
		return ""
	}
}

proc get_drivers args {
	set driverlist [dict create]
	dict set driverlist RM driver RM
	dict set driverlist ai_engine driver ai_engine
	dict set driverlist psu_ams driver ams
	dict set driverlist psu_apm driver apmps
	dict set driverlist psv_apm driver apmps
	dict set driverlist psx_apm driver apmps
	dict set driverlist apm driver apmps
	dict set driverlist v_uhdsdi_audio driver audio_embed
	dict set driverlist audio_formatter driver audio_spdif
	dict set driverlist spdif driver audio_spdif
	dict set driverlist axi_bram_ctrl driver axi_bram
	dict set driverlist lmb_bram_if_cntlr driver axi_bram
	dict set driverlist can driver axi_can
	dict set driverlist v_dp_txss1 driver dp_tx
	dict set driverlist v_dp_rxss1 driver dp_rx
	dict set driverlist canfd driver canfd
	dict set driverlist axi_cdma driver axi_cdma
	dict set driverlist clk_wiz driver axi_clk_wiz
	dict set driverlist clk_wizard driver axi_clk_wiz
	dict set driverlist axi_fifo_mm_s driver axi_fifo_mm_s
	dict set driverlist mutex driver mutex
	dict set driverlist mailbox driver mailbox
	dict set driverlist axi_dma driver axi_dma
	dict set driverlist axi_emc driver axi_emc
	dict set driverlist axi_ethernet driver axi_ethernet
	dict set driverlist axi_ethernet_buffer  driver axi_ethernet
	dict set driverlist axi_10g_ethernet driver axi_ethernet
	dict set driverlist xxv_ethernet driver axi_ethernet
	dict set driverlist usxgmii driver axi_ethernet
	dict set driverlist axi_gpio driver axi_gpio
	dict set driverlist axi_iic driver axi_iic
	dict set driverlist axi_i3c driver axi_i3c
	dict set driverlist axi_mcdma driver axi_mcdma
	dict set driverlist axi_pcie driver axi_pcie
	dict set driverlist axi_pcie3 driver axi_pcie
	dict set driverlist xdma driver axi_pcie
	dict set driverlist qdma driver xdmapcie
	dict set driverlist pcie_dma_versal driver axi_pcie
	dict set driverlist axi_perf_mon driver axi_perf_mon
	dict set driverlist axi_quad_spi driver axi_qspi
	dict set driverlist axi_sysace driver axi_sysace
	dict set driverlist axi_tft driver axi_tft
	dict set driverlist axi_timebase_wdt driver axi_timebase_wdt
	dict set driverlist axi_traffic_gen driver axi_traffic_gen
	dict set driverlist axi_usb2_device driver axi_usb2_device
	dict set driverlist vcu driver axi_vcu
	dict set driverlist axi_vdma driver axi_vdma
	dict set driverlist xadc_wiz driver axi_xadc
	dict set driverlist psu_canfd driver canfd
	dict set driverlist psv_canfd driver canfd
	dict set driverlist psx_canfd driver canfd
	dict set driverlist canfd driver canfd
	dict set driverlist ps7_can driver canps
	dict set driverlist psu_can driver canps
	dict set driverlist psv_can driver canps
	dict set driverlist microblaze driver cpu
	dict set driverlist microblaze_riscv driver cpu
	dict set driverlist psu_cortexa53 driver cpu_cortexa53
	dict set driverlist psv_cortexa72 driver cpu_cortexa72
	dict set driverlist ps7_cortexa9 driver cpu_cortexa9
	dict set driverlist psu_cortexr5 driver cpu_cortexr5
	dict set driverlist psv_cortexr5 driver cpu_cortexr5
	dict set driverlist psu_crl_apb driver crl_apb
	dict set driverlist ps7_ddrc driver ddrcps
	dict set driverlist psu_ddrc driver ddrcps
	dict set driverlist psv_ddrc driver ddrcps
	dict set driverlist ps7_ddr driver ddrcps
	dict set driverlist psu_ddr driver ddrps
	dict set driverlist psv_ddr driver ddrps
	dict set driverlist axi_noc driver ddrpsv
	dict set driverlist axi_noc2 driver ddrpsv
	dict set driverlist noc_mc_ddr4 driver ddrpsv
	dict set driverlist noc_mc_ddr5 driver ddrpsv
	dict set driverlist debug_bridge driver debug_bridge
	dict set driverlist v_demosaic driver demosaic
	dict set driverlist ps7_dev_cfg driver devcfg
	dict set driverlist ps7_dma driver dmaps
	dict set driverlist psu_gdma driver dmaps
	dict set driverlist psu_csudma driver dmaps
	dict set driverlist psv_adma driver dmaps
	dict set driverlist psx_adma driver dmaps
	dict set driverlist adma driver dmaps
	dict set driverlist psv_gdma driver dmaps
	dict set driverlist psx_gdma driver dmaps
	dict set driverlist gdma driver dmaps
	dict set driverlist psv_csudma driver dmaps
	dict set driverlist psx_csudma driver dmaps
	dict set driverlist csudma driver dmaps
	dict set driverlist psu_dp driver dp
	dict set driverlist psv_dp driver dp
	dict set driverlist dpu_eu driver dpu_eu
	dict set driverlist axi_ethernetlite driver emaclite
	dict set driverlist ps7_ethernet driver emacps
	dict set driverlist psu_ethernet driver emacps
	dict set driverlist psv_ethernet driver emacps
	dict set driverlist psx_ethernet driver emacps
	dict set driverlist ethernet driver emacps
	dict set driverlist ernic driver ernic
	dict set driverlist v_frmbuf_rd driver framebuf_rd
	dict set driverlist v_frmbuf_wr driver framebuf_wr
	dict set driverlist v_gamma_lut driver gamma_lut
	dict set driverlist ps7_globaltimer driver globaltimerps
	dict set driverlist ps7_gpio driver gpiops
	dict set driverlist psu_gpio driver gpiops
	dict set driverlist psv_gpio driver gpiops
	dict set driverlist psx_gpio driver gpiops
	dict set driverlist gpio driver gpiops
	dict set driverlist hdmi_acr_ctlr driver hdmi_ctrl
	dict set driverlist hdmi_gt_controller driver hdmi_gt_ctrl
	dict set driverlist v_hdmi_rx_ss driver hdmi_rx_ss
	dict set driverlist v_hdmi_tx_ss driver hdmi_tx_ss
	dict set driverlist i2s_receiver driver i2s_receiver
	dict set driverlist i2s_transmitter driver i2s_transmitter
	dict set driverlist ps7_i2c driver iicps
	dict set driverlist psu_i2c driver iicps
	dict set driverlist psv_i2c driver iicps
	dict set driverlist psx_i3c driver i3cpsx
	dict set driverlist i3c driver i3cpsx
	dict set driverlist axi_intc driver intc
	dict set driverlist iomodule driver iomodule
	dict set driverlist psu_ipi driver ipipsu
	dict set driverlist psv_ipi driver ipipsu
	dict set driverlist psx_ipi driver ipipsu
	dict set driverlist ipi driver ipipsu
	dict set driverlist mig_7series driver mig_7series
	dict set driverlist dd4 driver mig_7series
	dict set driverlist ddr3 driver mig_7series
	dict set driverlist mipi_csi2_rx_subsystem driver mipi_csi2_rx
	dict set driverlist mipi_csi2_tx_subsystem driver mipi_csi2_tx
	dict set driverlist v_mix driver mixer
	dict set driverlist v_multi_scaler driver multi_scaler
	dict set driverlist ps7_nand driver nandps
	dict set driverlist psu_nand driver nandps
	dict set driverlist ps7_sram driver norps
	dict set driverlist nvme_subsystem driver nvme_aggr
	dict set driverlist ps7_ocmc driver ocmcps
	dict set driverlist psu_ocmc driver ocmcps
	dict set driverlist psv_ocmc driver ocmcps
	dict set driverlist ps7_pl310 driver pl310ps
	dict set driverlist psu_pmu driver pmups
	dict set driverlist psv_pmc driver pmups
	dict set driverlist psv_psm driver pmups
	dict set driverlist pr_decoupler driver pr_decoupler
	dict set driverlist prc driver prc
	dict set driverlist dfx_controller driver prc
   dict set driverlist visp_ss driver visp_ss
	# What is psu_ocm
	dict set driverlist psu_ocm_ram_0 driver psu_ocm
	dict set driverlist psv_ocm_ram_0 driver psu_ocm
	dict set driverlist psx_ocm_ram driver psu_ocm
	dict set driverlist ocm_ram driver psu_ocm
	dict set driverlist ps7_ram driver ramps
	dict set driverlist usp_rf_data_converter driver rfdc
	dict set driverlist v_scenechange driver scene_change_detector
	dict set driverlist ps7_scugic driver scugic
	dict set driverlist psu_acpu_gic driver scugic
	dict set driverlist psv_acpu_gic driver scugic
	dict set driverlist psx_acpu_gic driver scugic
	dict set driverlist acpu_gic driver scugic
	dict set driverlist ps7_scutimer driver scutimer
	dict set driverlist ps7_scuwdt driver scuwdt
	dict set driverlist psu_wdt driver scuwdt
	dict set driverlist psv_wdt driver scuwdt
	dict set driverlist sd_fec driver sdfec
	dict set driverlist v_smpte_uhdsdi_rx_ss driver sdi_rx
	dict set driverlist v_smpte_uhdsdi_tx_ss driver sdi_tx
	dict set driverlist ps7_sdioi driver sdps
	dict set driverlist psu_sd driver sdps
	dict set driverlist psv_pmc_sd driver sdps
	dict set driverlist psx_pmc_sd driver sdps
	dict set driverlist ps7_slcr driver slcrps
	dict set driverlist ps7_smcc driver smccps
	dict set driverlist ps7_spi driver spips
	dict set driverlist psu_qspi driver spips
	dict set driverlist psv_pmc_qspi driver qspips
	dict set driverlist psx_pmc_qspi driver qspips
	dict set driverlist pmc_qspi driver qspips
	dict set driverlist psu_qspi driver qspips
	dict set driverlist ps7_qspi driver qspips
	dict set driverlist psv_spi driver spips
	dict set driverlist sync_ip driver sync_ip
	dict set driverlist axi_timer driver tmrctr
	dict set driverlist v_tpg driver tpg
	dict set driverlist tsn_endpoint_ethernet_mac driver tsn
	dict set driverlist ps7_ttc driver ttcps
	dict set driverlist psu_ttc driver ttcps
	dict set driverlist psv_ttc driver ttcps
	dict set driverlist psx_ttc driver ttcps
	dict set driverlist ttc driver ttcps
	dict set driverlist mdm driver uartlite
	dict set driverlist axi_uartlite driver uartlite
	dict set driverlist axi_uart16550 driver uartns
	dict set driverlist ps7_uart driver uartps
	dict set driverlist psu_uart driver uartps
	dict set driverlist psu_sbsauart driver uartps
	dict set driverlist psv_uart driver uartps
	dict set driverlist psv_sbsauart driver uartps
	dict set driverlist psx_sbsauart driver uartps
	dict set driverlist sbsauart driver uartps
	dict set driverlist ps7_coresight_comp driver coresight
	dict set driverlist psu_coresight_0 driver coresight
	dict set driverlist psv_coresight driver coresight
	dict set driverlist psx_coresight driver coresight
	dict set driverlist coresight driver coresight
	dict set driverlist ps7_usb driver usbps
	dict set driverlist psu_usb_xhci driver usbps
	dict set driverlist psv_usb_xhci driver usbps
	dict set driverlist vid_phy_controller driver vid_phy_ctrl
	dict set driverlist v_proc_ss driver vproc_ss
	dict set driverlist v_tc driver vtc
	dict set driverlist ps7_wdt driver wdtps
	dict set driverlist psu_wdt driver wdtps
	dict set driverlist psv_wdt driver wdtps
	dict set driverlist ps7_xadc driver xadcps
	dict set driverlist psv_pmc_sysmon driver sysmonpsv
	dict set driverlist pmc_sysmon driver sysmonpsv
	dict set driverlist mrmac driver mrmac
	set val [lindex $args 0]
	if {[string match -nocase $val "1"]} {
		set drivers ""
		foreach drv_handle [hsi::get_cells -hier] {
			set ipname [hsi get_property IP_NAME $drv_handle]
			set val [hsi::get_mem_ranges $drv_handle]
			if {[string match -nocase [get_ip_property $drv_handle IP_TYPE] "processor"]} {
				if {[string match -nocase $ipname "psv_cortexa72"] || [string match -nocase $ipname "psu_cortexa53"]} {
					set index [string index $drv_handle end]
					if {$index == 0} {
						continue
					}
				}
			} else {
				if {[string_is_empty $val]} {
					continue
				}
			}
			if {[catch {set tmp [dict get $driverlist $ipname]} msg]} {
					continue
			}
			if {[string match -nocase $drivers ""]} {
				set drivers $drv_handle
			} else {
				lappend drivers $drv_handle
			}
		}
		
		if {[string match -nocase $drivers ""]} {
			set drivers "generic"
		}
		return $drivers
	} else {
		set ipname [get_ip_property [hsi::get_cells -hier $val] IP_NAME]
		if {[catch {set tmp [dict get $driverlist $ipname]} msg]} {
			set drivers "generic"
			return "generic"
		}
		regsub "driver " $tmp "" tmp
		return $tmp
	}
}

proc get_clock_frequency {ip_handle portname} {
	set clk ""
	set clkhandle [hsi::get_pins -of_objects $ip_handle $portname]
	if {[string compare -nocase $clkhandle ""] != 0} {
		set width [get_port_width $clkhandle]
		if {$width >= 2} {
			set clk [hsi get_property CLK_FREQ $clkhandle ]
			regsub -all ":" $clk { } clk
			set clklen [llength $clk]
			if {$clklen > 1} {
				foreach clk_e $clk {
					if { $clk_e != "NULL" } {
						set clk $clk_e
					}
				}
			}
		} else {
			set clk [hsi get_property CLK_FREQ $clkhandle ]
		}
	}
	return $clk
}

proc gen_fixed_factor_clk_node {misc_clk_node clk_freq dts_file} {
	set zynq_periph [hsi get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
	set pl0_clk_val [hsi get_property CONFIG.C_PL_CLK0_BUF [hsi get_cells -hier $zynq_periph]]
	set pl1_clk_val [hsi get_property CONFIG.C_PL_CLK1_BUF [hsi get_cells -hier $zynq_periph]]
	set pl2_clk_val [hsi get_property CONFIG.C_PL_CLK2_BUF [hsi get_cells -hier $zynq_periph]]
	set pl3_clk_val [hsi get_property CONFIG.C_PL_CLK3_BUF [hsi get_cells -hier $zynq_periph]]
	set parent_freq ""
	set div ""
	set mult ""
	if {[string match -nocase $pl0_clk_val "true"]} {
		set parent_freq [hsi get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ [hsi get_cells -hier $zynq_periph]]
		set clock_name "zynqmp_clk 71"
	} elseif {[string match -nocase $pl1_clk_val "true"]} {
		set parent_freq [hsi get_property CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ [hsi get_cells -hier $zynq_periph]]
		set clock_name "zynqmp_clk 72"
	} elseif {[string match -nocase $pl2_clk_val "true"]} {
		set parent_freq [hsi get_property CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ [hsi get_cells -hier $zynq_periph]]
		set clock_name "zynqmp_clk 73"
	} elseif {[string match -nocase $pl3_clk_val "true"]} {
		set parent_freq [hsi get_property CONFIG.PSU__CRL_APB__PL3_REF_CTRL__ACT_FREQMHZ [hsi get_cells -hier $zynq_periph]]
		set clock_name "zynqmp_clk 74"
	}

	if {![string equal $parent_freq ""]} {
		set parent_freq [expr $parent_freq * 1000000]
		if {$parent_freq >= $clk_freq} {
			set div [expr round($parent_freq * 1000 / $clk_freq)]
			set mult 1000
		} elseif {$parent_freq < $clk_freq} {
			set mult [expr round($clk_freq * 1000 / $parent_freq)]
			set div 1000
		}
	}
	if {![string equal $div ""] && ![string equal $mult ""]} {
		add_prop "${misc_clk_node}" "compatible" "fixed-factor-clock" stringlist $dts_file 1
		add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file 1
		add_prop "${misc_clk_node}" "clocks" $clock_name reference $dts_file 1
		add_prop "${misc_clk_node}" "clock-div" $div int $dts_file 1
		add_prop "${misc_clk_node}" "clock-mult" $mult int $dts_file 1
	} else {
		add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file 1
		add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file 1
		add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file 1
	}
}

proc set_drv_property args {
	set drv_handle [lindex $args 0]
	set dts_file [set_drv_def_dts $drv_handle]
	set conf_prop [lindex $args 1]
	set value [lindex $args 2]
	set node [lindex $args 3]
	if {[llength $value] != 0} {
		if {$value != "-1" && [llength $value] != 0} {
			set type "hexint"
			if {[llength $args] >= 5} {
				set type [lindex $args 4]
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
			}
			# remove CONFIG. as add_new_property does not work with CONFIG.
			regsub -all {^CONFIG.} $conf_prop {} conf_prop
			#set node [get_node $drv_handle]
			add_prop $node $conf_prop $value $type $dts_file
		}
	}
}

# set driver property based on IP property
proc set_drv_conf_prop args {
	set drv_handle [lindex $args 0]
	set pram [lindex $args 1]
	set conf_prop [lindex $args 2]
	set node [lindex $args 3]
	set ip [hsi::get_cells -hier $drv_handle]
	set value [hsi get_property CONFIG.${pram} $ip]
	if {[llength $value] !=0} {
		regsub -all "MIO( |)" $value "" value
		if {$value != "-1" && [llength $value] !=0} {
			set type "hexint"
			if {[llength $args] >= 5} {
				set type [lindex $args 4]
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
			}
			regsub -all {^CONFIG.} $conf_prop {} conf_prop
			#set node [get_node $drv_handle]
			set name [get_ip_property $drv_handle IP_NAME]
			set dts_file [set_drv_def_dts $drv_handle]
			if {[string match -nocase $dts_file "pcw.dtsi"]} {
				set treeobj "pcwdt"
			} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
				set treeobj "pldt"
			} elseif {[string match -nocase $dts_file "versal.dtsi"] || [string match -nocase $dts_file "zynqmp.dtsi"]} {
				set treeobj "psdt"
			} else {
				set treeobj "systemdt"
			}
			if {[catch {set val [$treeobj get $node $conf_prop]} msg]} {
				add_prop $node $conf_prop $value $type $dts_file
			} else {
				add_prop $node $conf_prop $value $type $dts_file 1
			}
		}
	}
}

# set driver property based on other IP's property
proc add_cross_property args {
	set src_handle [lindex $args 0]
	set src_prams [lindex $args 1]
	set dest_handle [lindex $args 2]
	set dest_prop [lindex $args 3]
	set node [lindex $args 4]
	set ip [hsi::get_cells -hier $src_handle]
	set ipname [hsi get_property IP_NAME $ip]
	set proctype [get_hw_family]
	set valid_proclist "psv_cortexa72 psv_cortexr5 psu_cortexa53 psu_cortexr5 psu_pmu psv_pmc psv_psm ps7_cortexa9 microblaze microblaze_riscv psx_cortexa78 psx_cortexr52 psx_pmc psx_psm cortexa78 cortexr52 pmc psm"
	set type "hexint"
	if {[llength $args] >= 6} {
		set type [lindex $args 5]
	}
	set sub 0
	if {[regexp "(int|hex).*" $type match]} {
		set sub 1
	}
	foreach conf_prop $src_prams {
		set value [hsi get_property $conf_prop $ip]
		# ddrc (&mc) reports some of the properties (like PARITY) as NA
		# which results into wrong config structure entries.
		if  {[string match -nocase $value "NA"]} {
			continue
		}
		if {$conf_prop == "CONFIG.processor_mode"} {
			set value "true"
		}
		if {$ipname == "axi_ethernet"} {
			set value [is_property_set $value]
		}
		if {[llength $value]} {
			if {$value != "-1" && [llength $value] !=0} {
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
				if {$sub} {
					regsub -all {"} $value "" value
				}
				if {[string match -nocase $ipname "axi_mcdma"] && [string match -nocase $dest_prop "xlnx,include-sg"] } {
					set value ""
				}

				if {[string match -nocase $ipname "psv_rcpu_gic"]} {
					set node [create_node -n "&gic_r5" -d "pcw.dtsi" -p root]
				} elseif {$ipname in {"psx_rcpu_gic" "rcpu_gic"}} {
					set node [create_node -n "&gic_r52" -d "pcw.dtsi" -p root]
				} elseif {[lsearch $valid_proclist $ipname] >= 0} {
					set node [get_node $src_handle]
				} else {
					set node [get_node $dest_handle]
				}
				if {[string match -nocase $dest_prop "xlnx,s-axi-highaddr"] ||[string match -nocase $dest_prop "xlnx,s-axi-baseaddr"] } {
					return 0
				}
				if {[string match -nocase $dest_prop "xlnx,intc-level-edge"]} {
                                       set value [expr $value << 16 | 0x7fff]
                                }
				add_prop $node $dest_prop $value $type [set_drv_def_dts $dest_handle]
				return 0
			}
		}
	}
}

# TODO: merge to add_cross_property by detecting if dest_node is dt node or driver
proc add_cross_property_to_dtnode args {
	set src_handle [lindex $args 0]
	set src_prams [lindex $args 1]
	set dest_node [lindex $args 2]
	set dest_prop [lindex $args 3]
	set ip [hsi::get_cells -hier $src_handle]
	set dts_file [set_drv_def_dts $src_handle]
	foreach conf_prop $src_prams {
		set value [hsi get_property ${conf_prop} $ip]
		if {[llength $value]} {
			if {$value != "-1" && [llength $value] !=0} {
				set type "hexint"
				if {[llength $args] >= 5} {
					set type [lindex $args 4]
				}
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
				if {[regexp "(int|hex).*" $type match]} {
					regsub -all {"} $value "" value
				}
				add_prop $dest_node $dest_prop $value $type $dts_file
				return 0
			}
		}
	}
}

proc get_ip_property {drv_handle parameter} {
	global property_dict
	global cur_hw_design
	if { [dict exists $property_dict $cur_hw_design $drv_handle $parameter] } {
		return [dict get $property_dict $cur_hw_design $drv_handle $parameter]
	}
	set ip [hsi::get_cells -hier $drv_handle]
	if {[catch {set val [hsi get_property ${parameter} $ip]} msg]} {
		set val ""
	}
	dict set property_dict $cur_hw_design $drv_handle $parameter $val
	return $val
}

proc get_obj_property {handle parameter} {
	# Helps in fetching properties for both cell and memory object.
	# It is caller's responsibility to pass the correct object.
	if {[catch {set val [hsi get_property ${parameter} $handle]} msg]} {
		set val ""
	}
	return $val
}

proc is_it_in_pl {ip} {
	# FIXME: This is a workaround to check if IP that's in PL however,
	# this is not entirely correct, it is a hack and only works for
	# IP_NAME that does not matches ps7_*
	# better detection is required

	# handles interrupt that coming from get_drivers only
	if {[llength [get_drivers $ip]] < 1} {
		return -1
	}
	set ip_type [hsi get_property IP_NAME $ip]
	if {![regexp "ps*" "$ip_type" match]} {
		return 1
	}
	return -1
}

proc get_intr_id {drv_handle intr_port_name} {
	global cur_hw_design
	global intr_id_dict
	if { [dict exists $intr_id_dict $cur_hw_design $drv_handle $intr_port_name] } {
		return [dict get $intr_id_dict $cur_hw_design $drv_handle $intr_port_name]
	}
	proc_called_by
	set slave [hsi::get_cells -hier $drv_handle]
	set intr_info ""
	set proctype [get_hw_family]
	foreach pin ${intr_port_name} {
		set intc [get_interrupt_parent $drv_handle $pin]
		# If intc is returned as empty string (e.g. when pin is cdma_introut for axi_cdma),
		# there is no need to proceed further
		if {[string_is_empty $intc] == 1} {continue}
		set intc_ipname [hsi get_property IP_NAME $intc]
		if {[string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype]} {
			if {[llength $intc] > 1} {
				foreach intr_cntr $intc {
					if { [is_ip_interrupting_current_proc $intr_cntr] } {
						set intc $intr_cntr
						set intc_ipname [hsi get_property IP_NAME $intc]
					}
				}
			}
			if {[is_zynqmp_platform $proctype] } {
				if {[string match -nocase $intc_ipname "axi_intc"]} {
					set intc [get_interrupt_parent $drv_handle $pin]
				}
			}
			if {[string match -nocase $proctype "versal"] && [string match -nocase $intc_ipname "axi_intc"] } {
				set intc [get_interrupt_parent $drv_handle $pin]
			}
		}
		if {[string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype]} {
			set intr_id [get_psu_interrupt_id $drv_handle $pin]
		} else {
			set intr_id [get_interrupt_id $drv_handle $pin]
		}
		if {[string match -nocase $intr_id "-1"]} {continue}
		set intr_type [get_intr_type $intc $slave $pin]
		if {[string match -nocase $intr_type "-1"]} {
			continue
		}

		set cur_intr_info ""
		if { [string match -nocase $proctype "zynq"] }  {
			if {[string match "[hsi get_property IP_NAME $intc]" "ps7_scugic"] } {
				if {$intr_id > 32} {
					set intr_id [expr $intr_id - 32]
				}
				set cur_intr_info "0 $intr_id $intr_type"
			} elseif {[string match "[hsi get_property IP_NAME $intc]" "axi_intc"] } {
				set cur_intr_info "$intr_id $intr_type"
			}
		} elseif {$intc_ipname in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic"}} {
		    set cur_intr_info "0 $intr_id $intr_type"
		} else {
			set cur_intr_info "$intr_id $intr_type"
		}
		if {[string_is_empty $intr_info]} {

			set intr_info "$cur_intr_info"
		} else {
			append intr_info " " $cur_intr_info
		}
	}
	if {[string_is_empty $intr_info]} {
		set intr_info -1
	}

	dict set intr_id_dict $cur_hw_design $drv_handle $intr_port_name $intr_info
	return $intr_info
}

proc dtg_debug msg {
	return
	puts "# [lindex [info level -1] 0] #>> $msg"
}

proc dtg_verbose msg {
       global env
       set verbose $env(verbose)
       if {[string match -nocase $verbose "enable"]} {
               puts "VERBOSE: $msg"
       }
}

proc dtg_warning msg {
	global env
	set debug $env(debug)
	if {[string match -nocase $debug "enable"]} {
		puts "WARNING: $msg"
	}
}

proc proc_called_by {} {
	global env
	set trace $env(trace)
	if {[string match -nocase $trace "enable"]} {
		puts "# [lindex [info level -1] 0] #>> called by [lindex [info level -2] 0]"
	} else {
		return
	}
}

proc Pop {varname {nth 0}} {
	upvar $varname args
	set r [lindex $args $nth]
	set args [lreplace $args $nth $nth]
	return $r
}

proc string_is_empty {input} {
	if {[string compare -nocase $input ""] != 0} {
		return 0
	}
	return 1
}

proc check_if_forty_bit_address {addr_map} {
	set forty_bit_address_value [string trimleft [lindex $addr_map 0] "<"]
	if {[string match -nocase ${forty_bit_address_value} "0x0"]} {
		return 0
	}
	return 1
}

proc gen_dt_node_search_pattern args {
	proc_called_by
	# generates device tree node search pattern and return it

	global def_string
	#foreach var {node_name node_label node_unit_addr} {
	#	set ${var} ${def_string}
	#}
	while {[string match -* [lindex $args 0]]} {
		switch -glob -- [lindex $args 0] {
			-n* {set node_name [Pop args 1]}
			-l* {set node_label [Pop args 1]}
			-u* {set node_unit_addr [Pop args 1]}
			-- {Pop args ; break}
			default {
				error "gen_dt_node_search_pattern bad option - [lindex $args 0]"
			}
		}
		Pop args
	}
	set pattern ""
	# TODO: is these search patterns correct
	# TODO: check if pattern in the list or not
	if {![string equal -nocase ${node_label} ${def_string}] && \
		![string equal -nocase ${node_name} ${def_string}] && \
		![string equal -nocase ${node_unit_addr} ${def_string}]} {
		lappend pattern "^${node_label}:${node_name}@${node_unit_addr}$"
		lappend pattern "^${node_name}@${node_unit_addr}$"
	}

	if {![string equal -nocase ${node_label} ${def_string}] && \
		![string equal -nocase ${node_name} ${def_string}]} {
		lappend pattern "^${node_label}:${node_name}"
	}

	if {![string equal -nocase ${node_name} ${def_string}] && \
		![string equal -nocase ${node_unit_addr} ${def_string}]} {
		lappend pattern "^${node_name}@${node_unit_addr}$"
	}

	if {![string equal -nocase ${node_label} ${def_string}]} {
		lappend pattern "^&${node_label}$"
		lappend pattern "^${node_label}:"
	}

	return $pattern
}

proc set_cur_working_dts {{dts_file ""}} {
	# set current working device tree
	# return the tree object
	proc_called_by
	if {[string_is_empty ${dts_file}] == 1} {
		return [current_dt_tree]
	}
	set dt_idx [lsearch [get_dt_trees] ${dts_file}]
	if {$dt_idx >= 0} {
		set dt_tree_obj [current_dt_tree [lindex [get_dt_trees] $dt_idx]]
	} else {
		set dt_tree_obj [create_dt_tree -dts_file $dts_file]
	}
	return $dt_tree_obj
}

proc remove_prefix_from_addr {addr} {
	regsub -all {^0x} $addr {} addr
	# Remove all the leading zeroes in the address.
	set addr [string trimleft $addr 0]
	if {[string_is_empty $addr]} {
		set addr "0"
	}
	return $addr
}

proc get_baseaddr {slave_ip {no_prefix ""} {proc_handle ""}} {
	global baseaddr_dict
	global cur_hw_design
	global processor_ip_list
	if { [string_is_empty $proc_handle] && [dict exists $baseaddr_dict $cur_hw_design $slave_ip] } {
		set baseaddr [dict get $baseaddr_dict $cur_hw_design $slave_ip]
		if {![string_is_empty $no_prefix]} {
			set baseaddr [remove_prefix_from_addr $baseaddr]
		}
		return $baseaddr
	}
	# only returns the first addr
	set ip_name [get_ip_property [hsi::get_cells -hier $slave_ip] IP_NAME]
	if {[string match -nocase $slave_ip "psu_sata"]} {
		set addr [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]]
	} elseif {$ip_name in {"psx_i3c" "i3c"}} {
		set addr1 [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]]
		set addr [format 0x%08x [expr {$addr1  + 0x8000}]]
	} elseif {[string match -nocase $ip_name "psv_cpm"]} {
		set rev_num -1
		set port_type_0 -1
		set port_type_1 -1
		set cpm_unit_addr ""
		set addr "0"
		foreach drv [hsi::get_cells -hier -filter IP_NAME==psv_cpm] {
			if {![regexp "pspmc.*" "$drv" match]} {
				set rev_num [get_ip_property $drv CONFIG.CPM_REVISION_NUMBER]
				set avail_param [hsi list_property $drv]
					if {[lsearch -nocase $avail_param "CONFIG.C_CPM_PCIE0_PORT_TYPE"] >= 0} {
						set port_type_0 [hsi get_property CONFIG.C_CPM_PCIE0_PORT_TYPE $drv]
					}
					if {[lsearch -nocase $avail_param "CONFIG.C_CPM_PCIE1_PORT_TYPE"] >= 0} {
						set port_type_1 [hsi get_property CONFIG.C_CPM_PCIE1_PORT_TYPE $drv]
					}
			}
		}
		if {($rev_num == 0) && ($port_type_0 || $port_type_1)} {
			# CONFIG.CPM_SLCR is for cpm4
			set cpm_unit_addr [hsi get_property CONFIG.CPM_SLCR [hsi::get_cells -hier $slave_ip]]
		} elseif {($rev_num == 1) && ($port_type_0 || $port_type_1)} {
			# CONFIG.CPM5_SLCR_ADDR is for cpm5
			set cpm_unit_addr [hsi get_property CONFIG.CPM5_SLCR_ADDR [hsi::get_cells -hier $slave_ip]]
		}
		if {[llength $cpm_unit_addr]} {
			set addr [string tolower $cpm_unit_addr]
		}
	} elseif {[string match -nocase $ip_name "mmi_pcie0_slcr"]} {
		set cpm_unit_addr ""
		set addr "0"
		set mmi_port_type ""

		set mmi_pcie0_ip [hsi::get_cells -hier -filter IP_NAME==mmi_pcie0]
		set mmi_ip_name [get_ip_property [hsi::get_cells -hier $mmi_pcie0_ip] IP_NAME]

		if {[string match -nocase $mmi_ip_name "mmi_pcie0"]} {
			set mmi_port_type [hsi get_property CONFIG.C_MMI_PCIE0_PORT_TYPE [hsi::get_cells -hier $mmi_pcie0_ip]]
		}

		if {[string match -nocase $mmi_port_type "Root_Port_of_PCIe_Root_Port_Complex"]} {
			if {[string match -nocase $ip_name "mmi_pcie0_slcr"]} {
				set cpm_unit_addr [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]
			}
			if {[llength $cpm_unit_addr]} {
				set addr [string tolower $cpm_unit_addr]
			}
		}
	} else {
		set ip_mem_handle [hsi::get_mem_ranges $slave_ip]
		if {![string_is_empty $proc_handle]} {
			# INTERFACE IPs (e.g. CCAT) are coming in get_mem_ranges -of_objects $proc_handle
			# but not coming in output of INSTANCE filter of get_mem_ranges
			set proc_filter_ip_mem_handle [lindex [hsi::get_mem_ranges -of_objects $proc_handle -filter INSTANCE==$slave_ip] 0]
			if {![string_is_empty $proc_filter_ip_mem_handle]} {
				set addr [string tolower [hsi get_property BASE_VALUE $proc_filter_ip_mem_handle]]
				if {![string_is_empty $no_prefix]} {
					set addr [remove_prefix_from_addr $addr]
				}
				return $addr
			}
		}
		if { [string_is_empty $ip_mem_handle] } {
			set avail_param [hsi list_property [hsi::get_cells -hier $slave_ip]]
			if {[lsearch -nocase $avail_param "CONFIG.C_BASEADDR"] >= 0 } {
				set addr [string tolower [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $slave_ip]]]
			} elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
				set addr [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]]
			} elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_CTRL_BASEADDR"] >= 0} {
				set addr [string tolower [hsi get_property CONFIG.C_S_AXI_CTRL_BASEADDR [hsi::get_cells -hier $slave_ip]]]
			} elseif {[lsearch -nocase $avail_param "CONFIG.AXI_CTRL_BASEADDR"] >= 0} {
				# IP v_smpte_uhdsdi_tx led to this addition
				set addr [string tolower [hsi get_property CONFIG.AXI_CTRL_BASEADDR [hsi::get_cells -hier $slave_ip]]]
			} else {
				return ""
			}
		} else {
			set handle_count 0
			# For versal PS IPs, check the Master Interface and use the mem_handles where
			# master interface starts with any of the available processor IPs. Many a times,
			# these IPs can have master interfaces as CPM_PCIE_NOC_0 or FPD_AXI_NOC_1 where
			# the addresses may overflow as these are not part of processor views.
			if {[string match -nocase [get_hw_family] "versal"] && [is_ps_ip $slave_ip]} {
				for {} {$handle_count < [llength $ip_mem_handle]} {incr handle_count} {
					set master_intf [hsi get_property MASTER_INTERFACE [lindex $ip_mem_handle $handle_count]]
					set pattern [join [lmap prefix $processor_ip_list {string cat $prefix*}] "|"]
					# Fetch the handle index only when master_intf matches with any of APU, RPU and Master PMC SLR
					# or the master interface is empty. Dont take the index when the only master present is the
					# respective slave SLR.
					if {([regexp $pattern $master_intf] && ![regexp -nocase {^slv([1-3])_} $master_intf]) || [string_is_empty $master_intf]} {
						break
					}
				}
			}
			# In one of the design, MAXIL, ps_pl_axil kind of IPs are coming in APU/RPU processor maps,
			# but none of the memory instances has valid processor as its master interface. Add a check
			# to return invalid baseaddress for such cases. Such IPs are not part of hsi get_cells -hier
			# output but are appearing under get_mem_ranges outputs (similar to CCAT case).
			if {$handle_count >= [llength $ip_mem_handle]} {
				return ""
			}
			set addr [string tolower [hsi get_property BASE_VALUE [lindex $ip_mem_handle $handle_count]]]
		}
	}
	dict set baseaddr_dict $cur_hw_design $slave_ip $addr
	if {![string_is_empty $no_prefix]} {
		set addr [remove_prefix_from_addr $addr]
	}
	return $addr
}

proc get_highaddr {slave_ip {no_prefix ""} {proc_handle ""}} {
	global highaddr_dict
	global cur_hw_design
	global processor_ip_list
	if { [string_is_empty $proc_handle] && [dict exists $highaddr_dict $cur_hw_design $slave_ip] } {
		set highaddr [dict get $highaddr_dict $cur_hw_design $slave_ip]
		if {![string_is_empty $no_prefix]} {
			set highaddr [remove_prefix_from_addr $highaddr]
		}
		return $highaddr
	}
	set ip_mem_handle [hsi::get_mem_ranges $slave_ip]
	if {![string_is_empty $proc_handle]} {
		# INTERFACE IPs (e.g. CCAT) are coming in get_mem_ranges -of_objects $proc_handle
		# but not coming in output of INSTANCE filter of get_mem_ranges
		set proc_filter_ip_mem_handle [lindex [hsi::get_mem_ranges -of_objects $proc_handle -filter INSTANCE==$slave_ip] 0]
		if {![string_is_empty $proc_filter_ip_mem_handle]} {
			set addr [string tolower [hsi get_property HIGH_VALUE $proc_filter_ip_mem_handle]]
			if {![string_is_empty $no_prefix]} {
				set addr [remove_prefix_from_addr $addr]
			}
			return $addr
		}
	}
        if { [string_is_empty $ip_mem_handle] } {
             set avail_param [hsi list_property [hsi::get_cells -hier $slave_ip]]
             if {[lsearch -nocase $avail_param "CONFIG.C_HIGHADDR"] >= 0 } {
                    set addr [string tolower [hsi get_property CONFIG.C_HIGHADDR [hsi::get_cells -hier $slave_ip]]]
             } elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_HIGHADDR"] >= 0} {
                    set addr [string tolower [hsi get_property CONFIG.C_S_AXI_HIGHADDR [hsi::get_cells -hier $slave_ip]]]
             } elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_CTRL_HIGHADDR"] >= 0} {
                    set addr [string tolower [hsi get_property CONFIG.C_S_AXI_CTRL_HIGHADDR [hsi::get_cells -hier $slave_ip]]]
             } elseif {[lsearch -nocase $avail_param "CONFIG.AXI_CTRL_HIGHADDR"] >= 0} {
                    # IP v_smpte_uhdsdi_tx led to this addition
                    set addr [string tolower [hsi get_property CONFIG.AXI_CTRL_HIGHADDR [hsi::get_cells -hier $slave_ip]]]
             } else {
                    return ""
             }
        } else {
		set handle_count 0
		# For versal PS IPs, check the Master Interface and use the mem_handles where
		# master interface starts with any of the available processor IPs. Many a times,
		# these IPs can have master interfaces as CPM_PCIE_NOC_0 or FPD_AXI_NOC_1 where
		# the addresses may overflow as these are not part of processor views.
		if {[string match -nocase [get_hw_family] "versal"] && [is_ps_ip $slave_ip]} {
			for {} {$handle_count < [llength $ip_mem_handle]} {incr handle_count} {
				set master_intf [hsi get_property MASTER_INTERFACE [lindex $ip_mem_handle $handle_count]]
				set pattern [join [lmap prefix $processor_ip_list {string cat $prefix*}] "|"]
				# Fetch the handle index only when master_intf matches with any of APU, RPU and Master PMC SLR
				# or the master interface is empty. Dont take the index when the only master present is the
				# respective slave SLR.
				if {([regexp $pattern $master_intf] && ![regexp -nocase {^slv([1-3])_} $master_intf]) || [string_is_empty $master_intf]} {
					break
				}
			}
		}
		set addr [string tolower [hsi get_property HIGH_VALUE [lindex $ip_mem_handle $handle_count]]]
	}
	dict set highaddr_dict $cur_hw_design $slave_ip $addr
	if {![string_is_empty $no_prefix]} {
		set addr [remove_prefix_from_addr $addr]
	}
	return $addr
}

proc get_all_tree_nodes {dts_file} {
	# Workaround for -hier not working with -of_objects
	# get all the nodes presented in a dt_tree and return node list
	proc_called_by
	set cur_dts [current_dt_tree]
	current_dt_tree $dts_file
	set all_nodes [get_dt_nodes -hier]
	current_dt_tree $cur_dts
	return $all_nodes
}

proc check_node_in_dts {node_name dts_file_list} {
	# check if the node is in the device-tree file
	# return 1 if found
	# return 0 if not found
	proc_called_by
	foreach tmp_dts_file ${dts_file_list} {
		set dts_nodes [get_all_tree_nodes $tmp_dts_file]
		# TODO: better detection here
		foreach pattern ${node_name} {
			foreach node ${dts_nodes} {
				if {[regexp $pattern $node match]} {
					dtg_debug "Node $node ($pattern) found in $tmp_dts_file"
					return 1
				}
			}
		}
	}
	return 0
}

proc get_node_object {lu_node {dts_files ""} {error_out "yes"}} {
	# get the node object based on the args
	# returns the dt node object
	proc_called_by
	if [string_is_empty $dts_files] {
		set dts_files [get_dt_trees]
	}
	set cur_dts [current_dt_tree]
	foreach dts_file ${dts_files} {
		set dts_nodes [get_all_tree_nodes $dts_file]
		foreach node ${dts_nodes} {
			if {[regexp $lu_node $node match]} {
				set node_data [split $node ":"]
				set node_label [lindex $node_data 0]
				set lu_node_data [split $lu_node ":"]
				set lu_node_label [lindex $lu_node_data 0]
				if {![string match -nocase "$node_label" "$lu_node_label"]} {
					continue
				}
				# workaround for -hier not working with -of_objects
				current_dt_tree $dts_file
				set node_obj [get_dt_nodes -hier $node]
				current_dt_tree $cur_dts
				return $node_obj
			}
		}
	}
	if {[string_is_empty $error_out]} {
		return ""
	} else {
		error "Failed to find $lu_node node !!!"
	}
}

proc update_dt_parent args {
	# update device tree node's parent
	# return the node name
	proc_called_by
	global def_string
	set node [lindex $args 0]
	set new_parent [lindex $args 1]
	if {[llength $args] >= 3} {
		set dts_file [lindex $args 2]
	} else {
		set dts_file [current_dt_tree]
	}
	set node [get_node_object $node $dts_file]
	# Skip if node is a reference node (start with &) or amba
	if {[regexp "^&.*" "$node" match] || [regexp "apu-bus" "$node" match] || [regexp "rpu-bus" "node" match] || [regexp "axi" "$node" match]} {
		return $node
	}

	if {[string_is_empty $new_parent] || \
		[string equal ${def_string} "$new_parent"]} {
		return $node
	}

	# Currently the PARENT node must within the same dt tree
	if {![check_node_in_dts $new_parent $dts_file]} {
		error "Node '$node' is not in $dts_file tree"
	}

	set cur_parent [hsi get_property PARENT $node]
	# set new parent if required
	if {![string equal -nocase ${cur_parent} ${new_parent}] && [string_is_empty ${new_parent}] == 0} {
		dtg_debug "Update parent to $new_parent"
		set_property PARENT "${new_parent}" $node
	}
	return $node
}

proc get_all_dt_labels {{dts_files ""}} {
	# get all dt node labels
	set cur_dts [current_dt_tree]
	set labels ""
	if [string_is_empty $dts_files] {
		set dts_files [get_dt_trees]
	}
	foreach dts_file ${dts_files} {
		set dts_nodes [get_all_tree_nodes $dts_file]
		foreach node ${dts_nodes} {
			set node_label [hsi get_property "NODE_LABEL" $node]
			if {[string_is_empty $node_label]} {
				continue
			}
			lappend labels $node_label
		}
	}
	current_dt_tree $cur_dts
	return $labels
}

proc list_remove_element {cur_list elements} {
	foreach e ${elements} {
		set rm_idx [lsearch $cur_list $e]
		set cur_list [lreplace $cur_list $rm_idx $rm_idx]
	}
	return $cur_list
}

proc update_system_dts_include {include_file} {
	# where should we get master_dts data
	global count
	set master_dts "system-top.dts"
	set proctype [get_hw_family]
	if {[regexp "microblaze" $proctype match]} {
		global env
		set path $env(CUSTOM_SDT_REPO)
		#set drvname [get_drivers $drv_handle]
		#set common_file "$path/device_tree/data/config.yaml"
		set common_file [file join [file dirname [dict get [info frame 0] file]] "config.yaml"]
		set board_dts [get_user_config $common_file -board_dts]
		set dtsi_file " "
		set dtsi_file $board_dts
	}

	global include_list
	set cur_inc_list $include_list
	set tmp_list [split $cur_inc_list ","]
	if { [lsearch $tmp_list $include_file] < 0} {
		if {[string_is_empty $cur_inc_list]} {
			
			append cur_inc_list $include_file
		} else {
			if {[regexp "microblaze" $proctype match]} {
				append cur_inc_list "," $include_file
				set field [split $cur_inc_list ","]
				if {[regexp $dtsi_file $include_file match]} {
				} else {
					set cur_inc_list [lsort -decreasing $field]
					set cur_inc_list [join $cur_inc_list ","]
				}
			} else {
				set count [expr $count  + 1]
				append cur_inc_list "," $include_file
				set field [split $cur_inc_list ","]
				set cur_inc_list [lsort -decreasing $field]
				set cur_inc_list [join $cur_inc_list ","]
			}
		}
	}
	set include_list $cur_inc_list
}

proc get_dts_include {} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set family [get_hw_family]
	set common_file "$path/device_tree/data/config.yaml" 
        set dir [get_user_config $common_file -output_dir]
        if {[string match -nocase $family "versal"] || [string match -nocase $family "zynq"] || [is_zynqmp_platform $family]} {
		return [file normalize "$path/device_tree/data/kernel_dtsi/${release}/${dtsi_fname}"]
	} else {
		return "$dir/pl.dtsi"
	}
}

proc set_drv_def_dts {drv_handle} {
	proc_called_by
	global env
	#set path $env(CUSTOM_SDT_REPO)

	#set drvname [get_drivers $drv_handle]
	#set common_file "$path/device_tree/data/config.yaml"
	set common_file [file join [file dirname [dict get [info frame 0] file]] "config.yaml"]
	set family [get_hw_family]
	global bus_clk_list
	set pl_ip [is_pl_ip $drv_handle]
	if {$pl_ip || [regexp -nocase "microblaze" $family match]} {
		set default_dts "pl.dtsi"
		update_system_dts_include $default_dts
	} else {
		# PS IP, read pcw_dts property
		set default_dts "pcw.dtsi"
		update_system_dts_include $default_dts
	}

	return $default_dts
}

proc return_tree_obj {drv_handle} {
	set dts_file [set_drv_def_dts $drv_handle]
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
	}
	return $treeobj
}

proc dt_node_def_checking {node_label node_name node_ua node_obj} {
	# check if the node_object has matching label, name and unit_address properties
	global def_string
	if {[string equal -nocase $node_label $def_string]} {
		set node_label ""
	}
	if {[string equal -nocase $node_ua $def_string]} {
		set node_ua ""
	}
	if {[string match -nocase "data_source" $node_label]} {
		return 1
	}
	# ignore reference node as it does not have label and unit_addr
	if {![regexp "^&.*" "$node_obj" match]} {
		set old_label [hsi get_property "NODE_LABEL" $node_obj]
		set old_name [hsi get_property "NODE_NAME" $node_obj]
		set old_ua [hsi get_property "UNIT_ADDRESS" $node_obj]
		set config_prop [hsi list_property -regexp $node_obj "CONFIG.*"]
		if {[string_is_empty $old_ua]} {
			return 1
		}
		if {![string equal -nocase -length [string length $node_label] $node_label $old_label] || \
			![string equal -nocase $node_ua $old_ua] || \
			![string equal -nocase -length [string length $node_name] $node_name $old_name]} {
			if {[string compare -nocase $config_prop ""]} {
				dtg_debug "dt_node_def_checking($node_obj): label: ${node_label} - ${old_label}, name: ${node_name} - ${old_name}, unit addr: ${node_ua} - ${old_ua}"
				return 0
			}
		}
	}
	return 1
}

proc add_or_get_dt_node args {
	# Creates the dt node or the parent node if required
	# return dt node
	proc_called_by
	global def_string
	foreach var {node_name node_label node_unit_addr parent_obj dts_file} {
		set ${var} ${def_string}
	}
	set auto_ref 1
	set auto_ref_parent 0
	set force_create 0
	while {[string match -* [lindex $args 0]]} {
		switch -glob -- [lindex $args 0] {
			-force {set force_create 1}
			-disable_auto_ref {set auto_ref 0}
			-auto_ref_parent {set auto_ref_parent 1}
			-n* {set node_name [Pop args 1]}
			-l* {set node_label [Pop args 1]}
			-u* {set node_unit_addr [Pop args 1]}
			-p* {set parent_obj [Pop args 1]}
			-d* {set dts_file [Pop args 1]}
			--  {Pop args ; break}
			default {
				error "add_or_get_dt_node bad option - [lindex $args 0]"
			}
		}
		Pop args
	}

	# if no dts_file provided
	if {[string equal -nocase ${dts_file} ${def_string}]} {
		set dts_file [current_dt_tree]
	}

	# node_name sanity checking
	if {[string equal -nocase ${node_name} ${def_string}]} {
		error "Node name must be provided..."
	}

	# Generate unique label name to prevent issue caused by static dtsi
	# better way of handling this issue is required
	set label_list [get_all_dt_labels]
	# TODO: This only handle label duplication once. if multiple IP has
	# the same label, it will not work. Better handling required.
	if {[lsearch $label_list $node_label] >= 0} {
		set tmp_node [get_node_object ${node_label}]
		# rename if the node default properties differs
		if {[dt_node_def_checking $node_label $node_name $node_unit_addr $tmp_node] == 0} {
			dtg_warning "label '$node_label' found in existing tree"
		}
	}

	set search_pattern [gen_dt_node_search_pattern -n ${node_name} -l ${node_label} -u ${node_unit_addr}]

	dtg_debug ""
	dtg_debug "node_name: ${node_name}"
	dtg_debug "node_label: ${node_label}"
	dtg_debug "node_unit_addr: ${node_unit_addr}"
	dtg_debug "search_pattern: ${search_pattern}"
	dtg_debug "parent_obj: ${parent_obj}"
	dtg_debug "dts_file: ${dts_file}"

	# save the current working dt_tree first
	set cur_working_dts [current_dt_tree]
	# tree switch the target tree
	set_cur_working_dts ${dts_file}
	set parent_dts_file ${dts_file}

	# Set correct parent object
	#  Check if the parent object in other dt_trees or not. If yes, update
	#  parent node with reference node (&parent_obj).
	#  Check if parent is / and see if it in the target dts file
	#  if not /, then check if parent is created (FIXME: is right???)
	set tmp_dts_list [list_remove_element [get_dt_trees] ${dts_file}]
	set node_in_dts [check_node_in_dts ${parent_obj} ${tmp_dts_list}]
	if {${node_in_dts} ==  1 && \
		 ![string equal ${parent_obj} "/" ]} {
		set parent_obj [get_node_object ${parent_obj} ${tmp_dts_list}]
		set parent_label [hsi get_property "NODE_LABEL" $parent_obj]
		if {[string_is_empty $parent_label]} {
			set parent_label [hsi get_property "NODE_NAME" $parent_obj]
		}
		if {[string_is_empty $parent_label]} {
			error "no parent node name/label"
		}
		if {[regexp "^&.*" "$parent_label" match]} {
			set ref_node "${parent_label}"
		} else {
			set ref_node "&${parent_label}"
		}
		set parent_ref_in_dts [check_node_in_dts "${ref_node}" ${dts_file}]
		if {${parent_ref_in_dts} != 1} {
			if {$auto_ref_parent} {
				set_cur_working_dts ${dts_file}
				set parent_obj [create_dt_node -n "${ref_node}"]
			}
		} else {
			set parent_obj [get_node_object ${ref_node} ${dts_file}]
		}
	}

	# if dt node in the target dts file
	# get the nodes in the current dts file
	set dts_nodes [get_all_tree_nodes $dts_file]
	foreach pattern ${search_pattern} {
		foreach node ${dts_nodes} {
			if {[regexp $pattern $node match]} {
				if {[dt_node_def_checking $node_label $node_name $node_unit_addr $node] == 0} {
					dtg_warning "$pattern :: $node_label : $node_name @ $node_unit_addr, is differ to the node object $node"
				}
				set node [update_dt_parent ${node} ${parent_obj} ${dts_file}]
				set_cur_working_dts ${cur_working_dts}
				return $node
			}
		}
	}
	# clean up required
	# special search pattern for name only node
	set_cur_working_dts ${dts_file}
	foreach pattern "^${node_name}$" {
		foreach node ${dts_nodes} {
			# As there was cpu timer node already in dtsi file skipping to add ttc timer
			# to pcw.dtsi even if ip available. This check will skip that.
			if {[regexp $pattern $node match] && ![string match -nocase ${node_name} "timer"]} {
				set_cur_working_dts ${dts_file}
				set node [update_dt_parent ${node} ${parent_obj} ${dts_file}]
				set_cur_working_dts ${cur_working_dts}
				return $node
			}
		}
	}
	# if dt node in other target dts files
	# create a reference node if required
	set found_node 0
	set tmp_dts_list [list_remove_element [get_dt_trees] ${dts_file}]
	foreach tmp_dts_file ${tmp_dts_list} {
		set dts_nodes [get_all_tree_nodes $tmp_dts_file]
		# TODO: better detection here
		foreach pattern ${search_pattern} {
			foreach node ${dts_nodes} {
				if {[regexp $pattern $node match]} {
					# create reference node
					set found_node 1
					set found_node_obj [get_node_object ${node} $tmp_dts_file]
					break
				}
			}
		}
	}
	if {$found_node == 1 && $force_create == 0} {
		if {$auto_ref == 0} {
			# return the object found on other dts files
			set_cur_working_dts ${cur_working_dts}
			return $found_node_obj
		}
		dtg_debug "INFO: Found node and create it as reference node &${node_label}"
		if {[string equal -nocase ${node_label} ${def_string}]} {
			error "Unable to create reference node as reference label is not provided"
		}

		set node [create_dt_node -n "&${node_label}"]
		set_cur_working_dts ${cur_working_dts}
		return $node
	}

	# Others - create the dt node
	set cmd ""
	if {![string equal -nocase ${node_name} ${def_string}]} {
		set cmd "${cmd} -name ${node_name}"
	}
	if {![string equal -nocase ${node_label} ${def_string}]} {
		set cmd "${cmd} -label ${node_label}"
	}
	if {![string equal -nocase ${node_unit_addr} ${def_string}]} {
		set cmd "${cmd} -unit_addr ${node_unit_addr}"
	}
	if {![string equal -nocase ${parent_obj} ${def_string}] && \
		![string_is_empty ${parent_obj}]} {
		# temp solution for getting the right node object
		set cmd "${cmd} -objects \[get_node_object ${parent_obj} $parent_dts_file\]"
	}

	dtg_debug "create node command: create_dt_node ${cmd}"
	# FIXME: create_dt_node fail detection here
	set node [eval "create_dt_node ${cmd}"]
	set_cur_working_dts ${cur_working_dts}
	return $node
}

# FIXME: Consolidate it with get_ip_type, is_pl_ip, is_ps_ip, check the usecase of nochk list
proc get_pl_ip_list {} {
	global non_val_list
	global pl_ip_list
	set pl_ip_list ""
	set is_pl_ip_list [hsi get_cells -hier -filter IS_PL==1]
	foreach drv_handle $is_pl_ip_list {
		set ip_name [get_ip_property $drv_handle IP_NAME]
		if {[lsearch -nocase $non_val_list $ip_name] < 0} {
			lappend pl_ip_list $drv_handle
		}
	}
}

proc get_ip_type {ip_inst} {
	global ip_type_dict
	global cur_hw_design
	if { [dict exists $ip_type_dict $cur_hw_design $ip_inst] } {
		return [dict get $ip_type_dict $cur_hw_design $ip_inst]
	}
	# check if the IP is a soft IP (not PS7)
	# return 1 if it is soft ip
	# return 0 if not
	set ip_obj [hsi::get_cells -hier $ip_inst]
	if {[llength $ip_obj] < 1} {
		return -1
	}
	set family [get_hw_family]
	set ip_name [get_ip_property $ip_obj IP_NAME]
	set nochk_list "ai_engine noc_mc_ddr4 axi_noc"
	# Set the IP type as PL IP if the design is a pure Microblaze(/RISCV) design.
	if {[lsearch $nochk_list $ip_name] >= 0 || [regexp -nocase "microblaze" $family match]} {
		dict set ip_type_dict $cur_hw_design $ip_inst 1
		return 1
	}

	if {![catch {set prop [hsi get_property IS_PL [hsi::get_cells -hier $ip_inst]]} msg]} {
		dict set ip_type_dict $cur_hw_design $ip_inst $prop
		return $prop
	}

	dict set ip_type_dict $cur_hw_design $ip_inst 0
	return 0

}
proc is_pl_ip {ip_inst} {
	set type [get_ip_type $ip_inst]
	if {$type == -1} {return 0}
	return $type
}

proc is_ps_ip {ip_inst} {
	set type [get_ip_type $ip_inst]
	if {$type == -1} {return 0}
	return [expr !$type]
}

proc get_node_name {drv_handle} {
	global node_dict
	global cur_hw_design

	if { [dict exists $node_dict $cur_hw_design $drv_handle] } {
		return [dict get $node_dict $cur_hw_design $drv_handle]
	}
	# FIXME: handle node that is not an ip
	# what about it is a bus node
	set ip [hsi::get_cells -hier $drv_handle]
	# node that is not a ip
	if {[string_is_empty $ip]} {
		error "$drv_handle is not a valid IP"
	}
	#set unit_addr [get_baseaddr ${ip}]
	set dev_type [hsi get_property CONFIG.dev_type $drv_handle]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type $drv_handle
	}
	set dt_node [add_or_get_dt_node -n ${dev_type} -l ${drv_handle} -u ${unit_addr}]
	dict set $nodename_dict $cur_hw_design $drv_handle $dt_node
	return $dt_node
}

proc get_driver_conf_list {drv_handle} {
	# Assuming the driver property starts with CONFIG.<xyz>
	# Returns all the property name that should be add to the node
	set dts_conf_list ""
	# handle no CONFIG parameter
	if {[catch {set rt [report_property -return_string -regexp $drv_handle "CONFIG\\..*"]} msg]} {
		return ""
	}
	foreach line [split $rt "\n"] {
		regsub -all {\s+} $line { } line
		if {[regexp "CONFIG\\..*\\.dts(i|)" $line matched]} {
			continue
		}
		if {[regexp "CONFIG\\..*" $line matched]} {
			lappend dts_conf_list [lindex [split $line " "] 0]
		}
	}
	# Remove config based properties
	# currently it is not possible to different by type: Pending on HSI implementation
	# this is currently hard coded to remove CONFIG.def_dts CONFIG.dev_type CONFIG.dtg.alias CONFIG.dtg.ip_params
	set dts_conf_list [list_remove_element $dts_conf_list "CONFIG.def_dts CONFIG.dev_type CONFIG.dtg.alias CONFIG.dtg.ip_params"]
	return $dts_conf_list
}

proc add_driver_prop {drv_handle dt_node prop} {
	# driver property to DT node
	proc_called_by
	set value [hsi get_property $prop [hsi::get_cells -hier $drv_handle]]
	if {[string_is_empty ${prop}] != 0} {
		return -1
	}

	set type [get_type $drv_handle $prop]
	if {$type == ""} {
		set type boolean
	}
	set ipval $prop
	regsub -all {CONFIG.} $prop {xlnx,} prop
	set prop [string tolower $prop]
	dtg_debug "${dt_node} - ${prop} - ${value} - ${type}"
	set ipname [get_ip_property $drv_handle IP_NAME]
       	if {[string match -nocase $ipname "axi_mcdma"] && [string match -nocase $prop "xlnx,sg-include-stscntrl-strm"] && [string match -nocase $type "boolean"]} {
               set type "hexint"
       	}
	# only boolean allows empty string
	if {[string_is_empty ${value}] == 1 && ![regexp {boolean*} ${type} matched]} {
		dtg_warning "Only boolean type can have empty value. Fail to add driver($drv_handle) property($prop) type($type) value($value)"
		dtg_warning "Please add the property manually"
		return 1
	}
	# TODO: sanity check is missing
	set ipname [get_ip_property $drv_handle IP_NAME]

	if {[string match -nocase $ipname "axi_dma"]} {
		if {[string match -nocase $prop "xlnx,include-sg"] && [string match -nocase $value "0"]} {
			return
		}
	}
	# This is to avoid boolean type error for axi_dma include-sg paramter
	if {[string match -nocase $type "boolean"] && [string_is_empty ${value}] != 1} {
		set value ""
	}
	if {[string match -nocase "PROCESSOR" [get_ip_property $drv_handle IP_TYPE]]} {
		add_prop $dt_node $prop $value $type [set_drv_def_dts $drv_handle] 1
	} else {
	set node [get_node $drv_handle ]
	if {[string match -nocase $prop "c_tdest_val"]} {
		set value [string trimright $value "\""]
		set value [string trimleft $value "\""]
	}

	if {[regexp -nocase {0x([0-9a-f])} $value match]} {
		set type "hexint"
	} elseif {[string is integer -strict $value]} {
		set type "int"
	} elseif {[string is boolean -strict $value] || [string match -nocase $type ""]} {
		set type "boolean"
	} elseif {[string is wordchar -strict $value]} {
		set type "string"
	} else {
		set type "mixed"
	}
	add_prop $node $prop $value $type [set_drv_def_dts $drv_handle]
	}
}

proc gen_ps_mapping {} {
	global is_versal_net_platform
	global is_versal_2ve_2vm_platform
	global is_versal_2vp_platform
	set family [get_hw_family]
	set def_ps_mapping [dict create]
	if {[string match -nocase $family "versal"]} {
		if { $is_versal_net_platform } {
			if { $is_versal_2ve_2vm_platform } {
				dict set def_ps_mapping eb330000 label ipi0
				dict set def_ps_mapping eb340000 label ipi1
				dict set def_ps_mapping eb350000 label ipi2
				dict set def_ps_mapping eb360000 label ipi3
				dict set def_ps_mapping eb370000 label ipi4
				dict set def_ps_mapping eb380000 label ipi5
				dict set def_ps_mapping eb3a0000 label ipi6
				dict set def_ps_mapping eb3b0000 label ipi_nobuf1
				dict set def_ps_mapping eb3b1000 label ipi_nobuf2
				dict set def_ps_mapping eb3b2000 label ipi_nobuf3
				dict set def_ps_mapping eb3b3000 label ipi_nobuf4
				dict set def_ps_mapping eb3b4000 label ipi_nobuf5
				dict set def_ps_mapping eb3b5000 label ipi_nobuf6
				dict set def_ps_mapping eb310000 label ipi_asu
				dict set def_ps_mapping eb320000 label ipi_pmc
				dict set def_ps_mapping eb390000 label ipi_pmc_nobuf
				dict set def_ps_mapping e2000000 label gic_a78
				dict set def_ps_mapping eb9a0000 label gic_r52

				dict set def_ps_mapping eba00000 label r52_0a_atcm_global
				dict set def_ps_mapping eba10000 label r52_0a_btcm_global
				dict set def_ps_mapping eba20000 label r52_0a_ctcm_global
				dict set def_ps_mapping eba80000 label r52_0b_atcm_global
				dict set def_ps_mapping eba90000 label r52_0b_btcm_global
				dict set def_ps_mapping ebaa0000 label r52_0b_ctcm_global
				dict set def_ps_mapping ebb00000 label r52_0c_atcm_global
				dict set def_ps_mapping ebb10000 label r52_0c_btcm_global
				dict set def_ps_mapping ebb20000 label r52_0c_ctcm_global
				dict set def_ps_mapping ebb80000 label r52_0d_atcm_global
				dict set def_ps_mapping ebb90000 label r52_0d_btcm_global
				dict set def_ps_mapping ebba0000 label r52_0d_ctcm_global
				dict set def_ps_mapping ebc00000 label r52_0e_atcm_global
				dict set def_ps_mapping ebc10000 label r52_0e_btcm_global
				dict set def_ps_mapping ebc20000 label r52_0e_ctcm_global

				dict set def_ps_mapping eba40000 label r52_1a_atcm_global
				dict set def_ps_mapping eba50000 label r52_1a_btcm_global
				dict set def_ps_mapping eba60000 label r52_1a_ctcm_global
				dict set def_ps_mapping ebac0000 label r52_1b_atcm_global
				dict set def_ps_mapping ebad0000 label r52_1b_btcm_global
				dict set def_ps_mapping ebae0000 label r52_1b_ctcm_global
				dict set def_ps_mapping ebb40000 label r52_1c_atcm_global
				dict set def_ps_mapping ebb50000 label r52_1c_btcm_global
				dict set def_ps_mapping ebb60000 label r52_1c_ctcm_global
				dict set def_ps_mapping ebbc0000 label r52_1d_atcm_global
				dict set def_ps_mapping ebbd0000 label r52_1d_btcm_global
				dict set def_ps_mapping ebbe0000 label r52_1d_ctcm_global
				dict set def_ps_mapping ebc40000 label r52_1e_atcm_global
				dict set def_ps_mapping ebc50000 label r52_1e_btcm_global
				dict set def_ps_mapping ebc60000 label r52_1e_ctcm_global

				dict set def_ps_mapping ebd00000 label adma0
				dict set def_ps_mapping ebd10000 label adma1
				dict set def_ps_mapping ebd20000 label adma2
				dict set def_ps_mapping ebd30000 label adma3
				dict set def_ps_mapping ebd40000 label adma4
				dict set def_ps_mapping ebd50000 label adma5
				dict set def_ps_mapping ebd60000 label adma6
				dict set def_ps_mapping ebd70000 label adma7
				dict set def_ps_mapping ed931000 label "mdb_pcie0: pcie"
				dict set def_ps_mapping ed939000 label "mdb_pcie1: pcie"
				dict set def_ps_mapping f19e0000 label can0
				dict set def_ps_mapping f19f0000 label can1
				dict set def_ps_mapping f1a00000 label can2
				dict set def_ps_mapping f1a10000 label can3
				dict set def_ps_mapping f1a90000 label can4
				dict set def_ps_mapping f1aa0000 label can5
				dict set def_ps_mapping f11c0000 label dma0
				dict set def_ps_mapping f11d0000 label dma1
				dict set def_ps_mapping ebe8c000 label asu_dma0
				dict set def_ps_mapping ebe8d000 label asu_dma1
				dict set def_ps_mapping f1a60000 label gem0
				dict set def_ps_mapping f1a70000 label gem1
				dict set def_ps_mapping ed920000 label mmi_10gbe
				dict set def_ps_mapping f1a50000 label gpio0
				dict set def_ps_mapping f1020000 label gpio1
				dict set def_ps_mapping f1940000 label i2c0
				dict set def_ps_mapping f1948000 label i3c0
				dict set def_ps_mapping f1950000 label i2c1
				dict set def_ps_mapping f1958000 label i3c1
				dict set def_ps_mapping f1960000 label i2c2
				dict set def_ps_mapping f1968000 label i3c2
				dict set def_ps_mapping f1970000 label i2c3
				dict set def_ps_mapping f1978000 label i3c3
				dict set def_ps_mapping f1980000 label i2c4
				dict set def_ps_mapping f1988000 label i3c4
				dict set def_ps_mapping f1990000 label i2c5
				dict set def_ps_mapping f1998000 label i3c5
				dict set def_ps_mapping f19a0000 label i2c6
				dict set def_ps_mapping f19a8000 label i3c6
				dict set def_ps_mapping f19b0000 label i2c7
				dict set def_ps_mapping f19b8000 label i3c7
				dict set def_ps_mapping f1000000 label i2c8
				dict set def_ps_mapping f1008000 label i3c8
				dict set def_ps_mapping f0300000 label iomodule0
				dict set def_ps_mapping ebe80000 label asu_iomodule0
				dict set def_ps_mapping f1010000 label ospi
				dict set def_ps_mapping f1030000 label qspi
				dict set def_ps_mapping f12a0000 label rtc
				dict set def_ps_mapping f1040000 label sdhci0
				dict set def_ps_mapping f1050000 label sdhci1
				dict set def_ps_mapping f1920000 label serial0
				dict set def_ps_mapping f1930000 label serial1
				dict set def_ps_mapping f1270000 label sysmon0
				dict set def_ps_mapping ec000000 label smmu
				dict set def_ps_mapping f19c0000 label spi0
				dict set def_ps_mapping f19d0000 label spi1
				dict set def_ps_mapping f1e60000 label ttc0
				dict set def_ps_mapping f1e70000 label ttc1
				dict set def_ps_mapping f1e80000 label ttc2
				dict set def_ps_mapping f1e90000 label ttc3
				dict set def_ps_mapping f1ea0000 label ttc4
				dict set def_ps_mapping f1eb0000 label ttc5
				dict set def_ps_mapping f1ec0000 label ttc6
				dict set def_ps_mapping f1ed0000 label ttc7
				dict set def_ps_mapping f10b0000 label ufshc
				dict set def_ps_mapping f1ee0000 label usb0
				dict set def_ps_mapping f1ef0000 label usb1
				dict set def_ps_mapping ecc10000 label wwdt0
				dict set def_ps_mapping ecd10000 label wwdt1
				dict set def_ps_mapping ece10000 label wwdt2
				dict set def_ps_mapping ecf10000 label wwdt3
				dict set def_ps_mapping eb000000 label lpd_wwdt0
				dict set def_ps_mapping eb010000 label lpd_wwdt1
				dict set def_ps_mapping eb020000 label lpd_wwdt2
				dict set def_ps_mapping eb030000 label lpd_wwdt3
				dict set def_ps_mapping eb040000 label lpd_wwdt4
				dict set def_ps_mapping f03f0000 label pmc_wwdt
				dict set def_ps_mapping f0800000 label coresight
				dict set def_ps_mapping f1230000 label pmc_trng
				dict set def_ps_mapping f12d0000 label pmc_cfi_cframe_0
				dict set def_ps_mapping f12b0000 label pmc_cfu_apb_0
				dict set def_ps_mapping f0310000 label pmc_ppu1_mdm_0
				dict set def_ps_mapping f1b00000 label dwc3_0
				dict set def_ps_mapping f1c00000 label dwc3_1
				dict set def_ps_mapping edec0000 label mmi_dwc3
				dict set def_ps_mapping ed000000 label gpu
				dict set def_ps_mapping edd00000 label mmi_dc
				dict set def_ps_mapping ede00000 label mmi_dptx
			} else {
				dict set def_ps_mapping eb330000 label ipi0
				dict set def_ps_mapping eb340000 label ipi1
				dict set def_ps_mapping eb350000 label ipi2
				dict set def_ps_mapping eb360000 label ipi3
				dict set def_ps_mapping eb370000 label ipi4
				dict set def_ps_mapping eb380000 label ipi5
				dict set def_ps_mapping eb3a0000 label ipi6
				dict set def_ps_mapping eb3b0000 label ipi_nobuf1
				dict set def_ps_mapping eb3b1000 label ipi_nobuf2
				dict set def_ps_mapping eb3b2000 label ipi_nobuf3
				dict set def_ps_mapping eb3b3000 label ipi_nobuf4
				dict set def_ps_mapping eb3b4000 label ipi_nobuf5
				dict set def_ps_mapping eb3b5000 label ipi_nobuf6
				dict set def_ps_mapping eb310000 label ipi_psm
				dict set def_ps_mapping eb320000 label ipi_pmc
				dict set def_ps_mapping eb390000 label ipi_pmc_nobuf
				dict set def_ps_mapping e2000000 label gic_a78
				dict set def_ps_mapping eb9a0000 label gic_r52
				dict set def_ps_mapping ebd00000 label adma0
				dict set def_ps_mapping ebd10000 label adma1
				dict set def_ps_mapping ebd20000 label adma2
				dict set def_ps_mapping ebd30000 label adma3
				dict set def_ps_mapping ebd40000 label adma4
				dict set def_ps_mapping ebd50000 label adma5
				dict set def_ps_mapping ebd60000 label adma6
				dict set def_ps_mapping ebd70000 label adma7
				dict set def_ps_mapping f1980000 label can0
				dict set def_ps_mapping f1990000 label can1
				dict set def_ps_mapping f11c0000 label dma0
				dict set def_ps_mapping f11d0000 label dma1
				dict set def_ps_mapping f19e0000 label gem0
				dict set def_ps_mapping f19f0000 label gem1
				dict set def_ps_mapping f19d0000 label gpio0
				dict set def_ps_mapping f1020000 label gpio1
				dict set def_ps_mapping f1940000 label i2c0
				dict set def_ps_mapping f1950000 label i2c1
				dict set def_ps_mapping f1948000 label i3c0
				dict set def_ps_mapping f1958000 label i3c1
				dict set def_ps_mapping f0300000 label iomodule0
				dict set def_ps_mapping f1010000 label ospi
				dict set def_ps_mapping f1030000 label qspi
				dict set def_ps_mapping f12a0000 label rtc
				dict set def_ps_mapping f1040000 label sdhci0
				dict set def_ps_mapping f1050000 label sdhci1
				dict set def_ps_mapping f1920000 label serial0
				dict set def_ps_mapping f1930000 label serial1
				dict set def_ps_mapping f1270000 label sysmon0
				dict set def_ps_mapping ec000000 label smmu
				dict set def_ps_mapping f1960000 label spi0
				dict set def_ps_mapping f1970000 label spi1
				dict set def_ps_mapping f1dc0000 label ttc0
				dict set def_ps_mapping f1dd0000 label ttc1
				dict set def_ps_mapping f1de0000 label ttc2
				dict set def_ps_mapping f1df0000 label ttc3
				dict set def_ps_mapping f1e00000 label usb0
				dict set def_ps_mapping f1e10000 label usb1
				dict set def_ps_mapping f1b00000 label dwc3_0
				dict set def_ps_mapping f1c00000 label dwc3_1
				dict set def_ps_mapping ecc10000 label wwdt0
				dict set def_ps_mapping ecd10000 label wwdt1
				dict set def_ps_mapping ece10000 label wwdt2
				dict set def_ps_mapping ecf10000 label wwdt3
				dict set def_ps_mapping ea420000 label lpd_wwdt0
				dict set def_ps_mapping ea430000 label lpd_wwdt1
				dict set def_ps_mapping f03f0000 label pmc_wwdt
				dict set def_ps_mapping f0800000 label coresight
				dict set def_ps_mapping f1230000 label pmc_trng
				dict set def_ps_mapping f12d0000 label pmc_cfi_cframe_0
				dict set def_ps_mapping f12b0000 label pmc_cfu_apb_0
				dict set def_ps_mapping f0310000 label pmc_ppu1_mdm_0
			}
		} else {
			dict set def_ps_mapping f9000000 label "gic_a72: interrupt-controller"
			dict set def_ps_mapping f9001000 label "gic_r5: interrupt-controller"
			dict set def_ps_mapping fd4b0000 label gpu
			dict set def_ps_mapping ffa80000 label "lpd_dma_chan0: dma"
			dict set def_ps_mapping ffa90000 label "lpd_dma_chan1: dma"
			dict set def_ps_mapping ffaa0000 label "lpd_dma_chan2: dma"
			dict set def_ps_mapping ffab0000 label "lpd_dma_chan3: dma"
			dict set def_ps_mapping ffac0000 label "lpd_dma_chan4: dma"
			dict set def_ps_mapping ffad0000 label "lpd_dma_chan5: dma"
			dict set def_ps_mapping ffae0000 label "lpd_dma_chan6: dma"
			dict set def_ps_mapping ffaf0000 label "lpd_dma_chan7: dma"
			dict set def_ps_mapping ff0c0000 label "gem0: ethernet"
			dict set def_ps_mapping ff0d0000 label "gem1: ethernet"
			dict set def_ps_mapping ff0b0000 label "gpio0: gpio"
			dict set def_ps_mapping f1020000 label "gpio1: gpio"
			dict set def_ps_mapping ff020000 label "i2c0: i2c"
			dict set def_ps_mapping ff030000 label "i2c1: i2c"
			dict set def_ps_mapping f1000000 label "i2c2: i2c"
			dict set def_ps_mapping f1030000 label "qspi: spi"
			dict set def_ps_mapping f12a0000 label "rtc: rtc"
			dict set def_ps_mapping fd0c0000 label "sata: sata"
			dict set def_ps_mapping f1040000 label "sdhci0: sdhci"
			dict set def_ps_mapping f1050000 label "sdhci1: sdhci"
			dict set def_ps_mapping fd800000 label "smmu: smmu"
			dict set def_ps_mapping ff040000 label "spi0: spi"
			dict set def_ps_mapping ff050000 label "spi1: spi"
			dict set def_ps_mapping f1010000 label "ospi: spi"
			dict set def_ps_mapping ff000000 label "serial0: serial"
			dict set def_ps_mapping ff010000 label "serial1: serial"
			dict set def_ps_mapping fd4d0000 label "watchdog: watchdog"
			dict set def_ps_mapping ff120000 label "watchdog1: watchdog"
			dict set def_ps_mapping fca10000 label "cpm_pciea: pci"
			dict set def_ps_mapping fcdd0000 label "cpm5_pcie: pci"
			dict set def_ps_mapping e4a10000 label "cpm5nc: pci"
			dict set def_ps_mapping ff060000 label "can0: can"
			dict set def_ps_mapping ff070000 label "can1: can"
			dict set def_ps_mapping ff330000 label "ipi0: mailbox"
			dict set def_ps_mapping ff340000 label "ipi1: mailbox"
			dict set def_ps_mapping ff350000 label "ipi2: mailbox"
			dict set def_ps_mapping ff360000 label "ipi3: mailbox"
			dict set def_ps_mapping ff370000 label "ipi4: mailbox"
			dict set def_ps_mapping ff380000 label "ipi5: mailbox"
			dict set def_ps_mapping ff3a0000 label "ipi6: mailbox"
			dict set def_ps_mapping ff320000 label "ipi_pmc: mailbox"
			dict set def_ps_mapping ff390000 label "ipi_pmc_nobuf: mailbox"
			dict set def_ps_mapping ff310000 label "ipi_psm: mailbox"
			dict set def_ps_mapping ff0e0000 label "ttc0: timer"
			dict set def_ps_mapping ff0f0000 label "ttc1: timer"
			dict set def_ps_mapping ff100000 label "ttc2: timer"
			dict set def_ps_mapping ff110000 label "ttc3: timer"
			if {$is_versal_2vp_platform} {
				dict set def_ps_mapping f0300000 label "iomodule0: iomodule"
			} else {
				dict set def_ps_mapping f0280000 label "iomodule0: iomodule"
			}
			dict set def_ps_mapping ff9d0000 label "usb0: usb"
			dict set def_ps_mapping fe200000 label "dwc3_0: dwc3"
			dict set def_ps_mapping f0800000 label "coresight: coresight"
			dict set def_ps_mapping f11c0000 label "dma0: pmcdma"
			dict set def_ps_mapping f11d0000 label "dma1: pmcdma"
			dict set def_ps_mapping f0920000 label "apm: performance-monitor"
			dict set def_ps_mapping f1270000 label "sysmon0: sysmon"
			dict set def_ps_mapping 109270000 label "sysmon1: sysmon"
			dict set def_ps_mapping 111270000 label "sysmon2: sysmon"
			dict set def_ps_mapping 119270000 label "sysmon3: sysmon"
			dict set def_ps_mapping ff990000 label "lpd_xppu: xppu"
			dict set def_ps_mapping f1310000 label "pmc_xppu: xppu"
			dict set def_ps_mapping f1300000 label "pmc_xppu_npi: xppu"
			dict set def_ps_mapping fd390000 label "fpd_xmpu: xmpu"
			dict set def_ps_mapping f12f0000 label "pmc_xmpu: xmpu"
			dict set def_ps_mapping ff980000 label "ocm_xmpu: xmpu"
			dict set def_ps_mapping f6080000 label "ddrmc_xmpu_0: xmpu"
			dict set def_ps_mapping f6220000 label "ddrmc_xmpu_1: xmpu"
			dict set def_ps_mapping f6390000 label "ddrmc_xmpu_2: xmpu"
			dict set def_ps_mapping f6400000 label "ddrmc_xmpu_3: xmpu"
			dict set def_ps_mapping ffe00000 label psv_r5_0_atcm_global
			dict set def_ps_mapping ffe20000 label psv_r5_0_btcm_global
			dict set def_ps_mapping ffe90000 label psv_r5_1_atcm_global
			dict set def_ps_mapping ffeb0000 label psv_r5_1_btcm_global
			dict set def_ps_mapping fd000000 label cci
			dict set def_ps_mapping f1230000 label pmc_trng
			dict set def_ps_mapping f12d0000 label pmc_cfi_cframe_0
			dict set def_ps_mapping f12b0000 label pmc_cfu_apb_0
			dict set def_ps_mapping f0310000 label pmc_ppu1_mdm_0
		}
	} elseif {[is_zynqmp_platform $family]} {
		dict set def_ps_mapping f9010000 label "gic_a53: interrupt-controller"
		dict set def_ps_mapping f9000000 label "gic_r5: interrupt-controller"
		dict set def_ps_mapping ff060000 label "can0: can"
		dict set def_ps_mapping ff070000 label "can1: can"
		dict set def_ps_mapping fd500000 label "fpd_dma_chan1: dma"
		dict set def_ps_mapping fd510000 label "fpd_dma_chan2: dma"
		dict set def_ps_mapping fd520000 label "fpd_dma_chan3: dma"
		dict set def_ps_mapping fd530000 label "fpd_dma_chan4: dma"
		dict set def_ps_mapping fd540000 label "fpd_dma_chan5: dma"
		dict set def_ps_mapping fd550000 label "fpd_dma_chan6: dma"
		dict set def_ps_mapping fd560000 label "fpd_dma_chan7: dma"
		dict set def_ps_mapping fd570000 label "fpd_dma_chan8: dma"
		dict set def_ps_mapping fd4b0000 label "gpu: gpu"
		dict set def_ps_mapping ffa80000 label "lpd_dma_chan1: dma"
		dict set def_ps_mapping ffa90000 label "lpd_dma_chan2: dma"
		dict set def_ps_mapping ffaa0000 label "lpd_dma_chan3: dma"
		dict set def_ps_mapping ffab0000 label "lpd_dma_chan4: dma"
		dict set def_ps_mapping ffac0000 label "lpd_dma_chan5: dma"
		dict set def_ps_mapping ffad0000 label "lpd_dma_chan6: dma"
		dict set def_ps_mapping ffae0000 label "lpd_dma_chan7: dma"
		dict set def_ps_mapping ffaf0000 label "lpd_dma_chan8: dma"
		dict set def_ps_mapping ff100000 label "nand0: nand-controller"
		dict set def_ps_mapping ff0b0000 label "gem0: ethernet"
		dict set def_ps_mapping ff0c0000 label "gem1: ethernet"
		dict set def_ps_mapping ff0d0000 label "gem2: ethernet"
		dict set def_ps_mapping ff0e0000 label "gem3: ethernet"
		dict set def_ps_mapping ff0a0000 label "gpio: gpio"
		dict set def_ps_mapping ff020000 label "i2c0: i2c"
		dict set def_ps_mapping ff030000 label "i2c1: i2c"
		dict set def_ps_mapping ff0f0000 label "qspi: spi"
		dict set def_ps_mapping ffa60000 label "rtc: rtc"
		dict set def_ps_mapping fd0c0000 label "sata: ahci"
		dict set def_ps_mapping ff160000 label "sdhci0: mmc"
		dict set def_ps_mapping ff170000 label "sdhci1: mmc"
		dict set def_ps_mapping fd800000 label "smmu: smmu"
		dict set def_ps_mapping ff040000 label "spi0: spi"
		dict set def_ps_mapping ff050000 label "spi1: spi"
		dict set def_ps_mapping ff110000 label "ttc0: ttc"
		dict set def_ps_mapping ff120000 label "ttc1: ttc"
		dict set def_ps_mapping ff130000 label "ttc2: ttc"
		dict set def_ps_mapping ff140000 label "ttc3: ttc"
		dict set def_ps_mapping ff000000 label "uart0: serial"
		dict set def_ps_mapping ff010000 label "uart1: serial"
		dict set def_ps_mapping fe200000 label "dwc3_0: dwc3"
		dict set def_ps_mapping fe300000 label "dwc3_1: dwc3"
		dict set def_ps_mapping ff9e0000 label "usb1: usb"
		dict set def_ps_mapping ff9d0000 label "usb0: usb"
		dict set def_ps_mapping ff150000 label "lpd_watchdog: watchdog"
		dict set def_ps_mapping fd4d0000 label "watchdog0: watchdog"
		dict set def_ps_mapping 43c00000 label dp
		dict set def_ps_mapping 43c0a000 label dpsub
		dict set def_ps_mapping fd4c0000 label "zynqmp_dpdma: dma-controller"
		dict set def_ps_mapping fd4a0000 label "zynqmp_dpsub: display"
		dict set def_ps_mapping fd0e0000 label "pcie: pcie"
		dict set def_ps_mapping ff300000 label "ipi0: ipi"
		dict set def_ps_mapping ff310000 label "ipi1: ipi"
		dict set def_ps_mapping ff320000 label "ipi2: ipi"
		dict set def_ps_mapping ff330000 label "ipi3: ipi"
		dict set def_ps_mapping ff331000 label "ipi4: ipi"
		dict set def_ps_mapping ff332000 label "ipi5: ipi"
		dict set def_ps_mapping ff333000 label "ipi6: ipi"
		dict set def_ps_mapping ff340000 label "ipi7: ipi"
		dict set def_ps_mapping ff350000 label "ipi8: ipi"
		dict set def_ps_mapping ff360000 label "ipi9: ipi"
		dict set def_ps_mapping ff370000 label "ipi10: ipi"
		dict set def_ps_mapping ffcb0000 label "csuwdt_0: watchdog"
		dict set def_ps_mapping fd070000 label "mc: memory-controller"
		dict set def_ps_mapping fe800000 label "coresight_0: coresight"
		dict set def_ps_mapping ff960000 label "ocm: memory-controller"
		dict set def_ps_mapping ffa00000 label "perf_monitor_ocm: perf-monitor"
		dict set def_ps_mapping fd0b0000 label "perf_monitor_ddr: perf-monitor"
		dict set def_ps_mapping fd490000 label "perf_monitor_cci: perf-monitor"
		dict set def_ps_mapping ffa10000 label "perf_monitor_lpd: perf-monitor"
		dict set def_ps_mapping ffc80000 label "csudma_0: dma"
		dict set def_ps_mapping fd400000 label "psgtr: zynqmp_phy"
		dict set def_ps_mapping ffa50000 label "xilinx_ams: ams"
		dict set def_ps_mapping ffa50800 label "ams_ps: ams_ps"
		dict set def_ps_mapping ffa50c00 label "ams_pl: ams_pl"
		dict set def_ps_mapping ff980000 label "lpd_xppu: xppu"
	} else {
		#dict set def_ps_mapping f8891000 label pmu
		dict set def_ps_mapping f8007100 label adc
		dict set def_ps_mapping e0008000 label can0
		dict set def_ps_mapping e0009000 label can1
		dict set def_ps_mapping e000a000 label gpio0
		dict set def_ps_mapping e0004000 label i2c0
		dict set def_ps_mapping e0005000 label i2c1
		dict set def_ps_mapping f8f01000 label intc
		dict set def_ps_mapping f8f00100 label intc
		dict set def_ps_mapping f8f02000 label L2
		dict set def_ps_mapping f8006000 label mc
		#dict set def_ps_mapping f800c000 label ocmc
		dict set def_ps_mapping e0000000 label uart0
		dict set def_ps_mapping e0001000 label uart1
		dict set def_ps_mapping e0006000 label spi0
		dict set def_ps_mapping e0007000 label spi1
		dict set def_ps_mapping e000d000 label qspi
		dict set def_ps_mapping e000e000 label smcc
		dict set def_ps_mapping e1000000 label nfc0
		dict set def_ps_mapping e2000000 label nor0
		dict set def_ps_mapping e000b000 label gem0
		dict set def_ps_mapping e000c000 label gem1
		dict set def_ps_mapping e0100000 label sdhci0
		dict set def_ps_mapping e0101000 label sdhci1
		dict set def_ps_mapping f8000000 label slcr
		dict set def_ps_mapping f8003000 label dmac_s
		dict set def_ps_mapping f8007000 label devcfg
		dict set def_ps_mapping f8f00200 label global_timer
		dict set def_ps_mapping f8001000 label ttc0
		dict set def_ps_mapping f8002000 label ttc1
		dict set def_ps_mapping f8f00600 label scutimer
		dict set def_ps_mapping f8005000 label watchdog0
		dict set def_ps_mapping f8f00620 label scuwdt
		dict set def_ps_mapping e0002000 label usb0
		dict set def_ps_mapping e0003000 label usb1
		dict set def_ps_mapping f8800000 label coresight
	}
	return [part_specific_ps_mapping $def_ps_mapping]
}

proc gen_ps7_mapping {} {
	# TODO: check if it is target cpu is cortex a9

	# TODO: remove def_ps7_mapping
	proc_called_by
	set proctype "versal"
	set def_ps_mapping [dict create]
	if {[string match -nocase $proctype "psv_cortexa72"] ||
	    [string match -nocase $proctype "psv_cortexr5"] ||
	    [string match -nocase $proctype "versal"] ||
	    [string match -nocase $proctype "psv_pmc"]} {
		dict set def_ps_mapping f9000000 label "gic: interrupt-controller"
		dict set def_ps_mapping f9001000 label "rpu_gic: interrupt-controller"
		dict set def_ps_mapping fd4b0000 label gpu
		dict set def_ps_mapping ffa80000 label "lpd_dma_chan0: dma"
		dict set def_ps_mapping ffa90000 label "lpd_dma_chan1: dma"
		dict set def_ps_mapping ffaa0000 label "lpd_dma_chan2: dma"
		dict set def_ps_mapping ffab0000 label "lpd_dma_chan3: dma"
		dict set def_ps_mapping ffac0000 label "lpd_dma_chan4: dma"
		dict set def_ps_mapping ffad0000 label "lpd_dma_chan5: dma"
		dict set def_ps_mapping ffae0000 label "lpd_dma_chan6: dma"
		dict set def_ps_mapping ffaf0000 label "lpd_dma_chan7: dma"
		dict set def_ps_mapping ff0c0000 label "gem0: ethernet"
		dict set def_ps_mapping ff0d0000 label "gem1: ethernet"
		dict set def_ps_mapping ff0b0000 label "gpio0: gpio"
		dict set def_ps_mapping f1020000 label "gpio1: gpio"
		dict set def_ps_mapping ff020000 label "i2c0: i2c"
		dict set def_ps_mapping ff030000 label "i2c1: i2c"
		dict set def_ps_mapping f1000000 label "i2c2: i2c"
		dict set def_ps_mapping f1030000 label "qspi: spi"
		dict set def_ps_mapping f12a0000 label "rtc: rtc"
		dict set def_ps_mapping fd0c0000 label "sata: sata"
		dict set def_ps_mapping f1040000 label "sdhci0: sdhci"
		dict set def_ps_mapping f1050000 label "sdhci1: sdhci"
		dict set def_ps_mapping fd800000 label "smmu: smmu"
		dict set def_ps_mapping ff040000 label "spi0: spi"
		dict set def_ps_mapping ff050000 label "spi1: spi"
		dict set def_ps_mapping f1010000 label "ospi: spi"
		dict set def_ps_mapping ff0e0000 label "ttc0: timer"
		dict set def_ps_mapping ff0f0000 label "ttc1: timer"
		dict set def_ps_mapping ff100000 label "ttc2: timer"
		dict set def_ps_mapping ff110000 label "ttc3: timer"
		dict set def_ps_mapping ff000000 label "serial0: serial"
		dict set def_ps_mapping ff010000 label "serial1: serial"
		dict set def_ps_mapping fe200000 label "dwc3_0: dwc3"
		dict set def_ps_mapping fd4d0000 label "watchdog: watchdog"
		dict set def_ps_mapping fca10000 label "cpm_pciea: pci"
		dict set def_ps_mapping ff060000 label "can0: can"
		dict set def_ps_mapping ff070000 label "can1: can"
		dict set def_ps_mapping f12b0000 label cfu
		dict set def_ps_mapping f12d0000 label cframe
		dict set def_ps_mapping f11c0000 label pmcdma
		dict set def_ps_mapping f11d0000 label pmcdma
	} elseif {[string match -nocase $proctype "psu_cortexa53"] || \
		[string match -nocase $proctype "psu_pmu"] ||
		[string match -nocase $proctype "psu_cortexr5"]} {
		dict set def_ps_mapping f9010000 label gic
		dict set def_ps_mapping f9000000 label rpu_gic
		dict set def_ps_mapping ff060000 label can0
		dict set def_ps_mapping ff070000 label can1
		dict set def_ps_mapping fd500000 label gdma0
		dict set def_ps_mapping fd510000 label gdma1
		dict set def_ps_mapping fd520000 label gdma2
		dict set def_ps_mapping fd530000 label gdma3
		dict set def_ps_mapping fd540000 label gdma4
		dict set def_ps_mapping fd550000 label gdma5
		dict set def_ps_mapping fd560000 label gdma6
		dict set def_ps_mapping fd570000 label gdma7
		dict set def_ps_mapping fd4b0000 label gpu
		dict set def_ps_mapping ffa80000 label adma0
		dict set def_ps_mapping ffa90000 label adma0
		dict set def_ps_mapping ffaa0000 label adma2
		dict set def_ps_mapping ffab0000 label adma3
		dict set def_ps_mapping ffac0000 label adma4
		dict set def_ps_mapping ffad0000 label adma5
		dict set def_ps_mapping ffae0000 label adma6
		dict set def_ps_mapping ffaf0000 label adma7
		dict set def_ps_mapping ff100000 label nand0
		dict set def_ps_mapping ff0b0000 label gem0
		dict set def_ps_mapping ff0c0000 label gem1
		dict set def_ps_mapping ff0d0000 label gem2
		dict set def_ps_mapping ff0e0000 label gem3
		dict set def_ps_mapping ff0a0000 label gpio
		dict set def_ps_mapping ff020000 label i2c0
		dict set def_ps_mapping ff030000 label i2c1
		dict set def_ps_mapping ff0f0000 label qspi
		dict set def_ps_mapping ffa60000 label rtc
		dict set def_ps_mapping fd0c0000 label sata
		dict set def_ps_mapping ff160000 label sdhci0
		dict set def_ps_mapping ff170000 label sdhci1
		dict set def_ps_mapping fd800000 label smmu
		dict set def_ps_mapping ff040000 label spi0
		dict set def_ps_mapping ff050000 label spi1
		dict set def_ps_mapping ff110000 label ttc0
		dict set def_ps_mapping ff120000 label ttc1
		dict set def_ps_mapping ff130000 label ttc2
		dict set def_ps_mapping ff140000 label ttc3
		dict set def_ps_mapping ff000000 label uart0
		dict set def_ps_mapping ff010000 label uart1
		dict set def_ps_mapping fe200000 label usb0
		dict set def_ps_mapping fe300000 label usb1
		dict set def_ps_mapping fd4d0000 label watchdog0
		dict set def_ps_mapping 43c00000 label dp
		dict set def_ps_mapping 43c0a000 label dpsub
		dict set def_ps_mapping fd4c0000 label dpdma
		dict set def_ps_mapping fd0e0000 label pcie
		dict set def_ps_mapping ff300000 label ipi0
		dict set def_ps_mapping ff310000 label ipi1
		dict set def_ps_mapping ff320000 label ipi2
		dict set def_ps_mapping ff330000 label ipi3
		dict set def_ps_mapping ff331000 label ipi4
		dict set def_ps_mapping ff332000 label ipi5
		dict set def_ps_mapping ff333000 label ipi6
		dict set def_ps_mapping ffcb0000 label watchdog
		dict set def_ps_mapping fd070000 label memory-controller
		dict set def_ps_mapping fd1a0000 label crfapb
		dict set def_ps_mapping ff5e0000 label crlapb
		dict set def_ps_mapping ffcc0000 label efuse
		dict set def_ps_mapping ff180000 label iou_slcr
		dict set def_ps_mapping ff410000 label lpd_slcr
	} else {
		dict set def_ps_mapping f8891000 label pmu
		dict set def_ps_mapping f8007100 label adc
		dict set def_ps_mapping e0008000 label can0
		dict set def_ps_mapping e0009000 label can1
		dict set def_ps_mapping e000a000 label gpio0
		dict set def_ps_mapping e0004000 label i2c0
		dict set def_ps_mapping e0005000 label i2c1
		dict set def_ps_mapping f8f01000 label intc
		dict set def_ps_mapping f8f00100 label intc
		dict set def_ps_mapping f8f02000 label L2
		dict set def_ps_mapping f8006000 label memory-controller
		dict set def_ps_mapping f800c000 label ocmc
		dict set def_ps_mapping e0000000 label uart0
		dict set def_ps_mapping e0001000 label uart1
		dict set def_ps_mapping e0006000 label spi0
		dict set def_ps_mapping e0007000 label spi1
		dict set def_ps_mapping e000d000 label qspi
		dict set def_ps_mapping e000e000 label smcc
		dict set def_ps_mapping e1000000 label nand0
		dict set def_ps_mapping e2000000 label nor
		dict set def_ps_mapping e000b000 label gem0
		dict set def_ps_mapping e000c000 label gem1
		dict set def_ps_mapping e0100000 label sdhci0
		dict set def_ps_mapping e0101000 label sdhci1
		dict set def_ps_mapping f8000000 label slcr
		dict set def_ps_mapping f8003000 label dmac_s
		dict set def_ps_mapping f8007000 label devcfg
		dict set def_ps_mapping f8f00200 label global_timer
		dict set def_ps_mapping f8001000 label ttc0
		dict set def_ps_mapping f8002000 label ttc1
		dict set def_ps_mapping f8f00600 label scutimer
		dict set def_ps_mapping f8005000 label watchdog0
		dict set def_ps_mapping f8f00620 label scuwatchdog
		dict set def_ps_mapping e0002000 label usb0
		dict set def_ps_mapping e0003000 label usb1
	}

	set ps_mapping [dict create]
	global zynq_soc_dt_tree
	if {[lsearch [get_dt_trees] $zynq_soc_dt_tree] >= 0} {
		# get nodes under bus
		foreach node [get_all_tree_nodes $zynq_soc_dt_tree] {
			# only care about the device with parent ambe
			set parent [hsi get_property PARENT  $node]
			set ignore_parent_list {(/|cpu)}
			set node_label [hsi get_property NODE_LABEL $node]
			if {[regexp $ignore_parent_list $parent matched] && ![string match -nocase $node_label "gic_r5"]} {
				continue
			}
			set unit_addr [hsi get_property UNIT_ADDRESS $node]
			if {[string length $unit_addr] <= 1} {
				set unit_addr ""
			}
			set node_name [hsi get_property NODE_NAME $node]
			if  {[ regexp "tcm" $node_name ]} {
				set $node_name [dict get $ps_mapping $node_unit_addr label]
			}
			set node_label [hsi get_property NODE_LABEL $node]
			if {[catch {set status_prop [hsi get_property CONFIG.status $node]} msg]} {
				set status_prop "enable"
			}
			if {[string_is_empty $node_label] || \
				[string_is_empty $unit_addr]} {
				continue
			}
			dict set ps_mapping $unit_addr label $node_label
			dict set ps_mapping $unit_addr name $node_name
			dict set ps_mapping $unit_addr status $status_prop
		}
	}
	if {[string_is_empty $ps_mapping]} {
		return $def_ps_mapping
	} else {
		return $ps_mapping
	}
}

proc ps_node_mapping {ip_name prop} {
	# if {[is_ps_ip $ip_name]} {
	# 	set unit_addr [get_ps_node_unit_addr $ip_name]
	# 	if {$unit_addr == -1} {return $ip_name}
	# 	set ps7_mapping [gen_ps7_mapping]

	# 	if {[catch {set tmp [dict get $ps7_mapping $unit_addr $prop]} msg]} {
	# 		continue
	# 	}
	# 	return $tmp
	# }
	return $ip_name
}

proc get_ps_node_unit_addr {ip_name {prop "label"}} {
	set ip [hsi::get_cells -hier $ip_name]
	set ip_mem_handle [get_ip_mem_ranges [hsi::get_cells -hier $ip]]
	set ps7_mapping [gen_ps7_mapping]

	# loop through the base addresses: workaround for intc
	foreach handler ${ip_mem_handle} {
		set unit_addr [string tolower [hsi get_property BASE_VALUE $handler]]
		regsub -all {^0x} $unit_addr {} unit_addr
		if {[is_ps_ip [get_drivers $ip_name]]} {
			if {[catch {set tmp [dict get $ps7_mapping $unit_addr $prop]} msg]} {
				continue
			}
			return $unit_addr
		}
	}
	return -1
}

proc remove_empty_reference_node {} {
	# check for ps_ips
	global zynq_soc_dt_tree
	set dts_files [list_remove_element [get_dt_trees] $zynq_soc_dt_tree]
	foreach dts_file $dts_files {
		set_cur_working_dts $dts_file
		foreach node [get_all_tree_nodes $dts_file] {
			if {[regexp "^&.*" $node matched]} {
				# check if it has child node
				set child_nodes [get_dt_nodes -of_objects $node]
				if {![string_is_empty $child_nodes]} {
					continue
				}
				set prop_list [hsi list_property -regexp $node "CONFIG.*"]
				if {[string_is_empty $prop_list]} {
					dtg_debug "removing $node"
					delete_objs $node
				}
			}
		}
	}
}

proc add_dts_header {dts_file str_add} {
	set cur_dts [current_dt_tree]
	set dts_obj [set_cur_working_dts ${dts_file}]
	set header [hsi get_property HEADER $dts_obj]
	append header "\n" $str_add
	set_property HEADER $header $dts_obj
	set_cur_working_dts $cur_dts
}

proc zynq_gen_pl_clk_binding {drv_handle} {
	# add dts binding for required nodes
	#   clock-names = "ref_clk";
	#   clocks = <&clkc 0>;
	global bus_clk_list
	proc_called_by
	set plattype [get_hw_family]
	# Assuming these device supports the clocks
	global env
	set path $env(CUSTOM_SDT_REPO)

	#set drvname [get_drivers $drv_handle]
	#
	#set common_file "$path/device_tree/data/config.yaml"
	set common_file [file join [file dirname [dict get [info frame 0] file]] "config.yaml"]
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	}
	set mainline_ker [get_user_config $common_file -mainline_kernel]

	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
	if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		set valid_ip_list "axi_timer axi_uartlite axi_uart16550 axi_gpio axi_traffic_gen axi_ethernet axi_ethernet_buffer can canfd axi_iic xadc_wiz vcu"
	} else {
		set valid_ip_list "xadc_wiz"
	}
	set valid_plt "zynq zynqmp zynquplus zynquplusRFSOC"
	if {[lsearch  -nocase $valid_plt $plattype] >= 0} {
		set iptype [get_ip_property $drv_handle IP_NAME]
		if {[lsearch $valid_ip_list $iptype] >= 0} {
			set node [get_node $drv_handle]
			# FIXME: this is hardcoded - maybe dynamic detection
			# Keep the below logic, until we have clock frame work for ZynqMP
			if {[string match -nocase $iptype "can"] || [string match -nocase $iptype "canfd"]} {
				set clks "can_clk s_axi_aclk"
			} elseif {[string match -nocase $iptype "vcu"]} {
				set clks "pll_ref_clk s_axi_lite_aclk"
			} else {
				set clks "s_axi_aclk"
			}
			foreach pin $clks {
				if {[is_zynqmp_platform $plattype]} {
					set dts_file [set_drv_def_dts $drv_handle]
					set bus_node [add_or_get_bus_node $drv_handle $dts_file]
					set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] $pin]
					if {![string equal $clk_freq ""]} {
						if {[lsearch $bus_clk_list $clk_freq] < 0} {
							set bus_clk_list [lappend bus_clk_list $clk_freq]
						}
						set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
						set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" |
							-d ${dts_file} -p ${bus_node}]
						# create the node and assuming reg 0 is taken by cpu
						set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
						gen_fixed_factor_clk_node ${misc_clk_node} ${clk_freq} $dts_file
						if {[string match -nocase $iptype "can"] || [string match -nocase $iptype "vcu"] || [string match -nocase $iptype "canfd"]} {
							set clocks [lindex $clk_refs 0]
							append clocks ">, <&[lindex $clk_refs 1]"
							set_drv_prop $drv_handle "clocks" "$clocks" $node reference
							set_drv_prop_if_empty $drv_handle "clock-names" "$clks" $node stringlist
						} else {
							set_drv_prop_if_empty $drv_handle "clocks" $clk_refs $node reference
							set_drv_prop_if_empty $drv_handle "clock-names" "$clks" $node stringlist
						}
					}
				} else {
					set_drv_prop_if_empty $drv_handle "clock-names" "ref_clk" $node stringlist
					set_drv_prop_if_empty $drv_handle "clocks" "clkc 0" $node reference
				}
			}
		}
	}
}

proc gen_dfx_reg_property {drv_handle dfx_node} {
       set ip_name  [get_ip_property $drv_handle IP_NAME]
       set reg ""
       set slave [hsi::get_cells -hier ${drv_handle}]
       set ip_mem_handles [get_ip_mem_ranges $slave]
       foreach mem_handle ${ip_mem_handles} {
               set base [string tolower [hsi get_property BASE_VALUE $mem_handle]]
               set high [string tolower [hsi get_property HIGH_VALUE $mem_handle]]
               set size [format 0x%x [expr {${high} - ${base} + 1}]]
               set proctype [hsi get_property IP_NAME [hsi::get_cells -hier [get_sw_processor]]]
               if {[string_is_empty $reg]} {
                       if {$proctype in {"psu_cortexa53" "psv_cortexa72" "psx_cortexa78" "cortex78"}} {
                       # check if base address is 64bit and split it as MSB and LSB
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
                       } else {
                               set reg "$base $size"
                       }
               } else {
                       if {[string match -nocase $proctype "ps7_cortexa9"] || [string match -nocase $proctype "microblaze"]} {
                               set index [check_base $reg $base $size]
                               if {$index == "true"} {
                                       continue
                               }
                       }
                       if {$proctype in {"psu_cortexa53" "psv_cortexa72" "psx_cortexa78" "cortexa78" }} {
                               set index [check_64_base $reg $base $size]
                               if {$index == "true"} {
                                       continue
                               }
                       }
                       # ensure no duplication
                       if {![regexp ".*${reg}.*" "$base $size" matched]} {
                               if {$proctype in {"psu_cortexa53" "psv_cortexa72" "psx_cortexa78" "cortexa78"}} {
                                       set base1 "0x0 $base"
                                       set size1 "0x0 $size"
                                       if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                                               set temp $base
                                               set temp [string trimleft [string trimleft $temp 0] x]
                                               set len [string length $temp]
                                               set rem [expr {${len} - 8}]
                                               set high_base "0x[string range $temp $rem $len]"
                                               set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                                               set low_base [format 0x%08x $low_base]
                                               set base1 "$low_base $high_base"
                                       }
                                       if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                                               set temp $size
                                               set temp [string trimleft [string trimleft $temp 0] x]
                                               set len [string length $temp]
                                               set rem [expr {${len} - 8}]
                                               set high_size "0x[string range $temp $rem $len]"
                                               set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
                                               set low_size [format 0x%08x $low_size]
                                               set size1 "$low_size $high_size"
                                       }
                                       set reg "$reg $base1 $size1"
                               } else {
                                       set reg "$reg $base $size"
                               }
                       }
               }
       }
       add_new_dts_param "$dfx_node" "reg" "$reg" intlist
}

proc gen_dfx_clk_property {drv_handle dts_file child_node dfx_node} {
       set remove_pl [hsi get_property CONFIG.remove_pl [get_os]]
       if {[is_pl_ip $drv_handle] && $remove_pl} {
               return 0
       }
       set mainline_ker [hsi get_property CONFIG.mainline_kernel [get_os]]
       set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
       if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		return 0
       }
       set clocks ""
       set axi 0
       set is_clk_wiz 0
       set is_pl_clk 0
       set updat ""
       global bus_clk_list
       set clocknames ""
       set proctype [hsi get_property IP_NAME [hsi::get_cells -hier [get_sw_processor]]]
       if {[string match -nocase $proctype "microblaze"] || [string match -nocase $proctype "microblaze_riscv"]} {
               return
       }
       set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
       set ip [get_ip_property $drv_handle IP_NAME]
       foreach clk $clk_pins {
               set ip [hsi::get_cells -hier $drv_handle]
               set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] $clk]]
               set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
               set pl_clk ""
               set clkout ""
               foreach pin $pins {
                       if {[lsearch $valid_clk_list $pin] >= 0} {
                               set clkout $pin
                               set is_clk_wiz 1
                               set periph [::hsi::get_cells -of_objects $pin]
                       }
               }
               if {[llength $clkout]} {
                       set number [regexp -all -inline -- {[0-9]+} $clkout]
                       set clk_wiz [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                       set axi_clk "s_axi_aclk"
                       foreach clk1 $clk_wiz {
                               if {[regexp $axi_clk $clk1 match]} {
                                       set axi 1
                               }
                       }
                       if {[string match -nocase $axi "0"]} {
                               dtg_warning "no s_axi_aclk for clockwizard IP block: \" $periph\"\n\r"
                               set pins [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                               set clk_list "pl_clk*"
                               set clk_pl ""
                               set num ""
                               foreach clk_wiz_pin $pins {
                                       set clk_wiz_pins [hsi::get_pins -of_objects [get_nets -of_objects $clk_wiz_pin]]
                                       foreach pin $clk_wiz_pins {
                                               if {[regexp $clk_list $pin match]} {
                                                       set clk_pl $pin
                                               }
                                       }
                               }
                               set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                               if {[llength $clk_freq] == 0} {
                                       dtg_warning "clock frequency for the $clk is NULL of IP block: \" $drv_handle\"\n\r"
                                       continue
                               }
                               # if clk_freq is float convert it to int
                               set clk_freq [expr int($clk_freq)]
                               set iptype [get_ip_property $drv_handle IP_NAME]
                               if {![string equal $clk_freq ""]} {
                                       if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                               set bus_clk_list [lappend bus_clk_list $clk_freq]
                                       }
                                       set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                       set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                               -d ${dts_file} -p ${child_node}]
                                       set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                       set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                       add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
                                       add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
                                       add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
                               }
                       }
                       if {![string match -nocase $axi "0"]} {
                               switch $number {
                                       "1" {
                                               set peri "$periph 0"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "2" {
                                               set peri "$periph 1"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "3" {
                                               set peri "$periph 2"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "4" {
                                               set peri "$periph 3"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "5" {
                                               set peri "$periph 4"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "6" {
                                               set peri "$periph 5"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "7" {
                                               set peri "$periph 6"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                               }
                       }
               }
               if {$proctype in {"psu_cortexa53" "psv_cortexa72" "psx_cortexa78" "cortexa78"}} {
                       set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
               }
               foreach pin $pins {
                       if {[lsearch $clklist $pin] >= 0} {
                               set pl_clk $pin
                               set is_pl_clk 1
                       }
               }
               if {$proctype in {"psv_cortexa72" "psx_cortexa78" "cortexa78"}} {
                       switch $pl_clk {
                               "pl_clk0" {
                                       set pl_clk0 "versal_clk 65"
                                       set clocks [lappend clocks $pl_clk0]
                                       set updat  [lappend updat $pl_clk0]
                               }
                               "pl_clk1" {
                                               set pl_clk1 "versal_clk 66"
                                               set clocks [lappend clocks $pl_clk1]
                                               set updat  [lappend updat $pl_clk1]
                               }
                               "pl_clk2" {
                                               set pl_clk2 "versal_clk 67"
                                               set clocks [lappend clocks $pl_clk2]
                                               set updat [lappend updat $pl_clk2]
                               }
                               "pl_clk3" {
                                               set pl_clk3 "versal_clk 68"
                                               set clocks [lappend clocks $pl_clk3]
                                               set updat [lappend updat $pl_clk3]
                               }
                               default {
						dtg_warning  "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"\n\r"
                               }
                       }
               }
               if {[string match -nocase $proctype "psu_cortexa53"]} {
                       switch $pl_clk {
                               "pl_clk0" {
                                               set pl_clk0 "zynqmp_clk 71"
                                               set clocks [lappend clocks $pl_clk0]
                                               set updat  [lappend updat $pl_clk0]
                               }
                               "pl_clk1" {
                                               set pl_clk1 "zynqmp_clk 72"
                                               set clocks [lappend clocks $pl_clk1]
                                               set updat  [lappend updat $pl_clk1]
                               }
                               "pl_clk2" {
                                               set pl_clk2 "zynqmp_clk 73"
                                               set clocks [lappend clocks $pl_clk2]
                                               set updat [lappend updat $pl_clk2]
                               }
                               "pl_clk3" {
                                               set pl_clk3 "zynqmp_clk 74"
                                               set clocks [lappend clocks $pl_clk3]
                                               set updat [lappend updat $pl_clk3]
                               }
                               default {
					dtg_warning  "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"\n\r"
                               }
                       }
               }
               if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
                       set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                       if {[llength $clk_freq] == 0} {
                               dtg_warning "clock frequency for the $clk is NULL of IP block: \"$drv_handle\"\n\r"
                               continue
                       }
                       # if clk_freq is float convert it to int
                       set clk_freq [expr int($clk_freq)]
                       set iptype [get_ip_property $drv_handle IP_NAME]
                       if {![string equal $clk_freq ""]} {
                               if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                       set bus_clk_list [lappend bus_clk_list $clk_freq]
                               }
                               set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                               set misc_clk_node [add_or_get_dt_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                               -d ${dts_file} -p ${child_node}]
                               set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                               set updat [lappend updat misc_clk_${bus_clk_cnt}]
                               add_new_dts_param "${misc_clk_node}" "compatible" "fixed-clock" stringlist
                               add_new_dts_param "${misc_clk_node}" "#clock-cells" 0 int
                               add_new_dts_param "${misc_clk_node}" "clock-frequency" $clk_freq int
                       }
               }
               append clocknames " " "$clk"
               set is_pl_clk 0
               set is_clk_wiz 0
               set axi 0
       }
       add_new_dts_param "${dfx_node}" "clock-names" "$clocknames" stringlist
       set ip [get_ip_property $drv_handle IP_NAME]
       set len [llength $updat]
       switch $len {
               "1" {
                       set refs [lindex $updat 0]
                       add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
               }
               "2" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]"
                       add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
               }
               "3" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
                       add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
               }
               "4" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
                       add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
               }
               "5" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
                       add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
               }
               "6" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
                       add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
               }
               "7" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
                       add_new_dts_param "${dfx_node}" "clocks" "$refs" reference
	}
       }
}

proc gen_axis_switch_clk_property {drv_handle dts_file node} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	#set drvname [get_drivers $drv_handle]
	#set common_file "$path/device_tree/data/config.yaml"
	set common_file [file join [file dirname [dict get [info frame 0] file]] "config.yaml"]
	set mainline_ker [get_user_config $common_file -mainline_kernel]
       set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
       if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
               return 0
       }
       set clocks ""
       set axi 0
       set is_clk_wiz 0
       set is_pl_clk 0
       set updat ""
       global bus_clk_list
       set clocknames ""
	set proctype [get_hw_family]
	if {[regexp "microblaze" $proctype match]} {
		return
	}
       set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
       set ip [get_ip_property $drv_handle IP_NAME]
       foreach clk $clk_pins {
               set ip [hsi::get_cells -hier $drv_handle]
               set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] $clk]]
               set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
               set pl_clk ""
               set clkout ""
               foreach pin $pins {
                       if {[lsearch $valid_clk_list $pin] >= 0} {
                               set clkout $pin
                               set is_clk_wiz 1
                               set periph [hsi::get_cells -of_objects $pin]
                       }
               }
               if {[llength $clkout]} {
                       set number [regexp -all -inline -- {[0-9]+} $clkout]
                       set clk_wiz [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                       set axi_clk "s_axi_aclk"
                       foreach clk1 $clk_wiz {
                               if {[regexp $axi_clk $clk1 match]} {
                                       set axi 1
                               }
                       }
                       if {[string match -nocase $axi "0"]} {
                               dtg_warning "no s_axi_aclk for clockwizard IP block: \" $periph\"\n\r"
                               set pins [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                               set clk_list "pl_clk*"
                               set clk_pl ""
                               set num ""
                               foreach clk_wiz_pin $pins {
                                       set clk_wiz_pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects $clk_wiz_pin]]
                                       foreach pin $clk_wiz_pins {
                                               if {[regexp $clk_list $pin match]} {
                                                       set clk_pl $pin
                                               }
                                       }
                               }
                               set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                               if {[llength $clk_freq] == 0} {
                                       dtg_warning "clock frequency for the $clk is NULL of IP block: \" $drv_handle\"\n\r"
                                       continue
                               }
                               set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                               # if clk_freq is float convert it to int
                               set clk_freq [expr int($clk_freq)]
                               set iptype [get_ip_property $drv_handle IP_NAME]
                               if {![string equal $clk_freq ""]} {
                                       if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                               set bus_clk_list [lappend bus_clk_list $clk_freq]
                                       }
                                       set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                       set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                               -d ${dts_file} -p ${bus_node}]
                                       set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                       set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                       add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                       add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                       add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                               }
                       }
                       if {![string match -nocase $axi "0"]} {
                               switch $number {
                                       "1" {
                                               set peri "$periph 0"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "2" {
                                               set peri "$periph 1"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "3" {
                                               set peri "$periph 2"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "4" {
                                               set peri "$periph 3"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "5" {
                                               set peri "$periph 4"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "6" {
                                               set peri "$periph 5"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                                       "7" {
                                               set peri "$periph 6"
                                               set clocks [lappend clocks $peri]
                                               set updat [lappend updat $peri]
                                       }
                               }
                       }
               }
               if {$proctype in {"psu_cortexa53" "psv_cortexa72" "psx_cortexa78" "cortexa78"}} {
                       set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
               }
               foreach pin $pins {
                       if {[lsearch $clklist $pin] >= 0} {
                               set pl_clk $pin
                               set is_pl_clk 1
                       }
               }
               if {$proctype in {"psv_cortexa72" "psx_cortexa78" "cortexa78"}} {
                       switch $pl_clk {
                               "pl_clk0" {
                                       set pl_clk0 "versal_clk 65"
                                       set clocks [lappend clocks $pl_clk0]
                                       set updat  [lappend updat $pl_clk0]
                               }
                               "pl_clk1" {
                                               set pl_clk1 "versal_clk 66"
                                               set clocks [lappend clocks $pl_clk1]
                                               set updat  [lappend updat $pl_clk1]
                               }
                               "pl_clk2" {
                                               set pl_clk2 "versal_clk 67"
                                               set clocks [lappend clocks $pl_clk2]
                                               set updat [lappend updat $pl_clk2]
                               }
                               "pl_clk3" {
                                               set pl_clk3 "versal_clk 68"
                                               set clocks [lappend clocks $pl_clk3]
                                               set updat [lappend updat $pl_clk3]
                               }
                               default {
                                               dtg_debug "not supported pl_clk:$pl_clk"
                               }
                       }
               }
               if {[string match -nocase $proctype "psu_cortexa53"]} {
                       switch $pl_clk {
                               "pl_clk0" {
                                               set pl_clk0 "zynqmp_clk 71"
                                               set clocks [lappend clocks $pl_clk0]
                                               set updat  [lappend updat $pl_clk0]
                               }
                               "pl_clk1" {
                                               set pl_clk1 "zynqmp_clk 72"
                                               set clocks [lappend clocks $pl_clk1]
                                               set updat  [lappend updat $pl_clk1]
                               }
                               "pl_clk2" {
                                               set pl_clk2 "zynqmp_clk 73"
                                               set clocks [lappend clocks $pl_clk2]
                                               set updat [lappend updat $pl_clk2]
                               }
                               "pl_clk3" {
                                               set pl_clk3 "zynqmp_clk 74"
                                               set clocks [lappend clocks $pl_clk3]
                                               set updat [lappend updat $pl_clk3]
                               }
                               default {
                                       dtg_debug "not supported pl_clk:$pl_clk"
                               }
                       }
               }
               if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
                       set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                       if {[llength $clk_freq] == 0} {
                               dtg_warning "clock frequency for the $clk is NULL of IP block: \"$drv_handle\"\n\r"
                               continue
                       }
                       set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                       # if clk_freq is float convert it to int
                       set clk_freq [expr int($clk_freq)]
                       set iptype [get_ip_property $drv_handle IP_NAME]
                       if {![string equal $clk_freq ""]} {
                               if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                       set bus_clk_list [lappend bus_clk_list $clk_freq]
                               }
                               set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                               set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                               -d ${dts_file} -p ${bus_node}]
                               set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                               set updat [lappend updat misc_clk_${bus_clk_cnt}]
                               add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                               add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                               add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                       }
               }
               append clocknames " " "$clk"
               set is_pl_clk 0
               set is_clk_wiz 0
               set axi 0
       }
       add_prop "${node}" "clock-names" "$clocknames" stringlist $dts_file
       set ip [get_ip_property $drv_handle IP_NAME]
       set len [llength $updat]
       switch $len {
               "1" {
                       set refs [lindex $updat 0]
                       add_prop "${node}" "clocks" "$refs" reference $dts_file
               }
               "2" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]"
                       add_prop "${node}" "clocks" "$refs" reference $dts_file
               }
               "3" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
                       add_prop "${node}" "clocks" "$refs" reference $dts_file
               }
               "4" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
                       add_prop "${node}" "clocks" "$refs" reference $dts_file
               }
               "5" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
                       add_prop "${node}" "clocks" "$refs" reference $dts_file
               }
               "6" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
                       add_prop "${node}" "clocks" "$refs" reference $dts_file
               }
               "7" {
                       set refs [lindex $updat 0]
                       append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
                       add_prop "${node}" "clocks" "$refs" reference $dts_file
               }
       }
}

proc gen_clk_property {drv_handle} {
	global is_versal_net_platform
	global is_rm_design

	if {[is_ps_ip $drv_handle]} {
		return 0
	}

	set rp_info {}
	if {$is_rm_design} {
		set rp_info [get_rprm_for_drv $drv_handle]
		if {[llength $rp_info] != 0} {
			set firmware_name [get_partial_file]
			set partial_fileName [file rootname $firmware_name]
			set partial_fileName "${partial_fileName}_"
		}
	}

	global env
	set path $env(CUSTOM_SDT_REPO)
	#set drvname [get_drivers $drv_handle]
	#set common_file "$path/device_tree/data/config.yaml"
	set common_file [file join [file dirname [dict get [info frame 0] file]] "config.yaml"]
	set mainline_ker [get_user_config $common_file -mainline_kernel]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
        if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
		return 0
	}
	set clocks ""
	set axi 0
	set is_clk_wiz 0
	set is_pl_clk 0
	set updat ""
	global bus_clk_list
	set clocknames ""

	dtg_verbose "gen_clk_property:$drv_handle"
	proc_called_by
	set proctype [get_hw_family]
	if {[regexp "microblaze" $proctype match]} {
		return
	}

	set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I  || TYPE==gt_usrclk&&DIRECTION==I}]
	dtg_verbose "clk_pins:$clk_pins"
	set ip [get_ip_property $drv_handle IP_NAME]
	set ignore_list "lmb_bram_if_cntlr PERIPHERAL axi_noc mrmac"
	if {[lsearch $ignore_list $ip] >= 0 } {
		return 0
        }
	if {[string match -nocase $ip "vcu"]} {
		set clk_pins "pll_ref_clk s_axi_lite_aclk"
	}
	foreach clk $clk_pins {
		set ip [hsi::get_cells -hier $drv_handle]
		set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] $clk]]
		set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
		set pl_clk ""
		set clkout ""
		foreach pin $pins {
			if {[lsearch $valid_clk_list $pin] >= 0} {
				set clkout $pin
				set is_clk_wiz 1
				set periph [hsi::get_cells -of_objects $pin]
			}
		}
		if {[llength $clkout]} {
			set number [regexp -all -inline -- {[0-9]+} $clkout]
			set clk_wiz [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
			set axi_clk "s_axi_aclk"
			foreach clk1 $clk_wiz {
				if {[regexp $axi_clk $clk1 match]} {
					set axi 1
				}
			}

			if {[string match -nocase $axi "0"]} {
				dtg_warning "no s_axi_aclk for clockwizard IP block: \" $periph\"\n\r"
				set pins [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
				set clk_list "pl_clk*"
				set clk_pl ""
				set num ""
				foreach clk_wiz_pin $pins {
					set clk_wiz_pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects $clk_wiz_pin]]
					foreach pin $clk_wiz_pins {
						if {[regexp $clk_list $pin match]} {
							set clk_pl $pin
						}
					}
				}
				if {[llength $clk_pl]} {
					set num [regexp -all -inline -- {[0-9]+} $clk_pl]
				}
				set dts_file "pl.dtsi"
				set bus_node [add_or_get_bus_node $drv_handle $dts_file]
				set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
				if {[llength $clk_freq] == 0} {
					dtg_warning "clock frequency for the $clk is NULL of IP block: \" $drv_handle\"\n\r"
					continue
				}
				# if clk_freq is float convert it to int
				set clk_freq [expr int($clk_freq)]
				set iptype [get_ip_property $drv_handle IP_NAME]
				if {![string equal $clk_freq ""]} {
					if {[lsearch $bus_clk_list $clk_freq] < 0} {
						set bus_clk_list [lappend bus_clk_list $clk_freq]
					}
					set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
					set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
					-d ${dts_file} -p ${bus_node}]

					set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
					set updat [lappend updat misc_clk_${bus_clk_cnt}]
					if {[string match -nocase $proctype "zynqmp"]} {
						set in_pin [lindex [hsi::get_pins -of_objects $periph -filter {NAME =~ "*clk_in*"}] 0]
						set src [get_source_pins $in_pin]

						if {[string match "*pl_clk*" [string tolower $src]]} {
							gen_fixed_factor_clk_node ${misc_clk_node} ${clk_freq} $dts_file
						} else {
							add_prop $misc_clk_node "compatible" "fixed-clock" stringlist $dts_file 1
							add_prop $misc_clk_node "#clock-cells" 0 int $dts_file 1
							add_prop $misc_clk_node "clock-frequency" $clk_freq int $dts_file 1
						}
					} else {
						add_prop $misc_clk_node "compatible" "fixed-clock" stringlist $dts_file 1
						add_prop $misc_clk_node "#clock-cells" 0 int $dts_file 1
						add_prop $misc_clk_node "clock-frequency" $clk_freq int $dts_file 1
					}
				}
			}
			if {![string match -nocase $axi "0"]} {
				switch $number {
					"1" {
						set peri "$periph 0"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"2" {
						set peri "$periph 1"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"3" {
						set peri "$periph 2"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"4" {
						set peri "$periph 3"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"5" {
						set peri "$periph 4"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"6" {
						set peri "$periph 5"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
					"7" {
						set peri "$periph 6"
						set clocks [lappend clocks $peri]
						set updat [lappend updat $peri]
					}
				}
			}
		}
		switch $proctype {
			"zynqmp" - \
			"zynquplus" - \
			"zynquplusRFSOC" {
				set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
			}
			"versal" {
				set versal_periph [hsi get_cells -hier -filter \
					{ IP_NAME == psx_wizard || IP_NAME == versal_cips \
					|| IP_NAME == ps_wizard }]
				set ver [get_comp_ver $versal_periph]
				if {$ver >= 3.0} {
                               		set clklist "pl0_ref_clk pl1_ref_clk pl2_ref_clk pl3_ref_clk"
                       		} else {
                               		set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
				}
                       	}
			"zynq" {
				set clklist "FCLK_CLK0 FCLK_CLK1 FCLK_CLK2 FCLK_CLK3"
			} default {
			}
		}
		foreach pin $pins {
			if {[lsearch $clklist $pin] >= 0} {
				set pl_clk $pin
				set is_pl_clk 1
			}
		}
		if {[string match -nocase $proctype "versal"]} {
			set versal_periph [hsi get_cells -hier -filter \
				{ IP_NAME == psx_wizard || IP_NAME == versal_cips \
				|| IP_NAME == ps_wizard }]
                       set ver [get_comp_ver $versal_periph]
                       if {$ver >= 3.0} {
                       switch $pl_clk {
                               "pl0_ref_clk" {
                                               set pl_clk0 "versal_clk 65"
                                               set clocks [lappend clocks $pl_clk0]
                                               set updat  [lappend updat $pl_clk0]
                               }
                               "pl1_ref_clk" {
                                               set pl_clk1 "versal_clk 66"
                                               set clocks [lappend clocks $pl_clk1]
                                               set updat  [lappend updat $pl_clk1]
                               }
                               "pl2_ref_clk" {
                                               set pl_clk2 "versal_clk 67"
                                               set clocks [lappend clocks $pl_clk2]
                                               set updat [lappend updat $pl_clk2]
                               }
                               "pl3_ref_clk" {
                                               set pl_clk3 "versal_clk 68"
                                               set clocks [lappend clocks $pl_clk3]
                                               set updat [lappend updat $pl_clk3]
                               }
                               default {
                                               dtg_warning  "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"\n\r"
                               }
                       }
                     } else {
			switch $pl_clk {
				"pl_clk0" {
						set pl_clk0 "versal_clk 65"
						set clocks [lappend clocks $pl_clk0]
						set updat  [lappend updat $pl_clk0]
				}
				"pl_clk1" {
						set pl_clk1 "versal_clk 66"
						set clocks [lappend clocks $pl_clk1]
						set updat  [lappend updat $pl_clk1]
				}
				"pl_clk2" {
						set pl_clk2 "versal_clk 67"
						set clocks [lappend clocks $pl_clk2]
						set updat [lappend updat $pl_clk2]
				}
				"pl_clk3" {
						set pl_clk3 "versal_clk 68"
						set clocks [lappend clocks $pl_clk3]
						set updat [lappend updat $pl_clk3]
				}
				"" {
				}
				default {
						dtg_warning  "Clock pin \"$clk\" of IP block \"$drv_handle\" is not connected to any of the pl_clk\"\n\r"
				}
			}
		}
		}
		if {[is_zynqmp_platform $proctype]} {
			switch $pl_clk {
				"pl_clk0" {
						set pl_clk0 "zynqmp_clk 71"
						set clocks [lappend clocks $pl_clk0]
						set updat  [lappend updat $pl_clk0]
				}
				"pl_clk1" {
						set pl_clk1 "zynqmp_clk 72"
						set clocks [lappend clocks $pl_clk1]
						set updat  [lappend updat $pl_clk1]
				}
				"pl_clk2" {
						set pl_clk2 "zynqmp_clk 73"
						set clocks [lappend clocks $pl_clk2]
						set updat [lappend updat $pl_clk2]
				}
				"pl_clk3" {
						set pl_clk3 "zynqmp_clk 74"
						set clocks [lappend clocks $pl_clk3]
						set updat [lappend updat $pl_clk3]
				}
				"" {
				}
				default {
						dtg_debug "not supported pl_clk:$pl_clk"
				}
			}
		}
		if {[string match -nocase $proctype "zynq"]} {
			switch $pl_clk {
				"FCLK_CLK0" {
						set pl_clk0 "clkc 15"
						set clocks [lappend clocks $pl_clk0]
						set updat  [lappend updat $pl_clk0]
				}
				"FCLK_CLK1" {
						set pl_clk1 "clkc 16"
						set clocks [lappend clocks $pl_clk1]
						set updat  [lappend updat $pl_clk1]
				}
				"FCLK_CLK2" {
						set pl_clk2 "clkc 17"
						set clocks [lappend clocks $pl_clk2]
						set updat [lappend updat $pl_clk2]
				}
				"FCLK_CLK3" {
						set pl_clk3 "clkc 18"
						set clocks [lappend clocks $pl_clk3]
						set updat [lappend updat $pl_clk3]
				}
				"" {
				}
				default {
						dtg_debug "not supported pl_clk:$pl_clk"
				}
			}
		}

		if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
			set dts_file "pl.dtsi"
			set bus_node [add_or_get_bus_node $drv_handle $dts_file]
			set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
			if {[llength $clk_freq] == 0} {
				dtg_warning "clock frequency for the $clk is NULL of IP block: \" $drv_handle\"\n\r"
				continue
			}
			# if clk_freq is float convert it to int
			set clk_freq [expr int($clk_freq)]
			set iptype [get_ip_property $drv_handle IP_NAME]
			if {![string equal $clk_freq ""]} {
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
				set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
				if {[llength $rp_info] != 0} {
					set misc_clk_node [create_node -n "${partial_fileName}misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
					-d ${dts_file} -p ${bus_node}]
				} else {
					set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
					-d ${dts_file} -p ${bus_node}]
				}
				if {[catch {set compatible [pldt get $misc_clk_node "compatible"]} msg]} {
					if {[string match -nocase $proctype "zynqmp"]} {
						gen_fixed_factor_clk_node ${misc_clk_node} ${clk_freq} $dts_file
					} else {
						add_prop $misc_clk_node "compatible" "fixed-clock" stringlist $dts_file 1
						add_prop $misc_clk_node "#clock-cells" 0 int $dts_file 1
						add_prop $misc_clk_node "clock-frequency" $clk_freq int $dts_file 1
					}
				}
				set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
				if {[llength $rp_info] != 0} {
					set updat [lappend updat ${partial_fileName}misc_clk_${bus_clk_cnt}]
				} else {
					set updat [lappend updat misc_clk_${bus_clk_cnt}]
				}
			}
		}
		append clocknames " " "$clk"
		set is_pl_clk 0
		set is_clk_wiz 0
		set axi 0
	}
	set node [get_node $drv_handle]
	if {![string match -nocase $clocknames ""]} {
		set len [llength $updat]
		if {[string match -nocase "[get_ip_property $drv_handle IP_NAME]" "dfx_axi_shutdown_manager"]} {
			set_drv_prop_if_empty $drv_handle "clock-names" "aclk" $node stringlist
		} else {
			set_drv_prop_if_empty $drv_handle "clock-names" $clocknames $node stringlist
		}
	}
	set ip [get_ip_property $drv_handle IP_NAME]
	if {[string match -nocase $ip "vcu"]} {
		set vcu_label $drv_handle
		set vcu_clk1 "$drv_handle 0"
		set updat [lappend updat $vcu_clk1]
		set vcu_clk2 "$drv_handle 1"
		set updat [lappend updat $vcu_clk2]
		set vcu_clk3 "$drv_handle 2"
		set updat [lappend updat $vcu_clk3]
		set vcu_clk4 "$drv_handle 3"
		set updat [lappend updat $vcu_clk4]
		set len [llength $updat]
		set refs [lindex $updat 0]
		append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
		set_drv_prop $drv_handle "clocks" "$refs" $node reference
		return
	}
	set len [llength $updat]
	switch $len {
		"1" {
			set refs [lindex $updat 0]
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"2" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"3" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"4" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"5" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"6" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"7" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"8" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"9" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"10" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"11" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"12" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"13" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"14" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"15" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
		"16" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]"
			set_drv_prop $drv_handle "clocks" "$refs" $node reference
		}
	}

	zynq_gen_pl_clk_binding $drv_handle
}

proc overwrite_clknames {clknames drv_handle} {
	set node [get_node $drv_handle]
	add_prop $node clock-names $clknames stringlist [set_drv_def_dts $drv_handle] 1
}

proc get_comp_ver {drv_handle} {
	global comp_ver_dict
	global cur_hw_design

	if { [dict exists $comp_ver_dict $cur_hw_design $drv_handle] } {
		return [dict get $comp_ver_dict $cur_hw_design $drv_handle]
	}
	set slave [hsi::get_cells -hier ${drv_handle}]
	if {[string length $slave] == 0} {
		return -1
	}
	set vlnv  [split [hsi::get_property VLNV $slave] ":"]
	set ver   [lindex $vlnv 3]
	dict set comp_ver_dict $cur_hw_design $drv_handle $ver
	return $ver
}

proc get_comp_str {drv_handle} {
	global comp_str_dict
	global cur_hw_design

	if { [dict exists $comp_str_dict $cur_hw_design $drv_handle] } {
		return [dict get $comp_str_dict $cur_hw_design $drv_handle]
	}
	set slave [hsi::get_cells -hier ${drv_handle}]
	set vlnv [split [hsi get_property VLNV $slave] ":"]
	#set ver [lindex $vlnv 3]
	set name [lindex $vlnv 2]
	set ver [lindex $vlnv 3]
	set comp_prop "xlnx,${name}-${ver}"
	regsub -all {_} $comp_prop {-} comp_prop
	dict set comp_str_dict $cur_hw_design $drv_handle $comp_prop
	return $comp_prop
}

#TODO: cache intr_type based on ip and port names
proc get_intr_type {intc_name ip_name port_name} {
	global intr_type_dict
	global cur_hw_design
	if { [dict exists $intr_type_dict $cur_hw_design $intc_name $ip_name $port_name] } {
		return [dict get $intr_type_dict $cur_hw_design $intc_name $ip_name $port_name]
	}
	set intc [hsi::get_cells -hier $intc_name]
	set ip [hsi::get_cells -hier $ip_name]
	if {[llength $intc] == 0 && [llength $ip] == 0} {
		dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name -1
		return -1
	}
	if {[llength $intc] == 0} {
		dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name -1
		return -1
	}
	set intr_pin [hsi::get_pins -of_objects $ip $port_name]
	set sensitivity ""
	if {[llength $intr_pin] >= 1} {
		# TODO: check with HSM dev and see if this is a bug
		set sensitivity [hsi get_property SENSITIVITY $intr_pin]
	}
	set intc_type [hsi get_property IP_NAME $intc ]
	set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic psx_acpu_gic acpu_gic"
	if {[lsearch  -nocase $valid_intc_list $intc_type] >= 0} {
		if {[string match -nocase $sensitivity "EDGE_FALLING"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 2
			return 2;
		} elseif {[string match -nocase $sensitivity "EDGE_RISING"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 1
			return 1;
		} elseif {[string match -nocase $sensitivity "LEVEL_HIGH"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 4
			return 4;
		} elseif {[string match -nocase $sensitivity "LEVEL_LOW"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 8
			return 8;
		}
	} else {
		# Follow the openpic specification
		if {[string match -nocase $sensitivity "EDGE_FALLING"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 3
			return 3;
		} elseif {[string match -nocase $sensitivity "EDGE_RISING"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 0
			return 0;
		} elseif {[string match -nocase $sensitivity "LEVEL_HIGH"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 2
			return 2;
		} elseif {[string match -nocase $sensitivity "LEVEL_LOW"]} {
			dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name 1
			return 1;
		}
	}
	dict set intr_type_dict $cur_hw_design $intc_name $ip_name $port_name -1
	return -1
}

proc get_drv_conf_prop_list {ip_name {def_pattern "CONFIG.*"}} {
	set drv_handle [get_ip_handler $ip_name]
	if {[catch {set rt [hsi list_property -regexp $drv_handle ${def_pattern}]} msg]} {
		set rt ""
	}
	return $rt
}

proc get_ip_conf_prop_list {ip_name {def_pattern "CONFIG.*"}} {
	set ip [hsi::get_cells -hier $ip_name]
	if {[catch {set rt [hsi list_property -regexp $ip ${def_pattern}]} msg]} {
		set rt ""
	}
	return $rt
}

proc get_ip_handler {ip_name} {
	# check if it is processor
	proc_called_by
	# check if it is the target processor
	# get it from drvers
	return [get_drivers $ip_name]
}

proc set_drv_prop args {
	set drv_handle [lindex $args 0]
	set prop_name [lindex $args 1]
	set value [lindex $args 2]
	set node [lindex $args 3]
	set dts_file [set_drv_def_dts $drv_handle]
	# check if property exists if not create it
	set list [get_drv_conf_prop_list $drv_handle]
	if {[lsearch -glob ${list} ${prop_name}] < 0} {
	}

	if {[llength $args] >= 5} {
		set type [lindex $args 4]
		#set node [get_node $drv_handle]
		add_prop $node $prop_name $value $type $dts_file
	} else {
		add_prop $node $prop_name $value "hexint" $dts_file 
	}
	return 0
}

proc set_drv_prop_if_empty args {
	set drv_handle [lindex $args 0]
	set prop_name [lindex $args 1]
	set value [lindex $args 2]
	set node [lindex $args 3]
	set dts_file [set_drv_def_dts $drv_handle]
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
	} elseif {[string match -nocase $dts_file "versal.dtsi"]} {
		set treeobj "psdt"
	} else {
		set treeobj "systemdt"
	}
	#set node [get_node $drv_handle]
	set cur_prop_value ""
	if {[catch {set tmp [set cur_prop_value [$treeobj get $node $prop_name]]} msg]} {
	}
	if {[string_is_empty $cur_prop_value] == 0} {
		dtg_debug "$drv_handle $prop_name property is not empty, current value is '$cur_prop_value'"
		return -1
	}
	if {[llength $args] >= 5} {
		set type [lindex $args 4]
		set_drv_prop $drv_handle $prop_name $value $node $type
	} else {
		set_drv_prop $drv_handle $prop_name $value $node
	}
	return 0
}

proc gen_mb_interrupt_property {cpu_handle {intr_port_name ""}} {
	# generate interrupts and interrupt-parent properties for soft IP
	proc_called_by
	if {[is_ps_ip $cpu_handle]} {
		return 0
	}

	set slave [hsi::get_cells -hier ${cpu_handle}]
	set intc ""

	if {[string_is_empty $intr_port_name]} {
		set intr_port_name [hsi::get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
	}
	set cpin [get_interrupt_sources [hsi::get_cells -hier $cpu_handle]]
	if {![string_is_empty $cpin]} {
		set intc [hsi::get_cells -of_objects $cpin]
	}
	if {[string_is_empty $intc]} {
		dtg_warning "no interrupt controller found for $cpu_handle"
		return
	}
	if { [is_intr_cntrl $intc] != 1 } {
		set intf_pins [::hsi::get_intf_pins -of_objects $intc]
		foreach intp $intf_pins {
			set connectip [get_connected_stream_ip [hsi::get_cells -hier $intc] $intp]
			# For TMR designs, there can be interrupts going to comparator IP blocks of TMR
			# which are not really a source of INTERRUPTS for Software but are shown as INTERRUPT
			# pins in the design. Loop over all the connected pins and break when a controller is
			# found. Before encountering this design, connectip was always returning single
			# instance for all the known designs.
			foreach entry $connectip {
				if { [is_intr_cntrl $entry] == 1 } {
					set intc $entry
					break
				}
			}
		}
	}

	set proctype [get_hw_family]
	set bus_name [detect_bus_name $cpu_handle]
	set count [get_microblaze_nr $cpu_handle]
	set proc_name  [get_ip_property $cpu_handle IP_NAME]
	set rt_node [create_node -n "cpus_${proc_name}" -l "cpus_${proc_name}_${count}" -u $count -d "pl.dtsi" -p root]
	set cpu_node [create_node -n "cpu" -l "$cpu_handle" -u $count -d "pl.dtsi" -p $rt_node]

	if {[is_pl_ip $intc]} {
		global dup_periph_handle
		if { [dict exists $dup_periph_handle $intc] } {
			set intc [dict get $dup_periph_handle $intc]
		} else {
			set intc $intc
		}
	}
	# For preset_wrapper designs, the intc IP is not mapped to the microblaze processor
	# but it appears in get_cells -hier ouput. Moreover, the intc may not have the base
	# address in such cases which will lead to missing reference for intc in the SDT.
	# Therefore, check the presence of intc before its reference as handle.
	if {[lsearch -nocase [hsi::get_mem_ranges -of_objects $slave] $intc] >= 0} {
		add_prop $cpu_node "interrupt-handle" $intc reference "pl.dtsi" 1
	}
}

proc get_interrupt_parent {  periph_name intr_pin_name } {
    lappend intr_cntrl
    if { [llength $intr_pin_name] == 0 } {
        return $intr_cntrl
    }

    if { [llength $periph_name] != 0 } {
        set periph [::hsi::get_cells -hier -filter "NAME==$periph_name"]
        if { [llength $periph] == 0 } {
            return $intr_cntrl
        }
        set intr_pin [::hsi::get_pins -of_objects $periph -filter "NAME==$intr_pin_name"]
        if { [llength $intr_pin] == 0 } {
            return $intr_cntrl
        }
        set pin_dir [hsi get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "I"] } {
          return $intr_cntrl
        }
    } else {
        set intr_pin [::hsi::get_ports $intr_pin_name]
        if { [llength $intr_pin] == 0 } {
            return $intr_cntrl
        }
        set pin_dir [hsi get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "O"] } {
          return $intr_cntrl
        }
    }
    set intr_sink_pins [get_sink_pins $intr_pin]
    foreach intr_sink $intr_sink_pins {
        set sink_periph [lindex [::hsi::get_cells -of_objects $intr_sink] 0]
        if { [llength $sink_periph ] && [is_intr_cntrl $sink_periph] == 1 } {
            lappend intr_cntrl $sink_periph
        } elseif {[llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlconcat" "ilconcat"}) } {
           set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "dout"]]
         } elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlslice" "ilslice"}) } {
            set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "Dout"]]
        } elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"util_reduced_logic" "ilreduced_logic"}) } {
            set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "Res"]]
        }  elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
		set intr [hsi::get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
		set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "$intr"]]
	} elseif {[llength $sink_periph] &&  [string match -nocase [hsi get_property IP_NAME $sink_periph] "util_ff"]} {
		set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "Q"]]
	}
    }
    return $intr_cntrl
}

proc gen_interrupt_property {drv_handle {intr_port_name ""}} {
	global is_rm_design
	# generate interrupts and interrupt-parent properties for soft IP
	proc_called_by
	if {[is_ps_ip $drv_handle]} {
		return 0
	}
	set proctype [get_hw_family]
	set slave [hsi::get_cells -hier ${drv_handle}]
	set intr_id -1
	set intc ""
	set intr_info ""
	set intc_names ""
        set intr_par ""
	if {[string_is_empty $intr_port_name]} {
		if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"]} {
			set val [hsi::get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
			set intr_port_name [hsi::get_pins -of_objects $slave -filter {TYPE==INTERRUPT&&DIRECTION==O}]
			set single [hsi get_property CONFIG.C_IRQ_CONNECTION [hsi::get_cells -hier $slave]]
			if {$single == 0} {
				dtg_warning "The axi_intc Interrupt Output connection is Bus. Change it to Single"
			}
		} else {
			set intr_port_name [hsi::get_pins -of_objects $slave -filter {TYPE==INTERRUPT}]
		}
	}
	# TODO: consolidation with get_intr_id proc
	foreach pin ${intr_port_name} {
		set connected_intc [get_intr_cntrl_name $drv_handle $pin]
		regsub -all {\{|\}} $connected_intc "" connected_intc
		if {[llength $connected_intc] == 0 } {
			if {![string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"]} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected to any interrupt controller\n\r"
			}
			continue
		}
		set connected_intc [hsi::get_cells -hier $connected_intc]
		set connected_intc_name [hsi get_property IP_NAME $connected_intc]
		set valid_gpio_list "ps7_gpio axi_gpio"
		set valid_cascade_proc "microblaze microblaze_riscv zynq zynqmp zynquplus versal zynquplusRFSOC"
		# check whether intc is gpio or other
		if {[lsearch  -nocase $valid_gpio_list $connected_intc_name] >= 0} {
			set cur_intr_info ""
			generate_gpio_intr_info $connected_intc $drv_handle $pin
		} else {
			set intc [get_interrupt_parent $drv_handle $pin]
			if { [string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0 } {
				set pins [hsi::get_pins -of_objects [::hsi::get_cells -hier -filter "NAME==$drv_handle"] -filter "NAME==irq"]
				set intc [get_interrupt_parent $drv_handle $pins]
			} else {
				set intc [get_interrupt_parent $drv_handle $pin]
			}
			if {[string_is_empty $intc] == 1} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected\n\r"
				continue
			}
			set ip_name $intc
			set intc_name [hsi get_property IP_NAME $intc]
			if {$proctype in {"zynqmp" "versal" "microblaze" "microblaze_riscv"}} {
				if {[llength $intc] > 1} {
					foreach intr_cntr $intc {
						if { [is_ip_interrupting_current_proc $intr_cntr] } {
							set intc $intr_cntr
							set intc_name [hsi get_property IP_NAME $intc]
						}
					}
				}
				set proclist "zynqmp zynquplus zynquplusRFSOC"
				if {[lsearch -nocase $proclist $proctype] >= 0 && [string match -nocase $intc_name "axi_intc"]} {
					set intc [get_interrupt_parent $drv_handle $pin]
				}
				if {[string match -nocase $proctype "versal"] && [string match -nocase $intc_name "axi_intc"] } {
					set intc [get_interrupt_parent $drv_handle $pin]
				}
			}

			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype]} {
				if { [string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"] } {
					set intr_id [get_psu_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_psu_interrupt_id $drv_handle $pin]
				}
			}
			if { [string match -nocase $proctype "zynq"]} {
				if { [string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"] } {
					set intr_id [get_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_interrupt_id $drv_handle $pin]
				}
			}

			if {[regexp "microblaze" $proctype match]} {
				if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"] } {
					set intr_id [get_psu_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_psu_interrupt_id $drv_handle $pin]
				}
			}
			if {[string match -nocase $intr_id "-1"] && ![string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"]} {
				continue
			}
			set intr_type [get_intr_type $intc $slave $pin]
			if {[string match -nocase $intr_type "-1"]} {
				continue
			}

			set cur_intr_info ""
			set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic psx_acpu_gic acpu_gic"
			global intrpin_width
			if { [string match -nocase $proctype "zynq"] }  {
				if {[string match -nocase $intc_name "ps7_scugic"] } {
					if {$intr_id > 32} {
						set intr_id [expr $intr_id - 32]
					}
					set cur_intr_info "0 $intr_id $intr_type"

				} elseif {[string match "[hsi get_property IP_NAME $intc]" "axi_intc"] } {
					set cur_intr_info "$intr_id $intr_type"
				}
			} elseif {$intc_name in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic"}} {
			    set cur_intr_info "0 $intr_id $intr_type"
			    for { set i 1 } {$i < $intrpin_width} {incr i} {
				    set intr_id_inc [expr $intr_id + $i]
				    append cur_intr_info ">, <0 $intr_id_inc $intr_type"
		            }
			} else {
				set cur_intr_info "$intr_id $intr_type"
				for { set i 1 } {$i < $intrpin_width} {incr i} {
					set intr_id_inc [expr $intr_id + $i]
					append cur_intr_info ">, <$intr_id_inc $intr_type"
				}
			}
			if {[string_is_empty $intr_info]} {
				set intr_info "$cur_intr_info"
			} else {
				append intr_info " " $cur_intr_info
			}
		}
			append intr_names " " "$pin"
			append intr_par  " " "$intc"
			lappend intc_names "$intc" "$cur_intr_info"
	}
	set node [get_node $drv_handle]
	if {[llength $intr_par] > 1 } {
		set int_ext 0
		set intc0 [lindex $intr_par 0]
		for {set i 1} {$i < [llength $intr_par]} {incr i} {
			set intc [lindex $intr_par $i]
			if {![string match -nocase $intc0 $intc]} {
				set int_ext 1
			}
		}
		if {$int_ext == 1} {
			set intc_names [string map {psu_acpu_gic gic} $intc_names]
			set ref [lindex $intc_names 0]
			append ref " [lindex $intc_names 1]>, <&[lindex $intc_names 2] [lindex $intc_names 3]>, <&[lindex $intc_names 4] [lindex $intc_names 5]>,<&[lindex $intc_names 6] [lindex $intc_names 7]>, <&[lindex $intc_names 8] [lindex $intc_names 9]"
			if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "v_hdmi_tx_ss"]} {
				set_drv_prop_if_empty $drv_handle "interrupts-extended" $ref $node reference
			}
		}
	}

	if {[string_is_empty $intr_info]} {
		return -1
	}
	set interrupt_prop_data_type intlist
	# When there is an interrupt port instead of a pin i.e. when $intrpin_width is defined,
	# the intr_info already has the combination of numbers segragated with >, <. Such formation
	# of numbers only need to be wrapped within <> and doesnt need any more formating which is
	# available with intlist.
	if {[regexp {>, <} $intr_info]} {
		set interrupt_prop_data_type special
	}
	set_drv_prop $drv_handle interrupts $intr_info $node $interrupt_prop_data_type
	if {[string_is_empty $intc_name]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]
	set intc_len [llength $intc]
	if {$intc_len > 1} {
		foreach intc_ctr $intc { 
			set intc_ctr [hsi get_property IP_NAME [hsi::get_cells -hier $intc]]
			if {$intc_ctr in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic"}} {
				set intc "gic"
			}
		}
	} else {
		if { $intc_name in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic"}} {
			set intc "gic"
		}
	}

	# Legacy Linux Device trees have "gic" or "intc" as the interrupt-name labels.
	# Need to maintain the same label reference for interrupt-parent of other nodes.
	if {[string match -nocase $intc "gic"]} {
		set intc "imux"
	} elseif {[string match -nocase $intc_name "ps7_scugic"]} {
		set intc "intc"
	}


	set rp_info {}
	if {$is_rm_design} {
		set rp_info [get_rprm_for_drv $drv_handle]
	}
	if {[llength $rp_info] != 0} {
		if {[string match -nocase $intc "imux"]} {
			set intc "gic"
		} else {
			set rp_info [get_rprm_for_drv $intc]
			if {[llength $rp_info] != 0} {
				set firmware_name [get_partial_file]
				set partial_fileName [file rootname $firmware_name]
				set partial_fileName "${partial_fileName}_"
				set intc "${partial_fileName}${intc}"
			}
		}
	}

	if {[is_pl_ip $intc]} {
		global dup_periph_handle
		if { [dict exists $dup_periph_handle $intc] } {
			set intc [dict get $dup_periph_handle $intc]
		} else {
			set intc $intc
		}
	}
	set_drv_prop $drv_handle interrupt-parent $intc $node reference
	if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "xdma"]} {
		set msi_rx_pin_en [hsi get_property CONFIG.msi_rx_pin_en [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $msi_rx_pin_en "true"]} {
			set_drv_prop_if_empty $drv_handle "interrupt-names" $intr_names $node stringlist
		}
	} else {
		set_drv_prop_if_empty $drv_handle "interrupt-names" $intr_names $node stringlist
	}
}

proc gen_reg_property {drv_handle {skip_ps_check ""} {set_node_prop 1}} {
	global apu_proc_ip
	global is_64_bit_mb
	proc_called_by
        set unit_addr [get_baseaddr ${drv_handle} no_prefix]
	if {$unit_addr == "" } {
		return 0
	}
	set ps_mapping [gen_ps_mapping]
	if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg] || [is_pl_ip $drv_handle] || ![string_is_empty $skip_ps_check]} {
	} else {
		return 0
	}
	set dts_file [set_drv_def_dts $drv_handle]
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
	} elseif {[string match -nocase $dts_file "versal.dtsi"]} {
		set treeobj "psdt"
	} else {
		set treeobj "systemdt"
	}
	set node [get_node $drv_handle]
	if {[string_is_empty $skip_ps_check]} {
		if {[is_ps_ip $drv_handle]} {
			if {[catch {set tmp [set val [$treeobj get $node "reg"]]} msg]} {
			}
		}
	}
	set ip_name  [get_ip_property $drv_handle IP_NAME]
	if {$ip_name in {"xxv_ethernet" "ddr4" "psu_acpu_gic" "mrmac" "dcmac" "axi_noc"}} {
		return
	}

	set reg ""
	set slave [hsi::get_cells -hier ${drv_handle}]
	set ip_mem_handles [hsi::get_mem_ranges $drv_handle]
	if { [string_is_empty $ip_mem_handles] } {
		set base ""
		set proctype [get_hw_family]
		set avail_param [hsi list_property [hsi::get_cells -hier $slave]]
		if {[lsearch -nocase $avail_param "CONFIG.C_BASEADDR"] >= 0 } {
			set base [string tolower [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $slave]]]
			set high [string tolower [hsi get_property CONFIG.C_HIGHADDR [hsi::get_cells -hier $slave]]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
		} elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
			set base [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave]]]
			set high [string tolower [hsi get_property CONFIG.C_S_AXI_HIGHADDR [hsi::get_cells -hier $slave]]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
		} elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_CTRL_BASEADDR"] >= 0} {
			set base [string tolower [hsi get_property CONFIG.C_S_AXI_CTRL_BASEADDR [hsi::get_cells -hier $slave]]]
			set high [string tolower [hsi get_property CONFIG.C_S_AXI_CTRL_HIGHADDR [hsi::get_cells -hier $slave]]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
		} elseif {[lsearch -nocase $avail_param "CONFIG.AXI_CTRL_BASEADDR"] >= 0} {
			# IP v_smpte_uhdsdi_tx led to this addition
			set base [string tolower [hsi get_property CONFIG.AXI_CTRL_BASEADDR [hsi::get_cells -hier $slave]]]
			set high [string tolower [hsi get_property CONFIG.AXI_CTRL_HIGHADDR [hsi::get_cells -hier $slave]]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
		}
		if {![string_is_empty $base]} {
			if {[string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype] || [string length [string trimleft $base "0x"]] > 8 || $is_64_bit_mb} {
				set reg [get_64_bit_reg $base $size]
			} else {
                if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                    dtg_warning "$drv_handle base value $base is greater than 32-bit, restricting it to 32-bit value 0xFFFFFFFF"
                    set base "0xFFFFFFFF"
                }
                if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                    dtg_warning "$drv_handle size value $size is greater than 32-bit, restricting it to 32-bit value 0xFFFFFFFF"
                    set size "0xFFFFFFFF"
                }
				set reg "$base $size"
			}

			if {$set_node_prop} {
				set_drv_prop_if_empty $drv_handle reg $reg $node hexlist
			}
		}

		return
	} elseif {[llength $ip_mem_handles] > 1 && ![string_is_empty $apu_proc_ip]} {
		# In case of PS+PL designs, Force the PS mapped memory range to appear first in list.
		# It has been observed in a design that an IP is mapped to both PS and PL processor and
		# is having more than 32bit address when mapped to PS, but the same IP's address (as
		# obtained from HSI) when mapped to PL processor is truncated to lower 32 bits and is not
		# intended to be used with PL. Baremetal always takes the first reg instance from the
		# node unless specified otherwise and having PL mapped address first leads to wrong base
		# address for such IPs in the BSP which is targeted for PS processor.
		set apu_proc [lindex [hsi get_cells -hier -filter IP_NAME==$apu_proc_ip] 0]
		set pmc_proc [hsi get_cells -hier -filter IP_NAME=="psv_pmc"]
		set ip_mem_handle_apu [lindex [hsi::get_mem_ranges -of_objects $apu_proc -filter INSTANCE==$drv_handle] 0]
		if {![string_is_empty $ip_mem_handle_apu]} {
			set ip_mem_handles [linsert $ip_mem_handles 0 "$ip_mem_handle_apu"]
		} elseif {![string_is_empty $pmc_proc]} {
			set pmc_proc_0 [lindex $pmc_proc 0]
			set ip_mem_handle_pmc [lindex [hsi::get_mem_ranges -of_objects $pmc_proc -filter INSTANCE==$drv_handle] 0]
			if {![string_is_empty $ip_mem_handle_pmc]} {
				set ip_mem_handles [linsert $ip_mem_handles 0 "$ip_mem_handle_pmc"]
			}
		}
	}
	set mem_handle_base_high_list {}
	foreach mem_handle ${ip_mem_handles} {
		set proctype [get_hw_family]

			set base [string tolower [hsi get_property BASE_VALUE $mem_handle]]
	                set ips [hsi::get_cells -hier -filter {IP_NAME == "mrmac"}]
                        if {[llength $ips]} {
                               if {[string match -nocase $base "0xa4010000"] && $ip_name == "axi_gpio"} {
                                       return
                               }
                        }
			set high [string tolower [hsi get_property HIGH_VALUE $mem_handle]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]


			if {"$base $high" in $mem_handle_base_high_list} {
				continue
			} else {
				lappend mem_handle_base_high_list "$base $high"
			}

			set new_reg ""
			if {[string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype] || [string length [string trimleft $base "0x"]] > 8 || $is_64_bit_mb} {
				set new_reg [get_64_bit_reg $base $size]
			} else {
                if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                    dtg_warning "$drv_handle base value $base is greater than 32-bit, restricting it to 32-bit value 0xFFFFFFFF"
                    set base "0xFFFFFFFF"
                }
                if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                    dtg_warning "$drv_handle size value $size is greater than 32-bit, restricting it to 32-bit value 0xFFFFFFFF"
                    set size "0xFFFFFFFF"
                }

				set new_reg "$base $size"
			}
			if {[string_is_empty $reg]} {
				set reg $new_reg
			} else {
				set reg "$reg $new_reg"
			}
	}
	if {$set_node_prop} {
		set_drv_prop_if_empty $drv_handle reg $reg $node hexlist
	}
	set_drv_prop_if_empty $drv_handle reg $reg $node hexlist
	set ip_name [get_ip_property $drv_handle IP_NAME]
	if {[string match -nocase $ip_name "psv_pciea_attrib"]} {
		set ranges " 0x02000000 0x00000000 0xe0000000 0x0 0xe0000000 0x00000000 0x10000000>, \n\t\t\t      <0x43000000 0x00000080 0x00000000 0x00000080 0x00000000 0x00000000 0x80000000"
		add_prop $node "ranges" $ranges hexlist "pcw.dtsi"
	}
	return $reg
}

proc check_64_base {reg base size} {
	set high_base 0xdeadbeef
	set low_base  0
	if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		set temp $base
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_base "0x[string range $temp $rem $len]"
		set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_base [format 0x%08x $low_base]
	}
	set len [llength $reg]
	switch $len {
		"4" {
			set base_index0 [lindex $reg 0]
			set base_index1 [lindex $reg 1]
			if {$high_base != 0xdeadbeef} {
				if {$base_index0 == $low_base && $base_index1 == $high_base} {
					return true
				}
			} else {
				if {$base_index1 == $base} {
					return true
				}
			}
		}
		"8" {
			set base_index0 [lindex $reg 0]
			set base_index1 [lindex $reg 1]
			set base_index4 [lindex $reg 4]
			set base_index5 [lindex $reg 5]
			if {$high_base != 0xdeadbeef} {
				if {$base_index0 == $low_base && $base_index1 == $high_base} {
					return true
				}
				if {$base_index4 == $low_base && $base_index5 == $high_base} {
					return true
				}
			} else {
				if {$base_index1 == $base} {
					return true
				}
				if {$base_index5 == $base} {
					return true
				}
			}
		}
		"12" {
			set base_index0 [lindex $reg 0]
			set base_index1 [lindex $reg 1]
			set base_index4 [lindex $reg 4]
			set base_index5 [lindex $reg 5]
			set base_index8 [lindex $reg 8]
			set base_index9 [lindex $reg 9]
			if {$high_base != 0xdeadbeef} {
				if {$base_index0 == $low_base && $base_index1 == $high_base} {
					return true
				}
				if {$base_index4 == $low_base && $base_index5 == $high_base} {
					return true
				}
				if {$base_index8 == $low_base && $base_index9 == $high_base} {
					return true
				}
			} else {
				if {$base_index1 == $base} {
					return true
				}
				if {$base_index5 == $base} {
					return true
				}
				if {$base_index9 == $base} {
					return true
				}
			}
		}
	}
}

proc check_base {reg base size} {
	set len [llength $reg]
	switch $len {
		"2" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			if {$base_index0 == $base} {
				return true
			}
		}
		"4" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			if {$base_index0 == $base || $base_index1 == $base} {
					return true
			}
		}
		"6" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base} {
					return true
			}
		}
		"8" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base} {
					return true
			}
		}
		"10" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base} {
					return true
			}
		}
		"12" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			set base_index5 [lindex $reg 10]
			set size_index5 [lindex $reg 11]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base || $base_index5 == $base} {
					return true
			}
		}
		"14" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			set base_index5 [lindex $reg 10]
			set size_index5 [lindex $reg 11]
			set base_index6 [lindex $reg 12]
			set size_index6 [lindex $reg 13]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base || $base_index5 == $base || $base_index6 == $base} {
					return true
			}
		}
		"16" {
			set base_index0 [lindex $reg 0]
			set size_index0 [lindex $reg 1]
			set base_index1 [lindex $reg 2]
			set size_index1 [lindex $reg 3]
			set base_index2 [lindex $reg 4]
			set size_index2 [lindex $reg 5]
			set base_index3 [lindex $reg 6]
			set size_index3 [lindex $reg 7]
			set base_index4 [lindex $reg 8]
			set size_index4 [lindex $reg 9]
			set base_index5 [lindex $reg 10]
			set size_index5 [lindex $reg 11]
			set base_index6 [lindex $reg 12]
			set size_index6 [lindex $reg 13]
			set base_index7 [lindex $reg 14]
			set size_index7 [lindex $reg 15]
			if {$base_index0 == $base || $base_index1 == $base || $base_index2 == $base || $base_index3 == $base || $base_index4 == $base || $base_index5 == $base || $base_index6 == $base || $base_index7 == $base} {
					return true
			}
		}
	}
}

proc gen_compatible_string {drv_handle} {
        set vlnv [split [hsi get_property VLNV [hsi::get_cells -hier $drv_handle]] ":"]
        set name [lindex $vlnv 2]
        if {[string_is_empty $name]} {
                return 0
        }
        if {[string match -nocase $name "psv_fpd_smmutcu"]} {
                set name "psv_fpd_maincci"
        }
        set ver [lindex $vlnv 3]
        if {[string_is_empty $ver]} {
                set comp_prop "xlnx,${name}"
        } else {
                set comp_prop "xlnx,${name}-${ver}"
        }
        regsub -all {_} $comp_prop {-} comp_prop
        return $comp_prop
}

proc gen_compatible_property {drv_handle} {
	proc_called_by
	set dts_file [set_drv_def_dts $drv_handle]
	set ip [hsi::get_cells -hier $drv_handle]
	set ip_name  [get_ip_property $drv_handle IP_NAME]
	if {[string match -nocase $ip_name "axi_noc"]} {
		return
	}
        # TODO: check if the base address is correct
        set unit_addr [get_baseaddr ${ip} no_prefix]
	if {$unit_addr == "-1"} {
		return 0
	}
	set tcm_addresses "ffe00000 ffe10000 ffe20000 ffe30000 ffe90000 ffeb0000"
	set ps_mapping [gen_ps_mapping]
	if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg] || [is_pl_ip $drv_handle]} {
	} else {
		return 0
	}
	if {$unit_addr == "-1"} {
		return 0
	}
        if {![catch {set tmp [dict get $ps7_mapping $unit_addr label]} msg] && [is_ps_ip $drv_handle]} {
			return 0
	}
	set reg ""
	set slave [hsi::get_cells -hier ${drv_handle}]
	set proctype [hsi get_property IP_TYPE $slave]
	if {[string match -nocase $proctype "processor"] && ![string match -nocase $ip_name "microblaze"] &&
		![string match -nocase $ip_name "microblaze_riscv"] && ![string match -nocase $ip_name "tmr_inject"]} {
		return 0
	}
	set comp_prop [gen_compatible_string $slave]
	if {[string match -nocase $ip_name "psv_pciea_attrib"]} {
		set index [string index $drv_handle end]
		set comp_prop "${comp_prop}${index}"
	}
	regsub -all {_} $comp_prop {-} comp_prop
	if {[string match -nocase $proctype "processor"] && ![string match -nocase $ip_name "tmr_inject"]} {
		set proctype [get_hw_family]
		set bus_name [detect_bus_name $drv_handle]
		set count [get_microblaze_nr $drv_handle]
		set rt_node [create_node -n "cpus_${ip_name}" -l "cpus_${ip_name}_${count}" -u $count -d "pl.dtsi" -p $bus_name]
		set node [create_node -n "cpu" -l "$drv_handle" -u $count -d "pl.dtsi" -p $rt_node]
		add_prop $node compatible "$comp_prop xlnx,${ip_name}" stringlist "pl.dtsi"
	} else {
		set node [get_node $drv_handle]
		set_drv_prop_if_empty $drv_handle compatible $comp_prop $node stringlist
		if {[lsearch -nocase $tcm_addresses $unit_addr] >= 0} {
			pcwdt append $node compatible "\ \, \"mmio-sram\""
		}
	}

}

proc is_property_set {value} {
       if {[string compare -nocase $value "true"] == 0} {
               return 1
       }
       return 0
}

proc ip2drv_prop {ip_name prop_name_list} {
	set ip [hsi::get_cells -hier $ip_name]
	set emac [hsi get_property IP_NAME $ip]
	set node [get_node $ip_name]
	set pcieattrib_num "CONFIG.C_CPM_PCIE0_AXIBAR_NUM"
	set pcieattrib "CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_0 CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_1 CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_0 CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_1"
	foreach ip_prop_name $prop_name_list {
		if { $emac == "axi_ethernet1"} {
			# remove CONFIG.
			set drv_prop_name $ip_prop_name
			regsub -all {CONFIG.} $drv_prop_name {xlnx,} drv_prop_name
			regsub -all {_} $drv_prop_name {-} drv_prop_name
			set drv_prop_name [string tolower $drv_prop_name]
			add_prop $node $drv_prop_name hexint "pl.dtsi"
			continue
		}

		if { $emac == "mmi_dc"} {
			continue
		}

		set ignore_ip_props "CONFIG.C_AXIS_SIGNAL_SET CONFIG.C_USE_BRAM_BLOCK CONFIG.C_ALGORITHM \
			CONFIG.C_AXI_TYPE CONFIG.C_INTERFACE_TYPE CONFIG.C_AXI_SLAVE_TYPE CONFIG.device_port_type \
			CONFIG.C_AXI_WRITE_BASEADDR_SLV CONFIG.C_AXI_WRITE_HIGHADDR_SLV CONFIG.C_PVR_USER1 \
			CONFIG.Component_Name CONFIG.C_FAMILY CONFIGURABLE"
		if {[lsearch $ignore_ip_props $ip_prop_name] >= 0} {
			continue
		}

		if {[lsearch $pcieattrib_num $ip_prop_name] >= 0} {
			set drv_prop_name "xlnx,axibar-num"
		} elseif {[lsearch $pcieattrib $ip_prop_name] >= 0} {
			set index [string index $ip_prop_name end]
			if {[string match -nocase $ip_prop_name "CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_0"] || [string match -nocase $ip_prop_name "CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_1"]} {
				set drv_prop_name "xlnx,axibar-${index}"
			} else {
				set drv_prop_name "xlnx,axibar-highaddr-${index}"
			}
		} else {
			# remove CONFIG.C_
			set drv_prop_name $ip_prop_name
			regsub -all {CONFIG.C_} $drv_prop_name {xlnx,} drv_prop_name
			regsub -all {CONFIG.c_} $drv_prop_name {xlnx,} drv_prop_name
			regsub -all {^CONFIG.} $drv_prop_name {xlnx,} drv_prop_name
			regsub -all {_} $drv_prop_name {-} drv_prop_name
			set drv_prop_name [string tolower $drv_prop_name]
			if {[string match -nocase $drv_prop_name "xlnx,include-sg"]} {
				continue
			}
		}

		set prop [hsi get_property $ip_prop_name [hsi::get_cells -hier $ip_name]]
		if {[regexp -nocase {0x([0-9a-f])} $prop match]} {
			if {[string first $match $prop]} {
				set type "string"
			} else {
				set type "hexint"
			}
		} elseif {[string is integer -strict $prop]} {
			if {[regexp -nocase {([a-f])} $prop]} {
			   set type "hexint"
			} else {
			   set type "int"
			}
		} elseif {[string is boolean -strict $prop]} {
			set type "boolean"
		} elseif {[string is wordchar -strict $prop]} {
			set type "string"
		} else {
			set type "mixed"
		}

		if {[string match -nocase $emac "psv_pciea_attrib"] && [string match -nocase $ip_prop_name "CONFIG.C_CPM_PCIE0_PORT_TYPE"]} {
			add_prop $node "xlnx,device-port-type" $prop int [set_drv_def_dts $ip_name]
		} else {
			# For boolean property type if property value is false don't generate the property.
			if { $prop == "false" && $type == "boolean"} {
			} else {
				add_cross_property $ip $ip_prop_name $ip_name $drv_prop_name $node $type
			}
		}
	}
}

# Video subsystems can have IP cores in it. Some examples of such IP cores are
# axi_vdma, axi_timer, axi_gpio etc. These IP cores are not visible from the
# processor and dont use the AXI Bus. "xlnx,is-hierarchy" is the property
# which will differentiate such IP subcores from the generic peripherals.

proc set_hier_info {drv_handle} {
	set ip_type [get_ip_property $drv_handle IP_TYPE]
	if {[string match -nocase $ip_type "PERIPHERAL"]} {
		set mem_maps [hsi::get_mem_ranges [hsi get_cells -hier $drv_handle]]
		if {[llength $mem_maps] == 0} {
			set node [get_node $drv_handle]
			add_prop $node "xlnx,is-hierarchy" boolean [set_drv_def_dts $drv_handle]
		}
	}
}

# FIXME: Above proc seems to be not working. Replace that with new proc.
# Keep the proc for this release to avoid unforeseen usages.
proc set_updated_hier_info {hier_mapped_drv_list} {
	foreach drv_handle $hier_mapped_drv_list {
		set node [get_node $drv_handle]
		if {$node == ""} {
			continue
		} else {
			add_prop $node "xlnx,is-hierarchy" boolean [set_drv_def_dts $drv_handle]
		}
	}
}

proc gen_drv_prop_from_ip {drv_handle} {
	# check if we should generating the ip properties or not
	set ip_name [get_ip_property $drv_handle IP_NAME] 
	set prop_name_list [default_parameters $drv_handle]
	ip2drv_prop $drv_handle $prop_name_list
	set_hier_info $drv_handle
}

proc remove_duplicates {ip_handle} {
	set par_handles [get_ip_conf_prop_list $ip_handle "CONFIG.*"]
	set dictval [dict create]
	foreach prop $par_handles {
		set inner ""
		if {[regexp -nocase "CONFIG.C_.*" $prop match]} {
			set temp [regsub -all {CONFIG.C_} $prop $inner]
			dict set dictval [string tolower $temp] $prop
		}
		if {[regexp -nocase "CONFIG.c_.*" $prop match]} {
                        set temp [regsub -all {CONFIG.c_} $prop $inner]
                        dict set dictval [string tolower $temp] $prop
                }
	}
	foreach prop $par_handles {
		set temp [regsub -all {^CONFIG.} $prop ""]
		set temp [regsub -all {^C_} $temp ""]
		set temp [regsub -all {^c_} $temp ""]
		set temp [string tolower $temp]
		if {![dict exists $dictval $temp]} {
			dict set dictval $temp $prop
		}
	}
	set values [lsort -nocase -unique [dict keys $dictval]]
	set tempvalues {}
	foreach val $values {
		lappend tempvalues [dict get $dictval $val]
	}
	return $tempvalues
}

# based on libgen dtg
proc default_parameters {ip_handle {dont_generate ""}} {
	proc_called_by
	set par_handles [remove_duplicates $ip_handle]
	set valid_prop_names {}
	set ps_ip [is_ps_ip $ip_handle]
	foreach par $par_handles {
        if {[string first " " $par] != -1} {
            puts "warning: property $par of $ip_handle has space in it, skipping its generation"
            continue
        }
		if { $ps_ip } {
			set tmp_par $par
		} else {
			regsub -all {CONFIG.} $par {} tmp_par
		}
		# Ignore some parameters that are always handled specially
		
		if {$ps_ip} {
			switch -glob $tmp_par {
				$dont_generate - \
				"*BASEADDR" - \
				"*HIGHADDR" - \
				"*INTERCONNECT_?_AXI*" { }
				default {
					lappend valid_prop_names $par
				}
			}
		} else {
			switch -glob $tmp_par {
				$dont_generate - \
				"INSTANCE" - \
				"C_INSTANCE" - \
				"*BASEADDR" - \
				"*HIGHADDR" - \
				"C_SPLB*" - \
				"C_DPLB*" - \
				"C_IPLB*" - \
				"C_PLB*" - \
				"M_AXI*" - \
				"C_M_AXI*" - \
				"S_AXI_ADDR_WIDTH" - \
				"C_S_AXI_ADDR_WIDTH" - \
				"S_AXI_DATA_WIDTH" - \
				"C_S_AXI_DATA_WIDTH" - \
				"S_AXI_ACLK_FREQ_HZ" - \
				"C_S_AXI_ACLK_FREQ_HZ" - \
				"S_AXI_LITE*" - \
				"C_S_AXI_LITE*" - \
				"S_AXI_PROTOCOL" - \
				"C_S_AXI_PROTOCOL" - \
				"*INTERCONNECT_?_AXI*" - \
				"*S_AXI_ACLK_PERIOD_PS" - \
				"M*_AXIS*" - \
				"C_M*_AXIS*" - \
				"S*_AXIS*" - \
				"C_S*_AXIS*" - \
				"PRH*" - \
				"C_FAMILY" - \
				"FAMILY" - \
				"*CLK_FREQ_HZ" - \
				"*ENET_SLCR_*Mbps_DIV?" - \
				"HW_VER" { } \
				default {
					lappend valid_prop_names $par
				}
			}
		}
	}
	return $valid_prop_names
}

proc ps7_reset_handle {drv_handle reset_pram conf_prop} {
	set src_ip -1
	set value -1
	set ip [hsi::get_cells -hier $drv_handle]
	set value [hsi get_property ${reset_pram} $ip]
	# workaround for reset not been selected and show as "<Select>"
	regsub -all "<Select>" $value "" value
	if {[llength $value]} {
		# if MIO, assume gpio0 (bad assumption as this needs to match zynq-7000.dtsi)
		if {[regexp "^MIO" $value matched]} {
			# switch with kernel version
			global env
			set path $env(CUSTOM_SDT_REPO)

			#set drvname [get_drivers $drv_handle]
			#
			#set common_file "$path/device_tree/data/config.yaml"
			set common_file [file join [file dirname [dict get [info frame 0] file]] "config.yaml"]
			set kernel_ver [get_user_config $common_file -kernel_ver]

			switch -exact $kernel_ver {
				default {
					set src_ip "gpio0"
				}
			}
		}
		regsub -all "MIO( |)" $value "" value
		if {$src_ip != "-1"} {
			if {$value != "-1" && [llength $value] !=0} {
				regsub -all "CONFIG." $conf_prop "" conf_prop
				set node [get_node $drv_handle]
				set_drv_property $drv_handle ${conf_prop} "$src_ip $value 0" $node reference
			}
		}
	} else {
		dtg_warning "$drv_handle: No reset found"
		return -1
	}
}

proc gen_peripheral_nodes {drv_handle {node_only ""}} {
	# Check if the peripheral is in Secure or Non-secure zone
	global node_dict
	global cur_hw_design
	global node_name_dict
	proc_called_by
	set status_enable_flow 0
	set ip [hsi::get_cells -hier $drv_handle]
	# TODO: check if the base address is correct
	set unit_addr [get_baseaddr ${ip} no_prefix]
	if { [string equal $unit_addr "-1"] } {
		return 0
	}
	set proc_type [get_hw_family]
	set label $drv_handle
	set label_len [string length $label]
	if {$label_len >= 31} {
		# As per the device tree specification the label length should be maximum of 31 characters
		dtg_verbose "the label \"$label\" length is $label_len characters which is greater than default 31 characters as per DT SPEC...user need to fix the label\n\r"
	}
	set dev_type ""
	if {[string_is_empty $dev_type] == 1} {
		set ps_mapping [gen_ps_mapping]
		if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg] || [is_pl_ip $drv_handle]} {
			#In a use case, a pl_ip is labelled similar to an existing one in a dtsi file. This leads to a
			#duplicate node issue and sdtgen fails because of that. Hence add a check to append pl_ips
			#labels properly to avoid such issues.
			if {[is_pl_ip $drv_handle]} {
				foreach {base_addr entry} $ps_mapping {
					if {[dict exists $entry label]&& \
						[lindex [split [dict get $entry label] ": "] 0]==$drv_handle} {
						set label "pl_$drv_handle"
						break
					}
				}
			}
			set dev_type [get_ip_property $ip IP_NAME]
			set hier_name [get_ip_property $ip HIER_NAME]
			if {![string_is_empty $hier_name] && [llength [split $hier_name "/"]] > 1} {
				set dev_type $ip
			}
		} else {
			set value [split $tmp ": "]
			set label [lindex $value 0]
			set dev_type [lindex $value 2]
		} 
	}
	if {[string match -nocase $proc_type "versal"] } {
		set ip_type [hsi get_property IP_NAME $ip]
		if {[string match -nocase $ip_type "psv_cpm_slcr"]} {
			set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
			if {[llength $versal_periph]} {
				set avail_param [hsi list_property [hsi::get_cells -hier $versal_periph]]
				if {[lsearch -nocase $avail_param "CONFIG.CPM_PCIE0_PORT_TYPE"] >= 0} {
					set val [hsi get_property CONFIG.CPM_PCIE0_PORT_TYPE [hsi::get_cells -hier $versal_periph]]
					if {[string match -nocase $val "Root_Port_of_PCI_Express_Root_Complex"]} {
						#For Root port device tree entry should be set Okay
					} else {
						# For Non-Root port(PCI_Express_Endpoint_device) there should not be any device tree entry in DTS
						return 0
					}
				}
			}
		}
	}
	# TODO: more ignore ip list?
	set ip_type [hsi get_property IP_NAME $ip]
	set node [get_node $drv_handle]
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set ignore_list "PERIPHERAL axi_noc mig_7series"
	if {[string match -nocase $ip_type "psu_pcie"]} {
		set pcie_config [hsi get_property CONFIG.C_PCIE_MODE [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $pcie_config "Endpoint Device"]} {
			add_prop $node "xlnx,port-type" 0x0 hexint "pcw.dtsi" 1
		} else {
			add_prop $node "xlnx,port-type" 0x1 hexint "pcw.dtsi" 1
		}
		if {$node == 0} {
			return
		}
		add_prop $node "xlnx,dma-addr" 0xfd0f0000 hexint "pcw.dtsi" 1
	}
	if {[regexp "pmc_*" $ip_type match]} {
	#	return 0
	}
	if {[lsearch $ignore_list $ip_type] >= 0  \
		} {
		return 0
	}
	set default_dts [set_drv_def_dts $drv_handle]
	if {[string match -nocase $default_dts "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $default_dts "pl.dtsi"]} {
		set treeobj "pldt"
	} elseif {[string match -nocase $default_dts "versal.dtsi"]} {
		set treeobj "psdt"
	} else {
		set treeobj "systemdt"
	}
	set bus_node [add_or_get_bus_node $ip $default_dts]
	set status_enable_flow 0
	set status_disabled 0
	set status_chk 1
	set ps_mapping [gen_ps_mapping]
	if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg]} {
		if {[string match -nocase $treeobj "pcwdt"]} {
			set bus_node "&amba"
		}
	} elseif {[string match -nocase $treeobj "pcwdt"]} {
		set bus_node "root"
	}
	if {[is_ps_ip $drv_handle]} {
		set node [get_node $drv_handle]
		set values [$treeobj getall $node]
		set status_prop ""
		if {[catch {set tmp [set status_prop [$treeobj get $node "status"]]} msg]} {
		}
		if {[string match -nocase $status_prop ""]} {
			set status_enable_flow 0
			set status_chk 0
		}
		
		if {[string match -nocase $status_chk "1"]} {
			set status_enable_flow 1
		}
		if {[string match -nocase $status_prop "\ \"disabled\""]} {
			set status_disabled 1
		}
		set ps_mapping [gen_ps_mapping]
		if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg]} {
			set status_disabled 0
		}
	}
	if {$status_enable_flow} {
		if {[string match -nocase $ip_type "psv_rcpu_gic"] } {
			# Base address is same for gic and rpu_gic, hence set label forcefully
			# other wise we will get lable as "gic" which is same as acpu_gic label
			set label "gic_r5"
		} elseif {$ip_type in {"psx_rcpu_gic" "rcpu_gic"} } {
			set label "gic_r52"
		} else {
		}

		# check if it has status property
		set rt_node [get_node $drv_handle]
		if {$ip_type in {"psv_rcpu_gic" "psu_rcpu_gic"}} {
			set node [create_node -n "&gic_r5" -d "pcw.dtsi" -p root]
			add_prop $node "status" "okay" string $default_dts
			# HSI reports the same address for Versal GIC A72 and R5.
			# This is leading to missing ip-name and name property from gic_r5 node for versal.
			# Add them forcibly here.
			if {$ip_type == "psv_rcpu_gic"} {
				add_prop $node "xlnx,ip-name" $ip_type string $default_dts
				# There are designs in Vivado suite where all PS Wizard
				# IPs are having multiple entries, one starting with pmcps_0_<ip>
				# and one with ps_wizard_0_pmcps_0. This leads to 2 RPU GICs in
				# design with different names. Below call overwrites the NAME to
				# avoid syntax errors while adding prop.
				add_prop $node "xlnx,name" $drv_handle string $default_dts 1
			}
		} elseif {$ip_type in {"psx_rcpu_gic" "rcpu_gic"}} {
			set node [create_node -n "&gic_r52" -d "pcw.dtsi" -p root]
			add_prop $node "status" "okay" string $default_dts
		}
		if {[string match -nocase $rt_node "&dwc3_0"]} {
				if {[is_zynqmp_platform $proc_type]} {
					set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
					set avail_param [hsi list_property [hsi::get_cells -hier $zynq_periph]]
					if {[lsearch -nocase $avail_param "CONFIG.PSU__USB0__PERIPHERAL__ENABLE"] >= 0} {
						set value [hsi get_property CONFIG.PSU__USB0__PERIPHERAL__ENABLE [hsi::get_cells -hier $zynq_periph]]
						if {$value == 1} {
							if {[lsearch -nocase $avail_param "CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE"] >= 0} {
								set val [hsi get_property CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE [hsi::get_cells -hier $zynq_periph]]
								if {$val == 0} {
									add_prop $rt_node "maximum-speed" "high-speed" stringlist $default_dts
									add_prop "${rt_node}" "snps,dis_u2_susphy_quirk" boolean $default_dts
									add_prop "${rt_node}" "snps,dis_u3_susphy_quirk"  boolean $default_dts
									add_prop "${rt_node}" "/delete-property/ phy-names" boolean $$default_dts
									add_prop "${rt_node}" "/delete-property/ phys" boolean $$default_dts
								}
							}
						}
					}
				}
		}
		if {[string match -nocase $rt_node "&dwc3_1"]} {
				if {[is_zynqmp_platform $proc_type]} {
					set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
					set avail_param [hsi list_property [hsi::get_cells -hier $zynq_periph]]
					if {[lsearch -nocase $avail_param "CONFIG.PSU__USB1__PERIPHERAL__ENABLE"] >= 0} {
						set value [hsi get_property CONFIG.PSU__USB1__PERIPHERAL__ENABLE [hsi::get_cells -hier $zynq_periph]]
						if {$value == 1} {
							if {[lsearch -nocase $avail_param "CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE"] >= 0} {
								set val [hsi get_property CONFIG.PSU__USB3_1__PERIPHERAL__ENABLE [hsi::get_cells -hier $zynq_periph]]
								if {$val == 0} {
									add_prop $rt_node "maximum-speed" "high-speed" stringlist $default_dts
									add_prop "${rt_node}" "snps,dis_u2_susphy_quirk" boolean $default_dts
									add_prop "${rt_node}" "snps,dis_u3_susphy_quirk"  boolean $default_dts
									add_prop "${rt_node}" "/delete-property/ phy-names" boolean $$default_dts
									add_prop "${rt_node}" "/delete-property/ phys" boolean $$default_dts
								}
							}
						}
					}
				}
		}
		if {$status_disabled} {
			if {0} {
			if {[string match -nocase $ip_type "psu_smmu_gpv"]} {
				return
			}
			if {![string match -nocase $proc_type "psu_pmu"] && [string match -nocase $unit_addr "ffcb0000"]} {
				return
			}
			if {[string match -nocase $proc_type "psu_cortexa53"] && [string match -nocase $ip_type "psu_rcpu_gic"]} {
				return
			}
			if {[string match -nocase $proc_type "psu_cortexr5"] && [string match -nocase $ip_type "psu_acpu_gic"]} {
				return
			}
			if {[string match -nocase $proc_type "psv_cortexa72"] && [string match -nocase $ip_type "psv_rcpu_gic"]} {
				return
			}
			if {[string match -nocase $proc_type "psv_cortexr5"] && [string match -nocase $ip_type "psv_acpu_gic"]} {
				return
			}
			if {$proc_type in {"psx_cortexa78" "cortexa78"} && $ip_type in {"psx_rcpu_gic" "rcpu_gic"}} {
				return
			}
			if {$proc_type in {"psx_cortexr52" "cortexr52"} && $ip_type in {"psx_acpu_gic" "acpu_gic"}} {
				return
			}
			}
			add_prop $rt_node "status" "okay" string $default_dts 
		}
	} else {
		if {[string match -nocase $ip_type "tsn_endpoint_ethernet_mac"]} {
			set rt_node [create_node -n tsn_endpoint_ip_0 -l tsn_endpoint_ip_0 -d $default_dts -p $bus_node] 
		} else {
			set valid_proclist "psv_cortexa72 psv_cortexr5 psu_cortexa53 psu_cortexr5 psu_pmu psv_pmc psv_psm ps7_cortexa9 psx_cortexa78 psx_cortexr52 psx_pmc psx_psm microblaze microblaze_riscv cortexa78 cortexr52 pmc psm"
			if {[lsearch $valid_proclist $ip_type] >= 0} {
				set rt_node [get_node $drv_handle]
			} else {
				switch $dev_type {
					"psv_fpd_smmutcu" { set dev_type "psv_fpd_maincci" }
					"axi_intc" { set dev_type "interrupt-controller" }
					"axi_cdma" - "axi_dma" - "axi_vdma" { set dev_type "dma" }
					"axi_ethernet" - "axi_ethernet_buffer" - "axi_10g_ethernet" - "xxv_ethernet" - "usxgmii" - "ethernet_1_10_25g" - "axi_ethernetlite" {
						set dev_type "ethernet"
					}
					"axi_gpio" { set dev_type "gpio" }
					"axi_iic" { set dev_type "i2c" }
					"axi_pcie" - "axi_pcie3" - "qdma" - "xdma" - "pcie_dma_versal" {
						set dev_type "axi-pcie"
					}
					"axi_timebase_wdt" { set dev_type "watchdog" }
					"sdfec" { set dev_type "sd-fec" }
					"mdm" - "axi_uartlite" - "axi_uart16550" { set dev_type "serial" }
					"axi_timer" { set dev_type "timer" }

					"axi_bram_ctrl" {
                        # Below BRAM controller entry is a workaround. Encountered a design in Vivado
                        # test suite where there were 2 bram controllers, both starting at same
                        # address 0. None of them were mapped to any processor, their MASTER INTERFACEs
                        # were PCI interfaces. This was leading to duplicate node names (axi_bram_ctrl@0)
                        # with different labels in SDT.
                        set dev_type $ip
                    }
				}
				# Device tree node labels must be unique for each node_name.
				# If the current node_name already exists in node_name_dict,
				# update dev_type to the IP's NAME property to avoid duplication.
				set node_str "${dev_type}@${unit_addr}"
				if { [dict exists $node_name_dict $node_str] } {
					set read_handle [dict get $node_name_dict $node_str]
					if {$read_handle != $drv_handle} {
						set dev_type [get_ip_property $drv_handle NAME]
						set node_str "${dev_type}@${unit_addr}"
					}
				}
				set t [get_ip_property $drv_handle IP_NAME]
				set rt_node [create_node -n ${dev_type} -l ${label} -u ${unit_addr} -d ${default_dts} -p $bus_node]
				dict set node_name_dict $node_str $drv_handle
			}
		}

		add_prop $rt_node "status" "okay" string $default_dts
		add_prop $rt_node "xlnx,ip-name" $ip_type string $default_dts
		add_prop $rt_node "xlnx,name" $drv_handle string $default_dts
	}

	# generate_mb_ccf_node is not using drv_handle argument at all
	# generate_mb_ccf_node $drv_handle
	generate_cci_node $drv_handle $rt_node

	dict set node_dict $cur_hw_design $drv_handle $rt_node
	return $rt_node
}

proc detect_bus_name {ip_drv} {
	proc_called_by
	#puts "# [lindex [info level -1] 0] #>> called by [lindex [info level -2] 0]"
	# FIXME: currently use single bus assumption
	# TODO: detect bus connection
	# 	zynq: uses amba base zynq-7000.dtsi
	#		pl ip creates amba_pl
	# 	mb: detection is required (currently always call amba_pl)
	set valid_buses [hsi::get_cells -hier -filter { IP_TYPE == "BUS" && IP_NAME != "axi_protocol_converter" && IP_NAME != "lmb_v10"}]

	set valid_proc_list "ps7_cortexa9 psu_cortexa53 psv_cortexa72 psv_cortexr5 psv_pmc psu_pmu psu_cortexr5 psx_cortexa78 psx_cortexr52 psx_pmc psx_psm cortexa78 cortexr52 pmc psm"
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
		if {[is_pl_ip $ip_drv]}  {
			# create the parent_node for pl.dtsi
			set default_dts [set_drv_def_dts $ip_drv]
			set root_node [create_node -n "amba_pl" -l "amba_pl" -d ${default_dts} -p root]
			return "amba_pl: amba_pl"
		}
		if {$ip_drv in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic"}} {
			return "amba_apu: apu-bus"
		}
		if {$ip_drv in {"psu_rcpu_gic" "psv_rcpu_gic" "psx_rcpu_gic" "rcpu_gic"}} {
                        return "amba_rpu: rpu-bus"
                }
		set ipname ""
		if {[catch {set ipname [hsi get_property IP_NAME [hsi::get_cells -hier $ip_drv]]} msg]} {
		}
		set valid_xppu "psv_lpd_xppu psv_pmc_xppu psv_pmc_xppu_npi psu_lpd_xppu"
		if {[lsearch $valid_xppu $ipname] >= 0} {
			return "amba_xppu: indirect-bus@1"
		}
		return "amba: axi"
}

proc get_afi_val {val} {
	set afival ""
	switch $val {
		"128" {
			set afival 0
		} "64" {
			set afival 1
		} "32" {
			set afival 2
		} default {
			set afival ""
			dtg_warning "invalid value:$val"
		}
	}
	return $afival
}

proc get_max_afi_val {val prop_name} {
	set max_afival ""
	if {[string match $prop_name "CONFIG.C_MAXIGP2_DATA_WIDTH"]} {
		switch $val {
			"128" {
				set max_afival 0x200
			} "64" {
				set max_afival 0x100
			} "32" {
				set max_afival 0x000
			} default {
				set max_afival ""
				dtg_warning "invalid value:$val"
			}
		}
	} else {
		switch $val {
			"128" {
				set max_afival 2
			} "64" {
				set max_afival 1
			} "32" {
				set max_afival 0
			} default {
				set max_afival ""
				dtg_warning "invalid value:$val"
			}
		}
		if {![string_is_empty $max_afival]} {
			if {[string match $prop_name "CONFIG.C_MAXIGP0_DATA_WIDTH"]} {
				set max_afival [expr $max_afival <<8]
			} elseif {[string match $prop_name "CONFIG.C_MAXIGP1_DATA_WIDTH"]} {
				set max_afival [expr $max_afival << 10]
			}
		}
	}
	return $max_afival
}

proc get_axi_datawidth {val} {
	set data_width ""
	switch $val {
		"32" {
			set data_width 1
		} "64" {
			set data_width 0
		} default {
			dtg_warning "invalid data_width:$val"
		}
	}
	return $data_width
}

proc add_or_get_bus_node {ip_drv dts_file} {
	global is_64_bit_mb
	proc_called_by
	set bus_name [detect_bus_name $ip_drv]
	dtg_debug "bus_name: $bus_name"
	dtg_debug "bus_label: $bus_name"
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set proctype [get_hw_family]
	set bus_node $bus_name
	if {[string match -nocase $bus_node "amba_pl: amba_pl"]} {
		if {[is_zynqmp_platform $proctype] || [string match -nocase $proctype "versal"] || $is_64_bit_mb} {
			set addr_cells 2
			set size_cells 2
		} else {
			set addr_cells 1
			set size_cells 1
		}
		if {[catch {set val [pldt get $bus_node #address-cells]} msg]} {
			add_prop $bus_node #address-cells $addr_cells int $dts_file
			add_prop $bus_node #size-cells $size_cells int $dts_file
			add_prop $bus_node compatible "simple-bus" string $dts_file
			add_prop $bus_node ranges boolean $dts_file
		}
	}
	return $bus_node
}

proc cortexa9_opp_gen {drv_handle} {
	proc_called_by
	# generate opp overlay for cpu
	if {[catch {set cpu_max_freq [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ [hsi::get_cells -hier $drv_handle]]} msg]} {
		set cpu_max_freq ""
	}
	if {[string_is_empty ${cpu_max_freq}]} {
		dtg_warning "DTG failed to detect the CPU clock frequency"
		return -1
	}
	set cpu_max_freq [expr int([expr $cpu_max_freq/1000])]
	set processor [get_sw_processor]
	set default_dts [set_drv_def_dts $processor]
	set root_node [add_or_get_dt_node -n / -d ${default_dts}]

	set cpu_root_node [add_or_get_dt_node -n cpus -d ${default_dts} -p $root_node]
	set cpu_node [add_or_get_dt_node -n cpu -u 0 -d ${default_dts} -p ${cpu_root_node} -disable_auto_ref -force]

	set tmp_opp $cpu_max_freq
	set opp ""
	set i 0
	# do not generate opp for freq lower than 200MHz and use fix voltage
	# 1000000uv
	while {$tmp_opp >= 200000} {
		append opp " " "$tmp_opp 1000000"
		incr i
		set tmp_opp [expr int([expr $cpu_max_freq / pow(2, $i)])]
	}
	if {![string_is_empty $opp]} {
		add_new_dts_param $cpu_node "operating-points" "$opp" intlist
	}
}

proc remove_all_tree {} {
	# for testing
	set test_dummy "for_test_dummy.dts"
	if {[lsearch [get_dt_trees] ${test_dummy}] < 0} {
		create_dt_tree -dts_file $test_dummy
	}
	set_cur_working_dts $test_dummy

	foreach tree [get_dt_trees] {
		if {[string equal -nocase $test_dummy $tree]} {
			continue
		}
		catch {delete_objs $tree} msg
	}
}

proc gen_mdio_node {drv_handle parent_node} {
	set dts_file [set_drv_def_dts $drv_handle]
	set mdio_node [create_node -l ${drv_handle}_mdio -n mdio -p $parent_node -d $dts_file]
	add_prop $mdio_node "#address-cells" 1 int $dts_file
	add_prop "${mdio_node}" "#size-cells" 0 int $dts_file 
	return $mdio_node
}

proc gen_mb_ccf_subnode {drv_handle name freq reg} {
	set default_dts "pl.dtsi"
	set clk_node [create_node -n clocks -l clock -p root -d ${default_dts}]

	add_prop "${clk_node}" "#address-cells" 1 int $default_dts
	add_prop "${clk_node}" "#size-cells" 0 int $default_dts

	set clk_subnode_name "clk_${name}"
	set clk_subnode_label "clk_${name}"
	if {[string match -nocase $name "cpu"]} {
		set clk_subnode_label "clk_${name}_$reg"
	}
	set clk_subnode [create_node -l ${clk_subnode_label} -n ${clk_subnode_name} -u $reg -p ${clk_node} -d ${default_dts}]
	# clk subnode data
	add_prop "${clk_subnode}" "compatible" "fixed-clock" stringlist $default_dts
	add_prop "${clk_subnode}" "#clock-cells" 0 int $default_dts

	add_prop $clk_subnode "clock-output-names" $clk_subnode_name string $default_dts
	add_prop $clk_subnode "reg" $reg int $default_dts
	add_prop $clk_subnode "clock-frequency" $freq int $default_dts
}

proc generate_mb_ccf_node {drv_handle} {
	global bus_clk_list

	proc_called_by
	set family [get_hw_family]
	set cpu_clk_freq [get_clock_frequency $drv_handle "CLK"]
	# issue:
	# - hardcoded reg number cpu clock node
	# - assume clk_cpu for mb cpu
	# - only applies to master mb cpu
	gen_mb_ccf_subnode $drv_handle cpu $cpu_clk_freq [lsearch [hsi::get_cells -hier -filter {IP_NAME==microblaze || IP_NAME==microblaze_riscv}] $drv_handle]
}

proc gen_dev_ccf_binding args {
	global pl_design
	proc_called_by
	set drv_handle [lindex $args 0]
	set pins [lindex $args 1]
	set binding_list "clocks clock-frequency"
	if {[llength $args] >= 3} {
		set binding_list [lindex $args 2]
	}
	# list of ip should have the clocks property
	global bus_clk_list

	set proctype [get_hw_family]
	if { $pl_design } {
		set clk_refs ""
		set clk_names ""
		set clk_freqs ""
		foreach p $pins {
			set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "$p"]
			if {![string equal $clk_freq ""]} {
				# FIXME: bus clk source count should based on the clock generator not based on clk freq diff
				if {[lsearch $bus_clk_list $clk_freq] < 0} {
					set bus_clk_list [lappend bus_clk_list $clk_freq]
				}
				set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
				# create the node and assuming reg 0 is taken by cpu
				gen_mb_ccf_subnode $drv_handle bus_${bus_clk_cnt} $clk_freq [expr ${bus_clk_cnt} + 1]
				set clk_refs [lappend clk_refs clk_bus_${bus_clk_cnt}]
				set clk_names [lappend clk_names "$p"]
				set clk_freqs [lappend clk_freqs "$clk_freq"]
			}
		}
		set node [get_node $drv_handle]
		if {[lsearch $binding_list "clocks"] >= 0 && ![string_is_empty $clk_refs]} {
			# For axi_cdma, there are two clock names mapped:
			# clock-names = "s_axi_lite_aclk", "m_axi_aclk";
			# It is expected to get reference for them like below:
			# clocks = <&clk_bus_0 &clk_bus_0>; That's why referencelist.
			add_prop $node "clocks" $clk_refs referencelist "pl.dtsi"
		}
		if {[lsearch $binding_list "clock-names"] >= 0} {
			add_prop $node "clock-names" $clk_names stringlist "pl.dtsi"
		}
		if {[lsearch $binding_list "clock-frequency"] >= 0} {
			add_prop $node "clock-frequency" $clk_freqs hexlist "pl.dtsi"
		}
	}
}

proc update_eth_mac_addr {drv_handle} {
	proc_called_by
	set eth_count [get_count "eth_mac_count"]
	set tmp ""
	if {![string_is_empty $tmp]} {
		set def_mac [hsi get_property CONFIG.local-mac-address $drv_handle]
	} else {
		set def_mac ""
	}
	if {[string_is_empty $def_mac]} {
		set def_mac "00 10 35 00 00 00"
	}
	set mac_addr_data [split $def_mac " "]
	set last_value [format %02x [expr [lindex $mac_addr_data 5] + $eth_count ]]
	set mac_addr [lreplace $mac_addr_data 5 5 $last_value]
	dtg_debug "${drv_handle}:set mac addr to $mac_addr"
	incr eth_count
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	add_prop $node "local-mac-address" ${mac_addr} bytesequence $dts_file
}

proc get_os_dev_count {count_para {drv_handle ""} {os_para ""}} {
	set dev_count [get_os_parameter_value "${count_para}"]
	if {[llength $dev_count] == 0} {
		set dev_count 0
	}
	if {[string_is_empty $os_para] || [string_is_empty $drv_handle]} {
		return $dev_count
	}
	set ip [hsi::get_cells -hier $drv_handle]
	set chosen_ip [get_os_parameter_value "${os_para}"]
	if {[string match -nocase "$ip" "$chosen_ip"]} {
		set_os_parameter_value $count_para 1
		return 0
	} else {
		return $dev_count
	}
}

proc get_hw_version {} {
	set hw_ver_data [split [hsi get_property VIVADO_VERSION [hsi::get_hw_designs]] "."]
	set hw_ver [lindex $hw_ver_data 0].[lindex $hw_ver_data 1]
	return $hw_ver
}

proc get_hsi_version {} {
	set hsi_ver_data [split [hsi version -short] "."]
	set hsi_ver [lindex $hsi_ver_data 0].[lindex $hsi_ver_data 1]
	return $hsi_ver
}

proc get_sw_proc_prop {prop_name} {
	proc_called_by
	set sw_proc [get_sw_processor]
	set proc_ip [hsi::get_cells -hier $sw_proc]
	set property_value [hsi get_property $prop_name $proc_ip]
	return $property_value
}

# Get the interrupt controller name, which the ip is connected
proc get_intr_cntrl_name { periph_name intr_pin_name } {
	proc_called_by
	lappend intr_cntrl
	if { [llength $intr_pin_name] == 0 } {
		return $intr_cntrl
	}
	if { [llength $periph_name] != 0 } {
	# This is the case where IP pin is interrupting
		set periph [hsi::get_cells -hier -filter "NAME==$periph_name"]

		if { [llength $periph] == 0 } {
			return $intr_cntrl
		}
		set intr_pin [hsi::get_pins -of_objects $periph -filter "NAME==$intr_pin_name"]
		if { [llength $intr_pin] == 0 } {
			return $intr_cntrl
		}
		set valid_cascade_proc "microblaze microblaze_riscv zynq zynqmp zynquplus zynquplusRFSOC versal"
		set proctype [get_hw_family]
		if { [string match -nocase [hsi get_property IP_NAME $periph] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0 } {
			set sinks [get_sink_pins $intr_pin]
			foreach intr_sink ${sinks} {
				set sink_periph [hsi::get_cells -of_objects $intr_sink]
				if { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "axi_intc"] } {
					# this the case where interrupt port is connected to axi_intc.
					lappend intr_cntrl [get_intr_cntrl_name $sink_periph "irq"]
				} elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlconcat" "ilconcat"}) } {
					# this the case where interrupt port is connected to XLConcat IP.
					lappend intr_cntrl [get_intr_cntrl_name $sink_periph "dout"]
				} elseif { [llength $sink_periph ] && [is_intr_cntrl $sink_periph] == 1 } {
					lappend intr_cntrl $sink_periph
				} elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"microblaze" "microblaze_riscv"})} {
					lappend intr_cntrl $sink_periph
				} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "tmr_voter"] } {
					lappend intr_cntrl $sink_periph
				} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
					set intr [hsi::get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}
					# Encountered a design where dfx decoupler had two sets of interrupt ports.
					# One port is directly connected to axi_intc_cascaded and another port is connected
					# to xlconcat. xlconcat is getting input interrupts from axi_intc_cascaded and the
					# second interrupt port of dfx_decoupler. Output of xlconcat is going into
					# axi_intc_parent which is connected to gic. This design seems to be wrong from
					# linux perspective as the same dfx_decoupler IP is having two different
					# interrupt_parents axi_intc_cascaded for first interrupt port and axi_intc_parent
					# for second interrupt port. Adding below logic to avoid issues during PLM generation,
					# taking all interrupt pins into account.
					foreach pin $intr {
						lappend intr_cntrl [get_intr_cntrl_name $sink_periph "$pin"]
					}
			}
			if {[llength $intr_cntrl] > 1} {
				foreach intc $intr_cntrl {
					if { [is_ip_interrupting_current_proc $intc] } {
						set intr_cntrl $intc
					}
				}
			}
		}
		return $intr_cntrl
	}
	set pin_dir [hsi get_property DIRECTION $intr_pin]
	if { [string match -nocase $pin_dir "I"] } {
		return $intr_cntrl
	}
	} else {
		# This is the case where External interrupt port is interrupting
		set intr_pin [hsi::get_ports $intr_pin_name]
		if { [llength $intr_pin] == 0 } {
			return $intr_cntrl
		}
		set pin_dir [hsi get_property DIRECTION $intr_pin]
		if { [string match -nocase $pin_dir "O"] } {
			return $intr_cntrl
		}
	}
	set intr_sink_pins [get_sink_pins $intr_pin]
	if { [llength $intr_sink_pins] == 0 || [string match $intr_sink_pins "{}"]} {
		return $intr_cntrl
	}
	set valid_cascade_proc "microblaze microblaze_riscv zynq zynqmp zynquplus zynquplusRFSOC versal"
	foreach intr_sink ${intr_sink_pins} {
		if {[llength $intr_sink] == 0} {
			continue
		}
		set sink_periph [hsi::get_cells -of_objects $intr_sink]
		if { [llength $sink_periph ] && [is_intr_cntrl $sink_periph] == 1 } {
			if { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0} {
				lappend intr_cntrl [get_intr_cntrl_name $sink_periph "irq"]
			} else {
				lappend intr_cntrl $sink_periph
			}
		} elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlconcat" "ilconcat"}) } {
			# this the case where interrupt port is connected to XLConcat IP.
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "dout"]
		} elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlslice" "ilslice"}) } {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Dout"]
		} elseif {[llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"util_reduced_logic" "ilreduced_logic"})} {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Res"]
		} elseif {[llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "axi_gpio"]} {
			set intr_present [hsi get_property CONFIG.C_INTERRUPT_PRESENT $sink_periph]
			if {$intr_present == 1} {
				lappend intr_cntrl $sink_periph
			}
		} elseif {[llength $sink_periph] &&  [string match -nocase [hsi get_property IP_NAME $sink_periph] "util_ff"]} {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Q"]
		} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
			set intr [hsi::get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
			# Encountered a design where dfx decoupler had two sets of interrupt ports.
			# One port is directly connected to axi_intc_cascaded and another port is connected
			# to xlconcat. xlconcat is getting input interrupts from axi_intc_cascaded and the
			# second interrupt port of dfx_decoupler. Output of xlconcat is going into
			# axi_intc_parent which is connected to gic. This design seems to be wrong from
			# linux perspective as the same dfx_decoupler IP is having two different
			# interrupt_parents axi_intc_cascaded for first interrupt port and axi_intc_parent
			# for second interrupt port. Adding below logic to avoid issues during PLM generation,
			# taking all interrupt pins into account.
			foreach pin $intr {
				lappend intr_cntrl [get_intr_cntrl_name $sink_periph "$pin"]
			}
		}
		if {[llength $intr_cntrl] > 1} {
				foreach intc $intr_cntrl {
					if { [is_ip_interrupting_current_proc $intc] } {
						set intr_cntrl $intc
					}
				}
		}
	}
	set val [string trim $intr_cntrl \{\}]
	if {[llength $val] == 0} {
		return
	}
	return $intr_cntrl
}

# Generate interrupt info for the ips which are using gpio
# as interrupt.
proc generate_gpio_intr_info {connected_intc drv_handle pin} {
	set intr_info ""
	global ps_gpio_pincount
	if {[string_is_empty $connected_intc]} {
		return -1
	}
	# Get the gpio channel number to which the ip is connected
	set channel_nr [get_gpio_channel_nr $drv_handle $pin]
	set slave [hsi::get_cells -hier ${drv_handle}]
	set ip_name $connected_intc
	set intr_type [get_intr_type $connected_intc $slave $pin]
	if {[string match -nocase $intr_type "-1"]} {
		return -1
	}
	set sinkpin [get_sink_pins [hsi::get_pins -of [hsi::get_cells -hier $drv_handle] -filter {TYPE==INTERRUPT}]]
	set dual [hsi get_property CONFIG.C_IS_DUAL $connected_intc]
	regsub -all {[^0-9]} $sinkpin "" gpio_pin_count
	set gpio_cho_pin_lcnt [hsi get_property LEFT [hsi::get_pins -of_objects [hsi::get_cells -hier $connected_intc] gpio_io_i]]
	set gpio_cho_pin_rcnt [hsi get_property RIGHT [hsi::get_pins -of_objects [hsi::get_cells -hier $connected_intc] gpio_io_i]]
	set gpio_cho_pin_rcnt [expr $gpio_cho_pin_rcnt + 1]
	set gpio_ch0_pin_cnt [expr {$gpio_cho_pin_lcnt + $gpio_cho_pin_rcnt}]
	if {[string match $channel_nr "0"]} {
		# Check for ps7_gpio else check for axi_gpio
		if {[string match $sinkpin "GPIO_I"]} {
			set intr_info "$ps_gpio_pincount $intr_type"
			expr ps_gpio_pincount 1
		} elseif {[regexp "gpio_io_i" $sinkpin match]} {
			set intr_info "0 $intr_type"
		} else {
			# if channel width is more than one
			set intr_info "$gpio_pin_count $intr_type "
		}
	} else {
		if {[string match $dual "1"]} {
			# gpio channel 2 width is one
			if {[regexp "gpio2_io_i" $sinkpin match]} {
				set intr_info "32 $intr_type"
			} else {
				# if channel width is more than one
				set intr_pin [hsi::get_pins -of_objects $connected_intc -filter "NAME==$pin"]
				set gpio_channel [get_sink_pins $intr_pin]
				set intr_id [expr $gpio_pin_count + $gpio_ch0_pin_cnt]
				set intr_info "$intr_id $intr_type"
			}
		}
	}
	set intc $connected_intc
	if {[string_is_empty $intr_info]} {
		return -1
	}
	set node [get_node $drv_handle]
	set_drv_prop $drv_handle interrupts $intr_info $node intlist
	if {[string_is_empty $intc]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]
	set_drv_prop $drv_handle interrupt-parent $intc $node reference
}

# Get the gpio channel number to which the ip is connected
# if pin is gpio_io_* then channel is 1
# if pin is gpio2_io_* then channel is 2
proc get_gpio_channel_nr { periph_name intr_pin_name } {
	lappend intr_cntrl
	if { [llength $intr_pin_name] == 0 } {
		return $intr_cntrl
	}
	if { [llength $periph_name] != 0 } {
		set periph [hsi::get_cells -hier -filter "NAME==$periph_name"]

		if { [llength $periph] == 0 } {
			return $intr_cntrl
		}
		set intr_pin [hsi::get_pins -of_objects $periph -filter "NAME==$intr_pin_name"]
		if { [llength $intr_pin] == 0 } {
			return $intr_cntrl
		}
		set pin_dir [hsi get_property DIRECTION $intr_pin]
		if { [string match -nocase $pin_dir "I"] } {
			return $intr_cntrl
		}
		set intr_sink_pins [get_sink_pins $intr_pin]
		set sink_periph [hsi::get_cells -of_objects $intr_sink_pins]
		if { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlconcat" "ilconcat"}) } {
			# this the case where interrupt port is connected to XLConcat IP.
			return [get_gpio_channel_nr $sink_periph "dout"]
		}
		if {[regexp "gpio[2]_*" $intr_sink_pins match]} {
			return 1
		} else {
			return 0
		}
	}
}

proc is_interrupt { IP_NAME } {
	if { [string match -nocase $IP_NAME "ps7_scugic"] } {
		return true
	} elseif { $IP_NAME in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic"}} {
		return true
	} elseif { [string match -nocase $IP_NAME "psu_rcpu_gic"] } {
		return true
	}
	return false;

}

proc is_orgate { intc_src_port ip_name} {
	set ret -1

	set intr_sink_pins [get_sink_pins $intc_src_port]
	set sink_periph [hsi::get_cells -of_objects $intr_sink_pins]
	set ipname [hsi get_property IP_NAME $sink_periph]
	if {$ipname in {"xlconcat" "ilconcat"}} {
		set intf "dout"
		set intr1_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$intf"]
		set intr_sink_pins [get_sink_pins $intr1_pin]
		set sink_periph [hsi::get_cells -of_objects $intr_sink_pins]
		set ipname [hsi get_property IP_NAME $sink_periph]
		if {$ipname in {"util_reduced_logic" "ilreduced_logic"}} {
			set width [hsi get_property CONFIG.C_SIZE $sink_periph]
			return $width
		}
	}

	return $ret
}

#TODO: cache the data
proc get_psu_interrupt_id { ip_name port_name } {
	proc_called_by
	global is_versal_2ve_2vm_platform
	set versal_2ve_2vm_irq_dict {
		"pl_lpd_irq0" 104 "pl_lpd_irq1" 105 "pl_lpd_irq2" 106 "pl_lpd_irq3" 107 "pl_lpd_irq4" 108 "pl_lpd_irq5" 109 "pl_lpd_irq6" 110 "pl_lpd_irq7" 111
		"pl_fpd_irq0" 143 "pl_fpd_irq1" 144 "pl_fpd_irq2" 145 "pl_fpd_irq3" 146 "pl_fpd_irq4" 147 "pl_fpd_irq5" 148 "pl_fpd_irq6" 149 "pl_fpd_irq7" 150
		"pl_lpd_irq8" 51 "pl_lpd_irq9" 52 "pl_lpd_irq10" 53 "pl_lpd_irq11" 54
		"pl_lpd_irq12" 82 "pl_lpd_irq13" 83 "pl_lpd_irq14" 84 "pl_lpd_irq15" 85 "pl_lpd_irq16" 86 "pl_lpd_irq17" 87
		"pl_lpd_irq18" 88 "pl_lpd_irq19" 89 "pl_lpd_irq20" 90 "pl_lpd_irq21" 91 "pl_lpd_irq22" 92 "pl_lpd_irq23" 93
		"pl_mmi_irq0" 163 "pl_mmi_irq1" 163
	}
	set versal_2ve_2vm_irq_names_list [dict keys $versal_2ve_2vm_irq_dict]
	global or_id
	global or_cnt

	set ret -1
	set periph ""
	set intr_pin ""
	if { [llength $port_name] == 0 } {
		return $ret
	}
	global pl_ps_irq1
	global pl_ps_irq0
	if { [llength $ip_name] != 0 } {
		#This is the case where IP pin is interrupting
		set periph [hsi::get_cells -hier -filter "NAME==$ip_name"]
		if { [llength $periph] == 0 } {
			return $ret
		}
		set intr_pin [hsi::get_pins -of_objects $periph -filter "NAME==$port_name"]
		if { [llength $intr_pin] == 0 } {
			return $ret
		}
		set pin_dir [hsi get_property DIRECTION $intr_pin]
		if { [string match -nocase $pin_dir "I"] } {
			return $ret
		}
	} else {
		#This is the case where External interrupt port is interrupting
		set intr_pin [hsi::get_ports $port_name]
		if { [llength $intr_pin] == 0 } {
			return $ret
		}
		set pin_dir [hsi get_property DIRECTION $intr_pin]
		if { [string match -nocase $pin_dir "O"] } {
			return $ret
		}
	}
	set intc_periph [get_interrupt_parent $ip_name $port_name]
	if {[llength $intc_periph] > 1} {
		foreach intr_cntr $intc_periph {
			if { [is_ip_interrupting_current_proc $intr_cntr] } {
		        	set intc_periph $intr_cntr
			}
		}
	}
	if { [llength $intc_periph]  ==  0 } {
		return $ret
	}

	set intc_type [hsi get_property IP_NAME $intc_periph]
	if {[llength $intc_type] > 1} {
		foreach intr_cntr $intc_type {
			if { [is_ip_interrupting_current_proc $intr_cntr] } {
			        set intc_type $intr_cntr
			}
		}
	}

	set intc_src_ports [get_interrupt_sources $intc_periph]

	#Special Handling for cascading case of axi_intc Interrupt controller
	set cascade_id 0

	set i $cascade_id
	set found 0
	set j $or_id
	foreach intc_src_port $intc_src_ports {
	# Check whether externel port is interrupting not peripheral
	# like externel[7:0] port to gic
	set pin_dir [hsi get_property DIRECTION $intc_src_port]
	if { [string match -nocase $pin_dir "I"] } {
		incr i
	        continue
	}
	if { [llength $intc_src_port] == 0 } {
		incr i
		continue
	}
	set intr_width [get_port_width $intc_src_port]
	set intr_periph [hsi::get_cells -of_objects $intc_src_port]
	if { [llength $intr_periph] && [is_interrupt $intc_type] } {
		if {[hsi get_property IS_PL $intr_periph] == 0 } {
			continue
		}
	}
	set width [is_orgate $intc_src_port $ip_name]
	if { [string compare -nocase "$port_name"  "$intc_src_port" ] == 0 } {
		if { [string compare -nocase "$intr_periph" "$periph"] == 0  && $width != -1} {
			set or_cnt [expr $or_cnt + 1]
			if { $or_cnt == $width} {
				set or_cnt 0
				set or_id [expr $or_id + 1]
			}
			set ret $i
			set found 1
			break
		} elseif { [string compare -nocase "$intr_periph" "$periph"] == 0 } {
			set ret $i
			set found 1
			break
		}
	}
	if { $width != -1} {
		set i [expr $or_id]
	} else {
		set i [expr $i + $intr_width]
	}
	}
	set intr_list_irq0 [list 89 90 91 92 93 94 95 96]
	set intr_list_irq1 [list 104 105 106 107 108 109 110 111]
	set sink_pins [get_sink_pins $intr_pin]
	if { [llength $sink_pins] == 0 } {
		return
	}
	set proctype [get_hw_family]
	if {[regexp "microblaze" $proctype match]} {
		if {[string match -nocase "[hsi get_property IP_NAME $periph]" "axi_intc"]} {
			set ip [hsi get_property IP_NAME $periph]
			set cascade_master [hsi get_property CONFIG.C_CASCADE_MASTER [hsi::get_cells -hier $periph]]
			set en_cascade_mode [hsi get_property CONFIG.C_EN_CASCADE_MODE [hsi::get_cells -hier $periph]]
			set sink_pn [get_sink_pins $intr_pin]
			set peri [hsi::get_cells -of_objects $sink_pn]
			set periph_ip [hsi get_property IP_NAME [hsi::get_cells -hier $peri]]
			if {$periph_ip in {"xlconcat" "ilconcat"}} {
				set dout "dout"
				set intr_pin [hsi::get_pins -of_objects $peri -filter "NAME==$dout"]
				set pins [get_sink_pins "$intr_pin"]
				set perih [hsi::get_cells -of_objects $pins]
				if {[string match -nocase "[hsi get_property IP_NAME $perih]" "axi_intc"]} {
					set cascade_master [hsi get_property CONFIG.C_CASCADE_MASTER [hsi::get_cells -hier $perih]]
					set en_cascade_mode [hsi get_property CONFIG.C_EN_CASCADE_MODE [hsi::get_cells -hier $perih]]
				}
			}
			set number [regexp -all -inline -- {[0-9]+} $sink_pn]
			return $number
		}
	}
	if {[string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype] || [string match -nocase $proctype "zynq"]} {
		if {[string match -nocase "[hsi get_property IP_NAME $periph]" "axi_intc"]} {
			set ip [hsi get_property IP_NAME $periph]
			set cascade_master [hsi get_property CONFIG.C_CASCADE_MASTER [hsi::get_cells -hier $periph]]
			set en_cascade_mode [hsi get_property CONFIG.C_EN_CASCADE_MODE [hsi::get_cells -hier $periph]]
			set sink_pn [get_sink_pins $intr_pin]
			set peri [hsi::get_cells -of_objects $sink_pn]
			set periph_ip [hsi get_property IP_NAME [hsi::get_cells -hier $peri]]
			if {$periph_ip in {"xlconcat" "ilconcat"}} {
				set dout "dout"
				set intr_pin [hsi::get_pins -of_objects $peri -filter "NAME==$dout"]
				set pins [get_sink_pins "$intr_pin"]
				set periph [hsi::get_cells -of_objects $pins]
				if {[string match -nocase "[hsi get_property IP_NAME $periph]" "axi_intc"]} {
					set cascade_master [hsi get_property CONFIG.C_CASCADE_MASTER [hsi::get_cells -hier $periph]]
					set en_cascade_mode [hsi get_property CONFIG.C_EN_CASCADE_MODE [hsi::get_cells -hier $periph]]
				}
				if {$en_cascade_mode == 1} {
					set number [regexp -all -inline -- {[0-9]+} $sink_pn]
					if {$is_versal_2ve_2vm_platform && $sink_pin in $versal_2ve_2vm_irq_names_list} {
						set number [lsearch $versal_2ve_2vm_irq_names_list $sink_pin]
					}
					return $number
				}
			}
		}
	}
	set concat_block 0
	foreach sink_pin $sink_pins {
		set sink_periph [hsi::get_cells -of_objects $sink_pin]
		if {[llength $sink_periph] == 0 } {
			continue
	}
	set connected_ip [hsi get_property IP_NAME [hsi::get_cells -hier $sink_periph]]
	if {[llength $connected_ip]} {
		if {[string compare -nocase "$connected_ip" "dfx_decoupler"] == 0} {
			set dfx_intr [hsi::get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
			set intr_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$dfx_intr"]
			set sink_pins [get_sink_pins "$intr_pin"]
			foreach pin $sink_pins {
				set sink_pin $pin
				if {[string match -nocase $sink_pin "IRQ0_F2P"]} {
				       set sink_pin "IRQ0_F2P"
				       break
				}
				if {[string match -nocase $sink_pin "IRQ1_F2P"]} {
				       set sink_pin "IRQ1_F2P"
				       break
				}
			}
		}
	}
	if {[llength $connected_ip]} {
		# check for direct connection or concat block connected
		if {"$connected_ip" in {"xlconcat" "ilconcat"}} {
			set pin_number [regexp -all -inline -- {[0-9]+} $sink_pin]
			if {$is_versal_2ve_2vm_platform && $sink_pin in $versal_2ve_2vm_irq_names_list} {
				set pin_number [lsearch $versal_2ve_2vm_irq_names_list $sink_pin]
			}
			set number 0
			global intrpin_width
			for { set i 0 } {$i <= $pin_number} {incr i} {
				set pin_wdth [hsi get_property LEFT [ lindex [ hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph ] ] $i ] ]
				if { $i == $pin_number } {
					set intrpin_width [expr $pin_wdth + 1]
				} else {
					set number [expr $number + {$pin_wdth + 1}]
				}
	               }
	               dtg_debug "Full pin width for $sink_periph of $sink_pin:$number intrpin_width:$intrpin_width"
			set dout "dout"
			set concat_block 1
			set intr_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
			set sink_pins [get_sink_pins "$intr_pin"]
			if {[llength $sink_pins] == 0 } {
				continue
			}
	                set sink_periph [::hsi::get_cells -of_objects $sink_pins]
	                set connected_ip [hsi get_property IP_NAME [hsi::get_cells -hier $sink_periph]]
                        # When xlconcate connected via util_reduced_logic(OR) there is only one
                        # possiblity to get the interrupt so dont treat it as concat to assign the single
                        # interrupt number for all ip's connected to xlconcat
			if {[llength $connected_ip] && ("$connected_ip" in {"util_reduced_logic" "ilreduced_logic"})} {
				set concat_block 0
			}

	                while {[llength $connected_ip]} {
				if {!("$connected_ip" in {"xlconcat" "ilconcat"})} {
					break
				}
	                       set dout "dout"
	                       set intr_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
	                       set sink_pins [get_sink_pins $intr_pin]
			       if {[llength $sink_pins] == 0 } {
					continue
				}
	                       set sink_periph [::hsi::get_cells -of_objects $sink_pins]
			        set connected_ip [hsi get_property IP_NAME [hsi::get_cells -hier $sink_periph]]
	               }
			foreach pin $sink_pins {
				set sink_pin $pin
				if {[string match -nocase $sink_pin "IRQ0_F2P"]} {
					set sink_pin "IRQ0_F2P"
					break
				}
				if {[string match -nocase $sink_pin "IRQ1_F2P"]} {
					set sink_pin "IRQ1_F2P"
					break
				}
			}
		}
	}
	# check for ORgate or util_ff
	if { [string compare -nocase "$sink_pin" "Op1"] == 0 || [string compare -nocase "$sink_pin" "D"] == 0 } {
		if { [string compare -nocase "$sink_pin" "Op1"] == 0 } {
			set dout "Res"
		} elseif { [string compare -nocase "$sink_pin" "D"] == 0 } {
			set dout "Q"
		}
		set sink_periph [hsi::get_cells -of_objects $sink_pin]
		if {[llength $sink_periph]} {
			set intr_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
			if {[llength $intr_pin]} {
				set sink_pins [get_sink_pins "$intr_pin"]
				foreach pin $sink_pins {
					set sink_pin $pin
				}
				set sink_periph [hsi::get_cells -of_objects $sink_pin]
				if {[llength $sink_periph]} {
					set connected_ip [hsi get_property IP_NAME [hsi::get_cells -hier $sink_periph]]
					if {"$connected_ip" in {"xlconcat" "ilconcat"}} {
						set number [regexp -all -inline -- {[0-9]+} $sink_pin]
						if {$is_versal_2ve_2vm_platform && $sink_pin in $versal_2ve_2vm_irq_names_list} {
							set number [lsearch $versal_2ve_2vm_irq_names_list $sink_pin]
						}
						set dout "dout"
						set concat_block 1
						set intr_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
						if {[llength $intr_pin]} {
							set sink_pins [get_sink_pins "$intr_pin"]
							foreach pin $sink_pins {
								set sink_pin $pin
							}
						}
					}
				}
			}
		}
	}

	# generate irq id for IRQ1_F2P
	if { [string compare -nocase "$sink_pin" "IRQ1_F2P"] == 0 } {
	    if {$found == 1} {
	        set irqval $pl_ps_irq1
	        set pl_ps_irq1 [expr $pl_ps_irq1 + 1]
	        if {$concat_block == "0"} {
	            return [lindex $intr_list_irq1 $irqval]
	        } else {
	            set ret [expr 104 + $number]
	            return $ret
	        }
	    }
	} elseif { [string compare -nocase "$sink_pin" "IRQ0_F2P"] == 0 } {
		# generate irq id for IRQ0_F2P
		if {$found == 1} {
			set irqval $pl_ps_irq0
			set pl_ps_irq0 [expr $pl_ps_irq0 + 1]
			if {$concat_block == "0"} {
			    return [lindex $intr_list_irq0 $irqval]
			} else {
			    set ret [expr 89 + $number]
			    return $ret
			}
		}
	} elseif {[regexp "^pl_ps_irq.*" "$sink_pin" match] && \
			[expr [string trim "$sink_pin" "pl_ps_irq"] <= 15]} {
		if {$concat_block == "0"} {
			set intr_index [string trim "$sink_pin" "pl_ps_irq"]
			set ret [expr 84 + $intr_index]
		} else {
			set ret [expr 84 + $number]
		}
	} elseif {[regexp "^pl_lpd_irq.*|^pl_fpd_irq.*|^pl_mmi_irq.*" "$sink_pin" match]} {
		if {$is_versal_2ve_2vm_platform && $sink_pin in $versal_2ve_2vm_irq_names_list} {
			if {$concat_block == "0"} {
				set ret [dict get $versal_2ve_2vm_irq_dict $sink_pin]
			} elseif {$number < [llength $versal_2ve_2vm_irq_names_list]} {
				set ret [dict get $versal_2ve_2vm_irq_dict [lindex $versal_2ve_2vm_irq_names_list $number]]
			}
		}
	} elseif {[regexp "^pl_psx_irq.*" "$sink_pin" match] && \
			[expr [string trim "$sink_pin" "pl_psx_irq"] <= 15]} {
		if {$concat_block == "0"} {
			set intr_index [string trim "$sink_pin" "pl_psx_irq"]
			set ret [expr 104 + $intr_index]
		} else {
			set ret [expr 104 + $number]
		}
	} else {
	    set sink_periph [hsi::get_cells -of_objects $sink_pin]
	    if {[llength $sink_periph] == 0 } {
		break
	    }
	    set connected_ip [hsi get_property IP_NAME [hsi::get_cells -hier $sink_periph]]
	    if {[string match -nocase $connected_ip "axi_intc"] } {
	        set sink_pin [hsi::get_pins -of_objects $periph -filter {TYPE==INTERRUPT && DIRECTION==O}]
	    }
	    if {[llength $sink_pin] == 1} {
	        set port_width [get_port_width $sink_pin]
	    } else {
	            foreach pin $sink_pin {
	                    set port_width [get_port_width $pin]
	            }
	    }
	}
	}

	set id $ret
	return $ret
	}

proc check_ip_trustzone_state { drv_handle } {
	proc_called_by
    	set proctype [hsi get_property IP_NAME [hsi::get_cells -hier [get_sw_processor]]]
   	if {[string match -nocase $proctype "psu_cortexa53"]} {
    	if {$index == -1 } {
		return 0
	}
        set index [lsearch [get_mem_ranges -of_objects [hsi::get_cells -hier [get_sw_processor]]] $drv_handle]
        set avail_param [hsi list_property [lindex [get_mem_ranges -of_objects [hsi::get_cells -hier [get_sw_processor]]] $index]]
        if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
            set state [hsi get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [hsi::get_cells -hier [get_sw_processor]]] $index]]
            # Don't generate status okay when the peripheral is in Secure Trustzone
            if {[string match -nocase $state "Secure"]} {
                return 1
            }
        }
   } elseif {$proctype in {"psv_cortexa72" "psx_cortexa78" "cortexa78"}} {
        set index [lsearch [get_mem_ranges -of_objects [hsi::get_cells -hier [get_sw_processor]]] $drv_handle]
	if {$index == -1 } {
		return 0
	}
        set avail_param [hsi list_property [lindex [get_mem_ranges -of_objects [hsi::get_cells -hier [get_sw_processor]]] $index]]
        if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
                set state [hsi get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [hsi::get_cells -hier [get_sw_processor]]] $index]]
                # Don't generate status okay when the peripheral is in Secure Trustzone
                if {[string match -nocase $state "Secure"]} {
                        return 1
                }
          }
   } else {
	return 0
   }
}

proc generate_cci_node { drv_handle rt_node} {
	set dts_file [set_drv_def_dts $drv_handle]
	set avail_param [hsi list_property [hsi::get_cells -hier $drv_handle]]
	if {[lsearch -nocase $avail_param "CONFIG.IS_CACHE_COHERENT"] >= 0} {
		set cci_enable [hsi get_property CONFIG.IS_CACHE_COHERENT [hsi::get_cells -hier $drv_handle]]
		set iptype [get_ip_property $drv_handle IP_NAME]
		set nodma_coherent_list "psu_sata"
		if {[lsearch $nodma_coherent_list $iptype] >= 0} {
			#CR 974156, as per 2017.1 PCW update
			return
		}
		if {[string match -nocase $cci_enable "1"]} {
			add_prop $rt_node "dma-coherent" boolean $dts_file
		}
	}
}

proc generate_board_compatible { rt_node } {
	set boardname [hsi get_property BOARD [hsi::get_hw_designs]]
	if { [string length $boardname] != 0 } {
                set fields [split $boardname ":"]
                lassign $fields prefix board suffix
                if { [string length $board] != 0 } {
			add_prop root compatible $board string "system-top.dts"
                }
            }
}

proc is_smmu_en {} {
	proc_called_by
	global cur_hw_iss_data
	global cur_hw_is_smmu_en

	if {[catch {set subsystem_list [dict get $cur_hw_iss_data design subsystems]} msg]} {
		set subsystem_list ""
	}
	foreach subsystem $subsystem_list {
		if {[catch {set dest_list [dict get $cur_hw_iss_data design subsystems $subsystem access]} msg]} {
			set dest_list ""
		}
		foreach entry $dest_list {
			if {![catch {set destinations [dict get $entry destinations]}]} {
				if {![catch {set entry_flags [dict get $entry flags]}]} {
					if {![catch {set is_virtualized [dict get $entry flags requested_virtualized]}]} {
						set cur_hw_is_smmu_en "true"
					}
				}
			}
		}
	}
}

proc get_smid { iss_name} {
	proc_called_by
	global cur_hw_iss_data
	set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
	if {[catch {set destn [dict get $cur_hw_iss_data design cells $versal_periph SMIDs]} msg]} {
		set destn ""
	}
	foreach entry $destn {
		if {[dict exists $entry name]} {
			if {[dict get $entry name] == $iss_name} {
				set value [dict get $entry value]
				return $value
			}
		}
	}
	return
}

proc get_iss_drv_name { versal_periph addr} {
	proc_called_by
	global cur_hw_iss_data

	if {[catch {set destn [dict get $cur_hw_iss_data design cells $versal_periph destinations]} msg]} {
		set destn ""
	}
	set iss_name ""
	foreach entry $destn {
		if {[dict exists $entry addr]} {
			if {[dict get $entry addr] == $addr} {
				set iss_name [dict get $entry name]
			}
		}
	}
	return $iss_name
}


proc generate_smmu_cci_config { iss_name drv_handle} {
	proc_called_by
	global cur_hw_iss_data
	global cur_hw_is_smmu_en
	if {[catch {set subsystem_list [dict get $cur_hw_iss_data design subsystems]} msg]} {
		set subsystem_list ""
	}
	foreach subsystem $subsystem_list {
		if {[catch {set dest_list [dict get $cur_hw_iss_data design subsystems $subsystem access]} msg]} {
			set dest_list ""
		}
		foreach entry $dest_list {
			if {![catch {set destinations [dict get $entry destinations]}]} {
				if {$iss_name in $destinations} {
					if {![catch {set entry_flags [dict get $entry flags]}]} {
						set node [get_node $drv_handle]
						set is_coherent ""
						set is_virtualized ""
						foreach flag {requested_coherent requested_secure requested_virtualized} {
							if {![catch {set is_flag [dict get $entry_flags $flag]}]} {
								if {[string match -nocase $is_flag "true"]} {
									switch -- $flag {
										"requested_coherent" {
											add_prop $node "dma-coherent" boolean [set_drv_def_dts $drv_handle]
											set is_coherent "true"
										}
										"requested_secure" {
											add_prop $node "xlnx,is-secure" boolean [set_drv_def_dts $drv_handle]
										}
										"requested_virtualized" {
											set is_virtualized "true"
											set smid [get_smid $iss_name]
											if {![string_is_empty $smid]} {
												add_prop $node "iommus" "smmu $smid" reference [set_drv_def_dts $drv_handle]
											}
										}
									}
								}
							}
						}
						if {[string match -nocase $cur_hw_is_smmu_en "true"] &&
						    [string match -nocase $is_coherent "true"] &&
						    [string_is_empty $is_virtualized]} {
							set smid [get_smid $iss_name]
							if {![string_is_empty $smid]} {
								add_prop $node "iommus" "smmu $smid" reference [set_drv_def_dts $drv_handle]
							}
						}
					}
				}
			}
		}
	}
}

proc gen_domain_data { drv_handle } {
	proc_called_by
	global cur_hw_iss_data
	if {![string_is_empty $cur_hw_iss_data]} {
		set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
		if {![string_is_empty $versal_periph]} {
			set unit_addr [get_baseaddr ${drv_handle}]
			set iss_name [get_iss_drv_name $versal_periph $unit_addr]
		} else {
			set iss_name ""
		}
		if {![string_is_empty $iss_name] && ![string_is_empty $versal_periph]} {
			generate_smmu_cci_config $iss_name $drv_handle
		}
	}
}

# Function to generate the reg property format with baseaddr and highaddr.
proc gen_reg_property_format {base high {bit_format 64}} {
	set size [format 0x%lx [expr {${high} - ${base} + 1}]]
	set base [format 0x%lx $base]
	# When both base and size are 64 bit
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
	# When base has 32 bit and size has 64 bit
	} elseif {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
		set temp $size
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_size "0x[string range $temp $rem $len]"
		set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_size [format 0x%08x $low_size]
		set reg "0x0 $base $low_size $high_size"
	} elseif { $bit_format == 32 } {
		set reg "${base} ${size}"
	} else {
		set reg "0x0 $base 0x0 $size"
	}
	return $reg
}

# Create a 64 bit reg value in the dt property format from the base address
# and size address
proc get_64_bit_reg {base size} {
	set addr_cell_values ""
	set size_cell_values ""
	# check if base address is 64bit and split it as MSB and LSB
	if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		set addr_cell_values [split_string_to_32_bit_cell $base]
	} else {
		set addr_cell_values "0x0 $base"
	}

	# check if size is 64bit and split it as MSB and LSB
	if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
		set size_cell_values [split_string_to_32_bit_cell $size]
	} else {
		set size_cell_values "0x0 $size"
	}

	return "$addr_cell_values $size_cell_values"
}

# Split more than 32 bit addresses into two cells of hex numbers
proc split_string_to_32_bit_cell {addr} {
	regsub -all {^0x} $addr {} addr
	set len [string length $addr]
	set rem [expr {${len} - 8}]
	set lower_32bit_cell "0x[string range $addr $rem $len]"
	set higher_32bit_cell "0x[string range $addr 0 [expr {${rem} - 1}]]"
	set higher_32bit_cell [format 0x%08x $higher_32bit_cell]
	return "$higher_32bit_cell $lower_32bit_cell"
}

proc map_node_to_processor {node_label processor reg bit_format baseaddr size} {
	set proc_ip_name [get_ip_property $processor IP_NAME]
	set memmap_key ""
	switch $proc_ip_name {
		"microblaze" - "microblaze_riscv" - "psu_cortexr5" - "psv_cortexr5" - "psx_cortexr52" - "cortexr52" {
			set memmap_key $processor
		}
		"psv_cortexa72" - "psx_cortexa78" - "cortexa78" - "ps7_cortexa9" {
			set memmap_key "a53"
		}
		"psv_psm" - "psx_psm" - "psm" {
			set memmap_key "psm"
		}
		"psu_pmu" {
			set memmap_key "pmu"
		}
		"asu" {
			set memmap_key "asu"
		}
	}
	if {![string_is_empty $memmap_key]} {
		if {$proc_ip_name in {"microblaze" "microblaze_riscv"}} {
			if {$bit_format == 32} {
				set reg "0x0 $baseaddr 0x0 $size"
			}
		}
		set_memmap "${node_label}" $memmap_key $reg
	}
}
