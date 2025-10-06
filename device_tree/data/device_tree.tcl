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

package require Tcl 8.5.14
package require yaml
package require struct
package require textutil::split
package require json

namespace eval ::sdtgen {
    variable namespacelist [dict create]
    variable loader_path [file normalize [info script]]
}

proc init_proclist {} {
	variable ::sdtgen::namespacelist

	dict set ::sdtgen::namespacelist "RM" "RM"
	dict set ::sdtgen::namespacelist "ai_engine" "ai_engine"
	dict set ::sdtgen::namespacelist "psu_ams" "ams"
	dict set ::sdtgen::namespacelist "psu_apm psv_apm" "apmps"
	dict set ::sdtgen::namespacelist "v_uhdsdi_audio" "audio_embed"
	dict set ::sdtgen::namespacelist "audio_formatter" "audio_formatter"
	dict set ::sdtgen::namespacelist "spdif" "audio_spdif"
	dict set ::sdtgen::namespacelist "axi_bram_ctrl" "axi_bram"
	dict set ::sdtgen::namespacelist "lmb_bram_if_cntlr" "axi_bram"
	dict set ::sdtgen::namespacelist "can" "axi_can"
	dict set ::sdtgen::namespacelist "canfd" "canfd"
	dict set ::sdtgen::namespacelist "axi_cdma" "axi_cdma"
	dict set ::sdtgen::namespacelist "clk_wiz" "axi_clk_wiz"
	dict set ::sdtgen::namespacelist "clkx5_wiz" "axi_clk_wiz"
	dict set ::sdtgen::namespacelist "clk_wizard" "axi_clk_wiz"
	dict set ::sdtgen::namespacelist "axi_fifo_mm_s" "axi_fifo_mm_s"
	dict set ::sdtgen::namespacelist "mutex" "mutex"
	dict set ::sdtgen::namespacelist "mailbox" "mailbox"
	dict set ::sdtgen::namespacelist "axi_dma" "axi_dma"
	dict set ::sdtgen::namespacelist "axi_emc" "axi_emc"
	dict set ::sdtgen::namespacelist "axi_ethernet" "axi_ethernet"
	dict set ::sdtgen::namespacelist "axi_ethernet_buffer" "axi_ethernet"
	dict set ::sdtgen::namespacelist "axi_10g_ethernet" "axi_ethernet"
	dict set ::sdtgen::namespacelist "xxv_ethernet" "axi_ethernet"
	dict set ::sdtgen::namespacelist "ethernet_1_10_25g" "axi_ethernet"
	dict set ::sdtgen::namespacelist "usxgmii" "axi_ethernet"
	dict set ::sdtgen::namespacelist "axi_gpio" "axi_gpio"
	dict set ::sdtgen::namespacelist "axi_hwicap" "axi_hwicap"
	dict set ::sdtgen::namespacelist "axi_iic" "axi_iic"
	dict set ::sdtgen::namespacelist "axi_i3c" "axi_i3c"
	dict set ::sdtgen::namespacelist "axi_mcdma" "axi_mcdma"
	dict set ::sdtgen::namespacelist "axi_pcie" "axi_pcie"
	dict set ::sdtgen::namespacelist "axi_pcie3" "axi_pcie"
	dict set ::sdtgen::namespacelist "xdma" "axi_pcie"
	dict set ::sdtgen::namespacelist "axi_perf_mon" "axi_perf_mon"
	dict set ::sdtgen::namespacelist "axi_quad_spi" "axi_qspi"
	dict set ::sdtgen::namespacelist "axi_sysace" "axi_sysace"
	dict set ::sdtgen::namespacelist "axi_tft" "axi_tft"
	dict set ::sdtgen::namespacelist "axi_timebase_wdt" "axi_timebase_wdt"
	dict set ::sdtgen::namespacelist "axi_traffic_gen" "axi_traffic_gen"
	dict set ::sdtgen::namespacelist "axi_usb2_device" "axi_usb2_device"
	dict set ::sdtgen::namespacelist "vcu" "axi_vcu"
	dict set ::sdtgen::namespacelist "vcu2" "axi_vcu2"
	dict set ::sdtgen::namespacelist "vdu" "axi_vdu"
	dict set ::sdtgen::namespacelist "axi_vdma" "axi_vdma"
	dict set ::sdtgen::namespacelist "xadc_wiz" "axi_xadc"
	dict set ::sdtgen::namespacelist "system_management_wiz" "sysmon"
	dict set ::sdtgen::namespacelist "psu_canfd" "canfd"
	dict set ::sdtgen::namespacelist "psv_canfd" "canfd"
	dict set ::sdtgen::namespacelist "ps7_can" "canps"
	dict set ::sdtgen::namespacelist "psu_can" "canps"
	dict set ::sdtgen::namespacelist "psv_can" "canps"
	dict set ::sdtgen::namespacelist "microblaze" "cpu"
	dict set ::sdtgen::namespacelist "microblaze_riscv" "cpu"
	dict set ::sdtgen::namespacelist "psu_cortexa53" "cpu_cortexa53"
	dict set ::sdtgen::namespacelist "psv_cortexa72" "cpu_cortexa72"
	dict set ::sdtgen::namespacelist "ps7_cortexa9" "cpu_cortexa9"
	dict set ::sdtgen::namespacelist "psu_cortexr5" "cpu_cortexr5"
	dict set ::sdtgen::namespacelist "psv_cortexr5" "cpu_cortexr5"
	dict set ::sdtgen::namespacelist "psx_cortexr52" "cpu_cortexr52"
	dict set ::sdtgen::namespacelist "cortexr52" "cpu_cortexr52"
	dict set ::sdtgen::namespacelist "psx_cortexa78" "cpu_cortexa78"
	dict set ::sdtgen::namespacelist "cortexa78" "cpu_cortexa78"
	dict set ::sdtgen::namespacelist "psu_crl_apb" "crl_apb"
	dict set ::sdtgen::namespacelist "ps7_ddrc" "ddrcps"
	dict set ::sdtgen::namespacelist "psu_ddrc" "ddrcps"
	dict set ::sdtgen::namespacelist "psv_ddrc" "ddrcps"
	dict set ::sdtgen::namespacelist "ps7_ddr" "ddrps"
	dict set ::sdtgen::namespacelist "psu_ddr" "ddrps"
	dict set ::sdtgen::namespacelist "psv_ddr" "ddrps"
	dict set ::sdtgen::namespacelist "axi_noc" "ddrpsv"
	dict set ::sdtgen::namespacelist "noc_mc_ddr4" "ddrpsv"
	dict set ::sdtgen::namespacelist "debug_bridge" "debug_bridge"
	dict set ::sdtgen::namespacelist "ps7_dev_cfg" "devcfg"
	dict set ::sdtgen::namespacelist "ps7_dma" "dmaps"
	dict set ::sdtgen::namespacelist "psu_adma" "dmaps"
	dict set ::sdtgen::namespacelist "psu_gdma" "dmaps"
	dict set ::sdtgen::namespacelist "psu_csudma" "dmaps"
	dict set ::sdtgen::namespacelist "psv_adma" "dmaps"
	dict set ::sdtgen::namespacelist "psv_gdma" "dmaps"
	dict set ::sdtgen::namespacelist "psu_dp" "dp"
	dict set ::sdtgen::namespacelist "psv_dp" "dp"
	dict set ::sdtgen::namespacelist "dp_rx_subsystem" "dp_rxss12"
	dict set ::sdtgen::namespacelist "dp_tx_subsystem" "dp_txss12"
	dict set ::sdtgen::namespacelist "gtwiz_versal" "dp_gt_ctrl"
	dict set ::sdtgen::namespacelist "v_dp_rxss1" "dp_rxss14"
	dict set ::sdtgen::namespacelist "v_dp_txss1" "dp_txss14"
	dict set ::sdtgen::namespacelist "displayport" "dp12_14_core"
	dict set ::sdtgen::namespacelist "v_dp_rxss2" "dp_rxss21"
	dict set ::sdtgen::namespacelist "v_dp_txss2" "dp_txss21"
	dict set ::sdtgen::namespacelist "dprx" "dprx21_core"
	dict set ::sdtgen::namespacelist "dptx" "dptx21_core"
	dict set ::sdtgen::namespacelist "dpu_eu" "dpu_eu"
	dict set ::sdtgen::namespacelist "axi_ethernetlite" "emaclite"
	dict set ::sdtgen::namespacelist "ps7_ethernet" "emacps"
	dict set ::sdtgen::namespacelist "psu_ethernet" "emacps"
	dict set ::sdtgen::namespacelist "psv_ethernet" "emacps"
	dict set ::sdtgen::namespacelist "mmi_10gbe" "emacps"
	dict set ::sdtgen::namespacelist "ernic" "ernic"
	dict set ::sdtgen::namespacelist "v_frmbuf_rd" "framebuf_rd"
	dict set ::sdtgen::namespacelist "v_frmbuf_wr" "framebuf_wr"
	dict set ::sdtgen::namespacelist "ps7_globaltimer" "globaltimerps"
	dict set ::sdtgen::namespacelist "ps7_gpio" "gpiops"
	dict set ::sdtgen::namespacelist "psu_gpio" "gpiops"
	dict set ::sdtgen::namespacelist "psv_gpio" "gpiops"
	dict set ::sdtgen::namespacelist "hdmi_gt_controller" "hdmi_gt_ctrl"
	dict set ::sdtgen::namespacelist "v_hdmi_phy1" "hdmi_phy1"
	dict set ::sdtgen::namespacelist "v_hdmi_rxss1" "hdmi_rxss1"
	dict set ::sdtgen::namespacelist "v_hdmi_txss1" "hdmi_txss1"
	dict set ::sdtgen::namespacelist "v_hdmi_tx1" "hdmi_tx1"
	dict set ::sdtgen::namespacelist "v_hdmi_rx1" "hdmi_rx1"
	dict set ::sdtgen::namespacelist "v_hdmi_rx_ss" "hdmi_rx_ss"
	dict set ::sdtgen::namespacelist "v_hdmi_tx_ss" "hdmi_tx_ss"
	dict set ::sdtgen::namespacelist "v_hdmi_tx" "hdmi_tx"
	dict set ::sdtgen::namespacelist "v_hdmi_rx" "hdmi_rx"
	dict set ::sdtgen::namespacelist "hdcp22_tx" "hdmi_hdcp22_tx"
	dict set ::sdtgen::namespacelist "hdcp22_rx" "hdmi_hdcp22_rx"
	dict set ::sdtgen::namespacelist "hdcp22_tx_dp" "dp_hdcp22_tx"
	dict set ::sdtgen::namespacelist "hdcp22_rx_dp" "dp_hdcp22_rx"
	dict set ::sdtgen::namespacelist "v_smpte_uhdsdi_rx_ss" "sdi_rxss"
	dict set ::sdtgen::namespacelist "v_smpte_uhdsdi_tx_ss" "sdi_txss"
	dict set ::sdtgen::namespacelist "v_smpte_uhdsdi_rx" "sdi_rx"
	dict set ::sdtgen::namespacelist "v_smpte_uhdsdi_tx" "sdi_tx"
	dict set ::sdtgen::namespacelist "mipi_csi2_rx_subsystem" "mipi_csi2_rx_ss"
	dict set ::sdtgen::namespacelist "mipi_csi2_rx_ctrl" "mipi_csi2_rx_core"
	dict set ::sdtgen::namespacelist "mipi_csi2_tx_subsystem" "mipi_csi2_tx_ss"
	dict set ::sdtgen::namespacelist "mipi_csi2_tx_ctrl" "mipi_csi2_tx_core"
	dict set ::sdtgen::namespacelist "mipi_dsi_tx_subsystem" "mipi_dsi_tx_ss"
	dict set ::sdtgen::namespacelist "mipi_dsi_tx_ctrl" "mipi_dsi_tx_core"
	dict set ::sdtgen::namespacelist "mipi_dsi2_rx_subsystem" "mipi_dsi2_rx_ss"
	dict set ::sdtgen::namespacelist "mipi_dsi2_rx_ctrl" "mipi_dsi2_rx_core"
	dict set ::sdtgen::namespacelist "mipi_dphy" "mipi_dphy"
	dict set ::sdtgen::namespacelist "mipi_rx_phy" "mipi_rx_phy"
	dict set ::sdtgen::namespacelist "mipi_tx_phy" "mipi_tx_phy"
	dict set ::sdtgen::namespacelist "v_demosaic" "demosaic"
	dict set ::sdtgen::namespacelist "v_gamma_lut" "gamma_lut"
	dict set ::sdtgen::namespacelist "i2s_receiver" "i2s_receiver"
	dict set ::sdtgen::namespacelist "i2s_transmitter" "i2s_transmitter"
	dict set ::sdtgen::namespacelist "ps7_i2c" "iicps"
	dict set ::sdtgen::namespacelist "psu_i2c" "iicps"
	dict set ::sdtgen::namespacelist "psv_i2c" "iicps"
	dict set ::sdtgen::namespacelist "psx_i2c" "iicps"
	dict set ::sdtgen::namespacelist "i2c" "iicps"
	dict set ::sdtgen::namespacelist "psv_pmc_i2c" "iicps"
	dict set ::sdtgen::namespacelist "psx_pmc_i2c" "iicps"
	dict set ::sdtgen::namespacelist "pmc_i2c" "iicps"
	dict set ::sdtgen::namespacelist "axi_intc" "intc"
	dict set ::sdtgen::namespacelist "iomodule" "iomodule"
	dict set ::sdtgen::namespacelist "psx_iomodule" "iomodule"
	dict set ::sdtgen::namespacelist "iomodule" "iomodule"
	dict set ::sdtgen::namespacelist "psu_ipi" "ipipsu"
	dict set ::sdtgen::namespacelist "psv_ipi" "ipipsu"
	dict set ::sdtgen::namespacelist "psx_ipi" "ipipsu"
	dict set ::sdtgen::namespacelist "ipi" "ipipsu"
	dict set ::sdtgen::namespacelist "mig_7series" "ddrps"
	dict set ::sdtgen::namespacelist "ddr4" "ddrps"
	dict set ::sdtgen::namespacelist "ddr3" "ddrps"
	dict set ::sdtgen::namespacelist "mrmac" "mrmac"
	dict set ::sdtgen::namespacelist "v_multi_scaler" "multi_scaler"
	dict set ::sdtgen::namespacelist "ps7_nand" "nandps"
	dict set ::sdtgen::namespacelist "psu_nand" "nandps"
	dict set ::sdtgen::namespacelist "psv_nand" "nandps"
	dict set ::sdtgen::namespacelist "ps7_sram" "norps"
	dict set ::sdtgen::namespacelist "nvme_subsystem" "nvme_aggr"
	dict set ::sdtgen::namespacelist "ps7_ocmc" "ocmcps"
	dict set ::sdtgen::namespacelist "psu_ocm" "ocmcps"
	dict set ::sdtgen::namespacelist "psv_ocm" "ocmcps"
	dict set ::sdtgen::namespacelist "psu_ospi" "ospips"
	dict set ::sdtgen::namespacelist "psv_pmc_ospi" "ospips"
	dict set ::sdtgen::namespacelist "psx_pmc_ospi" "ospips"
	dict set ::sdtgen::namespacelist "pmc_ospi" "ospips"
	dict set ::sdtgen::namespacelist "pmcl_ospi" "ospips"
	dict set ::sdtgen::namespacelist "ps7_pl310" "pl310ps"
	dict set ::sdtgen::namespacelist "psu_pmu" "pmups"
	dict set ::sdtgen::namespacelist "psv_pmc" "pmups"
	dict set ::sdtgen::namespacelist "psv_psm" "pmups"
	dict set ::sdtgen::namespacelist "psx_pmc" "pmups"
	dict set ::sdtgen::namespacelist "pmc" "pmups"
	dict set ::sdtgen::namespacelist "psx_psm" "pmups"
	dict set ::sdtgen::namespacelist "psm" "pmups"
	dict set ::sdtgen::namespacelist "dfx_decoupler" "pr_decoupler"
	dict set ::sdtgen::namespacelist "dfx_controller" "prc"
	dict set ::sdtgen::namespacelist "psu_ocm_ram_0" "psu_ocm"
	dict set ::sdtgen::namespacelist "psv_ocm_ram_0" "psu_ocm"
	dict set ::sdtgen::namespacelist "ptp_1588_timer_syncer" "ptp_1588_timer_syncer"
	dict set ::sdtgen::namespacelist "ps7_qspi" "qspips"
	dict set ::sdtgen::namespacelist "psu_qspi" "qspips"
	dict set ::sdtgen::namespacelist "psv_pmc_qspi" "qspips"
	dict set ::sdtgen::namespacelist "ps7_ram" "ramps"
	dict set ::sdtgen::namespacelist "usp_rf_data_converter" "rfdc"
	dict set ::sdtgen::namespacelist "xdfe_cc_filter" "dfeccf"
	dict set ::sdtgen::namespacelist "xdfe_cc_mixer" "dfemix"
	dict set ::sdtgen::namespacelist "xdfe_ofdm" "dfeofdm"
	dict set ::sdtgen::namespacelist "xdfe_nr_prach" "dfeprach"
	dict set ::sdtgen::namespacelist "ps7_scugic" "scugic"
	dict set ::sdtgen::namespacelist "psu_acpu_gic" "scugic"
	dict set ::sdtgen::namespacelist "psv_acpu_gic" "scugic"
	dict set ::sdtgen::namespacelist "ps7_scutimer" "scutimer"
	dict set ::sdtgen::namespacelist "ps7_scuwdt" "scuwdt"
	dict set ::sdtgen::namespacelist "psu_wdt" "scuwdt"
	dict set ::sdtgen::namespacelist "psv_wdt" "scuwdt"
	dict set ::sdtgen::namespacelist "sd_fec" "sdfec"
	dict set ::sdtgen::namespacelist "ps7_sdioi" "sdps"
	dict set ::sdtgen::namespacelist "psu_sd" "sdps"
	dict set ::sdtgen::namespacelist "psv_pmc_sd" "sdps"
	dict set ::sdtgen::namespacelist "ps7_slcr" "slcrps"
	dict set ::sdtgen::namespacelist "ps7_smcc" "smccps"
	dict set ::sdtgen::namespacelist "ps7_spi" "spips"
	dict set ::sdtgen::namespacelist "psu_spi" "spips"
	dict set ::sdtgen::namespacelist "psv_spi" "spips"
	dict set ::sdtgen::namespacelist "spi" "spips"
	dict set ::sdtgen::namespacelist "sync_ip" "sync_ip"
	dict set ::sdtgen::namespacelist "psv_pmc_sysmon" "sysmonpsv"
	dict set ::sdtgen::namespacelist "slv1_psv_pmc_sysmon" "sysmonpsv"
	dict set ::sdtgen::namespacelist "slv2_psv_pmc_sysmon" "sysmonpsv"
	dict set ::sdtgen::namespacelist "slv3_psv_pmc_sysmon" "sysmonpsv"
	dict set ::sdtgen::namespacelist "pmc_sysmon" "sysmonpsv"
	dict set ::sdtgen::namespacelist "axi_timer" "tmrctr"
	dict set ::sdtgen::namespacelist "tmr_manager" "tmr_manager"
	dict set ::sdtgen::namespacelist "tmr_inject" "tmr_inject"
	dict set ::sdtgen::namespacelist "tsn_endpoint_ethernet_mac" "tsn"
	dict set ::sdtgen::namespacelist "ps7_ttc" "ttcps"
	dict set ::sdtgen::namespacelist "psu_ttc" "ttcps"
	dict set ::sdtgen::namespacelist "psv_ttc" "ttcps"
	dict set ::sdtgen::namespacelist "mdm" "uartlite"
	dict set ::sdtgen::namespacelist "axi_uartlite" "uartlite"
	dict set ::sdtgen::namespacelist "axi_uart16550" "uartns"
	dict set ::sdtgen::namespacelist "ps7_uart" "uartps"
	dict set ::sdtgen::namespacelist "psu_uart" "uartps"
	dict set ::sdtgen::namespacelist "psu_sbsauart" "uartps"
	dict set ::sdtgen::namespacelist "psv_uart" "uartps"
	dict set ::sdtgen::namespacelist "psv_sbsauart" "uartps"
	dict set ::sdtgen::namespacelist "ps7_usb" "usbps"
	dict set ::sdtgen::namespacelist "psu_usb_xhci" "usbps"
	dict set ::sdtgen::namespacelist "psv_usb_xhci" "usbps"
	dict set ::sdtgen::namespacelist "vid_phy_controller" "vid_phy_ctrl"
	dict set ::sdtgen::namespacelist "v_tc" "vtc"
	dict set ::sdtgen::namespacelist "v_proc_ss" "vproc_ss"
	dict set ::sdtgen::namespacelist "v_tpg" "tpg"
	dict set ::sdtgen::namespacelist "v_mix" "mixer"
	dict set ::sdtgen::namespacelist "v_scenechange" "scene_change_detector"
	dict set ::sdtgen::namespacelist "ps7_wdt" "wdtps"
	dict set ::sdtgen::namespacelist "psu_wdt" "wdtps"
	dict set ::sdtgen::namespacelist "psv_wdt" "wdtps"
	dict set ::sdtgen::namespacelist "psv_wwdt" "wdttb"
	dict set ::sdtgen::namespacelist "ps7_xadc" "xadcps"
	dict set ::sdtgen::namespacelist "qdma" "xdmapcie"
	dict set ::sdtgen::namespacelist "psv_cpm" "cpm_pcie"

	dict set ::sdtgen::namespacelist "psu_qspi_linear" "linear_spi"
	dict set ::sdtgen::namespacelist "ps7_qspi_linear" "linear_spi"

	dict set ::sdtgen::namespacelist "psx_apm" "apmps"
	dict set ::sdtgen::namespacelist "apm" "apmps"
	dict set ::sdtgen::namespacelist "psx_canfd" "canfd"
	dict set ::sdtgen::namespacelist "canfd" "canfd"
	dict set ::sdtgen::namespacelist "noc_mc_ddr5" "ddrpsv"
	dict set ::sdtgen::namespacelist "psx_adma" "dmaps"
	dict set ::sdtgen::namespacelist "adma" "dmaps"
	dict set ::sdtgen::namespacelist "psx_gdma" "dmaps"
	dict set ::sdtgen::namespacelist "gdma" "dmaps"
	dict set ::sdtgen::namespacelist "pmc_dma" "pmcdma"
	dict set ::sdtgen::namespacelist "pmcl_dma" "pmcdma"
	dict set ::sdtgen::namespacelist "psx_ethernet" "emacps"
	dict set ::sdtgen::namespacelist "ethernet" "emacps"
	dict set ::sdtgen::namespacelist "psx_gpio" "gpiops"
	dict set ::sdtgen::namespacelist "gpio" "gpiops"
	dict set ::sdtgen::namespacelist "psx_i3c" "i3cpsx"
	dict set ::sdtgen::namespacelist "i3c" "i3cpsx"
	dict set ::sdtgen::namespacelist "psx_acpu_gic" "scugic"
	dict set ::sdtgen::namespacelist "acpu_gic" "scugic"
	dict set ::sdtgen::namespacelist "psx_pmc_sd" "sdps"
	dict set ::sdtgen::namespacelist "pmc_sd" "sdps"
	dict set ::sdtgen::namespacelist "psx_pmc_qspi" "qspips"
	dict set ::sdtgen::namespacelist "pmc_qspi" "qspips"
	dict set ::sdtgen::namespacelist "psx_ttc" "ttcps"
	dict set ::sdtgen::namespacelist "ttc" "ttcps"
	dict set ::sdtgen::namespacelist "psx_sbsauart" "uartps"
	dict set ::sdtgen::namespacelist "sbsauart" "uartps"
	dict set ::sdtgen::namespacelist "axi_noc2" "ddrpsv"
	dict set ::sdtgen::namespacelist "noc_mc_ddr5" "ddrpsv"
	dict set ::sdtgen::namespacelist "psx_ocm_ram" "psu_ocm"
	dict set ::sdtgen::namespacelist "ocm_ram" "psu_ocm"
	dict set ::sdtgen::namespacelist "psx_ocm_ram_0" "psu_ocm"
	dict set ::sdtgen::namespacelist "ocm_ram_0" "psu_ocm"
	dict set ::sdtgen::namespacelist "psx_wwdt" "wdttb"
	dict set ::sdtgen::namespacelist "wwdt" "wdttb"
	dict set ::sdtgen::namespacelist "pmc_wwdt" "wdttb"
	dict set ::sdtgen::namespacelist "psx_pmc_trng" "trngpsx"
	dict set ::sdtgen::namespacelist "pmc_trng" "trngpsx"
	dict set ::sdtgen::namespacelist "visp_ss" "visp_ss"

	dict set ::sdtgen::namespacelist "asu" "asu"
	dict set ::sdtgen::namespacelist "axis_switch" "axis_switch"
	dict set ::sdtgen::namespacelist "axis_broadcaster" "axis_broadcaster"
	dict set ::sdtgen::namespacelist "ISPPipeline_accel" "isppipeline"
	dict set ::sdtgen::namespacelist "hdmi_acr_ctrl" "hdmi_ctrl"
	dict set ::sdtgen::namespacelist "dfx_axi_shutdown_manager" "dfx_axi_shutdown_manager"
	dict set ::sdtgen::namespacelist "mmi_dc" "axi_mmi_dc"
	dict set ::sdtgen::namespacelist "mmi_udh_dp" "axi_mmi_dptx"
	dict set ::sdtgen::namespacelist "mmi_usb_cfg" "mmi_usb"

	part_specific_init_proclist
}

proc Pop {varname {nth 0}} {
	upvar $varname args
	set r [lindex $args $nth]
	set args [lreplace $args $nth $nth]
	return $r
}

# Lately HSI started reporting verbose warnings from [Common 17-673]
proc suppress_hsi_warnings {} {
	hsi::set_msg_config -suppress -id "Common 17-673"
}

proc print_usage args {
        set help_str { 
            Usage: set/get_dt_param \[OPTION\]
            -repo             system device tree repo source
            -xsa              Vivado hw design file
            -board_dts        board specific file
            -mainline_kernel  mainline kernel version
            -kernel_ver       kernel version
            -dir              Directory where the dt files will be generated
            -user_dts         DTS file to be include into final device tree
            -debug            Enable DTG++ debug
            -trace            Enable DTG++ traces
            -zocl             Create zocl node in device tree. Possible options: enable/disable. Default option: disable
	}
        return $help_str
}

