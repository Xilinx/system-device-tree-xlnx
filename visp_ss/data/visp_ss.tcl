#
# (C) Copyright 2024 - 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

#IBA
proc add_iba_properties {drv_handle port_node dts_file isp_index iba_index tile_index} {
	set prefix "CONFIG.C_TILE${tile_index}_ISP${isp_index}_IBA${iba_index}_"
	set data_format [get_ip_property $drv_handle "${prefix}DATA_FORMAT"]
	set fps [get_ip_property $drv_handle "${prefix}FPS"]
	set ppc [get_ip_property $drv_handle "${prefix}PPC"]
	set max_width [get_ip_property $drv_handle "${prefix}RES_HOR"]
	set max_height [get_ip_property $drv_handle "${prefix}RES_VER"]
	set vcid [get_ip_property $drv_handle "${prefix}VCID"]
	add_prop "$port_node" "xlnx,iba${iba_index}_vcid" $vcid int $dts_file
	add_prop "$port_node" "xlnx,iba${iba_index}_max-height" $max_height int $dts_file
	add_prop "$port_node" "xlnx,iba${iba_index}_data_format" $data_format int $dts_file
	add_prop "$port_node" "xlnx,iba${iba_index}_ppc" $ppc int $dts_file
	add_prop "$port_node" "xlnx,iba${iba_index}_max-width" $max_width int $dts_file
	add_prop "$port_node" "xlnx,iba${iba_index}_frame_rate" $fps int $dts_file
}


#OBA_MP
proc add_oba_properties_mp {drv_handle port_node dts_file isp_index oba_index tile_index} {
	set config_properties {
		"CONFIG.C_TILE0_ISP0_OBA0_MP_YUV420"
		"CONFIG.C_TILE0_ISP0_OBA0_MP_YUV422"
		"CONFIG.C_TILE0_ISP1_OBA0_MP_YUV420"
		"CONFIG.C_TILE0_ISP1_OBA0_MP_YUV422"
		"CONFIG.C_TILE1_ISP0_OBA0_MP_YUV420"
		"CONFIG.C_TILE1_ISP0_OBA0_MP_YUV422"
		"CONFIG.C_TILE1_ISP1_OBA0_MP_YUV420"
		"CONFIG.C_TILE1_ISP1_OBA0_MP_YUV422"
		"CONFIG.C_TILE2_ISP0_OBA0_MP_YUV420"
		"CONFIG.C_TILE2_ISP0_OBA0_MP_YUV422"
		"CONFIG.C_TILE2_ISP1_OBA0_MP_YUV420"
		"CONFIG.C_TILE2_ISP1_OBA0_MP_YUV422"
	}
	set mp_data_format ""
	set sp_data_format ""
	foreach config_name $config_properties {
		set is_enabled [get_ip_property $drv_handle $config_name]
		if {$is_enabled eq "true"} {
			if {[string match *MP* $config_name]} {
				set format_type "MP"
				set format_name [string range $config_name [expr [string last "_" $config_name] + 1] end]
				set mp_data_format $format_name
			} elseif {[string match *SP* $config_name]} {
				set format_type "SP"
				set format_name [string range $config_name [expr [string last "_" $config_name] + 1] end]
				set sp_data_format $format_name
			}
		}
	}
	set prefix "CONFIG.C_TILE${tile_index}_ISP${isp_index}_OBA${oba_index}_"
	set mp_bpp [get_ip_property $drv_handle "${prefix}MP_BPP"]
	set mp_ppc [get_ip_property $drv_handle "${prefix}PPC"]
	add_prop "$port_node" "xlnx,oba${oba_index}_mp_bpp" $mp_bpp int $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_mp_data_format" $mp_data_format string $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_mp_ppc" $mp_ppc int $dts_file
}


#OBA_SP
proc add_oba_properties_sp {drv_handle port_node dts_file isp_index oba_index tile_index} {
	set config_properties {
		"CONFIG.C_TILE0_ISP0_OBA0_SP_YUV420"
		"CONFIG.C_TILE0_ISP0_OBA0_SP_YUV422"
		"CONFIG.C_TILE0_ISP1_OBA0_SP_YUV420"
		"CONFIG.C_TILE0_ISP1_OBA0_SP_YUV422"
		"CONFIG.C_TILE1_ISP0_OBA0_SP_YUV420"
		"CONFIG.C_TILE1_ISP0_OBA0_SP_YUV422"
		"CONFIG.C_TILE1_ISP1_OBA0_SP_YUV420"
		"CONFIG.C_TILE1_ISP1_OBA0_SP_YUV422"
		"CONFIG.C_TILE2_ISP0_OBA0_SP_YUV420"
		"CONFIG.C_TILE2_ISP0_OBA0_SP_YUV422"
		"CONFIG.C_TILE2_ISP1_OBA0_SP_YUV420"
		"CONFIG.C_TILE2_ISP1_OBA0_SP_YUV422"
	}
	set sp_data_format ""
	foreach config_name $config_properties {
		set is_enabled [get_ip_property $drv_handle $config_name]
		if {$is_enabled eq "true"} {
			if {[string match *MP* $config_name]} {
				set format_type "MP"
				set format_name [string range $config_name [expr [string last "_" $config_name] + 1] end]
				set mp_data_format $format_name
			} elseif {[string match *SP* $config_name]} {
				set format_type "SP"
				set format_name [string range $config_name [expr [string last "_" $config_name] + 1] end]
				set sp_data_format $format_name
			}
		}
	}
	set prefix "CONFIG.C_TILE${tile_index}_ISP${isp_index}_OBA${oba_index}_"
	set sp_bpp [get_ip_property $drv_handle "${prefix}SP_BPP"]
	set sp_ppc [get_ip_property $drv_handle "${prefix}PPC"]
	add_prop "$port_node" "xlnx,oba${oba_index}_sp_bpp" $sp_bpp int $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_sp_data_format" $sp_data_format string $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_sp_ppc" $sp_ppc int $dts_file
}


