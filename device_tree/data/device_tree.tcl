#
# (C) Copyright 2014-2015 Xilinx, Inc.
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
package require Tcl 8.5.14
package require yaml
package require struct
#namespace import cpu_cortexa72::*
# load yaml file into dict
proc get_yaml_dict { config_file } {
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

proc inc_os_prop {drv_handle os_conf_dev_var var_name conf_prop} {
    set ip_check "False"
    set os_ip [get_property ${os_conf_dev_var} [get_os]]
    if {![string match -nocase "" $os_ip]} {
        set os_ip [get_property ${os_conf_dev_var} [get_os]]
        set ip_check "True"
    }

    set count [hsi::utils::get_os_parameter_value $var_name]
    if {[llength $count] == 0} {
        if {[string match -nocase "True" $ip_check]} {
            set count 1
        } else {
            set count 0
        }
    }

    if {[string match -nocase "True" $ip_check]} {
        set ip [get_cells -hier $drv_handle]
        if {[string match -nocase $os_ip $ip]} {
            set ip_type [get_property IP_NAME $ip]
            set_property ${conf_prop} 0 $drv_handle
            return
        }
    }

    set_property $conf_prop $count $drv_handle
    incr count
    ::hsi::utils::set_os_parameter_value $var_name $count
}

proc gen_count_prop {drv_handle data_dict} {
    dict for {dev_type dev_conf_mapping} [dict get $data_dict] {
        set os_conf_dev_var [dict get $data_dict $dev_type "os_device"]
        set valid_ip_list [dict get $data_dict $dev_type "ip"]
        set drv_conf [dict get $data_dict $dev_type "drv_conf"]
        set os_count_name [dict get $data_dict $dev_type "os_count_name"]

        set slave [get_cells -hier $drv_handle]
        set iptype [get_property IP_NAME $slave]
        if {[lsearch $valid_ip_list $iptype] < 0} {
            continue
        }

        set irq_chk [dict get $data_dict $dev_type "irq_chk"]
        if {![string match -nocase "false" $irq_chk]} {
            set irq_id [::hsi::utils::get_interrupt_id $slave $irq_chk]
            if {[llength $irq_id] < 0} {
                dtg_warning "Fail to located interrupt pin - $irq_chk. The $drv_conf is not set for $dev_type"
                continue
            }
        }

        inc_os_prop $drv_handle $os_conf_dev_var $os_count_name $drv_conf
    }
}

proc gen_dev_conf {} {
    # data to populated certain configs for different devices
    set data_dict {
        uart {
            os_device "CONFIG.console_device"
            ip "axi_uartlite axi_uart16550 ps7_uart psu_uart psv_uart"
            os_count_name "serial_count"
            drv_conf "CONFIG.port-number"
            irq_chk "false"
        }
        mdm_uart {
            os_device "CONFIG.console_device"
            ip "mdm"
            os_count_name "serial_count"
            drv_conf "CONFIG.port-number"
            irq_chk "Interrupt"
        }
        syace {
            os_device "sysace_device"
            ip "axi_sysace"
            os_count_name "sysace_count"
            drv_conf "CONFIG.port-number"
            irq_chk "false"
        }
        traffic_gen {
            os_device "trafficgen_device"
            ip "axi_traffic_gen"
            os_count_name "trafficgen_count"
            drv_conf "CONFIG.xlnx,device-id"
            irq_chk "false"
        }
    }
    # update CONFIG.<para> for each driver when match driver is found
    foreach drv [get_drivers] {
        gen_count_prop $drv $data_dict
    }
}

# For calling from top level BSP
proc bsp_drc {os_handle} {
}

# If standalone purpose
proc device_tree_drc {os_handle} {
    bsp_drc $os_handle
    hsi::utils::add_new_child_node $os_handle "global_params"
}

proc extract_dts_name {override value} {
    set idx [lsearch -exact $override $value]
    set var [lreplace $override $idx $idx]
    return $var
}

proc gen_sata_laneinfo {} {

	foreach ip [hsi::get_cells] {
		set slane 0
		set freq {}
		set ip_type [get_property IP_TYPE [hsi::get_cells $ip]]
		if {$ip_type eq ""} {
			set ps $ip
		}
	}

	set param0 "/bits/ 8 <0x18 0x40 0x18 0x28>"
	set param1 "/bits/ 8 <0x06 0x14 0x08 0x0E>"
	set param2 "/bits/ 8 <0x13 0x08 0x4A 0x06>"
	set param3 "/bits/ 16 <0x96A4 0x3FFC>"

	set param4 "/bits/ 8 <0x1B 0x4D 0x18 0x28>"
	set param5 "/bits/ 8 <0x06 0x19 0x08 0x0E>"
	set param6 " /bits/ 8 <0x13 0x08 0x4A 0x06>"
	set param7 "/bits/ 16 <0x96A4 0x3FFC>"

	set param_list "ceva,p%d-cominit-params ceva,p%d-comwake-params ceva,p%d-burst-params ceva,p%d-retry-params"
	while {$slane < 2} {
		if {[get_property CONFIG.PSU__SATA__LANE$slane\__ENABLE [hsi::get_cells $ps]] == 1} {
			set gt_lane [get_property CONFIG.PSU__SATA__LANE$slane\__IO [hsi::get_cells $ps]]
			regexp [0-9] $gt_lane gt_lane
			lappend freq [get_property CONFIG.PSU__SATA__REF_CLK_FREQ [hsi::get_cells $ps]]
		} else {
			lappend freq 0
			}
		incr slane
	}

	foreach {i j} $freq {
		set i [expr {$i ? $i : $j}]
		set j [expr {$j ? $j : $i}]
	}

	lset freq 0 $i
	lset freq 1 $j
	set dts_file "pcw.dtsi"
	set sata_node [create_node -n "&psu_sata" -d $dts_file]
	set hsi_version [get_hsi_version]
	set ver [split $hsi_version "."]
	set version [lindex $ver 0]

	set slane 0
	while {$slane < 2} {
		set f [lindex $freq $slane]
		set count 0
		if {$f != 0} {
			while {$count < 4} {
				if {$version < 2018} {
					dtg_warning "quotes to be removed or use 2018.1 version for $sata_node params param0..param7"
				}
				set val_name [format [lindex $param_list $count] $slane]
				switch $count {
					"0" {
					add_prop $sata_node $val_name $param0 string $dts_file
					}
					"1" {
					add_prop $sata_node $val_name $param1 string $dts_file
					}
					"2" {
					add_prop $sata_node $val_name $param2 string $dts_file
					}
					"3" {
					add_prop $sata_node $val_name $param3 string $dts_file
					}
					"4" {
					add_prop $sata_node $val_name $param4 string $dts_file
					}
					"5" {
					add_prop $sata_node $val_name $param5 string $dts_file
					}
					"6" {
					add_prop $sata_node $val_name $param6 string $dts_file
					}
					"7" {
					add_prop $sata_node $val_name $param7 string $dts_file
					}
				}
			incr count
			}
		}
	incr slane
	}
}

proc gen_ext_axi_interface {}  {
	set family [get_hw_family]
	if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
		set ext_axi_intf [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]] -filter {INSTANCE ==""}]
		if {[regexp "ps._*" "$ext_axi_intf" match]} {
			return 0
		}
		set hsi_version [get_hsi_version]
		set ver [split $hsi_version "."]
		set version [lindex $ver 0]
		foreach drv_handle $ext_axi_intf {
			set base [string tolower [get_property BASE_VALUE $drv_handle]]
			set high [string tolower [get_property HIGH_VALUE $drv_handle]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
			if {$dt_overlay} {
				set bus_node "overlay2"
			} else {
				set bus_node "amba_pl"
			}
			set default_dts pl.dtsi
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
			regsub -all {^0x} $base {} base
			set ext_int_node [add_or_get_dt_node -n $drv_handle -l $drv_handle -u $base -d $default_dts -p $bus_node]
			hsi::utils::add_new_dts_param $ext_int_node "reg" "$reg" intlist
			if {$version >= 2018} {
				hsi::utils::add_new_dts_param "${ext_int_node}" "/* This is a external AXI interface, user may need to update the entries */" "" comment
			}
		}
	}
}

