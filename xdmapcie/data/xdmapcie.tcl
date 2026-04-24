#
# (C) Copyright 2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc set_reg_qdma {drv_handle} {
        set node [get_node $drv_handle]

        set ip_mem_handle [lindex [hsi::get_mem_ranges $drv_handle] 0]
        set cfg_baseaddr [string tolower [hsi get_property BASE_VALUE $ip_mem_handle]]
        set cfg_highaddr [string tolower [hsi get_property HIGH_VALUE $ip_mem_handle]]
        set cfg_size [format 0x%X [expr {$cfg_highaddr - $cfg_baseaddr + 1}]]
        set cfg [get_64_bit_reg $cfg_baseaddr $cfg_size]

        set breg_baseaddr [get_ip_property $drv_handle CONFIG.baseaddr]
        set breg_highaddr [get_ip_property $drv_handle CONFIG.highaddr]
        set breg_size [format 0x%X [expr {$breg_highaddr - $breg_baseaddr + 1}]]
        set breg [get_64_bit_reg $breg_baseaddr $breg_size]

        set reg "$cfg $breg"
        add_prop $node reg $reg hexlist "pl.dtsi" 1
}

proc xdmapcie_generate {drv_handle} {
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set ip_type [hsi get_property IP_NAME $drv_handle]
	set default_dts [set_drv_def_dts $drv_handle]
	set val -1

	if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "qdma"]} {
		if {[string match *qdma* $ip_type]} {
			set val [hsi get_property CONFIG.device_port_type $drv_handle]
			pldt append $node compatible "\ \, \"xlnx,qdma-host-3.00\""
		}
		if {[string match -nocase $val "Root_Port_of_PCI_Express_Root_Complex"]} {
			set axibar_num [get_ip_property $drv_handle "CONFIG.axibar_num"]
			set range_type 0x02000000
			# 64-bit high address.
			set high_64bit 0x00000000
			set ranges ""
			set proctype [get_hw_family]
			set no_address_translation [hsi::get_property CONFIG.axibar_notranslate [hsi::get_cells $drv_handle]]
			for {set x 0} {$x < $axibar_num} {incr x} {
				if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "qdma"]} {
					set axi_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar_%d" $x]]
					if {$no_address_translation} {
                                                set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar_%d" $x]]
                                        } else {
                                                set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar2pciebar_%d" $x]]
                                        }
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
			set_reg_qdma $drv_handle
		}

	if {[string match -nocase $val "Root_Port_of_PCI_Express_Root_Complex"]} {
		add_prop $node "xlnx,device_port_type" "Root_Port_of_PCI_Express_Root_Complex" stringlist "pl.dtsi" 1
		add_prop $node "xlnx,csr-slcr" 0x90000000 hexlist "pl.dtsi" 1
		add_prop $node "xlnx,num-of-bars" 0x2 hexint "pl.dtsi" 1
		add_prop $node "xlnx,include-baroffset-reg" 0x1 hexint "pl.dtsi" 1
		add_prop $node "xlnx,port-type" 1 hexint "pl.dtsi" 1
		add_prop $node "#address-cells" 3 int "pl.dtsi"
		add_prop $node "#size-cells" 2 int "pl.dtsi"
		add_prop $node "device_type" "pci" string "pl.dtsi"
		add_prop $node "#interrupt-cells" 1 int "pl.dtsi"
		pldt unset $node "interrupt-names"
		set intr_names "misc msi0 msi1"
		add_prop $node "interrupt-names" $intr_names stringlist "pl.dtsi" 1
		set first_reg_name "cfg"
		set second_reg_name " breg"
		set reg_name [append first_reg_name $second_reg_name]
		add_prop "${node}" "reg-names" ${reg_name} stringlist "pl.dtsi"
		set_drv_prop $drv_handle interrupt-map-mask "0 0 0 7" $node intlist
		# Add Interrupt controller child node
		set intc_cnt [get_count "${ip_type}_intc_cnt"]
		set intc_label "${ip_type}_intc_${intc_cnt}"
		set pcie_child_intc_node [create_node -l $intc_label -n interrupt-controller -p $node -d "pl.dtsi"]
		set int_map "0 0 0 1 &${intc_label} 0>, <0 0 0 2 &${intc_label} 1>, <0 0 0 3 &${intc_label} 2>, <0 0 0 4 &${intc_label} 3"
		set_drv_prop $drv_handle interrupt-map $int_map $node hexlist
		add_prop "${pcie_child_intc_node}" "interrupt-controller" boolean "pl.dtsi"
		add_prop "${pcie_child_intc_node}" "#address-cells" 0 int "pl.dtsi"
		add_prop "${pcie_child_intc_node}" "#interrupt-cells" 1 int "pl.dtsi"
	} else {
		add_prop $node "xlnx,device_port_type" "PCI_Express_Endpoint_device" stringlist "pl.dtsi" 1
	}
    }
}
