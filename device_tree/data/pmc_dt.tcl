#
# (C) Copyright 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

global plm_supported_ips
global ps_uart_ip_names
global mdm_uart_ip_names
global ipi_ip_names
global pmc_ip_names

set pmc_ip_names {"psv_pmc" "psx_pmc" "pmc"}

# UART and MDM IPs are needed to define the serial peripheral. MDM is used for no PS UART cases
# This mdm uses the uartlite driver.
set ps_uart_ip_names {"psv_sbsauart" "psx_sbsauart" "sbsauart"}
set mdm_uart_ip_names {"psv_pmc_ppu1_mdm" "psx_pmc_ppu1_mdm" "pmc_ppu1_mdm"}

# IPI has a different mechanism to find out the required address map. This doesn't come from
# hsi get_mem_ranges, CONFIG_C_CPU_NAME has to be read for each IPI instance to get the master.
set ipi_ip_names {"psv_ipi" "psx_ipi" "ipi"}

# List of drivers from embeddedsw:
# cframe, cfupmc, csudma, emacps, gpiops, i2cps, iomodule, ipipsu, qspipsu
# ospipsv, spips, sdps/emmc, sysmonpsv, trngpsv/x, ttcps,
# uartlite (for no PS uart case, mdm), uartpsv, ufspsxc, usbpsu, wdttb, zdma

# Below list is without uart, mdm and IPI entries, those are concatenated in the next line.
# Versal iomodule IP Name is iomodule
# USB nodes need both the dwc3 (xhci) as well as usb0 (the usb IP)
set plm_supported_ips {
	"psv_pmc_cfi_cframe" "psx_pmc_cfi_cframe" "pmc_cfi_cframe" \
	"psv_pmc_cfu_apb" "psx_pmc_cfu_apb" "pmc_cfu_apb" \
	"psv_pmc_dma" "psx_pmc_dma" "pmc_dma" "pmcl_dma" \
	"psv_ethernet" "psx_ethernet" "ethernet" \
	"psv_pmc_gpio" "psx_pmc_gpio" "pmc_gpio" "psv_gpio" "psx_gpio" "gpio" \
	"psv_pmc_i2c" "psx_pmc_i2c" "pmc_i2c" "psv_i2c" "psx_i2c" "i2c" \
	"iomodule" "psx_iomodule" \
	"psv_pmc_qspi" "psx_pmc_qspi" "pmc_qspi" \
	"psv_pmc_ospi" "psx_pmc_ospi" "pmc_ospi" "pmcl_ospi" \
	"psv_pmc_sd" "psx_pmc_sd" "psx_pmc_emmc" "pmc_sd" "pmc_emmc" \
	"psv_spi" "psx_spi" "spi" \
	"psv_pmc_sysmon" "psx_pmc_sysmon" "pmc_sysmon" \
	"psv_pmc_trng" "psx_pmc_trng" "pmc_trng" \
	"psv_ttc" "psx_ttc" "ttc" \
	"pmc_ufs_xhci" \
	"psv_usb_xhci" "psx_usb_xhci" "usb_xhci" \
	"psv_usb" "psx_usb" "usb" \
	"psv_wwdt" "psx_wwdt" "wwdt" "pmc_wwdt" \
	"psv_adma" "psv_gdma" "psx_adma" "adma"
}

set plm_supported_ips [concat $plm_supported_ips $ipi_ip_names $ps_uart_ip_names $mdm_uart_ip_names]

