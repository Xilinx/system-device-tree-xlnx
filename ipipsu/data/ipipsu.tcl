#
# (C) Copyright 2019-2021 Xilinx, Inc.
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

    proc ipipsu_generate {drv_handle} {
        set ipi_list [hsi get_cells -hier -filter {IP_NAME == "psu_ipi" || IP_NAME == "psv_ipi" || IP_NAME == "psx_ipi"}]
        set node [get_node $drv_handle]
	set node_label [string trimleft $node "&"]
	set buffer_base [hsi get_property CONFIG.C_BUFFER_BASE $drv_handle]
	set base [get_baseaddr $drv_handle]
        add_prop $node "xlnx,ipi-target-count" [llength $ipi_list] int "pcw.dtsi"
	set node_space "_"
	set src [hsi get_property CONFIG.C_BUFFER_INDEX [hsi get_cells -hier $drv_handle]]
	set idx 0
	foreach ipi_slave $ipi_list {
		set slv_node [create_node -n "child" -l "$node_label$node_space$idx" -u $idx -d "pcw.dtsi" -p $node]
		set buffer_index [hsi get_property CONFIG.C_BUFFER_INDEX [hsi get_cells -hier $ipi_slave]]
		if {[string match -nocase $buffer_index "NIL"]} {
			set buffer_index  0xffff
		} else {
			if { ![string match -nocase $src "NIL"]} {
				set req_base [expr  $buffer_base  + 64 * $buffer_index]
				add_prop $slv_node "xlnx,ipi-req-msg-buf" $req_base hexint "pcw.dtsi"
				set res_base [expr  $req_base +  0x20]
				add_prop $slv_node "xlnx,ipi-rsp-msg-buf" $res_base hexint "pcw.dtsi"
			}
		}
		if {[string_is_empty $buffer_index]} {
			set buffer_index  0xffff
		}
		add_prop $slv_node "xlnx,ipi-buf-index" $buffer_index int "pcw.dtsi"
		set bit_position [hsi get_property CONFIG.C_BIT_POSITION [hsi get_cells -hier $ipi_slave]]
		add_prop $slv_node "xlnx,ipi-id" $bit_position int "pcw.dtsi"
		set bit_mask [expr 1 << $bit_position]
		add_prop $slv_node "xlnx,ipi-bitmask" $bit_mask int "pcw.dtsi"
		incr idx
	}
    }
