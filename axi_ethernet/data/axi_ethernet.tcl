#
# (C) Copyright 2014-2021 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
#
# Michal SIMEK <monstr@monstr.eu>
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

namespace eval ::tclapp::xilinx::devicetree::axi_ethernet { 
namespace import ::tclapp::xilinx::devicetree::common::\*
set rxethmem 0

	proc generate {drv_handle} {
		global env
		global dtsi_fname
		set path $env(REPO)

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		set hw_design [hsi::current_hw_design]
	    	set board_name ""
    		if {[llength $hw_design]} {
			set board [split [get_property BOARD $hw_design] ":"]
	        	set board_name [lindex $board 1]
    		}
		global env
		set path $env(REPO)
		set common_file "$path/device_tree/data/config.yaml"
		set dt_overlay [get_user_config $common_file -dt_overlay]
		set bus_node [detect_bus_name $drv_handle]
	    	global rxethmem
	    	set rxethmem 0
		global ddrv_handle
		set ddrv_handle $drv_handle
		set dts_file [set_drv_def_dts $drv_handle]
		update_eth_mac_addr $drv_handle
		#adding stream connectivity
		set eth_ip [hsi::get_cells -hier $drv_handle]
		set ip_mem_handles [hsi::get_mem_ranges $eth_ip]
		if {[llength $ip_mem_handles] == 0} {
			return
		}
		# search for a valid bus interface name
		# This is required to work with Vivado 2015.1 due to IP PIN naming change
		set hasbuf [get_property CONFIG.processor_mode $eth_ip]
		set ip_name [get_property IP_NAME $eth_ip]
		if {$ip_name == "axi_ethernet"} {
			pldt append $node compatible "\ \, \"xlnx,axi-ethernet-1.00.a\""
		}
		set num_cores 1
		if {$ip_name == "xxv_ethernet"} {
			set ip_mem_handles [hsi::get_mem_ranges [hsi::get_cells -hier $drv_handle]]
			set num 0
			generate_reg_property $node $ip_mem_handles $num
			set num_cores [get_property CONFIG.NUM_OF_CORES [hsi::get_cells -hier $drv_handle]]
		}
		set new_label ""
		set clk_label ""
		set connected_ip ""
		set eth_node ""
		for {set core 0} {$core < $num_cores} {incr core} {
			if {$ip_name == "xxv_ethernet"  && $core != 0} {
				global env
				set path $env(REPO)
				set common_file "$path/device_tree/data/config.yaml"
				set dt_overlay [get_user_config $common_file -dt_overlay]
				if {$dt_overlay} {
					set bus_node "overlay2"
				} else {
					set bus_node "amba_pl: amba_pl"
				}
				#set dts_file [current_dt_tree]
				set dts_file "pl.dtsi"
				set ipmem_len [llength $ip_mem_handles]
				if {$ipmem_len > 1} {
					set base_addr [string tolower [get_property BASE_VALUE [lindex $ip_mem_handles $core]]]
					regsub -all {^0x} $base_addr {} base_addr
					append new_label $drv_handle "_" $core
					append clk_label $drv_handle "_" $core
					set eth_node [create_node -n "ethernet" -l "$new_label" -u $base_addr -d $dts_file -p $bus_node]
					generate_reg_property $eth_node $ip_mem_handles $core
				}
			}
			if {$hasbuf == "true" || $hasbuf == "" && $ip_name != "axi_10g_ethernet" && $ip_name != "ten_gig_eth_mac" && $ip_name != "xxv_ethernet" && $ip_name != "usxgmii"} {
				foreach n "AXI_STR_RXD m_axis_rxd" {
					set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
					if {[string_is_empty ${intf}] != 1} {
						break
					}
				}
				if { [llength $intf] } {
					set intf_net [hsi::get_intf_nets -of_objects $intf ]
					if { [llength $intf_net]  } {
						set target_intf [get_other_intf_pin $intf_net $intf]
						if { [llength $target_intf] } {
							set connected_ip [get_connectedip $intf]				
							if {[llength $connected_ip]} {
								#set_property axistream-connected "$connected_ip" $drv_handle
								add_prop $node axistream-connected "$connected_ip" reference $dts_file 1
								#set_property axistream-control-connected "$connected_ip" $drv_handle
								add_prop $node axistream-control-connected "$connected_ip" reference $dts_file 1
								set ip_prop CONFIG.c_include_mm2s_dre
								add_cross_property $connected_ip $ip_prop $drv_handle "xlnx,include-dre" boolean
							} else {
								dtg_warning "$drv_handle connected ip is NULL for the interface $intf"
							}
							set ip_prop CONFIG.Enable_1588
							add_cross_property $eth_ip $ip_prop $drv_handle "xlnx,eth-hasptp" boolean
						}
					}
				}
				foreach n "AXI_STR_RXD m_axis_tx_ts" {
					set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
					if {[string_is_empty ${intf}] != 1} {
			    			break
					}
				}

				if {[string_is_empty ${intf}] != 1} {
					set tx_tsip [get_connectedip $intf]
					set_drv_prop $drv_handle axififo-connected "$tx_tsip" reference
				}
			} else {
				foreach n "AXI_STR_RXD m_axis_rx" {
					set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
					if {[string_is_empty ${intf}] != 1} {
			    			break
					}
				}

				if {$ip_name == "xxv_ethernet" || $ip_name == "usxgmii"} {
					foreach n "AXI_STR_RXD axis_rx_0" {
			   			set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
			   			if {[string_is_empty ${intf}] != 1} {
			       				break
			  			}
					}
				}

				if { [llength $intf] } {
					set connected_ip [get_connectedip $intf]
				}

				foreach n "AXI_STR_RXD m_axis_tx_ts" {
					set intf [hsi::get_intf_pins -of_objects $eth_ip ${n}]
					if {[string_is_empty ${intf}] != 1} {
			    			break
					}
				}

				if {[string_is_empty ${intf}] != 1} {
					set tx_tsip [get_connectedip $intf]
					set_drv_prop $drv_handle axififo-connected "$tx_tsip" reference
				}
				if {![string_is_empty $connected_ip]} {
					add_prop $node axistream-connected "$connected_ip" reference $dts_file 1
					#set_property axistream-control-connected "$connected_ip" $drv_handle
					add_prop $node axistream-control-connected "$connected_ip" reference $dts_file 1
					# set_property axistream-connected "$connected_ip" $drv_handle
					# set_property axistream-control-connected "$connected_ip" $drv_handle
					set ip_prop CONFIG.c_include_mm2s_dre
					add_cross_property $connected_ip $ip_prop $drv_handle "xlnx,include-dre" boolean
				}
				#set_property xlnx,rxmem "$rxethmem" $drv_handle
				add_prop $node xlnx,rxmem "$rxethmem" string $dts_file
				if {$ip_name == "xxv_ethernet"  && $core != 0} {
					set intf [hsi::get_intf_pins -of_objects $eth_ip "axis_rx_${core}"]
					if {[llength $intf] && [llength $eth_node]} {
						set connected_ip [get_connectedip $intf]
						if {![string_is_empty $connected_ip]} {
						      add_prop $eth_node "axistream-connected" "$connected_ip" reference "pl.dtsi"
						      add_prop $eth_node "axistream-control-connected" "$connected_ip" reference "pl.dtsi"
						}
						add_prop $eth_node "xlnx,include-dre" boolean "pl.dtsi"
						#add_prop $eth_node "xlnx,rxmem" "$rxethmem" hex "pl.dtsi"
					}
				}
			}

			if {$ip_name == "axi_ethernet"} {
				set txcsum [get_property CONFIG.TXCSUM $eth_ip]
				set txcsum [get_checksum $txcsum]
				set rxcsum [get_property CONFIG.RXCSUM $eth_ip]
				set rxcsum [get_checksum $rxcsum]
				set phytype [get_property CONFIG.PHY_TYPE $eth_ip]
				set phytype [get_phytype $phytype]
				set phyaddr [get_property CONFIG.PHYADDR $eth_ip]
				#set phyaddr [convert_binary_to_decimal $phyaddr]
				set rxmem [get_property CONFIG.RXMEM $eth_ip]
				set rxmem [get_memrange $rxmem]
				add_prop $node "xlnx,txcsum" $txcsum hexint "pl.dtsi" 1
				add_prop $node "xlnx,rxcsum" $rxcsum hexint "pl.dtsi" 1
				add_prop $node "xlnx,phy-type" $phytype hexint "pl.dtsi" 1
				add_prop $node "xlnx,phyaddr" $phyaddr hexint "pl.dtsi" 1
				add_prop $node "xlnx,rxmem" $rxmem hexint "pl.dtsi" 1
			}

			set is_nobuf 0
			if {$ip_name == "axi_ethernet"} {
				set avail_param [list_property [hsi::get_cells -hier $drv_handle]]
				if {[lsearch -nocase $avail_param "CONFIG.speed_1_2p5"] >= 0} {
					if {[get_property CONFIG.speed_1_2p5 [hsi::get_cells -hier $drv_handle]] == "2p5G"} {
						set is_nobuf 1
						pldt append $node compatible "\ \, \"xlnx,axi-2_5-gig-ethernet-1.0\""	
						#set_property compatible "xlnx,axi-2_5-gig-ethernet-1.0" $drv_handle
			    		}
				}
			}
			if { $hasbuf == "false" && $is_nobuf == 0} {
				set ip_prop CONFIG.processor_mode
				add_cross_property $eth_ip $ip_prop $drv_handle "xlnx,eth-hasnobuf" boolean
			}
			#adding clock frequency
			set clk [hsi::get_pins -of_objects $eth_ip "S_AXI_ACLK"]
			if {[llength $clk] } {
				set freq [get_property CLK_FREQ $clk]
				#set_property clock-frequency "$freq" $drv_handle
				add_prop $node clock-frequency "$freq" int "pl.dtsi"
				#add_prop $node clock-frequency "$freq" int $dts_file
				if {$ip_name == "xxv_ethernet" && [llength $eth_node]} {
					add_prop $eth_node "clock-frequency" "$freq" int "pl.dtsi"
				}
			}

			# node must be created before child node
			if {$ip_name == "axi_ethernet"} {
				#set hier_params [gen_hierip_params $drv_handle]
			}
			set mdio_node [gen_mdio_node $drv_handle $node]
			set phytype [string tolower [get_property CONFIG.PHY_TYPE $eth_ip]]
			if {$phytype == "rgmii" && $board_name == "kc705"} {
				set phytype "rgmii-rxid"
			} elseif {$phytype == "1000basex"} {
				set phytype "1000base-x"
			}
			#set_property phy-mode "$phytype" $drv_handle
			if {![string match -nocase $phytype ""]} {
				add_prop $node phy-mode "$phytype" string "pl.dtsi" 1
				#add_prop $node phy-mode "$phytype" string $dts_file
			}
			if {$phytype == "sgmii" || $phytype == "1000base-x"} {
				#set_property phy-mode "$phytype" $drv_handle
				add_prop $node phy-mode "$phytype" string "pl.dtsi" 1
				#add_prop $node phy-mode "$phytype" string $dts_file
			  	set phynode [pcspma_phy_node $eth_ip]
			  	set phya [lindex $phynode 0]
			  	if { $phya != "-1"} {
					set phy_name "[lindex $phynode 1]"
					set_drv_prop $drv_handle phy-handle "$drv_handle$phy_name" reference
					gen_phy_node $mdio_node $phy_name $phya $drv_handle
			  	}
			}
			if {$ip_name == "xxv_ethernet" && $core != 0 && [llength $eth_node]} {
				append new_label "_" mdio
				set mdionode [create_node -l "$new_label" -n mdio -p $eth_node -d $dts_file]
				add_prop $mdionode "#address-cells" 1 int $dts_file
				add_prop "${mdionode}" "#size-cells" 0 int $dts_file
				set new_label ""
			}
			if {$ip_name == "axi_10g_ethernet"} {
				set phytype [string tolower [get_property CONFIG.base_kr $eth_ip]]
				#set_property phy-mode "$phytype" $drv_handle
				add_prop $node phy-mode "$phytype" string "pl.dtsi"
				#add_prop $node phy-mode "$phytype" string $dts_file
				add_prop $node "phy-mode" $phytype string "pl.dtsi"
				#add_prop $node "phy-mode" $phytype string $dts_file 
				pldt append $node compatible "\ \, \"xlnx,ten-gig-eth-mac\""
			}
			if {$ip_name == "xxv_ethernet"} {
				set phytype [string tolower [get_property CONFIG.BASE_R_KR $eth_ip]]
				add_prop $node phy-mode "$phytype" string $dts_file
				if {$core == 0} {
					pldt append $node compatible "\ \, \"xlnx,xxv-ethernet-1.0\""
				}
				if { $core!= 0 && [llength $eth_node]} {
					set compatible [pldt get $node compatible]
					set compatible [string trimright $compatible "\""]
					set compatible [string trimleft $compatible "\""]
					add_prop $eth_node "compatible" $compatible string "pl.dtsi"
					add_prop $eth_node "phy-mode" $phytype string "pl.dtsi"
				}
			}
			if {$ip_name == "usxgmii"} {
				pldt append $node compatible "\ \, \"xlnx,xxv-usxgmii-ethernet-1.0\""
				add_prop $node "xlnx,phy-type" 7 int "pl.dtsi"
				add_prop $node "xlnx,usxgmii-rate" 1000 int "pl.dtsi"
			}
			set ips [hsi::get_cells -hier $drv_handle]
			foreach ip [get_drivers 1] {
				if {[string compare -nocase $ip $connected_ip] == 0} {
					set target_handle $ip
				}
			}
			set hsi_version [get_hsi_version]
			set ver [split $hsi_version "."]
			set version [lindex $ver 0]
			if {![string_is_empty $connected_ip]} {
				set connected_ipname [get_property IP_NAME $connected_ip]
				if {$connected_ipname == "axi_mcdma" || $connected_ipname == "axi_dma"} {
			    	set num_queues [get_property CONFIG.c_num_mm2s_channels $connected_ip]
					set inhex [format %x $num_queues]
					set numqueues "/bits/ 16 <0x$inhex>"
					add_prop $node "xlnx,num-queues" $numqueues stringlist "pl.dtsi"
					#add_prop $node "xlnx,num-queues" $numqueues stringlist $dts_file
					if {$version < 2018} {
						dtg_warning "quotes to be removed or use 2018.1 version for $node param xlnx,num-queues"
					}
					set id 1
					for {set i 2} {$i <= $num_queues} {incr i} {
						set i [format "%x" $i]
						append id "\""
						append id " ,\"" $i
						set i [expr 0x$i]
					}
					add_prop $node "xlnx,channel-ids" $id intlist "pl.dtsi"
					#add_prop $node "xlnx,channel-ids" $id intlist $dts_file
					if {$ip_name == "xxv_ethernet"  && $core!= 0 && [llength $eth_node]} {
						add_prop $eth_node "xlnx,num-queues" $numqueues stringlist $dts_file
						add_prop $eth_node "xlnx,channel-ids" $id stringlist $dts_file
					}
					set ipnode [get_node $target_handle]
					set values [pldt getall $ipnode]
					set intr_parent ""
					if {[regexp "interrupt*" $values match]} {
						set intr_val [pldt get $ipnode interrupts]
						set intr_val [string trimright $intr_val " >"]
						set intr_val [string trimleft $intr_val "< "]
						set intr_parent [pldt get $ipnode interrupt-parent]
						set intr_parent [string trimright $intr_parent ">"]
						set intr_parent [string trimleft $intr_parent "<"]
						set intr_parent [string trimleft $intr_parent "&"]
						#set intr_parent [get_property CONFIG.interrupt-parent $target_handle]
						set int_names  [pldt get $ipnode interrupt-names]
						set names [split $int_names ","]
						if {[llength $names] >= 1} {
							set int1 [string trimright [lindex $names 0] "\" "]
							set int1 [string trimleft $int1 "\""]
						}
						if {[llength $names] >= 2} {
							set int2 [string trimright [lindex $names 1] "\" "]
							set int2 [string trimleft $int2 "\" "]
						}
					}
					if {[regexp "interrupt*" $values match]} {
						if { $hasbuf == "true" && $ip_name == "axi_ethernet"} {
							set intr_val1 [pldt get $node interrupts]
							set intr_val1 [string trimright $intr_val1 " >"]
							set intr_val1 [string trimleft $intr_val1 "< "]
							lappend intr_val1 $intr_val
							set intr_name [pldt get $node interrupt-names]
							set intr_name [string trimleft $intr_name "\""]
							set intr_name [string trimright $intr_name "\""]
							append intr_names " " $intr_name " "  $int1 " " $int2
							set proctype [get_hw_family]
							if {[regexp "kintex*" $proctype match]} {
								set null ""
								add_prop $node "interrupt-names" $null stringlist "pl.dtsi"
								add_prop $node "interrupts" $null intlist "pl.dtsi"
							}
						} else {
							set intr_names $int_names
						}
					}
					set default_dts "pl.dtsi"
					set nodep [get_node $drv_handle]
					if {![string_is_empty $intr_parent]} {
						#if { $hasbuf == "true" && $ip_name == "axi_ethernet"} {
						#regsub -all "\{||\t" $intr_val1 {} intr_val1
						#regsub -all "\}||\t" $intr_val1 {} intr_val1
						#add_prop $node "interrupts" $intr_val1 int "pl.dtsi"
						#} else {
						#	add_prop $node "interrupts" $intr_val1 int "pl.dtsi"
						#}
						#add_prop $node "interrupt-parent" $intr_parent reference "pl.dtsi"
						#add_prop $node "interrupt-names" $intr_names stringlist "pl.dtsi"
						if {$ip_name == "xxv_ethernet"  && $core!= 0 && [llength $eth_node]} {
							add_prop "${eth_node}" "interrupts" $intr_val intlist $dts_file
							add_prop "${eth_node}" "interrupt-parent" $intr_parent reference $dts_file
							add_prop "${eth_node}" "interrupt-names" $intr_names stringlist $dts_file
						} else {
							if { $hasbuf == "true" && $ip_name == "axi_ethernet"} {
								regsub -all "\{||\t" $intr_val1 {} intr_val1
								regsub -all "\}||\t" $intr_val1 {} intr_val1
								add_prop "${nodep}" "interrupts" $intr_val1 intlist "pl.dtsi" 1
							} else {
								add_prop "${nodep}" "interrupts" $intr_val intlist "pl.dtsi"
							}
							add_prop "${nodep}" "interrupt-parent" $intr_parent reference "pl.dtsi"
							add_prop "${nodep}" "interrupt-names" $intr_names stringlist "pl.dtsi" 1
							set test [pldt get $nodep interrupt-names]
						}
					}
				}
				if {$connected_ipname == "axi_dma" || $connected_ipname == "axi_mcdma"} {
					#set proctype [get_property IP_NAME [hsi::get_cells -hier [get_sw_processor]]]
					set proctype [get_hw_family]
					if {![regexp "kintex*" $proctype match]} {
						set eth_clk_names [pldt get $node clock-names]
						set eth_clks [pldt get $node clocks]
						set eth_clks [string trimright $eth_clks ">"]
						set eth_clks [string trimleft $eth_clks "<"]
						set eth_clks [string trimleft $eth_clks "&"]
						set eth_clk_names [split $eth_clk_names " , "]
						set eth_clkname_len [llength $eth_clk_names]
						for {set i 0 } {$i < $eth_clkname_len} {incr i} {
							set trimvar [lindex $eth_clk_names $i]
							set trimvar [string trimright $trimvar "\""]
							set trimvar [string trimleft $trimvar "\""]
							append temp "$trimvar "
						}
						if {$ip_name == "xxv_ethernet" && $core == 0} {
							add_prop "${nodep}" "zclocks" $eth_clks reference "pl.dtsi"
							set_drv_prop $drv_handle "zclock-names" $temp stringlist
						}
						if {$ip_name == "xxv_ethernet" && $core != 0} {
							set eth_clks [pldt get $nodep zclocks]
							set eth_clk_names [pldt get $nodep zclock-names]
							set eth_clks [string trimright $eth_clks ">"]
							set eth_clks [string trimleft $eth_clks "<"]
							set eth_clks [string trimleft $eth_clks "&"]
							set eth_clk_names [split $eth_clk_names " , "]
							set eth_clkname_len [llength $eth_clk_names]
							for {set i 0 } {$i < $eth_clkname_len} {incr i} {
								set trimvar [lindex $eth_clk_names $i]
								set trimvar [string trimright $trimvar "\""]
								set trimvar [string trimleft $trimvar "\""]
								append temp "$trimvar "
							}
						}
						set eth_clk_names $temp
						set i 0
						set dclk ""
						while {$i < $eth_clkname_len} {
							set clkname [lindex $eth_clk_names $i]
							for {set corenum 0} {$corenum < $num_cores} {incr corenum} {
								if {[string match -nocase $clkname "rx_core_clk_$corenum"]} {
									set core_clk_$corenum "rx_core_clk"
									set index_$corenum $i
								}
								if {[string match -nocase $clkname "s_axi_aclk_$corenum"]} {
									set axi_aclk_$corenum "s_axi_aclk"
									set axi_index_$corenum $i
								}
								if {[string match -nocase $clkname "dclk"]} {
									set dclk "dclk"
									set dclk_index $i
								}
							}
							incr i
						}
						set eth_clk_len [expr {[llength [split $eth_clks ","]]}]
						set clk_list [split $eth_clks ","]
						set ipnode [get_node $target_handle]
						set clk_names [pldt get $ipnode clock-names]
						set clk_names [split $clk_names " , "]
						set len [llength $clk_names]
						set temp ""
						for {set i 0 } {$i < $len} {incr i} {
							set trimvar [lindex $clk_names $i]
							set trimvar [string trimright $trimvar "\""]
							set trimvar [string trimleft $trimvar "\""]
							append temp "$trimvar "
						}
						set clk_names $temp
						set clks [pldt get $ipnode clocks]
						append names "$eth_clk_names" "$clk_names"
						set names ""
						append clk  "$eth_clks>," " $clks"
						set clks [string trimright $clks ">"]
						#set default_dts [get_property CONFIG.pl_dts [get_os]]
						set null ""
						#add_prop $nodep "clock-names" $null stringlist "pl.dtsi"
						#add_prop $nodep "clocks" $null reference "pl.dtsi"

						if {$ip_name == "xxv_ethernet"  && $core== 0} {
							if {[llength $dclk]} {	
								append clknames "$core_clk_0 " "$dclk " "$axi_aclk_0"
							} else {
								append clknames "$core_clk_0" "$axi_aclk_0"
							}		
							append clknames1 " $clknames" " $clk_names"
							set index0 [lindex $clk_list $axi_index_0]
							regsub -all "\>||\t" $index0 {} index0
							if {[llength $dclk]} {
								append clkvals  "[lindex $clk_list $index_0], [lindex $clk_list $dclk_index], $index0>, $clks"
							} else {
								append clkvals  "[lindex $clk_list $index_0], $index0>, <&$clks"
							}
							#set plnode [create_node -n "&${drv_handle}" -d "pl.dtsi" -p root]
							#  add_prop $eth_node "clocks" $clkvals reference "pl.dtsi"
							#  add_prop "$eth_node" "clock-names" $clknames1 stringlist "pl.dtsi"
							set clknames1 ""
						}
						if {$ip_name == "xxv_ethernet" && $core == 1 && [llength $eth_node]} {
							if {[llength $dclk]} {
								append clknames1 "$core_clk_1" "$dclk" "$axi_aclk_1"
							} else {
								append clknames1 "$core_clk_1" "$axi_aclk_1"
							}
							append clk_names1 " $clknames1" " $clk_names"
							set index1 [lindex $clk_list $axi_index_1]
							regsub -all "\>||\t" $index1 {} index1
							set ini1 [lindex $clk_list $index_1]
							regsub -all " " $ini1 "" ini1
							regsub -all "\<&||\t" $ini1 {} ini1
							if {[llength $dclk]} {
								append clkvals1  "$ini1, [lindex $clk_list $dclk_index], $index1>, <&$clks"
							} else {
								append clkvals1  "$ini1, $index1>, <&$clks"
							}
							# set eth1_node [create_node -n "&$clk_label" -d "pl.dtsi" -p root]
							add_prop "${eth_node}" "clocks" $clkvals1 reference "pl.dtsi"
							add_prop "${eth_node}" "clock-names" $clk_names1 stringlist "pl.dtsi"
							set clk_names1 ""
							set clkvals1 ""
						}
						if {$ip_name == "xxv_ethernet" && $core == 2 && [llength $eth_node]} {
							if {[llength $dclk]} {
								append clknames2 "$core_clk_2" "$dclk" "$axi_aclk_2"
							} else {
								append clknames2 "$core_clk_2" "$axi_aclk_2"
							}
							append clk_names2 " $clknames2" " $clk_names"
							set index2 [lindex $clk_list $axi_index_2]
							regsub -all "\>||\t" $index2 {} index2
							set ini2 [lindex $clk_list $index_2]
							regsub -all " " $ini2 "" ini2
							regsub -all "\<&||\t" $ini2 {} ini2
							if {[llength $dclk]} {
								append clkvals2  "$ini2, [lindex $clk_list $dclk_index],[lindex $clk_list $axi_index_2], <&$clks"
							} else {
								append clkvals2  "$ini2, [lindex $clk_list $axi_index_2], <&$clks"
							}
							append clk_label2 $drv_handle "_" $core
							# set eth2_node [create_node -n "&$clk_label2" -d "pl.dtsi" -p root]
							add_prop "${eth_node}" "clocks" $clkvals2 reference "pl.dtsi"
							add_prop "${eth_node}" "clock-names" $clk_names2 stringlist "pl.dtsi"
							set clk_names2 ""
							set clkvals2 ""
						}
						if {$ip_name == "xxv_ethernet" && $core == 3 && [llength $eth_node]} {
							if {[llength $dclk]} {
								append clknames3 "$core_clk_3" "$dclk" "$axi_aclk_3"
							} else {
								append clknames3 "$core_clk_3" "$axi_aclk_3"
							}
							append  clk_names3 " $clknames3" " $clk_names"
							set index3 [lindex $clk_list $axi_index_3]
							regsub -all "\>||\t" $index3 {} index3
							set ini [lindex $clk_list $index_3]
							regsub -all " " $ini "" ini
							regsub -all "\<&||\t" $ini {} ini
							if {[llength $dclk]} {
								append clkvals3 "$ini, [lindex $clk_list $dclk_index], [lindex $clk_list $axi_index_3]>, <&$clks"
							} else {
								append clkvals3 "$ini, [lindex $clk_list $axi_index_3]>, <&$clks"
							}
							append clk_label3 $drv_handle "_" $core
							# set eth3_node [create_node -n "&$clk_label3" -d "pl.dtsi" -p root]
							add_prop "${eth_node}" "clocks" $clkvals3 reference "pl.dtsi"
							add_prop "${eth_node}" "clock-names" $clk_names3 stringlist "pl.dtsi"
							set clk_names3 ""
							set clkvals3 ""
						}
					}
				}
			}
			if {$ip_name == "xxv_ethernet"  && $core!= 0 && [llength $eth_node]} {
				gen_drv_prop_eth_ip $drv_handle $eth_node
			}
			gen_dev_ccf_binding $drv_handle "s_axi_aclk"
		}
		set proctype [get_hw_family]
		if {[regexp "kintex*" $proctype match]} {
			set null ""
			add_prop $node "zclock-names" $null stringlist "pl.dtsi"
			add_prop $node "zclocks" $null reference "pl.dtsi"
		}
	}

