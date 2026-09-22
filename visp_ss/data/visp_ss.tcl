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
	set prefix "CONFIG.C_TILE${tile_index}_ISP${isp_index}_OBA${oba_index}_"
	set mp_data_format ""
	foreach fmt {YUV420 YUV422} {
		if {[get_ip_property $drv_handle "${prefix}MP_${fmt}"] eq "true"} {
			set mp_data_format $fmt
			break
		}
	}
	set mp_bpp [get_ip_property $drv_handle "${prefix}MP_BPP"]
	set mp_ppc [get_ip_property $drv_handle "${prefix}PPC"]
	add_prop "$port_node" "xlnx,oba${oba_index}_mp_bpp" $mp_bpp int $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_mp_data_format" $mp_data_format string $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_mp_ppc" $mp_ppc int $dts_file
}


#OBA_SP
proc add_oba_properties_sp {drv_handle port_node dts_file isp_index oba_index tile_index} {
	set prefix "CONFIG.C_TILE${tile_index}_ISP${isp_index}_OBA${oba_index}_"
	set sp_data_format ""
	foreach fmt {YUV420 YUV422} {
		if {[get_ip_property $drv_handle "${prefix}SP_${fmt}"] eq "true"} {
			set sp_data_format $fmt
			break
		}
	}
	set sp_bpp [get_ip_property $drv_handle "${prefix}SP_BPP"]
	set sp_ppc [get_ip_property $drv_handle "${prefix}PPC"]
	add_prop "$port_node" "xlnx,oba${oba_index}_sp_bpp" $sp_bpp int $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_sp_data_format" $sp_data_format string $dts_file
	add_prop "$port_node" "xlnx,oba${oba_index}_sp_ppc" $sp_ppc int $dts_file
}


