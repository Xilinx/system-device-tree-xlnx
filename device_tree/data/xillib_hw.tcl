#
# (C) Copyright 2013-2021 Xilinx, Inc.
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
namespace export *

#
# It will retrun the connected interface to and IP interface
#

proc get_connected_intf { periph_name intf_name} {
    set ret ""
    set periph [hsi::get_cells -hier "$periph_name"]
    if { [llength $periph] == 0} {
        return $ret
    }
    set intf_pin [hsi::get_intf_pins -of_objects $periph  "$intf_name"]
    if { [llength $intf_pin] == 0} {
        return $ret
    }
    set intf_net [hsi::get_intf_nets -of_objects $intf_pin]
    if { [llength $intf_net] == 0} {
        return $ret
    }
    # set connected_intf [hsi::get_intf_pins -of_objects $intf_net -filter "TYPE!=[hsi get_property TYPE $intf_pin]"]
    
    set connected_intf [get_other_intf_pin $intf_net $intf_pin ] 
    set intf_type [hsi get_property TYPE $intf_pin]
    set conn_busif_handle [get_intf_pin_oftype $connected_intf $intf_type 0]
    return $conn_busif_handle
}
# 
# it will return the net name connected to ip pin
#
proc get_net_name {ip_inst ip_pin} {
    set ret ""
    if { [llength $ip_pin] != 0 } {
    set port [hsi::get_pins -of_objects $ip_inst -filter "NAME==$ip_pin"]
    if { [llength $port] != 0 } {
        set pin [hsi::get_nets -of_objects $port ] 
        set ret [hsi get_property NAME $pin]
    }
    }
   return $ret
}

#
# It will return the interface net name connected to IP interface.
#
proc get_intfnet_name {ip_inst ip_busif} {
    set ret ""
    if { [llength $ip_busif] != 0 } {
    set bus_if [hsi::get_intf_pins -of_objects $ip_inst -filter "NAME==$ip_busif"]
    if { [llength $bus_if] != 0 } {
       set intf_net [hsi::get_intf_nets -of_objects $bus_if]
       set ret [hsi get_property NAME $intf_net]
    }
    }
    return $ret
}


# 
# It will return all the peripheral objects which are connected to processor
#
proc get_proc_slave_periphs {proc_handle} {
   set periphlist [hsi get_property slaves $proc_handle]
   if { $periphlist != "" } {
       foreach periph $periphlist {
        set periph1 [string trim $periph]
        set handle [hsi::get_cells -hier $periph1]
        lappend retlist $handle
       }
    return $retlist
   } else {
       return ""
   }
}
#
# It will return the clock frequency value of IP clock port.
# it will first check the requested pin should be be clock type.
#
proc get_clk_pin_freq { cell_obj clk_port} {
    set clk_port_obj [hsi::get_pins $clk_port -of_objects $cell_obj]
    if {$clk_port_obj ne "" } {
        set port_type [hsi get_property TYPE $clk_port_obj]
        if { [string compare -nocase $port_type  "CLK"] == 0 } {
            
            set clockValue [hsi get_property CLK_FREQ $clk_port_obj]
            # Temp solution handle to exponential representaion  
            set isExponentFormate "e"
            if {[string first $isExponentFormate $clockValue] != -1} {
              set retVal [format { %.0f} $clockValue]
              return $retVal
            }
            
            return [hsi get_property CLK_FREQ $clk_port_obj]
        } else {
            error "ERROR:Trying to access frequency value from non-clock port \"$clk_port\" of IP \"$cell_obj\""
        }
    } else {
        error "ERROR:\"$clk_port\" port does not exist in IP \"$cell_obj\""
    }
    return ""
}

# 
# It will check the pin object is external or not. If pin_object is 
# associated to a cell then it is internal otherise it is external
#
proc is_external_pin { pin_obj } {
    set pin_class [hsi get_property CLASS $pin_obj]
    if { [string compare -nocase "$pin_class" port] == 0 } {
        set ip [hsi::get_cells -of_objects $pin_obj]
        if {[llength $ip]} {
            return 0
        } else {
            return 1
        }
    } else {
        error "ERROR:is_external_pin Tcl proc expects port class type object $pin_obj. Whereas $pin_class type object is passed."
    }
}
#
# Get the width of port object. It will return width equal to 1 when
# port does not have width property
#
proc get_port_width { port_handle} {
    set left [hsi get_property LEFT $port_handle]
    set right [hsi get_property RIGHT $port_handle]
    if {[llength $left] == 0 && [llength $right] == 0} {
        return 1  
    }

    if {$left > $right} {
      set width [expr $left - $right + 1]
    } else {
      set width [expr $right - $left + 1]
    }
    return $width
}

#
# Remove the pin specified from the list of pins
#
proc remove_pin_from_list { pinList pin {hop_count 0}} {
    lappend returnList
    
    foreach pinInList $pinList {
	if {$hop_count >= 20} {
                puts "WARNING: Iteration limit of 20 reached. Breaking from loop."
                break
        }
        set hop_count [expr {$hop_count + 1}]
        # set pin_type [hsi get_property TYPE $pinInList]
        # if { $pin_type == "MONITOR"} {
            # continue
        # }
        set givenCell [hsi::get_cells -of_objects $pin]
        set newCell [hsi::get_cells -of_objects $pinInList]
        if { $givenCell != $newCell } {
            lappend returnList $pinInList
        }
    }

    return $returnList
}

