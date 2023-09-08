#
# (C) Copyright 2013-2021 Xilinx, Inc.
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
namespace export *
proc get_exact_arg_list { args } {
    lappend argList
    foreach arg $args {
        set subargs [regexp -all -inline {\S+} "$arg"]
        foreach subarg $subargs {
            set newarg $subarg
            set newarg [string map { "\{" "" } $newarg]
            set newarg [string map { "\}" "" } $newarg]
            lappend argList $newarg
        }
    }
    return $argList
}
#
# Open file in the include directory
#
proc open_include_file {file_name} {
    set filename [file join "../../include" $file_name]
    set config_inc [open $filename a]
    if {![file exists $filename]} {
        write_c_header $config_inc "Driver parameters"
    }
    return $config_inc
}

proc get_drivers_sw args {
	set driverlist [dict create]
	dict set driverlist RM driver RM
	dict set driverlist ai_engine driver ai_engine
	dict set driverlist psu_ams driver ams
	dict set driverlist psu_apm driver apmps
	dict set driverlist psv_apm driver apmps
	dict set driverlist v_uhdsdi_audio driver audio_embed
	dict set driverlist audio_formatter driver audio_spdif
	dict set driverlist spdif driver audio_spdif
	dict set driverlist axi_bram_ctrl driver axi_bram
	dict set driverlist lmb_bram_if_cntlr driver axi_bram
	dict set driverlist can driver axi_can
	dict set driverlist canfd driver axi_can
	dict set driverlist axi_cdma driver axi_cdma
	dict set driverlist clk_wiz driver axi_clk_wiz
	dict set driverlist clk_wizard driver axi_clk_wiz
	dict set driverlist axi_dma driver axi_dma
	dict set driverlist axi_emc driver axi_emc
	dict set driverlist axi_ethernet driver axi_ethernet
	dict set driverlist axi_ethernet_buffer  driver axi_ethernet
	dict set driverlist axi_10g_ethernet driver axi_ethernet
	dict set driverlist xxv_ethernet driver axi_ethernet
	dict set driverlist usxgmii driver axi_ethernet
	dict set driverlist axi_gpio driver axi_gpio
	dict set driverlist axi_iic driver axi_iic
	dict set driverlist axi_mcdma driver axi_mcdma
	dict set driverlist axi_pcie driver axi_pcie
	dict set driverlist axi_pcie3 driver axi_pcie
	dict set driverlist xdma driver axi_pcie
	dict set driverlist pcie_dma_versal driver axi_pcie
	dict set driverlist axi_perf_mon driver axi_perf_mon
	dict set driverlist axi_quad_spi driver axi_qspi
	dict set driverlist axi_sysace driver axi_sysace
	dict set driverlist axi_tft driver axi_tft
	dict set driverlist axi_timebase_wdt driver axi_timebase_wdt
	dict set driverlist axi_traffic_gen driver axi_traffic_gen
	dict set driverlist axi_usb2_device driver axi_usb2_device
	dict set driverlist vcu driver axi_vcu
	dict set driverlist axi_vdma driver axi_vdma
	dict set driverlist xadc_wiz driver axi_xadc
	dict set driverlist psu_canfd driver canfdps
	dict set driverlist psv_canfd driver canfdps
	dict set driverlist ps7_can driver canps
	dict set driverlist psu_can driver canps
	dict set driverlist psv_can driver canps
	dict set driverlist microblaze driver cpu
	dict set driverlist psu_cortexa53 driver cpu_cortexa53
	dict set driverlist psv_cortexa72 driver cpu_cortexa72
	dict set driverlist ps7_cortexa9 driver cpu_cortexa9
	dict set driverlist psu_cortexr5 driver cpu_cortexr5
	dict set driverlist psv_cortexr5 driver cpu_cortexr5
	dict set driverlist psu_crl_apb driver crl_apb
	dict set driverlist ps7_ddrc driver ddrcps
	dict set driverlist psu_ddrc driver ddrcps
	dict set driverlist psv_ddrc driver ddrcps
	dict set driverlist ps7_ddr driver ddrcps
	dict set driverlist psu_ddr driver ddrps
	dict set driverlist psv_ddr driver ddrps
	dict set driverlist axi_noc driver ddrpsv
	dict set driverlist noc_mc_ddr4 driver ddrpsv
	dict set driverlist debug_bridge driver debug_bridge
	dict set driverlist v_demosaic driver demosaic
	dict set driverlist ps7_dev_cfg driver devcfg
	dict set driverlist ps7_dma driver dmaps
	dict set driverlist psu_gdma driver dmaps
	dict set driverlist psu_csudma driver dmaps
	dict set driverlist psv_adma driver dmaps
	dict set driverlist psv_gdma driver dmaps
	dict set driverlist psv_csudma driver dmaps
	dict set driverlist psu_dp driver dp
	dict set driverlist psv_dp driver dp
	dict set driverlist dpu_eu driver dpu_eu
	dict set driverlist axi_ethernetlite driver emaclite
	dict set driverlist ps7_ethernet driver emacps
	dict set driverlist psu_ethernet driver emacps
	dict set driverlist psv_ethernet driver emacps
	dict set driverlist ernic driver ernic
	dict set driverlist v_frmbuf_rd driver framebuf_rd
	dict set driverlist v_frmbuf_wr driver framebuf_wr
	dict set driverlist v_gamma_lut driver gamma_lut
	dict set driverlist ps7_globaltimer driver globaltimerps
	dict set driverlist ps7_gpio driver gpiops
	dict set driverlist psu_gpio driver gpiops
	dict set driverlist psv_gpio driver gpiops
	dict set driverlist hdmi_acr_ctlr driver hdmi_ctrl
	dict set driverlist hdmi_gt_controller driver hdmi_gt_ctrl
	dict set driverlist v_hdmi_rx_ss driver hdmi_rx_ss
	dict set driverlist v_hdmi_tx_ss driver hdmi_tx_ss
	dict set driverlist i2s_receiver driver i2s_receiver
	dict set driverlist i2s_transmitter driver i2s_transmitter
	dict set driverlist ps7_i2c driver iicps
	dict set driverlist psu_i2c driver iicps
	dict set driverlist psv_i2c driver iicps
	dict set driverlist axi_intc driver intc
	dict set driverlist iomodule driver iomodule
	dict set driverlist psu_ipi driver ipipsu
	dict set driverlist psv_ipi driver ipipsu
	dict set driverlist mig_7series driver mig_7series
	dict set driverlist dd4 driver mig_7series
	dict set driverlist ddr3 driver mig_7series
	dict set driverlist mipi_csi2_rx_subsystem driver mipi_csi2_rx
	dict set driverlist mipi_csi2_tx_subsystem driver mipi_csi2_tx
	dict set driverlist v_mix driver mixer
	dict set driverlist v_multi_scaler driver multi_scaler
	dict set driverlist ps7_nand driver nandps
	dict set driverlist psu_nand driver nandps
	dict set driverlist ps7_sram driver norps
	dict set driverlist nvme_subsystem driver nvme_aggr
	dict set driverlist ps7_ocmc driver ocmcps
	dict set driverlist psu_ocmc driver ocmcps
	dict set driverlist psv_ocmc driver ocmcps
	dict set driverlist ps7_pl310 driver pl310ps
	dict set driverlist psu_pmu driver pmups
	dict set driverlist psv_pmc driver pmups
	dict set driverlist psv_psm driver pmups
	dict set driverlist pr_decoupler driver pr_decoupler
	dict set driverlist prc driver prc
	dict set driverlist dfx_controller driver prc
	dict set driverlist psu_ocm_ram_0 driver psu_ocm
	dict set driverlist psv_ocm_ram_0 driver psu_ocm
	dict set driverlist ps7_ram driver ramps
	dict set driverlist usp_rf_data_converter driver rfdc
	dict set driverlist v_scenechange driver scene_change_detector
	dict set driverlist ps7_scugic driver scugic
	dict set driverlist psu_acpu_gic driver scugic
	dict set driverlist psv_acpu_gic driver scugic
	dict set driverlist ps7_scutimer driver scutimer
	dict set driverlist ps7_scuwdt driver scuwdt
	dict set driverlist psu_wdt driver scuwdt
	dict set driverlist psv_wdt driver scuwdt
	dict set driverlist sd_fec driver sdfec
	dict set driverlist v_smpte_uhdsdi_rx_ss driver sdi_rx
	dict set driverlist v_smpte_uhdsdi_tx_ss driver sdi_tx
	dict set driverlist ps7_sdioi driver sdps
	dict set driverlist psu_sd driver sdps
	dict set driverlist psv_pmc_sd driver sdps
	dict set driverlist ps7_slcr driver slcrps
	dict set driverlist ps7_smcc driver smccps
	dict set driverlist ps7_spi driver spips
	dict set driverlist psu_qspi driver spips
	dict set driverlist psv_pmc_qspi driver qspips
	dict set driverlist psu_qspi driver qspips
	dict set driverlist ps7_qspi driver qspips
	dict set driverlist psv_spi driver spips
	dict set driverlist sync_ip driver sync_ip
	dict set driverlist axi_timer driver tmrctr
	dict set driverlist v_tpg driver tpg
	dict set driverlist tsn_endpoint_ethernet_mac driver tsn
	dict set driverlist ps7_ttc driver ttcps
	dict set driverlist psu_ttc driver ttcps
	dict set driverlist psv_ttc driver ttcps
	dict set driverlist mdm driver uartlite
	dict set driverlist axi_uartlite driver uartlite
	dict set driverlist axi_uart16550 driver uartns
	dict set driverlist ps7_uart driver uartps
	dict set driverlist psu_uart driver uartps
	dict set driverlist psu_sbsauart driver uartps
	dict set driverlist psv_uart driver uartps
	dict set driverlist psv_sbsauart driver uartps
	dict set driverlist ps7_usb driver usbps
	dict set driverlist psu_usb_xhci driver usbps
	dict set driverlist psv_usb_xhci driver usbps
	dict set driverlist vid_phy_controller driver vid_phy_ctrl
	dict set driverlist v_proc_ss driver vproc_ss
	dict set driverlist v_tc driver vtc
	dict set driverlist ps7_wdt driver wdtps
	dict set driverlist psu_wdt driver wdtps
	dict set driverlist psv_wdt driver wdtps
	dict set driverlist ps7_xadc driver xadcps
	dict set driverlist psv_pmc_sysmon driver sysmonpsv
	set val [lindex $args 0]
	if {[string match -nocase $val "1"]} {
		set drivers ""
		foreach drv_handle [hsi::get_cells -hier] {
			set ipname [hsi get_property IP_NAME $drv_handle]
			set val [hsi::get_mem_ranges $drv_handle]
			if {[string match -nocase [hsi get_property IP_TYPE [hsi::get_cells -hier $drv_handle]] "processor"]} {
				if {[string match -nocase $ipname "psv_cortexa72"] || [string match -nocase $ipname "psu_cortexa53"]} {
					set index [string index $drv_handle end]
					if {$index == 0} {
						continue
					}
				}
			} else {
				if {[string_is_empty $val]} {
					continue
				}
			}
			if {[catch {set tmp [dict get $driverlist $ipname]} msg]} {
					continue
			}
			if {[string match -nocase $drivers ""]} {
				set drivers $drv_handle
			} else {
				lappend drivers $drv_handle
			}
		}
		
		if {[string match -nocase $drivers ""]} {
			set drivers "generic"
		}
		return $drivers
	} else {
		set ipname [hsi get_property IP_NAME [hsi::get_cells -hier $val]]
		if {[catch {set tmp [dict get $driverlist $ipname]} msg]} {
			set drivers "generic"
			return "generic"
		}
		regsub "driver " $tmp "" tmp
		return $tmp
	}
}