#IMAGE SPLITTER STITCHER
proc add_splitter_stitcher_properties {drv_handle node dts_file rpu} {
	set prefix "CONFIG.C_IMAGE_SPLITTER_STITCHER_"
	set enable [get_ip_property $drv_handle "${prefix}ENABLE"]
	# IP cores predating this parameter return "" here; skip before any numeric test
	if {$enable eq ""} {
		return
	}
	if {![string match -nocase "true" $enable] && $enable ne "1"} {
		return
	}
	set ss_rpu [get_ip_property $drv_handle "${prefix}RPU"]
	# A valid RPU that just doesn't match this ISP node is the normal per-ISP
	# case (skipped silently); an out-of-range RPU is a misconfiguration.
	if {[lsearch -exact {6 7 8 9} $ss_rpu] < 0} {
		dtg_warning "$drv_handle: invalid C_IMAGE_SPLITTER_STITCHER_RPU '$ss_rpu'; splitter/stitcher properties not emitted"
		return
	}
	if {$ss_rpu ne $rpu} {
		return
	}
	# Emit every image splitter/stitcher parameter; booleans as 1/0
	set bool_params {ENABLE RGB888 Y YUV422 YUV420}
	foreach {param prop} {
		ENABLE      xlnx,image-splitter-stitcher-enable
		DATA_FORMAT xlnx,image-splitter-stitcher-data-format
		HRES        xlnx,image-splitter-stitcher-hres
		VRES        xlnx,image-splitter-stitcher-vres
		RPU         xlnx,image-splitter-stitcher-rpu
		VCID        xlnx,image-splitter-stitcher-vcid
		RGB888      xlnx,image-splitter-stitcher-rgb888
		Y           xlnx,image-splitter-stitcher-y
		YUV422      xlnx,image-splitter-stitcher-yuv422
		YUV420      xlnx,image-splitter-stitcher-yuv420
	} {
		set val [get_ip_property $drv_handle "${prefix}${param}"]
		if {[lsearch -exact $bool_params $param] >= 0} {
			set val [expr {([string match -nocase "true" $val] || $val eq "1") ? 1 : 0}]
		}
		add_prop "$node" $prop $val int $dts_file
	}
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

	rpu_info_mbox_create  $drv_handle $default_dts $bus_name

	# Pre-pass: group LIMO ISPs that resolve to the same ultimate upstream
	# source (MIPI, or a broadcaster/switch that is itself fed by a common
	# MIPI) so they can share a single visp_video node below. Must run before
	# any node creation, and as a single upfront pass over ALL tiles/isps, so
	# that transitive ("diamond") sharing - e.g. isp C sharing separately with
	# both isp A and isp B - correctly links A and B into one group too,
	# rather than only being discovered after A's and B's nodes already exist.
	set visp_video_dsu [dict create]
	set visp_video_upstream_owner [dict create]
	for {set ptile 0} {$ptile < 3} {incr ptile} {
		if {![get_ip_property $drv_handle "CONFIG.C_TILE${ptile}_ENABLE"]} {
			continue
		}
		set pconfig_only [get_ip_property $drv_handle "CONFIG.C_CONFIG_ONLY"]
		if {[string match -nocase $pconfig_only "true"] || $pconfig_only == 1} {
			continue
		}
		for {set pisp 0} {$pisp < 2} {incr pisp} {
			set pisp_id [expr {$ptile * 2 + $pisp}]
			set pio_type [get_ip_property $drv_handle CONFIG.C_TILE${ptile}_ISP${pisp}_IO_TYPE]
			if {$pio_type != 2} {
				continue
			}
			set plive_stream [get_ip_property $drv_handle CONFIG.C_TILE${ptile}_ISP${pisp}_LIVE_INPUTS]
			foreach vidin [get_isp_input_vidins $pisp $plive_stream] {
				set p_first_hop [find_valid_visp_inip $drv_handle "TILE${ptile}_ISP_MIPI_VIDIN${vidin}"]
				if {![llength $p_first_hop]} {
					continue
				}
				set p_source [resolve_ultimate_visp_source [lindex $p_first_hop 0]]
				if {![llength $p_source]} {
					continue
				}
				dsu_find visp_video_dsu $pisp_id
				if {[dict exists $visp_video_upstream_owner $p_source]} {
					dsu_union visp_video_dsu $pisp_id [dict get $visp_video_upstream_owner $p_source]
				} else {
					dict set visp_video_upstream_owner $p_source $pisp_id
				}
			}
		}
	}
	global visp_video_leader
	set visp_video_leader [dict create]
	dict for {leaf_isp_id unused_val} $visp_video_dsu {
		dict set visp_video_leader $leaf_isp_id [dsu_find visp_video_dsu $leaf_isp_id]
	}
	global visp_video_node_by_leader
	set visp_video_node_by_leader [dict create]

	# Same grouping, scoped to LILO (io_type==1) and LIMxO (io_type==4) -
	# LIMxO's live input side is identical to LILO's (single fixed pin per
	# isp, no live_stream variability), and its live *output* port (whichever
	# of MP/SP isn't memory-out) goes through the same vcap_<label> node
	# convention via visp_ss_lilo_link_frmbufs, so a LILO/LIMxO pair sharing
	# an upstream broadcaster must be grouped and merged exactly like two
	# LILO ISPs - no diff between the two modes for merge-node purposes.
	# This is a separate pass rather than reusing get_isp_input_vidins since
	# both modes use a single fixed pin, not live_stream variability. Kept
	# in its own dsu/leader/node maps so this group and LIMO's never mix
	# (they use different downstream node conventions: vcap_<label> vs
	# visp_video_<id>).
	set visp_lilo_dsu [dict create]
	set visp_lilo_upstream_owner [dict create]
	for {set ptile 0} {$ptile < 3} {incr ptile} {
		if {![get_ip_property $drv_handle "CONFIG.C_TILE${ptile}_ENABLE"]} {
			continue
		}
		set pconfig_only [get_ip_property $drv_handle "CONFIG.C_CONFIG_ONLY"]
		if {[string match -nocase $pconfig_only "true"] || $pconfig_only == 1} {
			continue
		}
		for {set pisp 0} {$pisp < 2} {incr pisp} {
			set pisp_id [expr {$ptile * 2 + $pisp}]
			set pio_type [get_ip_property $drv_handle CONFIG.C_TILE${ptile}_ISP${pisp}_IO_TYPE]
			if {$pio_type != 1 && $pio_type != 4} {
				continue
			}
			if {$pisp == 0} {
				set p_pin_name "TILE${ptile}_ISP_MIPI_VIDIN0"
			} else {
				set p_pin_name "TILE${ptile}_ISP_MIPI_VIDIN4"
			}
			set p_first_hop [find_valid_visp_inip $drv_handle $p_pin_name]
			if {![llength $p_first_hop]} {
				continue
			}
			set p_source [resolve_ultimate_visp_source [lindex $p_first_hop 0]]
			if {![llength $p_source]} {
				continue
			}
			dsu_find visp_lilo_dsu $pisp_id
			if {[dict exists $visp_lilo_upstream_owner $p_source]} {
				dsu_union visp_lilo_dsu $pisp_id [dict get $visp_lilo_upstream_owner $p_source]
			} else {
				dict set visp_lilo_upstream_owner $p_source $pisp_id
			}
		}
	}
	global visp_lilo_leader
	set visp_lilo_leader [dict create]
	dict for {leaf_isp_id unused_val} $visp_lilo_dsu {
		dict set visp_lilo_leader $leaf_isp_id [dsu_find visp_lilo_dsu $leaf_isp_id]
	}
	global visp_lilo_vcap_by_leader
	set visp_lilo_vcap_by_leader [dict create]

	set reg_mapping {}
	for {set tile 0} {$tile < 3} {incr tile} {
		set tile_enabled [get_ip_property $drv_handle "CONFIG.C_TILE${tile}_ENABLE"]
		if {!$tile_enabled} {
			continue
		}
		# Skip visp_ss sub-node creation for config-only IP instances.
		# In config-only mode only the config path is enabled (no ISP processing).
		# Skipping avoids inflating XPAR_XVISP_SS_NUM_INSTANCES with non-functional nodes.
		set config_only [get_ip_property $drv_handle "CONFIG.C_CONFIG_ONLY"]
		if {[string match -nocase $config_only "true"] || $config_only == 1} {
			continue
		}
		for {set isp 0} {$isp < 2} {incr isp} {
			set isp_id [expr {$tile * 2 + $isp}]
			# Read io_type early so we can skip ISPs with no valid mode (0 = not configured).
			# This prevents generating a dummy "xlnx,visp-disabled" node for unused ISPs.
			# 4 = LIMxO (Live Input, Mixed Output) - input side behaves like LILO.
			set io_type [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_IO_TYPE]
			if {$io_type != 1 && $io_type != 2 && $io_type != 3 && $io_type != 4} {
				continue
			}
			set sub_node_label "visp_ss_${tile}${isp_id}"
			set baseaddr [get_visp_baseaddr $drv_handle]
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
			set io_mode $io_type
			if {$io_type == 1} {
				set io_mode_name "lilo"
			} elseif {$io_type == 2} {
				set io_mode_name "limo"
			} elseif {$io_type == 3} {
				set io_mode_name "mimo"
			} elseif {$io_type == 4} {
				set io_mode_name "limxo"
			} else {
				set io_mode_name "Unknown"
			}
			set live_inputs [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_LIVE_INPUTS]
			set mem_inputs [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_MEM_INPUTS]
			set net_fps [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_NETFPS]
			set rpu [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_RPU]
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
			add_splitter_stitcher_properties $drv_handle $sub_node $default_dts $rpu
			set llpath_tile_num [expr {int([get_ip_property $drv_handle CONFIG.C_LLPATH${isp}_TILE])}]
			if { $llpath_tile_num < 3 && $llpath_tile_num >=0 && $llpath_tile_num == ${tile} } {
				add_prop "$sub_node" "xlnx,llpath${isp}-tile${llpath_tile_num}-enabled" "" noformating $default_dts
				add_prop "$sub_node" "xlnx,llpath${isp}-oba" [get_ip_property $drv_handle CONFIG.C_LLPATH${isp}_OBA] int $default_dts
				add_prop "$sub_node" "xlnx,llpath${isp}-iba" [get_ip_property $drv_handle CONFIG.C_LLPATH${isp}_IBA] int $default_dts
            }
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
			} elseif {$io_type == 4} {
				set compatible_name "xlnx,visp-ss-limxo-1.0"
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
	#generate_mbox_nodes $rpu_info_list $default_dts $bus_name
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

	# Look up the merge group computed by the pre-pass in visp_ss_generate.
	# The leader (lowest isp_id in the group) is always processed first by
	# the tile/isp loop there, so its visp_video node is guaranteed to
	# already exist by the time a follower ISP reaches this point.
	global visp_video_leader
	global visp_video_node_by_leader
	set leader_isp_id $isp_id
	if {[info exists visp_video_leader] && [dict exists $visp_video_leader $isp_id]} {
		set leader_isp_id [dict get $visp_video_leader $isp_id]
	}

	if {[info exists visp_video_node_by_leader] && [dict exists $visp_video_node_by_leader $leader_isp_id]} {
		set shared_info [dict get $visp_video_node_by_leader $leader_isp_id]
		set vcp_node        [lindex $shared_info 0]
		set vcap_ports_node [lindex $shared_info 1]
		set reg_counter     [lindex $shared_info 2]
	} else {
		set vcp_node [create_vcp_node $sub_node $default_dts $isp_id $bus_name]
		set vcap_ports_node [create_node -l "vcap_ports${tile}${isp_id}" -n "ports" -p $vcp_node -d $default_dts]
		add_prop "$vcap_ports_node" "#address-cells" 1 int $default_dts
		add_prop "$vcap_ports_node" "#size-cells" 0 int $default_dts
		set reg_counter 0
	}

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

	# Persist the node handles and updated reg_counter under this group's
	# leader so a later follower ISP in the same group reuses this node.
	dict set visp_video_node_by_leader $leader_isp_id [list $vcp_node $vcap_ports_node $reg_counter]
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
	# Link any frame buffer writer(s) feeding from this ISP's output(s) into
	# the shared vcap node for its LILO merge group (creates the group's vcap
	# node on the leader's first call, reuses/extends it for followers).
	visp_ss_lilo_link_frmbufs $drv_handle $default_dts $sub_node_label $isp_id
	add_iba_properties $drv_handle $sub_node $default_dts $isp $isp_iba $tile
	# Add OBA properties
	add_oba_properties_mp $drv_handle $sub_node $default_dts $isp $isp $tile
	add_oba_properties_sp $drv_handle $sub_node $default_dts $isp $isp $tile
}

# IO_MODE==4 (LIMxO): Live Input, Mixed Output.
# Input side is identical to LILO (single live input, non-MCM only).
# Output side: exactly one of MP/SP is configured live (routed to a
# memory-mapped downstream IP exactly like LILO, via visp_ss_outip_endpoints /
# its vcap_<label> node), and the other is configured memory-out - its port
# node is created with no OF-graph endpoint, and a visp_video_<isp_id> node
# binds to it purely by phandle (visp,source-subdev/visp,source-pad) so that
# xilinx-vipp's live-path pipeline walk (rooted at the vcap_<label> node)
# never traverses into the memory-out link and can't abort on it. DRC at the
# IP level guarantees MP and SP are never both live or both memory at once.
proc handle_io_mode_4 {drv_handle tile isp isp_id default_dts sub_node sub_node_label bus_name} {
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

	# Unlike MP_BPP/SP_BPP, ENABLE_MP_MEM/ENABLE_SP_MEM are NOT OBA-indexed -
	# confirmed directly against HSI CONFIG properties on this IP.
	set prefix "CONFIG.C_TILE${tile}_ISP${isp}_"
	set mp_mem_val [get_ip_property $drv_handle "${prefix}ENABLE_MP_MEM"]
	set sp_mem_val [get_ip_property $drv_handle "${prefix}ENABLE_SP_MEM"]
	set mp_is_mem [expr {([string match -nocase "true" $mp_mem_val] || $mp_mem_val eq "1") ? 1 : 0}]
	set sp_is_mem [expr {([string match -nocase "true" $sp_mem_val] || $sp_mem_val eq "1") ? 1 : 0}]

	if {$mp_is_mem == $sp_is_mem} {
		dtg_warning "$sub_node_label: LIMxO expects exactly one of MP/SP to be memory-out (ENABLE_MP_MEM=$mp_is_mem ENABLE_SP_MEM=$sp_is_mem) - check DRC coverage"
	}

	# index0=MP, index1=SP; 1=live-out (FBWR via xilinx-vipp), 0=memory-out (visp_video)
	add_prop "$sub_node" "xlnx,path_out_type" [list [expr {$mp_is_mem ? 0 : 1}] [expr {$sp_is_mem ? 0 : 1}]] hexinttuple $default_dts

	foreach out_type {PO SO} is_mem [list $mp_is_mem $sp_is_mem] {
		if {$is_mem} {
			# Memory-out: port node only, no endpoint - bound to visp_video_<isp_id>
			# purely by phandle so the live-path vcap pipeline walk never reaches it.
			set type [expr {$port_addr_counter1 == 1 ? "po" : "so"}]
			set mem_port [create_node -l "visp_port${port_addr_counter1}_${type}_${isp_id}" -n "port@${port_addr_counter1}" -p $ports_node -d $default_dts]
			add_prop "$mem_port" "reg" $port_addr_counter1 int $default_dts
			add_prop "$mem_port" "direction" output string $default_dts

			set vcp_node [create_node -l visp_video_${isp_id} -n "visp_video_${isp_id}" -p $bus_name -d $default_dts]
			add_prop "$vcp_node" "compatible" "xlnx,visp-video" string $default_dts
			add_prop "$vcp_node" "id" $isp_id int $default_dts
			add_prop "$vcp_node" "visp,source-subdev" $sub_node_label reference $default_dts
			add_prop "$vcp_node" "visp,source-pad" $port_addr_counter1 int $default_dts
		} else {
			set intf "TILE${tile}_ISP${isp}_VIDOUT_${out_type}"
			set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]
			if {[string length $outip] > 0} {
				visp_ss_outip_endpoints $drv_handle $default_dts $sub_node_label $outip $port_addr_counter1 $ports_node $isp_id
			}
		}
		incr port_addr_counter1
	}

	# Link this ISP's live-out frame buffer writer into the shared vcap node
	# for its LILO/LIMxO merge group - same call, same grouping as LILO (see
	# handle_io_mode_1), so a LIMxO ISP sharing an upstream broadcaster with
	# a LILO (or another LIMxO) ISP gets merged identically. The memory-out
	# port above was never given an OF-graph endpoint and get_all_connected_
	# frmbuf_wr_for_isp() excludes it, so only the live port's frmbuf_wr is
	# ever linked here.
	visp_ss_lilo_link_frmbufs $drv_handle $default_dts $sub_node_label $isp_id

	add_iba_properties $drv_handle $sub_node $default_dts $isp $isp_iba $tile
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
		} elseif {$io_mode == 4} {
			# LIMxO (Live Input, Mixed Output): input side identical to LILO;
			# output side mixes one live + one memory-out path (see
			# handle_io_mode_4 for details).
			handle_io_mode_4 $drv_handle $tile $isp $isp_id $default_dts $sub_node $sub_node_label $bus_name
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

						set broadcaster_ep_created 0
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
									set broadcaster_ep_created 1
									if {[llength $mipi_in_end]} {
										add_prop "$mipi_node" "remote-endpoint" $mipi_in_end reference $default_dts
									}
								}
							}
						}
						# broadcaster dicts (port*_broad_end_mappings) are populated by
						# axis_broadcaster_update_endpoints which runs after all _generate procs.
						# Defer if nothing was created yet.
						if {!$broadcaster_ep_created} {
							global visp_pending_endpoints
							if {![info exists visp_pending_endpoints]} { set visp_pending_endpoints {} }
							lappend visp_pending_endpoints [list broadcaster $port_node $inip $default_dts $sub]
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
					set switch_nomem_ep_created 0
					if {[info exists visp_remo_in_end] && [regexp -nocase $sub "$visp_remo_in_end" match]} {
						if {[llength $visp_remo_in_end]} {
							set visp_ss_node [create_node -n "endpoint" -l $visp_remo_in_end -p $port_node -d $default_dts]
							set switch_nomem_ep_created 1
							if {[llength $visp_in_end]} {
								add_prop "$visp_ss_node" "remote-endpoint" $visp_in_end reference $default_dts
							}
						}
					}

					if {[info exists visp_remo_in1_end] && [regexp -nocase $sub "$visp_remo_in1_end" match]} {
						if {[llength $visp_remo_in1_end]} {
							set visp_ss_node1 [create_node -n "endpoint" -l $visp_remo_in1_end -p $port_node -d $default_dts]
							set switch_nomem_ep_created 1
							if {[llength $visp_in1_end]} {
								add_prop "$visp_ss_node1" "remote-endpoint" $visp_in1_end reference $default_dts
							}
						}
					}

					if {[info exists visp_remo_in2_end] && [regexp -nocase $sub "$visp_remo_in2_end" match]} {
						if {[llength $visp_remo_in2_end]} {
							set visp_ss_node2 [create_node -n "endpoint" -l $visp_remo_in2_end -p $port_node -d $default_dts]
							set switch_nomem_ep_created 1
							if {[llength $visp_in2_end]} {
								add_prop "$visp_ss_node2" "remote-endpoint" $visp_in2_end reference $default_dts
							}
						}
					}

					if {[info exists visp_remo_in3_end] && [regexp -nocase $sub "$visp_remo_in3_end" match]} {
						if {[llength $visp_remo_in3_end]} {
							set visp_ss_node3 [create_node -n "endpoint" -l $visp_remo_in3_end -p $port_node -d $default_dts]
							set switch_nomem_ep_created 1
							if {[llength $visp_in3_end]} {
								add_prop "$visp_ss_node3" "remote-endpoint" $visp_in3_end reference $default_dts
							}
						}
					}
					# axis_switch dicts are populated by axis_switch_update_endpoints which
					# runs after all _generate procs — defer if nothing created yet.
					if {!$switch_nomem_ep_created} {
						global visp_pending_endpoints
						if {![info exists visp_pending_endpoints]} { set visp_pending_endpoints {} }
						lappend visp_pending_endpoints [list switch_nomem $port_node $visp_inip $default_dts $sub]
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
					set switch_mem_ep_created 0
					if {[regexp -nocase $drv_handle "$visp_remo_in_end" match]} {
						if {[llength $visp_remo_in_end]} {
							set visp_ss_node [create_node -n "endpoint" -l $visp_remo_in_end -p $port_node -d $default_dts]
							set switch_mem_ep_created 1
							if {[llength $visp_in_end]} {
								add_prop "$visp_ss_node" "remote-endpoint" $visp_in_end reference $default_dts
							}
						}
					}

					if {[regexp -nocase $drv_handle "$visp_remo_in1_end" match]} {
						if {[llength $visp_remo_in1_end]} {
							set visp_ss_node1 [create_node -n "endpoint" -l $visp_remo_in1_end -p $port_node -d $default_dts]
							set switch_mem_ep_created 1
							if {[llength $visp_in1_end]} {
								add_prop "$visp_ss_node1" "remote-endpoint" $visp_in1_end reference $default_dts
							}
						}
					}
					if {!$switch_mem_ep_created} {
						global visp_pending_endpoints
						if {![info exists visp_pending_endpoints]} { set visp_pending_endpoints {} }
						lappend visp_pending_endpoints [list switch_mem $port_node $visp_inip $default_dts $drv_handle]
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
						if {[llength $visp_in_end]} {
							add_prop "$visp_ss_node" "remote-endpoint" $visp_in_end reference $default_dts
						}
					} elseif {[llength $inip]} {
						# end_mappings/remo_mappings not yet populated — visp_ss generates before
						# MIPI/broadcaster/switch when the ISP is inside a hierarchy block whose
						# base address is lower than the MIPI's.  Defer to visp_ss_update_endpoints
						# which runs after all _generate procs have completed.
						global visp_pending_endpoints
						if {![info exists visp_pending_endpoints]} {
							set visp_pending_endpoints {}
						}
						lappend visp_pending_endpoints [list mipi $port_node $inip $default_dts ""]
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
	# Extend the list with any memory-mapped downstream IP that visp_ss can stream to.
	# v_frmbuf_wr and mipi_dsi_tx_subsystem use the visp_out<N><sub> label convention.
	# preprocess_accel uses the preprocess_in<ip> label convention (matches preprocess.tcl
	# gen_endpoint registration). outip is resolved from AXI hardware connections so no
	# TCL execution-order dependency exists — no deferral needed for the output side.
	set valid_mmip_list "v_frmbuf_wr mipi_dsi_tx_subsystem preprocess_accel"
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
					# Derive endpoint label from the downstream IP's naming convention.
					# v_frmbuf_wr / mipi_dsi_tx_subsystem: visp_out<N><visp_handle>
					# All other memory-mapped downstream IPs (e.g. preprocess_accel):
					#   preprocess_in<outip_path> — matches gen_endpoint registration in
					#   the downstream IP's own TCL (e.g. preprocess.tcl).
					if {[string match -nocase [hsi get_property IP_NAME $ip] "v_frmbuf_wr"] || \
					    [string match -nocase [hsi get_property IP_NAME $ip] "mipi_dsi_tx_subsystem"]} {
						# frmbuf_wr/mipi_dsi: vcap node uses sub_node_label as the visp_ss part
						set ep_label "visp_out${port_addr_counter1}${sub_node_label}"
						set remo_ep "${ip}${sub_node_label}"
					} else {
						# Other downstream IPs (e.g. preprocess_accel): their port@0 endpoint
						# label is $drv_handle$inip where inip = visp_ss HSI handle ($drv_handle).
						# Use $drv_handle (full HSI instance path) not $sub_node_label (DTS name).
						set ep_label "preprocess_in${ip}"
						set remo_ep "${ip}${drv_handle}"
					}
					set vispnode [create_node -n "endpoint" -l $ep_label -p $port0 -d $default_dts]
					gen_endpoint $drv_handle $ep_label
					add_prop "$vispnode" "remote-endpoint" $remo_ep reference $default_dts
					gen_remoteendpoint $drv_handle $remo_ep
					# vcap/frmbuf linking for this ISP is handled once, after
					# this loop completes, by visp_ss_lilo_link_frmbufs (see
					# handle_io_mode_1) - not per-outip here, so that all of an
					# ISP's frmbuf writers can be grouped under a single vcap
					# node shared with any other ISP in the same LILO group.
				} else {
					if {[string match -nocase [hsi get_property IP_NAME $ip] "system_ila"]} {
						continue
					}
					set connectip [get_connect_ip $ip $master_intf $default_dts]
					if {[llength $connectip]} {
						if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"] || \
						    [string match -nocase [hsi get_property IP_NAME $connectip] "mipi_dsi_tx_subsystem"]} {
							set ep_label "visp_out${port_addr_counter1}${sub_node_label}"
						} else {
							set ep_label "preprocess_in${connectip}"
						}
						set vispnode [create_node -n "endpoint" -l $ep_label -p $port0 -d $default_dts]
						gen_endpoint $drv_handle $ep_label
						add_prop "$vispnode" "remote-endpoint" $connectip$drv_handle reference $default_dts
						gen_remoteendpoint $drv_handle "$connectip$drv_handle"
						# See comment above - vcap/frmbuf linking happens once,
						# after this loop, via visp_ss_lilo_link_frmbufs.
					}
				}
			} else {
				dtg_warning "$drv_handle pin TILE0_ISP0_VIDOUT_PO is not connected..check your design"
			}
		}
	}

}

