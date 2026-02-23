#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc cpu_generate {drv_handle} {
        global mb_dict_64_bit
        global is_64_bit_mb
        global 64_bit_processor_list
        set proctype [get_hw_family]
        set addr_size [get_ip_property $drv_handle CONFIG.C_ADDR_SIZE]
        if {![string_is_empty $addr_size]} {
                set cell_size 1
                if {[expr $addr_size] > 32} {
                        set is_64_bit_mb 1
                        set cell_size 2
                        lappend 64_bit_processor_list $drv_handle
                }
                dict set mb_dict_64_bit $drv_handle $cell_size
        }
        # is_64_bit_mb must be set before calling add_or_get_bus_node proc to set the
        # correct address-cells and size-cells in amba_pl node
        set nr [get_microblaze_nr $drv_handle]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        set cpu_node [create_node -n "cpus_${ip_name}" -l "cpus_${ip_name}_${nr}" -u $nr -d "pl.dtsi" -p root]
        add_prop $cpu_node "compatible" "cpus,cluster" string "pl.dtsi"
        add_prop $cpu_node "#cpu-mask-cells" 1 int "pl.dtsi"
        add_prop $cpu_node "#address-cells" 1 int "pl.dtsi"
        add_prop $cpu_node "#size-cells" 0 int "pl.dtsi"
        set node [create_node -n "cpu" -l "$drv_handle" -u $nr -d "pl.dtsi" -p $cpu_node]
        add_prop $node device_type "cpu" string "pl.dtsi"
        set comp_prop [gen_compatible_string $drv_handle]
        if {$ip_name eq "microblaze_riscv"} {
		if {$is_64_bit_mb} {
			set comp_prop [concat $comp_prop {amd,mbv64 riscv}]
		} else {
			set comp_prop [concat $comp_prop {amd,mbv32 riscv}] }
        }
        add_prop $node compatible "$comp_prop xlnx,${ip_name}" stringlist "pl.dtsi"
        add_prop $node "xlnx,ip-name" $ip_name string "pl.dtsi"
        set model "$ip_name,[get_ip_version $drv_handle]"
        add_prop $node "model" $model string "pl.dtsi"
	if {$ip_name in {"microblaze" "microblaze_riscv"}} {
                set family [get_ip_property $drv_handle CONFIG.C_FAMILY]
		add_prop $node "xlnx,family" $family string "pl.dtsi"
	}
        add_prop $node "reg" $nr hexint "pl.dtsi"
        add_prop $node "bus-handle" "amba_pl" reference "pl.dtsi"

        set clk ""
        set clkhandle [hsi::get_pins -of_objects $drv_handle "CLK"]

        if { [string compare -nocase $clkhandle ""] != 0 } {
                set clk [hsi get_property CLK_FREQ $clkhandle]
        }
        if { [llength $drv_handle]  } {
                add_prop $node "clock-frequency" $clk int "pl.dtsi"
                add_prop $node "timebase-frequency" $clk int "pl.dtsi"
        }

        set icache_size [get_ip_param_value $drv_handle "C_ICACHE_BYTE_SIZE"]
        set isize  [cpu_check_64bit $icache_size]
        set icache_base [get_ip_param_value $drv_handle "C_ICACHE_BASEADDR"]
        set ibase  [cpu_check_64bit $icache_base]
        set icache_high [get_ip_param_value $drv_handle "C_ICACHE_HIGHADDR"]
        set ihigh_base  [cpu_check_64bit $icache_high]
        set dcache_size [get_ip_param_value $drv_handle "C_DCACHE_BYTE_SIZE"]
        set dsize  [cpu_check_64bit $dcache_size]
        set dcache_base [get_ip_param_value $drv_handle "C_DCACHE_BASEADDR"]
        set dbase  [cpu_check_64bit $dcache_base]
        set dcache_high [get_ip_param_value $drv_handle "C_DCACHE_HIGHADDR"]
        set dhigh_base  [cpu_check_64bit $dcache_high]
        set icache_line_size [expr 4*[get_ip_param_value $drv_handle "C_ICACHE_LINE_LEN"]]
        set dcache_line_size [expr 4*[get_ip_param_value $drv_handle "C_DCACHE_LINE_LEN"]]


        if { [llength $icache_size] != 0 } {
                add_prop $node "i-cache-baseaddr"  "$ibase" hexint "pl.dtsi"
                add_prop $node "i-cache-highaddr" $ihigh_base hexint "pl.dtsi"
                add_prop $node "i-cache-size" $isize int "pl.dtsi"
                add_prop $node "i-cache-line-size" $icache_line_size int "pl.dtsi"
        }
        if { [llength $dcache_size] != 0 } {
                add_prop $node "d-cache-baseaddr"  "$dbase" hexint "pl.dtsi"
                add_prop $node "d-cache-highaddr" $dhigh_base hexint "pl.dtsi"
                add_prop $node "d-cache-size" $dsize int "pl.dtsi"
                add_prop $node "d-cache-line-size" $dcache_line_size int "pl.dtsi"
        }

	# Generate xlnx,exceptions-in-delay-slots property
	if { $ip_name != "microblaze_riscv" } {
		set procver [get_ip_version $drv_handle]
		set procmajorver [lindex [split $procver "."] 0]
		if { [string compare -nocase $procver  "5.00.a"] >= 0 || $procmajorver > 5 } {
			set delayslotexception 1
		} else {
			set delayslotexception 0
		}
		add_prop $node "xlnx,exceptions-in-delay-slots"  "$delayslotexception" int "pl.dtsi"
	}
	gen_mb_interrupt_property $drv_handle
	gen_drv_prop_from_ip $drv_handle
	generate_mb_ccf_node $drv_handle

	if {$ip_name eq "microblaze_riscv"} {
		add_prop $cpu_node "bootph-all" "" boolean "pl.dtsi"
		add_prop $node "bootph-all" "" boolean "pl.dtsi"
		set riscv_props {
			CONFIG.C_DATA_SIZE
			CONFIG.C_ADDR_SIZE
			CONFIG.C_USE_MULDIV
			CONFIG.C_USE_ATOMIC
			CONFIG.C_USE_FPU
			CONFIG.C_USE_COMPRESSION
			CONFIG.C_USE_ICACHE
			CONFIG.C_USE_DCACHE
			CONFIG.C_USE_BITMAN_A
			CONFIG.C_USE_BITMAN_B
			CONFIG.C_USE_BITMAN_C
			CONFIG.C_USE_BITMAN_S
			CONFIG.C_TRAP_ENHANCEMENT
			CONFIG.C_USE_COUNTERS
			CONFIG.C_USE_MMU
			CONFIG.C_USE_SSTC
			CONFIG.C_PMP_ENTRIES
			CONFIG.C_PMP_ENHANCEMENTS
			CONFIG.C_DEBUG_EVENT_COUNTERS
			CONFIG.C_DEBUG_LATENCY_COUNTERS
		}
		foreach prop $riscv_props {
			set var_name [string tolower [string map {"CONFIG.C_" ""} $prop]]
			set $var_name [get_ip_property $drv_handle $prop]
		}

		set isa_base ""
		if {![string_is_empty $data_size]} {
			if {$is_64_bit_mb} {
				set isa_base "rv64"
			} else {
				set isa_base "rv32"
			}
			add_prop $node "riscv,isa-base" "${isa_base}i" string "pl.dtsi"
		}

		if {$use_mmu == 3 && ![string_is_empty $addr_size]} {
			add_prop $node "mmu-type" "riscv,sv${addr_size}" string "pl.dtsi"
		}

		set ext {"i"}
		if {$use_muldiv > 0} { lappend ext "m" }
		if {$use_atomic > 0} { lappend ext "a" }

		if {$use_fpu >= 1} {
			lappend ext "f"
			if {$is_64_bit_mb} {
				lappend ext "d"
			}
		}

		if {$use_compression > 0} { lappend ext "c" }

		set riscv_isa_entry ${isa_base}[join $ext ""]

		if {($use_icache > 0) || ($use_dcache > 0)} {
			lappend ext "zicbom"
			append riscv_isa_entry "_zicbom"
		}

		set ext [concat $ext {zicsr zifencei}]
		append riscv_isa_entry "_zicsr_zifencei"

		if {$use_bitman_a > 0 && $use_bitman_b > 0 && $use_bitman_s > 0} {
			lappend ext "b"
		}

		foreach entry {
			{use_bitman_a zba}
			{use_bitman_b zbb}
			{use_bitman_s zbs}
		} {
			lassign $entry prop token
			if {[set $prop] > 0} {
				lappend ext $token
				append riscv_isa_entry "_${token}"
			}
		}

		set conditional_exts {
			{$use_bitman_c > 0} zbc
			{$use_mmu > 3 && $use_sstc > 0} sstc
			{$use_mmu > 3 && $pmp_entries > 0 && $pmp_enhancements > 0} smepmp
			{$trap_enhancement == 2 || $trap_enhancement == 3} smrnmi
			{$trap_enhancement == 1 || $trap_enhancement == 3} smdbltrp
			{$use_counters > 0} zicntr
			{$debug_event_counters > 0 || $debug_latency_counters > 0} zihpm
		}
		foreach {condition token} $conditional_exts {
			if {[expr $condition]} {
				lappend ext $token
			}
		}

		add_prop $node "riscv,isa" "${riscv_isa_entry}" string "pl.dtsi"

		add_prop $node "riscv,isa-extensions" $ext stringlist "pl.dtsi"
		set cpu_intc [create_node -n "interrupt-controller" -l "cpu${nr}_intc" -d "pl.dtsi" -p $node]
		add_prop $cpu_intc "compatible" "riscv,cpu-intc" string "pl.dtsi"
		add_prop $cpu_intc "interrupt-controller" "" boolean "pl.dtsi"
		add_prop $cpu_intc "#interrupt-cells" 1 int "pl.dtsi"
	}

	# Speical handling for xlnx,memory-ip-list
	set valid_mem_list [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $drv_handle] -filter {IS_INSTRUCTION == true && IS_DATA == true && MEM_TYPE == "MEMORY"}]
	if {$valid_mem_list != ""} {
		foreach element $valid_mem_list {
			# Append the string and add the result to the modified list
			lappend modified_mem_list "${element}_memory"
		}
		add_prop $node "xlnx,memory-ip-list" $modified_mem_list stringlist "pl.dtsi"
	} else {
		set valid_inst_mem_list [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $drv_handle] -filter {IS_INSTRUCTION == true && MEM_TYPE == "MEMORY"}]
		set valid_data_mem_list [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $drv_handle] -filter {IS_DATA == true && MEM_TYPE == "MEMORY"}]
		if {$valid_inst_mem_list != "" && $valid_data_mem_list != ""} {
			set valid_inst_mem_addr_list [hsi get_property BASE_VALUE [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $drv_handle] -filter {IS_INSTRUCTION == true && MEM_TYPE == "MEMORY"}]]
			set valid_data_mem_addr_list [hsi get_property BASE_VALUE  [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $drv_handle] -filter {IS_DATA == true && MEM_TYPE == "MEMORY"}]]
			set common_indices [list]
			for {set idx1 0} {$idx1 < [llength $valid_inst_mem_addr_list]} {incr idx1} {
				# Get the element from list1
				set element1 [lindex $valid_inst_mem_addr_list $idx1]
				# Check if the element is in the second list
				set idx2 [lsearch $valid_data_mem_addr_list $element1]
				# If the element is found in both lists
				if {$idx2 != -1} {
					# Append the element and its indices from both lists
					lappend common_indices [list $element1 $idx1 $idx2]
				}
			}
			set valid_mem_list {}
			foreach entry $common_indices {
				if {[llength $entry] == 3} {
					foreach {element idx1 idx2} $entry {
						lappend valid_mem_list [lindex $valid_inst_mem_list $idx1]
						lappend valid_mem_list [lindex $valid_data_mem_list $idx2]
					}
				}
			}
			if {$valid_mem_list != ""} {
				foreach element $valid_mem_list {
					# Append the memory string as common code is adding memory string
					lappend modified_mem_list "${element}_memory"
				}
				add_prop $node "xlnx,memory-ip-list" $modified_mem_list stringlist "pl.dtsi"
			}
		}
	}
    }

    proc cpu_check_64bit {base} {
        if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                        set temp $base
                   set temp [string trimleft [string trimleft $temp 0] x]
                   set len [string length $temp]
                   set rem [expr {${len} - 8}]
                   set high_base "0x[string range $temp $rem $len]"
                   set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                   set low_base [format 0x%08x $low_base]
               if {$low_base == 0x0} {
                   set reg "$high_base"
                } else {
                        set reg "$low_base $high_base"
                }
           } else {
                set reg "$base"
        }
           return $reg
    }