#
# Given an interface pin and one of the interface net, this functions   
# returns the net which is on the other side of the boundary 
#
proc get_other_intf_net { intf_pin given_intf_net} {
    if { [llength $intf_pin] == 0 } {
        return ""
    }
    
    if { [llength $given_intf_net] == 0 } {
        return ""
    }
    
    set lower_intf_net [hsi::get_intf_nets -boundary_type lower -of_objects $intf_pin]
    set upper_intf_net [hsi::get_intf_nets -boundary_type upper -of_objects $intf_pin]
    if { [llength $lower_intf_net] != 0 && $lower_intf_net != $given_intf_net } { 
         return $lower_intf_net
    } elseif { [llength $upper_intf_net] != 0 && $upper_intf_net != $given_intf_net } {
        return $upper_intf_net
    }
    
    return ""
}

#
# Given an interface net and one of the interface pins, this functions recursively traverses block containers  
# to return the interface pin which is on the other end of the net 
#
proc get_other_intf_pin { intf_net given_intf_pin} {
    lappend return_pin_list
    if { [llength $intf_net] == 0 } {
        return ""
    }
    
    if { [llength $given_intf_pin] == 0 } {
        return ""
    }
    
    set intf_pins_list [hsi::get_intf_pins -of_objects $intf_net]
    if { [llength $intf_pins_list] == 0 } {
        return ""
    }
    set other_intf_pins [remove_pin_from_list $intf_pins_list $given_intf_pin]
    if { [llength $other_intf_pins] == 0 } {
        return ""
    }
    
    foreach other_intf_pin $other_intf_pins {
        set other_cell [hsi::get_cells -of_objects $other_intf_pin]
        if { [llength $other_cell] == 0 } {
            lappend return_pin_list $other_intf_pin
        }
        
        #set cell_type [hsi get_property IP_NAME $other_cell]
        set cell_type [hsi get_property BD_TYPE $other_cell]
        if { [ string match -nocase $cell_type "block_container" ] } {
            set other_bdry_intf_net [get_other_intf_net $other_intf_pin $intf_net]
            if { [llength $other_bdry_intf_net] == 0 } {
                continue
            }
            set result_pins [get_other_intf_pin $other_bdry_intf_net $other_intf_pin]
            if { [llength $result_pins] == 0 } {
                continue
            }
            foreach result_pin $result_pins {
                lappend return_pin_list $result_pin
            }
        } else {
            lappend return_pin_list $other_intf_pin
        }
        
    }
    
    return $return_pin_list
}

#
# Returns the pins that match the given type or does not match the given type based on the third argument 
# isOf takes bool value. If isOf is true, the proc returns all the pins of the type given
# If isOF is false, the proc returns all the pins that not the type given
#
proc get_intf_pin_oftype { given_intf_pins type isOf} {
    if { [llength $given_intf_pins] == 0 } {
        return $given_intf_pins
    }
    if { [ string match -nocase $type "" ] } {
        return $given_intf_pins
    }
    
    lappend return_pin_list
    foreach given_intf_pin $given_intf_pins {
        if { $isOf } {
            set given_pin_type [hsi get_property TYPE $given_intf_pin]
            if { [ string match -nocase $$given_pin_type $type ]} {
                lappend return_pin_list $given_intf_pin
            }
        } else {
            set given_pin_type [hsi get_property TYPE $given_intf_pin]
            if { ![ string match -nocase $$given_pin_type $type ]} {
                lappend return_pin_list $given_intf_pin
            }
        }
    }

    return $return_pin_list
}

proc prepend { src_list dest_list } {
    set temp_list $dest_list
    set dest_list {}
    foreach itr $src_list {
	    lappend dest_list $itr
    }
    foreach itr $temp_list {
	    lappend dest_list $itr
    }
    return $dest_list
}

