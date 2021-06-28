#
# (C) Copyright 2014-2021 Xilinx, Inc.
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

namespace eval ::tclapp::xilinx::devicetree::dp {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
		set node [get_node $drv_handle]
		generate_dp_param $drv_handle $node
	}

	proc generate_dp_param {drv_handle node} {
		set periph_list [hsi::get_cells -hier]
		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		foreach periph $periph_list {
		set zynq_ultra_ps [get_property IP_NAME $periph]
			if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
				set dp_sel [get_property CONFIG.PSU__DP__LANE_SEL [hsi::get_cells -hier $periph]]
				set mode [lindex $dp_sel 0]
				set lan_sel [lindex $dp_sel 1]
				set dp_freq [get_property CONFIG.PSU__DP__REF_CLK_FREQ [hsi::get_cells -hier $periph]]
				set dp_freq "${dp_freq}000000"
				set ref_clk_list [get_property CONFIG.PSU__DP__REF_CLK_SEL [hsi::get_cells -hier $periph]]
				regsub -all {[^0-9]} [lindex $ref_clk_list 1] "" val
				if {[string match -nocase $mode "Single"]} {
					if {[string match -nocase $lan_sel "Lower"]} {
						set lan_name "dp-phy0"
						set lan_phy_type "psgtr 1 6 0 $val"
						set_drv_prop $drv_handle phy-names "$lan_name" stringlist
						set_drv_prop $drv_handle phys "$lan_phy_type" reference
					} else {
						set lan_name "dp-phy0"
						set lan_phy_type "psgtr 3 6 0 $val"
						set_drv_prop $drv_handle phy-names "$lan_name" stringlist
						set_drv_prop $drv_handle phys "$lan_phy_type" reference
					}
					set_drv_prop $drv_handle xlnx,max-lanes 1 int
				} elseif {[string match -nocase $mode "Dual"]} {
					if {[string match -nocase $lan_sel "Lower"]} {
						set lan0_phy_type "psgtr 1 6 0 $val"
						set lan1_phy_type "psgtr 0 6 1 $val"
						add_prop $node phy-names "dp-phy0  dp-phy1" stringlist $dts_file
						set phy_ids "$lan0_phy_type>, <&$lan1_phy_type"
						set_drv_prop $drv_handle phys "$phy_ids" reference
					} else {
						set lan0_phy_type "psgtr 3 6 0 $val"
						set lan1_phy_type "psgtr 2 6 1 $val"
						add_prop $node phy-names "dp-phy0  dp-phy1" stringlist $dts_file
						set phy_ids "$lan0_phy_type>, <&$lan1_phy_type"
						set_drv_prop $drv_handle phys "$phy_ids" reference
					}
					set_drv_prop $drv_handle xlnx,max-lanes 2 int
				}
			}
		}
		global env
		set path $env(REPO)

		set drvname [get_drivers $drv_handle]

		set common_file "$path/device_tree/data/config.yaml"
		if {[file exists $common_file]} {
			#error "file not found: $common_file"
		}
		set mainline_ker [get_user_config $common_file -mainline_kernel]
		if {[string match -nocase $mainline_ker "none"]} {
			set dp_list "zynqmp_dp_snd_pcm0 zynqmp_dp_snd_pcm1 zynqmp_dp_snd_card0 zynqmp_dp_snd_codec0"
			foreach dp_name ${dp_list} {
				add_prop $node "status" "okay" string "pcw.dtsi"
			}
		}
	}
}
