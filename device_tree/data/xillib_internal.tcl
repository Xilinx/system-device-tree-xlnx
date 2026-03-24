#
# (C) Copyright 2013-2021 Xilinx, Inc.
# (C) Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

#
#TODO: Currently exported xml does not have internal interrupt connectivity for ps7 
# internal IPs so for the time being, this hard coding is placed. It will be removed
# once the internal interrupt connectivy is exposed in exported xml file.
#
proc special_handling_for_ps7_interrupt { periph_name} {

    set periph [hsi::get_cells -hier "$periph_name"]
    if { [llength $periph] != 1}  {
        return $ret
    }

    #current processor should be ps7_cortexa9
#    set sw_core [hsi::get_sw_processor]
 #   set proc_name [hsi get_property HW_INSTANCE $sw_core]
	set proc_list "psv_cortexa72 psu_cortexa53 ps7_cortexa9"
	set ip_name [hsi get_property IP_NAME [hsi::get_cells -hier $periph_name]]
	if { [lsearch -nocase $proc_list $ip_name] != 0 } {
#    set hw_core [hsi::get_cells -hier -filter "NAME==$proc_name" ]
 #   set proc_type [hsi get_property IP_NAME $hw_core ]
    if { [string compare -nocase "$ip_name"  ps7_cortexa9] != 0} {
        return 0
    }
	}
    #peripheral should have driver list
	if { [llength $periph_name] != 0 } {
    set periph_driver [hsi::get_drivers -filter "HW_INSTANCE==$periph_name"]
    if { [llength $periph_driver] != 1 } {
        return 0
    }
	}
    #peripheral name should have ps7 name 
    set ip_name [hsi get_property IP_NAME $periph]
    if { [string match -nocase ps7* "$ip_name"] } {
        return 1
    }
    return 0
}

#It assume that XLCONCAT IP cell object is passed to this function
proc get_concat_interrupt_sources { concat_ip_obj {lsb -1} {msb -1} } {
    lappend source_pins
    if {$lsb == -1 } {
        set i 0
        set num_ports [hsi get_property CONFIG.NUM_PORTS $concat_ip_obj]
    } else {
        set i $lsb
        set num_ports $msb
    }
    for { $i } { $i < $num_ports } { incr i } {
        set in_pin [hsi::get_pins -of_objects $concat_ip_obj "In$i"]
        set pins [get_source_pins $in_pin]
        foreach pin $pins {
            set source_cell [hsi::get_cells -of_objects $pin]
            if { [llength $source_cell] } {
                set ip_name [hsi get_property IP_NAME $source_cell]
                #Cascading case of concat IP
                if {$ip_name in {"xlconcat" "ilconcat"}} {
                    set source_pins [list {*}$source_pins {*}[get_concat_interrupt_sources $source_cell]]
                } elseif {$ip_name in {"xlslice" "ilslice"}} {
                    set source_pins [list {*}$source_pins {*}[get_slice_interrupt_sources $source_cell]]
                } elseif {$ip_name in {"util_reduced_logic" "ilreduced_logic"} } {
                    set source_pins [list {*}$source_pins {*}[get_util_reduced_logic_interrupt_sources $source_cell]]
                } else {
                    lappend source_pins $pin
                }

            } else {
                lappend source_pins $pin
            }
        }
    }
    return $source_pins
}

proc get_slice_interrupt_sources { slice_ip_obj } {
    lappend source_pins
    set in_pin [hsi::get_pins -of_objects $slice_ip_obj "Din"]
    set pins [get_source_pins $in_pin]
    foreach pin $pins {
        set source_cell [hsi::get_cells -of_objects $pin]
        if { [llength $source_cell] } {
            set ip_name [hsi get_property IP_NAME $source_cell]
            #Cascading case of xlslice IP
            if {$ip_name in {"xlslice" "ilslice"}} {
                set source_pins [list {*}$source_pins {*}[get_slice_interrupt_sources $source_cell]]
            } elseif {$ip_name in {"xlconcat" "ilconcat"}} {
                set from [::hsi get_property CONFIG.DIN_FROM $slice_ip_obj]
                set to [::hsi get_property CONFIG.DIN_TO $slice_ip_obj]
                set lsb [expr $from < $to ? $from : $to]
                set msb [expr $from > $to ? $from : $to]
                incr msb
                set source_pins [list {*}$source_pins {*}[get_concat_interrupt_sources $source_cell $lsb $msb]]
            } elseif {$ip_name in {"util_reduced_logic" "ilreduced_logic"}} {
                    set source_pins [list {*}$source_pins {*}[get_util_reduced_logic_interrupt_sources $source_cell]]
            } else {
                lappend source_pins $pin
            }

        } else {
            lappend source_pins $pin
        }
    }
    return $source_pins
}

proc get_util_reduced_logic_interrupt_sources { url_ip_obj } {
    lappend source_pins
    set in_pin [hsi::get_pins -of_objects $url_ip_obj "Op1"]
    set pins [get_source_pins $in_pin]
    foreach pin $pins {
        set source_cell [hsi::get_cells -of_objects $pin]
        if { [llength $source_cell] } {
            set ip_name [hsi get_property IP_NAME $source_cell]
            
            if {$ip_name in {"xlslice" "ilslice"}} {
                set source_pins [list {*}$source_pins {*}[get_slice_interrupt_sources $source_cell]]
            } elseif {$ip_name in {"xlconcat" "ilconcat"}} {
                set source_pins [list {*}$source_pins {*}[get_concat_interrupt_sources $source_cell]]
            } elseif {$ip_name in {"util_reduced_logic" "ilreduced_logic"}} {
		    #Cascading case of util_reduced_logic IP
                    set source_pins [list {*}$source_pins {*}[get_util_reduced_logic_interrupt_sources $source_cell]]
            } else {
                lappend source_pins $pin
            }

        } else {
            lappend source_pins $pin
        }
    }
    return $source_pins
}

proc get_intc_cascade_id_offset { intc } {
    # Alias to common_proc.tcl::get_intc_cascade_offset
    # Maintains compatibility for xillib_sw.tcl caller
    return [get_intc_cascade_offset $intc]
}