#
# Get handles for all ports driving the interrupt pin of a peripheral
#
proc get_interrupt_sources {periph_handle } {
   lappend interrupt_sources
   lappend interrupt_pins
   set interrupt_pins [hsi::get_pins -of_objects $periph_handle -filter {TYPE==INTERRUPT && DIRECTION==I}]
   foreach interrupt_pin $interrupt_pins {
       set source_pins [get_intr_src_pins $interrupt_pin]
       foreach source_pin $source_pins {
           lappend interrupt_sources $source_pin 
       }
   }
   return $interrupt_sources
}
#
# Get the interrupt source pins of a periph pin object
#
proc get_intr_src_pins {interrupt_pin} {
    lappend interrupt_sources
    set source_pins [get_source_pins $interrupt_pin]
    foreach source_pin $source_pins {
        set source_cell [hsi::get_cells -of_objects $source_pin]
        if { [llength $source_cell ] } {
            #For concat IP, we need to bring pin source for other end
            set ip_name [hsi get_property IP_NAME $source_cell]
            if {$ip_name in {"xlconcat" "ilconcat"}} {
                set interrupt_sources [list {*}$interrupt_sources {*}[get_concat_interrupt_sources $source_cell]]
            } elseif {$ip_name in {"xlslice" "ilslice"}} {
                set interrupt_sources [list {*}$interrupt_sources {*}[get_slice_interrupt_sources $source_cell]]
            } elseif {$ip_name in {"util_reduced_logic" "ilreduced_logic"}} {
                set interrupt_sources [list {*}$interrupt_sources {*}[get_util_reduced_logic_interrupt_sources $source_cell]]
            } else {
                lappend interrupt_sources $source_pin 
            }
        } else {
            lappend interrupt_sources $source_pin 
        }
    }
    return $interrupt_sources
}
#
# Get the source pins of a periph pin object
#
proc get_source_pins {periph_pin} {
   set net [hsi::get_nets -of_objects $periph_pin]
   set cell [hsi::get_cells -of_objects $periph_pin]
   if { [llength $net] == 0} {
       return [lappend return_value] 
   } else {
        set signals [split [hsi get_property NAME $net] "&"]
        lappend source_pins
        if { [llength $signals] == 1 } {
          foreach signal $signals {
            set signal [string trim $signal]
            set sig_net [hsi::get_nets -of_objects $cell $signal]
            if { [llength $sig_net] == 0 } {
                continue
            }
            set source_pin [hsi::get_pins -of_objects $sig_net -filter { DIRECTION==O}]
            if { [ llength $source_pin] != 0 } {

                set source_pins [linsert $source_pins 0 $source_pin ]
            }
            set source_port [hsi::get_ports -of_objects $sig_net -filter {DIRECTION==I}]
            if { [llength $source_port] != 0 } {

                set source_pins [linsert $source_pins 0 $source_port]
            }

            lappend real_source_pins
            if { [ llength $source_pins] == 0 } {

              set all_pins [hsi::get_pins -of_objects $sig_net ]
              foreach pin $all_pins {
                set real_source_pin [get_real_source_pin_traverse_out $pin]
		lappend result_real_source_pin
		lappend pins_to_retain
		foreach outpin $real_source_pin {
			set inpin [get_real_source_pin_traverse_in $outpin ]
			if { [llength $inpin ] == 0 } {
				set pins_to_retain [linsert $pins_to_retain end $outpin]
			}
			foreach tpin $inpin {
				set result_real_source_pin [linsert $result_real_source_pin 0 $tpin]
			}

		}
		lappend temp_result_pins
		foreach tpin $pins_to_retain {
			set temp_result_pins [linsert $temp_result_pins end $tpin ]
		}
		foreach tpin $result_real_source_pin {
			set temp_result_pins [linsert $temp_result_pins end $tpin ]
		}
		set real_source_pin $temp_result_pins

                if { [ llength $real_source_pin] != 0 } {
		    set real_source_pins [prepend $real_source_pin $real_source_pins]
                }
              }
              if { [llength $real_source_pins] != 0 } {
                    return $real_source_pins
              }
            } else {

                foreach source_pin $source_pins {
                    set real_source_pin [get_real_source_pin_traverse_in $source_pin]
                    if { [ llength $real_source_pin] != 0 } {
		    set real_source_pins [prepend $real_source_pin $real_source_pins]
                    }
                }
                if { [llength $real_source_pins] != 0 } {
                          return $real_source_pins
                }
            }
          }
        } else {
            foreach signal $signals {
                set signal [string trim $signal]
                set sig_nets [hsi::get_nets $signal]
                set got_net [get_net_of_perifh_pin $periph_pin $sig_nets]
                set source_pin [hsi::get_pins -of_objects $got_net -filter { DIRECTION==O}]
                if { [ llength $source_pin] != 0 } {
                    set source_pins [linsert $source_pins 0 $source_pin ]
                }
                set source_port [hsi::get_ports -of_objects $got_net -filter {DIRECTION==I}]
                if { [llength $source_port] != 0 } {
                    set source_pins [linsert $source_pins 0 $source_port]
                }
            }
        }
        return $source_pins
    }
}

proc get_real_source_pin_traverse_out { pin } {

    lappend source_pins
      set lower_net [hsi::get_nets -boundary_type lower -of_objects $pin]
      set upper_net [hsi::get_nets -boundary_type upper -of_objects $pin]
      
      if { [ llength $lower_net] != 0  && [ llength $upper_net] != 0 } {

          set real_source_pin [hsi::get_pins -of_objects $upper_net -filter "DIRECTION==O" ]
          # removing the pin from where the traversal started or from where the funtion is called 
          set real_source_pin [remove_pin_from_list $real_source_pin $pin]
          
          set real_source_port [hsi::get_ports -of_objects $upper_net -filter "DIRECTION==I" ]
          # removing the pin from where the traversal started or from where the funtion is called
          set real_source_port [remove_pin_from_list $real_source_port $pin]
          
	  lappend source_pins_cur_lvl
          if { [ llength $real_source_pin] != 0 } {
              set source_pins_cur_lvl [linsert $source_pins_cur_lvl 0 $real_source_pin ]
          }
          if { [llength $real_source_port] != 0 } {
              set source_pins_cur_lvl [linsert $source_pins_cur_lvl 0 $real_source_port]
          }

	  lappend real_source_pins_recurse
	  lappend hier_pins
	  foreach itr_source_pin $source_pins_cur_lvl {
		  set itr_source_pins_recurse [get_real_source_pin_traverse_out $itr_source_pin]
		  foreach temppin $itr_source_pins_recurse {
			  set real_source_pins_recurse [linsert $real_source_pins_recurse 0 $temppin ]
		  }
		  if { [llength $itr_source_pins_recurse] != 0 } {
			  set hier_pins [linsert $hier_pins 0 $itr_source_pin]
		  }
	  }
	  foreach itr_src_pin $hier_pins {
		  set source_pins_cur_lvl [remove_pin_from_list $source_pins_cur_lvl $itr_src_pin ]
	  }
          if { [ llength $source_pins_cur_lvl] != 0 } {
	      foreach temppin $source_pins_cur_lvl {
                  set source_pins [linsert $source_pins 0 $temppin]
              }
          }

	  if { [llength $real_source_pins_recurse] != 0 } {
		  foreach itr_pin $real_source_pins_recurse {
			 set source_pins [linsert $source_pins 0 $itr_pin ]
		  }
	  }
          #if { [ llength $source_pins] != 0 } {
          #       return [get_real_source_pin_traverse_out $source_pins]
          #}
	  if { [ llength $source_pins ] == 0 } {
		  #the pin corresponding to upper_net could be on the boundary. So check if there is an upper and lower net for the pin and if that upper net is not same as this, then take that and go a level up
		  set uppins [hsi::get_pins -of_objects $upper_net]
	          lappend result_pin_list
		  foreach uppin $uppins {
			  set up_net [hsi::get_nets -boundary_type upper -of_objects $uppin]
			  if { [ llength $upper_net] != 0 && $up_net != $upper_net } {
				  set src_pins [get_real_source_pin_traverse_out $uppin]
				  if { [llength $src_pins ] != 0 } {
					  foreach temppin $src_pins {
						  lappend result_pin_list $temppin
					  }
				  }
			  }
		  }
		  if { [llength $result_pin_list] != 0 } {
		      foreach temppin $result_pin_list {
			  #set source_pins [linsert $source_pins 0 $result_pin_list ]
		          set source_pins [linsert $source_pins 0 $temppin  ]
		      }
		  }
	  }
      }
    return $source_pins
}

