#
# (C) Copyright 2019-2022 Xilinx, Inc.
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

    proc sync_ip_generate {drv_handle} {

        set node [gen_peripheral_nodes $drv_handle]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        set enable_enc_dec [hsi get_property CONFIG.ENABLE_ENC_DEC [hsi::get_cells -hier $drv_handle]]
        if {$enable_enc_dec == 0} {
        #encode case
                add_prop "${node}" "xlnx,encode" boolean $dts_file
                set no_of_enc_chan [hsi get_property CONFIG.NO_OF_ENC_CHAN [hsi::get_cells -hier $drv_handle]]
                set no_of_enc_chan [expr $no_of_enc_chan + 1]
                add_prop "${node}" "xlnx,num-chan" $no_of_enc_chan int $dts_file
        } else {
        #decode case
                set no_of_dec_chan [hsi get_property CONFIG.NO_OF_DEC_CHAN [hsi::get_cells -hier $drv_handle]]
                set no_of_dec_chan [expr $no_of_dec_chan + 1]
                add_prop "${node}" "xlnx,num-chan" $no_of_dec_chan int $dts_file
        }
    }