#
# Create a parameter name based on the format of Xilinx device drivers
# Use peripheral name to form the parameter name
#
proc get_ip_param_name {periph_handle param} {
   set name [hsi get_property NAME $periph_handle ]
   set name [string toupper $name]
   set name [string map { "/" "_" } $name]
   set name [format "XPAR_%s_" $name]
   set param [string toupper $param]
   if {[string match C_* $param]} {
       set name [format "%s%s" $name [string range $param 2 end]]
   } else {
       set name [format "%s%s" $name $param]
   }
   return $name
}

#
# Create a parameter name based on the format of Xilinx device drivers.
# Use driver name to form the parameter name
#
proc get_driver_param_name {driver_name param} {
   set name [string toupper $driver_name]
   set name [string map { "/" "_" } $name]
   set name [format "XPAR_%s_" $name]
   if {[string match C_* $param]} {
       set name [format "%s%s" $name [string range $param 2 end]]
   } else {
       set name [format "%s%s" $name $param]
   }
   return $name
}
    
#
# Given a list of arguments, define them all in an include file.
# Handles IP model/user parameters, as well as the special parameters NUM_INSTANCES,
# DEVICE_ID
# Will not work for a processor.
#
proc define_include_file {drv_handle file_name drv_string args} {
    set args [get_exact_arg_list $args]
    # Open include file
    set file_handle [open_include_file $file_name]

    # Get all peripherals connected to this driver
    set periphs [get_common_driver_ips $drv_handle] 

    # Handle special cases
    set arg "NUM_INSTANCES"
    set posn [lsearch -exact $args $arg]
    if {$posn > -1} {
        puts $file_handle "/* Definitions for driver [string toupper [hsi get_property name $drv_handle]] */"
        # Define NUM_INSTANCES
        puts $file_handle "#define [get_driver_param_name $drv_string $arg] [llength $periphs]"
        set args [lreplace $args $posn $posn]
    }

    # Check if it is a driver parameter
    lappend newargs 
    foreach arg $args {
        set value [hsi get_property CONFIG.$arg $drv_handle]
        if {[llength $value] == 0} {
            lappend newargs $arg
        } else {
            puts $file_handle "#define [get_driver_param_name $drv_string $arg] [hsi get_property $arg $drv_handle]"
        }
    }
    set args $newargs

    # Print all parameters for all peripherals
    set device_id 0
    foreach periph $periphs {
        puts $file_handle ""
        puts $file_handle "/* Definitions for peripheral [string toupper [hsi get_property NAME $periph]] */"
        foreach arg $args {
            if {[string compare -nocase "DEVICE_ID" $arg] == 0} {
                set value $device_id
                incr device_id
            } else {
                set value [hsi get_property CONFIG.$arg $periph]
            }
            if {[llength $value] == 0} {
                set value 0
            }
            set value [format_addr_string $value $arg]
            if {[string compare -nocase "HW_VER" $arg] == 0} {
                puts $file_handle "#define [get_ip_param_name $periph $arg] \"$value\""
            } else {
                puts $file_handle "#define [get_ip_param_name $periph $arg] $value"
            }
        }
        puts $file_handle ""
    }		
    puts $file_handle "\n/******************************************************************/\n"
    close $file_handle
}

#
# Given a list of arguments, define them all in an include file.
# Similar to proc define_include_file, except that uses regsub
# to replace "S_AXI_" with "".
#
proc define_zynq_include_file {drv_handle file_name drv_string args} {
    set args [get_exact_arg_list $args]
   # Open include file
   set file_handle [open_include_file $file_name]

   # Get all peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle] 

   # Handle special cases
   set arg "NUM_INSTANCES"
   set posn [lsearch -exact $args $arg]
   if {$posn > -1} {
       puts $file_handle "/* Definitions for driver [string toupper [hsi get_property name $drv_handle]] */"
       # Define NUM_INSTANCES
       puts $file_handle "#define [get_driver_param_name $drv_string $arg] [llength $periphs]"
       set args [lreplace $args $posn $posn]
   }

   # Check if it is a driver parameter
   lappend newargs 
   foreach arg $args {
       set value [hsi get_property CONFIG.$arg $drv_handle ]
       if {[llength $value] == 0} {
           lappend newargs $arg
       } else {
           puts $file_handle "#define [get_driver_param_name $drv_string $arg] [hsi get_property CONFIG.$arg $drv_handle ]"
       }
   }
   set args $newargs

   # Print all parameters for all peripherals
   set device_id 0
   foreach periph $periphs {
       puts $file_handle ""
       puts $file_handle "/* Definitions for peripheral [string toupper [hsi get_property NAME $periph]] */"
       foreach arg $args {
           if {[string compare -nocase "DEVICE_ID" $arg] == 0} {
               set value $device_id
               incr device_id
           } else {
               set value [hsi get_property CONFIG.$arg $periph]
           }
           if {[llength $value] == 0} {
               set value 0
           }
           set value [format_addr_string $value $arg]
           set arg_name [get_ip_param_name $periph $arg]
           regsub "S_AXI_" $arg_name "" arg_name
           if {[string compare -nocase "HW_VER" $arg] == 0} {
               puts $file_handle "#define $arg_name \"$value\""
           } else {
               puts $file_handle "#define $arg_name $value"
           }
       }
       puts $file_handle ""
   }		
   puts $file_handle "\n/******************************************************************/\n"
   close $file_handle
}

