#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc intc_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        global env
        set path $env(CUSTOM_SDT_REPO)
        set common_file "$path/device_tree/data/config.yaml"
        pldt append $node compatible "\ \, \"xlnx,xps-intc-1.00.a\""
        add_prop $node "#interrupt-cells" 2 int "pl.dtsi"
        add_prop $node "interrupt-controller" boolean "pl.dtsi"
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

        # Calculate and add intc-type property based on cascade mode
        set cascade_mode [get_ip_param_value $ip C_EN_CASCADE_MODE]
        set cascade_master [get_ip_param_value $ip C_CASCADE_MASTER]

        # Set default values if parameters are empty
        if {$cascade_mode == "" || $cascade_mode == -1} {
            set cascade_mode 0
        }
        if {$cascade_master == "" || $cascade_master == -1} {
            set cascade_master 0
        }
        # Determine intc type:
        # 0 - Generic standalone (parent is not axi_intc)
        # 1 - Cascade master (cascade enabled, master)
        # 2 - Cascade intermediate (cascade enabled, not master)
        # 3 - Cascade leaf (parent is axi_intc, cascade disabled)
        if {$cascade_mode == 1 && $cascade_master == 1} {
            set intc_type 1
        } elseif {$cascade_mode == 1 && $cascade_master == 0} {
            set intc_type 2
        } else {
            # cascade_mode == 0: Check if parent exists using existing cascade offset logic
            if {[get_intc_cascade_offset $drv_handle] > 0} {
                set intc_type 3
            } else {
                set intc_type 0
            }
        }

        add_prop $node "xlnx,intc-type" $intc_type hexint $dts_file 1
        if {[string match -nocase $env(zocl) "enable"]} {
                add_prop $node "xlnx,num-intr-inputs" 0x20 hexint "pl.dtsi" 1
        } else {
                set_drv_conf_prop $drv_handle C_NUM_INTR_INPUTS "xlnx,num-intr-inputs" $node
        }
        set_drv_conf_prop $drv_handle C_HAS_FAST "xlnx,is-fast" $node
        set_drv_conf_prop $drv_handle C_IVAR_RESET_VALUE "xlnx,ivar-rst-val" $node
        set_drv_conf_prop $drv_handle C_ADDR_WIDTH "xlnx,addr-width" $node
    }