# Top Level Generate function to create the PMC specific device tree
proc generate_pmc_dt {xsa dir} {
	global cur_hw_design
	global plm_supported_ips
	global ipi_ip_names
	global ps_uart_ip_names
	global mdm_uart_ip_names
	global pmc_ip_names
	global processor_ip_list
	set default_uart_handle ""
	set addr_map_list [list]

	if {[string match -nocase [hsi::get_hw_designs] ""] } {
		error "ERROR: open_hw_design failed for $xsa"
	} else {
		# Below global dicts are needed to re-use get_node, gen_drv_prop_from_ip from common procs.
		# The get_baseaddr and get_highaddr definitions are overloaded with get_domain_specific_baseaddr and
		# get_domain_specific_highaddr respectively, meaning the global dicts node_dict, baseaddr_dict and
		# highaddr_dict are defined via new functions and read via the existing common procs.
		global node_dict
		global property_dict
		global baseaddr_dict
		global highaddr_dict
		dict set node_dict $cur_hw_design {}
		dict set property_dict $cur_hw_design {}
		dict set baseaddr_dict $cur_hw_design {}
		dict set highaddr_dict $cur_hw_design {}
	}

	# Validate the design, check whether the XSA is a Versal or Versal-like family design.
	# When the valid handle is found, pick the 0th instance for the further processing.
	set pmc_proc_handle [return_valid_ip_handle $pmc_ip_names]

	set processor_ip_list [get_ip_property $pmc_proc_handle IP_NAME]

	# Determine the Versal family (Versal, VersalNet, Versal_2VE_2VM)
	set proclist [get_valid_proc_list]
	set_hw_family $proclist

	# Set the system-device-tree-xlnx path as per user inputs
	set path [set_sdt_default_repo]

	# Find all the dtsi files that are required to be pulled in SDT (versal.dtsi, versal-clk.dtsi etc.)
	set platform_name [set_soc_dtsi]


	# Some IPs come in output of get_mem_ranges of pmc but are not really needed (e.g. IPI)
	set valid_plm_specific_handle {}

	# Get all the memory objects mapped to PMC
	set pmc_mapped_handles [hsi get_mem_ranges -of_objects $pmc_proc_handle]

	if {[string_is_empty $pmc_mapped_handles]} {
		error "ERROR: There is no IP mapped to the PMC processor instance $pmc_proc_handle. \n\
                   \[hsi get_mem_ranges -of_objects \[hsi get_cells -hier $pmc_proc_handle\]\] command returned no mapping.\
                    Please check your design."
	}

	# If some driver tcl (e.g. trngpsx) needs to write user defined nodes, they will be using amba
	# bus as parent node. That node needs to be created explicitly, in common flow it is part of APU TCLs
	pcwdt insert root end "&amba"

	# Same process as in SDT generation. First loop is for generating overall IP properties using common code.
	# Second loop is for running individual driver specific TCLs.
	foreach handle $pmc_mapped_handles {
		set ip_name [get_ip_property $handle IP_NAME]

		# Run the entire flow only for the IPs mentioned under $plm_supported_ips list.
		if {$ip_name in $plm_supported_ips} {

			# Special handling for finding IPI mapping to PMC
			if {$ip_name in $ipi_ip_names} {
				set ipi_master [get_ip_property $handle "CONFIG.C_CPU_NAME"]
				if {$ipi_master != "PMC"} {
					# Set the base address and high address for all the IPIs irrespective of
					# CPU mapping. These IPIs can be destinations (child nodes) of PMC IPIs and
					# these addresses are needed within ipipsu.tcl for get_baseaddr API.
					get_domain_specific_baseaddr $handle
					get_domain_specific_highaddr $handle
					continue
				}
			}
			# Give priority to PS UARTs over ppu1_mdm irrespective of the naming order.
			# The first PS UART coming in the naming order will be set as the serial port.
			if {($ip_name in $ps_uart_ip_names) && [string_is_empty $default_uart_handle]} {
				set default_uart_handle "$handle"
			}

			# Create nodes, set status, add IP-NAME and NAME
			if {[gen_domain_peripheral_nodes $handle]} {
				continue
			}

			# Create IP specific properties
			gen_drv_prop_from_ip $handle

			lappend valid_plm_specific_handle $handle

			# Update the address map metadata with the node and addresses
			set map_entry [gen_address_map $handle]
			if {![string_is_empty $map_entry]} {
				lappend addr_map_list $map_entry
			}
		} else {
			continue
		}
	}

	# Add the pmc handle to run the microblaze tcl that generates properties for PMC microblaze.
	# IP NAME in the node is of significance to validate the proc entries during the build flow.
	lappend valid_plm_specific_handle $pmc_proc_handle

	# Run the respective driver TCLs
	foreach handle $valid_plm_specific_handle {
		set ip_name [get_ip_property $handle IP_NAME]
		if { [dict exists $::sdtgen::namespacelist $ip_name] } {
			set drvname [dict get $::sdtgen::namespacelist $ip_name]
			source [file join $path $drvname "data" "${drvname}.tcl"]
			${drvname}_generate [hsi get_cells -hier $handle]
		}
		# If there is no PS UART, set default serial console to ppu1_mdm
		if {($ip_name in $mdm_uart_ip_names) && [string_is_empty $default_uart_handle]} {
			set default_uart_handle "$handle"
		}
	}

	# Common function, used to set properties for sem, ddrmc5 etc.
	gen_board_info

	# Common function, pulls in the dt-binding headers folder
	gen_include_headers

	# Common function, includes the custom dtsi file if passed via commandline
	include_custom_dts

	# Update the stdout-path under chosen node
	update_domain_stdout $default_uart_handle

	# Create the PMC address map in system-top.dts
	gen_pmc_cluster_map $addr_map_list

	# Add part specific miscellaneous entries
	gen_part_specific_misc

	# Delete empty tree children and write the dt files with the corresponding tree objects
	delete_tree systemdt root
	delete_tree pcwdt root
	write_dt systemdt root "$dir/system-top.dts"
	write_dt pcwdt root "$dir/pcw.dtsi"

	# Pull in the SOC specific dtsi files inside SDT folder
	fetch_soc_dtsi $dir $path $platform_name

	# Destroy all the tree objects used during session
	destroy_tree
}


