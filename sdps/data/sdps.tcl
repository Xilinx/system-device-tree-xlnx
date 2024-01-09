#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc sdps_generate {drv_handle} {
        set ip [hsi::get_cells -hier $drv_handle]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set clk_freq [get_ip_param_value $ip C_SDIO_CLK_FREQ_HZ]
        add_prop $node "clock-frequency" $clk_freq hexint $dts_file
        set_drv_conf_prop $drv_handle C_MIO_BANK xlnx,mio-bank $node hexint
        set_drv_conf_prop $drv_handle C_HAS_CD xlnx,card-detect $node int
        set_drv_conf_prop $drv_handle C_HAS_WP xlnx,write-protect $node int
        set_drv_conf_prop $drv_handle C_SLOT_TYPE xlnx,slot-type $node int
        set_drv_conf_prop $drv_handle C_CLK_50_SDR_ITAP_DLY xlnx,clk-50-sdr-itap-dly $node hexint
        set_drv_conf_prop $drv_handle C_CLK_50_SDR_OTAP_DLY xlnx,clk-50-sdr-otap-dly $node hexint
        set_drv_conf_prop $drv_handle C_CLK_50_DDR_ITAP_DLY xlnx,clk-50-ddr-itap-dly $node hexint
        set_drv_conf_prop $drv_handle C_CLK_50_DDR_OTAP_DLY xlnx,clk-50-ddr-otap-dly $node hexint
        set_drv_conf_prop $drv_handle C_CLK_100_SDR_OTAP_DLY xlnx,clk-100-sdr-otap-dly $node hexint
        set_drv_conf_prop $drv_handle C_CLK_200_SDR_OTAP_DLY xlnx,clk-200-sdr-otap-dly $node hexint
        set_drv_conf_prop $drv_handle C_CLK_200_DDR_OTAP_DLY xlnx,clk-200-ddr-otap-dly $node hexint
    }


