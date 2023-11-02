#
# (C) Copyright 2018-2022 Xilinx, Inc.
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

    proc vproc_ss_generate {drv_handle} {

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
        vproc_ss_add_hier_instances $drv_handle

	set p_highaddress [hsi get_property CONFIG.C_HIGHADDR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,highaddr" [format %08x $p_highaddress] hexint $dts_file

	set name [hsi get_property NAME [hsi::get_cells -hier $drv_handle]]
	pldt append $node compatible "\ \, \"xlnx,vpss-scaler-2.2\"\ \, \"xlnx,v-vpss-scaler-2.2\"\ \, \"xlnx,vpss-scaler\""
	set ip [hsi::get_cells -hier $drv_handle]
	set csc_enable_window [hsi get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
	set interlace [hsi get_property CONFIG.C_ENABLE_INTERLACED [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,enable-interlaced" $interlace boolean $dts_file
	set madi [hsi get_property CONFIG.C_DEINT_MOTION_ADAPTIVE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,deint-motion-adaptive" $madi boolean $dts_file
	set csc_enable_422 [hsi get_property CONFIG.C_CSC_ENABLE_422 [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,csc-enable-422" $csc_enable_422 string $dts_file
	set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,topology" $topology int $dts_file
	set v_scaler_phases [hsi get_property CONFIG.C_V_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,v-scaler-phases" $v_scaler_phases int $dts_file
	set v_scaler_taps [hsi get_property CONFIG.C_V_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,v-scaler-taps" $v_scaler_taps int $dts_file
	set h_scaler_phases [hsi get_property CONFIG.C_H_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,h-scaler-phases" $h_scaler_phases int $dts_file
	add_prop "${node}" "xlnx,max-num-phases" $h_scaler_phases int $dts_file
	set h_scaler_taps [hsi get_property CONFIG.C_H_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,h-scaler-taps" $h_scaler_taps int $dts_file
	set max_cols [hsi get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,max-cols" $max_cols int $dts_file
	set max_rows [hsi get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,max-rows" $max_rows int $dts_file
	set samples_per_clk [hsi get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
	set scaler_algo [hsi get_property CONFIG.C_SCALER_ALGORITHM [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,scaler-algorithm" $scaler_algo int $dts_file
	set enable_csc [hsi get_property CONFIG.C_ENABLE_CSC [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,enable-csc" $enable_csc string $dts_file
	set color_support [hsi get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
	set use_uram [hsi get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file
	set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
    }

    proc vproc_ss_add_hier_instances {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        hsi::current_hw_instance $drv_handle
        set gpios [hsi::get_cells -filter {IP_NAME==axi_gpio}]

	foreach gpio $gpios {
		set name [hsi get_property NAME [hsi::get_cells $gpio]]
		if {[regexp ".axis" $name match]} {
			add_prop "$node" "rstaxis-present" 1 int $dts_file
			add_prop "$node" "rstaxis-connected" $gpio reference $dts_file
		} else {
			add_prop "$node" "rstaxis-present" 0 int $dts_file
		}

		if {[regexp ".axi_mm" $name match]} {
			add_prop "$node" "rstaximm-present" 1 int $dts_file
			add_prop "$node" "rstaximm-connected" $gpio reference $dts_file
		} else {
			add_prop "$node" "rstaximm-present" 0 int $dts_file
		}
	}
        set vdma [hsi::get_cells -filter {IP_NAME==axi_vdma}]
        if {$vdma != ""} {
		add_prop "$node" "vdma-present" 1 int $dts_file
                add_prop "$node" "vdma-connected" $vdma reference $dts_file
        } else {
                add_prop "$node" "vdma-present" 0 int $dts_file
        }
        set sw [hsi::get_cells -filter {IP_NAME==axis_switch}]
        if {$sw != ""} {
		add_prop "$node" "router-present" 1 int $dts_file
                add_prop "$node" "router-connected" $sw reference $dts_file
        } else {
                add_prop "$node" "router-present" 0 int $dts_file
        }
        set csc [hsi::get_cells -filter {IP_NAME==v_csc}]
        if {$csc != ""} {
		add_prop "$node" "csc-present" 1 int $dts_file
                add_prop "$node" "csc-connected" $csc reference $dts_file
        } else {
                add_prop "$node" "csc-present" 0 int $dts_file
        }
        set deint [hsi::get_cells -filter {IP_NAME==v_deinterlacer}]
        if {$deint != ""} {
		add_prop "$node" "deint-present" 1 int $dts_file
                add_prop "$node" "deint-connected" $deint reference $dts_file
        } else {
                add_prop "$node" "deint-present" 0 int $dts_file
        }
        set hcr [hsi::get_cells -hier -filter {IP_NAME==v_hcresampler}]
        if {$hcr != ""} {
		add_prop "$node" "hcrsmplr-present" 1 int $dts_file
                add_prop "$node" "hcrsmplr-connected" $hcr reference $dts_file
        } else {
                add_prop "$node" "hcrsmplr-present" 0 int $dts_file
        }
        set hsr [hsi::get_cells  -filter {IP_NAME==v_hscaler}]
        if {$hsr != ""} {
		add_prop "$node" "hscale-present" 1 int $dts_file
                add_prop "$node" "hscale-connected" $hsr reference $dts_file
        } else {
                add_prop "$node" "hscale-present" 0 int $dts_file
        }
        set letter [hsi::get_cells  -filter {IP_NAME==v_letterbox}]
        if {$letter != ""} {
		add_prop "$node" "lbox-present" 1 int $dts_file
                add_prop "$node" "lbox-connected" $letter reference $dts_file
        } else {
                add_prop "$node" "lbox-present" 0 int $dts_file
        }
        set vcrs [hsi::get_cells  -filter {IP_NAME==v_vcresampler}]
	foreach vcr $vcrs {
		set name [hsi get_property NAME [hsi::get_cells $vcr]]
		if {[regexp "._o" $name match]} {
			add_prop "$node" "vcrsmplrout-present" 1 int $dts_file
			add_prop "$node" "vcrsmplrout-connected" $vcr reference $dts_file
		}
		if {[regexp "._i" $name match]} {
			add_prop "$node" "vcrsmplrin-present" 1 int $dts_file
			add_prop "$node" "vcrsmplrin-connected" $vcr reference $dts_file
		}
	}
        set vsc [hsi::get_cells  -filter {IP_NAME==v_vscaler}]
        if {$vsc != ""} {
		add_prop "$node" "vscale-present" 1 int $dts_file
                add_prop "$node" "vscale-connected" $vsc reference $dts_file
        } else {
                add_prop "$node" "vscale-present" 0 int $dts_file
        }

    }


