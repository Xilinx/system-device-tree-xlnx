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
    set ip [hsi::get_cells -hier $drv_handle]
    set config_baud 0
    set port_number 0
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
    if {[is_zynqmp_platform $proctype] || \
	[string match -nocase $proctype "versal"]} {
		if {[is_zynqmp_platform $proctype]} {
		   append bootargs "\ \, \"clk_ignore_unused\""
		}
    }
	if {[catch {set val [systemdt get $chosen_node "stdout-path"]} msg]} {
		add_prop $chosen_node "stdout-path" "serial0:${baud}n8" stringlist "system-top.dts"
	}
	set val [systemdt get $chosen_node "stdout-path"]
	add_prop $node "port-number" $port_number int $dts_file
    set uboot_prop [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
    if {[string match -nocase $uboot_prop "psu_uart"] || [string match -nocase $uboot_prop "psv_sbsauart"]} {
	set_drv_prop $drv_handle "u-boot,dm-pre-reloc" "" boolean
    }
    set has_modem [hsi get_property CONFIG.C_HAS_MODEM [hsi::get_cells -hier $drv_handle]]
    if {$has_modem == 0} {
	 add_prop $node "cts-override" boolean $dts_file
    }
    set_drv_conf_prop $drv_handle C_UART_CLK_FREQ_HZ xlnx,clock-freq int
}
