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
package require Tcl 8.5.14
package require yaml
package require struct
#namespace export *
#namespace export get_dt_param
# load yaml file into dict
proc get_yaml_dict1 { config_file } {
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

proc set_dt_param_1 args {
       global env
       set param [lindex $args 0]
       set val [lindex $args 1]
       switch $param {
               "repo" {
                       set env(REPO) $val
               } "board" {
                       set env(board) $val
               } "dt_overlay" {
                       set env(dt_overlay) $val
               } "mainline_kernel" {
                       set env(kernel) $val
               } "kernel_ver" {
                       set env(kernel_ver) $val
               } "dir" {
                       set env(dir) $val
               } default {
                       error "unknown option"
               }
       }

}

proc get_dt_param_1 args {
       global env
       set param [lindex $args 0]
       set val ""
       switch $param {
               -repo {
                       if {[catch {set val $env(REPO)} msg ]} {}
               } -board_dts {
                       if {[catch {set val $env(board)} msg ]} {}
               } -dt_overlay {
                       if {[catch {set val $env(dt_overlay)} msg ]} {}
               } -mainline_kernel {
                       if {[catch {set val $env(kernel)} msg ]} {}
               } -kernel_ver {
                       if {[catch {set val $env(kernel_ver)} msg ]} {}
               } -dir {
                       if {[catch {set val $env(dir)} msg ]} {}
               } default {
                       error "unknown option"
               }
       }

       return $val
}

proc inc_os_prop {drv_handle os_conf_dev_var var_name conf_prop} {
    set ip_check "False"
    set os_ip [get_property ${os_conf_dev_var} [get_os]]
    if {![string match -nocase "" $os_ip]} {
        set os_ip [get_property ${os_conf_dev_var} [get_os]]
        set ip_check "True"
    }

    set count [get_os_parameter_value $var_name]
    if {[llength $count] == 0} {
        if {[string match -nocase "True" $ip_check]} {
            set count 1
        } else {
            set count 0
        }
    }

    if {[string match -nocase "True" $ip_check]} {
        set ip [hsi::get_cells -hier $drv_handle]
        if {[string match -nocase $os_ip $ip]} {
            set ip_type [get_property IP_NAME $ip]
            set_property ${conf_prop} 0 $drv_handle
            return
        }
    }

    set_property $conf_prop $count $drv_handle
    incr count
    set_os_parameter_value $var_name $count
}

proc gen_count_prop {drv_handle data_dict} {
    dict for {dev_type dev_conf_mapping} [dict get $data_dict] {
        set os_conf_dev_var [dict get $data_dict $dev_type "os_device"]
        set valid_ip_list [dict get $data_dict $dev_type "ip"]
        set drv_conf [dict get $data_dict $dev_type "drv_conf"]
        set os_count_name [dict get $data_dict $dev_type "os_count_name"]

        set slave [hsi::get_cells -hier $drv_handle]
        set iptype [get_property IP_NAME $slave]
        if {[lsearch $valid_ip_list $iptype] < 0} {
            continue
        }

        set irq_chk [dict get $data_dict $dev_type "irq_chk"]
        if {![string match -nocase "false" $irq_chk]} {
            set irq_id [get_interrupt_id $slave $irq_chk]
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
    add_new_child_node $os_handle "global_params"
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
		set ip_type [get_property IP_TYPE [hsi::get_cells -hier $ip]]
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
		if {[get_property CONFIG.PSU__SATA__LANE$slane\__ENABLE [hsi::get_cells -hier $ps]] == 1} {
			set gt_lane [get_property CONFIG.PSU__SATA__LANE$slane\__IO [hsi::get_cells -hier $ps]]
			regexp [0-9] $gt_lane gt_lane
			lappend freq [get_property CONFIG.PSU__SATA__REF_CLK_FREQ [hsi::get_cells -hier $ps]]
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
		set ext_axi_intf [get_mem_ranges -of_objects [hsi::get_cells -hier [get_sw_processor]] -filter {INSTANCE ==""}]
		set hsi_version [get_hsi_version]
		set ver [split $hsi_version "."]
		set version [lindex $ver 0]
		set intf_count 0
		foreach drv_handle $ext_axi_intf {
			set base [string tolower [get_property BASE_VALUE $drv_handle]]
			set high [string tolower [get_property HIGH_VALUE $drv_handle]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set def_dts "pcw.dtsi"
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
			set ext_int_node [create_node -n $drv_handle -l $drv_handle$intf_count -u $base -d $default_dts -p root]
			add_new_dts_param $ext_int_node "reg" "$reg" intlist
			incr intf_count
			if {$version >= 2018} {
				add_new_dts_param "${ext_int_node}" "/* This is a external AXI interface, user may need to update the entries */" "" comment
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
		set dpdma_list "xlnx-zynqmp-dpdma.h"
	} else {
		set power_list "xlnx-versal-power.h"
		set clock_list "xlnx-versal-clk.h"
		set reset_list "xlnx-zynqmp-resets.h"
		set dpdma_list "xlnx-zynqmp-dpdma.h"
	}
	set powerdir "$dir_path/include/dt-bindings/power"
	set clockdir "$dir_path/include/dt-bindings/clock"
	set resetdir "$dir_path/include/dt-bindings/reset"
	set dpdmadir "$dir_path/include/dt-bindings/dma"
	file mkdir $powerdir
	file mkdir $clockdir
	file mkdir $resetdir
	file mkdir $dpdmadir
	if {[file exists $include_dtsi]} {
		foreach file [glob [file normalize [file dirname ${include_dtsi}]/*/*/*/*]] {
			if {[string first $power_list $file]!= -1} {
				file copy -force $file $powerdir
			} elseif {[string first $clock_list $file] != -1} {
				file copy -force $file $clockdir
			} elseif {[string first $reset_list $file] != -1} {
				file copy -force $file $resetdir
			} elseif {[string first $dpdma_list $file] != -1} {
				file copy -force $file $dpdmadir
			}
		}
	}
}

proc gen_afi_node {} {
	set afi_ip [hsi::get_cells -hier -filter {IP_NAME==psu_afi}]
	set pllist [hsi::get_cells -filter {IS_PL==1}]
	set dts "pl.dtsi"
	set family [get_hw_family]
	if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
	if {[llength $afi_ip] > 0 && [llength $pllist] > 0} {
		set node [create_node -l "afi0" -n "afi0" -p "amba_pl: amba_pl" -d "pl.dtsi"]
		add_prop $node "compatible" "xlnx,afi-fpga" string $dts 1
		add_prop $node "status" "okay" string $dts 1
		set config_afi " "
		
		set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
		set avail_param [list_property [hsi::get_cells -hier $zynq_periph]]
		if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP0_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_SAXIGP0_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival [get_afi_val $val]
			append config_afi "0 $afival>, <1 $afival>,"
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP1_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_SAXIGP1_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival [get_afi_val $val]
			append config_afi " <2 $afival>, <3 $afival>,"
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP2_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_SAXIGP2_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival [get_afi_val $val]
			append config_afi " <4 $afival>, <5 $afival>,"
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP3_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_SAXIGP3_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival [get_afi_val $val]
			append config_afi " <6 $afival>, <7 $afival>,"
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP4_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_SAXIGP4_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival [get_afi_val $val]
			append config_afi " <8 $afival>, <9 $afival>,"
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP5_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_SAXIGP5_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival [get_afi_val $val]
			append config_afi " <10 $afival>, <11 $afival>,"
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_SAXIGP6_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_SAXIGP6_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival [get_afi_val $val]
			append config_afi " <12 $afival>, <13 $afival>,"
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_MAXIGP0_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_MAXIGP0_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival0 [get_max_afi_val $val]
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_MAXIGP1_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_MAXIGP1_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			set afival1 [get_max_afi_val $val]
		}
		set afi0 [expr $afival0 <<8]
		set afi1 [expr $afival1 << 10]
		set afival [expr {$afi0} | {$afi1}]
		set afi_hex [format %x $afival]
		append config_afi " <14 0x$afi_hex>,"
		if {[lsearch -nocase $avail_param "CONFIG.C_MAXIGP2_DATA_WIDTH"] >= 0} {
			set val [get_property CONFIG.C_MAXIGP2_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
			switch $val {
				"128" {
					set afival 0x200
				} "64" {
					set afival 0x100
				} "32" {
					set afival 0x000
				} default {
					dtg_warning "invalid value:$val"
				}
			}
			append config_afi " <15 $afival"
		}
		add_prop "${node}" "config-afi" "$config_afi" special $dts

		if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK0_BUF"] >= 0} {
			set val [get_property CONFIG.C_PL_CLK0_BUF [hsi::get_cells -hier $zynq_periph]]
			if {[string match -nocase $val "true"]} {
				set clocking_node [create_node -n "clocking0" -l "clocking0" -p "amba_pl: amba_pl" -d $dts]
				add_prop "${clocking_node}" "compatible" "xlnx,fclk" string $dts 1
				add_prop "${clocking_node}" "clocks" "zynqmp_clk 71" reference $dts 1
				add_prop "${clocking_node}" "clock-output-names" "fabric_clk" string $dts 1
				add_prop "${clocking_node}" "#clock-cells" 0 int $dts 1
				add_prop "${clocking_node}" "assigned-clocks" "zynqmp_clk 71" reference $dts 1
				set freq [get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ [hsi::get_cells -hier $zynq_periph]]
				add_prop "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int $dts 1
			}
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK1_BUF"] >= 0} {
			set val [get_property CONFIG.C_PL_CLK1_BUF [hsi::get_cells -hier $zynq_periph]]
			if {[string match -nocase $val "true"]} {
				set clocking_node [create_node -n "clocking1" -l "clocking1" -p "amba_pl: amba_pl" -d $dts]
				add_prop "${clocking_node}" "compatible" "xlnx,fclk" string $dts 1
				add_prop "${clocking_node}" "clocks" "zynqmp_clk 72" reference $dts 1
				add_prop "${clocking_node}" "clock-output-names" "fabric_clk" string $dts 1
				add_prop "${clocking_node}" "#clock-cells" 0 int $dts 1
				add_prop "${clocking_node}" "assigned-clocks" "zynqmp_clk 72" reference $dts 1
				set freq [get_property CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ [hsi::get_cells -hier $zynq_periph]]
				add_prop "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int $dts 1
			}
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK2_BUF"] >= 0} {
			set val [get_property CONFIG.C_PL_CLK2_BUF [hsi::get_cells -hier $zynq_periph]]
			if {[string match -nocase $val "true"]} {
				set clocking_node [create_node -n "clocking2" -l "clocking2" -p "amba_pl: amba_pl" -d $dts]
				add_prop "${clocking_node}" "compatible" "xlnx,fclk" string $dts 1
				add_prop "${clocking_node}" "clocks" "zynqmp_clk 73" reference $dts 1
				add_prop "${clocking_node}" "clock-output-names" "fabric_clk" string $dts 1
				add_prop "${clocking_node}" "#clock-cells" 0 int $dts 1
				add_prop "${clocking_node}" "assigned-clocks" "zynqmp_clk 73" reference $dts 1
				set freq [get_property CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ [hsi::get_cells -hier $zynq_periph]]
				add_prop "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int $dts 1
			}
		}
		if {[lsearch -nocase $avail_param "CONFIG.C_PL_CLK3_BUF"] >= 0} {
			set val [get_property CONFIG.C_PL_CLK3_BUF [hsi::get_cells -hier $zynq_periph]]
			if {[string match -nocase $val "true"]} {
				set clocking_node [create_node -n "clocking3" -l "clocking3" -p "amba_pl: amba_pl" -d $dts]
				add_prop "${clocking_node}" "compatible" "xlnx,fclk" string $dts 1
				add_prop "${clocking_node}" "clocks" "zynqmp_clk 74" reference $dts 1
				add_prop "${clocking_node}" "clock-output-names" "fabric_clk" string $dts 1
				add_prop "${clocking_node}" "#clock-cells" 0 int $dts 1
				add_prop "${clocking_node}" "assigned-clocks" "zynqmp_clk 74" reference $dts 1
				set freq [get_property CONFIG.PSU__CRL_APB__PL3_REF_CTRL__ACT_FREQMHZ [hsi::get_cells -hier $zynq_periph]]
				add_prop "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int $dts 1
			}
		}

		if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"] || [string match -nocase $family "zynquplusRFSOC"]} {
			set hw_name [::hsi::get_hw_files -filter "TYPE == bit"]
			add_prop "amba_pl: amba_pl" "firmware-name" "$hw_name.bin" string  $dts 1
		} 
	}
	} 
	if {[string match -nocase $family "versal"] && [llength $pllist] > 0} {
		set hw_name [::hsi::get_hw_files -filter "TYPE == pdi"]
		add_prop "amba_pl: amba_pl" "firmware-name" "$hw_name" string  $dts 1
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
	if {[string match -nocase $dts_name "template"]} {
		return
	}
	if {[llength $dts_name] == 0} {
		return
	}
	set mainline_ker [get_user_config $common_file -mainline_kernel]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
	if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
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
       set ccf_node [create_node -n "&video_clk" -d $default_dts -p root]
       set periph_list [hsi::get_cells -hier]
       foreach periph $periph_list {
               set zynq_ultra_ps [get_property IP_NAME $periph]
               if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
                       set avail_param [list_property [hsi::get_cells -hier $periph]]
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ"] >= 0} {
                               set freq [get_property CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $freq "27"]} {
                                       return
                               } else {
                                       dtg_warning "Frequency $freq used instead of 27.00"
                                       add_prop "${ccf_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                               }
                       }
               }
       }

}

proc gen_versal_clk {} {
       set default_dts "pcw.dtsi"
       set ref_node [create_node -n "&ref_clk" -d $default_dts -p root]
       set pl_alt_ref_node [create_node -n "&pl_alt_ref_clk" -d $default_dts -p root]
       set periph_list [hsi::get_cells -hier]
       foreach periph $periph_list {
               set versal_ps [get_property IP_NAME $periph]
               if {[string match -nocase $versal_ps "versal_cips"] } {
                       set avail_param [list_property [hsi::get_cells -hier $periph]]
                       if {[lsearch -nocase $avail_param "CONFIG.PMC_REF_CLK_FREQMHZ"] >= 0} {
                               set freq [get_property CONFIG.PMC_REF_CLK_FREQMHZ [hsi::get_cells -hier $periph]]
                               if {![string match -nocase $freq "33.333"]} {
                                       dtg_warning "Frequency $freq used instead of 33.333"
                                       add_prop "${ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ"] >= 0} {
                               set freq [get_property CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ [hsi::get_cells -hier $periph]]
                               if {![string match -nocase $freq "33.333"]} {
                                       dtg_warning "Frequency $freq used instead of 33.333"
                                       add_prop "${pl_alt_ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                               }
                       }
               }
       }

}

proc gen_zynqmp_opp_freq {} {
       set default_dts "pcw.dtsi"
       set cpu_opp_table [create_node -n "&cpu_opp_table" -d $default_dts -p root]
       set periph_list [hsi::get_cells -hier]
       foreach periph $periph_list {
               set zynq_ultra_ps [get_property IP_NAME $periph]
               if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
                       set avail_param [list_property [hsi::get_cells -hier $periph]]
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ"] >= 0} {
                               set freq [get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $freq "1200"]} {
                                       # This is the default value set, so no need to calcualte
                                       return
                               }
                               if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ"] >= 0} {
                                       set act_freq [get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ [hsi::get_cells -hier $periph]]
                                       set act_freq [expr $act_freq * 1000000]
                               }
                               if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0"] >= 0} {
                                       set div [get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0 [hsi::get_cells -hier $periph]]
                               }
                               set opp_freq  [expr $act_freq * $div]
                               set opp00_result [expr int ([expr $opp_freq / 1])]
                               set opp01_result [expr int ([expr $opp_freq / 2])]
                               set opp02_result [expr int ([expr $opp_freq / 3])]
                               set opp03_result [expr int ([expr $opp_freq / 4])]
                               set opp00 "/bits/ 64 <$opp00_result>"
                               set opp01 "/bits/ 64 <$opp01_result>"
                               set opp02 "/bits/ 64 <$opp02_result>"
                               set opp03 "/bits/ 64 <$opp03_result>"
                               set opp00_table [create_node -n "opp00" -d $default_dts -p $cpu_opp_table]
                               add_prop "$opp00_table" "opp-hz" $opp00 stringlist $default_dts
                               set opp01_table [create_node -n "opp01" -d $default_dts -p $cpu_opp_table]
                               add_prop "$opp01_table" "opp-hz" $opp01 stringlist $default_dts
                               set opp02_table [create_node -n "opp02" -d $default_dts -p $cpu_opp_table]
                               add_prop "$opp02_table" "opp-hz" $opp02 stringlist $default_dts
                               set opp03_table [create_node -n "opp03" -d $default_dts -p $cpu_opp_table]
                               add_prop "$opp03_table" "opp-hz" $opp03 stringlist $default_dts
                       }
               }
       }
}

proc gen_zocl_node {} {
	global env
	set path $env(REPO)
	set common_file "$path/device_tree/data/config.yaml"
	if {[file exists $common_file]} {
        	#error "file not found: $common_file"
    	}
	set zocl [get_user_config $common_file -dt_zocl]
       #set ext_platform [get_property platform.extensible [get_os]]
       #puts "ext_platform:$ext_platform"
       #set proctype [get_property IP_NAME [hsi::get_cells -hier [get_sw_processor]]
       set proctype [get_hw_family]
       if {!$zocl} {
               return
       }
       set dt_overlay [get_user_config $common_file -dt_overlay]
       if {$dt_overlay} {
               set bus_node "overlay2"
       } else {
               set bus_node "amba_pl"
       }
       set default_dts "pl.dtsi"
       set zocl_node [create_node -n "zyxclmm_drm" -d ${default_dts} -p $bus_node]
	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] || [string match -nocase $proctype "zynq"]} {
               add_prop $zocl_node "compatible" "xlnx,zocl" string $default_dts
       } else {
               add_prop $zocl_node "compatible" "xlnx,zocl-versal" string $default_dts
       }
       set intr_ctrl [hsi::get_cells -hier -filter {IP_NAME == axi_intc}]
	if {[llength $intr_ctrl]} {
       set intr_ctrl_len [llength $intr_ctrl]
       set int0 [lindex $intr_ctrl 0]
       foreach ip [get_drivers] {
               if {[string compare -nocase $ip $int0] == 0} {
                       set target_handle $ip
               }
       }
       set intr_ctrl [pldt get $target_handle interrupt-parent]
       set intr_ctrl [string trimright $intr_ctrl ">"]
       set intr_ctrl [string trimleft $intr_ctrl "<"]
       set intr_ctrl [string trimleft $intr_ctrl "&"]

       set int1 [lindex $intr_ctrl 1]
       foreach ip [get_drivers] {
               if {[string compare -nocase $ip $int1] == 0} {
                       set target_handle $ip
               }
       }
       set intr [pldt get $target_handle interrupt-parent]
       set intr [string trimright $intr ">"]
       set intr [string trimleft $intr "<"]
       set intr [string trimleft $intr "&"]
       switch $intr_ctrl_len {
               "1"   {
                       set ref [lindex $intr_ctrl 0]
                       append ref " 0 4>, <&[lindex $intr_ctrl 0] 1 4>, <&[lindex $intr_ctrl 0] 2 4>, <&[lindex $intr_ctrl 0] 3 4>, <&[lindex $intr_ctrl 0] 4 4>, <&[lindex $intr_ctrl 0] 5 4>, <&[lindex $intr_ctrl 0] 6 4>, <&[lindex $intr_ctrl 0] 7 4>, <&[lindex $intr_ctrl 0] 8 4>, <&[lindex $intr_ctrl 0] 9 4>,
<&[lindex $intr_ctrl 0] 10 4>, <&[lindex $intr_ctrl 0] 11 4>, <&[lindex $intr_ctrl 0] 12 4>, <&[lindex $intr_ctrl 0] 13 4>, <&[lindex $intr_ctrl 0] 14 4>,
<&[lindex $intr_ctrl 0] 15 4>, <&[lindex $intr_ctrl 0] 16 4>, <&[lindex $intr_ctrl 0] 17 4>, <&[lindex $intr_ctrl 0] 18 4>, <&[lindex $intr_ctrl 0] 19 4>,
<&[lindex $intr_ctrl 0] 20 4>, <&[lindex $intr_ctrl 0] 21 4>, <&[lindex $intr_ctrl 0] 22 4>, <&[lindex $intr_ctrl 0] 23 4>, <&[lindex $intr_ctrl 0] 24 4>,
<&[lindex $intr_ctrl 0] 25 4>, <&[lindex $intr_ctrl 0] 26 4>, <&[lindex $intr_ctrl 0] 27 4>, <&[lindex $intr_ctrl 0] 28 4>, <&[lindex $intr_ctrl 0] 29 4>,
<&[lindex $intr_ctrl 0] 30 4>, <&[lindex $intr_ctrl 0] 31 4 "
                       add_prop $zocl_node "interrupts-extended" $ref reference $default_dts
               }
               "2"   {
                       set ref [lindex $intr_ctrl 0]
                       append ref " 0 4>, <&[lindex $intr_ctrl 0] 1 4>, <&[lindex $intr_ctrl 0] 2 4>, <&[lindex $intr_ctrl 0] 3 4>, <&[lindex $intr_ctrl 0] 4 4>, <&[lindex $intr_ctrl 0] 5 4>, <&[lindex $intr_ctrl 0] 6 4>, <&[lindex $intr_ctrl 0] 7 4>, <&[lindex $intr_ctrl 0] 8 4>, <&[lindex $intr_ctrl 0] 9 4>, <&[lindex $intr_ctrl 0] 10 4>, <&[lindex $intr_ctrl 0] 11 4>, <&[lindex $intr_ctrl 0] 12 4>, <&[lindex $intr_ctrl 0] 13 4>, <&[lindex $intr_ctrl 0] 14 4>, <&[lindex $intr_ctrl 0] 15 4>, <&[lindex $intr_ctrl 0] 16 4>, <&[lindex $intr_ctrl 0] 17 4>, <&[lindex $intr_ctrl 0] 18 4>, <&[lindex $intr_ctrl 0] 19 4>, <&[lindex $intr_ctrl 0] 20 4>, <&[lindex $intr_ctrl 0] 21 4>, <&[lindex $intr_ctrl 0] 22 4>, <&[lindex $intr_ctrl 0] 23 4>, <&[lindex $intr_ctrl 0] 24 4>, <&[lindex $intr_ctrl 0] 25 4>, <&[lindex $intr_ctrl 0] 26 4>, <&[lindex $intr_ctrl 0] 27 4>, <&[lindex $intr_ctrl 0] 28 4>, <&[lindex $intr_ctrl 0] 29 4>, <&[lindex $intr_ctrl 0] 30 4>, <&[lindex $intr_ctrl 0] 31 4>, <&[lindex $intr_ctrl 1] 0 4>, <&[lindex $intr_ctrl 1] 1 4>, <&[lindex $intr_ctrl 1] 2 4>,  <&[lindex $intr_ctrl 1] 3 4>,  <&[lindex $intr_ctrl 1] 4 4>,  <&[lindex $intr_ctrl 1] 5 4>, <&[lindex $intr_ctrl 1] 6 4>, <&[lindex $intr_ctrl 1] 7 4>,  <&[lindex $intr_ctrl 1] 8 4>,  <&[lindex $intr_ctrl 1] 9 4>,  <&[lindex $intr_ctrl 1] 10 4>, <&[lindex $intr_ctrl 1] 11 4>, <&[lindex $intr_ctrl 1] 12 4>, <&[lindex $intr_ctrl 1] 13 4>, <&[lindex $intr_ctrl 1] 14 4>, <&[lindex $intr_ctrl 1] 15 4>, <&[lindex $intr_ctrl 1] 16 4>, <&[lindex $intr_ctrl 1] 17 4>, <&[lindex $intr_ctrl 1] 18 4>, <&[lindex $intr_ctrl 1] 19 4>, <&[lindex $intr_ctrl 1] 20 4>, <&[lindex $intr_ctrl 1] 21 4>, <&[lindex $intr_ctrl 1] 22 4>, <&[lindex $intr_ctrl 1] 23 4>, <&[lindex $intr_ctrl 1] 24 4>, <&[lindex $intr_ctrl 1] 25 4>, <&[lindex $intr_ctrl 1] 26 4>, <&[lindex $intr_ctrl 1] 27 4>, <&[lindex $intr_ctrl 1] 28 4>, <&[lindex $intr_ctrl 1] 29 4>, <&[lindex $intr_ctrl 1] 30 4 "
               add_prop $zocl_node "interrupts-extended" $ref reference $default_dts
               }
               "3" {
                       set ref [lindex $intr_ctrl 0]
                       append ref " 0 4>, <&[lindex $intr_ctrl 0] 1 4>, <&[lindex $intr_ctrl 0] 2 4>, <&[lindex $intr_ctrl 0] 3 4>, <&[lindex $intr_ctrl 0] 4 4>, <&[lindex $intr_ctrl 0] 5 4>, <&[lindex $intr_ctrl 0] 6 4>, <&[lindex $intr_ctrl 0] 7 4>, <&[lindex $intr_ctrl 0] 8 4>, <&[lindex $intr_ctrl 0] 9 4>, <&[lindex $intr_ctrl 0] 10 4>, <&[lindex $intr_ctrl 0] 11 4>, <&[lindex $intr_ctrl 0] 12 4>, <&[lindex $intr_ctrl 0] 13 4>, <&[lindex $intr_ctrl 0] 14 4>, <&[lindex $intr_ctrl 0] 15 4>, <&[lindex $intr_ctrl 0] 16 4>, <&[lindex $intr_ctrl 0] 17 4>, <&[lindex $intr_ctrl 0] 18 4>, <&[lindex $intr_ctrl 0] 19 4>, <&[lindex $intr_ctrl 0] 20 4>, <&[lindex $intr_ctrl 0] 21 4>, <&[lindex $intr_ctrl 0] 22 4>, <&[lindex $intr_ctrl 0] 23 4>, <&[lindex $intr_ctrl 0] 24 4>, <&[lindex $intr_ctrl 0] 25 4>, <&[lindex $intr_ctrl 0] 26 4>, <&[lindex $intr_ctrl 0] 27 4>, <&[lindex $intr_ctrl 0] 28 4>, <&[lindex $intr_ctrl 0] 29 4>, <&[lindex $intr_ctrl 0] 30 4>, <&[lindex $intr_ctrl 0] 31 4>, <&[lindex $intr_ctrl 1] 0 4>, <&[lindex $intr_ctrl 1] 1 4>, <&[lindex $intr_ctrl 1] 2 4>, <&[lindex $intr_ctrl 1] 2 4>, <&[lindex $intr_ctrl 1] 3 4>, <&[lindex $intr_ctrl 1] 4 4>, <&[lindex $intr_ctrl 1] 5 4>, <&[lindex $intr_ctrl 1] 6 4>, <&[lindex $intr_ctrl 1] 7 4>, <&[lindex $intr_ctrl 1] 8 4>, <&[lindex $intr_ctrl 1] 9 4>, <&[lindex $intr_ctrl 1] 10 4>, <&[lindex $intr_ctrl 1] 11 4>, <&[lindex $intr_ctrl 1] 12 4>, <&[lindex $intr_ctrl 1] 13 4>, <&[lindex $intr_ctrl 1] 14 4>, <&[lindex $intr_ctrl 1] 15 4>, <&[lindex $intr_ctrl 1] 16 4>, <&[lindex $intr_ctrl 1] 17 4>, <&[lindex $intr_ctrl 1] 18 4>, <&[lindex $intr_ctrl 1] 19 4>, <&[lindex $intr_ctrl 1] 20 4>, <&[lindex $intr_ctrl 1] 21 4>, <&[lindex $intr_ctrl 1] 22 4>, <&[lindex $intr_ctrl 1] 23 4>, <&[lindex $intr_ctrl 1] 24 4>, <&[lindex $intr_ctrl 1] 25 4>, <&[lindex $intr_ctrl 1] 26 4>, <&[lindex $intr_ctrl 1] 27 4>, <&[lindex $intr_ctrl 1] 28 4>, <&[lindex $intr_ctrl 1] 29 4>, <&[lindex $intr_ctrl 1] 30 4>, <&[lindex $intr_ctrl 1] 31 4>, <&[lindex $intr_ctrl 2] 0 4>, <&[lindex $intr_ctrl 2] 1 4>, <&[lindex $intr_ctrl 2] 2 4>, <&[lindex $intr_ctrl 2] 3 4>, <&[lindex $intr_ctrl 2] 4 4>, <&[lindex $intr_ctrl 2] 5 4>, <&[lindex $intr_ctrl 2] 6 4>, <&[lindex $intr_ctrl 2] 7 4>, <&[lindex $intr_ctrl 2] 8 4>, <&[lindex $intr_ctrl 2] 9 4>, <&[lindex $intr_ctrl 2] 10 4>, <&[lindex $intr_ctrl 2] 11 4>, <&[lindex $intr_ctrl 2] 12 4>, <&[lindex $intr_ctrl 2] 13 4>, <&[lindex $intr_ctrl 2] 14 4>, <&[lindex $intr_ctrl 2] 15 4>, <&[lindex $intr_ctrl 2] 16 4>, <&[lindex $intr_ctrl 2] 17 4>, <&[lindex $intr_ctrl 2] 18 4>, <&[lindex $intr_ctrl 2] 19 4>, <&[lindex $intr_ctrl 2] 20 4>, <&[lindex $intr_ctrl 2] 21 4>, <&[lindex $intr_ctrl 2] 22 4 >, <&[lindex $intr_ctrl 2] 23 4>, <&[lindex $intr_ctrl 2] 24 4>, <&[lindex $intr_ctrl 2] 25 4>, <&[lindex $intr_ctrl 2] 26 4>, <&[lindex $intr_ctrl 2] 27 4>, <&[lindex $intr_ctrl 2] 28 4>, <&[lindex $intr_ctrl 2] 29 4>, <&[lindex $intr_ctrl 2] 30 4 "
               add_prop $zocl_node "interrupts-extended" $ref reference $default_dts
               }
       }
 }
}

proc gen_zynqmp_pinctrl {} {
       set default_dts "pcw.dtsi"
       set pinctrl_node [create_node -n "&pinctrl0" -d $default_dts -p root]
       set periph_list [hsi::get_cells -hier]
       foreach periph $periph_list {
               set zynq_ultra_ps [get_property IP_NAME $periph]
               if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
                       set avail_param [list_property [hsi::get_cells -hier $periph]]
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__UART1__PERIPHERAL__IO"] >= 0} {
                               set uart1_io [get_property CONFIG.PSU__UART1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $uart1_io "EMIO"]} {
                                       set pinctrl_uart1_default [create_node -n "uart1-default" -d $default_dts -p $pinctrl_node]
                                       add_prop "$pinctrl_uart1_default" "/delete-node/ mux" "" boolean $default_dts
                                       add_prop "$pinctrl_uart1_default" "/delete-node/ conf" "" boolean $default_dts
                                       add_prop "$pinctrl_uart1_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       add_prop "$pinctrl_uart1_default" "/delete-node/ conf-tx" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__UART0__PERIPHERAL__IO"] >= 0} {
                               set uart0_io [get_property CONFIG.PSU__UART0__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $uart0_io "EMIO"]} {
                                       set pinctrl_uart0_default [create_node -n "uart0-default" -d $default_dts -p $pinctrl_node]
                                       add_prop "$pinctrl_uart0_default" "/delete-node/ mux" "" boolean $default_dts
                                       add_prop "$pinctrl_uart0_default" "/delete-node/ conf" "" boolean $default_dts
                                       add_prop "$pinctrl_uart0_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       add_prop "$pinctrl_uart0_default" "/delete-node/ conf-tx" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__CAN1__PERIPHERAL__IO"] >= 0} {
                               set can1_io [get_property CONFIG.PSU__CAN1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $can1_io "EMIO"]} {
                                       set pinctrl_can1_default [create_node -n "can1-default" -d $default_dts -p $pinctrl_node]
                                       add_prop "$pinctrl_can1_default" "/delete-node/ mux" "" boolean $default_dts
                                       add_prop "$pinctrl_can1_default" "/delete-node/ conf" "" boolean $default_dts
                                       add_prop "$pinctrl_can1_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       add_prop "$pinctrl_can1_default" "/delete-node/ conf-tx" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__SD1__PERIPHERAL__IO"] >= 0} {
                               set sd1_io [get_property CONFIG.PSU__SD1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $sd1_io "EMIO"]} {
                                       set pinctrl_sdhci1_default [create_node -n "sdhci1-default" -d $default_dts -p $pinctrl_node]
                                       add_prop "$pinctrl_sdhci1_default" "/delete-node/ mux" "" boolean $default_dts
                                       add_prop "$pinctrl_sdhci1_default" "/delete-node/ conf" "" boolean $default_dts
                                       add_prop "$pinctrl_sdhci1_default" "/delete-node/ conf-cd" "" boolean $default_dts
                                       add_prop "$pinctrl_sdhci1_default" "/delete-node/ mux-cd" "" boolean $default_dts
                                       add_prop "$pinctrl_sdhci1_default" "/delete-node/ conf-wp" "" boolean $default_dts
                                       add_prop "$pinctrl_sdhci1_default" "/delete-node/ mux-wp" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__ENET3__PERIPHERAL__IO"] >= 0} {
                               set gem3_io [get_property CONFIG.PSU__ENET3__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $gem3_io "EMIO"]} {
                                       set pinctrl_gem3_default [create_node -n "gem3-default" -d $default_dts -p $pinctrl_node]
                                       add_prop "$pinctrl_gem3_default" "/delete-node/ mux" "" boolean $default_dts
                                       add_prop "$pinctrl_gem3_default" "/delete-node/ conf" "" boolean $default_dts
                                       add_prop "$pinctrl_gem3_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       add_prop "$pinctrl_gem3_default" "/delete-node/ conf-tx" "" boolean $default_dts
                                       add_prop "$pinctrl_gem3_default" "/delete-node/ conf-mdio" "" boolean $default_dts
                                       add_prop "$pinctrl_gem3_default" "/delete-node/ mux-mdio" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__I2C1__PERIPHERAL__IO"] >= 0} {
                               set i2c1_io [get_property CONFIG.PSU__I2C1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $i2c1_io "EMIO"]} {
                                       set pinctrl_i2c1_default [create_node -n "i2c1-default" -d $default_dts -p $pinctrl_node]
                                       add_prop "$pinctrl_i2c1_default" "/delete-node/ mux" "" boolean $default_dts
                                       add_prop "$pinctrl_i2c1_default" "/delete-node/ conf" "" boolean $default_dts
                                       set pinctrl_i2c1_gpio [create_node -n "i2c1-gpio" -d $default_dts -p $pinctrl_node]
                                       add_prop "$pinctrl_i2c1_gpio" "/delete-node/ mux" "" boolean $default_dts
                                       add_prop "$pinctrl_i2c1_gpio" "/delete-node/ conf" "" boolean $default_dts
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
	lappend list_offiles "$path/device_tree/data/xillib_hw.tcl"
	lappend list_offiles "$path/device_tree/data/xillib_sw.tcl"
	lappend list_offiles "$path/device_tree/data/xillib_internal.tcl"
	lappend list_offiles "$path/device_tree/data/common_proc.tcl"
	foreach file $list_offiles {
		if {[file exists $file]} {
		        source -notrace $file
		}
	}
	set val_proclist "psv_cortexa72 psu_cortexa53 ps7_cortexa9"
	set peri_list [hsi::get_cells -hier]
	set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
	set microblaze [hsi::get_cells -hier -filter {IP_NAME==microblaze}]
	set ps_design 0
	set pl_design 0
	foreach procperiph $proclist {
        	set ip_name [get_property IP_NAME [hsi::get_cells -hier $procperiph]]
		if {[lsearch $val_proclist $ip_name] >= 0} {
			set ps_design 1
		}
	}
	foreach procperiph $proclist {
		if {[string match -nocase $microblaze $ip_name]} {
			set pl_design 1
		}
	}
	if {$pl_design == 1 && $ps_design == 0} {
		set val_proclist "microblaze"
	}
	
	remove_duplicate_addr
	foreach procc $proclist {
		set index [string index $procc end]
		set ip_name [get_property IP_NAME [hsi::get_cells -hier $procc]]

		if {[lsearch $val_proclist $ip_name] >= 0 && $index == 0 } {
			set drvname [get_drivers $procc]
			set proc_file "$path/${drvname}/data/${drvname}.tcl"
			source -notrace $proc_file
	                ::tclapp::xilinx::devicetree::${drvname}::generate $procc
		
			#namespace import ::${drvname}::\*
		        #::${drvname}::generate $procc
    			add_skeleton
			set non_val_list "versal_cips noc_nmu noc_nsu ila zynq_ultra_ps_e psu_iou_s smart_connect emb_mem_gen xlconcat axis_tdest_editor util_reduced_logic noc_nsw axis_ila"
			set non_val_ip_types "MONITOR BUS PROCESSOR"
			global duplist
    			foreach drv_handle $peri_list {
				set ip_name [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
				if {[is_ps_ip $drv_handle] != 1} {
				set base [get_baseaddr $drv_handle]
				if {[catch {set rt [dict get $duplist $base]} msg]} {
				} else {
					if {[llength $rt] == 1} {
					set matchip_name [get_property IP_NAME [hsi::get_cells -hier $rt]]
					if {![string match -nocase $rt $drv_handle] && [string match -nocase $matchip_name $ip_name]} {
						continue
					}
					} else {
						for {set cnt 0} {$cnt < [llength $rt]} {incr cnt} {
							set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $rt $cnt]]]
							if {![string match -nocase [lindex $rt $cnt] $drv_handle] && [string match -nocase $matchip_name $ip_name]} {
								continue
							}
						}
					}
				}
				}
				if {[string match -nocase $ip_name ""]} {
					continue
				}
				set ip_type [get_property IP_TYPE [hsi::get_cells -hier $drv_handle]]
				if {[lsearch -nocase $non_val_list $ip_name] >= 0} {
					continue
				}
				if {[lsearch -nocase $non_val_ip_types $ip_type] >= 0 } {
					continue
				}
 	       			gen_peripheral_nodes $drv_handle "create_node_only"
	        		gen_reg_property $drv_handle
	        		gen_compatible_property $drv_handle
				gen_ctrl_compatible $drv_handle
	        		gen_drv_prop_from_ip $drv_handle
	       			gen_interrupt_property $drv_handle
	       			gen_clk_property $drv_handle
				set driver_name [get_drivers $drv_handle]
				gen_xppu $drv_handle
    			}
			set non_val_list "psv_cortexa72 psu_cortexa53 ps7_cortexa9 versal_cips noc_nmu noc_nsu ila psu_iou_s noc_nsw"
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
				if {[is_ps_ip $drv_handle] != 1} {
					set base [get_baseaddr $drv_handle]
					if {[catch {set rt [dict get $duplist $base]} msg]} {
					} else {
						if {[llength $rt] == 1} {
						set matchip_name [get_property IP_NAME [hsi::get_cells -hier $rt]]
						if {![string match -nocase $rt $drv_handle] && [string match -nocase $matchip_name $ip_name]} {
							continue
						}
						} else {
							for {set cnt 0} {$cnt < [llength $rt]} {incr cnt} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $rt $cnt]]]
								if {![string match -nocase [lindex $rt $cnt] $drv_handle] && [string match -nocase $matchip_name $ip_name]} {
									continue
								}
							}
						}
					}
				}
				set drvname [get_drivers $drv_handle]
				set drv_file "$path/${drvname}/data/${drvname}.tcl"
				source -notrace $drv_file
		                ::tclapp::xilinx::devicetree::${drvname}::generate $drv_handle
			}
			foreach drv_handle $peri_list {
				update_endpoints $drv_handle
				
			}
			namespace forget ::
		} elseif {[string match -nocase $ip_name "microblaze"]} {
			set drvname [get_drivers $procc]
			set proc_file "$path/${drvname}/data/${drvname}.tcl"
			source -notrace $proc_file
	                ::tclapp::xilinx::devicetree::${drvname}::generate $procc
			namespace forget ::
			
		} else {
			continue
		}
	}
    	gen_board_info
	gen_afi_node
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
			gen_versal_clk
			gen_zynqmp_opp_freq
			gen_zynqmp_pinctrl
			gen_zocl_node
		}
    	}
    	if {[string match -nocase $proctype "zynq"]} {
		set mainline_ker [get_user_config $common_file -mainline_kernel]
	       	if {[string match -nocase $mainline_ker "none"]} {
        	    	gen_zocl_node
        	}
    	}
    	#gen_resrv_memory
    	update_alias $drv_handle
    	update_cpu_node $drv_handle
	gen_r5_trustzone_config
	gen_tcmbus
	proc_mapping
        gen_cpu_cluster $drv_handle
	set family [get_hw_family]
	if {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
		set reset_node [create_node -n "&zynqmp_reset" -p root -d "pcw.dtsi"]
		add_prop $reset_node "status" "okay" string "pcw.dtsi"
	}
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
		delete_tree systemdt root
		delete_tree pldt root
		delete_tree pcwdt root
		write_dt systemdt root "$dir/system-top.dts"
		write_dt pldt root "$dir/pl.dtsi"
		write_dt pcwdt root "$dir/pcw.dtsi"
		global set osmap
		unset osmap
		
	} else {
		delete_tree systemdt root
		delete_tree pldt root
		write_dt systemdt root "$dir/system-top.dts"
		write_dt pldt root "$dir/pl.dtsi"
		global set osmap
		unset osmap
	}
	destroy_tree
}

proc delete_tree {dttree head} {
	set childs [$dttree children $head]
	foreach child $childs {
		if {[catch {set amba_childs [$dttree children $child]} msg]} {
		} else {
			foreach amba_cchild $amba_childs {
				set val [$dttree getall $amba_cchild]
				if {[string match -nocase $val ""]} {
					$dttree delete $amba_cchild
				}
			}
		}
	}
}

proc gen_r5_trustzone_config {} {
        set cortexa72proc [hsi::get_cells -hier -filter {IP_NAME=="psv_cortexa72"}]
        set family [get_hw_family]
        if {[string match -nocase $family "versal"]} {
                set cortexr5proc [hsi::get_cells -hier -filter {IP_NAME=="psv_cortexr5"}]
        } elseif {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
                set cortexr5proc [hsi::get_cells -hier -filter {IP_NAME=="psu_cortexr5"}]
        } else {
                set cortexr5proc ""
        }
	set rpu_cnt 0
        set slcr_instance [hsi::get_cells -hier -filter { IP_NAME == "psu_iouslcr" }]
	foreach r5proc $cortexr5proc {
		set r5_tz ""
		set r5_access 0
		set cnt 0
		if {[catch {set r5_tz [get_property CONFIG.C_TZ_NONSECURE $r5proc]} msg]} {
		}
		if {$r5_tz == "" || $r5_tz == "0"} {
			set r5_access 0xff
		} else {
			if {[llength $cortexr5proc] > 0} {
				set rpu_tz [string toupper [get_property TRUSTZONE [lindex [hsi::get_mem_ranges \
				[hsi::get_cells -hier $r5proc] *rpu*] 0]]]
				if {[string compare -nocase $rpu_tz "NONSECURE"] == 0} {
					set r5_access [expr int([expr $r5_access + pow(2,$cnt)])]
				}
			}
			incr cnt
			if {[llength $cortexa72proc] == 0 && [llength $slcr_instance] > 0} {
				set iou_slcr_tz [string toupper [get_property TRUSTZONE [lindex [hsi::get_mem_ranges \
				[hsi::get_cells -hier $r5proc] psu_iouslcr_0] 0]]]
				if {([string compare -nocase $iou_slcr_tz "NONSECURE"] == 0)} {
					set r5_access [expr int([expr $r5_access + pow(2,$cnt)])]
				}
			}
	        }
		set rt_node [create_node -n "&r5_cpu${rpu_cnt}" -d "pcw.dtsi" -p root]
		add_prop $rt_node "access-val" $r5_access hexint "pcw.dtsi"
		incr rpu_cnt
	}
}

proc update_hier_mem {iptype} {
	set periph_list [hsi::get_cells -hier]
	foreach periph $periph_list {
		if {[catch {set ipname [get_property IP_NAME [hsi::get_cells -hier $periph]]} msg]} {
			set ipname ""
			continue
		}
		set regprop ""
		set addr_64 "0"
		set size_64 "0"
		set base [get_baseaddr $periph]
		set high [get_highaddr $periph]
		if {[string match -nocase $base ""] || [string match -nocase $high ""]} {
			continue
		}
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
		set temp [get_node $periph]
		if {$temp == ""} {
			continue
		}
		set temp [string trimleft $temp "&"]
		set len [llength $temp]
		if {$len > 1} {
			set temp [split $temp ":"]
			set temp [lindex $temp 0]
		}
		if {[string match -nocase $iptype "psv_cortexa72"] || [string match -nocase $iptype "psu_cortexa53"]} {
						if {[is_pl_ip $periph]} {
							set tmpbase [get_baseaddr $periph]
							set ip_name [get_property IP_NAME [hsi::get_cells -hier $periph]]
							global duplist
							if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
								set_memmap $temp a53 $regprop
							} else {
								if {[llength $handle_value] == 1} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
								set temp [dict get $duplist $tmpbase]
								set_memmap $handle_value a53 $regprop
								} else {
									for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
										set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
										if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
										continue
										} else {
											set_memmap [lindex $handle_value $cnt] a53 $regprop
										}
									}
								}
							}
						} else {
								set_memmap $temp a53 $regprop
						}

		}
		if {[string match -nocase $iptype "psv_cortexr5"] || [string match -nocase $iptype "psu_cortexr5"]} {
						if {[is_pl_ip $periph]} {
							set tmpbase [get_baseaddr $periph]
							set ip_name [get_property IP_NAME [hsi::get_cells -hier $periph]]
							global duplist
							if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
								set_memmap $temp r5 $regprop
							} else {
								if {[llength $handle_value] == 1} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
								set temp [dict get $duplist $tmpbase]
								set_memmap $handle_value r5 $regprop
								} else {
									for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
										set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
										if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
										continue
										} else {
											set_memmap [lindex $handle_value $cnt] r5 $regprop
										}
									}
								}
							}
						} else {
								set_memmap $temp r5 $regprop
						}

		}
		if {[string match -nocase $iptype "psv_pmc"]} {
						if {[is_pl_ip $periph]} {
							set tmpbase [get_baseaddr $periph]
							set ip_name [get_property IP_NAME [hsi::get_cells -hier $periph]]
							global duplist
							if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
								set_memmap $temp pmc $regprop
							} else {
								if {[llength $handle_value] == 1} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
								set temp [dict get $duplist $tmpbase]
								set_memmap $handle_value pmc $regprop
								} else {
									for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
										set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
										if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
										continue
										} else {
											set_memmap [lindex $handle_value $cnt] pmc $regprop
										}
									}
								}
							}
						} else {
								set_memmap $temp pmc $regprop
						}

		}
		if {[string match -nocase $iptype "psv_psm"]} {
						if {[is_pl_ip $periph]} {
							set tmpbase [get_baseaddr $periph]
							set ip_name [get_property IP_NAME [hsi::get_cells -hier $periph]]
							global duplist
							if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
								set_memmap $temp psm $regprop
							} else {
								if {[llength $handle_value] == 1} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
								set temp [dict get $duplist $tmpbase]
								set_memmap $handle_value psm $regprop
								} else {
									for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
										set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
										if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
										continue
										} else {
											set_memmap [lindex $handle_value $cnt] psm $regprop
										}
									}
								}
							}
						} else {
								set_memmap $temp psm $regprop
						}

		}
		if {[string match -nocase $iptype "psu_pmu"]} {
						if {[is_pl_ip $periph]} {
							set tmpbase [get_baseaddr $periph]
							set ip_name [get_property IP_NAME [hsi::get_cells -hier $periph]]
							global duplist
							if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
								set_memmap $temp pmu $regprop
							} else {
								if {[llength $handle_value] == 1} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
								set temp [dict get $duplist $tmpbase]
								set_memmap $handle_value pmu $regprop
								} else {
									for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
										set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
										if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
										continue
										} else {
											set_memmap [lindex $handle_value $cnt] pmu $regprop
										}
									}
								}
							}
						} else {
								set_memmap $temp pmu $regprop
						}

		}
			if {[string match -nocase $iptype "microblaze"]} {
						if {[is_pl_ip $periph]} {
							set tmpbase [get_baseaddr $periph]
							set ip_name [get_property IP_NAME [hsi::get_cells -hier $periph]]
							global duplist
							if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
								set_memmap $temp $val $regprop
							} else {
								if {[llength $handle_value] == 1} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
								set temp [dict get $duplist $tmpbase]
								set_memmap $handle_value $val $regprop
								} else {
									for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
										set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
										if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
										continue
										} else {
											set_memmap [lindex $handle_value $cnt] $val $regprop
										}
									}
								}
							}
						} else {
								set_memmap $temp $val $regprop
						}

		}
	
	}
}
proc proc_mapping {} {
	set proctype [get_hw_family]
    set default_dts "system-top.dts"
    set proc_list [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
	set periphs_list ""
	set ps_list [create_busmap psdt root]
	set pl_list [create_busmap pldt root]
	set count 2
	for {set i 0 } {$i < $count} {incr i} {
	if {$i == 0} {
		set split_list [split $ps_list "\n"]
		set dt "psdt"
	} else {
		set split_list [split $pl_list "\n"]
		set dt "pldt"
	}

	append periphs_list [hsi::get_cells -hier -filter {IP_TYPE==MEMORY_CNTLR}]
	set family [get_hw_family]
	if {[string match -nocase $family "versal"]} {
		append periphs_list " [hsi::get_cells -hier -filter {IP_NAME==axi_noc}]"
		append periphs_list " [hsi::get_cells -hier -filter {IP_NAME==noc_mc_ddr4}]"
	}
        foreach val $proc_list {

		set periph_list [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $val]]
		set iptype [get_property IP_NAME [hsi::get_cells -hier $val]]
		foreach periph $periph_list {
			if {[catch {set hier_prop [get_property IS_HIERARCHICAL [hsi::get_cells -hier $periph]]} msg]} {
				set hier_prop 0
			}
			if {[catch {set ipname [get_property IP_NAME [hsi::get_cells -hier $periph]]} msg]} {
				set ipname ""
				continue
			}
			if {[lsearch $periphs_list $periph] >= 0} {
                               set valid_periph "psu_qspi_linear psv_pmc_qspi"
                               if {[lsearch $valid_periph $ipname] >= 0} {
                               } else {
                                       continue
                               }
                        }
			if {[string match -nocase $iptype "psv_cortexa72"] && [string match -nocase $ipname "psv_rcpu_gic"]} {
				continue
			}
			if {[string match -nocase $iptype "psv_cortexr5"] && [string match -nocase $ipname "psv_acpu_gic"]} {
				continue
			}
			if {[string match -nocase $iptype "psu_cortexa53"] && [string match -nocase $ipname "psu_rcpu_gic"]} {
				continue
			}
			if {[string match -nocase $iptype "psu_cortexr5"] && [string match -nocase $ipname "psu_acpu_gic"]} {
				continue
			}
			if {[string match -nocase $ipname "psv_ipi"]} {
				continue
			}
			set regprop ""
			set addr_64 "0"
			set size_64 "0"
			set base [get_baseaddr $periph]
			set high [get_highaddr $periph]
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
			set temp [get_node $periph]
			if {$temp == ""} {
				continue
			}
			set temp [string trimleft $temp "&"]
			set len [llength $temp]
			if {$len > 1} {
				set temp [split $temp ":"]
				set temp [lindex $temp 0]
			}

			if {[string match -nocase $ipname "psv_rcpu_gic"] } {
				set temp "gic_r5"
			}

			set ip_name [get_property IP_NAME [hsi::get_cells -hier $periph]]
			

			if {[string match -nocase $iptype "psv_cortexa72"] || [string match -nocase $iptype "psu_cortexa53"]} {
				
				
				if {[is_pl_ip $periph]} {
					set tmpbase [get_baseaddr $periph]
					global duplist
					if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
						set_memmap $temp a53 $regprop
					} else {
						if {[llength $handle_value] == 1} {
							set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]

							set temp [dict get $duplist $tmpbase]
							set_memmap $handle_value a53 $regprop
						} else {
							for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
								if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
								continue
								} else {
									set_memmap [lindex $handle_value $cnt] a53 $regprop
								}
							}
						}
					}
				} else {
						set_memmap $temp a53 $regprop
				}
			}
			if {[string match -nocase $iptype "psv_cortexr5"] || [string match -nocase $iptype "psu_cortexr5"]} {
				if {[is_pl_ip $periph]} {
					set tmpbase [get_baseaddr $periph]
					global duplist
					if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
						set_memmap $temp r5 $regprop
					} else {
						if {[llength $handle_value] == 1} {
						set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
						set temp [dict get $duplist $tmpbase]
						set_memmap $handle_value r5 $regprop
						} else {
							for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
								if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
								continue
								} else {
									set_memmap [lindex $handle_value $cnt] r5 $regprop
								}
							}
						}
					}
				} else {
						set_memmap $temp r5 $regprop
				}
			}
			if {[string match -nocase $iptype "psv_pmc"]} {
				if {[is_pl_ip $periph]} {
					set tmpbase [get_baseaddr $periph]
					global duplist
					if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
						set_memmap $temp pmc $regprop
					} else {
						if {[llength $handle_value] == 1} {
						set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
						set temp [dict get $duplist $tmpbase]
						set_memmap $handle_value pmc $regprop
						} else {
							for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
								if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
								continue
								} else {
									set_memmap [lindex $handle_value $cnt] pmc $regprop
								}
							}
						}
					}
				} else {
						set_memmap $temp pmc $regprop
				}
			}
			if {[string match -nocase $iptype "psv_psm"]} {
				if {[is_pl_ip $periph]} {
					set tmpbase [get_baseaddr $periph]
					global duplist
					if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
						set_memmap $temp psm $regprop
					} else {
						if {[llength $handle_value] == 1} {
						set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
						set temp [dict get $duplist $tmpbase]
						set_memmap $handle_value psm $regprop
						} else {
							for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
								if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
								continue
								} else {
									set_memmap [lindex $handle_value $cnt] psm $regprop
								}
							}
						}
					}
				} else {
						set_memmap $temp psm $regprop
				}
			}
			if {[string match -nocase $iptype "psu_pmu"]} {
				if {[is_pl_ip $periph]} {
					set tmpbase [get_baseaddr $periph]
					global duplist
					if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
						set_memmap $temp pmu $regprop
					} else {
						if {[llength $handle_value] == 1} {
						set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
						set temp [dict get $duplist $tmpbase]
						set_memmap $handle_value pmu $regprop
						} else {
							for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
								if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
								continue
								} else {
									set_memmap [lindex $handle_value $cnt] pmu $regprop
								}
							}
						}
					}
				} else {
						set_memmap $temp pmu $regprop
				}
			}
			if {[string match -nocase $iptype "microblaze"]} {
				if {[is_pl_ip $periph]} {
					set tmpbase [get_baseaddr $periph]
					global duplist
					if {[catch {set handle_value [dict get $duplist $tmpbase]} msg]} {
						set_memmap $temp $val $regprop
					} else {
						if {[llength $handle_value] == 1} {
						set matchip_name [get_property IP_NAME [hsi::get_cells -hier $handle_value]]
						set temp [dict get $duplist $tmpbase]
						set_memmap $handle_value $val $regprop
						} else {
							for {set cnt 0} {$cnt < [llength $handle_value]} {incr cnt} {
								set matchip_name [get_property IP_NAME [hsi::get_cells -hier [lindex $handle_value $cnt]]]
								if {![string match -nocase [lindex $handle_value $cnt] $periph] && [string match -nocase $matchip_name $ip_name]} {
								continue
								} else {
									set_memmap [lindex $handle_value $cnt] $val $regprop
								}
							}
						}
					}
				} else {
						set_memmap $temp $val $regprop
				}
			}
		}
		
	}
	}
}

proc generate_psvreg_property {base high} {
	if {[string match -nocase $base ""]} {
		return
	}
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
	set base_value_0 ""
	set high_value_0 ""
	set interface_block_names ""
 	lappend periphs_list [hsi::get_cells -hier -filter {IP_TYPE==MEMORY_CNTLR}]
	if {[string match -nocase $family "versal"]} {
		lappend periphs_list [hsi::get_cells -hier -filter {IP_NAME==axi_noc}]
		lappend periphs_list [hsi::get_cells -hier -filter {IP_NAME==noc_mc_ddr4}]
	}
	foreach periph $periphs_list {
	foreach proc_map $proc_list {
		set proctype [get_property IP_NAME $proc_map]
		if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psu_cortexr5"] || [string match -nocase $proctype "psu_pmu"]} {
			set ranges [hsi::get_mem_ranges -of_objects $proc_map]
			set ranges [hsi::get_mem_ranges -of_objects $proc_map -filter {MEM_TYPE==MEMORY}]
		} elseif {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psv_cortexr5"] || [string match -nocase $proctype "psv_pmc"]} {
			if {[catch {set interface_block_names [get_property ADDRESS_BLOCK [hsi::get_mem_ranges -of_objects $proc_map $periph]]} msg]} {}
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
	#set chosen_node [create_node -n "aliases" -p root -d $default_dts]
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
	set ipi_list [hsi::get_cells -hier *ipi*]
	foreach val $ipi_list {
		set temp [get_node $val]
		set temp [string trimleft $temp "&"]
		set val1 $temp
		set len [llength $temp]
		if {$len > 1} {
			set temp [split $temp ":"]
			set val1 [lindex $temp 0]
		}

		set cpu [get_property CONFIG.C_CPU_NAME [hsi::get_cells -hier $val]]
		if {[string match -nocase $cpu "A72"] || [string match -nocase $cpu "APU"]} {
			set base [get_baseaddr $val]
			set high [get_highaddr $val]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set_memmap $val1 a53 "0x0 $base 0x0 $size"
		}
		if {[string match -nocase $cpu "RPU0"] || [string match -nocase $cpu "RPU1"]} {
			set base [get_baseaddr $val]
			set high [get_highaddr $val]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set_memmap $val1 r5 "0x0 $base 0x0 $size"
		}
		if {[string match -nocase $cpu "R5_0"] || [string match -nocase $cpu "R5_1"]} {
			set base [get_baseaddr $val]
			set high [get_highaddr $val]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set_memmap $val1 r5 "0x0 $base 0x0 $size"
		}
		if {[string match -nocase $cpu "PSM"]} {
			set base [get_baseaddr $val]
			set high [get_highaddr $val]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set_memmap $val1 psm "0x0 $base 0x0 $size"
		}
		if {[string match -nocase $cpu "PMC"]} {
			set base [get_baseaddr $val]
			set high [get_highaddr $val]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set_memmap $val1 pmc "0x0 $base 0x0 $size"
		}
		if {[string match -nocase $cpu "PMU"]} {
			set base [get_baseaddr $val]
			set high [get_highaddr $val]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set_memmap $val1 pmu "0x0 $base 0x0 $size"
		}

	}
    	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
        	set cpu_node [create_node -l "cpus_a53" -n "cpus-a53" -u 0 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x2" hexint $default_dts
		add_prop $cpu_node "#ranges-address-cells" "0x2" hexint $default_dts
		global memmap
		set values [dict keys $memmap]
		set list_values "0x0 0xf0000000 &amba 0x0 0xf0000000 0x0 0x10000000>, \n\t\t\t      <0x0 0xffe00000 &tcm_bus 0x0 0x0 0x0 0x10000>, \n\t\t\t      <0x0 0xf9000000 &amba_apu 0x0 0xf9000000 0x0 0x80000>, \n\t\t\t      <0x0 0x0 &zynqmp_reset 0x0 0x0 0x0 0x0"
		foreach val $values {
			set temp [get_memmap $val a53]
			set com_val [split $temp ","]
			foreach value $com_val {
				set addr "[lindex $value 0] [lindex $value 1]"
				if {[string match -nocase $val "psu_rcpu_gic"] || [string match -nocase $val "psu_acpu_gic"]} {
					set size "0x0 [lindex $value 2]"
				} else {
					set size "[lindex $value 2] [lindex $value 3]"
				}
				set addr [string trimright $addr ">"]
				set addr [string trimleft $addr "<"]
				set size [string trimright $size ">"]
				set size [string trimleft $size "<"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
		add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x80" hexlist $default_dts
    	} elseif {[string match -nocase $proctype "versal"] } {
        	set cpu_node [create_node -l "cpus_a72" -n "cpus-a72" -u 0 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x2" hexint $default_dts
		add_prop $cpu_node "#ranges-address-cells" "0x2" hexint $default_dts
		global memmap
		set cnt 0
		set values [dict keys $memmap]
		set list_values "0x0 0xf0000000 &amba 0x0 0xf0000000 0x0 0x10000000>, \n\t\t\t     <0x0 0xffe00000 &tcm_bus 0x0 0xffe00000 0x0 0x10000>, \n\t\t\t      <0x0 0xf9000000 &amba_apu 0x0 0xf9000000 0x0 0x80000"
		foreach val $values {
			set temp [get_memmap $val a53]
			set com_val [split $temp ","]
			foreach value $com_val {
				set addr "[lindex $value 0] [lindex $value 1]"
				set size "[lindex $value 2] [lindex $value 3]"
				set addr [string trimright $addr ">"]
				set addr [string trimleft $addr "<"]
				set size [string trimright $size ">"]
				set size [string trimleft $size "<"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
		add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x260> , <&pmc_xppu 0x260> , <&lpd_xppu 0x261>, <&pmc_xppu 0x261> , <&pmc_xppu_npi 0x260> , <&pmc_xppu_npi 0x261" hexlist $default_dts
    	}
	if {[string match -nocase $proctype "versal"] } {
		set cpu_node [create_node -l "cpus_r5" -n "cpus-r5" -u 3 -d ${default_dts} -p root]
	} elseif {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		set cpu_node [create_node -l "cpus_r5" -n "cpus-r5" -u 1 -d ${default_dts} -p root]
	}
	add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
	add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
	add_prop $cpu_node "#ranges-address-cells" "0x1" hexint $default_dts
	global memmap
	set values [dict keys $memmap]
	set list_values "0xf0000000 &amba 0xf0000000 0x10000000>, \n\t\t\t      <0x0 &tcm_bus 0xffe00000 0x100000>, \n\t\t\t      <0xf9000000 &amba_rpu 0xf9000000 0x3000"
    	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		set list_values "0xf0000000 &amba 0xf0000000 0x10000000>, \n\t\t\t      <0x0 &tcm_bus 0xffe00000 0x100000>, \n\t\t\t      <0xf9000000 &amba_rpu 0xf9000000 0x3000>, \n\t\t\t      <0x0 &zynqmp_reset 0x0 0x0"
	}

	foreach val $values {
		set temp [get_memmap $val r5]
		set com_val [split $temp ","]
		foreach value $com_val {
			set addr "[lindex $value 1]"
			if {[string match -nocase $val "psu_rcpu_gic"] || [string match -nocase $val "psu_acpu_gic"]} {
				set size "[lindex $value 2]"
			} else {
				set size "[lindex $value 3]"
			}
			set addr [string trimright $addr ">"]
			set size [string trimright $size ">"]
			set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
		}
	}
	add_prop $cpu_node "address-map" $list_values special $default_dts
    	if {[string match -nocase $proctype "versal"] } {
		add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x200> , <&pmc_xppu 0x200> , <&lpd_xppu 0x204>, <&pmc_xppu 0x204> , <&pmc_xppu_npi 0x200> , <&pmc_xppu_npi 0x204" hexlist $default_dts
	} elseif {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x0> , <&lpd_xppu 0x10" hexlist $default_dts
	}

    	if {[string match -nocase $proctype "versal"]} {
		set cpu_node [create_node -l "cpus_microblaze_1" -n "cpus_microblaze" -u 1 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
	        add_prop "${cpu_node}" "#ranges-address-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x247> , <&pmc_xppu 0x247> , <&pmc_xppu_npi 0x247" hexlist $default_dts
	} else {
        	set microblaze_node [create_node -l "cpus_microblaze_1" -n "cpus_microblaze" -u 1 -d ${default_dts} -p root]
	        add_prop "${microblaze_node}" "compatible" "cpus,cluster" string $default_dts
       		add_prop "${microblaze_node}" "#ranges-size-cells" "0x1" hexint $default_dts
       	 	add_prop "${microblaze_node}" "#ranges-address-cells" "0x1" hexint $default_dts
		add_prop $microblaze_node "bus-master-id" "&lpd_xppu 0x40" hexlist $default_dts
	}
	global memmap
	set values [dict keys $memmap]
	set list_values "0xf0000000 &amba 0xf0000000 0x10000000"
    	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		set list_values "0xf0000000 &amba 0xf0000000 0x10000000>, \n\t\t\t      <0x0 &zynqmp_reset 0x0 0x0"
	}
	foreach val $values {
    		if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
			set temp [get_memmap $val pmu]
		} else {
			set temp [get_memmap $val pmc]
		}
		set com_val [split $temp ","]
		foreach value $com_val {
			set addr "[lindex $value 1]"
			set size "[lindex $value 3]"
			set addr [string trimright $addr ">"]
			set size [string trimright $size ">"]
			set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
		}
	}
    	if {[string match -nocase $proctype "versal"]} {
		add_prop $cpu_node "address-map" $list_values special $default_dts
	} else {
		add_prop $microblaze_node "address-map" $list_values special $default_dts
	}
	if {[string match -nocase $proctype "versal"]} {
		set cpu_node [create_node -l "cpus_microblaze_2" -n "cpus_microblaze" -u 2 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
	    add_prop "${cpu_node}" "#ranges-address-cells" "0x1" hexint $default_dts
		global memmap
		set values [dict keys $memmap]
		set list_values "0xf0000000 &amba 0xf0000000 0x10000000"
		foreach val $values {
			set temp [get_memmap $val psm]
			set com_val [split $temp ","]
			foreach value $com_val {
				set addr "[lindex $value 1]"
				set size "[lindex $value 3]"
				set addr [string trimright $addr ">"]
				set size [string trimright $size ">"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
		add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x238> , <&pmc_xppu 0x238> , <&pmc_xppu_npi 0x238" hexlist $default_dts
	}
	set microblaze_proc [hsi::get_cells -hier -filter {IP_NAME==microblaze}]
	
	if {[llength $microblaze_proc] > 0} {
		set plnode [create_node -l "amba_pl" -n "amba_pl" -d ${default_dts} -p root]
		
	
	foreach proc $microblaze_proc {
		set count [get_microblaze_nr $proc]
		if {[string match -nocase $proctype "versal"]} {
			set cpu_node [create_node -l "cpus_microblaze_${count}" -n "cpus_microblaze" -u $count -d ${default_dts} -p $plnode]
		} elseif {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
			set cpu_node [create_node -l "cpus_microblaze_${count}" -n "cpus_microblaze" -u $count -d ${default_dts} -p $plnode]	
		}
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
	    add_prop "${cpu_node}" "#ranges-address-cells" "0x1" hexint $default_dts
		global memmap
		set values [dict keys $memmap]
		set list_values "0xf1000000 &amba 0xf1000000 0xeb00000"
		foreach val $values {
			set temp [get_memmap $val $proc]
			set com_val [split $temp ","]
			foreach value $com_val {
				set addr "[lindex $value 1]"
				set size "[lindex $value 3]"
				set addr [string trimright $addr ">"]
				set size [string trimright $size ">"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
	}
	}
	
}

proc gen_tcmbus {} {
    set default_dts "system-top.dts"
    set tcmbus [create_node -n tcm_bus -l tcm_bus -d ${default_dts} -p root]
    add_prop "${tcmbus}" "compatible" "simple-bus" string $default_dts
    add_prop "${tcmbus}" "#size-cells" "0x1" hexlist $default_dts
    add_prop "${tcmbus}" "#address-cells" "0x1" hexlist $default_dts
    set tcm_child [create_node -n "tcm" -u "ffe00000" -d ${default_dts} -p $tcmbus]
    add_prop $tcm_child "compatible" "mmiio-sram" string $default_dts
    add_prop $tcm_child "reg" "0xffe00000 0x10000" hexlist $default_dts
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
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
	if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
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
			if {[is_pl_ip $drv_handle]} {
				set value "&$value"
			}
			set ip_list "i2c spi serial"
            	# TODO: need to check if the label already exists in the current system
		set proctype [get_hw_family]
	       # if {[regexp "kintex*" $proctype match]} {
			set alias_node [create_node -n "aliases" -p root -d "system-top.dts"]
			add_prop $alias_node $conf_name $value aliasref $default_dts
	#	}
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
		set ip [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $ip "axi_bram_ctrl"]} {
			return
		}
		if {[string match -nocase $ip "ddr4"]} {
			set slave [hsi::get_cells -hier ${drv_handle}]
			set ip_mem_handles [get_ip_mem_ranges $slave]
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

proc gen_ctrl_compatible {drv_handle} {
	set node [get_node $drv_handle]
	set dts [set_drv_def_dts $drv_handle]
	set baseaddr [get_baseaddr $drv_handle noprefix]
	set baseaddr "0x${baseaddr}"
	set family [get_hw_family]
        dict set pslist 0xf1020000 "xlnx,pmc-gpio-1.0"
	dict set pslist 0xf0280000 "xlnx,iomodule-3.1"
	dict set pslist 0xf11c0000 "xlnx,zynqmp-csudma-1.0"
	dict set pslist 0xf11d0000 "xlnx,zynqmp-csudma-1.0"
	dict set pslist 0xf1270000 "xlnx,versal-sysmon"
	dict set pslist 0xff990000 "xlnx,xppu"
	dict set pslist 0xf1310000 "xlnx,xppu"
	dict set pslist 0xf1300000 "xlnx,xppu"
	dict set pslist 0xf1000000 "cdns,i2c-r1p14 cdns,i2c-r1p10"
	dict set pslist 0xfd390000 "xlnx,xmpu"
	dict set pslist 0xf12f0000 "xlnx,xmpu"
	dict set pslist 0xff980000 "xlnx,xmpu"
	dict set pslist 0xf6080000 "xlnx,xmpu"
	dict set pslist 0xf6220000 "xlnx,xmpu"
	dict set pslist 0xf6390000 "xlnx,xmpu"
	dict set pslist 0xf6500000 "xlnx,xmpu"
	if {[string match -nocase $family "versal"]} {
		set ctrl_addr_list "0xF11E0000 0xFF9C0000 0xF11F0000 0xF12D0000 0xF12E4000
				0xF12E6000 0xF12E8000 0xF12EA000 0xF12EC000 0xF12D2000
				0xF12D4000 0xF12D6000 0xF12D8000 0xF12DA000 0xF12DC000
				0xF12DE000 0xF12E0000 0xF12E2000 0xF12EE000 0xF12B0000
				0xFD1A0000 0xFF5E0000 0xF1260000 0xF1200000 0xF1250000
				0xF1240000 0xFD360000 0xFD380000 0xFD700000 0xFD390000
				0xFD610000 0xFD690000 0xFE5F0000 0xFFC9F000 0xFCB40000
				0xFD370000 0xFE600000 0xF1330000 0xFF130000 0xFF140000
				0xFF9B0000 0xFE400000 0xFE000000 0xFF0A0000 0xFF080000
				0xFF410000 0xFF510000 0xFF990000 0xFF980000 0xF1160000
				0xF11C0000 0xF11D0000 0xF1110000 0xF1020000 0xF1000000
				0xF1080000 0xF1070000 0xF1060000 0xF0040000 0xF1320000
				0xF1100000 0xF1270000 0xF11A0000 0xF12F0000 0xF1310000
				0xF1300000 0xF0081000 0xF0082000 0xF0100000 0xF0280000
				0xF0310000 0xF0282000 0xF0281000 0xF0284000 0xF0283000
				0xF0300000 0xFFC90000 0xFFC80000 0xFFC88000 0xFFCF0000
				0xFFCB0000 0xFFCA0000 0xFFCD0000 0xFFCC0000 0xFFCE0000
				0xF0050000 0xF1210000 0xF1220000 0xF1230000 0xFD390000
				0xF12F0000 0xFF980000 0xF6080000 0xF6220000 0xF6390000
				0xF6500000"
		if {[lsearch -nocase $ctrl_addr_list $baseaddr] >= 0} {
			if {[catch {set tmp [dict get $pslist $baseaddr]} msg]} {
				pcwdt append $node compatible "\ \, \"xlnx,ctrlregs\""
			} else {
				add_prop $node compatible "$tmp xlnx,ctrlregs" stringlist $dts
			}
		}
	}
}

proc gen_xppu {drv_handle} {
	global env
	set path $env(REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set dt_overlay [get_user_config $common_file -dt_overlay]
	set ip [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $ip "axi_noc"] && $dt_overlay} {
		return
	}
	set node [get_node $drv_handle]
	set baseaddr [get_baseaddr $drv_handle noprefix]
	set xppu [dict create]
	set family [get_hw_family]
	if {[string match -nocase $family "versal"] && [is_ps_ip $drv_handle]} {
		dict set xppu	FF980000	addr	lpd
		dict set xppu	FF990000	addr	lpd
		dict set xppu	FFA80000	addr	lpd
		dict set xppu	FF9B0000	addr	lpd
		dict set xppu	FF960000	addr	lpd
		dict set xppu	FF970000	addr	lpd
		dict set xppu	FF8E0000	addr	lpd
		dict set xppu	FF940000	addr	lpd
		dict set xppu	FF900000	addr	lpd
		dict set xppu	FF9A0000	addr	lpd
		dict set xppu	FF9C0000	addr	lpd
		dict set xppu	FF5E0000	addr	lpd
		dict set xppu	FF8C0000	addr	lpd
		dict set xppu	FF880000	addr	lpd
		dict set xppu	FF800000	addr	lpd
		dict set xppu	FF600000	addr	lpd
		dict set xppu	FF410000	addr	lpd
		dict set xppu	FF500000	addr	lpd
		dict set xppu	FF420000	addr	lpd
		dict set xppu	FF440000	addr	lpd
		dict set xppu	FF480000	addr	lpd
		dict set xppu	FF510000	addr	lpd
		dict set xppu	FF540000	addr	lpd
		dict set xppu	FF520000	addr	lpd
		dict set xppu	80000000	addr	lpd
		dict set xppu	400000000	addr	lpd
		dict set xppu	40000000000	addr	lpd
		dict set xppu	FE600000	addr	lpd
		dict set xppu	FCFF0000	addr	lpd
		dict set xppu	F9000000	addr	lpd
		dict set xppu	F8000000	addr	lpd
		dict set xppu	FD000000	addr	lpd
		dict set xppu	A4000000	addr	lpd
		dict set xppu	A8000000	addr	lpd
		dict set xppu	B0000000	addr	lpd
		dict set xppu	FF9D0000	addr	lpd
		dict set xppu	FF9E0000	addr	lpd
		dict set xppu	FE200000	addr	lpd
		dict set xppu	FF200000	addr	lpd
		dict set xppu	FE000000	addr	lpd
		dict set xppu	FF000000	addr	lpd
		dict set xppu	FFC00000	addr	lpd
		dict set xppu	FF300000	addr	lpd
		dict set xppu	FFFC0000	addr	lpd
		dict set xppu	FE800000	addr	lpd
		dict set xppu	FFE40000	addr	lpd
		dict set xppu	FFE00000	addr	lpd
		dict set xppu	FFE90000	addr	lpd
		dict set xppu	FFEA0000	addr	lpd
		dict set xppu	FFEC0000	addr	lpd
		dict set xppu	FFB80000	addr	lpd
		dict set xppu	FCFE0000	addr	lpd
		dict set xppu	FCFC0000	addr	lpd
		dict set xppu	FCF80000	addr	lpd
		dict set xppu	FCF00000	addr	lpd
		dict set xppu	FCE00000	addr	lpd
		dict set xppu	FCC00000	addr	lpd
		dict set xppu	FC800000	addr	lpd
		dict set xppu	FC000000	addr	lpd
		dict set xppu	F0000000	addr	lpd
		dict set xppu	C0000000	addr	pmc
		dict set xppu	FB000000	addr	lpd
		dict set xppu	E0000000	addr	lpd
		dict set xppu	100000000	addr	lpd
		dict set xppu	1B700000000	addr	lpd
		dict set xppu	200000000	addr	lpd
		dict set xppu	1B600000000	addr	lpd
		dict set xppu	600000000	addr	lpd
		dict set xppu	1B400000000	addr	lpd
		dict set xppu	1B000000000	addr	lpd
		dict set xppu	800000000	addr	lpd
		dict set xppu	1A000000000	addr	lpd
		dict set xppu	18000000000	addr	lpd
		dict set xppu	8000000000	addr	lpd
		dict set xppu	C000000000	addr	lpd
		dict set xppu	14000000000	addr	lpd
		dict set xppu	10000000000	addr	lpd
		dict set xppu	50000000000	addr	lpd
		dict set xppu	20000000000	addr	lpd
		dict set xppu	60000000000	addr	lpd
		dict set xppu	80000000000	addr	lpd
		dict set xppu	FE400000	addr	lpd
		dict set xppu	FE5F0000	addr	lpd
		dict set xppu	180000		addr	lpd
		dict set xppu	80180000	addr	lpd
		dict set xppu	80000		addr	pmc
		dict set xppu	80080000	addr	pmc
		dict set xppu	F0800000	addr	pmc
		dict set xppu	F11A0000	addr	pmc
		dict set xppu	F11F0000	addr	pmc
		dict set xppu	F1160000	addr	pmc
		dict set xppu	F1180000	addr	pmc
		dict set xppu	F1220000	addr	pmc
		dict set xppu	F1330000	addr	pmc
		dict set xppu	F15A0000	addr	pmc
		dict set xppu	F1580000	addr	pmc
		dict set xppu	F1340000	addr	pmc
		dict set xppu	F1380000	addr	pmc
		dict set xppu	F1500000	addr	pmc
		dict set xppu	F1400000	addr	pmc
		dict set xppu	F1260000	addr	pmc
		dict set xppu	F1100000	addr	pmc
		dict set xppu	F0100000	addr	pmc
		dict set xppu	F0240000	addr	pmc
		dict set xppu	F0200000	addr	pmc
		dict set xppu	F0300000	addr	pmc
		dict set xppu	F11E0000	addr	pmc
		dict set xppu	F1200000	addr	pmc
		dict set xppu	F11C0000	addr	pmc
		dict set xppu	F11D0000	addr	pmc
		dict set xppu	F1210000	addr	pmc
		dict set xppu	F1230000	addr	pmc
		dict set xppu	F12F0000	addr	pmc
		dict set xppu	F1310000	addr	pmc
		dict set xppu	F1300000	addr	npi
		dict set xppu	F12B0000	addr	pmc
		dict set xppu	F12E0000	addr	pmc
		dict set xppu	F12C0000	addr	pmc
		dict set xppu	F1F80000	addr	pmc
		dict set xppu	F1240000	addr	pmc
		dict set xppu	F1000000	addr	pmc
		dict set xppu	F6000000	addr	pmc
		dict set xppu	F1110000	addr	pmc
		dict set xppu	F1120000	addr	pmc
		dict set xppu	F1140000	addr	pmc
		dict set xppu	F2000000	addr	pmc
		dict set xppu	F0110000	addr	pmc
		dict set xppu	F0310000	addr	pmc
		dict set xppu	F12A0000	addr	pmc
		dict set xppu	F2100000	addr	pmc
		dict set xppu	F1270000	addr	pmc
		dict set xppu	F1280000	addr	pmc
		dict set xppu	F9100000	addr	pmc
		dict set xppu	F9200000	addr	pmc
		dict set xppu	F9400000	addr	pmc
		dict set xppu	F9800000	addr	pmc
		dict set xppu	FA000000	addr	pmc
		dict set xppu	A0000000	addr	pmc
		dict set xppu	120000000	addr	pmc
		dict set xppu	140000000	addr	pmc
		dict set xppu	180000000	addr	pmc
		dict set xppu	1B780000000	addr	pmc
		dict set xppu	300000000	addr	pmc
		dict set xppu	1B800000000	addr	pmc
		dict set xppu	1000000000	addr	pmc
		dict set xppu	2000000000	addr	pmc
		dict set xppu	4000000000	addr	pmc
		dict set xppu	1C000000000	addr	pmc
		dict set xppu	F1320000	addr	pmc
		dict set xppu	FD360000	addr	lpd
		dict set xppu	FD380000	addr	lpd
		dict set xppu	FD5C0000	addr	lpd
		dict set xppu	FD1A0000	addr	lpd
		dict set xppu	FD2C0000	addr	lpd
		dict set xppu	FD1C0000	addr	lpd
		dict set xppu	FD280000	addr	lpd
		dict set xppu	FD200000	addr	lpd
		dict set xppu	FD370000	addr	lpd
		dict set xppu	FD390000	addr	lpd
		dict set xppu	FD5E0000	addr	lpd
		dict set xppu	FD5F0000	addr	lpd
		dict set xppu	FD4D0000	addr	lpd
		dict set xppu	FD610000	addr	lpd
		dict set xppu	FD690000	addr	lpd
		dict set xppu	FD700000	addr	lpd
		dict set xppu	AC000000	addr	lpd
		dict set xppu	FD800000	addr	lpd
		dict set xppu	FFF00000	addr	lpd
		dict set xppu	FD620000	addr	lpd
		dict set xppu	380000		addr	lpd
		dict set xppu	80380000	addr	lpd
		dict set xppu	70000000000	addr	lpd
		dict set xppu	FF010000	addr	lpd
		dict set xppu	FF020000	addr	lpd
		dict set xppu	FF030000	addr	lpd
		dict set xppu	FF040000	addr	lpd
		dict set xppu	FF050000	addr	lpd
		dict set xppu	FF060000	addr	lpd
		dict set xppu	FF070000	addr	lpd
		dict set xppu	FF080000	addr	lpd
		dict set xppu	FF090000	addr	lpd
		dict set xppu	FF0A0000	addr	lpd
		dict set xppu	FF0B0000	addr	lpd
		dict set xppu	FF0C0000	addr	lpd
		dict set xppu	FF0D0000	addr	lpd
		dict set xppu	FF0E0000	addr	lpd
		dict set xppu	FF0F0000	addr	lpd
		dict set xppu	FF100000	addr	lpd
		dict set xppu	FF110000	addr	lpd
		dict set xppu	FF120000	addr	lpd
		dict set xppu	FF130000	addr	lpd
		dict set xppu	FF140000	addr	lpd
		dict set xppu	FF150000	addr	lpd
		dict set xppu	FF160000	addr	lpd
		dict set xppu	FF170000	addr	lpd
		dict set xppu	FF180000	addr	lpd
		dict set xppu	FF190000	addr	lpd
		dict set xppu	FF1A0000	addr	lpd
		dict set xppu	FF1B0000	addr	lpd
		dict set xppu	FF1C0000	addr	lpd
		dict set xppu	FF1D0000	addr	lpd
		dict set xppu	FF1E0000	addr	lpd
		dict set xppu	FF1F0000	addr	lpd
		dict set xppu	FF210000	addr	lpd
		dict set xppu	FF220000	addr	lpd
		dict set xppu	FF230000	addr	lpd
		dict set xppu	FF240000	addr	lpd
		dict set xppu	FF250000	addr	lpd
		dict set xppu	FF260000	addr	lpd
		dict set xppu	FF270000	addr	lpd
		dict set xppu	FF280000	addr	lpd
		dict set xppu	FF290000	addr	lpd
		dict set xppu	FF2A0000	addr	lpd
		dict set xppu	FF2B0000	addr	lpd
		dict set xppu	FF2C0000	addr	lpd
		dict set xppu	FF2D0000	addr	lpd
		dict set xppu	FF2E0000	addr	lpd
		dict set xppu	FF2F0000	addr	lpd
		dict set xppu	FF310000	addr	lpd
		dict set xppu	FF320000	addr	lpd
		dict set xppu	FF330000	addr	lpd
		dict set xppu	FF340000	addr	lpd
		dict set xppu	FF350000	addr	lpd
		dict set xppu	FF360000	addr	lpd
		dict set xppu	FF370000	addr	lpd
		dict set xppu	FF380000	addr	lpd
		dict set xppu	FF390000	addr	lpd
		dict set xppu	FF3A0000	addr	lpd
		dict set xppu	FF3B0000	addr	lpd
		dict set xppu	FF3C0000	addr	lpd
		dict set xppu	FF3D0000	addr	lpd
		dict set xppu	FF3E0000	addr	lpd
		dict set xppu	FF3F0000	addr	lpd
		dict set xppu	FF400000	addr	lpd
		dict set xppu	FF430000	addr	lpd
		dict set xppu	FF450000	addr	lpd
		dict set xppu	FF460000	addr	lpd
		dict set xppu	FF470000	addr	lpd
		dict set xppu	FF490000	addr	lpd
		dict set xppu	FF4A0000	addr	lpd
		dict set xppu	FF4B0000	addr	lpd
		dict set xppu	FF4C0000	addr	lpd
		dict set xppu	FF4E0000	addr	lpd
		dict set xppu	FF4F0000	addr	lpd
		dict set xppu	FF530000	addr	lpd
		dict set xppu	FF550000	addr	lpd
		dict set xppu	FF560000	addr	lpd
		dict set xppu	FF570000	addr	lpd
		dict set xppu	FF580000	addr	lpd
		dict set xppu	FF590000	addr	lpd
		dict set xppu	FF5A0000	addr	lpd
		dict set xppu	FF5B0000	addr	lpd
		dict set xppu	FF5C0000	addr	lpd
		dict set xppu	FF5D0000	addr	lpd
		dict set xppu	FF5F0000	addr	lpd
		dict set xppu	FF610000	addr	lpd
		dict set xppu	FF620000	addr	lpd
		dict set xppu	FF630000	addr	lpd
		dict set xppu	FF640000	addr	lpd
		dict set xppu	FF650000	addr	lpd
		dict set xppu	FF660000	addr	lpd
		dict set xppu	FF670000	addr	lpd
		dict set xppu	FF680000	addr	lpd
		dict set xppu	FF690000	addr	lpd
		dict set xppu	FF6A0000	addr	lpd
		dict set xppu	FF6B0000	addr	lpd
		dict set xppu	FF6C0000	addr	lpd
		dict set xppu	FF6D0000	addr	lpd
		dict set xppu	FF6E0000	addr	lpd
		dict set xppu	FF6F0000	addr	lpd
		dict set xppu	FF700000	addr	lpd
		dict set xppu	FF710000	addr	lpd
		dict set xppu	FF720000	addr	lpd
		dict set xppu	FF730000	addr	lpd
		dict set xppu	FF740000	addr	lpd
		dict set xppu	FF750000	addr	lpd
		dict set xppu	FF760000	addr	lpd
		dict set xppu	FF770000	addr	lpd
		dict set xppu	FF780000	addr	lpd
		dict set xppu	FF790000	addr	lpd
		dict set xppu	FF7A0000	addr	lpd
		dict set xppu	FF7B0000	addr	lpd
		dict set xppu	FF7C0000	addr	lpd
		dict set xppu	FF7D0000	addr	lpd
		dict set xppu	FF7E0000	addr	lpd
		dict set xppu	FF7F0000	addr	lpd
		dict set xppu	FF810000	addr	lpd
		dict set xppu	FF820000	addr	lpd
		dict set xppu	FF830000	addr	lpd
		dict set xppu	FF840000	addr	lpd
		dict set xppu	FF850000	addr	lpd
		dict set xppu	FF860000	addr	lpd
		dict set xppu	FF870000	addr	lpd
		dict set xppu	FF890000	addr	lpd
		dict set xppu	FF8A0000	addr	lpd
		dict set xppu	FF8B0000	addr	lpd
		dict set xppu	FF8D0000	addr	lpd
		dict set xppu	FF8F0000	addr	lpd
		dict set xppu	FF910000	addr	lpd
		dict set xppu	FF920000	addr	lpd
		dict set xppu	FF930000	addr	lpd
		dict set xppu	FF950000	addr	lpd
		dict set xppu	FF9F0000	addr	lpd
		dict set xppu	FFA00000	addr	lpd
		dict set xppu	FFA10000	addr	lpd
		dict set xppu	FFA20000	addr	lpd
		dict set xppu	FFA30000	addr	lpd
		dict set xppu	FFA40000	addr	lpd
		dict set xppu	FFA50000	addr	lpd
		dict set xppu	FFA60000	addr	lpd
		dict set xppu	FFA70000	addr	lpd
		dict set xppu	FFA90000	addr	lpd
		dict set xppu	FFAA0000	addr	lpd
		dict set xppu	FFAB0000	addr	lpd
		dict set xppu	FFAC0000	addr	lpd
		dict set xppu	FFAD0000	addr	lpd
		dict set xppu	FFAE0000	addr	lpd
		dict set xppu	FFAF0000	addr	lpd
		dict set xppu	FFB00000	addr	lpd
		dict set xppu	FFB10000	addr	lpd
		dict set xppu	FFB20000	addr	lpd
		dict set xppu	FFB30000	addr	lpd
		dict set xppu	FFB40000	addr	lpd
		dict set xppu	FFB50000	addr	lpd
		dict set xppu	FFB60000	addr	lpd
		dict set xppu	FFB70000	addr	lpd
		dict set xppu	FFB90000	addr	lpd
		dict set xppu	FFBA0000	addr	lpd
		dict set xppu	FFBB0000	addr	lpd
		dict set xppu	FFBC0000	addr	lpd
		dict set xppu	FFBD0000	addr	lpd
		dict set xppu	FFBE0000	addr	lpd
		dict set xppu	FFBF0000	addr	lpd
		dict set xppu	FFC10000	addr	lpd
		dict set xppu	FFC20000	addr	lpd
		dict set xppu	FFC30000	addr	lpd
		dict set xppu	FFC40000	addr	lpd
		dict set xppu	FFC50000	addr	lpd
		dict set xppu	FFC60000	addr	lpd
		dict set xppu	FFC70000	addr	lpd
		dict set xppu	FFC80000	addr	lpd
		dict set xppu	FFC90000	addr	lpd
		dict set xppu	FFCA0000	addr	lpd
		dict set xppu	FFCB0000	addr	lpd
		dict set xppu	FFCC0000	addr	lpd
		dict set xppu	FFCD0000	addr	lpd
		dict set xppu	FFCE0000	addr	lpd
		dict set xppu	FFCF0000	addr	lpd
		dict set xppu	FFD00000	addr	lpd
		dict set xppu	FFD10000	addr	lpd
		dict set xppu	FFD20000	addr	lpd
		dict set xppu	FFD30000	addr	lpd
		dict set xppu	FFD40000	addr	lpd
		dict set xppu	FFD50000	addr	lpd
		dict set xppu	FFD60000	addr	lpd
		dict set xppu	FFD70000	addr	lpd
		dict set xppu	FFD80000	addr	lpd
		dict set xppu	FFD90000	addr	lpd
		dict set xppu	FFDA0000	addr	lpd
		dict set xppu	FFDB0000	addr	lpd
		dict set xppu	FFDC0000	addr	lpd
		dict set xppu	FFDD0000	addr	lpd
		dict set xppu	FFDE0000	addr	lpd
		dict set xppu	FFDF0000	addr	lpd
		dict set xppu	FFE10000	addr	lpd
		dict set xppu	FFE20000	addr	lpd
		dict set xppu	FFE30000	addr	lpd
		dict set xppu	FFE50000	addr	lpd
		dict set xppu	FFE60000	addr	lpd
		dict set xppu	FFE70000	addr	lpd
		dict set xppu	FFE80000	addr	lpd
		dict set xppu	FFEB0000	addr	lpd
		dict set xppu	FFED0000	addr	lpd
		dict set xppu	FFEE0000	addr	lpd
		dict set xppu	FFEF0000	addr	lpd
		dict set xppu	FFF10000	addr	lpd
		dict set xppu	FFF20000	addr	lpd
		dict set xppu	FFF30000	addr	lpd
		dict set xppu	FFF40000	addr	lpd
		dict set xppu	FFF50000	addr	lpd
		dict set xppu	FFF60000	addr	lpd
		dict set xppu	FFF70000	addr	lpd
		dict set xppu	FFF80000	addr	lpd
		dict set xppu	FFF90000	addr	lpd
		dict set xppu	FFFA0000	addr	lpd
		dict set xppu	FFFB0000	addr	lpd
		dict set xppu	FFFD0000	addr	lpd
		dict set xppu	FFFE0000	addr	lpd
		dict set xppu	FFFF0000	addr	lpd
		dict set xppu	FE100000	addr	lpd
		dict set xppu	FE300000	addr	lpd
		dict set xppu	FE500000	addr	lpd
		dict set xppu	FE700000	addr	lpd
		dict set xppu	FE900000	addr	lpd
		dict set xppu	FEA00000	addr	lpd
		dict set xppu	FEB00000	addr	lpd
		dict set xppu	FEC00000	addr	lpd
		dict set xppu	FED00000	addr	lpd
		dict set xppu	FEE00000	addr	lpd
		dict set xppu	FEF00000	addr	lpd
		dict set xppu	F1010000	addr	pmc
		dict set xppu	F1020000	addr	pmc
		dict set xppu	F1030000	addr	pmc
		dict set xppu	F1040000	addr	pmc
		dict set xppu	F1050000	addr	pmc
		dict set xppu	F1060000	addr	pmc
		dict set xppu	F1070000	addr	pmc
		dict set xppu	F1080000	addr	pmc
		dict set xppu	F1090000	addr	pmc
		dict set xppu	F10A0000	addr	pmc
		dict set xppu	F10B0000	addr	pmc
		dict set xppu	F10C0000	addr	pmc
		dict set xppu	F10D0000	addr	pmc
		dict set xppu	F10E0000	addr	pmc
		dict set xppu	F10F0000	addr	pmc
		dict set xppu	F1130000	addr	pmc
		dict set xppu	F1150000	addr	pmc
		dict set xppu	F1170000	addr	pmc
		dict set xppu	F1190000	addr	pmc
		dict set xppu	F11B0000	addr	pmc
		dict set xppu	F1250000	addr	pmc
		dict set xppu	F1290000	addr	pmc
		dict set xppu	F12D0000	addr	pmc
		dict set xppu	F1350000	addr	pmc
		dict set xppu	F1360000	addr	pmc
		dict set xppu	F1370000	addr	pmc
		dict set xppu	F1390000	addr	pmc
		dict set xppu	F13A0000	addr	pmc
		dict set xppu	F13B0000	addr	pmc
		dict set xppu	F13C0000	addr	pmc
		dict set xppu	F13D0000	addr	pmc
		dict set xppu	F13E0000	addr	pmc
		dict set xppu	F13F0000	addr	pmc
		dict set xppu	F1410000	addr	pmc
		dict set xppu	F1420000	addr	pmc
		dict set xppu	F1430000	addr	pmc
		dict set xppu	F1440000	addr	pmc
		dict set xppu	F1450000	addr	pmc
		dict set xppu	F1460000	addr	pmc
		dict set xppu	F1470000	addr	pmc
		dict set xppu	F1480000	addr	pmc
		dict set xppu	F1490000	addr	pmc
		dict set xppu	F14A0000	addr	pmc
		dict set xppu	F14B0000	addr	pmc
		dict set xppu	F14C0000	addr	pmc
		dict set xppu	F14D0000	addr	pmc
		dict set xppu	F14E0000	addr	pmc
		dict set xppu	F14F0000	addr	pmc
		dict set xppu	F1510000	addr	pmc
		dict set xppu	F1520000	addr	pmc
		dict set xppu	F1530000	addr	pmc
		dict set xppu	F1540000	addr	pmc
		dict set xppu	F1550000	addr	pmc
		dict set xppu	F1560000	addr	pmc
		dict set xppu	F1570000	addr	pmc
		dict set xppu	F1590000	addr	pmc
		dict set xppu	F15B0000	addr	pmc
		dict set xppu	F15C0000	addr	pmc
		dict set xppu	F15D0000	addr	pmc
		dict set xppu	F15E0000	addr	pmc
		dict set xppu	F15F0000	addr	pmc
		dict set xppu	F1600000	addr	pmc
		dict set xppu	F1610000	addr	pmc
		dict set xppu	F1620000	addr	pmc
		dict set xppu	F1630000	addr	pmc
		dict set xppu	F1640000	addr	pmc
		dict set xppu	F1650000	addr	pmc
		dict set xppu	F1660000	addr	pmc
		dict set xppu	F1670000	addr	pmc
		dict set xppu	F1680000	addr	pmc
		dict set xppu	F1690000	addr	pmc
		dict set xppu	F16A0000	addr	pmc
		dict set xppu	F16B0000	addr	pmc
		dict set xppu	F16C0000	addr	pmc
		dict set xppu	F16D0000	addr	pmc
		dict set xppu	F16E0000	addr	pmc
		dict set xppu	F16F0000	addr	pmc
		dict set xppu	F1700000	addr	pmc
		dict set xppu	F1710000	addr	pmc
		dict set xppu	F1720000	addr	pmc
		dict set xppu	F1730000	addr	pmc
		dict set xppu	F1740000	addr	pmc
		dict set xppu	F1750000	addr	pmc
		dict set xppu	F1760000	addr	pmc
		dict set xppu	F1770000	addr	pmc
		dict set xppu	F1780000	addr	pmc
		dict set xppu	F1790000	addr	pmc
		dict set xppu	F17A0000	addr	pmc
		dict set xppu	F17B0000	addr	pmc
		dict set xppu	F17C0000	addr	pmc
		dict set xppu	F17D0000	addr	pmc
		dict set xppu	F17E0000	addr	pmc
		dict set xppu	F17F0000	addr	pmc
		dict set xppu	F1800000	addr	pmc
		dict set xppu	F1810000	addr	pmc
		dict set xppu	F1820000	addr	pmc
		dict set xppu	F1830000	addr	pmc
		dict set xppu	F1840000	addr	pmc
		dict set xppu	F1850000	addr	pmc
		dict set xppu	F1860000	addr	pmc
		dict set xppu	F1870000	addr	pmc
		dict set xppu	F1880000	addr	pmc
		dict set xppu	F1890000	addr	pmc
		dict set xppu	F18A0000	addr	pmc
		dict set xppu	F18B0000	addr	pmc
		dict set xppu	F18C0000	addr	pmc
		dict set xppu	F18D0000	addr	pmc
		dict set xppu	F18E0000	addr	pmc
		dict set xppu	F18F0000	addr	pmc
		dict set xppu	F1900000	addr	pmc
		dict set xppu	F1910000	addr	pmc
		dict set xppu	F1920000	addr	pmc
		dict set xppu	F1930000	addr	pmc
		dict set xppu	F1940000	addr	pmc
		dict set xppu	F1950000	addr	pmc
		dict set xppu	F1960000	addr	pmc
		dict set xppu	F1970000	addr	pmc
		dict set xppu	F1980000	addr	pmc
		dict set xppu	F1990000	addr	pmc
		dict set xppu	F19A0000	addr	pmc
		dict set xppu	F19B0000	addr	pmc
		dict set xppu	F19C0000	addr	pmc
		dict set xppu	F19D0000	addr	pmc
		dict set xppu	F19E0000	addr	pmc
		dict set xppu	F19F0000	addr	pmc
		dict set xppu	F1A00000	addr	pmc
		dict set xppu	F1A10000	addr	pmc
		dict set xppu	F1A20000	addr	pmc
		dict set xppu	F1A30000	addr	pmc
		dict set xppu	F1A40000	addr	pmc
		dict set xppu	F1A50000	addr	pmc
		dict set xppu	F1A60000	addr	pmc
		dict set xppu	F1A70000	addr	pmc
		dict set xppu	F1A80000	addr	pmc
		dict set xppu	F1A90000	addr	pmc
		dict set xppu	F1AA0000	addr	pmc
		dict set xppu	F1AB0000	addr	pmc
		dict set xppu	F1AC0000	addr	pmc
		dict set xppu	F1AD0000	addr	pmc
		dict set xppu	F1AE0000	addr	pmc
		dict set xppu	F1AF0000	addr	pmc
		dict set xppu	F1B00000	addr	pmc
		dict set xppu	F1B10000	addr	pmc
		dict set xppu	F1B20000	addr	pmc
		dict set xppu	F1B30000	addr	pmc
		dict set xppu	F1B40000	addr	pmc
		dict set xppu	F1B50000	addr	pmc
		dict set xppu	F1B60000	addr	pmc
		dict set xppu	F1B70000	addr	pmc
		dict set xppu	F1B80000	addr	pmc
		dict set xppu	F1B90000	addr	pmc
		dict set xppu	F1BA0000	addr	pmc
		dict set xppu	F1BB0000	addr	pmc
		dict set xppu	F1BC0000	addr	pmc
		dict set xppu	F1BD0000	addr	pmc
		dict set xppu	F1BE0000	addr	pmc
		dict set xppu	F1BF0000	addr	pmc
		dict set xppu	F1C00000	addr	pmc
		dict set xppu	F1C10000	addr	pmc
		dict set xppu	F1C20000	addr	pmc
		dict set xppu	F1C30000	addr	pmc
		dict set xppu	F1C40000	addr	pmc
		dict set xppu	F1C50000	addr	pmc
		dict set xppu	F1C60000	addr	pmc
		dict set xppu	F1C70000	addr	pmc
		dict set xppu	F1C80000	addr	pmc
		dict set xppu	F1C90000	addr	pmc
		dict set xppu	F1CA0000	addr	pmc
		dict set xppu	F1CB0000	addr	pmc
		dict set xppu	F1CC0000	addr	pmc
		dict set xppu	F1CD0000	addr	pmc
		dict set xppu	F1CE0000	addr	pmc
		dict set xppu	F1CF0000	addr	pmc
		dict set xppu	F1D00000	addr	pmc
		dict set xppu	F1D10000	addr	pmc
		dict set xppu	F1D20000	addr	pmc
		dict set xppu	F1D30000	addr	pmc
		dict set xppu	F1D40000	addr	pmc
		dict set xppu	F1D50000	addr	pmc
		dict set xppu	F1D60000	addr	pmc
		dict set xppu	F1D70000	addr	pmc
		dict set xppu	F1D80000	addr	pmc
		dict set xppu	F1D90000	addr	pmc
		dict set xppu	F1DA0000	addr	pmc
		dict set xppu	F1DB0000	addr	pmc
		dict set xppu	F1DC0000	addr	pmc
		dict set xppu	F1DD0000	addr	pmc
		dict set xppu	F1DE0000	addr	pmc
		dict set xppu	F1DF0000	addr	pmc
		dict set xppu	F1E00000	addr	pmc
		dict set xppu	F1E10000	addr	pmc
		dict set xppu	F1E20000	addr	pmc
		dict set xppu	F1E30000	addr	pmc
		dict set xppu	F1E40000	addr	pmc
		dict set xppu	F1E50000	addr	pmc
		dict set xppu	F1E60000	addr	pmc
		dict set xppu	F1E70000	addr	pmc
		dict set xppu	F1E80000	addr	pmc
		dict set xppu	F1E90000	addr	pmc
		dict set xppu	F1EA0000	addr	pmc
		dict set xppu	F1EB0000	addr	pmc
		dict set xppu	F1EC0000	addr	pmc
		dict set xppu	F1ED0000	addr	pmc
		dict set xppu	F1EE0000	addr	pmc
		dict set xppu	F1EF0000	addr	pmc
		dict set xppu	F1F00000	addr	pmc
		dict set xppu	F1F10000	addr	pmc
		dict set xppu	F1F20000	addr	pmc
		dict set xppu	F1F30000	addr	pmc
		dict set xppu	F1F40000	addr	pmc
		dict set xppu	F1F50000	addr	pmc
		dict set xppu	F1F60000	addr	pmc
		dict set xppu	F1F70000	addr	pmc
		dict set xppu	F1F90000	addr	pmc
		dict set xppu	F1FA0000	addr	pmc
		dict set xppu	F1FB0000	addr	pmc
		dict set xppu	F1FC0000	addr	pmc
		dict set xppu	F1FD0000	addr	pmc
		dict set xppu	F1FE0000	addr	pmc
		dict set xppu	F1FF0000	addr	pmc
		dict set xppu	F0400000	addr	pmc
		dict set xppu	F0500000	addr	pmc
		dict set xppu	F0600000	addr	pmc
		dict set xppu	F0700000	addr	pmc
		dict set xppu	F0900000	addr	pmc
		dict set xppu	F0A00000	addr	pmc
		dict set xppu	F0B00000	addr	pmc
		dict set xppu	F0C00000	addr	pmc
		dict set xppu	F0D00000	addr	pmc
		dict set xppu	F0E00000	addr	pmc
		dict set xppu	F0F00000	addr	pmc
		dict set xppu	F6010000	addr	npi
		dict set xppu	F6020000	addr	npi
		dict set xppu	F6030000	addr	npi
		dict set xppu	F6040000	addr	npi
		dict set xppu	F6050000	addr	npi
		dict set xppu	F6060000	addr	npi
		dict set xppu	F6070000	addr	npi
		dict set xppu	F6080000	addr	npi
		dict set xppu	F6090000	addr	npi
		dict set xppu	F60A0000	addr	npi
		dict set xppu	F60B0000	addr	npi
		dict set xppu	F60C0000	addr	npi
		dict set xppu	F60D0000	addr	npi
		dict set xppu	F60E0000	addr	npi
		dict set xppu	F60F0000	addr	npi
		dict set xppu	F6100000	addr	npi
		dict set xppu	F6110000	addr	npi
		dict set xppu	F6120000	addr	npi
		dict set xppu	F6130000	addr	npi
		dict set xppu	F6140000	addr	npi
		dict set xppu	F6150000	addr	npi
		dict set xppu	F6160000	addr	npi
		dict set xppu	F6170000	addr	npi
		dict set xppu	F6180000	addr	npi
		dict set xppu	F6190000	addr	npi
		dict set xppu	F61A0000	addr	npi
		dict set xppu	F61B0000	addr	npi
		dict set xppu	F61C0000	addr	npi
		dict set xppu	F61D0000	addr	npi
		dict set xppu	F61E0000	addr	npi
		dict set xppu	F61F0000	addr	npi
		dict set xppu	F6200000	addr	npi
		dict set xppu	F6210000	addr	npi
		dict set xppu	F6220000	addr	npi
		dict set xppu	F6230000	addr	npi
		dict set xppu	F6240000	addr	npi
		dict set xppu	F6250000	addr	npi
		dict set xppu	F6260000	addr	npi
		dict set xppu	F6270000	addr	npi
		dict set xppu	F6280000	addr	npi
		dict set xppu	F6290000	addr	npi
		dict set xppu	F62A0000	addr	npi
		dict set xppu	F62B0000	addr	npi
		dict set xppu	F62C0000	addr	npi
		dict set xppu	F62D0000	addr	npi
		dict set xppu	F62E0000	addr	npi
		dict set xppu	F62F0000	addr	npi
		dict set xppu	F6300000	addr	npi
		dict set xppu	F6310000	addr	npi
		dict set xppu	F6320000	addr	npi
		dict set xppu	F6330000	addr	npi
		dict set xppu	F6340000	addr	npi
		dict set xppu	F6350000	addr	npi
		dict set xppu	F6360000	addr	npi
		dict set xppu	F6370000	addr	npi
		dict set xppu	F6380000	addr	npi
		dict set xppu	F6390000	addr	npi
		dict set xppu	F63A0000	addr	npi
		dict set xppu	F63B0000	addr	npi
		dict set xppu	F63C0000	addr	npi
		dict set xppu	F63D0000	addr	npi
		dict set xppu	F63E0000	addr	npi
		dict set xppu	F63F0000	addr	npi
		dict set xppu	F6400000	addr	npi
		dict set xppu	F6410000	addr	npi
		dict set xppu	F6420000	addr	npi
		dict set xppu	F6430000	addr	npi
		dict set xppu	F6440000	addr	npi
		dict set xppu	F6450000	addr	npi
		dict set xppu	F6460000	addr	npi
		dict set xppu	F6470000	addr	npi
		dict set xppu	F6480000	addr	npi
		dict set xppu	F6490000	addr	npi
		dict set xppu	F64A0000	addr	npi
		dict set xppu	F64B0000	addr	npi
		dict set xppu	F64C0000	addr	npi
		dict set xppu	F64D0000	addr	npi
		dict set xppu	F64E0000	addr	npi
		dict set xppu	F64F0000	addr	npi
		dict set xppu	F6500000	addr	npi
		dict set xppu	F6510000	addr	npi
		dict set xppu	F6520000	addr	npi
		dict set xppu	F6530000	addr	npi
		dict set xppu	F6540000	addr	npi
		dict set xppu	F6550000	addr	npi
		dict set xppu	F6560000	addr	npi
		dict set xppu	F6570000	addr	npi
		dict set xppu	F6580000	addr	npi
		dict set xppu	F6590000	addr	npi
		dict set xppu	F65A0000	addr	npi
		dict set xppu	F65B0000	addr	npi
		dict set xppu	F65C0000	addr	npi
		dict set xppu	F65D0000	addr	npi
		dict set xppu	F65E0000	addr	npi
		dict set xppu	F65F0000	addr	npi
		dict set xppu	F6600000	addr	npi
		dict set xppu	F6610000	addr	npi
		dict set xppu	F6620000	addr	npi
		dict set xppu	F6630000	addr	npi
		dict set xppu	F6640000	addr	npi
		dict set xppu	F6650000	addr	npi
		dict set xppu	F6660000	addr	npi
		dict set xppu	F6670000	addr	npi
		dict set xppu	F6680000	addr	npi
		dict set xppu	F6690000	addr	npi
		dict set xppu	F66A0000	addr	npi
		dict set xppu	F66B0000	addr	npi
		dict set xppu	F66C0000	addr	npi
		dict set xppu	F66D0000	addr	npi
		dict set xppu	F66E0000	addr	npi
		dict set xppu	F66F0000	addr	npi
		dict set xppu	F6700000	addr	npi
		dict set xppu	F6710000	addr	npi
		dict set xppu	F6720000	addr	npi
		dict set xppu	F6730000	addr	npi
		dict set xppu	F6740000	addr	npi
		dict set xppu	F6750000	addr	npi
		dict set xppu	F6760000	addr	npi
		dict set xppu	F6770000	addr	npi
		dict set xppu	F6780000	addr	npi
		dict set xppu	F6790000	addr	npi
		dict set xppu	F67A0000	addr	npi
		dict set xppu	F67B0000	addr	npi
		dict set xppu	F67C0000	addr	npi
		dict set xppu	F67D0000	addr	npi
		dict set xppu	F67E0000	addr	npi
		dict set xppu	F67F0000	addr	npi
		dict set xppu	F6800000	addr	npi
		dict set xppu	F6810000	addr	npi
		dict set xppu	F6820000	addr	npi
		dict set xppu	F6830000	addr	npi
		dict set xppu	F6840000	addr	npi
		dict set xppu	F6850000	addr	npi
		dict set xppu	F6860000	addr	npi
		dict set xppu	F6870000	addr	npi
		dict set xppu	F6880000	addr	npi
		dict set xppu	F6890000	addr	npi
		dict set xppu	F68A0000	addr	npi
		dict set xppu	F68B0000	addr	npi
		dict set xppu	F68C0000	addr	npi
		dict set xppu	F68D0000	addr	npi
		dict set xppu	F68E0000	addr	npi
		dict set xppu	F68F0000	addr	npi
		dict set xppu	F6900000	addr	npi
		dict set xppu	F6910000	addr	npi
		dict set xppu	F6920000	addr	npi
		dict set xppu	F6930000	addr	npi
		dict set xppu	F6940000	addr	npi
		dict set xppu	F6950000	addr	npi
		dict set xppu	F6960000	addr	npi
		dict set xppu	F6970000	addr	npi
		dict set xppu	F6980000	addr	npi
		dict set xppu	F6990000	addr	npi
		dict set xppu	F69A0000	addr	npi
		dict set xppu	F69B0000	addr	npi
		dict set xppu	F69C0000	addr	npi
		dict set xppu	F69D0000	addr	npi
		dict set xppu	F69E0000	addr	npi
		dict set xppu	F69F0000	addr	npi
		dict set xppu	F6A00000	addr	npi
		dict set xppu	F6A10000	addr	npi
		dict set xppu	F6A20000	addr	npi
		dict set xppu	F6A30000	addr	npi
		dict set xppu	F6A40000	addr	npi
		dict set xppu	F6A50000	addr	npi
		dict set xppu	F6A60000	addr	npi
		dict set xppu	F6A70000	addr	npi
		dict set xppu	F6A80000	addr	npi
		dict set xppu	F6A90000	addr	npi
		dict set xppu	F6AA0000	addr	npi
		dict set xppu	F6AB0000	addr	npi
		dict set xppu	F6AC0000	addr	npi
		dict set xppu	F6AD0000	addr	npi
		dict set xppu	F6AE0000	addr	npi
		dict set xppu	F6AF0000	addr	npi
		dict set xppu	F6B00000	addr	npi
		dict set xppu	F6B10000	addr	npi
		dict set xppu	F6B20000	addr	npi
		dict set xppu	F6B30000	addr	npi
		dict set xppu	F6B40000	addr	npi
		dict set xppu	F6B50000	addr	npi
		dict set xppu	F6B60000	addr	npi
		dict set xppu	F6B70000	addr	npi
		dict set xppu	F6B80000	addr	npi
		dict set xppu	F6B90000	addr	npi
		dict set xppu	F6BA0000	addr	npi
		dict set xppu	F6BB0000	addr	npi
		dict set xppu	F6BC0000	addr	npi
		dict set xppu	F6BD0000	addr	npi
		dict set xppu	F6BE0000	addr	npi
		dict set xppu	F6BF0000	addr	npi
		dict set xppu	F6C00000	addr	npi
		dict set xppu	F6C10000	addr	npi
		dict set xppu	F6C20000	addr	npi
		dict set xppu	F6C30000	addr	npi
		dict set xppu	F6C40000	addr	npi
		dict set xppu	F6C50000	addr	npi
		dict set xppu	F6C60000	addr	npi
		dict set xppu	F6C70000	addr	npi
		dict set xppu	F6C80000	addr	npi
		dict set xppu	F6C90000	addr	npi
		dict set xppu	F6CA0000	addr	npi
		dict set xppu	F6CB0000	addr	npi
		dict set xppu	F6CC0000	addr	npi
		dict set xppu	F6CD0000	addr	npi
		dict set xppu	F6CE0000	addr	npi
		dict set xppu	F6CF0000	addr	npi
		dict set xppu	F6D00000	addr	npi
		dict set xppu	F6D10000	addr	npi
		dict set xppu	F6D20000	addr	npi
		dict set xppu	F6D30000	addr	npi
		dict set xppu	F6D40000	addr	npi
		dict set xppu	F6D50000	addr	npi
		dict set xppu	F6D60000	addr	npi
		dict set xppu	F6D70000	addr	npi
		dict set xppu	F6D80000	addr	npi
		dict set xppu	F6D90000	addr	npi
		dict set xppu	F6DA0000	addr	npi
		dict set xppu	F6DB0000	addr	npi
		dict set xppu	F6DC0000	addr	npi
		dict set xppu	F6DD0000	addr	npi
		dict set xppu	F6DE0000	addr	npi
		dict set xppu	F6DF0000	addr	npi
		dict set xppu	F6E00000	addr	npi
		dict set xppu	F6E10000	addr	npi
		dict set xppu	F6E20000	addr	npi
		dict set xppu	F6E30000	addr	npi
		dict set xppu	F6E40000	addr	npi
		dict set xppu	F6E50000	addr	npi
		dict set xppu	F6E60000	addr	npi
		dict set xppu	F6E70000	addr	npi
		dict set xppu	F6E80000	addr	npi
		dict set xppu	F6E90000	addr	npi
		dict set xppu	F6EA0000	addr	npi
		dict set xppu	F6EB0000	addr	npi
		dict set xppu	F6EC0000	addr	npi
		dict set xppu	F6ED0000	addr	npi
		dict set xppu	F6EE0000	addr	npi
		dict set xppu	F6EF0000	addr	npi
		dict set xppu	F6F00000	addr	npi
		dict set xppu	F6F10000	addr	npi
		dict set xppu	F6F20000	addr	npi
		dict set xppu	F6F30000	addr	npi
		dict set xppu	F6F40000	addr	npi
		dict set xppu	F6F50000	addr	npi
		dict set xppu	F6F60000	addr	npi
		dict set xppu	F6F70000	addr	npi
		dict set xppu	F6F80000	addr	npi
		dict set xppu	F6F90000	addr	npi
		dict set xppu	F6FA0000	addr	npi
		dict set xppu	F6FB0000	addr	npi
		dict set xppu	F6FC0000	addr	npi
		dict set xppu	F6FD0000	addr	npi
		dict set xppu	F6FE0000	addr	npi
		dict set xppu	F6FF0000	addr	npi
		dict set xppu	F7000000	addr	npi
		dict set xppu	F7100000	addr	npi
		dict set xppu	F7200000	addr	npi
		dict set xppu	F7300000	addr	npi
		dict set xppu	F7400000	addr	npi
		dict set xppu	F7500000	addr	npi
		dict set xppu	F7600000	addr	npi
		dict set xppu	F7700000	addr	npi
		dict set xppu	F7800000	addr	npi
		dict set xppu	F7900000	addr	npi
		dict set xppu	F7A00000	addr	npi
		dict set xppu	F7B00000	addr	npi
		dict set xppu	F7C00000	addr	npi
		dict set xppu	F7D00000	addr	npi
		dict set xppu	F7E00000	addr	npi
		dict set xppu	F7F00000	addr	npi
		set baseaddr [string toupper $baseaddr]
		set tmp ""
		if {[catch {set tmp [dict get $xppu $baseaddr addr]} msg]} {
		}
		
		if {[string match -nocase $tmp "lpd"]} {
			set prop "lpd_xppu"
		}
		if {[string match -nocase $tmp "pmc"]} {
			set prop "pmc_xppu"
		}
		if {[string match -nocase $tmp "npi"]} {
			set prop "pmc_xppu_npi"
		}
		
		if {![string match -nocase $tmp ""]} {
			add_prop $node "firewall-0" $prop reference "pcw.dtsi"
		}
		set valid_list "psv_ethernet psv_pmc_sd psv_adma psv_pmc_dma psv_usb_xhci psv_pmc_qspi psv_pmc_ospi"
		set idlist [dict create]
		dict set idlist FF0C0000 id 0x234
		dict set idlist FF0D0000 id 0x235
		dict set idlist F1040000 id 0x242
		dict set idlist F1050000 id 0x243
		dict set idlist FFA80000 id 0x210
		dict set idlist FFA90000 id 0x212
		dict set idlist FFAA0000 id 0x214
		dict set idlist FFAB0000 id 0x216
		dict set idlist FFAC0000 id 0x218
		dict set idlist FFAD0000 id 0x21a
		dict set idlist FFAE0000 id 0x21c
		dict set idlist FFAF0000 id 0x21e
		dict set idlist FE200000 id 0x230
		dict set idlist F1030000 id 0x244
		
		set ip_name ""
		if {[catch {set ip_name [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]} msg]} {
		}
		if {![string match -nocase $ip_name ""]} {
			if {[lsearch $valid_list $ip_name] >=0} {
				if {![string match -nocase $tmp ""]} {
					set tmp ""
					if {[catch {set tmp [dict get $idlist $baseaddr id]} msg]} {
					}
					if {![string match -nocase $tmp ""]} {
						add_prop $node "bus-master-id" "&$prop $tmp" hexlist "pcw.dtsi"
					}
				}
			}	
		}

    } elseif {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
		dict set xppu FF000000 addr lpd
		dict set xppu FF010000 addr lpd
		dict set xppu FF020000 addr lpd
		dict set xppu FF030000 addr lpd
		dict set xppu FF040000 addr lpd
		dict set xppu FF050000 addr lpd
		dict set xppu FF060000 addr lpd
		dict set xppu FF070000 addr lpd
		dict set xppu FF080000 addr lpd
		dict set xppu FF090000 addr lpd
		dict set xppu FF0A0000 addr lpd
		dict set xppu FF0B0000 addr lpd
		dict set xppu FF0C0000 addr lpd
		dict set xppu FF0D0000 addr lpd
		dict set xppu FF0E0000 addr lpd
		dict set xppu FF0F0000 addr lpd
		dict set xppu FF100000 addr lpd
		dict set xppu FF110000 addr lpd
		dict set xppu FF120000 addr lpd
		dict set xppu FF130000 addr lpd
		dict set xppu FF140000 addr lpd
		dict set xppu FF150000 addr lpd
		dict set xppu FF160000 addr lpd
		dict set xppu FF170000 addr lpd
		dict set xppu FF180000 addr lpd
		dict set xppu FF190000 addr lpd
		dict set xppu FF1A0000 addr lpd
		dict set xppu FF1B0000 addr lpd
		dict set xppu FF1C0000 addr lpd
		dict set xppu FF1D0000 addr lpd
		dict set xppu FF1E0000 addr lpd
		dict set xppu FF1F0000 addr lpd
		dict set xppu FF200000 addr lpd
		dict set xppu FF210000 addr lpd
		dict set xppu FF220000 addr lpd
		dict set xppu FF230000 addr lpd
		dict set xppu FF240000 addr lpd
		dict set xppu FF250000 addr lpd
		dict set xppu FF260000 addr lpd
		dict set xppu FF270000 addr lpd
		dict set xppu FF280000 addr lpd
		dict set xppu FF290000 addr lpd
		dict set xppu FF2A0000 addr lpd
		dict set xppu FF2B0000 addr lpd
		dict set xppu FF2C0000 addr lpd
		dict set xppu FF2D0000 addr lpd
		dict set xppu FF2E0000 addr lpd
		dict set xppu FF2F0000 addr lpd
		dict set xppu FF300000 addr lpd
		dict set xppu FF310000 addr lpd
		dict set xppu FF320000 addr lpd
		dict set xppu FF330000 addr lpd
		dict set xppu FF340000 addr lpd
		dict set xppu FF350000 addr lpd
		dict set xppu FF360000 addr lpd
		dict set xppu FF370000 addr lpd
		dict set xppu FF380000 addr lpd
		dict set xppu FF390000 addr lpd
		dict set xppu FF3A0000 addr lpd
		dict set xppu FF3B0000 addr lpd
		dict set xppu FF3C0000 addr lpd
		dict set xppu FF3D0000 addr lpd
		dict set xppu FF3E0000 addr lpd
		dict set xppu FF3F0000 addr lpd
		dict set xppu FF400000 addr lpd
		dict set xppu FF410000 addr lpd
		dict set xppu FF420000 addr lpd
		dict set xppu FF430000 addr lpd
		dict set xppu FF440000 addr lpd
		dict set xppu FF450000 addr lpd
		dict set xppu FF460000 addr lpd
		dict set xppu FF470000 addr lpd
		dict set xppu FF480000 addr lpd
		dict set xppu FF490000 addr lpd
		dict set xppu FF4A0000 addr lpd
		dict set xppu FF4B0000 addr lpd
		dict set xppu FF4C0000 addr lpd
		dict set xppu FF4D0000 addr lpd
		dict set xppu FF4E0000 addr lpd
		dict set xppu FF4F0000 addr lpd
		dict set xppu FF500000 addr lpd
		dict set xppu FF510000 addr lpd
		dict set xppu FF520000 addr lpd
		dict set xppu FF530000 addr lpd
		dict set xppu FF540000 addr lpd
		dict set xppu FF550000 addr lpd
		dict set xppu FF560000 addr lpd
		dict set xppu FF570000 addr lpd
		dict set xppu FF580000 addr lpd
		dict set xppu FF590000 addr lpd
		dict set xppu FF5A0000 addr lpd
		dict set xppu FF5B0000 addr lpd
		dict set xppu FF5C0000 addr lpd
		dict set xppu FF5D0000 addr lpd
		dict set xppu FF5E0000 addr lpd
		dict set xppu FF5F0000 addr lpd
		dict set xppu FF600000 addr lpd
		dict set xppu FF610000 addr lpd
		dict set xppu FF620000 addr lpd
		dict set xppu FF630000 addr lpd
		dict set xppu FF640000 addr lpd
		dict set xppu FF650000 addr lpd
		dict set xppu FF660000 addr lpd
		dict set xppu FF670000 addr lpd
		dict set xppu FF680000 addr lpd
		dict set xppu FF690000 addr lpd
		dict set xppu FF6A0000 addr lpd
		dict set xppu FF6B0000 addr lpd
		dict set xppu FF6C0000 addr lpd
		dict set xppu FF6D0000 addr lpd
		dict set xppu FF6E0000 addr lpd
		dict set xppu FF6F0000 addr lpd
		dict set xppu FF700000 addr lpd
		dict set xppu FF710000 addr lpd
		dict set xppu FF720000 addr lpd
		dict set xppu FF730000 addr lpd
		dict set xppu FF740000 addr lpd
		dict set xppu FF750000 addr lpd
		dict set xppu FF760000 addr lpd
		dict set xppu FF770000 addr lpd
		dict set xppu FF780000 addr lpd
		dict set xppu FF790000 addr lpd
		dict set xppu FF7A0000 addr lpd
		dict set xppu FF7B0000 addr lpd
		dict set xppu FF7C0000 addr lpd
		dict set xppu FF7D0000 addr lpd
		dict set xppu FF7E0000 addr lpd
		dict set xppu FF7F0000 addr lpd
		dict set xppu FF800000 addr lpd
		dict set xppu FF810000 addr lpd
		dict set xppu FF820000 addr lpd
		dict set xppu FF830000 addr lpd
		dict set xppu FF840000 addr lpd
		dict set xppu FF850000 addr lpd
		dict set xppu FF860000 addr lpd
		dict set xppu FF870000 addr lpd
		dict set xppu FF880000 addr lpd
		dict set xppu FF890000 addr lpd
		dict set xppu FF8A0000 addr lpd
		dict set xppu FF8B0000 addr lpd
		dict set xppu FF8C0000 addr lpd
		dict set xppu FF8D0000 addr lpd
		dict set xppu FF8E0000 addr lpd
		dict set xppu FF8F0000 addr lpd
		dict set xppu FF900000 addr lpd
		dict set xppu FF910000 addr lpd
		dict set xppu FF920000 addr lpd
		dict set xppu FF930000 addr lpd
		dict set xppu FF940000 addr lpd
		dict set xppu FF950000 addr lpd
		dict set xppu FF960000 addr lpd
		dict set xppu FF970000 addr lpd
		dict set xppu FF980000 addr lpd
		dict set xppu FF990000 addr lpd
		dict set xppu FF9A0000 addr lpd
		dict set xppu FF9B0000 addr lpd
		dict set xppu FF9C0000 addr lpd
		dict set xppu FF9D0000 addr lpd
		dict set xppu FF9E0000 addr lpd
		dict set xppu FF9F0000 addr lpd
		dict set xppu FFA00000 addr lpd
		dict set xppu FFA10000 addr lpd
		dict set xppu FFA20000 addr lpd
		dict set xppu FFA30000 addr lpd
		dict set xppu FFA40000 addr lpd
		dict set xppu FFA50000 addr lpd
		dict set xppu FFA60000 addr lpd
		dict set xppu FFA70000 addr lpd
		dict set xppu FFA80000 addr lpd
		dict set xppu FFA90000 addr lpd
		dict set xppu FFAA0000 addr lpd
		dict set xppu FFAB0000 addr lpd
		dict set xppu FFAC0000 addr lpd
		dict set xppu FFAD0000 addr lpd
		dict set xppu FFAE0000 addr lpd
		dict set xppu FFAF0000 addr lpd
		dict set xppu FFB00000 addr lpd
		dict set xppu FFB10000 addr lpd
		dict set xppu FFB20000 addr lpd
		dict set xppu FFB30000 addr lpd
		dict set xppu FFB40000 addr lpd
		dict set xppu FFB50000 addr lpd
		dict set xppu FFB60000 addr lpd
		dict set xppu FFB70000 addr lpd
		dict set xppu FFB80000 addr lpd
		dict set xppu FFB90000 addr lpd
		dict set xppu FFBA0000 addr lpd
		dict set xppu FFBB0000 addr lpd
		dict set xppu FFBC0000 addr lpd
		dict set xppu FFBD0000 addr lpd
		dict set xppu FFBE0000 addr lpd
		dict set xppu FFBF0000 addr lpd
		dict set xppu FFC00000 addr lpd
		dict set xppu FFC10000 addr lpd
		dict set xppu FFC20000 addr lpd
		dict set xppu FFC30000 addr lpd
		dict set xppu FFC40000 addr lpd
		dict set xppu FFC50000 addr lpd
		dict set xppu FFC60000 addr lpd
		dict set xppu FFC70000 addr lpd
		dict set xppu FFC80000 addr lpd
		dict set xppu FFC90000 addr lpd
		dict set xppu FFCA0000 addr lpd
		dict set xppu FFCB0000 addr lpd
		dict set xppu FFCC0000 addr lpd
		dict set xppu FFCD0000 addr lpd
		dict set xppu FFCE0000 addr lpd
		dict set xppu FFCF0000 addr lpd
		dict set xppu FFD00000 addr lpd
		dict set xppu FFD10000 addr lpd
		dict set xppu FFD20000 addr lpd
		dict set xppu FFD30000 addr lpd
		dict set xppu FFD40000 addr lpd
		dict set xppu FFD50000 addr lpd
		dict set xppu FFD60000 addr lpd
		dict set xppu FFD70000 addr lpd
		dict set xppu FFD80000 addr lpd
		dict set xppu FFD90000 addr lpd
		dict set xppu FFDA0000 addr lpd
		dict set xppu FFDB0000 addr lpd
		dict set xppu FFDC0000 addr lpd
		dict set xppu FFDD0000 addr lpd
		dict set xppu FFDE0000 addr lpd
		dict set xppu FFDF0000 addr lpd
		dict set xppu FFE00000 addr lpd
		dict set xppu FFE10000 addr lpd
		dict set xppu FFE20000 addr lpd
		dict set xppu FFE30000 addr lpd
		dict set xppu FFE40000 addr lpd
		dict set xppu FFE50000 addr lpd
		dict set xppu FFE60000 addr lpd
		dict set xppu FFE70000 addr lpd
		dict set xppu FFE80000 addr lpd
		dict set xppu FFE90000 addr lpd
		dict set xppu FFEA0000 addr lpd
		dict set xppu FFEB0000 addr lpd
		dict set xppu FFEC0000 addr lpd
		dict set xppu FFED0000 addr lpd
		dict set xppu FFEE0000 addr lpd
		dict set xppu FFEF0000 addr lpd
		dict set xppu FFF00000 addr lpd
		dict set xppu FFF10000 addr lpd
		dict set xppu FFF20000 addr lpd
		dict set xppu FFF30000 addr lpd
		dict set xppu FFF40000 addr lpd
		dict set xppu FFF50000 addr lpd
		dict set xppu FFF60000 addr lpd
		dict set xppu FFF70000 addr lpd
		dict set xppu FFF80000 addr lpd
		dict set xppu FFF90000 addr lpd
		dict set xppu FFFA0000 addr lpd
		dict set xppu FFFB0000 addr lpd
		dict set xppu FFFC0000 addr lpd
		dict set xppu FFFD0000 addr lpd
		dict set xppu FFFE0000 addr lpd
		dict set xppu FFFF0000 addr lpd
		dict set xppu FF990000 addr lpd
		dict set xppu FF990020 addr lpd
		dict set xppu FF990040 addr lpd
		dict set xppu FF990060 addr lpd
		dict set xppu FF990080 addr lpd
		dict set xppu FF9900A0 addr lpd
		dict set xppu FF9900C0 addr lpd
		dict set xppu FF9900E0 addr lpd
		dict set xppu FF990100 addr lpd
		dict set xppu FF990120 addr lpd
		dict set xppu FF990140 addr lpd
		dict set xppu FF990160 addr lpd
		dict set xppu FF990180 addr lpd
		dict set xppu FF9901A0 addr lpd
		dict set xppu FF9901C0 addr lpd
		dict set xppu FF9901E0 addr lpd
		dict set xppu FF990200 addr lpd
		dict set xppu FF990220 addr lpd
		dict set xppu FF990240 addr lpd
		dict set xppu FF990260 addr lpd
		dict set xppu FF990280 addr lpd
		dict set xppu FF9902A0 addr lpd
		dict set xppu FF9902C0 addr lpd
		dict set xppu FF9902E0 addr lpd
		dict set xppu FF990300 addr lpd
		dict set xppu FF990320 addr lpd
		dict set xppu FF990340 addr lpd
		dict set xppu FF990360 addr lpd
		dict set xppu FF990380 addr lpd
		dict set xppu FF9903A0 addr lpd
		dict set xppu FF9903C0 addr lpd
		dict set xppu FF9903E0 addr lpd
		dict set xppu FF990400 addr lpd
		dict set xppu FF990420 addr lpd
		dict set xppu FF990440 addr lpd
		dict set xppu FF990460 addr lpd
		dict set xppu FF990480 addr lpd
		dict set xppu FF9904A0 addr lpd
		dict set xppu FF9904C0 addr lpd
		dict set xppu FF9904E0 addr lpd
		dict set xppu FF990500 addr lpd
		dict set xppu FF990520 addr lpd
		dict set xppu FF990540 addr lpd
		dict set xppu FF990560 addr lpd
		dict set xppu FF990580 addr lpd
		dict set xppu FF9905A0 addr lpd
		dict set xppu FF9905C0 addr lpd
		dict set xppu FF9905E0 addr lpd
		dict set xppu FF990600 addr lpd
		dict set xppu FF990620 addr lpd
		dict set xppu FF990640 addr lpd
		dict set xppu FF990660 addr lpd
		dict set xppu FF990680 addr lpd
		dict set xppu FF9906A0 addr lpd
		dict set xppu FF9906C0 addr lpd
		dict set xppu FF9906E0 addr lpd
		dict set xppu FF990700 addr lpd
		dict set xppu FF990720 addr lpd
		dict set xppu FF990740 addr lpd
		dict set xppu FF990760 addr lpd
		dict set xppu FF990780 addr lpd
		dict set xppu FF9907A0 addr lpd
		dict set xppu FF9907C0 addr lpd
		dict set xppu FF9907E0 addr lpd
		dict set xppu FF990800 addr lpd
		dict set xppu FF990820 addr lpd
		dict set xppu FF990840 addr lpd
		dict set xppu FF990860 addr lpd
		dict set xppu FF990880 addr lpd
		dict set xppu FF9908A0 addr lpd
		dict set xppu FF9908C0 addr lpd
		dict set xppu FF9908E0 addr lpd
		dict set xppu FF990900 addr lpd
		dict set xppu FF990920 addr lpd
		dict set xppu FF990940 addr lpd
		dict set xppu FF990960 addr lpd
		dict set xppu FF990980 addr lpd
		dict set xppu FF9909A0 addr lpd
		dict set xppu FF9909C0 addr lpd
		dict set xppu FF9909E0 addr lpd
		dict set xppu FF990A00 addr lpd
		dict set xppu FF990A20 addr lpd
		dict set xppu FF990A40 addr lpd
		dict set xppu FF990A60 addr lpd
		dict set xppu FF990A80 addr lpd
		dict set xppu FF990AA0 addr lpd
		dict set xppu FF990AC0 addr lpd
		dict set xppu FF990AE0 addr lpd
		dict set xppu FF990B00 addr lpd
		dict set xppu FF990B20 addr lpd
		dict set xppu FF990B40 addr lpd
		dict set xppu FF990B60 addr lpd
		dict set xppu FF990B80 addr lpd
		dict set xppu FF990BA0 addr lpd
		dict set xppu FF990BC0 addr lpd
		dict set xppu FF990BE0 addr lpd
		dict set xppu FF990C00 addr lpd
		dict set xppu FF990C20 addr lpd
		dict set xppu FF990C40 addr lpd
		dict set xppu FF990C60 addr lpd
		dict set xppu FF990C80 addr lpd
		dict set xppu FF990CA0 addr lpd
		dict set xppu FF990CC0 addr lpd
		dict set xppu FF990CE0 addr lpd
		dict set xppu FF990D00 addr lpd
		dict set xppu FF990D20 addr lpd
		dict set xppu FF990D40 addr lpd
		dict set xppu FF990D60 addr lpd
		dict set xppu FF990D80 addr lpd
		dict set xppu FF990DA0 addr lpd
		dict set xppu FF990DC0 addr lpd
		dict set xppu FF990DE0 addr lpd
		dict set xppu FF990E00 addr lpd
		dict set xppu FF990E20 addr lpd
		dict set xppu FF990E40 addr lpd
		dict set xppu FF990E60 addr lpd
		dict set xppu FF990E80 addr lpd
		dict set xppu FF990EA0 addr lpd
		dict set xppu FF990EC0 addr lpd
		dict set xppu FF990EE0 addr lpd
		dict set xppu FF990F00 addr lpd
		dict set xppu FF990F20 addr lpd
		dict set xppu FF990F40 addr lpd
		dict set xppu FF990F60 addr lpd
		dict set xppu FF990F80 addr lpd
		dict set xppu FF990FA0 addr lpd
		dict set xppu FF990FC0 addr lpd
		dict set xppu FF990FE0 addr lpd
		dict set xppu FE000000 addr lpd
		dict set xppu FE100000 addr lpd
		dict set xppu FE200000 addr lpd
		dict set xppu FE300000 addr lpd
		dict set xppu FE400000 addr lpd
		dict set xppu FE500000 addr lpd
		dict set xppu FE600000 addr lpd
		dict set xppu FE700000 addr lpd
		dict set xppu FE800000 addr lpd
		dict set xppu FE900000 addr lpd
		dict set xppu FEA00000 addr lpd
		dict set xppu FEB00000 addr lpd
		dict set xppu FEC00000 addr lpd
		dict set xppu FED00000 addr lpd
		dict set xppu FEE00000 addr lpd
		dict set xppu FEF00000 addr lpd
		set baseaddr [string toupper $baseaddr]
		set tmp ""
		if {[catch {set tmp [dict get $xppu $baseaddr addr]} msg]} {
		}
		if {[string match -nocase $tmp "lpd"]} {
			set prop "lpd_xppu"
		}

		if {![string match -nocase $tmp ""]} {
			add_prop $node "firewall-0" $prop reference "pcw.dtsi"
		}
		set valid_list "psu_ethernet psu_sd psu_adma psu_gdma psu_usb_xhci psu_qspi"
		set idlist [dict create]
		dict set idlist FFA80000 id 0x868
		dict set idlist FFA90000 id 0x869
		dict set idlist FFAA0000 id 0x86a
		dict set idlist FFAB0000 id 0x86b
		dict set idlist FFAC0000 id 0x86c
		dict set idlist FFAD0000 id 0x86d
		dict set idlist FFAE0000 id 0x86e
		dict set idlist FFAF0000 id 0x86f
		dict set idlist FF100000 id 0x872
		dict set idlist FF0B0000 id 0x874
		dict set idlist FF0C0000 id 0x875
		dict set idlist FF0D0000 id 0x876
		dict set idlist FE0E0000 id 0x877
		dict set idlist FF0F0000 id 0x873
		dict set idlist FF160000 id 0x870
		dict set idlist FF170000 id 0x870
		dict set idlist FE200000 id 0x860
		dict set idlist FE300000 id 0x861
		
		set ip_name ""
		if {[catch {set ip_name [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]} msg]} {
		}
		if {![string match -nocase $ip_name ""]} {
			if {[lsearch $valid_list $ip_name] >=0} {
				if {![string match -nocase $tmp ""]} {
					set tmp ""
					if {[catch {set tmp [dict get $idlist $baseaddr id]} msg]} {
					}
					if {![string match -nocase $tmp ""]} {
						add_prop $node "bus-master-id" "&$prop $tmp" hexlist "pcw.dtsi"
					}
				}
			}	
		}
	}
}

