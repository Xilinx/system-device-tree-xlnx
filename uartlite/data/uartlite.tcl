#
# (C) Copyright 2014-2015 Xilinx, Inc.
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

namespace eval uartlite {
proc generate {drv_handle} {
    set node [get_node $drv_handle]
    set dts_file [set_drv_def_dts $drv_handle]
    # try to source the common tcl procs
    # assuming the order of return is based on repo priority
   # set compatible [get_comp_str $drv_handle]
   # set compatible [append compatible " " "xlnx,xps-uartlite-1.00.a"]
   # set_drv_prop $drv_handle compatible "$compatible" stringlist
    pldt append $node compatible "\ \, \"xlnx,xps-uartlite-1.00.a\""
    set ip [hsi::get_cells -hier $drv_handle]
    #set consoleip [get_property CONFIG.console_device [get_os]]
    #if { [string match -nocase $consoleip $ip] } {
        set ip_type [get_property IP_NAME $ip]
        if { [string match -nocase $ip_type] } {
            set_count "console" "ttyUL0,115200"
        } else {
		
            set count "console" "ttyUL0,[hsi::utils::get_ip_param_value $ip C_BAUDRATE]"
        }
    #}
        set avail_param [list_property [hsi::get_cells -hier $drv_handle]]
        # This check is needed because BAUDRATE parameter for psuart is available from
        # 2017.1 onwards
        if {[lsearch -nocase $avail_param "CONFIG.C_BAUDRATE"] >= 0} {
            set baud [get_property CONFIG.C_BAUDRATE [hsi::get_cells -hier $drv_handle]]
        } else {
            set baud "115200"
        }
	set chosen_node [create_node -n "chosen" -d "system-top.dts" -p root]
        set bootargs "earlycon"
#        set proctype "psv_cortetxa72"
	set proctype [get_hw_family]
    if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"] || \
        [string match -nocase $proctype "versal"]} {
                if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
                   append bootargs "\ \, \"clk_ignore_unused\""
                }
    }
   add_prop $chosen_node "stdout-path" "serial0:${baud}n8" string "system-top.dts"

    set_drv_conf_prop $drv_handle C_BAUDRATE current-speed int
    if {[regexp "kintex*" $proctype match]} {
                 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
    }
}
}
