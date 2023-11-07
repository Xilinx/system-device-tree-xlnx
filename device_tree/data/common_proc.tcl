#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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
	lappend items ps7_qspi spi
	lappend items psu_qspi spi
	lappend items psv_pmc_qspi spi
	lappend items mdm serial
	lappend items axi_uartlite serial
	lappend items axi_uart16550 serial
	lappend items ps7_uart serial
	lappend items psu_uart serial
	lappend items psu_sbsauart serial
	lappend items psv_uart serial
	lappend items psv_sbsauart serial
	lappend items psx_sbsauart serial
	lappend items ps7_coresight_comp serial
	lappend items psu_coresight_0 serial
	lappend items psv_coresight serial
	lappend items psx_coresight serial
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

set node_dict [dict create]
set nodename_dict [dict create]
set ip_type_dict [dict create]
set property_dict [dict create]
set intr_id_dict [dict create]
set comp_ver_dict [dict create]
set comp_str_dict [dict create]
set cur_hw_design ""
set intr_type_dict [dict create]

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
			set microblaze_list "psx_pmc psx_psm"
		} else {
			set microblaze_list "psv_pmc psv_psm"
		}
	} elseif {[string match -nocase $design_family "zynqmp"]} {
		set microblaze_list "psu_pmu"
	}
	set soft_mb_handles [hsi::get_cells -hier -filter {IP_NAME==microblaze}]
	if {![string_is_empty soft_mb_handles]} {
		append microblaze_list " $soft_mb_handles"
	}
}