#VISP_SS MAIN
proc visp_ss_generate {drv_handle} {
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set default_dts [set_drv_def_dts $drv_handle]
	set bus_name [detect_bus_name $drv_handle]
	# Try to get interrupts, if not present, skip processing
	set intr_val ""
	set intr_mapping {}
	if {[catch {set intr_val [pldt get $node interrupts]}]} {
		puts "Interrupts are not available. Skipping interrupt processing."
	} elseif {$intr_val ne ""} {
		set intr_val [string trimright $intr_val ">"]
		set intr_val [string trimleft $intr_val "<"]
		set intr_parent [pldt get $node interrupt-parent]
		# Get interrupt names
		set intr_names [pldt get $node interrupt-names]
		set intr_names [string map {"," "" "\"" ""} $intr_names]

		# Validate interrupt data
		set num_interrupts [llength $intr_names]
		set num_cells [llength $intr_val]

		if {[expr $num_interrupts * 2] == $num_cells} {
			set cell_count 2
		} elseif {[expr $num_interrupts * 3] == $num_cells} {
			set cell_count 3
		} else {
			set cell_count -1
		}

		if {$cell_count == -1} {
			puts "Warning: Could not determine the Interrupt parent for $node. Interrupts may not function correctly."
		} else {
			# Populate intr_mapping
			for {set i 0} {$i < $num_interrupts} {incr i} {
				set value [lrange $intr_val [expr $i * $cell_count] [expr $i * $cell_count + ($cell_count - 1)]]
				dict set intr_mapping [lindex $intr_names $i] $value
			}
		}
	}
	set reg_mapping {}
	set rpu_ids {}
	set rpu_info_list {}
	for {set tile 0} {$tile < 3} {incr tile} {
		set tile_enabled [get_ip_property $drv_handle "CONFIG.C_TILE${tile}_ENABLE"]
		if {!$tile_enabled} {
			continue
		}
		for {set isp 0} {$isp < 2} {incr isp} {
			set isp_id [expr {$tile * 2 + $isp}]
			set sub_node_label "visp_ss_${tile}${isp_id}"
			set baseaddr [get_baseaddr [hsi get_cells -hier $drv_handle] no_prefix]
			set sub_region_size 0x800  ;#2KB
			set sub_baseaddr [format %08x [expr 0x$baseaddr + $isp_id * $sub_region_size]]
			set sub_baseaddr1 [expr 0x$baseaddr + $isp_id * $sub_region_size]
			set sub_node [create_node -l ${sub_node_label} -n "visp_ss" -u $sub_baseaddr -p $bus_name -d $default_dts]
			if {$sub_baseaddr1 > 0xFFFFFFFF} {
				# >32-bit address case
				set sub_baseaddr_high [format %08x [expr ($sub_baseaddr1 >> 32) & 0xFFFFFFFF]]
				set sub_baseaddr_low [format %08x [expr $sub_baseaddr1 & 0xFFFFFFFF]]
				set reg_value "0x$sub_baseaddr_high 0x$sub_baseaddr_low 0x0 $sub_region_size"
			} else {
				set reg_value "0x0 0x$sub_baseaddr 0x0 $sub_region_size"
			}
			add_prop "$sub_node" "reg" $reg_value hexlist $default_dts
			add_prop "$sub_node" "status" "okay" string $default_dts
			dict set reg_mapping $sub_node_label $reg_value
			set live_stream [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_LIVE_INPUTS]
			set io_mode [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_IO_TYPE]
			set io_type [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_IO_TYPE]
			if {$io_type == 1} {
				set io_mode_name "lilo"
			} elseif {$io_type == 2} {
				set io_mode_name "limo"
			} elseif {$io_type == 3} {
				set io_mode_name "mimo"
			} else {
				set io_mode_name "Unknown"
			}
			set live_inputs [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_LIVE_INPUTS]
			set mem_inputs [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_MEM_INPUTS]
			set net_fps [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_NETFPS]
			set rpu [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_RPU]
			lappend rpu_ids $rpu
			lappend rpu_info_list [list $rpu $io_type]
			add_prop "$sub_node" "xlnx,name" "$sub_node_label" string $default_dts
			set ip_name [pldt get $node xlnx,ip-name]
			set ip_name [string trim $ip_name "\""]
			add_prop "$sub_node" "xlnx,ip-name" $ip_name string $default_dts
			add_prop "$sub_node" "xlnx,io_mode" "$io_mode_name" string $default_dts
			add_prop "$sub_node" "xlnx,num_streams" $live_inputs int $default_dts
			add_prop "$sub_node" "xlnx,mem_inputs" $mem_inputs int $default_dts
			add_prop "$sub_node" "xlnx,netfps" $net_fps int $default_dts
			add_prop "$sub_node" "xlnx,rpu" $rpu int $default_dts
			add_prop "$sub_node" "isp_id" $isp_id int $default_dts
			switch $rpu {
				6 {
					set rprocn "D_0_$rpu"
				}
				7 {
					set rprocn "D_1_$rpu"
				}
				8 {
					set rprocn "E_0_$rpu"
				}
				9 {
					set rprocn "E_1_$rpu"
				}
			}
			#add_prop "$sub_node" "memory-region" "<&rproc_${rprocn}_calib_load>" noformating $default_dts
			if {[dict size $intr_mapping] > 0} {
				set tile_intrnames ""
				dict for {key value} $intr_mapping {
					if {[string match "*tile${tile}_isp${isp}*" $key]} {
						add_prop "$sub_node" "interrupts" "$value" hexlist $default_dts
						lappend tile_intrnames $key
					}

					# Special handling for tile ISP 0
					if {$isp == 0} {
						if {[string match "*tile${tile}_isp_isr_irq*" $key] || [string match "*tile${tile}_isp_xmpu_interrupt*" $key]} {
							add_prop "$sub_node" "interrupts" "$value" hexlist $default_dts
							lappend tile_intrnames $key
						}
					}
				}

				# Add interrupt-names only if there are valid entries
				if {$tile_intrnames ne ""} {
					add_prop "$sub_node" "interrupt-names" [join $tile_intrnames " "] stringlist $default_dts
				}

				# Set the interrupt-parent property
				add_prop $sub_node interrupt-parent $intr_parent noformating $default_dts
			}
			if {$io_type == 1} {
				set compatible_name "xlnx,visp-ss-lilo-1.0"
			} elseif {$io_type == 2} {
				set compatible_name "xlnx,visp-ss-limo-1.0"
			} elseif {$io_type == 3} {
				set compatible_name "xlnx,visp-ss-mimo-1.0"
			} else {
				set compatible_name "xlnx,visp-disabled"
				add_prop "$sub_node" "status" "disabled" string $default_dts
			}
			add_prop "$sub_node" "compatible" "$compatible_name" string $default_dts

			isp_handle_condition $drv_handle $tile $isp $io_mode $live_stream $isp_id $default_dts $sub_node $sub_node_label $bus_name
		}
	}
	pldt delete $node
	#generate_reserved_memory $rpu_ids $default_dts $bus_name
	#generate_remoteproc_node $rpu_ids $default_dts $bus_name
	#generate_tcm_nodes $rpu_ids $default_dts $bus_name
	generate_mbox_nodes $rpu_info_list $default_dts $bus_name
	#generate_ipi_mailbox_nodes $rpu_ids $default_dts $bus_name

	set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
	foreach proc $proclist {
		if {![string_is_empty [hsi get_mem_ranges -of_objects [hsi get_cells -hier $proc] -filter INSTANCE==$drv_handle]]} {
			set proc_ip_name [get_ip_property $proc IP_NAME]
			dict for {label reg_val} $reg_mapping {
				switch $proc_ip_name {
					"cortexr52" - "microblaze" - "microblaze_riscv" {
						set_memmap "${label}" $proc $reg_val
					}
					"cortexa78" {
						set_memmap "${label}" a53 $reg_val
					}
					"asu" {
						set_memmap "${label}" asu $reg_val
					}
					default {
					}
				}
			}
		}
	}
}

proc create_vcp_node {sub_node default_dts isp_id bus_name} {
	set vcp_node [create_node -l visp_video_${isp_id} -n "visp_video_${isp_id}" -p $bus_name -d $default_dts]
	add_prop "$vcp_node" "compatible" "xlnx,visp-video" string $default_dts
	add_prop "$vcp_node" "status" "okay" string $default_dts
	add_prop "$vcp_node" "id" $isp_id int $default_dts
	return $vcp_node
}

