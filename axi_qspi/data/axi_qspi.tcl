#
# (C) Copyright 2014-2022 Xilinx, Inc.
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

    proc axi_qspi_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,xps-spi-2.00.a\""
        set_drv_conf_prop $drv_handle "C_NUM_SS_BITS" "xlnx,num-ss-bits" $node
        set_drv_conf_prop $drv_handle "C_NUM_SS_BITS" "num-cs" $node
        set_drv_conf_prop $drv_handle "C_NUM_TRANSFER_BITS" "bits-per-word" $node int
        set_drv_conf_prop $drv_handle "C_FIFO_DEPTH" "fifo-size" $node int
        set_drv_conf_prop $drv_handle "C_SPI_MODE" "xlnx,spi-mode" $node int
        set_drv_conf_prop $drv_handle "C_USE_STARTUP" "xlnx,startup-block" $node boolean
        set avail_param [hsi list_property [hsi::get_cells -hier $drv_handle]]
        set value [hsi get_property CONFIG.C_FIFO_EXIST [hsi::get_cells -hier $drv_handle]]
        if {[llength $value] == 0} {
                set value1 [hsi get_property CONFIG.C_FIFO_DEPTH [hsi::get_cells -hier $drv_handle]]
                if {[llength $value1] == 0} {
                        set value1 0
                } else {
                        set value1 [hsi get_property CONFIG.C_FIFO_DEPTH $drv_handle]
                        if {$value1 == 0} {
                                set value1 0
                        } else {
                                set value1 1
                        }
                }
        } else {
                set value1 $value
        }
        add_prop $node "xlnx,hasfifos" $value1 int "pl.dtsi"
        set value [hsi get_property CONFIG.C_SPI_SLAVE_ONLY [hsi::get_cells -hier $drv_handle]]
        if {[llength $value] == 0} {
                add_prop $node "xlnx,slaveonly" 0 int "pl.dtsi"
        } else {
                add_prop $node "xlnx,slaveonly" $value int "pl.dtsi"
        }
        set_drv_conf_prop $drv_handle "C_TYPE_OF_AXI4_INTERFACE" "xlnx,axi-interface" $node int
        set value [hsi get_property CONFIG.C_S_AXI4_BASEADDR [hsi::get_cells -hier $drv_handle]]
        if {[llength $value] == 0} {
                add_prop $node "xlnx,Axi4-address" 0 int "pl.dtsi"
        } else {
                add_prop $node "xlnx,Axi4-address" $value int "pl.dtsi"
        }
        set_drv_conf_prop $drv_handle "C_XIP_MODE" "xlnx,xip-mode" $node int
    }


