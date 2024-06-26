#
# (C) Copyright 2019-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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
    proc ernic_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set ernic_ip [hsi::get_cells -hier $drv_handle]
        set ip_name [hsi get_property IP_NAME $ernic_ip]

        set ethip [ernic_get_connected_ip $drv_handle "rx_pkt_hndler_s_axis"]
        if {[llength $ethip]} {
                set_drv_property $drv_handle eth-handle "$ethip" $node reference
        }
    }

    proc ernic_get_connected_ip {drv_handle dma_pin} {
        global connected_ip
        set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $drv_handle] $dma_pin]
        set valid_eth_list "l_ethernet"
        if {[string_is_empty ${intf}]} {
                return ""
        }
        set connected_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]
        if {[string_is_empty ${connected_ip}]} {
                dtg_warning "$drv_handle connected ip is NULL for the pin $intf"
                return ""
        }
        set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $connected_ip]]
        if {[string match -nocase $iptype "axis_data_fifo"] } {
                set dma_pin "M_AXIS"
                ernic_get_connected_ip $connected_ip $dma_pin
        } elseif {[lsearch -nocase $valid_eth_list $iptype] >= 0 } {
                return $connected_ip
        } else {
                set dma_pin "S_AXIS"
                ernic_get_connected_ip $connected_ip $dma_pin
        }
    }


