#
# (C) Copyright 2025 - 2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

global is_versal_2ve_2vm_custom_eio_platform
set is_versal_2ve_2vm_custom_eio_platform 0

proc part_specific_init_proclist {} {
	global is_versal_2ve_2vm_custom_eio_platform
	set device [hsi get_property DEVICE [hsi::current_hw_design]]
	if {$device == "xa2ve3288"} {
		set is_versal_2ve_2vm_custom_eio_platform 1
		variable ::sdtgen::namespacelist
		dict set ::sdtgen::namespacelist "seio_spi" "spips"
		dict set ::sdtgen::namespacelist "seio_gpio" "gpiops"
		dict set ::sdtgen::namespacelist "seio_uart" "uartps"
	}
}

proc part_specific_ps_mapping {def_ps_mapping} {
	global is_versal_2ve_2vm_custom_eio_platform
	if {$is_versal_2ve_2vm_custom_eio_platform} {
		dict unset def_ps_mapping ed000000
		dict set def_ps_mapping ed010000 label spi0_eio
		dict set def_ps_mapping ed020000 label spi1_eio
		dict set def_ps_mapping ed030000 label spi2_eio
		dict set def_ps_mapping ed040000 label spi3_eio
		dict set def_ps_mapping ed050000 label serial0_eio
		dict set def_ps_mapping ed060000 label serial1_eio
		dict set def_ps_mapping ed070000 label serial2_eio
		dict set def_ps_mapping ed080000 label gpio_eio
		dict set def_ps_mapping ed0c0000 label pcie_eio
	}
	return $def_ps_mapping
}

proc gen_part_specific_misc {} {
	global is_versal_2ve_2vm_custom_eio_platform
	if {$is_versal_2ve_2vm_custom_eio_platform} {
		update_system_dts_include "versal2-custom-eio.dtsi"
	}
}
