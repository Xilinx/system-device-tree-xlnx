#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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
    
    variable aie_array_cols_start
    variable aie_array_cols_num

    proc ai_engine_generate_aie_array_device_info {node drv_handle bus_node} {
        set aie_array_id 0
        set compatible [get_comp_str $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,ai-engine-v2.0\""

	global is_versal_2ve_2vm_platform
	if {$is_versal_2ve_2vm_platform} {
		set power_domain_family "versal2_firmware"
	} else {
		set power_domain_family "versal_firmware"
	}

        #set default values
        set hw_gen "AIE"
        set aie_rows_start 1
        set aie_rows_num 8
        set mem_rows_start 0
        set mem_rows_num 0
        set shim_rows_start 0
        set shim_rows_num 1
        set ::aie_array_cols_start 0
        set ::aie_array_cols_num 50

        # override the above default values if AIE primitives are available in
        # xsa
        set CommandExists [ namespace which hsi::get_hw_primitives]
        if {$CommandExists != ""} {
                set aie_prop [hsi::get_hw_primitives aie]
                if {$aie_prop != ""} {
                        puts "INFO: Reading AIE hardware properties from XSA."

                        set hw_gen [hsi get_property HWGEN [hsi::get_hw_primitives aie]]
                        set aie_rows [hsi get_property AIETILEROWS [hsi::get_hw_primitives aie]]
                        set mem_rows [hsi get_property MEMTILEROW [hsi::get_hw_primitives aie]]
                        set shim_rows [hsi get_property SHIMROW [hsi::get_hw_primitives aie]]
                        set ::aie_array_cols_num [hsi get_property AIEARRAYCOLUMNS [hsi::get_hw_primitives aie]]

                        set aie_rows_start [lindex [split $aie_rows ":"] 0]
                        set aie_rows_num [lindex [split $aie_rows ":"] 1]
                        set mem_rows_start [lindex [split $mem_rows ":"] 0]
                        if {$mem_rows_start==-1} {
                                set mem_rows_start 0
                        }
                        set mem_rows_num [lindex [split $mem_rows ":"] 1]
                        set shim_rows_start [lindex [split $shim_rows ":"] 0]
                        set shim_rows_num [lindex [split $shim_rows ":"] 1]

                } else {
                        dtg_warning "$drv_handle: AIE hardware properties are not available in XSA, using defaults."
                }

        } else {
                dtg_warning "$drv_handle: AIE hardware properties are not available in XSA, using defaults."
        }

        if {$hw_gen=="AIE"} {
                append aiegen "/bits/ 8 <0x1>"
        } elseif {$hw_gen=="AIEML"} {
                append aiegen "/bits/ 8 <0x2>"
        } elseif {$hw_gen=="AIE2PS"} {
	        append aiegen "/bits/ 8 <0x5>"
        }

        add_prop "${node}" "xlnx,aie-gen" $aiegen noformating "pl.dtsi"
        append shimrows "/bits/ 8 <${shim_rows_start} ${shim_rows_num}>"
        add_prop "${node}" "xlnx,shim-rows" $shimrows noformating "pl.dtsi"
        append corerows "/bits/ 8 <${aie_rows_start} ${aie_rows_num}>"
        add_prop "${node}" "xlnx,core-rows" $corerows noformating "pl.dtsi"
        append memrows "/bits/ 8 <$mem_rows_start $mem_rows_num>"
        add_prop "${node}" "xlnx,mem-rows" $memrows noformating "pl.dtsi"

        set name [hsi get_property NAME [hsi get_current_part $drv_handle]]
        set part_num [string range $name 0 7]
        set part_num_v70 [string range $name 0 4]

        if {$part_num == "xcvp2502"} {
                #s100
                set power_domain "${power_domain_family} 0x18801000"
        } elseif {$part_num == "xcvp2802"} {
                #s200
                set power_domain "${power_domain_family} 0x18803000"
        } elseif {$part_num_v70 == "xcv70"} {
                #v70
                set power_domain "${power_domain_family} 0x18800000"
        } else {
		#NON SSIT devices
		set power_domain "${power_domain_family} 0x18800000"
	}
        add_prop "${node}" "power-domains" $power_domain reference "pl.dtsi"
        add_prop "${node}" "#address-cells" 2 hexlist "pl.dtsi"
        add_prop "${node}" "#size-cells" 2 hexlist "pl.dtsi"
        add_prop "${node}" "ranges" 0 boolean "pl.dtsi"

        set ai_clk_node [create_node -n "aie_core_ref_clk_0" -l "aie_core_ref_clk_0" -p ${bus_node} -d "pl.dtsi"]
        set clk_freq [hsi get_property CONFIG.AIE_CORE_REF_CTRL_FREQMHZ [hsi get_cells -hier $drv_handle]]
        set clk_freq [expr ${clk_freq} * 1000000]
        add_prop "${ai_clk_node}" "compatible" "fixed-clock" stringlist "pl.dtsi"
        add_prop "${ai_clk_node}" "#clock-cells" 0 int "pl.dtsi"
        add_prop "${ai_clk_node}" "clock-frequency" $clk_freq int "pl.dtsi"
        set clocks "aie_core_ref_clk_0"
        set_drv_prop_if_empty $drv_handle clocks "$clocks" $node reference
        set_drv_prop_if_empty $drv_handle "clock-names" "aclk0" $node string

        return ${node}
    }


    proc ai_engine_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(CUSTOM_SDT_REPO)
	global is_versal_2ve_2vm_platform

        set hw_gen "AIE"
        set CommandExists [ namespace which hsi::get_hw_primitives]
        if {$CommandExists != ""} {
                set aie_prop [hsi::get_hw_primitives aie]
                if {$aie_prop != ""} {
                        set hw_gen [hsi get_property HWGEN [hsi::get_hw_primitives aie]]
                }
        }

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        if {$is_versal_2ve_2vm_platform} {
                set power_domain_family "versal2_firmware"
        } else {
                set power_domain_family "versal_firmware"
        }

        set bus_node "amba_pl: amba_pl"
        ai_engine_generate_aie_array_device_info ${node} ${drv_handle} ${bus_node}
        set ip [hsi get_cells -hier $drv_handle]
        set unit_addr [get_baseaddr ${ip} no_prefix]
        set aperture_id 0
        set aperture_node [create_node -n "aie_aperture" -u "${unit_addr}" -l "aie_aperture_${aperture_id}" -p ${node} -d "pl.dtsi"]
        set reg [string trim [pldt get $node "reg"] \<\>]
        add_prop "${aperture_node}" "reg" $reg hexlist "pl.dtsi"

        set name [hsi get_property NAME [hsi get_current_part $drv_handle]]
        set part_num [string range $name 0 7]
        set part_num_v70 [string range $name 0 4]

        if {$part_num == "xcvp2502"} {
                #s100
                set power_domain "${power_domain_family} 0x18801000"
                add_prop "${aperture_node}" "xlnx,device-name" "100" int "pl.dtsi"
                set aperture_nodeid 0x18801000
        } elseif {$part_num == "xcvp2802"} {
                #s200
                set power_domain "${power_domain_family} 0x18803000"
                add_prop "${aperture_node}" "xlnx,device-name" "200" int "pl.dtsi"
                set aperture_nodeid 0x18803000
        } elseif {$part_num_v70 == "xcv70"} {
                #v70
                set power_domain "${power_domain_family} 0x18800000"
                add_prop "${aperture_node}" "xlnx,device-name" "0" int "pl.dtsi"
                set aperture_nodeid 0x18800000
        } else {
                #NON SSIT devices
                set intr_names "interrupt1"
                lappend intr_names "interrupt2"
                lappend intr_names "interrupt3"
                switch $hw_gen {
                        "AIE2PS" {
                                set intr_num "0x0 0xce 0x4>, <0x0 0xcf 0x4>, <0x0 0xd0 0x4"
                        }
                        default {
                                set intr_num "0x0 0x94 0x4>, <0x0 0x95 0x4>, <0x0 0x96 0x4"
                        }
                }
                set power_domain "${power_domain_family} 0x18800000"
                add_prop "${aperture_node}" "interrupt-names" $intr_names stringlist "pl.dtsi"
                add_prop "${aperture_node}" "interrupts" $intr_num hexlist "pl.dtsi"
                add_prop "${aperture_node}" "interrupt-parent" imux reference "pl.dtsi"
                add_prop "${aperture_node}" "xlnx,device-name" "0" int "pl.dtsi"
                set aperture_nodeid 0x18800000
        }

        add_prop "${aperture_node}" "power-domains" $power_domain reference "pl.dtsi"
        add_prop "${aperture_node}" "#address-cells" "2" hexlist "pl.dtsi"
        add_prop "${aperture_node}" "#size-cells" "2" hexlist "pl.dtsi"

        add_prop "${aperture_node}" "xlnx,columns" "$::aie_array_cols_start $::aie_array_cols_num" intlist "pl.dtsi"
        add_prop "${aperture_node}" "xlnx,node-id" "${aperture_nodeid}" hexlist "pl.dtsi"
    }


