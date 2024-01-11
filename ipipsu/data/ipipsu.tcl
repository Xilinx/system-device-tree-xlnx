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
	set r5_procs [hsi::get_cells -hier -filter {IP_NAME==psv_cortexr5 || IP_NAME==psu_cortexr5 || IP_NAME==psx_cortexr52}]
        set node [get_node $drv_handle]
	set child_node_label [hsi get_property NAME $drv_handle]
	set node_label [string trimleft $node "&"]
	set buffer_base [hsi get_property CONFIG.C_BUFFER_BASE $drv_handle]
	set base [get_baseaddr $drv_handle]
        add_prop $node "xlnx,ipi-target-count" [llength $ipi_list] int "pcw.dtsi"
	set node_space "_"
	set src [hsi get_property CONFIG.C_BUFFER_INDEX [hsi get_cells -hier $drv_handle]]

	if {[llength $node] > 1} {
                 set node_label [lindex [split $node_label ":"] 0]
        }
        set cpu [hsi get_property CONFIG.C_CPU_NAME [hsi::get_cells -hier $drv_handle]]
        set memmap_key ""
        switch $cpu {
                "APU" - "A72" - "A78_0" {
                        set memmap_key "a53"
                }
                "RPU0" - "R5_0" - "R52_0" {
                        set memmap_key [lindex $r5_procs 0]
                }
                "RPU1" - "R5_1" - "R52_1" {
                        set memmap_key [lindex $r5_procs 1]
                }
                "R52_2" {
                        set memmap_key [lindex $r5_procs 2]
                }
                "R52_3" {
                        set memmap_key [lindex $r5_procs 3]
                }
                "PSM" {
                        set memmap_key "psm"
                }
                "PMC" {
                        set memmap_key "pmc"
                }
                "PMU" {
                        set memmap_key "pmu"
                }
        }
	if {![string_is_empty $memmap_key]} {
		set high [get_highaddr $drv_handle]
		set size [format 0x%x [expr {${high} - ${base} + 1}]]
		set_memmap $node_label $memmap_key "0x0 $base 0x0 $size"
	}


	set idx 0
	foreach ipi_slave $ipi_list {
		set slv_node [create_node -n "child" -l "$child_node_label$node_space$idx" -u $idx -d "pcw.dtsi" -p $node]
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
