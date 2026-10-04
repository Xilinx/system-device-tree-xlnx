#
# (C) Copyright 2025-2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc parse_cpm6_config {config_str} {
	set result [dict create]
	set tokens [split $config_str " "]
	set len [llength $tokens]
	for {set i 0} {$i < [expr {$len - 1}]} {incr i 2} {
		dict set result [lindex $tokens $i] [lindex $tokens [expr {$i + 1}]]
	}
	return $result
}

proc cpm6_get {d key {default ""}} {
	if {[dict exists $d $key]} { return [dict get $d $key] }
	return $default
}

proc cpm6_fw_type_for_ctrl {protocol ide_cap_en link_ide_stream selective_ide_stream} {
	if {$protocol eq "" || [string match -nocase "Disabled" $protocol]} {
		return "Disabled"
	}
	if {[string match -nocase "*CXL*" $protocol]} {
		return "CXL"
	}
	# IDE stream bits are subordinate to IDE_CAP_EN in the CPM6 HSI model.
	# A design must have IDE capability enabled before it is classified as SEC.
	if {$ide_cap_en eq "1"} {
		return "SEC"
	}
	return "EMC"
}

proc cpm6_extract_ep_info {drv_handle d} {
	set f "pcw.dtsi"
	set node ""
	foreach c [hsi::get_cells -hier -filter {IP_NAME==psv_cpm6}] {
		if {![regexp "pspmc.*" "$c" match]} {
			catch {set node [get_node $c]}
			if {$node ne "" && $node ne "0" && $node != 0} { break }
		}
	}
	if {$node eq "" || $node eq "0" || $node == 0} {
		return
	}

	add_prop $node "#address-cells" 1 int $f
	add_prop $node "#size-cells" 0 int $f

	set active_ep -1
	set active_ep_count 0
	set active_ep_mask 0
	foreach i {0 1} {
		set p "CPM6_CTRL${i}"
		set en    [cpm6_get $d "${p}_EN" "0"]
		set mode  [cpm6_get $d "${p}_MODE" ""]
		set ptype [cpm6_get $d "${p}_PORT_TYPE" ""]
		set proto [cpm6_get $d "${p}_PROTOCOL" "Disabled"]
		set ide_cap_en [cpm6_get $d "${p}_IDE_CAP_EN" "0"]
		set link_ide_stream [cpm6_get $d "${p}_LINK_IDE_STREAM_EN" "0"]
		set selective_ide_stream [cpm6_get $d "${p}_SELECTIVE_IDE_STREAM_EN" "0"]
		set fwtype [cpm6_fw_type_for_ctrl $proto $ide_cap_en $link_ide_stream $selective_ide_stream]
		set lw    [cpm6_get $d "${p}_LINK_WIDTH" ""]
		set lr    [cpm6_get $d "${p}_LANE_RATE" ""]
		# PERST is stored as a MIO name (e.g. PMC_MIO_38 / PS_MIO_19); keep the trailing pin number only
		set perst_raw [cpm6_get $d "${p}_PERST" ""]
		set perst ""
		if {[regexp {([0-9]+)$} $perst_raw -> perst_num]} { set perst $perst_num }

		if {$en eq "1"} {
			set ctrl_node [create_node -n "controller@${i}" -l "${drv_handle}_ctrl${i}" -p $node -d $f]
			# Standard DT properties
			add_prop $ctrl_node "compatible" "xlnx,cpm6-controller" string $f
			add_prop $ctrl_node "reg" $i int $f
			# Controller identity
			add_prop $ctrl_node "xlnx,ctrl-id" $i int $f
			add_prop $ctrl_node "xlnx,en" $en int $f
			if {$perst ne ""} {
				add_prop $ctrl_node "xlnx,perst" $perst int $f
			}
			# Mode / type
			add_prop $ctrl_node "xlnx,mode" $mode string $f
			add_prop $ctrl_node "xlnx,port-type" $ptype string $f
			add_prop $ctrl_node "xlnx,protocol" $proto string $f
			add_prop $ctrl_node "xlnx,fw-type" $fwtype string $f
			# IDE capabilities
			add_prop $ctrl_node "xlnx,ide-cap-en" $ide_cap_en int $f
			add_prop $ctrl_node "xlnx,link-ide-stream" $link_ide_stream int $f
			add_prop $ctrl_node "xlnx,selective-ide-stream" $selective_ide_stream int $f
			if {[string match -nocase "*CXL*" $proto]} {
				add_prop $ctrl_node "xlnx,cxl-hdm-decoder-enable" [cpm6_get $d "CPM6_CXL${i}_HDM_DECODER_EN" "0"] int $f
				add_prop $ctrl_node "xlnx,cxl-num-hdm-decoders" [cpm6_get $d "CPM6_CXL${i}_NUM_HDM_DECODERS" "0"] int $f
				add_prop $ctrl_node "xlnx,cxl-range1-size" [cpm6_get $d "CPM6_CXL${i}_RANGE1_SIZE" "0"] string $f
				foreach regloc {1 2 3} {
					set bir [cpm6_get $d "CPM6_CXL${i}_REGLOC${regloc}_BIR" ""]
					set offset [cpm6_get $d "CPM6_CXL${i}_REGLOC${regloc}_OFFSET" ""]
					set regtype [cpm6_get $d "CPM6_CXL${i}_REGLOC${regloc}_REG_TYPE" ""]
					if {$bir ne ""} {
						add_prop $ctrl_node "xlnx,cxl-regloc${regloc}-bir" $bir string $f
					}
					if {$offset ne ""} {
						add_prop $ctrl_node "xlnx,cxl-regloc${regloc}-offset" $offset string $f
					}
					if {$regtype ne "" && ![string match -nocase "None" $regtype]} {
						add_prop $ctrl_node "xlnx,cxl-regloc${regloc}-type" $regtype string $f
					}
				}
			}
		}

		if {$en eq "1" && ([string match -nocase "*EP*" $ptype] || [string match -nocase "*CXL*" $ptype])} {
			incr active_ep_count
			set active_ep_mask [expr {$active_ep_mask | (1 << $i)}]
			set active_ep $i
		}
	}

	if {$active_ep == -1} {
		return
	}
}

