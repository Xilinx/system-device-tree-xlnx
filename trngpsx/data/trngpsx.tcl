#
# (C) Copyright 2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc trngpsx_generate {drv_handle} {
	set node [get_node $drv_handle]
	set pki_trng_baseaddress "0x20400051000"
	set pki_trng_offset "0x200"
	set pki_num_insts 8

	if {$node == 0} {
		return
	}
	for {set instance 0} {$instance < $pki_num_insts} {incr instance} {
		set instance_base_addr [format %lx [expr $pki_trng_baseaddress + [expr {$instance * $pki_trng_offset}]]]
		set instance_node_label "psx_pki_trng${instance}"
		set trng_node [create_node -l $instance_node_label -n "psx_pki_trng" -u $instance_base_addr -d "pcw.dtsi" -p "&amba"]
		add_prop $trng_node "compatible" "xlnx,psx-pmc-trng-11.0" string "pcw.dtsi"
		add_prop $trng_node "status" "okay" string "pcw.dtsi"
		set reg "0x[string range $instance_base_addr 0 end-8] 0x[string range $instance_base_addr end-7 end] 0x0 0x200"
		add_prop $trng_node "reg" $reg hexlist "pcw.dtsi"
		set_memmap $instance_node_label a53 $reg
	}
}