	proc pcspma_phy_node {slave} {
		set phyaddr [get_property CONFIG.PHYADDR $slave]
		#set phyaddr [convert_binary_to_decimal $phyaddr]
		set phymode "phy$phyaddr"

		return "$phyaddr $phymode"
	}

	proc get_checksum {value} {
		if {[string compare -nocase $value "None"] == 0} {
			set value 0
		} elseif {[string compare -nocase $value "Partial"] == 0} {
			set value 1
		} else {
			set value 2
		}

		return $value
	}

	proc get_memrange {value} {
		set values [split $value "k"]
		lassign $values value1 value2

		return [expr $value1 * 1024]
	}

	proc get_phytype {value} {
		if {[string compare -nocase $value "MII"] == 0} {
			set value 0
		} elseif {[string compare -nocase $value "GMII"] == 0} {
			set value 1
		} elseif {[string compare -nocase $value "RGMII"] == 0} {
			set value 3
		} elseif {[string compare -nocase $value "SGMII"] == 0} {
			set value 4
		} else {
			set value 5
		}

		return $value
	}

	proc gen_hierip_params {drv_handle} {
		set prop_name_list [deault_parameters $drv_handle]
		foreach prop_name ${prop_name_list} {
			ip2drv_prop $drv_handle $prop_name
		}
	}

