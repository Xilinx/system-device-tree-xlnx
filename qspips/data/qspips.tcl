#
# (C) Copyright 2014-2015 Xilinx, Inc.
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

namespace eval qspips {
	proc generate {drv_handle} {
		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		set slave [hsi::get_cells -hier $drv_handle]
		set qspi_mode [hsi::utils::get_ip_param_value $slave "C_QSPI_MODE"]
		if { $qspi_mode == 2} {
			set is_dual 1
		} else {
			set is_dual 0
		}
		add_prop $node "is-dual" $is_dual int $dts_file
		set bus_width [get_property CONFIG.C_QSPI_BUS_WIDTH [hsi::get_cells -hier $drv_handle]]

		switch $bus_width {
			"3" {
				add_prop $node "spi-tx-bus-width" 8 int $dts_file
				add_prop $node "spi-rx-bus-width" 8 int $dts_file
			}
			"2" {
				add_prop $node "spi-tx-bus-width" 4 int $dts_file
				add_prop $node "spi-rx-bus-width" 4 int $dts_file
			}
			"1" {
				add_prop $node "spi-tx-bus-width" 2 int $dts_file
				add_prop $node "spi-rx-bus-width" 2 int $dts_file
			}
			"0" {
				add_prop $node "spi-tx-bus-width" 1 int $dts_file
				add_prop $node "spi-rx-bus-width" 1 int $dts_file
			}
			default {
				dtg_warning "Unsupported bus_width:$bus_width"
			}
		}
		set_drv_conf_prop $drv_handle C_QSPI_BUS_WIDTH xlnx,bus-width int
		set_drv_conf_prop $drv_handle C_QSPI_MODE xlnx,connection-mode int
		set_drv_conf_prop $drv_handle C_QSPI_CLK_FREQ_HZ xlnx,clock-freq int
	}
}
