#
# (C) Copyright 2024 - 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc mutex_generate {drv_handle} {
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set compatible [get_comp_str $drv_handle]
	set family [get_hw_family]
	global is_64_bit_mb
	if {$family in {"microblaze" "Zynq"} && !$is_64_bit_mb} {
		set bit_format 32
	} else {
		set bit_format 64
	}

	#Delete the Mutex Core node
	pldt delete $node

	set proclist [hsi::get_cells -hier -filter IP_TYPE==PROCESSOR]

	set enable_hw_prot [hsi::get_property CONFIG.C_ENABLE_HW_PROT $drv_handle]
	set enable_user [hsi::get_property CONFIG.C_ENABLE_USER $drv_handle]
	set num_mutex [hsi::get_property CONFIG.C_NUM_MUTEX $drv_handle]
	set num_axi [hsi::get_property CONFIG.C_NUM_AXI $drv_handle]
	set ip_name [hsi::get_property IP_NAME $drv_handle]
	set name [hsi::get_property NAME $drv_handle]
	set bus_name [detect_bus_name $drv_handle]
	set dts_file pl.dtsi
	set size 0x10000

	#Create mutex nodes based on number of Axi Interfaces connected to the Mutex Core
	for {set i 0} {$i < $num_axi} {incr i} {
		set baseaddr [hsi::get_property CONFIG.C_S${i}_AXI_BASEADDR $drv_handle]
		set highaddr [hsi::get_property CONFIG.C_S${i}_AXI_HIGHADDR $drv_handle]
		set reg [gen_reg_property_format $baseaddr $highaddr $bit_format]
		set nodename_baseaddr [format %08x $baseaddr]
		set label_name ${drv_handle}_S${i}

		set node [create_node -n $label_name -l $label_name -u $nodename_baseaddr -p $bus_name -d $dts_file]

		add_prop "${node}" "xlnx,enable-hw-prot" $enable_hw_prot int $dts_file
		add_prop "${node}" "xlnx,enable-user" $enable_user int $dts_file
		add_prop "${node}" "xlnx,num-mutex" $num_mutex int $dts_file
		add_prop "${node}" "compatible" $compatible string $dts_file
		add_prop "${node}" "xlnx,ip-name" $ip_name string $dts_file
		add_prop "${node}" "xlnx,num-axi" $num_axi int $dts_file
		add_prop "${node}" "xlnx,name" $name string $dts_file
		add_prop "${node}" "status" "okay" string $dts_file
		add_prop "${node}" "reg" $reg hexlist $dts_file

		#Append generic compatible string
		pldt append $node compatible "\ \, \"xlnx,mutex\""

		#Processor mapping
		foreach proc $proclist {
			if {[catch {
				set interface_inst [hsi::get_mem_ranges -of [hsi::get_cells -hier $proc] -filter INSTANCE==$drv_handle]
			}]} {
				set interface_inst ""
			}

			# Iterate through all mutex interfaces accessible by this processor
			foreach mutex_inst $interface_inst {
				if {[llength $mutex_inst] == 0} {
					continue
				}

				set intf [hsi get_property BASE_NAME $mutex_inst]

				if {[string match "*S${i}*" $intf] && [string match "*S${i}*" $label_name]} {
					map_node_to_processor "${label_name}" $proc $reg $bit_format $baseaddr $size
					break
				}
			}
		}
	}
}
