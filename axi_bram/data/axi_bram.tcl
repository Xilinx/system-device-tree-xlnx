#
# (C) Copyright 2014-2021 Xilinx, Inc.
# (C) Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc axi_bram_is_ecc_bank {base_name} {
	return [string equal $base_name "C_S_AXI_CTRL_BASEADDR"]
}

proc axi_bram_mem_handles_have_ecc_bank {ip_mem_handles} {
	foreach bank ${ip_mem_handles} {
		if {[axi_bram_is_ecc_bank [hsi get_property BASE_NAME $bank]]} {
			return 1
		}
	}
	return 0
}

proc axi_bram_format_memmap {base high bit_format} {
	set memmap [gen_reg_property_format $base $high $bit_format]
	if {$bit_format == 32} {
		set size [format 0x%x [expr {${high} - ${base} + 1}]]
		set memmap "0x0 $base 0x0 $size"
	}
	return $memmap
}

proc axi_bram_memory_label {drv_handle is_ilmb_partner} {
	set memory_label "${drv_handle}_memory"
	if {$is_ilmb_partner} {
		regsub -nocase {ilmb_bram_if_cntlr_memory$} $memory_label {dlmb_bram_if_cntlr_memory} memory_label
	}
	return $memory_label
}

proc axi_bram_map_ecc_controller {node procc proc_ip_name drv_handle ecc_base ecc_high bit_format} {
	set ecc_memmap [axi_bram_format_memmap $ecc_base $ecc_high $bit_format]
	add_prop $node "xlnx,mem-ctrl-base-address" $ecc_base int "pl.dtsi"
	add_prop $node "xlnx,mem-ctrl-high-address" $ecc_high int "pl.dtsi"
	axi_bram_proc_mapping $procc $proc_ip_name $ecc_memmap $drv_handle
}

