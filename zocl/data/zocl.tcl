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

# Parse -zocl_params parameter string into a dictionary
# Expected format: "key1 val1 key2 val2 ..."
# Returns: dict with keys: memory-region, vpp_hier_name, legacy, domain-yaml
proc parse_zocl_params {params_string} {
	set params_dict [dict create]

	# Set defaults
	dict set params_dict "vpp_hier_name" "VitisRegion"
	dict set params_dict "legacy" "true"
        dict set params_dict "domain-yaml" ""
        # empty string, static, or rm
        dict set params_dict "dfx-mode" ""
        # Internally set only, populated from domain-yaml
	dict set params_dict "memory-region" ""

	if {[string_is_empty $params_string]} {
		return $params_dict
	}

	# Parse key-value pairs using foreach to preserve Tcl quoting
	# Validate that we have even number of elements (key-value pairs)
	set valid_keys {legacy domain-yaml vpp_hier_name dfx-mode}

	if {[catch {
		foreach {key value} $params_string {
			# Validate key is known
			if {$key ni $valid_keys} {
				dtg_warning "Unknown zocl_params key: $key (valid: $valid_keys)"
				continue
			}

			# Validate value for boolean keys
			if {$key eq "legacy"} {
				if {$value ni {true false}} {
					dtg_warning "Invalid value for legacy: $value (expected: true or false)"
					continue
				}
			}

			# Validate value for dfx-mode
			if {$key eq "dfx-mode"} {
				if {$value ni {"" static rm}} {
					dtg_warning "Invalid value for dfx-mode: $value (expected: static, rm, or empty)"
					continue
				}
			}

			dict set params_dict $key $value
		}
	} err]} {
		dtg_warning "Failed to parse zocl_params: $err. Using defaults."
	}

	# If domain-yaml is provided, parse it to get memory-region
	set domain_yaml [dict get $params_dict "domain-yaml"]
	if {![string_is_empty $domain_yaml]} {
		set memory_region [parse_domain_yaml $domain_yaml]
		if {![string_is_empty $memory_region]} {
			# Set memory-region from parsed domain-yaml
			dict set params_dict "memory-region" $memory_region
		}
	}

	return $params_dict
}

# Parse domain YAML file and extract shared-dma-pool memory regions for APU_Linux domain
# Returns: memory-region phandle string (e.g., "<&label1>,<&label2>,<&label3>")
proc parse_domain_yaml {yaml_file} {
	if {![file exists $yaml_file]} {
		error "Domain YAML file not found: $yaml_file"
		return ""
	}

	# Read and parse YAML file
	set fd [open $yaml_file r]
	set yaml_data [read $fd]
	close $fd

	# Parse YAML to dict using existing DTG yaml parser
	if {[catch {package require yaml} msg]} {
		error "YAML package not available: $msg"
		return ""
	}
	set yaml_dict [::yaml::yaml2dict $yaml_data]

	# Extract APU_Linux domain's reserved-memory references
	if {![dict exists $yaml_dict domains APU_Linux reserved-memory]} {
		dtg_warning "No APU_Linux domain or reserved-memory references found in $yaml_file"
		return ""
	}

	set apu_mem_refs [dict get $yaml_dict domains APU_Linux reserved-memory]

	# Get the reserved-memory section
	if {![dict exists $yaml_dict reserved-memory]} {
		dtg_warning "No reserved-memory section found in $yaml_file"
		return ""
	}
	set reserved_mem [dict get $yaml_dict reserved-memory]

	# Build list of memory region phandles from APU_Linux domain references
	# Accept regions with ZOCL-compatible designations to avoid unrelated carveouts
	# (OpenAMP firmware, vrings, resource tables, RPMsg memory)
	# Accepted compatible values:
	#   - "shared-dma-pool" (mandatory - for CMA)
	#   - "xlnx,zocl-alloc" (explicit ZOCL designation)
	set phandle_list []
	foreach mem_ref $apu_mem_refs {
		# mem_ref is like cma_reserved@800000000
		if {[dict exists $reserved_mem $mem_ref]} {
			set mem_entry [dict get $reserved_mem $mem_ref]

			# Check if this region qualifies
			set include_region 0

			# Require explicit compatible property
			if {[dict exists $mem_entry compatible]} {
				set compat [dict get $mem_entry compatible]
				# Accept shared-dma-pool (for CMA)
				if {[string match "*shared-dma-pool*" $compat]} {
					set include_region 1
				}
				# Accept xlnx,zocl-alloc (explicit ZOCL marker)
				if {[string match "*xlnx,zocl-alloc*" $compat]} {
					set include_region 1
				}
			}

			# If region qualifies, extract the label
			if {$include_region} {
				if {[dict exists $mem_entry label]} {
					set label [dict get $mem_entry label]
					lappend phandle_list "<&${label}>"
				} else {
					dtg_warning "Reserved memory $mem_ref has no label field"
				}
			}
		} else {
			dtg_verbose "Reserved memory reference $mem_ref not found in reserved-memory section"
		}
	}

	if {[llength $phandle_list] == 0} {
		dtg_warning "No shared-dma-pool entries found in APU_Linux domain"
		return ""
	}

	# Join with commas (no spaces)
	set memory_region [join $phandle_list ","]
	dtg_verbose "Extracted memory-region from $yaml_file: $memory_region"

	return $memory_region
}

