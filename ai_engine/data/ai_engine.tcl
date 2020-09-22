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
namespace eval ai_engine { 
	proc generate {drv_handle} {
		global env
		global dtsi_fname
		set path $env(REPO)

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		set keyval [pldt append $node compatible "\ \, \"xlnx,ai_engine\""]	
		set intr_names "interrupt1"
		set intr_num "<0x0 0x94 0x1>, <0x0 0x95 0x1>, <0x0 0x96 0x1>"
		set power_domain "<&versal_firmware PM_DEV_AI>"
		add_prop $node "interrupt-names" $intr_names stringlist "pl.dtsi"
		set keyval [pldt append $node "interrupt-names" "\ \, \"interrupt2\""]	
		set keyval [pldt append $node "interrupt-names" "\ \, \"interrupt3\""]	
		add_prop $node "interrupts" $intr_num intlist "pl.dtsi"
		add_prop $node "power-domains" $power_domain intlist "pl.dtsi"
		#set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
		set dt_overlay ""
	       	if {$dt_overlay} {
        	       set bus_node "overlay2"
	       	} else {
	       	       set bus_node "amba_pl"
       		}
		set aie_npi_node [create_node -n "aie-npi" -l aie_npi -u f70a0000 -d "pl.dtsi" -p "amba_pl: amba_pl"]
		add_prop $aie_npi_node "compatible" "xlnx,ai-engine-npi" stringlist "pl.dtsi"
		set aie_npi_reg "<0x0 0xf70a0000 0x0 0x1000>"
		add_prop $aie_npi_node reg $aie_npi_reg intlist "pl.dtsi"
	}
}
