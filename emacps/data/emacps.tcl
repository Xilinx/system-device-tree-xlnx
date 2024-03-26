#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

    ##############################################################################
    variable phy_count 0
    ##############################################################################


    proc emacps_is_gmii2rgmii_conv_present {slave} {
        set phy_addr -1
        set ipconv 0

        set ips [hsi::get_cells -hier -filter {IP_NAME == "gmii_to_rgmii"}]
        set ip_name [hsi get_property NAME $slave]
        set slave_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $slave]]

        foreach ip $ips {
            set ipconv2eth_pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $ip "gmii_txd"]]]
            if {[regexp -nocase {(enet[0-3])} "$ipconv2eth_pins" match]} {
                    set number [regexp -all -inline -- {[0-3]+} $ipconv2eth_pins]
                    if {[string match -nocase $slave "psu_ethernet_$number"] || [string match -nocase $slave "ps7_ethernet_$number"]} {
                            set ipconv $ip
                            set phy_addr [hsi get_property "CONFIG.C_PHYADDR" $ipconv]
                            break
                   }
            }
            foreach gmii_pin ${ipconv2eth_pins} {
                # check if it is connected to the slave IP
                if { [lsearch ${slave_pins} $gmii_pin] >= 0 } {
                    set ipconv $ip
                    set phy_addr [hsi get_property "CONFIG.C_PHYADDR" $ipconv]
                    break
                }
            }
            if { $phy_addr >= 0 } {
                break
            }
        }
        return "$phy_addr $ipconv"
    }

    proc emacps_gen_phy_node args {
        set mdio_node [lindex $args 0]
        set phy_name [lindex $args 1]
        set phya [lindex $args 2]
        set dts_file "pcw.dtsi"
        set rgmii_node [create_node -l $phy_name -n $phy_name -u $phya -p $mdio_node -d $dts_file]
        add_prop "${rgmii_node}" "reg" $phya int $dts_file
        add_prop "${rgmii_node}" "compatible" "xlnx,gmii-to-rgmii-1.0" string $dts_file
        add_prop "${rgmii_node}" "phy-handle" phy1 reference $dts_file
    }

    proc emacps_generate {drv_handle} {
        update_eth_mac_addr $drv_handle
        set node [get_node $drv_handle]
        set slave [hsi::get_cells -hier $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set phymode [get_ip_param_value $slave "C_ETH_MODE"]
        if { $phymode == 0 } {
        add_prop $node "phy-mode" "gmii" string $dts_file
        } elseif { $phymode == 2 } {
        add_prop $node "phy-mode" "sgmii" string $dts_file
        } else {
        add_prop $node "phy-mode" "rgmii-id" string $dts_file
        }

           set ps7_cortexa9_1x_clk [get_ip_param_value [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}] 0] "C_CPU_1X_CLK_FREQ_HZ"]
        if {$ps7_cortexa9_1x_clk != ""} {
           add_prop $node "xlnx,ptp-enet-clock" "$ps7_cortexa9_1x_clk" hexint $dts_file
        }
        ps7_reset_handle $drv_handle CONFIG.C_ENET_RESET CONFIG.enet-reset

        # only generate the mdio node if it has mdio
        set has_mdio [hsi get_property CONFIG.C_HAS_MDIO $slave]
        if { $has_mdio == "0" } {
            return 0
        }

        set proc_type [get_hw_family]

	set tsu_enable ""
	set psx_wizard_periph [hsi get_cells -hier -filter {IP_NAME == psx_wizard}]
	set ps_wizard_periph [hsi get_cells -hier -filter {IP_NAME == ps_wizard}]
	set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
	set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]
	set clk ""
	if {![string_is_empty $psx_wizard_periph]} {
		set psx_pmcx_params [hsi get_property CONFIG.PSX_PMCX_CONFIG [hsi get_cells -hier $psx_wizard_periph]]
		set psx_gem_tsu_enable ""
		if {[llength $psx_pmcx_params]} {
			set psx_gem_tsu ""
			if {[dict exists $psx_pmcx_params "PSX_GEM_TSU"]} {
				set psx_gem_tsu [dict get $psx_pmcx_params "PSX_GEM_TSU"]
				if {[dict exists $psx_gem_tsu "ENABLE"]} {
					set tsu_enable [dict get $psx_gem_tsu "ENABLE"]
				}
			}
		}
		set clk [emacps_set_tsu_ext_clk versal $node versal_net_clk]
	} elseif {![string_is_empty $ps_wizard_periph]} {
		set ps_pmc_params [hsi get_property CONFIG.PS_PMC_CONFIG [hsi get_cells -hier $ps_wizard_periph]]
		set ps_gem_tsu_enable ""
		if {[llength $ps_pmc_params]} {
			set ps_gem_tsu ""
			if {[dict exists $ps_pmc_params "PS_GEM_TSU"]} {
				set ps_gem_tsu [dict get $ps_pmc_params "PS_GEM_TSU"]
				if {[dict exists $ps_gem_tsu "ENABLE"]} {
					set tsu_enable [dict get $ps_gem_tsu "ENABLE"]
				}
			}
		}
		set clk [emacps_set_tsu_ext_clk versal $node]
	} elseif {![string_is_empty $versal_periph]} {
		set tsu_enable [get_ip_property $versal_periph "CONFIG.PS_GEM_TSU_ENABLE"]
		set clk [emacps_set_tsu_ext_clk versal $node]
	} elseif {![string_is_empty $zynq_periph]} {
		set tsu_enable [get_ip_property $zynq_periph "CONFIG.PSU__GEM__TSU__ENABLE"]
		set clk [emacps_set_tsu_ext_clk zynqmp $node zynqmp_clk]
	}

	if {$tsu_enable == 1} {
                set default_dts [set_drv_def_dts $drv_handle]
                set tsu_node [create_node -n / -d $default_dts -p root]
                set tsu_node [create_node -n "tsu_ext_clk" -l "tsu_ext_clk" -d $default_dts -p /]
                add_prop "${tsu_node}" "compatible" "fixed-clock" stringlist $default_dts
                add_prop "${tsu_node}" "#clock-cells" 0 int $default_dts
                set tsu-clk-freq [hsi get_property CONFIG.C_ENET_TSU_CLK_FREQ_HZ [hsi::get_cells -hier $drv_handle]]
                add_prop "${tsu_node}" "clock-frequency" ${tsu-clk-freq} int $default_dts
                set_drv_prop_if_empty $drv_handle "clock-names" "pclk hclk tx_clk rx_clk tsu_clk" $node stringlist
                set_drv_prop_if_empty $drv_handle "clocks" $clk $node reference
        }

        # check if gmii2rgmii converter is used.
        set conv_data [emacps_is_gmii2rgmii_conv_present $slave]
        set phya [lindex $conv_data 0]
        if { $phya != "-1" } {
            set phy_name "[lindex $conv_data 1]"
            set_drv_prop $drv_handle phy-handle "phy1" $node reference
            set mdio_node [emacps_gen_mdio1_node $drv_handle $node]
            emacps_gen_phy_node $mdio_node $phy_name $phya
        }

        set ip_name " "
        if {[string match -nocase $proc_type "ps7_cortexa9"] } {
               if {[string match -nocase $node "&gem1"]} {
                    set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == processing_system7}]
                    set port0_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $zynq_periph] "ENET1_MDIO_O"]]
                    set sink_periph ""
                    if {[llength $port0_pins]} {
                        set sink_periph [::hsi::get_cells -of_objects $port0_pins]
                    }
                    if {[llength $sink_periph]} {
                        set ip_name [get_property IP_NAME $sink_periph]
                    }
                    if {[llength $ip_name] && [string match -nocase $ip_name "gig_ethernet_pcs_pma"]} {
                        set pin [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "phyaddr"]]
                        if {[llength $pin]} {
                            set periph [::hsi::get_cells -of_objects $pin]
                        }
                        if {[llength $periph]} {
                            set val [hsi get_property CONFIG.CONST_VAL $periph]
                            set inhex [format %x $val]
                            set_drv_prop $drv_handle phy-handle "phy$inhex" $node reference
                            set pcspma_phy_node [create_node -l phy$inhex -n phy -u $inhex -p $node]
                            add_prop "${pcspma_phy_node}" "reg" $val int
                            set phy_type [hsi get_property CONFIG.Standard $sink_periph]
                            set is_sgmii [hsi get_property CONFIG.c_is_sgmii $sink_periph]
                            if {$phy_type == "1000BASEX"} {
                                 add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x5 int
                                 add_prop $node "phy-mode" "1000base-x" string $dts_file 1
                            } elseif { $is_sgmii == "true"} {
                                 add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x4 int
                                 add_prop $node "phy-mode" "sgmii" string $dts_file 1
                            } else {
                                 dtg_warning "unsupported phytype:$phy_type"
                            }
                        }
                   }
              }
        }

        if {[is_zynqmp_platform $proc_type]} {
                set sink_periph ""
                      if {[string match -nocase $node "&gem0"]} {
              set connected_ip [get_connected_stream_ip $zynq_periph "MDIO_ENET0"]
              if {[llength $connected_ip]} {
                      set ip_name [hsi get_property IP_NAME $connected_ip]
              }
              if {[llength $ip_name] && [string match -nocase $ip_name "gig_ethernet_pcs_pma"]} {

                        set intf_pins [::hsi::get_intf_pins -of_objects [hsi get_cells $zynq_periph] "MDIO_ENET0"]
                        set connected_pin ""
                        set intf_nets ""
                        if {[llength $intf_pins]} {
                                set intf_nets [::hsi::get_intf_nets -of_objects $intf_pins]
                        }
                        if {[llength $intf_nets]} {
                                set connected_pin [::hsi::get_intf_pins -of_objects $intf_nets -filter {TYPE==SLAVE || TYPE==TARGET}]
                        }
                        set phyaddr_suffix ""
                        if {[llength $connected_pin]} {
                                set phyaddr_suffix [string trim $connected_pin "mdio_pcs_pma"]
                        }
                        set phyaddr "phyaddr"
                        if {[llength $phyaddr_suffix]} {
                                append phyaddr "_$phyaddr_suffix"
                        }

                        set pin [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $connected_ip] $phyaddr]]

                      if {[llength $pin]} {
                              set sink_periph [hsi::get_cells -of_objects $pin]
                      }
                      if {[llength $sink_periph]} {
                              set val [hsi get_property CONFIG.CONST_VAL $sink_periph]
                              set inhex [format %x $val]
                              set_drv_prop $drv_handle phy-handle "phy$inhex" $node reference
                              set pcspma_phy_node [create_node -l phy$inhex -n phy -u $inhex -p $node -d $dts_file]
                              add_prop "${pcspma_phy_node}" "reg" $val int $dts_file
                              set phy_type [hsi get_property CONFIG.Standard $connected_ip]
                              set is_sgmii [hsi get_property CONFIG.c_is_sgmii $connected_ip]
                              if {$phy_type == "1000BASEX"} {
                                      add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x5 int $dts_file
                                      add_prop $node "phy-mode" "1000base-x" string $dts_file  1
                              } elseif { $is_sgmii == "true"} {
                                      add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x4 int $dts_file
                                      add_prop $node "phy-mode" "sgmii" string $dts_file 1
                              } else {
                                      dtg_warning "unsupported phytype:$phy_type"
                              }
                      }
              }
                }
                        if {[string match -nocase $node "&gem1"]} {
               set connected_ip [get_connected_stream_ip $zynq_periph "MDIO_ENET1"]
               if {[llength $connected_ip]} {
                       set ip_name [hsi get_property IP_NAME $connected_ip]
               }
               if {[llength $ip_name] && [string match -nocase $ip_name "gig_ethernet_pcs_pma"]} {

                        set intf_pins [::hsi::get_intf_pins -of_objects [hsi get_cells $zynq_periph] "MDIO_ENET1"]
                        set connected_pin ""
                        set intf_nets ""
                        if {[llength $intf_pins]} {
                                set intf_nets [::hsi::get_intf_nets -of_objects $intf_pins]
                        }
                        if {[llength $intf_nets]} {
                                set connected_pin [::hsi::get_intf_pins -of_objects $intf_nets -filter {TYPE==SLAVE || TYPE==TARGET}]
                        }
                        set phyaddr_suffix ""
                        if {[llength $connected_pin]} {
                                set phyaddr_suffix [string trim $connected_pin "mdio_pcs_pma"]
                        }
                        set phyaddr "phyaddr"
                        if {[llength $phyaddr_suffix]} {
                                append phyaddr "_$phyaddr_suffix"
                        }
                        set pin [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $connected_ip] $phyaddr]]

                       if {[llength $pin]} {
                               set sink_periph [hsi::get_cells -of_objects $pin]
                       }
                       if {[llength $sink_periph]} {
                               set val [hsi get_property CONFIG.CONST_VAL $sink_periph]
                               set inhex [format %x $val]
                               set_drv_prop $drv_handle phy-handle "phy$inhex" $node reference
                               set pcspma_phy_node [create_node -l phy$inhex -n phy -u $inhex -p $node -d $dts_file]
                               add_prop "${pcspma_phy_node}" "reg" $val int $dts_fil
                               set phy_type [hsi get_property CONFIG.Standard $connected_ip]
                               set is_sgmii [hsi get_property CONFIG.c_is_sgmii $connected_ip]
                               if {$phy_type == "1000BASEX"} {
                                       add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x5 int $dts_fil
                                       add_prop $node "phy-mode" "1000base-x" string $dts_file 1
                               } elseif { $is_sgmii == "true"} {
                                       add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x4 int $dts_fil
                                       add_prop $node "phy-mode" "sgmii" string $dts_file 1
                               } else {
                                       dtg_warning "unsupported phytype:$phy_type"
                               }
                       }
               }
                }
                                       if {[string match -nocase $node "&gem2"]} {
                               set connected_ip [get_connected_stream_ip $zynq_periph "MDIO_ENET2"]
                               if {[llength $connected_ip]} {
                                       set ip_name [hsi get_property IP_NAME $connected_ip]
                               }
                               if {[llength $ip_name] && [string match -nocase $ip_name "gig_ethernet_pcs_pma"]} {
                                set intf_pins [::hsi::get_intf_pins -of_objects [hsi get_cells $zynq_periph] "MDIO_ENET2"]
                                set connected_pin ""
                                set intf_nets ""
                                if {[llength $intf_pins]} {
                                        set intf_nets [::hsi::get_intf_nets -of_objects $intf_pins]
                                }
                                if {[llength $intf_nets]} {
                                        set connected_pin [::hsi::get_intf_pins -of_objects $intf_nets -filter {TYPE==SLAVE || TYPE==TARGET}]
                                }
                                set phyaddr_suffix ""
                                if {[llength $connected_pin]} {
                                        set phyaddr_suffix [string trim $connected_pin "mdio_pcs_pma"]
                                }
                                set phyaddr "phyaddr"
                                if {[llength $phyaddr_suffix]} {
                                        append phyaddr "_$phyaddr_suffix"
                                }
                                set pin [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $connected_ip] $phyaddr]]

                       if {[llength $pin]} {
                               set sink_periph [hsi::get_cells -of_objects $pin]
                       }
                       if {[llength $sink_periph]} {
                               set val [hsi get_property CONFIG.CONST_VAL $sink_periph]
                               set inhex [format %x $val]
                               set_drv_prop $drv_handle phy-handle "phy$inhex" $node reference
                               set pcspma_phy_node [create_node -l phy$inhex -n phy -u $inhex -p $node -d $dts_file]
                               add_prop "${pcspma_phy_node}" "reg" $val int $dts_file
                               set phy_type [hsi get_property CONFIG.Standard $connected_ip]
                               set is_sgmii [hsi get_property CONFIG.c_is_sgmii $connected_ip]
                               if {$phy_type == "1000BASEX"} {
                                       add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x5 int $dts_file
                                       add_prop $node "phy-mode" "1000base-x" string $dts_file 1
                               } elseif { $is_sgmii == "true"} {
                                       add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x4 int $dts_file
                                       add_prop $node "phy-mode" "sgmii" string $dts_file 1
                               } else {
                                       dtg_warning "unsupported phytype:$phy_type"
                               }
                       }
               }
        }
        if {[string match -nocase $node "&gem3"]} {
               set connected_ip [get_connected_stream_ip $zynq_periph "MDIO_ENET3"]
               if {[llength $connected_ip]} {
                       set ip_name [hsi get_property IP_NAME $connected_ip]
               }
               if {[llength $ip_name] && [string match -nocase $ip_name "gig_ethernet_pcs_pma"]} {

                        set intf_pins [::hsi::get_intf_pins -of_objects [hsi get_cells $zynq_periph] "MDIO_ENET3"]
                        set connected_pin ""
                        set intf_nets ""
                        if {[llength $intf_pins]} {
                                set intf_nets [::hsi::get_intf_nets -of_objects $intf_pins]
                        }
                        if {[llength $intf_nets]} {
                                set connected_pin [::hsi::get_intf_pins -of_objects $intf_nets -filter {TYPE==SLAVE || TYPE==TARGET}]
                        }
                        set phyaddr_suffix ""
                        if {[llength $connected_pin]} {
                                set phyaddr_suffix [string trim $connected_pin "mdio_pcs_pma"]
                        }
                        set phyaddr "phyaddr"
                        if {[llength $phyaddr_suffix]} {
                                append phyaddr "_$phyaddr_suffix"
                        }
                        set pin [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $connected_ip] $phyaddr]]

                       if {[llength $pin]} {
                               set sink_periph [hsi::get_cells -of_objects $pin]
                       }
                       if {[llength $sink_periph]} {
                               set val [hsi get_property CONFIG.CONST_VAL $sink_periph]
                               set inhex [format %x $val]
                               set_drv_prop $drv_handle phy-handle "phy$inhex" $node reference
                               set pcspma_phy_node [create_node -l phy$inhex -n phy -u $inhex -p $node -d $dts_file]
                               add_prop "${pcspma_phy_node}" "reg" $val int $dts_file
                               set phy_type [hsi get_property CONFIG.Standard $connected_ip]
                               set is_sgmii [hsi get_property CONFIG.c_is_sgmii $connected_ip]
                               if {$phy_type == "1000BASEX"} {
                                       add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x5 int $dts_file
                                       add_prop $node "phy-mode" "1000base-x" string $dts_file 1
                               } elseif { $is_sgmii == "true"} {
                                       add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x4 int $dts_file
                                       add_prop $node "phy-mode" "sgmii" string $dts_file 1
                                } else {
                                      dtg_warning "unsupported phytype:$phy_type"
                              }
                      }

                        }
                }
        }
        set is_pcspma [hsi::get_cells -hier -filter {IP_NAME == gig_ethernet_pcs_pma}]
        if {![string_is_empty ${is_pcspma}] && $phymode == 2} {
                # if eth mode is sgmii and no external pcs/pma found
                add_prop $node "is-internal-pcspma" boolean $dts_file
        }
    }

    proc emacps_gen_mdio1_node {drv_handle parent_node} {
            set default_dts "pcw.dtsi"
           set mdio_node [create_node -l ${drv_handle}_mdio -n mdio -d $default_dts -p $parent_node]
           add_prop "${mdio_node}" "#address-cells" 1 int $default_dts
           add_prop "${mdio_node}" "#size-cells" 0 int $default_dts
           return $mdio_node
    }

    proc emacps_set_tsu_ext_clk {platform node {clk "versal_clk"}} {
	set clocks ""
	if {[string match -nocase $platform "zynqmp"]} {
		if {[string match -nocase $node "&gem3"]} {
			set clocks "${clk} 31>, <&${clk} 107>, <&${clk} 48>, <&${clk} 52>, <&tsu_ext_clk"
		} elseif {[string match -nocase $node "&gem2"]} {
			set clocks "${clk} 31>, <&${clk} 106>, <&${clk} 47>, <&${clk} 51>, <&tsu_ext_clk"
		} elseif {[string match -nocase $node "&gem1"]} {
			set clocks "${clk} 31>, <&${clk} 105>, <&${clk} 46>, <&${clk} 50>, <&tsu_ext_clk"
		} elseif {[string match -nocase $node "&gem0"]} {
			set clocks "${clk} 31>, <&${clk} 104>, <&${clk} 45>, <&${clk} 49>, <&tsu_ext_clk"
		}
	}
	if {[string match -nocase $platform "versal"]} {
		if {[string match -nocase $node "&gem0"]} {
			set clocks "${clk} 82>, <&${clk} 88>, <&${clk} 49>, <&${clk} 48>, <&tsu_ext_clk"
		} elseif {[string match -nocase $node "&gem1"]} {
			set clocks "${clk} 82>, <&${clk} 89>, <&${clk} 51>, <&${clk} 50>, <&tsu_ext_clk"
		}
	}
	return $clocks
    }
