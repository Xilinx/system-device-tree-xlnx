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
	set node [get_node $drv_handle]
	set slave [hsi::get_cells -hier $drv_handle]
	set pit_used ""
	set unit_addr [get_baseaddr ${slave} no_prefix]
	set default_dts [set_drv_def_dts $drv_handle]
	set bus_node [add_or_get_bus_node $slave $default_dts]
	set ps_mapping [gen_ps_mapping]
        if {[catch {set tmp [dict get $ps_mapping $unit_addr label]} msg]} {
		if {[string match -nocase $default_dts "pcw.dtsi"]} {
			pcwdt append $node compatible "\ \, \"xlnx,iomodule-3.1\""
		}
	}

	for {set i 1} {$i < 5} {incr i} {
		set val [get_ip_param_value $slave "C_USE_PIT${i}"]
		if {[string match -nocase $pit_used ""]} {
			set pit_used $val
		} else {
			append pit_used " " $val
		}
	}
	add_prop $node "xlnx,pit-used" $pit_used intlist $default_dts

	set pit_size ""
	set pit_mask ""
	for {set i 1} {$i < 5} {incr i} {
		set val [get_ip_param_value $slave "C_PIT${i}_SIZE"]
		set msk_val [expr pow(2, $val) - 1]
		set msk_val [format "%.0f" $msk_val]
		set msk_val [format "0x%08X" $msk_val]
		if {[string match -nocase $pit_size ""]} {
			set pit_size $val
		} else {
			append pit_size " " $val
		}
		if {[string match -nocase $pit_mask ""]} {
			set pit_mask $msk_val
		} else {
			append pit_mask " " $msk_val
		}
	}
	add_prop $node "xlnx,pit-size" $pit_size intlist $default_dts
	add_prop $node "xlnx,pit-mask" $pit_mask hexlist $default_dts

	set pit_prescaler ""
	for {set i 1} {$i < 5} {incr i} {
		set val [get_ip_param_value $slave "C_PIT${i}_PRESCALER"]
		if {[string match -nocase $pit_prescaler ""]} {
			set pit_prescaler $val
		} else {
			append pit_prescaler " " $val
		}
	}
	add_prop $node "xlnx,pit-prescaler" $pit_prescaler intlist $default_dts

	set pit_readable ""
	for {set i 1} {$i < 5} {incr i} {
		set val [get_ip_param_value $slave "C_PIT${i}_READABLE"]
		if {[string match -nocase $pit_readable ""]} {
			set pit_readable $val
		} else {
			append pit_readable " " $val
		}
	}
	add_prop $node "xlnx,pit-readable" $pit_readable intlist $default_dts

	set gpo_init ""
	for {set i 1} {$i < 5} {incr i} {
		set val [get_ip_param_value $slave "C_GPO${i}_INIT"]
		if {[string match -nocase $gpo_init ""]} {
			set gpo_init $val
		} else {
			append gpo_init " " $val
		}
	}
	add_prop $node "xlnx,gpo-init" $gpo_init intlist $default_dts

	set param_list "C_INTC_HAS_FAST C_INTC_ADDR_WIDTH C_INTC_LEVEL_EDGE C_UART_BAUDRATE"
	foreach param $param_list {
#		ip2drv_prop $drv_handle "CONFIG.$param"
	}
	set val [get_ip_param_value $slave "C_FREQ"]
	add_prop $node "xlnx,clock-freq" $val int $default_dts
#		set val [get_ip_param_value $slave "C_INTC_INTR_SIZE"]
	set max_intr_size 0
	set periph_num_intr_internal [get_num_intr_internal $slave]
	set periph_num_intr_inputs [get_num_intr_inputs $slave]
	set periph_intr_size [expr $periph_num_intr_internal + $periph_num_intr_inputs]
	if {$max_intr_size < $periph_intr_size} {
		set max_intr_size $periph_intr_size
	}
	add_prop $node "xlnx,max-intr-size" $max_intr_size int $default_dts
	add_prop $node "xlnx,options" 1 int $default_dts
	set val [get_ip_param_value $slave "C_INTC_BASE_VECTORS"]
}

proc get_num_intr_internal {slave} {
    set c_use_uart_rx          [get_ip_param_value $slave "C_USE_UART_RX"]
    set c_uart_error_interrupt [get_ip_param_value $slave "C_UART_ERROR_INTERRUPT"]
    set c_uart_rx_interrupt    [get_ip_param_value $slave "C_UART_RX_INTERRUPT"]
    set c_use_uart_tx          [get_ip_param_value $slave "C_USE_UART_TX"]
    set c_uart_tx_interrupt    [get_ip_param_value $slave "C_UART_TX_INTERRUPT"]
    set c_intc_use_ext_intr    [get_ip_param_value $slave "C_INTC_USE_EXT_INTR"]
    set c_intc_intr_size       [get_ip_param_value $slave "C_INTC_INTR_SIZE"]

    set num_intr_internal 0
    if {$c_use_uart_tx * $c_use_uart_rx * $c_uart_error_interrupt} { set num_intr_internal 1 }
    if {$c_use_uart_tx * $c_uart_tx_interrupt}                     { set num_intr_internal 2 }
    if {$c_use_uart_rx * $c_uart_rx_interrupt}                     { set num_intr_internal 3 }
    foreach kind {PIT FIT GPI} suffix {"SIZE" "No_CLOCKS" "INTERRUPT"} intbit {3 7 11} {
      foreach it {1 2 3 4} {
        set c_use_it       [expr [get_ip_param_value $slave "C_${kind}${it}_${suffix}"] > 0]
        set c_it_interrupt [get_ip_param_value $slave "C_${kind}${it}_INTERRUPT"]
        if {$c_use_it * $c_it_interrupt} { set num_intr_internal [expr $intbit + $it] }
      }
    }
    # If any external interrupts are used - return 16 since in that case all internal interrupts
    # must be accounted for because external interrupts start at bit position 16
    if {$c_intc_use_ext_intr} {
        return 16
    }
    return $num_intr_internal
}

proc get_num_intr_inputs {slave} {
    set intc_use_ext_intr [get_ip_param_value $slave "C_INTC_USE_EXT_INTR"]
    if {$intc_use_ext_intr} {
        set num_intr_inputs [get_ip_param_value $slave "C_INTC_INTR_SIZE"]
    } else {
        set num_intr_inputs 0
    }
    return $num_intr_inputs
}
