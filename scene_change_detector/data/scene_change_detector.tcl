#
# (C) Copyright 2018 Xilinx, Inc.
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

namespace eval scene_change_detector {
proc generate {drv_handle} {
#	set node [gen_peripheral_nodes $drv_handle]
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
#	set compatible "xlnx,v-scd"
#	set_drv_prop $drv_handle compatible "$compatible" stringlist
	pldt append $node compatible "\ \, \"xlnx,v-scd\""
	set ip [hsi::get_cells -hier $drv_handle]
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,max-data-width" $max_data_width int $dts_file
	set memory_scd [get_property CONFIG.MEMORY_BASED [hsi::get_cells -hier $drv_handle]]
	if {$memory_scd == 1} {
		set max_nr_streams [get_property CONFIG.MAX_NR_STREAMS [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,numstreams" $max_nr_streams int $dts_file
		add_prop $node "#address-cells" 1 int $dts_file
		add_prop $node "#size-cells" 0 int $dts_file
		add_prop $node "xlnx,memorybased" boolean $dts_file
		add_prop "$node" "#dma-cells" 1 int $dts_file
		set aximm_addr_width [get_property CONFIG.AXIMM_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,addrwidth" $aximm_addr_width hexint $dts_file
		for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
			set scd_node [create_node -n "subdev@$stream" -p $node -d $dts_file]
			set port_node [create_node -n "port@0" -l port_$stream -p $scd_node -d $dts_file]
			add_prop "$port_node" "reg" 0 int $dts_fle
			set endpoint [create_node -n "endpoint" -l scd_in$stream -p $port_node -d $dts_file]
			add_prop "$endpoint" "remote-endpoint" vcap0_out$stream reference $dts_file
		}
		#TODO SURESH
#		set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
		set dt_overlay ""
		if {$dt_overlay} {
			set bus_node "overlay2"
		} else {
			set bus_node "amba_pl"
		}
#		set dts_file [current_dt_tree]
		set dma_names ""
		set dmas ""
		set vcap_scd [create_node -n "video_cap" -l videocap -d $dts_file -p $bus_node]
		for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
			append dma_names " " "port$stream"
			set peri "$drv_handle $stream"
			set dmas [lappend dmas $peri]
		}
		add_prop "$vcap_scd" "dma-names" $dma_names stringlist
		generate_dmas $vcap_scd $dmas
		set ports_vcap [create_node -n "ports" -l ports_vcap -p $vcap_scd -d $dts_file]
		add_prop $ports_vcap "#address-cells" 1 int $dts_file
		add_prop $ports_vcap "#size-cells" 0 int $dts_file
		add_prop $vcap_scd "compatible" "xlnx,video" string $dts_file
		for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
			set port_vcap_node [create_node -n "port@$stream" -l port$stream -p $ports_vcap -d $dts_file]
			add_prop "$port_vcap_node" "reg" $stream int $dts_file
			add_prop "$port_vcap_node" "direction" output string $dts_file
			set vcap_endpoint [create_node -n "endpoint" -l vcap0_out$stream -p $port_vcap_node -d $dts_file]
			add_prop "$vcap_endpoint" "remote-endpoint" scd_in$stream reference $dts_file
		}
	} else {
		set max_nr_streams [get_property CONFIG.MAX_NR_STREAMS [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,numstreams" $max_nr_streams int $dts_file
		add_prop $node "#address-cells" 1 int $dts_file
		add_prop $node "#size-cells" 0 int $dts_file
	}
}

proc generate_dmas {vcap_scd dmas} {
	set len [llength $dmas]
	switch $len {
		"1" {
			set refs [lindex $dmas 0]
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
		"2" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]"
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
		"3" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]"
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
		"4" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]"
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
		"5" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]"
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
		"6" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]"
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
		"7" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]>, <&[lindex $dmas 6]"
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
		"8" {
			set refs [lindex $dmas 0]
			append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]>, <&[lindex $dmas 6]>, <&[lindex $dmas 7]"
			add_prop "$vcap_scd" "dmas" $refs reference $dts_file
		}
	}
}
}