proc handle_io_mode_2 {drv_handle tile isp isp_id default_dts sub_node sub_node_label live_stream bus_name io_mode} {
	set ports_node [create_node -l "ports${tile}${isp_id}" -n "ports" -p $sub_node -d $default_dts]
	add_prop "$ports_node" "#address-cells" 1 int $default_dts
	add_prop "$ports_node" "#size-cells" 0 int $default_dts

	set vcp_node [create_vcp_node $sub_node $default_dts $isp_id $bus_name]
	set vcap_ports_node [create_node -l "vcap_ports${tile}${isp_id}" -n "ports" -p $vcp_node -d $default_dts]
	add_prop "$vcap_ports_node" "#address-cells" 1 int $default_dts
	add_prop "$vcap_ports_node" "#size-cells" 0 int $default_dts

	set reg_counter 0
	set vcap_reg_counter 1
	set port_addr_counter 0
	set skip_default_port_creation 0  ;# Added flag

	for {set iba 0} {$iba < $live_stream} {incr iba} {
		set iba_mod [expr $iba % 4]

		for {set j 0} {$j < 5} {incr j} {
			set port_idx [expr $iba * 5 + $j]
			set port_num $port_idx

			# Special-case: ISP1 live_stream 1 or 2
			if {$isp == 1 && $io_mode == 2 && $live_stream <= 2 && $port_idx % 5 == 0 && $iba == 0 && !$skip_default_port_creation} {
				set iba_values {}
				if {$live_stream == 1} {
					lappend iba_values 4
				} elseif {$live_stream == 2} {
					lappend iba_values 4 3
				}
				foreach iba_val $iba_values {
					add_iba_properties $drv_handle $sub_node $default_dts $isp $iba_val $tile
					set visp_ip_name "TILE${tile}_ISP_MIPI_VIDIN${iba_val}"
					set visp_inip [find_valid_visp_inip $drv_handle $visp_ip_name]
					visp_ss_inip_endpoints $drv_handle $ports_node $default_dts "${sub_node_label}${port_addr_counter}" $port_addr_counter $visp_inip
					incr port_addr_counter 5
				}
				set skip_default_port_creation 1
				continue
			}

			# Skip generic fallback IBA block if already handled special case
			if {$skip_default_port_creation && $port_idx % 5 == 0} {
				continue
			}

			# Fallback: IBA input port creation
			if {$port_idx % 5 == 0} {
				add_iba_properties $drv_handle $sub_node $default_dts $isp $iba_mod $tile
				set visp_ip_name "TILE${tile}_ISP_MIPI_VIDIN${iba_mod}"
				set visp_inip [find_valid_visp_inip $drv_handle $visp_ip_name]
				visp_ss_inip_endpoints $drv_handle $ports_node $default_dts "${sub_node_label}${port_addr_counter}" $port_addr_counter $visp_inip
				incr port_addr_counter 5

			} elseif {$port_idx % 5 == 1 || $port_idx % 5 == 2} {
				# MP or SP output port creation
				set type [expr {$port_idx % 5 == 1 ? "mp" : "sp"}]
				set visp_label "visp_isp${isp_id}_port${isp_id}${iba_mod}_${type}"
				set video_label "visp_video_${isp_id}_${iba_mod}_[expr {$type eq "mp" ? 0 : 1}]"
				set vport_label "vport${isp_id}${port_idx}"

				# VISP side
				set port [create_node -l "port${isp_id}${port_idx}" -n "port@${port_num}" -p $ports_node -d $default_dts]
				add_prop "$port" "reg" $port_num int $default_dts
				set endpoint_node [create_node -n "endpoint" -l $visp_label -p $port -d $default_dts]
				add_prop "$endpoint_node" "remote-endpoint" $video_label reference $default_dts
				add_prop "$endpoint_node" "type" "output" string $default_dts

				# Video side
				set vcp_ports [create_node -l $vport_label -n "port@${reg_counter}" -p $vcap_ports_node -d $default_dts]
				add_prop "$vcp_ports" "reg" $reg_counter int $default_dts
				incr reg_counter

				set vcp_endpoint [create_node -n "endpoint" -l $video_label -p $vcp_ports -d $default_dts]
				add_prop "$vcp_endpoint" "remote-endpoint" $visp_label reference $default_dts
			}
		}
	}
}
# IO_MODE==1 (LILO)
proc handle_io_mode_1 {drv_handle tile isp isp_id default_dts sub_node sub_node_label bus_name} {
	set ports_node [create_node -l "ports${tile}${isp_id}" -n "ports" -p $sub_node -d $default_dts]
	add_prop "$ports_node" "#address-cells" 1 int $default_dts
	add_prop "$ports_node" "#size-cells" 0 int $default_dts
	set port_addr_counter1 1
	set port_addr_counter 0
	set pin_name ""
	if {$isp == 0} {
		set pin_name "TILE${tile}_ISP_MIPI_VIDIN0"
		set isp_iba 0
	} elseif {$isp == 1} {
		set pin_name "TILE${tile}_ISP_MIPI_VIDIN4"
		set isp_iba 4
	} else {
		return
	}
	set visp_inip [find_valid_visp_inip $drv_handle $pin_name]
	visp_ss_inip_endpoints $drv_handle $ports_node $default_dts "${sub_node_label}${port_addr_counter}" $port_addr_counter $visp_inip
	incr port_addr_counter 5
	foreach out_type {PO SO} {
		set intf "TILE${tile}_ISP${isp}_VIDOUT_${out_type}"
		set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]
		if {[string length $outip] > 0} {
			visp_ss_outip_endpoints $drv_handle $default_dts $sub_node_label $outip $port_addr_counter1 $ports_node $isp_id
			incr port_addr_counter1
		}
	}
	add_iba_properties $drv_handle $sub_node $default_dts $isp $isp_iba $tile
	# Add OBA properties
	add_oba_properties_mp $drv_handle $sub_node $default_dts $isp $isp $tile
	add_oba_properties_sp $drv_handle $sub_node $default_dts $isp $isp $tile
}

#conditions
proc isp_handle_condition {drv_handle tile isp io_mode live_stream isp_id default_dts sub_node sub_node_label bus_name} {
	if {$isp == 0 || $isp == 1} {
		if {$io_mode == 1} {
			handle_io_mode_1 $drv_handle $tile $isp $isp_id $default_dts $sub_node $sub_node_label $bus_name
		} elseif {$io_mode == 2} {
			handle_io_mode_2 $drv_handle $tile $isp $isp_id $default_dts $sub_node $sub_node_label $live_stream $bus_name $io_mode
		} else {
		}
	}
}

