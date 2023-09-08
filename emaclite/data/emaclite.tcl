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

    proc emaclite_generate {drv_handle} {
        set node [get_node $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,axi-ethernetlite-3.0\" , \"xlnx,xps-ethernetlite-1.00.a\""
        update_eth_mac_addr $drv_handle
        gen_mdio_node $drv_handle $node
    }

