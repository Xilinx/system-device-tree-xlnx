#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

# Helper function to configure PHY properties
proc emacps_configure_phy_props {pcspma_phy_node node dts_file phy_type is_sgmii {proc_type ""}} {
    if {$phy_type == "1000BASEX"} {
	add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x5 int $dts_file
	if {$proc_type == "versal"} {
		add_prop $node "phy-mode" "gmii" string $dts_file 1
	} else {
		add_prop $node "phy-mode" "1000base-x" string $dts_file 1
	}
    } elseif {$is_sgmii == "true"} {
        add_prop "${pcspma_phy_node}" "xlnx,phy-type" 0x4 int $dts_file
        add_prop $node "phy-mode" "sgmii" string $dts_file 1
    } else {
        dtg_warning "unsupported phytype:$phy_type"
    }
}

# Helper function to get phyaddr suffix from connected pin
proc emacps_get_phyaddr_suffix {zynq_periph mdio_interface} {
    set intf_pins [::hsi::get_intf_pins -of_objects [hsi get_cells $zynq_periph] $mdio_interface]
    set phyaddr_suffix ""
    if {[llength $intf_pins]} {
        set intf_nets [::hsi::get_intf_nets -of_objects $intf_pins]
        if {[llength $intf_nets]} {
            set connected_pin [::hsi::get_intf_pins -of_objects $intf_nets -filter {TYPE==SLAVE || TYPE==TARGET}]
            if {[llength $connected_pin]} {
                set phyaddr_suffix [string trim $connected_pin "mdio_pcs_pma"]
            }
        }
    }
    return $phyaddr_suffix
}

# Helper function to process PCS/PMA PHY configuration
proc emacps_process_pcspma_phy {drv_handle node dts_file connected_ip zynq_periph mdio_interface {proc_type ""}} {
    set phyaddr_suffix [emacps_get_phyaddr_suffix $zynq_periph $mdio_interface]
    set phyaddr "phyaddr"
    if {[llength $phyaddr_suffix]} {
        append phyaddr "_$phyaddr_suffix"
    }
    set pin [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $connected_ip] $phyaddr]]

    if {[llength $pin]} {
        set sink_periph [hsi::get_cells -of_objects $pin]
        if {[llength $sink_periph]} {
            set val [hsi get_property CONFIG.CONST_VAL $sink_periph]
            if {[llength $val]} {
                set inhex [format %x $val]
                set_drv_prop $drv_handle phy-handle "phy$inhex" $node reference
                set pcspma_phy_node [create_node -l phy$inhex -n phy -u $inhex -p $node -d $dts_file]
                add_prop "${pcspma_phy_node}" "reg" $val int $dts_file
                set phy_type [hsi get_property CONFIG.Standard $connected_ip]
                set is_sgmii [hsi get_property CONFIG.c_is_sgmii $connected_ip]
                emacps_configure_phy_props $pcspma_phy_node $node $dts_file $phy_type $is_sgmii $proc_type
            } else {
                dtg_warning "Cannot auto-detect PCS/PMA PHY address configuration. \
                Skipping PHY node creation. Please verify hardware configuration \
                or add PHY details manually to device tree if needed."
            }
        }
    }
}


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
    global env
    set mdio_node [lindex $args 0]
    set phy_name [lindex $args 1]
    set phya [lindex $args 2]
    set dts_file "pcw.dtsi"
    set rgmii_node [create_node -l $phy_name -n $phy_name -u $phya -p $mdio_node -d $dts_file]
    add_prop "${rgmii_node}" "reg" $phya int $dts_file
    add_prop "${rgmii_node}" "compatible" "xlnx,gmii-to-rgmii-1.0" string $dts_file
    if {![catch {[string_is_empty $env(sdt_board_dts)]} msg]} {
        add_prop "${rgmii_node}" "phy-handle" phy1 reference $dts_file
    }
}

proc emacps_get_tsu_enable {params key} {
    if {[dict exists $params $key]} {
        set tsu_dict [dict get $params $key]
        if {[dict exists $tsu_dict "ENABLE"]} {
            return [dict get $tsu_dict "ENABLE"]
        }
    }
    # Return an empty string if TSU enable parameter is not found
    return ""
}