# Returns {outip port_num} pairs for every frame buffer writer connected to
# this ISP's VIDOUT_PO/VIDOUT_SO. port_num must match the visp_out<N><label>
# endpoint label that was actually created for that connection by whichever
# handle_io_mode_* function ran for this ISP - but LILO and LIMxO number
# their ports differently, so this function mirrors each mode's own scheme
# rather than using one counter rule for both:
#
#  - LILO (handle_io_mode_1): port_addr_counter1 only advances when
#    get_connected_stream_ip finds a connection (see its PO/SO loop), so we
#    match that here: connectivity-conditional counting.
#
#  - LIMxO (handle_io_mode_4): port_addr_counter1 advances ONCE PER PO/SO
#    UNCONDITIONALLY (its mem-out branch creates port@N without ever calling
#    get_connected_stream_ip, and its increment sits outside both branches),
#    i.e. purely positional: PO is always port 1, SO is always port 2. Using
#    connectivity-conditional counting here instead would desync from that
#    the moment a mem-out pin's connection isn't picked up by
#    get_connected_stream_ip the same way a live pin's is - producing a
#    port_num that doesn't match the endpoint handle_io_mode_4 actually
#    created (a dangling remote-endpoint phandle, caught by dtc). So for
#    LIMxO we count positionally too, and separately exclude the memory-out
#    slot (ENABLE_MP_MEM/ENABLE_SP_MEM) from the returned list - it's bound
#    to visp_video by phandle instead of vcap, and must not become an extra
#    vcap DMA channel alongside the live one.
proc get_all_connected_frmbuf_wr_for_isp {drv_handle isp_id} {
	set frmbuf_list {}
	set tile [expr $isp_id / 2]
	set isp [expr $isp_id % 2]

	set mp_is_mem 0
	set sp_is_mem 0
	set io_type [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_IO_TYPE]
	set is_limxo [expr {$io_type == 4}]
	if {$is_limxo} {
		set prefix "CONFIG.C_TILE${tile}_ISP${isp}_"
		set mp_mem_val [get_ip_property $drv_handle "${prefix}ENABLE_MP_MEM"]
		set sp_mem_val [get_ip_property $drv_handle "${prefix}ENABLE_SP_MEM"]
		set mp_is_mem [expr {([string match -nocase "true" $mp_mem_val] || $mp_mem_val eq "1") ? 1 : 0}]
		set sp_is_mem [expr {([string match -nocase "true" $sp_mem_val] || $sp_mem_val eq "1") ? 1 : 0}]
	}

	set port_addr_counter1 1
	foreach out_type {PO SO} is_mem [list $mp_is_mem $sp_is_mem] {
		set intf "TILE${tile}_ISP${isp}_VIDOUT_${out_type}"
		set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]
		if {$is_limxo} {
			if {!$is_mem && [llength $outip] > 0} {
				set outipname [hsi get_property IP_NAME $outip]
				if {[string match -nocase $outipname "v_frmbuf_wr"]} {
					lappend frmbuf_list [list $outip $port_addr_counter1]
				}
			}
			incr port_addr_counter1
		} else {
			if {[llength $outip] > 0} {
				set outipname [hsi get_property IP_NAME $outip]
				if {[string match -nocase $outipname "v_frmbuf_wr"]} {
					lappend frmbuf_list [list $outip $port_addr_counter1]
				}
				incr port_addr_counter1
			}
		}
	}
	return $frmbuf_list
}

