#
# (C) Copyright 2014-2015 Xilinx, Inc.
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

namespace eval emaclite {
proc generate {drv_handle} {
    set node [get_node $drv_handle]
#    set compatible [get_comp_str $drv_handle]
 #   set compatible [append compatible " " "xlnx,xps-ethernetlite-1.00.a"]
 #   set_drv_prop $drv_handle compatible "$compatible" stringlist
    add_prop $node compatible "\ \, \"xlnx,xps-ethernetlite-1.00.a\""
    update_eth_mac_addr $drv_handle
#    set node [gen_peripheral_nodes $drv_handle]
    gen_mdio_node $drv_handle $node
}
}
