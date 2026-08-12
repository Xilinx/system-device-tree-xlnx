#
# (C) Copyright 2026 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Tcl helpers to generate the misc_props node in pcw.dtsi and hold user-defined
# properties that are required in addition to the default SDT-generated ones.
#
# misc_props is emitted in pcw.dtsi as:
#
#	/ {
#		misc_props {
#			xlnx,my-string = "value";
#			xlnx,slr-count = <1>;
#			xlnx,my-flag;
#		};
#	};
#
# Add user-defined properties in gen_misc_props_node using add_prop on
# $misc_props_node. Read design/part values via HSI as needed, for example:
#
#	set noc_cell [lindex [hsi::get_cells -hier -filter {IP_NAME==axi_noc2}] 0]
#	if {[llength $noc_cell] > 0} {
#		set my_val [hsi::get_property CONFIG.DDRMC5_I2C_MASTER $noc_cell]
#		if {![string_is_empty $my_val]} {
#			add_prop $misc_props_node "xlnx,my-string" $my_val string "pcw.dtsi"
#		}
#	}
#
#	set slrcount [common::get_property NUM_OF_SLRS [hsi get_current_part]]
#	if {$slrcount != -1} {
#		add_prop $misc_props_node "xlnx,slr-count" $slrcount int "pcw.dtsi"
#	}
#
#	add_prop $misc_props_node "xlnx,my-flag" "" boolean "pcw.dtsi"
#
# Name each property the way you want the baremetal macro/CMake variable to read.
# Downstream Lopper reads /misc_props from the SDT and generates xparameters macros
# and CMake variables. Example outputs for the properties above:
#
# xparameters.h:
#   /* xlnx,my-string */
#   #define MY_STRING "value"
#   /* xlnx,slr-count */
#   #define SLR_COUNT 0x1
#   /* xlnx,my-flag */
#   #define MY_FLAG
#
# CMake:
#   set(MY_STRING "value" CACHE STRING "xlnx,my-string")
#   set(SLR_COUNT 0x1 CACHE STRING "xlnx,slr-count")
#   set(MY_FLAG "ON" CACHE STRING "xlnx,my-flag")
#
#

# Generate the misc_props node and populate user-defined properties.
proc gen_misc_props_node {} {
	#Uncomment below lines first to add miscellaneous properties
	#create_node -n / -d "pcw.dtsi" -p root
	#set misc_props_node [create_node -n "misc_props" -d "pcw.dtsi" -p /]
	# Add additional properties here via add_prop (see examples above).
}
