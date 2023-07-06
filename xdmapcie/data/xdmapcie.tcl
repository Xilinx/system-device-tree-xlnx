proc xdmapcie_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
            return
        }
	if {[string match -nocase [get_ip_property $drv_handle IP_NAME] "qdma"]} {
		pldt append $node compatible "\ \, \"xlnx,qdma-host-3.00\""
		add_prop $node "xlnx,csr-slcr" 0x90000000 hexlist "pl.dtsi" 1
		add_prop $node "xlnx,num-of-bars" 0x2 hexint "pl.dtsi" 1
		add_prop $node "xlnx,include-baroffset-reg" 0x1 hexint "pl.dtsi" 1
		add_prop $node "xlnx,port-type" 1 hexint "pl.dtsi" 1
		add_prop $node "#address-cells" 3 int "pl.dtsi"
		add_prop $node "#size-cells" 2 int "pl.dtsi"
		set ranges "<0x02000000 0x00000000 0xA8000000 0x0 0xA8000000 0x00000000 0x08000000>"
		add_prop $node "ranges" $ranges hexlist "pl.dtsi"
		add_prop $node "device_type" "pci" string "pl.dtsi"
	} elseif {[string match -nocase [get_ip_property $drv_handle IP_NAME] "psv_noc_pcie_1"]} {
		pcwdt append $node compatible "\ \, \"xlnx,versal-cpm-host-1.00\""
		pcwdt append $node compatible "\ \, \"xlnx,versal-cpm5-host\""
		add_prop $node "xlnx,num-of-bars" 0x2 hexint "pcw.dtsi" 1
		add_prop $node "xlnx,port-type" 1 hexint "pcw.dtsi" 1
		add_prop $node "#address-cells" 3 int "pcw.dtsi"
		add_prop $node "#size-cells" 2 int "pcw.dtsi"
		set ranges "0x02000000 0x00000000 0xe0000000 0x0 0xe0000000 0x00000000 0x10000000>, <0x43000000 0x00000080 0x00000000 0x00000080 0x00000000 0x00000000 0x80000000"
		add_prop $node "ranges" $ranges hexlist "pcw.dtsi"
		add_prop $node "xlnx,csr-slcr" fce20000 hexint	"pcw.dtsi" 1
		add_prop $node "device_type" "pci" string "pcw.dtsi"
        }
}
