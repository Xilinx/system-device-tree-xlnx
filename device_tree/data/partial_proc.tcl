#
# (C) Copyright 2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc write_rm_dt args {
	set dt [lindex $args 0]

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
	set fd [open $file w]
	if {[string match -nocase $dt "pldt"]} {
		puts $fd "\/dts-v1\/;\n\/plugin\/;"
	}

	set partial_fileName [file tail $file]
	set partial_fileName [file rootname $partial_fileName]
	set partial_fileName "${partial_fileName}_"
	foreach children $mainroot {
		set childs [$dt children $children]
		set proplist [$dt getall $children]
		if {[string match -nocase $children "amba_pl: amba_pl"]} {
			set children "amba"
			set proplist ""
		}
		puts $fd "&$children {"
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
							puts $fd "\t$prop = $val_temp;"
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
							puts $fd "\t$prop = $val;"
						}
					} else {
						if {[string match -nocase $val ""]} {
							puts $fd "\t$prop;"
						} else {
							puts $fd "\t$prop = $val;"
						}
					}
				}
				set pr [expr $pr + 2]
			}
		}
		foreach child $childs {
			puts $fd "\t$partial_fileName$child {"
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
								puts $fd "\t\t$prop;"
							} else {
								puts $fd "\t\t$prop = $val;"
							}
						}
					}
					set pr [expr $pr + 2]
				}
			}

			foreach child $nestchilds {
				puts $fd "\t\t$partial_fileName$child {"
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
									puts $fd "\t\t\t$prop;"
								} else {
									puts $fd "\t\t\t$prop = $val;"
								}
							}
						}
						set pr [expr $pr + 2]
					}
				}

				foreach child $innerchilds {
					puts $fd "\t\t\t$partial_fileName$child {"
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
										puts $fd "\t\t\t\t\t$prop = $val;"
									}
								} else {
									if {[string match -nocase $val ""]} {
										puts $fd "\t\t\t\t$prop;"
									} else {
										puts $fd "\t\t\t\t$prop = $val;"
									}
								}
							}
							set pr [expr $pr + 2]
						}
					}

					foreach child $nextinner {
						puts $fd "\t\t\t\t$partial_fileName$child {"
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
											puts $fd "\t\t\t\t\t$prop = $first_str;"
										}
									} else {
										if {[string match -nocase $val ""]} {
											puts $fd "\t\t\t\t\t$prop;"
										} else {
											puts $fd "\t\t\t\t\t$prop = $val;"
										}
									}
								}
								set pr [expr $pr + 2]
							}
						}
						puts $fd "\t\t\t\t};"
					}
					puts $fd "\t\t\t};"
				}
				puts $fd "\t\t};"
			}
			puts $fd "\t};"
		}
		puts $fd "};"
	}
	close $fd
}

proc get_rprm_for_drv {drv_handle} {
	set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
	foreach pr_region $pr_regions {
		set is_dfx [hsi::get_property CONFIG.ENABLE_DFX [hsi::get_cells -hier $pr_region]]
		if {[llength $is_dfx] && $is_dfx == 0} {
			return ""
		}
		set rmName [hsi::get_property RECONFIG_MODULE_NAME [hsi::get_cells -hier $pr_region]]
		set inst [hsi::current_hw_instance [hsi::get_cells -hier $pr_region]]
		set drv [hsi::get_cells $drv_handle]
		::hsi::current_hw_instance
		if {[llength $drv] != 0} {
			append instRpName "$inst" "_" "$rmName"
			return [list $inst $rmName $instRpName]
		}
	}
}

proc get_rm_names {pr} {
        set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
        set rm_name ""
        foreach pr_region $pr_regions {
		if {[regexp $pr $pr_region match]} {
			set rm_name [hsi::get_property RECONFIG_MODULE_NAME [hsi::get_cells -hier $pr_region]]
		}
        }
        return $rm_name
}

proc get_partial_file {rmName} {
	set proctype [get_hw_family]

	if {[is_zynqmp_platform $proctype]} {
		append rp_inst $rmName "_BIT_FILE"
	} else {
		append rp_inst $rmName "_PDI_FILE"
	}

        set firmware_name [hsi::get_property $rp_inst [hsi::current_hw_design]]
	set firmware_name [file tail $firmware_name]

	return $firmware_name
}

proc get_partial_bin {rmName} {
        set proctype [get_hw_family]

        if {[is_zynqmp_platform $proctype]} {
                append rp_inst $rmName "_BIT_FILE"
        } else {
                append rp_inst $rmName "_PDI_FILE"
        }
        set firmware_name [hsi::get_property $rp_inst [hsi::current_hw_design]]

	return $firmware_name
}

