#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2024Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc scugic_generate {drv_handle} {
       set dts_file [set_drv_def_dts $drv_handle]
       set proctype [get_hw_family]
       set cpm_ip [hsi::get_cells -hier -filter IP_NAME==psv_cpm]

       if {[string match -nocase $proctype "versal"] && \
           [string match -nocase [hsi get_property CONFIG.APU_GIC_ITS_CTL [hsi get_cells -hier $drv_handle]] "0xF9020000"] && \
           [llength $cpm_ip]} {
            set node [create_node -n "&gic_its" -d $dts_file -p root]
            add_prop $node "status" "okay" string $dts_file
            set reg "0x0 0xf9020000 0x0 0x20000"
            set_memmap "gic_its" a53 $reg
       }
    }