proc gen_include_headers {} {
	global env
	set path $env(REPO)
	set common_file "$path/device_tree/data/config.yaml"
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	}
	#set file "$path/${drvname}/data/config.yaml"
	set kernel_ver [get_user_config $common_file -kernel_ver]

	set family [get_hw_family]
	set include_dtsi [file normalize "$path/device_tree/data/kernel_dtsi/${kernel_ver}/include"]
	set include_list "include*"
	set dir_path [get_user_config $common_file -dir]
	if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
		set power_list "xlnx-zynqmp-power.h"
		set clock_list "xlnx-zynqmp-clk.h"
		set reset_list "xlnx-zynqmp-resets.h"
	} else {
		set power_list "xlnx-versal-power.h"
		set clock_list "xlnx-versal-clk.h"
		set reset_list "xlnx-zynqmp-resets.h"
	}
	set powerdir "$dir_path/include/dt-bindings/power"
	set clockdir "$dir_path/include/dt-bindings/clock"
	set resetdir "$dir_path/include/dt-bindings/reset"
	file mkdir $powerdir
	file mkdir $clockdir
	file mkdir $resetdir
	if {[file exists $include_dtsi]} {
		foreach file [glob [file normalize [file dirname ${include_dtsi}]/*/*/*/*]] {
			if {[string first $power_list $file]!= -1} {
				file copy -force $file $powerdir
			} elseif {[string first $clock_list $file] != -1} {
				file copy -force $file $clockdir
			} elseif {[string first $reset_list $file] != -1} {
				file copy -force $file $resetdir
			}
		}
	}
}

proc gen_board_info {} {
	global env
	set path $env(REPO)

	set common_file "$path/device_tree/data/config.yaml"
	set kernel_ver [get_user_config $common_file -kernel_ver]
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	}
	set dtsi_file [get_user_config $common_file -board_dts]
	set dir_path [get_user_config $common_file -dir]
    	if {[string match $dtsi_file "none"]} {
		return
    	}
	if {[file exists $dtsi_file]} {
		set dir $dir_path
		set pathtype [file pathtype $dtsi_file]
		if {[string match -nocase $pathtype "relative"]} {
			dtg_warning "checking file:$dtsi_file  pwd:$dir"
			#Get the absolute path from relative path
			set dtsi_file [file normalize $dtsi_file]
		}
		file copy -force $dtsi_file $dir_path
		update_system_dts_include [file tail $dtsi_file]
		return
	}
	set dts_name $dtsi_file
	if {[string match -nocase $dts_name "template"]} {
		return
	}
	if {[llength $dts_name] == 0} {
		return
	}
	set include_dtsi [file normalize "$path/device_tree/data/kernel_dtsi/${kernel_ver}/include"]
	set include_list "include*"
	set gpio_list "gpio.h"
	set intr_list "irq.h"
	set phy_list  "phy.h"
	set input_list "input.h"
	set pinctrl_list "pinctrl-zynqmp.h"
	set gpiodir "$dir_path/include/dt-bindings/gpio"
	set phydir "$dir_path/include/dt-bindings/phy"
	set intrdir "$dir_path/include/dt-bindings/interrupt-controller"
	set inputdir "$dir_path/include/dt-bindings/input"
	set pinctrldir "$dir_path/include/dt-bindings/pinctrl"
	file mkdir $phydir
	file mkdir $gpiodir
	file mkdir $intrdir
	file mkdir $inputdir
	file mkdir $pinctrldir
	if {[file exists $include_dtsi]} {
		foreach file [glob [file normalize [file dirname ${include_dtsi}]/*/*/*/*]] {
			if {[string first $gpio_list $file] != -1} {
				file copy -force $file $gpiodir
			} elseif {[string first $phy_list $file] != -1} {
				file copy -force $file $phydir
			} elseif {[string first $intr_list $file] != -1} {
				file copy -force $file $intrdir
			} elseif {[string first $input_list $file] != -1} {
				file copy -force $file $inputdir
			} elseif {[string first $pinctrl_list $file] != -1} {
				file copy -force $file $pinctrldir
			}
		}
	}
	set mainline_ker [get_user_config $common_file -mainline_kernel]
	if {[string match -nocase $mainline_ker "v4.17"]} {
		set mainline_dtsi [file normalize "$path/device_tree/data/kernel_dtsi/${mainline_ker}/board"]
		if {[file exists $mainline_dtsi]} {
			set mainline_board_file 0
			foreach file [glob [file normalize [file dirname ${mainline_dtsi}]/board/*]] {
				set dtsi_name "$dts_name.dtsi"
				# NOTE: ./ works only if we did not change our directory
				if {[regexp $dtsi_name $file match]} {
					file copy -force $file $dir_path
					update_system_dts_include [file tail $file]
					set mainline_board_file 1
				}
			}
			if {$mainline_board_file == 0} {
				error "Error:$dtsi_name board file is not present in DTG. Please add a vaild board."
			}
		}
	} else {
		set kernel_dtsi [file normalize "$path/device_tree/data/kernel_dtsi/${kernel_ver}/BOARD"]
		if {[file exists $kernel_dtsi]} {
			set valid_board_file 0
			foreach file [glob [file normalize [file dirname ${kernel_dtsi}]/BOARD/*]] {
				set dtsi_name "$dts_name.dtsi"
				# NOTE: ./ works only if we did not change our directory
				if {[regexp $dtsi_name $file match]} {
					file copy -force $file $dir_path
					update_system_dts_include [file tail $file]
					set valid_board_file 1
				}
			}
			if {$valid_board_file == 0} {
				error "Error:$dtsi_name board file is not present in DTG. Please add a valid board."
			}
			set default_dts "system-top.dts"
			set valid_axi_list "kc705-full kc705-lite ac701-full ac701-lite"
			set valid_no_axi_list "kcu105 zc702 zc706 zc1751-dc1 zc1751-dc2 zedboard"
			if {[lsearch -nocase $valid_axi_list $dts_name] >= 0 || [string match -nocase $dts_name "kcu705"]} {
				add_prop root "hard-reset-gpios" "reset_gpio 0 0 1" reference $default_dts
			}
		} else {
			puts "File not found\n\r"
		}
	}
}

proc gen_zynqmp_ccf_clk {} {
	set default_dts "pcw.dts"
	set ccf_node [create_node -n "&pss_ref_clk" -d $default_dts -p root]
	set periph_list [hsi::get_cells -hier]
	foreach periph $periph_list {
		set zynq_ultra_ps [get_property IP_NAME $periph]
		if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
			set avail_param [list_property i::get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PSU__PSS_REF_CLK__FREQMHZ"] >= 0} {
				set freq [get_property CONFIG.PSU__PSS_REF_CLK__FREQMHZ [hsi::get_cells -hier $periph]]
				if {[string match -nocase $freq "33.333"]} {
					return
				} else {
					dtg_warning "Frequency $freq used instead of 33.333"
					add_prop ${ccf_node} "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
				}
			}
		}
	}

}

proc generate {} {

	global env
	set path $env(REPO)
	if {[string match -nocase $path ""]} {
		error "please set repo path"
		return
	}
	set list_offiles {}
	lappend list_offiles "$path/device_tree/data/common_proc.tcl"
	lappend list_offiles "$path/device_tree/data/xillib_hw.tcl"
	lappend list_offiles "$path/device_tree/data/xillib_sw.tcl"
	lappend list_offiles "$path/device_tree/data/xillib_internal.tcl"
	foreach file $list_offiles {
		if {[file exists $file]} {
		        source -notrace $file
		}
	}

	set val_proclist "psv_cortexa72 psu_cortexa53 ps7_cortexa9"
	set peri_list [hsi::get_cells -hier]
	set proclist [hsi::get_cells -filter {IP_TYPE==PROCESSOR}]
	foreach procc $proclist {
		set index [string index $procc end]
		set ip_name [get_property IP_NAME [hsi::get_cells -hier $procc]]

		if {[lsearch $val_proclist $ip_name] >= 0 && $index == 0} {
			set drvname [get_drivers $procc]
			set proc_file "$path/${drvname}/data/${drvname}.tcl"
			source -notrace $proc_file
			namespace import ::${drvname}::\*
		        ::${drvname}::generate $procc
    			add_skeleton
			set non_val_list "versal_cips noc_nmu noc_nsu"
			set non_val_ip_types "MONITOR BUS PROCESSOR"
    			foreach drv_handle $peri_list {
				
				set ip_name [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
				set ip_type [get_property IP_TYPE [hsi::get_cells -hier $drv_handle]]
				if {[lsearch -nocase $non_val_list $ip_name] >= 0} {
					continue
				}
				if {[lsearch -nocase $non_val_ip_types $ip_type] >= 0} {
					continue
				}
 	       			gen_peripheral_nodes $drv_handle "create_node_only"
	        		gen_reg_property $drv_handle
	        		gen_compatible_property $drv_handle
	        		gen_drv_prop_from_ip $drv_handle
	       			gen_interrupt_property $drv_handle
	       			gen_clk_property $drv_handle

				set driver_name [get_drivers $drv_handle]
    			}
			set non_val_list "psv_cortexa72 psu_cortexa53 ps7_cortexa9 versal_cips noc_nmu noc_nsu"
			set non_val_ip_types "MONITOR BUS"
			foreach drv_handle $peri_list {
				set ip_name [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
				set ip_type [get_property IP_TYPE [hsi::get_cells -hier $drv_handle]]
				if {[lsearch -nocase $non_val_list $ip_name] >= 0} {
					continue
				}
				if {[lsearch -nocase $non_val_ip_types $ip_type] >= 0} {
					continue
				}
				set drvname [get_drivers $drv_handle]
				set drv_file "$path/${drvname}/data/${drvname}.tcl"
				source -notrace $drv_file
				namespace import ::${drvname}::\*
				::${drvname}::generate $drv_handle
			}
			namespace forget ::
		} else {
			continue
		}
	}
    	gen_board_info
    	gen_include_headers
	set proctype [get_hw_family]
	set common_file "$path/device_tree/data/config.yaml"
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	}
	set kernel_ver [get_user_config $common_file -kernel_ver]

    	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] || \
		[string match -nocase $proctype "versal"]} {
		if {[string match -nocase $kernel_ver "none"]} {
			gen_sata_laneinfo
			gen_zynqmp_ccf_clk
		}
    	}
    	gen_resrv_memory
    	update_alias $drv_handle
    	update_cpu_node $drv_handle
    	gen_cpu_cluster $drv_handle
	set family [get_hw_family]
	set dir [get_user_config $common_file -dir]
	if [catch { set retstr [file mkdir $dir] } errmsg] {
		error "cannot create directory"
	}
	set release [get_user_config $common_file -kernel_ver]
	global dtsi_fname
	if {[string match -nocase $family "versal"] || [string match -nocase $family "zynqmp"] || [string match -nocase $family "zynq"] || [string match -nocase $family "zynquplus"]} {
		set mainline_dtsi [file normalize "$path/device_tree/data/kernel_dtsi/${release}/${dtsi_fname}"]
		foreach file [glob [file normalize [file dirname ${mainline_dtsi}]/*]] {
			# NOTE: ./ works only if we did not change our directory
			file copy -force $file $dir
		}
		write_dt systemdt root "$dir/system-top.dts"
		write_dt pldt root "$dir/pl.dtsi"
		write_dt pcwdt root "$dir/pcw.dtsi"
		
	} else {
		write_dt systemdt root "$dir/system-top.dts"
		write_dt pldt root "$dir/pl.dtsi"
	}
}

proc generate_psvreg_property {base high} {
	set size [format 0x%x [expr {${high} - ${base} + 1}]]

	set family [get_hw_family]
	if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"] || [string match -nocase $family "versal"]} {
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

proc gen_resrv_memory {} {
	set proc_list [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
	set regprop ""
        set addr_64 "0"
    	set size_64 "0"
	set a53map ""
	set r5map ""
	set pmumap ""		
	set a53count "0"
	set r5count "0"
        set is_ddr_low_0 0
        set is_ddr_low_1 0
        set is_ddr_low_2 0
        set is_ddr_low_3 0
        set is_ddr_ch_1 0
        set is_ddr_ch_2 0
        set is_ddr_ch_3 0
	set periphs_list ""
	set family [get_hw_family]
	set first 0
 	append periphs_list [hsi::get_cells -hier -filter {IP_TYPE==MEMORY_CNTLR}]
	if {[string match -nocase $family "versal"]} {
		append periphs_list [hsi::get_cells -hier -filter {IP_NAME==axi_noc}]
		append periphs_list [hsi::get_cells -hier -filter {IP_NAME==noc_mc_ddr4}]
	}
	foreach periph $periphs_list {
	foreach proc_map $proc_list {
		set proctype [get_property IP_NAME $proc_map]
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psu_cortexr5"] || [string match -nocase $proctype "psu_pmu"]} {
			set ranges [hsi::get_mem_ranges -of_objects $proc_map]
			set ranges [hsi::get_mem_ranges -of_objects $proc_map -filter {MEM_TYPE==MEMORY}]
		} elseif {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psv_cortexr5"] || [string match -nocase $proctype "psv_pmc"]} {
			set interface_block_names [get_property ADDRESS_BLOCK [hsi::get_mem_ranges -of_objects $proc_map]]
		}

		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] } {
			if {[string match -nocase $a53count "1"] } {
				continue
			}
		}
		if {[string match -nocase $proctype "psu_cortexr5"] || [string match -nocase $proctype "psv_cortexr5"]} {
			if {[string match -nocase $r5count "1"] } {
				continue
			}
		}
		if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psv_cortexr5"] || [string match -nocase $proctype "psv_cortexa72"]} {
			set i 0
			foreach block_name $interface_block_names {
				if {[string match "C0_DDR_LOW0*" $block_name] || [string match "C1_DDR_LOW0*" $block_name]} {
					if {$is_ddr_low_0 == 0} {
						if {[catch {set base_value_0 [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
					}
					if {[catch {set high_value_0 [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
					set is_ddr_low_0 1
				} elseif {[string match "C0_DDR_LOW1*" $block_name] || [string match "C1_DDR_LOW1*" $block_name]} {
					if {$is_ddr_low_1 == 0} {
						
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
						if {[catch {set base_value_1 [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
		 }
					}
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
					if {[catch {set high_value_1 [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
					set is_ddr_low_1 1}
				} elseif {[string match "C0_DDR_LOW2*" $block_name] || [string match "C1_DDR_LOW2*" $block_name]} {
					if {$is_ddr_low_2 == 0} {
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
						if {[catch {set base_value_2 [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
		}
					}
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
					set high_value_2 [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
					set is_ddr_low_2 1 }
				} elseif {[string match "C0_DDR_LOW3*" $block_name] || [string match "C1_DDR_LOW3*" $block_name]} {
					if {$is_ddr_low_3 == "0"} {
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
						set base_value_3 [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]
		}
					}
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
					if {[catch {set high_value_3 [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
					set is_ddr_low_3 1 }
				} elseif {[string match "C0_DDR_CH1*" $block_name]} {
					if {$is_ddr_ch_1 == "0"} {
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
						if {[catch {set base_value_4 [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
		 }
					}
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
					if {[catch {set high_value_4 [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg ]} {}
					set is_ddr_ch_1 1 }
				} elseif {[string match "C0_DDR_CH2*" $block_name]} {
					if {$is_ddr_ch_2 == "0"} {
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
					if {[catch {set base_value_5 [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
		 }
				}
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
					if {[catch {set high_value_5 [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg]} {}
					set is_ddr_ch_2 1 }
				} elseif {[string match "C0_DDR_CH3*" $block_name]} {
					if {$is_ddr_ch_3 == "0"} {
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
						if {[catch {set base_value_6 [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg] } {}
		 }
					}
						set val [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]
						if {[string match -nocase $val ""]} {} else {
					if {[catch {set high_value_6 [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR} ] 0] $periph] $i]]} msg] } {}
					set is_ddr_ch_3 1 }
				}
				incr i
			}
			set updat ""
			if {$is_ddr_low_0 == 1} {
				set reg_val_0 [generate_psvreg_property $base_value_0 $high_value_0]
				set updat [lappend updat $reg_val_0]
			}
			if {$is_ddr_low_1 == 1} {
				set reg_val_1 [generate_psvreg_property $base_value_1 $high_value_1]
				set updat [lappend updat $reg_val_1]
			}
			if {$is_ddr_low_2 == 1} {
				set reg_val_2 [generate_psvreg_property $base_value_2 $high_value_2]
				set updat [lappend updat $reg_val_2]
			}
			if {$is_ddr_low_3 == 1} {
				set reg_val_3 [generate_psvreg_property $base_value_3 $high_value_3]
				set updat [lappend updat $reg_val_3]
			}
			if {$is_ddr_ch_1 == 1} {
				set reg_val_4 [generate_psvreg_property $base_value_4 $high_value_4]
				set updat [lappend updat $reg_val_4]
			}
			if {$is_ddr_ch_2 == 1} {
				set reg_val_5 [generate_psvreg_property $base_value_5 $high_value_5]
				set updat [lappend updat $reg_val_5]
			}
			if {$is_ddr_ch_3 == 1} {
				set reg_val_6 [generate_psvreg_property $base_value_6 $hiagh_value_6]
				set updat [lappend updat $reg_val_6]
			}
			set len [llength $updat]
			if {[string match -nocase $len "0"] } {
				continue
			}	
			switch $len {
				"1" {
					set reg_val [lindex $updat 0]
				}
				"2" {
					set reg_val [lindex $updat 0]
					append reg_val ">, <[lindex $updat 1]"
				}
				"3" {
					set reg_val [lindex $updat 0]
					append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]"
				}
				"4" {
					set reg_val [lindex $updat 0]
					append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]"
				}
				"5" {
					set reg_val [lindex $updat 0]
					append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]"
				}
				"6" {
					set reg_val [lindex $updat 0]
					append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]"
				}
				"7" {
					set reg_val [lindex $updat 0]
					append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]"
				}
			}
			if {[string match -nocase $proctype "psv_cortexa72"]} {
				set a53map $reg_val
			set a53count "1"
			} elseif {[string match -nocase $proctype "psv_cortexr5"]} {
				set r5map $reg_val
			set r5count "1"
			} else {
				set pmumap $reg_val
			}
			


		} elseif {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psu_cortexr5"] || [string match -nocase $proctype "psu_pmu"]} {
			foreach mem_map $ranges {
				if {![regexp "_ddr_*" $mem_map match]} {
		#			continue
				}

				set base [get_property BASE_VALUE  $mem_map]
				set high [get_property HIGH_VALUE  $mem_map]
				set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
				if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
				    set addr_64 "1"
				    set temp $base
				    set temp [string trimleft [string trimleft $temp 0] x]
				    set len [string length $temp]
				    set rem [expr {${len} - 8}]
				    set high_base "0x[string range $temp $rem $len]"
				    set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				    set low_base [format 0x%08x $low_base]
				}
				if {[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]} {
				    set size_64 "1"
				    set temp $mem_size
				    set temp [string trimleft [string trimleft $temp 0] x]
				    set len [string length $temp]
				    set rem [expr {${len} - 8}]
				    set high_size "0x[string range $temp $rem $len]"
				    set low_size "0x[string range $temp 0 [expr {${rem} - 1}]]"
				    set low_size [format 0x%08x $low_size]
				}
				if {[string match $regprop ""]} {
				    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
				        set regprop "$low_base $high_base $low_size $high_size"
				    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
				        set regprop "${low_base} ${high_base} 0x0 ${mem_size}"
				    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
				        set regprop "0x0 ${base} 0x0 ${mem_size}"
				    } else {
				        set regprop "0x0 ${base} 0x0 ${mem_size}"
				    }
				} else {
				    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
				        append regprop ">, " "<$low_base $high_base $low_size $high_size"
				    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
				        append regprop ">, " "<${low_base} ${high_base} 0x0 ${mem_size}"
				    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
				        append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
				    } else {
				        append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
				    }
				}
			 	if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
					set a53map $regprop
					set a53count "1"
				} elseif {[string match -nocase $proctype "psu_cortexr5"] || [string match -nocase $proctype "psv_cortexr5"]} {
					set r5map $regprop
					set r5count "1"
				} elseif {[string match -nocase $proctype "psu_pmu"] || [string match -nocase $proctype "psv_pmc"]} {
					set pmumap $regprop
				}

				set addr_64 "0"
		    		set size_64 "0"
			}
			set regprop ""
		}

	}
	set default_dts "system-top.dts"
	set mem_node [create_node -n "reserved-memory" -p root -d $default_dts]
	if {$first == 0} { 
		add_prop $mem_node "#address-cells" "0x2" hexint $default_dts
		add_prop $mem_node "#size-cells" "0x2" hexint $default_dts
		add_prop $mem_node "ranges" boolean $default_dts
		set first 1
	}
    	if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psu_cortexr5"] || [string match -nocase $proctype "psu_pmu"] } {
        	set child_node [create_node -l "memory_r5" -n "memory_r5" -d ${default_dts} -p $mem_node]
        	add_prop $child_node reg $r5map hexlist -d ${default_dts}
        	set child_node [create_node -l "memory_a53" -n "memory_a53" -d ${default_dts} -p $mem_node]
        	add_prop $child_node reg $a53map hexlist -d ${default_dts}
        	set child_node [create_node -l "memory_pmu" -n "memory_pmu" -d ${default_dts} -p $mem_node]
        	add_prop $child_node reg $pmumap hexlist -d ${default_dts}
    	}
    	if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psv_cortexr5"] || [string match -nocase $proctype "psv_pmc"] || [string match -nocase $proctype "psv_psm"]} {
    		if {![string_is_empty $a53map]} {
	        	set child_node [create_node -l "memory_a72" -n "memory_a72" -d ${default_dts} -p $mem_node]
			add_prop $child_node reg $a53map hexlist $default_dts
		}
    		if {![string_is_empty $r5map]} {
		        set child_node [create_node -l "memory_r5" -n "memory_r5" -d ${default_dts} -p $mem_node]
			add_prop $child_node reg $r5map hexlist $default_dts
		}
    		if {![string_is_empty $pmumap]} {
        		set child_node [create_node -l "memory_pmc" -n "memory_pmc" -d ${default_dts} -p $mem_node]
			add_prop $child_node reg $pmumap hexlist $default_dts
		}
    	}
}
}
proc post_generate {os_handle} {
    update_chosen $os_handle
    update_alias $os_handle
    update_cpu_node $os_handle
    gen_cpu_cluster $os_handle
    gen_dev_conf
    foreach drv_handle [get_drivers] {
        gen_peripheral_nodes $drv_handle
    }
    global zynq_soc_dt_tree
    delete_objs [get_dt_tree $zynq_soc_dt_tree]
    remove_empty_reference_node
    remove_main_memory_node
    gen_tcmbus $os_handle
}

proc add_skeleton {} {
	global env
	set path $env(REPO)

	set common_file "$path/device_tree/data/config.yaml"
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	}

	set default_dts "system-top.dts"
	set chosen_node [create_node -n "chosen" -p root -d $default_dts]
	set chosen_node [create_node -n "aliases" -p root -d $default_dts]
}

proc update_chosen {os_handle} {
	set default_dts "system-top.dts"
    	set chosen_node [create_node -n "chosen" -d ${default_dts} -p root]

	set bootargs ""
    	if {[llength $bootargs]} {
        	append bootargs " earlycon"
    	} else {
		set bootargs "earlycon"
    	}
	set family [get_hw_family]
    	if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"] || \
		[string match -nocase $family "versal"]} {
		if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
	           	append bootargs " clk_ignore_unused"
		}
    	}
    	add_prop $chosen_node "bootargs" $bootargs string $default_dts
     	set consoleip "none"
    	if {![string match -nocase $consoleip "none"]} {
         	set consoleip [ps_node_mapping $consoleip label]
         	set index [string first "," $console]
         	set baud [string range $console [expr $index + 1] [string length $console]]
		add_prop $chosen_node "stdout-path" "serial0:${baud}n8" string $default_dts
   	}
}

proc gen_cpu_cluster {os_handle} {

	set proctype [get_hw_family]
	set default_dts "system-top.dts"
    	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
        	set cpu_node [create_node -n "cpus_a53"  -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "range-size-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "range-address-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "range-map" "0xf0000000 &amba 0xf0000000 0x10000000\t0xfe000000 &tcm_bus 0x0 0x10000" mixed $default_dts

    	} elseif {[string match -nocase $proctype "versal"] } {
        	set cpu_node [create_node -n "cpus_a72"  -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "range-size-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "range-address-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "range-map" "0xf0000000 &amba 0xf0000000 0x10000000\t0xfe000000 &tcm_bus 0x0 0x10000" mixed $default_dts
    	}

	set cpu_node [create_node -n "cpus_r5" -d ${default_dts} -p root]
	add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
	add_prop $cpu_node "range-size-cells" "0x1" hexint $default_dts
	add_prop $cpu_node "range-address-cells" "0x1" hexint $default_dts
	add_prop $cpu_node "range-map" "0xf0000000 &amba 0xf0000000 0x10000000\t 0x0 &tcm_bus 0x0 0x10000\t0xfe000000 &tcm_bus 0x0 0x10000" mixed $default_dts

        set cpu_node [create_node -n "cpus_microblaze" -d ${default_dts} -p root]
        add_prop "${cpu_node}" "compatible" "cpus,cluster" string $default_dts
        add_prop "${cpu_node}" "range-size-cells" "0x1" hexint $default_dts
        add_prop "${cpu_node}" "range-address-cells" "0x1" hexint $default_dts
}

proc gen_tcmbus {os_handle} {
    set default_dts [get_property CONFIG.master_dts [get_os]]
    set system_root_node [add_or_get_dt_node -n "/" -d ${default_dts}]
    set tcmbus [add_or_get_dt_node -n "tcm_bus" -l "tcm_bus" -d ${default_dts} -p ${system_root_node}]
    hsi::utils::add_new_dts_param "${tcmbus}" "compatible" "simple-bus" string
    hsi::utils::add_new_dts_param "${tcmbus}" "#size-cells" "0x1" hexint
    hsi::utils::add_new_dts_param "${tcmbus}" "#address-cells" "0x1" hexint
    set tcm_node [add_or_get_dt_node -n "tcm" -u "e00000" -d ${default_dts} -p ${tcmbus}]
    hsi::utils::add_new_dts_param "${tcm_node}" "compatible" "mmiio-sram" string
    hsi::utils::add_new_dts_param "${tcm_node}" "reg" "0xe00000 0x10000" intlist
}

proc update_cpu_node {os_handle} {
	set default_dts "system-top.dts"
	set proctype [get_hw_family]
    	if {[string match -nocase $proctype "versal"] } {
        	set current_proc "psv_cortexa72_"
        	set total_cores 2
    	} elseif {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
        	set current_proc "psu_cortexa53_"
        	set total_cores 4
    	} elseif {[string match -nocase $proctype "zynq"] } {
        	set current_proc "ps7_cortexa9_"
        	set total_cores 2
    	} else {
        	set current_proc ""
    	}

    	if {[string compare -nocase $current_proc ""] == 0} {
        	return
    	}
    	if {[string match -nocase $proctype "versal"]} {
        	set procs [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
        	set pnames ""
		foreach proc_name $procs {
              		if {[regexp "psv_cortexa72*" $proc_name match]} {
	             		append pnames " " $proc_name
              		}
        	}
        	set a72cores [llength $pnames]
        	if {[string match -nocase $a72cores $total_cores]} {
	     	return
        	}
    	}
    	#getting boot arguments
    	set proc_instance 0
    	for {set i 0} {$i < $total_cores} {incr i} {
        	set proc_name [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}] $i]
        	if {[llength $proc_name] == 0} {
			set cpu_node [create_node -n "cpus" -d "system-top.dts" -p root]
			add_prop "cpus" "/delete-node/ cpu@$i" boolean "system-top.dts"
            		continue
        	}
		if {[string match -nocase [get_property IP_NAME [hsi::get_cells -hier $proc_name]] "microblaze"]} {
			return
		}
        	if {[string match -nocase $proc_name "$current_proc$i"] } {
            		continue
        	} else {
			set cpu_node [create_node -n "cpus" -d $default_dts -p root]
			add_prop "cpus" "/delete-node/ cpu@$i" boolean "system-top.dts"

        	}
    	}
}

proc update_alias {os_handle} {

	global env
	set path $env(REPO)
	set common_file "$path/device_tree/data/config.yaml"
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	}
	set mainline_ker [get_user_config $common_file -mainline_kernel]
    	if {[string match -nocase $mainline_ker "v4.17"]} {
         	return
    	}
	set default_dts "system-top.dts"
	set all_drivers [get_drivers 1]

	# Search for ps_qspi, if it is there then interchange this with first driver
	# because to have correct internal u-boot commands qspi has to be listed in aliases as the first for spi0
	set proctype [get_hw_family]
	if {[string match -nocase $proctype "zynq"]} {
		set pos [lsearch $all_drivers "ps7_qspi*"]
	} elseif {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		set pos [lsearch $all_drivers "psu_qspi*"]
	} elseif {[string match -nocase $proctype "versal"]} {
		set pos [lsearch $all_drivers "psv_pmc_qspi*"]
	} else {
		set pos [lsearch $all_drivers "psu_qspi*"]
	}
	if { $pos >= 0 } {
		set first_element [lindex $all_drivers 0]
		set qspi_element [lindex $all_drivers $pos]
		set all_drivers [lreplace $all_drivers 0 0 $qspi_element]
		set all_drivers [lreplace $all_drivers $pos $pos $first_element]
    	}
	# Update all_drivers list such that console device should be the first
	# uart device in the list.
	#set console_ip [get_property CONFIG.console_device [get_os]]
	#if {![string match -nocase $console_ip "none"]} {
		#set valid_console [lsearch $all_drivers $console_ip]
		#if { $valid_console < 0 } {
			#error "Trying to assign a console::$console_ip which doesn't exists !!!"
		#}
	#}
	#set dt_overlay [get_property CONFIG.DT_Overlay [get_os]]
	#set remove_pl [get_property CONFIG.remove_pl [get_os]]
	
	foreach drv_handle $all_drivers {
		set drvname [get_drivers $drv_handle]
		set common_file "$path/$drvname/data/config.yaml"
		set exists [file exists $common_file]
		if {$exists == 0} {
			continue
		}
		set alias_str [get_driver_config $drv_handle alias]
		if {0} {
		if {[string match -nocase $alias_str "serial"]} {
			if {![string match -nocase $console_ip "none"]} {
				if {[string match $console_ip $drv_handle] == 0} {
					# break the loop After swaping console device and uart device
					# found in list
					set consoleip_pos [lsearch $all_drivers $console_ip]
					set first_occur_pos [lsearch $all_drivers $drv_handle]
					set console_element [lindex $all_drivers $consoleip_pos]
					set uart_element [lindex $all_drivers $first_occur_pos]
					set all_drivers [lreplace $all_drivers $consoleip_pos $consoleip_pos $uart_element]
					set all_drivers [lreplace $all_drivers $first_occur_pos $first_occur_pos $console_element]
					break
				} else {
					# if the first uart device in the list is console device
					break
				}
			}
		 }
		}
	}

	foreach drv_handle $all_drivers {
            	set ip_name  [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
            	if {[string match -nocase $ip_name "psv_pmc_qspi"]} {
                  	set ip_type [get_property IP_TYPE [hsi::get_cells -hier $drv_handle]]
                  	if {[string match -nocase $ip_type "PERIPHERAL"]} {
                        	continue
                  	}
            	}
		set drvname [get_drivers $drv_handle]

		set common_file "$path/$drvname/data/config.yaml"
		set exists [file exists $common_file]
		if {$exists == 0} {
			continue
		}
		set tmp [get_driver_config $drv_handle alias]

        	if {[string_is_empty $tmp]} {
            	continue
        	} else {
			set alias_str $tmp
			set alias_count [get_count $alias_str]
            		set conf_name ${alias_str}${alias_count}
			set value [get_node $drv_handle]
			set value [split $value ": "]
			set value [lindex $value 0]
		            set ip_list "i2c spi serial"
            	# TODO: need to check if the label already exists in the current system
		set alias_node [create_node -n "aliases" -p root -d "system-top.dts"]
		add_prop $alias_node $conf_name $value aliasref $default_dts
        }
    }
}
# remove main memory node
proc remove_main_memory_node {} {
    set main_memory [get_property CONFIG.main_memory [get_os]]
    if {[string_is_empty $main_memory]} {
        return 0
    }

    # in theory it will not del the ps ddr as it snot been generated
    set mc_obj [get_node_object $main_memory "" ""]
    if {[string_is_empty $mc_obj]} {
        return 0
    }
	set all_drivers [get_drivers]
	foreach drv_handle $all_drivers {
		set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
		if {[string match -nocase $ip "axi_bram_ctrl"]} {
			return
		}
		if {[string match -nocase $ip "ddr4"]} {
			set slave [get_cells -hier ${drv_handle}]
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
			if {[llength $ip_mem_handles] > 1} {
				return
			}
		}
	}
    set cur_dts [current_dt_tree]
    foreach dts_file [get_dt_tree] {
        set dts_nodes [get_all_tree_nodes $dts_file]
        foreach node ${dts_nodes} {
            if {[regexp $mc_obj $node match]} {
                current_dt_tree $dts_file
                delete_objs $mc_obj
                current_dt_tree $cur_dts
            }
        }
    }
}
