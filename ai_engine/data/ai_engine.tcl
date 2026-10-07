#
# (C) Copyright 2018-2022 Xilinx, Inc.
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
    
    variable aie_array_cols_start
    variable aie_array_cols_num

    proc ai_engine_generate_aie_array_device_info {node drv_handle bus_node} {
        set aie_array_id 0
        set compatible [get_comp_str $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,ai-engine-v2.0\""

        #set default values
        set hw_gen "AIE"
        set aie_rows_start 1
        set aie_rows_num 8
        set mem_rows_start 0
        set mem_rows_num 0
        set shim_rows_start 0
        set shim_rows_num 1
        set ::aie_array_cols_start 0
        set ::aie_array_cols_num 50

        # override the above default values if AIE primitives are available in
        # xsa
        set CommandExists [ namespace which hsi::get_hw_primitives]
        if {$CommandExists != ""} {
                set aie_prop [hsi::get_hw_primitives aie]
                if {$aie_prop != ""} {
                        puts "INFO: Reading AIE hardware properties from XSA."

                        set hw_gen [hsi get_property HWGEN [hsi::get_hw_primitives aie]]
                        set aie_rows [hsi get_property AIETILEROWS [hsi::get_hw_primitives aie]]
                        set mem_rows [hsi get_property MEMTILEROW [hsi::get_hw_primitives aie]]
                        set shim_rows [hsi get_property SHIMROW [hsi::get_hw_primitives aie]]
                        set ::aie_array_cols_num [hsi get_property AIEARRAYCOLUMNS [hsi::get_hw_primitives aie]]

                        set aie_rows_start [lindex [split $aie_rows ":"] 0]
                        set aie_rows_num [lindex [split $aie_rows ":"] 1]
                        set mem_rows_start [lindex [split $mem_rows ":"] 0]
                        if {$mem_rows_start==-1} {
                                set mem_rows_start 0
                        }
                        set mem_rows_num [lindex [split $mem_rows ":"] 1]
                        set shim_rows_start [lindex [split $shim_rows ":"] 0]
                        set shim_rows_num [lindex [split $shim_rows ":"] 1]

                } else {
                        dtg_warning "$drv_handle: AIE hardware properties are not available in XSA, using defaults."
                }

        } else {
                dtg_warning "$drv_handle: AIE hardware properties are not available in XSA, using defaults."
        }

        if {$hw_gen=="AIE"} {
                append aiegen "/bits/ 8 <0x1>"
        } elseif {$hw_gen=="AIEML"} {
                append aiegen "/bits/ 8 <0x2>"
        } elseif {$hw_gen=="AIE2PS"} {
	        append aiegen "/bits/ 8 <0x5>"
        }

        add_prop "${node}" "xlnx,aie-gen" $aiegen noformating "pl.dtsi"
        append shimrows "/bits/ 8 <${shim_rows_start} ${shim_rows_num}>"
        add_prop "${node}" "xlnx,shim-rows" $shimrows noformating "pl.dtsi"
        append corerows "/bits/ 8 <${aie_rows_start} ${aie_rows_num}>"
        add_prop "${node}" "xlnx,core-rows" $corerows noformating "pl.dtsi"
        append memrows "/bits/ 8 <$mem_rows_start $mem_rows_num>"
        add_prop "${node}" "xlnx,mem-rows" $memrows noformating "pl.dtsi"

        if {$hw_gen=="AIE2PS"} {
                set reset_ref "scmi_reset 0xc10405e"
        } else {
                set reset_ref "versal_reset 0xc10405e"
        }
        add_prop "${node}" "resets" $reset_ref reference "pl.dtsi"
        add_prop "${node}" "#address-cells" 2 hexlist "pl.dtsi"
        add_prop "${node}" "#size-cells" 2 hexlist "pl.dtsi"
        add_prop "${node}" "ranges" 0 boolean "pl.dtsi"

        set ai_clk_node [create_node -n "aie_core_ref_clk_0" -l "aie_core_ref_clk_0" -p ${bus_node} -d "pl.dtsi"]
        set clk_freq [hsi get_property CONFIG.AIE_CORE_REF_CTRL_FREQMHZ [hsi get_cells -hier $drv_handle]]
        set clk_freq [expr ${clk_freq} * 1000000]
        add_prop "${ai_clk_node}" "compatible" "fixed-clock" stringlist "pl.dtsi"
        add_prop "${ai_clk_node}" "#clock-cells" 0 int "pl.dtsi"
        add_prop "${ai_clk_node}" "clock-frequency" $clk_freq int "pl.dtsi"
        set clocks "aie_core_ref_clk_0"
        set_drv_prop_if_empty $drv_handle clocks "$clocks" $node reference
        set_drv_prop_if_empty $drv_handle "clock-names" "aclk0" $node string

        return ${node}
    }


    # Read IP metadata directly so preflight does not populate design caches.
    # Both spellings must agree; an absent value is distinct from column zero.
    proc ai_engine_column_property {cell property} {
        set result ""
        foreach name [list CONFIG.C_$property CONFIG.$property] {
                if {[catch {set value [hsi::get_property $name $cell]}] || $value eq ""} {
                        continue
                }
                set value [parse_dt_integer [string trim $value] "$cell $name"]
                if {$result ne "" && $result != $value} {
                        error "ERROR: $cell has conflicting CONFIG.C_$property and CONFIG.$property values."
                }
                set result $value
        }
        return $result
    }

    proc ai_engine_device_label {node drv_handle start_column} {
        if {![info exists ::aie_device_label]} {
                error "ERROR: $drv_handle has no validated column 0 ai_engine device owner."
        }
        return $::aie_device_label
    }

    # Number of columns of the whole AI engine array, i.e. device wide.
    proc ai_engine_get_array_num_cols {drv_handle} {
        set array_num_cols 50
        set CommandExists [ namespace which hsi::get_hw_primitives]
        if {$CommandExists != ""} {
                set aie_prop [hsi::get_hw_primitives aie]
                if {$aie_prop != ""} {
                        set array_num_cols [hsi get_property AIEARRAYCOLUMNS [hsi::get_hw_primitives aie]]
                }
        }
        return $array_num_cols
    }

    # Collapse the per-column reg windows of an aperture into a single window.
    #
    # The driver ioremaps one span running from the first window to the last,
    # so the split windows carry nothing extra. Its contiguity check compares
    # each window's low address cell against a running total of sizes seeded
    # from zero, which only holds for an aperture based at offset 0; a merged
    # window skips that check and keeps non-zero start columns probeable.
    #
    # Returns the input untouched when the windows are not describing one
    # contiguous span, so an unexpected layout is emitted rather than fused.
    proc ai_engine_merge_reg_windows {reg} {
        if {[llength $reg] < 8 || [llength $reg] % 4 != 0} {
                return $reg
        }
        if {[catch {
                set base [expr {([lindex $reg 0] << 32) | [lindex $reg 1]}]
                set next $base
                set total 0
                foreach {addr_hi addr_lo size_hi size_lo} $reg {
                        set addr [expr {($addr_hi << 32) | $addr_lo}]
                        set size [expr {($size_hi << 32) | $size_lo}]
                        if {$addr != $next} {
                                error "non-contiguous"
                        }
                        set total [expr {$total + $size}]
                        set next [expr {$addr + $size}]
                }
        }]} {
                return $reg
        }
        return [list [format 0x%08x [expr {$base >> 32}]] \
                     [format 0x%08x [expr {$base & 0xffffffff}]] \
                     [format 0x%x [expr {$total >> 32}]] \
                     [format 0x%x [expr {$total & 0xffffffff}]]]
    }

    # Reconfigurable partition this XSA was exported for, empty when the design
    # is not a partition export.
    proc ai_engine_get_rp_inst {} {
        if {[catch {set rp_inst [hsi::get_property RP_INST_NAME \
                [hsi::current_hw_design]]}]} {
                return ""
        }
        return $rp_inst
    }

    # AI engine instances owned by $rp_inst, matched on the hierarchy prefix
    # since partition rp0 owns rp0_rp0_aie. Matching "<rp>_" rather than "<rp>"
    # keeps similarly named partitions such as rp1 and rp10 apart.
    #
    # Comes back empty for designs that do not name their instances after a
    # partition, which is how flat non-DFX designs opt out of the filtering.
    proc ai_engine_cells_of_rp {rp_inst} {
        set owned {}
        if {$rp_inst eq ""} {
                return $owned
        }
        if {[catch {set cells [hsi::get_cells -hier -filter {IP_NAME==ai_engine}]}]} {
                return $owned
        }
        foreach cell $cells {
                if {[string match "${rp_inst}_*" $cell]} {
                        lappend owned $cell
                }
        }
        return $owned
    }

    proc ai_engine_get_param {key default} {
        set aie_params [get_dt_param -aie_params]
        if {[dict exists $aie_params $key]} {
                return [dict get $aie_params $key]
        }
        return $default
    }

    # Remove all cache aliases to the wrapper, and suppress later address maps.
    proc ai_engine_drop_node {cell node} {
        global node_dict cur_hw_design
        if {![info exists ::rp_excluded_cells]} { set ::rp_excluded_cells {} }
        if {[lsearch -exact $::rp_excluded_cells $cell] < 0} {
                lappend ::rp_excluded_cells $cell
        }
        if {[dict exists $node_dict $cur_hw_design]} {
                dict for {key value} [dict get $node_dict $cur_hw_design] {
                        if {$value eq $node} {
                                dict set node_dict $cur_hw_design $key 0
                        }
                }
        }
        pldt delete $node
    }

    proc ai_engine_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(CUSTOM_SDT_REPO)

        set hw_gen "AIE"
        set CommandExists [ namespace which hsi::get_hw_primitives]
        if {$CommandExists != ""} {
                set aie_prop [hsi::get_hw_primitives aie]
                if {$aie_prop != ""} {
                        set hw_gen [hsi get_property HWGEN [hsi::get_hw_primitives aie]]
                }
        }

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        set bus_node "amba_pl: amba_pl"

        # There is only ever one AI engine device, but it can own several
        # apertures. In a DFX design every RP carries its own ai_engine IP, so
        # only the instance whose aperture starts at column 0 emits the device
        # node. Any other instance emits its aperture alone, to be merged under
        # the device node contributed by the column 0 instance.
        if {![dict exists $::aie_inventory $::aie_generation_context $drv_handle]} {
                error "ERROR: $drv_handle was not present in the validated AI engine inventory."
        }
        set metadata [dict get $::aie_inventory $::aie_generation_context $drv_handle]
        set start_column [dict get $metadata start]
        set aperture_num_cols [dict get $metadata width]
        set split_aperture [dict get $metadata split]
        if {$start_column == 0} {
                ai_engine_generate_aie_array_device_info ${node} ${drv_handle} ${bus_node}
        }
        # Aperture values are local, independent of any earlier generation pass.
        if {!$split_aperture} {
                set aperture_num_cols $::aie_array_cols_num
        }

        set reg [string trim [pldt get $node "reg"] \<\>]
        if {$split_aperture} {
                set reg [ai_engine_merge_reg_windows $reg]
        }

        set ip [hsi get_cells -hier $drv_handle]
        set unit_addr [get_baseaddr ${ip} no_prefix]

        if {$split_aperture} {
                set aperture_dts "aie_aperture.dtsi"
                global is_rm_design
                # Target node names stay unique per column because struct::tree
                # moves a node when an existing name is re-inserted elsewhere.
                # write_rm_dt resolves the emitted reference through
                # ::aie_aperture_targets so it follows the XSA cell name.
                set aie_label [ai_engine_device_label $node $drv_handle $start_column]
                if {[info exists is_rm_design] && $is_rm_design} {
                        set aperture_target [create_node -n "aie_ap_tgt_${start_column}" -p root -d $aperture_dts]
                } else {
                        set ap_grp [create_node -n "aie_ap_grp_${start_column}" -p root -d $aperture_dts]
                        set aperture_target [create_node -n "aie_ap_tgt_${start_column}" -p ${ap_grp} -d $aperture_dts]
                }
                if {![info exists ::aie_aperture_targets]} {
                        set ::aie_aperture_targets [dict create]
                }
                dict set ::aie_aperture_targets $aperture_target $aie_label
                set aperture_node [create_node -n "aie_aperture" -u "${unit_addr}" -l "aie_aperture_${start_column}" -p ${aperture_target} -d $aperture_dts]
        } else {
                set aperture_dts "pl.dtsi"
                set aperture_id 0
                set aperture_node [create_node -n "aie_aperture" -u "${unit_addr}" -l "aie_aperture_${aperture_id}" -p ${node} -d $aperture_dts]
        }
        add_prop "${aperture_node}" "reg" $reg hexlist $aperture_dts

        set name [hsi get_property NAME [hsi get_current_part $drv_handle]]
        set part_num [string range $name 0 7]
        set part_num_vc2802 [string range $name 0 4]

        if {$part_num == "xcvp2502"} {
                #s100
                add_prop "${aperture_node}" "xlnx,device-name" "100" int $aperture_dts
                set aperture_nodeid 0x18801000
        } elseif {$part_num == "xcvp2802"} {
                #s200
                add_prop "${aperture_node}" "xlnx,device-name" "200" int $aperture_dts
                set aperture_nodeid 0x18803000
        } elseif {$part_num_vc2802 == "xcvc2802"} {
                #v70
                add_prop "${aperture_node}" "xlnx,device-name" "0" int $aperture_dts
                set aperture_nodeid 0x18800000
        } else {
                #NON SSIT devices
                set intr_names "interrupt1"
                lappend intr_names "interrupt2"
                lappend intr_names "interrupt3"
                switch $hw_gen {
                        "AIE2PS" {
                                set intr_num "0x0 0xce 0x4>, <0x0 0xcf 0x4>, <0x0 0xd0 0x4"
                        }
                        default {
                                set intr_num "0x0 0x94 0x4>, <0x0 0x95 0x4>, <0x0 0x96 0x4"
                        }
                }
                add_prop "${aperture_node}" "interrupt-names" $intr_names stringlist $aperture_dts
                add_prop "${aperture_node}" "interrupts" $intr_num hexlist $aperture_dts
                add_prop "${aperture_node}" "interrupt-parent" imux reference $aperture_dts
                add_prop "${aperture_node}" "xlnx,device-name" "0" int $aperture_dts
                set aperture_nodeid 0x18800000
        }

        add_prop "${aperture_node}" "#address-cells" "2" hexlist $aperture_dts
        add_prop "${aperture_node}" "#size-cells" "2" hexlist $aperture_dts

        add_prop "${aperture_node}" "xlnx,columns" "$start_column $aperture_num_cols" intlist $aperture_dts

        set aperture_nodeid [ai_engine_get_param "node-id:$start_column" \
                [ai_engine_get_param "node-id" $aperture_nodeid]]
        add_prop "${aperture_node}" "xlnx,node-id" "${aperture_nodeid}" hexlist $aperture_dts

        # The ai_engine wrapper of a non-zero start column instance lives only
        # in the partial overlay; drop it from the main partition tree.
        if {$start_column != 0} {
                ai_engine_drop_node $drv_handle $node
        }
    }

    # Shared by the metadata scan and the generation pass, before any nodes
    # are created. Missing addresses and RP ownership have identical semantics.
    proc ai_engine_cell_is_selected {cell is_rm rp excluded owned} {
        if {[lsearch -exact $excluded $cell] >= 0} { return 0 }
        if {[llength $owned] && [lsearch -exact $owned $cell] < 0} { return 0 }
        if {$is_rm} {
                set owner [get_rprm_for_drv $cell]
                if {![llength $owner] || ![string equal -nocase [lindex $owner 0] $rp]} {
                        return 0
                }
        }
        set address [get_ai_engine_baseaddr $cell]
        return [expr {$address ne "" && $address ne "-1"}]
    }

    proc ai_engine_preflight_cells {is_rm has_rms rp} {
        set cells [hsi::get_cells -hier -filter {IP_NAME==ai_engine}]
        set excluded {}
        if {!$is_rm && $has_rms} {
                foreach region [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER] {
                        hsi::current_hw_instance $region
                        lappend excluded {*}[hsi::get_cells]
                        hsi::current_hw_instance
                }
        }
        set owned [ai_engine_cells_of_rp $rp]
        set selected {}
        foreach cell $cells {
                if {[ai_engine_cell_is_selected $cell $is_rm $rp $excluded $owned]} {
                        lappend selected $cell
                }
        }
        return $selected
    }

    proc ai_engine_filter_peripherals {peripherals is_rm has_rms rp} {
        global baseaddr_dict cur_hw_design
        set all_aie [hsi::get_cells -hier -filter {IP_NAME==ai_engine}]
        set selected [ai_engine_preflight_cells $is_rm $has_rms $rp]
        set result {}
        foreach cell $peripherals {
                # Alternative RMs can reuse design and cell names. Do not let
                # an earlier pass's cached address override fresh selection.
                if {[lsearch -exact $all_aie $cell] >= 0 && [info exists baseaddr_dict] &&
                        [dict exists $baseaddr_dict $cur_hw_design $cell]} {
                        dict unset baseaddr_dict $cur_hw_design $cell
                }
                if {[lsearch -exact $all_aie $cell] >= 0 && [lsearch -exact $selected $cell] < 0} {
                        if {[lsearch -exact $::rp_excluded_cells $cell] < 0} {
                                lappend ::rp_excluded_cells $cell
                        }
                } else {
                        lappend result $cell
                }
        }
        return $result
    }

    proc ai_engine_collect_metadata {cells} {
        set records [dict create]
        foreach cell $cells {
                # HSI cell objects stringify as "null" after their design closes.
                # Store a plain string, not the object, as the persistent key.
                set name [string range "${cell} " 0 end-1]
                dict set records $name [dict create \
                        start [ai_engine_column_property $cell START_COLUMN] \
                        width [ai_engine_column_property $cell NUM_COLUMN] \
                        array [parse_dt_integer [ai_engine_get_array_num_cols $cell] "AIE array size"]]
        }
        return $records
    }

    # Alternative RMs of one RP describe the same logical apertures. Compare
    # their layouts, then check overlap only between simultaneously active RPs
    # and static apertures. Keep each context's records for later emission.
    proc ai_engine_validate_inventory {inventory context_rps} {
        unset -nocomplain ::aie_device_label
        set groups [dict create]
        set split 0
        dict for {context cells} $inventory {
                set rp [dict get $context_rps $context]
                set group [list rp [string tolower $rp]]
                if {$rp eq ""} { set group [list static $context] }
                dict lappend groups $group $context
                if {$rp ne "" && [dict size $cells]} { set split 1 }
                dict for {cell record} $cells {
                        set start [dict get $record start]
                        if {$start ne "" && $start != 0} { set split 1 }
                }
        }
        set count 0
        dict for {group contexts} $groups {
                incr count [dict size [dict get $inventory [lindex $contexts 0]]]
        }
        if {$count > 1} { set split 1 }
        set columns [dict create]
        set intervals {}
        set owner_labels {}
        set array_size ""
        dict for {group contexts} $groups {
                set expected ""
                set first_context [lindex $contexts 0]
                foreach context $contexts {
                        set layout {}
                        set local_columns [dict create]
                        dict for {cell record} [dict get $inventory $context] {
                                set start [dict get $record start]
                                set width [dict get $record width]
                                set array [dict get $record array]
                                set where "$cell in $context"
                                if {$start eq ""} {
                                        if {$split} { error "ERROR: $where requires an explicit start column in split mode." }
                                        set start 0
                                }
                                if {$array <= 0 || $start >= $array} {
                                        error "ERROR: $where start column $start is outside the $array-column array."
                                }
                                if {$array_size ne "" && $array != $array_size} {
                                        error "ERROR: $where reports an inconsistent AI engine array size."
                                }
                                set array_size $array
                                if {!$split} { set width $array }
                                if {$width eq "" || $width <= 0 || $start + $width > $array} {
                                        error "ERROR: $where requires a valid explicit aperture width within the array (CONFIG.C_NUM_COLUMN/CONFIG.NUM_COLUMN)."
                                }
                                if {[dict exists $local_columns $start]} {
                                        error "ERROR: Duplicate AI engine start column $start in $context."
                                }
                                dict set local_columns $start $where
                                lappend layout [list $start $width $array]
                                if {$start == 0} { lappend owner_labels $cell }
                                dict set record start $start
                                dict set record width $width
                                dict set record split $split
                                dict set inventory $context $cell $record
                        }
                        set layout [lsort -integer -index 0 $layout]
                        if {$context ne $first_context} {
                                if {$layout ne $expected} {
                                        error "ERROR: Alternative RMs for RP '[dict get $context_rps $context]' have inconsistent AI engine apertures: $first_context and $context."
                                }
                                continue
                        }
                        set expected $layout
                        foreach aperture $layout {
                                lassign $aperture start width array
                                set where [dict get $local_columns $start]
                                if {[dict exists $columns $start]} {
                                        error "ERROR: Duplicate AI engine start column $start: [dict get $columns $start] and $where."
                                }
                                dict set columns $start $where
                                lappend intervals [list $start [expr {$start + $width}] $where]
                        }
                }
        }
        set previous_end 0
        set previous ""
        foreach interval [lsort -integer -index 0 $intervals] {
                lassign $interval start end where
                if {$start < $previous_end} {
                        error "ERROR: Overlapping AI engine apertures: $previous and $where."
                }
                set previous_end $end
                set previous $where
        }
        if {[dict size $columns] && ![llength $owner_labels]} {
                error "ERROR: No emitted column 0 ai_engine instance is available to own the device node. Supply the column 0 partition in the same run."
        }
        if {[llength $owner_labels]} {
                # Deterministic across RM order. Other alternatives expose this
                # label as an alias while retaining their original cell labels.
                set ::aie_device_label [lindex [lsort -unique $owner_labels] 0]
        }
        return $inventory
    }

    # mktemp creates a fresh directory atomically with mode 0700. Extract below
    # the output directory, but remove the workspace on success and failure.
    proc ai_engine_create_workspace {output_dir} {
        file mkdir $output_dir
        return [exec mktemp -d -- [file join $output_dir .sdt-aie-XXXXXXXXXX]]
    }

    proc ai_engine_preflight {static_xsa rm_xsas output_dir} {
        set ::aie_inventory [dict create]
        unset -nocomplain ::aie_device_label
        if {[info exists ::env(dt_domain)] && $::env(dt_domain) eq "pmc"} { return }
        set original_designs [hsi::get_hw_designs]
        set original ""
        if {[llength $original_designs]} { set original [hsi::current_hw_design] }
        set output_dir [file normalize $output_dir]
        set created_output [expr {![file exists $output_dir]}]
        set workspace ""
        set status [catch {
                set workspace [ai_engine_create_workspace $output_dir]
                set inventory [dict create]
                set context_rps [dict create]
                if {$original eq ""} {
                        hsi::open_hw_design [file normalize $static_xsa] -outdir [file join $workspace static]
                }
                set rp ""
                if {![llength $rm_xsas]} {
                        set rp [string range "[ai_engine_get_rp_inst] " 0 end-1]
                }
                set cells [ai_engine_preflight_cells 0 [expr {[llength $rm_xsas] > 0}] $rp]
                set context [file normalize $static_xsa]
                dict set context_rps $context [string range "${rp} " 0 end-1]
                dict set inventory $context [ai_engine_collect_metadata $cells]
                foreach design [hsi::get_hw_designs] {
                        if {[lsearch -exact $original_designs $design] < 0} { hsi::close_hw_design $design }
                }
                set index 0
                foreach rm_xsa $rm_xsas {
                        set rm_xsa [file normalize $rm_xsa]
                        set rm_dir [file join $workspace rm[incr index]]
                        file mkdir $rm_dir
                        hsi::open_hw_design $rm_xsa -outdir $rm_dir
                        set rp [string range "[ai_engine_get_rp_inst] " 0 end-1]
                        if {$rp eq ""} { error "ERROR: RM XSA '$rm_xsa' does not identify a reconfigurable partition." }
                        hsi::open_hw_design -static [file normalize $static_xsa] -cells $rp:$rm_xsa -outdir $rm_dir
                        set cells [ai_engine_preflight_cells 1 1 $rp]
                        if {[dict exists $inventory $rm_xsa]} {
                                error "ERROR: Duplicate RM XSA '$rm_xsa'."
                        }
                        dict set context_rps $rm_xsa $rp
                        dict set inventory $rm_xsa [ai_engine_collect_metadata $cells]
                        foreach design [hsi::get_hw_designs] {
                                if {[lsearch -exact $original_designs $design] < 0} { hsi::close_hw_design $design }
                        }
                }
                set ::aie_inventory [ai_engine_validate_inventory $inventory $context_rps]
        } result options]
        # Do not let one failed cleanup operation prevent the remaining ones.
        set cleanup_errors {}
        foreach design [hsi::get_hw_designs] {
                if {[lsearch -exact $original_designs $design] < 0} {
                        if {[catch {hsi::close_hw_design $design} cleanup_result cleanup_options]} { lappend cleanup_errors $cleanup_result }
                }
        }
        if {$original ne ""} {
                if {[catch {hsi::current_hw_design $original} cleanup_result cleanup_options]} { lappend cleanup_errors $cleanup_result }
        }
        if {$workspace ne ""} {
                if {[catch {file delete -force $workspace} cleanup_result cleanup_options]} { lappend cleanup_errors $cleanup_result }
        }
        # Non-recursive deletion preserves files created by another process.
        if {$created_output} { catch {file delete $output_dir} }
        if {$status} { return -options $options $result }
        if {[llength $cleanup_errors]} { error "ERROR: AI engine preflight cleanup failed: [join $cleanup_errors {; }]" }
    }
