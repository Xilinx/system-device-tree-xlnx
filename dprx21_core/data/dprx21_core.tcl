#
# (C) Copyright 2014-2022 Xilinx, Inc.
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


proc dprx21_core_generate {drv_handle} {
	set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
	set dts_file [set_drv_def_dts $drv_handle]
	set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1
	# ENABLE_DSC is an integer here and the string true on the transmit core, so
	# the value is tested as a boolean rather than compared against 1. Emit the
	# property only when the design builds DSC in, which leaves the macro
	# undefined everywhere else and drops the driver's DSC code at compile time.
	# The property has to be unset rather than left alone, because the generic
	# parameter dump would otherwise emit it as <0> and define the macro.
	set enable_dsc [get_ip_property $drv_handle CONFIG.ENABLE_DSC]
	if {[string is boolean -strict $enable_dsc] && $enable_dsc} {
		add_prop "${node}" "xlnx,enable-dsc" 1 int $dts_file 1
	} else {
		pldt unset $node "xlnx,enable-dsc"
	}

}
