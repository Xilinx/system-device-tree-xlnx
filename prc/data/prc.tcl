#
# (C) Copyright 2020-2021 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc prc_generate {drv_handle} {
        prc_generate_params $drv_handle
    }

    proc prc_generate_params {drv_handle} {
        global env 
            set path $env(CUSTOM_SDT_REPO)
        set node [get_node $drv_handle] 
        set dts_file [set_drv_def_dts $drv_handle]
        set drvname [get_drivers $drv_handle]
     
            #set api_file "$path/$drvname/data/api.tcl" 
            #if {[file exists $common_file]} { 
            #        source $api_file 
            #}
        rdi::source [file join $path "prc" "data" "api.tcl"]
	pldt append $node compatible "\ \, \"xlnx,dfx-controller\""

        set ip [hsi::get_cells -hier $drv_handle]
        set configuration [hsi get_property CONFIG.ALL_PARAMS $ip]

        # Use the PRC's API to get the number of VSMs that the user configured in this instance of the PRC
        set num_vs  [prc_v1_2::priv::get_num_vs configuration]
        set clearing_bitstream [prc_v1_2::priv::requires_clear_bitstream configuration]
        set cp_arbitration_protocol  [prc_v1_2::priv::get_cp_arbitration_protocol configuration]
        set has_axi_lite_if [prc_v1_2::priv::get_has_axi_lite_if configuration]
        set reset_active_level [prc_v1_2::priv::get_reset_active_level configuration]
        set cp_fifo_depth [prc_v1_2::priv::get_cp_fifo_depth configuration]
        set cp_fifo_type [prc_v1_2::priv::get_cp_fifo_type_as_int configuration]
        set cp_family [prc_v1_2::priv::get_cp_family_as_int configuration]
        set cdc_stages [prc_v1_2::priv::get_cdc_stages configuration]
        set cp_compression [prc_v1_2::priv::get_cp_compression configuration]
        set address_offsets [prc_v1_2::priv::calculate_address_offsets configuration]

        set C_REG_SELECT_MSB    [dict get $address_offsets C_REG_SELECT_MSB  ]
        set C_REG_SELECT_LSB    [dict get $address_offsets C_REG_SELECT_LSB  ]
        set C_TABLE_SELECT_MSB  [dict get $address_offsets C_TABLE_SELECT_MSB]
        set C_TABLE_SELECT_LSB  [dict get $address_offsets C_TABLE_SELECT_LSB]
        set C_VSM_SELECT_MSB    [dict get $address_offsets C_VSM_SELECT_MSB  ]
        set C_VSM_SELECT_LSB    [dict get $address_offsets C_VSM_SELECT_LSB  ]

        add_prop $node "num-vsms" $num_vs int $dts_file
        add_prop $node "clearing-bitstream" $clearing_bitstream int $dts_file
        add_prop $node "cp-arbitration-protocol" $cp_arbitration_protocol int $dts_file
        add_prop $node "has-axi-lite-if" $has_axi_lite_if int $dts_file
        add_prop $node "reset-active-level" $reset_active_level int $dts_file
        add_prop $node "cp-fifo-depth" $cp_fifo_depth int $dts_file
        add_prop $node "cp-fifo-type" $cp_fifo_type int $dts_file
        add_prop $node "cp-family" $cp_family int $dts_file
        add_prop $node "cdc-stages" $cdc_stages int $dts_file
        add_prop $node "cp-compression"  $cp_compression int $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set num_rms [prc_v1_2::priv::get_num_rms_in_vs configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $num_rms
                } else {
                        append prcinfo " " $num_rms
                }
        }
        add_prop $node "num-rms" $prcinfo intlist $dts_file

        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set num_rms_alloc [prc_v1_2::priv::get_vs_num_rms_allocated configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $num_rms_alloc
                } else {
                        append prcinfo " " $num_rms_alloc
                }
        }
        add_prop $node "num-rms-alloc" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set num_trger_alloc [prc_v1_2::priv::get_vs_num_triggers_allocated configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $num_trger_alloc
                } else {
                        append prcinfo " " $num_trger_alloc
                }
        }
        add_prop $node "num-trigger-alloc" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set strt_in_shtdwn [prc_v1_2::priv::get_vs_start_in_shutdown configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $strt_in_shtdwn
                } else {
                        append prcinfo " " $strt_in_shtdwn
                }
        }
        add_prop $node "start-in-shutdown" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set shtdwn_on_err [prc_v1_2::priv::get_vs_shutdown_on_error configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $shtdwn_on_err
                } else {
                        append prcinfo " " $shtdwn_on_err
                }
        }
        add_prop $node "shutdown-on-err" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set has_por_rm [prc_v1_2::priv::get_vs_has_por_rm configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $has_por_rm
                } else {
                        append prcinfo " " $has_por_rm
                }
        }
        add_prop $node "has-por-rm" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set por_rm [prc_v1_2::priv::get_vs_por_rm configuration $vs_name]
                set rm_id [prc_v1_2::priv::get_rm_id configuration $vs_name $por_rm]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $rm_id
                } else {
                        append prcinfo " " $rm_id
                }
        }
        add_prop $node "por-rm" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set has_axs_status [prc_v1_2::priv::get_vs_has_axis_status configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $has_axs_status
                } else {
                        append prcinfo " " $has_axs_status
                }
        }
        add_prop $node "has-axis-status" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set has_axs_control [prc_v1_2::priv::get_vs_has_axis_control configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $has_axs_control
                } else {
                        append prcinfo " " $has_axs_control
                }
        }
        add_prop $node "has-axis-control" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set skp_rm_strtup_aft_rst [prc_v1_2::priv::get_vs_skip_rm_startup_after_reset configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $skp_rm_strtup_aft_rst
                } else {
                        append prcinfo " " $skp_rm_strtup_aft_rst
                }
        }
        add_prop $node "skip-rm-startup-after-reset" $prcinfo intlist $dts_file
        set prcinfo ""
        for {set vs_id 0} {$vs_id < $num_vs} { incr vs_id} {
                set vs_name [prc_v1_2::priv::get_vs_name configuration $vs_id]
                set num_hw_trgers [prc_v1_2::priv::get_vs_num_hw_triggers configuration $vs_name]
                if {[string_is_empty $prcinfo]} {
                        set prcinfo $num_hw_trgers
                } else {
                        append prcinfo " " $num_hw_trgers
                }
        }
        add_prop $node "num-hw-triggers" $prcinfo intlist $dts_file
        add_prop $node "vsm-msb" $C_VSM_SELECT_MSB int $dts_file
        add_prop $node "vsm-lsb" $C_VSM_SELECT_LSB int $dts_file
        add_prop $node "bank-msb"  $C_TABLE_SELECT_MSB int $dts_file
        add_prop $node "bank-lsb" $C_TABLE_SELECT_LSB int $dts_file
        add_prop $node "reg-select-msb" $C_REG_SELECT_MSB int $dts_file
        add_prop $node "reg-select-lsb" $C_REG_SELECT_LSB int $dts_file
    }