#
# Define parameter only if all peripherals have this parameter defined.
#
proc define_if_all {drv_handle file_name drv_string args} {
    set args [get_exact_arg_list $args]
   # Open include file
   set file_handle [open_include_file $file_name]

   # Get all peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle] 

   # Check all parameters for all peripherals
   foreach arg $args {
       set value 1
       foreach periph $periphs {
           set thisvalue [get_param_value $periph $arg]
           if {$thisvalue != 1} {
               set value 0
               break
           }
       }
       if {$value == 1} {
           puts $file_handle "#define [get_driver_param_name $drv_string $arg] $value"
       }
   }		
   close $file_handle
}

#
# Define parameter as the maxm value for all connected peripherals
#
proc define_max {drv_handle file_name define_name arg} {
   # Open include file
   set file_handle [open_include_file $file_name]

   # Get all peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle] 

   # Check all parameters for all peripherals
   set value 0
   foreach periph $periphs {
       set thisvalue [get_param_value $periph $arg]
       if {$thisvalue > $value} {
           set value $thisvalue
       }
   }
   puts $file_handle "#define $define_name $value"
   close $file_handle
}
	
#
# Create configuration C file as required by Xilinx  drivers
#
proc define_config_file {drv_handle file_name drv_string args} {
    set args [get_exact_arg_list $args]
    set filename [file join "src" $file_name] 
    #Fix for CR 784758
    #file delete $filename
    set config_file [open $filename w]
    write_c_header $config_file "Driver configuration"    
    puts $config_file "#include \"xparameters.h\""
    puts $config_file "#include \"[string tolower $drv_string].h\""
    puts $config_file "\n/*"
    puts $config_file "* The configuration table for devices"
    puts $config_file "*/\n"
    set num_insts [get_driver_param_name $drv_string "NUM_INSTANCES"]
    puts $config_file [format "%s_Config %s_ConfigTable\[%s\] =" $drv_string $drv_string $num_insts]
    puts $config_file "\{"
    set periphs [get_common_driver_ips $drv_handle]     
    set start_comma ""
    foreach periph $periphs {
        puts $config_file [format "%s\t\{" $start_comma]
        set comma ""
        foreach arg $args {
            if {[string compare -nocase "DEVICE_ID" $arg] == 0} {
                puts -nonewline $config_file [format "%s\t\t%s,\n" $comma [get_ip_param_name $periph $arg]]
                continue
            }
            # Check if this is a driver parameter or a peripheral parameter
            set value [hsi get_property CONFIG.$arg $drv_handle]
            if {[llength $value] == 0} {
                set local_value [hsi get_property CONFIG.$arg $periph ]
                # If a parameter isn't found locally (in the current
                # peripheral), we will (for some obscure and ancient reason)
                # look in peripherals connected via point to point links
                if { [string compare -nocase $local_value ""] == 0} { 
                    set p2p_name [get_p2p_name $periph $arg]
                    if { [string compare -nocase $p2p_name ""] == 0} {
                        puts -nonewline $config_file [format "%s\t\t%s" $comma [get_ip_param_name $periph $arg]]
                    } else {
                        puts -nonewline $config_file [format "%s\t\t%s" $comma $p2p_name]
                    }
                } else {
                    puts -nonewline $config_file [format "%s\t\t%s" $comma [get_ip_param_name $periph $arg]]
                }
            } else {
                puts -nonewline $config_file [format "%s\t\t%s" $comma [get_driver_param_name $drv_string $arg]]
            }
            set comma ",\n"
        }
        puts -nonewline $config_file "\n\t\}"
        set start_comma ",\n"
    }
    puts $config_file "\n\};"

    puts $config_file "\n";

    close $config_file
}

#
# Create configuration C file as required by Xilinx Zynq drivers
# Similar to proc define_config_file, except that uses regsub
# to replace "S_AXI_" with ""
#
proc define_zynq_config_file {drv_handle file_name drv_string args} {
    set args [get_exact_arg_list $args]
   set filename [file join "src" $file_name] 
   #Fix for CR 784758
   #file delete $filename
   set config_file [open $filename w]
   write_c_header $config_file "Driver configuration"    
   puts $config_file "#include \"xparameters.h\""
   puts $config_file "#include \"[string tolower $drv_string].h\""
   puts $config_file "\n/*"
   puts $config_file "* The configuration table for devices"
   puts $config_file "*/\n"
   set num_insts [get_driver_param_name $drv_string "NUM_INSTANCES"]
   puts $config_file [format "%s_Config %s_ConfigTable\[%s\] =" $drv_string $drv_string $num_insts]
   puts $config_file "\{"
   set periphs [get_common_driver_ips $drv_handle]     
   set start_comma ""
   foreach periph $periphs {
       puts $config_file [format "%s\t\{" $start_comma]
       set comma ""
       foreach arg $args {
           # Check if this is a driver parameter or a peripheral parameter
           set value [hsi get_property CONFIG.$arg $drv_handle]
           if {[llength $value] == 0} {
            set local_value [hsi get_property CONFIG.$arg $periph ]
            # If a parameter isn't found locally (in the current
            # peripheral), we will (for some obscure and ancient reason)
            # look in peripherals connected via point to point links
            if { [string compare -nocase $local_value ""] == 0} { 
               set p2p_name [get_p2p_name $periph $arg]
               if { [string compare -nocase $p2p_name ""] == 0} {
                   set arg_name [get_ip_param_name $periph $arg]
                   regsub "S_AXI_" $arg_name "" arg_name
                   puts -nonewline $config_file [format "%s\t\t%s" $comma $arg_name]
               } else {
                   regsub "S_AXI_" $p2p_name "" p2p_name
                   puts -nonewline $config_file [format "%s\t\t%s" $comma $p2p_name]
               }
           } else {
               set arg_name [get_ip_param_name $periph $arg]
               regsub "S_AXI_" $arg_name "" arg_name
               puts -nonewline $config_file [format "%s\t\t%s" $comma $arg_name]
                   }
           } else {
               set arg_name [get_driver_param_name $drv_string $arg]
               regsub "S_AXI_" $arg_name "" arg_name
               puts -nonewline $config_file [format "%s\t\t%s" $comma $arg_name]
           }
           set comma ",\n"
       }
       puts -nonewline $config_file "\n\t\}"
       set start_comma ",\n"
   }
   puts $config_file "\n\};"

   puts $config_file "\n";

   close $config_file
}

#
# Add definitions in an include file.  Args must be name value pairs
#
proc define_with_names {drv_handle periph_handle file_name args} {
   set args [get_exact_arg_list $args]
   # Open include file
   set file_handle [open_include_file $file_name]

   foreach {lhs rhs} $args {
       set value [get_param_value $periph_handle $rhs]
       set value [format_addr_string $value $rhs]
       puts $file_handle "#define $lhs $value"
   }		
   close $file_handle
}

#
# Generate a C structure from an array
# "args" is variable no - fields of the array 
#
#proc xadd_struct {file_handle lib_handle struct_type struct_name array_name args} { 
#
#   set arrhandle [xget_handle $lib_handle "ARRAY" $array_name] 
#   set elements [xget_handle $arrhandle "ELEMENTS" "*"] 
#   set count 0 
#   set max_count [llength $elements] 
#   puts $file_handle "struct $struct_type $struct_name\[$max_count\] = \{" 
#
#   foreach ele $elements { 
#   incr count 
#   puts -nonewline $file_handle "\t\{" 
#   foreach field $args { 
#       set field_value [hsi get_property CONFIG.$field $ele] 
#       if { $field == [lindex $args end] } { 
#   	puts -nonewline $file_handle "$field_value" 
#       } else { 
#   	puts -nonewline $file_handle "$field_value," 
#       } 
#   } 
#   if {$count < $max_count} { 
#       puts $file_handle "\}," 
#   } else { 
#       puts $file_handle "\}" 
#   } 
#   } 
#   puts $file_handle "\}\;" 
#}

