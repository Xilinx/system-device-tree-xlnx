#
# (C) Copyright 2017-2022 Xilinx, Inc.
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

    proc axi_vcu_generate {drv_handle} {
        # Generate properties required for vcu node
        set node [get_node $drv_handle]
        if {$node == 0} {
           return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        add_prop $node "#address-cells" 2 int $dts_file
        add_prop $node "#size-cells" 2 int $dts_file
        add_prop $node "#clock-cells" 1 int $dts_file
        set vcu_ip [hsi::get_cells -hier $drv_handle]
        set baseaddr [get_baseaddr $vcu_ip no_prefix]
        set slcr_offset 0x40000
        set logicore_offset 0x41000
        set vcu_slcr_reg [format %08x [expr 0x$baseaddr + $slcr_offset]]
        set logicore_reg [format %08x [expr 0x$baseaddr + $logicore_offset]]
        set reg "0x0 0x$vcu_slcr_reg 0x0 0x1000>, <0x0 0x$logicore_reg 0x0 0x1000"
        add_prop $node "reg" $reg hexlist $dts_file 1
        set intr_val [pldt get $node interrupts]
        set intr_val [string trimright $intr_val ">"]
        set intr_val [string trimleft $intr_val "<"]
        set intr_parent [pldt get $node interrupt-parent]
        set intr_parent [string trimright $intr_parent ">"]
        set intr_parent [string trimleft $intr_parent "<"]
        set intr_parent [string trimleft $intr_parent "&"]
        set clock-names " pll_ref\"\ \, \"aclk\""
        pldt append $node clock-names " , \"pll_ref\" , \"aclk\" , "
        zynq_gen_pl_clk_binding $drv_handle
        set first_reg_name "vcu_slcr"
        set second_reg_name " logicore"
        set reg_name [append first_reg_name $second_reg_name]
        add_prop "${node}" "reg-names" ${reg_name} stringlist $dts_file
        add_prop "${node}" "ranges" "" boolean $dts_file
        
        pldt append $node compatible "\ \, \"xlnx,vcu\""

        # Generate child encoder
        set ver [axi_vcu_get_ipdetails $drv_handle "ver"]
        set encoder_enable [hsi get_property CONFIG.ENABLE_ENCODER [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $encoder_enable "TRUE"]} {
            set encoder_node [create_node -l "encoder" -n "al5e" -u $baseaddr -p $node -d $dts_file]
            set encoder_comp "al,al5e-${ver}"
            add_prop "${encoder_node}" compatible $encoder_comp string $dts_file
            pldt append ${encoder_node} compatible "\ \, \"al,al5e\""
            set encoder_reg "0x0 0x$baseaddr 0x0 0x10000"
            add_prop "${encoder_node}" "reg" $encoder_reg hexlist $dts_file
            add_prop "${encoder_node}" "interrupts" $intr_val intlist $dts_file
            add_prop "${encoder_node}" "interrupt-parent" $intr_parent reference  $dts_file
        }
        set decoder_enable [hsi get_property CONFIG.ENABLE_DECODER [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $decoder_enable "TRUE"]} {
            # Fenerate child decoder
            set decoder_offset 0x20000
            set decoder_reg [format %08x [expr 0x$baseaddr + $decoder_offset]]
            set decoder_node [create_node -l "decoder" -n "al5d" -u $decoder_reg -p $node -d $dts_file]
            set decoder_comp "al,al5d-${ver}"
            add_prop "${decoder_node}" "compatible" $decoder_comp string $dts_file
            pldt append ${decoder_node} compatible "\ \, \"al,al5d\""
            set decoder_reg "0x0 0x$decoder_reg 0x0 0x10000"
            add_prop "${decoder_node}" "reg" $decoder_reg hexlist $dts_file
            add_prop "${decoder_node}" "interrupts" $intr_val intlist $dts_file
            add_prop "${decoder_node}" "interrupt-parent" $intr_parent reference $dts_file
            # When a PL DDR (vcu_ddr4_controller) is present in the design, create a
            # reserved-memory carveout for it and point the decoder to it via a
            # memory-region property. If no PL DDR is present, skip creating both.
            set plddr_ips [hsi::get_cells -hier -filter {IP_NAME == "vcu_ddr4_controller"}]
            if {[llength $plddr_ips]} {
                # Select the PL DDR controller actually reachable from this VCU
                # instance (via its master address map) instead of blindly taking the
                # first one. Fall back to the first controller (with a warning) only
                # when connectivity cannot be determined.
                set plddr_ip ""
                set vcu_plddr_matches {}
                if {![catch {set vcu_segs [hsi::get_mem_ranges -of_objects $vcu_ip]} msg]} {
                    foreach seg $vcu_segs {
                        set seg_inst [hsi get_property INSTANCE $seg]
                        if {[lsearch -exact $plddr_ips $seg_inst] >= 0 &&
                            [lsearch -exact $vcu_plddr_matches $seg_inst] < 0} {
                            lappend vcu_plddr_matches $seg_inst
                        }
                    }
                }
                if {[llength $vcu_plddr_matches] >= 1} {
                    set plddr_ip [lindex $vcu_plddr_matches 0]
                    if {[llength $vcu_plddr_matches] > 1} {
                        dtg_warning "axi_vcu: $drv_handle can reach multiple vcu_ddr4_controller instances ($vcu_plddr_matches); using $plddr_ip for the decoder carveout"
                    }
                }
                if {[string_is_empty $plddr_ip]} {
                    if {[llength $plddr_ips] > 1} {
                        dtg_warning "axi_vcu: unable to determine which vcu_ddr4_controller is connected to $drv_handle; defaulting to [lindex $plddr_ips 0]"
                    }
                    set plddr_ip [lindex $plddr_ips 0]
                }

                # Determine the PL DDR base/high address range mapped to a processor.
                # The bank must be matched by INSTANCE (its memory-range NAME differs
                # from the cell name, so a positional/name filter would never match).
                set plddr_base ""
                set plddr_high ""
                foreach procc [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}] {
                    foreach bank [hsi::get_mem_ranges -of_objects $procc -filter "INSTANCE==$plddr_ip"] {
                        set b [hsi get_property BASE_VALUE $bank]
                        set h [hsi get_property HIGH_VALUE $bank]
                        if {![string_is_empty $b] && ![string_is_empty $h]} {
                            set plddr_base $b
                            set plddr_high $h
                            break
                        }
                    }
                    if {![string_is_empty $plddr_base]} {
                        break
                    }
                }
                # Fallback: if the bank is not mapped to a processor, use the IP
                # base/high addresses. Both ends of the range are required so the
                # carveout size can be validated against the actual PL DDR size.
                if {[string_is_empty $plddr_base]} {
                    set plddr_base [get_baseaddr $plddr_ip]
                    set plddr_high [get_highaddr $plddr_ip]
                }

                # Only proceed when the complete PL DDR range is known. Without both
                # ends we cannot bound the carveout, so skip generation rather than
                # emit a potentially out-of-range reservation or a dangling reference.
                if {[string_is_empty $plddr_base] || [string_is_empty $plddr_high]} {
                    dtg_warning "axi_vcu: could not determine the PL DDR address range for $plddr_ip; skipping reserved-memory carveout and memory-region for $drv_handle"
                } else {
                    # reserved-memory always lives under the system-top root
                    set resv_dts "system-top.dts"
                    # Normalise to lowercase, 0x-prefixed hex so expr treats the
                    # values as hexadecimal (a bare value would be read as decimal).
                    set plddr_base [string tolower $plddr_base]
                    set plddr_high [string tolower $plddr_high]
                    if {![string match "0x*" $plddr_base]} {
                        set plddr_base "0x$plddr_base"
                    }
                    if {![string match "0x*" $plddr_high]} {
                        set plddr_high "0x$plddr_high"
                    }
                    set addr_hi [format 0x%x [expr {$plddr_base >> 32}]]
                    set addr_lo [format 0x%x [expr {$plddr_base & 0xffffffff}]]
                    # Default VCU decoder DMA pool size (from the validated reference
                    # design). It is capped below to the actual PL DDR bank size so we
                    # never reserve a region that extends beyond the available DDR.
                    set pref_size 0x6a400000
                    set avail [expr {$plddr_high - $plddr_base + 1}]
                    if {$avail <= 0} {
                        dtg_warning "axi_vcu: invalid PL DDR range for $plddr_ip (high <= base); skipping reserved-memory carveout"
                        set size 0
                    } elseif {$pref_size > $avail} {
                        dtg_warning "axi_vcu: preferred VCU decoder carveout ([format 0x%x $pref_size]) exceeds PL DDR size ([format 0x%x $avail]); clamping to PL DDR size"
                        set size $avail
                    } else {
                        set size $pref_size
                    }
                    if {$size > 0} {
                        set size_hi [format 0x%x [expr {$size >> 32}]]
                        set size_lo [format 0x%x [expr {$size & 0xffffffff}]]
                        regsub {^0x} $plddr_base "" unit_addr

                        # Idempotent creation driven entirely by the current tree (no
                        # persistent global state, which would go stale across tree
                        # regeneration or a second hardware design in the same Tcl
                        # process). Reuse the reserved-memory container if present.
                        set resv_node ""
                        foreach child [systemdt children root] {
                            if {[string match -nocase $child "reserved-memory"]} {
                                set resv_node $child
                                break
                            }
                        }
                        if {[string_is_empty $resv_node]} {
                            set resv_node [create_node -n "reserved-memory" -d $resv_dts]
                            add_prop "$resv_node" "#address-cells" 2 int $resv_dts
                            add_prop "$resv_node" "#size-cells" 2 int $resv_dts
                            add_prop "$resv_node" "ranges" "" boolean $resv_dts
                        }

                        # Dedupe carveouts directly from the tree by matching the PL
                        # DDR base (unit address). Reuse the existing label if the
                        # region already exists; otherwise mint a unique label. The
                        # first VCU carveout keeps the well-known "plmem_vcu_dec".
                        set plmem_label ""
                        set vcu_carveout_count 0
                        foreach child [systemdt children $resv_node] {
                            if {[regexp {vcu_dma_mem_region@} $child]} {
                                incr vcu_carveout_count
                                if {[string match "*@$unit_addr" $child]} {
                                    regexp {^(\S+):} $child -> plmem_label
                                }
                            }
                        }
                        if {[string_is_empty $plmem_label]} {
                            if {$vcu_carveout_count == 0} {
                                set plmem_label "plmem_vcu_dec"
                            } else {
                                set plmem_label "plmem_vcu_dec_${vcu_carveout_count}"
                            }
                            set plmem_node [create_node -l $plmem_label -n "vcu_dma_mem_region" -u $unit_addr -p $resv_node -d $resv_dts]
                            add_prop "$plmem_node" "label" $plmem_label string $resv_dts
                            add_prop "$plmem_node" "compatible" "shared-dma-pool" string $resv_dts
                            add_prop "$plmem_node" "no-map" "" boolean $resv_dts
                            add_prop "$plmem_node" "reg" [list $addr_hi $addr_lo $size_hi $size_lo] hexlist $resv_dts
                        }
                        add_prop "${decoder_node}" "memory-region" $plmem_label reference $dts_file
                    }
                }
            }
        }
        set clknames "pll_ref aclk vcu_core_enc vcu_mcu_enc vcu_core_dec vcu_mcu_dec"
        overwrite_clknames $clknames $drv_handle
        set ip [hsi::get_cells -hier $drv_handle]
        set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] "vcu_resetn"]]
        foreach pin $pins {
                set sink_periph [hsi::get_cells -of_objects $pin]
                if {[llength $sink_periph]} {
                        set sink_ip [hsi get_property IP_NAME $sink_periph]
                        if {$sink_ip in {"xlslice" "ilslice"}} {
                                set gpio [hsi get_property CONFIG.DIN_FROM $sink_periph]
                                set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $sink_periph "Din"]]]
                                foreach pin $pins {
                                        set periph [hsi::get_cells -of_objects $pin]
                                        if {[llength $periph]} {
                                                set ip [hsi get_property IP_NAME $periph]
                                                set proc_type [get_hw_family]
                                                if {[string match -nocase $proc_type "versal"] } {
                                                        if {$ip in { "versal_cips" "ps_wizard" }} {
                                                                # As in versal there is only bank0 for MIOs
                                                                set gpio [expr $gpio + 26]
                                                                add_prop $node "reset-gpios" "gpio0 $gpio 0" reference $dts_file
                                                                break
                                                        }
                                                }
                                                if {[is_zynqmp_platform $proc_type]} {
                                                        if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
                                                                set gpio [expr $gpio + 78]
                                                                add_prop $node "reset-gpios" "gpio $gpio 0" reference $dts_file
                                                                break
                                                        }
                                                }
                                                if {[string match -nocase $ip "axi_gpio"]} {
                                                        add_prop "$node" "reset-gpios" "$periph $gpio 0 1" reference $dts_file
                                                }
                                        } else {
                                                dtg_warning "periph for the pin:$pin is NULL $periph...check the design"
                                        }
                                }
                        }
                } else {
                        dtg_warning "peripheral for the pin:$pin is NULL $sink_periph...check the design"
                }
        }
    }

    proc axi_vcu_get_ipdetails {drv_handle arg} {
        set slave [hsi::get_cells -hier ${drv_handle}]
        set vlnv [split [hsi get_property VLNV $slave] ":"]
        set ver [lindex $vlnv 3]
        set name [lindex $vlnv 2]
        set ver [lindex $vlnv 3]
        set comp_prop "xlnx,${name}-${ver}"
        regsub -all {_} $comp_prop {-} comp_prop
        if {[string match -nocase $arg "ver"]} {
        return $ver
        } else {
        return $comp_prop
        }
    }


