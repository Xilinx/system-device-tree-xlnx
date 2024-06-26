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

    proc axi_pcie_set_pcie_ranges {drv_handle proctype} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        add_prop $node "#address-cells" 3 int "pl.dtsi"
        add_prop $node "#size-cells" 2 int "pl.dtsi"
        add_prop $node "#interrupt-cells" 1 int "pl.dtsi"
        if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "xdma"]} {
                set axibar_num [get_ip_property $drv_handle "CONFIG.axibar_num"]
        } else {
                set axibar_num [get_ip_property $drv_handle "CONFIG.AXIBAR_NUM"]
        }
        set range_type 0x02000000
        # 64-bit high address.
        set high_64bit 0x00000000
        set ranges ""
        for {set x 0} {$x < $axibar_num} {incr x} {
                if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "xdma"] || [string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_pcie3"]} {
                        set axi_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar_%d" $x]]
                        set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.axibar2pciebar_%d" $x]]
                        set axi_highaddr [get_ip_property $drv_handle [format "CONFIG.axibar_highaddr_%d" $x]]
                } else {
                        set axi_baseaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR_%d" $x]]
                        set pcie_baseaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR2PCIEBAR_%d" $x]]
                        set axi_highaddr [get_ip_property $drv_handle [format "CONFIG.C_AXIBAR_HIGHADDR_%d" $x]]
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

                if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "xdma"]} {
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
                                if {[string match -nocase $proctype "microblaze"] } {
                                        set axi_baseaddr "$axi_baseaddr"
                                } else {
                                        set axi_baseaddr "0x0 $axi_baseaddr"
                                }
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

    proc axi_pcie_set_pcie_reg {drv_handle proctype} {
        set node [get_node $drv_handle]
        if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "xdma"] || [string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_pcie3"]} {
                set baseaddr [get_ip_property $drv_handle CONFIG.baseaddr]
                set highaddr [get_ip_property $drv_handle CONFIG.highaddr]
                set size [format 0x%X [expr $highaddr -$baseaddr + 1]]
                if {[regexp -nocase {0x([0-9a-f]{9})} "$baseaddr" match]} {
                        set temp $baseaddr
                        set temp [string trimleft [string trimleft $temp 0] x]
                        set len [string length $temp]
                        set rem [expr {${len} - 8}]
                        set high_base "0x[string range $temp $rem $len]"
                        set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                        set low_base [format 0x%08x $low_base]
                        set reg "$low_base $high_base 0x0 $size"
                } else {
                        if {[string match -nocase $proctype "microblaze"] } {
                                set reg "$baseaddr $size"
                        } else {
                                set reg "0x0 $baseaddr 0x0 $size"
                        }
                }

                add_prop $node reg $reg hexlist "pl.dtsi" 1
        } else {
                set baseaddr [get_ip_property $drv_handle CONFIG.BASEADDR]
                set highaddr [get_ip_property $drv_handle CONFIG.HIGHADDR]
                set size [format 0x%X [expr $highaddr -$baseaddr + 1]]
                add_prop $node reg "$baseaddr $size" hexlist "pl.dtsi" 1
        }
    }

    proc axi_pcie_axibar_num_workaround {drv_handle} {
        # this required to workaround 2014.2_web tag kernel
        # must have both xlnx,pciebar2axibar-0 and xlnx,pciebar2axibar-1 generated
        set axibar_num [get_ip_property $drv_handle "CONFIG.AXIBAR_NUM"]
        if {[expr $axibar_num <= 1]} {
                set axibar_num 2
        }
        return $axibar_num
    }

    proc axi_pcie_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set family [get_hw_family]
        if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "axi_pcie"]} {
                pldt append $node compatible "\ \, \"xlnx,axi-pcie-host-1.00.a\""
                add_prop $node "xlnx,port-type" 1 hexint "pl.dtsi" 1
        }
        if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "xdma"]} {
                pldt append $node compatible "\ \, \"xlnx,xdma-host-3.00\""
                set msi_rx_pin_en [hsi get_property CONFIG.msi_rx_pin_en [hsi::get_cells -hier $drv_handle]]
                if {[string match -nocase $msi_rx_pin_en "true"]} {
                        set intr_names "misc msi0 msi1"
                        add_prop $node "interrupt-names" $intr_names stringlist "pl.dtsi" 1
                }
                add_prop $node "xlnx,num-of-bars" 0x2 hexint "pl.dtsi" 1
                add_prop $node "xlnx,port-type" 1 hexint "pl.dtsi" 1
		add_prop $node "xlnx,csr-slcr" 0xa0000000 hexint "pl.dtsi" 1
        }
        add_prop $node device_type "pci" string "pl.dtsi"
        set proctype [get_hw_family]
        axi_pcie_set_pcie_reg $drv_handle $proctype
        axi_pcie_set_pcie_ranges $drv_handle $proctype
        set_drv_prop $drv_handle interrupt-map-mask "0 0 0 7" $node intlist
        if {[regexp "microblaze" $proctype match]} {
                set_drv_prop $drv_handle bus-range "0x0 0xff" $node hexint
        }
        # Add Interrupt controller child node
	set pcieintc_cnt [get_count "pci_intc_cnt"]
	set pcie_child_intc_node [create_node -l "pcie_intc_${pcieintc_cnt}" -n interrupt-controller -p $node -d "pl.dtsi"]
	set int_map "0 0 0 1 &pcie_intc_${pcieintc_cnt} 1>, <0 0 0 2 &pcie_intc_${pcieintc_cnt} 2>, <0 0 0 3 &pcie_intc_${pcieintc_cnt} 3>,\
               <0 0 0 4 &pcie_intc_${pcieintc_cnt} 4"
	incr pcieintc_cnt
	set_drv_prop $drv_handle interrupt-map $int_map $node hexlist
	incr pcieintc_cnt

        add_prop "${pcie_child_intc_node}" "interrupt-controller" boolean "pl.dtsi"
        add_prop "${pcie_child_intc_node}" "#address-cells" 0 int "pl.dtsi"
        add_prop "${pcie_child_intc_node}" "#interrupt-cells" 1 int "pl.dtsi"
        set prop [hsi get_property CONFIG.device_port_type [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $prop "Root_Port_of_PCI_Express_Root_Complex"]} {
                add_prop $node "xlnx,device-port-type" 1 hexint "pl.dtsi"
        }
    }


