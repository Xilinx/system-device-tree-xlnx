    proc ddrpsv_generate {drv_handle} {
        global is_versal_net_platform
        set a72 0
        set dts_file "system-top.dts"

        # Get the periph_name from drv_handle (output is usually same as drv_handle)
        set periph_name [hsi::get_cells -hier ${drv_handle}]
        set vlnv [split [hsi get_property VLNV $periph_name] ":"]
        set name [lindex $vlnv 2]
        set ver [lindex $vlnv 3]

        # Property for compatibility string
        set comp_prop "xlnx,${name}-${ver}"
        regsub -all {_} $comp_prop {-} comp_prop

        # Defined at the top to avoid scope issue if no DDR region is mapped
        set reg_val ""
        set apu_reg_val ""

        # List that contains base_address of each DDR region (C0_DDR_LOW(0-3), C0_DDR_CH(1-3))
        global base_addr_list
        set base_addr_list {0 0 0 0 0 0 0 0}

        # List that contains high_address of each DDR region (C0_DDR_LOW(0-3), C0_DDR_CH(1-3))
        global high_addr_list
        set high_addr_list {0 0 0 0 0 0 0 0}

        # list all the processors available in the design
        set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
        foreach procc $proclist {
                # Variables to get the presence status of each DDR region
                # If the region is present status is set to 1
                set is_ddr_low_0 0
                set is_ddr_low_1 0
                set is_ddr_low_2 0
                set is_ddr_low_3 0
                set is_ddr_ch_1 0
                set is_ddr_ch_2 0
                set is_ddr_ch_3 0
                set is_ddr_ch_0 0
                
                # Get all the NOC memory instances mapped to the particular processor
                set mapped_periph_list [hsi::get_mem_ranges -of_objects $procc $periph_name]

                # If there is no instances mapped, then skip that processor
                if { $mapped_periph_list eq "" } {
                        continue
                }

                # Get the processor IP name (A72/R5/PMC/PSM)
                set proc_ip_name [hsi get_property IP_NAME $procc]

                # Get the interface block names
                # (e.g. C0_DDR_LOW0 C0_DDR_LOW0 C0_DDR_LOW0 C0_DDR_LOW1 C0_DDR_LOW1 C0_DDR_LOW1)
                # Blocks with same name say C0_DDR_LOW0 will be having a different master interface
                # FPD_CCI_NOC_0, FPD_CCI_NOC_1 are the examples of master interfaces
                set interface_block_names [hsi get_property ADDRESS_BLOCK ${mapped_periph_list}]

                # If the mappings have already been found for a72_0, then ignore the process for a72_1
                if {$a72 == 1 && ([string match -nocase ${proc_ip_name} "psv_cortexa72"] || [string match -nocase ${proc_ip_name} "psx_cortexa78"]) } {
                        continue
                }
                if {[string match -nocase ${proc_ip_name} "psv_cortexa72"] || [string match -nocase ${proc_ip_name} "psx_cortexa78"]} {
                       set a72 1
                }

                # Loop variable to go over all the interface blocks
                set i 0

                # TODO Check on interface block name: C0_DDR_CH0_LEGACY for KSB

                # Loop through all the interface blocks mapped to the processor
                foreach block_name $interface_block_names {
                        # ddr_region_id:
                        #        specifies index of base_addr_list/high_addr_list
                        #        for each DDR region.
                        # is_ddr_low<0-6>:
                        #        status of each DDR region, if it is present or not.
                        # ddrpsv_handle_address_details:
                        #       to update the base_addr_list and high_ddr_list if needed.
                        # i:
                        #       loop variable to traverse across the mapped DDR region.
                        #       This is needed as block_name dont have unique names.
                        if {[string match "C*_DDR_LOW0*" $block_name]} {
                                set ddr_region_id 0
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_low_0 $ddr_region_id
                                set is_ddr_low_0 1
                        } elseif {[string match "C*_DDR_LOW1*" $block_name]} {
                                set ddr_region_id 1
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_low_1 $ddr_region_id
                                set is_ddr_low_1 1
                        } elseif {[string match "C*_DDR_LOW2*" $block_name]} {
                                set ddr_region_id 2
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_low_2 $ddr_region_id
                                set is_ddr_low_2 1
                        } elseif {[string match "C*_DDR_LOW3*" $block_name] } {
                                set ddr_region_id 3
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_low_3 $ddr_region_id
                                set is_ddr_low_3 1
                        # For KSB interface_block_name is coming as C0_DDR_CH0_LEGACY
                        } elseif {[string match "C*_DDR_CH0*" $block_name]} {
                                set ddr_region_id 4
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_ch_0  $ddr_region_id
                                set is_ddr_ch_0 1
                        } elseif {[string match "C*_DDR_CH1*" $block_name]} {
                                set ddr_region_id 5
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_ch_1 $ddr_region_id
                                set is_ddr_ch_1 1
                        } elseif {[string match "C*_DDR_CH2*" $block_name]} {
                                set ddr_region_id 6
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_ch_2 $ddr_region_id
                                set is_ddr_ch_2 1
                        } elseif {[string match "C*_DDR_CH3*" $block_name]} {
                                set ddr_region_id 7
                                ddrpsv_handle_address_details $i $mapped_periph_list $is_ddr_ch_3  $ddr_region_id
                                set is_ddr_ch_3 1
                        }
                        incr i
                }
                set updat ""
                if {$is_ddr_low_0 == 1} {
                        set base_value_0 [lindex $base_addr_list 0]
                        set high_value_0 [lindex $high_addr_list 0]
                        set reg_val_0 [ddrpsv_generate_reg_property $base_value_0 $high_value_0]
                        set updat [lappend updat $reg_val_0]
                }
                if {$is_ddr_low_1 == 1} {
                        set base_value_1 [lindex $base_addr_list 1]
                        set high_value_1 [lindex $high_addr_list 1]
                        set reg_val_1 [ddrpsv_generate_reg_property $base_value_1 $high_value_1]
                        set updat [lappend updat $reg_val_1]
                }
                if {$is_ddr_low_2 == 1} {
                        set base_value_2 [lindex $base_addr_list 2]
                        set high_value_2 [lindex $high_addr_list 2]
                        set reg_val_2 [ddrpsv_generate_reg_property $base_value_2 $high_value_2]
                        set updat [lappend updat $reg_val_2]
                }
                if {$is_ddr_low_3 == 1} {
                        set base_value_3 [lindex $base_addr_list 3]
                        set high_value_3 [lindex $high_addr_list 3]
                        set reg_val_3 [ddrpsv_generate_reg_property $base_value_3 $high_value_3]
                        set updat [lappend updat $reg_val_3]
                }
                if {$is_ddr_ch_0 == 1} {
                        set base_value_4 [lindex $base_addr_list 4]
                        set high_value_4 [lindex $high_addr_list 4]
                        set reg_val_4 [ddrpsv_generate_reg_property $base_value_4 $high_value_4]
                        set updat [lappend updat $reg_val_4]
                }
                if {$is_ddr_ch_1 == 1} {
                        set base_value_5 [lindex $base_addr_list 5]
                        set high_value_5 [lindex $high_addr_list 5]
                        set reg_val_5 [ddrpsv_generate_reg_property $base_value_5 $high_value_5]
                        set updat [lappend updat $reg_val_5]
                }
                if {$is_ddr_ch_2 == 1} {
                        set base_value_6 [lindex $base_addr_list 6]
                        set high_value_6 [lindex $high_addr_list 6]
                        set reg_val_6 [ddrpsv_generate_reg_property $base_value_6 $high_value_6]
                        set updat [lappend updat $reg_val_6]
                }
                if {$is_ddr_ch_3 == 1} {
                        set base_value_7 [lindex $base_addr_list 7]
                        set high_value_7 [lindex $high_addr_list 7]
                        set reg_val_7 [ddrpsv_generate_reg_property $base_value_7 $high_value_7]
                        set updat [lappend updat $reg_val_7]
                }

                set len [llength $updat]
                set reg_val ""

                # TODO Check on the interleaves logic (Not present in esw or DTG repo)
                switch $len {
                        "1" {
                                set reg_val [lindex $updat 0]
                                ddrpsv_update_mc_ranges $drv_handle $reg_val
                        }
                        "2" {
                                set reg_val [lindex $updat 0]
                                append reg_val ">, <[lindex $updat 1]"
                                ddrpsv_update_mc_ranges $drv_handle $reg_val
                        }
                        "3" {
                                set reg_val [lindex $updat 0]
                                append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]"
                                ddrpsv_update_mc_ranges $drv_handle $reg_val
                        }
                        "4" {
                                set reg_val [lindex $updat 0]
                                append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]"
                                ddrpsv_update_mc_ranges $drv_handle $reg_val
                        }
                        "5" {
                                set reg_val [lindex $updat 0]
                                append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]"
                                ddrpsv_update_mc_ranges $drv_handle $reg_val
                        }
                        "6" {
                                set reg_val [lindex $updat 0]
                                append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]"
                                ddrpsv_update_mc_ranges $drv_handle $reg_val
                        }
                        "7" {
                                set reg_val [lindex $updat 0]
                                append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]"
                                ddrpsv_update_mc_ranges $drv_handle $reg_val
                        }
                        }

                        if {$len} {
                                if {[string match -nocase ${proc_ip_name} "psv_cortexr5"] || [string match -nocase ${proc_ip_name} "psx_cortexr52"]} {
                                        set r5_cores 2
                                        if { $is_versal_net_platform } {
                                                set r5_cores 4
                                        }
                                        set val [get_count ${proc_ip_name}]
                                        set map [get_mc_map $drv_handle]
                                        if {$val < $r5_cores || $map == 1} {
                                                set_memmap "${drv_handle}_memory" $procc $reg_val
                                        }
                                }
                                if {[string match -nocase ${proc_ip_name} "psv_cortexa72"] || [string match -nocase ${proc_ip_name} "psx_cortexa78"]} {
                                        set val [get_count ${proc_ip_name}]
                                        set map [get_mc_map $drv_handle]
                                        if {$val == 0 || $map == 1} {
                                                set_memmap "${drv_handle}_memory" a53 $reg_val
                                                set apu_reg_val $reg_val
                                        }
                                }
                                if {[string match -nocase ${proc_ip_name} "psv_pmc"] || [string match -nocase ${proc_ip_name} "psx_pmc"]} {
                                        set val [get_count ${proc_ip_name}]
                                        set map [get_mc_map $drv_handle]
                                        if {$val == 0 || $map == 1} {
                                                set_memmap "${drv_handle}_memory" pmc $reg_val
                                        }
                                }
                                if {[string match -nocase ${proc_ip_name} "psv_psm"] || [string match -nocase ${proc_ip_name} "psx_psm"]} {
                                        set val [get_count ${proc_ip_name}]
                                        set map [get_mc_map $drv_handle]
                                        if {$val == 0 || $map == 1} {
                                                set_memmap "${drv_handle}_memory" psm $reg_val
                                        }
                                }
                                if {[string match -nocase ${proc_ip_name} "microblaze"] } {
                                        set val [get_count "microblaze"]
                                        set map [get_mc_map $drv_handle]
                                        if {$val == 0 || $map == 1} {
                                                set_memmap "${drv_handle}_memory" $procc $reg_val
                                        }
                                }
                        }
        }

        # TODO: Figure out a way to get the system level axi_noc memory availability
        # For now, let's just show the APU memory map in the memory node.
        # This reg property is only symbolic to identify this node as a valid IP.
        # Actual memory info will be picked up from the cpu clusters address map.
        if {[llength $apu_reg_val]} {
                set higheraddr [expr [lindex $apu_reg_val 0] << 32]
                set loweraddr [lindex $apu_reg_val 1]
                set baseaddr [format 0x%x [expr {${higheraddr} + ${loweraddr}}]]
                regsub -all {^0x} $baseaddr {} baseaddr
                set memory_node [create_node -n memory -l "${drv_handle}_memory" -u $baseaddr -p root -d "system-top.dts"]
                if {[catch {set dev_type [hsi get_property CONFIG.device_type $drv_handle]} msg]} {
                        set dev_type memory
                }
                if {[string_is_empty $dev_type]} {set dev_type memory}
                add_prop "${memory_node}" "compatible" $comp_prop string $dts_file
                add_prop "${memory_node}" "device_type" $dev_type string $dts_file
                add_prop "${memory_node}" "reg" $apu_reg_val hexlist $dts_file
        }

    }

    proc ddrpsv_generate_reg_property {base high} {
        set size [format 0x%x [expr {${high} - ${base} + 1}]]

        set proctype [get_hw_family]
        if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_pmc"] || [string match -nocase $proctype "psv_cortexr5"]} {
                if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                        set temp $base
                        set temp [string trimleft [string trimleft $temp 0] x]
                        set len [string length $temp]
                        set rem [expr {${len} - 8}]
                        set high_base "0x[string range $temp $rem $len]"
                        set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                        set low_base [format 0x%08x $low_base]
                } else {
                        set high_base $base
                        set low_base 0x0
                }
                if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                        set temp $size
                        set temp [string trimleft [string trimleft $temp 0] x]
                        set len [string length $temp]
                        set rem [expr {${len} - 8}]
                        set high_size "0x[string range $temp $rem $len]"
                        set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
                        set low_size [format 0x%08x $low_size]
                } else {
                        set high_size $size
                        set low_size 0x0
                }
                set reg "$low_base $high_base $low_size $high_size"
        } else {
                set reg "0x0 $base 0x0 $size"
        }
        return $reg
    }

    proc ddrpsv_update_mc_ranges {drv_handle reg} {
        global is_versal_net_platform
        if { !$is_versal_net_platform } {
                set num_mc [hsi get_property CONFIG.NUM_MC [hsi::get_cells -hier $drv_handle]]
                set intrleave_size [hsi get_property CONFIG.MC_INTERLEAVE_SIZE [hsi::get_cells -hier $drv_handle]]
                if {$num_mc >= 1} {
                        if {[catch {set value [pcwdt get "&mc0" ranges]} msg]} {
                                set node [create_node -n "&mc0" -d "pcw.dtsi" -p root]
                                add_prop $node ranges $reg hexlist "pcw.dtsi" 1
                                add_prop $node "status" "okay" string "pcw.dtsi" 1
                                set mcnode [create_node -n "&ddrmc_xmpu_0" -d "pcw.dtsi" -p root]
                                add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
                        } else {
                                set reg_val $value
                                set reg_val [string trimleft $reg_val "<"]
                                set reg_val [string trimright $reg_val ">"]
                                append reg_val ">, <$reg"
                                pcwdt unset "&mc0" ranges
                                set reg_val [ddrpsv_remove_dup $reg_val]
                                add_prop "&mc0" ranges $reg_val hexlist "pcw.dtsi" 1
                                add_prop "&mc0" "status" "okay" string "pcw.dtsi" 1
                        }
                }

                if {$num_mc >= 2} {
                        if {[catch {set value [pcwdt get "&mc1" ranges]} msg]} {
                                set node [create_node -n "&mc1" -d "pcw.dtsi" -p root]          
                                add_prop $node ranges $reg hexlist "pcw.dtsi" 1
                                add_prop $node "status" "okay" string "pcw.dtsi" 1
                                set mcnode [create_node -n "&ddrmc_xmpu_1" -d "pcw.dtsi" -p root]               
                                add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
                        } else {
                                set reg_val $value
                                set reg_val [string trimleft $reg_val "<"]
                                set reg_val [string trimright $reg_val ">"]
                                append reg_val ">, <$reg"
                                pcwdt unset "&mc1" ranges
                                set reg_val [ddrpsv_remove_dup $reg_val]
                                add_prop "&mc1" ranges $reg_val hexlist "pcw.dtsi" 1                    
                                add_prop "&mc1" "status" "okay" string "pcw.dtsi" 1
                        }
                        add_prop "&mc0" interleave "$intrleave_size 0" hexlist "pcw.dtsi" 1
                        add_prop "&mc1" interleave "$intrleave_size 1" hexlist "pcw.dtsi" 1
                }
                
                if {$num_mc >= 4} {
                        if {[catch {set value [pcwdt get "&mc2" ranges]} msg]} {
                                set node [create_node -n "&mc2" -d "pcw.dtsi" -p root]
                                add_prop $node ranges $reg hexlist "pcw.dtsi" 1
                                add_prop $node "status" "okay" string "pcw.dtsi" 1
                                set mcnode [create_node -n "&ddrmc_xmpu_2" -d "pcw.dtsi" -p root]
                                add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
                        } else {
                                set reg_val $value
                                set reg_val [string trimleft $reg_val "<"]
                                set reg_val [string trimright $reg_val ">"]
                                append reg_val ">, <$reg"
                                pcwdt unset "&mc2" ranges
                                set reg_val [ddrpsv_remove_dup $reg_val]
                                add_prop "&mc2" ranges $reg_val hexlist "pcw.dtsi" 1               
                                add_prop "&mc2" "status" "okay" string "pcw.dtsi" 1
                        }
                        add_prop "&mc2" interleave "$intrleave_size 2" hexlist "pcw.dtsi" 1
                        if {[catch {set value [pcwdt get "&mc3" ranges]} msg]} {
                                set node [create_node -n "&mc3" -d "pcw.dtsi" -p root]
                                add_prop $node ranges $reg hexlist "pcw.dtsi" 1
                                set mcnode [create_node -n "&ddrmc_xmpu_3" -d "pcw.dtsi" -p root]
                                add_prop $mcnode "status" "okay" string "pcw.dtsi" 1
                        } else {
                                set reg_val $value
                                set reg_val [string trimleft $reg_val "<"]
                                set reg_val [string trimright $reg_val ">"]
                                append reg_val ">, <$reg"
                                pcwdt unset "&mc3" ranges
                                set reg_val [ddrpsv_remove_dup $reg_val]
                                add_prop "&mc3" ranges $reg_val hexlist "pcw.dtsi" 1             
                                add_prop "&mc3" "status" "okay" string "pcw.dtsi" 1
                        }

                        add_prop "&mc3" interleave "$intrleave_size 3" hexlist "pcw.dtsi" 1
                }
        }

    }

    proc ddrpsv_remove_dup {reg} {
        set list [ddrpsv_multisplit $reg ">, <"]
        set list [lsort -unique $list]
        set len [llength $list]
        if {$len == 1} {
                return $list
        }
        set first [lindex $list 0]
        set list [lreplace $list 0 0]
        foreach val $list {
                append first ">, <$val"
        }
        return $first
        
    }

    proc ddrpsv_multisplit "str splitStr {mc {\x00}}" {
        return [split [string map [list $splitStr $mc] $str] $mc]
    }                                                                                                                                                                           

    proc ddrpsv_get_base_addr {mapped_periph_list index} {
        # Get the Base address of the mapped DDR region
        return [hsi get_property BASE_VALUE [lindex ${mapped_periph_list} $index]]
    }

    proc ddrpsv_get_high_addr {mapped_periph_list index} {
        # Get the High address of the mapped DDR region
        return [hsi get_property HIGH_VALUE [lindex ${mapped_periph_list} $index]]
    }

    proc ddrpsv_handle_address_details { index mapped_periph_list is_ddr_region_accessed ddr_region_id } {
        #Variables to hold base address and high address of each DDR region
        global base_addr_list
        global high_addr_list

        # Get the base address of the passed DDR region i.e. mapped_periph_list[index]
        set temp [ddrpsv_get_base_addr $mapped_periph_list $index]

        # If the DDR region is accessed for the first time OR
        # If the base address found is less than the address present in the list for this DDR region,
        # replace the address in the list with the new address found.
        if { $is_ddr_region_accessed == 0 || [string compare $temp [lindex $base_addr_list $ddr_region_id]] < 0 } {
                lset base_addr_list $ddr_region_id $temp
        }

        # Get the High address of the passed DDR region i.e. mapped_periph_list[index]
        set temp [ddrpsv_get_high_addr $mapped_periph_list $index]

        # If the DDR region is accessed for the first time OR
        # If the high address found is greater than the address present in the list for this DDR region,
        # replace the address in the list with the new address found.
        if { $is_ddr_region_accessed == 0 || [string compare $temp [lindex $high_addr_list $ddr_region_id]] > 0} {
                lset high_addr_list $ddr_region_id $temp
        }
    }