proc get_real_source_pin_traverse_in { pin } {

    lappend source_pins
    
    set hasCells [hsi::get_cells -of_objects $pin]
    if { [ llength $hasCells] == 0 } {
      return $source_pins
    }
    
    set ipname [hsi get_property IP_NAME [hsi::get_cells -of_objects $pin]]
    set source_type [hsi get_property BD_TYPE [hsi::get_cells -of_objects $pin]]
    if { [ string match -nocase $source_type "block_container" ] || [ string match -nocase $ipname "versal_cips" ] || [ string match -nocase $ipname "pspmc" ] || [ string match -nocase $ipname "psxl" ] || [ string match -nocase $ipname "psx_wizard" ] || [ string match -nocase $ipname "pmcps" ] || [ string match -nocase $ipname "ps_wizard" ] } {

        set lower_net [hsi::get_nets -boundary_type lower -of_objects $pin]
        set upper_net [hsi::get_nets -boundary_type upper -of_objects $pin]
        
        if { [ llength $lower_net] != 0  && [ llength $upper_net] != 0 } {

            set real_source_pin [hsi::get_pins -of_objects $lower_net -filter "DIRECTION==O" ]

            # removing the pin from where the traversal started or from where the funtion is called 
            set real_source_pin [remove_pin_from_list $real_source_pin $pin]

            set real_source_port [hsi::get_ports -of_objects $lower_net -filter "DIRECTION==I" ]
            # removing the pin from where the traversal started or from where the funtion is called 
            set real_source_port [remove_pin_from_list $real_source_port $pin]

	    lappend source_pins_cur_lvl
            if { [ llength $real_source_pin] != 0 } {
                set source_pins_cur_lvl [linsert $source_pins_cur_lvl 0 $real_source_pin ]
            }
            if { [llength $real_source_port] != 0 } {
                set source_pins_cur_lvl [linsert $source_pins_cur_lvl 0 $real_source_port]
            }


	    lappend real_source_pins_recurse
	    lappend hier_pins
	    foreach itr_source_pin $source_pins_cur_lvl {

                    set itr_source_pins_recurse [get_real_source_pin_traverse_in $itr_source_pin]
                    foreach temppin $itr_source_pins_recurse {
                            set real_source_pins_recurse [linsert $real_source_pins_recurse 0 $temppin ]
                    }
                    if { [llength $itr_source_pins_recurse] != 0 } {
                            set hier_pins [linsert $hier_pins 0 $itr_source_pin]
                    }

	    }
	    foreach itr_src_pin $hier_pins {
                    set source_pins_cur_lvl [remove_pin_from_list $source_pins_cur_lvl $itr_src_pin ]
            }
	    if { [llength $real_source_pins_recurse] != 0 } {
                    foreach itr_pin $real_source_pins_recurse {
			 set source_pins [linsert $source_pins 0 $itr_pin ]
                    }
            }

            if { [ llength $source_pins_cur_lvl] != 0 } {
	        foreach temppin $source_pins_cur_lvl {
                    #set source_pins [linsert $source_pins 0 $source_pins_cur_lvl ]
                    set source_pins [linsert $source_pins 0 $temppin  ]
	        }
            }

            #if { [ llength $source_pins] != 0 } {
            #       return [get_real_source_pin_traverse_in $source_pins]
            #}
        } 
    }
    
    if { [ llength $source_pins] == 0 } {
            return $pin
    }
    
    return $source_pins
}

#
# Find net of a peripheral pin object
#
proc get_net_of_perifh_pin {periph_pin sig_nets} {
    
    if { [ llength $sig_nets ] == 1 } {
        set got_net [lindex $sig_nets 0]
        return $got_net
    }

    set found 0
    set got_net ""
    set cell [hsi::get_cells -of_objects $periph_pin]
    foreach sig_net $sig_nets {
        if {$sig_net != ""} {
            set both_cells [hsi::get_cells -of_objects $sig_net]
            foreach single_cell $both_cells {
                if {$single_cell == $cell } {
                    set got_net $sig_net
                    set found 1
                    break;
                }
            }
            if {$found} {
            break;
            }
        }
    }
    return $got_net
}


