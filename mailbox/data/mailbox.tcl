#
# (C) Copyright 2024 - 2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc mailbox_generate {drv_handle} {
	# Initialize global stream node counter
	global stream_node_counter

	if {![info exists stream_node_counter]} {
		# Axi-stream doesnt have a dedicated register, hence populating reg with dummy values
		# Initialize counter to 0xFFFFFFF0 as integer for decreasing order
		# Counter decrements by 0x10 for each AXI-Stream node
		set stream_node_counter 0xFFFFFFF0
	}

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

	# Obtain and clean up interrupt values from the base node
	if {[catch {
		set intr_val [pldt get $node interrupts]
	}]} {
		set intr_val ""
	}

	# Strip angle brackets and normalize whitespace
	set intr_val [string trimright $intr_val ">"]
	set intr_val [string trimleft $intr_val "<"]
	set intr_val [string trim $intr_val]
	set intr_val [regsub -all {\s+} $intr_val " "]

	# Get interrupt pins from mailbox IP (typically Interrupt_0 and Interrupt_1)
	set intr_pins [hsi get_pins -of_objects [hsi get_cells -hier $drv_handle] -filter "TYPE==INTERRUPT"]
	set periph_val [hsi get_property NAME [hsi get_cells -hier $drv_handle]]

	# Split interrupt values per port based on connected pins and controller type
	set intr_list [split $intr_val " "]
	set intr_s0 ""
	set intr_s1 ""
	set intr_parent_s0 ""
	set intr_parent_s1 ""
	set offset 0

	# Process only connected interrupt pins
	foreach pin $intr_pins {
		# Skip pins that aren't wired in the design
		set is_connected [hsi get_property IS_CONNECTED $pin]
		if {$is_connected == 0} {
			continue
		}

		# Extract port ID from pin name (Interrupt_0 -> port 0, Interrupt_1 -> port 1)
		set pin_name [hsi get_property NAME $pin]
		set port_id 0
		if {[regexp {Interrupt_(\d+)} $pin_name match port_num]} {
			set port_id $port_num
		}

		# Determine interrupt format based on controller type
		# PS GICs use 3-cell format, PL controllers use 2-cell format
		set cells_per_intr 2
		set port_intr_parent ""

		set intc_list [get_interrupt_parent $periph_val $pin]
		if {[llength $intc_list] > 0} {
			set intc [lindex $intc_list 0]
			set intc_name [hsi get_property IP_NAME $intc]

			# Check for PS GIC (ARM GIC controllers)
			if {$intc_name in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic" "psu_rcpu_gic" "psv_rcpu_gic" "psx_rcpu_gic" "rcpu_gic" "ps7_scugic"}} {
				set cells_per_intr 3

				# Convert GIC handles to standard kernel labels
				if {$intc_name in {"psu_acpu_gic" "psv_acpu_gic" "psx_acpu_gic" "acpu_gic" "psu_rcpu_gic" "psv_rcpu_gic" "psx_rcpu_gic" "rcpu_gic"}} {
					set port_intr_parent "imux"
				} elseif {[string match -nocase $intc_name "ps7_scugic"]} {
					set port_intr_parent "intc"
				}
			} else {
				# PL interrupt controller - use the actual handle
				if {[is_pl_ip $intc]} {
					global dup_periph_handle
					if {[dict exists $dup_periph_handle $intc]} {
						set port_intr_parent [dict get $dup_periph_handle $intc]
					} else {
						set port_intr_parent $intc
					}
				} else {
					set port_intr_parent $intc
				}
			}
		}

		# Extract the appropriate number of interrupt cells for this port
		if {$offset < [llength $intr_list]} {
			set port_intr [join [lrange $intr_list $offset [expr {$offset + $cells_per_intr - 1}]] " "]

			if {$port_id == 0} {
				set intr_s0 $port_intr
				set intr_parent_s0 $port_intr_parent
			} else {
				set intr_s1 $port_intr
				set intr_parent_s1 $port_intr_parent
			}

			set offset [expr {$offset + $cells_per_intr}]
		}
	}

	# Remove the base node and create separate nodes for S0 and S1 interfaces
	pldt delete $node

	# Create a device tree node for each mailbox interface
	for {set port_id 0} {$port_id < 2} {incr port_id} {
		# port_interface: 2 = AXI4-Lite, 4 = AXI4-Stream
		set port_interface [common::get_property CONFIG.[format "C_INTERCONNECT_PORT_%d" $port_id] $drv_handle]
		set port_intr [expr {$port_id == 0 ? $intr_s0 : $intr_s1}]
		set port_intr_parent [expr {$port_id == 0 ? $intr_parent_s0 : $intr_parent_s1}]

		create_mbox_nodes $drv_handle $port_interface $port_id $port_intr $port_intr_parent
	}
}

