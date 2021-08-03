#
# (C) Copyright 2014-2021 Xilinx, Inc.
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

proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

	set keyval [pldt append $node compatible "\ \, \"xlnx,axi-can-1.00.a\""]
    	set ip_name [get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
	    set version [string tolower [common::get_property VLNV $drv_handle]]
	    if {[string match -nocase $ip_name "canfd"]} {
		if {[string compare -nocase "xilinx.com:ip:canfd:1.0" $version] == 0} {
			set keyval [pldt append $node compatible "\ \, \"xlnx,canfd-1.0\""]
		} else {
			set keyval [pldt append $node compatible " \, \"xlnx,canfd-2.0\""]
		}
		set_drv_conf_prop $drv_handle NUM_OF_TX_BUF tx-mailbox-count hexint
		set_drv_conf_prop $drv_handle NUM_OF_TX_BUF rx-fifo-depth hexint
	    } else {
		set_drv_conf_prop $drv_handle c_can_num_acf can-num-acf hexint
		set_drv_conf_prop $drv_handle c_can_tx_dpth tx-fifo-depth hexint
		set_drv_conf_prop $drv_handle c_can_rx_dpth rx-fifo-depth hexint
	    }

	set proc_type [get_hw_family]
	if {[regexp "kintex*" $proc_type match]} {
	    gen_dev_ccf_binding $drv_handle "s_axi_aclk"
	}
}
