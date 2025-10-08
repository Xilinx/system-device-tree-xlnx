#
# (C) Copyright 2014-2021 Xilinx, Inc.
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

proc axi_bram_generate {drv_handle} {
	set node [get_node $drv_handle]
	set a53 0
	set drv_handle [hsi::get_cells -hier ${drv_handle}]
	set baseaddr [get_baseaddr $drv_handle noprefix]
	set dup_ilmb_dlmb_node 0
	global apu_proc_ip
	global is_64_bit_mb
	set family [get_hw_family]
	if {$family in {"microblaze" "Zynq"} && !$is_64_bit_mb} {
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

	set mb_proclist [hsi::get_cells -hier -filter {IP_NAME==microblaze || IP_NAME==microblaze_riscv}]
	foreach mb_proc $mb_proclist {
		set mb_proc_memmap [hsi::get_mem_ranges -of_objects $mb_proc]
		if {[lsearch $mb_proc_memmap $drv_handle] < 0} {
			continue
		}
		foreach periph $mb_proc_memmap {
			set periph_handle [hsi get_cells -hier $periph]
			if {![string_is_empty $periph_handle] \
				&& [string match -nocase [get_ip_property $periph_handle IP_NAME] "lmb_bram_if_cntlr"]} {
				set bram_base_addr [get_baseaddr $periph_handle noprefix]
				if {[string match -nocase $bram_base_addr $baseaddr]} {
					if {[systemdt exists "${periph_handle}_memory: memory@${bram_base_addr}"]} {
						set dup_ilmb_dlmb_node 1
						break
					}
				}
			}
		}
	}

	if { $dup_ilmb_dlmb_node == 1 } {
		return
	}

	set overall_reg ""

	set ecc_enabled 0
	set have_ecc [hsi get_property CONFIG.C_ECC [hsi::get_cells -hier $drv_handle]]

	set drv_ip [get_ip_property $drv_handle IP_NAME]
	set proclist [get_proc_list_without_pmc]
	foreach procc $proclist {
		set bram_device_memmap_format ""
		set proc_specific_reg ""
		set proc_ip_name [get_ip_property $procc IP_NAME]
		if { $proc_ip_name == $apu_proc_ip} {
			if {$a53 == 1} {
				continue
			}
			set a53 1
		}
		set ip_mem_handles [hsi::get_mem_ranges -of_objects $procc -filter INSTANCE==$drv_handle]

		foreach bank ${ip_mem_handles} {
			set base [hsi get_property BASE_VALUE $bank]
			set high [hsi get_property HIGH_VALUE $bank]
			set base_name [hsi get_property BASE_NAME $bank]
			if {[string match -nocase $drv_ip "lmb_bram_if_cntlr"] } {
				set base [hsi get_property CONFIG.C_BASEADDR $drv_handle]
				set high [hsi get_property CONFIG.C_HIGHADDR $drv_handle]
				set width [hsi get_property CONFIG.C_S_AXI_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
				if {[llength $width] == 0} {
					set width 32
				}
				add_prop $node "xlnx,data-width" $width int "pl.dtsi"
			}

			set reg [gen_reg_property_format $base $high $bit_format]
			if {[lsearch -exact $proc_specific_reg $reg] == -1 } {
				lappend proc_specific_reg $reg
			} else {
				continue
			}
			set memmap_format $reg
			if {$bit_format == 32} {
				set size [format 0x%x [expr {${high} - ${base} + 1}]]
				set memmap_format "0x0 $base 0x0 $size"
			}
			if {$have_ecc} {
				if {$base_name == "C_S_AXI_CTRL_BASEADDR"} {
					add_prop $node "xlnx,mem-ctrl-base-address" $base int "pl.dtsi"
					add_prop $node "xlnx,mem-ctrl-high-address" $high int "pl.dtsi"
					axi_bram_proc_mapping $procc $proc_ip_name $memmap_format $drv_handle
				} else {
					set bram_device_memmap_format $memmap_format
					axi_bram_proc_mapping $procc $proc_ip_name $memmap_format "${drv_handle}_memory"
					if {[lsearch -exact $overall_reg $reg] == -1} {
						lappend overall_reg $reg
					}
				}
			} else {
				axi_bram_proc_mapping $procc $proc_ip_name $memmap_format "${drv_handle}_memory"
				axi_bram_proc_mapping $procc $proc_ip_name $memmap_format $drv_handle
				if {[lsearch -exact $overall_reg $reg] == -1} {
					lappend overall_reg $reg
				}
			}
		}
	}

	if {[llength $overall_reg] > 0} {
		set overall_reg [join $overall_reg ">, <"]
		set memory_node [create_node -n "memory" -l "${drv_handle}_memory" -u $baseaddr -p root -d "system-top.dts"]
		add_prop "${memory_node}" "reg" $overall_reg hexlist "system-top.dts" 1
		add_prop "${memory_node}" "device_type" "memory" string "system-top.dts" 1
		add_prop "${memory_node}" "xlnx,ip-name" $drv_ip string "system-top.dts"
		add_prop "${memory_node}" "memory_type" "memory" string "system-top.dts"
		add_prop ${memory_node} "compatible" [gen_compatible_string $drv_handle] string "system-top.dts"
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