proc create_mbox_nodes {drv_handle port_interface port_id intr_val intr_parent} {
	# Access global stream node counter
	global stream_node_counter

	# Identify if the processor is 32-bit or 64-bit
	set family [get_hw_family]
	global is_64_bit_mb
	if {$family in {"microblaze" "Zynq"} && !$is_64_bit_mb} {
		set bit_format 32
	} else {
		set bit_format 64
	}

	set ip_name [hsi::get_property IP_NAME $drv_handle]
	set name [hsi::get_property NAME $drv_handle]
	set bus_name [detect_bus_name $drv_handle]
	set compatible [get_comp_str $drv_handle]
	set label_name ${drv_handle}_S${port_id}
	set dts_file pl.dtsi

	# Set size based on interface type: AXI-Lite uses 0x10000, AXI-Stream uses 0x10
	if {$port_interface == 2} {
		set size 0x10000
	} else {
		set size 0x10
	}

	set mbox_delete_node    0
	set mbox_baseaddr	0
	set mbox_send_fsl	0
	set mbox_recv_fsl	0
	set mbox_use_fsl	0

	# Collect all connected processors for this port
	set connected_processors {}
	set node_created 0
	set node ""

	set proclist [hsi::get_cells -hier -filter IP_TYPE==PROCESSOR]
	foreach processor $proclist {
		set is_axi4lite_connected 0
		set use_fsl 0

		if {$port_interface == 2} {
			# AXI4LITE interface
			set mbox_baseaddr [common::get_property CONFIG.[format "C_S%d_AXI_BASEADDR" $port_id] $drv_handle]
			set mbox_highaddr [common::get_property CONFIG.[format "C_S%d_AXI_HIGHADDR" $port_id] $drv_handle]
			set is_axi4lite_connected [check_if_connected $drv_handle $port_id $processor]
		} else {
			# AXI4STREAM interface
			set send_fsl 0
			set recv_fsl  0
			set delete_node	0

			handle_stream $drv_handle $port_interface $port_id $processor use_fsl send_fsl recv_fsl delete_node

			set mbox_use_fsl        $use_fsl
			set mbox_send_fsl       $send_fsl
			set mbox_recv_fsl       $recv_fsl

			# Only update mbox_delete_node if it should be deleted
			if {$delete_node == 1} {
				set mbox_delete_node 1
			}
		}

		# If this processor is connected, add it to the list
		if { $is_axi4lite_connected == 1 || $use_fsl == 1 } {
			lappend connected_processors $processor

			# Create the node only once (for the first connected processor)
			if {$node_created == 0} {
				if {$mbox_baseaddr != 0} {
					# AXI-Lite interface: use actual base address
					set nodename_baseaddr [format %lx $mbox_baseaddr]
				} else {
					# AXI-Stream interface: use decreasing counter as base address in reg format
					# Format as hex string to ensure consistent hex representation
					set mbox_baseaddr [format "0x%X" $stream_node_counter]
					set mbox_highaddr [format "0x%X" [expr {$stream_node_counter + $size - 1}]]
					set nodename_baseaddr [format "%x" $stream_node_counter]
					set stream_node_counter [expr {$stream_node_counter - $size}]
				}

				set node [create_node -n $label_name -l $label_name -u $nodename_baseaddr -p $bus_name -d $dts_file]
				set reg [gen_reg_property_format $mbox_baseaddr $mbox_highaddr $bit_format]

				# Add properties to the node
				add_prop "${node}" "xlnx,send-fsl" $mbox_send_fsl int $dts_file
				add_prop "${node}" "xlnx,recv-fsl" $mbox_recv_fsl int $dts_file
				add_prop "${node}" "xlnx,use-fsl" $mbox_use_fsl int $dts_file
				add_prop "${node}" "compatible" $compatible string $dts_file
				add_prop "${node}" "xlnx,ip-name" $ip_name string $dts_file
				add_prop "${node}" "xlnx,name" $name string $dts_file
				add_prop "${node}" "status" "okay" string $dts_file
				add_prop "${node}" "reg" $reg hexlist $dts_file

				# Append generic compatible string
				pldt append $node compatible "\ \, \"xlnx,mailbox\""

				# Add interrupt properties
				if {![string_is_empty $intr_val]} {
					add_prop "${node}" "interrupts" $intr_val intlist $dts_file
				}
				if {![string_is_empty $intr_parent]} {
					add_prop "${node}" "interrupt-parent" $intr_parent reference  $dts_file
				}
				set node_created 1
			}
		}
	}
	# Map the single node to all connected processors
	foreach processor $connected_processors {
		map_node_to_processor "${label_name}" $processor $reg $bit_format $mbox_baseaddr $size
	}

	# Delete node if C_USE_EXTENDED_FSL_INSTR not enabled on Microblaze for AXI Stream interface connectivity with mailbox core
	if { $mbox_delete_node == 1 && $node_created == 1 } {
		pldt delete $node
	}
}

