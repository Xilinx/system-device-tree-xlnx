#
# (C) Copyright 2014-2021 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
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

proc generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,xps-uartlite-1.00.a\""
	set config_baud [hsi get_property CONFIG.dt_setbaud [get_os]]
	set ip [hsi::get_cells -hier $drv_handle]
	set ip_type [hsi get_property IP_NAME $ip]
	set avail_param [hsi list_property [hsi::get_cells -hier $drv_handle]]
	# This check is needed because BAUDRATE parameter for psuart is available from
	# 2017.1 onwards
	if { !$config_baud } {
		if {[lsearch -nocase $avail_param "CONFIG.C_BAUDRATE"] >= 0} {
	    		set baud [hsi get_property CONFIG.C_BAUDRATE [hsi::get_cells -hier $drv_handle]]
		} else {
	  	  set baud "115200"
		}
	} else {
		set baud "$config_baud"
	}
	set chosen_node [create_node -n "chosen" -d "system-top.dts" -p root]
	set bootargs "earlycon"
	set proctype [get_hw_family]
	if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] || \
		[string match -nocase $proctype "versal"]} {
			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
			   append bootargs "\ \, \"clk_ignore_unused\""
			}
	}
	set_drv_conf_prop $drv_handle C_BAUDRATE current-speed int
	if {[regexp "kintex*" $proctype match]} {
		 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
	}
}