proc set_sdt_default_repo {} {
	global env
	variable ::sdtgen::loader_path
	if { ![info exists ::env(CUSTOM_SDT_REPO)] } {
		set env(CUSTOM_SDT_REPO) [file dirname [file dirname [file dirname $::sdtgen::loader_path]]]
	}
	return $env(CUSTOM_SDT_REPO)
}

proc get_user_config args {
        set dict_devicetree  {}
	set val [get_dt_param [lindex $args 1]]
	if {[string match -nocase $val ""]} {
	        set config_file [lindex $args 0]
		set cfg [get_yaml_dict $config_file]
	        set user [dict get $cfg dict_devicetree]
		set mainline_kernel [dict get $user mainline_kernel]
		set kernel_ver [dict get $user kernel_ver]
		set dir [dict get $user output_dir]
		set zocl [dict get $user zocl]
		set param ""
		switch -glob -- [lindex $args 1] {
			-repo {
				set param $path
			} -master_dts {
				set param $master_dts
			} -config_dts {
				set param $config_dts
			} -board_dts {
				set param ""
			} -pl_only {
				set param $pl_only
			} -mainline_kernel {
				set param $mainline_kernel
			} -kernel_ver {
				set param $kernel_ver
			} -dir {
				set param $dir
			} -zocl {
				set param $zocl
			} default {
				error "get_user_config bad option - [lindex $args 0]"
			}
		}
	} else {
		set param $val
	}
        return $param
}

proc get_yaml_dict { config_file } {
        set data ""
        if {[file exists $config_file]} {
                set fd [open $config_file r]
                set data [read $fd]
                close $fd
        } else {
                error "YAML:: No such file $config_file"
        }
	return [yaml::yaml2dict $data]
}

proc set_dt_param args {
	global env
	if {[llength $args] == 0 || ![string match -* [lindex $args 0]]} {
		print_usage
	} else {
		while {[string match -* [lindex $args 0]]} {
			if {[string match -nocase [lindex $args 1] ""] && ![string match -nocase [lindex $args 0] "-help"]} {
				puts "invalid value for [lindex $args 0]"
				print_usage
			}
			switch -glob -- [lindex $args 0] {
				-force {set force_create 1}
				-xsa {
					set xsa_file [Pop args 1]
					if {![regexp {^(file|link)$} [file type $xsa_file]] } {
						error "ERROR: set_dt_param expects an XSA file as an input. Please check -xsa argument."
					}
					set env(xsa) $xsa_file
				}
				-rm_xsa {
					set rm_xsa_file [Pop args 1]
					set rm_xsa_list [split $rm_xsa_file " "]
					foreach xsa $rm_xsa_list {
						if {![regexp {^(file|link)$} [file type $xsa]]} {
							error "ERROR: set_dt_param expects an XSA file as an input. Please check -rm_xsa argument."
						}
					}
					set env(rm_xsa) $rm_xsa_file
				}
				-board_dts {
					set board_dts_file [Pop args 1]
					if {[string tolower [file extension $board_dts_file]] eq ".dtsi"} {
						error "ERROR: board_dts expects file name without .dtsi extension. Please update"
					}
					set common_file "$env(CUSTOM_SDT_REPO)/device_tree/data/config.yaml"
					set kernel_ver [get_user_config $common_file -kernel_ver]
					set kernel_dtsi [file normalize "$env(CUSTOM_SDT_REPO)/device_tree/data/kernel_dtsi/$kernel_ver/BOARD"]
					set target_board_file [file join $kernel_dtsi "${board_dts_file}.dtsi"]
					if {![file exists $target_board_file]} {
						error "Error: The board file '${board_dts_file}.dtsi' was not found in the repository. Please refer $kernel_dtsi for valid board names."
					}
					set env(sdt_board_dts) $board_dts_file
				}
				-domain {
					set dt_domain [Pop args 1]
					if {$dt_domain != "pmc"} {
						error "ERROR: Invalid domain option '$dt_domain'. Only Valid option is 'pmc'."
					}
					set env(dt_domain) $dt_domain
				}
                                -mainline_kernel {set env(kernel) [Pop args 1] }
                                -kernel_ver {set env(kernel_ver) [Pop args 1]}
                                -dir {
					set dir [Pop args 1]
					if {[file exists $dir]} {
						puts "INFO: $dir exists. Files will be overwritten"
					}
					set env(dir) $dir
				}
                                -repo {set env(CUSTOM_SDT_REPO) [Pop args 1]}
                                -zocl {
					set zocl [Pop args 1]
					if {!($zocl in {"enable" "disable"})} {
						error "Invalid option: $zocl. Valid options: enable/disable. Default option: disable"
					}
					set env(zocl) $zocl
				}
                                -user_dts - \-include_dts {
					# FIXME: Below line should not be needed. It is added to support
					# -user_dts {a.dtsi b.dtsi} kind of input which Vitis uses. Otherwise
					# files are not getting copied with the usage of lappend in defining user_dts.
					set env(user_dts) [Pop args 1]
					set user_dts_args [lrange $args 1 end]
					foreach arg $user_dts_args {
						if {![string match "-*" $arg]} {
							lappend env(user_dts) $arg
							Pop args 1
						} else {
							break
						}
					}
					foreach dts $env(user_dts) {
						if {![file exists $dts]} {
							error "$dts does not exist"
						}
					}
                                }
                                -debug {
					set debug [Pop args 1]
					if {!($debug in {"enable" "disable"})} {
						error "Invalid option: $debug. Valid options: enable/disable. Default option: disable"
					}
					set env(debug) $debug
				}
                                -verbose {
					set verbose [Pop args 1]
					if {!($verbose in {"enable" "disable"})} {
						error "Invalid option: $verbose. Valid options: enable/disable. Default option: disable"
					}
					set env(verbose) $verbose
				}
                                -trace {
					set trace [Pop args 1]
					if {!($trace in {"enable" "disable"})} {
						error "Invalid option: $trace. Valid options: enable/disable. Default option: disable"
					}
					set env(trace) $trace
				}
                                -help {return [print_usage]}
                                -  {Pop args ; break}
                                default {
                                        error "set_dt_param bad option - [lindex $args 0]"
                                        print_usage
                                }
                        }
                        Pop args
                }
        }
}

proc get_dt_param args {
	global env
	set param [lindex $args 0]
	set val ""
	switch $param {
	-xsa {
		if {[catch {set val $env(xsa)} msg ]} {}
	} -rm_xsa {
		if {[catch {set val $env(rm_xsa)} msg ]} {}
	} -repo {
		if {[catch {set val $env(CUSTOM_SDT_REPO)} msg ]} {
			set val [set_sdt_default_repo]
		}
	} -board -
	 -board_dts {
		if {[catch {set val $env(sdt_board_dts)} msg ]} {}
	} -mainline_kernel {
		if {[catch {set val $env(kernel)} msg ]} {}
	} -kernel_ver {
		if {[catch {set val $env(kernel_ver)} msg ]} {}
	} -dir {
		if {[catch {set val $env(dir)} msg ]} {}
	} -trace {
		if {[catch {set val $env(trace)} msg ]} {
			set val "disable"
		}
	} -debug {
		if {[catch {set val $env(debug)} msg ]} {
			set val "disable"
		}
	} -zocl {
		if {[catch {set val $env(zocl)} msg ]} {
			set val "disable"
		}
	} -user_dts {
		if {[catch {set val $env(user_dts)} msg ]} {}
	} -include_dts {
		if {[catch {set val $env(user_dts)} msg ]} {}
	} -help {
		set val [print_usage]
	} default {
		puts "unknown option $param"
		set val [print_usage]
	}
	}
	return $val
}

proc inc_os_prop {drv_handle os_conf_dev_var var_name conf_prop} {
    set ip_check "False"
    set os_ip [hsi get_property ${os_conf_dev_var} [get_os]]
    if {![string match -nocase "" $os_ip]} {
        set os_ip [hsi get_property ${os_conf_dev_var} [get_os]]
        set ip_check "True"
    }

    set count [get_os_parameter_value $var_name]
    if {[llength $count] == 0} {
        if {[string match -nocase "True" $ip_check]} {
            set count 1
        } else {
            set count 0
        }
    }

    if {[string match -nocase "True" $ip_check]} {
        set ip [hsi::get_cells -hier $drv_handle]
        if {[string match -nocase $os_ip $ip]} {
            set ip_type [hsi get_property IP_NAME $ip]
            set_property ${conf_prop} 0 $drv_handle
            return
        }
    }

    set_property $conf_prop $count $drv_handle
    incr count
    set_os_parameter_value $var_name $count
}

proc gen_count_prop {drv_handle data_dict} {
    dict for {dev_type dev_conf_mapping} [dict get $data_dict] {
        set os_conf_dev_var [dict get $data_dict $dev_type "os_device"]
        set valid_ip_list [dict get $data_dict $dev_type "ip"]
        set drv_conf [dict get $data_dict $dev_type "drv_conf"]
        set os_count_name [dict get $data_dict $dev_type "os_count_name"]

        set slave [hsi::get_cells -hier $drv_handle]
        set iptype [hsi get_property IP_NAME $slave]
        if {[lsearch $valid_ip_list $iptype] < 0} {
            continue
        }

        set irq_chk [dict get $data_dict $dev_type "irq_chk"]
        if {![string match -nocase "false" $irq_chk]} {
            set irq_id [get_interrupt_id $slave $irq_chk]
            if {[llength $irq_id] < 0} {
                dtg_warning "Fail to located interrupt pin - $irq_chk. The $drv_conf is not set for $dev_type"
                continue
            }
        }

        inc_os_prop $drv_handle $os_conf_dev_var $os_count_name $drv_conf
    }
}

proc gen_dev_conf {} {
    # data to populated certain configs for different devices
    set data_dict {
        uart {
            os_device "CONFIG.console_device"
            ip "axi_uartlite axi_uart16550 ps7_uart psu_uart psv_uart"
            os_count_name "serial_count"
            drv_conf "CONFIG.port-number"
            irq_chk "false"
        }
        mdm_uart {
            os_device "CONFIG.console_device"
            ip "mdm"
            os_count_name "serial_count"
            drv_conf "CONFIG.port-number"
            irq_chk "Interrupt"
        }
        syace {
            os_device "sysace_device"
            ip "axi_sysace"
            os_count_name "sysace_count"
            drv_conf "CONFIG.port-number"
            irq_chk "false"
        }
        traffic_gen {
            os_device "trafficgen_device"
            ip "axi_traffic_gen"
            os_count_name "trafficgen_count"
            drv_conf "CONFIG.xlnx,device-id"
            irq_chk "false"
        }
    }
    # update CONFIG.<para> for each driver when match driver is found
    foreach drv [get_drivers] {
        gen_count_prop $drv $data_dict
    }
}

proc gen_edac_node {} {
	set dts_file "pcw.dtsi"
	set pspmc [hsi get_cells -hier -filter {IP_NAME == "pspmc"}]
	set psxwizard [hsi get_cells -hier -filter {IP_NAME == "psx_wizard"}]
	if {[llength $pspmc]} {
		if { [hsi get_property CONFIG.SEM_MEM_SCAN $pspmc] || [hsi get_property CONFIG.SEM_NPI_SCAN $pspmc] } {
			set edac_node [create_node -n &xilsem_edac -d $dts_file -p root]
			add_prop "${edac_node}" "status" "okay" string $dts_file
			set_memmap "xilsem_edac" a53 "0x0 0xf2014050 0x0 0xc4"

		}
	# put status=okay in edac node for versal-net when any of the CIPS parameters "CONFIG.SEM_MEM_SCAN" or "CONFIG.SEM_NPI_SCAN" are enabled in the design
	} elseif {[llength $psxwizard]} {
		set psx_pmcx_config [hsi get_property CONFIG.PSX_PMCX_CONFIG [hsi get_cells -hier $psxwizard]]
		if {[llength $psx_pmcx_config]} {
			if {[dict exists $psx_pmcx_config "SEM_MEM_SCAN"] || [dict exists $psx_pmcx_config "SEM_NPI_SCAN"]} {
				set edac_node [create_node -n &xilsem_edac -d $dts_file -p root]
				add_prop "${edac_node}" "status" "okay" string $dts_file
				set_memmap "xilsem_edac" a53 "0x0 0xf2014050 0x0 0xc4"
			}
		}
	}
}

proc gen_ddrmc_node {} {
	set dts_file "pcw.dtsi"
	set ddrmc [hsi get_cells -hier -filter {IP_NAME == "noc_mc_ddr4"}]
	if {[llength $ddrmc]} {
		set i 0
		foreach mc $ddrmc {
			if { [hsi get_property CONFIG.MC_ECC $mc] } {
				set ddrmc_node [create_node -n &mc$i -d $dts_file -p root]
				add_prop "${ddrmc_node}" "status" "okay" string ${dts_file}
			}
			incr i
		}
	}

}

proc gen_sata_laneinfo {} {

	foreach ip [hsi::get_cells] {
		set slane 0
		set freq {}
		set ip_type [hsi get_property IP_TYPE [hsi::get_cells -hier $ip]]
		if {$ip_type eq ""} {
			set ps $ip
		}
	}

	set param0 "/bits/ 8 <0x18 0x40 0x18 0x28>"
	set param1 "/bits/ 8 <0x06 0x14 0x08 0x0E>"
	set param2 "/bits/ 8 <0x13 0x08 0x4A 0x06>"
	set param3 "/bits/ 16 <0x96A4 0x3FFC>"

	set param4 "/bits/ 8 <0x1B 0x4D 0x18 0x28>"
	set param5 "/bits/ 8 <0x06 0x19 0x08 0x0E>"
	set param6 " /bits/ 8 <0x13 0x08 0x4A 0x06>"
	set param7 "/bits/ 16 <0x96A4 0x3FFC>"

	set param_list "ceva,p%d-cominit-params ceva,p%d-comwake-params ceva,p%d-burst-params ceva,p%d-retry-params"
	while {$slane < 2} {
		if {[hsi get_property CONFIG.PSU__SATA__LANE$slane\__ENABLE [hsi::get_cells -hier $ps]] == 1} {
			set gt_lane [hsi get_property CONFIG.PSU__SATA__LANE$slane\__IO [hsi::get_cells -hier $ps]]
			regexp [0-9] $gt_lane gt_lane
			lappend freq [hsi get_property CONFIG.PSU__SATA__REF_CLK_FREQ [hsi::get_cells -hier $ps]]
		} else {
			lappend freq 0
			}
		incr slane
	}

	foreach {i j} $freq {
		set i [expr {$i ? $i : $j}]
		set j [expr {$j ? $j : $i}]
	}

	lset freq 0 $i
	lset freq 1 $j
	set dts_file "pcw.dtsi"
	set sata_node [create_node -n "&sata" -d $dts_file -p root]
	set hsi_version [get_hsi_version]
	set ver [split $hsi_version "."]
	set version [lindex $ver 0]

	set slane 0
	while {$slane < 2} {
		set f [lindex $freq $slane]
		set count 0
		if {$f != 0} {
			while {$count < 4} {
				if {$version < 2018} {
					dtg_warning "quotes to be removed or use 2018.1 version for $sata_node params param0..param7"
				}
				set val_name [format [lindex $param_list $count] $slane]
				switch $count {
					"0" {
					add_prop $sata_node $val_name $param0 string $dts_file
					}
					"1" {
					add_prop $sata_node $val_name $param1 string $dts_file
					}
					"2" {
					add_prop $sata_node $val_name $param2 string $dts_file
					}
					"3" {
					add_prop $sata_node $val_name $param3 string $dts_file
					}
					"4" {
					add_prop $sata_node $val_name $param4 string $dts_file
					}
					"5" {
					add_prop $sata_node $val_name $param5 string $dts_file
					}
					"6" {
					add_prop $sata_node $val_name $param6 string $dts_file
					}
					"7" {
					add_prop $sata_node $val_name $param7 string $dts_file
					}
				}
			incr count
			}
		}
	incr slane
	}
}

proc gen_include_headers {} {
	global env
	set common_file "$env(CUSTOM_SDT_REPO)/device_tree/data/config.yaml"
	set kernel_ver [get_user_config $common_file -kernel_ver]
	set includes_dir [file normalize "$env(CUSTOM_SDT_REPO)/device_tree/data/kernel_dtsi/${kernel_ver}/include"]
	set dir_path [get_user_config $common_file -dir]
	# Copy full include directory to dt WS
	if {[file exists $includes_dir]} {
		file delete -force $dir_path/include
		file copy -force $includes_dir $dir_path
	}
}

proc include_custom_dts {} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	# Windows treats an empty env variable as not defined
	if {[catch {set user_dts $env(user_dts)} msg]} {
		set user_dts ""
	}
	set dir_name $env(dir)
	foreach include_dts_file [split $user_dts] {
		if {[file exists $include_dts_file]} {
			file normalize $include_dts_file
			file copy -force $include_dts_file $dir_name
			}
		}
}

proc gen_afi_node {} {
	global rp_region_dict
	global is_bridge_en

	set is_bridge_en 0
	set pllist [hsi::get_cells -filter {IS_PL==1}]
	set dts "pl.dtsi"
	set family [get_hw_family]
	if {[llength $pllist] > 0} {
		set amba_pl_node [add_or_get_bus_node [lindex $pllist 0] $dts]
		if {[is_zynqmp_platform $family]} {

			set hw_name [::hsi::get_hw_files -filter "TYPE == bin"]
			if {$hw_name ne ""} {
				add_prop $amba_pl_node "firmware-name" $hw_name string $dts 1
			} else {
				set hw_name [::hsi::get_hw_files -filter "TYPE == bit"]
				add_prop $amba_pl_node "firmware-name" "$hw_name.bin" string $dts 1
			}

			set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
			set pl_clk_buf_props "CONFIG.C_PL_CLK0_BUF CONFIG.C_PL_CLK1_BUF CONFIG.C_PL_CLK2_BUF CONFIG.C_PL_CLK3_BUF"
			foreach prop ${pl_clk_buf_props} {
				set val [hsi get_property $prop $zynq_periph]
				if {[string match -nocase $val "true"]} {
					set index [lsearch $pl_clk_buf_props $prop]
					set clk_num [expr {71 + $index}]
					set clocking_node [create_node -n "clocking${index}" -l "clocking${index}" -p $amba_pl_node -d $dts]
					add_prop "${clocking_node}" "status" "okay" string $dts 1
					add_prop "${clocking_node}" "compatible" "xlnx,fclk" string $dts 1
					add_prop "${clocking_node}" "clocks" "zynqmp_clk $clk_num" reference $dts 1
					add_prop "${clocking_node}" "clock-output-names" "fabric_clk" string $dts 1
					add_prop "${clocking_node}" "#clock-cells" 0 int $dts 1
					add_prop "${clocking_node}" "assigned-clocks" "zynqmp_clk $clk_num" reference $dts 1
					set freq [hsi get_property CONFIG.PSU__CRL_APB__PL${index}_REF_CTRL__ACT_FREQMHZ $zynq_periph]
					add_prop "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int $dts 1
				}
			}

			set afi_ip [hsi::get_cells -hier -filter {IP_NAME==psu_afi}]
			if {[llength $afi_ip] > 0} {
				set node [create_node -l "afi0" -n "afi0" -p $amba_pl_node -d "pl.dtsi"]
				add_prop $node "compatible" "xlnx,afi-fpga" string $dts 1
				add_prop $node "status" "okay" string $dts 1
				set config_afi ""
				set prefix ""

				set total_saxigp_data_width_num 7
				for {set data_width_num 0} {$data_width_num < $total_saxigp_data_width_num} {incr data_width_num} {
					if {($data_width_num != 0)} {
						set prefix "<"
					}
					set val [hsi get_property CONFIG.C_SAXIGP${data_width_num}_DATA_WIDTH $zynq_periph]
					if {![string_is_empty $val]} {
						set afival [get_afi_val $val]
						append config_afi " ${prefix}[expr {2*$data_width_num}] $afival>, <[expr {2*$data_width_num + 1}] $afival>,"
					}
				}

				set val [hsi get_property CONFIG.C_MAXIGP0_DATA_WIDTH $zynq_periph]
				set afival0 [get_max_afi_val $val CONFIG.C_MAXIGP0_DATA_WIDTH]

				set val [hsi get_property CONFIG.C_MAXIGP1_DATA_WIDTH $zynq_periph]
				set afival1 [get_max_afi_val $val CONFIG.C_MAXIGP1_DATA_WIDTH]

				if {![string_is_empty $afival0] && ![string_is_empty $afival1]} {
					set afival [expr {$afival0} | {$afival1}]
					set afi_hex [format %x $afival]
					append config_afi " <14 0x$afi_hex>,"
				}

				set val [hsi get_property CONFIG.C_MAXIGP2_DATA_WIDTH $zynq_periph]
				set afival [get_max_afi_val $val CONFIG.C_MAXIGP2_DATA_WIDTH]
				if {![string_is_empty $afival]} {
					append config_afi " <15 $afival"
				}

				add_prop "${node}" "config-afi" "$config_afi" special $dts
				set resets "zynqmp_reset 116>, <&zynqmp_reset 117>, <&zynqmp_reset 118>, <&zynqmp_reset 119"
				add_prop "${node}" "resets" "$resets" reference $dts
			}
		} 
		if {[string match -nocase $family "versal"]} {
			set hw_name [::hsi::get_hw_files -filter "TYPE == pl_pdi"]
			if {![llength $hw_name]}  {
				set hw_name [::hsi::get_hw_files -filter "TYPE == pdi"]
			}
			add_prop $amba_pl_node "firmware-name" "$hw_name" string $dts 1
		}
		if {[string match -nocase $family "zynq"]} {
			set hw_name [::hsi::get_hw_files -filter "TYPE == bit"]
			add_prop $amba_pl_node "firmware-name" "$hw_name.bin" string $dts 1
			set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == processing_system7}]
			set avail_param [common::list_property [hsi::get_cells -hier $zynq_periph]]
			set pl_clk_buf_props "CONFIG.PCW_FPGA_FCLK0_ENABLE CONFIG.PCW_FPGA_FCLK1_ENABLE CONFIG.PCW_FPGA_FCLK2_ENABLE CONFIG.PCW_FPGA_FCLK3_ENABLE"
			foreach prop ${pl_clk_buf_props} {
				if {[lsearch -nocase $avail_param $prop] >= 0} {
					set val [hsi::get_property $prop [hsi::get_cells -hier $zynq_periph]]
					if {[string match -nocase $val "1"]} {
						set index [lsearch $pl_clk_buf_props $prop]
						set clk_num [expr {15 + $index}]
						set clocking_node [create_node -n "clocking${index}" -l "clocking${index}" -p $amba_pl_node -d $dts]
						add_prop "${clocking_node}" "compatible" "xlnx,fclk" string $dts 1
						add_prop "${clocking_node}" "clocks" "clkc $clk_num" reference $dts 1
						add_prop "${clocking_node}" "clock-output-names" "fabric_clk" string $dts 1
						add_prop "${clocking_node}" "#clock-cells" 0 int $dts 1
						add_prop "${clocking_node}" "assigned-clocks" "clkc $clk_num" reference $dts 1
						set freq [hsi::get_property CONFIG.PCW_FPGA${index}_PERIPHERAL_FREQMHZ [hsi::get_cells -hier $zynq_periph]]
						add_prop "${clocking_node}" "assigned-clock-rates" [scan [expr $freq * 1000000] "%d"] int $dts 1
					}
				}
			}

			set pl_afi_buf_props "CONFIG.C_USE_S_AXI_HP0 CONFIG.C_USE_S_AXI_HP1 CONFIG.C_USE_S_AXI_HP2 CONFIG.C_USE_S_AXI_HP3"
			foreach prop ${pl_afi_buf_props} {
				if {[lsearch -nocase $avail_param $prop] >= 0} {
					set val [hsi::get_property $prop [hsi::get_cells -hier $zynq_periph]]
					if {[string match -nocase $val "1"]} {
						set index [lsearch $pl_afi_buf_props $prop]
						set afi [hsi::get_cells -hier -filter "NAME==ps7_afi_${index}"]
						set afi_param [common::list_property [hsi::get_cells -hier "$afi"]]
						if {[lsearch -nocase $afi_param "CONFIG.C_S_AXI_BASEADDR"] >= 0} {
							set base_addr [hsi::get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $afi]]
						}
						if {[lsearch -nocase $afi_param "CONFIG.C_S_AXI_HIGHADDR"] >= 0} {
							set high_addr [hsi::get_property CONFIG.C_S_AXI_HIGHADDR [hsi::get_cells -hier $afi]]
						}
						set size [format 0x%x [expr {${high_addr} - ${base_addr} + 1}]]
						set reg "$base_addr $size"
						regsub -all {^0x} $base_addr {} addr
						set addr [string tolower $addr]
						set node [create_node -l "afi${index}" -n "afi${index}" -u $addr -p $amba_pl_node -d "pl.dtsi"]
						add_prop $node "compatible" "xlnx,afi-fpga" string $dts 1
						add_prop $node "#address-cells" "1" int $dts 1
						add_prop $node "#size-cells" "0" int $dts 1
						add_prop $node "status" "okay" string $dts 1
						add_prop $node "reg" "$reg" hexlist $dts 1
						if {[lsearch -nocase $avail_param "CONFIG.C_S_AXI_HP${index}_DATA_WIDTH"] >= 0} {
							set val [hsi::get_property CONFIG.C_S_AXI_HP${index}_DATA_WIDTH [hsi::get_cells -hier $zynq_periph]]
							set bus_width [get_axi_datawidth $val]
							add_prop $node "xlnx,afi-width" "$bus_width" int $dts 1
						}
					}
				}
			}
		}
		set pr_regions [hsi::get_cells -hier -filter BD_TYPE==BLOCK_CONTAINER]
		foreach rp $pr_regions {
			set intf_pins [::hsi::get_intf_pins -of_objects $rp]
			set fpga_inst [regexp -inline {\d+} $rp]
			set pr_node [create_node -l "fpga_PR$fpga_inst" -n "fpga-PR$fpga_inst" -p $amba_pl_node -d $dts]
			add_prop "${pr_node}" "compatible" "fpga-region" string $dts 1
			add_prop "${pr_node}" "#address-cells" 2 int $dts 1
			add_prop "${pr_node}" "#size-cells" 2 int $dts 1
			add_prop "${pr_node}" "ranges" "" boolean $dts 1
			foreach intf $intf_pins {
				set connectip [get_connected_stream_ip [::hsi::get_cells -hier $rp] $intf]
				if {[llength $connectip]} {
					if { [::hsi::get_property IP_NAME $connectip] in { "dfx_decoupler" "dfx_axi_shutdown_manager" } } {
						dict set rp_region_dict $rp $connectip
						set is_bridge_en 1
					}
				}
			}
		}
	}
	
}

