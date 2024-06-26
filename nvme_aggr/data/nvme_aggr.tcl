#
# (C) Copyright 2018-2022 Xilinx, Inc.
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
    proc nvme_aggr_generate {drv_handle} {
        set proc_type [get_hw_family]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        set nvme_ip [hsi::get_cells -hier $drv_handle]
        set ip_name [hsi get_property IP_NAME $nvme_ip]

        if {[is_zynqmp_platform $proc_type] || \
            [string match -nocase $proc_type "versal"]} {
                add_prop $node "#address-cells" 2 int $dts_file
                add_prop $node "#size-cells" 2 int $dts_file
                add_prop "${node}" "ranges" "" boolean $dts_file
        } elseif {[string match -nocase $proc_type "zynq"] ||
            [string match -nocase $proc_type "microblaze"]} {
                add_prop $node "#address-cells" 1 int $dts_file
                add_prop $node "#size-cells" 1 int $dts_file
                add_prop "${node}" "ranges" boolean $dts_file
        }

        set intr_val [hsi get_property CONFIG.interrupts $drv_handle]
        set intr_parent [hsi get_property CONFIG.interrupt-parent $drv_handle]
        set intr_names [hsi get_property CONFIG.interrupt-names $drv_handle]

        set ha_intr ""
        set tc_intr ""
        set mapper_intr ""
        foreach intr1 $intr_names {
                if {[string match -nocase $intr1 "hc_interrupt"]} {
                        lappend ha_intr $intr1
                }
                if {[string match -nocase $intr1 "nvme_tc_intr"]} {
                        lappend tc_intr $intr1
                }
                if {[string match -nocase $intr1 "mapper_interrupt"]} {
                        lappend tc_intr $intr1
                }
        }
        
      set periph_list [hsi::get_cells -hier]
      set nvme_inst_name [hsi::get_cells -filter {IP_NAME =~ "*nvme*"}]
        foreach periph $periph_list {
                if {[string match -nocase "${nvme_inst_name}_nvmeha_0" $periph] } {
          set addr [hsi get_property CONFIG.HA_S_AXI_LITE_OFFSET $nvme_ip]
          set addr [format %0x $addr]
                        nvme_aggr_gen_ha_node $periph $addr $node $drv_handle $proc_type $nvme_ip $intr_parent $ha_intr
                }
                if {[string match -nocase "${nvme_inst_name}_nvme_tc_0" $periph] } {
          set addr [hsi get_property CONFIG.TC_S_AXI_LITE_OFFSET $nvme_ip]
          set addr [format %0x $addr]
                        nvme_aggr_gen_tc_node $periph $addr $node $drv_handle $proc_type $nvme_ip $intr_parent $tc_intr
        }
                if {[string match -nocase "${nvme_inst_name}_nvme_mapper_0" $periph] } {
          set addr [hsi get_property CONFIG.MAPER_S_AXI_LITE_OFFSET $nvme_ip]
          set addr [format %0x $addr]
                        nvme_aggr_gen_mapper_node $periph $addr $node $drv_handle $proc_type $nvme_ip $intr_parent $mapper_intr
        }
        }
    }

    proc nvme_aggr_gen_ha_node {periph addr parent_node drv_handle proc_type nvme_ip intr_parent intr} {
        set dts_file [set_drv_def_dts $drv_handle]
        set ha_node [create_node -n "nvme_ha" -l nvme_ha_0 -u $addr -p $parent_node -d $dts_file]
        set lite_size [hsi get_property CONFIG.HA_S_AXI_LITE_SIZE $nvme_ip]
        set full_off [hsi get_property CONFIG.HA_SW_S_AXI_OFFSET $nvme_ip]
        set full_size [hsi get_property CONFIG.HA_SW_S_AXI_SIZE $nvme_ip]
        set ssd_off [hsi get_property CONFIG.HA_S_AXI_SSD_OFFSET $nvme_ip]
        set ssd_size [hsi get_property CONFIG.HA_S_AXI_SSD_SIZE $nvme_ip]
        if {[string match -nocase $proc_type "ps7_cortexa9"] ||
          [string match -nocase $proc_type "microblaze"]} {
                set ha_reg "0x$addr $lite_size $full_off $full_size $ssd_off $ssd_size"
        } else {
                set ha_reg "0x0 0x$addr 0x0 $lite_size 0x0 $full_off 0x0 $full_size 0x0 $ssd_off 0x0 $ssd_size"
        }
        add_prop "${ha_node}" "reg" $ha_reg int $dts_file
        add_prop "${ha_node}" "compatible" "xlnx,nvmeha-1.0" string $dts_file

      set intr_len [llength $intr]
      for {set i 0} {$i < $intr_len} {incr i} {
                lappend intr_num [get_intr_id $nvme_ip [lindex $intr $i]]
        }
        regsub -all "\{||\t" $intr_num {} intr_num
        regsub -all "\}||\t" $intr_num {} intr_num
        add_prop ${ha_node} "interrupts" $intr_num intlist $dts_file
        add_prop "${ha_node}" "interrupt-parent" $intr_parent reference $dts_file
      add_prop "${ha_node}" "interrupt-names" $intr stringlist $dts_file

      nvme_aggr_gen_property "CONFIG.C_NUM_SQ" "xlnx,num-sq" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_0" "xlnx,num-sq-hw-0" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_1" "xlnx,num-sq-hw-1" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_2" "xlnx,num-sq-hw-2" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_3" "xlnx,num-sq-hw-3" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_4" "xlnx,num-sq-hw-4" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_5" "xlnx,num-sq-hw-5" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_6" "xlnx,num-sq-hw-6" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_7" "xlnx,num-sq-hw-7" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_8" "xlnx,num-sq-hw-8" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_9" "xlnx,num-sq-hw-9" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_10" "xlnx,num-sq-hw-10" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_11" "xlnx,num-sq-hw-11" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_12" "xlnx,num-sq-hw-12" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_13" "xlnx,num-sq-hw-13" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_14" "xlnx,num-sq-hw-14" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_15" "xlnx,num-sq-hw-15" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_16" "xlnx,num-sq-hw-16" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_17" "xlnx,num-sq-hw-17" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_18" "xlnx,num-sq-hw-18" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_19" "xlnx,num-sq-hw-19" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_20" "xlnx,num-sq-hw-20" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_21" "xlnx,num-sq-hw-21" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_22" "xlnx,num-sq-hw-22" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_23" "xlnx,num-sq-hw-23" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_24" "xlnx,num-sq-hw-24" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_25" "xlnx,num-sq-hw-25" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_26" "xlnx,num-sq-hw-26" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_27" "xlnx,num-sq-hw-27" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_28" "xlnx,num-sq-hw-28" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_29" "xlnx,num-sq-hw-29" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_30" "xlnx,num-sq-hw-30" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_HW_31" "xlnx,num-sq-hw-31" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_0" "xlnx,num-sq-sw-0" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_1" "xlnx,num-sq-sw-1" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_2" "xlnx,num-sq-sw-2" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_3" "xlnx,num-sq-sw-3" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_4" "xlnx,num-sq-sw-4" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_5" "xlnx,num-sq-sw-5" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_6" "xlnx,num-sq-sw-6" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_7" "xlnx,num-sq-sw-7" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_8" "xlnx,num-sq-sw-8" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_9" "xlnx,num-sq-sw-9" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_10" "xlnx,num-sq-sw-10" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_11" "xlnx,num-sq-sw-11" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_12" "xlnx,num-sq-sw-12" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_13" "xlnx,num-sq-sw-13" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_14" "xlnx,num-sq-sw-14" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_15" "xlnx,num-sq-sw-15" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_16" "xlnx,num-sq-sw-16" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_17" "xlnx,num-sq-sw-17" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_18" "xlnx,num-sq-sw-18" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_19" "xlnx,num-sq-sw-19" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_20" "xlnx,num-sq-sw-20" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_21" "xlnx,num-sq-sw-21" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_22" "xlnx,num-sq-sw-22" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_23" "xlnx,num-sq-sw-23" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_24" "xlnx,num-sq-sw-24" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_25" "xlnx,num-sq-sw-25" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_26" "xlnx,num-sq-sw-26" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_27" "xlnx,num-sq-sw-27" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_28" "xlnx,num-sq-sw-28" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_29" "xlnx,num-sq-sw-29" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_30" "xlnx,num-sq-sw-30" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SQ_SW_31" "xlnx,num-sq-sw-31" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SSD" "xlnx,num-ssd" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_SQ_DEPTH_HW" "xlnx,sq-depth-hw" $nvme_ip $ha_node
      nvme_aggr_gen_property "CONFIG.C_SQ_DEPTH_SW" "xlnx,sq-depth-sw" $nvme_ip $ha_node
    }

    proc nvme_aggr_gen_tc_node {periph addr parent_node drv_handle proc_type nvme_ip intr_parent intr} {
        set dts_file [set_drv_def_dts $drv_handle]
        set tc_node [create_node -n "nvme_tc" -l nvme_tc_0 -u $addr -p $parent_node -d $dts_file]
        set lite_size [hsi get_property CONFIG.TC_S_AXI_LITE_SIZE $nvme_ip]
        set full_off [hsi get_property CONFIG.TC_SW_S_AXI_OFFSET $nvme_ip]
        set full_size [hsi get_property CONFIG.TC_SW_S_AXI_SIZE $nvme_ip]
        if {[string match -nocase $proc_type "ps7_cortexa9"] ||
          [string match -nocase $proc_type "microblaze"]} {
                set tc_reg "0x$addr $lite_size $full_off $full_size"
        } else {
                set tc_reg "0x0 0x$addr 0x0 $lite_size 0x0 $full_off 0x0 $full_size"
        }
        add_prop "${tc_node}" "reg" $tc_reg int $dts_file
        add_prop "${tc_node}" "compatible" "xlnx,nvme-tc-1.0" string $dts_file

      set intr_len [llength $intr]
        for {set i 0} {$i < $intr_len} {incr i} {
                lappend intr_num [get_intr_id $nvme_ip [lindex $intr $i]]
        }
        regsub -all "\{||\t" $intr_num {} intr_num
        regsub -all "\}||\t" $intr_num {} intr_num
        add_prop ${tc_node} "interrupts" $intr_num intlist $dts_file
        add_prop "${tc_node}" "interrupt-parent" $intr_parent reference $dts_file
        add_prop "${tc_node}" "interrupt-names" $intr stringlist $dts_file
      
      set debug_en [hsi get_property CONFIG.DEBUG_EN $nvme_ip]
      if {[string match -nocase $debug_en "true"]} {
        add_prop "${tc_node}" "xlnx,debug-en" "0x1" int $dts_file
      } else {
        add_prop "${tc_node}" "xlnx,debug-en" "0x0" int $dts_file
      }

      nvme_aggr_gen_property "CONFIG.C_ARB_BURST" "xlnx,arb-burst" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_CAP_MAX_HOST_Q_DEPTH" "xlnx,cap-max-host-q-depth" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_CAP_MPSMAX" "xlnx,cap-mpsmax" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_CAP_MPSMIN" "xlnx,cap-mpsmin" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_CAP_TIMEOUT" "xlnx,cap-timeout" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_LBA_DATA_SIZE" "xlnx,lba-data-size" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_MAX_DMA_SIZE" "xlnx,max-dma-size" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_MDTS" "xlnx,mdts" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_NUM_CMD_INDX" "xlnx,num-cmd-indx" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_NUM_FUNC" "xlnx,num-func" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_NUM_HSQ" "xlnx,num-hsq" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_NUM_SGLS_PER_INDX" "xlnx,num-sgls-per-indx" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_PERF_MON_EN" "xlnx,perf-mon-en" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_S_AXI_ID_WIDTH" "xlnx,s-axi-id-width" $nvme_ip $tc_node
      nvme_aggr_gen_property "CONFIG.C_SGL_SUPPORT" "xlnx,sgl-support" $nvme_ip $tc_node

    }  

    proc nvme_aggr_gen_mapper_node {periph addr parent_node drv_handle proc_type nvme_ip intr_parent intr} {
        set dts_file [set_drv_def_dts $drv_handle]
        set mapper_node [create_node -n "nvme_mapper" -l nvme_mapper_0 -u $addr -p $parent_node -d $dts_file]
        set lite_size [hsi get_property CONFIG.MAPPER_S_AXI_LITE_SIZE $nvme_ip]
        set full_off [hsi get_property CONFIG.MAPPER_SW_S_AXI_OFFSET $nvme_ip]
        set full_size [hsi get_property CONFIG.MAPPER_SW_S_AXI_SIZE $nvme_ip]
        if {[string match -nocase $proc_type "ps7_cortexa9"] ||
          [string match -nocase $proc_type "microblaze"]} {
                set mapper_reg "0x$addr $lite_size $full_off $full_size"
        } else {
                set mapper_reg "0x0 0x$addr 0x0 $lite_size 0x0 $full_off 0x0 $full_size"
        }
        add_prop "${mapper_node}" "reg" $mapper_reg int $dts_file
        add_prop "${mapper_node}" "compatible" "xlnx,nvme-mapper-1.0" string $dts_file

        set en_p2p [hsi get_property CONFIG.EN_P2P_BUFFERS $nvme_ip]
        if {[string match -nocase $en_p2p "true"]} {
            add_prop "${mapper_node}" "xlnx,en-p2p-buffer" boolean $dts_file
        }
        nvme_aggr_gen_property "CONFIG.MAX_PRP_PER_CMD" "xlnx,max-prp-per-cmd" $periph $mapper_node
        nvme_aggr_gen_property "CONFIG.NUM_UID_SUPPORT" "xlnx,num-uid-support" $periph $mapper_node
        nvme_aggr_gen_property "CONFIG.P2P_PF_NUM" "xlnx,p2p-pf-num" $periph $mapper_node
    }

    proc nvme_aggr_gen_property {property pro_dt_name nvme_ip node} {
      set num_sgls [hsi get_property $property $nvme_ip]
      set num_sgls 0x[format %0x $num_sgls] 
      add_prop "$node" $pro_dt_name $num_sgls int $dts_file
    }