# Use HSI Filter to get the valid IP Handle lists among all the available handles
# Throw error with the expected IP Names if none of the valid IP handles is found.
proc return_valid_ip_handle {valid_ip_list} {
	global pmc_ip_names
	set hsi_filter [create_hsi_filter_from_loop $valid_ip_list]
	set valid_handles [hsi get_cells -hier -filter $hsi_filter]
	if {[string_is_empty $valid_handles]} {
		error "ERROR: Supported IPs are $valid_ip_list. No matching handle found"
	}
	return [lindex $valid_handles 0]
}


# Create an HSI filter from a list of valid elements
proc create_hsi_filter_from_loop {list_of_ele} {
	set hsi_filter ""
	foreach entry $list_of_ele {
		append hsi_filter "IP_NAME == $entry"
		if {$entry != [lindex $list_of_ele end]} {
			append hsi_filter " || "
		}
	}
	if {[string_is_empty $hsi_filter]} {
		error "ERROR: hsi filter could not be created for $list_of_ele"
	}
	return $hsi_filter
}


# Find all the dtsi files that are required to be pulled in SDT (versal.dtsi, versal-clk.dtsi etc.)
proc set_soc_dtsi {} {
        global design_family
	global is_versal_net_platform
	global is_versal_2ve_2vm_platform
	global is_versal_2vp_platform
	global platform_name ""
	if {$design_family == "versal"} {
		if { $is_versal_net_platform } {
			if {$is_versal_2ve_2vm_platform} {
				set platform_name "versal2"
				update_system_dts_include [file tail "${platform_name}-clk-ccf.dtsi"]
			} else {
				set platform_name "versal-net"
				update_system_dts_include [file tail "${platform_name}-clk-ccf.dtsi"]
			}
		} else {
			set platform_name "versal"
			update_system_dts_include [file tail "${platform_name}-clk.dtsi"]
		}

		set dtsi_fname "${platform_name}/${platform_name}.dtsi"
		if {$is_versal_2vp_platform} {
			set dtsi_fname "${platform_name}/versal2vp.dtsi"
		}
		update_system_dts_include [file tail ${dtsi_fname}]
	}
	if {[string_is_empty $platform_name]} {
		error "ERROR: platform name couldn't be determined"
	}
	return $platform_name
}