#
# Get the sink pins of a peripheral pin object
#
proc get_sink_pins {periph_pin} {
   set net [hsi::get_nets -of_objects $periph_pin]
   set cell [hsi::get_cells -of_objects $periph_pin]
   if { [llength $net] == 0} {
       return [lappend return_value] 
   } else {
       set signals [split [hsi::get_property NAME $net] "&"]
       lappend source_pins
       if { [llength $signals] == 1 } {
       foreach signal $signals {
           set signal [string trim $signal]
           if { $cell == "" } {
               set sig_net [hsi::get_nets $signal]
           } else {
               set sig_net [hsi::get_nets -of_objects $cell $signal]
           }
           
           #Direct out pins
           set pins [hsi::get_pins -of_objects $sig_net -filter { DIRECTION==I}]
           if { [ llength $pins] != 0 } {
               foreach source_pin $pins { 
                   set source_pins [linsert $source_pins 0 $source_pin ]
               }
           }
           set source_ports [hsi::get_ports -of_objects $sig_net -filter {DIRECTION==O}]
           if { [llength $source_ports] != 0 } {
               foreach source_port $source_ports { 
                   set source_pins [linsert $source_pins 0 $source_port]
               }
           }

           lappend real_sink_pins
           if { [ llength $source_pins] != 0 } {
               foreach test_pin $source_pins {
                    set real_sink_pin [get_real_sink_pins_traverse_in $test_pin]
                    if { [ llength $real_sink_pin] != 0 } {
                        foreach real_pin $real_sink_pin {
                          set real_sink_pins [linsert $real_sink_pins end $real_pin]
                        }
                    }
               }
            }
            set real_sink_pin [get_real_sink_pins_traverse_out $periph_pin]
	    lappend result_real_sink_pin
	    lappend pins_to_retain
	    foreach outpin $real_sink_pin {
		    set inpin [get_real_sink_pins_traverse_in $outpin]
		    if { [llength $inpin ] == 0 } {
			    set pins_to_retain [linsert $pins_to_retain end $outpin]
		    }
		    foreach tpin $inpin {
			    set result_real_sink_pin [linsert $result_real_sink_pin end $tpin]
		    }
	    }
	    lappend temp_result_pins
	    foreach tpin $pins_to_retain {
		    set temp_result_pins [linsert $temp_result_pins end $tpin ]
	    }
	    foreach tpin $result_real_sink_pin {
		    set temp_result_pins [linsert $temp_result_pins end $tpin ]
	    }
	    set real_sink_pin $temp_result_pins

            if { [ llength $real_sink_pin] != 0 } {
                foreach real_pin $real_sink_pin {
                  set real_sink_pins [linsert $real_sink_pins end $real_pin]
                }
            }
        if { [llength $real_sink_pins] != 0 } {
                return $real_sink_pins
        }
         }
       } else {

        foreach signal $signals {
            set signal [string trim $signal]
            set sig_nets [hsi::get_nets $signal]
            set got_net [get_net_of_perifh_pin $periph_pin $sig_nets]
            set pins [hsi::get_pins -of_objects $got_net -filter { DIRECTION==I}]
            if { [ llength $pins] != 0 } {
                foreach source_pin $pins { 
                    set source_pins [linsert $source_pins 0 $source_pin ]
                }
            }
            set source_ports [hsi::get_ports -of_objects $got_net -filter {DIRECTION==O}]
            if { [llength $source_ports] != 0 } {
                foreach source_port $source_ports { 
                   set source_pins [linsert $source_pins 0 $source_port]
                }
            }
        }
       }
       
       return $source_pins
       
   }
}

proc get_real_sink_pins_traverse_in { test_pin } {

    lappend source_pins
    set hasCells [hsi::get_cells -of_objects $test_pin]
    if { [ llength $hasCells] == 0 } {
      return $source_pins
    }
    set ipname [hsi get_property IP_NAME [hsi::get_cells -of_objects $test_pin]]
    set source_type [hsi get_property BD_TYPE [hsi::get_cells -of_objects $test_pin]]
    if { [ string match -nocase $source_type "block_container" ] || [ string match -nocase $ipname "ps11" ] || [ string match -nocase $ipname "ps11xgui" ] || [ string match -nocase $ipname "psxt" ] || [ string match -nocase $ipname "versal_cips" ] || [ string match -nocase $ipname "pspmc" ] || [ string match -nocase $ipname "psxl" ] || [ string match -nocase $ipname "psx_wizard" ] || [ string match -nocase $ipname "pmcps" ] || [ string match -nocase $ipname "ps_wizard" ]} {
    
        set lower_net [hsi::get_nets -boundary_type lower -of_objects $test_pin]
        set upper_net [hsi::get_nets -boundary_type upper -of_objects $test_pin]
        
        if { [ llength $lower_net] != 0  && [ llength $upper_net] != 0 } {
         
            set real_sink_pins [hsi::get_pins -of_objects $lower_net -filter "DIRECTION==I" ]
            # removing the pin form where the traversal started or from where the funtion is called 
            set real_sink_pins [remove_pin_from_list $real_sink_pins $test_pin]
            
	    lappend sink_pins_cur_lvl
            if { [ llength $real_sink_pins] != 0 } {
                foreach sink_pin $real_sink_pins {
                    set sink_pins_cur_lvl [linsert $sink_pins_cur_lvl 0 $sink_pin ]
                }
            }
            
            set real_sink_ports [hsi::get_ports -of_objects $lower_net -filter "DIRECTION==O" ]
            # removing the pin form where the traversal started or from where the funtion is called 
            set real_sink_ports [remove_pin_from_list $real_sink_ports $test_pin]
            
            if { [llength $real_sink_ports] != 0 } {
                foreach sink_port $real_sink_ports {
                    set sink_pins_cur_lvl [linsert $sink_pins_cur_lvl 0 $sink_port]
                }
            }

	    #Need to recursively go into the hierarchies
	    lappend real_sink_pins_recurse
	    lappend hier_pins
	    foreach itr_sink_pin $sink_pins_cur_lvl {
		    set itr_sink_pins_recurse [get_real_sink_pins_traverse_in $itr_sink_pin]
		    foreach temppin $itr_sink_pins_recurse {
			    set real_sink_pins_recurse [linsert $real_sink_pins_recurse 0 $temppin ]
		    }

		    if { [llength $itr_sink_pins_recurse] != 0 } {
                            set hier_pins [linsert $hier_pins 0 $itr_sink_pin]
                    }
	    }

	    foreach itr_sink_pin $hier_pins {
                    set sink_pins_cur_lvl [remove_pin_from_list $sink_pins_cur_lvl $itr_sink_pin ]
            }
	    if { [ llength $sink_pins_cur_lvl] != 0 } {
	        foreach temppin $sink_pins_cur_lvl {
                    #set source_pins [linsert $source_pins 0 $sink_pins_cur_lvl ]
                    set source_pins [linsert $source_pins 0 $temppin  ]
	        }
            }

	    if { [llength $real_sink_pins_recurse] != 0 } {
                    foreach itr_pin $real_sink_pins_recurse {
                  	 set source_pins [linsert $source_pins 0 $itr_pin ]
                }
            }
		    
        }
    } else {
         set source_pins [linsert $source_pins 0 $test_pin]
    }
    
    return $source_pins
}

