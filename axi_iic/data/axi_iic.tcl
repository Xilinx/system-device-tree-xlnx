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

    proc axi_iic_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(CUSTOM_SDT_REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        set ip [hsi::get_cells -hier $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set clk_freq [get_ip_param_value $ip CONFIG.C_S_AXI_ACLK_FREQ_HZ]
        add_prop $node "xlnx,s-axi-aclk-freq-hz" $clk_freq hexint $dts_file
        pldt append $node compatible "\ \, \"xlnx,xps-iic-2.00.a\""
        set proctype [get_hw_family]
        if {[regexp "microblaze" $proctype match]} {
        gen_dev_ccf_binding $drv_handle "s_axi_aclk"
        }
    }


