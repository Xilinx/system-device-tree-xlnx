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

    proc dmaps_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set ip [hsi::get_cells -hier $drv_handle]

        set ip_name [get_ip_property $drv_handle IP_NAME]
        set req_dma_list "psu_gdma psu_adma psu_csudma"
        if {[lsearch  -nocase $req_dma_list $ip_name] >= 0} {
        set_drv_conf_prop $drv_handle C_DMA_MODE xlnx,dma-type  $node int
        if {[string match -nocase $ip_name "psu_csudma"]} {
           add_prop $node "xlnx,dma-type" 0 int $dts_file
        }
        }
    }