	proc deault_parameters {ip_handle {dont_generate ""}} {
		set par_handles [get_ip_conf_prop_list $ip_handle "CONFIG.*"]
		set valid_prop_names {}
		foreach par $par_handles {
			regsub -all {CONFIG.} $par {} tmp_par
			# Ignore some parameters that are always handled specially
			switch -glob $tmp_par {
				$dont_generate - \
				"Component_Name" - \
				"DIFFCLK_BOARD_INTERFACE" - \
				"EDK_IPTYPE" - \
				"ETHERNET_BOARD_INTERFACE" - \
				"Include_IO" - \
				"PHY_TYPE" - \
				"RXCSUM" - \
				"TXCSUM" - \
				"TXMEM" - \
				"RXMEM" - \
				"PHYADDR" - \
				"C_BASEADDR" - \
				"C_HIGHADDR" - \
				"processor_mode" - \
				"Enable_1588_1step" - \
				"lvdsclkrate" - \
				"gtrefclkrate" - \
				"drpclkrate" - \
				"Enable_Pfc" - \
				"Frame_Filter" - \
				"MDIO_BOARD_INTERFACE" - \
				"Number_of_Table_Entries" - \
				"PHYRST_BOARD_INTERFACE" - \
				"SIMULATION_MODE" - \
				"Statistics_Reset" - \
				"Statistics_Width" - \
				"SupportLevel" - \
				"TIMER_CLK_PERIOD" - \
				"Timer_Format" - \
				"SupportLevel" - \
				"TransceiverControl" - \
				"USE_BOARD_FLOW" - \
				"HW_VER" { } \
				default {
					lappend valid_prop_names $par
				}
			}
		}
		return $valid_prop_names
	}