proc generate_rm_sdt {static_xsa rm_xsa dir} {
	variable ::sdtgen::namespacelist
	global rp_region_dict
	global is_rm_design
	global is_bridge_en
	global env

	set is_rm_design 1
	set path $env(REPO)
	if {[catch {set path $env(REPO)} msg]} {
		set path "."
		set env(REPO) $path
	}

	if { $::sdtgen::namespacelist == "" } {
		init_proclist
	}

	file copy -force $static_xsa $dir
	set static_xsa_name [file tail $static_xsa]
	set static_xsa_path "$dir/$static_xsa_name"
	file copy -force $rm_xsa $dir
	set rm_xsa_name [file tail $rm_xsa]
	set rm_xsa_path "$dir/$rm_xsa_name"
	set rm_ws [file rootname $rm_xsa_name]
	setws -switch "$dir/$rm_ws"
	platform create -name $rm_ws -hw $static_xsa_path -rm-hw $rm_xsa_path
	set cur_hw_design [hsi::current_hw_design]
	file delete -force "$static_xsa_path"
	file delete -force "$rm_xsa_path"
	dict set node_dict $cur_hw_design {}
	dict set nodename_dict $cur_hw_design {}
	dict set property_dict $cur_hw_design {}
	dict set comp_ver_dict $cur_hw_design {}
	dict set comp_str_dict $cur_hw_design {}
	dict set ip_type_dict $cur_hw_design {}
	dict set intr_id_dict $cur_hw_design {}
	set list_offiles {}

	set peri_list [hsi::get_cells -hier]
	set peri_list [move_match_elements_to_top $peri_list "axi_intc"]
	set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
       # set_hw_family $proclist
        suppress_hsi_warnings
        foreach procperiph $proclist {
                set proc_drv_handle [hsi::get_cells -hier $procperiph]
                set ip_name [hsi get_property IP_NAME $proc_drv_handle]

                # For tmr_manager designs, tmr_inject IPs also come as the processor
                # and tmr_manager doesnt have a driver. It is safe to add this if dict exist check.

                if { [dict exists $::sdtgen::namespacelist $ip_name] } {
                        set proc_drv_name [dict get $::sdtgen::namespacelist $ip_name]
                        source [file join $path $proc_drv_name "data" "${proc_drv_name}.tcl"]
                        ${proc_drv_name}_generate $proc_drv_handle
                }
        }

	set skip 0
	foreach drv_handle $peri_list {
		set unit_addr [get_baseaddr ${drv_handle}]
		if {$unit_addr == ""} {
			continue
		}

		set rp_info [get_rprm_for_drv $drv_handle]
		if {[llength $rp_info] != 0} {
			if {$skip == 0} {
				set fpga_inst [regexp -inline {\d+} [lindex $rp_info 0]]
				set firmware_name [get_partial_file [lindex $rp_info 1]]
				set bin_file [get_partial_bin [lindex $rp_info 1]]
				file copy -force $bin_file $dir
				set replacement {
					".pdi" ".dtsi"
					".bit" ".dtsi"
					".bin" ".dtsi"
				}
				set partial_file [string map $replacement $firmware_name]
				set dts "pl.dtsi"
				set amba_pl_node [create_node -n "amba_pl" -l "amba_pl" -d ${dts} -p root]
				set pr_node [create_node -n "fpga_PR$fpga_inst" -d ${dts} -p root]
				add_prop $pr_node "firmware-name" $firmware_name string ${dts} 1
				if {$is_bridge_en} {
					set connectip [dict get $rp_region_dict "rp$fpga_inst"]
					add_prop "${pr_node}" "fpga-bridges" "$connectip" reference $dts 1
				}
				add_prop $pr_node "partial-fpga-config" "" boolean $dts 1
				set $skip 1
			}

			set ip_name [get_ip_property $drv_handle IP_NAME]
			set ip_type [get_ip_property $drv_handle IP_TYPE]
			gen_peripheral_nodes $drv_handle "create_node_only"
			gen_reg_property $drv_handle
			gen_compatible_property $drv_handle
			gen_ctrl_compatible $drv_handle
			gen_drv_prop_from_ip $drv_handle
			gen_interrupt_property $drv_handle
			gen_clk_property $drv_handle
			gen_power_domains $drv_handle
			if { [dict exists $::sdtgen::namespacelist $ip_name] } {
				set drvname [dict get $::sdtgen::namespacelist $ip_name]
				source [file join $path $drvname "data" "${drvname}.tcl"]
				${drvname}_generate $drv_handle
			}
		}
	}
	platform remove $rm_ws
	delete_tree pldt root
	move_match_node_to_top pldt root "misc_clk_*"
	write_rm_dt pldt root "$dir/$rm_ws/$partial_file"
	file rename "$dir/$firmware_name" "$dir/$rm_ws/$firmware_name"
}