#
#---------------------------------------------------------------------------------------------
# Given a list of memory bank arguments, define them all in an include file.
# The "args" is a base, high address pairs of the memory banks
# For example:
# define_include_file_membank $drv_handle "xparameters.h" "C_MEM0_BASEADDR" "C_MEM0_HIGHADDR"
# generates :
# XPAR_MYEMC_MEM0_BASEADDR, XPAR_MYEMC_MEM1_HIGHADDR definitions in xparameters.h file
# Handles MHS/MPD parameters 
#---------------------------------------------------------------------------------------------
proc define_include_file_membank {drv_handle file_name args} {
   set args [get_exact_arg_list $args]

   # Get all peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle] 
   
   foreach periph $periphs {
        
       lappend newargs

       set len [llength $args]

       for { set i 0 } { $i <  $len} { incr i 2} {
           set base [lindex $args $i]
           set high [lindex $args [expr $i+1]]
           set baseval [hsi get_property CONFIG.$base $periph]
           set baseval [string map {_ ""} $baseval]
           # Check to see if value starts with 0b or 0x
           if {[string match -nocase 0b* $baseval]} {
            set baseval [convert_binary_to_hex $baseval]
           } else {
            set baseval [format "0x%08X" $baseval]
           }
           set highval [hsi get_property CONFIG.$high $periph]
           set highval [string map {_ ""} $highval]
           # Check to see if value starts with 0b or 0x
           if {[string match -nocase 0b* $highval]} {
            set highval [convert_binary_to_hex $highval]
           } else {
            set highval [format "0x%08X" $highval]
           }
           set baseval [format "%x" $baseval]
           set highval [format "%x" $highval]
           if {$highval > $baseval} {
            lappend newargs $base
            lappend newargs $high
           }	
       }
       define_membank $periph $file_name $newargs
       set newargs ""
   }
}

#---------------------------------------------------
# Generates the defn for a memory bank
# The prev fn takes in a list of memory bank args
#---------------------------------------------------
proc define_membank { periph file_name args } {
   set args [get_exact_arg_list $args]
   set newargs [lindex $args 0]
   
   # Open include file
   set file_handle [open_include_file $file_name]

   puts $file_handle "/* Definitions for peripheral [string toupper [hsi get_property NAME $periph]] */"
   
   foreach arg $newargs {
       set value [hsi get_property CONFIG.$arg $periph]
       set value [format_addr_string $value $arg]
       puts $file_handle "#define [get_ip_param_name $periph $arg] $value"
   }

   puts $file_handle "\n/******************************************************************/\n"
   close $file_handle
}