proc cpm_pcie_generate {drv_handle} {
	foreach cell [hsi::get_cells -hier -filter {IP_NAME==ps_wizard}] {
		set avail [hsi list_property $cell]
		if {[lsearch -nocase $avail "CONFIG.CPM6_CONFIG_INTERNAL"] >= 0} {
			set cfg [hsi get_property CONFIG.CPM6_CONFIG_INTERNAL $cell]
			if {$cfg ne ""} {
				set d [parse_cpm6_config $cfg]
				set has_ep 0
				foreach ctrl {0 1} {
					set ctrl_prefix "CPM6_CTRL${ctrl}"
					set ctrl_en [cpm6_get $d "${ctrl_prefix}_EN" "0"]
					set ctrl_port_type [cpm6_get $d "${ctrl_prefix}_PORT_TYPE" ""]
					if {$ctrl_en eq "1" && ([string match -nocase "*EP*" $ctrl_port_type] || [string match -nocase "*CXL*" $ctrl_port_type])} {
						set has_ep 1
						break
					}
				}
				if {$has_ep} {
					cpm6_extract_ep_info $drv_handle $d
					return
				}
			}
		}
	}

	if {![regexp "pspmc.*" "$drv_handle" match]} {
		return
	}

	set rev_num -1
	set port_type_0 -1
	set port_type_1 -1

	foreach drv [hsi::get_cells -hier -filter IP_NAME==psv_cpm] {
		if {![regexp "pspmc.*" "$drv" match]} {
			set rev_num [get_ip_property $drv CONFIG.CPM_REVISION_NUMBER]
			set port_type_0 [get_ip_property $drv CONFIG.C_CPM_PCIE0_PORT_TYPE]
			set port_type_1 [get_ip_property $drv CONFIG.C_CPM_PCIE1_PORT_TYPE]
		}
	}

	if {($rev_num == 1) && ($port_type_1 == 1)} {
		set node [get_node $drv_handle]
		if {$node == 0} {
	            return
	        }
	        add_prop $node "xlnx,csr-slcr" 0xfcea0000 hexlist "pcw.dtsi" 1
	        add_prop $node compatible "xlnx,versal-cpm5-host1" stringlist "pcw.dtsi" 1
	        set ranges "0x02000000 0x0 0xe8000000 0x0 0xe8000000 0x0 0x8000000>,<0x43000000 0xa0 0x00000000 0xa0 0x00000000 0x0 0x80000000"
	        add_prop $node "ranges" $ranges hexlist "pcw.dtsi" 1
		set reg "0x07 0x00000000 0x00 0x10000000>,<0x00 0xfcdd0000 0x00 0x1000>,<0x00 0xfcea0000 0x00 0x10000"
	        add_prop $node "reg" $reg hexlist "pcw.dtsi" 1
	        add_prop $node "resets" "versal_reset VERSAL_RST_PCIE_CORE1" reference "pcw.dtsi" 1

	}

}
