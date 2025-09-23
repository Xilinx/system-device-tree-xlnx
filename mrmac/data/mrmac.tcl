#
# (C) Copyright 2019-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
#
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

    proc mrmac_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        set compatible [get_comp_str $drv_handle]
        if {[string match -nocase [hsi get_property IP_NAME [hsi get_cells -hier $drv_handle]] "mrmac"]} {
              set compatible [append compatible " " "xlnx,mrmac-ethernet-1.0"]
        }

        set mrmac_ip [hsi::get_cells -hier $drv_handle]
        mrmac_gen_mrmac_clk_property $drv_handle
        set connected_ip [get_connected_stream_ip $mrmac_ip "tx_axis_tdata0"]


        global env
        set path $env(CUSTOM_SDT_REPO)
        set common_file "$path/device_tree/data/config.yaml"
        set bus_node "amba_pl"
        set dts_file [set_drv_def_dts $drv_handle]
        set mem_ranges [hsi get_mem_ranges [hsi::get_cells -hier $drv_handle]]
        dtg_verbose "mem_ranges:$mem_ranges"
            foreach mem_range $mem_ranges {
                   set base_addr [string tolower [hsi get_property BASE_VALUE $mem_range]]
                   set base [format %llx $base_addr]
                   set high_addr [string tolower [hsi get_property HIGH_VALUE $mem_range]]
                   set slave_intf [hsi get_property SLAVE_INTERFACE $mem_range]
               dtg_verbose "slave_intf:$slave_intf"
                   set ptp_comp "xlnx,timer-syncer-1588-1.0"
                   # Handle PTP timer interfaces using a for loop
                   for {set ptp_idx 0} {$ptp_idx < 4} {incr ptp_idx} {
                           if {[string match -nocase $slave_intf "ptp_${ptp_idx}_s_axi"]} {
                                   set ptp_node [create_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
                                   add_prop "$ptp_node" "compatible" "$ptp_comp" stringlist $dts_file
                                   mrmac_generate_reg_property $ptp_node $base_addr $high_addr
                           }
                   }
            }

        set mrmac_clk_names [pldt get $node zclock-names1]

        set mrmac_clks [pldt get $node zclocks1]

        set mrmac_clkname_len [expr {[llength [split $mrmac_clk_names ","]]}]

        set mrmac_clk_len [expr {[llength [split $mrmac_clks ","]]}]

        set clk_list $mrmac_clks
        set null ""
        set_drv_prop $drv_handle "zclock-names1" $null $node stringlist
        set refs ""
        set_drv_prop $drv_handle "zclocks1" "$refs" $node stringlist


        # Initialize variables
        set i 0
        set clk_types {rx_axi_clk rx_flexif_clk rx_ts_clk tx_axi_clk tx_flexif_clk tx_ts_clk}
        set s_axi_aclk ""
        set s_axi_aclk_index0 ""

        # Use arrays for storing indexed clock names and indices
        array set clk_name {}
        array set clk_index {}

        # Process each clkname in the list
        foreach clkname $mrmac_clk_names {
            set lc_clkname [string tolower $clkname]

            if {$lc_clkname eq "s_axi_aclk"} {
                 set s_axi_aclk "s_axi_aclk"
                 set s_axi_aclk_index0 $i
            } else {
                 foreach type $clk_types {
                       for {set idx 0} {$idx < 4} {incr idx} {
                            if {$lc_clkname eq "${type}${idx}"} {
                                set clk_name(${type}${idx}) $type
                                set clk_index(${type}${idx}) $i
                            }
                       }
                  }
            }

            if {$clkname ne ","} {
               incr i
            }
        }

  proc mrmac_generate_gt_gpios {drv_handle node port_num mode lanes dts_file} {
	set mrmac_ip [hsi::get_cells -hier $drv_handle]
        if {$mode eq "new"} {
            set reset_pin_name "rx_serdes_data0"
        } else {
            set reset_pin_name "gt_reset_all_in"
        }
        set gt_reset_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $mrmac_ip] $reset_pin_name]]
        dtg_verbose "gt_reset_pins:$gt_reset_pins"
        set gt_reset_per ""
        set gt_per ""
        if {[llength $gt_reset_pins]} {
                set gt_reset_periph [hsi get_cells -of_objects $gt_reset_pins]
                if {[llength $gt_reset_periph]} {
                      if {$mode eq "new"} {
                              if {[get_ip_property $gt_reset_periph IP_NAME] in {"xlslice" "ilslice"}} {
                                  set intf "Din"
                                  set in_pin [::hsi::get_pins -of_objects $gt_reset_periph -filter "NAME==$intf"]
                                  set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_reset_periph] $in_pin]]
                                  set gt_reset_per [::hsi::get_cells -of_objects $sink_pins]
                                  set ip_name [hsi::get_property IP_NAME $gt_reset_per]
                                  if {[string match -nocase $ip_name "gtwiz_versal"]} {
                                      set intf "INTF${port_num}_rst_all_in"
                                      set in_pin [::hsi::get_pins -of_objects $gt_reset_per -filter "NAME==$intf"]
                                      set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_reset_per] $in_pin]]
                                      set gt_wiz_per [::hsi::get_cells -of_objects $sink_pins]
				      if {[get_ip_property $gt_wiz_per IP_NAME] in {"xlslice" "ilslice"}} {
                                          set intf "Din"
                                          set in_pin [::hsi::get_pins -of_objects $gt_wiz_per -filter "NAME==$intf"]
                                          set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_wiz_per] $in_pin]]
                                          set gt_per [::hsi::get_cells -of_objects $sink_pins]
                                      }
                                  }
                              }
                      } elseif {$mode eq "old"} {
                              if {[get_ip_property $gt_reset_periph IP_NAME] in {"xlconcat" "ilconcat"}} {
                                   set intf "In${port_num}"
                                   set in_pin [::hsi::get_pins -of_objects $gt_reset_periph -filter "NAME==$intf"]
                                   set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_reset_periph] $in_pin]]
                                   set gt_reset_per [::hsi::get_cells -of_objects $sink_pins]
                                   if {[get_ip_property $gt_reset_per IP_NAME] in {"xlslice" "ilslice"}} {
                                        set intf "Din"
                                        set in_pin [::hsi::get_pins -of_objects $gt_reset_per -filter "NAME==$intf"]
                                        set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_reset_per] $in_pin]]
                                        set gt_per [::hsi::get_cells -of_objects $sink_pins]
                                        dtg_verbose "gt_reset_per:$gt_reset_per"
                                   }
                              }
                      }

                      if {[llength $gt_per]} {
                            set ip_name [hsi::get_property IP_NAME $gt_per]
			    if {[string match -nocase $ip_name "axi_gpio"]} {
                                   set gpio_list ""
                                   for {set i 0} {$i <= 1} {incr i} {
                                       if {$gpio_list ne ""} {
                                           append gpio_list ","
                                       }
                                       append gpio_list "<&$gt_per $i 0>"
                                   }
                                   set gpio_list [string trimleft $gpio_list "<"]
                                   set gpio_list [string trimleft $gpio_list "&"]
                                   set gpio_list [string trimright $gpio_list ">"]
                                   add_prop "$node" "gt-ctrl-rate-gpios" "$gpio_list" reference $dts_file

                                   # Add gt_rx_dpath-gpios and gt_tx_dpath-gpios
                                   add_prop "$node" "gt-rx-dpath-gpios" "$gt_per 33 0" reference $dts_file
                                   add_prop "$node" "gt-tx-dpath-gpios" "$gt_per 34 0" reference $dts_file
				   set is_board_project [hsi get_property CONFIG.IS_BOARD_PROJECT [hsi::get_cells -hier $drv_handle]]
                                   set gt_connect [get_connected_stream_ip [hsi::get_cells -hier $gt_per] "S_AXI"]
                                   if {$mode eq "old"} {
                                       set gpio_list ""
                                       for {set i 0} {$i < $lanes} {incr i} {
                                          if {$gpio_list ne ""} {
                                             append gpio_list ","
                                          }
                                          set j [expr $i + 1]
					  if {$lanes <= 2} {
					       if {$is_board_project == 1} {
                                                  set axi_interface "M0${i}_AXI"
					       } else {
						  set axi_interface "M0${j}_AXI"
					       }
					  } else {
                                               set axi_interface "M0${j}_AXI"
					  }
                                          set gt_rate_reset [get_connected_stream_ip [hsi::get_cells -hier $gt_connect] "$axi_interface"]
                                          append gpio_list "<&$gt_rate_reset 32 0>"
                                       }
                                       set gpio_list [string trimleft $gpio_list "<"]
                                       set gpio_list [string trimleft $gpio_list "&"]
                                       set gpio_list [string trimright $gpio_list ">"]
                                       add_prop "$node" "gt-ctrl-gpios" "$gpio_list" reference $dts_file
                                   } elseif {$mode eq "new"} {
                                       add_prop "$node" "gt-ctrl-gpios" "$gt_per 32 0" reference $dts_file
                                   }

				   if {$lanes <= 2} {
					 if {$is_board_project == 1} {
				             set axi_reset_interface "M0${lanes}_AXI"
				         } else {
				             set axi_reset_interface "M00_AXI"
					 }
				   } else {
                                         set axi_reset_interface "M00_AXI"
                                   }
                                   set gt_reset_mask [get_connected_stream_ip [hsi::get_cells -hier $gt_connect] "$axi_reset_interface"]
                                   if {[llength $gt_reset_mask]} {
                                      if {$mode eq "old"} {
                                          set gpio_list1 ""
                                          set gpio_list2 ""
                                          for {set i 0} {$i < $lanes} {incr i} {
                                              set j [expr $i + 32]
                                              if {$gpio_list1 ne ""} {
                                                 append gpio_list1 ","
                                              }
                                              if {$gpio_list2 ne ""} {
                                                 append gpio_list2 ","
                                              }
                                              append gpio_list1 "<&$gt_reset_mask $j 0>"
                                              set k [expr $j + 4]
                                              append gpio_list2 "<&$gt_reset_mask $k 0>"
                                          }
                                          set gpio_list1 [string trimleft $gpio_list1 "<"]
                                          set gpio_list1 [string trimleft $gpio_list1 "&"]
                                          set gpio_list1 [string trimright $gpio_list1 ">"]
                                          set gpio_list2 [string trimleft $gpio_list2 "<"]
                                          set gpio_list2 [string trimleft $gpio_list2 "&"]
                                          set gpio_list2 [string trimright $gpio_list2 ">"]

                                          # Add gt_rx_rst_done-gpios and gt_tx_rst_done-gpios
                                          add_prop "$node" "gt-rx-rst-done-gpios" "$gpio_list1" reference $dts_file
                                          add_prop "$node" "gt-tx-rst-done-gpios" "$gpio_list2" reference $dts_file
                                      } elseif {$mode eq "new"} {
                                          set i [expr $port_num + 32]
                                          set j [expr $port_num + 36]
                                          add_prop "$node" "gt-rx-rst-done-gpios" "$gt_reset_mask $i 0" reference $dts_file
                                          add_prop "$node" "gt-tx-rst-done-gpios" "$gt_reset_mask $j 0" reference $dts_file
                                      }
			           }
                            }
                      }
                }
        }
  }
        # Add properties for all 4 MRMAC ports using a clean dynamic for loop
        # This completely replaces all the duplicated property assignments and node creation

        set MAC_PORT_RATE_C0 [hsi get_property CONFIG.MAC_PORT0_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $MAC_PORT_RATE_C0 "100GE"]} {
             set num_channels 1
        } else {
             set num_channels [hsi get_property CONFIG.C_NUM_GT_CHANNELS [hsi::get_cells -hier $drv_handle]]
        }
        for {set port_index 0} {$port_index < $num_channels} {incr port_index} {
            if {$port_index == 0} {
                # PORT0 uses the main node
                set current_port_node $node
                set phc_index 0
                set gt_lane 0
            } else {
                set bus_node "amba_pl: amba_pl"
                set port_label "$drv_handle"
                append port_label "_" $port_index
                set port_base [format 0x%llx [expr $base_addr + ($port_index * 0x1000)]]
                set port_base_hex [format %llx $port_base]
                set port_highaddr_hex [format 0x%llx [expr $port_base + 0xFFF]]
                set current_port_node [create_node -n "mrmac" -l "$port_label" -u $port_base_hex -d $dts_file -p $bus_node]
                set phc_index $port_index
                set gt_lane $port_index
            }

            add_prop "$current_port_node" "compatible" "$compatible" stringlist $dts_file 1
            # Create nodes dynamically for PORT1, PORT2, PORT3
            set port_base [format 0x%llx [expr $base_addr + ($port_index * 0x1000)]]
            set port_base_hex [format %llx $port_base]
            set port_highaddr_hex [format 0x%llx [expr $port_base + 0xFFF]]
            add_prop "$current_port_node" "compatible" "$compatible" stringlist $dts_file 1
            if {[string match -nocase $slave_intf "s_axi"] && ($port_index == 0)} {
                    mrmac_generate_reg_property $current_port_node $port_base $port_highaddr_hex
            } else {
                    mrmac_generate_reg_property $current_port_node $port_base $port_highaddr_hex
            }

            set gt_mode [hsi get_property CONFIG.GT_MODE_C0 [hsi::get_cells -hier $drv_handle]]
            set gt_mode [split $gt_mode " "]
            set gt_mode [lindex $gt_mode 0]
            add_prop "${current_port_node}" "xlnx,gt-mode" $gt_mode string $dts_file

            set port_dpath [hsi get_property CONFIG.MRMAC_DATA_PATH_INTERFACE_PORT${port_index}_C0  [hsi::get_cells -hier $drv_handle]]
            set port_dpath [split $port_dpath " "]
            set port_dwidth [lindex $port_dpath 1]
            set port_dwidth [string trimright $port_dwidth "b"]
            add_prop "${current_port_node}" "xlnx,axistream-dwidth" $port_dwidth int $dts_file

	    set gt_old_pin [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $mrmac_ip] "gt_reset_all_in"]]
	    set gt_new_pin [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $mrmac_ip] "rx_serdes_data0"]]

            if {[llength $gt_old_pin]} {
		 set mode "old"
            } elseif {[llength $gt_new_pin]} {
		 set mode "new"
            } else {
                 dtg_warning "No GPIO Path detected...please check the design..."
            }

	    mrmac_generate_gt_gpios $drv_handle $current_port_node $port_index $mode $num_channels $dts_file
	    # Call the helper function to add all MRMAC properties
            mrmac_add_port_properties $drv_handle $current_port_node $port_index $dts_file


            set clknames [list $s_axi_aclk]
            set clkvals []

            # Clean and append s_axi_aclk
            set s_axi_val [lindex $clk_list $s_axi_aclk_index0]
            regsub -all "," $s_axi_val "" s_axi_val
            lappend clkvals $s_axi_val

            # Loop for other clock types
            foreach type $clk_types {
                set clk_key "${type}${port_index}"
                if {
                   [info exists clk_name($clk_key)] &&
                   [info exists clk_index($clk_key)]
                } then {
                   lappend clknames $clk_name($clk_key)

                   set clkval [lindex $clk_list $clk_index($clk_key)]
                   regsub -all "," $clkval "" clkval
                   lappend clkvals $clkval
                }
            }

            # Build comma-separated string from cleaned list
            set clkvals_str [join $clkvals ", "]

            add_prop "${current_port_node}" "clocks" $clkvals_str noformating $dts_file
            add_prop "${current_port_node}" "clock-names" $clknames stringlist $dts_file

            set rx_index [expr {$port_index * 2}]
            set rx_axis_tdata "rx_axis_tdata$rx_index"
            set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] $rx_axis_tdata]]
            dtg_verbose "port_pins:$port_pins"
            foreach pin $port_pins {
                    set sink_periph [hsi::get_cells -of_objects $pin]
                    set mux_ip ""
                    set fifo_ip ""
                    if {[llength $sink_periph]} {
                            mrmac_connect_axistream $drv_handle $current_port_node $sink_periph $dts_file
                    }
            }

            set tx_ptp_tstamp_tag_out "tx_ptp_tstamp_tag_out_${port_index}"
            set txtodport_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] $tx_ptp_tstamp_tag_out]]
            dtg_verbose "txtodport_pins:$txtodport_pins"
            if {[llength $txtodport_pins]} {
              set tod_sink_periph [hsi::get_cells -of_objects $txtodport_pins]
                  if {[llength $tod_sink_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $tod_sink_periph] "mrmac_ptp_timestamp_if"]} {
                                   set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $tod_sink_periph] "tx_timestamp_tod"]]
                                   set tod_sink_periph [::hsi::get_cells -of_objects $port_pins]
                           }

                           if {[get_ip_property $tod_sink_periph IP_NAME] in {"xlconcat" "ilconcat"}} {
                               set intf "dout"
                               set in_pin [hsi::get_pins -of_objects $tod_sink_periph -filter "NAME==$intf"]
                               set insink_pins [get_sink_pins $in_pin]
                               set xl_per [hsi::get_cells -of_objects $insink_pins]
                               if {[string match -nocase [hsi get_property IP_NAME $xl_per] "axis_dwidth_converter"]} {
                                     set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $xl_per] "m_axis_tdata"]]
                                     set axis_per [hsi::get_cells -of_objects $port_pins]
                                     if {[string match -nocase [hsi get_property IP_NAME $axis_per] "axis_clock_converter"]} {
                                            set tx_ip [get_connected_stream_ip [hsi::get_cells -hier $axis_per] "M_AXIS"]
                                            if {[llength $tx_ip]} {
                                            add_prop "$current_port_node" "axififo-connected" $tx_ip reference $dts_file
                                            }
                                     }
                               }
                           }
                  }
           } else {
                dtg_warning "tx_timestamp_tod_${port_index} connected pins are NULL...please check the design..."
           }
           set rx_ptp_tstamp_out rx_ptp_tstamp_out_${port_index}
           set rxtod_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] $rx_ptp_tstamp_out]]
           dtg_verbose "rxtod_pins:$rxtod_pins"
           if {[llength $rxtod_pins]} {
               set rx_periph [hsi::get_cells -of_objects $rxtod_pins]
               if {[llength $rx_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $rx_periph] "mrmac_ptp_timestamp_if"]} {
                                   set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rx_periph] "rx_timestamp_tod"]]
                                   set rx_periph [::hsi::get_cells -of_objects $port_pins]
                           }
                           if {[get_ip_property $rx_periph IP_NAME] in {"xlconcat" "ilconcat"}} {
                                 set intf "dout"
                                 set inrx_pin [hsi::get_pins -of_objects $rx_periph -filter "NAME==$intf"]
                                 set rxtodsink_pins [get_sink_pins $inrx_pin]
                                 set rx_per [hsi::get_cells -of_objects $rxtodsink_pins]
                                 if {[string match -nocase [hsi get_property IP_NAME $rx_per] "axis_dwidth_converter"]} {
                                      set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rx_per] "m_axis_tdata"]]
                                      set rx_axis_per [hsi::get_cells -of_objects $port_pins]
                                      if {[string match -nocase [hsi get_property IP_NAME $rx_axis_per] "axis_clock_converter"]} {
                                           set rx_ip [get_connected_stream_ip [hsi::get_cells -hier $rx_axis_per] "M_AXIS"]
                                           if {[llength $rx_ip]} {
                                               add_prop "$current_port_node" "xlnx,rxtsfifo" $rx_ip reference $dts_file
                                           }
                                      }
                                 }
                           }
               }
           } else {
                dtg_warning "rx_timestamp_tod_${port_index} connected pins are NULL...please check the design..."
           }

           add_prop "$current_port_node" "xlnx,phcindex" $port_index int $dts_file
           add_prop "$current_port_node" "xlnx,gtlane" $port_index int $dts_file
           lappend mrmac_list "$current_port_node"
        }

	set mcdma_ips [hsi::get_cells -hier -filter {IP_NAME == axi_mcdma}]
	set len [llength $mcdma_ips]

        set eoe_tcl_file "$path/axi_eoe/data/axi_eoe.tcl"
        if {[file exists $eoe_tcl_file]} {
            source $eoe_tcl_file
            set eoe_ips [hsi::get_cells -hier -filter {IP_NAME == ethernet_offload}]
            if {[llength $eoe_ips]} {
                foreach eoe_ip $eoe_ips {
                        regexp {^.*_.*_.*_.*_.*_(\d+)_.*$} $eoe_ip match digit
                        for {set i 0} {$i < $len} {incr i} {
                             set mcdma_node [lindex $mcdma_ips $i]
                             set eth_dma [hsi get_property CONFIG.C_ETHERNET_DMA $mcdma_node]
                             if {[string compare -nocase $digit $i] == 0} {
                                 if {[string compare -nocase $eth_dma 1] == 0} {
	                             set mrmac_node [lindex $mrmac_list $i]
                                     axi_eoe_generate $eoe_ip $mrmac_node  $dts_file
                                 } else {
                                     error "ERROR: Ethernet Offload is not Supported"
                                 }
                             }
                        }
                }
            }
        }
     }


    proc mrmac_add_port_properties {drv_handle node port_num dts_file} {
        # Add all the port-specific properties

        # FEC and FLEX properties
        set FEC_SLICE_CFG_C0 [hsi get_property CONFIG.C_FEC_SLICE${port_num}_CFG_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-slice${port_num}-cfg-c0" $FEC_SLICE_CFG_C0 string $dts_file
        set FEC_SLICE_CFG_C1 [hsi get_property CONFIG.C_FEC_SLICE${port_num}_CFG_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-slice${port_num}-cfg-c1" $FEC_SLICE_CFG_C1 string $dts_file

        set FLEX_PORT_DATA_RATE_C0 [hsi get_property CONFIG.C_FLEX_PORT${port_num}_DATA_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port${port_num}-data-rate-c0" $FLEX_PORT_DATA_RATE_C0 string $dts_file
        set FLEX_PORT_DATA_RATE_C1 [hsi get_property CONFIG.C_FLEX_PORT${port_num}_DATA_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port${port_num}-data-rate-c1" $FLEX_PORT_DATA_RATE_C1 string $dts_file

        set FLEX_PORT_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.C_FLEX_PORT${port_num}_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port${port_num}-enable-time-stamping-c0" $FLEX_PORT_ENABLE_TIME_STAMPING_C0 int $dts_file
        set FLEX_PORT_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.C_FLEX_PORT${port_num}_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port${port_num}-enable-time-stamping-c1" $FLEX_PORT_ENABLE_TIME_STAMPING_C1 int $dts_file

        set FLEX_PORT_MODE_C0 [hsi get_property CONFIG.C_FLEX_PORT${port_num}_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port${port_num}-mode-c0" $FLEX_PORT_MODE_C0 string $dts_file
        set FLEX_PORT_MODE_C1 [hsi get_property CONFIG.C_FLEX_PORT${port_num}_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port${port_num}-mode-c1" $FLEX_PORT_MODE_C1 string $dts_file

        # PORT 1588v2 properties
        set PORT_1588v2_Clocking_C0 [hsi get_property CONFIG.PORT${port_num}_1588v2_Clocking_C0 [hsi::get_cells -hier $drv_handle]]
        set PORT_1588v2_Clocking_C1 [hsi get_property CONFIG.PORT${port_num}_1588v2_Clocking_C1 [hsi::get_cells -hier $drv_handle]]

        set PORT_1588v2_Operation_MODE_C0 [hsi get_property CONFIG.PORT${port_num}_1588v2_Operation_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        set PORT_1588v2_Operation_MODE_C1 [hsi get_property CONFIG.PORT${port_num}_1588v2_Operation_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        if {$port_num == 0} {
                add_prop "${node}" "xlnx,port${port_num}-1588v2-clocking-c0" $PORT_1588v2_Clocking_C0 noformating $dts_file
                add_prop "${node}" "xlnx,port${port_num}-1588v2-clocking-c1" $PORT_1588v2_Clocking_C1 noformating $dts_file
                add_prop "${node}" "xlnx,port${port_num}-1588v2-operation-mode-c0" $PORT_1588v2_Operation_MODE_C0 noformating $dts_file
                add_prop "${node}" "xlnx,port${port_num}-1588v2-operation-mode-c1" $PORT_1588v2_Operation_MODE_C1 noformating $dts_file
	} else {
                add_prop "${node}" "xlnx,port${port_num}-1588v2-clocking-c0" $PORT_1588v2_Clocking_C0 string $dts_file
                add_prop "${node}" "xlnx,port${port_num}-1588v2-clocking-c1" $PORT_1588v2_Clocking_C1 string $dts_file
                add_prop "${node}" "xlnx,port${port_num}-1588v2-operation-mode-c0" $PORT_1588v2_Operation_MODE_C0 string $dts_file
                add_prop "${node}" "xlnx,port${port_num}-1588v2-operation-mode-c1" $PORT_1588v2_Operation_MODE_C1 string $dts_file
	}
        # MAC PORT properties
        set MAC_PORT_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-enable-time-stamping-c0" $MAC_PORT_ENABLE_TIME_STAMPING_C0 int $dts_file
        set MAC_PORT_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-enable-time-stamping-c1" $MAC_PORT_ENABLE_TIME_STAMPING_C1 int $dts_file

        set MAC_PORT_RATE_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $MAC_PORT_RATE_C0 "10GE"]} {
            set number 10000
            add_prop "${node}" "max-speed" $number int $dts_file
        } elseif {[string match -nocase $MAC_PORT_RATE_C0 "25GE"]} {
            set number 25000
            add_prop "${node}" "max-speed" $number int $dts_file
        } elseif {[string match -nocase $MAC_PORT_RATE_C0 "100GE"]} {
            set number 100000
            add_prop "${node}" "max-speed" $number int $dts_file
        }
        add_prop "${node}" "xlnx,mac-port${port_num}-rate-c0" $MAC_PORT_RATE_C0 string $dts_file
        set MAC_PORT_RATE_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rate-c1" $MAC_PORT_RATE_C1 string $dts_file

        # RX ETYPE properties
        set MAC_PORT_RX_ETYPE_GCP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-gcp-c0" $MAC_PORT_RX_ETYPE_GCP_C0 int $dts_file
        set MAC_PORT_RX_ETYPE_GCP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-gcp-c1" $MAC_PORT_RX_ETYPE_GCP_C1 int $dts_file
        set MAC_PORT_RX_ETYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-gpp-c0" $MAC_PORT_RX_ETYPE_GPP_C0 int $dts_file
        set MAC_PORT_RX_ETYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-gpp-c1" $MAC_PORT_RX_ETYPE_GPP_C1 int $dts_file
        set MAC_PORT_RX_ETYPE_PCP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-pcp-c0" $MAC_PORT_RX_ETYPE_PCP_C0 int $dts_file
        set MAC_PORT_RX_ETYPE_PCP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-pcp-c1" $MAC_PORT_RX_ETYPE_PCP_C1 int $dts_file
        set MAC_PORT_RX_ETYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-ppp-c0" $MAC_PORT_RX_ETYPE_PPP_C0 int $dts_file
        set MAC_PORT_RX_ETYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_ETYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-etype-ppp-c1" $MAC_PORT_RX_ETYPE_PPP_C1 int $dts_file

        # RX FLOW properties
        set MAC_PORT_RX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-flow-c0" $MAC_PORT_RX_FLOW_C0 int $dts_file
        set MAC_PORT_RX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-flow-c1" $MAC_PORT_RX_FLOW_C1 int $dts_file

        # RX OPCODE properties
        set MAC_PORT_RX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-gpp-c0" $MAC_PORT_RX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT_RX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-gpp-c1" $MAC_PORT_RX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT_RX_OPCODE_MAX_GCP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MAX_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-max-gcp-c0" $MAC_PORT_RX_OPCODE_MAX_GCP_C0 int $dts_file
        set MAC_PORT_RX_OPCODE_MAX_GCP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MAX_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-max-gcp-c1" $MAC_PORT_RX_OPCODE_MAX_GCP_C1 int $dts_file
        set MAC_PORT_RX_OPCODE_MAX_PCP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MAX_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-max-pcp-c0" $MAC_PORT_RX_OPCODE_MAX_PCP_C0 int $dts_file
        set MAC_PORT_RX_OPCODE_MAX_PCP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MAX_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-max-pcp-c1" $MAC_PORT_RX_OPCODE_MAX_PCP_C1 int $dts_file
        set MAC_PORT_RX_OPCODE_MIN_GCP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MIN_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-min-gcp-c0" $MAC_PORT_RX_OPCODE_MIN_GCP_C0 int $dts_file
        set MAC_PORT_RX_OPCODE_MIN_GCP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MIN_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-min-gcp-c1" $MAC_PORT_RX_OPCODE_MIN_GCP_C1 int $dts_file
        set MAC_PORT_RX_OPCODE_MIN_PCP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MIN_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-min-pcp-c0" $MAC_PORT_RX_OPCODE_MIN_PCP_C0 int $dts_file
        set MAC_PORT_RX_OPCODE_MIN_PCP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_MIN_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-min-pcp-c1" $MAC_PORT_RX_OPCODE_MIN_PCP_C1 int $dts_file
        set MAC_PORT_RX_OPCODE_PPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-ppp-c0" $MAC_PORT_RX_OPCODE_PPP_C0 int $dts_file
        set MAC_PORT_RX_OPCODE_PPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_OPCODE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-rx-opcode-ppp-c1" $MAC_PORT_RX_OPCODE_PPP_C1 int $dts_file

        # RX PAUSE properties (with mrmac_check_size)
        set MAC_PORT_RX_PAUSE_DA_MCAST_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_PAUSE_DA_MCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_RX_PAUSE_DA_MCAST_C0 [mrmac_check_size $MAC_PORT_RX_PAUSE_DA_MCAST_C0 $node]
        set MAC_PORT_RX_PAUSE_DA_MCAST_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_PAUSE_DA_MCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_RX_PAUSE_DA_MCAST_C1 [mrmac_check_size $MAC_PORT_RX_PAUSE_DA_MCAST_C1 $node]
        set MAC_PORT_RX_PAUSE_DA_UCAST_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_PAUSE_DA_UCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_RX_PAUSE_DA_UCAST_C0 [mrmac_check_size $MAC_PORT_RX_PAUSE_DA_UCAST_C0 $node]
        set MAC_PORT_RX_PAUSE_DA_UCAST_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_PAUSE_DA_UCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_RX_PAUSE_DA_UCAST_C1 [mrmac_check_size $MAC_PORT_RX_PAUSE_DA_UCAST_C1 $node]
        set MAC_PORT_RX_PAUSE_SA_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_PAUSE_SA_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_RX_PAUSE_SA_C0 [mrmac_check_size $MAC_PORT_RX_PAUSE_SA_C0 $node]
        set MAC_PORT_RX_PAUSE_SA_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_RX_PAUSE_SA_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_RX_PAUSE_SA_C1 [mrmac_check_size $MAC_PORT_RX_PAUSE_SA_C1 $node]
	if {$port_num == 0} {
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-mcast-c0" $MAC_PORT_RX_PAUSE_DA_MCAST_C0 noformating $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-mcast-c1" $MAC_PORT_RX_PAUSE_DA_MCAST_C1 noformating $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-ucast-c0" $MAC_PORT_RX_PAUSE_DA_UCAST_C0 noformating $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-ucast-c1" $MAC_PORT_RX_PAUSE_DA_UCAST_C1 noformating $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-sa-c0" $MAC_PORT_RX_PAUSE_SA_C0 noformating $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-sa-c1" $MAC_PORT_RX_PAUSE_SA_C1 noformating $dts_file
	} else {
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-mcast-c0" $MAC_PORT_RX_PAUSE_DA_MCAST_C0 int $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-mcast-c1" $MAC_PORT_RX_PAUSE_DA_MCAST_C1 int $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-ucast-c0" $MAC_PORT_RX_PAUSE_DA_UCAST_C0 int $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-da-ucast-c1" $MAC_PORT_RX_PAUSE_DA_UCAST_C1 int $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-sa-c0" $MAC_PORT_RX_PAUSE_SA_C0 int $dts_file
             add_prop "${node}" "xlnx,mac-port${port_num}-rx-pause-sa-c1" $MAC_PORT_RX_PAUSE_SA_C1 int $dts_file
	}

        # TX DA properties (with mrmac_check_size)
        set MAC_PORT_TX_DA_GPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_DA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_DA_GPP_C0 [mrmac_check_size $MAC_PORT_TX_DA_GPP_C0 $node]
        set MAC_PORT_TX_DA_GPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_DA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_DA_GPP_C1 [mrmac_check_size $MAC_PORT_TX_DA_GPP_C1 $node]
        set MAC_PORT_TX_DA_PPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_DA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_DA_PPP_C0 [mrmac_check_size $MAC_PORT_TX_DA_PPP_C0 $node]
        set MAC_PORT_TX_DA_PPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_DA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_DA_PPP_C1 [mrmac_check_size $MAC_PORT_TX_DA_PPP_C1 $node]
	if {$port_num == 0} {
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-gpp-c0" $MAC_PORT_TX_DA_GPP_C0 noformating $dts_file
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-gpp-c1" $MAC_PORT_TX_DA_GPP_C1 noformating $dts_file
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-ppp-c0" $MAC_PORT_TX_DA_PPP_C0 noformating $dts_file
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-ppp-c1" $MAC_PORT_TX_DA_PPP_C1 noformating $dts_file
	} else {
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-gpp-c0" $MAC_PORT_TX_DA_GPP_C0 int $dts_file
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-gpp-c1" $MAC_PORT_TX_DA_GPP_C1 int $dts_file
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-ppp-c0" $MAC_PORT_TX_DA_PPP_C0 int $dts_file
              add_prop "${node}" "xlnx,mac-port${port_num}-tx-da-ppp-c1" $MAC_PORT_TX_DA_PPP_C1 int $dts_file
	}


        # TX ETHERTYPE properties
        set MAC_PORT_TX_ETHERTYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_ETHERTYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-ethertype-gpp-c0" $MAC_PORT_TX_ETHERTYPE_GPP_C0 int $dts_file
        set MAC_PORT_TX_ETHERTYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_ETHERTYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-ethertype-gpp-c1" $MAC_PORT_TX_ETHERTYPE_GPP_C1 int $dts_file
        set MAC_PORT_TX_ETHERTYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_ETHERTYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-ethertype-ppp-c0" $MAC_PORT_TX_ETHERTYPE_PPP_C0 int $dts_file
        set MAC_PORT_TX_ETHERTYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_ETHERTYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-ethertype-ppp-c1" $MAC_PORT_TX_ETHERTYPE_PPP_C1 int $dts_file

        # TX FLOW properties
        set MAC_PORT_TX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-flow-c0" $MAC_PORT_TX_FLOW_C0 int $dts_file
        set MAC_PORT_TX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-flow-c1" $MAC_PORT_TX_FLOW_C1 int $dts_file

        # TX OPCODE properties
        set MAC_PORT_TX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-opcode-gpp-c0" $MAC_PORT_TX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT_TX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port${port_num}-tx-opcode-gpp-c1" $MAC_PORT_TX_OPCODE_GPP_C1 int $dts_file

        # TX SA properties (with mrmac_check_size)
        set MAC_PORT_TX_SA_GPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_SA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_SA_GPP_C0 [mrmac_check_size $MAC_PORT_TX_SA_GPP_C0 $node]
        set MAC_PORT_TX_SA_GPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_SA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_SA_GPP_C1 [mrmac_check_size $MAC_PORT_TX_SA_GPP_C1 $node]
        set MAC_PORT_TX_SA_PPP_C0 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_SA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_SA_PPP_C0 [mrmac_check_size $MAC_PORT_TX_SA_PPP_C0 $node]
        set MAC_PORT_TX_SA_PPP_C1 [hsi get_property CONFIG.MAC_PORT${port_num}_TX_SA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT_TX_SA_PPP_C1 [mrmac_check_size $MAC_PORT_TX_SA_PPP_C1 $node]
	if {$port_num == 0} {
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-gpp-c0" $MAC_PORT_TX_SA_GPP_C0 noformating $dts_file
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-gpp-c1" $MAC_PORT_TX_SA_GPP_C1 noformating $dts_file
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-ppp-c0" $MAC_PORT_TX_SA_PPP_C0 noformating $dts_file
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-ppp-c1" $MAC_PORT_TX_SA_PPP_C1 noformating $dts_file
	} else {
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-gpp-c0" $MAC_PORT_TX_SA_GPP_C0 int $dts_file
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-gpp-c1" $MAC_PORT_TX_SA_GPP_C1 int $dts_file
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-ppp-c0" $MAC_PORT_TX_SA_PPP_C0 int $dts_file
                add_prop "${node}" "xlnx,mac-port${port_num}-tx-sa-ppp-c1" $MAC_PORT_TX_SA_PPP_C1 int $dts_file
	}

        # GT Channel properties
        set GT_CH_RXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH${port_num}_RXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-enable-c0" $GT_CH_RXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH_RXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH${port_num}_RXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-enable-c1" $GT_CH_RXPROGDIV_FREQ_ENABLE_C1 string $dts_file
        set GT_CH_RXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH${port_num}_RXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-source-c0" $GT_CH_RXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH_RXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH${port_num}_RXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-source-c1" $GT_CH_RXPROGDIV_FREQ_SOURCE_C1 string $dts_file
        set GT_CH_RXPROGDIV_FREQ_VAL_C0 [hsi get_property CONFIG.GT_CH${port_num}_RXPROGDIV_FREQ_VAL_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_RXPROGDIV_FREQ_VAL_C1 [hsi get_property CONFIG.GT_CH${port_num}_RXPROGDIV_FREQ_VAL_C1 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_RX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH${port_num}_RX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-buffer-mode-c0" $GT_CH_RX_BUFFER_MODE_C0 int $dts_file
        set GT_CH_RX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH${port_num}_RX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-buffer-mode-c1" $GT_CH_RX_BUFFER_MODE_C1 int $dts_file
        set GT_CH_RX_DATA_DECODING_C0 [hsi get_property CONFIG.GT_CH${port_num}_RX_DATA_DECODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-data-decoding-c0" $GT_CH_RX_DATA_DECODING_C0 string $dts_file
        set GT_CH_RX_DATA_DECODING_C1 [hsi get_property CONFIG.GT_CH${port_num}_RX_DATA_DECODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-data-decoding-c1" $GT_CH_RX_DATA_DECODING_C1 string $dts_file
        set GT_CH_RX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH${port_num}_RX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-int-data-width-c0" $GT_CH_RX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH_RX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH${port_num}_RX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-int-data-width-c1" $GT_CH_RX_INT_DATA_WIDTH_C1 int $dts_file
        set GT_CH_RX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH${port_num}_RX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_RX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH${port_num}_RX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_RX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH${port_num}_RX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-outclk-source-c0" $GT_CH_RX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH_RX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH${port_num}_RX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-rx-outclk-source-c1" $GT_CH_RX_OUTCLK_SOURCE_C1 string $dts_file
        set GT_CH_RX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH${port_num}_RX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_RX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH${port_num}_RX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_RX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH${port_num}_RX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_RX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH${port_num}_RX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
	if {$port_num == 0} {
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-val-c0" $GT_CH_RXPROGDIV_FREQ_VAL_C0 noformating $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-val-c1" $GT_CH_RXPROGDIV_FREQ_VAL_C1 noformating $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-line-rate-c0" $GT_CH_RX_LINE_RATE_C0 noformating $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-line-rate-c1" $GT_CH_RX_LINE_RATE_C1 noformating $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-user-data-width-c0" $GT_CH_RX_USER_DATA_WIDTH_C0 int $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-user-data-width-c1" $GT_CH_RX_USER_DATA_WIDTH_C1 int $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-refclk-frequency-c0" $GT_CH_RX_REFCLK_FREQUENCY_C0 noformating $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-refclk-frequency-c1" $GT_CH_RX_REFCLK_FREQUENCY_C1 noformating $dts_file
	} else {
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-val-c0" $GT_CH_RXPROGDIV_FREQ_VAL_C0 string $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rxprogdiv-freq-val-c1" $GT_CH_RXPROGDIV_FREQ_VAL_C1 string $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-line-rate-c0" $GT_CH_RX_LINE_RATE_C0 string $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-line-rate-c1" $GT_CH_RX_LINE_RATE_C1 string $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-user-data-width-c0" $GT_CH_RX_USER_DATA_WIDTH_C0 string $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-user-data-width-c1" $GT_CH_RX_USER_DATA_WIDTH_C1 string $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-refclk-frequency-c0" $GT_CH_RX_REFCLK_FREQUENCY_C0 string $dts_file
                   add_prop "${node}" "xlnx,gt-ch${port_num}-rx-refclk-frequency-c1" $GT_CH_RX_REFCLK_FREQUENCY_C1 string $dts_file
	}

        # GT TX properties
        set GT_CH_TXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH${port_num}_TXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-txprogdiv-freq-enable-c0" $GT_CH_TXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH_TXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH${port_num}_TXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-txprogdiv-freq-enable-c1" $GT_CH_TXPROGDIV_FREQ_ENABLE_C1 string $dts_file
        set GT_CH_TXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH${port_num}_TXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-txprogdiv-freq-source-c0" $GT_CH_TXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH_TXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH${port_num}_TXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-txprogdiv-freq-source-c1" $GT_CH_TXPROGDIV_FREQ_SOURCE_C1 string $dts_file
        set GT_CH_TXPROGDIV_FREQ_VAL_C0 [hsi get_property CONFIG.GT_CH${port_num}_TXPROGDIV_FREQ_VAL_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TXPROGDIV_FREQ_VAL_C1 [hsi get_property CONFIG.GT_CH${port_num}_TXPROGDIV_FREQ_VAL_C1 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-buffer-mode-c0" $GT_CH_TX_BUFFER_MODE_C0 int $dts_file
        set GT_CH_TX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-buffer-mode-c1" $GT_CH_TX_BUFFER_MODE_C1 int $dts_file
        set GT_CH_TX_DATA_ENCODING_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_DATA_ENCODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-data-encoding-c0" $GT_CH_TX_DATA_ENCODING_C0 string $dts_file
        set GT_CH_TX_DATA_ENCODING_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_DATA_ENCODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-data-encoding-c1" $GT_CH_TX_DATA_ENCODING_C1 string $dts_file
        set GT_CH_TX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-outclk-source-c0" $GT_CH_TX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH_TX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-outclk-source-c1" $GT_CH_TX_OUTCLK_SOURCE_C1 string $dts_file
        set GT_CH_TX_PLL_TYPE_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_PLL_TYPE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-pll-type-c0" $GT_CH_TX_PLL_TYPE_C0 string $dts_file
        set GT_CH_TX_PLL_TYPE_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_PLL_TYPE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch${port_num}-tx-pll-type-c1" $GT_CH_TX_PLL_TYPE_C1 string $dts_file
        set GT_CH_TX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH${port_num}_TX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        set GT_CH_TX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH${port_num}_TX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
	if {$port_num == 1 } {
                 add_prop "${node}" "xlnx,gt-ch${port_num}-txprogdiv-freq-val-c0" $GT_CH_TXPROGDIV_FREQ_VAL_C0 string $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-txprogdiv-freq-val-c1" $GT_CH_TXPROGDIV_FREQ_VAL_C1 string $dts_file
	}
	if {$port_num != 0} {
                 add_prop "${node}" "xlnx,gt-ch${port_num}-tx-refclk-frequency-c0" $GT_CH_TX_REFCLK_FREQUENCY_C0 string $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-tx-refclk-frequency-c1" $GT_CH_TX_REFCLK_FREQUENCY_C1 string $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-tx-user-data-width-c0" $GT_CH_TX_USER_DATA_WIDTH_C0 int $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-tx-user-data-width-c1" $GT_CH_TX_USER_DATA_WIDTH_C1 int $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-tx-line-rate-c0" $GT_CH_TX_LINE_RATE_C0 string $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-tx-line-rate-c1" $GT_CH_TX_LINE_RATE_C1 string $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-int-data-width-c0" $GT_CH_TX_INT_DATA_WIDTH_C0 int $dts_file
                 add_prop "${node}" "xlnx,gt-ch${port_num}-int-data-width-c1" $GT_CH_TX_INT_DATA_WIDTH_C1 int $dts_file
	}
    }

    proc mrmac_get_axistream_info {drv_handle node fifo_ip dts_file} {

         add_prop "$node" "axistream-connected" "$fifo_ip" reference $dts_file "pl.dtsi"
         set num_queues [hsi get_property CONFIG.c_num_mm2s_channels $fifo_ip]
         set inhex [format %x $num_queues]
         append numqueues "/bits/ 16 <0x$inhex>"
         add_prop $node "xlnx,num-queues" $numqueues noformating $dts_file
         set id 1
         for {set i 2} {$i <= $num_queues} {incr i} {
              set i [format "%x" $i]
              append id "\""
              append id " ,\"" $i
              set i [expr 0x$i]
         }
         if {$id == 1} {
             add_prop $node "xlnx,channel-ids" $id stringlist $dts_file
         } else {
             add_prop $node "xlnx,channel-ids" $id intlist $dts_file
         }
         mrmac_generate_intr_info  $drv_handle $node $fifo_ip
    }

    proc mrmac_connect_axistream {drv_handle node sink_periph dts_file} {

         if {[get_ip_property $sink_periph IP_NAME] in {"xlconcat" "ilconcat"}} {
                set fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "dout"]]
                set sink_periph [hsi::get_cells -of_objects $fifo_pin]
         }

         if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "axis_register_slice"]} {
                set sink_periph [get_connected_stream_ip [hsi::get_cells -hier $sink_periph] "M_AXIS"]
         }

         if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
                 set fifo_width_bytes [hsi get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
                 if {[string_is_empty $fifo_width_bytes]} {
                        set fifo_width_bytes 1
                 }

                 set rxethmem [hsi get_property CONFIG.FIFO_DEPTH $sink_periph]
                 # FIFO can be other than 8 bits, and we need the rxmem in bytes
                 set rxethmem [expr $rxethmem * $fifo_width_bytes]
                 add_prop "${node}" "xlnx,rxmem" $rxethmem int $dts_file
                 set fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "m_axis_tdata"]]
                 set fiforx_connect_ip [hsi::get_cells -of_objects $fifo_pin]
                 if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip] "axis_dwidth_converter"]} {
                       set fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $fiforx_connect_ip] "m_axis_tdata"]]
                       set fiforx_connect_ip [hsi::get_cells -of_objects $fifo_pin]
                       if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip] "axis_data_fifo"]} {
                              set fiforx_connect_ip [get_connected_stream_ip [hsi::get_cells -hier $fiforx_connect_ip] "M_AXIS"]
                       }
                 }

                 if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip] "axi_mcdma"]} {
                        mrmac_get_axistream_info $drv_handle $node $fiforx_connect_ip $dts_file
                 }

                 if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip] "mrmac_10g_mux"]} {
                        set data_fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $fiforx_connect_ip] "rx_m_axis_tdata"]]
                        set data_fifo_per [hsi::get_cells -of_objects $data_fifo_pin]
                        foreach data_fifo $data_fifo_per {
                              if {[string match -nocase [hsi get_property IP_NAME $data_fifo] "axis_data_fifo"]} {
                                      set fiforx_pin [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $data_fifo] "m_axis_tdata"]]
                                      if {[llength $fiforx_pin]} {
                                              set fiforx_per [::hsi::get_cells -of_objects $fiforx_pin]
                                      }
				      if {[string match -nocase [hsi get_property IP_NAME $fiforx_per] "axi_mcdma"]} {
					      mrmac_get_axistream_info $drv_handle $node $fiforx_per $dts_file
                                      } else {
                                              if {[llength $fiforx_per]} {
                                                    if {[string match -nocase [hsi get_property IP_NAME $fiforx_per] "RX_PTP_TS_PREPEND"]} {
                                                         set fiforx_connect_ip [get_connected_stream_ip [hsi get_cells -hier $fiforx_per] "m_axis"]
                                                    }
                                              }

					      if {[llength $fiforx_per]} {
                                                    if {[string match -nocase [hsi get_property IP_NAME $fiforx_per] "ethernet_offload"]} {
                                                         set fiforx_connect_ip [get_connected_stream_ip [hsi get_cells -hier $fiforx_per] "s2mm_axis"]
                                                    }
                                              }

                                              if {[llength $fiforx_connect_ip]} {

                                                     if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip] "axi_mcdma"]} {
                                                                mrmac_get_axistream_info $drv_handle $node $fiforx_connect_ip $dts_file
                                                     }
                                              }
                                      }
                              }
                        }
                 }
         }
    }

    proc mrmac_generate_reg_property {node base high} {
        set size [format 0x%llx [expr {${high} - ${base} + 1}]]

        set proctype [get_hw_family]
        if {[string match -nocase $proctype "versal"]} {
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
        add_prop "${node}" "reg" $reg hexlist "pl.dtsi"
    }

    proc mrmac_generate_intr_info {drv_handle node fifo_ip} {
        set ips [hsi::get_cells -hier $drv_handle]
        foreach ip [get_drivers 1] {
                if {[string compare -nocase $ip $fifo_ip] == 0} {
                        set target_handle $ip
                }
        }
        set ipnode [get_node $target_handle]
        set values [pldt getall $ipnode]
        set intr_parent ""
        set intr_val ""
        set int_names ""
        if {[regexp "interrupt*" $values match]} {
                set intr_val [pldt get $ipnode interrupts]
                set intr_val [string trimright $intr_val " >"]
                set intr_val [string trimleft $intr_val "< "]
                set intr_parent [pldt get $ipnode interrupt-parent]
                set intr_parent [string trimright $intr_parent ">"]
                set intr_parent [string trimleft $intr_parent "<"]
                set intr_parent [string trimleft $intr_parent "&"]
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
        } else {
                dtg_warning "Interrupts are not generated...please check the design"
        }
        set dts_file "pl.dtsi"
        if {[llength  $intr_val]} {
                add_prop "${node}" "interrupts" $intr_val intlist $dts_file
        }
        if {[llength $intr_parent]} {
                add_prop "${node}" "interrupt-parent" $intr_parent reference $dts_file
        }
        if {[llength $int_names]} {
                add_prop "${node}" "interrupt-names" $int_names noformating $dts_file
        }
    }

    proc mrmac_check_size {base node} {
        if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                set temp $base
                set temp [string trimleft [string trimleft $temp 0] x]
                set len [string length $temp]
                set rem [expr {${len} - 8}]
                set high_base "0x[string range $temp $rem $len]"
                set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                set low_base [format 0x%08x $low_base]
                set reg "$low_base $high_base"
        } else {
                set reg "$base"
        }
        return $reg
    }


    proc mrmac_gen_mrmac_clk_property {drv_handle} {
        set dts_file [set_drv_def_dts $drv_handle]
        set proctype [get_hw_family]
        if {[regexp "microblaze" $proctype match]} {
                return
        }
        set clocks ""
        set axi 0
        set is_clk_wiz 0
        set is_pl_clk 0
        set updat ""
        global bus_clk_list
        set clocknames ""
        set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
        set ip [get_ip_property $drv_handle IP_NAME]
        foreach clk $clk_pins {
                set ip [hsi::get_cells -hier $drv_handle]
                set port_width [get_port_width $clk]
                set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] $clk]]
                if {$port_width >= 2} {
                        for {set i 0} { $i < $port_width} {incr i} {
                                set peri [hsi::get_cells -of_objects $pins]
                                set mrclk "$clk$i"
                                if {[llength $peri]} {
                                           if {[get_ip_property $peri IP_NAME] in {"xlconcat" "ilconcat"}} {
                                                   set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects [hsi::get_cells $peri] In$i]] -filter "DIRECTION==O"]
                                                   set clk_peri [hsi::get_cells -of_objects $pins]
                                           }
                                }
                                set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
                                set pl_clk ""
                                set clkout ""
                                foreach pin $pins {
                                        if {[lsearch $valid_clk_list $pin] >= 0} {
                                                set clkout $pin
                                                set is_clk_wiz 1
                                                set periph [hsi::get_cells -of_objects $pin]
                                        }
                                }
                                if {[llength $clkout]} {
                                        set number [regexp -all -inline -- {[0-9]+} $clkout]
                                        set clk_wiz [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                                        set axi_clk "s_axi_aclk"
                                        foreach clk1 $clk_wiz {
                                                if {[regexp $axi_clk $clk1 match]} {
                                                        set axi 1
                                                }
                                }

                                if {[string match -nocase $axi "0"]} {
                                        dtg_warning "no s_axi_aclk for clockwizard"
                                        set pins [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                                        set clk_list "pl_clk*"
                                        set clk_pl ""
                                        set num ""
                                        foreach clk_wiz_pin $pins {
                                                        set clk_wiz_pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects $clk_wiz_pin]]
                                                        foreach pin $clk_wiz_pins {
                                                                if {[regexp $clk_list $pin match]} {
                                                                        set clk_pl $pin
                                                                }
                                                        }
                                        }
                                        if {[llength $clk_pl]} {
                                                set num [regexp -all -inline -- {[0-9]+} $clk_pl]
                                        }

                                        set dts_file "pl.dtsi"
                                        set bus_node [get_node $drv_handle]
                                        set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                                        if {[llength $clk_freq] == 0} {
                                                dtg_warning "clock frequency for the $clk is NULL"
                                                continue
                                        }

                                        set iptype [get_ip_property $drv_handle IP_NAME]
                                        if {![string equal $clk_freq ""]} {
                                                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                                        set bus_clk_list [lappend bus_clk_list $clk_freq]
                                                }
                                                set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                                set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                                -d ${dts_file} -p ${bus_node}]
                                                set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                                set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                                add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                                add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                                add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                                        }
                                }
                                if {![string match -nocase $axi "0"]} {
                                                switch $number {
                                                                "1" {
                                                                        set peri "$periph 0"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "2" {
                                                                        set peri "$periph 1"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "3" {
                                                                        set peri "$periph 2"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "4" {
                                                                        set peri "$periph 3"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "5" {
                                                                        set peri "$periph 4"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "6" {
                                                                        set peri "$periph 5"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "7" {
                                                                        set peri "$periph 6"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                }
                                }
                        }
                        set clklist ""
                        if {[string match -nocase $proctype "versal"]} {
                                set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
                        }
                        foreach pin $pins {
                                if { [llength $clklist]} {
                                        if {[lsearch $clklist $pin] >= 0} {
                                                set pl_clk $pin
                                                set is_pl_clk 1
                                        }
                                }
                        }
                        if {[string match -nocase $proctype "versal"]} {
                                switch $pl_clk {
                                                "pl_clk0" {
                                                                set pl_clk0 "versal_clk 65"
                                                                set clocks [lappend clocks $pl_clk0]
                                                                set updat  [lappend updat $pl_clk0]
                                                }
                                                "pl_clk1" {
                                                                set pl_clk1 "versal_clk 66"
                                                                set clocks [lappend clocks $pl_clk1]
                                                                set updat  [lappend updat $pl_clk1]
                                                }
                                                "pl_clk2" {
                                                                set pl_clk2 "versal_clk 67"
                                                                set clocks [lappend clocks $pl_clk2]
                                                                set updat [lappend updat $pl_clk2]
                                                }
                                                "pl_clk3" {
                                                                set pl_clk3 "versal_clk 68"
                                                                set clocks [lappend clocks $pl_clk3]
                                                                set updat [lappend updat $pl_clk3]
                                                }
                                                default {
                                                                dtg_debug "not supported pl_clk:$pl_clk"
                                                }
                                        }
                        }

                        if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
                                        set dts_file "pl.dtsi"
                                        set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                                        set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                                        if {[llength $clk_freq] == 0} {
                                                dtg_warning "clock frequency for the $clk is NULL"
                                                continue
                                        }
                                        set iptype [get_ip_property $drv_handle IP_NAME]
                                        if {![string equal $clk_freq ""]} {
                                                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                                        set bus_clk_list [lappend bus_clk_list $clk_freq]
                                                }
                                                set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                                set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                                -d ${dts_file} -p ${bus_node}]
                                                set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                                set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                                add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                                add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                                add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                                        }
                        }
                        append clocknames " " "$mrclk"
                        set is_pl_clk 0
                        set is_clk_wiz 0
                        set axi 0
                }
        } else {
                set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
                set pl_clk ""
                set clkout ""
                foreach pin $pins {
                        if {[lsearch $valid_clk_list $pin] >= 0} {
                                set clkout $pin
                                set is_clk_wiz 1
                                set periph [hsi::get_cells -of_objects $pin]
                        }
                }
                if {[llength $clkout]} {
                        set number [regexp -all -inline -- {[0-9]+} $clkout]
                        set clk_wiz [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                        set axi_clk "s_axi_aclk"
                        foreach clk1 $clk_wiz {
                                if {[regexp $axi_clk $clk1 match]} {
                                        set axi 1
                                }
                        }
                        if {[string match -nocase $axi "0"]} {
                                dtg_warning "no s_axi_aclk for clockwizard"
                                set pins [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                                set clk_list "pl_clk*"
                                set clk_pl ""
                                set num ""
                                foreach clk_wiz_pin $pins {
                                        set clk_wiz_pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects $clk_wiz_pin]]
                                        foreach pin $clk_wiz_pins {
                                                if {[regexp $clk_list $pin match]} {
                                                        set clk_pl $pin
                                                }
                                        }
                                }
                                if {[llength $clk_pl]} {
                                        set num [regexp -all -inline -- {[0-9]+} $clk_pl]
                                }
                                set dts_file "pl.dtsi"
                                set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                                set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                                if {[llength $clk_freq] == 0} {
                                        dtg_warning "clock frequency for the $clk is NULL"
                                        continue
                                }
                                set iptype [get_ip_property $drv_handle IP_NAME]
                                if {![string equal $clk_freq ""]} {
                                        if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                                set bus_clk_list [lappend bus_clk_list $clk_freq]
                                        }
                                        set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                        set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                        -d ${dts_file} -p ${bus_node}]
                                        set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                        set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                        add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                        add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                        add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                                }
                        }
                        if {![string match -nocase $axi "0"]} {
                                switch $number {
                                        "1" {
                                                set peri "$periph 0"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "2" {
                                                set peri "$periph 1"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "3" {
                                                set peri "$periph 2"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "4" {
                                                set peri "$periph 3"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "5" {
                                                set peri "$periph 4"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "6" {
                                                set peri "$periph 5"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "7" {
                                                set peri "$periph 6"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                }
                        }
                }
                if {[string match -nocase $proctype "versal"]} {
                        set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
                }
                foreach pin $pins {
                        if {[lsearch $clklist $pin] >= 0} {
                                set pl_clk $pin
                                set is_pl_clk 1
                        }
                }
                if {[string match -nocase $proctype "versal"]} {
                        switch $pl_clk {
                                "pl_clk0" {
                                                set pl_clk0 "versal_clk 65"
                                                set clocks [lappend clocks $pl_clk0]
                                                set updat  [lappend updat $pl_clk0]
                                }
                                "pl_clk1" {
                                                set pl_clk1 "versal_clk 66"
                                                set clocks [lappend clocks $pl_clk1]
                                                set updat  [lappend updat $pl_clk1]
                                }
                                "pl_clk2" {
                                                set pl_clk2 "versal_clk 67"
                                                set clocks [lappend clocks $pl_clk2]
                                                set updat [lappend updat $pl_clk2]
                                }
                                "pl_clk3" {
                                                set pl_clk3 "versal_clk 68"
                                                set clocks [lappend clocks $pl_clk3]
                                                set updat [lappend updat $pl_clk3]
                                }
                                default {
                                                dtg_warning "not supported pl_clk:$pl_clk"
                                }
                        }
                }

                if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
                        set dts_file "pl.dtsi"
                        set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                        set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                        if {[llength $clk_freq] == 0} {
                                dtg_warning "clock frequency for the $clk is NULL"
                                continue
                        }
                        set iptype [get_ip_property $drv_handle IP_NAME]
                        if {![string equal $clk_freq ""]} {
                                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                        set bus_clk_list [lappend bus_clk_list $clk_freq]
                                }
                                set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                -d ${dts_file} -p ${bus_node}]
                                set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                        }
                }
                append clocknames " " "$clk"
                set is_pl_clk 0
                set is_clk_wiz 0
                set axi 0
        }
        }
        set node [get_node $drv_handle]
        set_drv_prop_if_empty $drv_handle "zclock-names1" $clocknames $node stringlist
        set ip [get_ip_property $drv_handle IP_NAME]
        set len [llength $updat]
	if {$len > 0} {
            set refs [lindex $updat 0]
            for {set i 1} {$i < $len} {incr i} {
                append refs ">, <&[lindex $updat $i]"
            }
            set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
	}
    }

    proc mrmac_get_clk_frequency {ip_handle portname} {
        set clk ""
        set clkhandle [hsi::get_pins -of_objects $ip_handle $portname]
        set width [get_port_width $clkhandle]
        if {[string compare -nocase $clkhandle ""] != 0} {
                if {$width >= 2} {
                        set clk [hsi get_property CLK_FREQ $clkhandle ]
                        regsub -all ":" $clk { } clk
                        set clklen [llength $clk]
                        if {$clklen > 1} {
                                set clk [lindex $clk 0]
                        }
                } else {
                        set clk [hsi get_property CLK_FREQ $clkhandle ]
                }
        }
        return $clk
    }
