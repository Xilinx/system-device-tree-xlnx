#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc axi_traffic_gen_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        pldt append $node compatible "\ \, \"xlnx,axi-traffic-gen\""
        # the interrupt related setting is only required for AXI4 protocol only
        set atg_mode [hsi get_property "CONFIG.C_ATG_MODE" [hsi::get_cells -hier $drv_handle]]
        set atg_mode_name $atg_mode
        set axi4_name [string match -nocase $atg_mode_name "AXI4"]
        set axi4_lite_name [string match -nocase $atg_mode_name "AXI4-Lite"]
        set axi4_Stream_name [string match -nocase $atg_mode_name "AXI4-Stream"]
        if {$axi4_name == 1} {
                set atg_mode_value 1
        }
        if {$axi4_lite_name == 1} {
                set atg_mode_value 2
        }
        if {$axi4_Stream_name == 1} {
                set atg_mode_value 3
        }

        if {[llength $atg_mode_name] == 0} {
                set atg_mode_value 0
        }

        if { ![string match -nocase $atg_mode "AXI4"] } {
                return 0
        }
        add_prop $node "xlnx,atg-mode" $atg_mode_value int "pl.dtsi" 1
        set atg_mode_l2_name [hsi get_property "CONFIG.C_ATG_MODE_L2" [hsi::get_cells -hier $drv_handle]]
        set adv_mode_name [string match -nocase $atg_mode_l2_name "Advanced"]
            set basic_mode_name [string match -nocase $atg_mode_l2_name "Basic"]
            set static_mode_name [string match -nocase $atg_mode_l2_name "Static"]
            if {$adv_mode_name == 1} {
                set atg_mode_value_l2 1
        }
            if {$basic_mode_name == 1} {
                set atg_mode_value_l2 2
            }
        if {$static_mode_name == 1} {
                set atg_mode_value_l2 3
        }
        if {[llength $atg_mode_l2_name] == 0} {
                 set atg_mode_value_l2 0
        }

        add_prop $node "xlnx,atg-mode-l2" $atg_mode_value_l2 int "pl.dtsi" 1
        set axi_mode_name [hsi get_property "CONFIG.C_AXIS_MODE" [hsi::get_cells -hier $drv_handle]]
        set master_name [string match -nocase $axi_mode_name "Master Only"]
        set slave_name [string match -nocase $axi_mode_name "Slave Only"]
        set master_loop_name [string match -nocase $axi_mode_name "Master Loop back"]
        set slave_loop_name [string match -nocase $axi_mode_name "Slave Loop back"]
        if {$master_name == 1} {
                set axi_mode_value 1
        }
        if {$slave_name == 1} {
                set axi_mode_value 2
        }
        if {$master_loop_name == 1} {
                set axi_mode_value 3
        }
        if {$slave_loop_name == 1} {
                set axi_mode_value 4
        }
        if {[llength $axi_mode_name] == 0} {
                set axi_mode_value 0
        }
        add_prop $node "xlnx,axis-mode" $axi_mode_value int "pl.dtsi" 1
        set proc_type [get_hw_family]
        # set up interrupt-names
        set intr_list "irq_out err_out"
        set interrupts ""
        set interrupt_names ""
        foreach irq ${intr_list} {
                set intr_info [get_intr_id $drv_handle $irq]
                if { [string match -nocase $intr_info "-1"] } {
                        if {[string match -nocase $proc_type "versal"]} {
                                continue
                        } else {
                                dtg_warning "ERROR: ${drv_handle}: $irq port is not connected"
                        }
                }
                if { [string match -nocase $interrupt_names ""] } {
                        if {[string match -nocase $irq "irq_out"]} {
                               set irq "irq-out"
                            }
                                if {[string match -nocase $irq "err_out"]} {
                               set irq "err-out"
                                }
                        set interrupt_names "$irq"
                        set interrupts "$intr_info"
                } else {
                        if {[string match -nocase $irq "irq_out"]} {
                               set irq "irq-out"
                            }
                                if {[string match -nocase $irq "err_out"]} {
                               set irq "err-out"
                                }
                        append interrupt_names " " "$irq"
                        append interrupts " " "$intr_info"
                }
        }
    }


