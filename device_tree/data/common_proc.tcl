#
# (C) Copyright 2014-2021 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
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

#
# common procedures
#

# global variables

#namespace export get_drivers
#namespace export gen_root_node
global def_string zynq_soc_dt_tree bus_clk_list pl_ps_irq1 pl_ps_irq0 pstree include_list count intrpin_width
global or_id
global or_cnt
global repo_path
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
	lappend items ps7_pmu cpu
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
}

global set duplist [dict create]
global set osmap [dict create]
global set microblaze_map [dict create]
global set mc_map [dict create]
global set memmap [dict create]
global set label_addr [dict create]
global set label_type [dict create]
global set end_mappings [dict create]
global set remo_mappings [dict create]
global set port1_end_mappings [dict create]
global set port2_end_mappings [dict create]
global set port3_end_mappings [dict create]
global set port4_end_mappings [dict create]
global set axis_port1_remo_mappings [dict create]
global set axis_port2_remo_mappings [dict create]
global set axis_port3_remo_mappings [dict create]
global set axis_port4_remo_mappings [dict create]
global set port1_broad_end_mappings [dict create]
global set port2_broad_end_mappings [dict create]
global set port3_broad_end_mappings [dict create]
global set port4_broad_end_mappings [dict create]
global set port5_broad_end_mappings [dict create]
global set port6_broad_end_mappings [dict create]
global set broad_port1_remo_mappings [dict create]
global set broad_port2_remo_mappings [dict create]
global set broad_port3_remo_mappings [dict create]
global set broad_port4_remo_mappings [dict create]
global set broad_port5_remo_mappings [dict create]
global set broad_port6_remo_mappings [dict create]
global set axis_switch_in_end_mappings [dict create]
global set axis_switch_port1_end_mappings [dict create]
global set axis_switch_port2_end_mappings [dict create]
global set axis_switch_port3_end_mappings [dict create]
global set axis_switch_port4_end_mappings [dict create]
global set axis_switch_in_remo_mappings [dict create]
global set axis_switch_port1_remo_mappings [dict create]
global set axis_switch_port2_remo_mappings [dict create]
global set axis_switch_port3_remo_mappings [dict create]
global set axis_switch_port4_remo_mappings [dict create]

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

set repo_path ""
set or_id 0
set or_cnt 0
set tree {}
set include_list ""
set pstree 0

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

proc get_microblaze_nr {drv_handle} {
	global microblaze_map
	set proctype [get_hw_family]
	set microblaze_proc [hsi::get_cells -hier -filter {IP_NAME==microblaze}]
	set theValue 1
	if {[llength $microblaze_proc] >= 0} {
	if {[catch {set rt [dict get $microblaze_map $drv_handle]} msg]} {
		if {[catch {set len [dict size $microblaze_map]} msg]} {
			set theValue 0
		}
		if {$theValue != 0} {
			foreach theKey [dict keys $microblaze_map] {
				set theValue [dict get $microblaze_map $theKey]
			}
		}
		if {[string match -nocase $proctype "versal"]} {
			if {$theValue } {
				set val [expr $theValue + 1]
				dict set microblaze_map $drv_handle $val
				return $val
			} else {
				dict set microblaze_map $drv_handle 3
				return 3
			}
		} elseif {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
			if {$theValue } {
				set val [expr $theValue + 1]
				dict set microblaze_map $drv_handle $val
				return $val
			} else {
				dict set microblaze_map $drv_handle 2
				return 2
			}
		}
	} else {
		return $rt
	}	
	}
}
proc get_driver_param args {
	global driver_param
	set drv_handle [lindex $args 0]
	set type [lindex $args 1]
	set val ""
	set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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

proc remove_duplicate_addr {} {
	global duplist
	set val [hsi::get_cells -hier]
	global mainlist
	global addrlist
	set mainlist ""
	set addrlist ""
	set ignorelist "psu_iou_s zynq_ultra_ps_e_0 versal_cips displayport v_tc"
	foreach v $val {
		set nested 0
		if {[is_ps_ip $v] == 1} {
			continue
		}
		set main_base [get_baseaddr $v]
		if {$main_base == ""} {
			continue
		}
		set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $v]]
		if {[lsearch $ignorelist $ip_name] >= 0} {
			continue
		}
		if {[lsearch $addrlist $main_base] >= 0} {
			if {[catch {set rt [dict get $duplist $main_base]} msg]} {
				continue
			} else {
				set matchip_name [hsi get_property IP_NAME [hsi::get_cells -hier $rt]]
				if {[string match -nocase $matchip_name $ip_name]} {
					continue
				}
				set nested 1
			}
		} else {
			append mainlist " " $v
			append addrlist " " $main_base
			if {$nested == 1} {
				dict lappend duplist $main_base $v
			} else {
				dict set duplist $main_base $v
			}
		}
	}	
	set values [dict keys $duplist]
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
						} else {
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

proc get_hw_family {} {
	set prop [hsi get_property FAMILY [hsi::get_hw_designs]]
	return $prop
}

proc get_dt_data args {
	global env
	set path $env(REPO)
	set prop [lindex $args 1]
	set drv_handle [lindex $args 0]
	set drvname [get_drivers $drv_handle]
	set common_file "$path/$drvname/data/config.yaml"
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	} else {
		return ""
	}
	set value [get_driver_config $drv_handle $prop]

	return $value
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

	proc_called_by
	set handle [lindex $args 0]
	set non_val_list "versal_cips noc_nmu noc_nsu ila zynq_ultra_ps_e psu_iou_s smart_connect noc_nsw"
	set non_val_ip_types "MONITOR BUS PROCESSOR"
	set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $handle]]
	set ip_type [hsi get_property IP_TYPE [hsi::get_cells -hier $handle]]
	if {[lsearch -nocase $non_val_list $ip_name] >= 0} {
		return ""
	}
	if {[lsearch -nocase $non_val_ip_types $ip_type] >= 0 && ![string match -nocase "axi_perf_mon" $ip_name]} {
		return ""
	}

	if {[is_ps_ip $handle]} {
		set dts_file "versal.dtsi"
	} else {
		set dts_file [set_drv_def_dts $handle]
	}
	set dts_file [set_drv_def_dts $handle]
	set ip_type [hsi get_property IP_TYPE [hsi::get_cells -hier $handle]]
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
	set childs [$treeobj children $busname]
	foreach child $childs {
	}
	set dev_type [hsi get_property IP_NAME [hsi::get_cells -hier $handle]]
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

	return $node
}