proc get_real_sink_pins_traverse_out_recurse { periph_pin } {

	lappend sink_pins
	set hasCells [hsi::get_cells -of_objects $periph_pin]
         set ipname [hsi get_property IP_NAME [hsi::get_cells -of_objects $periph_pin]]
         set source_type [hsi get_property BD_TYPE [hsi::get_cells -of_objects $periph_pin]]
		 if { [ string match -nocase $source_type "block_container" ] || [ string match -nocase $ipname "versal_cips" ] || [ string match -nocase $ipname "pspmc" ] || [ string match -nocase $ipname "psxl" ] || [ string match -nocase $ipname "psx_wizard" ] || [ string match -nocase $ipname "pmcps" ] || [ string match -nocase $ipname "ps_wizard" ] } {
         
            set lower_net [hsi::get_nets -boundary_type lower -of_objects $periph_pin]
            set upper_net [hsi::get_nets -boundary_type upper -of_objects $periph_pin]
            
            if { [ llength $lower_net] != 0  && [ llength $upper_net] != 0 } {
               
                set real_sink_pins [hsi::get_pins -of_objects $upper_net -filter "DIRECTION==I" ]
                # removing the pin from where the traversal started or from where the funtion is called 
                set real_sink_pins [remove_pin_from_list $real_sink_pins $periph_pin]
            
                set real_sink_ports [hsi::get_ports -of_objects $upper_net -filter "DIRECTION==O" ]
                # removing the pin from where the traversal started or from where the funtion is called 
                set real_sink_ports [remove_pin_from_list $real_sink_ports $periph_pin]
                                                                                                                        
                lappend sink_pins_cur_lvl
                if { [ llength $real_sink_pins] != 0 } {
                    foreach sink_pin $real_sink_pins { 
                        set sink_pins_cur_lvl [linsert $sink_pins_cur_lvl 0 $sink_pin ]
                    }
                }
            
                if { [llength $real_sink_ports] != 0 } {
                    foreach sink_port $real_sink_ports { 
                        set sink_pins_cur_lvl [linsert $sink_pins_cur_lvl 0 $sink_port]
                    }
                }
                                                                                                                        
                #Need to recursively go into the hierarchies
                lappend real_sink_pins_recurse
                lappend hier_pins
                foreach itr_sink_pin $real_sink_pins {
             	   set itr_sink_pins_recurse [get_real_sink_pins_traverse_out_recurse $itr_sink_pin]
             	   foreach temppin $itr_sink_pins_recurse {
             		   set real_sink_pins_recurse [linsert $real_sink_pins_recurse 0 $temppin ]
             	   }
             	   if { [llength $itr_sink_pins_recurse] != 0 } {
                                set hier_pins [linsert $hier_pins 0 $itr_sink_pin]
                        }
                                                                                                                        
                }
                                                                                                                        
                foreach itr_sink_pin $hier_pins {
                        set sink_pins_cur_lvl [remove_pin_from_list $sink_pins_cur_lvl $itr_sink_pin ]
                }
                if { [ llength $sink_pins_cur_lvl] != 0 } {
		    foreach temppin $sink_pins_cur_lvl {
                        #set sink_pins [linsert $sink_pins 0 $sink_pins_cur_lvl ]
                        set sink_pins [linsert $sink_pins 0 $temppin  ]
	            }
                }
                                                                                                                        
                if { [llength $real_sink_pins_recurse] != 0 } {
             	   foreach sink_pin $real_sink_pins_recurse {
             		   set sink_pins  [linsert $sink_pins 0 $sink_pin ]
                    }
                }
            }
         }
	 if { [ llength $sink_pins] != 0 } {
             return $sink_pins
         }

}

proc get_real_sink_pins_traverse_out { periph_pin } {

    #InDirect out pins
    set hasCells [hsi::get_cells -of_objects [hsi::get_pins $periph_pin]]
    lappend source_pins
    set sig_net [hsi::get_nets -of_objects $periph_pin]
    set pins [hsi::get_pins -of_objects $sig_net -filter {DIRECTION==O}]
    if { [ llength $pins] != 0 } {
        foreach source_pin $pins { 
            set source_pins [linsert $source_pins 0 $source_pin ]
        }
    }
    set source_ports [hsi::get_ports -of_objects $sig_net -filter {DIRECTION==I}]
    if { [llength $source_ports] != 0 } {
        foreach source_port $source_ports { 
            set source_pins [linsert $source_pins 0 $source_port]
        }
    }
    lappend sink_pins
    if { [ llength $source_pins] != 0 } {
        foreach test_pin $source_pins {
            set hasCells [hsi::get_cells -of_objects $test_pin]
            if { [ llength $hasCells] == 0 } {
              continue
            }
	    set sink_pins_recurse [get_real_sink_pins_traverse_out_recurse $test_pin]
            if { [llength $sink_pins_recurse] != 0 } {
		foreach temppin $sink_pins_recurse {
                    #set sink_pins [linsert $sink_pins 0 $sink_pins_recurse]
                    set sink_pins [linsert $sink_pins 0 $temppin ]
	        }
            }
         } 
     }
     if { [ llength $sink_pins] != 0 } {
         return $sink_pins
     }
}