# Saves the number of microblaze processors in microblaze_map dict
# and returns the microblaze numbers found during a particular cmd
# execution.
proc get_microblaze_nr {drv_handle} {
	global microblaze_list
	set mb_index [lsearch $microblaze_list $drv_handle]
	if {$mb_index >= 0} {
		return $mb_index
	} else {
		error "$drv_handle couldn't be found in the microblaze list: $microblaze_list"
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
		if { $periph_addr ne "" && [is_ps_ip $drv_handle] != 1 && [lsearch $non_val_list $ip_name] < 0 } {
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
	if {[catch {dict for {memory procs} $memmap {}} msg]} {
		dict set memmap $mem_ip $proc_ip $val
	} else {
		dict for {memory procs} $memmap {
			if {[string match -nocase $memory $mem_ip]} {
			        dict with procs {
					if {[dict exists $memmap $memory $proc_ip]} {
						if {[catch {set value [dict get $procs $proc_ip]} msg]} {
							dict set memmap $mem_ip $proc_ip $val
						} elseif { $value ne $val } {
							dict set memmap $mem_ip $proc_ip "$value , $val"
						}
					} else {
						dict set memmap $mem_ip $proc_ip $val
					}
        			}
			} else {
				dict set memmap $mem_ip $proc_ip $val
			}
		}
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
	set design_family ""
	set pl_design 0
	set ps_design 0
	set is_versal_net_platform 0

	foreach procperiph $proclist {
		set proc_drv_handle [hsi::get_cells -hier $procperiph]
        	set ip_name [hsi get_property IP_NAME $proc_drv_handle]
		switch $ip_name {
			"psx_cortexa78" {
				set design_family "versal"
				set ps_design 1
				set is_versal_net_platform 1
			} "psv_cortexa72" {
				set design_family "versal"
				set ps_design 1
			} "psu_cortexa53" {
				set design_family "zynqmp"
				set ps_design 1
			} "ps7_cortexa9" {
				set design_family "zynq"
				set ps_design 1
			} "microblaze" {
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

# set global dict_devicetree
proc get_user_config args {
        set dict_devicetree  {}
	set val [get_dt_param [lindex $args 1]]
	if {[string match -nocase $val ""]} {
	        set config_file [lindex $args 0]
       		set cfg [get_yaml_dict $config_file]
	        set user [dict get $cfg dict_devicetree]
	        set overlay [dict get $user dt_overlay]
        	set mainline_kernel [dict get $user mainline_kernel]
        	set kernel_ver [dict get $user kernel_ver]
        	set dir [dict get $user output_dir]
        	set zocl [dict get $user dt_zocl]
        	set param ""
        	switch -glob -- [lindex $args 1] {
                	-repo {
                        	set param $path
                	} -master_dts {
                        	set param $master_dts
                	} -config_dts {
                        	set param $config_dts
                	} -board_dts {
                        	set param ""
                	} -dt_overlay {
                        	set param $overlay
                	} -pl_only {
                        	set param $pl_only
			} -mainline_kernel {
				set param $mainline_kernel
			} -kernel_ver {
				set param $kernel_ver
			} -dir {
				set param $dir
			} -dt_zocl {
				set param $zocl
                	} default {
                        	error "get_user_config bad option - [lindex $args 0]"
                	}
        	}
	} else {
		set param $val
	}
        return $param
}

proc get_node args {
	global node_dict
	global cur_hw_design

	proc_called_by
	set handle [lindex $args 0]
	set handle [hsi::get_cells -hier $handle]
	if { [dict exists $node_dict $cur_hw_design $handle] } {
		return [dict get $node_dict $cur_hw_design $handle]
	}
	set non_val_list "versal_cips noc_nmu noc_nsu ila zynq_ultra_ps_e psu_iou_s smart_connect noc_nsw"
	set non_val_ip_types "MONITOR BUS PROCESSOR"
	set ip_name [hsi get_property IP_NAME $handle]
	set ip_type [hsi get_property IP_TYPE $handle]
	if {[lsearch -nocase $non_val_list $ip_name] >= 0} {
		dict set node_dict $cur_hw_design $handle {}
		return ""
	}
	if {[lsearch -nocase $non_val_ip_types $ip_type] >= 0 && ![string match -nocase "axi_perf_mon" $ip_name]} {
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
	set path $env(REPO)
	set drv_handle [lindex $args 0]
	set type [lindex $args 1]
	set param [get_driver_param $drv_handle $type]

	return $param
}

# load yaml file into dict
proc get_yaml_dict { config_file } {
	proc_called_by
        set data ""
        if {[file exists $config_file]} {
                set fd [open $config_file r]
                set data [read $fd]
                close $fd
        } else {
                error "YAML:: No such file $config_file"
        }
	return [yaml::yaml2dict $data]
}

proc write_value {type value} {
        if {[catch {
                if {$type == "int"} {
			set base [format %x $value]
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
                                	set val "<$low_base $high_base 0x0 $size>"
                        	}
                	} else {
				if {$value < 0} {
					set val "<[format 0x%.8x [expr {$value & 0xFFFFFFFF}]]>"
				} else {
	                        	set val "<$value>"
				}
                	}
                } elseif {$type == "hexint"} {
			if {[regexp -nocase {0x([0-9a-f])} $value match]} {
				set val "<$value>"
			} elseif {[regexp -nocase {([a-f])} $value match]} {
				set val "<0x$value>"
			} else {
                        	set val "<0x[format %x $value]>"
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
		puts $error
                set val "\"$value\""
        }
        return $val
}

proc create_node args {
	set node_name ""
	set node_unit_addr ""
	set node_label ""
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
			--  {Pop args ; break}
			default {
				error "add_or_get_dt_node bad option - [lindex $args 0]"
			}
		}
		Pop args
	}
	set ignore_list "fifo_generator clk_wiz clk_wizard xlconcat xlconstant \
		util_vector_logic xlslice util_ds_buf proc_sys_reset axis_data_fifo \
		v_vid_in_axi4s bufg_gt axis_tdest_editor util_reduced_logic \
		gt_quad_base noc_nsw blk_mem_gen emb_mem_gen lmb_bram_if_cntlr \
		perf_axi_tg noc_mc_ddr4 c_counter_binary timer_sync_1588 oddr \
		axi_noc mailbox dp_videoaxi4s_bridge axi4svideo_bridge axi_vip \
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
	set path $env(REPO)
	# Windows treats an empty env variable as not defined
	if {[catch {set include_dts $env(include_dts)} msg]} {
		set include_dts ""
	}
	set common_file "$path/device_tree/data/config.yaml"
	set dt_overlay [get_user_config $common_file -dt_overlay]
	set fd [open $file w]
	if {[string match -nocase $dt "systemdt"]} {
		puts $fd "\/dts-v1\/\;"
		global include_list
		set includelist [split $include_list ","]
		foreach val $includelist {
			puts $fd "#include \"$val\""
		}
		foreach include_dts_file $include_dts {
			set include_dts_filename [file tail $include_dts_file]
			puts $fd "#include \"$include_dts_filename\""
		}
	}
	if {[string match -nocase $dt "pldt"] && $dt_overlay} {
		puts $fd "\/dts-v1\/\n\/plugin\/;"
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
					set first_str "\"[lindex $val 0]\""
					set first_str ""
					set first true
                			foreach element $val {
                				if {$first != true} {
                				} 
						set first false
					}
					puts $fd "\t$prop = $first_str;"
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
	close $fd
}

proc get_repo_path args {
	if { [info exists ::env(REPO) ] } {
		set path $env(repo_path)
		return $path
	} else {
		error "No repo found, please set it using ser env(REPO) PATH"
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
	dict set driverlist v_uhdsdi_audio driver audio_embed
	dict set driverlist audio_formatter driver audio_spdif
	dict set driverlist spdif driver audio_spdif
	dict set driverlist axi_bram_ctrl driver axi_bram
	dict set driverlist lmb_bram_if_cntlr driver axi_bram
	dict set driverlist can driver axi_can
	dict set driverlist v_dp_txss1 driver dp_tx
	dict set driverlist v_dp_rxss1 driver dp_rx
	dict set driverlist canfd driver axi_can
	dict set driverlist axi_cdma driver axi_cdma
	dict set driverlist clk_wiz driver axi_clk_wiz
	dict set driverlist clk_wizard driver axi_clk_wiz
	dict set driverlist axi_dma driver axi_dma
	dict set driverlist axi_emc driver axi_emc
	dict set driverlist axi_ethernet driver axi_ethernet
	dict set driverlist axi_ethernet_buffer  driver axi_ethernet
	dict set driverlist axi_10g_ethernet driver axi_ethernet
	dict set driverlist xxv_ethernet driver axi_ethernet
	dict set driverlist usxgmii driver axi_ethernet
	dict set driverlist axi_gpio driver axi_gpio
	dict set driverlist axi_iic driver axi_iic
	dict set driverlist axi_mcdma driver axi_mcdma
	dict set driverlist axi_pcie driver axi_pcie
	dict set driverlist axi_pcie3 driver axi_pcie
	dict set driverlist xdma driver axi_pcie
	dict set driverlist psv_noc_pcie_1 driver xdmapcie
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
	dict set driverlist psu_canfd driver canfdps
	dict set driverlist psv_canfd driver canfdps
	dict set driverlist psx_canfd driver canfdps
	dict set driverlist ps7_can driver canps
	dict set driverlist psu_can driver canps
	dict set driverlist psv_can driver canps
	dict set driverlist microblaze driver cpu
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
	dict set driverlist psv_gdma driver dmaps
	dict set driverlist psx_gdma driver dmaps
	dict set driverlist psv_csudma driver dmaps
	dict set driverlist psx_csudma driver dmaps
	dict set driverlist psu_dp driver dp
	dict set driverlist psv_dp driver dp
	dict set driverlist dpu_eu driver dpu_eu
	dict set driverlist axi_ethernetlite driver emaclite
	dict set driverlist ps7_ethernet driver emacps
	dict set driverlist psu_ethernet driver emacps
	dict set driverlist psv_ethernet driver emacps
	dict set driverlist psx_ethernet driver emacps
	dict set driverlist ernic driver ernic
	dict set driverlist v_frmbuf_rd driver framebuf_rd
	dict set driverlist v_frmbuf_wr driver framebuf_wr
	dict set driverlist v_gamma_lut driver gamma_lut
	dict set driverlist ps7_globaltimer driver globaltimerps
	dict set driverlist ps7_gpio driver gpiops
	dict set driverlist psu_gpio driver gpiops
	dict set driverlist psv_gpio driver gpiops
	dict set driverlist psx_gpio driver gpiops
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
	dict set driverlist axi_intc driver intc
	dict set driverlist iomodule driver iomodule
	dict set driverlist psu_ipi driver ipipsu
	dict set driverlist psv_ipi driver ipipsu
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
	# What is psu_ocm
	dict set driverlist psu_ocm_ram_0 driver psu_ocm
	dict set driverlist psv_ocm_ram_0 driver psu_ocm
	dict set driverlist psx_ocm_ram driver psu_ocm
	dict set driverlist ps7_ram driver ramps
	dict set driverlist usp_rf_data_converter driver rfdc
	dict set driverlist v_scenechange driver scene_change_detector
	dict set driverlist ps7_scugic driver scugic
	dict set driverlist psu_acpu_gic driver scugic
	dict set driverlist psv_acpu_gic driver scugic
	dict set driverlist psx_acpu_gic driver scugic
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
	dict set driverlist mdm driver uartlite
	dict set driverlist axi_uartlite driver uartlite
	dict set driverlist axi_uart16550 driver uartns
	dict set driverlist ps7_uart driver uartps
	dict set driverlist psu_uart driver uartps
	dict set driverlist psu_sbsauart driver uartps
	dict set driverlist psv_uart driver uartps
	dict set driverlist psv_sbsauart driver uartps
	dict set driverlist psx_sbsauart driver uartps
	dict set driverlist ps7_coresight_comp driver coresight
	dict set driverlist psu_coresight_0 driver coresight
	dict set driverlist psv_coresight driver coresight
	dict set driverlist psx_coresight driver coresight
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
		set ipname [hsi get_property IP_NAME [hsi::get_cells -hier $val]]
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
		set clk [hsi get_property CLK_FREQ $clkhandle ]
		# For one Versal Net design, there is an IP clock_monitor_0 having
		# "299994000:249995000:99998000:299994000" as clk_freq value .
		if {![string is xdigit $clk]} {
			set clk	""
		}
	}
	return $clk
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
	set valid_proclist "psv_cortexa72 psv_cortexr5 psu_cortexa53 psu_cortexr5 psu_pmu psv_pmc psv_psm ps7_cortexa9 microblaze psx_cortexa78 psx_cortexr52 psx_pmc psx_psm"
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
				if {[regexp -nocase {0x([0-9a-f]{9})} "$value" match] && ![string match -nocase $type "string"] } {
					set temp [string range $value 2 end]
					#set temp [string trimleft [string trimleft $temp 0] x]
					set len [string length $temp]
					set rem [expr {${len} - 8}]
					set high_base "0x[string range $temp $rem $len]"
					set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
					set low_base [format 0x%08x $low_base]
					set value "$low_base $high_base"
				}

				if {[string match -nocase $ipname "psv_rcpu_gic"]} {
					set node [create_node -n "&gic_r5" -d "pcw.dtsi" -p root]
				} elseif {[string match -nocase $ipname "psx_rcpu_gic"]} {
					set node [create_node -n "&gic_r52" -d "pcw.dtsi" -p root]
				} elseif {[lsearch $valid_proclist $ipname] >= 0} {
					switch $ipname {
						"psv_cortexa72" {
							set index [string index $src_handle end]
							set node [create_node -n "&psv_cortexa72_${index}" -d "pcw.dtsi" -p root]
						} "psv_cortexr5" {
							set index [string index $src_handle end]
							set node [create_node -n "&psv_cortexr5_${index}" -d "pcw.dtsi" -p root]
						} "psv_pmc" {
							set node [create_node -n "&psv_pmc_0" -d "pcw.dtsi" -p root]
						} "psv_psm" {
							set node [create_node -n "&psv_psm_0" -d "pcw.dtsi" -p root]
						} "psx_pmc" {
							set node [create_node -n "&psx_pmc_0" -d "pcw.dtsi" -p root]
						} "psx_psm" {
							set node [create_node -n "&psx_psm_0" -d "pcw.dtsi" -p root]
						} "psu_cortexa53" {
							set index [string index $src_handle end]
							set node [create_node -n "&psu_cortexa53_${index}" -d "pcw.dtsi" -p root]
						} "psu_cortexr5" {
							set index [string index $src_handle end]
							set node [create_node -n "&psu_cortexr5_${index}" -d "pcw.dtsi" -p root]
						} "psu_pmu" {
							set node [create_node -n "&psu_pmu_0" -d "pcw.dtsi" -p root]
						} "microblaze" {
							set count [get_microblaze_nr $src_handle]
							set bus_name [detect_bus_name $src_handle]
							set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
							set node [create_node -n "cpu" -l "$src_handle" -u $count -d "pl.dtsi" -p $rt_node]
						} "ps7_cortexa9" {
							set index [string index $src_handle end]
							set node [create_node -n "&ps7_cortexa9_${index}" -d "pcw.dtsi" -p root]
						} "psx_cortexa78" {
							set index [string index $src_handle end]
							set node [create_node -n "&psx_cortexa78_${index}" -d "pcw.dtsi" -p root]
						} "psx_cortexr52" {
							set index [string index $src_handle end]
							set node [create_node -n "&psx_cortexr52_${index}" -d "pcw.dtsi" -p root]
						}
					}
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
	set val [hsi get_property ${parameter} $ip]
	dict set property_dict $cur_hw_design $drv_handle $parameter $val
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
		} elseif {[string match -nocase $intc_ipname "psu_acpu_gic"] || [string match -nocase $intc_ipname "psv_acpu_gic"] || [string match -nocase $intc_ipname "psx_acpu_gic"]} {
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

proc get_baseaddr {slave_ip {no_prefix ""}} {
	# only returns the first addr
	set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $slave_ip]]
	if {[string match -nocase $slave_ip "psu_sata"]} {
		set addr [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]]
	} else {
		set ip_mem_handle [lindex [hsi::get_mem_ranges [hsi::get_cells -hier $slave_ip]] 0]
		if {[string match -nocase $ip_name "psv_pmc_qspi"] || [string match -nocase $ip_name "psv_coresight"]} {
			# Currently addresses for ps mapping is coming from static dtsi files originating from u-boot
			# and it is very APU specific. To generate aliases, the code is also looking for those APU mapped
			# addresses. For pmc_qspi, there can be different MASTER INTERFACEs and hence the BASE_value changes
			# a/c to them. So, just as a workaround for the error during alias mapping for qspi, adding logic to
			# specifically fetch the A72_0 mapped address of pmc_qspi.
			set a72_0_proc [lindex [hsi get_cells -hier -filter IP_NAME==psv_cortexa72] 0]
			set ip_mem_handle [lindex [hsi::get_mem_ranges -of_objects $a72_0_proc [hsi::get_cells -hier $slave_ip]] 0]
		}
		if { [string_is_empty $ip_mem_handle] } {
			set avail_param [hsi list_property [hsi::get_cells -hier $slave_ip]]
			if {[lsearch -nocase $avail_param "CONFIG.C_BASEADDR"] >= 0 } {
				set addr [string tolower [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $slave_ip]]]
			} elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
				set addr [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]]
			} elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_CTRL_BASEADDR"] >= 0} {
				set addr [string tolower [hsi get_property CONFIG.C_S_AXI_CTRL_BASEADDR [hsi::get_cells -hier $slave_ip]]]
			} else {
				return ""
			}
		} else {
			set addr [string tolower [hsi get_property BASE_VALUE $ip_mem_handle]]
		}
	}
	if {![string_is_empty $no_prefix]} {
		regsub -all {^0x} $addr {} addr
		# Remove all the leading zeroes in the address.
		set addr [string trimleft $addr 0]
		if {[string_is_empty $addr]} {
			set addr "0"
		}
	}
	return $addr
}

proc get_highaddr {slave_ip {no_prefix ""}} {
	set ip_mem_handle [lindex [hsi::get_mem_ranges [hsi::get_cells -hier $slave_ip]] 0]
        if { [string_is_empty $ip_mem_handle] } {
             set avail_param [hsi list_property [hsi::get_cells -hier $slave_ip]]
             if {[lsearch -nocase $avail_param "CONFIG.C_HIGHADDR"] >= 0 } {
                    set addr [string tolower [hsi get_property CONFIG.C_HIGHADDR [hsi::get_cells -hier $slave_ip]]]
             } elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_HIGHADDR"] >= 0} {
                    set addr [string tolower [hsi get_property CONFIG.C_S_AXI_HIGHADDR [hsi::get_cells -hier $slave_ip]]]
             } elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_CTRL_HIGHADDR"] >= 0} {
                    set addr [string tolower [hsi get_property CONFIG.C_S_AXI_CTRL_HIGHADDR [hsi::get_cells -hier $slave_ip]]]
             } else {
                    return ""
             }
        } else {
		set addr [string tolower [hsi get_property HIGH_VALUE $ip_mem_handle]]
	}
	if {![string_is_empty $no_prefix]} {
		regsub -all {^0x} $addr {} addr
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

proc update_overlay_custom_dts_include {include_file} {
	set dt_overlay [hsi get_property CONFIG.dt_overlay [get_os]]
	set overlay_custom_dts [hsi get_property CONFIG.overlay_custom_dts [get_os]]
	set overlay_custom_dts_obj [get_dt_trees ${overlay_custom_dts}]
	if {[string_is_empty $overlay_custom_dts_obj] == 1} {
		set overlay_custom_dts_obj [set_cur_working_dts ${overlay_custom_dts}]
	}
	if {[string equal ${include_file} ${overlay_custom_dts_obj}]} {
		return 0
	}
	set cur_inc_list [hsi get_property INCLUDE_FILES $overlay_custom_dts_obj]
	set tmp_list [split $cur_inc_list ","]
	if { [lsearch $tmp_list $include_file] < 0} {
		if {[string_is_empty $cur_inc_list]} {
			set cur_inc_list $include_file
		} else {
			append cur_inc_list "," $include_file
			set field [split $cur_inc_list ","]
			set cur_inc_list [lsort -decreasing $field]
			set cur_inc_list [join $cur_inc_list ","]
		}
		set_property INCLUDE_FILES ${cur_inc_list} $overlay_custom_dts_obj
	}
}

proc update_system_dts_include {include_file} {
	# where should we get master_dts data
	global count
	set master_dts "system-top.dts"
	set proctype [get_hw_family]
	if {[regexp "microblaze" $proctype match]} {
		global env
		set path $env(REPO)
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
	set path $env(REPO)
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
	global env
	#set path $env(REPO)

	#set drvname [get_drivers $drv_handle]
	#set common_file "$path/device_tree/data/config.yaml"
	set common_file [file join [file dirname [dict get [info frame 0] file]] "config.yaml"]
	set dt_overlay [get_user_config $common_file -dt_overlay]
	set family [get_hw_family]
	global bus_clk_list
	set pl_ip [is_pl_ip $drv_handle]
	if {$pl_ip} {
		set default_dts "pl.dtsi"
		if {!$dt_overlay} {
			update_system_dts_include $default_dts
		}
	} else {
		# PS IP, read pcw_dts property
		set default_dts "pcw.dtsi"
		update_system_dts_include $default_dts
	}
	if {$pl_ip && $dt_overlay} {
		set fpga_node [create_node -n "fragment" -u 0 -d ${default_dts} -p root]
		set pl_file $default_dts
		set targets "fpga_full"
		add_prop $fpga_node target "$targets" reference $default_dts 1
		set child_name "__overlay__"
		set child_node [create_node -l "overlay0" -n $child_name -p $fpga_node -d $default_dts]
		add_prop "${child_node}" "#address-cells" 2 int $default_dts 1
		add_prop "${child_node}" "#size-cells" 2 int $default_dts 1
		if {[is_zynqmp_platform $family]} {
			set hw_name [::hsi::get_hw_files -filter "TYPE == bit"]
			add_prop "${child_node}" "firmware-name" "$hw_name.bin" string  $default_dts 1
			add_prop "root" "firmware-name" "$hw_name" string  $default_dts 1
		} elseif {[string match -nocase $family "versal"]} {
			set hw_name [::hsi::get_hw_files -filter "TYPE == pdi"]
			add_prop "${child_node}" "firmware-name" "$hw_name" string  $default_dts 1
			add_prop "root" "firmware-name" "$hw_name" string  $default_dts 1
		}
	}
	return $default_dts
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
	set ip_name [hsi get_property IP_NAME $ip_obj]
	set nochk_list "ai_engine noc_mc_ddr4 axi_noc"
	if {[lsearch $nochk_list $ip_name] >= 0} {
		dict set ip_type_dict $cur_hw_design $ip_inst 1
		return 1
	}
	#if {[catch {set proplist [hsi list_property [hsi::get_cells -hier $ip_inst]]} msg]} {
	#} else {
	#	if {[lsearch -nocase $proplist "IS_PL"] >= 0} {
			if {![catch {set prop [hsi get_property IS_PL [hsi::get_cells -hier $ip_inst]]} msg]} {
				#if {$prop} {
				#	return 1
				#} else {
				#	return 0
				#}
				dict set ip_type_dict $cur_hw_design $ip_inst $prop
				return $prop
			}
		#}
	#}
	#set ip_name [hsi get_property IP_NAME $ip_obj]
	if {![regexp "ps._*" "$ip_name" match]} {
		dict set ip_type_dict $cur_hw_design $ip_inst 1
		return 1
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
	if {$type == -1} return 0
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
	set family [get_hw_family]
	set def_ps_mapping [dict create]
	if {[string match -nocase $family "versal"]} {
		if { $is_versal_net_platform } {
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
			dict set def_ps_mapping f19e0000 label gem0
			dict set def_ps_mapping f19f0000 label gem1
			dict set def_ps_mapping f19d0000 label gpio0
			dict set def_ps_mapping f1020000 label gpio1
			dict set def_ps_mapping f1940000 label i2c0
			dict set def_ps_mapping f1950000 label i2c1
			dict set def_ps_mapping f1948000 label i3c0
			dict set def_ps_mapping f1958000 label i3c1
			dict set def_ps_mapping f1010000 label ospi
			dict set def_ps_mapping f1030000 label qspi
			dict set def_ps_mapping f12a0000 label rtc
			dict set def_ps_mapping f1040000 label sdhci0
			dict set def_ps_mapping f1050000 label sdhci1
			dict set def_ps_mapping f1920000 label serial0
			dict set def_ps_mapping f1930000 label serial1
			dict set def_ps_mapping ec000000 label smmu
			dict set def_ps_mapping f1960000 label spi0
			dict set def_ps_mapping f1970000 label spi1
			dict set def_ps_mapping f1dc0000 label ttc0
			dict set def_ps_mapping f1dd0000 label ttc1
			dict set def_ps_mapping f1de0000 label ttc2
			dict set def_ps_mapping f1df0000 label ttc3
			dict set def_ps_mapping f1e00000 label usb0
			dict set def_ps_mapping f1e10000 label usb1
			dict set def_ps_mapping ecc10000 label wwdt0
			dict set def_ps_mapping ecd10000 label wwdt1
			dict set def_ps_mapping ece10000 label wwdt2
			dict set def_ps_mapping ecf10000 label wwdt3
			dict set def_ps_mapping f0800000 label coresight
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
			dict set def_ps_mapping ff060000 label "can0: can"
			dict set def_ps_mapping ff070000 label "can1: can"
			dict set def_ps_mapping ff330000 label "ipi3: mailbox"
			dict set def_ps_mapping ff340000 label "ipi4: mailbox"
			dict set def_ps_mapping ff350000 label "ipi5: mailbox"
			dict set def_ps_mapping ff360000 label "ipi6: mailbox"
			dict set def_ps_mapping ff370000 label "ipi7: mailbox"
			dict set def_ps_mapping ff380000 label "ipi8: mailbox"
			dict set def_ps_mapping ff3a0000 label "ipi9: mailbox"
			dict set def_ps_mapping ff320000 label "ipi0: mailbox"
			dict set def_ps_mapping ff390000 label "ipi1: mailbox"
			dict set def_ps_mapping ff310000 label "ipi2: mailbox"
			dict set def_ps_mapping ff0e0000 label "ttc0: timer"
			dict set def_ps_mapping ff0f0000 label "ttc1: timer"
			dict set def_ps_mapping ff100000 label "ttc2: timer"
			dict set def_ps_mapping ff110000 label "ttc3: timer"
			dict set def_ps_mapping	f0280000 label "iomodule0: iomodule"
			dict set def_ps_mapping	ff9d0000 label "usb0: usb"
			dict set def_ps_mapping	fe200000 label "dwc3_0: dwc3"
			dict set def_ps_mapping f0800000 label "coresight: coresight"
			dict set def_ps_mapping f11c0000 label "dma0: pmcdma"
			dict set def_ps_mapping f11d0000 label "dma1: pmcdma"
			dict set def_ps_mapping f0920000 label "apm: performance-monitor"
			dict set def_ps_mapping f1270000 label "sysmon0: sysmon"
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
	return $def_ps_mapping
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
	set path $env(REPO)

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
						add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file 1
						add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file 1
						add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file 1
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
                       if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
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
                       if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"] } {
                               set index [check_64_base $reg $base $size]
                               if {$index == "true"} {
                                       continue
                               }
                       }
                       # ensure no duplication
                       if {![regexp ".*${reg}.*" "$base $size" matched]} {
                               if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
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
       if {[string match -nocase $proctype "microblaze"]} {
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
               if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
                       set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
               }
               foreach pin $pins {
                       if {[lsearch $clklist $pin] >= 0} {
                               set pl_clk $pin
                               set is_pl_clk 1
                       }
               }
               if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
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
	set path $env(REPO)
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
               if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
                       set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
               }
               foreach pin $pins {
                       if {[lsearch $clklist $pin] >= 0} {
                               set pl_clk $pin
                               set is_pl_clk 1
                       }
               }
               if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
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
	if {[is_ps_ip $drv_handle]} {
		return 0
	}
	global env
	set path $env(REPO)
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

	set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
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
				if {[is_zynqmp_platform $proctype]} {
					switch $num {
						"0" {
							set def_dts "pcw.dtsi"
							set fclk_node [create_node -n "&fclk0" -d $def_dts -p root]
							add_prop $fclk_node "status" "okay" string $def_dts

						}
						"1" {
							set def_dts "pcw.dtsi"
							set fclk_node [create_node -n "&fclk1" -d $def_dts -p root]
							add_prop $fclk_node "status" "okay" string $def_dts
						}
						"2" {
							set def_dts "pcw.dtsi"
							set fclk_node [create_node -n "&fclk2" -d $def_dts -p root]
							add_prop $fclk_node "status" "okay" string $def_dts
						}
						"3" {
							set def_dts "pcw.dtsi"
							set fclk_node [create_node -n "&fclk3" -d $def_dts -p root]
							add_prop $fclk_node "status" "okay" string $def_dts
						}
					}
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
					add_prop $misc_clk_node "compatible" "fixed-clock" stringlist $dts_file 1
					add_prop $misc_clk_node "#clock-cells" 0 int $dts_file 1
					add_prop $misc_clk_node "clock-frequency" $clk_freq int $dts_file 1
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
				if { $is_versal_net_platform } {
					set versal_periph [hsi get_cells -hier -filter {IP_NAME == psx_wizard}]
				} else {
					set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
				}
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
			if { $is_versal_net_platform } {
				set versal_periph [hsi get_cells -hier -filter {IP_NAME == psx_wizard}]
			} else {
				set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
			}
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
				set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
				-d ${dts_file} -p ${bus_node}]
				if {[catch {set compatible [pldt get $misc_clk_node "compatible"]} msg]} {
				add_prop $misc_clk_node "compatible" "fixed-clock" stringlist $dts_file 1
				add_prop $misc_clk_node "#clock-cells" 0 int $dts_file 1
				add_prop $misc_clk_node "clock-frequency" $clk_freq int $dts_file 1
				}
				set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
				set updat [lappend updat misc_clk_${bus_clk_cnt}]
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
	set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic psx_acpu_gic"
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
			if { [is_intr_cntrl $connectip] == 1 } {
				set intc $connectip
			}
		}
	}

	set proctype [get_hw_family]
	set bus_name [detect_bus_name $cpu_handle]
	set count [get_microblaze_nr $cpu_handle]
	set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
	set cpu_node [create_node -n "cpu" -l "$cpu_handle" -u $count -d "pl.dtsi" -p $rt_node]

	if {[is_pl_ip $intc]} {
		global dup_periph_handle
		if { [dict exists $dup_periph_handle $intc] } {
			set intc [dict get $dup_periph_handle $intc]
		} else {
			set intc $intc
		}
	}
	add_prop $cpu_node "interrupt-handle" $intc reference "pl.dtsi" 1
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
        } elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "xlconcat"] } {
           set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "dout"]]
        } elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "xlslice"] } {
            set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "Dout"]]
        } elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "util_reduced_logic"] } {
            set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "Res"]]
        }  elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
		set intr [hsi::get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}]
		set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "$intr"]]
	}
    }
    return $intr_cntrl
}

