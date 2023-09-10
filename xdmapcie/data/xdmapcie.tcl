#
# (C) Copyright 2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc xdmapcie_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
            return
        }

	if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "qdma"]} {
		set axibar_num [get_ip_property $drv_handle "CONFIG.axibar_num"]
		set range_type 0x02000000
		# 64-bit high address.
		set high_64bit 0x00000000
		set ranges ""
               set proctype [get_hw_family]
                for {set x 0} {$x < $axibar_num} {incr x} {
			if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "qdma"]} {
				set axi_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar_%d" $x]]
				set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar2pciebar_%d" $x]]
				set axi_highaddr [get_ip_property $drv_handle [format "CONFIG.axibar_highaddr_%d" $x]]
		}
		set size [expr $axi_highaddr -$axi_baseaddr + 1]
		# Check the size of pci memory region is 4GB or not,if
		# yes then split the size to MSB and LSB.
		if {[regexp -nocase {([0-9a-f]{9})} "$size" match]} {
			set size [format 0x%016x [expr $axi_highaddr -$axi_baseaddr + 1]]
			set low_size [string range $size 0 9]
			set high_size "0x[string range $size 10 17]"
			set size "$low_size $high_size"
		} else {
			set size [format 0x%08x [expr $axi_highaddr - $axi_baseaddr + 1]]
			set size "$high_64bit $size"
		}
		if {[regexp -nocase {([0-9a-f]{9})} "$axi_baseaddr" match] || [regexp -nocase {([0-9a-f]{9})} "$axi_highaddr" match]} {
			set range_type 0x43000000
		}
		if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "qdma"]} {
			if {[regexp -nocase {([0-9a-f]{9})} "$pcie_baseaddr" match]} {
				set temp $pcie_baseaddr
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_base "0x[string range $temp $rem $len]"
				set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_base [format 0x%08x $low_base]
				set pcie_baseaddr "$low_base $high_base"
			} else {
				set pcie_baseaddr "$high_64bit $pcie_baseaddr"
			}
			if {[regexp -nocase {([0-9a-f]{9})} "$axi_baseaddr" match]} {
				set temp $axi_baseaddr
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_base "0x[string range $temp $rem $len]"
				set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_base [format 0x%08x $low_base]
				set axi_baseaddr "$low_base $high_base"
			} else {
				set axi_baseaddr "0x0 $axi_baseaddr"
			}
			set value "$range_type $pcie_baseaddr $axi_baseaddr $size"
		} else {
			set value "$range_type $high_64bit $pcie_baseaddr $axi_baseaddr $size"
		}
		if {[string match "" $ranges]} {
			set ranges $value
		} else {
			append ranges "> , <" $value
		}
	}

	add_prop $node "ranges" $ranges hexlist "pl.dtsi"

	}

	if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "qdma"]} {
		pldt append $node compatible "\ \, \"xlnx,qdma-host-3.00\""
		add_prop $node "xlnx,csr-slcr" 0x90000000 hexlist "pl.dtsi" 1
		add_prop $node "xlnx,num-of-bars" 0x2 hexint "pl.dtsi" 1
		add_prop $node "xlnx,include-baroffset-reg" 0x1 hexint "pl.dtsi" 1
		add_prop $node "xlnx,port-type" 1 hexint "pl.dtsi" 1
		add_prop $node "#address-cells" 3 int "pl.dtsi"
		add_prop $node "#size-cells" 2 int "pl.dtsi"
		add_prop $node "device_type" "pci" string "pl.dtsi"
	} elseif {[string match -nocase [get_ip_property $drv_handle IP_NAME] "psv_noc_pcie_1"]} {
		set cpm_rev "0"
		set cpm_handle [hsi::get_cells -hier versal_cips_0_cpm_0_psv_cpm]
		set hsi_cpm_rev_num ""
		if {[catch {set hsi_cpm_rev_num [hsi get_property CONFIG.CPM_REVISION_NUMBER $cpm_handle]} msg]} {
		}
		if {![string_is_empty $hsi_cpm_rev_num]} {
		    set cpm_rev $hsi_cpm_rev_num
		}

		if {$cpm_rev == "0"} {
			pcwdt append $node compatible "\ \, \"xlnx,versal-cpm-host-1.00\""
			add_prop $node "xlnx,csr-slcr" "0x6 00000000" hexlist "pcw.dtsi" 1
		} else {
			pcwdt append $node compatible "\ \, \"xlnx,versal-cpm5-host\""
			add_prop $node "xlnx,csr-slcr" "0xfce20000" hexlist "pcw.dtsi" 1
		}
		add_prop $node "xlnx,num-of-bars" 0x2 hexint "pcw.dtsi" 1
		add_prop $node "xlnx,port-type" 1 hexint "pcw.dtsi" 1
		add_prop $node "#address-cells" 3 int "pcw.dtsi"
		add_prop $node "#size-cells" 2 int "pcw.dtsi"
		set ranges "0x02000000 0x00000000 0xe0000000 0x0 0xe0000000 0x00000000 0x10000000>, <0x43000000 0x00000080 0x00000000 0x00000080 0x00000000 0x00000000 0x80000000"
		add_prop $node "ranges" $ranges hexlist "pcw.dtsi"
		add_prop $node "device_type" "pci" string "pcw.dtsi"
        }
}
