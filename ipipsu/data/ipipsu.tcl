#
# (C) Copyright 2019-2021 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc ipipsu_generate {drv_handle} {
	global parent_ipi_node_accessed
	set ipi_list [hsi get_cells -hier -filter {IP_NAME == "psu_ipi" || IP_NAME == "psv_ipi" || IP_NAME == "psx_ipi" || IP_NAME == "ipi"}]
	set src_buffer_index [hsi get_property CONFIG.C_BUFFER_INDEX [hsi get_cells -hier $drv_handle]]
	set src_buffer_base [hsi get_property CONFIG.C_BUFFER_BASE [hsi get_cells -hier $drv_handle]]
	set base [get_baseaddr $drv_handle]
	set node [get_node $drv_handle]
	# For some of the Versal Premium devices, there is a duplication of PS IP cell objects.
	# One set of names starts with pmcps_0_<ip_name> and other with ps_wizard_0_pmcps_0_<ip_name>.
	# Below is needed to distinguish the redundant entries.
	if {!($node in $parent_ipi_node_accessed)} {
		lappend parent_ipi_node_accessed $node
	} else {
		return
	}
	set proctype [get_hw_family]
	set dts_file "pcw.dtsi"
	set cpu [hsi get_property CONFIG.C_CPU_NAME [hsi::get_cells -hier $drv_handle]]

	if {![is_zynqmp_platform $proctype]} {
		generate_reg_versal $node $dts_file $src_buffer_base $src_buffer_index $drv_handle
		generate_reg_names_versal $node $dts_file $src_buffer_index
	}

	# Map IPI nodes to corresponding CPU Master
	ipi_cpu_mapping $cpu $drv_handle $node $base

	# if the CPU name is PL, then call interrupt update
	if {[regexp {^(S_AXI_FPD|S_AXI_GP2|S_AXI_LPD|S_ACP_FPD|S_ACE_FPD|PL_AXI_LPD|PL_AXI_FPD*|PL_ACP_APU|CPM)} $cpu]} {
		ipi_pl_interrupt_update $drv_handle $node
	}

	# Generate all the available IPI child nodes and return the target ipi count
	set target_count [generate_ipi_child_nodes $ipi_list $node $drv_handle $src_buffer_base $src_buffer_index $dts_file $proctype $cpu]
	add_prop $node "xlnx,ipi-target-count" $target_count int $dts_file

}