proc visp_ss_inip_endpoints {drv_handle node default_dts sub port_addr_counter visp_inip} {
	global end_mappings
	global remo_mappings
	global port1_end_mappings
	global port2_end_mappings
	global port3_end_mappings
	global port4_end_mappings
	global axis_port1_remo_mappings
	global axis_port2_remo_mappings
	global axis_port3_remo_mappings
	global axis_port4_remo_mappings
	global port1_broad_end_mappings
	global broad_port1_remo_mappings
	global port2_broad_end_mappings
	global broad_port2_remo_mappings
	global port3_broad_end_mappings
	global broad_port3_remo_mappings
	global port4_broad_end_mappings
	global broad_port4_remo_mappings
	global port5_broad_end_mappings
	global broad_port5_remo_mappings
	global port6_broad_end_mappings
	global broad_port6_remo_mappings
	global port7_broad_end_mappings
	global broad_port7_remo_mappings
	global port_broad_end_mappings

	set port_node [create_node -n "port@$port_addr_counter" -l $sub$drv_handle -p $node -d $default_dts]
	add_prop "$port_node" "reg" $port_addr_counter int $default_dts 1
	set len [llength $visp_inip]

	if {$len > 1} {
		for {set i 0} {$i < $len} {incr i} {
			set temp_ip [lindex $visp_inip $i]
			if {[regexp -nocase "ila" $temp_ip match]} {
				continue
			}
			set visp_inip "$temp_ip"
		}
	}

	foreach inip $visp_inip {
		if {[llength $inip]} {
			set ip_mem_handles [hsi::get_mem_ranges $inip]
			if {![llength $ip_mem_handles]} {
				set broad_ip [get_broad_in_ip $inip]
				if {[llength $broad_ip]} {
					if {[string match -nocase [hsi::get_property IP_NAME $inip] "axis_broadcaster"]} {
						set master_intf [hsi::get_intf_pins -of_objects [hsi get_cells -hier $inip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
						set intlen [llength $master_intf]
						set mipi_in_end ""
						set mipi_remo_in_end ""
						set max_ports [expr {$intlen}]

						for {set i 1} {$i <= $max_ports} {incr i} {
							# Construct variable names dynamically
							set port_var "port${i}_broad_end_mappings"
							set remo_var "broad_port${i}_remo_mappings"

							# Get local and remote endpoint using $inip
							if {[info exists $port_var] && [dict exists [set $port_var] $inip]} {
								set mipi_in_end [dict get [set $port_var] $inip]
							} else {
								continue
							}
							if {[info exists $remo_var] && [dict exists [set $remo_var] $inip]} {
								set mipi_remo_in_end [dict get [set $remo_var] $inip]
							} else {
								continue
							}

							# Only if remote endpoint matches sub
							if {[info exists mipi_remo_in_end] && [regexp -nocase $sub "$mipi_remo_in_end" match]} {
								if {[llength $mipi_remo_in_end]} {
									set mipi_node [create_node -n "endpoint" -l $mipi_remo_in_end -p $port_node -d $default_dts]
								}
								if {[llength $mipi_in_end]} {
									add_prop "$mipi_node" "remote-endpoint" $mipi_in_end reference $default_dts
								}
							}
						}
					}
				}
			}
		}

		if {[llength $visp_inip]} {
			if {[string match -nocase [hsi::get_property IP_NAME $visp_inip] "axis_switch"]} {
				set ip_mem_handles [hsi::get_mem_ranges $visp_inip]
				if {![llength $ip_mem_handles]} {
					set visp_in_end ""
					set visp_remo_in_end ""
					if {[info exists port1_end_mappings] && [dict exists $port1_end_mappings $visp_inip]} {
						set visp_in_end [dict get $port1_end_mappings $visp_inip]
						dtg_verbose "visp_in_end:$visp_in_end"
					}
					if {[info exists axis_port1_remo_mappings] && [dict exists $axis_port1_remo_mappings $visp_inip]} {
						set visp_remo_in_end [dict get $axis_port1_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in_end:$visp_remo_in_end"
					}
					if {[info exists port2_end_mappings] && [dict exists $port2_end_mappings $visp_inip]} {
						set visp_in1_end [dict get $port2_end_mappings $visp_inip]
						dtg_verbose "visp_in1_end:$visp_in1_end"
					}
					if {[info exists axis_port2_remo_mappings] && [dict exists $axis_port2_remo_mappings $visp_inip]} {
						set visp_remo_in1_end [dict get $axis_port2_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in1_end:$visp_remo_in1_end"
					}
					if {[info exists port3_end_mappings] && [dict exists $port3_end_mappings $visp_inip]} {
						set visp_in2_end [dict get $port3_end_mappings $visp_inip]
						dtg_verbose "visp_in2_end:$visp_in2_end"
					}
					if {[info exists axis_port3_remo_mappings] && [dict exists $axis_port3_remo_mappings $visp_inip]} {
						set visp_remo_in2_end [dict get $axis_port3_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in2_end:$visp_remo_in2_end"
					}
					if {[info exists port4_end_mappings] && [dict exists $port4_end_mappings $visp_inip]} {
						set visp_in3_end [dict get $port4_end_mappings $visp_inip]
						dtg_verbose "visp_in3_end:$visp_in3_end"
					}
					if {[info exists axis_port4_remo_mappings] && [dict exists $axis_port4_remo_mappings $visp_inip]} {
						set visp_remo_in3_end [dict get $axis_port4_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in3_end:$visp_remo_in3_end"
					}
					set drv [split $visp_remo_in_end "-"]
					set handle [lindex $drv 0]
					if {[info exists visp_remo_in_end] && [regexp -nocase $sub "$visp_remo_in_end" match]} {
						if {[llength $visp_remo_in_end]} {
							set visp_ss_node [create_node -n "endpoint" -l $visp_remo_in_end -p $port_node -d $default_dts]
						}
						if {[llength $visp_in_end]} {
							add_prop "$visp_ss_node" "remote-endpoint" $visp_in_end reference $default_dts
						}
					}

					if {[info exists visp_remo_in1_end] && [regexp -nocase $sub "$visp_remo_in1_end" match]} {
						if {[llength $visp_remo_in1_end]} {
							set visp_ss_node1 [create_node -n "endpoint" -l $visp_remo_in1_end -p $port_node -d $default_dts]
						}
						if {[llength $visp_in1_end]} {
							add_prop "$visp_ss_node1" "remote-endpoint" $visp_in1_end reference $default_dts
						}
					}

					if {[info exists visp_remo_in2_end] && [regexp -nocase $sub "$visp_remo_in2_end" match]} {
						if {[llength $visp_remo_in2_end]} {
							set visp_ss_node2 [create_node -n "endpoint" -l $visp_remo_in2_end -p $port_node -d $default_dts]
						}
						if {[llength $visp_in2_end]} {
							add_prop "$visp_ss_node2" "remote-endpoint" $visp_in2_end reference $default_dts
						}
					}

					if {[info exists visp_remo_in3_end] && [regexp -nocase $sub "$visp_remo_in3_end" match]} {
						if {[llength $visp_remo_in3_end]} {
							set visp_ss_node3 [create_node -n "endpoint" -l $visp_remo_in3_end -p $port_node -d $default_dts]
						}
						if {[llength $visp_in3_end]} {
							add_prop "$visp_ss_node3" "remote-endpoint" $visp_in3_end reference $default_dts
						}
					}
					return
				} else {
					set visp_in_end ""
					set visp_remo_in_end ""
					if {[info exists axis_switch_port1_end_mappings] && [dict exists $axis_switch_port1_end_mappings $visp_inip]} {
						set visp_in_end [dict get $axis_switch_port1_end_mappings $visp_inip]
						dtg_verbose "visp_in_end:$visp_in_end"
					}
					if {[info exists axis_switch_port1_remo_mappings] && [dict exists $axis_switch_port1_remo_mappings $visp_inip]} {
						set visp_remo_in_end [dict get $axis_switch_port1_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in_end:$visp_remo_in_end"
					}
					if {[info exists axis_switch_port2_end_mappings] && [dict exists $axis_switch_port2_end_mappings $visp_inip]} {
						set visp_in1_end [dict get $axis_switch_port2_end_mappings $visp_inip]
						dtg_verbose "visp_in1_end:$visp_in1_end"
					}
					if {[info exists axis_switch_port2_remo_mappings] && [dict exists $axis_switch_port2_remo_mappings $visp_inip]} {
						set visp_remo_in1_end [dict get $axis_switch_port2_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in1_end:$visp_remo_in1_end"
					}
					if {[info exists axis_switch_port3_end_mappings] && [dict exists $axis_switch_port3_end_mappings $visp_inip]} {
						set visp_in2_end [dict get $axis_switch_port3_end_mappings $visp_inip]
						dtg_verbose "visp_in2_end:$visp_in2_end"
					}
					if {[info exists axis_switch_port3_remo_mappings] && [dict exists $axis_switch_port3_remo_mappings $visp_inip]} {
						set visp_remo_in2_end [dict get $axis_switch_port3_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in2_end:$visp_remo_in2_end"
					}
					if {[info exists axis_switch_port4_end_mappings] && [dict exists $axis_switch_port4_end_mappings $visp_inip]} {
						set visp_in3_end [dict get $axis_switch_port4_end_mappings $visp_inip]
						dtg_verbose "visp_in3_end:$visp_in3_end"
					}
					if {[info exists axis_switch_port4_remo_mappings] && [dict exists $axis_switch_port4_remo_mappings $visp_inip]} {
						set visp_remo_in3_end [dict get $axis_switch_port4_remo_mappings $visp_inip]
						dtg_verbose "visp_remo_in3_end:$visp_remo_in3_end"
					}
					set drv [split $visp_remo_in_end "-"]
					set handle [lindex $drv 0]
					if {[regexp -nocase $drv_handle "$visp_remo_in_end" match]} {
						if {[llength $visp_remo_in_end]} {
							set visp_ss_node [create_node -n "endpoint" -l $visp_remo_in_end -p $port_node -d $default_dts]
						}
						if {[llength $visp_in_end]} {
							add_prop "$visp_ss_node" "remote-endpoint" $visp_in_end reference $default_dts
						}
					}

					if {[regexp -nocase $drv_handle "$visp_remo_in1_end" match]} {
						if {[llength $visp_remo_in1_end]} {
							set visp_ss_node1 [create_node -n "endpoint" -l $visp_remo_in1_end -p $port_node -d $default_dts]
						}
						if {[llength $visp_in1_end]} {
							add_prop "$visp_ss_node1" "remote-endpoint" $visp_in1_end reference $default_dts
						}
					}
				}
			}
		}

		set inip ""
		if {[llength $visp_inip]} {
			foreach inip $visp_inip {
				set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
				} else {
					if {[string match -nocase [hsi::get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
				}
				if {[llength $inip]} {
					set visp_in_end ""
					set visp_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set visp_in_end [dict get $end_mappings $inip]
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set visp_remo_in_end [dict get $remo_mappings $inip]
					}
					if {[llength $visp_remo_in_end]} {
						set visp_ss_node [create_node -n "endpoint" -l $visp_remo_in_end -p $port_node -d $default_dts]
					}
					if {[llength $visp_in_end]} {
						add_prop "$visp_ss_node" "remote-endpoint" $visp_in_end reference $default_dts
					}
				}
			}
		} else {
			dtg_warning "$drv_handle pin s_axis is not connected..check your design"
		}


	}
}


proc visp_ss_outip_endpoints {drv_handle default_dts sub_node_label outip port_addr_counter1 ports_node isp_id} {
	if {![llength $outip]} {
		puts "Error: outip is empty or not valid. Exiting..."
		return
	}
	set outipname ""
	if {[catch {hsi get_property IP_NAME $outip} outipname]} {
		puts "Error: Failed to get IP_NAME for outip: $outip"
		return
	}
	set valid_mmip_list "v_frmbuf_wr mipi_dsi_tx_subsystem"
	if {[lsearch  -nocase $valid_mmip_list $outipname] >= 0} {
		foreach ip $outip {
			if {[llength $ip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				set ip_mem_handles [hsi::get_mem_ranges $ip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
					set type [expr {$port_addr_counter1 == 1 ? "po" : "so"}]
					set port0 [create_node -l "visp_port${port_addr_counter1}_${type}_${isp_id}" -n "port@${port_addr_counter1}" -p $ports_node -d $default_dts]
					add_prop "$port0" "reg" $port_addr_counter1 int $default_dts
					add_prop "$port0" "direction" output string $default_dts
					set vispnode [create_node -n "endpoint" -l visp_out${port_addr_counter1}${sub_node_label} -p $port0 -d $default_dts]
					gen_endpoint $drv_handle "visp_out${port_addr_counter1}${sub_node_label}"
					add_prop "$vispnode" "remote-endpoint" $ip$sub_node_label reference $default_dts
					gen_remoteendpoint $drv_handle "$ip$sub_node_label"
					if {[string match -nocase [hsi get_property IP_NAME $ip] "v_frmbuf_wr"]} {
						visp_ss_gen_frmbuf_wr_node $ip $drv_handle $default_dts $sub_node_label $port_addr_counter1 $type $isp_id
					}
				} else {
					if {[string match -nocase [hsi get_property IP_NAME $ip] "system_ila"]} {
						continue
					}
					set connectip [get_connect_ip $ip $master_intf $default_dts]
					if {[llength $connectip]} {
						set vispnode [create_node -n "endpoint" -l visp_out$port_addr_counter1$sub_node_label -p $port0 -d $default_dts]
						gen_endpoint $drv_handle "visp_out$sub_node_label"
						add_prop "$vispnode" "remote-endpoint" $connectip$drv_handle reference $default_dts
						gen_remoteendpoint $drv_handle "$connectip$drv_handle"
						if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
							visp_ss_gen_frmbuf_wr_node $connectip $drv_handle $default_dts $sub_node_label $port_addr_counter1 $type $isp_id
						}
					}
				}
			} else {
				dtg_warning "$drv_handle pin TILE0_ISP0_VIDOUT_PO is not connected..check your design"
			}
		}
	}

}

proc visp_ss_gen_frmbuf_wr_node {outip drv_handle dts_file sub_node_label port_addr_counter1 type isp_id} {
	set bus_node [detect_bus_name $drv_handle]
	set vcap [create_node -n "vcap_$sub_node_label" -l vcap_$sub_node_label -p $bus_node -d $dts_file]
	add_prop $vcap "compatible" "xlnx,video" string $dts_file
	# Build DMA list for multiple frame buffer writers
	set dma_list ""
	# Get all connected frame buffer writers for this ISP
	set all_outips [get_all_connected_frmbuf_wr_for_isp $drv_handle $isp_id]
	set num_outips [llength $all_outips]
	set vcap_ports_node [create_node -n "ports" -l vcap_ports$sub_node_label -p $vcap -d $dts_file]
	add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
	add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file

	if {$num_outips == 2} {
		# Two outips (PO and SO) case
		set dma_list ""
		set dma_names_list {}
		for {set i 0} {$i < 2} {incr i} {
			set current_outip [lindex $all_outips $i]
			if {$i == 0} {
				set dma_list "<&$current_outip 0>"
			} else {
				append dma_list " , <&$current_outip 1>"
			}
			lappend dma_names_list "port$i"
		}
		add_prop $vcap "dmas" $dma_list noformating $dts_file
		add_prop $vcap "dma-names" $dma_names_list stringlist $dts_file

		# Create two input ports for vcap
		for {set i 0} {$i < 2} {incr i} {
			set outip_index [expr {$i == 0 ? 1 : 0}]
			set current_outip [lindex $all_outips $outip_index]
			set reg_value [expr {$i == 0 ? 1 : 0}]
			set vcap_port_node [create_node -n "port@$i" -l vcap_port${sub_node_label}_$i -p $vcap_ports_node -d $dts_file]
			add_prop "$vcap_port_node" "reg" $reg_value int $dts_file
			add_prop "$vcap_port_node" "direction" input string $dts_file
			set vcap_in_node [create_node -n "endpoint" -l ${current_outip}${sub_node_label} -p $vcap_port_node -d $dts_file]
			gen_endpoint $drv_handle "${current_outip}${sub_node_label}"
			add_prop "$vcap_in_node" "remote-endpoint" visp_out[expr {$outip_index+1}]$sub_node_label reference $dts_file
			gen_remoteendpoint $drv_handle "visp_out[expr {$outip_index+1}]$sub_node_label"
		}
	} elseif {$num_outips == 1} {
		# Single outip case
		set current_outip [lindex $all_outips 0]
		add_prop $vcap "dmas" "<&$current_outip 0>" noformating $dts_file
		add_prop $vcap "dma-names" "port0" string $dts_file

		set vcap_port_node [create_node -n "port@0" -l vcap_port$sub_node_label -p $vcap_ports_node -d $dts_file]
		add_prop "$vcap_port_node" "reg" 0 int $dts_file
		add_prop "$vcap_port_node" "direction" input string $dts_file
		set vcap_in_node [create_node -n "endpoint" -l ${current_outip}${sub_node_label} -p $vcap_port_node -d $dts_file]
		gen_endpoint $drv_handle "${current_outip}${sub_node_label}"
		add_prop "$vcap_in_node" "remote-endpoint" visp_out${port_addr_counter1}$sub_node_label reference $dts_file
		gen_remoteendpoint $drv_handle "visp_out$sub_node_label"
	} else {
		# No outip connected, fallback (do nothing or log)
		puts "No outip connected for ISP $isp_id"
	}
}
# Helper function to get all connected frame buffer writers for an ISP
proc get_all_connected_frmbuf_wr_for_isp {drv_handle isp_id} {
	set frmbuf_list {}
	# Calculate tile and isp from isp_id
	set tile [expr $isp_id / 2]
	set isp [expr $isp_id % 2]
	# For each ISP, check both PO and SO outputs
	foreach out_type {PO SO} {
		set intf "TILE${tile}_ISP${isp}_VIDOUT_${out_type}"
		set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]
		if {[llength $outip] > 0} {
			set outipname [hsi get_property IP_NAME $outip]
			if {[string match -nocase $outipname "v_frmbuf_wr"]} {
				lappend frmbuf_list $outip
			}
		}
	}
	return $frmbuf_list
}

proc find_valid_visp_inip {drv_handle visp_ip_name} {
	set visp_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $visp_ip_name]
	#puts "visp_inip:$visp_inip"
	set valid_patterns {.*(broadcaster|switch|mipi).*}

	# Loop until we find a valid IP or no new connections
	while {1} {
		set visp_list [split $visp_inip " "]
			set match_found 0
			set matched_ip ""

			foreach ip $visp_list {
				if {[regexp $valid_patterns $ip]} {
					set match_found 1
						set matched_ip $ip
						break
				}
			}

		if {$match_found} {
			#puts "DEBUG: Found VALID IP: $matched_ip"
			# Return the handle, not just name
			return [hsi::get_cells -hier $matched_ip]
		}

		set new_visp_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $visp_inip]
			if {$new_visp_inip eq $visp_inip} {
				break
			}
		set visp_inip $new_visp_inip
	}


	return ""
}

proc generate_reserved_memory {rpu_ids default_dts bus_name} {
	set reserved_mem_node [create_node -l "reserved_memory" -n "reserved_memory" -p $bus_name -d $default_dts]
    add_prop "$reserved_mem_node" "#address-cells" 2 int $default_dts
    add_prop "$reserved_mem_node" "#size-cells" 2 int $default_dts
    add_prop "$reserved_mem_node" "ranges" "" noformating $default_dts
	# Address mapping for RPU IDs
    set rpu_addr_map {
        6 {fw 0x0C000000 vring0 0x24FF8000 vring1 0x24FF9000 hal_priv 0x1114E000 load_calib 0x11126000}
        7 {fw 0x1214F000 vring0 0x24FFA000 vring1 0x24FFB000 hal_priv 0x1729D000 load_calib 0x17275000}
        8 {fw 0x1829E000 vring0 0x24FFC000 vring1 0x24FFD000 hal_priv 0x1D3EC000 load_calib 0x1D3C4000}
		9 {fw 0x1E3ED000 vring0 0x24FFE000 vring1 0x24FFF000 hal_priv 0x2353B000 load_calib 0x23513000}
    }
    foreach rpu_id $rpu_ids {
		if {![dict exists $rpu_addr_map $rpu_id]} {
            puts "Unknown RPU ID: $rpu_id - Skipping"
            continue
        }
        # Extract RPU memory regions dynamically
        set rpu_values [dict get $rpu_addr_map $rpu_id]
        set fw_addr [dict get $rpu_values fw]
        set vring0_addr [dict get $rpu_values vring0]
        set vring1_addr [dict get $rpu_values vring1]
        set hal_priv_addr [dict get $rpu_values hal_priv]
        set load_calib_addr [dict get $rpu_values load_calib]
		switch $rpu_id {
        6 {
            set rprocn "D_0_$rpu_id"
        }
        7 {
            set rprocn "D_1_$rpu_id"
        }
        8 {
            set rprocn "E_0_$rpu_id"
        }
        9 {
            set rprocn "E_1_$rpu_id"
		}
	}
		# Reserved firmware memory
        set rpu_fw_node [create_node -l "rproc_${rprocn}_reserved_rpu_fw" -n "rproc_${rpu_id}_reserved_rpu_fw" -p $reserved_mem_node -d $default_dts]
        add_prop "$rpu_fw_node" "no-map" "" noformating $default_dts
        add_prop "$rpu_fw_node" "reg" <[list 0x0 $fw_addr 0x0 0x5126000]> noformating $default_dts
        # calb_memory
        set load_calib_node [create_node -l "rproc_${rprocn}_calib_load" -n "rpu${rpu_id}_calib_load" -p $reserved_mem_node -d $default_dts]
        add_prop "$load_calib_node" "no-map" "" noformating $default_dts
        add_prop "$load_calib_node" "reg" <[list 0x0 $load_calib_addr 0x0 0x28000]> noformating $default_dts
        # HAL private memory
        set hal_mem_priv_node [create_node -l "rproc_${rprocn}_hal_mem_priv" -n "rpu${rpu_id}_hal_mem_priv" -p $reserved_mem_node -d $default_dts]
        add_prop "$hal_mem_priv_node" "no-map" "" noformating $default_dts
        add_prop "$hal_mem_priv_node" "reg" <[list 0x0 $hal_priv_addr 0x0 0x01001000]> noformating $default_dts
		# VRing 0
        set vring0_node [create_node -l "rproc_${rprocn}vdev0vring0" -n "rpu${rpu_id}vdev0vring0" -p $reserved_mem_node -d $default_dts]
        add_prop "$vring0_node" "no-map" "" noformating $default_dts
        add_prop "$vring0_node" "reg" <[list 0x0 $vring0_addr 0x0 0x1000]> noformating $default_dts
        # VRing 1
        set vring1_node [create_node -l "rproc_${rprocn}vdev0vring1" -n "rpu${rpu_id}vdev0vring1" -p $reserved_mem_node -d $default_dts]
        add_prop "$vring1_node" "no-map" "" noformating $default_dts
        add_prop "$vring1_node" "reg" <[list 0x0 $vring1_addr 0x0 0x1000]> noformating $default_dts
    }
	set rpu_mbox_node [create_node -l "isp_mbox_buffer" -n "isp_mbox_buffer@2453C000" -p $reserved_mem_node -d $default_dts]
	add_prop "$rpu_mbox_node" "no-map" "" noformating $default_dts
    add_prop "$rpu_mbox_node" "reg" [list 0x0 0x2453C000 0x0 0x400000] hexlist $default_dts
	set rpu_share_mem_node [create_node -l "rpu_shared_mem" -n "rpu_shared_mem@2493C000" -p $reserved_mem_node -d $default_dts]
	add_prop "$rpu_share_mem_node" "no-map" "" noformating $default_dts
    add_prop "$rpu_share_mem_node" "reg" [list 0x0 0x2493C000 0x0 0x6C3FFF] hexlist $default_dts
}

proc generate_remoteproc_node {rpu_ids default_dts bus_name} {
    set unique_rpu_ids [lsort -unique $rpu_ids]
    set cluster_count 0
    #set base_addr 0xebac0000
	set base_addr 0xebb80000
	set base_addr1 0xebac0000
    set rpu_list [list]

    foreach rpu_id $unique_rpu_ids {
        lappend rpu_list $rpu_id
        if {[llength $rpu_list] == 2} {
            set cluster_label "versal2_r52f_cluster${cluster_count}_split"
            set cluster_addr [format 0x%08x [expr {$base_addr + ($cluster_count * 0x100000)}]]
			set cluster_addr1 [format remoteproc@%08x [expr {$base_addr1 + ($cluster_count * 0x100000)}]]

            # Create remoteproc cluster node
            set remoteproc_node [create_node -l $cluster_label -n "$cluster_addr1" -p $bus_name -d $default_dts]
            add_prop "$remoteproc_node" "compatible" "xlnx,versal2-r52fss" string $default_dts
            add_prop "$remoteproc_node" "#address-cells" 2 int $default_dts
            add_prop "$remoteproc_node" "#size-cells" 2 int $default_dts
            add_prop "$remoteproc_node" "xlnx,cluster-mode" 0 int $default_dts

            # Define ranges dynamically based on RPU IDs
            set ranges [list]
            set rpu_id1 [lindex $rpu_list 0]
            set rpu_id2 [lindex $rpu_list 1]

            foreach {rpu_id offset} [list $rpu_id1 0 $rpu_id2 0x20000] {
                lappend ranges [format "<0x%x 0x0 0x0 0x%08x 0x0 0x10000>" $rpu_id [expr {$cluster_addr + $offset}]]
                lappend ranges [format "<0x%x 0x10000 0x0 0x%08x 0x0 0x8000>" $rpu_id [expr {$cluster_addr + $offset + 0x10000}]]
                lappend ranges [format "<0x%x 0x18000 0x0 0x%08x 0x0 0x8000>" $rpu_id [expr {$cluster_addr + $offset + 0x20000}]]
            }
            add_prop "$remoteproc_node" "ranges" [join $ranges ", "] noformating $default_dts


            # Generate R5F nodes
            generate_r5f_node $rpu_id1 $remoteproc_node $default_dts
            generate_r5f_node $rpu_id2 $remoteproc_node $default_dts

            # Reset list and increment cluster count
            set rpu_list [list]
            incr cluster_count
        }
    }

    # Handle an unpaired RPU ID
    if {[llength $rpu_list] == 1} {
        set rpu_id1 [lindex $rpu_list 0]
        set cluster_label "versal2_r52f_cluster${cluster_count}_split"
        set cluster_addr [format 0x%08x [expr {$base_addr + ($cluster_count * 0x40000)}]]
        set cluster_addr1 [format remoteproc@%08x [expr {$base_addr + ($cluster_count * 0x40000)}]]

        set remoteproc_node [create_node -l $cluster_label -n "$cluster_addr1" -p $bus_name -d $default_dts]
        add_prop "$remoteproc_node" "compatible" "xlnx,versal2-r52fss" string $default_dts
        add_prop "$remoteproc_node" "#address-cells" 2 int $default_dts
        add_prop "$remoteproc_node" "#size-cells" 2 int $default_dts
        add_prop "$remoteproc_node" "xlnx,cluster-mode" 0 int $default_dts

        # Define ranges for single-node cluster
        set ranges [list]
        set offset 0
        lappend ranges [format "<0x%x 0x0 0x0 0x%08x 0x0 0x10000>" $rpu_id1 [expr {$cluster_addr + $offset}]]
        lappend ranges [format "<0x%x 0x10000 0x0 0x%08x 0x0 0x8000>" $rpu_id1 [expr {$cluster_addr + $offset + 0x10000}]]
        lappend ranges [format "<0x%x 0x18000 0x0 0x%08x 0x0 0x8000>" $rpu_id1 [expr {$cluster_addr + $offset + 0x20000}]]
        add_prop "$remoteproc_node" "ranges" [join $ranges ", "] noformating $default_dts

        generate_r5f_node $rpu_id1 $remoteproc_node $default_dts
    }
}


proc generate_r5f_node {rpu_id parent_node default_dts} {
    set r5f_label "r52f_${rpu_id}"
    set r5f_node [create_node -l $r5f_label -n "$r5f_label" -p $parent_node -d $default_dts]
    add_prop "$r5f_node" "compatible" "xlnx,versal2-r52f" string $default_dts
	# Define reg properties based on index
    set base_offset [expr {$rpu_id * 0x40000}]
    set reg [list \
        [format "<0x%x 0x0 0x0 0x10000>" $rpu_id] \
        [format "<0x%x 0x10000 0x0 0x8000>" $rpu_id] \
        [format "<0x%x 0x18000 0x0 0x8000>" $rpu_id]
    ]
    add_prop "$r5f_node" "reg" [join $reg ", "] noformating $default_dts
    add_prop "$r5f_node" "reg-names" "atcm, btcm, ctcm" string $default_dts
	switch $rpu_id {
        6 {
            set rprocn "D_0_$rpu_id"
        }
        7 {
            set rprocn "D_1_$rpu_id"
        }
        8 {
            set rprocn "E_0_$rpu_id"
        }
        9 {
            set rprocn "E_1_$rpu_id"
		}
	}
    # Define memory regions
    set memory_regions [list \
        "&rproc_${rprocn}_reserved_rpu_fw" \
        "&rproc_${rprocn}_hal_mem_priv" \
        "&rproc_${rprocn}vdev0vring0" \
        "&rproc_${rprocn}vdev0vring1"
    ]
    set formatted_memory_regions [join [lmap region $memory_regions {format "<%s>" $region}] ", "]
    add_prop "$r5f_node" "memory-region" $formatted_memory_regions noformating $default_dts
	switch $rpu_id {
        6 {
            set power_domains "<&versal2_firmware PM_DEV_RPU_D_0>, <&versal2_firmware PM_DEV_TCM_D_0A>, <&versal2_firmware PM_DEV_TCM_D_0B>, <&versal2_firmware PM_DEV_TCM_D_0C>"
        }
        7 {
            set power_domains "<&versal2_firmware PM_DEV_RPU_D_1>, <&versal2_firmware PM_DEV_TCM_D_1A>, <&versal2_firmware PM_DEV_TCM_D_1B>, <&versal2_firmware PM_DEV_TCM_D_1C>"
        }
        8 {
            set power_domains "<&versal2_firmware PM_DEV_RPU_E_0>, <&versal2_firmware PM_DEV_TCM_E_0A>, <&versal2_firmware PM_DEV_TCM_E_0B>, <&versal2_firmware PM_DEV_TCM_E_0C>"
        }
        9 {
            set power_domains "<&versal2_firmware PM_DEV_RPU_E_1>, <&versal2_firmware PM_DEV_TCM_E_1A>, <&versal2_firmware PM_DEV_TCM_E_1B>, <&versal2_firmware PM_DEV_TCM_E_1C>"
		}
	}
	#add_prop "$r5f_node" "power-domains" $power_domains noformating $default_dts
}

proc generate_tcm_nodes {rpu_ids default_dts bus_name} {
    # Define base addresses and sizes for TCMs
	set tcm_nodes {
		6 0xeb5b8000
		7 0xeb5bc000
		8 0xeb5c8000
		9 0xeb5cc000
    }
    set tcm_size 0x40000  ; # 256 KB
	foreach {rpu_id tcm_nodes1} $tcm_nodes {
        # Calculate base address for each RPU's TCM
		if {$rpu_id in $rpu_ids} {
			set size [format "0x%X" $tcm_size]
			set label "tcm_rpu${rpu_id}"
			set name "tcm_rpu${rpu_id}@$tcm_nodes1"
			# Create the node under reserved-memory
			set tcm_node [create_node -l $label -n $name -p $bus_name -d $default_dts]
			# Add properties to the node
			add_prop $tcm_node compatible "mmio-sram" string $default_dts
			add_prop $tcm_node reg "0x0 $tcm_nodes1 0x0 $size" hexlist $default_dts
			add_prop $tcm_node no-map "" noformating $default_dts
			add_prop $tcm_node status "okay" string $default_dts
		}
	}
}

proc generate_mbox_nodes {rpu_info_list default_dts bus_name} {
    # Map to collect compatible strings per rpu_id
    array set compat_map {}

    # Map rpu_id to child label (child0..child3)
    array set rpu_to_child {
        6 child0
        7 child1
        8 child2
        9 child3
    }

    foreach rpu_info $rpu_info_list {
        lassign $rpu_info rpu_id io_type

        # Determine compatible string based on io_type
        if {$io_type == 3} {
            set compat_str "xlnx,mimo-mbox"
        } elseif {$io_type == 1 || $io_type == 2} {
            set compat_str "xlnx,mbox"
        } else {
            puts "Warning: Invalid io_type '$io_type' for RPU $rpu_id. Skipping mbox node creation."
            continue
        }

        # Collect unique compatible strings per rpu_id
        if {[info exists compat_map($rpu_id)]} {
            if {[lsearch -exact $compat_map($rpu_id) $compat_str] == -1} {
                lappend compat_map($rpu_id) $compat_str
            }
        } else {
            set compat_map($rpu_id) [list $compat_str]
        }
    }

    # Create one mbox node per rpu_id
    foreach rpu_id [array names compat_map] {
        set mbox_label "visp_mbox_rpu_${rpu_id}"
        set mbox_name "visp_mbox_rpu_${rpu_id}"
        set compat_list $compat_map($rpu_id)

        puts "Creating mbox node for RPU $rpu_id with compatible: $compat_list"

        set mbox_node [create_node -l $mbox_label -n $mbox_name -p $bus_name -d $default_dts]
        add_prop "$mbox_node" "compatible" $compat_list stringlist $default_dts
        add_prop "$mbox_node" "rpu_id" $rpu_id int $default_dts
        add_prop "$mbox_node" "mbox-names" [list "tx" "rx"] stringlist $default_dts
        add_prop "$mbox_node" "status" "okay" string $default_dts

        # Add mboxes property referencing the correct child node
        if {[info exists rpu_to_child($rpu_id)]} {
            set child_label $rpu_to_child($rpu_id)
            #add_prop "$mbox_node" "mboxes" "<&${child_label} 0>, <&${child_label} 1>" noformating $default_dts
			if {$rpu_id == 6} {
				set ipi_cell [hsi get_cells -hier ps_wizard_0_ps11_0_ipi_3_nobuf]
				if {[llength $ipi_cell] > 0} {
					set cpu_name [hsi get_property CONFIG.C_CPU_NAME $ipi_cell]
					if {$cpu_name eq "R52_6"} {
						add_prop "$mbox_node" "mboxes" "<&ipi_5_to_ipi_3_nobuf 0x0>, <&ipi_5_to_ipi_3_nobuf 0x1>" noformating $default_dts
					} else {
						puts "Warning: IPI for RPU6 found but CPU name mismatch (got $cpu_name). IPI not enabled in your design."
					}
				} else {
					puts "Warning: IPI for RPU6 not enabled in your design."
				}
			}

			if {$rpu_id == 7} {
				set ipi_cell [hsi get_cells -hier ps_wizard_0_ps11_0_ipi_4_nobuf]
				if {[llength $ipi_cell] > 0} {
					set cpu_name [hsi get_property CONFIG.C_CPU_NAME $ipi_cell]
					if {$cpu_name eq "R52_7"} {
						add_prop "$mbox_node" "mboxes" "<&ipi_5_to_ipi_4_nobuf 0x0>, <&ipi_5_to_ipi_4_nobuf 0x1>" noformating $default_dts
					} else {
						puts "Warning: IPI for RPU7 found but CPU name mismatch (got $cpu_name). IPI not enabled in your design."
					}
				} else {
					puts "Warning: IPI for RPU7 not enabled in your design."
				}
			}

			if {$rpu_id == 8} {
				set ipi_cell [hsi get_cells -hier ps_wizard_0_ps11_0_ipi_5_nobuf]
				if {[llength $ipi_cell] > 0} {
					set cpu_name [hsi get_property CONFIG.C_CPU_NAME $ipi_cell]
					if {$cpu_name eq "R52_8"} {
						add_prop "$mbox_node" "mboxes" "<&ipi_6_to_ipi_5_nobuf 0x0>, <&ipi_6_to_ipi_5_nobuf 0x1>" noformating $default_dts
					} else {
						puts "Warning: IPI for RPU8 found but CPU name mismatch (got $cpu_name). IPI not enabled in your design."
					}
				} else {
					puts "Warning: IPI for RPU8 not enabled in your design."
				}
			}

			if {$rpu_id == 9} {
				set ipi_cell [hsi get_cells -hier ps_wizard_0_ps11_0_ipi_6_nobuf]
				if {[llength $ipi_cell] > 0} {
					set cpu_name [hsi get_property CONFIG.C_CPU_NAME $ipi_cell]
					if {$cpu_name eq "R52_9"} {
						add_prop "$mbox_node" "mboxes" "<&ipi_6_to_ipi_6_nobuf 0x0>, <&ipi_6_to_ipi_6_nobuf 0x1>" noformating $default_dts
					} else {
						puts "Warning: IPI for RPU9 found but CPU name mismatch (got $cpu_name). IPI not enabled in your design."
					}
				} else {
					puts "Warning: IPI for RPU9 not enabled in your design."
				}
			}

        } else {
            puts "Warning: No child label mapping found for rpu_id=$rpu_id. Skipping mboxes property."
        }

        #add_prop "$mbox_node" "memory-region" "<&isp_mbox_buffer>" noformating $default_dts
    }
}


proc generate_ipi_mailbox_nodes {rpu_ids default_dts bus_name} {
    set ipi_node [create_node -n "ipi_nobuf1" -p $bus_name -d $default_dts]
	add_prop "$ipi_node" "status" "okay" string $default_dts
	set ipi_base_id 6
	set rpu_base_addresses {
		6 12 0xeb3b2000
		7 13 0xeb3b3000
		8 14 0xeb3b4000
		9 15 0xeb3b5000
	}
	set reg_size 0x1000
	foreach {rpu_id ipi_id rpu_base_addresses1} $rpu_base_addresses {
        if {$rpu_id in $rpu_ids} {
            set mailbox_label "ipi_mailbox_rpu${rpu_id}"
	    set mailbox_name [format "mailbox@%08x" [expr {$rpu_base_addresses1}]]
            set mailbox_node [create_node -l $mailbox_label -n $mailbox_name -p $ipi_node -d $default_dts]
            add_prop $mailbox_node "xlnx,ipi-id" $ipi_id int $default_dts
	    add_prop $mailbox_node reg "0x0 $rpu_base_addresses1 0x0 $reg_size" hexlist $default_dts
            add_prop $mailbox_node "reg-names" "ctrl" string $default_dts
        }
    }
}
