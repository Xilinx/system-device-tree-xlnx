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
    global env
    set path $env(REPO)
    set common_file "$path/device_tree/data/config.yaml"
    set zocl [get_user_config $common_file --dt_zocl]
    pldt append $node compatible "\ \, \"xlnx,xps-intc-1.00.a\""
    add_prop $node "#interrupt-cells" 2 int "pl.dtsi"
    set ip [hsi::get_cells -hier $drv_handle]
    set num_intr_inputs [get_ip_param_value $ip C_NUM_INTR_INPUTS]
    set kind_of_intr [get_ip_param_value $ip C_KIND_OF_INTR]
    # Pad to 32 bits - num_intr_inputs
    if { $num_intr_inputs != -1 } {
	set count 0
	set par_mask 0
	for { set count 0 } { $count < $num_intr_inputs} { incr count} {
	    set mask [expr {1<<$count}]
	    set new_mask [expr {$mask | $par_mask}]
	    set par_mask $new_mask
	}

	set kind_of_intr_32 $kind_of_intr
	set kind_of_intr [expr {$kind_of_intr_32 & $par_mask}]
    } else {
	set kind_of_intr 0
    }
    add_prop $node "xlnx,kind-of-intr" $kind_of_intr hexint $dts_file 1
    if {$zocl} {
            set num_intr_inputs "0x20"
            set_drv_prop $drv_handle "xlnx,num-intr-inputs" $num_intr_inputs int
    } else {
            set_drv_conf_prop $drv_handle C_NUM_INTR_INPUTS "xlnx,num-intr-inputs"
    }
    set_drv_conf_prop $drv_handle C_HAS_FAST "xlnx,is-fast"
    set_drv_conf_prop $drv_handle C_IVAR_RESET_VALUE "xlnx,ivar-rst-val"
    set_drv_conf_prop $drv_handle C_ADDR_WIDTH "xlnx,addr-width"
}
