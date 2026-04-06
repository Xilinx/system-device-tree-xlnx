#
# (C) Copyright 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc cpm_pcie_generate {drv_handle} {
	if {![regexp "pspmc.*" "$drv_handle" match]} {
		return
	}

	set rev_num -1
	set port_type_0 -1
	set port_type_1 -1

	foreach drv [hsi::get_cells -hier -filter IP_NAME==psv_cpm] {
		if {![regexp "pspmc.*" "$drv" match]} {
			set rev_num [get_ip_property $drv CONFIG.CPM_REVISION_NUMBER]
			set port_type_0 [get_ip_property $drv CONFIG.C_CPM_PCIE0_PORT_TYPE]
			set port_type_1 [get_ip_property $drv CONFIG.C_CPM_PCIE1_PORT_TYPE]
		}
	}

	if {($rev_num == 1) && ($port_type_1 == 1)} {
		set node [get_node $drv_handle]
		if {$node == 0} {
	            return
	        }
	        add_prop $node "xlnx,csr-slcr" 0xfcea0000 hexlist "pcw.dtsi" 1
	        add_prop $node compatible "xlnx,versal-cpm5-host1" stringlist "pcw.dtsi" 1
	        set ranges "0x02000000 0x0 0xe8000000 0x0 0xe8000000 0x0 0x8000000>,<0x43000000 0xa0 0x00000000 0xa0 0x00000000 0x0 0x80000000"
	        add_prop $node "ranges" $ranges hexlist "pcw.dtsi" 1
	        set reg "0x07 0x00000000 0x00 0x10000000>,<0x00 0xfcdd0000 0x00 0x1000>,<0x00 0xfcea0000 0x00 0x10000>,<0x00 0xfcdc0000 0x00 0x10000"
	        add_prop $node "reg" $reg hexlist "pcw.dtsi" 1
	        set reg_names "cfg cpm_slcr cpm_csr cpm_crx"
	        add_prop $node reg-names $reg_names stringlist "pcw.dtsi" 1

	}

}
