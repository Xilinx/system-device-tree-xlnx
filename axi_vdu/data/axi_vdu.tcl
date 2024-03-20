#
# (C) Copyright 2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc gen_reset_gpio {drv_handle node} {
    set ip [hsi get_cells -hier $drv_handle]
    set default_dts [set_drv_def_dts $drv_handle]
    set pins [get_source_pins [hsi get_pins -of_objects [ hsi get_cells -hier $ip] "vdu_resetn"]]
    foreach pin $pins {
	set sink_periph [::hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [hsi get_property IP_NAME $sink_periph]
		    if {[string match -nocase $sink_ip "axi_gpio"]} {
			    add_prop $node "reset-gpios" "$sink_periph 0 1" reference $default_dts
			}
			if {[string match -nocase $sink_ip "xlslice"]} {
				set gpio [get_property CONFIG.DIN_FROM $sink_periph]
				set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $sink_periph "Din"]]]
				foreach pin $pins {
					set periph [::hsi::get_cells -of_objects $pin]
					if {[llength $periph]} {
						set ip [get_property IP_NAME $periph]
						if { $ip in { "versal_cips" "ps_wizard" }} {
							# As in versal there is only bank0 for MIOs
							set gpio [expr $gpio + 26]
							add_prop $node "reset-gpios" "gpio0 $gpio 0" reference $default_dts
							break
						}
						if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
							set gpio [expr $gpio + 78]
							add_prop $node "reset-gpios" "gpio $gpio 0" reference $default_dts
							break
						}
						if {[string match -nocase $ip "axi_gpio"]} {
							add_prop $node "reset-gpios" "$periph $gpio 0 1" reference $default_dts
						}
					} else {
						dtg_warning "periph for the pin:$pin is NULL $periph...check the design"
					}
				}
			}
		} else {
			dtg_warning "peripheral for the pin:$pin is NULL $sink_periph...check the design"
		}
	}
}

proc get_intr_width {intr_parent} {
	set intr_width ""
	if { [string match -nocase $intr_parent "imux"] }  {
		set intr_width "3"
	} else {
		set intr_width "2"
	}
	return $intr_width
}

proc axi_vdu_generate {drv_handle} {
	# Generate properties required for vdu node
	set node [get_node $drv_handle]
	if {$node == 0} {
	   return
	}
	set drv_label [ps_node_mapping $drv_handle label]
	set default_dts [set_drv_def_dts $drv_handle]

	set vdu_ip [hsi get_cells -hier $drv_handle]
	set core_clk [hsi get_property CONFIG.Actual_CORE_CLK [hsi get_cells -hier $drv_handle]]
	if {[llength $core_clk]} {
		add_prop $node "xlnx,core_clk" ${core_clk} int $default_dts
	}
	set mcu_clk [hsi get_property CONFIG.Actual_MCU_CLK [hsi get_cells -hier $drv_handle]]
	if {[llength $mcu_clk]} {
		add_prop $node "xlnx,mcu_clk" ${mcu_clk} int $default_dts
	}
	set ref_clk [hsi get_property CONFIG.REF_CLK [hsi get_cells -hier $drv_handle]]
	if {[llength $ref_clk]} {
		add_prop $node "xlnx,ref_clk" ${ref_clk} int $default_dts
	}

	gen_reset_gpio "$drv_handle" "$node"
	set bus_name [detect_bus_name $drv_handle]

	set intrnames_List ""
	set intr_val ""
	set intr_parent ""

	set baseaddr [get_baseaddr $vdu_ip no_prefix]
	set num_decoders [hsi get_property CONFIG.NUM_DECODER_INSTANCES [hsi get_cells -hier $drv_handle]]
	set al5d_baseoffset "0x20000"
	set al5d_baseaddr [format %08x [expr 0x$baseaddr + $al5d_baseoffset]]
	set al5d_offset "0x100000"
	set intr_width ""

	set intrnames_List [split [string map {" " ""} [pldt get $node "interrupt-names"]] ","]
	set intr_val [string trim [pldt get $node "interrupts"] \<\>]
	set intr_parent [string trim [pldt get $node "interrupt-parent"] \<\&\>]

	pldt unset $node "interrupt-names"
	pldt unset $node "interrupts"
	pldt unset $node "interrupt-parent"

	for {set inst 0} {$inst < $num_decoders} {incr inst} {
		set al5d_node_label "al5d${inst}"
		set al5d_node [create_node -l ${al5d_node_label} -n "al5d" -u $al5d_baseaddr -p $bus_name -d $default_dts]
		add_prop "$al5d_node" "compatible" "al,al5d" string $default_dts

		add_prop "$al5d_node" "al,devicename" "allegroDecodeIP$inst" string $default_dts
		add_prop "$al5d_node" "xlnx,vdu" "$drv_label" reference $default_dts
		add_prop "$al5d_node" "status" "okay" string $default_dts
		#add_prop "$al5d_node" "/* To be filled by user depending on design else CMA region will be used */" "" comment $default_dts
		#add_prop "$al5d_node" "/*memory-region = <&mem_reg_0> */" "" comment $default_dts

		# check if base address is 64bit and split it as MSB and LSB
		if {[regexp -nocase {0x([0-9a-f]{9})} "0x$al5d_baseaddr" match]} {
			set temp $al5d_baseaddr
			set temp [string trimleft [string trimleft $temp 0] x]
			set len [string length $temp]
			set rem [expr {${len} - 8}]
			set high_base "0x[string range $temp $rem $len]"
			set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
			set low_base [format 0x%08x $low_base]
			if {[regexp -nocase {0x([0-9a-f]{9})} "$al5d_offset" match]} {
				set temp $al5d_offset
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_size "0x[string range $temp $rem $len]"
				set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_size [format 0x%08x $low_size]
				set reg "$low_base $high_base $low_size $high_size"
			} else {
				set reg "$low_base $high_base 0x0 $al5d_offset"
			}
		} else {
			set reg "0x0 0x$al5d_baseaddr 0x0 $al5d_offset"
		}

		add_prop "$al5d_node" "reg" "$reg" hexlist $default_dts
		set_memmap $al5d_node_label a53 $reg
		if {[llength $intr_parent]} {
			set intr_width [get_intr_width $intr_parent]
			add_prop "$al5d_node" "interrupt-parent" "$intr_parent" reference $default_dts
		}

		if {[llength $intr_width] && [llength $intr_val]} {
			set intrs_List [regexp -inline -all -- {\S+} $intr_val]
			set intrs_cnt [llength $intrs_List]
			set start "[expr {${inst} * $intr_width}]"
			set end "[expr {$start + $intr_width - 1}]"
			if { $intrs_cnt > $intr_width } {
				add_prop "$al5d_node" "interrupts" "[lrange $intrs_List $start $end]" intlist $default_dts
			} else {
				add_prop "$al5d_node" "interrupts" "$intrs_List" intlist $default_dts
			}
		}

		if {[llength $intrnames_List]} {
			set intrnames_cnt [llength $intrnames_List]
			if { $intrnames_cnt > 1 } {
				add_prop "$al5d_node" "interrupt-names" "[lindex $intrnames_List $inst]" noformating $default_dts
			} else {
				add_prop "$al5d_node" "interrupt-names" "[lindex $intrnames_List 0]" noformating $default_dts
			}
		}
		set al5d_baseaddr [format %08x [expr 0x$al5d_baseaddr + $al5d_offset]]
	}

}