	proc gen_phy_node args {
	    set mdio_node [lindex $args 0]
	    set phy_name [lindex $args 1]
	    set phya [lindex $args 2]
	    set drv  [lindex $args 3]

	    set phy_node [create_node -l $drv$phy_name -n phy -u $phya -p $mdio_node -d "pl.dtsi"]
	    add_prop "${phy_node}" "reg" $phya int "pl.dtsi"
	    add_prop "${phy_node}" "device_type" "ethernet-phy" string "pl.dtsi"

	    return $phy_node
	}

	proc is_ethsupported_target {connected_ip} {
	   set connected_ipname [get_property IP_NAME $connected_ip]
	   if {$connected_ipname == "axi_dma" || $connected_ipname == "axi_fifo_mm_s" || $connected_ipname == "axi_mcdma"} {
	      return "true"
	   } else {
	      return "false"
	   }
	}

	proc get_targetip {ip} {
	  global ddrv_handle
	   if {[string_is_empty $ip] != 0} {
	       return
	   }
	   set p2p_busifs_i [hsi::get_intf_pins -of_objects $ip -filter "TYPE==INITIATOR || TYPE==MASTER"]
	   set target_periph ""
	   foreach p2p_busif $p2p_busifs_i {
	      set busif_name [string toupper [get_property NAME  $p2p_busif]]
	      set conn_busif_handle [get_connected_intf $ip $busif_name]
	      if {[string_is_empty $conn_busif_handle] != 0} {
		  continue
	      }
	      set target_periph [hsi::get_cells -of_objects $conn_busif_handle]
	      set cell_name [hsi::get_cells -hier $target_periph]
	      set target_name [get_property IP_NAME [hsi::get_cells -hier $target_periph]]
	      if {$target_name == "axis_data_fifo" || $target_name == "Ethernet_filter"} {
		  #set target_periph [get_cells -of_objects $conn_busif_handle]
		  set master_slaves [hsi::get_intf_pins -of [hsi::get_cells -hier $cell_name]]
		  if {[llength $master_slaves] == 0} {
		      return
		  }
		  set master_intf ""
		  foreach periph_intf $master_slaves {
		      set prop [get_property TYPE $periph_intf]
		      if {$prop == "INITIATOR"} {
			  set master_intf $periph_intf
		      }
		  }
		  if {[llength $master_intf] == 0} {
		      return
		  }
		  set intf [hsi::get_intf_pins -of_objects $cell_name $master_intf]
		  set intf_net [hsi::get_intf_nets -of_objects $intf]
		  set intf_pins [get_other_intf_pin $intf_net $intf]
		  foreach intf $intf_pins {
		      set target_intf [hsi::get_intf_pins -of_objects $intf_net -filter "TYPE==TARGET" $intf]
		      if {[llength $target_intf]} {
			   set connected_ip [hsi::get_cells -of_objects $target_intf]
			   if {[llength $connected_ip]} {
				 set cell [hsi::get_cells -hier $connected_ip]
				 set target_name [get_property IP_NAME [hsi::get_cells -hier $cell]]
				 if {$target_name == "axis_data_fifo"} {
					  return [get_targetip $connected_ip]
				 }
				 if {![string_is_empty $connected_ip] && [is_ethsupported_target $connected_ip] == "true"} {
					  return $connected_ip
				 }
			   } else {
				  dtg_warning "$ddrv_handle connected ip is NULL for the target intf $target_intf"
			   }
		      } else {
			      dtg_warning "$ddrv_handle target interface is NULL for the intf pin $intf"
		      }
		 }
	      }
	   }
	   return $target_periph
	}