#
# get the pin count which are connected to peripheral pin
#
proc get_connected_pin_count { periph_pin } {
    set total_width 0
    set cell [hsi::get_cells -of_objects $periph_pin]
    set connected_nets [hsi::get_nets -of_objects $periph_pin]
    set signals [split $connected_nets "&"]
    if { [llength $signals] == 1 } {
     foreach signal $signals {
        set width 0
        set signal [string trim $signal]
      set sig_nets [hsi::get_nets -of_object $cell $signal]
      if { [llength $sig_nets] == 0 } {
            continue
        }
      set signal [string trim $signal]
      set got_net [get_net_of_perifh_pin $periph_pin $sig_nets]
      set source_port [hsi::get_ports -of_objects $got_net]
        if {[llength $source_port] != 0 } {
            set width [get_port_width $source_port]
        } else {
            set source_pin [hsi::get_pins -of_objects $got_net -filter {DIRECTION==O}]
            if { [llength $source_pin] ==0 } {
                # handling team BD case 
                set source_pin [get_source_pins $periph_pin]
                if { [llength $source_pin] ==0 } {
                    continue
                }
            }
            set width [get_port_width $source_pin]
        }
        set total_width [expr {$total_width + $width}]
     }
    } else {
     foreach signal $signals {
        set width 0
        set signal [string trim $signal]
      set sig_nets [hsi::get_nets $signal]
      if { [llength $sig_nets] == 0 } {
            continue
        }
      set signal [string trim $signal]
      set got_net [get_net_of_perifh_pin $periph_pin $sig_nets]
      set source_port [hsi::get_ports -of_objects $got_net]
        if {[llength $source_port] != 0 } {
            set width [get_port_width $source_port]
        } else {
            set source_pin [hsi::get_pins -of_objects $got_net -filter {DIRECTION==O}]
            if { [llength $source_pin] ==0 } {
                continue
            }
            set width [get_port_width $source_pin]
        }
        set total_width [expr {$total_width + $width}]
     }
    }
    return $total_width
}

# 
# Returns name of the p2p peripheral if arg is present
# 
proc get_p2p_name {periph arg} {
   set p2p_name ""
   
   # Get all point2point buses for periph 
   set p2p_busifs_i [hsi::get_intf_pins -of_objects $periph -filter "TYPE==INITIATOR"]
   
   # Add p2p periphs 
   foreach p2p_busif $p2p_busifs_i {
       set intf_net [hsi::get_intf_nets -of_objects $p2p_busif]
       if { $intf_net ne "" } {
           # set conn_busif_handle [hsi::get_intf_pins -of_objects $intf_net -filter "TYPE==TARGET"]
           set intf_type "TARGET"
           set conn_busif_handles [get_other_intf_pin $intf_net $p2p_busif]
           set conn_busif_handle [get_intf_pin_oftype $conn_busif_handles $intf_type 1]
           if { [string compare -nocase $conn_busif_handle ""] != 0} { 
               set p2p_periph [hsi::get_cells -of_objects $conn_busif_handle]
               if { $p2p_periph ne "" } {
                   set value [hsi get_property $arg $p2p_periph]
                   if { [string compare -nocase $value ""] != 0} { 
                       return [get_ip_param_name $p2p_periph $arg]
                   }
               }
           }
       }
    }
   
   return $p2p_name
}

#
# it returns all the processor instance object in design
#
proc get_procs { } {
   return [hsi::get_cells  -hier -filter { IP_TYPE==PROCESSOR}]
}

#
# Get the interrupt ID of a peripheral interrupt port
#
proc get_port_intr_id { periph_name intr_port_name } {
    return [get_interrupt_id $periph_name $intr_port_name]
}
#
# It will check the is peripheral is interrupt controller or not
#
proc is_intr_cntrl { periph_name } {
    set ret 0

    if { [llength $periph_name] != 0 } {
    set periph [hsi::get_cells -hier -filter "NAME==$periph_name"]
    if { [llength $periph] == 1 } {
        set special [hsi get_property CONFIG.EDK_SPECIAL $periph]
        set ip_type [hsi get_property IP_TYPE $periph]
        if {[string compare -nocase $special "interrupt_controller"] == 0  || 
            [string compare -nocase $special "INTR_CTRL"] == 0 || 
            [string compare -nocase $ip_type "INTERRUPT_CNTLR"] == 0 } {
                set ret 1
        }
    }
    }
    return $ret
}

