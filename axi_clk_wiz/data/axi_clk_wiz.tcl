#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc axi_clk_wiz_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set compatible [get_comp_str $drv_handle]
        if {[string match  "xlnx,clocking-wizard-*" $compatible] || [string match  "xlnx,clk-wiz-*" $compatible] } {
               set keyval [pldt append $node compatible "\ \, \"xlnx,clocking-wizard\""]
        } else {
               set keyval [pldt append $node compatible "\ \, \"xlnx,versal-clk-wizard\""]
        }
        set ip [hsi::get_cells -hier $drv_handle]
        axi_clk_wiz_gen_speedgrade $drv_handle
        set primfreq [hsi get_property CONFIG.PRIM_IN_FREQ $ip]
        set primfreq_hz [scan [expr {$primfreq * 1000000}] %d]
        add_prop $node "xlnx,prim-in-freq" $primfreq_hz int "pl.dtsi" 1
        set j 0
        set output_names ""
        for {set i 1} {$i < 8} {incr i} {
                if {[hsi get_property CONFIG.C_CLKOUT${i}_USED $ip] != 0} {
                        set freq [hsi get_property CONFIG.C_CLKOUT${i}_OUT_FREQ $ip]
                        set pin_name [hsi get_property CONFIG.C_CLK_OUT${i}_PORT $ip]
                        set basefrq [string tolower [hsi get_property CONFIG.C_BASEADDR $ip]]
                        set pin_name "$basefrq-$pin_name"
                        lappend output_names $pin_name
                        incr j
                }
        }
        if {![string_is_empty $output_names]} {
                add_prop $node "clock-output-names" $output_names string "pl.dtsi"
                add_prop $node "xlnx,nr-outputs" $j int "pl.dtsi"
        }
        add_prop $node "#clock-cells" 1 int "pl.dtsi"

        set family [get_hw_family]
        if {[regexp "microblaze" $family match]} {
                gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
       }
    }

    proc axi_clk_wiz_gen_speedgrade {drv_handle} {
        set speedgrade [hsi get_property SPEEDGRADE [hsi::get_hw_designs]]
        set num [regexp -all -inline -- {[0-9]} $speedgrade]
        if {![string equal $num ""]} {
                set node [get_node $drv_handle]
                add_prop $node "xlnx,speed-grade" $num int "pl.dtsi"
        }
    }