	proc get_connectedip {intf} {
	   global rxethmem
	   if { [llength $intf]} {
	      set connected_ip ""
	      set intf_net [hsi::get_intf_nets -of_objects $intf ]
	      if { [llength $intf_net]  } {
		 set target_intf [get_other_intf_pin $intf_net $intf]
		 if { [llength $target_intf] } {
		    set connected_ip [hsi::get_cells -of_objects $target_intf]
		    if {[llength $connected_ip]} {
			  set target_ipname [get_property IP_NAME $connected_ip]
			  if {$target_ipname == "ila"} {
				 return
			  }
			  if {$target_ipname == "axis_data_fifo"} {
				set fifo_width_bytes [get_property CONFIG.TDATA_NUM_BYTES $connected_ip]
				if {[string_is_empty $fifo_width_bytes]} {
				      set fifo_width_bytes 1
				}
				set rxethmem [get_property CONFIG.FIFO_DEPTH $connected_ip]
				# FIFO can be other than 8 bits, and we need the rxmem in bytes
				set rxethmem [expr $rxethmem * $fifo_width_bytes]
			 } else {
				# In 10G MAC case if the rx_stream interface is not connected to
				# a Stream-fifo set the rxethmem value to a default jumbo MTU size
				set rxethmem 9600
			 }
		    } else {
			    dtg_warning "$drv_handle connected_ip is NULL for the target_intf $target_intf"
		    }
		 }
		if {[string_is_empty $connected_ip]} {
			return ""
		}
		 set target_ip [is_ethsupported_target $connected_ip]
		 if { $target_ip == "true"} {
		    return $connected_ip
		 } else {
		     set i 0
		     set retries 5
		     # When AXI Ethernet Configured in Non-Buf mode or In case of 10G MAC
		     # The Ethernet MAC won't directly got connected to fifo or dma
		     # We need to traverse through stream data fifo's and axi interconnects
		     # Inorder to find the target IP(AXI DMA or AXI FIFO)
		     while {$i < $retries} {
			set target_ip "false"
			set target_periph [get_targetip $connected_ip]
			if {[string_is_empty $target_periph] == 0} {
			    set target_ip [is_ethsupported_target $target_periph]
			}
			if { $target_ip == "true"} {
			  return $target_periph
			}
			set connected_ip $target_periph
			incr i
		     }
		     dtg_warning "Couldn't find a valid target_ip Please cross check hw design"
		 }
	      }
	   }
	}