proc gen_interrupt_property {drv_handle {intr_port_name ""}} {
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
		if {[llength $connected_intc] == 0 || [string match $connected_intc "{}"] } {
			if {![string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_intc"]} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected to any interrupt controller\n\r"
			}
			continue
		}
		set connected_intc_name [hsi get_property IP_NAME $connected_intc]
		set valid_gpio_list "ps7_gpio axi_gpio"
		set valid_cascade_proc "microblaze zynq zynqmp zynquplus versal zynquplusRFSOC"
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
			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype]} {
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
			set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic psx_acpu_gic"
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
			} elseif {[string match -nocase $intc_name "psu_acpu_gic"] || [string match -nocase $intc_name "psv_acpu_gic"] || [string match -nocase $intc_name "psx_acpu_gic"]} {
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
	set_drv_prop $drv_handle interrupts $intr_info $node intlist
	if {[string_is_empty $intc_name]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]
	set intc_len [llength $intc]
	if {$intc_len > 1} {
		foreach intc_ctr $intc { 
			set intc_ctr [hsi get_property IP_NAME [hsi::get_cells -hier $intc]]
			if { [string match -nocase $intc_ctr "psu_acpu_gic"] || [string match -nocase $intc_ctr "psv_acpu_gic"] || [string match -nocase $intc_ctr "psx_acpu_gic"]} {
				set intc "gic"
			}
		}
	} else {
		if { [string match -nocase $intc_name "psu_acpu_gic"] || [string match -nocase $intc_name "psv_acpu_gic"] || [string match -nocase $intc_name "psx_acpu_gic"]} {
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

proc gen_reg_property {drv_handle {skip_ps_check ""}} {
	proc_called_by
        set unit_addr [get_baseaddr ${drv_handle} no_prefix]
	if {$unit_addr == "" } {
		return 0
	}
	set ps_mapping [gen_ps_mapping]
	if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg]} {
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
	if {$ip_name == "xxv_ethernet" || $ip_name == "ddr4" || $ip_name == "psu_acpu_gic" || $ip_name == "mrmac" || $ip_name == "axi_noc"} {
		return
	}

	set reg ""
	set slave [hsi::get_cells -hier ${drv_handle}]
	set ip_mem_handles [hsi::get_mem_ranges $slave]
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
		}
		if {![string_is_empty $base]} {
			if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [is_zynqmp_platform $proctype]} {
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

			set_drv_prop_if_empty $drv_handle reg $reg $node hexlist
		}

		return
	}
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

			if {[string_is_empty $reg]} {
				if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [is_zynqmp_platform $proctype]} {
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
				if {[string match -nocase $proctype "zynq"] || [regexp "microblaze" $proctype match]} {
					set index [check_base $reg $base $size]
					if {$index == "true" && $ip_name != "axi_fifo_mm_s"} {
						continue
					}
				}
				if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [is_zynqmp_platform $proctype]} {
					set index [check_64_base $reg $base $size]
					if {$index == "true" && $ip_name != "axi_fifo_mm_s"} {
						continue
					}
				}
				# ensure no duplication
				if {![regexp ".*${reg}.*" "$base $size" matched]} {
					if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [is_zynqmp_platform $proctype]} {
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
	set_drv_prop_if_empty $drv_handle reg $reg $node hexlist
	set ip_name [get_ip_property $drv_handle IP_NAME]
	if {[string match -nocase $ip_name "psv_pciea_attrib"]} {
		set ranges " 0x02000000 0x00000000 0xe0000000 0x0 0xe0000000 0x00000000 0x10000000>, \n\t\t\t      <0x43000000 0x00000080 0x00000000 0x00000080 0x00000000 0x00000000 0x80000000"
		add_prop $node "ranges" $ranges hexlist "pcw.dtsi"
	}
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
	if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg]} {
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
	if {[string match -nocase $proctype "processor"] && ![string match -nocase $ip_name "microblaze"]} {
		return 0
	}
	set comp_prop [gen_compatible_string $slave]
	if {[string match -nocase $ip_name "psv_pciea_attrib"]} {
		set index [string index $drv_handle end]
		set comp_prop "${comp_prop}${index}"
	}
	regsub -all {_} $comp_prop {-} comp_prop
	if {[string match -nocase $proctype "processor"]} {
		set proctype [get_hw_family]
		set bus_name [detect_bus_name $drv_handle]
		set count [get_microblaze_nr $drv_handle]
		set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
		set node [create_node -n "cpu" -l "$drv_handle" -u $count -d "pl.dtsi" -p $rt_node]
		add_prop $node compatible "$comp_prop xlnx,microblaze" stringlist "pl.dtsi"	
	} else {
		set node [get_node $drv_handle]
		set_drv_prop_if_empty $drv_handle compatible $comp_prop $node stringlist
		if {[string match -nocase $ip_name "dfx_axi_shutdown_manager"]} {
			pldt append $node compatible "\ \, \"xlnx,dfx-axi-shutdown-manager-1.00\""
			pldt append $node compatible "\ \, \"xlnx,dfx-axi-shutdown-manager\""
		}
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
		set ignore_ip_props "CONFIG.C_AXIS_SIGNAL_SET CONFIG.C_USE_BRAM_BLOCK CONFIG.C_ALGORITHM \
			CONFIG.C_AXI_TYPE CONFIG.C_INTERFACE_TYPE CONFIG.C_AXI_SLAVE_TYPE CONFIG.device_port_type \
			CONFIG.C_AXI_WRITE_BASEADDR_SLV CONFIG.C_AXI_WRITE_HIGHADDR_SLV CONFIG.C_PVR_USER1 \
			CONFIG.Component_Name CONFIG.C_FAMILY"
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
			regsub -all {^CONFIG.} $drv_prop_name {xlnx,} drv_prop_name
			regsub -all {_} $drv_prop_name {-} drv_prop_name
			set drv_prop_name [string tolower $drv_prop_name]
			if {[string match -nocase $drv_prop_name "xlnx,include-sg"] || [string match -nocase $drv_prop_name "xlnx,sg-include-stscntrl-strm"]} {
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
			set type "int"
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
	}
	foreach prop $par_handles {
		set temp [regsub -all {^CONFIG.} $prop ""]
		set temp [regsub -all {^C_} $temp ""]
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
		if { $ps_ip } {
			set tmp_par $par
		} else {
			regsub -all {CONFIG.} $par {} tmp_par
		}
		# Ignore some parameters that are always handled specially
		
		if {$ps_ip} {
			lappend valid_prop_names $par
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
			set path $env(REPO)

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
		if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg]} {
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
	global env
	set path $env(REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set dt_overlay [get_user_config $common_file -dt_overlay]
        if {$dt_overlay} {
                set ignore_list "lmb_bram_if_cntlr PERIPHERAL axi_noc dfx_decoupler mig_7series"
        } else {
                set ignore_list "lmb_bram_if_cntlr PERIPHERAL axi_noc mig_7series"
        }
	if {[string match -nocase $ip_type "psu_pcie"]} {
		set pcie_config [hsi get_property CONFIG.C_PCIE_MODE [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $pcie_config "Endpoint Device"]} {
			lappend ignore_list $ip_type
		}
		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		add_prop $node "xlnx,port-type" 0x1 hexint "pcw.dtsi" 1
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
		} elseif {[string match -nocase $ip_type "psx_rcpu_gic"] } {
			set label "gic_r52"
		} else {
		}

		# check if it has status property
		set rt_node [get_node $drv_handle]
		if {[string match -nocase $ip_type "psv_rcpu_gic"] || [string match -nocase $ip_type "psu_rcpu_gic"]} {
			set node [create_node -n "&gic_r5" -d "pcw.dtsi" -p root]
			add_prop $node "status" "okay" string $default_dts
		} elseif {[string match -nocase $ip_type "psx_rcpu_gic"]} {
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
			if {[string match -nocase $proc_type "psx_cortexa78"] && [string match -nocase $ip_type "psx_rcpu_gic"]} {
				return
			}
			if {[string match -nocase $proc_type "psx_cortexr52"] && [string match -nocase $ip_type "psx_acpu_gic"]} {
				return
			}
			}
			add_prop $rt_node "status" "okay" string $default_dts 
		}
	} else {
		if {[string match -nocase $ip_type "tsn_endpoint_ethernet_mac"]} {
			set rt_node [create_node -n tsn_endpoint_ip_0 -l tsn_endpoint_ip_0 -d $default_dts -p $bus_node] 
		} else {
			set valid_proclist "psv_cortexa72 psv_cortexr5 psu_cortexa53 psu_cortexr5 psu_pmu psv_pmc psv_psm ps7_cortexa9 psx_cortexa78 psx_cortexr52 psx_pmc psx_psm"
			if {[lsearch $valid_proclist $ip_type] >= 0} {
				switch $ip_type {
					"psv_cortexa72" {
						set index [string index $drv_handle end]
						set rt_node [create_node -n "&psv_cortexa72_${index}" -d ${default_dts} -p root]
					} "psv_cortexr5" {
						set index [string index $drv_handle end]
						set rt_node [create_node -n "&psv_cortexr5_${index}" -d ${default_dts} -p root]
					} "psv_pmc" {
						set rt_node [create_node -n "&psv_pmc_0" -d ${default_dts} -p root]
					} "psv_psm" {
						set rt_node [create_node -n "&psv_psm_0" -d "pcw.dtsi" -p root]
					} "psu_cortexa53" {
						set index [string index $src_handle end]
						set node [create_node -n "&psu_cortexa53_${index}" -d "pcw.dtsi" -p root]
					} "psu_cortexr5" {
						set index [string index $src_handle end]
						set node [create_node -n "&psu_cortexr5_${index}" -d "pcw.dtsi" -p root]
					} "psu_pmu" {
						set node [create_node -n "&psu_pmu_0" -d "pcw.dtsi" -p root]
					} "ps7_cortexa9" {
						set index [string index $drv_handle end]
						set node [create_node -n "&ps7_cortexa9_${index}" -d "pcw.dtsi" -p root]
					} "psx_cortexa78" {
						set index [string index $drv_handle end]
						set rt_node [create_node -n "&psx_cortexa78_${index}" -d ${default_dts} -p root]
					} "psx_cortexr52" {
						set index [string index $drv_handle end]
						set rt_node [create_node -n "&psx_cortexr52_${index}" -d ${default_dts} -p root]
					} "psx_psm" {
						set rt_node [create_node -n "&psx_psm_0" -d ${default_dts} -p root]
					} "psx_pmc" {
						set rt_node [create_node -n "&psx_pmc_0" -d ${default_dts} -p root]
					} 
				}
			} else {
				if {[string match -nocase $ip_type "microblaze"]} {
					set proctype [get_hw_family]
					set bus_name [detect_bus_name $drv_handle]
					set count [get_microblaze_nr $drv_handle]
					set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d ${default_dts} -p $bus_name]
					set rt_node [create_node -n "cpu" -l "$drv_handle" -u $count -d "pl.dtsi" -p $rt_node]
				} else {
					if {[string match -nocase $dev_type "psv_fpd_smmutcu"]} {
							set dev_type "psv_fpd_maincci"
					}
					set t [get_ip_property $drv_handle IP_NAME]
					set rt_node [create_node -n ${dev_type} -l ${label} -u ${unit_addr} -d ${default_dts} -p $bus_node]
				}
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

	set valid_proc_list "ps7_cortexa9 psu_cortexa53 psv_cortexa72 psv_cortexr5 psv_pmc psu_pmu psu_cortexr5 psx_cortexa78 psx_cortexr52 psx_pmc psx_psm" 
	global env
	set path $env(REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set dt_overlay [get_user_config $common_file -dt_overlay]
		if {[is_pl_ip $ip_drv] && $dt_overlay} {
			# create the parent_node for pl.dtsi
			set default_dts [set_drv_def_dts $ip_drv]
			set fpga_node [create_node -n "fragment" -u 2 -d $default_dts -p root]
			set targets "amba"
			add_prop $fpga_node target "$targets" reference $default_dts 1
			set child_name "__overlay__"
			set bus_node [create_node -l "overlay2" -n $child_name -p $fpga_node -d $default_dts]
			return "overlay2: __overlay__"
		}
		if {[is_pl_ip $ip_drv]}  {
			# create the parent_node for pl.dtsi
			set default_dts [set_drv_def_dts $ip_drv]
			set root_node [create_node -n "amba_pl" -l "amba_pl" -d ${default_dts} -p root]
			return "amba_pl: amba_pl"
		}
		if {[string match -nocase $ip_drv "psu_acpu_gic"] || [string match -nocase $ip_drv "psv_acpu_gic"] || [string match -nocase $ip_drv "psx_acpu_gic"]} {
			return "amba_apu: apu-bus"
		}
		if {[string match -nocase $ip_drv "psu_rcpu_gic"] || [string match -nocase $ip_drv "psv_rcpu_gic"] || [string match -nocase $ip_drv "psx_rcpu_gic"]} {
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
	proc_called_by
	set bus_name [detect_bus_name $ip_drv]
	dtg_debug "bus_name: $bus_name"
	dtg_debug "bus_label: $bus_name"
	global env
	set path $env(REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set dt_overlay [get_user_config $common_file -dt_overlay]
	set proctype [get_hw_family]
	if {[is_pl_ip $ip_drv] && $dt_overlay} {
		set dts "pl.dtsi"
		set fpga_node [create_node -n "fragment" -u 2 -d $dts -p root]
		set targets "amba"
		add_prop $fpga_node target "$targets" reference $dts 1
		set child_name "__overlay__"
		set bus_node [create_node -l "overlay2" -n $child_name -p $fpga_node -d $dts]
		if {[is_zynqmp_platform $proctype] || [string match -nocase $proctype "versal"]} {
			add_prop "${bus_node}" "#address-cells" 2 int $dts 1
			add_prop "${bus_node}" "#size-cells" 2 int $dts 1
		} else {
			add_prop "${bus_node}" "#address-cells" 1 int $dts 1
			add_prop "${bus_node}" "#size-cells" 1 int $dts 1
		}
	} else {
		set bus_node $bus_name
		if {[string match -nocase $bus_node "amba_pl: amba_pl"]} {
			if {[is_zynqmp_platform $proctype] || [string match -nocase $proctype "versal"]} {
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
	set clk_subnode [create_node -l ${clk_subnode_name} -n ${clk_subnode_name} -u $reg -p ${clk_node} -d ${default_dts}]
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
	gen_mb_ccf_subnode $drv_handle cpu $cpu_clk_freq 0
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
		set valid_cascade_proc "microblaze zynq zynqmp zynquplus zynquplusRFSOC versal"
		set proctype [get_hw_family]
		if { [string match -nocase [hsi get_property IP_NAME $periph] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0 } {
			set sinks [get_sink_pins $intr_pin]
			foreach intr_sink ${sinks} {
				set sink_periph [hsi::get_cells -of_objects $intr_sink]
				if { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "axi_intc"] } {
					# this the case where interrupt port is connected to axi_intc.
					lappend intr_cntrl [get_intr_cntrl_name $sink_periph "irq"]
				} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "xlconcat"] } {
					# this the case where interrupt port is connected to XLConcat IP.
					lappend intr_cntrl [get_intr_cntrl_name $sink_periph "dout"]
				} elseif { [llength $sink_periph ] && [is_intr_cntrl $sink_periph] == 1 } {
					lappend intr_cntrl $sink_periph
				} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "microblaze"] } {
					lappend intr_cntrl $sink_periph
				} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "tmr_voter"] } {
					lappend intr_cntrl $sink_periph
				} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "dfx_decoupler"] } {
					set intr [hsi::get_pins -of_objects $sink_periph -filter {TYPE==INTERRUPT&&DIRECTION==O}
					lappend intr_cntrl [get_intr_cntrl_name $sink_periph "$intr"]
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
	set valid_cascade_proc "microblaze zynq zynqmp zynquplus zynquplusRFSOC versal"
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
		} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "xlconcat"] } {
			# this the case where interrupt port is connected to XLConcat IP.
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "dout"]
		} elseif { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "xlslice"]} {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Dout"]
		} elseif {[llength $sink_periph] &&  [string match -nocase [hsi get_property IP_NAME $sink_periph] "util_reduced_logic"]} {
			lappend intr_cntrl [get_intr_cntrl_name $sink_periph "Res"]
		} elseif {[llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "axi_gpio"]} {
			set intr_present [hsi get_property CONFIG.C_INTERRUPT_PRESENT $sink_periph]
			if {$intr_present == 1} {
				lappend intr_cntrl $sink_periph
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
		if { [llength $sink_periph] && [string match -nocase [hsi get_property IP_NAME $sink_periph] "xlconcat"] } {
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
	} elseif { [string match -nocase $IP_NAME "psu_acpu_gic"] || [string match -nocase $IP_NAME "psv_acpu_gic"] || [string match -nocase $IP_NAME "psx_acpu_gic"]} {
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
	if { $ipname == "xlconcat" } {
		set intf "dout"
		set intr1_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$intf"]
		set intr_sink_pins [get_sink_pins $intr1_pin]
		set sink_periph [hsi::get_cells -of_objects $intr_sink_pins]
		set ipname [hsi get_property IP_NAME $sink_periph]
		if {$ipname == "util_reduced_logic"} {
			set width [hsi get_property CONFIG.C_SIZE $sink_periph]
			return $width
		}
	}

	return $ret
}

#TODO: cache the data
proc get_psu_interrupt_id { ip_name port_name } {
	proc_called_by
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
			if {[string match -nocase $periph_ip "xlconcat"]} {
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
			if {[string match -nocase $periph_ip "xlconcat"]} {
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
		if { [string compare -nocase "$connected_ip" "xlconcat"] == 0 } {
	               set pin_number [regexp -all -inline -- {[0-9]+} $sink_pin]
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
	                set sink_periph [::hsi::get_cells -of_objects $sink_pins]
	                set connected_ip [hsi get_property IP_NAME [hsi::get_cells -hier $sink_periph]]
	                while {[llength $connected_ip]} {
				if {![string match -nocase "$connected_ip" "xlconcat"]} {
					break
				}
	                       set dout "dout"
	                       set intr_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$dout"]
	                       set sink_pins [get_sink_pins $intr_pin]
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
	# check for ORgate
	if { [string compare -nocase "$sink_pin" "Op1"] == 0 } {
		set dout "Res"
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
					if { [string compare -nocase "$connected_ip" "xlconcat"] == 0 } {
						set number [regexp -all -inline -- {[0-9]+} $sink_pin]
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
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq0"] == 0} {
		set ret 84
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq1"] == 0} {
		set ret 85
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq2"] == 0} {
		set ret 86
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq3"] == 0} {
		set ret 87
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq4"] == 0} {
		set ret 88
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq5"] == 0} {
		set ret 89
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq6"] == 0} {
		set ret 90
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq7"] == 0} {
		set ret 91
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq8"] == 0} {
		set ret 92
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq9"] == 0} {
		set ret 93
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq10"] == 0} {
		set ret 94
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq11"] == 0} {
		set ret 95
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq12"] == 0} {
		set ret 96
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq13"] == 0} {
		set ret 97
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq14"] == 0} {
		set ret 98
	} elseif { [string compare -nocase "$sink_pin" "pl_ps_irq15"] == 0} {
		set ret 99
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
   } elseif {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
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
