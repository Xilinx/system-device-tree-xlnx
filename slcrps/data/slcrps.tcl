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
    set dts_file [set_drv_def_dts $drv_handle]
    gen_clocks_node $node $dts_file
}

proc gen_clocks_node {parent_node dts_file} {
    set clocks_child_name "clkc"
    set clkc_node [create_node -l $clocks_child_name -n $clocks_child_name -u 100 -p $parent_node -d $dts_file]

    if {[catch {set ps_clk_freq [get_property CONFIG.C_INPUT_CRYSTAL_FREQ_HZ [hsi::get_cells -hier ps7_clockc_0]]} msg]} {
	set ps_clk_freq ""
    }
    if {[string_is_empty ${ps_clk_freq}]} {
	puts "WARNING: DTG failed to detect the ps-clk-frequency, Using default value - 33333333"
	set ps_clk_freq 33333333
    }
    add_prop "${clkc_node}" "ps-clk-frequency" ${ps_clk_freq} int $dts_file

    set fclk_val "0"
    set clk_pin_list [hsi::get_pins [hsi::get_cells -hier ps7_clockc_0] -regexp FCLK_CLK[0-3]]
    foreach clk_pin ${clk_pin_list} {
	dtg_debug "clk_pin: $clk_pin"
	set clk_net [get_nets -of_objects $clk_pin]
	set connected_pin_names [get_pins -of_objects $clk_net]
	foreach target_pin ${connected_pin_names} {
	    dtg_debug " target_pin: $target_pin"
	    set connected_ip [hsi::get_cells -of_objects $target_pin]
	    if {[is_pl_ip $connected_ip]} {
		regsub -all {FCLK_CLK} $clk_pin {} fclk_pin
		set fclk_val [expr [expr 1 << $fclk_pin] | $fclk_val]
		dtg_debug "  PL IP: $connected_ip, CLK_PIN: $clk_pin, FCLK_PIN: $fclk_pin, FCLK_VAL: [format %x $fclk_val]"
		# Here could be break
	    } elseif {![string match "ps7_clockc_0" $connected_ip]} {
		dtg_debug "  PS IP: $connected_ip"
	    }
	}
    }
    add_prop "${clkc_node}" "fclk-enable" "0x[format %x $fclk_val]" int $dts_file
    return $clkc_node
}