	proc generate_reg_property {node ip_mem_handles num} {
	       if {[llength $ip_mem_handles] == 0} {
			 return
	       }
	       set base [string tolower [get_property BASE_VALUE [lindex $ip_mem_handles $num]]]
	       set high [string tolower [get_property HIGH_VALUE [lindex $ip_mem_handles $num]]]
	       set size [format 0x%x [expr {${high} - ${base} + 1}]]

	#       set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		set proctype [get_hw_family]
	#	set proctype "psv_cortexa72"
	       if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		    if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
			      set temp $base
			      set temp [string trimleft [string trimleft $temp 0] x]
			      set len [string length $temp]
			      set rem [expr {${len} - 8}]
			      set high_base "0x[string range $temp $rem $len]"
			      set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
			      set low_base [format 0x%08x $low_base]
			      if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
				       set temp $size
				       set temp [string trimleft [string trimleft $temp 0] x]
				       set len [string length $temp]
				       set rem [expr {${len} - 8}]
				       set high_size "0x[string range $temp $rem $len]"
				       set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
				       set low_size [format 0x%08x $low_size]
				       set reg "$low_base $high_base $low_size $high_size"
			      } else {
				      set reg "$low_base $high_base 0x0 $size"
			      }
		    } else {
			    set reg "0x0 $base 0x0 $size"
		    }
	       } else {
		       set reg "$base $size"
	       }
	       add_prop $node "reg" $reg hexint "pl.dtsi"
	       #add_prop $node "reg" $reg hexlist "pl.dtsi"
	#       add_new_dts_param "${node}" "reg" $reg inthexlist
	}

	proc gen_drv_prop_eth_ip {drv_handle ipname} {
		set prop_name_list [default_parameters $drv_handle]
		foreach prop_name ${prop_name_list} {
		     ip2_prop $ipname $prop_name $drv_handle
		}
	}

	proc ip2_prop {ip_name ip_prop_name drv_handle} {
		set drv_prop_name $ip_prop_name
		regsub -all {CONFIG.C_} $drv_prop_name {xlnx,} drv_prop_name
		regsub -all {_} $drv_prop_name {-} drv_prop_name
		set drv_prop_name [string tolower $drv_prop_name]
		set prop [get_property ${ip_prop_name} [hsi::get_cells -hier $drv_handle]]
		if {[llength $prop]} {
			if {$prop != "-1" && [llength $prop] !=0} {
				if {[regexp -nocase {0x([0-9a-f])} $prop match]} {
					set type "hexint"
				} elseif {[string is integer -strict $prop]} {
					set type "int"
				} elseif {[string is boolean -strict $prop]} {
					set type "boolean"
				} elseif {[string is wordchar -strict $prop]} {
					set type "string"
				} else {
					set type "mixed"
				}
				add_prop $ip_name "$drv_prop_name" $prop $type "pl.dtsi"
			}
		}
	}
}