# Links this ISP's frame buffer writer(s) as additional DMA channels on the
# shared vcap node for its LILO merge group. Creates the group's vcap node on
# the leader's first call (named after the leader's own sub_node_label);
# followers reuse and extend it, with port/reg numbering continuing across
# the whole group so a follower's channels never collide with the leader's.
proc visp_ss_lilo_link_frmbufs {drv_handle default_dts sub_node_label isp_id} {
	global visp_lilo_leader
	global visp_lilo_vcap_by_leader

	set frmbufs [get_all_connected_frmbuf_wr_for_isp $drv_handle $isp_id]
	if {![llength $frmbufs]} {
		return
	}

	set leader_isp_id $isp_id
	if {[info exists visp_lilo_leader] && [dict exists $visp_lilo_leader $isp_id]} {
		set leader_isp_id [dict get $visp_lilo_leader $isp_id]
	}

	if {[info exists visp_lilo_vcap_by_leader] && [dict exists $visp_lilo_vcap_by_leader $leader_isp_id]} {
		set group_info      [dict get $visp_lilo_vcap_by_leader $leader_isp_id]
		set vcap            [lindex $group_info 0]
		set vcap_ports_node [lindex $group_info 1]
		set reg_counter     [lindex $group_info 2]
		set dma_list        [lindex $group_info 3]
		set dma_names_list  [lindex $group_info 4]
	} else {
		set bus_node [detect_bus_name $drv_handle]
		set vcap [create_node -n "vcap_$sub_node_label" -l vcap_$sub_node_label -p $bus_node -d $default_dts]
		add_prop $vcap "compatible" "xlnx,video" string $default_dts
		add_prop $vcap "xlnx,atomic_streamon" 1 int $default_dts
		set vcap_ports_node [create_node -n "ports" -l vcap_ports$sub_node_label -p $vcap -d $default_dts]
		add_prop "$vcap_ports_node" "#address-cells" 1 int $default_dts
		add_prop "$vcap_ports_node" "#size-cells" 0 int $default_dts
		set reg_counter 0
		set dma_list ""
		set dma_names_list {}
	}

	foreach entry $frmbufs {
		set outip     [lindex $entry 0]
		set port_num  [lindex $entry 1]

		if {$dma_list eq ""} {
			set dma_list "<&$outip 0>"
		} else {
			append dma_list " , <&$outip 0>"
		}
		lappend dma_names_list "port${reg_counter}"

		set vcap_port_node [create_node -n "port@${reg_counter}" -l vcap_port${sub_node_label}_${reg_counter} -p $vcap_ports_node -d $default_dts]
		add_prop "$vcap_port_node" "reg" $reg_counter int $default_dts
		add_prop "$vcap_port_node" "direction" input string $default_dts
		set vcap_in_node [create_node -n "endpoint" -l ${outip}${sub_node_label} -p $vcap_port_node -d $default_dts]
		gen_endpoint $drv_handle "${outip}${sub_node_label}"
		add_prop "$vcap_in_node" "remote-endpoint" visp_out${port_num}${sub_node_label} reference $default_dts
		gen_remoteendpoint $drv_handle "visp_out${port_num}${sub_node_label}"

		incr reg_counter
	}

	# noformating/stringlist add_prop only appends on repeat calls with an
	# unchanged value; force a full overwrite each time so accumulated group
	# DMA channels replace (not duplicate) the previous partial list.
	add_prop $vcap "dmas" $dma_list noformating $default_dts 1
	add_prop $vcap "dma-names" $dma_names_list stringlist $default_dts 1

	dict set visp_lilo_vcap_by_leader $leader_isp_id [list $vcap $vcap_ports_node $reg_counter $dma_list $dma_names_list]
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

# Starting from an ISP's already-resolved first-hop upstream IP (broadcaster,
# switch, or mipi, as found by find_valid_visp_inip), continue traversing
# backward to the ultimate MIPI CSI2 RX source, so that two ISPs are only
# grouped when they truly share the same physical sensor - not merely the
# same intermediate switch/broadcaster instance (which could otherwise be
# routing two different MIPI sources to two different ISPs). axis_switch is
# treated the same as axis_broadcaster here (traverse through its primary
# input) matching how axis_switch_update_endpoints/get_axis_switch_in_connect_ip
# already treat it elsewhere in this framework - as a single-primary-input
# fan-out in this video-pipeline context, not a general multi-input crossbar.
proc resolve_ultimate_visp_source {first_hop_ip {hop_count 0}} {
	if {![llength $first_hop_ip] || $hop_count > 20} {
		return $first_hop_ip
	}
	set ip_name [hsi::get_property IP_NAME $first_hop_ip]

	if {[string match -nocase $ip_name "axis_broadcaster"] || [string match -nocase $ip_name "axis_switch"]} {
		set slave_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $first_hop_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
		if {[llength $slave_intf]} {
			set upstream [get_connected_stream_ip [hsi::get_cells -hier $first_hop_ip] [lindex $slave_intf 0]]
			if {[llength $upstream]} {
				return [resolve_ultimate_visp_source [lindex $upstream 0] [expr {$hop_count + 1}]]
			}
		}
	}

	return $first_hop_ip
}

# Returns the ordered list of physical VIDIN pin indices this ISP uses.
# ISP0 fills from VIDIN0 upward; ISP1 fills from VIDIN4 downward (both cores
# share one pool of 5 VIDIN pins per tile). Mirrors the special-case/fallback
# split already used by the port-creation loop in handle_io_mode_2.
proc get_isp_input_vidins {isp live_stream} {
	set vidins {}
	if {$isp == 1 && $live_stream <= 2} {
		if {$live_stream == 1} {
			set vidins {4}
		} elseif {$live_stream == 2} {
			set vidins {4 3}
		}
	} else {
		for {set i 0} {$i < $live_stream} {incr i} {
			lappend vidins [expr {$i % 4}]
		}
	}
	return $vidins
}

# Minimal union-find (disjoint-set) used to group LIMO ISPs that share an
# upstream source, including transitively (e.g. isp C sharing with both isp A
# and isp B links A and B into the same group even though A and B share
# nothing directly).
proc dsu_find {dsu_var x} {
	upvar 1 $dsu_var dsu
	if {![dict exists $dsu $x]} {
		dict set dsu $x $x
	}
	set p [dict get $dsu $x]
	if {$p != $x} {
		set p [dsu_find dsu $p]
		dict set dsu $x $p
	}
	return $p
}

proc dsu_union {dsu_var a b} {
	upvar 1 $dsu_var dsu
	set ra [dsu_find dsu $a]
	set rb [dsu_find dsu $b]
	if {$ra == $rb} {
		return
	}
	# Smaller root always wins, so the group's leader ends up being the
	# lowest isp_id across the whole component - and since visp_ss_generate's
	# tile/isp loop always processes isp_ids in increasing order, the leader
	# is guaranteed to be generated before any of its followers.
	if {$ra < $rb} {
		dict set dsu $rb $ra
	} else {
		dict set dsu $ra $rb
	}
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
        if { $io_type == 1 || $io_type == 2 || $io_type == 3 || $io_type == 4} {
            set compat_str "xlnx,isp-mbox"
        } else {
            puts "Warning: Invalid io_type '$io_type' for RPU $rpu_id. Stale mbox will be created."
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
    foreach rpu_id [lsort -integer [array names compat_map]] {
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

			set ipi_list [hsi get_cells -hier -filter { IP_NAME == "ipi"}]
			set dest_cpu_name [format "R52_%d" $rpu_id]
			set dest_ipi [find_ipi_for_cpu $ipi_list $dest_cpu_name]

			if {![string length $dest_ipi]} {
				puts "Warning: No destination IPI found for RPU$rpu_id (CPU=$dest_cpu_name). Skipping mboxes property."
			} else {


				if { $rpu_id == 6 || $rpu_id == 7} {
					set src_ipi [extract_ipi_number [hsi get_property NAME [hsi get_cells -hier *_ipi_5]]]

				} elseif {$rpu_id == 8 || $rpu_id == 9} {
					set src_ipi [extract_ipi_number [hsi get_property NAME [hsi get_cells -hier *_ipi_6]]]

				} else {
					puts "warning Invalid rpu id found for APU interrupt Mapping."
				}

				if {![string length $src_ipi]} {
					puts "Warning: Could not resolve both TX/RX IPI sources for RPU$rpu_id. Skipping mboxes property."
				} else {
					set child_label_dest [build_ipi_child_label  $dest_ipi]
					set child_label "$src_ipi$child_label_dest"
					add_prop "$mbox_node" "mboxes" "<&$child_label 0x0>, <&$child_label 0x1>" noformating $default_dts
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

proc _visp_extract_ipi_label {ipi_cell} {
    set nm [hsi get_property NAME [hsi get_cells -hier $ipi_cell]]
	extract_ipi_number ipi_cell
    # Fallback: try to slice from the last occurrence of "ipi_"
    set idx [string last "ipi_" $nm]
    if {$idx >= 0} {
        return [string range $nm $idx end]
    }
    return $nm
}

proc build_ipi_child_label { dest_ipi} {
    #set src_name  [_visp_extract_ipi_label $src_ipi]
    set dest_name [_visp_extract_ipi_label $dest_ipi]
    return "_to_${dest_name}"
}

proc find_ipi_for_cpu {ipi_list target_cpu} {
    foreach ipi $ipi_list {
        set cpu_name [hsi get_property CONFIG.C_CPU_NAME [hsi get_cells -hier $ipi]]
        if {$cpu_name eq $target_cpu} {
            return $ipi
        }
    }
    return ""
}

proc extract_ipi_number {ipi_name} {
	if {[regexp {ipi_(\w+)$} $ipi_name -> ipi_suffix]} {
		return "ipi_$ipi_suffix"
	}
}

#Function to move  MBOX entry above vissp
proc rpu_info_mbox_create { drv_handle default_dts bus_name} {

       set rpu_ids {}
       set rpu_info_list {}

       for {set tile 0} {$tile < 3} {incr tile} {
               set tile_enabled [get_ip_property $drv_handle "CONFIG.C_TILE${tile}_ENABLE"]
               if {!$tile_enabled} {
                       continue
               }
               set config_only [get_ip_property $drv_handle "CONFIG.C_CONFIG_ONLY"]
               if {[string match -nocase $config_only "true"] || $config_only == 1} {
                       continue
               }
               for {set isp 0} {$isp < 2} {incr isp} {
                       set io_type [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_IO_TYPE]
                       if {$io_type != 1 && $io_type != 2 && $io_type != 3 && $io_type != 4} {
                               continue
                       }
                       set rpu [get_ip_property $drv_handle CONFIG.C_TILE${tile}_ISP${isp}_RPU]
                       lappend rpu_ids $rpu
                       lappend rpu_info_list [list $rpu $io_type]
               }
       }
       generate_mbox_nodes $rpu_info_list $default_dts $bus_name
}

proc get_visp_baseaddr {drv_handle} {
    set cell_name [common::get_property NAME [hsi::get_cells -hier $drv_handle]]
    set apu_addrs {}
    set rpu_addrs {}

    # Collect APU addresses
    set apu [lindex [hsi::get_cells -hier -filter {IP_NAME == "cortexa78"}] 0]
    if {$apu ne ""} {
        foreach mr [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $apu]] {
            set inst [common::get_property INSTANCE $mr]
            if {$inst eq $cell_name} {
                lappend apu_addrs [common::get_property BASE_VALUE $mr]
            }
        }
    }

    # Collect RPU addresses
    set rpu [lindex [hsi::get_cells -hier -filter {IP_NAME == "cortexr52"}] 0]
    if {$rpu ne ""} {
        foreach mr [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $rpu]] {
            set inst [common::get_property INSTANCE $mr]
            if {$inst eq $cell_name} {
                lappend rpu_addrs [common::get_property BASE_VALUE $mr]
            }
        }
    }

    # Remove duplicates within each list
    set apu_addrs [lsort -unique $apu_addrs]
    set rpu_addrs [lsort -unique $rpu_addrs]

    #puts "DEBUG get_visp_baseaddr: cell=$cell_name"
    #puts "  APU addresses ([llength $apu_addrs]): $apu_addrs"
    #puts "  RPU addresses ([llength $rpu_addrs]): $rpu_addrs"

    # Find unique address (present in one but not both)
    foreach addr $apu_addrs {
        if {[lsearch -exact $rpu_addrs $addr] == -1} {
            #puts "  -> Unique APU addr (not in RPU): $addr"
            return [string trimleft $addr "0x"]
        }
    }
    foreach addr $rpu_addrs {
        if {[lsearch -exact $apu_addrs $addr] == -1} {
            #puts "  -> Unique RPU addr (not in APU): $addr"
            return [string trimleft $addr "0x"]
        }
    }

    # Fallback: if all addresses are common, return first APU address
    #puts "  -> No unique addr found, fallback to first APU addr: [lindex $apu_addrs 0]"
    if {[llength $apu_addrs] > 0} {
        return [string trimleft [lindex $apu_addrs 0] "0x"]
    }
    return ""
}

# Called by the DTG framework after ALL _generate procs have completed.
# Processes endpoints that were deferred during visp_ss_generate because
# end_mappings/remo_mappings were not yet populated at generate time
# (happens when the visp_ss hierarchy block has a lower base address than MIPI).
proc visp_ss_update_endpoints {drv_handle} {
	global visp_pending_endpoints
	global visp_endpoints_processed
	global end_mappings
	global remo_mappings
	global port1_end_mappings port2_end_mappings port3_end_mappings port4_end_mappings
	global axis_port1_remo_mappings axis_port2_remo_mappings
	global axis_port3_remo_mappings axis_port4_remo_mappings
	global axis_switch_port1_end_mappings axis_switch_port2_end_mappings
	global axis_switch_port3_end_mappings axis_switch_port4_end_mappings
	global axis_switch_port1_remo_mappings axis_switch_port2_remo_mappings
	global axis_switch_port3_remo_mappings axis_switch_port4_remo_mappings
	global port1_broad_end_mappings port2_broad_end_mappings
	global port3_broad_end_mappings port4_broad_end_mappings
	global port5_broad_end_mappings port6_broad_end_mappings port7_broad_end_mappings
	global broad_port1_remo_mappings broad_port2_remo_mappings
	global broad_port3_remo_mappings broad_port4_remo_mappings
	global broad_port5_remo_mappings broad_port6_remo_mappings broad_port7_remo_mappings

	# All tile instances share one pending list; only the first call processes it.
	if {[info exists visp_endpoints_processed]} {
		return
	}
	set visp_endpoints_processed 1

	if {![info exists visp_pending_endpoints] || ![llength $visp_pending_endpoints]} {
		return
	}

	foreach entry $visp_pending_endpoints {
		set type       [lindex $entry 0]
		set port_node  [lindex $entry 1]
		set ip_handle  [lindex $entry 2]
		set entry_dts  [lindex $entry 3]
		set filter     [lindex $entry 4]

		switch $type {
			"mipi" {
				# Upstream is MIPI/direct memory-mapped source.
				# end_mappings / remo_mappings are now populated.
				set visp_in_end ""
				set visp_remo_in_end ""
				if {[info exists end_mappings] && [dict exists $end_mappings $ip_handle]} {
					set visp_in_end [dict get $end_mappings $ip_handle]
				}
				if {[info exists remo_mappings] && [dict exists $remo_mappings $ip_handle]} {
					set visp_remo_in_end [dict get $remo_mappings $ip_handle]
				}
				if {[llength $visp_remo_in_end]} {
					set nd [create_node -n "endpoint" -l $visp_remo_in_end -p $port_node -d $entry_dts]
					if {[llength $visp_in_end]} {
						add_prop "$nd" "remote-endpoint" $visp_in_end reference $entry_dts
					}
				}
			}
			"broadcaster" {
				# Upstream is axis_broadcaster.
				# port*_broad_end_mappings populated by axis_broadcaster_update_endpoints.
				set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip_handle] \
				                 -filter {TYPE==MASTER || TYPE==INITIATOR}]
				set max_ports [llength $master_intf]
				for {set i 1} {$i <= $max_ports} {incr i} {
					set port_var "port${i}_broad_end_mappings"
					set remo_var "broad_port${i}_remo_mappings"
					set b_in_end ""
					set b_remo_end ""
					if {[info exists $port_var] && [dict exists [set $port_var] $ip_handle]} {
						set b_in_end [dict get [set $port_var] $ip_handle]
					} else { continue }
					if {[info exists $remo_var] && [dict exists [set $remo_var] $ip_handle]} {
						set b_remo_end [dict get [set $remo_var] $ip_handle]
					} else { continue }
					if {[llength $b_remo_end] && [regexp -nocase $filter "$b_remo_end" match]} {
						set nd [create_node -n "endpoint" -l $b_remo_end -p $port_node -d $entry_dts]
						if {[llength $b_in_end]} {
							add_prop "$nd" "remote-endpoint" $b_in_end reference $entry_dts
						}
					}
				}
			}
			"switch_nomem" {
				# Non-memory-mapped axis_switch.
				# port*_end_mappings / axis_port*_remo_mappings populated by axis_switch_update_endpoints.
				set sw_pairs [list \
					port1_end_mappings axis_port1_remo_mappings \
					port2_end_mappings axis_port2_remo_mappings \
					port3_end_mappings axis_port3_remo_mappings \
					port4_end_mappings axis_port4_remo_mappings]
				foreach {in_map remo_map} $sw_pairs {
					set s_in_end ""
					set s_remo_end ""
					if {[info exists $in_map] && [dict exists [set $in_map] $ip_handle]} {
						set s_in_end [dict get [set $in_map] $ip_handle]
					}
					if {[info exists $remo_map] && [dict exists [set $remo_map] $ip_handle]} {
						set s_remo_end [dict get [set $remo_map] $ip_handle]
					}
					if {[llength $s_remo_end] && [regexp -nocase $filter "$s_remo_end" match]} {
						set nd [create_node -n "endpoint" -l $s_remo_end -p $port_node -d $entry_dts]
						if {[llength $s_in_end]} {
							add_prop "$nd" "remote-endpoint" $s_in_end reference $entry_dts
						}
					}
				}
			}
			"switch_mem" {
				# Memory-mapped axis_switch.
				# axis_switch_port*_end_mappings populated by axis_switch_update_endpoints.
				set sw_pairs [list \
					axis_switch_port1_end_mappings axis_switch_port1_remo_mappings \
					axis_switch_port2_end_mappings axis_switch_port2_remo_mappings \
					axis_switch_port3_end_mappings axis_switch_port3_remo_mappings \
					axis_switch_port4_end_mappings axis_switch_port4_remo_mappings]
				foreach {in_map remo_map} $sw_pairs {
					set s_in_end ""
					set s_remo_end ""
					if {[info exists $in_map] && [dict exists [set $in_map] $ip_handle]} {
						set s_in_end [dict get [set $in_map] $ip_handle]
					}
					if {[info exists $remo_map] && [dict exists [set $remo_map] $ip_handle]} {
						set s_remo_end [dict get [set $remo_map] $ip_handle]
					}
					# switch_mem uses drv_handle (stored in filter) as the match string
					if {[llength $s_remo_end] && [regexp -nocase $filter "$s_remo_end" match]} {
						set nd [create_node -n "endpoint" -l $s_remo_end -p $port_node -d $entry_dts]
						if {[llength $s_in_end]} {
							add_prop "$nd" "remote-endpoint" $s_in_end reference $entry_dts
						}
					}
				}
			}
		}
	}
}