# Pull in all the SOC specific dtsi files inside SDT folder
proc fetch_soc_dtsi {dir path platform_name} {
	set common_file "$path/device_tree/data/config.yaml"
	global include_list
	set release [get_user_config $common_file -kernel_ver]
	set soc_dtsi_folder [file normalize "$path/device_tree/data/kernel_dtsi/${release}/${platform_name}"]
	set include_dts_list [split $include_list ","]
	foreach file [glob [file normalize ${soc_dtsi_folder}/*]] {
		set filename [file tail $file]
		if {$filename in $include_dts_list} {
			file copy -force $file $dir
		}
	}
}


# Get the PMC specific base address of the IP (with and without prefix 0x)
proc get_domain_specific_baseaddr {mem_handle {no_prefix ""}} {
	global baseaddr_dict
	global cur_hw_design
	if { [dict exists $baseaddr_dict $cur_hw_design $mem_handle] } {
		set baseaddr [dict get $baseaddr_dict $cur_hw_design $mem_handle]
		if {![string_is_empty $no_prefix]} {
			set baseaddr [remove_prefix_from_addr $baseaddr]
		}
		return $baseaddr
	}
	set addr [string tolower [get_obj_property $mem_handle BASE_VALUE]]
	dict set baseaddr_dict $cur_hw_design $mem_handle $addr
	if {![string_is_empty $no_prefix]} {
		set addr [remove_prefix_from_addr $addr]
	}
	return $addr
}


# Get the PMC specific high address of the IP (with and without prefix 0x)
proc get_domain_specific_highaddr {mem_handle {no_prefix ""}} {
	global highaddr_dict
	global cur_hw_design
	if { [dict exists $highaddr_dict $cur_hw_design $mem_handle] } {
		set highaddr [dict get $highaddr_dict $cur_hw_design $mem_handle]
		if {![string_is_empty $no_prefix]} {
			set highaddr [remove_prefix_from_addr $highaddr]
		}
		return $highaddr
	}
	set addr [string tolower [get_obj_property $mem_handle HIGH_VALUE]]
	dict set highaddr_dict $cur_hw_design $mem_handle $addr
	if {![string_is_empty $no_prefix]} {
		set addr [remove_prefix_from_addr $addr]
	}
	return $addr
}


# Create the reference node for each peripherals in pcw.dtsi, set their status, ip-names and names
proc gen_domain_peripheral_nodes {mem_handle} {
	global node_dict
	global cur_hw_design
	set baseaddr [get_domain_specific_baseaddr $mem_handle no_prefix]
	set highaddr [get_domain_specific_highaddr $mem_handle no_prefix]
	set ps_mapping [gen_ps_mapping]
	if {[catch {
		set node_label [dict get $ps_mapping $baseaddr label]
		set node_label [lindex [split $node_label ": "] 0]
	} msg]} {
		puts "WARNING: Add the node for $mem_handle in the soc specific dtsi file"
		return 1
	}
	set node [pcwdt insert root end "&$node_label"]
	add_prop $node "status" "okay" string "pcw.dtsi"
	add_prop $node "xlnx,ip-name" [get_ip_property $mem_handle IP_NAME] string "pcw.dtsi"
	add_prop $node "xlnx,name" $mem_handle string "pcw.dtsi"
	dict set node_dict $cur_hw_design $mem_handle $node
	return 0
}


# Add the stdout-path under chosen node for correct settings of STDIN and STDOUT addresses in BSP.
proc update_domain_stdout {default_uart_handle} {
	if {[string_is_empty $default_uart_handle]} {
		puts "WARNING: No valid UART found in the design"
		return
	}
	set chosen_node [systemdt insert root end "chosen"]
	set alias_node [systemdt insert root end "aliases"]
	set uart_node_label [get_label $default_uart_handle]
	regsub -all {^&} $uart_node_label {} uart_node_label
	# If stdout-path is already not set via any of the uart driver tcls, set it here
	if {[catch {set val [systemdt get $chosen_node "stdout-path"]} msg]} {
		add_prop $chosen_node "stdout-path" "serial0:115200n8" string "system-top.dts"
	}
	add_prop $alias_node "serial0" &${uart_node_label} aliasref "system-top.dts"
}


# Populate the memory object related entries (baseaddr label baseaddr size) in the list format that address map expects.
proc gen_address_map {mem_handle} {
	set baseaddr [get_domain_specific_baseaddr $mem_handle]
	set highaddr [get_domain_specific_highaddr $mem_handle]
	set addr_map_entry [list]
	if {[regexp -nocase {0x([0-9a-f]{9})} "$baseaddr" match]} {
		puts "WARNING: Baseaddress for $mem_handle is $baseaddr which is more than 32 bit address. Ignoring $mem_handle for the address map"
		return $addr_map_entry
	}
	set mem_size [format 0x%lx [expr {${highaddr} - ${baseaddr} + 1}]]
	if {[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]} {
		puts "WARNING: Mem Size for $mem_handle is $mem_size which is more than 32 bit address. Ignoring $mem_handle for the address map"
		return $addr_map_entry
	}
	set node_label [get_label $mem_handle]
	lappend addr_map_entry <$baseaddr $node_label $baseaddr $mem_size>
	return $addr_map_entry
}


# Create the PMC address map in system-top.dts using the data populated by gen_address_map
proc gen_pmc_cluster_map {address_map} {
	set cpu_node [systemdt insert root end "cpus_microblaze_0: cpus_microblaze@0"]
	add_prop $cpu_node "compatible" "cpus,cluster" string "system-top.dts"
	add_prop $cpu_node "#ranges-size-cells" "0x1" hexint "system-top.dts"
        add_prop $cpu_node "#ranges-address-cells" "0x1" hexint "system-top.dts"
        add_prop $cpu_node "address-map" [join $address_map ", \n\t\t\t      "] noformating "system-top.dts"
}