#----------------------------------------------------
# Find all possible address params for the
# given peripheral "periph"
#----------------------------------------------------
proc find_addr_params {periph} {
  
   set addr_params [list]

   #get the mem_ranges which belongs to this peripheral
   if { [llength $periph] != 0 } {
   set sw_proc_handle [hsi::get_sw_processor]
   set hw_proc_handle [hsi::get_cells -hier [hsi get_property hw_instance $sw_proc_handle]]
   set mem_ranges [hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$periph"]
   foreach mem_range $mem_ranges {
       set bparam_name [hsi get_property BASE_NAME $mem_range]
       set bparam_value [hsi get_property BASE_VALUE $mem_range]
       set hparam_name [hsi get_property HIGH_NAME $mem_range]
       set hparam_value [hsi get_property HIGH_VALUE $mem_range]

       # Check if already added
       set bposn [lsearch -exact $addr_params $bparam_name]
       set hposn [lsearch -exact $addr_params $hparam_name]
       if {$bposn > -1  || $hposn > -1 } {
           continue
       }
       lappend addr_params $bparam_name
       lappend addr_params $hparam_name
   }
   }
   return $addr_params
}

#----------------------------------------------------
# Defines all possible address params in the filename
# for all periphs that use this driver
#----------------------------------------------------
proc define_addr_params {drv_handle file_name} {
   
   set addr_params [list]

   # Open include file
   set file_handle [open_include_file $file_name]

   # Get all peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle] 

   # Print all parameters for all peripherals
   foreach periph $periphs {
   puts $file_handle ""
   puts $file_handle "/* Definitions for peripheral [string toupper [hsi get_property NAME $periph]] */"

   set addr_params ""
   set addr_params [find_addr_params $periph]

   foreach arg $addr_params {
       set value [get_param_value $periph $arg]
       if {$value != ""} {
           set value [format_addr_string $value $arg]
           puts $file_handle "#define [get_ip_param_name $periph $arg] $value"
       }
   }
   puts $file_handle ""
   }		
   puts $file_handle "\n/******************************************************************/\n"
   close $file_handle
}

#----------------------------------------------------
# Defines all non-reserved params in the filename
# for all periphs that use this driver
#----------------------------------------------------
proc define_all_params {drv_handle file_name} {
   
   set params [list]
   lappend reserved_param_list "C_DEVICE" "C_PACKAGE" "C_SPEEDGRADE" "C_FAMILY" "C_INSTANCE" "C_KIND_OF_EDGE" "C_KIND_OF_LVL" "C_KIND_OF_INTR" "C_NUM_INTR_INPUTS" "C_MASK" "C_NUM_MASTERS" "C_NUM_SLAVES" "C_LMB_AWIDTH" "C_LMB_DWIDTH" "C_LMB_MASK" "C_LMB_NUM_SLAVES" "INSTANCE" "HW_VER"

   # Open include file
   set file_handle [open_include_file $file_name]

   # Get all peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle] 
  
   # Print all parameters for all peripherals
   foreach periph $periphs {
       puts $file_handle ""
       puts $file_handle "/* Definitions for peripheral [string toupper [hsi get_property NAME $periph]] */"
       set params ""
       set params [common::hsi list_property $periph CONFIG.*]
       foreach param $params {
           set param_name [string range $param [string length "CONFIG."] [string length $param]]
           set posn [lsearch -exact $reserved_param_list $param_name]
           if {$posn == -1 } {
               set param_value [hsi get_property $param $periph]
                if {$param_value != ""} {
                    set param_value [format_addr_string $param_value $param_name]
                    puts $file_handle "#define [get_ip_param_name $periph $param_name] $param_value"
                }
           }
       }
       puts $file_handle "\n/******************************************************************/\n"
   }		
   close $file_handle
}

#
# define_canonical_xpars - Used to print out canonical defines for a driver. 
# Given a list of arguments, define each as a canonical constant name, using
# the driver name, in an include file.
#
proc define_canonical_xpars {drv_handle file_name drv_string args} {
    set args [get_exact_arg_list $args]
   # Open include file
   set file_handle [open_include_file $file_name]

   # Get all the peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle]

   # Get the names of all the peripherals connected to this driver
   foreach periph $periphs {
       set peripheral_name [string toupper [hsi get_property NAME $periph]]
       lappend peripherals $peripheral_name
   }

   # Get possible canonical names for all the peripherals connected to this
   # driver
   set device_id 0
   foreach periph $periphs {
       set canonical_name [string toupper [format "%s_%s" $drv_string $device_id]]
       lappend canonicals $canonical_name
       
       # Create a list of IDs of the peripherals whose hardware instance name
       # doesn't match the canonical name. These IDs can be used later to
       # generate canonical definitions
       if { [lsearch $peripherals $canonical_name] < 0 } {
           lappend indices $device_id
       }
       incr device_id
   }

   set i 0
   foreach periph $periphs {
       set periph_name [string toupper [hsi get_property NAME $periph]]

       # Generate canonical definitions only for the peripherals whose
       # canonical name is not the same as hardware instance name
       if { [lsearch $canonicals $periph_name] < 0 } {
           puts $file_handle "/* Canonical definitions for peripheral $periph_name */"
           set canonical_name [format "%s_%s" $drv_string [lindex $indices $i]]

           foreach arg $args {
               set lvalue [get_driver_param_name $canonical_name $arg]

               # The commented out rvalue is the name of the instance-specific constant
               # set rvalue [get_ip_param_name $periph $arg]
               # The rvalue set below is the actual value of the parameter
               set rvalue [get_param_value $periph $arg]
               if {[llength $rvalue] == 0} {
                   set rvalue 0
               }
               set rvalue [format_addr_string $rvalue $arg]
   
               puts $file_handle "#define $lvalue $rvalue"

           }
           puts $file_handle ""
           incr i
       }
   }

   puts $file_handle "\n/******************************************************************/\n"
   close $file_handle
}

#-----------------------------------------------------------------------------
# define_zynq_canonical_xpars - Used to print out canonical defines for a driver. 
# Similar to proc define_config_file, except that uses regsub to replace "S_AXI_"
# with "".
#-----------------------------------------------------------------------------
proc define_zynq_canonical_xpars {drv_handle file_name drv_string args} {
    set args [get_exact_arg_list $args]
   # Open include file
   set file_handle [open_include_file $file_name]

   # Get all the peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle]

   # Get the names of all the peripherals connected to this driver
   foreach periph $periphs {
       set peripheral_name [string toupper [hsi get_property NAME $periph]]
       lappend peripherals $peripheral_name
   }

   # Get possible canonical names for all the peripherals connected to this
   # driver
   set device_id 0
   foreach periph $periphs {
       set canonical_name [string toupper [format "%s_%s" $drv_string $device_id]]
       lappend canonicals $canonical_name
       
       # Create a list of IDs of the peripherals whose hardware instance name
       # doesn't match the canonical name. These IDs can be used later to
       # generate canonical definitions
       if { [lsearch $peripherals $canonical_name] < 0 } {
           lappend indices $device_id
       }
       incr device_id
   }

   set i 0
   foreach periph $periphs {
       set periph_name [string toupper [hsi get_property NAME $periph]]

       # Generate canonical definitions only for the peripherals whose
       # canonical name is not the same as hardware instance name
       if { [lsearch $canonicals $periph_name] < 0 } {
           puts $file_handle "/* Canonical definitions for peripheral $periph_name */"
           set canonical_name [format "%s_%s" $drv_string [lindex $indices $i]]

           foreach arg $args {
               set lvalue [get_driver_param_name $canonical_name $arg]
               regsub "S_AXI_" $lvalue "" lvalue

               # The commented out rvalue is the name of the instance-specific constant
               # set rvalue [get_ip_param_name $periph $arg]
               # The rvalue set below is the actual value of the parameter
               set rvalue [get_param_value $periph $arg]
               if {[llength $rvalue] == 0} {
                   set rvalue 0
               }
               set rvalue [format_addr_string $rvalue $arg]
   
               puts $file_handle "#define $lvalue $rvalue"

           }
           puts $file_handle ""
           incr i
       }
   }

   puts $file_handle "\n/******************************************************************/\n"
   close $file_handle
}

#----------------------------------------------------
# Define processor params using IP type
#----------------------------------------------------
proc define_processor_params {drv_handle file_name} {
   set sw_proc_handle [hsi::get_sw_processor]
   set proc_name [hsi get_property hw_instance $sw_proc_handle]
   set hw_proc_handle [hsi::get_cells -hier $proc_name ]

   set lprocs [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]

   set params [list]
   lappend reserved_param_list "C_DEVICE" "C_PACKAGE" "C_SPEEDGRADE" "C_FAMILY" "C_INSTANCE" "C_KIND_OF_EDGE" "C_KIND_OF_LVL" "C_KIND_OF_INTR" "C_NUM_INTR_INPUTS" "C_MASK" "C_NUM_MASTERS" "C_NUM_SLAVES" "C_DCR_AWIDTH" "C_DCR_DWIDTH" "C_DCR_NUM_SLAVES" "C_LMB_AWIDTH" "C_LMB_DWIDTH" "C_LMB_MASK" "C_LMB_NUM_SLAVES" "C_OPB_AWIDTH" "C_OPB_DWIDTH" "C_OPB_NUM_MASTERS" "C_OPB_NUM_SLAVES" "C_PLB_AWIDTH" "C_PLB_DWIDTH" "C_PLB_MID_WIDTH" "C_PLB_NUM_MASTERS" "C_PLB_NUM_SLAVES" "INSTANCE"
   
   # Open include file
   set file_handle [open_include_file $file_name]
   
   # Get all peripherals connected to this driver
   set periphs [get_common_driver_ips $drv_handle] 
   # Print all parameters for all peripherals
   foreach periph $periphs {
   
       set name [hsi get_property IP_NAME $periph]
       set name [string toupper $name]
       set iname [hsi get_property NAME $periph]
   #--------------------------------	
   # Set CPU ID & CORE_CLOCK_FREQ_HZ
   #--------------------------------		
   set id 0
   foreach processor $lprocs {
       if {[string compare -nocase $processor $iname] == 0} {
        set pname [format "XPAR_%s_ID" $name]
        puts $file_handle "#define XPAR_CPU_ID $id"
        puts $file_handle "#define $pname $id"
       }
       incr id
   }

   set params ""
   set params [common::hsi list_property $periph CONFIG.*]

   foreach param $params {
       set param_name [string toupper [string range $param [string length "CONFIG."] [string length $param]]]
       set posn [lsearch -exact $reserved_param_list $param_name]
       if {$posn == -1 } {
        set param_value [hsi get_property  $param $periph]
       
        if {$param_value != ""} {
            set param_value [format_addr_string $param_value $param_name]
            set name [hsi get_property IP_NAME $periph]
            set name [string toupper $name]
            set name [format "XPAR_%s_" $name]
            set param [string toupper $param_name]
            if {[string match C_* $param_name]} {
                set name [format "%s%s" $name [string range $param_name 2 end]]
            } else {
                set name [format "%s%s" $name $param_name]
            }
            if {[string compare -nocase $param "HW_VER"] == 0} {
                puts $file_handle "#define [string toupper $name] \"$param_value\""
            } else {
                puts $file_handle "#define [string toupper $name] $param_value"
            }
        }
       }
   }
   
   puts $file_handle "\n/******************************************************************/\n"
   }		
   close $file_handle
}

#
# Get the memory range of IP for current processor
#
proc get_ip_mem_ranges {periph} {
	puts "Inside get_ip_mem_ranges : $periph"
    set sw_proc_handle [hsi::get_sw_processor]
    set hw_proc_handle [hsi::get_cells -hier [hsi get_property hw_instance $sw_proc_handle]]
	if { [llength $periph] != 0 } {
    set mem_ranges [hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$periph"]
	}
    return $mem_ranges
}

#
# Handle the stdin parameter of a processor
#
proc handle_stdin_proc {drv_handle} {

   set stdin [hsi get_property CONFIG.stdin $drv_handle]
   set sw_proc_handle [hsi::get_sw_processor]
   set hw_proc_handle [hsi::get_cells -hier [hsi get_property hw_instance $sw_proc_handle]]

   set processor [hsi get_property hw_instance $sw_proc_handle]
   if {[llength $stdin] == 1 && [string compare -nocase "none" $stdin] != 0} {
       set stdin_drv_handle [hsi::get_drivers -filter "HW_INSTANCE==$stdin"]
       if {[llength $stdin_drv_handle] == 0} {
           error "No driver for stdin peripheral $stdin. Check the following reasons: \n 1. $stdin is not accessible from processor $processor.\n 2. No Driver block is defined for $stdin in MSS file." "" "hsi_error"
           return
       }

       set interface_handle [hsi::get_sw_interfaces -of_objects $stdin_drv_handle -filter "NAME==stdin"]
       if {[llength $interface_handle] == 0} {
           error "No stdin interface available for driver for peripheral $stdin" "" "hsi_error"
       }

       set inbyte_name [hsi get_property FUNCTION.inbyte $interface_handle ]
       if {[llength $inbyte_name] == 0} {
         error "No inbyte function available for driver for peripheral $stdin" "" "hsi_error"
       }
       set header [hsi get_property PROPERTY.header $interface_handle]
       if {[llength $header] == 0} {
         error "No header property available in stdin interface for driver for peripheral $stdin" "" "hsi_error"
       }
       set config_file [open "src/inbyte.c" w]
       puts $config_file "\#include \"xparameters.h\"" 
       puts $config_file [format "\#include \"%s\"\n" $header]
       puts $config_file "\#ifdef __cplusplus"
       puts $config_file "extern \"C\" {"
       puts $config_file "\#endif"
       puts $config_file "char inbyte(void);"
       puts $config_file "\#ifdef __cplusplus"
       puts $config_file "}"
       puts $config_file "\#endif \n"
       puts $config_file "char inbyte(void) {"
       puts $config_file [format "\t return %s(STDIN_BASEADDRESS);" $inbyte_name]
       puts $config_file "}"
       close $config_file
       set config_file [open_include_file "xparameters.h"]
       set stdin_mem_range [hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdin && IS_DATA==1"]
       #check ifstdin_mem_range is empty, if so give error 
       #set stdin_mem_range [hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdin"]
       if { [llength $stdin_mem_range] > 1 } {
           set stdin_mem_range [hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdin&& (BASE_NAME==C_BASEADDR||BASE_NAME==C_S_AXI_BASEADDR)"]
       }
       if { [llength $stdin_mem_range] < 1 } {
           error "No mem range of type DATA found." "" "hsi_error"
	   return
       }
       set base_name [hsi get_property BASE_NAME $stdin_mem_range]
       set base_value [lindex [hsi get_property BASE_VALUE $stdin_mem_range] 0]
       puts $config_file "\#define STDIN_BASEADDRESS [format_addr_string $base_value $base_name]"
       close $config_file
   }
}


#
# Handle the stdout parameter of a processor
#
proc handle_stdout {drv_handle} {
   set stdout [hsi get_property CONFIG.stdout $drv_handle]
   set sw_proc_handle [hsi::get_sw_processor]
   set hw_proc_handle [hsi::get_cells -hier [hsi get_property hw_instance $sw_proc_handle]]
   set processor [hsi get_property NAME $hw_proc_handle]

   if {[llength $stdout] == 1 && [string compare -nocase "none" $stdout] != 0} {
       set stdout_drv_handle [hsi::get_drivers -filter "HW_INSTANCE==$stdout"]
       if {[llength $stdout_drv_handle] == 0} {
           error "No driver for stdout peripheral $stdout. Check the following reasons: \n 1. $stdout is not accessible from processor $processor.\n 2. No Driver block is defined for $stdout in MSS file." "" "hsi_error"
           return
       }
       
       set interface_handle [hsi::get_sw_interfaces -of_objects $stdout_drv_handle -filter "NAME==stdout"]
       if {[llength $interface_handle] == 0} {
         error "No stdout interface available for driver for peripheral $stdout" "" "hsi_error"
       }
       set outbyte_name [hsi get_property FUNCTION.outbyte $interface_handle]
       if {[llength $outbyte_name] == 0} {
         error "No outbyte function available for driver for peripheral $stdout" "" "hsi_error"
       }
       set header [hsi get_property PROPERTY.header $interface_handle]
       if {[llength $header] == 0} {
         error "No header property available in stdout interface for driver for peripheral $stdout" "" "hsi_error"
       }
       set config_file [open "src/outbyte.c" w]
       puts $config_file "\#include \"xparameters.h\""
       puts $config_file [format "\#include \"%s\"\n" $header ]
       puts $config_file "\#ifdef __cplusplus"
       puts $config_file "extern \"C\" {"
       puts $config_file "\#endif"
       puts $config_file "void outbyte(char c); \n"
       puts $config_file "\#ifdef __cplusplus"
       puts $config_file "}"
       puts $config_file "\#endif \n"
       puts $config_file "void outbyte(char c) {"
       puts $config_file [format "\t %s(STDOUT_BASEADDRESS, c);" $outbyte_name]
       puts $config_file "}"
       close $config_file
       set config_file [open_include_file "xparameters.h"]
       set stdout_mem_range [hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdout && IS_DATA==1" ]
       #Check if stdout_mem_range is empty, if so give error
       if { [llength $stdout_mem_range] > 1 } {
           set stdout_mem_range [hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdout&& (BASE_NAME==C_BASEADDR||BASE_NAME==C_S_AXI_BASEADDR)"]
       }
       if { [llength $stdout_mem_range] < 1 } {
           error "No mem range of type DATA found." "" "hsi_error"
	   return
       }
       set base_name [hsi get_property BASE_NAME $stdout_mem_range]
       set base_value [lindex [hsi get_property BASE_VALUE $stdout_mem_range] 0]
       puts $config_file "\#define STDOUT_BASEADDRESS [format_addr_string $base_value $base_name]"
       close $config_file
   }
}

proc get_common_driver_ips {driver_handle} {
	puts "inside"
  set retlist ""
  set drs { }
  set class [hsi get_property CLASS $driver_handle]
  if { [string match -nocase $class "sw_proc"] } {
      set hw_instance [hsi get_property HW_INSTANCE $driver_handle]
      lappend retlist [hsi::get_cells -hier $hw_instance]
  } else {
      set driver_name [hsi get_property NAME $driver_handle]
	  if { [llength $driver_name] != 0 } {
      set drs [get_drivers_sw -filter "NAME==$driver_name"]
      foreach driver $drs {
           set hw_instance [hsi get_property hw_instance $driver]
           set cell [hsi::get_cells -hier $hw_instance]
           lappend retlist $cell
      }
  }
  }
  return $retlist
}

#
# this API return true if it is interrupting the current processor
#
proc is_pin_interrupting_current_proc { periph_name intr_pin_name} {
    set ret 0
    set periph [hsi::get_cells -hier "$periph_name"] 
    if { [llength $periph] != 1 } {
        return $ret
    }
    #get the list of connected 
    set intr_cntrls [get_connected_intr_cntrl "$periph_name" "$intr_pin_name"]
    foreach intr_cntrl $intr_cntrls {
        if { [is_ip_interrupting_current_proc $intr_cntrl] == 1} {
            return 1
        }
    }
   return [special_handling_for_ps7_interrupt $periph_name]
}

#
# this API return true if any interrupt controller is connected to processor 
#and is available processor memory map
#
proc get_current_proc_intr_cntrl { } {
    set current_proc [hsi get_property HW_INSTANCE [hsi::get_sw_processor] ]
    set proc_handle [hsi::get_cells -hier $current_proc]
    set proc_ips [get_proc_slave_periphs $proc_handle]
    foreach ip $proc_ips {
        if {  [is_intr_cntrl $ip] == 1  
            && [is_ip_interrupting_current_proc $ip]} {
            return $ip
        }
    }
    Return ""
}

#
# this API return true if any at least one interrupt port of IP is reaching 
# to current processor
#
proc is_ip_interrupting_current_proc { periph_name} {
   set ret 0 
   set periph [hsi::get_cells -hier "$periph_name"]
   if { [llength $periph] != 1}  {
       return $ret
   }
   if { [is_intr_cntrl $periph_name] == 1} {

        set cntrl_driver [get_drivers_sw $periph_name]
	if {[string match -nocase $cntrl_driver "generic"]} {
		set cntrl_driver ""
	}
        #Interrupt controller should have a driver for current sw design
        if { [llength $cntrl_driver] != 1} {
            return 0
        }
        #set current_proc [hsi get_property HW_INSTANCE [hsi::get_sw_processor]]
	set proc_list "psv_cortexa72 psu_cortexa53 ps7_cortexa9"
#        set current_proc "psv_cortexa72_0"
#	set current_proc [get_hw_family]
        set intr_pin [hsi::get_pins -of_objects $periph "Irq"]
        if { [llength $intr_pin] != 0} {
            set sink_pins [get_sink_pins $intr_pin]
            foreach sink_pin $sink_pins {
                set connected_ip [hsi::get_cells -of_objects $sink_pin]
                #Connected interface should be IP Instance
                #Connected IP should be current_processor
                set ip_name [hsi get_property IP_NAME $connected_ip]
		if {[lsearch -nocase $proc_list $ip_name] >= 0} {
                    return 1
                }
            }
        } else {
            #special handling for iomodule interrupt as currently we do not have
            #vlnv property into interface object
            set connected_intf [get_connected_intf $periph "INTC_Irq"]
            if { [llength $connected_intf] != 0 } {
                set connected_ip [hsi::get_cells -of_objects $connected_intf] 
                #Connected interface should be IP Instance
                #Connected IP should be current_processor
                set ip_name [hsi get_property IP_NAME $connected_ip]
		if {[lsearch -nocase $proc_list $ip_name] >= 0} {
                    return 1
                }
            }
        }
        if { [llength $intr_pin] == 0 } {
	        set intr_pin [hsi::get_pins -of_objects $periph -filter "TYPE==INTERRUPT&&DIRECTION==O"]
        }
        if { [llength $intr_pin] != 0} {
            set sink_pins [get_sink_pins $intr_pin]
            foreach sink_pin $sink_pins {
                set connected_ip [hsi::get_cells -of_objects $sink_pin]
                #Connected interface should be IP Instance
                #Connected IP should be current_processor
                set ip_name [hsi get_property IP_NAME $connected_ip]
		if {[lsearch -nocase $proc_list $ip_name] >= 0} {
#			puts "return3"
                    return 1
                }
            }
        }
   } else {
       set intrs [hsi::get_pins -of_objects $periph -filter "TYPE==INTERRUPT&&DIRECTION==O"]
       foreach intr $intrs {
           set intr_name [hsi get_property NAME $intr]
           set flag [is_pin_interrupting_current_proc "$periph_name" "$intr_name"]
           if { $flag } {
               return 1
           }
       }
   }
   #TODO: Special hard coding for ps7 internal
   return [special_handling_for_ps7_interrupt $periph_name]
}

################################################################################
## DTS Related common utils
################################################################################

proc add_new_child_node { parent node_name } {
    set node [hsi::get_nodes -of_objects $parent $node_name]
    if { [llength $node] } {
        hsi::delete_objs $node
    }
    set node [hsi::create_node  $node_name $parent]
    return $node
}
proc add_new_property { node  property type value } {
    set prop [hsi::create_comp_param $property $value $node]
    common::set_property CONFIG.TYPE $type $prop
    return $prop
}

proc add_new_dts_param { node  param_name param_value param_type {param_decription ""} } {
	if { $param_type != "boolean" && $param_type != "comment" && [llength $param_value] == 0 } {
		error "param_value can only be empty if the param_type is boolean, value is must for other data types"
	}
	if { $param_type == "boolean" && [llength $param_value] != 0 } {
                error "param_value can only be empty if the param_type is boolean"
        }
	common::set_property $param_name $param_value $node
	set param [hsi get_property CONFIG.$param_name $node]
	common::set_property TYPE $param_type $param
	common::set_property DESC $param_decription $param
    return $param
}

proc add_driver_properties { node driver } {
	set props [hsi::get_comp_params -of_objects $driver]
	foreach prop $props {
	    set name [hsi get_property NAME $prop]
	    set value [hsi get_property VALUE $prop]
	    set type [hsi get_property CONFIG.TYPE $prop]
	    add_new_dts_param $node "$name" "$value" "$type"
	}
}

proc get_os_parameter_value { param_name } {
    set value ""
    set global_params_node [hsi::get_nodes -of_objects [::hsi::get_os] "global_params"]
    if { [llength $global_params_node] } {
        set value [hsi get_property CONFIG.$param_name $global_params_node]
    }
    return $value
}
proc set_os_parameter_value { param_name param_value } {
    set global_params_node [hsi::get_nodes -of_objects [::hsi::get_os] "global_params"]
    if { [llength $global_params_node] == 0 } {
        set global_params_node [add_new_child_node [hsi::get_os] "global_params"]
    }
    common::set_property CONFIG.$param_name "$param_value" $global_params_node
}
proc get_or_create_child_node { parent node_name } {
    set node [hsi::get_nodes -of_objects $parent $node_name]
    if { [llength $node] == 0 } {
        set node [hsi::create_node $node_name $parent]
    }
    return $node
}

proc get_dtg_interrupt_info { ip_name intr_port_name } {
    set intr_info ""
    set ip [hsi::get_cells -hier $ip_name]
    if { [llength $ip] == 0} {
        return $intr_info
    }
    if { [is_pin_interrupting_current_proc $ip_name "$intr_port_name" ] != 1 }  {
        return $intr_info
    }
    set intr_id [get_interrupt_id $ip_name $intr_port_name]
    if { $intr_id  == -1 } {
        return $intr_info
    }
    set intc [get_connected_intr_cntrl $ip_name $intr_port_name]
    set intr_type [get_dtg_interrupt_type $intc $ip $intr_port_name] 
    if { [string match "[hsi get_property IP_NAME $intc]" "ps7_scugic"] } {
        if { $intr_id > 32 } {
            set intr_id [expr $intr_id -32]
        }
        set intr_info "0 $intr_id $intr_type"
    } else {
        set intr_info "0 $intr_id $intr_type"
    }
    return $intr_info
}

proc get_dtg_interrupt_type { intc_name ip_name port_name } {
    set intc [hsi::get_cells -hier $intc_name]
    set ip [hsi::get_cells -hier $ip_name]
    if {[llength $intc] == 0 && [llength $ip] == 0} {
        return -1
    }
    set intr_pin [hsi::get_pins -of_objects $ip $port_name]
    set sensitivity ""
    if { [llength $intr_pin] } {
        set sensitivity [hsi get_property SENSITIVITY $intr_pin]
    }
    set intc_type [hsi get_property IP_NAME $intc ]
    if { [string match -nocase $intc_type "ps7_scugic"] } {
		# Follow the openpic specification
		if { [string match -nocase $sensitivity "EDGE_FALLING"] } {
			return 2;
		} elseif { [string match -nocase $sensitivity "EDGE_RISING"] } {
			return 1;
		} elseif { [string match -nocase $sensitivity "LEVEL_HIGH"] } {
			return 4;
		} elseif { [string match -nocase $sensitivity "LEVEL_LOW"] } {
			return 8;
		}
	} else {
		# Follow the openpic specification
		if { [string match -nocase $sensitivity "EDGE_FALLING"] } {
			return 3;
		} elseif { [string match -nocase $sensitivity "EDGE_RISING"]  } {
			return 0;
		} elseif { [string match -nocase $sensitivity "LEVEL_HIGH"]  } {
			return 2;
		} elseif { [string match -nocase $sensitivity "LEVEL_LOW"]  } {
			return 1;
		}
	}
    return -1
}
proc get_interrupt_parent_proc {  ip_name port_name } {
    set intc [get_connected_intr_cntrl $ip_name $port_name]
    return $intc
}

proc get_connected_stream_ip { ip_name intf_name } {
    set ip [hsi::get_cells -hier $ip_name]
    if { [llength $ip] == 0 } {
        return ""
    }
    set intf [hsi::get_intf_pins -of_objects $ip "$intf_name"] 
    if { [llength $intf] == 0 } {
        return ""
    }
    set intf_type [hsi get_property TYPE $intf]

    set intf_net [hsi::get_intf_nets -of_objects $intf]
    if { [llength $intf_net] == 0 } {
        return ""
    }
    set connected_intf_pins [get_other_intf_pin $intf_net $intf] 
    set connected_intf_pin [get_intf_pin_oftype $connected_intf_pins $intf_type 0]
    
    if { [llength $connected_intf_pin] } {
        set connected_ip [hsi::get_cells -of_objects $connected_intf_pin]
        return $connected_ip
    }
    return ""
}

# This API returns the interrupt ID of a IP Pin
# Usecase: to get the ID of a top level interrupt port, provide empty string for ip_name
# Usecase: If port width port than 1 bit, then it will return multiple interrupts ID with ":" seperated
proc get_interrupt_id { ip_name port_name } {
    set ret -1
    set periph ""
    set intr_pin ""
    if { [llength $port_name] == 0 } {
        return $ret
    }

    if { [llength $ip_name] != 0 } {
        #This is the case where IP pin is interrupting
        set periph [hsi::get_cells -hier -filter "NAME==$ip_name"]
        if { [llength $periph] == 0 } {
            return $ret
        }
        set intr_pin [hsi::get_pins -of_objects $periph -filter "NAME==$port_name"]
        if { [llength $intr_pin] == 0 } {
            return $ret
        }
        set pin_dir [hsi get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "I"] } {
          return $ret
        }
    } else {
        #This is the case where External interrupt port is interrupting
        set intr_pin [hsi::get_ports $port_name]
        if { [llength $intr_pin] == 0 } {
            return $ret
        }
        set pin_dir [hsi get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "O"] } {
          return $ret
        }
    }

    set intc_periph [get_connected_intr_cntrl $ip_name $port_name]
    if { [llength $intc_periph]  ==  0 } {
        return $ret
    }

    set intc_type [hsi get_property IP_NAME $intc_periph]
    set irqid [hsi get_property IRQID $intr_pin]
    if { [llength $irqid] != 0 && [string match -nocase $intc_type "ps7_scugic"] } {
        set irqid [split $irqid ":"]
        return $irqid
    }

    # For zynq the intc_src_ports are in reverse order
    if { [string match -nocase "$intc_type" "ps7_scugic"]  } {
        set ip_param [hsi get_property CONFIG.C_IRQ_F2P_MODE $intc_periph]
        set ip_intr_pin [hsi::get_pins -of_objects $intc_periph "IRQ_F2P"]
        if { [string match -nocase "$ip_param" "REVERSE"] } {
            set intc_src_ports [lreverse [get_intr_src_pins $ip_intr_pin]]
        } else {
            set intc_src_ports [get_intr_src_pins $ip_intr_pin]
        }
        set total_intr_count -1
        foreach intc_src_port $intc_src_ports {
            set intr_periph [hsi::get_cells -of_objects $intc_src_port]
            set intr_width [get_port_width $intc_src_port]
            if { [llength $intr_periph] } {
                #case where an a pin of IP is interrupt
                if {[hsi get_property IS_PL $intr_periph] == 0} {
                    continue
                }
            }
            set total_intr_count [expr $total_intr_count + $intr_width]
        }
    } else  {
        set intc_src_ports [get_interrupt_sources $intc_periph]
    }

    #Special Handling for cascading case of axi_intc Interrupt controller
    set cascade_id 0
    if { [string match -nocase "$intc_type" "axi_intc"] } {
        set cascade_id [get_intc_cascade_id_offset $intc_periph]
    }

    set i $cascade_id
    set found 0
    foreach intc_src_port $intc_src_ports {
        if { [llength $intc_src_port] == 0 } {
            incr i
            continue
        }
        set intr_width [get_port_width $intc_src_port]
        set intr_periph [hsi::get_cells -of_objects $intc_src_port]
        if { [string match -nocase $intc_type "ps7_scugic"] && [llength $intr_periph]} {
            if {[hsi get_property IS_PL $intr_periph] == 0 } {
                continue
            }
        }
        if { [string compare -nocase "$port_name"  "$intc_src_port" ] == 0 } {
            if { [string compare -nocase "$intr_periph" "$periph"] == 0 } {
                set ret $i
                set found 1
                break
            }
        }
        set i [expr $i + $intr_width]
    }

    # interrupt source not found, this could be case where IP interrupt is connected
    # to core0/core1 nFIQ nIRQ of scugic 
    if { $found == 0 && [string match -nocase $intc_type "ps7_scugic"]} {
        set sink_pins [get_sink_pins $intr_pin]
        lappend intr_pin_name;
        foreach sink_pin $sink_pins {
            set connected_ip [hsi::get_cells -of_objects $sink_pin]
            set ip_name [hsi get_property NAME $connected_ip]
            if { [string match -nocase "$ip_name" "ps7_scugic"] == 0 } {
                set intr_pin_name $sink_pin
            }
        }
        if {[string match -nocase "Core1_nIRQ" $sink_pin] || [string match -nocase "Core0_nIRQ" $sink_pin] } {
            set ret 31
        } elseif {[string match -nocase "Core0_nFIQ" $sink_pin] || [string match -nocase "Core1_nFIQ" $sink_pin] } {
           set ret 28
        }
    }

    set port_width [get_port_width $intr_pin]
    set tempret $ret
    set lastadded 0
    set ps7_scugic_flow 0
    set i 1
    for {set i 1 } { $i <= $port_width } { incr i } {
      if { [string match -nocase $intc_type "ps7_scugic"] && $found == 1  } {
        set ps7_scugic_flow 1
        set ip_param [hsi get_property CONFIG.C_IRQ_F2P_MODE $intc_periph]
        if { [string compare -nocase "$ip_param" "DIRECT"]} {
            # if (total_intr_count - id) is < 16 then it needs to be subtracted from 76 
            # and if (total_intr_count - id) < 8 it needs to be subtracted from 91
            if { $lastadded == 0} {
              set ret {}
              set tempret [expr $total_intr_count -$tempret + $lastadded]
            } else {
              set tempret [expr -$tempret + $lastadded]
            }
            if { $tempret < 8 } {
                set tempret [expr 91 - $tempret]
                set lastadded 91
            } elseif { $tempret < 16} {
                set tempret [expr 68 - ${tempret} + 8 ]
                set lastadded [expr 68 + 8]
            }
        } else {
            # if id is < 8 then it needs to be added to 61 
            # and if id < 16 it needs to be added to 76
            if { $lastadded == 0} {
              set ret {}
            }
            set limit [expr $tempret - $lastadded]
            if { $limit < 8 } {
                set tempret [expr $limit + 61]
                set lastadded 61
            } elseif { $limit < 16} {
                set tempret [expr $limit + 84 - 8]
                set lastadded [expr 84 - 8]
            }
        }
      }
      if { $lastadded != 0} {
        lappend ret $tempret
        set tempret [expr $tempret + 1]
      }
      if { $ps7_scugic_flow == 0 && $i < $port_width} {
       lappend ret [expr $tempret + 1]
       incr tempret
      }
    }
    return $ret
}

proc get_connected_bus { periph_name intfs_pin} {
	set bus ""
	if { [llength [hsi::get_cells -hier $periph_name]] == 0 } {
		return ""
	}
	set pin [hsi::get_intf_pins -of_objects [::hsi::get_cells -hier $periph_name] $intfs_pin]
	if { $pin == "" } {
		return ""
	}
	
	set version [hsi get_property VIVADO_VERSION [hsi::current_hw_design]]
	if { [llength $version] <= 0 } {
		return ""
	}
	set is_pl [hsi get_property IS_PL [hsi::get_cells -hier $periph_name]]
	set is_ps true
	if { [string match -nocase $is_pl "true"] || [string match -nocase $is_pl "1"]} {
		set is_ps false
	}
	if { $version < 2014.4 || $is_ps} {
		#for old type of designs.
		set intf_pins [hsi::get_intf_nets -of_objects $pin]
		if { [llength $intf_pins] == 0} {
			return ""
		}
		if { [llength [hsi::get_cells -hier $intf_pins]] == 0} {
			return ""
		}
		set type [hsi get_property IP_TYPE [hsi::get_cells -hier $intf_pins]]
		if { $type == "BUS" } {
			set bus $intf_pins
			return $bus
		}
	} elseif { [llength $version] > 0 && $version >= 2014.4 } {
        #for new type of designs.
		set intf_nets [hsi::get_intf_nets -of_objects $pin]
		if { [llength $intf_nets] == 0} {
			return ""
		}
		set got_pins [hsi::get_intf_pins -of_objects $intf_nets]
		if { [llength $got_pins] == 0} {
			return ""
		}
		set second_pin [lindex $got_pins 0]
		if { [string match -nocase $second_pin $intfs_pin] } {
			set second_pin [lindex $got_pins 1]
		}
		set type [hsi get_property IP_TYPE [hsi::get_cells -of_objects $second_pin]]
		if { $type == "BUS" } {
			set bus [hsi::get_cells -of_objects $second_pin]
			return $bus
		}
	}
	return $bus
}

proc get_rp_rm_for_drv { drv_handle } {

	if { [llength $drv_handle ] == 0 } {
		return ""
	}
	set config [hsi::current_pr_configuration]
	if { [llength $config] == 0 } {
		return ""
	}
	set mappingProp [hsi get_property PARTITION_CELL_RMS $config]
	set name [hsi get_property NAME $config]

	set bdcvarmaps [split $mappingProp ";"]
	set mappingSize [llength $bdcvarmaps ]
	foreach bdcvarmap $bdcvarmaps {

		if { [llength $bdcvarmap ] == 0 } {
			continue;
		}
		#puts "!!!!  Processing mapping : $bdcvarmap"
		set bdcvar [split $bdcvarmap ":"]
		set bdc [lindex $bdcvar 0]
		set var [lindex $bdcvar 1]
		#puts "!!!! BDC : $bdc"
		#puts "!!!! var : $var"

		hsi::current_hw_instance $bdc

		set isPresent [hsi::get_cells -hier $drv_handle]
		#puts "isPresent : $isPresent"
		#change back the current hw instance to top
		hsi::current_hw_instance  
		if { [llength $isPresent  ] == 0 } {
			continue;
		}
		#puts " -----------------------------------------------"
		#puts "!!!! *** driver : $drv_handle will go into file :==>>> ${bdc}_${var}.dtsi ****"
		#puts " -----------------------------------------------"
		set fileName "${bdc}_${var}.dtsi"
		#puts " filename : $fileName"
		#return $fileName
		return [list $bdc $var $name ];

	}
	#puts "Driver not found in config: [hsi get_property name $config]"
        return ""

}