proc axi_bram_generate {drv_handle} {
	set node [get_node $drv_handle]
	set a53 0
	set drv_handle [hsi::get_cells -hier ${drv_handle}]
	global apu_proc_ip
	global is_64_bit_mb
	set family [get_hw_family]
	if {$family in {"microblaze" "microblaze_riscv" "zynq"} && !$is_64_bit_mb} {
		set bit_format 32
	} else {
		set bit_format 64
	}

	pldt append $node compatible "\ \, \"xlnx,axi-bram-ctrl\""
	# HSI reports ilmb_ram and dlmb_ram as two different IPs even though it points to the same BRAM_CNTRL. The
	# linker needs just one entry among these two and other is just a redundant data for us.
	# e.g.: microblaze_0_local_memory_dlmb_bram_if_cntlr_0 and microblaze_0_local_memory_ilmb_bram_if_cntlr
	# one out of these two are sufficient to be used under memory section. If both will be kept as memory, they
	# will point to the same memory with different names leading to ambiguity. Moreover, In case of multiple
	# microblazes in design, There will be 2 BRAM CNTRL, in total 4 IPs (2 ilmb and 2dlmb), out of which One
	# from each CNTRL has to be preserved under the memory node.

	set drv_ip [get_ip_property $drv_handle IP_NAME]
	set is_lmb [string match -nocase $drv_ip "lmb_bram_if_cntlr"]
	set is_ilmb_partner [expr {$is_lmb && [regexp -nocase {ilmb_bram_if_cntlr$} $drv_handle]}]

	set lmb_base 0
	set lmb_high 0
	set ecc_base 0
	set ecc_high 0
	set ecc_val [hsi get_property CONFIG.C_ECC $drv_handle]
	set have_ecc [expr {![string_is_empty $ecc_val] && $ecc_val == 1}]
	# Ordinary axi_bram_ctrl uses the ECC bank reported in each processor's map.
	set have_ecc_ctrl [expr {!$is_lmb && $have_ecc}]

	if {$is_lmb} {
		set lmb_base [hsi get_property CONFIG.C_BASEADDR $drv_handle]
		set lmb_high [hsi get_property CONFIG.C_HIGHADDR $drv_handle]
		if {[string_is_empty $ecc_val]} {
			error "$drv_handle: CONFIG.C_ECC is empty"
		}
		if {$have_ecc} {
			set ecc_base [hsi get_property CONFIG.C_S_AXI_CTRL_BASEADDR $drv_handle]
			set ecc_high [hsi get_property CONFIG.C_S_AXI_CTRL_HIGHADDR $drv_handle]
			if {$ecc_base > 0} {
				foreach procc [get_proc_list_without_pmc] {
					set ip_mem_handles [hsi::get_mem_ranges -of_objects $procc -filter INSTANCE==$drv_handle]
					if {[axi_bram_mem_handles_have_ecc_bank $ip_mem_handles]} {
						set have_ecc_ctrl 1
						break
					}
				}
			}
		}
		set data_width [hsi get_property CONFIG.C_S_AXI_DATA_WIDTH $drv_handle]
		if {[string_is_empty $data_width]} {
			set data_width 32
		}
		add_prop $node "xlnx,data-width" $data_width int "pl.dtsi"
	}

	# ILMB shares DLMB physical BRAM; skip unless ECC needs this instance processed.
	if {$is_ilmb_partner && !$have_ecc_ctrl} {
		return
	}

	set create_memory_node [expr {!$is_ilmb_partner}]
	set overall_reg ""
	set memory_reg ""
	set memory_unit_addr ""

	set proclist [get_proc_list_without_pmc]
	foreach procc $proclist {
		set proc_specific_reg ""
		set proc_ip_name [get_ip_property $procc IP_NAME]
		if { $proc_ip_name == $apu_proc_ip} {
			if {$a53 == 1} {
				continue
			}
			set a53 1
		}
		set ip_mem_handles [hsi::get_mem_ranges -of_objects $procc -filter INSTANCE==$drv_handle]
		set proc_has_ecc_bank [axi_bram_mem_handles_have_ecc_bank $ip_mem_handles]

		foreach bank ${ip_mem_handles} {
			set base_name [hsi get_property BASE_NAME $bank]
			set base [hsi get_property BASE_VALUE $bank]
			set high [hsi get_property HIGH_VALUE $bank]

			if {[lsearch -exact $proc_specific_reg $base_name] != -1} {
				continue
			}
			lappend proc_specific_reg $base_name

			set reg [gen_reg_property_format $base $high $bit_format]
			set memmap_format [axi_bram_format_memmap $base $high $bit_format]

			if {$have_ecc_ctrl && [axi_bram_is_ecc_bank $base_name]} {
				if {!$is_lmb} {
					set ecc_base $base
					set ecc_high $high
				}
				axi_bram_map_ecc_controller $node $procc $proc_ip_name $drv_handle \
					$ecc_base $ecc_high $bit_format
			} elseif {![axi_bram_is_ecc_bank $base_name]} {
				set memory_label [axi_bram_memory_label $drv_handle $is_ilmb_partner]
				if {$create_memory_node} {
					axi_bram_proc_mapping $procc $proc_ip_name $memmap_format $memory_label
					if {[lsearch -exact $overall_reg $reg] == -1} {
						lappend overall_reg $reg
						if {[string_is_empty $memory_reg]} {
							set memory_reg $reg
							set memory_unit_addr [remove_prefix_from_addr [format 0x%x $base]]
						}
					}
					if {!$have_ecc_ctrl} {
						axi_bram_proc_mapping $procc $proc_ip_name $memmap_format $drv_handle
					}
				} elseif {!$proc_has_ecc_bank} {
					axi_bram_proc_mapping $procc $proc_ip_name $memmap_format $memory_label
				}
			}
		}

		# LockStep slave CPUs may expose only the LMB bank in HSI.
		if {$is_lmb && $have_ecc_ctrl && !$proc_has_ecc_bank && [llength $ip_mem_handles] > 0} {
			axi_bram_map_ecc_controller $node $procc $proc_ip_name $drv_handle \
				$ecc_base $ecc_high $bit_format
		}
	}

	if {$create_memory_node && [llength $overall_reg] > 0} {
		set overall_reg [join $overall_reg ">, <"]
		set memory_node [create_node -n "memory" -l "${drv_handle}_memory" -u $memory_unit_addr -p root -d "system-top.dts"]
		add_prop "${memory_node}" "reg" $overall_reg hexlist "system-top.dts" 1
		add_prop "${memory_node}" "device_type" "memory" string "system-top.dts" 1
		add_prop "${memory_node}" "xlnx,ip-name" $drv_ip string "system-top.dts"
		add_prop "${memory_node}" "memory_type" "memory" string "system-top.dts"
		set compat_string [gen_compatible_string $drv_handle]
		if {$is_lmb} {
			lappend compat_string "mmio-sram"
		}
		add_prop ${memory_node} "compatible" $compat_string stringlist "system-top.dts"
		if {![string_is_empty $memory_reg]} {
			add_prop "${memory_node}" "ranges" "0 $memory_reg" hexlist "system-top.dts" 1
		}
		if {$bit_format == 32} {
			add_prop "${memory_node}" "#address-cells" 1 int "system-top.dts" 1
			add_prop "${memory_node}" "#size-cells" 1 int "system-top.dts" 1
		} else {
			add_prop "${memory_node}" "#address-cells" 2 int "system-top.dts" 1
			add_prop "${memory_node}" "#size-cells" 2 int "system-top.dts" 1
		}
	}

	if {$is_lmb} {
		set proctype [get_hw_family]
		if {[string match -nocase $proctype "versal"] || [is_zynqmp_platform $proctype]} {
			set reg_bit_format 64
		} else {
			set reg_bit_format $bit_format
		}
		set reg [gen_reg_property_format $lmb_base $lmb_high $reg_bit_format]
		if {$have_ecc_ctrl} {
			set reg "[gen_reg_property_format $ecc_base $ecc_high $reg_bit_format] $reg"
		}
		add_prop $node "reg" $reg hexlist "pl.dtsi" 1
	} elseif {$have_ecc_ctrl && $ecc_base > 0 && [llength $overall_reg] > 0} {
		# Keep the ECC control bank first so it matches the controller unit address.
		set reg [gen_reg_property_format $ecc_base $ecc_high $bit_format]
		foreach memory_bank_reg $overall_reg {
			append reg " $memory_bank_reg"
		}
		add_prop $node "reg" $reg hexlist "pl.dtsi" 1
	}
}

proc axi_bram_proc_mapping {proc_instance proc_ip_name memmap node_label} {
	set proc_key $proc_instance
	switch -glob -- $proc_ip_name {
		"psu_cortexr5" - "psv_cortexr5" - "psx_cortexr52" - "cortexr52" {
			set_memmap ${node_label} $proc_instance $memmap
		}
		"*cortexa*" {
			set_memmap ${node_label} a53 $memmap
		}
		"psu_pmu" {
			set_memmap ${node_label} pmu $memmap
		}
		"psv_psm" - "psx_psm" - "psm" {
			set_memmap ${node_label} psm $memmap
		}
		"asu" {
			set_memmap ${node_label} asu $memmap
		}
		"microblaze" - "microblaze_riscv" {
			set_memmap ${node_label} $proc_instance $memmap
		}
	}
}