# Generate IPI child nodes
proc generate_ipi_child_nodes {ipi_list node drv_handle src_buffer_base src_buffer_index dts_file proctype cpu} {
	# Constants for buffer calculations
	set default_buffer_index 0xffff
	set response_offset 0x20
	set buffer_size 64

	set src_name [extract_ipi_number [hsi get_property NAME $drv_handle]]
	set idx 0
	set ipi5_present 0
	set child_node_label_list [list]
	foreach ipi_slave $ipi_list {
		# Generate child node label
		set dest_name [extract_ipi_number [hsi get_property NAME $ipi_slave]]
		if {$dest_name eq "ipi_5"} {
			set ipi5_present 1
		}
		set child_node_label "${src_name}_to_${dest_name}"
		# For some of the Versal Premium devices, there is a duplication of PS IP cell objects.
		# One set of names starts with pmcps_0_<ip_name> and other with ps_wizard_0_pmcps_0_<ip_name>.
		# Below is needed to distinguish the redundant entries.
		if {!($child_node_label in $child_node_label_list)} {
			lappend child_node_label_list $child_node_label
		} else {
			continue
		}

		# Create child node for this IPI slave
		set childname_baseaddr [format %lx [get_baseaddr $ipi_slave]]
		set child_node_name "$child_node_label: child@$childname_baseaddr"
		set slv_node [string trim [pcwdt insert $node end $child_node_name] "{}"]

		# Get hardware properties for this slave
		set buffer_index [hsi get_property CONFIG.C_BUFFER_INDEX [hsi get_cells -hier $ipi_slave]]
		set bit_position [hsi get_property CONFIG.C_BIT_POSITION [hsi get_cells -hier $ipi_slave]]
		set child_cpu_name [hsi get_property CONFIG.C_CPU_NAME [hsi get_cells -hier $ipi_slave]]
		set buffer_base [hsi get_property CONFIG.C_BUFFER_BASE [hsi get_cells -hier $ipi_slave]]
		set bit_mask [expr 1 << $bit_position]

		# Generate reg and reg-name properties
		if {![is_zynqmp_platform $proctype]} {
			generate_reg_versal $slv_node $dts_file $buffer_base $buffer_index $ipi_slave
			generate_reg_names_versal $slv_node $dts_file $buffer_index
		} else {
			generate_reg_zynqmp $slv_node $dts_file $src_buffer_base $buffer_base $src_buffer_index $buffer_index $ipi_slave
			generate_reg_names_zynqmp $slv_node $dts_file
		}

		# Normalize buffer index - handle NIL and empty values
		if {[string match -nocase $buffer_index "NIL"] || [string_is_empty $buffer_index]} {
			set buffer_index $default_buffer_index
		} else {
			# Configure buffer addresses only if both buffer_index and src_buffer_index are valid
			if {![string match -nocase $src_buffer_index "NIL"]} {
				set buffer_addresses [calculate_ipi_buffer_addresses $src_buffer_base $buffer_index]
				set req_base [lindex $buffer_addresses 0]
				set res_base [lindex $buffer_addresses 1]
				add_prop $slv_node "xlnx,ipi-req-msg-buf" $req_base hexint $dts_file
				add_prop $slv_node "xlnx,ipi-rsp-msg-buf" $res_base hexint $dts_file
			}
		}

		# Add properties to the slave node
		add_prop $slv_node "xlnx,ipi-buf-index" $buffer_index int $dts_file
		add_prop $slv_node "xlnx,cpu-name" $child_cpu_name string $dts_file
		add_ipi_id $slv_node $proctype $ipi_slave $dts_file $bit_position
		add_prop $slv_node "xlnx,ipi-bitmask" $bit_mask int $dts_file
		add_prop $slv_node "#mbox-cells" 1 int $dts_file
		generate_compatible $slv_node $proctype $dts_file

		incr idx
	}

	# PMC needs a target entry for IPI5 even when the design does not instantiate it,
	# as in JTAG mode XSDB requires IPI5 to communicate with PLM. 0x80 and 7 are the
	# Versal IPI5 bitmask and buffer index. Only the PMC channel that owns a message
	# buffer is eligible, the no-buffer one cannot carry the XSDB payload.
	if {$cpu eq "PMC" && !$ipi5_present && ![string match -nocase $src_buffer_index "NIL"]} {
		set xsdb_node [string trim [pcwdt insert $node end "${src_name}_to_xsdb: child"] "{}"]
		add_prop $xsdb_node "xlnx,ipi-bitmask" 0x80 hexint $dts_file
		add_prop $xsdb_node "xlnx,ipi-buf-index" 7 int $dts_file
		incr idx
	}
	return $idx
}

# Generate child node compatible string
proc generate_compatible {node proctype dts_file} {
	if {[is_zynqmp_platform $proctype]} {
		set compatible_string "xlnx,zynqmp-ipi-dest-mailbox"
	} else {
		set compatible_string "xlnx,versal-ipi-dest-mailbox"
	}
	add_prop $node "compatible" $compatible_string string $dts_file
}

# Generate reg property for Versal series
proc generate_reg_versal {node dts_file buffer_base buffer_index ipi_handle} {
	set bit_format 64
	set baseaddr [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi get_cells -hier $ipi_handle]]
	set highaddr [hsi get_property CONFIG.C_S_AXI_HIGHADDR [hsi get_cells -hier $ipi_handle]]
	set reg [gen_reg_property_format $baseaddr $highaddr $bit_format]
	set region_size 0x1ff
	if { ![string match -nocase $buffer_index "NIL"]} {
		set buffer_high [get_buffer_high $buffer_base $region_size]
		set buffer_reg [gen_reg_property_format $buffer_base $buffer_high $bit_format]
		foreach item $buffer_reg {
			lappend reg $item
		}
	}
	add_prop $node "reg" $reg hexlist $dts_file
}