proc check_if_connected {periph port_id processor} {
	set is_axi4lite_connected 0

	set mem [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $processor] -filter INSTANCE==$periph]

	# Filter out duplicate entries using base:high:slave_intf as key
	array set seen {}
	set unique_ranges {}

	foreach r $mem {
		set base [hsi::get_property BASE_VALUE $r]
		set high [hsi::get_property HIGH_VALUE $r]
		set slave_intf [hsi::get_property SLAVE_INTERFACE $r]
		set key "$base:$high:$slave_intf"
		if {![info exists seen($key)]} {
			set seen($key) 1
			lappend unique_ranges $r
		}
	}

	# Check if processor has any mem_range with the correct SLAVE_INTERFACE (S0_AXI or S1_AXI)
	# This allows NOC address translation where different processors see different addresses
	foreach r $unique_ranges {
		set slave_intf [hsi::get_property SLAVE_INTERFACE $r]
		# Check if this mem_range is for the correct port (S0_AXI or S1_AXI)
		if {[string match "*S${port_id}_AXI*" $slave_intf]} {
			set is_axi4lite_connected 1
			break
		}
	}
	return $is_axi4lite_connected
}

proc handle_stream {periph port_interface port_id processor usefsl sendfsl recvfsl deletenode} {
	upvar $recvfsl   recv_fsl
	upvar $sendfsl  send_fsl
	upvar $usefsl   use_fsl

	upvar $deletenode	delete_node

	set not_connected 0

	set periph_name [string toupper [common::get_property NAME $periph]]
	set initiator_handle [get_connected_intf $periph S${port_id}_AXIS]
	if { [llength $initiator_handle] == 0 } {
		incr not_connected
	} else {
		set maxis_initiator_handle [hsi::get_cells -of_objects $initiator_handle]
		if { $maxis_initiator_handle == $processor } {
			if {[common::get_property CONFIG.C_USE_EXTENDED_FSL_INSTR $processor] != 1 } {
				puts "WARNING: The mailbox node requires parameter C_USE_EXTENDED_FSL_INSTR on MicroBlaze to be enabled when an AXI Stream interface is used to connect the mailbox core."
				set delete_node	1
			}
			set initiator_name [common::get_property NAME $initiator_handle]
			scan $initiator_name "M%d_AXIS" send_fsl
			set use_fsl 1
		} else {
			set use_fsl 0
		}
	}

	set target_handle [get_connected_intf $periph M${port_id}_AXIS]
	if { [llength $target_handle] == 0 } {
		incr not_connected
	} else {
		set saxis_target_handle [hsi::get_cells -of_objects $target_handle]
		if { $saxis_target_handle == $processor } {
			if {[common::get_property CONFIG.C_USE_EXTENDED_FSL_INSTR $processor] != 1 } {
				puts "WARNING: The mailbox node requires parameter C_USE_EXTENDED_FSL_INSTR on MicroBlaze to be enabled when an AXI Stream interface is used to connect the mailbox core."
				set delete_node	1
			}
			set target_name [common::get_property NAME $target_handle]
			scan $target_name "S%d_AXIS" recv_fsl
			set use_fsl 1
		} else {
			set use_fsl 0
		}
	}

	if { $not_connected == 2 } {
		puts "WARNING: Unable to figure out AXI stream connectivity for Interface $port_id on mailbox $periph_name."
		set delete_node	1
	}
}
