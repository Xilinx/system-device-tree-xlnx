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

namespace eval axi_traffic_gen {
proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}

#	set compatible [get_comp_str $drv_handle]
#	set compatible [append compatible " " "xlnx,axi-traffic-gen"]
#	set_drv_prop $drv_handle compatible "$compatible" stringlist
	pldt append $node compatible "\ \, \"xlnx,axi-traffic-gen\""
	# the interrupt related setting is only required for AXI4 protocol only
	set atg_mode [get_property "CONFIG.C_ATG_MODE" [hsi::get_cells -hier $drv_handle]]
	if { ![string match -nocase $atg_mode "AXI4"] } {
		return 0
	}
#	set proc_type [get_sw_proc_prop IP_NAME]
	set proc_type [get_hw_family]
	# set up interrupt-names
	set intr_list "irq-out err-out"
	set interrupts ""
	set interrupt_names ""
	foreach irq ${intr_list} {
		set intr_info [get_intr_id $drv_handle $irq]
		if { [string match -nocase $intr_info "-1"] } {
			if {[string match -nocase $proc_type "versal"]} {
				continue
			} else {
				error "ERROR: ${drv_handle}: $irq port is not connected"
			}
		}
		if { [string match -nocase $interrupt_names ""] } {
			set interrupt_names "$irq"
			set interrupts "$intr_info"
		} else {
			append interrupt_names " " "$irq"
			append interrupts " " "$intr_info"
		}
	}
	add_prop $node "interrupts" $interrupts int "pl.dtsi"
	add_prop $node "interrupt-names" $interrupt_names stringlist "pl.dtsi"
}
}