# Generate reg property for ZynqMP
proc generate_reg_zynqmp {node dts_file src_buffer_base dest_buffer_base src_buffer_index dest_buffer_index ipi_handle} {
	set bit_format 64

	# Calculate local regions (source IPI's buffers to destination)
	set local_buffer_addresses [calculate_ipi_buffer_addresses $src_buffer_base $dest_buffer_index]
    set local_request_region [format 0x%x [lindex $local_buffer_addresses 0]]
	set local_response_region [format 0x%x [lindex $local_buffer_addresses 1]]

	# Calculate remote regions (destination IPI's buffers to source)
	set remote_buffer_addresses [calculate_ipi_buffer_addresses $dest_buffer_base $src_buffer_index]
	set remote_request_region [format 0x%x [lindex $remote_buffer_addresses 0]]
	set remote_response_region [format 0x%x [lindex $remote_buffer_addresses 1]]

	# Each region is 32 bytes (0x20)
	set region_size 0x1f

	# Generate reg property with four regions
	set local_req_high [get_buffer_high $local_request_region $region_size]
	set local_resp_high [get_buffer_high $local_response_region $region_size]
	set remote_req_high [get_buffer_high $remote_request_region $region_size]
	set remote_resp_high [get_buffer_high $remote_response_region $region_size]

	set local_req_reg [gen_reg_property_format $local_request_region $local_req_high $bit_format]
	set local_resp_reg [gen_reg_property_format $local_response_region $local_resp_high $bit_format]
	set remote_req_reg [gen_reg_property_format $remote_request_region $remote_req_high $bit_format]
	set remote_resp_reg [gen_reg_property_format $remote_response_region $remote_resp_high $bit_format]

	# Combine all regions into reg property
	set reg {}
	foreach item $local_req_reg {
		lappend reg $item
	}
	foreach item $local_resp_reg {
		lappend reg $item
	}
	foreach item $remote_req_reg {
		lappend reg $item
	}
	foreach item $remote_resp_reg {
		lappend reg $item
	}
	add_prop $node "reg" $reg hexlist $dts_file
}

# Calculate buffer high address
proc get_buffer_high {buffer_base region_size} {
	set buffer_high [format 0x%x [expr {$buffer_base + $region_size}]]
	return $buffer_high
}

# Calculate request and response buffer address
proc calculate_ipi_buffer_addresses {base_addr buffer_index} {
    set response_offset 0x20
	set buffer_size 64
    set req_base [expr {$base_addr + $buffer_size * $buffer_index}]
    set res_base [expr {$req_base + $response_offset}]
    return [list $req_base $res_base]
}

# Generate reg-names for Versal series
proc generate_reg_names_versal {node dts_file buffer_index} {
	add_prop $node "reg-names" "ctrl" string $dts_file
	if { ![string match -nocase $buffer_index "NIL"]} {
		pcwdt append $node reg-names "\ \, \"msg\""
	}
}

# Generate reg-names For ZynqMp
proc generate_reg_names_zynqmp {node dts_file} {
	set reg_names_list [list "local_request_region" "local_response_region" "remote_request_region" "remote_response_region"]
	add_prop $node "reg-names" $reg_names_list stringlist $dts_file
}

# Configure and add IPI ID based on platform type
proc add_ipi_id {node proctype ipi_slave dts_file bit_position} {
	if {[is_zynqmp_platform $proctype]} {
		# Using a dictionary to create baseaddress-ID mapping
		set ipi_id [dict create 0xff300000 0 0xff310000 1 0xff320000 2 0xff330000 3 0xff331000 4 0xff332000 5 0xff333000 6 0xff340000 7 0xff350000 8 0xff360000 9 0xff370000 10]
		set slave_base [get_baseaddr $ipi_slave]
		add_prop $node "xlnx,ipi-id" [dict get $ipi_id $slave_base] int $dts_file
	} else {
		add_prop $node "xlnx,ipi-id" $bit_position int $dts_file
	}
}

# Extract "ipi_x" from IPI Name
proc extract_ipi_number {ipi_name} {
	if {[regexp {ipi_(\w+)$} $ipi_name -> ipi_suffix]} {
		return "ipi_$ipi_suffix"
	}
}

# Configure memory mapping for IPI based on CPU type
proc ipi_cpu_mapping {cpu drv_handle node base} {
	set cpu [hsi get_property CONFIG.C_CPU_NAME [hsi::get_cells -hier $drv_handle]]
	set node_label [string trimleft $node "&"]
	set memmap_key [get_cpu_memmap_key $cpu $drv_handle]

	if {[llength $node] > 1} {
		set node_label [lindex [split $node_label ":"] 0]
	}

	if {![string_is_empty $memmap_key]} {
		set high [get_highaddr $drv_handle]
		set size [format 0x%x [expr {${high} - ${base} + 1}]]
		set_memmap $node_label $memmap_key "0x0 $base 0x0 $size"
	}
}