proc gen_include_dtfile {args} {
	set kernel_dtsi [lindex $args 0]
	set outdir_path [lindex $args 1]
	set fp [open $kernel_dtsi r]
	set file_data [read $fp]
	set data [split $file_data "\n"]
	set include_regexp {^#include \".*\.dts.*\"$}
	foreach line $data {
		if {[regexp $include_regexp $line matched]} {
			set include_dt [lindex [split $line " "] 1]
			regsub -all " |\t|;|\"" $include_dt {} include_dt
			foreach file [glob [file normalize [file dirname ${kernel_dtsi}]/*]] {
				# NOTE: ./ works only if we did not change our directory
				if {[regexp $include_dt $file match]} {
					file copy -force $file ${outdir_path}/
					gen_include_dtfile $file ${outdir_path}/
					break
				}
			}
		}
	}
}

proc get_sem_property { prop } {
	set pspmcCell [hsi::get_cells -hier -filter "IP_NAME==pspmc"]
	if {$pspmcCell eq ""} {
		set pspmcCell [hsi::get_cells -hier -filter "IP_NAME==pmcps"]
	}
	if {$pspmcCell eq ""} {
		set pspmcCell [hsi::get_cells -hier -filter "IP_NAME==psxl"]
	}
	if {$pspmcCell eq ""} {
		set pspmcCell [hsi::get_cells -hier -filter {IP_NAME==ps11 || IP_NAME==ps11xgui || IP_NAME==psxt}]
	}
	if {$pspmcCell ne ""} {
		set readconfig [common::get_property $prop $pspmcCell]
		set readconfig [lindex $readconfig 0]
		return $readconfig
	} else {
		set cipsCell [hsi::get_cells -hier -filter "IP_NAME==versal_cips"]
		if {$cipsCell ne ""} {
			set isHierIp [common::get_property IS_HIERARCHICAL $cipsCell]
			if {$isHierIp} {
				set ps_pmc_config [common::get_property CONFIG.PS_PMC_CONFIG $cipsCell]
				set prop_exists [dict get $ps_pmc_config $prop]
				if {$prop_exists} {
					return [dict get $ps_pmc_config $prop]
				} else {
					return 0
				}
			} else {
				return [common::get_property $prop $cipsCell]
			}
		}
		return 0
	}
	return 0
}

proc gen_pss_ref_clk_freq {drv_handle node ip_name} {
	set pss_ref_clk_mhz ""
	if {[string match -nocase $ip_name "psu_pmu"]} {
		set ps_periph [hsi::get_cells -hier zynq_ultra_ps_e_0]
		if { [llength $ps_periph] == 1} {
			set pss_ref_clk_mhz [common::get_property "CONFIG.PSU__PSS_REF_CLK__FREQMHZ" $ps_periph]
		} else {
			puts "WARNING: CONFIG.PSU__PSS_REF_CLK__FREQMHZ not found. Using default value for XPAR_PSU_PSS_REF_CLK_FREQ_HZ."
			set pss_ref_clk_mhz 33333000
		}
	} else {
		set pss_ref_clk_mhz [common::get_property CONFIG.C_PSS_REF_CLK_FREQ $drv_handle]
		if { $pss_ref_clk_mhz == "" } {
			puts "WARNING: CONFIG.C_PSS_REF_CLK_FREQ not found. Using default value for XPAR_PSU_PSS_REF_CLK_FREQ_HZ."
			set pss_ref_clk_mhz 33333000
		}
	}
	if {![string_is_empty $pss_ref_clk_mhz]} {
		if {[llength [split $pss_ref_clk_mhz "."]] > 1} {
			set pss_ref_clk_mhz [scan [expr $pss_ref_clk_mhz * 1000000] %d]
		}
	        add_prop $node "xlnx,pss-ref-clk-freq" $pss_ref_clk_mhz int "pcw.dtsi"
	}
}

proc gen_board_info {} {
	global env
	global is_versal_net_platform
	global is_versal_2ve_2vm_platform
	global is_versal_2ve_2vm_small_platform
	set path $env(CUSTOM_SDT_REPO)
	set default_dts "system-top.dts"
	set common_file "$path/device_tree/data/config.yaml"
	set kernel_ver [get_user_config $common_file -kernel_ver]
	set dtsi_file [get_user_config $common_file -board_dts]
	set dir_path [get_user_config $common_file -dir]
	set device [hsi get_property DEVICE [hsi::current_hw_design]]
	set ddr5_handle [hsi::get_cells -hier -filter {IP_NAME==noc_mc_ddr5}]
	add_prop "root" "device_id" "${device}" string $default_dts

	set family [get_hw_family]
	switch $family {
		"versal" {
			if {$is_versal_2ve_2vm_platform} {
				set family "Versal_2VE_2VM"
			} elseif {$is_versal_net_platform} {
				set family "VersalNet"
			} else {
				set family "Versal"
			}
		}
		"zynqmp" {
			set family "ZynqMP"
		}
		"zynq" {
			set family "Zynq"
		}
		"microblaze" {
			set family "microblaze"
			add_prop "root" "model" "Microblaze" string $default_dts
			set mb_riscv_proc [hsi::get_cells -hier -filter {IP_NAME==microblaze_riscv}]
			if {[llength $mb_riscv_proc]} {
				add_prop "root" "model" "Microblaze RISCV" string $default_dts 1
				set family "microblaze_riscv"
			}
		}
	}
	add_prop "root" "family" "${family}" string $default_dts

	set variant ""
	if {$family in {"microblaze" "microblaze_riscv"}} {
		set mb_cpu_handle [lindex [hsi get_cells -hier -filter IP_NAME==$family] 0]
		set variant [get_ip_property $mb_cpu_handle CONFIG.C_FAMILY]
		switch $device {
			"xcsu200p" - "xcsu150p" {
				set variant spartanuplusaes1
			}
			"xcsu50p" {
				set variant spartanuplusb
			}
			"xcsu60p" {
				set variant spartanuplusf
			}
		}
		if {[regexp "spartanuplus.*" "$variant" match] && ($variant != "spartanuplus")} {
			set variant "spartanuplus $variant"
		}
	}

	if {$is_versal_2ve_2vm_small_platform} {
		set variant "Versal_2VE_2VM_Small"
	}

	switch $device {
		"xc2vp3602" {
			set variant "Versal_2VP"
		}
		"xc2vp3202" {
			set variant "Versal_2VP_P"
		}
	}

	if {![string_is_empty $variant]} {
		add_prop "root" "variant" $variant stringlist system-top.dts 1
	}

	if {[llength $ddr5_handle] > 0} {
	   foreach ddr5_cell $ddr5_handle {
		   set ddr_type [hsi::get_property CONFIG.DDRMC5_DEVICE_TYPE $ddr5_cell]
		   if {$ddr_type eq "RDIMMs" || $ddr_type eq "UDIMMs"} {
			   add_prop "root" "xlnx,ddrmc5-device-type" $ddr_type string $default_dts
			   break
                   }
	   }
	}

	if {[hsi get_current_part] != ""} {
		set slrcount [common::get_property NUM_OF_SLRS [hsi get_current_part]]
		if {$slrcount != -1} {
			add_prop "root" "slrcount" $slrcount int $default_dts
		}
		set speed_grade [common::get_property SPEEDGRADE [hsi current_hw_design]]
		regsub -all {^-} $speed_grade {} speed_grade
		if {$speed_grade != ""} {
			add_prop "root" "speed_grade" "${speed_grade}" string $default_dts
		}
	}
	set sem_mem_scan [get_sem_property CONFIG.SEM_MEM_SCAN]
	set sem_npi_scan [get_sem_property CONFIG.SEM_NPI_SCAN]
	if {$sem_mem_scan != 0} {
		add_prop "root" "semmem-scan" $sem_mem_scan int $default_dts
	}
	if {$sem_npi_scan != 0} {
		add_prop "root" "semnpi-scan" $sem_npi_scan int $default_dts
	}
	set boardname [get_board_name]
	if { [string length $boardname] != 0 } {
		set fields [split $boardname ":"]
		lassign $fields prefix board suffix
		if { [string length $board] != 0 } {
			if {$dtsi_file eq ""} {
				add_prop "root" "compatible" "xlnx,${board}" string $default_dts
			}
			add_prop "root" "board" "${board}" string $default_dts
		}
	}
	if {[file exists $dtsi_file]} {
		set dir $dir_path
		set pathtype [file pathtype $dtsi_file]
		if {[string match -nocase $pathtype "relative"]} {
			dtg_warning "checking file:$dtsi_file  pwd:$dir"
			#Get the absolute path from relative path
			set dtsi_file [file normalize $dtsi_file]
		}
		file copy -force $dtsi_file $dir_path
		update_system_dts_include [file tail $dtsi_file]
		return
	}
	set dts_name $dtsi_file

	if {[llength $dts_name] == 0} {
		return
	}

	set kernel_dtsi [file normalize "$path/device_tree/data/kernel_dtsi/${kernel_ver}/BOARD"]
	if {[file exists $kernel_dtsi]} {
		set valid_board_file 0
		foreach file [glob [file normalize [file dirname ${kernel_dtsi}]/BOARD/*]] {
			set dtsi_name "$dts_name.dtsi"
			# NOTE: ./ works only if we did not change our directory
			if {[regexp $dtsi_name $file match]} {
				file copy -force $file $dir_path
				update_system_dts_include [file tail $file]
				set valid_board_file 1
				gen_include_dtfile "${file}" "${dir_path}"
				break
			}
		}
		if {$valid_board_file == 0} {
			error "Error:$dtsi_name board file is not present in DTG. Please add a valid board."
		}
	} else {
		puts "$kernel_dtsi folder is not found"
	}
}

proc gen_zynqmp_ccf_clk {} {
	set ps_wrapper [hsi get_cells -hier -filter {IP_NAME==zynq_ultra_ps_e}]
	if {[llength $ps_wrapper] == 0} {
		return
	}
	set default_dts "pcw.dtsi"
	set periph_list [hsi::get_cells -hier]
	foreach periph $periph_list {
		set zynq_ultra_ps [hsi get_property IP_NAME $periph]
		if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
			set avail_param [hsi list_property [hsi::get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PSU__PSS_REF_CLK__FREQMHZ"] >= 0} {
				set freq [hsi get_property CONFIG.PSU__PSS_REF_CLK__FREQMHZ [hsi::get_cells -hier $periph]]
				if {[string match -nocase $freq "33.333"]} {
					return
				} else {
					dtg_warning "Frequency $freq used instead of 33.333"
					set ccf_node [create_node -n "&pss_ref_clk" -d $default_dts -p root]
					add_prop ${ccf_node} "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
				}
			}
		}
	}
       set periph_list [hsi::get_cells -hier]
       foreach periph $periph_list {
               set zynq_ultra_ps [hsi get_property IP_NAME $periph]
               if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
                       set avail_param [hsi list_property [hsi::get_cells -hier $periph]]
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ"] >= 0} {
                               set freq [hsi get_property CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $freq "27"]} {
                                       return
                               } else {
                                       dtg_warning "Frequency $freq used instead of 27.00"
                                       set ccf_node [create_node -n "&video_clk" -d $default_dts -p root]
                                       add_prop "${ccf_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                               }
                       }
               }
       }

}

proc gen_versal_clk {} {
	set ps_wrapper [hsi get_cells -hier -filter {IP_NAME==ps_wizard || IP_NAME==versal_cips || IP_NAME==pspmc}]
	if {[llength $ps_wrapper] == 0} {
		return
	}
       set default_dts "pcw.dtsi"
       set periph_list [hsi::get_cells -hier]
       foreach periph $periph_list {
               set versal_ps [hsi get_property IP_NAME $periph]
               if { $versal_ps in { "ps_wizard" }} {
			set ps_wizard_params [hsi get_property CONFIG.PS_PMC_CONFIG [hsi get_cells -hier $periph]]
			if {[llength $ps_wizard_params ]} {
				if {[dict exists $ps_wizard_params "PMC_REF_CLK_FREQMHZ"]} {
					set freq [dict get $ps_wizard_params PMC_REF_CLK_FREQMHZ]
					if {![string match -nocase $freq "33.333"]} {
						dtg_warning "Frequency $freq used instead of 33.333"
						set ref_node [create_node -n "&ref" -d $default_dts -p root]
						add_prop "${ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
					}
				}
				if {[dict exists $ps_wizard_params "PMC_PL_ALT_REF_CLK_FREQMHZ"]} {
					set freq [dict get $ps_wizard_params PMC_PL_ALT_REF_CLK_FREQMHZ]
					if {![string match -nocase $freq "33.333"]} {
						dtg_warning "Frequency $freq used instead of 33.333"
						set pl_alt_ref_node [create_node -n "&pl_alt_ref" -d $default_dts -p root]
						add_prop "${pl_alt_ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
					}
				}
			}
		}
               if { $versal_ps in { "versal_cips" } } {
                       set ver [get_comp_ver $periph]
                       if {$ver < 3.0} {
                               set avail_param [hsi list_property [hsi get_cells -hier $periph]]
                               if {[lsearch -nocase $avail_param "CONFIG.PMC_REF_CLK_FREQMHZ"] >= 0} {
                                       set freq [hsi get_property CONFIG.PMC_REF_CLK_FREQMHZ [hsi get_cells -hier $periph]]
                                       if {![string match -nocase $freq "33.333"]} {
                                               dtg_warning "Frequency $freq used instead of 33.333"
                                               set ref_node [create_node -n "&ref" -d $default_dts -p root]
                                               add_prop "${ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                                       }
                               }
                               if {[lsearch -nocase $avail_param "CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ"] >= 0} {
                                       set freq [hsi get_property CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ [hsi get_cells -hier $periph]]
                                       if {![string match -nocase $freq "33.333"]} {
                                               dtg_warning "Frequency $freq used instead of 33.333"
                                               set pl_alt_ref_node [create_node -n "&pl_alt_ref" -d $default_dts -p root]
                                               add_prop "${pl_alt_ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                                       }
                               }
                       }
               }
               if {[string match -nocase $versal_ps "pspmc"] } {
                       set avail_param [hsi list_property [hsi::get_cells -hier $periph]]
                       if {[lsearch -nocase $avail_param "CONFIG.PMC_REF_CLK_FREQMHZ"] >= 0} {
                               set freq [hsi get_property CONFIG.PMC_REF_CLK_FREQMHZ [hsi::get_cells -hier $periph]]
                               if {![string match -nocase $freq "33.333"]} {
                                       dtg_warning "Frequency $freq used instead of 33.333"
                                       set ref_node [create_node -n "&ref" -d $default_dts -p root]
                                       add_prop "${ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ"] >= 0} {
                               set freq [hsi get_property CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ [hsi::get_cells -hier $periph]]
                               if {![string match -nocase $freq "33.333"]} {
                                       dtg_warning "Frequency $freq used instead of 33.333"
                                       set pl_alt_ref_node [create_node -n "&pl_alt_ref" -d $default_dts -p root]
                                       add_prop "${pl_alt_ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int $default_dts
                               }
                       }
               }
       }

}

proc gen_opp_freq {} {
	set default_dts "pcw.dtsi"
	set periph_list [hsi get_cells -hier]
	set opp_freq ""
	set add_opp_prop ""
	foreach periph $periph_list {
		set proc_ps [hsi get_property IP_NAME $periph]
		if {[string match -nocase $proc_ps "zynq_ultra_ps_e"] } {
			set avail_param [hsi list_property [hsi get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ"] >= 0} {
				set act_freq ""
				set div ""
				if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ"] >= 0} {
					set act_freq [hsi get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ [hsi get_cells -hier $periph]]
				}
				if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0"] >= 0} {
					set div [hsi get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0 [hsi get_cells -hier $periph]]
				}
				if {[llength $act_freq] && [llength $div]} {
					set opp_freq [expr ceil([expr ($act_freq * $div) ]) * 1000000]
				}
				# if design don't have clock configs then skip adding new opps
				if {$opp_freq == ""} {
					return
				}
				set cpu_opp_table [create_node -n "&cpu_opp_table" -d $default_dts -p root]
				# Remove default opps
				add_prop "$cpu_opp_table" "/delete-node/ opp00" "" boolean $default_dts
				add_prop "$cpu_opp_table" "/delete-node/ opp01" "" boolean $default_dts
				add_prop "$cpu_opp_table" "/delete-node/ opp02" "" boolean $default_dts
				add_prop "$cpu_opp_table" "/delete-node/ opp03" "" boolean $default_dts
			}
		}
		if { $proc_ps in { "versal_cips" "ps_wizard" }} {
			set ps_pmc_params [hsi get_property CONFIG.PS_PMC_CONFIG [hsi get_cells -hier $periph]]
			set ps_pmc_params_int [hsi get_property CONFIG.PS_PMC_CONFIG_INTERNAL [hsi get_cells -hier $periph]]
			if {[llength $ps_pmc_params ] || [llength $ps_pmc_params_int] } {
				set act_freq ""
				set div ""

                                if {[dict exists $ps_pmc_params "PS_CRF_ACPU_CTRL_ACT_FREQMHZ"]} {
					set act_freq [dict get $ps_pmc_params PS_CRF_ACPU_CTRL_ACT_FREQMHZ]
				} elseif {[dict exists $ps_pmc_params_int "PS_CRF_ACPU_CTRL_ACT_FREQMHZ"]} {
					set act_freq [dict get $ps_pmc_params_int PS_CRF_ACPU_CTRL_ACT_FREQMHZ]
				}

                                if {[dict exists $ps_pmc_params "PS_CRF_ACPU_CTRL_DIVISOR0"]} {
					set div [dict get $ps_pmc_params PS_CRF_ACPU_CTRL_DIVISOR0]
				} elseif {[dict exists $ps_pmc_params_int "PS_CRF_ACPU_CTRL_DIVISOR0"] && \
					[dict get $ps_pmc_params_int PS_CRF_ACPU_CTRL_DIVISOR0] > 0} {
					set div [dict get $ps_pmc_params_int PS_CRF_ACPU_CTRL_DIVISOR0]
				}

				if {[llength $act_freq] && [llength $div]} {
					set opp_freq [expr ceil([expr ($act_freq * $div) ]) * 1000000]
				}
				# if design don't have clock configs then skip adding new opps
				if {$opp_freq == ""} {
					return
				}
			}
			set cpu_opp_table [create_node -n "&cpu_opp_table" -d $default_dts -p root]
			# Remove default opps
			add_prop "$cpu_opp_table" "/delete-node/ opp00" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp01" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp02" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp03" "" boolean $default_dts
		}
		if {[string match -nocase $proc_ps "psx_wizard"] } {
			#NOTE: CONFIG.PSX_PMCX_CONFIG_INTERNAL this may change
			set psx_pmcx_params [hsi get_property CONFIG.PSX_PMCX_CONFIG_INTERNAL [hsi get_cells -hier $periph]]
			if {[llength $psx_pmcx_params]} {
				set act_freq ""
				set div ""
				if {[dict exists $psx_pmcx_params "PSX_CRF_ACPU0_CTRL_ACT_FREQMHZ"]} {
					set act_freq [dict get $psx_pmcx_params PSX_CRF_ACPU0_CTRL_ACT_FREQMHZ]
				}
				if {[dict exists $psx_pmcx_params "PSX_CRF_ACPU0_CTRL_DIVISOR0"] && \
					[dict get $psx_pmcx_params PSX_CRF_ACPU0_CTRL_DIVISOR0] > 0} {
					set div [dict get $psx_pmcx_params PSX_CRF_ACPU0_CTRL_DIVISOR0]
				}
                                if {[llength $act_freq] && [llength $div]} {
					set opp_freq [expr ceil([expr ($act_freq * $div)]) * 1000000]
				}
			}
			# if design don't have clock configs then skip adding new opps
			if {$opp_freq == ""} {
				return
			}
			set cpu_opp_table [create_node -n "&cpu_opp_table" -d $default_dts -p root]
			# Remove default opps
			add_prop "$cpu_opp_table" "/delete-node/ opp-1066000000" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp-1866000000" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp-1900000000" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp-1999000000" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp-2050000000" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp-2100000000" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp-2200000000" "" boolean $default_dts
			add_prop "$cpu_opp_table" "/delete-node/ opp-2400000000" "" boolean $default_dts
		}
	}

	if {[llength $opp_freq]} {
		set opp00_result [expr round([expr $opp_freq / 1])]
		set opp01_result [expr round([expr $opp_freq / 2])]
		set opp02_result [expr round([expr $opp_freq / 3])]
		set opp03_result [expr round([expr $opp_freq / 4])]
		set opp00 "/bits/ 64 <$opp00_result>"
		set opp01 "/bits/ 64 <$opp01_result>"
		set opp02 "/bits/ 64 <$opp02_result>"
		set opp03 "/bits/ 64 <$opp03_result>"
		set opp_microvolt "<1000000>"
		set clock_latency "<500000>"
		# Create opp table as per dt-bindings
		set opp00_table [create_node -n "opp-${opp00_result}" -d $default_dts -p $cpu_opp_table]
		add_prop "$opp00_table" "opp-hz" $opp00 noformating $default_dts
		add_prop "$opp00_table" "opp-microvolt" $opp_microvolt noformating $default_dts
		add_prop "$opp00_table" "clock-latency-ns" $clock_latency noformating $default_dts
		set opp01_table [create_node -n "opp-${opp01_result}" -d $default_dts -p $cpu_opp_table]
		add_prop "$opp01_table" "opp-hz" $opp01 noformating $default_dts
		add_prop "$opp01_table" "opp-microvolt" $opp_microvolt noformating $default_dts
		add_prop "$opp01_table" "clock-latency-ns" $clock_latency noformating $default_dts
		set opp02_table [create_node -n "opp-${opp02_result}" -d $default_dts -p $cpu_opp_table]
		add_prop "$opp02_table" "opp-hz" $opp02 noformating $default_dts
		add_prop "$opp02_table" "opp-microvolt" $opp_microvolt noformating $default_dts
		add_prop "$opp02_table" "clock-latency-ns" $clock_latency noformating $default_dts
		set opp03_table [create_node -n "opp-${opp03_result}" -d $default_dts -p $cpu_opp_table]
		add_prop "$opp03_table" "opp-hz" $opp03 noformating $default_dts
		add_prop "$opp03_table" "opp-microvolt" $opp_microvolt noformating $default_dts
		add_prop "$opp03_table" "clock-latency-ns" $clock_latency noformating $default_dts
	}
}

proc gen_zynqmp_pinctrl {} {
	set ps_wrapper [hsi get_cells -hier -filter IP_NAME==zynq_ultra_ps_e]
	global env
	if {[llength $ps_wrapper] == 0} {
		return
	}
       set default_dts "pcw.dtsi"
       set periph_list [hsi::get_cells -hier]
       foreach periph $ps_wrapper {
               set zynq_ultra_ps [hsi get_property IP_NAME $periph]
               if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
                       set avail_param [hsi list_property [hsi::get_cells -hier $periph]]
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__UART1__PERIPHERAL__IO"] >= 0} {
                               set uart1_io [hsi get_property CONFIG.PSU__UART1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $uart1_io "EMIO"]} {
                               	       dtg_warning "EMIO support for UART1 PERIPHERAL is not yet available in SDT. Please manually edit the device tree"
                               	       # FIXME : Add the support with DTG as reference
                               	       # set pinctrl_node [create_node -n "&pinctrl0" -d $default_dts -p root]
                                       # set pinctrl_uart1_default [create_node -n "uart1-default" -d $default_dts -p $pinctrl_node]
                                       # add_prop "$pinctrl_uart1_default" "/delete-node/ mux" "" boolean $default_dts
                                       # add_prop "$pinctrl_uart1_default" "/delete-node/ conf" "" boolean $default_dts
                                       # add_prop "$pinctrl_uart1_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       # add_prop "$pinctrl_uart1_default" "/delete-node/ conf-tx" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__UART0__PERIPHERAL__IO"] >= 0} {
                               set uart0_io [hsi get_property CONFIG.PSU__UART0__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $uart0_io "EMIO"]} {
                               	       dtg_warning "EMIO support for UART0 PERIPHERAL is not yet available in SDT. Please manually edit the device tree"
                               	       # FIXME : Add the support with DTG as reference
                               	       # set pinctrl_node [create_node -n "&pinctrl0" -d $default_dts -p root]
                                       # set pinctrl_uart0_default [create_node -n "uart0-default" -d $default_dts -p $pinctrl_node]
                                       # add_prop "$pinctrl_uart0_default" "/delete-node/ mux" "" boolean $default_dts
                                       # add_prop "$pinctrl_uart0_default" "/delete-node/ conf" "" boolean $default_dts
                                       # add_prop "$pinctrl_uart0_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       # add_prop "$pinctrl_uart0_default" "/delete-node/ conf-tx" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__CAN1__PERIPHERAL__IO"] >= 0} {
                               set can1_io [hsi get_property CONFIG.PSU__CAN1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $can1_io "EMIO"]} {
                               	       dtg_warning "EMIO support for CAN1 PERIPHERAL is not yet available in SDT. Please manually edit the device tree"
                               	       # FIXME : Add the support with DTG as reference
                               	       # set pinctrl_node [create_node -n "&pinctrl0" -d $default_dts -p root]
                                       # set pinctrl_can1_default [create_node -n "can1-default" -d $default_dts -p $pinctrl_node]
                                       # add_prop "$pinctrl_can1_default" "/delete-node/ mux" "" boolean $default_dts
                                       # add_prop "$pinctrl_can1_default" "/delete-node/ conf" "" boolean $default_dts
                                       # add_prop "$pinctrl_can1_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       # add_prop "$pinctrl_can1_default" "/delete-node/ conf-tx" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__SD1__PERIPHERAL__IO"] >= 0} {
                               set sd1_io [hsi get_property CONFIG.PSU__SD1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $sd1_io "EMIO"]} {
                               	       dtg_warning "EMIO support for SD1 PERIPHERAL is not yet available in SDT. Please manually edit the device tree"
                               	       # FIXME : Add the support with DTG as reference
                               	       # set pinctrl_node [create_node -n "&pinctrl0" -d $default_dts -p root]
                                       # set pinctrl_sdhci1_default [create_node -n "sdhci1-default" -d $default_dts -p $pinctrl_node]
                                       # add_prop "$pinctrl_sdhci1_default" "/delete-node/ mux" "" boolean $default_dts
                                       # add_prop "$pinctrl_sdhci1_default" "/delete-node/ conf" "" boolean $default_dts
                                       # add_prop "$pinctrl_sdhci1_default" "/delete-node/ conf-cd" "" boolean $default_dts
                                       # add_prop "$pinctrl_sdhci1_default" "/delete-node/ mux-cd" "" boolean $default_dts
                                       # add_prop "$pinctrl_sdhci1_default" "/delete-node/ conf-wp" "" boolean $default_dts
                                       # add_prop "$pinctrl_sdhci1_default" "/delete-node/ mux-wp" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__ENET3__PERIPHERAL__IO"] >= 0} {
                               set gem3_io [hsi get_property CONFIG.PSU__ENET3__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $gem3_io "EMIO"]} {
                               	       dtg_warning "EMIO support for ENET3 PERIPHERAL is not yet available in SDT. Please manually edit the device tree."
                               	       # FIXME : Add the support with DTG as reference
                               	       # set pinctrl_node [create_node -n "&pinctrl0" -d $default_dts -p root]
                                       # set pinctrl_gem3_default [create_node -n "gem3-default" -d $default_dts -p $pinctrl_node]
                                       # add_prop "$pinctrl_gem3_default" "/delete-node/ mux" "" boolean $default_dts
                                       # add_prop "$pinctrl_gem3_default" "/delete-node/ conf" "" boolean $default_dts
                                       # add_prop "$pinctrl_gem3_default" "/delete-node/ conf-rx" "" boolean $default_dts
                                       # add_prop "$pinctrl_gem3_default" "/delete-node/ conf-tx" "" boolean $default_dts
                                       # add_prop "$pinctrl_gem3_default" "/delete-node/ conf-mdio" "" boolean $default_dts
                                       # add_prop "$pinctrl_gem3_default" "/delete-node/ mux-mdio" "" boolean $default_dts
                               }
                       }
                       if {[lsearch -nocase $avail_param "CONFIG.PSU__I2C1__PERIPHERAL__IO"] >= 0} {
                               set i2c1_io [hsi get_property CONFIG.PSU__I2C1__PERIPHERAL__IO [hsi::get_cells -hier $periph]]
                               if {[string match -nocase $i2c1_io "EMIO"]} {
                               	       dtg_warning "EMIO support for I2C1 PERIPHERAL is not yet available in SDT. Please manually edit the device tree"
                               	       # FIXME : Add the support with DTG as reference
                               	       # set pinctrl_node [create_node -n "&pinctrl0" -d $default_dts -p root]
                                       # set pinctrl_i2c1_default [create_node -n "i2c1-default" -d $default_dts -p $pinctrl_node]
                                       # add_prop "$pinctrl_i2c1_default" "/delete-node/ mux" "" boolean $default_dts
                                       # add_prop "$pinctrl_i2c1_default" "/delete-node/ conf" "" boolean $default_dts
                                       # set pinctrl_i2c1_gpio [create_node -n "i2c1-gpio" -d $default_dts -p $pinctrl_node]
                                       # add_prop "$pinctrl_i2c1_gpio" "/delete-node/ mux" "" boolean $default_dts
                                       # add_prop "$pinctrl_i2c1_gpio" "/delete-node/ conf" "" boolean $default_dts
                               }
                       }
               }
       }
}

proc move_match_elements_to_top {peri_list pattern} {
	set matchedList {}
	set nonMatchedList {}

	foreach drv_handle $peri_list {
		set ip_name [hsi get_property IP_NAME $drv_handle]
		if {[string match -nocase $pattern $ip_name]} {
			lappend matchedList $drv_handle
		} else {
			lappend nonMatchedList $drv_handle
		}
	}

	set newList [concat $matchedList $nonMatchedList]

	return $newList
}

proc generate_sdt args {
	variable ::sdtgen::namespacelist
	global node_dict
	global nodename_dict
	global ip_type_dict
	global property_dict
	global intr_id_dict
	global comp_ver_dict
	global comp_str_dict
	global cur_hw_design
	global dup_periph_handle
	global microblaze_list
	global microblaze_riscv_list
	global rp_region_dict
	global is_rm_design
	global mb_dict_64_bit
	global is_64_bit_mb
	global baseaddr_dict
	global highaddr_dict
	global processor_ip_list
	global 64_bit_processor_list
	global linear_spi_list
	global cur_hw_iss_data
	global non_val_list
	global non_val_ip_types
	global monitor_ip_exclusion_list
	# For some of the Versal Premium devices, there is a duplication of PS IP cell objects.
	# One set of names starts with pmcps_0_<ip_name> and other with ps_wizard_0_pmcps_0_<ip_name>.
	# Below variables are needed to distinguish the redundant entries.
	global parent_ipi_node_accessed
	set parent_ipi_node_accessed [list]
	set endpoint_proc_dict [dict create]

	set linear_spi_list "psu_qspi_linear ps7_qspi_linear"

	set is_rm_design 0
        if {[llength $args]!= 0} {
                set help_string "sdtgen generate_sdt
Generates system device tree based on args given in:
\tsdtgen set_dt_param -board <board file> -dir <output directory path> -xsa <xsa file>"

                return $help_string
        } 

	global env
	set path [set_sdt_default_repo]
	if {[catch {set path $env(CUSTOM_SDT_REPO)} msg]} {
		set path "."
		set env(CUSTOM_SDT_REPO) $path
	}
	if {[catch {set debug $env(debug)} msg]} {
		set env(debug) "disable"
	}
	if {[catch {set verbose $env(verbose)} msg]} {
                set env(verbose) "disable"
        }
	if {[catch {set trace $env(trace)} msg]} {
		set env(trace) "disable"
	}
	if {[catch {set zocl $env(zocl)} msg]} {
		set env(zocl) "disable"
	}
	if {[catch {set xsa $env(xsa)} msg]} {
		error "ERROR: No xsa provided, please set the xsa with -xsa option"
		return
	}
	if {[catch {set dir $env(dir)} msg]} {
		error "ERROR: SDT Output directory is not set, please set it with -dir option"
		return
	}
	if {![catch {set rm_xsa $env(rm_xsa)} msg ]} {
		set rm_xsa_exist 1
	} else {
		set rm_xsa_exist 0
	}

	source [file join $path "device_tree" "data" "common_proc.tcl"]
	source [file join $path "device_tree" "data" "video_utils.tcl"]
	source [file join $path "device_tree" "data" "xillib_common.tcl"]
	source [file join $path "device_tree" "data" "xillib_hw.tcl"]
	source [file join $path "device_tree" "data" "xillib_internal.tcl"]
	source [file join $path "device_tree" "data" "xillib_sw.tcl"]
	source [file join $path "device_tree" "data" "partial_proc.tcl"]
	source [file join $path "device_tree" "data" "parts_spec.tcl"]
	source [file join $path "device_tree" "data" "pmc_dt.tcl"]

	set common_file "$path/device_tree/data/config.yaml"
	set dir [get_user_config $common_file -dir]
	if [catch { set retstr [file mkdir $dir] } errmsg] {
		error "cannot create directory"
	}

	set cur_hw_design [hsi::get_hw_designs]
	if {[string match -nocase $cur_hw_design ""]} {
		file copy -force $xsa $dir
		set xsa_name [file tail $xsa]
		set xsa_path "$dir/$xsa_name"
		set cur_hw_design [hsi::open_hw_design "$xsa_path"]
		set hw_name [hsi get_property NAME [hsi get_hw_designs ]]
		set iss_file [::hsi::get_hw_files "*.iss"]
		if {![string_is_empty $iss_file]} {
			set cur_hw_iss_file "$dir/$iss_file"
			if {[file exists $cur_hw_iss_file]} {
				set fp [open $cur_hw_iss_file r]
				set cur_hw_iss_data [read $fp]
				set cur_hw_iss_data [::json::json2dict $cur_hw_iss_data]
				is_smmu_en
			}
		}
		file delete -force "$xsa_path"
	}

	if { $::sdtgen::namespacelist == "" } {
		init_proclist
	}

	if {[catch {set dt_domain $env(dt_domain)} msg]} {
	} elseif {$dt_domain == "pmc"} {
		generate_pmc_dt $xsa $dir
		return
	}

	dict set node_dict $cur_hw_design {}
	dict set nodename_dict $cur_hw_design {}
	dict set property_dict $cur_hw_design {}
	dict set comp_ver_dict $cur_hw_design {}
	dict set comp_str_dict $cur_hw_design {}
	dict set ip_type_dict $cur_hw_design {}
	dict set intr_id_dict $cur_hw_design {}
	dict set baseaddr_dict $cur_hw_design {}
	dict set highaddr_dict $cur_hw_design {}

	set list_offiles {}
	set peri_list [hsi::get_cells -hier]
	set peri_list [move_match_elements_to_top $peri_list "axi_intc"]
	set peri_list [move_match_elements_to_top $peri_list "clk_wiz"]
	set peri_list [move_match_elements_to_top $peri_list "clk_wizard"]
	set peri_list [move_match_elements_to_top $peri_list "clkx5_wiz"]

	set proclist [get_valid_proc_list]
	set processor_ip_list [list]
	set 64_bit_processor_list [list]
	set is_64_bit_mb 0

	# TODO: Consolidate this.
	# This can't be merged to the loop running for each cpu.tcl.
	# remove_duplicate_addr uses get_baseaddr and get_baseaddr uses processor_ip_list.
	# Cant move remove_duplicate_addr after cpu tcl processing as gen_mb_interrupt_property
	# is being used inside cpu.tcl which uses dup_periph_handle defined under
	# remove_duplicate_addr.

	foreach procperiph $proclist {
		set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $procperiph]]
		if {[lsearch -exact $processor_ip_list $ip_name] == -1} {
			# If not present, append it to the list
			lappend processor_ip_list $ip_name
		}
	}

	set non_val_list "versal_cips psx_wizard psxl ps_wizard ps11 ps11xgui psxt dmac_slv axi_noc axi_noc2 noc_mc_ddr4 noc_mc_ddr5 ddr3 ddr4 mig_7series hbm noc_nmu noc_nsu noc2_nmu noc2_nsu ila zynq_ultra_ps_e psu_iou_s smart_connect emb_mem_gen xlconcat xlconstant xlslice ilconcat ilconstant ilslice axis_tdest_editor util_reduced_logic noc_nsw noc2_nsw axis_ila pspmc pmcps psv_ocm_ram_0 ocm_ram psv_pmc_qspi_ospi psx_pmc_qspi_ospi pmc_qspi_ospi add_keep_128 c_counter_binary dbg_monmux tsn_endpoint_ethernet_mac_block ${linear_spi_list}"
	set non_val_ip_types "MONITOR BUS PROCESSOR"
	set non_val_list1 "psv_cortexa72 psu_cortexa53 ps7_cortexa9 versal_cips psx_wizard ps_wizard noc_nmu noc_nsu ila psu_iou_s noc_nsw pspmc pmcps"
	set non_val_ip_types1 "MONITOR BUS"

	set_hw_family $proclist
	set_microblaze_list
	set_microblaze_riscv_list
	suppress_hsi_warnings
	get_pl_ip_list

	# Generate properties only once if different instances of the same IP is 
	# having a common base address. (e.g. tmr_inject connected to muliple
	# microblazes). This is to avoid the duplicate node name dtc compilation 
	# error.
	#FIXME: This is a workaround. Need to find a better way to handle this.
	#remove_duplicate_addr $peri_list $non_val_list

	# amba or amba_pl reference needs to be there in pcw.dtsi before
	# getting IP related configs. Thus, running the cpu tcls beforehand
	# helps.
	foreach procperiph $proclist {
		set proc_drv_handle [hsi::get_cells -hier $procperiph]
        	set ip_name [hsi get_property IP_NAME $proc_drv_handle]

        	# For tmr_manager designs, tmr_inject IPs also come as the processor
        	# and tmr_manager doesnt have a driver. It is safe to add this if dict exist check.
        	
        	if { [dict exists $::sdtgen::namespacelist $ip_name] } {
	        	set proc_drv_name [dict get $::sdtgen::namespacelist $ip_name]
			source [file join $path $proc_drv_name "data" "${proc_drv_name}.tcl"]
			${proc_drv_name}_generate $proc_drv_handle
		}
	}

	set no_reg_drv_handle ""

	foreach drv_handle $peri_list {
		set ip_name [get_ip_property $drv_handle IP_NAME]
		set ip_type [get_ip_property $drv_handle IP_TYPE]
		set skip1 0
		if {[string match -nocase $ip_name ""]} {
			set skip1 1
		}
		if {[lsearch -nocase $non_val_list $ip_name] >= 0} {
			set skip1 1
		}
		if {[lsearch -nocase $non_val_ip_types $ip_type] >= 0 &&
		    [lsearch -nocase $monitor_ip_exclusion_list $ip_name] == -1 && ![string match -nocase $ip_name "tmr_inject"]} {
			set skip1 1
		}
		if {[string match -nocase $ip_name "gmii_to_rgmii"]} {
			set skip1 1
		}
		if { [dict exists $dup_periph_handle $drv_handle] } {
			set skip1 1
		}
		if { [string_is_empty [get_baseaddr ${drv_handle}]] && ![string match -nocase $ip_name "mailbox"] } {
			set skip1 1
			lappend no_reg_drv_handle ${drv_handle}
		}
		# There can be ZynqMP designs where psu_sata is part of the hsi get_cells -hier output
		# but not in the hsi get_mem_ranges output which means that it is not mapped to any proc.
		# Status "okay" is being added to SATA nodes in such cases as well. It is leading to the
		# deletion of this node in Linux DT as the node is not mapped in APU address-map and the
		# status is "okay". This deletion leads to failure in applying static overlays that has
		# sata in it. Therefore, avoid generating the reference node and the common properties
		# for sata when it is not mapped to any proc. This will keep the sata node from zynqmp.dtsi
		# as is in the "disabled" state.
		if {[string match -nocase $ip_name "psu_sata"] &&
		      [string_is_empty [hsi get_mem_ranges $drv_handle]]} {
			set skip1 1
		}
		if { $skip1 == 0 } {
			gen_peripheral_nodes $drv_handle "create_node_only"
			gen_reg_property $drv_handle
			gen_compatible_property $drv_handle
			gen_drv_prop_from_ip $drv_handle
			gen_interrupt_property $drv_handle
			gen_clk_property $drv_handle
			#gen_xppu $drv_handle
			gen_power_domains $drv_handle
			gen_domain_data $drv_handle
		}
	}

	# There are few driver's generate procs which require the interrupts and clocks properties
	# of other IPs. So, all the dependent IP props need to be generated before calling that
	# driver's generate proc. These IP includes axi_ethernet, mrmac, tsn and video related
	# drivers.

	foreach drv_handle $peri_list {
		set ip_name [dict get $property_dict $cur_hw_design $drv_handle IP_NAME]
		set ip_type [dict get $property_dict $cur_hw_design $drv_handle IP_TYPE]
		set skip2 0
		if {[lsearch -nocase $proclist $drv_handle] >= 0} {
			set skip2 1
		}
		if {[lsearch -nocase $no_reg_drv_handle $drv_handle] >= 0} {
			set skip2 1
		}
		if {[lsearch -nocase $non_val_list1 $ip_name] >= 0} {
			set skip2 1
		}
		if {[lsearch -nocase $non_val_ip_types1 $ip_type] >= 0 &&
		    [lsearch -nocase $monitor_ip_exclusion_list $ip_name] == -1} {
			set skip2 1
		}
		if { [dict exists $dup_periph_handle $drv_handle] } {
			set skip2 1
		}
		if { $skip2 == 0 || $ip_name in {"axis_switch" "axis_broadcaster"}} {
			if { [dict exists $::sdtgen::namespacelist $ip_name] } {
				set drvname [dict get $::sdtgen::namespacelist $ip_name]
				source [file join $path $drvname "data" "${drvname}.tcl"]
				${drvname}_generate $drv_handle
				if {[lsearch [info procs] ${drvname}_update_endpoints] >= 0} {
					dict set endpoint_proc_dict $drv_handle ${drvname}_update_endpoints
				}
			}
		}
	}

	foreach drv_handle [dict keys $endpoint_proc_dict] {
		set endpoint_proc_name [dict get $endpoint_proc_dict $drv_handle]
		$endpoint_proc_name $drv_handle
	}

	namespace forget ::

	gen_board_info
	gen_part_specific_misc
	gen_afi_node
    	gen_include_headers
        include_custom_dts
	set proctype [get_hw_family]
	set kernel_ver [get_user_config $common_file -kernel_ver]
	if {[string match -nocase $env(zocl) "enable"]} {
		if {$proctype in {"zynq" "zynqmp" "versal"}} {
			source [file join $path "zocl" "data" "zocl.tcl"]
			gen_zocl_node $proctype
		}
	}
    	if {[is_zynqmp_platform $proctype] || [string match -nocase $proctype "versal"]} {
		#gen_sata_laneinfo
		gen_zynqmp_ccf_clk
		gen_versal_clk
		gen_opp_freq
		gen_zynqmp_pinctrl
		if {[string match -nocase $proctype "versal"]} {
			gen_edac_node
			gen_ddrmc_node
		}
    	}

	update_alias
    	update_cpu_node
	gen_r5_trustzone_config
	proc_mapping
	update_chosen
	update_memory_node
	gen_cpu_cluster
	set family $proctype
	#set family [get_hw_family]
	if {[is_zynqmp_platform $family]} {
		set reset_node [create_node -n "&zynqmp_reset" -p root -d "pcw.dtsi"]
		add_prop $reset_node "status" "okay" string "pcw.dtsi"
		set pinctrl_node [create_node -n "&pinctrl0" -p root -d "pcw.dtsi"]
		add_prop $pinctrl_node "status" "okay" string "pcw.dtsi"
	}
	set release [get_user_config $common_file -kernel_ver]
	global dtsi_fname
	if {[string match -nocase $family "versal"] || [string match -nocase $family "zynq"] || [is_zynqmp_platform $family]} {
		set mainline_dtsi [file normalize "$path/device_tree/data/kernel_dtsi/${release}/${dtsi_fname}"]
		global include_list
		set include_dts_list [split $include_list ","]
		foreach file [glob [file normalize [file dirname ${mainline_dtsi}]/*]] {
			set filename [file tail $file]
			if {$filename in $include_dts_list} {
				# NOTE: ./ works only if we did not change our directory
				file copy -force $file $dir
			}
		}
		delete_tree systemdt root
		delete_tree pldt root
		delete_tree pcwdt root
		write_dt systemdt root "$dir/system-top.dts"
		move_match_node_to_top pldt root "misc_clk_*"
		move_match_node_to_top pldt root "afi*"
		move_match_node_to_top pldt root "clocking*"
		move_match_node_to_top pldt root "fpga_PR*"
		write_dt pldt root "$dir/pl.dtsi"
		write_dt pcwdt root "$dir/pcw.dtsi"
		if {$rm_xsa_exist != 0} {
			foreach partial_xsa $rm_xsa {
				pldt destroy
				::struct::tree pldt
				generate_rm_sdt $xsa $partial_xsa $dir
			}
		}
		global set osmap
		if {[info exists osmap]} {
			unset osmap
		}
		
	} else {
		delete_tree systemdt root
		delete_tree pldt root
		write_dt systemdt root "$dir/system-top.dts"
		write_dt pldt root "$dir/pl.dtsi"
		global set osmap
		if {[info exists osmap]} {
			unset osmap
		}
	}
	destroy_tree
}

proc move_match_node_to_top {tree parent match} {
    # Get the children of the parent node
    set children [$tree children $parent]

    foreach child $children {
        # Check if the child matches the condition
        if {[string match $match $child]} {
            # Move the matching child node to the top
	    $tree move $parent 0 $child
        } else {
            # Recursively move matching nodes to the top within the child node
            move_match_node_to_top $tree $child $match
        }
    }
}

proc delete_tree {dttree head} {
	set childs [$dttree children $head]
	foreach child $childs {
		if {[catch {set amba_childs [$dttree children $child]} msg]} {
		} else {
			foreach amba_cchild $amba_childs {
				set val [$dttree getall $amba_cchild]
				if {[string match -nocase $val ""] && [string_is_empty [$dttree children $amba_cchild]]} {
					$dttree delete $amba_cchild
				}
			}
		}
	}
}

proc gen_r5_trustzone_config {} {
        set cortexa72proc [hsi::get_cells -hier -filter {IP_NAME=="psv_cortexa72"}]
        set family [get_hw_family]
        if {[string match -nocase $family "versal"]} {
                set cortexr5proc [hsi::get_cells -hier -filter {IP_NAME=="psv_cortexr5"}]
                set r5proc_name "psv_cortexr5"
                # There are designs in Vivado suite where all PS Wizard IPs are
                # having multiple entries, one starting with pmcps_0_<ip> and one with
                # ps_wizard_0_pmcps_0. Below call fixes the R5 proc list to have two
                # entries for Versal.
                set cortexr5proc [lrange $cortexr5proc 0 1]
        } elseif {[is_zynqmp_platform $family]} {
                set cortexr5proc [hsi::get_cells -hier -filter {IP_NAME=="psu_cortexr5"}]
                set r5proc_name "psu_cortexr5"
        } else {
                set cortexr5proc ""
                set r5proc_name ""
        }
	set rpu_cnt 0
        set slcr_instance [hsi::get_cells -hier -filter { IP_NAME == "psu_iouslcr" }]
	foreach r5proc $cortexr5proc {
		set r5_tz ""
		set r5_access 0
		set cnt 0
		if {[catch {set r5_tz [hsi get_property CONFIG.C_TZ_NONSECURE $r5proc]} msg]} {
		}
		if {$r5_tz == "" || $r5_tz == "0"} {
			set r5_access 0xff
		} else {
			if {[llength $cortexr5proc] > 0} {
				set rpu_tz [string toupper [hsi get_property TRUSTZONE [lindex [hsi::get_mem_ranges \
				[hsi::get_cells -hier $r5proc] *rpu*] 0]]]
				if {[string compare -nocase $rpu_tz "NONSECURE"] == 0} {
					set r5_access [expr int([expr $r5_access + pow(2,$cnt)])]
				}
			}
			incr cnt
			if {[llength $cortexa72proc] == 0 && [llength $slcr_instance] > 0} {
				set iou_slcr_tz [string toupper [hsi get_property TRUSTZONE [lindex [hsi::get_mem_ranges \
				[hsi::get_cells -hier $r5proc] psu_iouslcr_0] 0]]]
				if {([string compare -nocase $iou_slcr_tz "NONSECURE"] == 0)} {
					set r5_access [expr int([expr $r5_access + pow(2,$cnt)])]
				}
			}
	        }
		set rt_node [create_node -n "&${r5proc_name}_${rpu_cnt}" -d "pcw.dtsi" -p root]
		add_prop $rt_node "access-val" $r5_access hexint "pcw.dtsi"
		incr rpu_cnt
	}
}

proc proc_mapping {} {
	global is_versal_net_platform
	global linear_spi_list
	global monitor_ip_exclusion_list
	global 64_bit_processor_list
	global pmc_ip_names
	global plm_supported_ips
	set proctype [get_hw_family]
	set default_dts "system-top.dts"
	set overall_periph_list [hsi::get_cells -hier]

	# For Versal Net designs dmac_mst IP is also coming as a PROCESSOR
	set proc_list [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR && IP_NAME!=dmac_mst}]
	set hier_periph_list [hsi::get_cells -hier -filter {IS_HIERARCHICAL==1}]
	set periphs_list ""
	append periphs_list [hsi::get_cells -hier -filter {IP_TYPE==MEMORY_CNTLR}]
	set family [get_hw_family]
	append periphs_list " [hsi::get_cells -hier -filter { \
		IP_NAME==axi_noc2 || IP_NAME==noc_mc_ddr5 || IP_NAME==axi_noc || IP_NAME==noc_mc_ddr4 || \
		IP_NAME==ddr3 || IP_NAME==ddr4 || IP_NAME==mig_7series}]"
	global dup_periph_handle
	set pmc_scan 0
        foreach val $proc_list {
		set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $val]]
		# For devices where we have multiple PMCs, there can be some wrong mappings for SECONDARY PMCs
		# For versal, it is assumed that there will only be a single PMC for which PLM will be built.
		# Therefore, ignore memmap settings for other PMCs and do it only for primary PMC.
		if {[string match *pmc $iptype]} {
			if {$pmc_scan} {
				continue
			} else {
				set pmc_scan 1
			}
		}
		#puts "$val: [time {
		# When get_mem_ranges output of a processor is a nested list and is too large,
		# after certain number of elements, a ... is observed in the output.
		# Add a join statement to avoid such behavior.
		set periph_list [join [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $val]]]

		set hier_mapped_list [::struct::set intersect $periph_list $hier_periph_list]
		foreach entry $hier_mapped_list {
			set hier_mem_filter \
				"HIER_NAME=~*${entry}/* && \
				( \
					CONFIG.C_BASEADDR=~0x* || \
					CONFIG.C_S_AXI_BASEADDR=~0x* || \
					CONFIG.C_S_AXI_CTRL_BASEADDR=~0x* || \
					CONFIG.AXI_CTRL_BASEADDR=~0x*
				)"
			append periph_list " [hsi::get_cells -hier -filter $hier_mem_filter]"
		}
		foreach periph $periph_list {
			# There can be a custom IP which is appearing in the output of get_mem_ranges
			# but is missing in get_cells -hier. Such IP's base address and high address
			# is generated in Vitis classic via the cpu tcls using xdefine_addr_params_for_ext_intf
			# proc.
			set ip_type [get_ip_property [hsi::get_cells -hier $periph] IP_TYPE]
			set ipname [get_ip_property [hsi::get_cells -hier $periph] IP_NAME]

			# Do not process memory object if the corresponding cell object doesnt have the IP NAME
			if {[string_is_empty $ipname]} {
				continue
			}

			if {($iptype in $pmc_ip_names) && !($ipname in $plm_supported_ips)} {
				continue
			}

			if {[lsearch $overall_periph_list $periph] < 0 || \
				([string match -nocase $ip_type "MONITOR"] && \
					!($ipname in $monitor_ip_exclusion_list))} {
				set base_addr [get_baseaddr $periph "no_prefix"]
				if {[string_is_empty $base_addr]} {
					continue
				}
				set exception_dts [set_drv_def_dts $periph]
				set exception_bus "&amba"
				if {[string match -nocase $exception_dts "pl.dtsi"]} {
					set exception_bus "amba_pl: amba_pl"
				}
				set node [create_node -n ${periph} -l ${periph} -u $base_addr -d ${exception_dts} -p ${exception_bus}]
				gen_reg_property $periph "skip_ps_check"
				add_prop $node "compatible" "${periph}" string ${exception_dts}
				add_prop $node "xlnx,ip-name" "${periph}" string ${exception_dts}
				add_prop $node "xlnx,name" "${periph}" string ${exception_dts}
				add_prop $node status okay string ${exception_dts}
			}
			if {[lsearch $periphs_list $periph] >= 0} {
				set valid_periph "psv_pmc_qspi axi_quad_spi psx_pmc_qspi pmc_qspi axi_emc ${linear_spi_list} tmr_manager"
                              	if {[lsearch $valid_periph $ipname] >= 0} {
                              	} else {
                                	continue
                              	}
                       	}
			if {[string match -nocase $iptype "psv_cortexa72"] && [string match -nocase $ipname "psv_rcpu_gic"]} {
				continue
			}
			if {$iptype in {"psx_cortexa78" "cortexa78"} && $ipname in {"psx_rcpu_gic" "rcpu_gic"}} {
				continue
			}
			if {$iptype in {"psx_cortexr52" "cortexr52"} && $ipname in {"psx_acpu_gic" "acpu_gic"}} {
				continue
			}
			if {[string match -nocase $iptype "psv_cortexr5"] && [string match -nocase $ipname "psv_acpu_gic"]} {
				continue
			}
			if {[string match -nocase $iptype "psu_cortexa53"] && [string match -nocase $ipname "psu_rcpu_gic"]} {
				continue
			}
			if {[string match -nocase $iptype "psu_cortexr5"] && [string match -nocase $ipname "psu_acpu_gic"]} {
				continue
			}
			if {$ipname in {"psv_pmc_qspi_ospi" "psx_pmc_qspi_ospi" "pmc_qspi_ospi"}} {
				continue
			}
			if {$ipname in {"psv_ipi" "psx_ipi" "psu_ipi" "ipi"}} {
				continue
			}
			if {$ipname == "visp_ss"} {
				continue
			}
			if {$ipname == "mutex"} {
				continue
			}
			if {$ipname == "mailbox"} {
				continue
			}
			if {$ipname in {"tsn_endpoint_ethernet_mac_block"}} {
				continue
			}
			set regprop ""
			set addr_64 "0"
			set size_64 "0"
			set base [get_baseaddr $periph "" $val]
			set high [get_highaddr $periph "" $val]
			set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
			if {([regexp -nocase {0x([0-9a-f]{9})} "$base" match] || \
				[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]) && \
				!($val in $64_bit_processor_list)} {
					continue
			}

			if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                            set addr_64 "1"
                            set temp $base
                            set temp [string trimleft [string trimleft $temp 0] x]
                            set len [string length $temp]
                            set rem [expr {${len} - 8}]
                            set high_base "0x[string range $temp $rem $len]"
                            set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                            set low_base [format 0x%08x $low_base]
                        }
                        if {[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]} {
                            set size_64 "1"
                            set temp $mem_size
                            set temp [string trimleft [string trimleft $temp 0] x]
                            set len [string length $temp]
                            set rem [expr {${len} - 8}]
                            set high_size "0x[string range $temp $rem $len]"
                            set low_size "0x[string range $temp 0 [expr {${rem} - 1}]]"
                            set low_size [format 0x%08x $low_size]
                        }
                        if {[string match $regprop ""]} {
                            if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
                                set regprop "$low_base $high_base $low_size $high_size"
                            } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
                                set regprop "${low_base} ${high_base} 0x0 ${mem_size}"
                            } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
                                set regprop "0x0 ${base} 0x0 ${mem_size}"
                            } else {
                                set regprop "0x0 ${base} 0x0 ${mem_size}"
                            }
                        } else {
                            if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
                                append regprop ">, " "<$low_base $high_base $low_size $high_size"
                            } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
                                append regprop ">, " "<${low_base} ${high_base} 0x0 ${mem_size}"
                            } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
                                append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
                            } else {
                                append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
                            }
                        }
			set temp [get_node $periph]
			if {$temp == ""} {
				continue
			}
			set temp [string trimleft $temp "&"]
			set len [llength $temp]
			if {$len > 1} {
				set temp [split $temp ":"]
				set temp [lindex $temp 0]
			}

			if {[string match -nocase $ipname "psv_rcpu_gic"] } {
				set temp "gic_r5"
			} elseif {$ipname in {"psx_rcpu_gic" "rcpu_gic"}} {
				set temp "gic_r52"
				# Incase of R52, the address coming from the xsa seems incorrect
				# hence override the regprop here to reflect properly in address-map
				set regprop "0x0 0xe2000000 0x0 0x10000"
			}

			set pl_ip [is_pl_ip $periph]

			set family [get_hw_family]
			set mem_proc_key_map [dict create]
			dict set mem_proc_key_map "psv_cortexa72" "a53"
			dict set mem_proc_key_map "psu_cortexa53" "a53"
			dict set mem_proc_key_map "psu_cortexr5" "$val"
			dict set mem_proc_key_map "psv_cortexr5" "$val"
			dict set mem_proc_key_map "psx_cortexr52" "$val"
			dict set mem_proc_key_map "cortexr52" "$val"
			dict set mem_proc_key_map "psv_pmc" "pmc"
			dict set mem_proc_key_map "psv_psm" "psm"
			dict set mem_proc_key_map "psu_pmu" "pmu"
			dict set mem_proc_key_map "ps7_cortexa9" "a53"
			dict set mem_proc_key_map "psx_cortexa78" "a53"
			dict set mem_proc_key_map "cortexa78" "a53"
			dict set mem_proc_key_map "psx_pmc" "pmc"
			dict set mem_proc_key_map "pmc" "pmc"
			dict set mem_proc_key_map "psx_psm" "psm"
			dict set mem_proc_key_map "psm" "psm"
			dict set mem_proc_key_map "slv1_psv_pmc" "slv1_pmc"
			dict set mem_proc_key_map "slv2_psv_pmc" "slv2_pmc"
			dict set mem_proc_key_map "slv3_psv_pmc" "slv3_pmc"

			dict set mem_proc_key_map "microblaze" "$val"
			dict set mem_proc_key_map "microblaze_riscv" "$val"
			dict set mem_proc_key_map "asu" "asu"

			if {![catch {set mem_map_key [dict get $mem_proc_key_map $iptype]} msg]} {
				if {[regexp -nocase "pmc_wdt|pmc_wwdt" $periph match] && $mem_map_key != "pmc"} {
					continue
				}
				if {$pl_ip} {
					if { ![dict exists $dup_periph_handle $periph] } {
						set_memmap $temp $mem_map_key $regprop
					} else {
						set_memmap [dict get $dup_periph_handle $periph] $mem_map_key $regprop
					}
				} elseif {[lsearch $linear_spi_list $ipname] < 0} {
					set_memmap $temp $mem_map_key $regprop
				}

				if {[lsearch $linear_spi_list $ipname] >= 0 || $ipname in {"axi_emc"}} {
					set temp [get_node "${periph}_memory"]
					if {[llength $temp] > 1} {
						set temp [lindex [split $temp ":"] 0]
					}
					if {![string_is_empty $temp]} {
						set_memmap $temp $mem_map_key $regprop
					}
				}
			}
		}
	    #}]"
		
	}
}

proc add_skeleton {} {
	global env
	set path $env(CUSTOM_SDT_REPO)

	set common_file "$path/device_tree/data/config.yaml"

	set default_dts "system-top.dts"
	set chosen_node [create_node -n "chosen" -p root -d $default_dts]
}

proc update_chosen {} {
	set default_dts "system-top.dts"
    	set chosen_node [create_node -n "chosen" -d ${default_dts} -p root]
	set alias_node [create_node -n "aliases" -p root -d "system-top.dts"]

	set bootargs ""
    	if {[llength $bootargs]} {
        	append bootargs "earlycon console=ttyPS0,115200 clk_ignore_unused init_fatal_sh=1"
    	} else {
		set bootargs "earlycon console=ttyPS0,115200 clk_ignore_unused init_fatal_sh=1"
    	}
	set family [get_hw_family]
    	if {[is_zynqmp_platform $family]} {
    		add_prop $chosen_node "bootargs" $bootargs string $default_dts
    	}

	# If stdout-path is already not set via any of the uart driver tcls, set the stdout to
	# coresight. serial0 will by default refer to coresight if there is no uart in design.
	if {[catch {set val [systemdt get $chosen_node "stdout-path"]} msg]} {
		set serial0_val ""
		if {[catch {set serial0_val [systemdt get $alias_node "serial0"]} msg]} {
		}
		if {![string_is_empty $serial0_val]} {
			add_prop $chosen_node "stdout-path" "serial0:115200n8" stringlist "system-top.dts"
		}
	}
}

proc update_memory_node {} {
	# Update the generated memory node addresses if two memory nodes are having the same base addresses
	# e.g. Two microblazes connected to one BRAM each. Each BRAM can start from 0. It leads to overwriting
	# of one node by other. Thus, update their addresses with incremental leading zeroes.
	set root_child_nodes [systemdt children root]
	set axi_noc_baseaddr_dict [dict create]
	set mem_addr_counter [dict create]
	foreach node $root_child_nodes {
		if [regexp -nocase "memory@" $node match] {
			set ip_name_addr [::textutil::split::splitx $node ": memory@"]
			set mem_ip_handle [lindex $ip_name_addr 0]
			set mem_addr [lindex $ip_name_addr 1]
			if { [dict exists $mem_addr_counter $mem_addr] } {
				set redundant_addr_count [dict get $mem_addr_counter $mem_addr]
				incr redundant_addr_count
				dict set mem_addr_counter $mem_addr $redundant_addr_count
				set leading_zeroes [string repeat "0" $redundant_addr_count]
				systemdt rename $node "$mem_ip_handle: memory@${leading_zeroes}$mem_addr"
			} else {
				dict set mem_addr_counter $mem_addr 0
			}
			if {![catch {set memory_ip_name [systemdt get $node "xlnx,ip-name"]} msg]} {
				if {[regexp -nocase "axi_noc" $memory_ip_name match]} {
					regsub -all {^0x} $mem_addr {} mem_addr
					dict set axi_noc_baseaddr_dict 0x$mem_addr $node
				}
			}
		}
	}

	# Linux/u-boot expects DDR with lower addresses to be the first one among all the memory
	# nodes available. Without below sorting, these nodes appear in the alphabetical order
	# i.e. the order in which hsi get_cells returns the cell names. If the cell names have
	# been updated in design like axi_noc2_s0_ddr_memory: memory@00000000 and
	# axi_noc2_1_ddr_memory: memory@60000000000, higher memory is getting picked up by
	# u-boot as that comes first in alphabetical order.

	if {[llength [dict keys $axi_noc_baseaddr_dict]] > 1 } {
		# Sorting it in decreasing order to push the nodes back to SDT as stack.
		set sorted_noc_addr_List [lsort -decreasing -integer [dict keys $axi_noc_baseaddr_dict]]
		set sorted_noc_node_list [list]

		foreach key $sorted_noc_addr_List {
		    lappend sorted_noc_node_list [dict get $axi_noc_baseaddr_dict $key]
		}

		foreach node $sorted_noc_node_list {
			systemdt move root 0 $node
		}
	}
}


proc gen_cpu_cluster {} {
	global is_versal_net_platform
	global is_versal_2ve_2vm_platform
	global mb_dict_64_bit
	set proctype [get_hw_family]
	set default_dts "system-top.dts"
	set r5_procs [hsi::get_cells -hier -filter {IP_NAME==psv_cortexr5 || IP_NAME==psu_cortexr5 || IP_NAME==psx_cortexr52 || IP_NAME==cortexr52}]
	set r5_present 0

	if {[string match -nocase [get_hw_family] "zynq"]} {
        	set cpu_node [create_node -l "cpus_a9" -n "cpus-a9" -u 0 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "#ranges-address-cells" "0x1" hexint $default_dts
		global memmap
		set values [dict keys $memmap]
		set list_values "0xf0000000 &amba 0xf0000000 0x10000000"
		foreach val $values {
			set temp [get_memmap $val a53]
			set com_val [split $temp ","]
			foreach value $com_val {
				set addr "[lindex $value 1]"
				set size "[lindex $value 3]"
				set addr [string trimright $addr ">"]
				set size [string trimright $size ">"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
	} elseif {[is_zynqmp_platform $proctype]} {
    		set r5_present 1
        	set cpu_node [create_node -l "cpus_a53" -n "cpus-a53" -u 0 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x2" hexint $default_dts
		add_prop $cpu_node "#ranges-address-cells" "0x2" hexint $default_dts
		global memmap
		set values [dict keys $memmap]
		set list_values "0x0 0xf0000000 &amba 0x0 0xf0000000 0x0 0x10000000>, \n\t\t\t      <0x0 0xf9000000 &amba_apu 0x0 0xf9000000 0x0 0x80000>, \n\t\t\t      <0x0 0x0 &zynqmp_reset 0x0 0x0 0x0 0x0>, \n\t\t\t      <0x0 0x0 &pinctrl0 0x0 0x0 0x0 0x0>, \n\t\t\t      <0x0 0xffa50800 &ams_ps 0x0 0xffa50800 0x0 0x400>, \n\t\t\t      <0x0 0xffa50c00 &ams_pl 0x0 0xffa50c00 0x0 0x400"
		foreach val $values {
			set temp [get_memmap $val a53]
			set com_val [split $temp ","]
			foreach value $com_val {
				set addr "[lindex $value 0] [lindex $value 1]"
				if {[string match -nocase $val "psu_rcpu_gic"] || [string match -nocase $val "psu_acpu_gic"]} {
					set size "0x0 [lindex $value 2]"
				} else {
					set size "[lindex $value 2] [lindex $value 3]"
				}
				set addr [string trimright $addr ">"]
				set addr [string trimleft $addr "<"]
				set size [string trimright $size ">"]
				set size [string trimleft $size "<"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
		#add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x80" hexlist $default_dts
    	} elseif {[string match -nocase $proctype "versal"] } {
    		set r5_present 1
    		set proc_name "a72"
    		if { $is_versal_net_platform } {
    			set proc_name "a78"
    		}
    		set cpu_node [create_node -l "cpus_${proc_name}" -n "cpus-${proc_name}" -u 0 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x2" hexint $default_dts
		add_prop $cpu_node "#ranges-address-cells" "0x2" hexint $default_dts
		global memmap
		set cnt 0
		set values [dict keys $memmap]
		set list_values "0x0 0xf0000000 &amba 0x0 0xf0000000 0x0 0x10000000>, \n\t\t\t      <0x0 0xf9000000 &amba_apu 0x0 0xf9000000 0x0 0x80000"
		foreach val $values {
			set temp [get_memmap $val a53]
			set com_val [split $temp ","]
			foreach value $com_val {
				set addr "[lindex $value 0] [lindex $value 1]"
				set size "[lindex $value 2] [lindex $value 3]"
				set addr [string trimright $addr ">"]
				set addr [string trimleft $addr "<"]
				set size [string trimright $size ">"]
				set size [string trimleft $size "<"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
		# TODO Fix this LPD_XPPU part
		#add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x260> , <&lpd_xppu 0x261" hexlist $default_dts
    	}
    	if { $r5_present } {
    		set r5_cores 2
    		if { $is_versal_net_platform } {
			set rpu_ip_name "psx_cortexr52"
			if { $is_versal_2ve_2vm_platform } {
				set rpu_ip_name "cortexr52"
			}
			set r5_cores [llength [hsi get_cells -hier -filter IP_NAME==$rpu_ip_name]]
    		}
		for {set core 0} {$core < $r5_cores} {incr core} {
			set proc_name "r5"
			if { $is_versal_net_platform } {
				set proc_name "r52"
	    		}
			set cpu_node [create_node -l "cpus_${proc_name}_$core" -n "cpus-${proc_name}" -u $core -d ${default_dts} -p root]
			add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
			add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
			add_prop $cpu_node "#ranges-address-cells" "0x1" hexint $default_dts
			global memmap
			set values [dict keys $memmap]
			set list_values "0xf0000000 &amba 0xf0000000 0x10000000>, \n\t\t\t      <0xf9000000 &amba_rpu 0xf9000000 0x3000"
			if {[is_zynqmp_platform $proctype]} {
				set list_values "0xf0000000 &amba 0xf0000000 0x10000000>, \n\t\t\t      <0xf9000000 &amba_rpu 0xf9000000 0x3000>, \n\t\t\t      <0x0 &zynqmp_reset 0x0 0x0"
			}

			foreach val $values {
				set temp [get_memmap $val [lindex $r5_procs $core]]
				set com_val [split $temp ","]
				foreach value $com_val {
					# Ignore if a 40 bit address is mapped to R5 processor
					if {![check_if_forty_bit_address $value]} {
						set addr "[lindex $value 1]"
						if {[string match -nocase $val "psu_rcpu_gic"] || [string match -nocase $val "psu_acpu_gic"]} {
							set size "[lindex $value 2]"
						} else {
							set size "[lindex $value 3]"
						}
						set addr [string trimright $addr ">"]
						set size [string trimright $size ">"]
						set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
					}
				}
			}
			add_prop $cpu_node "address-map" $list_values special $default_dts
		    	# if {[string match -nocase $proctype "versal"] } {
			# 	add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x200> , <&lpd_xppu 0x204" hexlist $default_dts
			# } elseif {[is_zynqmp_platform $proctype]} {
			# 	add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x0> , <&lpd_xppu 0x10" hexlist $default_dts
			# }
		}
	}

    	if {[string match -nocase $proctype "versal"]} {
		set cpu_node [create_node -l "cpus_microblaze_0" -n "cpus_microblaze" -u 0 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
	        add_prop $cpu_node "#ranges-address-cells" "0x1" hexint $default_dts
		#add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x247> , <&pmc_xppu 0x247> , <&pmc_xppu_npi 0x247" hexlist $default_dts
	} elseif {[is_zynqmp_platform $proctype]} {
        	set cpu_node [create_node -l "cpus_microblaze_0" -n "cpus_microblaze" -u 0 -d ${default_dts} -p root]
	        add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "#ranges-address-cells" "0x1" hexint $default_dts
		#add_prop $microblaze_node "bus-master-id" "&lpd_xppu 0x40" hexlist $default_dts
	}
	global memmap
	set values [dict keys $memmap]
	set list_values "0xf0000000 &amba 0xf0000000 0x10000000"
    	if {[is_zynqmp_platform $proctype]} {
		set list_values "0xf0000000 &amba 0xf0000000 0x10000000>, \n\t\t\t      <0x0 &zynqmp_reset 0x0 0x0"
	}
	foreach val $values {
    		if {[is_zynqmp_platform $proctype]} {
			set temp [get_memmap $val pmu]
		} else {
			set temp [get_memmap $val pmc]
		}
		set com_val [split $temp ","]
		foreach value $com_val {
			# coresight is mapped as a PS IP in gen_ps_mapping
			# But it is not needed in pmc/psm cpu cluster
			set ips_to_ignore "coresight"
			# Ignore if a 40 bit address is mapped to PMU/PMC processor
			if {![check_if_forty_bit_address $value] && [lsearch $ips_to_ignore $val] < 0} {
				set addr "[lindex $value 1]"
				set size "[lindex $value 3]"
				set addr [string trimright $addr ">"]
				set size [string trimright $size ">"]
				set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
			}
		}
	}
    	if {[string match -nocase $proctype "versal"]} {
		add_prop $cpu_node "address-map" $list_values special $default_dts
	} elseif {[is_zynqmp_platform $proctype]} {
		add_prop $cpu_node "address-map" $list_values special $default_dts
	}
	if {[llength [hsi get_cells -hier -filter {IP_NAME == psv_psm || IP_NAME == psx_psm || IP_NAME == psm}]]} {
		set cpu_node [create_node -l "cpus_microblaze_1" -n "cpus_microblaze" -u 1 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
	   	add_prop $cpu_node "#ranges-address-cells" "0x1" hexint $default_dts
		global memmap
		set values [dict keys $memmap]
		set list_values "0xf0000000 &amba 0xf0000000 0x10000000"
		foreach val $values {
			set temp [get_memmap $val psm]
			set com_val [split $temp ","]
			foreach value $com_val {
				# coresight is mapped as a PS IP in gen_ps_mapping
				# But it is not needed in pmc/psm cpu cluster
				set ips_to_ignore "coresight"
				# Ignore if a 40 bit address is mapped to PSM
				if {![check_if_forty_bit_address $value] && [lsearch $ips_to_ignore $val] < 0} {
					set addr "[lindex $value 1]"
					set size "[lindex $value 3]"
					set addr [string trimright $addr ">"]
					set size [string trimright $size ">"]
					set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
				}
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
		#add_prop $cpu_node "bus-master-id" "&lpd_xppu 0x238> , <&pmc_xppu 0x238> , <&pmc_xppu_npi 0x238" hexlist $default_dts
	}

	if {[llength [hsi get_cells -hier -filter {IP_NAME == asu}]]} {
		set cpu_node [create_node -l "cpus_asu" -n "cpus_asu" -u 0 -d ${default_dts} -p root]
		add_prop $cpu_node "compatible" "cpus,cluster" string $default_dts
		add_prop $cpu_node "#ranges-size-cells" "0x1" hexint $default_dts
		add_prop $cpu_node "#ranges-address-cells" "0x1" hexint $default_dts
		global memmap
		set values [dict keys $memmap]
		set list_values "0xf0000000 &amba 0xf0000000 0x10000000"
		foreach val $values {
			set temp [get_memmap $val asu]
			set com_val [split $temp ","]
			foreach value $com_val {
				# coresight is mapped as a PS IP in gen_ps_mapping
				# But it is not needed in pmc/psm/asu cpu cluster
				set ips_to_ignore "coresight"
				# Ignore if a 40 bit address is mapped to PSM
				if {![check_if_forty_bit_address $value] && [lsearch $ips_to_ignore $val] < 0} {
					set addr "[lindex $value 1]"
					set size "[lindex $value 3]"
					set addr [string trimright $addr ">"]
					set size [string trimright $size ">"]
					set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
				}
			}
		}
		add_prop $cpu_node "address-map" $list_values special $default_dts
	}

	set microblaze_proc [hsi::get_cells -hier -filter {IP_NAME==microblaze || IP_NAME==microblaze_riscv}]
	if {[llength $microblaze_proc] > 0} {
		set root_cell_size 1
		foreach proc $microblaze_proc {
			set count [get_microblaze_nr $proc]
			set proc_name [hsi get_property IP_NAME $proc]
			set cpu_node [create_node -l "cpus_${proc_name}_${count}" -n "cpus_${proc_name}" -u $count -d ${default_dts} -p root]
			set cell_size [dict get $mb_dict_64_bit $proc]
			if { $root_cell_size < $cell_size } {
				set root_cell_size $cell_size
			}
			add_prop $cpu_node "#ranges-size-cells" "0x${cell_size}" hexint $default_dts
			add_prop "${cpu_node}" "#ranges-address-cells" "0x${cell_size}" hexint $default_dts
			global memmap
			set values [dict keys $memmap]
			set list_values ""
			foreach val $values {
				set temp [get_memmap $val $proc]
				set com_val [split $temp ","]
				set ips_to_ignore "coresight"
				# coresight mapped to microblaze is wrong configuration ignore it
				if {[lsearch $ips_to_ignore $val] >= 0} {
					continue
				}
				foreach value $com_val {
					if {[expr $cell_size > 1]} {
						set addr "[lindex $value 0] [lindex $value 1]"
						set size "[lindex $value 2] [lindex $value 3]"
						set addr [string trimright $addr ">"]
						set addr [string trimleft $addr "<"]
						set size [string trimright $size ">"]
						set size [string trimleft $size "<"]
					} else {
						set addr "[lindex $value 1]"
						set size "[lindex $value 3]"
						set addr [string trimright $addr ">"]
						set size [string trimright $size ">"]
					}
					if {[string_is_empty $list_values]} {
						set list_values "$addr &${val} $addr $size"
					} else {
						set list_values [append list_values ">, \n\t\t\t      " "<$addr &${val} $addr $size"]
					}
				}
			}
			add_prop $cpu_node "address-map" $list_values special $default_dts
		}
		if {[string match -nocase $proctype "microblaze"]} {
			add_prop "root" "#address-cells" $root_cell_size int "system-top.dts"
			add_prop "root" "#size-cells" $root_cell_size int "system-top.dts"
		}
	}
	
}

proc update_cpu_node {} {
	# Purpose is to delete the APU nodes. These nodes are defined in platform specific
	# dtsi files. There are few platforms where general purpose boards have say quad
	# cores but some of the boards have dual cores only (ZynqMP cg devices). To have
	# proper cpu listing for linux, the extra cpu nodes from static files have to be
	# deleted. In order to remove these nodes, all the references corresponding to
	# these nodes also have to be removed. Removing all the existing references is a
	# challenge and error prone. Platforms like Versal Net and Versal_2VE_2VM with A78
	# processors have clusters and the node name is not easy to decode. It would
	# involve complicated logic to remove cpu nodes along with all its references.
	# Popular known use case is only for ZYNQMP CG devices and DTG contains
	# valid logic only for ZynqMP.

	global apu_proc_ip
	if {$apu_proc_ip != "psu_cortexa53"} {
		return
	}

	set default_dts "system-top.dts"
	set apu_cores_in_design [hsi::get_cells -hier -filter "IP_NAME == ${apu_proc_ip}"]
	set len_apu_cores_in_design [llength $apu_cores_in_design]

	if {$len_apu_cores_in_design < 4} {
		set delete_node_label "cpus-a53@0"
		set cpu_node [create_node -n $delete_node_label -d "system-top.dts" -p root]
		for {set i $len_apu_cores_in_design} {$i < 4} {incr i} {
			add_prop $delete_node_label "/delete-node/ cpu@$i" boolean "system-top.dts"
			add_prop root "/delete-node/ &psu_cortexa53_${i}_debug;" boolean "pcw.dtsi"
    		}
		# Update the existing interrupt-affinity property of pmu node that contains apu references.
		set intr_affinity ""
		set cpu_cooling_maps ""
		set pmu_node [create_node -n pmu -d "system-top.dts" -p root]
		for {set i 0} {$i < $len_apu_cores_in_design} {incr i} {
			append intr_affinity "<&psu_cortexa53_$i>, "
			append cpu_cooling_maps "<&psu_cortexa53_$i THERMAL_NO_LIMIT THERMAL_NO_LIMIT>, "
		}
		set intr_affinity [string trimright $intr_affinity ", "]
		add_prop $pmu_node "interrupt-affinity" $intr_affinity noformating "system-top.dts"

		# Update the existing cooling-device property of thermal-zones that contains apu references.
		set cpu_cooling_maps [string trimright $cpu_cooling_maps ", "]
		set thermal_zone_node [create_node -n thermal-zones -d $default_dts -p root]
		set apu_thermal_node [create_node -n apu-thermal -d $default_dts -p $thermal_zone_node]
		set cooling_maps_node [create_node -n cooling-maps -d $default_dts -p $apu_thermal_node]
		set maps_node [create_node -n map -d $default_dts -p $cooling_maps_node]
		add_prop $maps_node "cooling-device" $cpu_cooling_maps noformating $default_dts
	}
}

proc update_alias {} {
	global is_versal_net_platform
	global dup_periph_handle
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set mainline_ker [get_user_config $common_file -mainline_kernel]
	set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
	if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
         	return
    	}
	set default_dts "system-top.dts"
	set all_drivers [get_drivers 1]

	# Search for ps_qspi, if it is there then interchange this with first driver
	# because to have correct internal u-boot commands qspi has to be listed in aliases as the first for spi0
	set proctype [get_hw_family]
	if {[string match -nocase $proctype "zynq"]} {
		set pos [lsearch $all_drivers "ps7_qspi*"]
	} elseif {[is_zynqmp_platform $proctype]} {
		set pos [lsearch $all_drivers "psu_qspi*"]
	} elseif {[string match -nocase $proctype "versal"]} {
		set pos [lsearch $all_drivers "psv_pmc_qspi*"]
		if {$is_versal_net_platform} {
			set pos [lsearch $all_drivers "psx_pmc_qspi*"]
		}
		if {$pos == -1} {
			set pos [lsearch $all_drivers "pmc_qspi*"]
		}
	} else {
		set pos [lsearch $all_drivers "psu_qspi*"]
	}
	if { $pos >= 0 } {
		set first_element [lindex $all_drivers 0]
		set qspi_element [lindex $all_drivers $pos]
		set all_drivers [lreplace $all_drivers 0 0 $qspi_element]
		set all_drivers [lreplace $all_drivers $pos $pos $first_element]
    	}

	set valid_pluarts "mdm axi_uartlite axi_uart16550"
	set valid_coresights "ps7_coresight_comp psu_coresight_0 psv_coresight psx_coresight coresight"

	set design_pluarts ""
	set design_coresight ""
	foreach drv_handle $all_drivers {
		if {$drv_handle == "generic"} {
			continue
		}
		set ip_name  [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
		if {[lsearch $valid_pluarts $ip_name] >= 0} {
			lappend design_pluarts $drv_handle
		} elseif {[lsearch $valid_coresights $ip_name] >= 0} {
			lappend design_coresight $drv_handle
		}
	}

	set family [get_hw_family]
	if {![regexp "microblaze" $family match]} {
		set ps_uarts [hsi::get_cells -hier -filter {IP_NAME==psv_sbsauart || IP_NAME==psx_sbsauart || IP_NAME==sbsauart || IP_NAME==psu_uart || IP_NAME==ps7_uart}]

	        if {[llength $ps_uarts] >= 2} {
			set uart_address "ff000000 ff010000 e0000000 e0010000 f1920000 f1930000"
	                set addr [get_baseaddr [lindex $ps_uarts 0] noprefix]
	                set pos [lsearch $uart_address $addr]
	                set list_pos1 [lsearch $all_drivers [lindex $ps_uarts 0]]
	                set list_pos2 [lsearch $all_drivers [lindex $ps_uarts 1]]
			if {($pos % 2 == 1) || ($list_pos1 > $list_pos2)} {
	                        set all_drivers [lreplace $all_drivers $list_pos1 $list_pos1 [lindex $ps_uarts 1]]
	                        set all_drivers [lreplace $all_drivers $list_pos2 $list_pos2 [lindex $ps_uarts 0]]
	                }
	        }
	}

	foreach drv_handle $all_drivers {
		if {$drv_handle == "generic"} {
			continue
		}
		if {[lsearch $design_pluarts $drv_handle] >= 0 || [lsearch $design_coresight $drv_handle] >= 0} {
			continue
		}
            	set ip_name  [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
		if {$ip_name in {"psv_pmc_qspi" "psx_pmc_qspi" "pmc_qspi"}} {
                  	set ip_type [get_ip_property $drv_handle IP_TYPE]
                  	if {[string match -nocase $ip_type "PERIPHERAL"]} {
                        	continue
                  	}
            	}
		set drvname [get_drivers $drv_handle]

		set common_file "$path/$drvname/data/config.yaml"
		set exists [file exists $common_file]
		set tmp [get_driver_config $drv_handle alias]
		if {[string_is_empty $tmp] || [dict exists $dup_periph_handle $drv_handle] } {
            		continue
        	} else {
			set alias_str $tmp
			set alias_count [get_count $alias_str]
            		set conf_name ${alias_str}${alias_count}
			set value [get_node $drv_handle]
			set value [split $value ": "]
			set value [lindex $value 0]
			if {[is_pl_ip $drv_handle]} {
				set value "&$value"
			}
			set ip_list "i2c spi serial"
			# TODO: need to check if the label already exists in the current system
			set proctype [get_hw_family]
			set alias_node [create_node -n "aliases" -p root -d "system-top.dts"]
			add_prop $alias_node $conf_name $value aliasref $default_dts
		}
	}

	foreach drv_handle $design_pluarts {
		set drvname [get_drivers $drv_handle]
		set common_file "$path/$drvname/data/config.yaml"
		set exists [file exists $common_file]
		set tmp [get_driver_config $drv_handle alias]
		if {[string_is_empty $tmp] || [dict exists $dup_periph_handle $drv_handle]} {
			continue
		} else {
			set alias_str $tmp
			set alias_count [get_count $alias_str]
			set conf_name ${alias_str}${alias_count}
			set value [get_node $drv_handle]
			set value [split $value ": "]
			set value [lindex $value 0]
			if {[is_pl_ip $drv_handle]} {
				set value "&$value"
			}
			set alias_node [create_node -n "aliases" -p root -d "system-top.dts"]
			add_prop $alias_node $conf_name $value aliasref $default_dts
		}
	}

	if {![string_is_empty $design_coresight]} {
		set alias_count [get_count "serial"]
		set conf_name "serial${alias_count}"
		set value [lindex [split [get_node [lindex $design_coresight 0]] ": "] 0]
		set alias_node [create_node -n "aliases" -p root -d "system-top.dts"]
		add_prop $alias_node $conf_name $value aliasref $default_dts
	}
}

proc gen_xppu {drv_handle} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
	set node [get_node $drv_handle]
	set baseaddr [get_baseaddr $drv_handle noprefix]
	set xppu [dict create]
	set family [get_hw_family]

	if {[string match -nocase $family "versal"] && [is_ps_ip $drv_handle]} {
		dict set xppu	FF200000	addr	xmpu_pmc
		dict set xppu	FD4D0000	addr	xmpu_fpd
		dict set xppu	FD390000	addr	xmpu_fpd
		dict set xppu	FD800000	addr	xmpu_fpd
		dict set xppu	A4000000	addr	xmpu_fpd
		dict set xppu	B0000000	addr	xmpu_fpd
		dict set xppu	80000000	addr	xmpu_fpd
		dict set xppu	FD5C0000	addr	xmpu_fpd
		dict set xppu	FD000000	addr	xmpu_fpd
		dict set xppu	FD1A0000	addr	xmpu_fpd
		dict set xppu	FD360000	addr	xmpu_fpd
		dict set xppu	FD380000	addr	xmpu_fpd
		dict set xppu	FD5E0000	addr	xmpu_fpd
		dict set xppu	FD5F0000	addr	xmpu_fpd
		dict set xppu	FD610000	addr	xmpu_fpd
		dict set xppu	FD690000	addr	xmpu_fpd
		dict set xppu	FD700000	addr	xmpu_fpd
		dict set xppu	F9000000	addr	xmpu_fpd
		dict set xppu	FFFC0000	addr	xmpu_ocm
		dict set xppu	FF980000	addr	lpd
		dict set xppu	FF990000	addr	lpd
		dict set xppu	FFA80000	addr	lpd
		dict set xppu	FF9B0000	addr	lpd
		dict set xppu	FF960000	addr	lpd
		dict set xppu	FF970000	addr	lpd
		dict set xppu	FF8E0000	addr	lpd
		dict set xppu	FF940000	addr	lpd
		dict set xppu	FF900000	addr	lpd
		dict set xppu	FF9A0000	addr	lpd
		dict set xppu	FF9C0000	addr	lpd
		dict set xppu	FF5E0000	addr	lpd
		dict set xppu	FF8C0000	addr	lpd
		dict set xppu	FF880000	addr	lpd
		dict set xppu	FF800000	addr	lpd
		dict set xppu	FF600000	addr	lpd
		dict set xppu	FF410000	addr	lpd
		dict set xppu	FF500000	addr	lpd
		dict set xppu	FF420000	addr	lpd
		dict set xppu	FF440000	addr	lpd
		dict set xppu	FF480000	addr	lpd
		dict set xppu	FF510000	addr	lpd
		dict set xppu	FF540000	addr	lpd
		dict set xppu	FF520000	addr	lpd
		dict set xppu	400000000	addr	lpd
		dict set xppu	40000000000	addr	lpd
		dict set xppu	FE600000	addr	lpd
		dict set xppu	FCFF0000	addr	lpd
		dict set xppu	F8000000	addr	lpd
		dict set xppu	A8000000	addr	lpd
		dict set xppu	FF9D0000	addr	lpd
		dict set xppu	FF9E0000	addr	lpd
		dict set xppu	FE200000	addr	lpd
		dict set xppu	FE000000	addr	lpd
		dict set xppu	FF000000	addr	lpd
		dict set xppu	FFC00000	addr	lpd
		dict set xppu	FF300000	addr	lpd
		dict set xppu	FE800000	addr	lpd
		dict set xppu	FFE40000	addr	lpd
		dict set xppu	FFE00000	addr	lpd
		dict set xppu	FFE90000	addr	lpd
		dict set xppu	FFEA0000	addr	lpd
		dict set xppu	FFEC0000	addr	lpd
		dict set xppu	FFB80000	addr	lpd
		dict set xppu	FCFE0000	addr	lpd
		dict set xppu	FCFC0000	addr	lpd
		dict set xppu	FCF80000	addr	lpd
		dict set xppu	FCF00000	addr	lpd
		dict set xppu	FCE00000	addr	lpd
		dict set xppu	FCC00000	addr	lpd
		dict set xppu	FC800000	addr	lpd
		dict set xppu	FC000000	addr	lpd
		dict set xppu	F0000000	addr	lpd
		dict set xppu	FB000000	addr	lpd
		dict set xppu	E0000000	addr	lpd
		dict set xppu	100000000	addr	lpd
		dict set xppu	1B700000000	addr	lpd
		dict set xppu	200000000	addr	lpd
		dict set xppu	1B600000000	addr	lpd
		dict set xppu	600000000	addr	lpd
		dict set xppu	1B400000000	addr	lpd
		dict set xppu	1B000000000	addr	lpd
		dict set xppu	800000000	addr	lpd
		dict set xppu	1A000000000	addr	lpd
		dict set xppu	18000000000	addr	lpd
		dict set xppu	8000000000	addr	lpd
		dict set xppu	C000000000	addr	lpd
		dict set xppu	14000000000	addr	lpd
		dict set xppu	10000000000	addr	lpd
		dict set xppu	50000000000	addr	lpd
		dict set xppu	20000000000	addr	lpd
		dict set xppu	60000000000	addr	lpd
		dict set xppu	80000000000	addr	lpd
		dict set xppu	FE400000	addr	lpd
		dict set xppu	FE5F0000	addr	lpd
		dict set xppu	180000		addr	lpd
		dict set xppu	80180000	addr	lpd
		dict set xppu	80000		addr	pmc
		dict set xppu	80080000	addr	pmc
		dict set xppu	F0800000	addr	pmc
		dict set xppu	F11A0000	addr	pmc
		dict set xppu	F11F0000	addr	pmc
		dict set xppu	F1160000	addr	pmc
		dict set xppu	F1180000	addr	pmc
		dict set xppu	F1220000	addr	pmc
		dict set xppu	F1330000	addr	pmc
		dict set xppu	F15A0000	addr	pmc
		dict set xppu	F1580000	addr	pmc
		dict set xppu	F1340000	addr	pmc
		dict set xppu	F1380000	addr	pmc
		dict set xppu	F1500000	addr	pmc
		dict set xppu	F1400000	addr	pmc
		dict set xppu	F1260000	addr	pmc
		dict set xppu	F1100000	addr	pmc
		dict set xppu	F0100000	addr	pmc
		dict set xppu	F0240000	addr	pmc
		dict set xppu	F0200000	addr	pmc
		dict set xppu	F0300000	addr	pmc
		dict set xppu	F11E0000	addr	pmc
		dict set xppu	F1200000	addr	pmc
		dict set xppu	F11C0000	addr	pmc
		dict set xppu	F11D0000	addr	pmc
		dict set xppu	F1210000	addr	pmc
		dict set xppu	F1230000	addr	pmc
		dict set xppu	F12F0000	addr	pmc
		dict set xppu	F1310000	addr	pmc
		dict set xppu	F1300000	addr	pmc
		dict set xppu	F12B0000	addr	pmc
		dict set xppu	F12E0000	addr	pmc
		dict set xppu	F12C0000	addr	pmc
		dict set xppu	F1F80000	addr	pmc
		dict set xppu	F1240000	addr	pmc
		dict set xppu	F1000000	addr	pmc
		dict set xppu	F6000000	addr	pmc
		dict set xppu	F1110000	addr	pmc
		dict set xppu	F1120000	addr	pmc
		dict set xppu	F1140000	addr	pmc
		dict set xppu	F2000000	addr	pmc
		dict set xppu	F0110000	addr	pmc
		dict set xppu	F0310000	addr	pmc
		dict set xppu	F12A0000	addr	pmc
		dict set xppu	F2100000	addr	pmc
		dict set xppu	F1270000	addr	pmc
		dict set xppu	F1280000	addr	pmc
		dict set xppu	F9100000	addr	pmc
		dict set xppu	F9200000	addr	pmc
		dict set xppu	F9400000	addr	pmc
		dict set xppu	F9800000	addr	pmc
		dict set xppu	FA000000	addr	pmc
		dict set xppu	A0000000	addr	pmc
		dict set xppu	120000000	addr	pmc
		dict set xppu	140000000	addr	pmc
		dict set xppu	180000000	addr	pmc
		dict set xppu	1B780000000	addr	pmc
		dict set xppu	300000000	addr	pmc
		dict set xppu	1B800000000	addr	pmc
		dict set xppu	1000000000	addr	pmc
		dict set xppu	2000000000	addr	pmc
		dict set xppu	4000000000	addr	pmc
		dict set xppu	1C000000000	addr	pmc
		dict set xppu	F1320000	addr	pmc
		dict set xppu	FD2C0000	addr	lpd
		dict set xppu	FD1C0000	addr	lpd
		dict set xppu	FD280000	addr	lpd
		dict set xppu	FD200000	addr	lpd
		dict set xppu	FD370000	addr	lpd
		dict set xppu	AC000000	addr	lpd
		dict set xppu	FFF00000	addr	lpd
		dict set xppu	FD620000	addr	lpd
		dict set xppu	380000		addr	lpd
		dict set xppu	80380000	addr	lpd
		dict set xppu	70000000000	addr	lpd
		dict set xppu	FF010000	addr	lpd
		dict set xppu	FF020000	addr	lpd
		dict set xppu	FF030000	addr	lpd
		dict set xppu	FF040000	addr	lpd
		dict set xppu	FF050000	addr	lpd
		dict set xppu	FF060000	addr	lpd
		dict set xppu	FF070000	addr	lpd
		dict set xppu	FF080000	addr	lpd
		dict set xppu	FF090000	addr	lpd
		dict set xppu	FF0A0000	addr	lpd
		dict set xppu	FF0B0000	addr	lpd
		dict set xppu	FF0C0000	addr	lpd
		dict set xppu	FF0D0000	addr	lpd
		dict set xppu	FF0E0000	addr	lpd
		dict set xppu	FF0F0000	addr	lpd
		dict set xppu	FF100000	addr	lpd
		dict set xppu	FF110000	addr	lpd
		dict set xppu	FF120000	addr	lpd
		dict set xppu	FF130000	addr	lpd
		dict set xppu	FF140000	addr	lpd
		dict set xppu	FF150000	addr	lpd
		dict set xppu	FF160000	addr	lpd
		dict set xppu	FF170000	addr	lpd
		dict set xppu	FF180000	addr	lpd
		dict set xppu	FF190000	addr	lpd
		dict set xppu	FF1A0000	addr	lpd
		dict set xppu	FF1B0000	addr	lpd
		dict set xppu	FF1C0000	addr	lpd
		dict set xppu	FF1D0000	addr	lpd
		dict set xppu	FF1E0000	addr	lpd
		dict set xppu	FF1F0000	addr	lpd
		dict set xppu	FF210000	addr	lpd
		dict set xppu	FF220000	addr	lpd
		dict set xppu	FF230000	addr	lpd
		dict set xppu	FF240000	addr	lpd
		dict set xppu	FF250000	addr	lpd
		dict set xppu	FF260000	addr	lpd
		dict set xppu	FF270000	addr	lpd
		dict set xppu	FF280000	addr	lpd
		dict set xppu	FF290000	addr	lpd
		dict set xppu	FF2A0000	addr	lpd
		dict set xppu	FF2B0000	addr	lpd
		dict set xppu	FF2C0000	addr	lpd
		dict set xppu	FF2D0000	addr	lpd
		dict set xppu	FF2E0000	addr	lpd
		dict set xppu	FF2F0000	addr	lpd
		dict set xppu	FF310000	addr	lpd
		dict set xppu	FF320000	addr	lpd
		dict set xppu	FF330000	addr	lpd
		dict set xppu	FF340000	addr	lpd
		dict set xppu	FF350000	addr	lpd
		dict set xppu	FF360000	addr	lpd
		dict set xppu	FF370000	addr	lpd
		dict set xppu	FF380000	addr	lpd
		dict set xppu	FF390000	addr	lpd
		dict set xppu	FF3A0000	addr	lpd
		dict set xppu	FF3B0000	addr	lpd
		dict set xppu	FF3C0000	addr	lpd
		dict set xppu	FF3D0000	addr	lpd
		dict set xppu	FF3E0000	addr	lpd
		dict set xppu	FF3F0000	addr	lpd
		dict set xppu	FF400000	addr	lpd
		dict set xppu	FF430000	addr	lpd
		dict set xppu	FF450000	addr	lpd
		dict set xppu	FF460000	addr	lpd
		dict set xppu	FF470000	addr	lpd
		dict set xppu	FF490000	addr	lpd
		dict set xppu	FF4A0000	addr	lpd
		dict set xppu	FF4B0000	addr	lpd
		dict set xppu	FF4C0000	addr	lpd
		dict set xppu	FF4E0000	addr	lpd
		dict set xppu	FF4F0000	addr	lpd
		dict set xppu	FF530000	addr	lpd
		dict set xppu	FF550000	addr	lpd
		dict set xppu	FF560000	addr	lpd
		dict set xppu	FF570000	addr	lpd
		dict set xppu	FF580000	addr	lpd
		dict set xppu	FF590000	addr	lpd
		dict set xppu	FF5A0000	addr	lpd
		dict set xppu	FF5B0000	addr	lpd
		dict set xppu	FF5C0000	addr	lpd
		dict set xppu	FF5D0000	addr	lpd
		dict set xppu	FF5F0000	addr	lpd
		dict set xppu	FF610000	addr	lpd
		dict set xppu	FF620000	addr	lpd
		dict set xppu	FF630000	addr	lpd
		dict set xppu	FF640000	addr	lpd
		dict set xppu	FF650000	addr	lpd
		dict set xppu	FF660000	addr	lpd
		dict set xppu	FF670000	addr	lpd
		dict set xppu	FF680000	addr	lpd
		dict set xppu	FF690000	addr	lpd
		dict set xppu	FF6A0000	addr	lpd
		dict set xppu	FF6B0000	addr	lpd
		dict set xppu	FF6C0000	addr	lpd
		dict set xppu	FF6D0000	addr	lpd
		dict set xppu	FF6E0000	addr	lpd
		dict set xppu	FF6F0000	addr	lpd
		dict set xppu	FF700000	addr	lpd
		dict set xppu	FF710000	addr	lpd
		dict set xppu	FF720000	addr	lpd
		dict set xppu	FF730000	addr	lpd
		dict set xppu	FF740000	addr	lpd
		dict set xppu	FF750000	addr	lpd
		dict set xppu	FF760000	addr	lpd
		dict set xppu	FF770000	addr	lpd
		dict set xppu	FF780000	addr	lpd
		dict set xppu	FF790000	addr	lpd
		dict set xppu	FF7A0000	addr	lpd
		dict set xppu	FF7B0000	addr	lpd
		dict set xppu	FF7C0000	addr	lpd
		dict set xppu	FF7D0000	addr	lpd
		dict set xppu	FF7E0000	addr	lpd
		dict set xppu	FF7F0000	addr	lpd
		dict set xppu	FF810000	addr	lpd
		dict set xppu	FF820000	addr	lpd
		dict set xppu	FF830000	addr	lpd
		dict set xppu	FF840000	addr	lpd
		dict set xppu	FF850000	addr	lpd
		dict set xppu	FF860000	addr	lpd
		dict set xppu	FF870000	addr	lpd
		dict set xppu	FF890000	addr	lpd
		dict set xppu	FF8A0000	addr	lpd
		dict set xppu	FF8B0000	addr	lpd
		dict set xppu	FF8D0000	addr	lpd
		dict set xppu	FF8F0000	addr	lpd
		dict set xppu	FF910000	addr	lpd
		dict set xppu	FF920000	addr	lpd
		dict set xppu	FF930000	addr	lpd
		dict set xppu	FF950000	addr	lpd
		dict set xppu	FF9F0000	addr	lpd
		dict set xppu	FFA00000	addr	lpd
		dict set xppu	FFA10000	addr	lpd
		dict set xppu	FFA20000	addr	lpd
		dict set xppu	FFA30000	addr	lpd
		dict set xppu	FFA40000	addr	lpd
		dict set xppu	FFA50000	addr	lpd
		dict set xppu	FFA60000	addr	lpd
		dict set xppu	FFA70000	addr	lpd
		dict set xppu	FFA90000	addr	lpd
		dict set xppu	FFAA0000	addr	lpd
		dict set xppu	FFAB0000	addr	lpd
		dict set xppu	FFAC0000	addr	lpd
		dict set xppu	FFAD0000	addr	lpd
		dict set xppu	FFAE0000	addr	lpd
		dict set xppu	FFAF0000	addr	lpd
		dict set xppu	FFB00000	addr	lpd
		dict set xppu	FFB10000	addr	lpd
		dict set xppu	FFB20000	addr	lpd
		dict set xppu	FFB30000	addr	lpd
		dict set xppu	FFB40000	addr	lpd
		dict set xppu	FFB50000	addr	lpd
		dict set xppu	FFB60000	addr	lpd
		dict set xppu	FFB70000	addr	lpd
		dict set xppu	FFB90000	addr	lpd
		dict set xppu	FFBA0000	addr	lpd
		dict set xppu	FFBB0000	addr	lpd
		dict set xppu	FFBC0000	addr	lpd
		dict set xppu	FFBD0000	addr	lpd
		dict set xppu	FFBE0000	addr	lpd
		dict set xppu	FFBF0000	addr	lpd
		dict set xppu	FFC10000	addr	lpd
		dict set xppu	FFC20000	addr	lpd
		dict set xppu	FFC30000	addr	lpd
		dict set xppu	FFC40000	addr	lpd
		dict set xppu	FFC50000	addr	lpd
		dict set xppu	FFC60000	addr	lpd
		dict set xppu	FFC70000	addr	lpd
		dict set xppu	FFC80000	addr	lpd
		dict set xppu	FFC90000	addr	lpd
		dict set xppu	FFCA0000	addr	lpd
		dict set xppu	FFCB0000	addr	lpd
		dict set xppu	FFCC0000	addr	lpd
		dict set xppu	FFCD0000	addr	lpd
		dict set xppu	FFCE0000	addr	lpd
		dict set xppu	FFCF0000	addr	lpd
		dict set xppu	FFD00000	addr	lpd
		dict set xppu	FFD10000	addr	lpd
		dict set xppu	FFD20000	addr	lpd
		dict set xppu	FFD30000	addr	lpd
		dict set xppu	FFD40000	addr	lpd
		dict set xppu	FFD50000	addr	lpd
		dict set xppu	FFD60000	addr	lpd
		dict set xppu	FFD70000	addr	lpd
		dict set xppu	FFD80000	addr	lpd
		dict set xppu	FFD90000	addr	lpd
		dict set xppu	FFDA0000	addr	lpd
		dict set xppu	FFDB0000	addr	lpd
		dict set xppu	FFDC0000	addr	lpd
		dict set xppu	FFDD0000	addr	lpd
		dict set xppu	FFDE0000	addr	lpd
		dict set xppu	FFDF0000	addr	lpd
		dict set xppu	FFE10000	addr	lpd
		dict set xppu	FFE20000	addr	lpd
		dict set xppu	FFE30000	addr	lpd
		dict set xppu	FFE50000	addr	lpd
		dict set xppu	FFE60000	addr	lpd
		dict set xppu	FFE70000	addr	lpd
		dict set xppu	FFE80000	addr	lpd
		dict set xppu	FFEB0000	addr	lpd
		dict set xppu	FFED0000	addr	lpd
		dict set xppu	FFEE0000	addr	lpd
		dict set xppu	FFEF0000	addr	lpd
		dict set xppu	FFF10000	addr	lpd
		dict set xppu	FFF20000	addr	lpd
		dict set xppu	FFF30000	addr	lpd
		dict set xppu	FFF40000	addr	lpd
		dict set xppu	FFF50000	addr	lpd
		dict set xppu	FFF60000	addr	lpd
		dict set xppu	FFF70000	addr	lpd
		dict set xppu	FFF80000	addr	lpd
		dict set xppu	FFF90000	addr	lpd
		dict set xppu	FFFA0000	addr	lpd
		dict set xppu	FFFB0000	addr	lpd
		dict set xppu	FFFD0000	addr	lpd
		dict set xppu	FFFF0000	addr	lpd
		dict set xppu	FE100000	addr	lpd
		dict set xppu	FE300000	addr	lpd
		dict set xppu	FE500000	addr	lpd
		dict set xppu	FE700000	addr	lpd
		dict set xppu	FE900000	addr	lpd
		dict set xppu	FEA00000	addr	lpd
		dict set xppu	FEB00000	addr	lpd
		dict set xppu	FEC00000	addr	lpd
		dict set xppu	FED00000	addr	lpd
		dict set xppu	FEE00000	addr	lpd
		dict set xppu	FEF00000	addr	lpd
		dict set xppu	F1010000	addr	pmc
		dict set xppu	F1020000	addr	pmc
		dict set xppu	F1030000	addr	pmc
		dict set xppu	F1040000	addr	pmc
		dict set xppu	F1050000	addr	pmc
		dict set xppu	F1060000	addr	pmc
		dict set xppu	F1070000	addr	pmc
		dict set xppu	F1080000	addr	pmc
		dict set xppu	F1090000	addr	pmc
		dict set xppu	F10A0000	addr	pmc
		dict set xppu	F10B0000	addr	pmc
		dict set xppu	F10C0000	addr	pmc
		dict set xppu	F10D0000	addr	pmc
		dict set xppu	F10E0000	addr	pmc
		dict set xppu	F10F0000	addr	pmc
		dict set xppu	F1130000	addr	pmc
		dict set xppu	F1150000	addr	pmc
		dict set xppu	F1170000	addr	pmc
		dict set xppu	F1190000	addr	pmc
		dict set xppu	F11B0000	addr	pmc
		dict set xppu	F1250000	addr	pmc
		dict set xppu	F1290000	addr	pmc
		dict set xppu	F12D0000	addr	pmc
		dict set xppu	F1350000	addr	pmc
		dict set xppu	F1360000	addr	pmc
		dict set xppu	F1370000	addr	pmc
		dict set xppu	F1390000	addr	pmc
		dict set xppu	F13A0000	addr	pmc
		dict set xppu	F13B0000	addr	pmc
		dict set xppu	F13C0000	addr	pmc
		dict set xppu	F13D0000	addr	pmc
		dict set xppu	F13E0000	addr	pmc
		dict set xppu	F13F0000	addr	pmc
		dict set xppu	F1410000	addr	pmc
		dict set xppu	F1420000	addr	pmc
		dict set xppu	F1430000	addr	pmc
		dict set xppu	F1440000	addr	pmc
		dict set xppu	F1450000	addr	pmc
		dict set xppu	F1460000	addr	pmc
		dict set xppu	F1470000	addr	pmc
		dict set xppu	F1480000	addr	pmc
		dict set xppu	F1490000	addr	pmc
		dict set xppu	F14A0000	addr	pmc
		dict set xppu	F14B0000	addr	pmc
		dict set xppu	F14C0000	addr	pmc
		dict set xppu	F14D0000	addr	pmc
		dict set xppu	F14E0000	addr	pmc
		dict set xppu	F14F0000	addr	pmc
		dict set xppu	F1510000	addr	pmc
		dict set xppu	F1520000	addr	pmc
		dict set xppu	F1530000	addr	pmc
		dict set xppu	F1540000	addr	pmc
		dict set xppu	F1550000	addr	pmc
		dict set xppu	F1560000	addr	pmc
		dict set xppu	F1570000	addr	pmc
		dict set xppu	F1590000	addr	pmc
		dict set xppu	F15B0000	addr	pmc
		dict set xppu	F15C0000	addr	pmc
		dict set xppu	F15D0000	addr	pmc
		dict set xppu	F15E0000	addr	pmc
		dict set xppu	F15F0000	addr	pmc
		dict set xppu	F1600000	addr	pmc
		dict set xppu	F1610000	addr	pmc
		dict set xppu	F1620000	addr	pmc
		dict set xppu	F1630000	addr	pmc
		dict set xppu	F1640000	addr	pmc
		dict set xppu	F1650000	addr	pmc
		dict set xppu	F1660000	addr	pmc
		dict set xppu	F1670000	addr	pmc
		dict set xppu	F1680000	addr	pmc
		dict set xppu	F1690000	addr	pmc
		dict set xppu	F16A0000	addr	pmc
		dict set xppu	F16B0000	addr	pmc
		dict set xppu	F16C0000	addr	pmc
		dict set xppu	F16D0000	addr	pmc
		dict set xppu	F16E0000	addr	pmc
		dict set xppu	F16F0000	addr	pmc
		dict set xppu	F1700000	addr	pmc
		dict set xppu	F1710000	addr	pmc
		dict set xppu	F1720000	addr	pmc
		dict set xppu	F1730000	addr	pmc
		dict set xppu	F1740000	addr	pmc
		dict set xppu	F1750000	addr	pmc
		dict set xppu	F1760000	addr	pmc
		dict set xppu	F1770000	addr	pmc
		dict set xppu	F1780000	addr	pmc
		dict set xppu	F1790000	addr	pmc
		dict set xppu	F17A0000	addr	pmc
		dict set xppu	F17B0000	addr	pmc
		dict set xppu	F17C0000	addr	pmc
		dict set xppu	F17D0000	addr	pmc
		dict set xppu	F17E0000	addr	pmc
		dict set xppu	F17F0000	addr	pmc
		dict set xppu	F1800000	addr	pmc
		dict set xppu	F1810000	addr	pmc
		dict set xppu	F1820000	addr	pmc
		dict set xppu	F1830000	addr	pmc
		dict set xppu	F1840000	addr	pmc
		dict set xppu	F1850000	addr	pmc
		dict set xppu	F1860000	addr	pmc
		dict set xppu	F1870000	addr	pmc
		dict set xppu	F1880000	addr	pmc
		dict set xppu	F1890000	addr	pmc
		dict set xppu	F18A0000	addr	pmc
		dict set xppu	F18B0000	addr	pmc
		dict set xppu	F18C0000	addr	pmc
		dict set xppu	F18D0000	addr	pmc
		dict set xppu	F18E0000	addr	pmc
		dict set xppu	F18F0000	addr	pmc
		dict set xppu	F1900000	addr	pmc
		dict set xppu	F1910000	addr	pmc
		dict set xppu	F1920000	addr	pmc
		dict set xppu	F1930000	addr	pmc
		dict set xppu	F1940000	addr	pmc
		dict set xppu	F1950000	addr	pmc
		dict set xppu	F1960000	addr	pmc
		dict set xppu	F1970000	addr	pmc
		dict set xppu	F1980000	addr	pmc
		dict set xppu	F1990000	addr	pmc
		dict set xppu	F19A0000	addr	pmc
		dict set xppu	F19B0000	addr	pmc
		dict set xppu	F19C0000	addr	pmc
		dict set xppu	F19D0000	addr	pmc
		dict set xppu	F19E0000	addr	pmc
		dict set xppu	F19F0000	addr	pmc
		dict set xppu	F1A00000	addr	pmc
		dict set xppu	F1A10000	addr	pmc
		dict set xppu	F1A20000	addr	pmc
		dict set xppu	F1A30000	addr	pmc
		dict set xppu	F1A40000	addr	pmc
		dict set xppu	F1A50000	addr	pmc
		dict set xppu	F1A60000	addr	pmc
		dict set xppu	F1A70000	addr	pmc
		dict set xppu	F1A80000	addr	pmc
		dict set xppu	F1A90000	addr	pmc
		dict set xppu	F1AA0000	addr	pmc
		dict set xppu	F1AB0000	addr	pmc
		dict set xppu	F1AC0000	addr	pmc
		dict set xppu	F1AD0000	addr	pmc
		dict set xppu	F1AE0000	addr	pmc
		dict set xppu	F1AF0000	addr	pmc
		dict set xppu	F1B00000	addr	pmc
		dict set xppu	F1B10000	addr	pmc
		dict set xppu	F1B20000	addr	pmc
		dict set xppu	F1B30000	addr	pmc
		dict set xppu	F1B40000	addr	pmc
		dict set xppu	F1B50000	addr	pmc
		dict set xppu	F1B60000	addr	pmc
		dict set xppu	F1B70000	addr	pmc
		dict set xppu	F1B80000	addr	pmc
		dict set xppu	F1B90000	addr	pmc
		dict set xppu	F1BA0000	addr	pmc
		dict set xppu	F1BB0000	addr	pmc
		dict set xppu	F1BC0000	addr	pmc
		dict set xppu	F1BD0000	addr	pmc
		dict set xppu	F1BE0000	addr	pmc
		dict set xppu	F1BF0000	addr	pmc
		dict set xppu	F1C00000	addr	pmc
		dict set xppu	F1C10000	addr	pmc
		dict set xppu	F1C20000	addr	pmc
		dict set xppu	F1C30000	addr	pmc
		dict set xppu	F1C40000	addr	pmc
		dict set xppu	F1C50000	addr	pmc
		dict set xppu	F1C60000	addr	pmc
		dict set xppu	F1C70000	addr	pmc
		dict set xppu	F1C80000	addr	pmc
		dict set xppu	F1C90000	addr	pmc
		dict set xppu	F1CA0000	addr	pmc
		dict set xppu	F1CB0000	addr	pmc
		dict set xppu	F1CC0000	addr	pmc
		dict set xppu	F1CD0000	addr	pmc
		dict set xppu	F1CE0000	addr	pmc
		dict set xppu	F1CF0000	addr	pmc
		dict set xppu	F1D00000	addr	pmc
		dict set xppu	F1D10000	addr	pmc
		dict set xppu	F1D20000	addr	pmc
		dict set xppu	F1D30000	addr	pmc
		dict set xppu	F1D40000	addr	pmc
		dict set xppu	F1D50000	addr	pmc
		dict set xppu	F1D60000	addr	pmc
		dict set xppu	F1D70000	addr	pmc
		dict set xppu	F1D80000	addr	pmc
		dict set xppu	F1D90000	addr	pmc
		dict set xppu	F1DA0000	addr	pmc
		dict set xppu	F1DB0000	addr	pmc
		dict set xppu	F1DC0000	addr	pmc
		dict set xppu	F1DD0000	addr	pmc
		dict set xppu	F1DE0000	addr	pmc
		dict set xppu	F1DF0000	addr	pmc
		dict set xppu	F1E00000	addr	pmc
		dict set xppu	F1E10000	addr	pmc
		dict set xppu	F1E20000	addr	pmc
		dict set xppu	F1E30000	addr	pmc
		dict set xppu	F1E40000	addr	pmc
		dict set xppu	F1E50000	addr	pmc
		dict set xppu	F1E60000	addr	pmc
		dict set xppu	F1E70000	addr	pmc
		dict set xppu	F1E80000	addr	pmc
		dict set xppu	F1E90000	addr	pmc
		dict set xppu	F1EA0000	addr	pmc
		dict set xppu	F1EB0000	addr	pmc
		dict set xppu	F1EC0000	addr	pmc
		dict set xppu	F1ED0000	addr	pmc
		dict set xppu	F1EE0000	addr	pmc
		dict set xppu	F1EF0000	addr	pmc
		dict set xppu	F1F00000	addr	pmc
		dict set xppu	F1F10000	addr	pmc
		dict set xppu	F1F20000	addr	pmc
		dict set xppu	F1F30000	addr	pmc
		dict set xppu	F1F40000	addr	pmc
		dict set xppu	F1F50000	addr	pmc
		dict set xppu	F1F60000	addr	pmc
		dict set xppu	F1F70000	addr	pmc
		dict set xppu	F1F90000	addr	pmc
		dict set xppu	F1FA0000	addr	pmc
		dict set xppu	F1FB0000	addr	pmc
		dict set xppu	F1FC0000	addr	pmc
		dict set xppu	F1FD0000	addr	pmc
		dict set xppu	F1FE0000	addr	pmc
		dict set xppu	F1FF0000	addr	pmc
		dict set xppu	F0400000	addr	pmc
		dict set xppu	F0500000	addr	pmc
		dict set xppu	F0600000	addr	pmc
		dict set xppu	F0700000	addr	pmc
		dict set xppu	F0900000	addr	pmc
		dict set xppu	F0A00000	addr	pmc
		dict set xppu	F0B00000	addr	pmc
		dict set xppu	F0C00000	addr	pmc
		dict set xppu	F0D00000	addr	pmc
		dict set xppu	F0E00000	addr	pmc
		dict set xppu	F0F00000	addr	pmc
		dict set xppu	F6010000	addr	npi
		dict set xppu	F6020000	addr	npi
		dict set xppu	F6030000	addr	npi
		dict set xppu	F6040000	addr	npi
		dict set xppu	F6050000	addr	npi
		dict set xppu	F6060000	addr	npi
		dict set xppu	F6070000	addr	npi
		dict set xppu	F6080000	addr	npi
		dict set xppu	F6090000	addr	npi
		dict set xppu	F60A0000	addr	npi
		dict set xppu	F60B0000	addr	npi
		dict set xppu	F60C0000	addr	npi
		dict set xppu	F60D0000	addr	npi
		dict set xppu	F60E0000	addr	npi
		dict set xppu	F60F0000	addr	npi
		dict set xppu	F6100000	addr	npi
		dict set xppu	F6110000	addr	npi
		dict set xppu	F6120000	addr	npi
		dict set xppu	F6130000	addr	npi
		dict set xppu	F6140000	addr	npi
		dict set xppu	F6150000	addr	npi
		dict set xppu	F6160000	addr	npi
		dict set xppu	F6170000	addr	npi
		dict set xppu	F6180000	addr	npi
		dict set xppu	F6190000	addr	npi
		dict set xppu	F61A0000	addr	npi
		dict set xppu	F61B0000	addr	npi
		dict set xppu	F61C0000	addr	npi
		dict set xppu	F61D0000	addr	npi
		dict set xppu	F61E0000	addr	npi
		dict set xppu	F61F0000	addr	npi
		dict set xppu	F6200000	addr	npi
		dict set xppu	F6210000	addr	npi
		dict set xppu	F6220000	addr	npi
		dict set xppu	F6230000	addr	npi
		dict set xppu	F6240000	addr	npi
		dict set xppu	F6250000	addr	npi
		dict set xppu	F6260000	addr	npi
		dict set xppu	F6270000	addr	npi
		dict set xppu	F6280000	addr	npi
		dict set xppu	F6290000	addr	npi
		dict set xppu	F62A0000	addr	npi
		dict set xppu	F62B0000	addr	npi
		dict set xppu	F62C0000	addr	npi
		dict set xppu	F62D0000	addr	npi
		dict set xppu	F62E0000	addr	npi
		dict set xppu	F62F0000	addr	npi
		dict set xppu	F6300000	addr	npi
		dict set xppu	F6310000	addr	npi
		dict set xppu	F6320000	addr	npi
		dict set xppu	F6330000	addr	npi
		dict set xppu	F6340000	addr	npi
		dict set xppu	F6350000	addr	npi
		dict set xppu	F6360000	addr	npi
		dict set xppu	F6370000	addr	npi
		dict set xppu	F6380000	addr	npi
		dict set xppu	F6390000	addr	npi
		dict set xppu	F63A0000	addr	npi
		dict set xppu	F63B0000	addr	npi
		dict set xppu	F63C0000	addr	npi
		dict set xppu	F63D0000	addr	npi
		dict set xppu	F63E0000	addr	npi
		dict set xppu	F63F0000	addr	npi
		dict set xppu	F6400000	addr	npi
		dict set xppu	F6410000	addr	npi
		dict set xppu	F6420000	addr	npi
		dict set xppu	F6430000	addr	npi
		dict set xppu	F6440000	addr	npi
		dict set xppu	F6450000	addr	npi
		dict set xppu	F6460000	addr	npi
		dict set xppu	F6470000	addr	npi
		dict set xppu	F6480000	addr	npi
		dict set xppu	F6490000	addr	npi
		dict set xppu	F64A0000	addr	npi
		dict set xppu	F64B0000	addr	npi
		dict set xppu	F64C0000	addr	npi
		dict set xppu	F64D0000	addr	npi
		dict set xppu	F64E0000	addr	npi
		dict set xppu	F64F0000	addr	npi
		dict set xppu	F6500000	addr	npi
		dict set xppu	F6510000	addr	npi
		dict set xppu	F6520000	addr	npi
		dict set xppu	F6530000	addr	npi
		dict set xppu	F6540000	addr	npi
		dict set xppu	F6550000	addr	npi
		dict set xppu	F6560000	addr	npi
		dict set xppu	F6570000	addr	npi
		dict set xppu	F6580000	addr	npi
		dict set xppu	F6590000	addr	npi
		dict set xppu	F65A0000	addr	npi
		dict set xppu	F65B0000	addr	npi
		dict set xppu	F65C0000	addr	npi
		dict set xppu	F65D0000	addr	npi
		dict set xppu	F65E0000	addr	npi
		dict set xppu	F65F0000	addr	npi
		dict set xppu	F6600000	addr	npi
		dict set xppu	F6610000	addr	npi
		dict set xppu	F6620000	addr	npi
		dict set xppu	F6630000	addr	npi
		dict set xppu	F6640000	addr	npi
		dict set xppu	F6650000	addr	npi
		dict set xppu	F6660000	addr	npi
		dict set xppu	F6670000	addr	npi
		dict set xppu	F6680000	addr	npi
		dict set xppu	F6690000	addr	npi
		dict set xppu	F66A0000	addr	npi
		dict set xppu	F66B0000	addr	npi
		dict set xppu	F66C0000	addr	npi
		dict set xppu	F66D0000	addr	npi
		dict set xppu	F66E0000	addr	npi
		dict set xppu	F66F0000	addr	npi
		dict set xppu	F6700000	addr	npi
		dict set xppu	F6710000	addr	npi
		dict set xppu	F6720000	addr	npi
		dict set xppu	F6730000	addr	npi
		dict set xppu	F6740000	addr	npi
		dict set xppu	F6750000	addr	npi
		dict set xppu	F6760000	addr	npi
		dict set xppu	F6770000	addr	npi
		dict set xppu	F6780000	addr	npi
		dict set xppu	F6790000	addr	npi
		dict set xppu	F67A0000	addr	npi
		dict set xppu	F67B0000	addr	npi
		dict set xppu	F67C0000	addr	npi
		dict set xppu	F67D0000	addr	npi
		dict set xppu	F67E0000	addr	npi
		dict set xppu	F67F0000	addr	npi
		dict set xppu	F6800000	addr	npi
		dict set xppu	F6810000	addr	npi
		dict set xppu	F6820000	addr	npi
		dict set xppu	F6830000	addr	npi
		dict set xppu	F6840000	addr	npi
		dict set xppu	F6850000	addr	npi
		dict set xppu	F6860000	addr	npi
		dict set xppu	F6870000	addr	npi
		dict set xppu	F6880000	addr	npi
		dict set xppu	F6890000	addr	npi
		dict set xppu	F68A0000	addr	npi
		dict set xppu	F68B0000	addr	npi
		dict set xppu	F68C0000	addr	npi
		dict set xppu	F68D0000	addr	npi
		dict set xppu	F68E0000	addr	npi
		dict set xppu	F68F0000	addr	npi
		dict set xppu	F6900000	addr	npi
		dict set xppu	F6910000	addr	npi
		dict set xppu	F6920000	addr	npi
		dict set xppu	F6930000	addr	npi
		dict set xppu	F6940000	addr	npi
		dict set xppu	F6950000	addr	npi
		dict set xppu	F6960000	addr	npi
		dict set xppu	F6970000	addr	npi
		dict set xppu	F6980000	addr	npi
		dict set xppu	F6990000	addr	npi
		dict set xppu	F69A0000	addr	npi
		dict set xppu	F69B0000	addr	npi
		dict set xppu	F69C0000	addr	npi
		dict set xppu	F69D0000	addr	npi
		dict set xppu	F69E0000	addr	npi
		dict set xppu	F69F0000	addr	npi
		dict set xppu	F6A00000	addr	npi
		dict set xppu	F6A10000	addr	npi
		dict set xppu	F6A20000	addr	npi
		dict set xppu	F6A30000	addr	npi
		dict set xppu	F6A40000	addr	npi
		dict set xppu	F6A50000	addr	npi
		dict set xppu	F6A60000	addr	npi
		dict set xppu	F6A70000	addr	npi
		dict set xppu	F6A80000	addr	npi
		dict set xppu	F6A90000	addr	npi
		dict set xppu	F6AA0000	addr	npi
		dict set xppu	F6AB0000	addr	npi
		dict set xppu	F6AC0000	addr	npi
		dict set xppu	F6AD0000	addr	npi
		dict set xppu	F6AE0000	addr	npi
		dict set xppu	F6AF0000	addr	npi
		dict set xppu	F6B00000	addr	npi
		dict set xppu	F6B10000	addr	npi
		dict set xppu	F6B20000	addr	npi
		dict set xppu	F6B30000	addr	npi
		dict set xppu	F6B40000	addr	npi
		dict set xppu	F6B50000	addr	npi
		dict set xppu	F6B60000	addr	npi
		dict set xppu	F6B70000	addr	npi
		dict set xppu	F6B80000	addr	npi
		dict set xppu	F6B90000	addr	npi
		dict set xppu	F6BA0000	addr	npi
		dict set xppu	F6BB0000	addr	npi
		dict set xppu	F6BC0000	addr	npi
		dict set xppu	F6BD0000	addr	npi
		dict set xppu	F6BE0000	addr	npi
		dict set xppu	F6BF0000	addr	npi
		dict set xppu	F6C00000	addr	npi
		dict set xppu	F6C10000	addr	npi
		dict set xppu	F6C20000	addr	npi
		dict set xppu	F6C30000	addr	npi
		dict set xppu	F6C40000	addr	npi
		dict set xppu	F6C50000	addr	npi
		dict set xppu	F6C60000	addr	npi
		dict set xppu	F6C70000	addr	npi
		dict set xppu	F6C80000	addr	npi
		dict set xppu	F6C90000	addr	npi
		dict set xppu	F6CA0000	addr	npi
		dict set xppu	F6CB0000	addr	npi
		dict set xppu	F6CC0000	addr	npi
		dict set xppu	F6CD0000	addr	npi
		dict set xppu	F6CE0000	addr	npi
		dict set xppu	F6CF0000	addr	npi
		dict set xppu	F6D00000	addr	npi
		dict set xppu	F6D10000	addr	npi
		dict set xppu	F6D20000	addr	npi
		dict set xppu	F6D30000	addr	npi
		dict set xppu	F6D40000	addr	npi
		dict set xppu	F6D50000	addr	npi
		dict set xppu	F6D60000	addr	npi
		dict set xppu	F6D70000	addr	npi
		dict set xppu	F6D80000	addr	npi
		dict set xppu	F6D90000	addr	npi
		dict set xppu	F6DA0000	addr	npi
		dict set xppu	F6DB0000	addr	npi
		dict set xppu	F6DC0000	addr	npi
		dict set xppu	F6DD0000	addr	npi
		dict set xppu	F6DE0000	addr	npi
		dict set xppu	F6DF0000	addr	npi
		dict set xppu	F6E00000	addr	npi
		dict set xppu	F6E10000	addr	npi
		dict set xppu	F6E20000	addr	npi
		dict set xppu	F6E30000	addr	npi
		dict set xppu	F6E40000	addr	npi
		dict set xppu	F6E50000	addr	npi
		dict set xppu	F6E60000	addr	npi
		dict set xppu	F6E70000	addr	npi
		dict set xppu	F6E80000	addr	npi
		dict set xppu	F6E90000	addr	npi
		dict set xppu	F6EA0000	addr	npi
		dict set xppu	F6EB0000	addr	npi
		dict set xppu	F6EC0000	addr	npi
		dict set xppu	F6ED0000	addr	npi
		dict set xppu	F6EE0000	addr	npi
		dict set xppu	F6EF0000	addr	npi
		dict set xppu	F6F00000	addr	npi
		dict set xppu	F6F10000	addr	npi
		dict set xppu	F6F20000	addr	npi
		dict set xppu	F6F30000	addr	npi
		dict set xppu	F6F40000	addr	npi
		dict set xppu	F6F50000	addr	npi
		dict set xppu	F6F60000	addr	npi
		dict set xppu	F6F70000	addr	npi
		dict set xppu	F6F80000	addr	npi
		dict set xppu	F6F90000	addr	npi
		dict set xppu	F6FA0000	addr	npi
		dict set xppu	F6FB0000	addr	npi
		dict set xppu	F6FC0000	addr	npi
		dict set xppu	F6FD0000	addr	npi
		dict set xppu	F6FE0000	addr	npi
		dict set xppu	F6FF0000	addr	npi
		dict set xppu	F7000000	addr	npi
		dict set xppu	F7100000	addr	npi
		dict set xppu	F7200000	addr	npi
		dict set xppu	F7300000	addr	npi
		dict set xppu	F7400000	addr	npi
		dict set xppu	F7500000	addr	npi
		dict set xppu	F7600000	addr	npi
		dict set xppu	F7700000	addr	npi
		dict set xppu	F7800000	addr	npi
		dict set xppu	F7900000	addr	npi
		dict set xppu	F7A00000	addr	npi
		dict set xppu	F7B00000	addr	npi
		dict set xppu	F7C00000	addr	npi
		dict set xppu	F7D00000	addr	npi
		dict set xppu	F7E00000	addr	npi
		dict set xppu	F7F00000	addr	npi
		set baseaddr [string toupper $baseaddr]
		set tmp ""
		if {[catch {set tmp [dict get $xppu $baseaddr addr]} msg]} {
		}
		
		if {[string match -nocase $tmp "lpd"]} {
			set prop "lpd_xppu"
		}
		if {[string match -nocase $tmp "pmc"]} {
			set prop "pmc_xppu"
		}
		if {[string match -nocase $tmp "npi"]} {
			set prop "pmc_xppu_npi"
		}
		if {[string match -nocase $tmp "xmpu_pmc"]} {
			set prop "pmc_xmpu"
		}
		if {[string match -nocase $tmp "xmpu_fpd"]} {
			set prop "fpd_xmpu"
		}
		if {[string match -nocase $tmp "xmpu_ocm"]} {
			set prop "ocm_xmpu"
		}
		
		if {![string match -nocase $tmp ""]} {
			add_prop $node "firewall-0" $prop reference "pcw.dtsi"
		}
		set valid_list "psv_ethernet psv_pmc_sd psv_adma psv_pmc_dma psv_usb_xhci psv_pmc_qspi psv_pmc_ospi"
		set idlist [dict create]
		dict set idlist FF0C0000 id 0x234
		dict set idlist FF0D0000 id 0x235
		dict set idlist F1040000 id 0x242
		dict set idlist F1050000 id 0x243
		dict set idlist FFA80000 id 0x210
		dict set idlist FFA90000 id 0x212
		dict set idlist FFAA0000 id 0x214
		dict set idlist FFAB0000 id 0x216
		dict set idlist FFAC0000 id 0x218
		dict set idlist FFAD0000 id 0x21a
		dict set idlist FFAE0000 id 0x21c
		dict set idlist FFAF0000 id 0x21e
		dict set idlist FE200000 id 0x230
		dict set idlist F1030000 id 0x244
		
		set ip_name ""
		if {[catch {set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]} msg]} {
		}
		if {![string match -nocase $ip_name ""]} {
			if {[lsearch $valid_list $ip_name] >=0} {
				if {![string match -nocase $tmp ""]} {
					set tmp ""
					if {[catch {set tmp [dict get $idlist $baseaddr id]} msg]} {
					}
					if {![string match -nocase $tmp ""]} {
						add_prop $node "bus-master-id" "&$prop $tmp" hexlist "pcw.dtsi"
					}
				}
			}	
		}

    } elseif {[is_zynqmp_platform $family]} {
		dict set xppu FF000000 addr lpd
		dict set xppu FF010000 addr lpd
		dict set xppu FF020000 addr lpd
		dict set xppu FF030000 addr lpd
		dict set xppu FF040000 addr lpd
		dict set xppu FF050000 addr lpd
		dict set xppu FF060000 addr lpd
		dict set xppu FF070000 addr lpd
		dict set xppu FF080000 addr lpd
		dict set xppu FF090000 addr lpd
		dict set xppu FF0A0000 addr lpd
		dict set xppu FF0B0000 addr lpd
		dict set xppu FF0C0000 addr lpd
		dict set xppu FF0D0000 addr lpd
		dict set xppu FF0E0000 addr lpd
		dict set xppu FF0F0000 addr lpd
		dict set xppu FF100000 addr lpd
		dict set xppu FF110000 addr lpd
		dict set xppu FF120000 addr lpd
		dict set xppu FF130000 addr lpd
		dict set xppu FF140000 addr lpd
		dict set xppu FF150000 addr lpd
		dict set xppu FF160000 addr lpd
		dict set xppu FF170000 addr lpd
		dict set xppu FF180000 addr lpd
		dict set xppu FF190000 addr lpd
		dict set xppu FF1A0000 addr lpd
		dict set xppu FF1B0000 addr lpd
		dict set xppu FF1C0000 addr lpd
		dict set xppu FF1D0000 addr lpd
		dict set xppu FF1E0000 addr lpd
		dict set xppu FF1F0000 addr lpd
		dict set xppu FF200000 addr lpd
		dict set xppu FF210000 addr lpd
		dict set xppu FF220000 addr lpd
		dict set xppu FF230000 addr lpd
		dict set xppu FF240000 addr lpd
		dict set xppu FF250000 addr lpd
		dict set xppu FF260000 addr lpd
		dict set xppu FF270000 addr lpd
		dict set xppu FF280000 addr lpd
		dict set xppu FF290000 addr lpd
		dict set xppu FF2A0000 addr lpd
		dict set xppu FF2B0000 addr lpd
		dict set xppu FF2C0000 addr lpd
		dict set xppu FF2D0000 addr lpd
		dict set xppu FF2E0000 addr lpd
		dict set xppu FF2F0000 addr lpd
		dict set xppu FF300000 addr lpd
		dict set xppu FF310000 addr lpd
		dict set xppu FF320000 addr lpd
		dict set xppu FF330000 addr lpd
		dict set xppu FF340000 addr lpd
		dict set xppu FF350000 addr lpd
		dict set xppu FF360000 addr lpd
		dict set xppu FF370000 addr lpd
		dict set xppu FF380000 addr lpd
		dict set xppu FF390000 addr lpd
		dict set xppu FF3A0000 addr lpd
		dict set xppu FF3B0000 addr lpd
		dict set xppu FF3C0000 addr lpd
		dict set xppu FF3D0000 addr lpd
		dict set xppu FF3E0000 addr lpd
		dict set xppu FF3F0000 addr lpd
		dict set xppu FF400000 addr lpd
		dict set xppu FF410000 addr lpd
		dict set xppu FF420000 addr lpd
		dict set xppu FF430000 addr lpd
		dict set xppu FF440000 addr lpd
		dict set xppu FF450000 addr lpd
		dict set xppu FF460000 addr lpd
		dict set xppu FF470000 addr lpd
		dict set xppu FF480000 addr lpd
		dict set xppu FF490000 addr lpd
		dict set xppu FF4A0000 addr lpd
		dict set xppu FF4B0000 addr lpd
		dict set xppu FF4C0000 addr lpd
		dict set xppu FF4D0000 addr lpd
		dict set xppu FF4E0000 addr lpd
		dict set xppu FF4F0000 addr lpd
		dict set xppu FF500000 addr lpd
		dict set xppu FF510000 addr lpd
		dict set xppu FF520000 addr lpd
		dict set xppu FF530000 addr lpd
		dict set xppu FF540000 addr lpd
		dict set xppu FF550000 addr lpd
		dict set xppu FF560000 addr lpd
		dict set xppu FF570000 addr lpd
		dict set xppu FF580000 addr lpd
		dict set xppu FF590000 addr lpd
		dict set xppu FF5A0000 addr lpd
		dict set xppu FF5B0000 addr lpd
		dict set xppu FF5C0000 addr lpd
		dict set xppu FF5D0000 addr lpd
		dict set xppu FF5E0000 addr lpd
		dict set xppu FF5F0000 addr lpd
		dict set xppu FF600000 addr lpd
		dict set xppu FF610000 addr lpd
		dict set xppu FF620000 addr lpd
		dict set xppu FF630000 addr lpd
		dict set xppu FF640000 addr lpd
		dict set xppu FF650000 addr lpd
		dict set xppu FF660000 addr lpd
		dict set xppu FF670000 addr lpd
		dict set xppu FF680000 addr lpd
		dict set xppu FF690000 addr lpd
		dict set xppu FF6A0000 addr lpd
		dict set xppu FF6B0000 addr lpd
		dict set xppu FF6C0000 addr lpd
		dict set xppu FF6D0000 addr lpd
		dict set xppu FF6E0000 addr lpd
		dict set xppu FF6F0000 addr lpd
		dict set xppu FF700000 addr lpd
		dict set xppu FF710000 addr lpd
		dict set xppu FF720000 addr lpd
		dict set xppu FF730000 addr lpd
		dict set xppu FF740000 addr lpd
		dict set xppu FF750000 addr lpd
		dict set xppu FF760000 addr lpd
		dict set xppu FF770000 addr lpd
		dict set xppu FF780000 addr lpd
		dict set xppu FF790000 addr lpd
		dict set xppu FF7A0000 addr lpd
		dict set xppu FF7B0000 addr lpd
		dict set xppu FF7C0000 addr lpd
		dict set xppu FF7D0000 addr lpd
		dict set xppu FF7E0000 addr lpd
		dict set xppu FF7F0000 addr lpd
		dict set xppu FF800000 addr lpd
		dict set xppu FF810000 addr lpd
		dict set xppu FF820000 addr lpd
		dict set xppu FF830000 addr lpd
		dict set xppu FF840000 addr lpd
		dict set xppu FF850000 addr lpd
		dict set xppu FF860000 addr lpd
		dict set xppu FF870000 addr lpd
		dict set xppu FF880000 addr lpd
		dict set xppu FF890000 addr lpd
		dict set xppu FF8A0000 addr lpd
		dict set xppu FF8B0000 addr lpd
		dict set xppu FF8C0000 addr lpd
		dict set xppu FF8D0000 addr lpd
		dict set xppu FF8E0000 addr lpd
		dict set xppu FF8F0000 addr lpd
		dict set xppu FF900000 addr lpd
		dict set xppu FF910000 addr lpd
		dict set xppu FF920000 addr lpd
		dict set xppu FF930000 addr lpd
		dict set xppu FF940000 addr lpd
		dict set xppu FF950000 addr lpd
		dict set xppu FF960000 addr lpd
		dict set xppu FF970000 addr lpd
		dict set xppu FF980000 addr lpd
		dict set xppu FF990000 addr lpd
		dict set xppu FF9A0000 addr lpd
		dict set xppu FF9B0000 addr lpd
		dict set xppu FF9C0000 addr lpd
		dict set xppu FF9D0000 addr lpd
		dict set xppu FF9E0000 addr lpd
		dict set xppu FF9F0000 addr lpd
		dict set xppu FFA00000 addr lpd
		dict set xppu FFA10000 addr lpd
		dict set xppu FFA20000 addr lpd
		dict set xppu FFA30000 addr lpd
		dict set xppu FFA40000 addr lpd
		dict set xppu FFA50000 addr lpd
		dict set xppu FFA60000 addr lpd
		dict set xppu FFA70000 addr lpd
		dict set xppu FFA80000 addr lpd
		dict set xppu FFA90000 addr lpd
		dict set xppu FFAA0000 addr lpd
		dict set xppu FFAB0000 addr lpd
		dict set xppu FFAC0000 addr lpd
		dict set xppu FFAD0000 addr lpd
		dict set xppu FFAE0000 addr lpd
		dict set xppu FFAF0000 addr lpd
		dict set xppu FFB00000 addr lpd
		dict set xppu FFB10000 addr lpd
		dict set xppu FFB20000 addr lpd
		dict set xppu FFB30000 addr lpd
		dict set xppu FFB40000 addr lpd
		dict set xppu FFB50000 addr lpd
		dict set xppu FFB60000 addr lpd
		dict set xppu FFB70000 addr lpd
		dict set xppu FFB80000 addr lpd
		dict set xppu FFB90000 addr lpd
		dict set xppu FFBA0000 addr lpd
		dict set xppu FFBB0000 addr lpd
		dict set xppu FFBC0000 addr lpd
		dict set xppu FFBD0000 addr lpd
		dict set xppu FFBE0000 addr lpd
		dict set xppu FFBF0000 addr lpd
		dict set xppu FFC00000 addr lpd
		dict set xppu FFC10000 addr lpd
		dict set xppu FFC20000 addr lpd
		dict set xppu FFC30000 addr lpd
		dict set xppu FFC40000 addr lpd
		dict set xppu FFC50000 addr lpd
		dict set xppu FFC60000 addr lpd
		dict set xppu FFC70000 addr lpd
		dict set xppu FFC80000 addr lpd
		dict set xppu FFC90000 addr lpd
		dict set xppu FFCA0000 addr lpd
		dict set xppu FFCB0000 addr lpd
		dict set xppu FFCC0000 addr lpd
		dict set xppu FFCD0000 addr lpd
		dict set xppu FFCE0000 addr lpd
		dict set xppu FFCF0000 addr lpd
		dict set xppu FFD00000 addr lpd
		dict set xppu FFD10000 addr lpd
		dict set xppu FFD20000 addr lpd
		dict set xppu FFD30000 addr lpd
		dict set xppu FFD40000 addr lpd
		dict set xppu FFD50000 addr lpd
		dict set xppu FFD60000 addr lpd
		dict set xppu FFD70000 addr lpd
		dict set xppu FFD80000 addr lpd
		dict set xppu FFD90000 addr lpd
		dict set xppu FFDA0000 addr lpd
		dict set xppu FFDB0000 addr lpd
		dict set xppu FFDC0000 addr lpd
		dict set xppu FFDD0000 addr lpd
		dict set xppu FFDE0000 addr lpd
		dict set xppu FFDF0000 addr lpd
		dict set xppu FFE00000 addr lpd
		dict set xppu FFE10000 addr lpd
		dict set xppu FFE20000 addr lpd
		dict set xppu FFE30000 addr lpd
		dict set xppu FFE40000 addr lpd
		dict set xppu FFE50000 addr lpd
		dict set xppu FFE60000 addr lpd
		dict set xppu FFE70000 addr lpd
		dict set xppu FFE80000 addr lpd
		dict set xppu FFE90000 addr lpd
		dict set xppu FFEA0000 addr lpd
		dict set xppu FFEB0000 addr lpd
		dict set xppu FFEC0000 addr lpd
		dict set xppu FFED0000 addr lpd
		dict set xppu FFEE0000 addr lpd
		dict set xppu FFEF0000 addr lpd
		dict set xppu FFF00000 addr lpd
		dict set xppu FFF10000 addr lpd
		dict set xppu FFF20000 addr lpd
		dict set xppu FFF30000 addr lpd
		dict set xppu FFF40000 addr lpd
		dict set xppu FFF50000 addr lpd
		dict set xppu FFF60000 addr lpd
		dict set xppu FFF70000 addr lpd
		dict set xppu FFF80000 addr lpd
		dict set xppu FFF90000 addr lpd
		dict set xppu FFFA0000 addr lpd
		dict set xppu FFFB0000 addr lpd
		dict set xppu FFFC0000 addr lpd
		dict set xppu FFFD0000 addr lpd
		dict set xppu FFFE0000 addr lpd
		dict set xppu FFFF0000 addr lpd
		dict set xppu FF990000 addr lpd
		dict set xppu FF990020 addr lpd
		dict set xppu FF990040 addr lpd
		dict set xppu FF990060 addr lpd
		dict set xppu FF990080 addr lpd
		dict set xppu FF9900A0 addr lpd
		dict set xppu FF9900C0 addr lpd
		dict set xppu FF9900E0 addr lpd
		dict set xppu FF990100 addr lpd
		dict set xppu FF990120 addr lpd
		dict set xppu FF990140 addr lpd
		dict set xppu FF990160 addr lpd
		dict set xppu FF990180 addr lpd
		dict set xppu FF9901A0 addr lpd
		dict set xppu FF9901C0 addr lpd
		dict set xppu FF9901E0 addr lpd
		dict set xppu FF990200 addr lpd
		dict set xppu FF990220 addr lpd
		dict set xppu FF990240 addr lpd
		dict set xppu FF990260 addr lpd
		dict set xppu FF990280 addr lpd
		dict set xppu FF9902A0 addr lpd
		dict set xppu FF9902C0 addr lpd
		dict set xppu FF9902E0 addr lpd
		dict set xppu FF990300 addr lpd
		dict set xppu FF990320 addr lpd
		dict set xppu FF990340 addr lpd
		dict set xppu FF990360 addr lpd
		dict set xppu FF990380 addr lpd
		dict set xppu FF9903A0 addr lpd
		dict set xppu FF9903C0 addr lpd
		dict set xppu FF9903E0 addr lpd
		dict set xppu FF990400 addr lpd
		dict set xppu FF990420 addr lpd
		dict set xppu FF990440 addr lpd
		dict set xppu FF990460 addr lpd
		dict set xppu FF990480 addr lpd
		dict set xppu FF9904A0 addr lpd
		dict set xppu FF9904C0 addr lpd
		dict set xppu FF9904E0 addr lpd
		dict set xppu FF990500 addr lpd
		dict set xppu FF990520 addr lpd
		dict set xppu FF990540 addr lpd
		dict set xppu FF990560 addr lpd
		dict set xppu FF990580 addr lpd
		dict set xppu FF9905A0 addr lpd
		dict set xppu FF9905C0 addr lpd
		dict set xppu FF9905E0 addr lpd
		dict set xppu FF990600 addr lpd
		dict set xppu FF990620 addr lpd
		dict set xppu FF990640 addr lpd
		dict set xppu FF990660 addr lpd
		dict set xppu FF990680 addr lpd
		dict set xppu FF9906A0 addr lpd
		dict set xppu FF9906C0 addr lpd
		dict set xppu FF9906E0 addr lpd
		dict set xppu FF990700 addr lpd
		dict set xppu FF990720 addr lpd
		dict set xppu FF990740 addr lpd
		dict set xppu FF990760 addr lpd
		dict set xppu FF990780 addr lpd
		dict set xppu FF9907A0 addr lpd
		dict set xppu FF9907C0 addr lpd
		dict set xppu FF9907E0 addr lpd
		dict set xppu FF990800 addr lpd
		dict set xppu FF990820 addr lpd
		dict set xppu FF990840 addr lpd
		dict set xppu FF990860 addr lpd
		dict set xppu FF990880 addr lpd
		dict set xppu FF9908A0 addr lpd
		dict set xppu FF9908C0 addr lpd
		dict set xppu FF9908E0 addr lpd
		dict set xppu FF990900 addr lpd
		dict set xppu FF990920 addr lpd
		dict set xppu FF990940 addr lpd
		dict set xppu FF990960 addr lpd
		dict set xppu FF990980 addr lpd
		dict set xppu FF9909A0 addr lpd
		dict set xppu FF9909C0 addr lpd
		dict set xppu FF9909E0 addr lpd
		dict set xppu FF990A00 addr lpd
		dict set xppu FF990A20 addr lpd
		dict set xppu FF990A40 addr lpd
		dict set xppu FF990A60 addr lpd
		dict set xppu FF990A80 addr lpd
		dict set xppu FF990AA0 addr lpd
		dict set xppu FF990AC0 addr lpd
		dict set xppu FF990AE0 addr lpd
		dict set xppu FF990B00 addr lpd
		dict set xppu FF990B20 addr lpd
		dict set xppu FF990B40 addr lpd
		dict set xppu FF990B60 addr lpd
		dict set xppu FF990B80 addr lpd
		dict set xppu FF990BA0 addr lpd
		dict set xppu FF990BC0 addr lpd
		dict set xppu FF990BE0 addr lpd
		dict set xppu FF990C00 addr lpd
		dict set xppu FF990C20 addr lpd
		dict set xppu FF990C40 addr lpd
		dict set xppu FF990C60 addr lpd
		dict set xppu FF990C80 addr lpd
		dict set xppu FF990CA0 addr lpd
		dict set xppu FF990CC0 addr lpd
		dict set xppu FF990CE0 addr lpd
		dict set xppu FF990D00 addr lpd
		dict set xppu FF990D20 addr lpd
		dict set xppu FF990D40 addr lpd
		dict set xppu FF990D60 addr lpd
		dict set xppu FF990D80 addr lpd
		dict set xppu FF990DA0 addr lpd
		dict set xppu FF990DC0 addr lpd
		dict set xppu FF990DE0 addr lpd
		dict set xppu FF990E00 addr lpd
		dict set xppu FF990E20 addr lpd
		dict set xppu FF990E40 addr lpd
		dict set xppu FF990E60 addr lpd
		dict set xppu FF990E80 addr lpd
		dict set xppu FF990EA0 addr lpd
		dict set xppu FF990EC0 addr lpd
		dict set xppu FF990EE0 addr lpd
		dict set xppu FF990F00 addr lpd
		dict set xppu FF990F20 addr lpd
		dict set xppu FF990F40 addr lpd
		dict set xppu FF990F60 addr lpd
		dict set xppu FF990F80 addr lpd
		dict set xppu FF990FA0 addr lpd
		dict set xppu FF990FC0 addr lpd
		dict set xppu FF990FE0 addr lpd
		dict set xppu FE000000 addr lpd
		dict set xppu FE100000 addr lpd
		dict set xppu FE200000 addr lpd
		dict set xppu FE300000 addr lpd
		dict set xppu FE400000 addr lpd
		dict set xppu FE500000 addr lpd
		dict set xppu FE600000 addr lpd
		dict set xppu FE700000 addr lpd
		dict set xppu FE800000 addr lpd
		dict set xppu FE900000 addr lpd
		dict set xppu FEA00000 addr lpd
		dict set xppu FEB00000 addr lpd
		dict set xppu FEC00000 addr lpd
		dict set xppu FED00000 addr lpd
		dict set xppu FEE00000 addr lpd
		dict set xppu FEF00000 addr lpd
		set baseaddr [string toupper $baseaddr]
		set tmp ""
		if {[catch {set tmp [dict get $xppu $baseaddr addr]} msg]} {
		}
		if {[string match -nocase $tmp "lpd"]} {
			set prop "lpd_xppu"
		}

		if {![string match -nocase $tmp ""]} {
			add_prop $node "firewall-0" $prop reference "pcw.dtsi"
		}
		set valid_list "psu_ethernet psu_sd psu_adma psu_gdma psu_usb_xhci psu_qspi"
		set idlist [dict create]
		dict set idlist FFA80000 id 0x868
		dict set idlist FFA90000 id 0x869
		dict set idlist FFAA0000 id 0x86a
		dict set idlist FFAB0000 id 0x86b
		dict set idlist FFAC0000 id 0x86c
		dict set idlist FFAD0000 id 0x86d
		dict set idlist FFAE0000 id 0x86e
		dict set idlist FFAF0000 id 0x86f
		dict set idlist FF100000 id 0x872
		dict set idlist FF0B0000 id 0x874
		dict set idlist FF0C0000 id 0x875
		dict set idlist FF0D0000 id 0x876
		dict set idlist FE0E0000 id 0x877
		dict set idlist FF0F0000 id 0x873
		dict set idlist FF160000 id 0x870
		dict set idlist FF170000 id 0x870
		dict set idlist FE200000 id 0x860
		dict set idlist FE300000 id 0x861
		
		set ip_name ""
		if {[catch {set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]} msg]} {
		}
		if {![string match -nocase $ip_name ""]} {
			if {[lsearch $valid_list $ip_name] >=0} {
				if {![string match -nocase $tmp ""]} {
					set tmp ""
					if {[catch {set tmp [dict get $idlist $baseaddr id]} msg]} {
					}
					if {![string match -nocase $tmp ""]} {
						add_prop $node "bus-master-id" "&$prop $tmp" hexlist "pcw.dtsi"
					}
				}
			}	
		}
	}
}

proc gen_power_domains {drv_handle} {
        global env
        global is_versal_net_platform
        global is_versal_2ve_2vm_platform

        set path $env(CUSTOM_SDT_REPO)
        set common_file "$path/device_tree/data/config.yaml"
        set ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
        set node [get_node $drv_handle]
        set baseaddr [get_baseaddr $drv_handle noprefix]
        set node_id [dict create]
        set family [get_hw_family]

        if {[string match -nocase $family "versal"] && [is_ps_ip $drv_handle]} {
		if { $is_versal_net_platform } {
			if { $is_versal_2ve_2vm_platform } {
				return
			}
			set firmware_name "versal_net_firmware"
			dict set node_id EBA00000 id 0x183180CB
			dict set node_id EBA10000 id 0x183180CC
			dict set node_id EBA20000 id 0x183180CD
			dict set node_id EBA40000 id 0x183180CE
			dict set node_id EBA50000 id 0x183180CF
			dict set node_id EBA60000 id 0x183180D0
			dict set node_id EBA80000 id 0x183180D1
			dict set node_id EBA90000 id 0x183180D2
			dict set node_id EBAA0000 id 0x183180D3
			dict set node_id EBAC0000 id 0x183180D4
			dict set node_id EBAD0000 id 0x183180D5
			dict set node_id EBAE0000 id 0x183180D6
		} else {
			set firmware_name "versal_firmware"
			dict set node_id FFE00000 id 0x1831800b
			dict set node_id FFE20000 id 0x1831800c
			dict set node_id FFE90000 id 0x1831800d
			dict set node_id FFEB0000 id 0x1831800e
			dict set node_id psv_tcm_global id 0x1831800b
			dict set node_id psv_r5_0_atcm_lockstep id 0x1831800b
			dict set node_id psv_r5_0_btcm_lockstep id 0x1831800c
			dict set node_id psv_r5_1_atcm_lockstep id 0x1831800d
			dict set node_id psv_r5_1_btcm_lockstep id 0x1831800e
			dict set node_id psv_ocm id 0x18314007
		}

               set baseaddr [string toupper $baseaddr]
               set tmp ""
               if {[catch {set tmp [dict get $node_id $ip id]} msg]} {
               }
               if {[catch {set tmp [dict get $node_id $baseaddr id]} msg]} {
               }

               if {![string match -nocase $tmp ""]} {
                       add_prop $node "power-domains" "$firmware_name $tmp" reference "pcw.dtsi"
               }
       } elseif {[is_zynqmp_platform $family]} {
               dict set node_id psu_r5_0_atcm_global id 15
               dict set node_id psu_r5_0_btcm_global id 16
               dict set node_id psu_r5_1_atcm_global id 17
               dict set node_id psu_r5_1_btcm_global id 18
               dict set node_id psu_r5_0_atcm id 15
               dict set node_id psu_r5_0_btcm id 16
               dict set node_id psu_r5_1_atcm id 17
               dict set node_id psu_r5_1_btcm id 18
               dict set node_id psu_r5_tcm_ram_0 15
               dict set node_id psu_r5_0_atcm_lockstep id 15
               dict set node_id psu_r5_0_btcm_lockstep id 16
               dict set node_id psu_r5_tcm_ram_global id 15
               dict set node_id psu_r5_0_atcm id 15
               dict set node_id psu_r5_0_btcm id 16
               dict set node_id psu_r5_1_atcm id 17
               dict set node_id psu_r5_1_btcm id 18
               dict set node_id psu_r5_tcm_ram id 15
               dict set node_id psu_ocm_ram_0 id 11
               set tmp ""
               if {[catch {set tmp [dict get $node_id $ip id]} msg]} {
               }
               set prop "zynqmp_firmware $tmp"

               if {![string match -nocase $tmp ""]} {
                       add_prop $node "power-domains" $prop reference "pcw.dtsi"
               }
       }
}

proc copy_hw_files args {
	if {[llength $args]!= 0} {
		set help_string "
\tCopy hardware artifacts of a given xsa to output directory.
\tUSAGE: sdtgen set_dt_param -dir <output directory path> -xsa <xsa file>
\t       sdtgen copy_hw_files"

		return $help_string
        }

    	global env
	if {[catch {set xsa $env(xsa)} msg]} {
 		error "\[DTG++ ERROR]:  No xsa provided, please set the xsa \
		        \n\r            Ex: set_dt_param -xsa <system.xsa>"
		return
	}

	if {[catch {set dir $env(dir)} msg]} {
		error "\[DTG++ ERROR]:  No dir provided, please set the -dir option \
		        \n\r            Ex: set_dt_param -dir <dir path with write permission>"
		return
	}

	set cur_hw_design [hsi::get_hw_designs]
	if {[string match -nocase $cur_hw_design ""]} {
		if [catch { set retstr [file mkdir $dir] } errmsg] {
			error "cannot create the passed directory: $env(dir)"
			return
		}
		file copy -force $xsa $dir

		set xsa_name [file tail $xsa]
		set xsa_path "$dir/$xsa_name"
		hsi::open_hw_design "$xsa_path"
		file delete -force "$xsa_path"
	}
}