# Trace an interrupt pin through dfx_decoupler and xlconcat to find
  # the parent axi_intc and the interrupt index.
  # Returns: list of {intc_node_label intr_id} or empty if not found.
  proc trace_intr_to_intc {pin {bit_offset 0}} {
      set net [hsi::get_nets -of_objects $pin]
      if {![llength $net]} { return {} }

      # Find sink pins on this net (exclude the source pin itself)
      set sink_pins [hsi::get_pins -of_objects $net -filter {DIRECTION==I}]

      foreach sink $sink_pins {
          set cell [hsi::get_cells -of_objects $sink]

          # Check if we reached a PS interrupt pin (no cell means top-level port)
          if {![llength $cell]} {
              # This is a top-level pin - check if it's a PS interrupt
              set pin_name [hsi get_property NAME $sink]

              # Use existing get_psu_interrupt_id to resolve PS interrupt pins
              # HSI uses scalar names: pl_fpd_irq3, pl_ps_irq0, IRQ0_F2P, pl_psx_irq0
              set ps_irq_id [get_psu_interrupt_id "" $pin_name]
              if {$ps_irq_id >= 0} {
                  # Add bit_offset for xlconcat accumulation
                  set final_irq [expr {$ps_irq_id + $bit_offset}]

                  # Get interrupt parent for this platform
                  # Use "imux" (interrupt-multiplex) for ZynqMP/Versal (routes to both A72/R5 GICs)
                  # Use "intc" for Zynq (ps7_scugic)
                  set proctype [get_hw_family]
                  set intr_parent "imux"
                  if {[string match -nocase $proctype "zynq"]} {
                      set intr_parent "intc"
                  }

                  # Return PS interrupt reference (3-element list with "ps" marker)
                  return [list $intr_parent $final_irq "ps"]
              }
              continue
          }

          set ip [hsi get_property IP_NAME $cell]

          if {$ip == "axi_intc"} {
              # Reached the controller — bit_offset is the interrupt ID
              set ctrl_node [get_node $cell]
              if {[string_is_empty $ctrl_node]} { continue }
              set label [lindex [split $ctrl_node ": "] 0]

              # In RM overlays, labels are prefixed by write_rm_dt
              # Check if we're in RM context and prepend prefix if needed
              global is_rm_design
              global partial_file
              if {[info exists is_rm_design] && $is_rm_design == 1} {
                  if {[info exists partial_file] && $partial_file ne ""} {
                      # Extract prefix from partial file (e.g., "rm0" from "rm0.dtsi")
                      set prefix [file rootname [file tail $partial_file]]
                      set label "${prefix}_${label}"
                  }
              }

              return [list $label $bit_offset]
          }

          if {$ip == "xlconcat"} {
              # Determine which In<N> port we hit
              set pin_name [hsi get_property NAME $sink]
              set in_idx [regexp -inline {\d+} $pin_name]

              # Accumulate widths of all lower-numbered inputs
              set id_offset 0
              for {set i 0} {$i < $in_idx} {incr i} {
                  set in_pin [hsi::get_pins -of_objects $cell -filter "NAME==In${i}"]
                  if {[llength $in_pin]} {
                      set w [hsi get_property LEFT $in_pin]
                      # LEFT is the MSB index; width = LEFT+1 for [LEFT:0]
                      if {$w eq ""} { set w 0 }
                      incr id_offset [expr {$w + 1}]
                  } else {
                      incr id_offset 1
                  }
              }

              # Follow the concat output, carrying the accumulated offset
              set out_pin [hsi::get_pins -of_objects $cell -filter {NAME==dout}]
              if {[llength $out_pin]} {
                  return [trace_intr_to_intc $out_pin [expr {$bit_offset + $id_offset}]]
              }
          }

          if {$ip == "dfx_decoupler"} {
              # Pass through — find the corresponding interrupt output
              set out_pins [hsi::get_pins -of_objects $cell \
                  -filter {TYPE==INTERRUPT && DIRECTION==O}]
              foreach out $out_pins {
                  set result [trace_intr_to_intc $out $bit_offset]
                  if {[llength $result]} { return $result }
              }
          }
      }
      return {}
  }

 proc get_pl_kernel_interrupts {vpp_hier_name} {
      set intr_list []

      # Step 1: Find the reconfigurable partition (e.g., VitisRegion_inst_0)
      # Skip BLOCK_CONTAINERs that have HD.RECONFIGURABLE explicitly set to 0
      set pr_regions [hsi::get_cells -hier -filter {BD_TYPE==BLOCK_CONTAINER}]
      set pr_region ""
      foreach region $pr_regions {
          # Check if HD.RECONFIGURABLE is explicitly disabled
          set skip_region 0
          if {![catch {set is_reconfig [hsi get_property HD.RECONFIGURABLE $region]}]} {
              if {$is_reconfig == 0 || $is_reconfig eq "false"} {
                  # Explicitly not reconfigurable - skip this one
                  set skip_region 1
              }
          }
          if {!$skip_region} {
              set pr_region $region
              break
          }
      }

      if {$pr_region eq ""} {
          # No reconfigurable partition — flat design, try direct tracing
          return [get_pl_kernel_interrupts_flat $vpp_hier_name]
      }

      # Step 2: Navigate into hierarchy to map kernel → xlconcat bit offset
      hsi::current_hw_instance [hsi::get_cells -hier $pr_region]

      set kernel_map []
      set all_cells [hsi::get_cells]

      foreach cell $all_cells {
          if {![string match "${vpp_hier_name}*" $cell]} { continue }

          set intr_pins [hsi::get_pins -of_objects $cell \
              -filter {TYPE==INTERRUPT && DIRECTION==O}]
          if {![llength $intr_pins]} { continue }

          foreach pin $intr_pins {
              set net [hsi::get_nets -of_objects $pin]
              if {![llength $net]} { continue }

              set sink_pins [hsi::get_pins -of_objects $net -filter {DIRECTION==I}]
              foreach sink $sink_pins {
                  set sink_cell [hsi::get_cells -of_objects $sink]
                  if {![llength $sink_cell]} { continue }
                  if {[hsi get_property IP_NAME $sink_cell] ne "xlconcat"} { continue }

                  set pin_name [hsi get_property NAME $sink]
                  set in_idx [regexp -inline {\d+} $pin_name]

                  # Accumulate widths of lower inputs for bit offset
                  set bit_offset 0
                  for {set i 0} {$i < $in_idx} {incr i} {
                      set in_pin [hsi::get_pins -of_objects $sink_cell \
                          -filter "NAME==In${i}"]
                      if {[llength $in_pin]} {
                          set w [hsi get_property LEFT $in_pin]
                          if {$w eq ""} { set w 0 }
                          incr bit_offset [expr {$w + 1}]
                      } else {
                          incr bit_offset 1
                      }
                  }

                  lappend kernel_map [list $cell $bit_offset]
              }
          }
      }

      # Step 3: Navigate back to top level
      ::hsi::current_hw_instance

      if {![llength $kernel_map]} {
          dtg_verbose "No kernel-to-xlconcat mappings found inside $pr_region"
          return $intr_list
      }

      # Step 4: Trace VitisRegion boundary interrupt port to interrupt controller
      set intc_label ""
      set base_offset 0
      set is_ps_irq 0

      set boundary_pins [hsi::get_pins -of_objects \
          [hsi::get_cells -hier $pr_region] \
          -filter {TYPE==INTERRUPT && DIRECTION==O}]

      foreach bpin $boundary_pins {
          set result [trace_intr_to_intc $bpin 0]
          if {[llength $result] >= 2} {
              set intc_label [lindex $result 0]
              set base_offset [lindex $result 1]
              # Check if this is a PS interrupt (3-element list with "ps" marker)
              if {[llength $result] == 3 && [lindex $result 2] eq "ps"} {
                  set is_ps_irq 1
              }
              break
          }
      }

      if {$intc_label eq ""} {
          dtg_verbose "Could not trace $pr_region interrupt to interrupt controller"
          return $intr_list
      }

      # Step 5: Generate interrupt entries with exact IDs
      foreach entry $kernel_map {
          set bit_off [lindex $entry 1]
          set final_id [expr {$base_offset + $bit_off}]
          if {$is_ps_irq} {
              # PS interrupt format: <&imux 0 irq_num 4> (SPI via interrupt-multiplex)
              lappend intr_list "<&${intc_label} 0 ${final_id} 4>"
          } else {
              # axi_intc format: <&intc_label irq_num 4>
              lappend intr_list "<&${intc_label} ${final_id} 4>"
          }
      }

      return $intr_list
  }

  # Fallback for flat (non-DFX) designs where direct tracing works
  proc get_pl_kernel_interrupts_flat {vpp_hier_name} {
      set intr_list []

      set all_cells [hsi::get_cells -hier]
      set pl_kernels []
      foreach cell $all_cells {
          if {[string match "${vpp_hier_name}*" $cell]} {
              lappend pl_kernels $cell
          }
      }

      if {[llength $pl_kernels] == 0} {
          dtg_verbose "No PL kernels found matching '${vpp_hier_name}*'"
          return $intr_list
      }

      foreach kernel $pl_kernels {
          set intr_pins [hsi::get_pins -of_objects \
              [hsi::get_cells -hier $kernel] \
              -filter {TYPE==INTERRUPT && DIRECTION==O}]

          foreach pin $intr_pins {
              set result [trace_intr_to_intc $pin 0]
              if {[llength $result] >= 2} {
                  set label [lindex $result 0]
                  set id    [lindex $result 1]
                  # Check if this is a PS interrupt (3-element list with "ps" marker)
                  if {[llength $result] == 3 && [lindex $result 2] eq "ps"} {
                      # PS interrupt format: <&imux 0 irq_num 4> (SPI via interrupt-multiplex)
                      lappend intr_list "<&${label} 0 ${id} 4>"
                  } else {
                      # axi_intc format: <&intc_label irq_num 4>
                      lappend intr_list "<&${label} ${id} 4>"
                  }
              }
          }
      }

      return $intr_list
  }