# Map CPU name to memory map identifier
proc get_cpu_memmap_key {cpu drv_handle} {
	set r5_procs [hsi::get_cells -hier -filter {IP_NAME==psv_cortexr5 || IP_NAME==psu_cortexr5 || IP_NAME==psx_cortexr52 || IP_NAME==cortexr52}]
	set memmap_key ""
	switch -glob $cpu {
		"APU" - "A72" - "A78_*" {
			set memmap_key "a53"
		}
		"RPU0" - "R5_0" - "R52_0" {
			set memmap_key [lindex $r5_procs 0]
		}
		"RPU1" - "R5_1" - "R52_1" {
			set memmap_key [lindex $r5_procs 1]
		}
		"R52_2" {
			set memmap_key [lindex $r5_procs 2]
		}
		"R52_3" {
			set memmap_key [lindex $r5_procs 3]
		}
		"R52_4" {
			set memmap_key [lindex $r5_procs 4]
		}
		"R52_5" {
			set memmap_key [lindex $r5_procs 5]
		}
		"R52_6" {
			set memmap_key [lindex $r5_procs 6]
		}
		"R52_7" {
			set memmap_key [lindex $r5_procs 7]
		}
		"R52_8" {
			set memmap_key [lindex $r5_procs 8]
		}
		"R52_9" {
			set memmap_key [lindex $r5_procs 9]
		}
		"PSM" {
			set memmap_key "psm"
		}
		"PMC" {
			set memmap_key "pmc"
		}
		"PMU" {
			set memmap_key "pmu"
		}
		"ASU" {
			set memmap_key "asu"
		}
		"S_AXI_FPD" - "S_AXI_GP2" - "S_AXI_LPD" - "S_ACP_FPD" - "S_ACE_FPD" - \
		"PL_AXI_LPD" - "PL_AXI_FPD*" - "PL_ACP_APU" - "CPM" {
			set memmap_key [memmap_pl_ipi $cpu $drv_handle]
		}
	}
	return $memmap_key
}

# Mem-Map for PL-IPI
proc memmap_pl_ipi {cpu drv_handle} {
	foreach processor [hsi::get_cells -hier -filter IP_TYPE==PROCESSOR] {
		# Get the memory ranges for the current processor
		set mem_ranges [hsi::get_mem_ranges -of_objects $processor]

		# Check if the drv_handle is in the memory ranges
		set idx [lsearch -exact $mem_ranges $drv_handle]
		if {$idx >= 0} {
			set matched_entry [lindex $mem_ranges $idx]
			# Check if slave-interface matches with cpu
			if {[string match -nocase [hsi get_property SLAVE_INTERFACE $matched_entry] $cpu]} {
				return $processor
			}
		}
	}
	return ""
}

# Update IPI PL Interrupt Properties for Versal and Versal-Gen2 platforms
proc ipi_pl_interrupt_update {drv_handle node} {
	global is_versal_net_platform
	global is_versal_2ve_2vm_platform

	# Check if the hardware family is Versal
	set proctype [get_hw_family]
	if {[string match -nocase $proctype "versal"]} {
		# Skip if it's a Versal-NET and not Versal-Gen2
		if { $is_versal_net_platform && !$is_versal_2ve_2vm_platform } {
			return
		}
	} else {
		# unsupported platforms
		return
	}

	set periph_val [lindex [split [hsi get_property HIER_NAME [hsi get_cells -hier $drv_handle]] "/"] 1]
	if {[string length $periph_val] == 0} {
		return
	}

	set expected_pin [get_expected_ipi_ps_pl_irq_pin $drv_handle $periph_val]
	set intc [get_interrupt_parent $periph_val $expected_pin]
	if {[string_is_empty $intc]} {
		return
	}

	set intr_info [get_intr_id $periph_val $expected_pin]
	if {[string match -nocase $intr_info "-1"]} {
		return
	}

	# Update interrupt properties in the device tree source file
	set dts_file [set_drv_def_dts $drv_handle]
	add_prop $node "interrupts" $intr_info intlist $dts_file
	add_prop $node "interrupt-parent" $intc reference $dts_file
}

# Extract expected PS_PL_IRQ PIN
proc get_expected_ipi_ps_pl_irq_pin {drv_handle periph_val} {
	set drv_intr_pin [hsi::get_pins -of_objects $drv_handle -filter "TYPE==INTERRUPT&&NAME=~*pl_irq*"]
	if {[llength $drv_intr_pin] == 1} {
		set last_part [lindex [split $drv_intr_pin "_"] end]
		return [hsi::get_pins -of_objects [hsi::get_cells -hier $periph_val] -filter "TYPE==INTERRUPT&&NAME=~*ps_pl_irq*$last_part"]
	}
	return ""
}