#
# It needs IP name and interrupt port name and it will return the connected 
# interrupt controller
# for External interrupt port, IP name should be empty
#
proc get_connected_intr_cntrl { periph_name intr_pin_name } {
    lappend intr_cntrl
    if { [llength $intr_pin_name] == 0 } {
        return $intr_cntrl
    }

    if { [llength $periph_name] != 0 } {
        #This is the case where IP pin is interrupting
        set periph [hsi::get_cells -hier -filter "NAME==$periph_name"]
        if { [llength $periph] == 0 } {
            return $intr_cntrl
        }
        set intr_pin [hsi::get_pins -of_objects $periph -filter "NAME==$intr_pin_name"]
        if { [llength $intr_pin] == 0 } {
            return $intr_cntrl
        }
        set pin_dir [hsi get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "I"] } {
          return $intr_cntrl
        }
    } else {
        #This is the case where External interrupt port is interrupting
        set intr_pin [hsi::get_ports $intr_pin_name]
        if { [llength $intr_pin] == 0 } {
            return $intr_cntrl
        }
        set pin_dir [hsi get_property DIRECTION $intr_pin]
        if { [string match -nocase $pin_dir "O"] } {
          return $intr_cntrl
        }
    }

    set intr_sink_pins [get_sink_pins $intr_pin]
    foreach intr_sink $intr_sink_pins {
        #changes made to fix CR 933826
        set sink_periph [lindex [hsi::get_cells -of_objects $intr_sink] 0]
        if { [llength $sink_periph ] && [is_intr_cntrl $sink_periph] == 1 } {
            lappend intr_cntrl $sink_periph
        } elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlconcat" "ilconcat"})} {
            #this the case where interrupt port is connected to XLConcat IP.
            #changes made to fix CR 933826 
            set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "dout"]]
        } elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"xlslice" "ilslice"})} {
            set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "Dout"]]
        } elseif { [llength $sink_periph] && ([get_ip_property $sink_periph IP_NAME] in {"util_reduced_logic" "ilreduced_logic"})} {
            set intr_cntrl [list {*}$intr_cntrl {*}[get_connected_intr_cntrl $sink_periph "Res"]]
        }
    }
    return $intr_cntrl
}

#
# It will get the version information from IP VLNV property 
#
proc get_ip_version { ip_name } {
    set version ""
    set ip_handle [hsi::get_cells -hier $ip_name]
    if { [llength $ip_handle] == 0 } {
        error "ERROR:IP $ip_name does not exist in design"
        return ""
    }
    set vlnv [hsi get_property VLNV $ip_handle]
    set splitted_vlnv [split $vlnv ":"]
    if { [llength $splitted_vlnv] == 4 } {
        set version [lindex $splitted_vlnv 3]
    } else {
        #TODO: Keeping older EDK xml support. It should be removed
        set version [hsi get_property HW_VER $ip_handle]
    }
    return $version
}

#
# It will return IP param value
#
proc get_ip_param_value { ip param} {
    set value [hsi get_property $param $ip]
    if {[llength $value] != 0} {
        return $value
    }
    set value [hsi get_property CONFIG.$param $ip] 
    if {[llength $value] != 0} {
        return $value
    }
}

#
# It will return board name
#
proc get_board_name { } {
    global board_name
    set board_name [hsi get_property BOARD [hsi::current_hw_design] ]
     if { [llength $board_name] == 0 } {
        set board_name "."
    }
    return $board_name
}

proc get_trimmed_param_name { param } {
    set param_name $param
    regsub -nocase ^CONFIG. $param_name "" param_name
    regsub -nocase ^C_ $param_name "" param_name
    return $param_name
}
#
# It returns the ip subtype. First its check for special type of EDK_SPECIAL parameter
#
proc get_ip_sub_type { ip_inst_object} {
    if { [string compare -nocase cell [hsi get_property CLASS $ip_inst_object]] != 0 } {
        error "get_mem_type API expect only mem_range type object whereas $class type object is passed"
    }

    set ip_type [hsi get_property CONFIG.EDK_SPECIAL $ip_inst_object]
    if { [llength $ip_type] != 0 } {
        return $ip_type
    }

    set ip_name [hsi get_property IP_NAME $ip_inst_object]
    if { [string compare -nocase "$ip_name"  "lmb_bram_if_cntlr"] == 0
        || [string compare -nocase "$ip_name" "isbram_if_cntlr"] == 0
        || [string compare -nocase "$ip_name" "axi_bram_ctrl"] == 0
        || [string compare -nocase "$ip_name" "dsbram_if_cntlr"] == 0
        || [string compare -nocase "$ip_name" "ps7_ram"] == 0 } {
            set ip_type "BRAM_CTRL"
    } elseif { [string match -nocase *ddr* "$ip_name" ] == 1 } {
         set ip_type "DDR_CTRL"
     } elseif { [string compare -nocase "$ip_name" "mpmc"] == 0 } {
         set ip_type "DRAM_CTRL"
     } elseif { [string compare -nocase "$ip_name" "axi_emc"] == 0 } {
         set ip_type "SRAM_FLASH_CTRL"
     } elseif { [string compare -nocase "$ip_name" "psu_ocm_ram_0"] == 0 
                || [string compare -nocase "$ip_name" "psu_ocm_ram_1"] == 0
                || [string compare -nocase "$ip_name" "psv_ocm_ram_0"] == 0 } {
         set ip_type "OCM_CTRL"
     } else {
         set ip_type [hsi get_property IP_TYPE $ip_inst_object]
     }
     return $ip_type
}

proc generate_psinit { } {
    set obj [hsi::get_cells -hier -filter {CONFIGURABLE == 1}]
    if { [llength $obj] == 0 } {
      set xmlpath [hsi get_property PATH [hsi::current_hw_design]]
      if { $xmlpath != "" } {
        set xmldir [file dirname $xmlpath]
        set file "$xmldir[file separator]ps7_init.c"
        if { [file exists $file] } {
          file copy -force $file .
        }
        
        set file "$xmldir[file separator]ps7_init.h"
        if { [file exists $file] } {
          file copy -force $file .
        }
      }
    } else {
      generate_target {psinit} $obj -dir .
    }
}