proc get_prop args {
	proc_called_by
	set handle [lindex $args 0]
	set property [lindex $args 1]
	set dts_file [set_drv_def_dts $handle]]
	set ip_type [hsi get_property IP_TYPE [hsi::get_cells -hier $handle]]

	if {[string match -nocase $ip_type "PROCESSOR"]} {
		set busname root
	} else {
		set busname [detect_bus_name $handle]
	}
	set addr [get_baseaddr $handle]
	if {[string match -nocase $dts_file "pcw.dtsi"]} {
		set treeobj "pcwdt"
	} elseif {[string match -nocase $dts_file "pl.dtsi"]} {
		set treeobj "pldt"
	} elseif {[string match -nocase $dts_file "versal.dtsi"]} {
		set treeobj "psdt"
	} else {
		set treeobj "systemdt"
	}
	set childs [$treeobj children $busname]
	foreach child $childs {
	}
	set label [hsi get_property IP_NAME [hsi::get_cells -hier $handle]]
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
	set ignore_list "fifo_generator clk_wiz clk_wizard xlconcat xlconstant util_vector_logic xlslice util_ds_buf proc_sys_reset axis_data_fifo v_vid_in_axi4s bufg_gt axis_tdest_editor util_reduced_logic gt_quad_base noc_nsw blk_mem_gen emb_mem_gen lmb_bram_if_cntlr perf_axi_tg noc_mc_ddr4 c_counter_binary timer_sync_1588 oddr axi_noc mailbox dp_videoaxi4s_bridge axi4svideo_bridge axi_vip"
	set temp [lsearch $ignore_list $node_name]
	if {[string match -nocase $node_unit_addr ""] && $temp >= 0 } {
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
	if {[catch {set tmp [dict get $ps_mapping $node_unit_addr label]} msg]} {
	} else {
		set new_name "&$node_name"
	}
	}
	if {[string match -nocase $node_name "amba_pl: amba_pl"] || 
		[string match -nocase $node_name "amba: amba"] ||
		[string match -nocase $node_name "amba_apu: amba_apu"] ||
                [string match -nocase $node_name "amba_rpu: amba_rpu"]} {	
	} else {
		set busname [detect_bus_name $node_name]
	}
	if {[string match -nocase $node_name "amba_pl: amba_pl"] || 
		[string match -nocase $node_name "amba: amba"] ||
		[string match -nocase $node_name "amba_rpu: amba_rpu"] ||
		[string match -nocase $node_name "amba_apu: amba_apu"] || [string match -nocase $node_name "root"]} {	
		set mainroot [$treeobj children root]
		
		if {[string match -nocase $mainroot ""]} {
			if {[string match $node_name "amba_pl: amba_pl"]} {
				
				set interconnect [$treeobj insert root end "amba_pl: amba_pl"]
			}	
			if {[string match $node_name "amba: amba"]} {
				set interconnect [$treeobj insert root end "amba: amba"]
			}	
			if {[string match $node_name "amba_apu: amba_apu"]} {
				set interconnect [$treeobj insert root end "amba_apu: amba_apu"]
			}
			if {[string match $node_name "amba_rpu: amba_rpu"]} {
                                set interconnect [$treeobj insert root end "amba_rpu: amba_rpu"]
                        }
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "amba_pl: amba_pl"]} {
				set interconnect [$treeobj insert root end "amba_pl: amba_pl"]
			}	
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "amba: amba"]} {
				set interconnect [$treeobj insert root end "amba: amba"]
			}	
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "amba_apu"]} {
				set interconnect [$treeobj insert root end "amba_apu: amba_apu"]
			}	
			if {[string match -nocase $node_name "root"] && [string match $parent_obj "amba_rpu"]} {
                                set interconnect [$treeobj insert root end "amba_rpu: amba_rpu"]
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
	foreach val $args {
		incr count
	}
	set node [lindex $args 0]
	set prop [lindex $args 1]


	if {$count > 4} {
		set val [lindex $args 2]
		set type [lindex $args 3]
		set dts_file [lindex $args 4]
	} else {
		set val ""
		set type [lindex $args 2]
		set dts_file [lindex $args 3]
	}
	if {$count > 5} {
		set overwrite [lindex $args 5]
	}

	if {[string match -nocase $node "&gic"]} {
	}
	if {[string match -nocase $dts_file "pcw.dtsi"]} {

	}

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
		set temp [$treeobj children root]
		foreach kid $temp {
			foreach nkid [$treeobj children $kid] {
				if {[string match -nocase $nkid $node]} {
				}
			}
		}
		set node [string trimleft $node "\{"]
		set node [string trimright $node "\}"]
		if {$bypass == 0} {
			if {[string match -nocase $prop "reg"]} {
			}
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

proc line_to_node_val {line} {
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
	if {[info exists env(include_dts)]} {
		set include_dts $env(include_dts)
	} else {
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
	dict set driverlist noc_mc_ddr4 driver ddrpsv
	dict set driverlist debug_bridge driver debug_bridge
	dict set driverlist v_demosaic driver demosaic
	dict set driverlist ps7_dev_cfg driver devcfg
	dict set driverlist ps7_dma driver dmaps
	dict set driverlist psu_gdma driver dmaps
	dict set driverlist psu_csudma driver dmaps
	dict set driverlist psv_adma driver dmaps
	dict set driverlist psv_gdma driver dmaps
	dict set driverlist psv_csudma driver dmaps
	dict set driverlist psu_dp driver dp
	dict set driverlist psv_dp driver dp
	dict set driverlist dpu_eu driver dpu_eu
	dict set driverlist axi_ethernetlite driver emaclite
	dict set driverlist ps7_ethernet driver emacps
	dict set driverlist psu_ethernet driver emacps
	dict set driverlist psv_ethernet driver emacps
	dict set driverlist ernic driver ernic
	dict set driverlist v_frmbuf_rd driver framebuf_rd
	dict set driverlist v_frmbuf_wr driver framebuf_wr
	dict set driverlist v_gamma_lut driver gamma_lut
	dict set driverlist ps7_globaltimer driver globaltimerps
	dict set driverlist ps7_gpio driver gpiops
	dict set driverlist psu_gpio driver gpiops
	dict set driverlist psv_gpio driver gpiops
	dict set driverlist hdmi_acr_ctlr driver hdmi_ctrl
	dict set driverlist hdmi_gt_controller driver hdmi_gt_ctrl
	dict set driverlist v_hdmi_rx_ss driver hdmi_rx_ss
	dict set driverlist v_hdmi_tx_ss driver hdmi_tx_ss
	dict set driverlist i2s_receiver driver i2s_receiver
	dict set driverlist i2s_transmitter driver i2s_transmitter
	dict set driverlist ps7_i2c driver iicps
	dict set driverlist psu_i2c driver iicps
	dict set driverlist psv_i2c driver iicps
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
	dict set driverlist ps7_pmu driver pmups
	dict set driverlist psu_pmu driver pmups
	dict set driverlist psv_pmc driver pmups
	dict set driverlist psv_psm driver pmups
	dict set driverlist pr_decoupler driver pr_decoupler
	dict set driverlist prc driver prc
	dict set driverlist dfx_controller driver prc
	dict set driverlist psu_ocm_ram_0 driver psu_ocm
	dict set driverlist psv_ocm_ram_0 driver psu_ocm
	dict set driverlist ps7_ram driver ramps
	dict set driverlist usp_rf_data_converter driver rfdc
	dict set driverlist v_scenechange driver scene_change_detector
	dict set driverlist ps7_scugic driver scugic
	dict set driverlist psu_acpu_gic driver scugic
	dict set driverlist psv_acpu_gic driver scugic
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
	dict set driverlist ps7_slcr driver slcrps
	dict set driverlist ps7_smcc driver smccps
	dict set driverlist ps7_spi driver spips
	dict set driverlist psu_qspi driver spips
	dict set driverlist psv_pmc_qspi driver qspips
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
	dict set driverlist mdm driver uartlite
	dict set driverlist axi_uartlite driver uartlite
	dict set driverlist axi_uart16550 driver uartns
	dict set driverlist ps7_uart driver uartps
	dict set driverlist psu_uart driver uartps
	dict set driverlist psu_sbsauart driver uartps
	dict set driverlist psv_uart driver uartps
	dict set driverlist psv_sbsauart driver uartps
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
			if {[string match -nocase [hsi get_property IP_TYPE [hsi::get_cells -hier $drv_handle]] "processor"]} {
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
	}
	return $clk
}

proc gen_axis_port1_endpoint {drv_handle value} {
       global port1_end_mappings
       dict append port1_end_mappings $drv_handle $value
       set val [dict get $port1_end_mappings $drv_handle]
}

proc gen_axis_port2_endpoint {drv_handle value} {
       global port2_end_mappings
       dict append port2_end_mappings $drv_handle $value
       set val [dict get $port2_end_mappings $drv_handle]
}

proc gen_axis_port3_endpoint {drv_handle value} {
       global port3_end_mappings
       dict append port3_end_mappings $drv_handle $value
       set val [dict get $port3_end_mappings $drv_handle]
}

proc gen_axis_port4_endpoint {drv_handle value} {
       global port4_end_mappings
       dict append port4_end_mappings $drv_handle $value
       set val [dict get $port4_end_mappings $drv_handle]
}

proc set_drv_property args {

	set drv_handle [lindex $args 0]
	set dts_file [set_drv_def_dts $drv_handle]
	set conf_prop [lindex $args 1]
	set value [lindex $args 2]
	if {[llength $value] !=0} {
		if {$value != "-1" && [llength $value] !=0} {
			set type "hexint"
			if {[llength $args] >= 4} {
				set type [lindex $args 3]
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
			}
			# remove CONFIG. as add_new_property does not work with CONFIG.
			regsub -all {^CONFIG.} $conf_prop {} conf_prop
			set node [get_node $drv_handle]
			add_prop $node $conf_prop $value $type $dts_file
		}
	}
}

# set driver property based on IP property
proc set_drv_conf_prop args {
	set drv_handle [lindex $args 0]
	set pram [lindex $args 1]
	set conf_prop [lindex $args 2]
	set ip [hsi::get_cells -hier $drv_handle]
	set value [hsi get_property CONFIG.${pram} $ip]
	if {[llength $value] !=0} {
		regsub -all "MIO( |)" $value "" value
		if {$value != "-1" && [llength $value] !=0} {
			set type "hexint"
			if {[llength $args] >= 4} {
				set type [lindex $args 3]
				if {[string equal -nocase $type "boolean"]} {
					if {[expr $value < 1]} {
						return 0
					}
					set value ""
				}
			}
			regsub -all {^CONFIG.} $conf_prop {} conf_prop
			set node [get_node $drv_handle]
			set name [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
	set ip [hsi::get_cells -hier $src_handle]
	set ipname [hsi get_property IP_NAME $ip]
	set proctype [get_hw_family]
	foreach conf_prop $src_prams {
		set value [hsi get_property ${conf_prop} $ip]
		if {$conf_prop == "CONFIG.processor_mode"} {
			set value "true"
		}
		if {$ipname == "axi_ethernet"} {
			set value [is_property_set $value]
		}
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
				set ipname [hsi get_property IP_NAME [hsi::get_cells -hier $ip]]
				if {[string match -nocase $ipname "axi_mcdma"] && [string match -nocase $dest_prop "xlnx,include-sg"] } {
					set type "boolean"
					set value ""
				}
				if {[regexp -nocase {0x([0-9a-f]{9})} "$value" match]} {
					set temp $value
					set temp [string trimleft [string trimleft $temp 0] x]
					set len [string length $temp]
					set rem [expr {${len} - 8}]
					set high_base "0x[string range $temp $rem $len]"
					set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
					set low_base [format 0x%08x $low_base]
					set value "$low_base $high_base"
				}

				set valid_proclist "psv_cortexa72 psv_cortexr5 psu_cortexa53 psu_cortexr5 psu_pmu psv_pmc psv_psm microblaze"
				if {[string match -nocase $ipname "psv_rcpu_gic"]} {
					set node [create_node -n "&gic_r5" -d "pcw.dtsi" -p root]
				} elseif {[lsearch $valid_proclist $ipname] >= 0} {
					switch $ipname {
						"psv_cortexa72" {
							set index [string index $src_handle end]
							set node [create_node -n "&a72_cpu${index}" -d "pcw.dtsi" -p root]
						} "psv_cortexr5" {
							set index [string index $src_handle end]
							set node [create_node -n "&r5_cpu${index}" -d "pcw.dtsi" -p root]
						} "psv_pmc" {
							set node [create_node -n "&ub1_cpu" -d "pcw.dtsi" -p root]
						} "psv_psm" {
							set node [create_node -n "&ub2_cpu" -d "pcw.dtsi" -p root]
						} "psu_cortexa53" {
							set index [string index $src_handle end]
							set node [create_node -n "&a53_cpu${index}" -d "pcw.dtsi" -p root] 
						} "psu_cortexr5" {
							set index [string index $src_handle end]
							set node [create_node -n "&r5_cpu${index}" -d "pcw.dtsi" -p root]
						} "psu_pmu" {
							set node [create_node -n "&ub1_cpu" -d "pcw.dtsi" -p root]
						} "microblaze" {
							set count [get_microblaze_nr $src_handle]
							set bus_name [detect_bus_name $src_handle]
							if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
								set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
							} elseif {[string match -nocase $proctype "versal"]} {
								set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
							}
								set node [create_node -n "cpu" -l "ub${count}_cpu" -u 0 -d "pl.dtsi" -p $rt_node]
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
	set ip [hsi::get_cells -hier $drv_handle]
	return [hsi get_property ${parameter} $ip]
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
	proc_called_by
	set slave [hsi::get_cells -hier $drv_handle]
	set intr_info ""
	set proctype [get_hw_family]
	foreach pin ${intr_port_name} {
		set intc [get_interrupt_parent $drv_handle $pin]
		if {[string_is_empty $intc] == 1} {continue}
		if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "zynquplus"]} {

			if {[llength $intc] > 1} {
				foreach intr_cntr $intc {
					if { [is_ip_interrupting_current_proc $intr_cntr] } {
						set intc $intr_cntr
					}
				}
			}
			set intc_ipname [hsi get_property IP_NAME $intc]
			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] } {
				if {[string match -nocase $intc_ipname "axi_intc"]} {
					set intc [get_interrupt_parent $drv_handle $pin]
				}
			}
			if {[string match -nocase $proctype "versal"] && [string match -nocase $intc_ipname "axi_intc"] } {
				set intc [get_interrupt_parent $drv_handle $pin]
			}
		}
		if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "zynquplus"]} {
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
		} elseif {[string match -nocase $intc_ipname "psu_acpu_gic"] || [string match -nocase $intc_ipname "psv_acpu_gic"]} {
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

proc gen_dt_node_search_pattern args {
	proc_called_by
	# generates device tree node search pattern and return it

	global def_string
	foreach var {node_name node_label node_unit_addr} {
		set ${var} ${def_string}
	}
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
	if {[string match -nocase $slave_ip "psu_sata"]} {
		set addr [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]]
	} else {
		set ip_mem_handle [lindex [hsi::get_mem_ranges [hsi::get_cells -hier $slave_ip]] 0]
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
                    set addr [string tolower [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $slave_ip]]]
             } elseif {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_CTRL_HIGHADDR"] >= 0} {
                    set addr [string tolower [hsi get_property CONFIG.C_S_AXI_CTRL_BASEADDR [hsi::get_cells -hier $slave_ip]]]
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
	if {[regexp "^&.*" "$node" match] || [regexp "amba_apu" "$node" match] || [regexp "amba_rpu" "node" match] || [regexp "amba" "$node" match]} {
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
	if {[regexp "kintex*" $proctype match]} {
		global env
		set path $env(REPO)
		set drvname [get_drivers $drv_handle]
		set common_file "$path/device_tree/data/config.yaml"
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
			if {[regexp "kintex*" $proctype match]} {
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
        if {[string match -nocase $family "versal"] || [string match -nocase $family "zynqmp"] || [string match -nocase $family "zynq"] || [string match -nocase $family "zynquplus"]} {
		return [file normalize "$path/device_tree/data/kernel_dtsi/${release}/${dtsi_fname}"]
	} else {
		return "$dir/pl.dtsi"
	}
}

proc set_drv_def_dts {drv_handle} {
	global env
	set path $env(REPO)

	set drvname [get_drivers $drv_handle]
	set common_file "$path/device_tree/data/config.yaml"
	set dt_overlay [get_user_config $common_file -dt_overlay]
	set family [get_hw_family]
	global bus_clk_list
	if {[is_pl_ip $drv_handle]} {
		set default_dts "pl.dtsi"
		if {!$dt_overlay} {
			update_system_dts_include $default_dts
		}
	} else {
		# PS IP, read pcw_dts property
		set default_dts "pcw.dtsi"
		update_system_dts_include $default_dts
	}
	if {[is_pl_ip $drv_handle] && $dt_overlay} {
		set fpga_node [create_node -n "fragment" -u 0 -d ${default_dts} -p root]
		set pl_file $default_dts
		set targets "fpga_full"
		add_prop $fpga_node target "$targets" reference $default_dts 1
		set child_name "__overlay__"
		set child_node [create_node -l "overlay0" -n $child_name -p $fpga_node -d $default_dts]
		add_prop "${child_node}" "#address-cells" 2 int $default_dts 1
		add_prop "${child_node}" "#size-cells" 2 int $default_dts 1
		if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"] || [string match -nocase $family "zynquplusRFSOC"]} {
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

proc is_pl_ip {ip_inst} {
	# check if the IP is a soft IP (not PS7)
	# return 1 if it is soft ip
	# return 0 if not
	set ip_obj [hsi::get_cells -hier $ip_inst]
	if {[llength [hsi::get_cells -hier $ip_inst]] < 1} {
		return 0
	}
	set ip_name [hsi get_property IP_NAME $ip_obj]
	set nochk_list "ai_engine noc_mc_ddr4"
	if {[lsearch $nochk_list $ip_name] >= 0} {
		return 1
	}
	if {[catch {set proplist [hsi list_property [hsi::get_cells -hier $ip_inst]]} msg]} {
	} else {
		if {[lsearch -nocase $proplist "IS_PL"] >= 0} {
			set prop [hsi get_property IS_PL [hsi::get_cells -hier $ip_inst]]
			if {$prop} {
				return 1
			} else {
				return 0
			}
		}
	}
	set ip_name [hsi get_property IP_NAME $ip_obj]
	if {![regexp "ps._*" "$ip_name" match]} {
		return 1
	}
	return 0
}

proc is_ps_ip {ip_inst} {
	proc_called_by
	# check if the IP is a soft IP (not PS7)
	# return 1 if it is soft ip
	# return 0 if not
	set ip_obj [hsi::get_cells -hier $ip_inst]
	if {[catch {set proplist [hsi list_property [hsi::get_cells -hier $ip_inst]]} msg]} {
	} else {
	if {[lsearch -nocase $proplist "IS_PL"] >= 0} {
		set prop [hsi get_property IS_PL [hsi::get_cells -hier $ip_inst]]
		if {$prop} {
			return 0
		}
	}
	}
	if {[llength [hsi::get_cells -hier $ip_inst]] < 1} {
		return 0
	}
	
	set ip_name [hsi get_property IP_NAME $ip_obj]
	if {[string match -nocase $ip_name "axi_noc"]} {
		return 0
	}
	if {[string match -nocase $ip_name "iomodule"]} {
		set prop [hsi get_property IS_PL [hsi::get_cells -hier $ip_inst]]
                if {$prop == 0} {
                        return 1
                }
	}
	if {[regexp "ps._*" "$ip_name" match]} {
		return 1
	}
	return 0
}

proc get_node_name {drv_handle} {
	# FIXME: handle node that is not an ip
	# what about it is a bus node
	set ip [hsi::get_cells -hier $drv_handle]
	# node that is not a ip
	if {[string_is_empty $ip]} {
		error "$drv_handle is not a valid IP"
	}
	set unit_addr [get_baseaddr ${ip}]
	set dev_type [hsi get_property CONFIG.dev_type $drv_handle]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type $drv_handle
	}
	set dt_node [add_or_get_dt_node -n ${dev_type} -l ${drv_handle} -u ${unit_addr}]
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
	set ipname [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
	set ipname [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]

	if {[string match -nocase $ipname "axi_dma"]} {
		if {[string match -nocase $prop "xlnx,include-sg"] && [string match -nocase $value "0"]} {
			return
		}
	}
	# This is to avoid boolean type error for axi_dma include-sg paramter
	if {[string match -nocase $type "boolean"] && [string_is_empty ${value}] != 1} {
		set value ""
	}
	if {[string match -nocase "PROCESSOR" [hsi get_property IP_TYPE [hsi::get_cells -hier $drv_handle]]]} {
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

proc create_dt_tree_from_dts_file {} {
	global def_string dtsi_fname
	set kernel_dtsi ""
	set mainline_dtsi ""
	set kernel_ver [hsi get_property CONFIG.kernel_version [get_os]]
	set mainline_ker [hsi get_property CONFIG.mainline_kernel [get_os]]
	if {[string match -nocase $mainline_ker "v4.17"]} {
		foreach i [get_sw_cores device_tree] {
			set mainline_dtsi [file normalize "[hsi get_property "REPOSITORY" $i]/data/kernel_dtsi/v4.17/${dtsi_fname}"]
			if {[file exists $mainline_dtsi]} {
				foreach file [glob [file normalize [file dirname ${mainline_dtsi}]/*]] {
					# NOTE: ./ works only if we did not change our directory
					file copy -force $file ./
				}
				break
			}
		}
	} else {
		foreach i [get_sw_cores device_tree] {
			set kernel_dtsi [file normalize "[hsi get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/${dtsi_fname}"]
			if {[file exists $kernel_dtsi]} {
				foreach file [glob [file normalize [file dirname ${kernel_dtsi}]/*]] {
					# NOTE: ./ works only if we did not change our directory
					file copy -force $file ./
				}
				break
			}
		}

		if {![file exists $kernel_dtsi] || [string_is_empty $kernel_dtsi]} {
			error "Unable to find the dts file $kernel_dtsi"
		}
	}

	global zynq_soc_dt_tree
	set default_dts [create_dt_tree -dts_file $zynq_soc_dt_tree]
	if {[string match -nocase $mainline_ker "v4.17"]} {
		set fp [open $mainline_dtsi r]
		set file_data [read $fp]
		set data [split $file_data "\n"]
	} else {
		set fp [open $kernel_dtsi r]
		set file_data [read $fp]
		set data [split $file_data "\n"]
	}

	set node_level -1
	foreach line $data {
		set node_start_regexp "\{(\\s+|\\s|)$"
		set node_end_regexp "\}(\\s+|\\s|);(\\s+|\\s|)$"
		if {[regexp $node_start_regexp $line matched]} {
			regsub -all "\{| |\t" $line {} line
			incr node_level
			set cur_node [line_to_node $line $node_level $default_dts]
		} elseif {[regexp $node_end_regexp $line matched]} {
			set node_level [expr "$node_level - 1"]
		}
		# TODO (MAYBE): convert every property into dt node
		set status_regexp "status(|\\s+)="
		set value ""
		if {[regexp $status_regexp $line matched]} {
			regsub -all "\{| |\t|;|\"" $line {} line
			set line_data [split $line "="]
			set value [lindex $line_data 1]
			add_new_dts_param "${cur_node}" "status" $value string
		}
		set status_regexp "compatible(|\\s+)="
		set value ""
		if {[regexp $status_regexp $line matched]} {
			regsub -all "\{| |\t|;|\"" $line {} line
			set line_data [split $line "="]
			set value [lindex $line_data 1]
			add_new_dts_param "${cur_node}" "compatible" $value stringlist
		}
	}
}

proc line_to_node {line node_level default_dts} {
	# TODO: make dt_node_dict as global
	global dt_node_dict
	global def_string
	regsub -all "\{| |\t" $line {} line
	set parent_node $def_string
	set node_label $def_string
	set node_name $def_string
	set node_unit_addr $def_string

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

	if {$node_level > 0} {
		set parent_node [dict get $dt_node_dict [expr $node_level - 1] parent_node]
	}

	set cur_node [add_or_get_dt_node -n ${node_name} -l ${node_label} -u ${node_unit_addr} -d ${default_dts} -p ${parent_node}]
	dict set dt_node_dict $node_level parent_node $cur_node

	return $cur_node
}

proc gen_ps_mapping {} {
	set family [get_hw_family]
	set def_ps_mapping [dict create]
	if {[string match -nocase $family "versal"]} {
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
	} elseif {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
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
	if {[is_ps_ip [get_drivers $ip_name]]} {
		set unit_addr [get_ps_node_unit_addr $ip_name]
		if {$unit_addr == -1} {return $ip_name}
		set ps7_mapping [gen_ps7_mapping]

		if {[catch {set tmp [dict get $ps7_mapping $unit_addr $prop]} msg]} {
			continue
		}
		return $tmp
	}
	return $ip_name
}

proc get_ps_node_unit_addr {ip_name {prop "label"}} {
	set ip [hsi::get_cells -hier $ip_name]
	set ip_mem_handle [get_ip_mem_ranges [hsi::get_cells -hier $ip]]

	# loop through the base addresses: workaround for intc
	foreach handler ${ip_mem_handle} {
		set unit_addr [string tolower [hsi get_property BASE_VALUE $handler]]
		regsub -all {^0x} $unit_addr {} unit_addr
		set ps7_mapping [gen_ps7_mapping]
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

	set drvname [get_drivers $drv_handle]

	set common_file "$path/device_tree/data/config.yaml"
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
	set valid_plt "zynq zynqmp zynquplus"
	if {[lsearch  -nocase $valid_plt $plattype] >= 0} {
		set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
		if {[lsearch $valid_ip_list $iptype] >= 0} {
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
			if {[string match -nocase $plattype "zynqmp"] || [string match -nocase $plattype "zynquplus"]} {
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
						set_drv_prop $drv_handle "clocks" "$clocks" reference
						set_drv_prop_if_empty $drv_handle "clock-names" "$clks" stringlist
					} else {
						set_drv_prop_if_empty $drv_handle "clocks" $clk_refs reference
						set_drv_prop_if_empty $drv_handle "clock-names" "$clks" stringlist
					}
				}
			} else {
				set_drv_prop_if_empty $drv_handle "clock-names" "ref_clk" stringlist
				set_drv_prop_if_empty $drv_handle "clocks" "clkc 0" reference
			}
			}
		}
	}
}

proc gen_dfx_reg_property {drv_handle dfx_node} {
       set ip_name  [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
       set reg ""
       set slave [hsi::get_cells -hier ${drv_handle}]
       set ip_mem_handles [get_ip_mem_ranges $slave]
       foreach mem_handle ${ip_mem_handles} {
               set base [string tolower [hsi get_property BASE_VALUE $mem_handle]]
               set high [string tolower [hsi get_property HIGH_VALUE $mem_handle]]
               set size [format 0x%x [expr {${high} - ${base} + 1}]]
               set proctype [hsi get_property IP_NAME [hsi::get_cells -hier [get_sw_processor]]]
               if {[string_is_empty $reg]} {
                       if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
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
                       if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
                               set index [check_64_base $reg $base $size]
                               if {$index == "true"} {
                                       continue
                               }
                       }
                       # ensure no duplication
                       if {![regexp ".*${reg}.*" "$base $size" matched]} {
                               if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
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
       set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
                               set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
               if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
                       set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
               }
               foreach pin $pins {
                       if {[lsearch $clklist $pin] >= 0} {
                               set pl_clk $pin
                               set is_pl_clk 1
                       }
               }
               if {[string match -nocase $proctype "psv_cortexa72"]} {
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
                       set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
       set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
	set drvname [get_drivers $drv_handle]
	set common_file "$path/device_tree/data/config.yaml"
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
	if {[regexp "kintex*" $proctype match]} {
		return
	}
       set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
       set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
                               set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
               if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
                       set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
               }
               foreach pin $pins {
                       if {[lsearch $clklist $pin] >= 0} {
                               set pl_clk $pin
                               set is_pl_clk 1
                       }
               }
               if {[string match -nocase $proctype "psv_cortexa72"]} {
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
                       set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
       set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
	if {[is_ps_ip $drv_handle]} {
		return 0
	}
	global env
	set path $env(REPO)
	set drvname [get_drivers $drv_handle]
	set common_file "$path/device_tree/data/config.yaml"
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
	if {[regexp "kintex*" $proctype match]} {
		return
	}

	set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
	dtg_verbose "clk_pins:$clk_pins"
	set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
				if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] || [string match -nocase $proctype "zynquplusRFSOC"]} {
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
				set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
				set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
				set ver [get_comp_ver $versal_periph]
				if {$ver >= 3.0} {
                               		set clklist "pl0_ref_clk pl1_ref_clk pl2_ref_clk pl3_ref_clk"
                       		} else {
                               		set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
				}
                       	}
			"zynq" {
				set clklist "FCLK_CLK FCLK_CLK1 FCLK_CLK2 FCLK_CLK3"
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
                       set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
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
		if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] || [string match -nocase $proctype "zynquplusRFSOC"]} {
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
			set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
	if {![string match -nocase $clocknames ""]} {
		set len [llength $updat]
		if {[string match -nocase "[hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]" "dfx_axi_shutdown_manager"]} {
			set_drv_prop_if_empty $drv_handle "clock-names" "aclk" stringlist
		} else {
			set_drv_prop_if_empty $drv_handle "clock-names" $clocknames stringlist
		}
	}
	set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
		set_drv_prop $drv_handle "clocks" "$refs" reference
		return
	}
	set len [llength $updat]
	switch $len {
		"1" {
			set refs [lindex $updat 0]
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"2" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"3" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"4" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"5" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"6" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"7" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"8" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"9" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"10" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"11" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"12" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"13" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"14" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"15" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
		"16" {
			set refs [lindex $updat 0]
			append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]"
			set_drv_prop $drv_handle "clocks" "$refs" reference
		}
	}
}

proc overwrite_clknames {clknames drv_handle} {
	set node [get_node $drv_handle]
	add_prop $node clock-names $clknames stringlist [set_drv_def_dts $drv_handle] 1
}

proc get_comp_ver {drv_handle} {
       set slave [hsi::get_cells -hier ${drv_handle}]
       set vlnv  [split [hsi::get_property VLNV $slave] ":"]
       set ver   [lindex $vlnv 3]
       return $ver
}

proc get_comp_str {drv_handle} {
	set slave [hsi::get_cells -hier ${drv_handle}]
	set vlnv [split [hsi get_property VLNV $slave] ":"]
	set ver [lindex $vlnv 3]
	set name [lindex $vlnv 2]
	set ver [lindex $vlnv 3]
	set comp_prop "xlnx,${name}-${ver}"
	regsub -all {_} $comp_prop {-} comp_prop
	return $comp_prop
}

proc get_intr_type {intc_name ip_name port_name} {
	set intc [hsi::get_cells -hier $intc_name]
	set ip [hsi::get_cells -hier $ip_name]
	if {[llength $intc] == 0 && [llength $ip] == 0} {
		return -1
	}
	if {[llength $intc] == 0} {
		return -1
	}
	set intr_pin [hsi::get_pins -of_objects $ip $port_name]
	set sensitivity ""
	if {[llength $intr_pin] >= 1} {
		# TODO: check with HSM dev and see if this is a bug
		set sensitivity [hsi get_property SENSITIVITY $intr_pin]
	}
	set intc_type [hsi get_property IP_NAME $intc ]
	set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic"
	if {[lsearch  -nocase $valid_intc_list $intc_type] >= 0} {
		if {[string match -nocase $sensitivity "EDGE_FALLING"]} {
				return 2;
		} elseif {[string match -nocase $sensitivity "EDGE_RISING"]} {
				return 1;
		} elseif {[string match -nocase $sensitivity "LEVEL_HIGH"]} {
				return 4;
		} elseif {[string match -nocase $sensitivity "LEVEL_LOW"]} {
				return 8;
		}
	} else {
		# Follow the openpic specification
		if {[string match -nocase $sensitivity "EDGE_FALLING"]} {
				return 3;
		} elseif {[string match -nocase $sensitivity "EDGE_RISING"]} {
				return 0;
		} elseif {[string match -nocase $sensitivity "LEVEL_HIGH"]} {
				return 2;
		} elseif {[string match -nocase $sensitivity "LEVEL_LOW"]} {
				return 1;
		}
	}
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
	set dts_file [set_drv_def_dts $drv_handle]
	# check if property exists if not create it
	set list [get_drv_conf_prop_list $drv_handle]
	if {[lsearch -glob ${list} ${prop_name}] < 0} {
	}

	if {[llength $args] >= 4} {
		set type [lindex $args 3]
		set node [get_node $drv_handle]
		add_prop $node $prop_name $value $type $dts_file 
	} else {
		add_prop $node $prop_name $value $type $dts_file 
	}
	return 0
}

proc set_drv_prop_if_empty args {
	set drv_handle [lindex $args 0]
	set prop_name [lindex $args 1]
	set value [lindex $args 2]
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
	set cur_prop_value ""
	if {[catch {set tmp [set cur_prop_value [$treeobj get $node $prop_name]]} msg]} {
	}
	if {[string_is_empty $cur_prop_value] == 0} {
		
		dtg_debug "$drv_handle $prop_name property is not empty, current value is '$cur_prop_value'"
		return -1
	}
	if {[llength $args] >= 4} {

		set type [lindex $args 3]
		set_drv_prop $drv_handle $prop_name $value $type
	} else {
		set_drv_prop $drv_handle $prop_name $value
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
	if { [::hsi::utils::is_intr_cntrl $intc] != 1 } {
		set intf_pins [::hsi::get_intf_pins -of_objects $intc]
		foreach intp $intf_pins {
			set connectip [get_connected_stream_ip [get_cells -hier $intc] $intp]
			if { [::hsi::utils::is_intr_cntrl $connectip] == 1 } {
				set intc $connectip
			}
		}
	}
	if {[string_is_empty $intc]} {
		dtg_warning "no interrupt controller found"
		return
	}

	set proctype [get_hw_family]
	set bus_name [detect_bus_name $cpu_handle]
	set count [get_microblaze_nr $cpu_handle]
	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
	} elseif {[string match -nocase $proctype "versal"]} {
		set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
	}
	set cpu_node [create_node -n "cpu" -l "ub${count}_cpu" -u 0 -d "pl.dtsi" -p $rt_node]
	if {[is_pl_ip $intc]} {
		set tmpbase [get_baseaddr $intc]
		global duplist
		if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
		} else {
			set intc $handle_value
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
		if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "axi_intc"]} {
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
			if {![string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "axi_intc"]} {
				dtg_warning "Interrupt pin \"$pin\" of IP block: \"$drv_handle\" is not connected to any interrupt controller\n\r"
			}
			continue
		}
		set connected_intc_name [hsi get_property IP_NAME $connected_intc]
		set valid_gpio_list "ps7_gpio axi_gpio"
		set valid_cascade_proc "kintex7 zynq zynqmp zynquplus versal zynquplusRFSOC"
		# check whether intc is gpio or other
		if {[lsearch  -nocase $valid_gpio_list $connected_intc_name] >= 0} {
			set cur_intr_info ""
			generate_gpio_intr_info $connected_intc $drv_handle $pin
		} else {
			set intc [get_interrupt_parent $drv_handle $pin]
			if { [string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "axi_intc"] && [lsearch -nocase $valid_cascade_proc $proctype] >= 0 } {
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
			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "zynquplus"] || [string match -nocase $proctype "zynquplusRFSOC"]} {
				set intc_name [hsi get_property IP_NAME $intc]
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

			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "zynquplus"] || [string match -nocase $proctype "zynquplusRFSOC"]} {
				if { [string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "axi_intc"] } {
					set intr_id [get_psu_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_psu_interrupt_id $drv_handle $pin]
				}
			}
			if { [string match -nocase $proctype "zynq"]} {
				if { [string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "axi_intc"] } {
					set intr_id [get_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_interrupt_id $drv_handle $pin]
				}
			}

			if {[regexp "kintex*" $proctype match]} {
				if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "axi_intc"] } {
					set intr_id [get_psu_interrupt_id $drv_handle "irq"]
				} else {
					set intr_id [get_psu_interrupt_id $drv_handle $pin]
				}
			}
			if {[string match -nocase $intr_id "-1"] && ![string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "axi_intc"]} {
				continue
			}
			set intr_type [get_intr_type $intc $slave $pin]
			if {[string match -nocase $intr_type "-1"]} {
				continue
			}

			set cur_intr_info ""
			set valid_intc_list "ps7_scugic psu_acpu_gic psv_acpu_gic"
			global intrpin_width
			if { [string match -nocase $proctype "ps7_cortexa9"] }  {
				if {[string match "[hsi get_property IP_NAME $intc]" "ps7_scugic"] } {
					if {$intr_id > 32} {
						set intr_id [expr $intr_id - 32]
					}
					set cur_intr_info "0 $intr_id $intr_type"

				} elseif {[string match "[hsi get_property IP_NAME $intc]" "axi_intc"] } {
					set cur_intr_info "$intr_id $intr_type"
				}
			} elseif {[string match -nocase $intc_name "psu_acpu_gic"] || [string match -nocase $intc_name "psv_acpu_gic"]} {
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
			if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "v_hdmi_tx_ss"]} {
	                       set_drv_prop_if_empty $drv_handle "interrupts-extended" $ref reference
			}
               }
       }

	if {[string_is_empty $intr_info]} {
		return -1
	}
	set_drv_prop $drv_handle interrupts $intr_info intlist
	if {[string_is_empty $intc_name]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]
	set intc_len [llength $intc]
	if {$intc_len > 1} {
		foreach intc_ctr $intc { 
			set intc_ctr [hsi get_property IP_NAME [hsi::get_cells -hier $intc]]
			if { [string match -nocase $intc_ctr "psu_acpu_gic"] || [string match -nocase $intc_ctr "psv_acpu_gic"]} {
				set intc "gic"
			}
		}
	} else {
		if { [string match -nocase $intc_name "psu_acpu_gic"] || [string match -nocase $intc_name "psv_acpu_gic"]} {
			set intc "gic"
		}
	}
	if {[string match -nocase $intc "gic"]} {
		set intc "imux"
	}
	if {[is_pl_ip $intc]} {
		set tmpbase [get_baseaddr $intc]
		global duplist
		if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
		} else {
			set intc $handle_value
		}
	}
	set_drv_prop $drv_handle interrupt-parent $intc reference
	if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]] "xdma"]} {
		set msi_rx_pin_en [hsi get_property CONFIG.msi_rx_pin_en [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $msi_rx_pin_en "true"]} {
			set_drv_prop_if_empty $drv_handle "interrupt-names" $intr_names stringlist
		}
	} else {
		set_drv_prop_if_empty $drv_handle "interrupt-names" $intr_names stringlist
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
	if {[string_is_empty $skip_ps_check]} {
		if {[is_ps_ip $drv_handle]} {
			set node [get_node $drv_handle]
			if {[catch {set tmp [set val [$treeobj get $node "reg"]]} msg]} {
			}
		}
	}
	set ip_name  [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [string match -nocase $proctype "zynquplus"]} {
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

		set_drv_prop_if_empty $drv_handle reg $reg hexlist
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
				if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [string match -nocase $proctype "zynquplus"]} {
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
				if {[string match -nocase $proctype "zynq"] || [regexp "kintex*" $proctype match]} {
					set index [check_base $reg $base $size]
					if {$index == "true" && $ip_name != "axi_fifo_mm_s"} {
						continue
					}
				}
				if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [string match -nocase $proctype "zynquplus"]} {
					set index [check_64_base $reg $base $size]
					if {$index == "true" && $ip_name != "axi_fifo_mm_s"} {
						continue
					}
				}
				# ensure no duplication
				if {![regexp ".*${reg}.*" "$base $size" matched]} {
					if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [string match -nocase $proctype "zynquplus"]} {
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
	set_drv_prop_if_empty $drv_handle reg $reg hexlist
	set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $ip_name "psv_pciea_attrib"]} {
		set node [get_node $drv_handle]
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

proc gen_compatible_property {drv_handle} {
	proc_called_by
	set dts_file [set_drv_def_dts $drv_handle]
	set ip [hsi::get_cells -hier $drv_handle]
	set ip_name  [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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
	set vlnv [split [hsi get_property VLNV $slave] ":"]
	set name [lindex $vlnv 2]
	if {[string match -nocase $name ""]} {
		return 0
	}
	if {[string match -nocase $name "psv_fpd_smmutcu"]} {
		set name "psv_fpd_maincci"
	}
	set ver [lindex $vlnv 3]
	if {[string match -nocase $ver ""]} {
		set comp_prop "xlnx,${name}"
	} else {
		set comp_prop "xlnx,${name}-${ver}"
	}
	if {[string match -nocase $ip_name "psv_pciea_attrib"]} {
		set index [string index $drv_handle end]
		set comp_prop "${comp_prop}${index}"
	}
	regsub -all {_} $comp_prop {-} comp_prop
	if {[string match -nocase $proctype "processor"]} {
		set proctype [get_hw_family]
		set bus_name [detect_bus_name $drv_handle]
		set count [get_microblaze_nr $drv_handle]
		if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
			set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
		} elseif {[string match -nocase $proctype "versal"]} {
			set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d "pl.dtsi" -p $bus_name]
		}
		set node [create_node -n "cpu" -l "ub${count}_cpu" -u 0 -d "pl.dtsi" -p $rt_node]
		add_prop $node compatible "$comp_prop xlnx,microblaze" stringlist "pl.dtsi"	
	} else {
		set_drv_prop_if_empty $drv_handle compatible $comp_prop stringlist
		if {[string match -nocase $ip_name "dfx_axi_shutdown_manager"]} {
			set node [get_node $drv_handle]
			pldt append $node compatible "\ \, \"xlnx,dfx-axi-shutdown-manager-1.00\""
			pldt append $node compatible "\ \, \"xlnx,dfx-axi-shutdown-manager\""
		}
		if {[lsearch -nocase $tcm_addresses $unit_addr] >= 0} {
			set node [get_node $drv_handle]
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

proc ip2drv_prop {ip_name ip_prop_name} {
	set drv_handle [get_ip_handler $ip_name]
	set ip [hsi::get_cells -hier $ip_name]
	set emac [hsi get_property IP_NAME $ip]

	if { $emac == "axi_ethernet1"} {
		# remove CONFIG.
		set prop [hsi get_property $ip_prop_name [hsi::get_cells -hier $ip_name]]
		set drv_prop_name $ip_prop_name
		regsub -all {CONFIG.} $drv_prop_name {xlnx,} drv_prop_name
		regsub -all {_} $drv_prop_name {-} drv_prop_name
		set drv_prop_name [string tolower $drv_prop_name]
		set node [get_node $ip_name]
		add_prop $node $drv_prop_name hexint "pl.dtsi"
		return
	}
	if {[string match -nocase $ip_prop_name "CONFIG.C_AXIS_SIGNAL_SET"] || [string match -nocase $ip_prop_name "CONFIG.C_USE_BRAM_BLOCK"] || [string match -nocase $ip_prop_name "CONFIG.C_ALGORITHM"] || [string match -nocase $ip_prop_name "CONFIG.C_AXI_TYPE"] || [string match -nocase $ip_prop_name "CONFIG.C_INTERFACE_TYPE"] || [string match -nocase $ip_prop_name "CONFIG.C_AXI_SLAVE_TYPE"] || [string match -nocase $ip_prop_name "CONFIG.device_port_type"] || [string match -nocase $ip_prop_name "CONFIG.C_AXI_WRITE_BASEADDR_SLV"] || [string match -nocase $ip_prop_name "CONFIG.C_AXI_WRITE_HIGHADDR_SLV"]|| [string match -nocase $ip_prop_name "CONFIG.C_PVR_USER1"] || [string match -nocase $ip_prop_name "CONFIG.Component_Name"]} {
		return
	}
	set drv_prop_name $ip_prop_name
	set pcieattrib_num "CONFIG.C_CPM_PCIE0_AXIBAR_NUM"
	set pcieattrib "CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_0 CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_BASEADDR_1 CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_0 CONFIG.C_CPM_PCIE0_PF0_AXIBAR2PCIE_HIGHADDR_1"
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
		regsub -all {CONFIG.C_} $drv_prop_name {xlnx,} drv_prop_name
	
		regsub -all {^CONFIG.} $drv_prop_name {xlnx,} drv_prop_name
		regsub -all {_} $drv_prop_name {-} drv_prop_name
	}
	set drv_prop_name [string tolower $drv_prop_name]

	set prop [hsi get_property $ip_prop_name [hsi::get_cells -hier $ip_name]]

	if {[regexp -nocase {0x([0-9a-f])} $prop match]} {
		set type "hexint"
	} elseif {[string is integer -strict $prop]} {
		set type "int"
	} elseif {[string is boolean -strict $prop]} {
		set type "boolean"
	} elseif {[string is wordchar -strict $prop]} {
		set type "string"
	} else {
		set type "mixed"
	}
	if {[string match -nocase $drv_prop_name "xlnx,include-sg"] || [string match -nocase $drv_prop_name "xlnx,sg-include-stscntrl-strm"]} {
		return
	}
	if {[string match -nocase $emac "psv_pciea_attrib"] && [string match -nocase $ip_prop_name "CONFIG.C_CPM_PCIE0_PORT_TYPE"]} {
		set node [get_node $ip_name]
		add_prop $node "xlnx,device-port-type" $prop int [set_drv_def_dts $ip_name]
	} else {
		add_cross_property $ip $ip_prop_name $ip_name ${drv_prop_name} $type
	}
}

proc gen_drv_prop_from_ip {drv_handle} {
	# check if we should generating the ip properties or not
	set prop_name_list [default_parameters $drv_handle]
	foreach prop_name ${prop_name_list} {
		ip2drv_prop $drv_handle $prop_name
	}
}

proc remove_duplicates {ip_handle} {
	set par_handles [get_ip_conf_prop_list $ip_handle "CONFIG.*"]
	set dictval [dict create]
	set values ""
	foreach prop $par_handles {
		set inner ""
		if {[regexp -nocase "CONFIG.C_.*" $prop match]} {
			set temp [regsub -all {CONFIG.C_} $prop $inner]
			lappend values $temp
			dict append dictval $temp $prop
		}
	}
	foreach prop $par_handles {
		set inner ""
		set temp [regsub -all {^CONFIG.} $prop $inner]
		set inner ""
		set temp [regsub -all {^C_} $temp $inner]
		lappend values $temp
		if {[catch {set rt [dict get $dictval $temp]} msg]} {
			dict append dictval $temp $prop
		} else {
		}

	}
	set valus [lsort -nocase -unique $values]
	set tempvalues ""
	foreach val $valus {
		if {[catch {set rt [dict get $dictval $val]} msg]} {
		} else {
			lappend tempvalues $rt
		}
	}
	return $tempvalues
}

# based on libgen dtg
proc default_parameters {ip_handle {dont_generate ""}} {
	proc_called_by
	set par_handles [get_ip_conf_prop_list $ip_handle "CONFIG.*"]
	set par_handles [remove_duplicates $ip_handle]
	set valid_prop_names {}
	foreach par $par_handles {
		if {[is_ps_ip $ip_handle]} {
			set tmp_par $par
		} else {
			regsub -all {CONFIG.} $par {} tmp_par
		}
		# Ignore some parameters that are always handled specially
		
		if {[is_ps_ip $ip_handle]} {
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

			set drvname [get_drivers $drv_handle]

			set common_file "$path/device_tree/data/config.yaml"
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
				set_drv_property $drv_handle ${conf_prop} "$src_ip $value 0" reference
			}
		}
	} else {
		dtg_warning "$drv_handle: No reset found"
		return -1
	}
}

proc gen_peripheral_nodes {drv_handle {node_only ""}} {
	# Check if the peripheral is in Secure or Non-secure zone
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
			set dev_type [hsi get_property IP_NAME [hsi::get_cells -hier $ip]]
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
		} else {
		}

		# check if it has status property
		set rt_node [get_node $drv_handle]
		if {[string match -nocase $ip_type "psv_rcpu_gic"] || [string match -nocase $ip_type "psu_rcpu_gic"]} {
			set node [create_node -n "&gic_r5" -d "pcw.dtsi" -p root]
			add_prop $node "status" "okay" string $default_dts
		}
		if {[string match -nocase $rt_node "&dwc3_0"]} {
				if {[string match -nocase $proc_type "zynqmp"] || [string match -nocase $proc_type "zynquplus"]} {
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
				if {[string match -nocase $proc_type "zynqmp"] || [string match -nocase $proc_type "zynquplus"]} {
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
			}
			add_prop $rt_node "status" "okay" string $default_dts 
		}
	} else {
		if {[string match -nocase $ip_type "tsn_endpoint_ethernet_mac"]} {
			set rt_node [create_node -n tsn_endpoint_ip_0 -l tsn_endpoint_ip_0 -d $default_dts -p $bus_node] 
		} else {
			set valid_proclist "psv_cortexa72 psv_cortexr5 psu_cortexa53 psu_cortexr5 psu_pmu psv_pmc psv_psm"
			if {[lsearch $valid_proclist $ip_type] >= 0} {
				switch $ip_type {
					"psv_cortexa72" {
						set index [string index $drv_handle end]
						set rt_node [create_node -n "&a72_cpu${index}" -d ${default_dts} -p root]
					} "psv_cortexr5" {
						set index [string index $drv_handle end]
						set rt_node [create_node -n "&r5_cpu${index}" -d ${default_dts} -p root]
					} "psv_pmc" {
						set rt_node [create_node -n "&ub1_cpu" -d ${default_dts} -p root]
					} "psv_psm" {
						set node [create_node -n "&ub2_cpu" -d "pcw.dtsi" -p root]
					} "psu_cortexa53" {
						set index [string index $src_handle end]
						set node [create_node -n "&a53_cpu${index}" -d "pcw.dtsi" -p root] 
					} "psu_cortexr5" {
						set index [string index $src_handle end]
						set node [create_node -n "&r5_cpu${index}" -d "pcw.dtsi" -p root]
					} "psu_pmu" {
						set node [create_node -n "&ub1_cpu" -d "pcw.dtsi" -p root]
					}
				}
			} else {
				if {[string match -nocase $ip_type "microblaze"]} {
					set proctype [get_hw_family]
					set bus_name [detect_bus_name $drv_handle]
					set count [get_microblaze_nr $drv_handle]
					if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
						set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d ${default_dts} -p $bus_name]
					} elseif {[string match -nocase $proctype "versal"]} {
						set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d ${default_dts} -p $bus_name]
					}
					set rt_node [create_node -n "cpu" -l "ub${count}_cpu" -u 0 -d "pl.dtsi" -p $rt_node]
				} else {
					if {[string match -nocase $dev_type "psv_fpd_smmutcu"]} {
							set dev_type "psv_fpd_maincci"
					}
					set t [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
					set rt_node [create_node -n ${dev_type} -l ${label} -u ${unit_addr} -d ${default_dts} -p $bus_node]
				}
			}
		}

		add_prop $rt_node "status" "okay" string $default_dts
		add_prop $rt_node "xlnx,ip-name" $ip_type string $default_dts
	}

	zynq_gen_pl_clk_binding $drv_handle
	generate_mb_ccf_node $drv_handle
	generate_cci_node $drv_handle $rt_node

	set dts_file_list ""
	if {[catch {set rt [report_property -return_string -regexp $drv_handle "CONFIG.*\\.dts(i|)"]} msg]} {
		set rt ""
	}
	foreach line [split $rt "\n"] {
		regsub -all {\s+} $line { } line
		if {[regexp "CONFIG.*\\.dts(i|)" $line matched]} {
			lappend dts_file_list [lindex [split $line " "] 0]
		}
	}
	regsub -all {CONFIG.} $dts_file_list {} dts_file_list

	set drv_dt_prop_list [get_driver_conf_list $drv_handle]
	foreach dts_file ${dts_file_list} {
		set dts_prop_list [hsi get_property CONFIG.${dts_file} $drv_handle]
		set dt_node ""
		if {[string_is_empty ${dts_prop_list}] == 0} {
			foreach prop ${dts_prop_list} {
				add_driver_prop $drv_handle $dt_node CONFIG.${prop}
				# remove from default list
				set drv_dt_prop_list [list_remove_element $drv_dt_prop_list "CONFIG.${prop}"]
			}
		}
	}

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

	set valid_proc_list "ps7_cortexa9 psu_cortexa53 psv_cortexa72 psv_cortexr5 psv_pmc psu_pmu psu_cortexr5"
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
		if {[string match -nocase $ip_drv "psu_acpu_gic"] || [string match -nocase $ip_drv "psv_acpu_gic"]} {
			return "amba_apu: amba_apu"
		}
		if {[string match -nocase $ip_drv "psu_rcpu_gic"] || [string match -nocase $ip_drv "psv_rcpu_gic"]} {
                        return "amba_rpu: amba_rpu"
                }
		set ipname ""
		if {[catch {set ipname [hsi get_property IP_NAME [hsi::get_cells -hier $ip_drv]]} msg]} {
		}
		set valid_xppu "psv_lpd_xppu psv_pmc_xppu psv_pmc_xppu_npi psu_lpd_xppu"
		if {[lsearch $valid_xppu $ipname] >= 0} {
			return "amba_xppu: indirect-bus@1"
		}
		return "amba: amba"
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
			dtg_warning "invalid value:$val"
		}
	}
	return $afival
}

proc get_max_afi_val {val} {
	set max_afival ""
	switch $val {
		"128" {
			set max_afival 2
		} "64" {
			set max_afival 1
		} "32" {
			set max_afival 0
		} default {
			dtg_warning "invalid value:$val"
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
		if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] || [string match -nocase $proctype "versal"]} {
			add_prop "${bus_node}" "#address-cells" 2 int $dts 1
			add_prop "${bus_node}" "#size-cells" 2 int $dts 1
		} else {
			add_prop "${bus_node}" "#address-cells" 1 int $dts 1
			add_prop "${bus_node}" "#size-cells" 1 int $dts 1
		}
	} else {
			set bus_node $bus_name
		if {[string match -nocase $bus_node "amba_pl: amba_pl"]} {
			if {[catch {set val [pldt get $bus_node #address-cells]} msg]} {
				add_prop $bus_node #address-cells 2 int $dts_file 
				add_prop $bus_node #size-cells 2 int $dts_file 
				add_prop $bus_node compatible "simple-bus" string $dts_file 
				add_prop $bus_node ranges boolean $dts_file 
			} else {}
		}
	}
	return $bus_node
}

proc gen_root_node {drv_handle} {
	set default_dts [set_drv_def_dts $drv_handle]
	# add compatible
	set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier ${drv_handle}]]
	set busname [detect_bus_name $drv_handle]
	set unit_addr [get_baseaddr $drv_handle noprefix]
	set ps_mapping [gen_ps_mapping]
	if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg]} {
		if {[is_ps_ip $drv_handle]} {
			set root_node [create_node -n "&amba" -d $default_dts -p root]
		}
	} elseif {[string match -nocase $default_dts "pcw.dtsi"]} {
		set root_node "root"
	} elseif {[string match -nocase $default_dts "pl.dtsi"]} {
		set root_node "root"
	}
	switch $ip_name {
		"ps7_cortexa9" {
			create_dt_tree_from_dts_file
			global dtsi_fname
			update_system_dts_include [file tail ${dtsi_fname}]
			# no root_node required as zynq-7000.dtsi
			return 0
		}
		"psu_pmu" {
			global dtsi_fname
			return 0
		}
		"psu_cortexr5" {
			global dtsi_fname
			return 0
		}
		"psu_cortexa53" {
			global env
			global pstree
			set path $env(REPO)
			set common_file "$path/device_tree/data/config.yaml"
			set release [get_user_config $common_file -kernel_ver]
			set mainline_ker [get_user_config $common_file -mainline_kernel]
			set psfile "$path/device_tree/data/kernel_dtsi/$release/zynqmp/zynqmp.dtsi"
			set clkfile "$path/device_tree/data/kernel_dtsi/$release/zynqmp/zynqmp-clk-ccf.dtsi"
			create_ps_tree $psfile psdt
			create_ps_tree $clkfile clkdt
			global dtsi_fname
			set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
		        if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
				update_system_dts_include [file tail ${dtsi_fname}]
				update_system_dts_include [file tail "zynqmp-clk.dtsi"]
				return 0
			}

			update_system_dts_include [file tail ${dtsi_fname}]
			update_system_dts_include [file tail "zynqmp-clk-ccf.dtsi"]
			set pstree 1
        		add_prop "${root_node}" model "xlnx,zynqmp" string $default_dts
			add_prop "${root_node}" "#address-cells" 2 int $default_dts
			add_prop "${root_node}" "#size-cells" 2 int $default_dts
			# no root_node required as zynqmp.dtsi
			return 0
		}
		"psv_cortexa72" {
			global env
			global pstree
			set path $env(REPO)
			set common_file "$path/device_tree/data/config.yaml"
			set release [get_user_config $common_file -kernel_ver]
			set psfile "$path/device_tree/data/kernel_dtsi/$release/versal/versal.dtsi"
			set clkfile "$path/device_tree/data/kernel_dtsi/$release/versal/versal-clk.dtsi"
			create_ps_tree $psfile psdt
			create_ps_tree $clkfile clkdt
			set pstree 1
			set board_dts [get_user_config $common_file -board_dts]
			global dtsi_fname
			update_system_dts_include [file tail ${dtsi_fname}]
			set overrides ""
			set dtsi_file " "
			set dtsi_file $board_dts
			if {[string match -nocase $dtsi_file "versal-spp-itr8-cn13940875"] || [string match -nocase $dtsi_file "versal-vc-p-a2197-00-reva-x-prc-01-reva-pm"]} {
				update_system_dts_include "versal-spp-pm.dtsi"
			} else {
				update_system_dts_include "versal-clk.dtsi"
			}
			add_prop $root_node "model" "xlnx,versal" string $default_dts
			add_prop $root_node "#address-cells" 2 int $default_dts
			add_prop $root_node "#size-cells" 2 int $default_dts
			return 0
		}
		"psv_cortexr5" {
			return 0
		}
		"psv_pmc" {
			return 0
		} "psv_psm" {
			return 0
		}
		"microblaze" {
			set family [get_hw_family]
			set count [get_microblaze_nr $drv_handle]
			set bus_name [detect_bus_name $drv_handle]
			if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
				set root_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d ${default_dts} -p $bus_name]
			} elseif {[string match -nocase $family "versal"]} {
				set root_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d ${default_dts} -p $bus_name]
			}
			add_prop $root_node "compatible" "cpus,cluster" string $default_dts
			add_prop $root_node "#address-cells" 1 int $default_dts
			add_prop $root_node "#size-cells" 0 int $default_dts
			add_prop $root_node "#cpu-mask-cells" 1 int $default_dts
			return 0
		}
		default {
			return -code error "Unknown arch"
		}
	}
	add_prop "${root_node}" "#address-cells" 1 int $default_dts
	add_prop "${root_node}" "#size-cells" 1 int $default_dts
	add_prop "${root_node}" model $model string $default_dts
	add_prop "${root_node}" compatible $compatible string $default_dts

	return $root_node
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

# Q: common function for all processor or one for each driver lib
proc gen_cpu_nodes {drv_handle} {
	set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
	switch $ip_name {
		"ps7_cortexa9" {
			# skip node generation for static zynq-7000 dtsi
			# TODO: this needs to be fixed to allow override
			cortexa9_opp_gen $drv_handle
		}
		"psu_cortexa53" {
			# skip node generation for static zynqmp dtsi
		}
		"psv_cortexa72" {
		} "microblaze" {}
		"psu_pmu" {
		} "psv_pmc" {
		} "psv_psm" {
		} "psv_cortexr5" {
		} "psu_cortexr5" {
		} "microblaze" {
		}
		default {
			error "Unknown arch"
		}
	}

	set dev_type [get_driver_config $drv_handle dev_type]
	if {[string_is_empty $dev_type] == 1} {
		set dev_type $drv_handle
	}
	gen_compatible_property $drv_handle
	gen_mb_interrupt_property $drv_handle

	set default_dts [set_drv_def_dts $drv_handle]
	set processor_type [hsi get_property IP_NAME [hsi::get_cells -hier ${drv_handle}]]
	set proc_list "psu_pmu psv_pmc psu_cortexr5 psu_cortexa53 psv_cortexa72 psv_cortexr5 ps7_cortexa9 psv_psm microblaze"
	if {[lsearch -nocase $proc_list $processor_type] >= 0} {
	} else {
		set cpu_root_node [get_node $drv_handle]
		add_prop $cpu_root_node "#address-cells" 1 int $default_dts
		add_prop $cpu_root_node "#size-cells" 0 int $default_dts
	}
	if {[string match -nocase $processor_type "psv_cortexa72"] || [string match -nocase $processor_type "psu_cortexa53"] || \
		[string match -nocase $processor_type "ps7_cortexa9"] || [string match -nocase $processor_type "microblaze"]} {
		set processor_list [eval "hsi::get_cells -hier -filter { IP_TYPE == \"PROCESSOR\" && IP_NAME == \"${processor_type}\" }"]
	} else {
		set processor_list $drv_handle
	}

	set drv_dt_prop_list [get_driver_conf_list $drv_handle]
        gen_drv_prop_from_ip $drv_handle
	generate_mb_ccf_node $drv_handle
	set bus_node [add_or_get_bus_node $drv_handle $default_dts]
	set bus_label [lindex [split $bus_node ":"] 0]
	set cpu_no 0
	set compatiblelist ""
	set loop 0
	set slave [hsi::get_cells -hier ${drv_handle}]

	foreach cpu ${processor_list} {
		set tmp $cpu
		if {[lsearch -nocase $proc_list $processor_type] >= 0} {
			if {[string match -nocase $loop "0"]} {
			set loop 0
			}
		}
		if {[string match -nocase $processor_type "psu_pmu"]} {
			set cpu_node [pcwdt insert root end "&ub1_cpu"]
			add_prop $cpu_node "microblaze_ddr_reserve_ea" [hsi get_property CONFIG.C_DDR_RESERVE_EA $slave] int $default_dts
			add_prop $cpu_node "microblaze_ddr_reserve_sa" [hsi get_property CONFIG.C_DDR_RESERVE_SA $slave] int $default_dts
			set name [split [hsi get_property NAME $slave] "_"]
			set cpu [lindex $name 2]
			set compatiblelist [lappend compatiblelist "pmu-microblaze"]
			set compatiblelist [lappend compatiblelist "pmu-microblaze-$cpu"]
			if {[string match -nocase $loop "0"]} {
			}
			set slave [hsi::get_cells -hier ${drv_handle}]
			add_prop $cpu_node "xlnx,ip-name" $processor_type string $default_dts

			set loop 1
		} elseif {[string match -nocase $processor_type "psv_pmc"] || [string match -nocase $processor_type "psv_psm"]} {
			if {[string match -nocase $processor_type "psv_pmc"]} {
				set cpu_node [pcwdt insert root end "&ub1_cpu"]
			} else {
				set cpu_node [pcwdt insert root end "&ub2_cpu"]
			}
			set name [split [hsi get_property NAME $slave] "_"]
			set cpu [lindex $name 2]
			set compatiblelist [lappend compatiblelist "pmc-microblaze"]
			set compatiblelist [lappend compatiblelist "pmc-microblaze-$cpu"]
			if {[string match -nocase $loop "0"]} {
			}
			set loop 1
		} elseif {[string match -nocase $processor_type "psu_cortexr5"] || [string match -nocase $processor_type "psv_cortexr5"]} {
			set slave [hsi::get_cells -hier ${drv_handle}]
			set name [split [hsi get_property NAME $slave] "_"]
			set cpu [lindex $name 2]
			if {[string match -nocase $cpu "0"]} {
					set cpu_nr 0
			} else {
					set cpu_nr 1
			}
			set cpu_node [pcwdt insert root end "&r5_cpu${cpu_nr}"]
			add_prop $cpu_node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $slave] int $default_dts
			set compatiblelist [lappend compatiblelist "arm,cortex-r5"]
			set compatiblelist [lappend compatiblelist "arm,cortex-r5-$cpu"]
			if {[string match -nocase $loop "0"]} {
			}
			set loop 1
		} elseif {[string match -nocase $processor_type "psu_cortexa53"] || [string match -nocase $processor_type "psv_cortexa72"]} {
			set slave [hsi::get_cells -hier $cpu]
			set name [split [hsi get_property NAME $slave] "_"]
			set cpu_nr [lindex $name 2]
			set cpu_nr [string index [hsi get_property NAME $slave] end]
			if {[string match -nocase $processor_type "psu_cortexa53"]} {
				set cpu_node [pcwdt insert root end "&a53_cpu${cpu_nr}"]
			} else {
				set cpu_node [pcwdt insert root end "&a72_cpu${cpu_nr}"]
			}
			add_prop $cpu_node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $slave] int $default_dts
			add_prop $cpu_node "stamp-frequency" [hsi get_property CONFIG.C_TIMESTAMP_CLK_FREQ $slave] int $default_dts
			if {[string match -nocase $processor_type "psu_cortexa53"]} {
				set compatiblelist [lappend compatiblelist "arm,cortex-a53"]
				set compatiblelist [lappend compatiblelist "arm,armv8"] 
				set compatiblelist [lappend compatiblelist "arm,cortex-a53-$cpu_nr"]
			} else {
				set compatiblelist [lappend compatiblelist "arm,cortex-a72"]
				set compatiblelist [lappend compatiblelist "arm,armv8"] 
				set compatiblelist [lappend compatiblelist "arm,cortex-a72-$cpu_nr"]
			}
			if {[string match -nocase $loop "0"]} {
			}
			add_prop $cpu_node "xlnx,ip-name" $processor_type string $default_dts
			set loop 1
		} elseif {[string match -nocase $processor_type "ps7_cortexa9"]} {
			set slave [hsi::get_cells -hier ${drv_handle}]
			set name [split [hsi get_property NAME $slave] "_"]
			set cpu_nr [lindex $name 2]
			set cpu_node [add_or_get_dt_node -n ${dev_type} -l "cpu${cpu_nr}" -d ${default_dts} -p /]
			set compatiblelist [lappend compatiblelist "arm,cortex-a9"]
			set compatiblelist [lappend compatiblelist "arm,cortex-a9-$cpu_nr"]
			if {[string match -nocase $loop "0"]} {
			}
			add_prop $cpu_node "xlnx,ip-name" $processor_type string $default_dts
			set loop 1
		} else {
			set proctype [get_hw_family]
			set bus_name [detect_bus_name $drv_handle]
			set count [get_microblaze_nr $drv_handle]
			# Generate the node only for the single core
			if {$cpu_no >= 1} {
				break
			}
			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
				set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d ${default_dts} -p $bus_name]
			} elseif {[string match -nocase $proctype "versal"]} {
				set rt_node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${count}" -u $count -d ${default_dts} -p $bus_name]
			}
			set cpu_node [create_node -n "cpu" -l "ub${count}_cpu" -u 0 -d "pl.dtsi" -p $rt_node]
			add_prop $cpu_node "xlnx,ip-name" $processor_type string $default_dts
		}
		add_prop $cpu_node "bus-handle" $bus_label reference $default_dts
		incr cpu_no
	}
	if {[lsearch -nocase $proc_list $processor_type] >= 0} {
	} else {
		add_prop $cpu_root_node "#cpus" $cpu_no int $default_dts
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

proc add_memory_node {drv_handle} {
	set master_dts [hsi get_property CONFIG.master_dts [get_os]]
	set cur_dts [current_dt_tree]
	set master_dts_obj [get_dt_trees ${master_dts}]
	set_cur_working_dts $master_dts

	# assuming single memory region
	#  - single memory region
	#  - / node is created
	#  - reg property is generated
	# CHECK node naming
	set ddr_ip ""
	set main_memory  [hsi get_property CONFIG.main_memory [get_os]]
	if {![string match -nocase $main_memory "none"]} {
		set ddr_ip [hsi get_property IP_NAME [hsi::get_cells -hier $main_memory]]
	}
	set ddr_list "psu_ddr ps7_ddr axi_emc mig_7series psv_ddr axi_bram_ctrl lmb_bram_if_cntlr"
	if {[lsearch -nocase $ddr_list $ddr_ip] >= 0} {
		set parent_node [add_or_get_dt_node -n / -d ${master_dts}]
		set unit_addr [get_baseaddr $drv_handle]
		set reg_value [hsi get_property CONFIG.reg $drv_handle]
		set addr [lindex $reg_value 1]
		regsub -all {^0x} $addr {} addr
		set memory_node [add_or_get_dt_node -n memory -u $addr -p $parent_node]
		add_new_dts_param "${memory_node}" "reg" $reg_value inthexlist
		# maybe hardcoded
		if {[catch {set dev_type [hsi get_property CONFIG.device_type $drv_handle]} msg]} {
			set dev_type memory
		}
		if {[string_is_empty $dev_type]} {set dev_type memory}
		add_new_dts_param "${memory_node}" "device_type" $dev_type string

		set_cur_working_dts $cur_dts
		set slave [hsi::get_cells -hier ${drv_handle}]
		set vlnv [split [hsi get_property VLNV $slave] ":"]
		set name [lindex $vlnv 2]
		set ver [lindex $vlnv 3]
		set comp_prop "xlnx,${name}-${ver}"
		regsub -all {_} $comp_prop {-} comp_prop
		add_new_dts_param "${memory_node}" "compatible" $comp_prop string
		add_new_dts_param "${memory_node}" "xlnx,ip-name" $ddr_ip string
		return $memory_node
	}
}

proc gen_mb_ccf_subnode {drv_handle name freq reg} {
	set cur_dts [current_dt_tree]
	set default_dts [set_drv_def_dts $drv_handle]

	set clk_node [add_or_get_dt_node -n clocks -p / -d ${default_dts}]
	add_new_dts_param "${clk_node}" "#address-cells" 1 int
	add_new_dts_param "${clk_node}" "#size-cells" 0 int

	set clk_subnode_name "clk_${name}"
	set clk_subnode [add_or_get_dt_node -l ${clk_subnode_name} -n ${clk_subnode_name} -u $reg -p ${clk_node} -d ${default_dts}]
	# clk subnode data
	add_new_dts_param "${clk_subnode}" "compatible" "fixed-clock" stringlist
	add_new_dts_param "${clk_subnode}" "#clock-cells" 0 int

	add_new_dts_param $clk_subnode "clock-output-names" $clk_subnode_name string
	add_new_dts_param $clk_subnode "reg" $reg int
	add_new_dts_param $clk_subnode "clock-frequency" $freq int

	set_cur_working_dts $cur_dts
}

proc generate_mb_ccf_node {drv_handle} {
	global bus_clk_list

	proc_called_by
	set family [get_hw_family]
	if {[regexp "kintex*" $family match]} {
		set cpu_clk_freq [get_clock_frequency $drv_handle "CLK"]
		# issue:
		# - hardcoded reg number cpu clock node
		# - assume clk_cpu for mb cpu
		# - only applies to master mb cpu
		gen_mb_ccf_subnode $drv_handle cpu $cpu_clk_freq 0
	}
}

proc gen_dev_ccf_binding args {
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
	if {[regexp "kintex*" $proctype match]} {
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
				set clk_refs [lappend clk_refs &clk_bus_${bus_clk_cnt}]
				set clk_names [lappend clk_names "$p"]
				set clk_freqs [lappend clk_freqs "$clk_freq"]
			}
		}
		if {[lsearch $binding_list "clocks"] >= 0} {
			add_new_property $drv_handle "clocks" referencelist $clk_refs
		}
		if {[lsearch $binding_list "clock-names"] >= 0} {
			add_new_property $drv_handle "clock-names" stringlist $clk_names
		}
		if {[lsearch $binding_list "clock-frequency"] >= 0} {
			add_new_property $drv_handle "clock-frequency" hexintlist $clk_freqs
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
		set valid_cascade_proc "kintex zynq zynqmp zynquplus versal"
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
	set valid_cascade_proc "kintex7 zynq zynqmp zynquplus versal"
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
	set_drv_prop $drv_handle interrupts $intr_info intlist
	if {[string_is_empty $intc]} {
		return -1
	}
	set intc [ps_node_mapping $intc label]
	set_drv_prop $drv_handle interrupt-parent $intc reference
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
	} elseif { [string match -nocase $IP_NAME "psu_acpu_gic"] || [string match -nocase $IP_NAME "psv_acpu_gic"]} {
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
	if {[regexp "kintex*" $proctype match]} {
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
    if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]
       || [string match -nocase $proctype "zynq"]} {
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
   } elseif {[string match -nocase $proctype "psv_cortexa72"]} {
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
		set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
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

proc update_endpoints {drv_handle} {
        global end_mappings
        global remo_mappings
	global set port1_end_mappings
        global set port2_end_mappings
        global set port3_end_mappings
        global set port4_end_mappings
        global set axis_port1_remo_mappings
        global set axis_port2_remo_mappings
        global set axis_port3_remo_mappings
        global set axis_port4_remo_mappings

	global set port1_broad_end_mappings
        global set port2_broad_end_mappings
        global set port3_broad_end_mappings
        global set port4_broad_end_mappings
        global set port5_broad_end_mappings
        global set port6_broad_end_mappings
        global set broad_port1_remo_mappings
        global set broad_port2_remo_mappings
        global set broad_port3_remo_mappings
        global set broad_port4_remo_mappings
        global set broad_port5_remo_mappings
        global set broad_port6_remo_mappings
        global set axis_switch_in_end_mappings
        global set axis_switch_in_remo_mappings
        global set axis_switch_port1_end_mappings
        global set axis_switch_port2_end_mappings
        global set axis_switch_port3_end_mappings
        global set axis_switch_port4_end_mappings
        global set axis_switch_port1_remo_mappings
        global set axis_switch_port2_remo_mappings
        global set axis_switch_port3_remo_mappings
        global set axis_switch_port4_remo_mappings

		set broad [get_count "broad"]

		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		set ip [hsi::get_cells -hier $drv_handle]
		if {[string match -nocase [hsi get_property IP_NAME $ip] "v_proc_ss"]} {
			set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
			if {$topology == 0} {
				set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
				add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
				set ports_node [create_node -n "ports" -l scaler_ports$drv_handle -p $node -d $dts_file]
				add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
				add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
				set port_node [create_node -n "port" -l scaler_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
				add_prop "$port_node" "reg" 0 int $dts_file
				add_prop "$port_node" "xlnx,video-format" 3 int $dts_file
				add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
				set scaninip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis"]
				foreach inip $scaninip {
						if {[llength $inip]} {
								set ip_mem_handles [hsi::get_mem_ranges $inip]
								if {![llength $ip_mem_handles]} {
										set broad_ip [get_broad_in_ip $inip]
										if {[llength $broad_ip]} {
												if {[string match -nocase [hsi get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
														set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
														set intlen [llength $master_intf]
														set sca_in_end ""
														set sca_remo_in_end ""
														switch $intlen {
															"1" {
																	if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
																			set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
																			dtg_verbose "sca_in_end:$sca_in_end"
																	}
																	if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
																			set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
																			dtg_verbose "drv:$drv_handle inremoend:$sca_remo_in_end"
																	}
																	if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
																			if {[llength $sca_remo_in_end]} {
																					set sca_node [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
																			}
																			if {[llength $sca_in_end]} {
																							add_prop "$sca_node" "remote-endpoint" $sca_in_end reference $dts_file
																			}
																	}
															}
															"2" {
																if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
																		set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
																}
																if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
																		set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
																}
																if {[info exists port1_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
																		set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
																}
																if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
																		set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
																}
																if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
																		if {[llength $sca_remo_in_end]} {
																				set sca_node [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
																}
																		if {[llength $sca_in_end]} {
																				add_prop "$sca_node" "remote-endpoint" $sca_in_end reference $dts_file
																		}
																}
																if {[regexp -nocase $drv_handle "$sca_remo_in1_end" match]} {
																		if {[llength $sca_remo_in1_end]} {
																				set sca_node [create_node -n "endpoint" -l $sca_remo_in1_end -p $port_node -d $dts_file]
																		}
																		if {[llength $sca_in1_end]} {
																				add_prop "$sca_node" "remote-endpoint" $sca_in1_end reference $dts_file
																		}
																}
															}
															"3" {
																if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
																		set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
																}
																if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
																		set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
																}
																if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
																		set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
																}
																if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
																		set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
																}
																if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
																		set sca_in2_end [dict get $port3_broad_end_mappings $broad_ip]
																}
																if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
																		set sca_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
																}
																if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
																		if {[llength $sca_remo_in_end]} {
																				set sca_node [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
																		}
																		if {[llength $sca_in_end]} {
																				add_prop "$sca_node" "remote-endpoint" $sca_in_end reference $dts_file
																		}
																}
																if {[regexp -nocase $drv_handle "$sca_remo_in1_end" match]} {
																		if {[llength $sca_remo_in1_end]} {
																				set sca_node [create_node -n "endpoint" -l $sca_remo_in1_end -p $port_node -d $dts_file]
																		}
																		if {[llength $sca_in1_end]} {
																				add_prop "$sca_node" "remote-endpoint" $sca_in1_end reference $dts_file
																		}
																}
																if {[regexp -nocase $drv_handle "$sca_remo_in2_end" match]} {
																	if {[llength $sca_remo_in2_end]} {
                                                                        set sca_node [create_node -n "endpoint" -l $sca_remo_in2_end -p $port_node -d $dts_file]
                                                                    }
																	if {[llength $sca_in2_end]} {
																			add_prop "$sca_node" "remote-endpoint" $sca_in2_end reference $dts_file
																	}
																}
															}
															"4" {
						 if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
                                                                        set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
                                                                }
                                                                if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
                                                                        set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
                                                                }

                                                                if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
                                                                        set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
                                                                }
                                                                if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
                                                                        set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
                                                                }

                                                                if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
                                                                        set sca_in2_end [dict get $port3_broad_end_mappings $broad_ip]
                                                                }
                                                                if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
                                                                        set sca_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
                                                                }
                                                                if {[info exists port4_broad_end_mappings] && [dict exists $port4_broad_end_mappings $broad_ip]} {
                                                                        set sca_in3_end [dict get $port4_broad_end_mappings $broad_ip]
                                                                }
                                                                if {[info exists broad_port4_remo_mappings] && [dict exists $broad_port4_remo_mappings $broad_ip]} {
                                                                        set sca_remo_in3_end [dict get $broad_port4_remo_mappings $broad_ip]
                                                                }
															}
														}
                                                return
                                        }
									}
                                }
							}
						}




			 foreach inip $scaninip {
                                if {[llength $inip]} {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                        set ip_mem_handles [hsi::get_mem_ranges $inip]
                                        if {[llength $ip_mem_handles]} {
                                                set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                        } else {
                                                set inip [get_in_connect_ip $inip $master_intf]
                                                if {[llength $inip]} {
                                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "axi_vdma"]} {
                                                                gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
                                                        }
                                                }
                                        }
                                        if {[llength $inip]} {
                                                set sca_in_end ""
                                                set sca_remo_in_end ""
						if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                                        set sca_in_end [dict get $end_mappings $inip]
                                                }
						if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                                        set sca_remo_in_end [dict get $remo_mappings $inip]
                                                }
                                                if {[llength $sca_remo_in_end]} {
                                                        set scainnode [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
                                                }
                                                if {[llength $sca_in_end]} {
                                                        add_prop "$scainnode" "remote-endpoint" $sca_in_end reference $dts_file
                                                }
                                        }
                                } else {
                                        dtg_warning "$drv_handle pin s_axis is not connected..check your design"
                                }
                        }
		}
		if {$topology == 3} {
			set ports_node [create_node -n "ports" -l csc_ports$drv_handle -p $node -d $dts_file]
			add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
			add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
			set port_node [create_node -n "port" -l csc_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
			add_prop "$port_node" "reg" 0 int $dts_file
			add_prop "$port_node" "xlnx,video-format" 3 int $dts_file
			set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
			add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
			set cscinip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis"]
			if {[llength $cscinip]} {
					foreach inip $cscinip {
							set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set ip_mem_handles [hsi::get_mem_ranges $inip]
							if {[llength $ip_mem_handles]} {
									set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
									if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
											gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
									}
							} else {
									set inip [get_in_connect_ip $inip $master_intf]
									if {[llength $inip]} {
											if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
													continue
											}
											if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
													gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
											}
									}
							}
							if {[llength $inip]} {
									set csc_in_end ""
									set csc_remo_in_end ""
									if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
											set csc_in_end [dict get $end_mappings $inip]
											dtg_verbose "drv:$drv_handle inend:$csc_in_end"
									}
									if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
											set csc_remo_in_end [dict get $remo_mappings $inip]
											dtg_verbose "drv:$drv_handle inremoend:$csc_remo_in_end"
									}
									if {[llength $csc_remo_in_end]} {
											set cscinnode [create_node -n "endpoint" -l $csc_remo_in_end -p $port_node -d $dts_file]
									}
									if {[llength $csc_in_end]} {
											add_prop "$cscinnode" "remote-endpoint" $csc_in_end reference $dts_file
									}
							}
					}
			} else {
					dtg_warning "$drv_handle pin s_axis is not connected..check your design"
			}
		}

	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_demosaic"]} {
		set ports_node [create_node -n "ports" -l demosaic_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                set port_node [create_node -n "port" -l demosaic_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$port_node" "reg" 0 int $dts_file
                add_prop "$port_node" "xlnx,cfa-pattern" rggb string $dts_file
		set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
                add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
		set demo_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
		set len [llength $demo_inip]
		if {$len > 1} {
			for {set i 0 } {$i < $len} {incr i} {
                		set temp_ip [lindex $demo_inip $i]
                		if {[regexp -nocase "ila" $temp_ip match]} {
                        		continue
               	 		}
                	set demo_inip "$temp_ip"
        		}
		}	
		foreach inip $demo_inip {
			if {[llength $inip]} {
				set ip_mem_handles [hsi::get_mem_ranges $inip]
                               if {![llength $ip_mem_handles]} {
                                       set broad_ip [get_broad_in_ip $inip]
                                       if {[llength $broad_ip]} {
                                               if {[string match -nocase [hsi get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
                                                       set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                                                       set intlen [llength $master_intf]
                                                       set mipi_in_end ""
                                                       set mipi_remo_in_end ""
                                                       switch $intlen {
                                                               "1" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
                                                                               set mipi_in_end [dict get $port1_broad_end_mappings $broad_ip]
                                                               }
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
                                                                               set mipi_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
                                                               }
								if {[info exists sca_remo_in_end] && [regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
                                                                       if {[llength $mipi_remo_in_end]} {
                                                                               set mipi_node [create_node -n "endpoint" -l $mipi_remo_in_end -p $port_node -d $dts_file]
                                                                       }
                                                                       if {[llength $mipi_in_end]} {
                                                                               add_prop "$mipi_node" "remote-endpoint" $mipi_in_end reference $dts_file
                                                                       }
                                                               }

                                                               }
                                                               "2" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
                                                                               set mipi_in_end [dict get $port1_broad_end_mappings $broad_ip]
                                                                       }
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
                                                                               set mipi_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
                                                                       }
									if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
                                                                               set mipi_in1_end [dict get $port2_broad_end_mappings $broad_ip]
                                                                       }
									if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
                                                                               set mipi_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
                                                                       }
									if {[info exists mipi_remo_in_end] && [regexp -nocase $drv_handle "$mipi_remo_in_end" match]} {
                                                                               if {[llength $mipi_remo_in_end]} {
                                                                                       set mipi_node [create_node -n "endpoint" -l $mipi_remo_in_end -p $port_node -d $dts_file]
                                                                       }
                                                                       if {[llength $mipi_in_end]} {
                                                                               add_prop "$mipi_node" "remote-endpoint" $mipi_in_end reference $dts_file
                                                                       }
                                                                       }
									if {[info exists mipi_remo_in1_end] && [regexp -nocase $drv_handle "$mipi_remo_in1_end" match]} {
                                                                               if {[llength $mipi_remo_in1_end]} {
                                                                                       set mipi_node [create_node -n "endpoint" -l $mipi_remo_in1_end -p $port_node -d $dts_file]
                                                                       }
                                                                       if {[llength $mipi_in1_end]} {
                                                                               add_prop "$mipi_node" "remote-endpoint" $mipi_in1_end reference $dts_file
                                                                       }
                                                                       }
                                                               }
                                                       }
                                                       return
                                               }
                                       }
                               }
                       }
               }

	set inip ""
	if {[llength $demo_inip]} {
		if {[string match -nocase [hsi get_property IP_NAME $demo_inip] "axis_switch"]} {
                        set ip_mem_handles [hsi::utils::get_ip_mem_ranges $demo_inip]
                        if {![llength $ip_mem_handles]} {
			set demo_in_end ""
			set demo_remo_in_end ""
			if {[info exists port1_end_mappings] && [dict exists $port1_end_mappings $demo_inip]} {
				set demo_in_end [dict get $port1_end_mappings $demo_inip]
				dtg_verbose "demo_in_end:$demo_in_end"
			}
			if {[info exists axis_port1_remo_mappings] && [dict exists $axis_port1_remo_mappings $demo_inip]} {
				set demo_remo_in_end [dict get $axis_port1_remo_mappings $demo_inip]
				dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
			}
			if {[info exists port2_end_mappings] && [dict exists $port2_end_mappings $demo_inip]} {
				set demo_in1_end [dict get $port2_end_mappings $demo_inip]
				dtg_verbose "demo_in1_end:$demo_in1_end"
			}
			if {[info exists axis_port2_remo_mappings] && [dict exists $axis_port2_remo_mappings $demo_inip]} {
				set demo_remo_in1_end [dict get $axis_port2_remo_mappings $demo_inip]
				dtg_verbose "demo_remo_in1_end:$demo_remo_in1_end"
			}
			if {[info exists axis_port2-remo_mappings] && [dict exists $axis_port2_remo_mappings $demo_inip]} {
				set demo_in2_end [dict get $port3_end_mappings $demo_inip]
				dtg_verbose "demo_in2_end:$demo_in2_end"
			}
			if {[info exists axis_port3_remo_mappings] && [dict exists $axis_port3_remo_mappings $demo_inip]} {
				set demo_remo_in2_end [dict get $axis_port3_remo_mappings $demo_inip]
				dtg_verbose "demo_remo_in2_end:$demo_remo_in2_end"
			}
			if {[info exists port4_end_mappings] && [dict exists $port4_end_mappings $demo_inip]} {
				set demo_in3_end [dict get $port4_end_mappings $demo_inip]
				dtg_verbose "demo_in3_end:$demo_in3_end"
			}
			if {[info exists axis_port4_remo_mappings] && [dict exists $axis_port4_remo_mappings $demo_inip]} {
				set demo_remo_in3_end [dict get $axis_port4_remo_mappings $demo_inip]
				dtg_verbose "demo_remo_in3_end:$demo_remo_in3_end"
			}
			set drv [split $demo_remo_in_end "-"]
			set handle [lindex $drv 0]
			if {[regexp -nocase $drv_handle "$demo_remo_in_end" match]} {

				if {[llength $demo_remo_in_end]} {
					set demosaic_node [create_node -n "endpoint" -l $demo_remo_in_end -p $port_node -d $dts_file]
					puts "demosaic_node:$demosaic_node"
				}
				if {[llength $demo_in_end]} {
					add_prop "$demosaic_node" "remote-endpoint" $demo_in_end reference $dts_file
				}
				dtg_verbose "****DEMO_END1****"
			}
			if {[info exists demo_remo_in1_end] && [regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
				if {[llength $demo_remo_in1_end]} {
					set demosaic_node1 [create_node -n "endpoint" -l $demo_remo_in1_end -p $port_node -d $dts_file]
					puts "demosaic_node1:$demosaic_node1"
				}
				if {[llength $demo_in1_end]} {
					add_prop "$demosaic_node1" "remote-endpoint" $demo_in1_end reference $dts_file
				}
				dtg_verbose "****DEMO_END2****"
			}
			if {[info exists demo_remo_in2_end] && [regexp -nocase $drv_handle "$demo_remo_in2_end" match]} {
				if {[llength $demo_remo_in2_end]} {
					set demosaic_node2 [create_node -n "endpoint" -l $demo_remo_in2_end -p $port_node -d $dts_file]
					puts "demosaic_node2:$demosaic_node2"
				}
				if {[llength $demo_in2_end]} {
					add_prop "$demosaic_node2" "remote-endpoint" $demo_in2_end reference $dts_file
				}
				dtg_verbose "****DEMO_END3****"
			}
			if {[info exists demo_remo_in3_end] && [regexp -nocase $drv_handle "$demo_remo_in3_end" match]} {
				if {[llength $demo_remo_in3_end]} {
					set demosaic_node3 [create_node -n "endpoint" -l $demo_remo_in3_end -p $port_node -d $dts_file]
					puts "demosaic_node3:$demosaic_node3"
				}
				if {[llength $demo_in3_end]} {
					add_prop "$demosaic_node3" "remote-endpoint" $demo_in3_end reference $dts_file
				}
				dtg_verbose "****DEMO_END3****"
			}
			return
			} else {
                               set demo_in_end ""
                               set demo_remo_in_end ""
                               if {[info exists axis_switch_port1_end_mappings] && [dict exists $axis_switch_port1_end_mappings $demo_inip]} {
                                       set demo_in_end [dict get $axis_switch_port1_end_mappings $demo_inip]
                                       dtg_verbose "demo_in_end:$demo_in_end"
                               }
                               if {[info exists axis_switch_port1_remo_mappings] && [dict exists $axis_switch_port1_remo_mappings $demo_inip]} {
                                       set demo_remo_in_end [dict get $axis_switch_port1_remo_mappings $demo_inip]
                                       dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
                               }
                               if {[info exists axis_switch_port2_end_mappings] && [dict exists $axis_switch_port2_end_mappings $demo_inip]} {
                                       set demo_in1_end [dict get $axis_switch_port2_end_mappings $demo_inip]
                                       dtg_verbose "demo_in1_end:$demo_in1_end"
                               }
                               if {[info exists axis_switch_port2_remo_mappings] && [dict exists $axis_switch_port2_remo_mappings $demo_inip]} {
                                       set demo_remo_in1_end [dict get $axis_switch_port2_remo_mappings $demo_inip]
                                       dtg_verbose "demo_remo_in1_end:$demo_remo_in1_end"
                               }
                               if {[info exists axis_switch_port3_end_mappings] && [dict exists $axis_switch_port3_end_mappings $demo_inip]} {
                                       set demo_in2_end [dict get $axis_switch_port3_end_mappings $demo_inip]
                                       dtg_verbose "demo_in2_end:$demo_in2_end"
                               }
                               if {[info exists axis_switch_port3_remo_mappings] && [dict exists $axis_switch_port3_remo_mappings $demo_inip]} {
                                       set demo_remo_in2_end [dict get $axis_switch_port3_remo_mappings $demo_inip]
                                       dtg_verbose "demo_remo_in2_end:$demo_remo_in2_end"
                               }
                               if {[info exists axis_switch_port4_end_mappings] && [dict exists $axis_switch_port4_end_mappings $demo_inip]} {
                                       set demo_in3_end [dict get $axis_switch_port4_end_mappings $demo_inip]
                                       dtg_verbose "demo_in3_end:$demo_in3_end"
                               }
                               if {[info exists axis_switch_port4_remo_mappings] && [dict exists $axis_switch_port4_remo_mappings $demo_inip]} {
                                       set demo_remo_in3_end [dict get $axis_switch_port4_remo_mappings $demo_inip]
                                       dtg_verbose "demo_remo_in3_end:$demo_remo_in3_end"
                               }
                               set drv [split $demo_remo_in_end "-"]
                               set handle [lindex $drv 0]
                               if {[regexp -nocase $drv_handle "$demo_remo_in_end" match]} {
                                       if {[llength $demo_remo_in_end]} {
                                               set demosaic_node [create_node -n "endpoint" -l $demo_remo_in_end -p $port_node -d $dts_file]
                                       }
                                       if {[llength $demo_in_end]} {
                                               add_prop "$demosaic_node" "remote-endpoint" $demo_in_end reference $dts_file
                                       }
                                       dtg_verbose "****DEMO_END1****"
                               }
                               if {[regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
                                       if {[llength $demo_remo_in1_end]} {
                                               set demosaic_node1 [create_node -n "endpoint" -l $demo_remo_in1_end -p $port_node -d $dts_file]
                                       }
                                       if {[llength $demo_in1_end]} {
                                               add_prop "$demosaic_node1" "remote-endpoint" $demo_in1_end reference $dts_file
                                       }
                                       dtg_verbose "****DEMO_END2****"
                               }
                       }			
			}
		}
                if {[llength $demo_inip]} {
                        foreach inip $demo_inip {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                }
                                if {[llength $inip]} {
                                        set demo_in_end ""
                                        set demo_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                                set demo_in_end [dict get $end_mappings $inip]
						dtg_verbose "demo_in_end:$demo_in_end"
                                        }
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                                set demo_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
                                        }
                                        if {[llength $demo_remo_in_end]} {
                                                set demosaic_node [create_node -n "endpoint" -l $demo_remo_in_end -p $port_node -d $dts_file]
                                        }
                                        if {[llength $demo_in_end]} {
                                                add_prop "$demosaic_node" "remote-endpoint" $demo_in_end reference $dts_file
                                        }
                                }
                        }
                } else {
                        dtg_warning "$drv_handle pin s_axis is not connected..check your design"
                }
		dtg_verbose "***************DEMOEND****************"
	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_gamma_lut"]} {
                set ports_node [create_node -n "ports" -l gamma_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
		add_prop "$ports_node" "#size-cells" 0 int $dts_file 1

                set port_node [create_node -n "port" -l gamma_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$port_node" "reg" 0 int $dts_file
		set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
                add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
		set gamma_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
		set inip ""
                if {[llength $gamma_inip]} {
                        foreach inip $gamma_inip {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                }
                                if {[llength $inip]} {
                                        set gamma_in_end ""
                                        set gamma_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                                set gamma_in_end [dict get $end_mappings $inip]
						dtg_verbose "gamma_in_end:$gamma_in_end"
                                        }
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                                set gamma_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "gamma_remo_in_end:$gamma_remo_in_end"
                                        }
                                        if {[llength $gamma_remo_in_end]} {
                                                set gamma_node [create_node -n "endpoint" -l $gamma_remo_in_end -p $port_node -d $dts_file]
                                        }
                                        if {[llength $gamma_in_end]} {
                                                add_prop "$gamma_node" "remote-endpoint" $gamma_in_end reference $dts_file
                                        }
                                }
                        }
                } else {
                        dtg_warning "$drv_handle pin s_axis_video is not connected..check your design"
                }

	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_hdmi_tx_ss"]} {
                set ports_node [create_node -n "ports" -l hdmitx_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                set hdmi_port_node [create_node -n "port" -l encoder_hdmi_port$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$hdmi_port_node" "reg" 0 int $dts_file
                set hdmitx_in_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_IN"]
                if {![llength $hdmitx_in_ip]} {
                        dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
                }
                set inip ""
                foreach inip $hdmitx_in_ip {
                        if {[llength $inip]} {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $hdmitx_in_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node $dts_file
                                        }
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node $dts_file
                                        }
                                }
                        }
                }
		 if {[llength $inip]} {
                        set hdmitx_in_end ""
                        set hdmitx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                set hdmitx_in_end [dict get $end_mappings $inip]
				dtg_verbose "hdmitx_in_end:$hdmitx_in_end"
                        }
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                set hdmitx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "hdmitx_remo_in_end:$hdmitx_remo_in_end"
                        }
                        if {[llength $hdmitx_remo_in_end]} {
                                set hdmitx_node [create_node -n "endpoint" -l $hdmitx_remo_in_end -p $hdmi_port_node -d $dts_file]
                        }
                        if {[llength $hdmitx_in_end]} {
                                add_prop "$hdmitx_node" "remote-endpoint" $hdmitx_in_end reference $dts_file
                        }
                }
        }

	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_tpg"]} {
		set family [get_hw_family]
               if {[string match -nocase $family "zynq"]} {
                       #TBF
                       return
               }
		set ports_node [create_node -n "ports" -l tpg_ports$drv_handle -p $node -d $dts_file]
		set port0_node [create_node -n "port" -l tpg_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$port0_node" "reg" 0 int $dts_file 1
                add_prop "$port0_node" "xlnx,video-format" 2 int $dts_file 1
		 set tpg_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
               if {![llength $tpg_inip]} {
                       dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected..check your design"
               }
                 set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $tpg_inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                set inip [get_in_connect_ip $tpg_inip $master_intf]
                if {[llength $inip]} {
                        set tpg_in_end ""
                        set tpg_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                set tpg_in_end [dict get $end_mappings $inip]
                        }
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                set tpg_remo_in_end [dict get $remo_mappings $inip]
                        }
                        if {[llength $tpg_remo_in_end]} {
                                set tpg_node [create_node -n "endpoint" -l $tpg_remo_in_end -p $port0_node -d $dts_file]
                        }
                        if {[llength $tpg_in_end]} {
                                add_prop "$tpg_node" "remote-endpoint" $tpg_in_end reference $dts_file
                        }
                }
	}

	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_smpte_uhdsdi_tx_ss"]} {
                set ports_node [create_node -n "ports" -l sditx_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                set sdi_port_node [create_node -n "port" -l encoder_sdi_port$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$sdi_port_node" "reg" 0 int $dts_file
                set sditx_in_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_IN"]
                if {![llength $sditx_in_ip]} {
                        dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
                }
                set inip ""
                foreach inip $sditx_in_ip {
                        if {[llength $inip]} {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $sdi_port_node $dts_file
                                        }
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $sdi_port_node $dts_file
                                        }
                                }
                        }
                }
		if {[llength $inip]} {
                        set sditx_in_end ""
                        set sditx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                set sditx_in_end [dict get $end_mappings $inip]
				dtg_verbose "sditx_in_end:$sditx_in_end"
                        }
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                set sditx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "sditx_remo_in_end:$sditx_remo_in_end"
                        }
                        if {[llength $sditx_remo_in_end]} {
                                set sditx_node [create_node -n "endpoint" -l $sditx_remo_in_end -p $sdi_port_node -d $dts_file]
                        }
                        if {[llength $sditx_in_end]} {
                                add_prop "$sditx_node" "remote-endpoint" $sditx_in_end reference $dts_file
                        }
                }
	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "mipi_dsi_tx_subsystem"]} {
		set dsitx_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]
		if {![llength $dsitx_inip]} {
			dtg_warning "$drv_handle pin S_AXIS is not connected ..check your design"
		}
		set port_node [create_node -n "port" -l encoder_dsi_port$drv_handle -u 0 -p $node -d $dts_file]
		add_prop "$port_node" "reg" 0 int $dts_file
		set inip ""
		foreach inip $dsitx_inip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
					}
				} else {
					if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
					if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
					}
				}
			}
		}
		if {[llength $inip]} {
                        set dsitx_in_end ""
                        set dsitx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                set dsitx_in_end [dict get $end_mappings $inip]
				dtg_verbose "dsitx_in_end:$dsitx_in_end"
                        }
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                set dsitx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "dsitx_remo_in_end:$dsitx_remo_in_end"
                        }
                        if {[llength $dsitx_remo_in_end]} {
                                set dsitx_node [create_node -n "endpoint" -l $dsitx_remo_in_end -p $port_node -d $dts_file]
                        }
                        if {[llength $dsitx_in_end]} {
				add_prop "$dsitx_node" "remote-endpoint" $dsitx_in_end reference $dts_file
                        }
                }
	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_scenechange"]} {
		set memory_scd [hsi get_property CONFIG.MEMORY_BASED [hsi::get_cells -hier $drv_handle]]
		if {$memory_scd == 1} {
			#memory scd
			return
		}
		set scd_ports_node [create_node -n "scd" -l scd_ports$drv_handle -p $node -d $dts_file]
		add_prop "$scd_ports_node" "#address-cells" 1 int $dts_file 1
		add_prop "$scd_ports_node" "#size-cells" 0 int $dts_file 1
		set port_node [create_node -n "port" -l scd_port0$drv_handle -u 0 -p $scd_ports_node -d $dts_file]
		add_prop "$port_node" "reg" 0 int $dts_file
		set scd_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
		if {![llength $scd_inip]} {
			dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected...check your design"
		}
		set broad_ip [get_broad_in_ip $scd_inip]
               if {[llength $broad_ip]} {
               if {[string match -nocase [hsi get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
                       set scd_in_end ""
                       set scd_remo_in_end ""
			if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
                               set scd_in_end [dict get $port1_broad_end_mappings $broad_ip]
                       }
			if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
                               set scd_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
                       }
			if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
                               set scd_in1_end [dict get $port2_broad_end_mappings $broad_ip]
                       }
			if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
                               set scd_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
                       }
			if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
                               set scd_in2_end [dict get $port3_broad_end_mappings $broad_ip]
                       }
			if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
                               set scd_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
                       }
			if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
                               set scd_in3_end [dict get $port4_broad_end_mappings $broad_ip]
                       }
			if {[info exists port4_broad_end_mappings] && [dict exists $port4_broad_end_mappings $broad_ip]} {
                               set scd_remo_in3_end [dict get $broad_port4_remo_mappings $broad_ip]
                       }
			if {[info exists scd_remo_in_end] && [regexp -nocase $drv_handle "$scd_remo_in_end" match]} {
                               if {[llength $scd_remo_in_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in_end reference $dts_file
                               }
                       }
			if {[info exists scd_remo_in1_end] && [regexp -nocase $drv_handle "$scd_remo_in1_end" match]} {
                               if {[llength $scd_remo_in1_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in1_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in1_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in1_end reference $dts_file
                               }
                       }
			if {[info exists scd_remo_in2_end] && [regexp -nocase $drv_handle "$scd_remo_in2_end" match]} {
                               if {[llength $scd_remo_in2_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in2_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in2_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in2_end reference $dts_file
                               }
                       }
			if {[info exists scd_remo_in3_end] && [regexp -nocase $drv_handle "$scd_remo_in3_end" match]} {
                               if {[llength $scd_remo_in3_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in3_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in3_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in3_end reference $dts_file
                               }
                       }
                       return
               }
               }
		foreach inip $scd_inip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
				} else {
					if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
				}
				if {[llength $inip]} {
					set scd_in_end ""
					set scd_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set scd_in_end [dict get $end_mappings $inip]
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set scd_remo_in_end [dict get $remo_mappings $inip]
					}
					if {[llength $scd_remo_in_end]} {
						set scd_node [create_node -n "endpoint" -l $scd_remo_in_end -p $port_node -d $dts_file]
					}
					if {[llength $scd_in_end]} {
						add_prop "$scd_node" "remote-endpoint" $scd_in_end reference $dts_file
					}
				}
			}
		}


	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "axis_broadcaster"]} {
			set axis_broad_ip [hsi get_property IP_NAME $ip]
			set unit_addr [get_baseaddr ${ip} no_prefix]
			if { ![string equal $unit_addr ""] } {
				#break
				return
			}
			set label $ip
			set ip_type [hsi get_property IP_TYPE $ip]
                        if {[string match -nocase $ip_type "BUS"]} {
                               #break
								return
                        }

			set bus_node [detect_bus_name $ip]
			set dts_file [set_drv_def_dts $ip]
			 set rt_node [create_node -n "axis_broadcaster$ip" -l ${label} -u 0 -d ${dts_file} -p $bus_node]
                        if {[llength $axis_broad_ip]} {
                                set intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set inip [get_in_connect_ip $ip $intf]
                                if {[llength $inip]} {
                                        set inipname [hsi get_property IP_NAME $inip]
set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_l
ut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_sc
enechange"
                                if {[lsearch  -nocase $valid_mmip_list $inipname] >= 0} {
                                set ports_node [create_node -n "ports" -l axis_broadcaster_ports$ip -p $rt_node -d $dts_file]
                                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                                set port_node [create_node -n "port" -l axis_broad_port0$ip -u 0 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 0 int $dts_file
				if {[llength $inip]} {
                                        set axis_broad_in_end ""
                                        set axis_broad_remo_in_end ""
                                        if {[dict exists $end_mappings $inip]} {
                                                set axis_broad_in_end [dict get $end_mappings $inip]
						dtg_verbose "drv:$ip inend:$axis_broad_in_end"
                                        }
                                        if {[dict exists $remo_mappings $inip]} {
                                                set axis_broad_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "drv:$ip inremoend:$axis_broad_remo_in_end"
                                        }
                                        if {[llength $axis_broad_remo_in_end]} {
                                                set axisinnode [create_node -n "endpoint" -l $axis_broad_remo_in_end -p $port_node -d $dts_file]
                                        }
                                        if {[llength $axis_broad_in_end]} {
                                                add_prop "$axisinnode" "remote-endpoint" $axis_broad_in_end reference $dts_file 1
                                        }
                                        }
                                }
                                }
                        }
	}

	 if {[string match -nocase [hsi get_property IP_NAME $ip] "axis_switch"]} {
		set axis_ip [hsi get_property IP_NAME $ip]
		set dts_file [set_drv_def_dts $ip]
		set unit_addr [get_baseaddr ${ip} no_prefix]
		if { ![string equal $unit_addr ""] } {
			return
		}
		set label $ip
		set bus_node [detect_bus_name $ip]
		set dev_type [hsi get_property IP_NAME [hsi::get_cells -hier [hsi::get_cells -hier $ip]]]
		if {[llength $axis_ip]} {
			set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
			set inip [get_in_connect_ip $ip $intf]
			if {[llength $inip]} {
			set inipname [hsi get_property IP_NAME $inip]
			set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_l
ut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_sc
enechange"
		if {[lsearch  -nocase $valid_mmip_list $inipname] >= 0} {
			set rt_node [create_node -n ${dev_type} -l ${label} -u 0 -d $dts_file -p $bus_node]
			set ports_node [create_node -n "ports" -l axis_switch_ports$ip -p $rt_node -d $dts_file]
			gen_axis_switch_clk_property $ip $dts_file $rt_node
			add_prop "$ports_node" "#address-cells" 1 int $dts_file
			add_prop "$ports_node" "#size-cells" 0 int $dts_file
			set port_node [create_node -n "port" -l axis_switch_port0$ip -u 0 -p $ports_node -d $dts_file]
			add_prop "$port_node" "reg" 0 int $dts_file
			if {[llength $inip]} {
			       set axis_switch_in_end ""
			       set axis_switch_remo_in_end ""
				if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
				       set axis_switch_in_end [dict get $end_mappings $inip]
				       dtg_verbose "drv:$ip inend:$axis_switch_in_end"
			       }
				if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
				       set axis_switch_remo_in_end [dict get $remo_mappings $inip]
				       dtg_verbose "drv:$ip inremoend:$axis_switch_remo_in_end"
			       }
			       if {[llength $axis_switch_remo_in_end]} {
				       set axisinnode [create_node -n "endpoint" -l $axis_switch_remo_in_end -p $port_node -d $dts_file]
			       }
			       if {[llength $axis_switch_in_end]} {
				       add_prop "$axisinnode" "remote-endpoint" $axis_switch_in_end reference $dts_file
			       }

				}
			}
		}
	}
	}
}

proc gen_broadcaster {ip dts_file} {
	dtg_verbose "+++++++++gen_broadcaster:$ip"
        set compatible [get_comp_str $ip]
        set intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
        set inip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
        set inip [get_in_connect_ip $ip $intf]
	set bus_node [detect_bus_name $ip]
        set broad_node [create_node -n "axis_broadcaster$ip" -l $ip -u 0 -p $bus_node -d $dts_file]
        set ports_node [create_node -n "ports" -l axis_broadcaster_ports$ip -p $broad_node -d $dts_file]
        add_prop "$ports_node" "#address-cells" 1 int $dts_file
        add_prop "$ports_node" "#size-cells" 0 int $dts_file
        add_prop "$broad_node" "compatible" "$compatible" string $dts_file
        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
        set broad 10
        set count 0
	foreach intf $master_intf {
		set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
		if {[llength $connectip]} {
			set ip_mem_handles [hsi::get_mem_ranges $connectip]
				if {![llength $ip_mem_handles]} {
					set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
					set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master_intf]
					if {[llength $connectip]} {
						set ip_mem_handles [hsi::get_mem_ranges $connectip]
						if {![llength $ip_mem_handles]} {
							set master2_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
							set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master2_intf]
						}
						if {[llength $connectip]} {
							set ip_mem_handles [hsi::get_mem_ranges $connectip]
							if {![llength $ip_mem_handles]} {
							set master3_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
							set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master3_intf]
						}
					}
				}
			}
			incr count
		}
                if {$count == 1} {
                        if {[llength $connectip]} {
                                set port_node [create_node -n "port" -l axis_broad_port1$ip -u 1 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 1 int $dts_file
                                set axis_node [create_node -n "endpoint" -l axis_broad_out1$ip -p $port_node -d $dts_file]
                                gen_broad_port1_endpoint $ip "axis_broad_out1$ip"
                                add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
                                gen_broad_port1_remoteendpoint $ip $connectip$ip
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_broad_frmbuf_wr_node $connectip $connectip$ip "axis_broad_out1$ip" $ip $dts_file
                                }
                        }
                }
                if {$count == 2} {
                        if {[llength $connectip]} {
                                set port_node [create_node -n "port" -l axis_broad_port2$ip -u 2 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 2 int $dts_file
                                set axis_node [create_node -n "endpoint" -l axis_broad_out2$ip -p $port_node -d $dts_file]
                                gen_broad_port2_endpoint $ip "axis_broad_out2$ip"
                                add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
                                gen_broad_port2_remoteendpoint $ip $connectip$ip
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_broad_frmbuf_wr_node $connectip $connectip$ip "axis_broad_out2$ip" $ip $dts_file
                                }
                        }
                }
                if {$count == 3} {
                        if {[llength $connectip]} {
                                set port_node [create_node -n "port" -l axis_broad_port3$ip -u 3 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 3 int $dts_file
                                set axis_node [create_node -n "endpoint" -l axis_broad_out3$ip -p $port_node -d $dts_file]
                                gen_broad_port3_endpoint $ip "axis_broad_out3$ip"
                                add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
                                gen_broad_port3_remoteendpoint $ip $connectip$ip
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_broad_frmbuf_wr_node $connectip $connectip$ip "axis_broad_out3$ip" $ip $dts_file
                                }
                        }
                }
		if {$count == 4} {
                        if {[llength $connectip]} {
                                set port_node [create_node -n "port" -l axis_broad_port4$ip -u 4 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 4 int $dts_file
                                set axis_node [create_node -n "endpoint" -l axis_broad_out4$ip -p $port_node -d $dts_file]
                                gen_broad_port4_endpoint $ip "axis_broad_out4$ip"
                                add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
                                gen_broad_port4_remoteendpoint $ip $connectip$ip
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_broad_frmbuf_wr_node $connectip $connectip$ip "axis_broad_out4$ip" $ip $dts_file
                                }
                        }
                }
                if {$count == 5} {
                        if {[llength $connectip]} {
                                set port_node [create_node -n "port" -l axis_broad_port5$ip -u 5 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 5 int $dts_file
                                set axis_node [create_node -n "endpoint" -l axis_broad_out5$ip -p $port_node -d $dts_file]
                                gen_broad_port5_endpoint $ip "axis_broad_out5$ip"
                                add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
                                gen_broad_port5_remoteendpoint $ip $connectip$ip
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_broad_frmbuf_wr_node $connectip $connectip$ip "axis_broad_out5$ip" $ip $dts_file
                                }
                        }
                }
                if {$count == 6} {
                        if {[llength $connectip]} {
                                set port_node [create_node -n "port" -l axis_broad_port6$ip -u 6 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 6 int $dts_file
                                set axis_node [create_node -n "endpoint" -l axis_broad_out6$ip -p $port_node -d $dts_file]
                                gen_broad_port6_endpoint $ip "axis_broad_out6$ip"
                                add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
                                gen_broad_port6_remoteendpoint $ip $connectip$ip
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_broad_frmbuf_wr_node $connectip $connectip$ip "axis_broad_out6$ip" $ip $dts_file
                                }
                        }
                }
		if {$count == 7} {
                        if {[llength $connectip]} {
                                set port_node [create_node -n "port" -l axis_broad_port7$ip -u 7 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 7 int $dts_file
                                set axis_node [create_node -n "endpoint" -l axis_broad_out7$ip -p $port_node -d $dts_file]
                                add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_broad_frmbuf_wr_node $connectip $connectip$ip "axis_broad_out7$ip" $ip $dts_file
                                }
                        }
                }
        }




}

proc gen_broad_frmbuf_wr_node {connectip outip drv_handle ip dts_file} {
	 set bus_node [detect_bus_name $ip]
        set vcap [create_node -n vcap$drv_handle -p $bus_node -d $dts_file]
        add_prop $vcap "compatible" "xlnx,video" string $dts_file
        add_prop $vcap "dmas" "$connectip 0" reference $dts_file
        add_prop $vcap "dma-names" "port0" string $dts_file
        set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d $dts_file]
        add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
        add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
        set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node -d $dts_file]
        add_prop "$vcap_port_node" "reg" 0 int $dts_file
        add_prop "$vcap_port_node" "direction" input string $dts_file
        set vcap_in_node [create_node -n "endpoint" -l $outip -p $vcap_port_node -d $dts_file]
        add_prop "$vcap_in_node" "remote-endpoint" $drv_handle reference $dts_file
}

proc get_connect_ip {ip intfpins dts_file} {
	dtg_verbose "get_con_ip:$ip pins:$intfpins"
        if {[llength $intfpins]== 0} {
                return
        }
        if {[llength $ip]== 0} {
                return
        }
        if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $ip]] "axis_broadcaster"]} {
                gen_broadcaster $ip $dts_file
                return
        }
        global connectip ""
        foreach intf $intfpins {
                set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
				if {[llength $connectip]} {
                       if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $connectip]] "axis_switch"]} {
                               gen_axis_switch $connectip
                               break
                       }
                }
                if {[llength $connectip]} {
                        if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $connectip]] "axis_broadcaster"]} {
                                gen_broadcaster $connectip
                                break
                        }
                        if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $connectip]] "axis_switch"]} {
                                gen_axis_switch $connectip
                                break
                        }
                }
               set len [llength $connectip]
               if {$len > 1} {
                       for {set i 0 } {$i < $len} {incr i} {
                               set ip [lindex $connectip $i]
                               if {[regexp -nocase "ila" $ip match]} {
                                       continue
                               }
                               set connectip "$ip"
                       }
               }
                if {[llength $connectip]} {
                        set ip_mem_handles [hsi::get_mem_ranges $connectip]
                        if {[llength $ip_mem_handles]} {
                                break
                        } else {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                                get_connect_ip $connectip $master_intf $dts_file
                        }
                }
        }
        return $connectip
}

proc gen_endpoint {drv_handle value} {
        global end_mappings
        dict append end_mappings $drv_handle $value
        set val [dict get $end_mappings $drv_handle]
}

proc gen_axis_switch_in_endpoint {drv_handle value} {
       global axis_switch_in_end_mappings
       dict append axis_switch_in_end_mappings $drv_handle $value
       set val [dict get $axis_switch_in_end_mappings $drv_handle]
}

proc gen_axis_switch_in_remo_endpoint {drv_handle value} {
       global axis_switch_in_remo_mappings
       dict append axis_switch_in_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_in_remo_mappings $drv_handle]
}

proc gen_axis_switch_port1_endpoint {drv_handle value} {
       global axis_switch_port1_end_mappings
       dict append axis_switch_port1_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port1_end_mappings $drv_handle]
}

proc gen_axis_switch_port2_endpoint {drv_handle value} {
       global axis_switch_port2_end_mappings
       dict append axis_switch_port2_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port2_end_mappings $drv_handle]
}

proc gen_axis_switch_port3_endpoint {drv_handle value} {
       global axis_switch_port3_end_mappings
       dict append axis_switch_port3_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port3_end_mappings $drv_handle]
}

proc gen_axis_switch_port4_endpoint {drv_handle value} {
       global axis_switch_port4_end_mappings
       dict append axis_switch_port4_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port4_end_mappings $drv_handle]
}

proc gen_axis_switch_port1_remote_endpoint {drv_handle value} {
       global axis_switch_port1_remo_mappings
       dict append axis_switch_port1_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port1_remo_mappings $drv_handle]
}

proc gen_axis_switch_port2_remote_endpoint {drv_handle value} {
       global axis_switch_port2_remo_mappings
       dict append axis_switch_port2_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port2_remo_mappings $drv_handle]
}

proc gen_axis_switch_port3_remote_endpoint {drv_handle value} {
       global axis_switch_port3_remo_mappings
       dict append axis_switch_port3_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port3_remo_mappings $drv_handle]
}

proc gen_axis_switch_port4_remote_endpoint {drv_handle value} {
       global axis_switch_port4_remo_mappings
       dict append axis_switch_port4_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port4_remo_mappings $drv_handle]
}

proc gen_broad_port1_endpoint {drv_handle value} {
        global port1_broad_end_mappings
        dict append port1_broad_end_mappings $drv_handle $value
        set val [dict get $port1_broad_end_mappings $drv_handle]
}

proc gen_broad_port2_endpoint {drv_handle value} {
        global port2_broad_end_mappings
        dict append port2_broad_end_mappings $drv_handle $value
        set val [dict get $port2_broad_end_mappings $drv_handle]
}

proc gen_broad_port3_endpoint {drv_handle value} {
        global port3_broad_end_mappings
        dict append port3_broad_end_mappings $drv_handle $value
        set val [dict get $port3_broad_end_mappings $drv_handle]
}

proc gen_broad_port4_endpoint {drv_handle value} {
        global port4_broad_end_mappings
        dict append port4_broad_end_mappings $drv_handle $value
        set val [dict get $port4_broad_end_mappings $drv_handle]
}

proc gen_broad_port5_endpoint {drv_handle value} {
        global port5_broad_end_mappings
        dict append port5_broad_end_mappings $drv_handle $value
        set val [dict get $port5_broad_end_mappings $drv_handle]
}

proc gen_broad_port6_endpoint {drv_handle value} {
        global port6_broad_end_mappings
        dict append port6_broad_end_mappings $drv_handle $value
        set val [dict get $port6_broad_end_mappings $drv_handle]
}

proc get_axis_switch_in_connect_ip {ip intfpins} {
       puts "get_axis_switch_in_connect_ip:$ip $intfpins"
       global connectip ""
       foreach intf $intfpins {
               set connectip [get_connected_stream_ip [hsi get_cells -hier $ip] $intf]
               puts "connectip:$connectip"
               if {[llength $connectip]} {
                       set ipname [hsi get_property IP_NAME $connectip]
                       puts "ipname:$ipname"
                       set ip_mem_handles [get_ip_mem_ranges $connectip]
                       if {[llength $ip_mem_handles]} {
                               break
                       } else {
                               set master_intf [::hsi::get_intf_pins -of_objects [hsi get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                               get_axis_switch_in_connect_ip $connectip $master_intf
                       }
               }
       }
       return $connectip
}

proc gen_remoteendpoint {drv_handle value} {
        global remo_mappings
        dict append remo_mappings $drv_handle $value
        set val [dict get $remo_mappings $drv_handle]
}

proc gen_axis_port1_remoteendpoint {drv_handle value} {
       global axis_port1_remo_mappings
       dict append axis_port1_remo_mappings $drv_handle $value
       set val [dict get $axis_port1_remo_mappings $drv_handle]
}

proc gen_axis_port2_remoteendpoint {drv_handle value} {
       global axis_port2_remo_mappings
       dict append axis_port2_remo_mappings $drv_handle $value
       set val [dict get $axis_port2_remo_mappings $drv_handle]
}

proc gen_axis_port3_remoteendpoint {drv_handle value} {
       global axis_port3_remo_mappings
       dict append axis_port3_remo_mappings $drv_handle $value
       set val [dict get $axis_port3_remo_mappings $drv_handle]
}

proc gen_axis_port4_remoteendpoint {drv_handle value} {
       global axis_port4_remo_mappings
       dict append axis_port4_remo_mappings $drv_handle $value
       set val [dict get $axis_port4_remo_mappings $drv_handle]
}

proc gen_broad_port1_remoteendpoint {drv_handle value} {
        global broad_port1_remo_mappings
        dict append broad_port1_remo_mappings $drv_handle $value
        set val [dict get $broad_port1_remo_mappings $drv_handle]
}

proc gen_broad_port2_remoteendpoint {drv_handle value} {
        global broad_port2_remo_mappings
        dict append broad_port2_remo_mappings $drv_handle $value
        set val [dict get $broad_port2_remo_mappings $drv_handle]
}

proc gen_broad_port3_remoteendpoint {drv_handle value} {
        global broad_port3_remo_mappings
        dict append broad_port3_remo_mappings $drv_handle $value
        set val [dict get $broad_port3_remo_mappings $drv_handle]
}

proc gen_broad_port4_remoteendpoint {drv_handle value} {
        global broad_port4_remo_mappings
        dict append broad_port4_remo_mappings $drv_handle $value
        set val [dict get $broad_port4_remo_mappings $drv_handle]
}

proc gen_broad_port5_remoteendpoint {drv_handle value} {
        global broad_port5_remo_mappings
        dict append broad_port5_remo_mappings $drv_handle $value
        set val [dict get $broad_port5_remo_mappings $drv_handle]
}

proc gen_broad_port6_remoteendpoint {drv_handle value} {
        global broad_port6_remo_mappings
        dict append broad_port6_remo_mappings $drv_handle $value
        set val [dict get $broad_port6_remo_mappings $drv_handle]
}

proc get_in_connect_ip {ip intfpins} {
	dtg_verbose "get_in_con_ip:$ip pins:$intfpins"
        if {[llength $intfpins]== 0} {
                return
        }
        if {[llength $ip]== 0} {
                return
        }
        global connectip ""
        foreach intf $intfpins {
                        set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
                        if {[llength $connectip]} {
                        set extip [hsi get_property IP_NAME $connectip]
                        if {[string match -nocase $extip "dfe_glitch_protect"] || [string match -nocase $extip "axi_interconnect"] || [string match -nocase $extip "axi_crossbar"]} {
                                return
                        }
                        }
                        set len [llength $connectip]
                        if {$len > 1} {
                                for {set i 0 } {$i < $len} {incr i} {
                                        set ip [lindex $connectip $i]
                                        if {[regexp -nocase "ila" $ip match]} {
                                                continue
                                        }
                                        set connectip "$ip"
                                }
                        }
                        if {[llength $connectip]} {
                                set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                if {[llength $ip_mem_handles]} {
                                                break
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "system_ila"]} {
                                                        continue
                                        }
                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                        get_in_connect_ip $connectip $master_intf
                                }
                        }
        }
        return $connectip
}

proc gen_frmbuf_rd_node {ip drv_handle sdi_port_node dts_file} {
        set frmbuf_rd_node [create_node -n "endpoint" -l encoder$drv_handle -p $sdi_port_node -d $dts_file]
        add_prop "$frmbuf_rd_node" "remote-endpoint" $ip$drv_handle reference $dts_file
	set bus_node [detect_bus_name $drv_handle]
        set pl_display [create_node -n "drm-pl-disp-drv$drv_handle" -l "v_pl_disp$drv_handle" -p $bus_node -d $dts_file]
        add_prop $pl_display "compatible" "xlnx,pl-disp" string $dts_file
        add_prop $pl_display "dmas" "$ip 0" reference $dts_file
        add_prop $pl_display "dma-names" "dma0" string $dts_file
        add_prop $pl_display "xlnx,vformat" "YUYV" string $dts_file
        set pl_display_port_node [create_node -n "port" -l pl_display_port$drv_handle -u 0 -p $pl_display -d $dts_file]
        add_prop "$pl_display_port_node" "reg" 0 int $dts_file
        set pl_disp_crtc_node [create_node -n "endpoint" -l $ip$drv_handle -p $pl_display_port_node -d $dts_file]
        add_prop "$pl_disp_crtc_node" "remote-endpoint" encoder$drv_handle reference $dts_file
}

proc gen_axis_switch {ip} {
	set compatible [get_comp_str $ip]
	dtg_verbose "+++++++++gen_axis_switch:$ip"
	set routing_mode [hsi get_property CONFIG.ROUTING_MODE [hsi get_cells -hier $ip]]
        if {$routing_mode == 1} {
                # Routing_mode is 1 means it is a memory mapped
                return
        }
	set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set inip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
	puts "connectinip:$inip"
	set intf1 [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set iip [get_connected_stream_ip [hsi::get_cells -hier $inip] $intf1]
	puts "iip:$iip"
	set inip [get_in_connect_ip $ip $intf]
	puts "inip:$inip"
	set bus_node [detect_bus_name $ip]
	set dts [set_drv_def_dts $ip]
	set switch_node [create_node -n "axis_switch_$ip" -l $ip -u 0 -p $bus_node -d $dts]
	set ports_node [create_node -n "ports" -l axis_switch_ports$ip -p $switch_node -d $dts]
	add_prop "$ports_node" "#address-cells" 1 int $dts
	add_prop "$ports_node" "#size-cells" 0 int $dts
	set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
	puts "intf:$master_intf"
	add_prop "$switch_node" "xlnx,routing-mode" $routing_mode int $dts
	set num_si [hsi get_property CONFIG.NUM_SI [hsi::get_cells -hier $ip]]

	add_prop "$switch_node" "xlnx,num-si-slots" $num_si int $dts
	set num_mi [hsi get_property CONFIG.NUM_MI [hsi::get_cells -hier $ip]]
	add_prop "$switch_node" "xlnx,num-mi-slots" $num_mi int $dts
	add_prop "$switch_node" "compatible" "$compatible" string $dts
	set count 0
	foreach intf $master_intf {
	       set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
	       set len [llength $connectip]
               if {$len > 1} {
                       for {set i 0 } {$i < $len} {incr i} {
                              set temp_ip [lindex $connectip $i]
                              if {[regexp -nocase "ila" $temp_ip match]} {
                                      continue
                              }
                              set connectip "$temp_ip"
                      }
               }
	       puts "connectip:$connectip intf:$intf"
	       if {[llength $connectip]} {
		       incr count
	       }
	       if {$count == 1} {
		       set port_node [create_node -n "port" -l axis_switch_port1$ip -u 1 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 1 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out1$ip -p $port_node -d $dts]
		       gen_axis_port1_endpoint $ip "axis_switch_out1$ip"
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port1_remoteendpoint $ip $connectip$ip
	       }
	       if {$count == 2} {
		       set port_node [create_node -n "port" -l axis_switch_port2$ip -u 2 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 2 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out2$ip -p $port_node -d $dts]
		       gen_axis_port2_endpoint $ip "axis_switch_out2$ip"
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port2_remoteendpoint $ip $connectip$ip
	       }
	       if {$count == 3} {
		       set port_node [create_node -n "port" -l axis_switch_port3$ip -u 3 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 3 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out3$ip -p $port_node -d $dts]
		       gen_axis_port3_endpoint $ip "axis_switch_out3$ip" 
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port3_remoteendpoint $ip $connectip$ip
	       }
	       if {$count == 4} {
		       set port_node [create_node -n "port" -l axis_switch_port4$ip -u 4 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 4 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out4$ip -p $port_node -d $dts]
		       gen_axis_port4_endpoint $ip "axis_switch_out4$ip"
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port4_remoteendpoint $ip $connectip$ip
	       }
	}
}

proc get_broad_in_ip {ip} {
	dtg_verbose "get_braod_in_ip:$ip"
        if {[llength $ip]== 0} {
                return
        }
        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
        set connectip ""
        foreach intf $master_intf {
                set connect [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
                set len [llength $connectip]
                if {$len > 1} {
                    for {set i 0 } {$i < $len} {incr i} {
                        set ip [lindex $connectip $i]
                        if {[regexp -nocase "ila" $ip match]} {
                            continue
                        }
                        set connectip "$ip"
                    }
                }
                foreach connectip $connect {
                        if {[llength $connectip]} {
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_broadcaster"]} {
                                        return $connectip
                                }
                                set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                if {![llength $ip_mem_handles]} {
                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                        foreach intf $master_intf {
                                                set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $intf]
                                                foreach connect $connectip {
                                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_broadcaster"]} {
                                                                return $connectip
                                                        }
                                                }
                                        }
                                        if {[llength $connectip]} {
                                                set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                                if {![llength $ip_mem_handles]} {
                                                        set master2_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                        foreach intf $master2_intf {
                                                                set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $intf]
                                                                if {[llength $connectip]} {
                                                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_broadcaster"]} {
                                                                                return $connectip
                                                                        }
                                                                }
                                                        }
                                                }
						if {[llength $connectip]} {
                                                        set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                                        if {![llength $ip_mem_handles]} {
                                                                set master3_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                                set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master3_intf]
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
        return $connectip
}
