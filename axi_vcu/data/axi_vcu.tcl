#
# (C) Copyright 2017 Xilinx, Inc.
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

namespace eval axi_vcu {
	proc generate {drv_handle} {
	    # Generate properties required for vcu node
	    set node [get_node $drv_handle]
	    if {$node == 0} {
		   return
	    }
	    set dts_file [set_drv_def_dts $drv_handle]
	    add_prop $node "#address-cells" 2 int $dts_file
	    add_prop "#size-cells" 2 int $dts_file
	    add_prop "#clock-cells" 1 int $dts_file
	    set vcu_ip [hsi::get_cells -hier $drv_handle]
	    set baseaddr [get_baseaddr $vcu_ip no_prefix]
	    set slcr_offset 0x40000
	    set logicore_offset 0x41000
	    set vcu_slcr_reg [format %08x [expr 0x$baseaddr + $slcr_offset]]
	    set logicore_reg [format %08x [expr 0x$baseaddr + $logicore_offset]]
	    set reg "0x0 0x$vcu_slcr_reg 0x0 0x1000>, <0x0 0x$logicore_reg 0x0 0x1000"
	    set_drv_prop $drv_handle reg $reg int
	    set intr_val [pldt get $node interrupts]
	    set intr_parent [pldt get $node interrupt-parent]
	    set clock-names "pll_ref"
	    set clock-names [append clock-names " aclk"]
	    add_prop $node "clock-names" ${clock-names} stringlist $dts_file
	    zynq_gen_pl_clk_binding $drv_handle
	    set first_reg_name "vcu_slcr"
	    set second_reg_name " logicore"
	    set reg_name [append first_reg_name $second_reg_name]
	    add_prop "${node}" "reg-names" ${reg_name} stringlist $dts_file
	    add_prop "${node}" "ranges" "" boolean $dts_file
	    
	    pldt append $node compatible "\ \, \"xlnx,vcu\""

	    # Generate child encoder
	    set ver [get_ipdetails $drv_handle "ver"]
	    set encoder_node [create_node -l "encoder" -n "al5e@$baseaddr" -p $node]
	    set encoder_comp "al,al5e-${ver}"
	    set encoder_comp [append encoder_comp "\ \, \" al,al5e\""]
	    add_prop "${encoder_node}" "compatible" $encoder_comp stringlist $dts_file
	    set encoder_reg "0x0 0x$baseaddr 0x0 0x10000"
	    add_prop "${encoder_node}" "reg" $encoder_reg int $dts_file
	    add_prop "${encoder_node}" "interrupts" $intr_val int $dts_file
	    add_prop "${encoder_node}" "interrupt-parent" $intr_parent reference  $dts_file
	    # Fenerate child decoder
	    set decoder_offset 0x20000
	    set decoder_reg [format %08x [expr 0x$baseaddr + $decoder_offset]]
	    set decoder_node [create_node -l "decoder" -n "al5d@$decoder_reg" -p $node]
	    set decoder_comp "al,al5d-${ver}"
	    set decoder_comp [append decoder_comp "\ \, \"al,al5d\""]
	    add_prop "${decoder_node}" "compatible" $decoder_comp stringlist $dts_file
	    set decoder_reg "0x0 0x$decoder_reg 0x0 0x10000"
	    add_prop "${decoder_node}" "reg" $decoder_reg int $dts_file
	    add_prop "${decoder_node}" "interrupts" $intr_val int $dts_file
	    add_prop "${decoder_node}" "interrupt-parent" $intr_parent reference $dts_file
	    set clknames "pll_ref aclk vcu_core_enc vcu_core_dec vcu_mcu_enc vcu_mcu_dec"
	    overwrite_clknames $clknames $drv_handle
	    set ip [hsi::get_cells -hier $drv_handle]
	    set pins [hsi::utils::get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] "vcu_resetn"]]
		foreach pin $pins {
			set sink_periph [hsi::get_cells -of_objects $pin]
			if {[llength $sink_periph]} {
				set sink_ip [get_property IP_NAME $sink_periph]
				if {[string match -nocase $sink_ip "xlslice"]} {
					set gpio [get_property CONFIG.DIN_FROM $sink_periph]
					set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $sink_periph "Din"]]]
					foreach pin $pins {
						set periph [hsi::get_cells -of_objects $pin]
						if {[llength $periph]} {
							set ip [get_property IP_NAME $periph]
							#set proc_type [get_sw_proc_prop IP_NAME]
							set proc_type [get_hw_family]
							if {[string match -nocase $proc_type "versal"] } {
								if {[string match -nocase $ip "versal_cips"]} {
									# As in versal there is only bank0 for MIOs
									set gpio [expr $gpio + 26]
									add_prop $node "reset-gpios" "gpio0 $gpio 0" reference $dts_file
									break
								}
							}
							if {[string match -nocase $proc_type "zynqmp"] || [string match -nocase $proc_type "zynquplus"]} {
								if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
									set gpio [expr $gpio + 78]
									add_prop $node "reset-gpios" "gpio $gpio 0" reference $dts_file
									break
								}
							}
							if {[string match -nocase $ip "axi_gpio"]} {
								add_prop "$node" "reset-gpios" "$periph $gpio 0 1" reference $dts_file
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

	proc get_ipdetails {drv_handle arg} {
	    set slave [hsi::get_cells -hier ${drv_handle}]
	    set vlnv [split [get_property VLNV $slave] ":"]
	    set ver [lindex $vlnv 3]
	    set name [lindex $vlnv 2]
	    set ver [lindex $vlnv 3]
	    set comp_prop "xlnx,${name}-${ver}"
	    regsub -all {_} $comp_prop {-} comp_prop
	    if {[string match -nocase $arg "ver"]} {
		return $ver
	    } else {
		return $comp_prop
	    }
	}
}
