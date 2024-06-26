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


    proc gpiops_generate {drv_handle} {
         set count 32
         set dts_file [set_drv_def_dts $drv_handle]
         set node [get_node $drv_handle]
         set ip [hsi::get_cells -hier $drv_handle]
         add_prop $node "emio-gpio-width" [get_ip_param_value $ip C_EMIO_GPIO_WIDTH] hexint $dts_file
         set gpiomask [get_ip_param_value $ip "C_MIO_GPIO_MASK"]

         if {[llength $gpiomask]} {
         set mask [expr {$gpiomask & 0xffffffff}]
         add_prop $node "gpio-mask-low" $mask int $dts_file
         set mask [expr {$gpiomask>>$count}]
         set mask [expr {$mask & 0xffffffff}]
         add_prop $node "gpio-mask-high" "$mask" int $dts_file
         }
    }


