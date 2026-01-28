#
# (C) Copyright 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc axi_vcu2_generate {drv_handle} {
        # Generate properties required for vcu2 node
        set node [get_node $drv_handle]
        if {$node == 0} {
           return
        }
        set parent [get_node amba_pl]
        set dts_file [set_drv_def_dts $drv_handle]
        add_prop $node "#address-cells" 2 int $dts_file
        add_prop $node "#size-cells" 2 int $dts_file
        add_prop $node "#clock-cells" 1 int $dts_file
        set vcu2_ip [hsi::get_cells -hier $drv_handle]
        set baseaddr [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $drv_handle]]
        foreach ip_mem_bank [hsi::get_mem_ranges $drv_handle -of_objects [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}] 0]] {
            if ([string match "VCU2_0_S_AXI" [hsi get_property ADDRESS_BLOCK $ip_mem_bank]]) {
                set baseaddr [hsi get_property BASE_VALUE $ip_mem_bank]
            }
        }
        set nsu_path [hsi get_property CONFIG.NSU_PATH_ONLY [hsi::get_cells -hier $drv_handle]]
        # If it's empty, fall back to NSU_ONLY
            if { $nsu_path eq "" } {
                set nsu_path [hsi get_property CONFIG.NSU_ONLY [hsi::get_cells -hier $drv_handle]]
            }
	    if {[string match -nocase $nsu_path "TRUE"]} {
		    puts "VCU2 is using NSU path, so skipping interrupts"
	    } else {
            set intr_val [pldt get $node interrupts]
            set intr_val [string trimright $intr_val ">"]
            set intr_val [string trimleft $intr_val "<"]
            set intr_names [pldt get $node interrupt-names]
            set intr_names [string map {"," "" "\"" ""} $intr_names]
            set intr_mapping {}
            for {set i 0} {$i < [llength $intr_names]} {incr i} {
                # Extract the next three values (base address, IRQ number, flags)
                set value [lrange $intr_val [expr $i * 3] [expr $i * 3 + 2]]
                # Map the name to its value
                dict set intr_mapping [lindex $intr_names $i] $value
            }
            set intr_parent [pldt get $node interrupt-parent]
            set intr_parent [string trimright $intr_parent ">"]
            set intr_parent [string trimleft $intr_parent "<"]
            set intr_parent [string trimleft $intr_parent "&"]
        }

        # Generate child node encoder
        set encoder_enable [hsi get_property CONFIG.C0_ENABLE_ENCODER [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $encoder_enable "TRUE"]} {
            set encoder_mcu_clk [hsi get_property CONFIG.C0_ENC_MCU_AND_CORE_CLK [hsi::get_cells -hier $drv_handle]]
            set encoder_offset 0x40000
            set encoder_baseaddr [format %08x [expr $baseaddr + $encoder_offset]]
            set encoder_node [create_node -l "encoder" -n "ale2xx" -u $encoder_baseaddr -p $parent -d $dts_file]
            set encoder_comp "al,ale2xx"
            add_prop "${encoder_node}" compatible $encoder_comp string $dts_file
            add_prop "${encoder_node}" xlnx,mcu-clk $encoder_mcu_clk int $dts_file
            if {"0x$encoder_baseaddr" > 0xFFFFFFFF} {
                set high_addr [format %08x [expr (("0x$encoder_baseaddr") >> 32) & 0xFFFFFFFF]]
                set low_addr [format %08x [expr ("0x$encoder_baseaddr") & 0xFFFFFFFF]]
                set encoder_reg "0x$high_addr 0x$low_addr 0x0 0x80000 0x0 0x8000000 0x0 0x8000000"
            } else {
                set encoder_reg "0x0 0x$encoder_baseaddr 0x0 0x80000 0x0 0x8000000 0x0 0x8000000"
            }
            add_prop "${encoder_node}" "reg" $encoder_reg hexlist $dts_file
	        if {[string match -nocase $nsu_path "FALSE"]} {
                dict for {key value} $intr_mapping {
                    if {[string match "*enc*" $key]} {
                        add_prop "${encoder_node}" "interrupts" "$value" hexlist $dts_file
                    }
                }
                add_prop "${encoder_node}" "interrupt-parent" $intr_parent reference  $dts_file
            }
            add_prop "${encoder_node}" "reg-names" "regs apb" stringlist $dts_file
            add_prop "${encoder_node}" "clock-names" "mcu" stringlist $dts_file
            add_prop "${encoder_node}" "al,devicename" "al_e2xx" string $dts_file
        }

        # Generate child node decoder
        set decoder_enable [hsi get_property CONFIG.C0_ENABLE_DECODER [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $decoder_enable "TRUE"]} {
            set decoder_mcu_clk [hsi get_property CONFIG.C0_DEC_MCU_AND_CORE_CLK [hsi::get_cells -hier $drv_handle]]
            set decoder_offset 0x80000
            set decoder_baseaddr [format %08x [expr $baseaddr + $decoder_offset]]
            set decoder_node [create_node -l "decoder" -n "ald3xx" -u $decoder_baseaddr -p $parent -d $dts_file]
            set decoder_comp "al,ald3xx"
            add_prop "${decoder_node}" xlnx,mcu-clk $decoder_mcu_clk int $dts_file
            add_prop "${decoder_node}" compatible $decoder_comp string $dts_file
            if {"0x$decoder_baseaddr" > 0xFFFFFFFF} {
                set high_addr [format %08x [expr (("0x$decoder_baseaddr") >> 32) & 0xFFFFFFFF]]
                set low_addr [format %08x [expr ("0x$decoder_baseaddr") & 0xFFFFFFFF]]
                set decoder_reg "0x$high_addr 0x$low_addr 0x0 0x80000 0x0 0x00000000 0x0 0x8000000"
            } else {
                set decoder_reg "0x0 0x$decoder_baseaddr 0x0 0x80000 0x0 0x00000000 0x0 0x08000000"
            }
            add_prop "${decoder_node}" "reg" $decoder_reg hexlist $dts_file
	        if {[string match -nocase $nsu_path "FALSE"]} {
                dict for {key value} $intr_mapping {
                    if {[string match "*dec*" $key]} {
                        add_prop "${decoder_node}" "interrupts" "$value" hexlist $dts_file
                    }
                }
                add_prop "${decoder_node}" "interrupt-parent" $intr_parent reference  $dts_file
            }
            add_prop "${decoder_node}" "reg-names" "regs apb" stringlist $dts_file
            add_prop "${decoder_node}" "clock-names" "mcu" stringlist $dts_file
            add_prop "${decoder_node}" "al,devicename" "al_d3xx" string $dts_file
        }

    }
