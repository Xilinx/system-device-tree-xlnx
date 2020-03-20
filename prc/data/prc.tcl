#
# (C) Copyright 2020 Xilinx, Inc.
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

source api.tcl -notrace
proc generate {drv_handle} {
	foreach i [get_sw_cores device_tree] {
        	set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        	if {[file exists $common_tcl_file]} {
                	source $common_tcl_file
                	break
                }
        }

	prc_generate_params $drv_handle
}

proc prc_generate_params {drv_handle} {
	set ip [get_cells -hier $drv_handle]
	set configuration [common::get_property CONFIG.ALL_PARAMS $ip]

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

	set C_REG_SELECT_MSB	[dict get $address_offsets C_REG_SELECT_MSB  ]
	set C_REG_SELECT_LSB	[dict get $address_offsets C_REG_SELECT_LSB  ]
	set C_TABLE_SELECT_MSB	[dict get $address_offsets C_TABLE_SELECT_MSB]
	set C_TABLE_SELECT_LSB	[dict get $address_offsets C_TABLE_SELECT_LSB]
	set C_VSM_SELECT_MSB	[dict get $address_offsets C_VSM_SELECT_MSB  ]
	set C_VSM_SELECT_LSB	[dict get $address_offsets C_VSM_SELECT_LSB  ]

	hsi::utils::add_new_property $drv_handle "num-vsms" int $num_vs
	hsi::utils::add_new_property $drv_handle "clearing-bitstream" int $clearing_bitstream
	hsi::utils::add_new_property $drv_handle "cp-arbitration-protocol" int $cp_arbitration_protocol
	hsi::utils::add_new_property $drv_handle "has-axi-lite-if" int $has_axi_lite_if
	hsi::utils::add_new_property $drv_handle "reset-active-level" int $reset_active_level
	hsi::utils::add_new_property $drv_handle "cp-fifo-depth" int $cp_fifo_depth
	hsi::utils::add_new_property $drv_handle "cp-fifo-type" int $cp_fifo_type
	hsi::utils::add_new_property $drv_handle "cp-family" int $cp_family
	hsi::utils::add_new_property $drv_handle "cdc-stages" int $cdc_stages
	hsi::utils::add_new_property $drv_handle "cp-compression" int $cp_compression
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
	hsi::utils::add_new_property $drv_handle "num-rms" int $prcinfo

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
	hsi::utils::add_new_property $drv_handle "num-rms-alloc" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "num-trigger-alloc" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "start-in-shutdown" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "shutdown-on-err" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "has-por-rm" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "por-rm" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "has-axis-status" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "has-axis-control" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "skip-rm-startup-after-reset" int $prcinfo
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
	hsi::utils::add_new_property $drv_handle "num-hw-triggers" int $prcinfo
	hsi::utils::add_new_property $drv_handle "vsm-msb" int $C_VSM_SELECT_MSB
	hsi::utils::add_new_property $drv_handle "vsm-lsb" int $C_VSM_SELECT_MSB
	hsi::utils::add_new_property $drv_handle "bank-msb" int $C_VSM_SELECT_MSB
	hsi::utils::add_new_property $drv_handle "banl-lsb" int $C_VSM_SELECT_MSB
	hsi::utils::add_new_property $drv_handle "reg-select-msb" int $C_VSM_SELECT_MSB
	hsi::utils::add_new_property $drv_handle "reg-select-lsb" int $C_VSM_SELECT_MSB
}
