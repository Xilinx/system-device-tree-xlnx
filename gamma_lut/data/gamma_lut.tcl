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

namespace eval ::tclapp::xilinx::devicetree::gamma_lut {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		if {$node == 0} {
			return
		}
		pldt append $node compatible "\ \, \"xlnx,v-gamma-lut\""
		set gamma_ip [hsi::get_cells -hier $drv_handle]
		if 0 {
		set s_axi_ctrl_addr_width [get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int $dts_file
		set s_axi_ctrl_data_width [get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int $dts_file
		set max_rows [get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
		set max_cols [get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,max-width" $max_cols int $dts_file
		}
		set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		set ports_node [create_node -n "ports" -l gamma_ports$drv_handle -p $node -d $dts_file]
		add_prop "$ports_node" "#address-cells" 1 int $dts_file
		add_prop "$ports_node" "#size-cells" 0 int $dts_file
		set port1_node [create_node -n "port" -l gamma_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
		add_prop "$port1_node" "reg" 1 int $dts_file
		add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file

		set gammaoutip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis_video"]
		foreach outip $gammaoutip {
                if {[llength $outip]} {
                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $outip] -filter { TYPE==MASTER || TYPE == INITIATOR}]
                        set ip_mem_handles [hsi::get_mem_ranges $outip]
                        if {[llength $ip_mem_handles]} {
                                set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
                                set gammanode [create_node -n "endpoint" -l gamma_out$drv_handle -p $port1_node -d $dts_file]
                                add_prop "$gammanode" "remote-endpoint" $outip$drv_handle reference $dts_file
                                gen_endpoint $drv_handle "gamma_out$drv_handle"
                                gen_remoteendpoint $drv_handle "$outip$drv_handle"
                                if {[string match -nocase [get_property IP_NAME $outip] "v_frmbuf_wr"]} {
                                        gen_frmbuf_wr_node $outip $drv_handle $dts_file
                                }
                        } else {
                                if {[string match -nocase [get_property IP_NAME $outip] "system_ila"]} {
                                        continue
                                }
                                set connectip [get_connect_ip $outip $master_intf $dts_file]
                                if {[llength $connectip]} {
                                        set gammanode [create_node -n "endpoint" -l gamma_out$drv_handle -p $port1_node -d $dts_file]
                                        gen_endpoint $drv_handle "gamma_out$drv_handle"
                                        add_prop "$gammanode" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                        gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                                        if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                                gen_frmbuf_wr_node $connectip $drv_handle $dts_file
                                        }
                                }
                        }
                } else {
                        dtg_warning "$drv_handle pin m_axis_video is not connected..check your design"
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
		add_prop "$vcap_in_node" "remote-endpoint" gamma_out$drv_handle reference $dts_file
	}
}