proc emacps_generate {drv_handle} {
    global env
    global is_versal_2ve_2vm_platform

    # Initialize core variables
    set node [get_node $drv_handle]
    set slave [hsi::get_cells -hier $drv_handle]
    set dts_file [set_drv_def_dts $drv_handle]
    set ip_name [get_ip_property $drv_handle IP_NAME]
    set phymode [get_ip_param_value $slave "C_ETH_MODE"]
    set proc_type [get_hw_family]

    # Configure PHY mode based on ethernet mode
    if { $phymode == 0 } {
        add_prop $node "phy-mode" "gmii" string $dts_file
    } elseif { $phymode == 2 } {
        add_prop $node "phy-mode" "sgmii" string $dts_file
    } elseif { !($is_versal_2ve_2vm_platform && [string match -nocase $ip_name "mmi_10gbe"]) } {
        add_prop $node "phy-mode" "rgmii-id" string $dts_file
    }


    # Configure PTP ethernet clock if available
    set ps7_cortexa9_1x_clk [get_ip_param_value [lindex [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}] 0] "C_CPU_1X_CLK_FREQ_HZ"]
    if {$ps7_cortexa9_1x_clk != ""} {
        add_prop $node "xlnx,ptp-enet-clock" "$ps7_cortexa9_1x_clk" hexint $dts_file
    }
    ps7_reset_handle $drv_handle CONFIG.C_ENET_RESET CONFIG.enet-reset


    # Initialize TSU (Time Stamp Unit) configuration variables
    set tsu_enable ""
    set clk ""

    # Cache peripheral lookups to avoid repeated queries
    set psx_wizard_periph [hsi get_cells -hier -filter {IP_NAME == psx_wizard}]
    set ps_wizard_periph [hsi get_cells -hier -filter {IP_NAME == ps_wizard}]
    set versal_periph [hsi::get_cells -hier -filter {IP_NAME == versal_cips}]
    set zynq_periph [hsi::get_cells -hier -filter {IP_NAME == zynq_ultra_ps_e}]

    # Configure TSU based on platform type
    if {![string_is_empty $psx_wizard_periph]} {
        set psx_pmcx_params [hsi get_property CONFIG.PSX_PMCX_CONFIG [hsi get_cells -hier $psx_wizard_periph]]
        set tsu_enable [emacps_get_tsu_enable $psx_pmcx_params "PSX_GEM_TSU"]
        set clk [emacps_set_tsu_ext_clk versal $node versal_net_clk]
    } elseif {![string_is_empty $ps_wizard_periph]} {
        if {[string match -nocase $ip_name "mmi_10gbe"]} {
            set config_prop "CONFIG.MMI_CONFIG"
            # Use fixed 150 MHz clock for MMI 10GbE as required by hardware specification
            set sys_clk "clk150"
            # Check for GEM_EXT_TSU_EN in CONFIG.MMI_CONFIG property
            set mmi_10gbe_params [hsi get_property $config_prop [hsi get_cells -hier $ps_wizard_periph]]
            if {[dict exists $mmi_10gbe_params "GEM_EXT_TSU_EN"]} {
                set tsu_enable [dict get $mmi_10gbe_params "GEM_EXT_TSU_EN"]
            }
        } else {
            set config_prop [expr {$is_versal_2ve_2vm_platform ? "CONFIG.PS11_CONFIG" : "CONFIG.PS_PMC_CONFIG"}]
            set sys_clk [expr {$is_versal_2ve_2vm_platform ? "versal2_clk" : "versal_clk"}]
        }
        set ps_pmc_params [hsi get_property $config_prop [hsi get_cells -hier $ps_wizard_periph]]
        if {$tsu_enable == ""} {
            set tsu_enable [emacps_get_tsu_enable $ps_pmc_params "PS_GEM_TSU"]
        }
        set clk [emacps_set_tsu_ext_clk versal $node $sys_clk]
    } elseif {![string_is_empty $versal_periph]} {
        set tsu_enable [get_ip_property $versal_periph "CONFIG.PS_GEM_TSU_ENABLE"]
        set clk [emacps_set_tsu_ext_clk versal $node]
    } elseif {![string_is_empty $zynq_periph]} {
        set tsu_enable [get_ip_property $zynq_periph "CONFIG.PSU__GEM__TSU__ENABLE"]
        set clk [emacps_set_tsu_ext_clk zynqmp $node zynqmp_clk]
    }

    if {$tsu_enable == 1} {
        # Configure TSU (Time Stamp Unit) clock node and properties
        set tsu_node_name "tsu_ext_clk"
        set clock_names "pclk hclk tx_clk rx_clk tsu_clk"
        # For mmi_10gbe, use a different node and clock-names
        if {[string match -nocase $ip_name "mmi_10gbe"]} {
            set clock_names "pclk hclk tx_clk tsu_clk"
            set tsu_node_name "mmi_tsu_ext_clk"
        }
        set default_dts [set_drv_def_dts $drv_handle]
        set tsu_node [create_node -n / -d $default_dts -p root]
        set tsu_node [create_node -n "$tsu_node_name" -l "$tsu_node_name" -d $default_dts -p /]
        add_prop "${tsu_node}" "compatible" "fixed-clock" stringlist $default_dts
        add_prop "${tsu_node}" "#clock-cells" 0 int $default_dts
        set tsu-clk-freq [hsi get_property CONFIG.C_ENET_TSU_CLK_FREQ_HZ [hsi::get_cells -hier $drv_handle]]
        add_prop "${tsu_node}" "clock-frequency" ${tsu-clk-freq} int $default_dts
        set_drv_prop_if_empty $drv_handle "clock-names" "$clock_names" $node stringlist
        set_drv_prop_if_empty $drv_handle "clocks" $clk $node reference
    }

    # only generate the mdio node if it has mdio
    set has_mdio [hsi get_property CONFIG.C_HAS_MDIO $slave]
    if { $has_mdio == "0" } {
        return 0
    }

    # check if gmii2rgmii converter is used.
    set conv_data [emacps_is_gmii2rgmii_conv_present $slave]
    set phya [lindex $conv_data 0]
    if { $phya != "-1" } {
        set phy_name "[lindex $conv_data 1]"
        if {![catch {[string_is_empty $env(sdt_board_dts)]} msg]} {
            set_drv_prop $drv_handle phy-handle "phy1" $node reference
        }
        set mdio_node [emacps_gen_mdio1_node $drv_handle $node]
        emacps_gen_phy_node $mdio_node $phy_name $phya
    }

    # Process Zynq platform specific configurations
    if {[string match -nocase $proc_type "zynq"] } {
        if {[string match -nocase $node "&gem1"]} {
            set zynq_ps7_periph [hsi::get_cells -hier -filter {IP_NAME == processing_system7}]
            set port0_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $zynq_ps7_periph] "ENET1_MDIO_O"]]
            set sink_periph ""
            if {[llength $port0_pins]} {
                set sink_periph [::hsi::get_cells -of_objects $port0_pins]
            }
            if {[llength $sink_periph]} {
                set sink_ip_name [hsi get_property IP_NAME $sink_periph]
                if {[llength $sink_ip_name] && [string match -nocase $sink_ip_name "gig_ethernet_pcs_pma"]} {
                    set pin [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "phyaddr"]]
                    if {[llength $pin]} {
                        set periph [::hsi::get_cells -of_objects $pin]
                        if {[llength $periph]} {
                            set val [hsi get_property CONFIG.CONST_VAL $periph]
                            set inhex [format %x $val]
                            set_drv_prop $drv_handle phy-handle "phy$inhex" $node reference
                            set pcspma_phy_node [create_node -l phy$inhex -n phy -u $inhex -p $node -d $dts_file]
                            add_prop "${pcspma_phy_node}" "reg" $val int $dts_file
                            set phy_type [hsi get_property CONFIG.Standard $sink_periph]
                            set is_sgmii [hsi get_property CONFIG.c_is_sgmii $sink_periph]
                            emacps_configure_phy_props $pcspma_phy_node $node $dts_file $phy_type $is_sgmii
                        }
                    }
                }
            }
        }
    }

    if {[is_zynqmp_platform $proc_type]} {
        # Process GEM interfaces using helper function to reduce code duplication
        set gem_interfaces [list \
            [list "&gem0" "MDIO_ENET0"] \
            [list "&gem1" "MDIO_ENET1"] \
            [list "&gem2" "MDIO_ENET2"] \
            [list "&gem3" "MDIO_ENET3"] \
        ]

        foreach gem_interface $gem_interfaces {
            set gem_node [lindex $gem_interface 0]
            set mdio_interface [lindex $gem_interface 1]

            if {[string match -nocase $node $gem_node]} {
                set connected_ip [get_connected_stream_ip $zynq_periph $mdio_interface]
                if {[llength $connected_ip]} {
                    set connected_ip_name [hsi get_property IP_NAME $connected_ip]
                    if {[llength $connected_ip_name] && [string match -nocase $connected_ip_name "gig_ethernet_pcs_pma"]} {
                        emacps_process_pcspma_phy $drv_handle $node $dts_file $connected_ip $zynq_periph $mdio_interface
                        break
                    }
                }
            }
        }
    }

    if {[string match -nocase $proc_type "versal"]} {
        # Versal has gem0 and gem1
        set gem_interfaces [list \
            [list "&gem0" "GEM0_MDIO"] \
            [list "&gem1" "GEM1_MDIO"] \
        ]

        # For Versal with ps_wizard, the peripheral reference would be different
        set versal_ps_periph [hsi get_cells -hier -filter {IP_NAME == versal_cips || IP_NAME == ps_wizard}]

        foreach gem_interface $gem_interfaces {
            set gem_node [lindex $gem_interface 0]
            set mdio_interface [lindex $gem_interface 1]
            if {[string match -nocase $node $gem_node]} {
                set connected_ip [get_connected_stream_ip $versal_ps_periph $mdio_interface]
                if {[llength $connected_ip]} {
                    set connected_ip_name [hsi get_property IP_NAME $connected_ip]
                    if {[llength $connected_ip_name] && [string match -nocase $connected_ip_name "gig_ethernet_pcs_pma"]} {
                        emacps_process_pcspma_phy $drv_handle $node $dts_file $connected_ip $versal_ps_periph $mdio_interface "versal"
                        break
                    }
                }
            }
        }
    }

    # Check for internal PCS/PMA configuration
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
    # Define clock configuration lookup tables for better performance
    array set zynqmp_clocks {
        "&gem0" "31>, <&%s 104>, <&%s 45>, <&%s 49>, <&tsu_ext_clk"
        "&gem1" "31>, <&%s 105>, <&%s 46>, <&%s 50>, <&tsu_ext_clk"
        "&gem2" "31>, <&%s 106>, <&%s 47>, <&%s 51>, <&tsu_ext_clk"
        "&gem3" "31>, <&%s 107>, <&%s 48>, <&%s 52>, <&tsu_ext_clk"
    }

    array set versal_clocks {
        "&gem0" "82>, <&%s 88>, <&%s 49>, <&%s 48>, <&tsu_ext_clk"
        "&gem1" "82>, <&%s 89>, <&%s 51>, <&%s 50>, <&tsu_ext_clk"
        "&mmi_10gbe" ">, <&%s>, <&%s>, <&mmi_tsu_ext_clk"
    }

    set clocks ""
    set platform_lower [string tolower $platform]
    set node_lower [string tolower $node]

    if {$platform_lower == "zynqmp" && [info exists zynqmp_clocks($node_lower)]} {
        set clocks [format "${clk} $zynqmp_clocks($node_lower)" $clk $clk $clk]
    } elseif {$platform_lower == "versal" && [info exists versal_clocks($node_lower)]} {
        set clocks [format "${clk} $versal_clocks($node_lower)" $clk $clk $clk]
    }

    return $clocks
}