# Generate zocl node in legacy mode (original behavior)
proc gen_zocl_node_legacy {family} {
	global pl_ip_list
	if {![llength $pl_ip_list]} {
		dtg_warning "dt_zocl enabled and No PL ip's found in specified design, skip adding zocl node"
		return
	}
	set bus_node "amba_pl: amba_pl"
	set default_dts "pl.dtsi"
	set family [get_hw_family]
	set zocl_node [create_node -n "zyxclmm_drm" -d ${default_dts} -p $bus_node]
	if {$family in {"zynq" "zynqmp"}} {
	       add_prop $zocl_node "compatible" "xlnx,zocl" string $default_dts
	} else {
	       add_prop $zocl_node "compatible" "xlnx,zocl-versal" string $default_dts
	}
	set intr_ctrl [hsi::get_cells -hier -filter {IP_NAME == axi_intc}]
	set intr_extended ""
	foreach ctrl $intr_ctrl {
		set ctrl_node [get_node $ctrl]
		if {![string_is_empty $ctrl_node]} {
			set ctrl_node_label [lindex [split $ctrl_node ": "] 0]
			set ctrl_ref "&${ctrl_node_label}"
			set intr_num_range 32
			if {$ctrl != [lindex $intr_ctrl 0]} {
				set intr_num_range 31
			}
			for {set i 0} {$i < $intr_num_range} {incr i} {
				append intr_extended "<$ctrl_ref $i 4>"
				if {($i != ($intr_num_range - 1)) || ($ctrl != [lindex $intr_ctrl end])} {
					append intr_extended ", "
				}
			}
		}
	}
	if {[llength $intr_ctrl]} {
		if {![string_is_empty $intr_extended]} {
			add_prop $zocl_node "interrupts-extended" $intr_extended noformating $default_dts
		}
	} else {
		# if axi_intc not found then use gic controller
		set intr_num "<0x0 0x89 0x4>, <0x0 0x90 0x4>, <0x0 0x91 0x4>, <0x0 0x92 0x4>, <0x0 0x93 0x4>, <0x0 0x94 0x4>, <0x0 0x95 0x4>, <0x0 0x96 0x4>"
		add_prop $zocl_node "interrupt-parent" imux reference $default_dts
		add_prop $zocl_node "interrupts" $intr_num noformating $default_dts
	}

	set decouplers [hsi get_cells -hier -filter {IP_NAME == dfx_decoupler}]
	set count 1
	foreach decoupler $decouplers {
		if { $count == 1 } {
			add_prop "$zocl_node" "xlnx,pr-decoupler" "" boolean $default_dts
		} else {
			#zocl driver not supporting multiple decouplers so display warning.
			dtg_warning "Multiple dfx_decoupler IPs found in the design,\
				using pr-isolation-addr from [lindex [split $decouplers " "] 0] IP"
			break
		}
		set baseaddr [hsi get_property CONFIG.C_BASEADDR [hsi get_cells -hier $decoupler]]
		if {[llength $baseaddr]} {
			set baseaddr "0x0 $baseaddr"
			add_prop "$zocl_node" "xlnx,pr-isolation-addr" "$baseaddr" hexlist $default_dts
		}
		incr count
	}
}

