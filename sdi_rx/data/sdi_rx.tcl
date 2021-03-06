#
# (C) Copyright 2018-2021 Xilinx, Inc.
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

proc generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	pldt append $node compatible "\ \, \"xlnx,v-smpte-uhdsdi-rx-ss\""

	set ports_node [create_node -n "ports" -l sdirx_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file
	add_prop "$ports_node" "#size-cells" 0 int $dts_file
	set port_node [create_node -n "port" -l sdirx_port$drv_handle -u 0 -p $ports_node -d $dts_file]
	add_prop "$port_node" "xlnx,video-format" 0 int $dts_file
	add_prop "$port_node" "xlnx,video-width" 10 int $dts_file
	add_prop "$port_node" "reg" 0 int $dts_file

	set sdirxip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_OUT"]
	foreach ip $sdirxip {
	if {[llength $ip]} {
                if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
                        continue
                }
                set intfpins [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                set ip_mem_handles [hsi::get_mem_ranges $ip]
                if {[llength $ip_mem_handles]} {
                        set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
                        set sdi_rx_node [create_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node -d $dts_file]
                        gen_endpoint $drv_handle "sdirx_out$drv_handle"
                        add_prop "$sdi_rx_node" "remote-endpoint" $ip$drv_handle reference $dts_file
                        gen_remoteendpoint $drv_handle $ip$drv_handle
                        if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
                                gen_frmbuf_wr_node $ip $drv_handle $dts_file
                        }
                } else {
                        set connectip [get_connect_ip $ip $intfpins $dts_file]
                        if {[llength $connectip]} {
                                set sdi_rx_node [create_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node -d $dts_file]
                                gen_endpoint $drv_handle "sdirx_out$drv_handle"
                                add_prop "$sdi_rx_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                gen_remoteendpoint $drv_handle $connectip$drv_handle
                                if {[string match -nocase [get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_frmbuf_wr_node $connectip $drv_handle $dts_file
                                }
                        }
                }
        }
}


}
proc gen_frmbuf_wr_node {outip drv_handle dts_file} {
	set bus_node [detect_bus_name $drv_handle]
	set vcap [create_node -n "vcap_sdirx$drv_handle" -p $bus_node -d $dts_file]
	add_prop $vcap "compatible" "xlnx,video" string $dts_file
	add_prop $vcap "dmas" "$outip 0" reference $dts_file
	add_prop $vcap "dma-names" "port0" string $dts_file
	set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d $dts_file]
	add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
	add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
	set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node -d $dts_file]
	add_prop "$vcap_port_node" "reg" 0 int $dts_file
	add_prop "$vcap_port_node" "direction" input string $dts_file
	set vcap_in_node [create_node -n "endpoint" -l $outip$drv_handle -p $vcap_port_node -d $dts_file]
	add_prop "$vcap_in_node" "remote-endpoint" sdirx_out$drv_handle reference $dts_file
}
