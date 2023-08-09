	proc axi_can_generate {drv_handle} {
		global env
		global dtsi_fname
		set path $env(REPO)

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}

		set ip_name [get_ip_property $drv_handle IP_NAME]
		if {[string match -nocase $ip_name "can"]} {
			set keyval [pldt append $node compatible "\ \, \"xlnx,axi-can-1.00.a\""]
		}
		set version [string tolower [hsi get_property VLNV $drv_handle]]
		if {[string match -nocase $ip_name "canfd"]} {
			if {[string compare -nocase "xilinx.com:ip:canfd:1.0" $version] == 0} {
				set keyval [pldt append $node compatible "\ \, \"xlnx,canfd-1.0\""]
			} else {
				set keyval [pldt append $node compatible " \, \"xlnx,canfd-2.0\""]
			}
			set_drv_conf_prop $drv_handle NUM_OF_TX_BUF tx-mailbox-count $node hexint
			set_drv_conf_prop $drv_handle NUM_OF_TX_BUF rx-fifo-depth $node hexint
		} else {
			set_drv_conf_prop $drv_handle c_can_num_acf can-num-acf $node hexint
			set_drv_conf_prop $drv_handle c_can_tx_dpth tx-fifo-depth $node hexint
			set_drv_conf_prop $drv_handle c_can_rx_dpth rx-fifo-depth $node hexint
		}

		set proc_type [get_hw_family]
		if {[regexp "microblaze" $proc_type match]} {
			gen_dev_ccf_binding $drv_handle "s_axi_aclk"
		}
	}