# Generate zocl node in new dual-node mode
proc gen_zocl_node_dual {family params_dict} {
	global pl_ip_list
	global is_rm_design
	if {![llength $pl_ip_list]} {
		dtg_warning "dt_zocl enabled and No PL ip's found in specified design, skip adding zocl node"
		return
	}

	set bus_node "amba_pl: amba_pl"
	set default_dts "pl.dtsi"

	# Extract parameters
	set memory_region [dict get $params_dict "memory-region"]
	set vpp_hier_name [dict get $params_dict "vpp_hier_name"]
	set dfx_mode [dict get $params_dict "dfx-mode"]

	# dfx_mode is passed via zocl_params from device_tree.tcl
	# No auto-detection needed here

	# For DFX designs, split node generation
	# dfx-mode = static → generate only zyxclmm_drm (in pl.dtsi from static XSA)
	# dfx-mode = rm → generate only fpga_accelerator (in rm*.dtsi from RM XSA)
	# dfx-mode = empty → generate both nodes (flat/segmented designs)

	set generate_zyxclmm 1
	set generate_accel 1

	if {$dfx_mode == "static"} {
		set generate_accel 0
	} elseif {$dfx_mode == "rm"} {
		set generate_zyxclmm 0
	}

	# Generate zyxclmm_drm node (if applicable)
	if {$generate_zyxclmm} {
		set zocl_node [create_node -n "zyxclmm_drm" -d ${default_dts} -p $bus_node]

		# Add compatible property
		if {$family in {"zynq" "zynqmp"}} {
			add_prop $zocl_node "compatible" "xlnx,zocl" string $default_dts
		} else {
			add_prop $zocl_node "compatible" "xlnx,zocl-versal" string $default_dts
		}

                # Add memory-region property
                if {![string_is_empty $memory_region]} {
                    add_prop $zocl_node "memory-region" $memory_region noformating $default_dts
                } else {
                    dtg_warning "No memory-region or domain-yaml provided in -zocl_params. XRT allocator will have no reserved memory regions."
                }
                # Note: Decoupler management not needed in dual-node mode
                # XRT does not manage decouplers outside of legacy mode
	}

	# Generate fpga_accelerator node (if applicable)
	if {$generate_accel} {
		set accel_node [create_node -n "fpga_accelerator" -d ${default_dts} -l "fpga_accelerator" -p $bus_node]
		add_prop $accel_node "compatible" "xlnx,fpga_accelerator" string $default_dts

		# Discover PL kernel interrupts
		set intr_list [get_pl_kernel_interrupts $vpp_hier_name]

		# Add interrupts-extended property if interrupts were found
		if {[llength $intr_list] > 0} {
			set intr_extended [join $intr_list ", "]
			add_prop $accel_node "interrupts-extended" $intr_extended noformating $default_dts
			dtg_verbose "Added [llength $intr_list] interrupt(s) to fpga_accelerator node"
		} else {
			dtg_verbose "No PL kernel interrupts found, fpga_accelerator node created without interrupts-extended property"
		}
	}
}

# Main entry point for generating zocl node
proc gen_zocl_node {family {zocl_params_str ""}} {
	# Parse parameters
	set params_dict [parse_zocl_params $zocl_params_str]

	# Get legacy flag
	set legacy_mode [dict get $params_dict "legacy"]

	# Branch based on legacy mode
	if {[string match -nocase $legacy_mode "true"] || [string match -nocase $legacy_mode "1"]} {
		gen_zocl_node_legacy $family
	} else {
		gen_zocl_node_dual $family $params_dict
	}
}
