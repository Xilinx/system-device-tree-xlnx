    proc mrmac_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        set keyval [pldt append $node compatible "\ \, \"xlnx,mrmac-ethernet-1.0\""]
        set_drv_prop $drv_handle compatible "$compatible" $node stringlist
        set mrmac_ip [hsi::get_cells -hier $drv_handle]
        mrmac_gen_mrmac_clk_property $drv_handle
        global env
        set path $env(REPO)
        set common_file "$path/device_tree/data/config.yaml"
        set dt_overlay [get_user_config $common_file -dt_overlay]
            if {$dt_overlay} {
                    set bus_node "overlay2"
            } else {
                    set bus_node "amba_pl"
            }
            set dts_file [current_dt_tree]
        set mem_ranges [get_mem_ranges [hsi::get_cells -hier $drv_handle]]
        dtg_verbose "mem_ranges:$mem_ranges"
            foreach mem_range $mem_ranges {
                   set base_addr [string tolower [hsi get_property BASE_VALUE $mem_range]]
                   set base [format %x $base_addr]
                   set high_addr [string tolower [hsi get_property HIGH_VALUE $mem_range]]
                   set slave_intf [hsi get_property SLAVE_INTERFACE $mem_range]
               dtg_verbose "slave_intf:$slave_intf"
                   set ptp_comp "xlnx,timer-syncer-1588-1.0"
                   if {[string match -nocase $slave_intf "ptp_0_s_axi"]} {
                           set ptp_0_node [create_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
                           add_prop "$ptp_0_node" "compatible" "$ptp_comp" stringlist $dts_file
                           mrmac_generate_reg_property $ptp_0_node $base_addr $high_addr
                   }
                   if {[string match -nocase $slave_intf "ptp_1_s_axi"]} {
                           set ptp_1_node [create_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
                           add_prop "$ptp_1_node" "compatible" "$ptp_comp" stringlist $dts_file
                           mrmac_generate_reg_property $ptp_1_node $base_addr $high_addr
                   }
                   if {[string match -nocase $slave_intf "ptp_2_s_axi"]} {
                           set ptp_2_node [create_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
                           add_prop "$ptp_2_node" "compatible" "$ptp_comp" stringlist $dts_file
                           mrmac_generate_reg_property $ptp_2_node $base_addr $high_addr
                   }
                   if {[string match -nocase $slave_intf "ptp_3_s_axi"]} {
                           set ptp_3_node [create_node -n "ptp_timer" -l "$slave_intf" -u $base -d $dts_file -p $bus_node]
                           add_prop "$ptp_3_node" "compatible" "$ptp_comp" stringlist $dts_file
                           mrmac_generate_reg_property $ptp_3_node $base_addr $high_addr
                   }
               if {[string match -nocase $slave_intf "s_axi"]} {
                        set mrmac0_highaddr_hex [format 0x%x [expr $base_addr + 0xFFF]]
                        mrmac_generate_reg_property $node $base_addr $mrmac0_highaddr_hex
                   }
            }
            set connected_ip [get_connected_stream_ip $mrmac_ip "tx_axis_tdata0"]
        set FEC_SLICE0_CFG_C0 [hsi get_property CONFIG.C_FEC_SLICE0_CFG_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-slice0-cfg-c0" $FEC_SLICE0_CFG_C0 string $dts_file
        set FEC_SLICE0_CFG_C1 [hsi get_property CONFIG.C_FEC_SLICE0_CFG_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-slice0-cfg-c1" $FEC_SLICE0_CFG_C1 string $dts_file
        set FLEX_PORT0_DATA_RATE_C0 [hsi get_property CONFIG.C_FLEX_PORT0_DATA_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port0-data-rate-c0" $FLEX_PORT0_DATA_RATE_C0 string $dts_file
        set FLEX_PORT0_DATA_RATE_C1 [hsi get_property CONFIG.C_FLEX_PORT0_DATA_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port0-data-rate-c1" $FLEX_PORT0_DATA_RATE_C1 string $dts_file
        set FLEX_PORT0_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.C_FLEX_PORT0_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port0-enable-time-stamping-c0" $FLEX_PORT0_ENABLE_TIME_STAMPING_C0 int $dts_file
        set FLEX_PORT0_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.C_FLEX_PORT0_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port0-enable-time-stamping-c1" $FLEX_PORT0_ENABLE_TIME_STAMPING_C1 int $dts_file
        set FLEX_PORT0_MODE_C0 [hsi get_property CONFIG.C_FLEX_PORT0_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port0-mode-c0" $FLEX_PORT0_MODE_C0 string $dts_file
        set FLEX_PORT0_MODE_C1 [hsi get_property CONFIG.C_FLEX_PORT0_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,flex-port0-mode-c1" $FLEX_PORT0_MODE_C1 string $dts_file
        set PORT0_1588v2_Clocking_C0 [hsi get_property CONFIG.PORT0_1588v2_Clocking_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,port0-1588v2-clocking-c0" $PORT0_1588v2_Clocking_C0 string $dts_file
        set PORT0_1588v2_Clocking_C1 [hsi get_property CONFIG.PORT0_1588v2_Clocking_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,port0-1588v2-clocking-c1" $PORT0_1588v2_Clocking_C1 string $dts_file
        set PORT0_1588v2_Operation_MODE_C0 [hsi get_property CONFIG.PORT0_1588v2_Operation_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,port0-1588v2-operation-mode-c0" $PORT0_1588v2_Operation_MODE_C0 string $dts_file
        set PORT0_1588v2_Operation_MODE_C1 [hsi get_property CONFIG.PORT0_1588v2_Operation_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,port0-1588v2-operation-mode-c1" $PORT0_1588v2_Operation_MODE_C1 string $dts_file
        set MAC_PORT0_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.MAC_PORT0_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-enable-time-stamping-c0" $MAC_PORT0_ENABLE_TIME_STAMPING_C0 int $dts_file
        set MAC_PORT0_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.MAC_PORT0_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-enable-time-stamping-c1" $MAC_PORT0_ENABLE_TIME_STAMPING_C1 int $dts_file
        set MAC_PORT0_RATE_C0 [hsi get_property CONFIG.MAC_PORT0_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $MAC_PORT0_RATE_C0 "10GE"]} {
                   set number 10000
                add_prop "${node}" "xlnx,mrmac-rate" $number int $dts_file
            } else {
                add_prop "${node}" "xlnx,mrmac-rate" $MAC_PORT0_RATE_C0 string $dts_file
        }
        add_prop "${node}" "xlnx,mac-port0-rate-c0" $MAC_PORT0_RATE_C0 string $dts_file
        set MAC_PORT0_RATE_C1 [hsi get_property CONFIG.MAC_PORT0_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rate-c1" $MAC_PORT0_RATE_C1 string $dts_file
        set MAC_PORT0_RX_ETYPE_GCP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-gcp-c0" $MAC_PORT0_RX_ETYPE_GCP_C0 int $dts_file
        set MAC_PORT0_RX_ETYPE_GCP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-gcp-c1" $MAC_PORT0_RX_ETYPE_GCP_C1 int $dts_file
        set MAC_PORT0_RX_ETYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-gpp-c0" $MAC_PORT0_RX_ETYPE_GPP_C0 int $dts_file
        set MAC_PORT0_RX_ETYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-gpp-c1" $MAC_PORT0_RX_ETYPE_GPP_C1 int $dts_file
        set MAC_PORT0_RX_ETYPE_PCP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-pcp-c0" $MAC_PORT0_RX_ETYPE_PCP_C0 int $dts_file
        set MAC_PORT0_RX_ETYPE_PCP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-pcp-c1" $MAC_PORT0_RX_ETYPE_PCP_C1 int $dts_file
        set MAC_PORT0_RX_ETYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-ppp-c0" $MAC_PORT0_RX_ETYPE_PPP_C0 int $dts_file
        set MAC_PORT0_RX_ETYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_ETYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-etype-ppp-c1" $MAC_PORT0_RX_ETYPE_PPP_C1 int $dts_file
        set MAC_PORT0_RX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT0_RX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-flow-c0" $MAC_PORT0_RX_FLOW_C0 int $dts_file
        set MAC_PORT0_RX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT0_RX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-flow-c1" $MAC_PORT0_RX_FLOW_C1 int $dts_file
        set MAC_PORT0_RX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-gpp-c0" $MAC_PORT0_RX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT0_RX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-gpp-c1" $MAC_PORT0_RX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT0_RX_OPCODE_MAX_GCP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-max-gcp-c0" $MAC_PORT0_RX_OPCODE_MAX_GCP_C0 int $dts_file
        set MAC_PORT0_RX_OPCODE_MAX_GCP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-max-gcp-c1" $MAC_PORT0_RX_OPCODE_MAX_GCP_C1 int $dts_file
        set MAC_PORT0_RX_OPCODE_MAX_PCP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-max-pcp-c0" $MAC_PORT0_RX_OPCODE_MAX_PCP_C0 int $dts_file

        set MAC_PORT0_RX_OPCODE_MAX_PCP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MAX_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-max-pcp-c1" $MAC_PORT0_RX_OPCODE_MAX_PCP_C1 int $dts_file
        set MAC_PORT0_RX_OPCODE_MIN_GCP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-min-gcp-c0" $MAC_PORT0_RX_OPCODE_MIN_GCP_C0 int $dts_file
        set MAC_PORT0_RX_OPCODE_MIN_GCP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-min-gcp-c1" $MAC_PORT0_RX_OPCODE_MIN_GCP_C1 int $dts_file
        set MAC_PORT0_RX_OPCODE_MIN_PCP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-min-pcp-c0" $MAC_PORT0_RX_OPCODE_MIN_PCP_C0 int $dts_file
        set MAC_PORT0_RX_OPCODE_MIN_PCP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_MIN_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-min-pcp-c1" $MAC_PORT0_RX_OPCODE_MIN_PCP_C1 int $dts_file
        set MAC_PORT0_RX_OPCODE_PPP_C0 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-ppp-c0" $MAC_PORT0_RX_OPCODE_PPP_C0 int $dts_file
        set MAC_PORT0_RX_OPCODE_PPP_C1 [hsi get_property CONFIG.MAC_PORT0_RX_OPCODE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-rx-opcode-ppp-c1" $MAC_PORT0_RX_OPCODE_PPP_C1 int $dts_file
        set MAC_PORT0_RX_PAUSE_DA_MCAST_C0 [hsi get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_MCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_RX_PAUSE_DA_MCAST_C0 [mrmac_check_size $MAC_PORT0_RX_PAUSE_DA_MCAST_C0 $node]
        add_prop "${node}" "xlnx,mac-port0-rx-pause-da-mcast-c0" $MAC_PORT0_RX_PAUSE_DA_MCAST_C0 int $dts_file
        set MAC_PORT0_RX_PAUSE_DA_MCAST_C1 [hsi get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_MCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_RX_PAUSE_DA_MCAST_C1 [mrmac_check_size $MAC_PORT0_RX_PAUSE_DA_MCAST_C1 $node]
        add_prop "${node}" "xlnx,mac-port0-rx-pause-da-mcast-c1" $MAC_PORT0_RX_PAUSE_DA_MCAST_C1 int $dts_file
        set MAC_PORT0_RX_PAUSE_DA_UCAST_C0 [hsi get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_UCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_RX_PAUSE_DA_UCAST_C0 [mrmac_check_size $MAC_PORT0_RX_PAUSE_DA_UCAST_C0 $node]
        add_prop "${node}" "xlnx,mac-port0-rx-pause-da-ucast-c0" $MAC_PORT0_RX_PAUSE_DA_UCAST_C0 int $dts_file
        set MAC_PORT0_RX_PAUSE_DA_UCAST_C1 [hsi get_property CONFIG.MAC_PORT0_RX_PAUSE_DA_UCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_RX_PAUSE_DA_UCAST_C1 [mrmac_check_size $MAC_PORT0_RX_PAUSE_DA_UCAST_C1 $node]
        add_prop "${node}" "xlnx,mac-port0-rx-pause-da-ucast-c1" $MAC_PORT0_RX_PAUSE_DA_UCAST_C1 int $dts_file
        set MAC_PORT0_RX_PAUSE_SA_C0 [hsi get_property CONFIG.MAC_PORT0_RX_PAUSE_SA_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_RX_PAUSE_SA_C0 [mrmac_check_size $MAC_PORT0_RX_PAUSE_SA_C0 $node]
        add_prop "${node}" "xlnx,mac-port0-rx-pause-sa-c0" $MAC_PORT0_RX_PAUSE_SA_C0 int $dts_file
        set MAC_PORT0_RX_PAUSE_SA_C1 [hsi get_property CONFIG.MAC_PORT0_RX_PAUSE_SA_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_RX_PAUSE_SA_C1 [mrmac_check_size $MAC_PORT0_RX_PAUSE_SA_C1 $node]
        add_prop "${node}" "xlnx,mac-port0-rx-pause-sa-c1" $MAC_PORT0_RX_PAUSE_SA_C1 int $dts_file
        set MAC_PORT0_TX_DA_GPP_C0 [hsi get_property CONFIG.MAC_PORT0_TX_DA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_DA_GPP_C0 [mrmac_check_size $MAC_PORT0_TX_DA_GPP_C0 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-da-gpp-c0" $MAC_PORT0_TX_DA_GPP_C0 int $dts_file
        set MAC_PORT0_TX_DA_GPP_C1 [hsi get_property CONFIG.MAC_PORT0_TX_DA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_DA_GPP_C1 [mrmac_check_size $MAC_PORT0_TX_DA_GPP_C1 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-da-gpp-c1" $MAC_PORT0_TX_DA_GPP_C1 int $dts_file
        set MAC_PORT0_TX_DA_PPP_C0 [hsi get_property CONFIG.MAC_PORT0_TX_DA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_DA_PPP_C0 [mrmac_check_size $MAC_PORT0_TX_DA_PPP_C0 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-da-ppp-c0" $MAC_PORT0_TX_DA_PPP_C0 int $dts_file
        set MAC_PORT0_TX_DA_PPP_C1 [hsi get_property CONFIG.MAC_PORT0_TX_DA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_DA_PPP_C1 [mrmac_check_size $MAC_PORT0_TX_DA_PPP_C1 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-da-ppp-c1" $MAC_PORT0_TX_DA_PPP_C1 int $dts_file
        set MAC_PORT0_TX_ETHERTYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-ethertype-gpp-c0" $MAC_PORT0_TX_ETHERTYPE_GPP_C0 int $dts_file
        set MAC_PORT0_TX_ETHERTYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-ethertype-gpp-c1" $MAC_PORT0_TX_ETHERTYPE_GPP_C1 int $dts_file
        set MAC_PORT0_TX_ETHERTYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-ethertype-ppp-c0" $MAC_PORT0_TX_ETHERTYPE_PPP_C0 int $dts_file
        set MAC_PORT0_TX_ETHERTYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT0_TX_ETHERTYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-ethertype-ppp-c1" $MAC_PORT0_TX_ETHERTYPE_PPP_C1 int $dts_file
        set MAC_PORT0_TX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT0_TX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-flow-c0" $MAC_PORT0_TX_FLOW_C0 int $dts_file
        set MAC_PORT0_TX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT0_TX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-flow-c1" $MAC_PORT0_TX_FLOW_C1 int $dts_file
        set MAC_PORT0_TX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT0_TX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-opcode-gpp-c0" $MAC_PORT0_TX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT0_TX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT0_TX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mac-port0-tx-opcode-gpp-c1" $MAC_PORT0_TX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT0_TX_SA_GPP_C0 [hsi get_property CONFIG.MAC_PORT0_TX_SA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_SA_GPP_C0 [mrmac_check_size $MAC_PORT0_TX_SA_GPP_C0 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-sa-gpp-c0" $MAC_PORT0_TX_SA_GPP_C0 int $dts_file
        set MAC_PORT0_TX_SA_GPP_C1 [hsi get_property CONFIG.MAC_PORT0_TX_SA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_SA_GPP_C1 [mrmac_check_size $MAC_PORT0_TX_SA_GPP_C1 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-sa-gpp-c1" $MAC_PORT0_TX_SA_GPP_C1 int $dts_file
        set MAC_PORT0_TX_SA_PPP_C0 [hsi get_property CONFIG.MAC_PORT0_TX_SA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_SA_PPP_C0 [mrmac_check_size $MAC_PORT0_TX_SA_PPP_C0 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-sa-ppp-c0" $MAC_PORT0_TX_SA_PPP_C0 int $dts_file
        set MAC_PORT0_TX_SA_PPP_C1 [hsi get_property CONFIG.MAC_PORT0_TX_SA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT0_TX_SA_PPP_C1 [mrmac_check_size $MAC_PORT0_TX_SA_PPP_C1 $node]
        add_prop "${node}" "xlnx,mac-port0-tx-sa-ppp-c1" $MAC_PORT0_TX_SA_PPP_C1 int $dts_file
        set GT_CH0_RXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rxprogdiv-freq-enable-c0" $GT_CH0_RXPROGDIV_FREQ_ENABLE_C0 string $dts_file

        set GT_CH0_RXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rxprogdiv-freq-enable-c1" $GT_CH0_RXPROGDIV_FREQ_ENABLE_C1 string $dts_file
        set GT_CH0_RXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rxprogdiv-freq-source-c0" $GT_CH0_RXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH0_RXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rxprogdiv-freq-source-c1" $GT_CH0_RXPROGDIV_FREQ_SOURCE_C1 string $dts_file
        set GT_CH0_RXPROGDIV_FREQ_VAL_C0 [hsi get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_VAL_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rxprogdiv-freq-val-c0" $GT_CH0_RXPROGDIV_FREQ_VAL_C0 string $dts_file
        set GT_CH0_RXPROGDIV_FREQ_VAL_C1 [hsi get_property CONFIG.GT_CH0_RXPROGDIV_FREQ_VAL_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rxprogdiv-freq-val-c1" $GT_CH0_RXPROGDIV_FREQ_VAL_C1 string $dts_file
        set GT_CH0_RX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH0_RX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-buffer-mode-c0" $GT_CH0_RX_BUFFER_MODE_C0 int $dts_file
        set GT_CH0_RX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH0_RX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-buffer-mode-c1" $GT_CH0_RX_BUFFER_MODE_C1 int $dts_file
        set GT_CH0_RX_DATA_DECODING_C0 [hsi get_property CONFIG.GT_CH0_RX_DATA_DECODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-data-decoding-c0" $GT_CH0_RX_DATA_DECODING_C0 string $dts_file
        set GT_CH0_RX_DATA_DECODING_C1 [hsi get_property CONFIG.GT_CH0_RX_DATA_DECODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-data-decoding-c1" $GT_CH0_RX_DATA_DECODING_C1 string $dts_file


        set GT_CH0_RX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH0_RX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-int-data-width-c0" $GT_CH0_RX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH0_RX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH0_RX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-int-data-width-c1" $GT_CH0_RX_INT_DATA_WIDTH_C1 int $dts_file


        set GT_CH0_RX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH0_RX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-line-rate-c0" $GT_CH0_RX_LINE_RATE_C0 string $dts_file
        set GT_CH0_RX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH0_RX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-line-rate-c1" $GT_CH0_RX_LINE_RATE_C1 string $dts_file


        set GT_CH0_RX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH0_RX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-outclk-source-c0" $GT_CH0_RX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH0_RX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH0_RX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-outclk-source-c1" $GT_CH0_RX_OUTCLK_SOURCE_C1 string $dts_file


        set GT_CH0_RX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH0_RX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-refclk-frequency-c0" $GT_CH0_RX_REFCLK_FREQUENCY_C0 string $dts_file
        set GT_CH0_RX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH0_RX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-refclk-frequency-c1" $GT_CH0_RX_REFCLK_FREQUENCY_C1 string $dts_file


        set GT_CH0_RX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH0_RX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-user-data-width-c0" $GT_CH0_RX_USER_DATA_WIDTH_C0 string $dts_file
        set GT_CH0_RX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH0_RX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-rx-user-data-width-c1" $GT_CH0_RX_USER_DATA_WIDTH_C1 string $dts_file

        set GT_CH0_TXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-txprogdiv-freq-enable-c0" $GT_CH0_TXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH0_TXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-txprogdiv-freq-enable-c1" $GT_CH0_TXPROGDIV_FREQ_ENABLE_C1 string $dts_file


        set GT_CH0_TXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-txprogdiv-freq-source-c0" $GT_CH0_TXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH0_TXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH0_TXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,gt-ch0-txprogdiv-freq-source-c1" $GT_CH0_TXPROGDIV_FREQ_SOURCE_C1 string $dts_file

        set mrmac_clk_names [hsi get_property CONFIG.zclock-names1 $drv_handle]
        set mrmac_clks [hsi get_property CONFIG.zclocks1 $drv_handle]
        set mrmac_clkname_len [llength $mrmac_clk_names]
        set mrmac_clk_len [expr {[llength [split $mrmac_clks ","]]}]
        set clk_list [split $mrmac_clks ","]
        set null ""
        set_drv_prop $drv_handle "zclock-names1" $node $null
        set refs ""
        set_drv_prop $drv_handle "zclocks1" "$refs" $node stringlist

        set i 0
        while {$i < $mrmac_clkname_len} {
                set clkname [lindex $mrmac_clk_names $i]
                if {[string match -nocase $clkname "s_axi_aclk"]} {
                        set s_axi_aclk "s_axi_aclk"
                        set s_axi_aclk_index0 $i
                }
                if {[string match -nocase $clkname "rx_axi_clk0"]} {
                        set rx_axi_clk0 "rx_axi_clk"
                        set rx_axi_clk_index0 $i
                }
                if {[string match -nocase $clkname "rx_axi_clk1"]} {
                        set rx_axi_clk1 "rx_axi_clk"
                        set rx_axi_clk_index1 $i
                }
                if {[string match -nocase $clkname "rx_axi_clk2"]} {
                        set rx_axi_clk2 "rx_axi_clk"
                        set rx_axi_clk_index2 $i
                }
                if {[string match -nocase $clkname "rx_axi_clk3"]} {
                        set rx_axi_clk3 "rx_axi_clk"
                        set rx_axi_clk_index3 $i
                }
                if {[string match -nocase $clkname "rx_flexif_clk0"]} {
                        set rx_flexif_clk0 "rx_flexif_clk"
                        set rx_flexif_clk_index0 $i
                }
                if {[string match -nocase $clkname "rx_flexif_clk1"]} {
                        set rx_flexif_clk1 "rx_flexif_clk"
                        set rx_flexif_clk_index1 $i
                }
                if {[string match -nocase $clkname "rx_flexif_clk2"]} {
                        set rx_flexif_clk2 "rx_flexif_clk"
                        set rx_flexif_clk_index2 $i
                }
                if {[string match -nocase $clkname "rx_flexif_clk3"]} {
                        set rx_flexif_clk3 "rx_flexif_clk"
                        set rx_flexif_clk_index3 $i
                }
                if {[string match -nocase $clkname "rx_ts_clk0"]} {
                        set rx_ts_clk0 "rx_ts_clk"
                        set rx_ts_clk0_index0 $i
                }
                if {[string match -nocase $clkname "rx_ts_clk1"]} {
                        set rx_ts_clk1 "rx_ts_clk"
                        set rx_ts_clk1_index1 $i
                }
                if {[string match -nocase $clkname "rx_ts_clk2"]} {
                        set rx_ts_clk2 "rx_ts_clk"
                        set rx_ts_clk2_index2 $i
                }
                if {[string match -nocase $clkname "rx_ts_clk3"]} {
                        set rx_ts_clk3 "rx_ts_clk"
                        set rx_ts_clk3_index3 $i
                }
                if {[string match -nocase $clkname "tx_axi_clk0"]} {
                        set tx_axi_clk0 "tx_axi_clk"
                        set tx_axi_clk_index0 $i
                }
                if {[string match -nocase $clkname "tx_axi_clk1"]} {
                        set tx_axi_clk1 "tx_axi_clk"
                        set tx_axi_clk_index1 $i
                }
                if {[string match -nocase $clkname "tx_axi_clk2"]} {
                        set tx_axi_clk2 "tx_axi_clk"
                        set tx_axi_clk_index2 $i
                }
                if {[string match -nocase $clkname "tx_axi_clk3"]} {
                        set tx_axi_clk3 "tx_axi_clk"
                        set tx_axi_clk_index3 $i
                }
                if {[string match -nocase $clkname "tx_flexif_clk0"]} {
                        set tx_flexif_clk0 "tx_flexif_clk"
                        set tx_flexif_clk_index0 $i
                }
                if {[string match -nocase $clkname "tx_flexif_clk1"]} {
                        set tx_flexif_clk1 "tx_flexif_clk"
                        set tx_flexif_clk_index1 $i
                }
                if {[string match -nocase $clkname "tx_flexif_clk2"]} {
                        set tx_flexif_clk2 "tx_flexif_clk"
                        set tx_flexif_clk_index2 $i
                }
                if {[string match -nocase $clkname "tx_flexif_clk3"]} {
                        set tx_flexif_clk3 "tx_flexif_clk"
                        set tx_flexif_clk_index3 $i
                }
                if {[string match -nocase $clkname "tx_ts_clk0"]} {
                        set tx_ts_clk0 "tx_ts_clk"
                        set tx_ts_clk_index0 $i
                }
                if {[string match -nocase $clkname "tx_ts_clk1"]} {
                        set tx_ts_clk1 "tx_ts_clk"
                        set tx_ts_clk_index1 $i
                }
                if {[string match -nocase $clkname "tx_ts_clk2"]} {
                        set tx_ts_clk2 "tx_ts_clk"
                        set tx_ts_clk_index2 $i
                }
                if {[string match -nocase $clkname "tx_ts_clk3"]} {
                        set tx_ts_clk3 "tx_ts_clk"
                        set tx_ts_clk_index3 $i
                }
                incr i
        }

        lappend clknames "$s_axi_aclk" "$rx_axi_clk0" "$rx_flexif_clk0" "$rx_ts_clk0" "$tx_axi_clk0" "$tx_flexif_clk0" "$tx_ts_clk0"
        set index0 [lindex $clk_list $s_axi_aclk_index0]
        regsub -all "\<&" $index0 {} index0
        regsub -all "\<&" $index0 {} index0
        set txindex0 [lindex $clk_list $tx_ts_clk_index0]
        regsub -all "\>" $txindex0 {} txindex0
        append clkvals0  "$index0, [lindex $clk_list $rx_axi_clk_index0], [lindex $clk_list $rx_flexif_clk_index0], [lindex $clk_list $rx_ts_clk0_index0], [lindex $clk_list $tx_axi_clk_index0], [lindex $clk_list $tx_flexif_clk_index0], $txindex0"
        add_prop "${node}" "clocks" $clkvals0 reference $dts_file
        add_prop "${node}" "clock-names" $clknames stringlist $dts_file

        set port0_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "rx_axis_tdata0"]]
        dtg_verbose "port0_pins:$port0_pins"
        foreach pin $port0_pins {
                set sink_periph [hsi::get_cells -of_objects $pin]
                set mux_ip ""
                set fifo_ip ""
                if {[llength $sink_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
                                   set fifo_width_bytes [hsi get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
                                   if {[string_is_empty $fifo_width_bytes]} {
                                           set fifo_width_bytes 1
                                   }
                                   set rxethmem [hsi get_property CONFIG.FIFO_DEPTH $sink_periph]
                                   # FIFO can be other than 8 bits, and we need the rxmem in bytes
                                   set rxethmem [expr $rxethmem * $fifo_width_bytes]
                                   add_prop "${node}" "xlnx,rxmem" $rxethmem int $dts_file
                                   set fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "m_axis_tdata"]]
                                   set mux_per [hsi::get_cells -of_objects $fifo_pin]
                                   if {[string match -nocase [hsi get_property IP_NAME $mux_per] "mrmac_10g_mux"]} {
                                           set data_fifo_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mux_per] "rx_m_axis_tdata"]]
                                           set data_fifo_per [hsi::get_cells -of_objects $data_fifo_pin]
                                           if {[string match -nocase [hsi get_property IP_NAME $data_fifo_per] "axis_data_fifo"]} {
                                                   set fiforx_connect_ip [get_connected_stream_ip [hsi::get_cells -hier $data_fifo_per] "M_AXIS"]
                                               dtg_verbose "fiforx_connect_ip:$fiforx_connect_ip"
                                                   set fiforx_pin [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $data_fifo_per] "m_axis_tdata"]]
                                                   if {[llength $fiforx_pin]} {
                                                           set fiforx_per [::hsi::get_cells -of_objects $fiforx_pin]
                                                   }
                                                   if {[llength $fiforx_per]} {
                                                           if {[string match -nocase [hsi get_property IP_NAME $fiforx_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
                                                                   set fiforx_connect_ip [get_connected_stream_ip [hsi get_cells -hier $fiforx_per] "M_AXIS"]
                                                           }
                                                   }
                                                   if {[llength $fiforx_connect_ip]} {

                                                   if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip] "axi_mcdma"]} {
                                                           add_prop "$node" "axistream-connected" "$fiforx_connect_ip" reference $dts_file
                                                           set num_queues [hsi get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip]
                                                           set inhex [format %x $num_queues]
                                                           append numqueues "/bits/ 16 <0x$inhex>"
                                                           add_prop $node "xlnx,num-queues" $numqueues stringlist $dts_file
                                                           set id 1
                                                           for {set i 2} {$i <= $num_queues} {incr i} {
                                                                   set i [format "%" $i]
                                                                   append id "\""
                                                                   append id ",\"" $i
                                                                   set i [expr 0x$i]
                                                           }
                                                           add_prop $node "xlnx,num-queues" $numqueues stringlist $dts_file
                                                           add_prop $node "xlnx,channel-ids" $id stringlist $dts_file
                                                           mrmac_generate_intr_info  $drv_handle $node $fiforx_connect_ip
                                                   }
                                               }
                                }
                                }
                        }
                                  }
           }

           set port0_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_0"]]
           dtg_verbose "port0_pins:$port0_pins"

        if {[llength $port0_pins]} {
           set sink_periph [hsi::get_cells -of_objects $port0_pins]
           if {[llength $sink_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "mrmac_ptp_timestamp_if"]} {
                                   set port_pins [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $sink_periph] "tx_timestamp_tod"]]
                                   set sink_periph [::hsi::get_cells -of_objects $port_pins]
                           }
                   }

           if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "xlconcat"]} {
                   set intf "dout"
                   set intr1_pin [hsi::get_pins -of_objects $sink_periph -filter "NAME==$intf"]
                   set sink_pins [get_sink_pins $intr1_pin]
                   set xl_per [hsi::get_cells -of_objects $sink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $xl_per] "axis_dwidth_converter"]} {
                           set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $xl_per] "m_axis_tdata"]]
                           set axis_per [hsi::get_cells -of_objects $port_pins]
                           if {[string match -nocase [hsi get_property IP_NAME $axis_per] "axis_clock_converter"]} {
                                   set tx_ip [get_connected_stream_ip [hsi::get_cells -hier $axis_per] "M_AXIS"]
                                   if {[llength $tx_ip]} {
                                           add_prop "$node" "axififo-connected" $tx_ip reference $dts_file
                                   }
                                }
                        }
                }
           } else {
        dtg_warning "tx_timestamp_tod_0 connected pins are NULL...please check the design..."
           }
           set rxtod_pins [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $mrmac_ip] "rx_ptp_tstamp_out_0"]]
           dtg_verbose "rxtod_pins:$rxtod_pins"
        if {[llength $rxtod_pins]} {
           set rx_periph [hsi::get_cells -of_objects $rxtod_pins]
                   if {[llength $rx_periph]} {
                           if {[string match -nocase [get_property IP_NAME $rx_periph] "mrmac_ptp_timestamp_if"]} {
                                   set port_pins [::hsi::utils::get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $rx_periph] "rx_timestamp_tod"]]
                                   set rx_periph [::hsi::get_cells -of_objects $port_pins]
                           }
                   }

           if {[string match -nocase [hsi get_property IP_NAME $rx_periph] "xlconcat"]} {
                   set intf "dout"
                   set in1_pin [hsi::get_pins -of_objects $rx_periph -filter "NAME==$intf"]
                   set sink_pins [get_sink_pins $in1_pin]
                   set rxxl_per [hsi::get_cells -of_objects $sink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $rxxl_per] "axis_dwidth_converter"]} {
                           set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rxxl_per] "m_axis_tdata"]]
                           set rx_axis_per [hsi::get_cells -of_objects $port_pins]
                           if {[string match -nocase [hsi get_property IP_NAME $rx_axis_per] "axis_clock_converter"]} {
                                   set rx_ip [get_connected_stream_ip [hsi::get_cells -hier $rx_axis_per] "M_AXIS"]
                                   if {[llength $rx_ip]} {
                                           add_prop "$node" "xlnx,rxtsfifo" $rx_ip reference $dts_file
                                }
                        }
                }
        }
        } else {
                dtg_warning "rx_timestamp_tod_0 connected pins are NULL...please check the design..."
        }
           set handle ""
           set mask_handle ""
           set ips [hsi::get_cells -hier -filter {IP_NAME == "axi_gpio"}]
           foreach ip $ips {
                   set mem_ranges [hsi::get_mem_ranges [hsi::get_cells -hier $ip]]
                   foreach mem_range $mem_ranges {
                           set base [string tolower [hsi get_property BASE_VALUE $mem_range]]
                           if {[string match -nocase $base "0xa4010000"]} {
                                   set handle $ip
                                   break
                           }
                   }
           }
           if {[llength $handle]} {
                   add_prop "$node" "xlnx,gtctrl" $handle reference $dts_file
           }
           # Workaround: For gtpll we might need to add the below code for v0.1 version.
           # We can remove this workaround for later versions.
           foreach ip $ips {
                   set mem_ranges [hsi::get_mem_ranges [hsi::get_cells -hier $ip]]
                   foreach mem_range $mem_ranges {
                           set base [string tolower [hsi get_property BASE_VALUE $mem_range]]
                           if {[string match -nocase $base "0xa4000000"]} {
                                   set mask_handle $ip
                                   break
                           }
                   }
           }
           if {[llength $mask_handle]} {
                   add_prop "$node" "xlnx,gtpll" $mask_handle reference $dts_file
           }
                   add_prop "$node" "xlnx,phcindex" 0 int $dts_file
                   add_prop "$node" "xlnx,gtlane" 0 int $dts_file

        set gt_reset_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $mrmac_ip] "gt_reset_all_in"]]
        dtg_verbose "gt_reset_pins:$gt_reset_pins"
        set gt_reset_per ""
        if {[llength $gt_reset_pins]} {
                set gt_reset_periph [::hsi::get_cells -of_objects $gt_reset_pins]
                if {[string match -nocase [hsi get_property IP_NAME $gt_reset_periph] "xlconcat"]} {
                        set intf "In0"
                        set in1_pin [::hsi::get_pins -of_objects $gt_reset_periph -filter "NAME==$intf"]
                        set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_reset_periph] $in1_pin]]
                        set gt_per [::hsi::get_cells -of_objects $sink_pins]
                        if {[string match -nocase [hsi get_property IP_NAME $gt_per] "xlslice"]} {
                                set intf "Din"
                                set in1_pin [::hsi::get_pins -of_objects $gt_per -filter "NAME==$intf"]
                                set sink_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_per] $in1_pin]]
                                set gt_reset_per [::hsi::get_cells -of_objects $sink_pins]
                                dtg_verbose "gt_reset_per:$gt_reset_per"
                                if {[llength $gt_reset_per]} {
                                        add_prop "$node" "xlnx,gtctrl" $gt_reset_per reference $dts_file
                                }
                        }
                }
        }

        set gt_pll_pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier $mrmac_ip] "mst_rx_resetdone_in"]]
        dtg_verbose "gt_pll_pins:$gt_pll_pins"
        set gt_pll_per ""
            if {[llength $gt_pll_pins]} {
                    set gt_pll_periph [::hsi::get_cells -of_objects $gt_pll_pins]
                    if {[string match -nocase [hsi get_property IP_NAME $gt_pll_periph] "xlconcat"]} {
                            set intf "dout"
                            set in1_pin [::hsi::get_pins -of_objects $gt_pll_periph -filter "NAME==$intf"]
                            set sink_pins [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $gt_pll_periph] $in1_pin]]
                            foreach pin $sink_pins {
                                    if {[string match -nocase $pin "In0"]} {
                                            set gt_per [::hsi::get_cells -of_objects $sink_pins]
                                            foreach per $gt_per {
                                                    if {[string match -nocase [hsi get_property IP_NAME $per] "xlconcat"]} {
                                                            set intf "dout"
                                                            set in1_pin [::hsi::get_pins -of_objects $per -filter "NAME==$intf"]
                                                            set sink_pins [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $per] $in1_pin]]
                                                            if {[llength $sink_pins]} {
                                                                    set gt_pll_per [::hsi::get_cells -of_objects $sink_pins]
                                                                    dtg_verbose "gt_pll_per:$gt_pll_per"
                                                                    if {[llength $gt_pll_per]} {
                                                                           add_prop "$node" "xlnx,gtpll" $gt_pll_per reference $dts_file
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }

        global env
        set path $env(REPO)
        set common_file "$path/device_tree/data/config.yaml"
        set dt_overlay [get_user_config $common_file -dt_overlay]
            if {$dt_overlay} {
                    set bus_node "overlay2"
            } else {
                    set bus_node "amba_pl"
            }
        set dts_file [current_dt_tree]
        set mrmac1_base [format 0x%x [expr $base_addr + 0x1000]]
        set mrmac1_base_hex [format %x $mrmac1_base]
        set mrmac1_highaddr_hex [format 0x%x [expr $mrmac1_base + 0xFFF]]
        set port1 1
        append new_label $drv_handle "_" $port1
        set mrmac1_node [create_node -n "mrmac" -l "$new_label" -u $mrmac1_base_hex -d $dts_file -p $bus_node]
        add_prop "$mrmac1_node" "compatible" "$compatible" stringlist $dts_file
        mrmac_generate_reg_property $mrmac1_node $mrmac1_base $mrmac1_highaddr_hex
        lappend clknames1 "$s_axi_aclk" "$rx_axi_clk1" "$rx_flexif_clk1" "$rx_ts_clk1" "$tx_axi_clk1" "$tx_flexif_clk1" "$tx_ts_clk1"
        set index1 [lindex $clk_list $s_axi_aclk_index0]
        regsub -all "\<&" $index1 {} index1
        regsub -all "\<&" $index1 {} index1
        set txindex1 [lindex $clk_list $tx_ts_clk_index1]
        regsub -all "\>" $txindex1 {} txindex1
        append clkvals  "$index1, [lindex $clk_list $rx_axi_clk_index1], [lindex $clk_list $rx_flexif_clk_index1], [lindex $clk_list $rx_ts_clk1_index1], [lindex $clk_list $tx_axi_clk_index1], [lindex $clk_list $tx_flexif_clk_index1], $txindex1"
        add_prop "${mrmac1_node}" "clocks" $clkvals reference $dts_file
        add_prop "${mrmac1_node}" "clock-names" $clknames1 stringlist $dts_file
        set port1_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "rx_axis_tdata2"]]
        dtg_verbose "port1_pins:$port1_pins"
        foreach pin $port1_pins {
                set sink_periph [hsi::get_cells -of_objects $pin]
                set mux_ip ""
                set fifo_ip ""
                if {[llength $sink_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
                                   set fifo_width_bytes [hsi get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
                                   if {[string_is_empty $fifo_width_bytes]} {
                                           set fifo_width_bytes 1
                                   }
                                   set rxethmem [hsi get_property CONFIG.FIFO_DEPTH $sink_periph]
                                   # FIFO can be other than 8 bits, and we need the rxmem in bytes
                                   set rxethmem [expr $rxethmem * $fifo_width_bytes]
                                   add_prop "${mrmac1_node}" "xlnx,rxmem" $rxethmem int $dts_file
                                   set fifo1_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "m_axis_tdata"]]
                                   set mux_per1 [hsi::get_cells -of_objects $fifo1_pin]
                                   if {[string match -nocase [hsi get_property IP_NAME $mux_per1] "mrmac_10g_mux"]} {
                                           set data_fifo_pin1 [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mux_per1] "rx_m_axis_tdata"]]
                                           set data_fifo_per1 [hsi::get_cells -of_objects $data_fifo_pin1]
                                           if {[string match -nocase [hsi get_property IP_NAME $data_fifo_per1] "axis_data_fifo"]} {
                                                   set fiforx_connect_ip1 [get_connected_stream_ip [hsi::get_cells -hier $data_fifo_per1] "M_AXIS"]
                                                   set fiforx1_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $data_fifo_per1] "m_axis_tdata"]]
                                                   if {[llength $fiforx1_pin]} {
                                                           set fiforx1_per [::hsi::get_cells -of_objects $fiforx1_pin]
                                                   }
                                                   if {[llength $fiforx1_per]} {
                                                           if {[string match -nocase [hsi get_property IP_NAME $fiforx1_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
                                                                   set fiforx_connect_ip1 [get_connected_stream_ip [hsi::get_cells -hier $fiforx1_per] "M_AXIS"]
                                                           }
                                                   }
                                                   if {[llength $fiforx_connect_ip1]} {

                                                   if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip1] "axi_mcdma"]} {
                                                           add_prop "$mrmac1_node" "axistream-connected" "$fiforx_connect_ip1" reference
                                                           set num_queues [hsi get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip1]
                                                           set inhex [format %x $num_queues]
                                                           append numqueues1 "/bits/ 16 <0x$inhex>"
                                                           add_prop $mrmac1_node "xlnx,num-queues" $numqueues1 stringlist $dts_file
                                                           set id 1
                                                           for {set i 2} {$i <= $num_queues} {incr i} {
                                                                   set i [format "%" $i]
                                                                   append id "\""
                                                                   append id ",\"" $i
                                                                   set i [expr 0x$i]
                                                           }
                                                           add_prop $mrmac1_node "xlnx,num-queues" $numqueues1 stringlist $dts_file
                                                           add_prop $mrmac1_node "xlnx,channel-ids" $id stringlist $dts_file
                                                           mrmac_generate_intr_info  $drv_handle $mrmac1_node $fiforx_connect_ip1
                                                   }
                                               }
                                        }
                                }
                        }
                   }
           }

           set txtodport1_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_1"]]
           dtg_verbose "txtodport1_pins:$txtodport1_pins"
        if {[llength $txtodport1_pins]} {
              set tod1_sink_periph [hsi::get_cells -of_objects $txtodport1_pins]
                  if {[llength $tod1_sink_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $tod1_sink_periph] "mrmac_ptp_timestamp_if"]} {
                                   set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $tod1_sink_periph] "tx_timestamp_tod"]]
                                   set tod1_sink_periph [::hsi::get_cells -of_objects $port_pins]
                           }
                   }

           if {[string match -nocase [hsi get_property IP_NAME $tod1_sink_periph] "xlconcat"]} {
                   set intf "dout"
                   set in1_pin [hsi::get_pins -of_objects $tod1_sink_periph -filter "NAME==$intf"]
                   set in1sink_pins [get_sink_pins $in1_pin]
                   set xl_per1 [hsi::get_cells -of_objects $in1sink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $xl_per1] "axis_dwidth_converter"]} {
                           set port1_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $xl_per1] "m_axis_tdata"]]
                           set axis_per1 [hsi::get_cells -of_objects $port1_pins]
                           if {[string match -nocase [hsi get_property IP_NAME $axis_per1] "axis_clock_converter"]} {
                                   set tx1_ip [get_connected_stream_ip [hsi::get_cells -hier $axis_per1] "M_AXIS"]
                                   if {[llength $tx1_ip]} {
                                           add_prop "$mrmac1_node" "axififo-connected" $tx1_ip reference $dtds_file
                                   }
                        }
                        }
           }
        } else {
                dtg_warning "tx_timestamp_tod_1 connected pins are NULL...please check the design..."
        }
           set rxtod1_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "rx_ptp_tstamp_out_1"]]
           dtg_verbose "rxtod1_pins:$rxtod1_pins"
           if {[llength $rxtod1_pins]} {
                set rx_periph1 [hsi::get_cells -of_objects $rxtod1_pins]
               if {[llength $rx_periph1]} {
                           if {[string match -nocase [hsi get_property IP_NAME $rx_periph1] "mrmac_ptp_timestamp_if"]} {
                                   set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rx_periph1] "rx_timestamp_tod"]]
                                   set rx_periph1 [::hsi::get_cells -of_objects $port_pins]
                           }
                   }       
           if {[string match -nocase [hsi get_property IP_NAME $rx_periph1] "xlconcat"]} {
                   set intf "dout"
                   set inrx1_pin [hsi::get_pins -of_objects $rx_periph1 -filter "NAME==$intf"]
                   set rxtodsink_pins [get_sink_pins $inrx1_pin]
                   set rx_per [hsi::get_cells -of_objects $rxtodsink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $rx_per] "axis_dwidth_converter"]} {
                           set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rx_per] "m_axis_tdata"]]
                           set rx_axis_per [hsi::get_cells -of_objects $port_pins]
                           if {[string match -nocase [hsi get_property IP_NAME $rx_axis_per] "axis_clock_converter"]} {
                                   set rx_ip [get_connected_stream_ip [hsi::get_cells -hier $rx_axis_per] "M_AXIS"]
                                   if {[llength $rx_ip]} {
                                           add_prop "$mrmac1_node" "xlnx,rxtsfifo" $rx_ip reference $dts_file
                                }
                        }
                }
        }
        } else {
                dtg_warning "rx_timestamp_tod_1 connected pins are NULL...please check the design..."
        }
           if {[llength $handle]} {
                   add_prop "$mrmac1_node" "xlnx,gtctrl" $handle reference $dts_file
           }
           if {[llength $mask_handle]} {
                   add_prop "$mrmac1_node" "xlnx,gtpll" $mask_handle reference $dts_file
           }
           if {[llength $gt_reset_per]} {
                   add_prop "$mrmac1_node" "xlnx,gtctrl" $gt_reset_per reference $dts_file
           }
           if {[llength $gt_pll_per]} {
                   add_prop "$mrmac1_node" "xlnx,gtpll" $gt_pll_per reference $dts_file
           }

           add_prop "$mrmac1_node" "xlnx,phcindex" 1 int $dts_file
           add_prop "$mrmac1_node" "xlnx,gtlane" 1 int $dts_file

        set FEC_SLICE1_CFG_C0 [hsi get_property CONFIG.C_FEC_SLICE1_CFG_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-slice1-cfg-c0" $FEC_SLICE1_CFG_C0 string $dts_file
        set FEC_SLICE1_CFG_C1 [hsi get_property CONFIG.C_FEC_SLICE1_CFG_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-slice1-cfg-c1" $FEC_SLICE1_CFG_C1 string $dts_file
        set FLEX_PORT1_DATA_RATE_C0 [hsi get_property CONFIG.C_FLEX_PORT1_DATA_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-port1-data-rate-c0" $FLEX_PORT1_DATA_RATE_C0 string $dts_file
        set FLEX_PORT1_DATA_RATE_C1 [hsi get_property CONFIG.C_FLEX_PORT1_DATA_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-port1-data-rate-c1" $FLEX_PORT1_DATA_RATE_C1 string $dts_file
        set FLEX_PORT1_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.C_FLEX_PORT1_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-port1-enable-time-stamping-c0" $FLEX_PORT1_ENABLE_TIME_STAMPING_C0 int $dts_file
        set FLEX_PORT1_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.C_FLEX_PORT1_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-port1-enable-time-stamping-c1" $FLEX_PORT1_ENABLE_TIME_STAMPING_C1 int $dts_file
        set FLEX_PORT1_MODE_C0 [hsi get_property CONFIG.C_FLEX_PORT1_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-port1-mode-c0" $FLEX_PORT1_MODE_C0 string $dts_file
        set FLEX_PORT1_MODE_C1 [hsi get_property CONFIG.C_FLEX_PORT1_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,flex-port1-mode-c1" $FLEX_PORT1_MODE_C1 string $dts_file
        set PORT1_1588v2_Clocking_C0 [hsi get_property CONFIG.PORT1_1588v2_Clocking_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,port1-1588v2-clocking-c0" $PORT1_1588v2_Clocking_C0 string $dts_file
        set PORT1_1588v2_Clocking_C1 [hsi get_property CONFIG.PORT1_1588v2_Clocking_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,port1-1588v2-clocking-c1" $PORT1_1588v2_Clocking_C1 string $dts_file
        set PORT1_1588v2_Operation_MODE_C0 [hsi get_property CONFIG.PORT1_1588v2_Operation_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,port1-1588v2-operation-mode-c0" $PORT1_1588v2_Operation_MODE_C0 string $dts_file
        set PORT1_1588v2_Operation_MODE_C1 [hsi get_property CONFIG.PORT1_1588v2_Operation_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,port1-1588v2-operation-mode-c1" $PORT1_1588v2_Operation_MODE_C1 string $dts_file
        set MAC_PORT1_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.MAC_PORT1_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-enable-time-stamping-c0" $MAC_PORT1_ENABLE_TIME_STAMPING_C0 int $dts_file
        set MAC_PORT1_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.MAC_PORT1_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-enable-time-stamping-c1" $MAC_PORT1_ENABLE_TIME_STAMPING_C1 int $dts_file
        set MAC_PORT1_RATE_C0 [hsi get_property CONFIG.MAC_PORT1_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $MAC_PORT1_RATE_C0 "10GE"]} {
                   set number 10000
                add_prop "${mrmac1_node}" "xlnx,mrmac-rate" $number int $dts_file
            } else {
                add_prop "${mrmac1_node}" "xlnx,mrmac-rate" $MAC_PORT1_RATE_C0 string $dts_file
        }
        set MAC_PORT1_RATE_C1 [hsi get_property CONFIG.MAC_PORT1_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rate-c1" $MAC_PORT1_RATE_C1 string $dts_file
        set MAC_PORT1_RX_ETYPE_GCP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gcp-c0" $MAC_PORT1_RX_ETYPE_GCP_C0 int $dts_file
        set MAC_PORT1_RX_ETYPE_GCP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gcp-c1" $MAC_PORT1_RX_ETYPE_GCP_C1 int $dts_file
        set MAC_PORT1_RX_ETYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gpp-c0" $MAC_PORT1_RX_ETYPE_GPP_C0 int $dts_file
        set MAC_PORT1_RX_ETYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-gpp-c1" $MAC_PORT1_RX_ETYPE_GPP_C1 int $dts_file
        set MAC_PORT1_RX_ETYPE_PCP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-pcp-c0" $MAC_PORT1_RX_ETYPE_PCP_C0 int $dts_file
        set MAC_PORT1_RX_ETYPE_PCP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-pcp-c1" $MAC_PORT1_RX_ETYPE_PCP_C1 int $dts_file
        set MAC_PORT1_RX_ETYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-ppp-c0" $MAC_PORT1_RX_ETYPE_PPP_C0 int $dts_file
        set MAC_PORT1_RX_ETYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_ETYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-etype-ppp-c1" $MAC_PORT1_RX_ETYPE_PPP_C1 int $dts_file
        set MAC_PORT1_RX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT1_RX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-flow-c0" $MAC_PORT1_RX_FLOW_C0 int $dts_file
        set MAC_PORT1_RX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT1_RX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-flow-c1" $MAC_PORT1_RX_FLOW_C1 int $dts_file
        set MAC_PORT1_RX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-gpp-c0" $MAC_PORT1_RX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT1_RX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-gpp-c1" $MAC_PORT1_RX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT1_RX_OPCODE_MAX_GCP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-gcp-c0" $MAC_PORT1_RX_OPCODE_MAX_GCP_C0 int $dts_file
        set MAC_PORT1_RX_OPCODE_MAX_GCP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-gcp-c1" $MAC_PORT1_RX_OPCODE_MAX_GCP_C1 int $dts_file
        set MAC_PORT1_RX_OPCODE_MAX_PCP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-pcp-c0" $MAC_PORT1_RX_OPCODE_MAX_PCP_C0 int $dts_file
        set MAC_PORT1_RX_OPCODE_MAX_PCP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MAX_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-max-pcp-c1" $MAC_PORT1_RX_OPCODE_MAX_PCP_C1 int $dts_file
        set MAC_PORT1_RX_OPCODE_MIN_GCP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-gcp-c0" $MAC_PORT1_RX_OPCODE_MIN_GCP_C0 int $dts_file
        set MAC_PORT1_RX_OPCODE_MIN_GCP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-gcp-c1" $MAC_PORT1_RX_OPCODE_MIN_GCP_C1 int $dts_file
        set MAC_PORT1_RX_OPCODE_MIN_PCP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-pcp-c0" $MAC_PORT1_RX_OPCODE_MIN_PCP_C0 int $dts_file
        set MAC_PORT1_RX_OPCODE_MIN_PCP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_MIN_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-min-pcp-c1" $MAC_PORT1_RX_OPCODE_MIN_PCP_C1 int $dts_file
        set MAC_PORT1_RX_OPCODE_PPP_C0 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-ppp-c0" $MAC_PORT1_RX_OPCODE_PPP_C0 int $dts_file
        set MAC_PORT1_RX_OPCODE_PPP_C1 [hsi get_property CONFIG.MAC_PORT1_RX_OPCODE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-opcode-ppp-c1" $MAC_PORT1_RX_OPCODE_PPP_C1 int $dts_file
        set MAC_PORT1_RX_PAUSE_DA_MCAST_C0 [hsi get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_MCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_RX_PAUSE_DA_MCAST_C0 [mrmac_check_size $MAC_PORT1_RX_PAUSE_DA_MCAST_C0 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-mcast-c0" $MAC_PORT1_RX_PAUSE_DA_MCAST_C0 int $dts_file
        set MAC_PORT1_RX_PAUSE_DA_MCAST_C1 [hsi get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_MCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_RX_PAUSE_DA_MCAST_C1 [mrmac_check_size $MAC_PORT1_RX_PAUSE_DA_MCAST_C1 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-mcast-c1" $MAC_PORT1_RX_PAUSE_DA_MCAST_C1 int $dts_file
        set MAC_PORT1_RX_PAUSE_DA_UCAST_C0 [hsi get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_UCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_RX_PAUSE_DA_UCAST_C0 [mrmac_check_size $MAC_PORT1_RX_PAUSE_DA_UCAST_C0 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-ucast-c0" $MAC_PORT1_RX_PAUSE_DA_UCAST_C0 int $dts_file
        set MAC_PORT1_RX_PAUSE_DA_UCAST_C1 [hsi get_property CONFIG.MAC_PORT1_RX_PAUSE_DA_UCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_RX_PAUSE_DA_UCAST_C1 [mrmac_check_size $MAC_PORT1_RX_PAUSE_DA_UCAST_C1 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-pause-da-ucast-c1" $MAC_PORT1_RX_PAUSE_DA_UCAST_C1 int $dts_file
        set MAC_PORT1_RX_PAUSE_SA_C0 [hsi get_property CONFIG.MAC_PORT1_RX_PAUSE_SA_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_RX_PAUSE_SA_C0 [mrmac_check_size $MAC_PORT1_RX_PAUSE_SA_C0 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-pause-sa-c0" $MAC_PORT1_RX_PAUSE_SA_C0 int $dts_file
        set MAC_PORT1_RX_PAUSE_SA_C1 [hsi get_property CONFIG.MAC_PORT1_RX_PAUSE_SA_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_RX_PAUSE_SA_C1 [mrmac_check_size $MAC_PORT1_RX_PAUSE_SA_C1 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-rx-pause-sa-c1" $MAC_PORT1_RX_PAUSE_SA_C1 int $dts_file
        set MAC_PORT1_TX_DA_GPP_C0 [hsi get_property CONFIG.MAC_PORT1_TX_DA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_DA_GPP_C0 [mrmac_check_size $MAC_PORT1_TX_DA_GPP_C0 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-da-gpp-c0" $MAC_PORT1_TX_DA_GPP_C0 int $dts_file
        set MAC_PORT1_TX_DA_GPP_C1 [hsi get_property CONFIG.MAC_PORT1_TX_DA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_DA_GPP_C1 [mrmac_check_size $MAC_PORT1_TX_DA_GPP_C1 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-da-gpp-c1" $MAC_PORT1_TX_DA_GPP_C1 int $dts_file
        set MAC_PORT1_TX_DA_PPP_C0 [hsi get_property CONFIG.MAC_PORT1_TX_DA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_DA_PPP_C0 [mrmac_check_size $MAC_PORT1_TX_DA_PPP_C0 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-da-ppp-c0" $MAC_PORT1_TX_DA_PPP_C0 int $dts_file
        set MAC_PORT1_TX_DA_PPP_C1 [hsi get_property CONFIG.MAC_PORT1_TX_DA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_DA_PPP_C1 [mrmac_check_size $MAC_PORT1_TX_DA_PPP_C1 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-da-ppp-c1" $MAC_PORT1_TX_DA_PPP_C1 int $dts_file
        set MAC_PORT1_TX_ETHERTYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-gpp-c0" $MAC_PORT1_TX_ETHERTYPE_GPP_C0 int $dts_file
        set MAC_PORT1_TX_ETHERTYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-gpp-c1" $MAC_PORT1_TX_ETHERTYPE_GPP_C1 int $dts_file
        set MAC_PORT1_TX_ETHERTYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-ppp-c0" $MAC_PORT1_TX_ETHERTYPE_PPP_C0 int $dts_file
        set MAC_PORT1_TX_ETHERTYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT1_TX_ETHERTYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-ethertype-ppp-c1" $MAC_PORT1_TX_ETHERTYPE_PPP_C1 int $dts_file
        set MAC_PORT1_TX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT1_TX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-flow-c0" $MAC_PORT1_TX_FLOW_C0 int $dts_file
        set MAC_PORT1_TX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT1_TX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-flow-c1" $MAC_PORT1_TX_FLOW_C1 int $dts_file
        set MAC_PORT1_TX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT1_TX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-opcode-gpp-c0" $MAC_PORT1_TX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT1_TX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT1_TX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-opcode-gpp-c1" $MAC_PORT1_TX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT1_TX_SA_GPP_C0 [hsi get_property CONFIG.MAC_PORT1_TX_SA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_SA_GPP_C0 [mrmac_check_size $MAC_PORT1_TX_SA_GPP_C0 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-sa-gpp-c0" $MAC_PORT1_TX_SA_GPP_C0 int $dts_file
        set MAC_PORT1_TX_SA_GPP_C1 [hsi get_property CONFIG.MAC_PORT1_TX_SA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_SA_GPP_C1 [mrmac_check_size $MAC_PORT1_TX_SA_GPP_C1 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-sa-gpp-c1" $MAC_PORT1_TX_SA_GPP_C1 int $dts_file
        set MAC_PORT1_TX_SA_PPP_C0 [hsi get_property CONFIG.MAC_PORT1_TX_SA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_SA_PPP_C0 [mrmac_check_size $MAC_PORT1_TX_SA_PPP_C0 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-sa-ppp-c0" $MAC_PORT1_TX_SA_PPP_C0 int $dts_file
        set MAC_PORT1_TX_SA_PPP_C1 [hsi get_property CONFIG.MAC_PORT1_TX_SA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT1_TX_SA_PPP_C1 [mrmac_check_size $MAC_PORT1_TX_SA_PPP_C1 $mrmac1_node]
        add_prop "${mrmac1_node}" "xlnx,mac-port1-tx-sa-ppp-c1" $MAC_PORT1_TX_SA_PPP_C1 int $dts_file
        set GT_CH1_RXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-enable-c0" $GT_CH1_RXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH1_RXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-enable-c1" $GT_CH1_RXPROGDIV_FREQ_ENABLE_C1 string $dts_file
        set GT_CH1_RXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-source-c0" $GT_CH1_RXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH1_RXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-source-c1" $GT_CH1_RXPROGDIV_FREQ_SOURCE_C1 string $dts_file
        set GT_CH1_RXPROGDIV_FREQ_VAL_C0 [hsi get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_VAL_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-val-c0" $GT_CH1_RXPROGDIV_FREQ_VAL_C0 string $dts_file
        set GT_CH1_RXPROGDIV_FREQ_VAL_C1 [hsi get_property CONFIG.GT_CH1_RXPROGDIV_FREQ_VAL_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rxprogdiv-freq-val-c1" $GT_CH1_RXPROGDIV_FREQ_VAL_C1 string $dts_file
        set GT_CH1_RX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH1_RX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-buffer-mode-c0" $GT_CH1_RX_BUFFER_MODE_C0 int $dts_file
        set GT_CH1_RX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH1_RX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-buffer-mode-c1" $GT_CH1_RX_BUFFER_MODE_C1 int $dts_file
        set GT_CH1_RX_DATA_DECODING_C0 [hsi get_property CONFIG.GT_CH1_RX_DATA_DECODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-data-decoding-c0" $GT_CH1_RX_DATA_DECODING_C0 string $dts_file
        set GT_CH1_RX_DATA_DECODING_C1 [hsi get_property CONFIG.GT_CH1_RX_DATA_DECODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-data-decoding-c1" $GT_CH1_RX_DATA_DECODING_C1 string $dts_file


        set GT_CH1_RX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH1_RX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-int-data-width-c0" $GT_CH1_RX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH1_RX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH1_RX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-int-data-width-c1" $GT_CH1_RX_INT_DATA_WIDTH_C1 int $dts_file


        set GT_CH1_RX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH1_RX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-line-rate-c0" $GT_CH1_RX_LINE_RATE_C0 string $dts_file
        set GT_CH1_RX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH1_RX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-line-rate-c1" $GT_CH1_RX_LINE_RATE_C1 string $dts_file


        set GT_CH1_RX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH1_RX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-outclk-source-c0" $GT_CH1_RX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH1_RX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH1_RX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-outclk-source-c1" $GT_CH1_RX_OUTCLK_SOURCE_C1 string $dts_file


        set GT_CH1_RX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH1_RX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-refclk-frequency-c0" $GT_CH1_RX_REFCLK_FREQUENCY_C0 string $dts_file
        set GT_CH1_RX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH1_RX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-refclk-frequency-c1" $GT_CH1_RX_REFCLK_FREQUENCY_C1 string $dts_file


        set GT_CH1_RX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH1_RX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-user-data-width-c0" $GT_CH1_RX_USER_DATA_WIDTH_C0 string $dts_file
        set GT_CH1_RX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH1_RX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-rx-user-data-width-c1" $GT_CH1_RX_USER_DATA_WIDTH_C1 string $dts_file

        set GT_CH1_TXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-enable-c0" $GT_CH1_TXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH1_TXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-enable-c1" $GT_CH1_TXPROGDIV_FREQ_ENABLE_C1 string $dts_file


        set GT_CH1_TXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-source-c0" $GT_CH1_TXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH1_TXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-source-c1" $GT_CH1_TXPROGDIV_FREQ_SOURCE_C1 string $dts_file


        set GT_CH1_TXPROGDIV_FREQ_VAL_C0 [hsi get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_VAL_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-val-c0" $GT_CH1_TXPROGDIV_FREQ_VAL_C0 string $dts_file
        set GT_CH1_TXPROGDIV_FREQ_VAL_C1 [hsi get_property CONFIG.GT_CH1_TXPROGDIV_FREQ_VAL_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-txprogdiv-freq-val-c1" $GT_CH1_TXPROGDIV_FREQ_VAL_C1 string $dts_file


        set GT_CH1_TX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH1_TX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-buffer-mode-c0" $GT_CH1_TX_BUFFER_MODE_C0 int $dts_file
        set GT_CH1_TX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH1_TX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-buffer-mode-c1" $GT_CH1_TX_BUFFER_MODE_C1 int $dts_file


        set GT_CH1_TX_DATA_ENCODING_C0 [hsi get_property CONFIG.GT_CH1_TX_DATA_ENCODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-data-encoding-c0" $GT_CH1_TX_DATA_ENCODING_C0 string $dts_file
        set GT_CH1_TX_DATA_ENCODING_C1 [hsi get_property CONFIG.GT_CH1_TX_DATA_ENCODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-data-encoding-c1" $GT_CH1_TX_DATA_ENCODING_C1 string $dts_file

        set GT_CH1_TX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH1_TX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-int-data-width-c0" $GT_CH1_TX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH1_TX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH1_TX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-int-data-width-c1" $GT_CH1_TX_INT_DATA_WIDTH_C1 int $dts_file

        set GT_CH1_TX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH1_TX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-line-rate-c0" $GT_CH1_TX_LINE_RATE_C0 string $dts_file
        set GT_CH1_TX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH1_TX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-line-rate-c1" $GT_CH1_TX_LINE_RATE_C1 string $dts_file


        set GT_CH1_TX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH1_TX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-outclk-source-c0" $GT_CH1_TX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH1_TX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH1_TX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-outclk-source-c1" $GT_CH1_TX_OUTCLK_SOURCE_C1 string $dts_file


        set GT_CH1_TX_PLL_TYPE_C0 [hsi get_property CONFIG.GT_CH1_TX_PLL_TYPE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-pll-type-c0" $GT_CH1_TX_PLL_TYPE_C0 string $dts_file
        set GT_CH1_TX_PLL_TYPE_C1 [hsi get_property CONFIG.GT_CH1_TX_PLL_TYPE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-pll-type-c1" $GT_CH1_TX_PLL_TYPE_C1 string $dts_file


        set GT_CH1_TX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH1_TX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-refclk-frequency-c0" $GT_CH1_TX_REFCLK_FREQUENCY_C0 string $dts_file
        set GT_CH1_TX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH1_TX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-refclk-frequency-c1" $GT_CH1_TX_REFCLK_FREQUENCY_C1 string $dts_file


        set GT_CH1_TX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH1_TX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-user-data-width-c0" $GT_CH1_TX_USER_DATA_WIDTH_C0 int $dts_file
        set GT_CH1_TX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH1_TX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch1-tx-user-data-width-c1" $GT_CH1_TX_USER_DATA_WIDTH_C1 int $dts_file

        set mrmac2_base [format 0x%x [expr $base_addr + 0x2000]]
        set mrmac2_base_hex [format %x $mrmac2_base]
        set mrmac2_highaddr_hex [format 0x%x [expr $mrmac2_base + 0xFFF]]
        set port2 2
        append label2 $drv_handle "_" $port2
        set mrmac2_node [create_node -n "mrmac" -l "$label2" -u $mrmac2_base_hex -d $dts_file -p $bus_node]
        add_prop "$mrmac2_node" "compatible" "$compatible" stringlist $dts_file
        mrmac_generate_reg_property $mrmac2_node $mrmac2_base $mrmac2_highaddr_hex

        lappend clknames2 "$s_axi_aclk" "$rx_axi_clk2" "$rx_flexif_clk2" "$rx_ts_clk2" "$tx_axi_clk2" "$tx_flexif_clk2" "$tx_ts_clk2"
        set index2 [lindex $clk_list $s_axi_aclk_index0]
        regsub -all "\<&" $index2 {} index2
        regsub -all "\<&" $index2 {} index2
        set txindex2 [lindex $clk_list $tx_ts_clk_index2]
        regsub -all "\>" $txindex2 {} txindex2
        append clkvals2  "$index2,[lindex $clk_list $rx_axi_clk_index2], [lindex $clk_list $rx_flexif_clk_index2], [lindex $clk_list $rx_ts_clk2_index2], [lindex $clk_list $tx_axi_clk_index2], [lindex $clk_list $tx_flexif_clk_index2], $txindex2"
        add_prop "${mrmac2_node}" "clocks" $clkvals2 reference $dts_file
        add_prop "${mrmac2_node}" "clock-names" $clknames2 stringlist $dts_file
        set port2_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "rx_axis_tdata4"]]
        foreach pin $port2_pins {
                set sink_periph [hsi::get_cells -of_objects $pin]
                set mux_ip ""
                set fifo_ip ""
                if {[llength $sink_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
                                   set fifo_width_bytes [hsi get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
                                   if {[string_is_empty $fifo_width_bytes]} {
                                           set fifo_width_bytes 1
                                   }
                                   set rxethmem [hsi get_property CONFIG.FIFO_DEPTH $sink_periph]
                                   # FIFO can be other than 8 bits, and we need the rxmem in bytes
                                   set rxethmem [expr $rxethmem * $fifo_width_bytes]
                                   add_prop "${mrmac2_node}" "xlnx,rxmem" $rxethmem int
                                   set fifo2_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "m_axis_tdata"]]
                                   set mux_per2 [::hsi::get_cells -of_objects $fifo2_pin]
                                   if {[string match -nocase [hsi get_property IP_NAME $mux_per2] "mrmac_10g_mux"]} {
                                           set data_fifo_pin2 [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mux_per2] "rx_m_axis_tdata"]]
                                           set data_fifo_per2 [hsi::get_cells -of_objects $data_fifo_pin2]
                                           if {[string match -nocase [hsi get_property IP_NAME $data_fifo_per2] "axis_data_fifo"]} {
                                                   set fiforx_connect_ip2 [get_connected_stream_ip [hsi::get_cells -hier $data_fifo_per2] "M_AXIS"]
                                                   set fiforx2_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $data_fifo_per2] "m_axis_tdata"]]
                                                   set fiforx2_per [::hsi::get_cells -of_objects $fiforx2_pin]
                                                   if {[string match -nocase [hsi get_property IP_NAME $fiforx2_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
                                                           set fiforx_connect_ip2 [get_connected_stream_ip [hsi get_cells -hier $fiforx2_per] "M_AXIS"]
                                                   }
                                                   if {[llength $fiforx_connect_ip2]} {
                                                   if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip2] "axi_mcdma"]} {
                                                           add_prop "$mrmac2_node" "axistream-connected" "$fiforx_connect_ip2" reference
                                                           set num_queues [hsi get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip2]
                                                           set inhex [format %x $num_queues]
                                                           append numqueues2 "/bits/ 16 <0x$inhex>"
                                                           add_prop $mrmac2_node "xlnx,num-queues" $numqueues2 stringlist $dts_file
                                                           set id 1
                                                           for {set i 2} {$i <= $num_queues} {incr i} {
                                                                   set i [format "%" $i]
                                                                   append id "\""
                                                                   append id ",\"" $i
                                                                   set i [expr 0x$i]
                                                           }
                                                           add_prop $mrmac2_node "xlnx,num-queues" $numqueues2 stringlist $dts_file
                                                           add_prop $mrmac2_node "xlnx,channel-ids" $id stringlist $dts_file
                                                           mrmac_generate_intr_info  $drv_handle $mrmac2_node $fiforx_connect_ip2
                                                   }
                                               }
                                        }
                                }
                        }
    }
           }

           set txtodport2_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_2"]]
        if {[llength $txtodport2_pins]} {
                       set tod2_sink_periph [hsi::get_cells -of_objects $txtodport2_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $tod2_sink_periph] "mrmac_ptp_timestamp_if"]} {
                           set port_pins [get_sink_pins [hsi get_pins -of_objects [hsi get_cells -hier $tod2_sink_periph] "tx_timestamp_tod"]]
                           set tod2_sink_periph [::hsi::get_cells -of_objects $port_pins]
                   }
           
           if {[string match -nocase [hsi get_property IP_NAME $tod2_sink_periph] "xlconcat"]} {
                   set intf "dout"
                   set in2_pin [hsi::get_pins -of_objects $tod2_sink_periph -filter "NAME==$intf"]
                   set in2sink_pins [get_sink_pins $in2_pin]
                   set xl_per2 [::hsi::get_cells -of_objects $in2sink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $xl_per2] "axis_dwidth_converter"]} {
                           set port2pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $xl_per2] "m_axis_tdata"]]
                           set axis_per2 [hsi::get_cells -of_objects $port2pins]
                           if {[string match -nocase [hsi get_property IP_NAME $axis_per2] "axis_clock_converter"]} {
                                   set tx2_ip [get_connected_stream_ip [hsi::get_cells -hier $axis_per2] "M_AXIS"]
                                   if {[llength $tx2_ip]} {
                                           add_prop "$mrmac2_node" "axififo-connected" $tx2_ip reference $dts_file
                                   }
                        }
                   }
           }
        } else {
                dtg_warning "tx_timestamp_tod_2 connected pins are NULL...please check the design..."
        }
           set rxtod2_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "rx_ptp_tstamp_out_2"]]
        if {[llength $rxtod2_pins]} {
                set rx_periph2 [hsi::get_cells -of_objects $rxtod2_pins]
                if {[string match -nocase [hsi get_property IP_NAME $rx_periph2] "mrmac_ptp_timestamp_if"]} {
                           set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rx_periph2] "rx_timestamp_tod"]]
                           set rx_periph2 [::hsi::get_cells -of_objects $port_pins]
                }
           if {[string match -nocase [hsi get_property IP_NAME $rx_periph2] "xlconcat"]} {
                   set intf "dout"
                   set inrx2_pin [hsi::get_pins -of_objects $rx_periph2 -filter "NAME==$intf"]
                   set rxtodsink_pins [get_sink_pins $inrx2_pin]
                   set rx_per2 [hsi::get_cells -of_objects $rxtodsink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $rx_per2] "axis_dwidth_converter"]} {
                           set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rx_per2] "m_axis_tdata"]]
                           set rx_axis_per2 [hsi::get_cells -of_objects $port_pins]
                           if {[string match -nocase [hsi get_property IP_NAME $rx_axis_per2] "axis_clock_converter"]} {
                                   set rx_ip2 [get_connected_stream_ip [hsi::get_cells -hier $rx_axis_per2] "M_AXIS"]
                                   if {[llength $rx_ip2]} {
                                           add_prop "$mrmac2_node" "xlnx,rxtsfifo" $rx_ip2 reference $dts_file
                                }

                        }
                }
        }
        } else {
                dtg_warning "rx_timestamp_tod_2 connected pins are NULL...please check the design..."
        }
           if {[llength $handle]} {
                   add_prop "$mrmac2_node" "xlnx,gtctrl" $handle reference $dts_file
           }
           if {[llength $mask_handle]} {
                   add_prop "$mrmac2_node" "xlnx,gtpll" $mask_handle reference $dts_file
           }
           if {[llength $gt_reset_per]} {
                   add_prop "$mrmac2_node" "xlnx,gtctrl" $gt_reset_per reference $dts_file
           }
           if {[llength $gt_pll_per]} {
                   add_prop "$mrmac2_node" "xlnx,gtpll" $gt_pll_per reference $dts_file
           }

           add_prop "$mrmac2_node" "xlnx,phcindex" 2 int $dts_file
           add_prop "$mrmac2_node" "xlnx,gtlane" 2 int $dts_file
        set FEC_SLICE2_CFG_C0 [hsi get_property CONFIG.C_FEC_SLICE2_CFG_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-slice2-cfg-c0" $FEC_SLICE2_CFG_C0 string $dts_file
        set FEC_SLICE2_CFG_C1 [hsi get_property CONFIG.C_FEC_SLICE2_CFG_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-slice2-cfg-c1" $FEC_SLICE2_CFG_C1 string $dts_file
        set FLEX_PORT2_DATA_RATE_C0 [hsi get_property CONFIG.C_FLEX_PORT2_DATA_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-port2-data-rate-c0" $FLEX_PORT2_DATA_RATE_C0 string $dts_file
        set FLEX_PORT2_DATA_RATE_C1 [hsi get_property CONFIG.C_FLEX_PORT2_DATA_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-port2-data-rate-c1" $FLEX_PORT2_DATA_RATE_C1 string $dts_file
        set FLEX_PORT2_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.C_FLEX_PORT2_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-port2-enable-time-stamping-c0" $FLEX_PORT2_ENABLE_TIME_STAMPING_C0 int $dts_file
        set FLEX_PORT2_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.C_FLEX_PORT2_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-port2-enable-time-stamping-c1" $FLEX_PORT2_ENABLE_TIME_STAMPING_C1 int $dts_file
        set FLEX_PORT2_MODE_C0 [hsi get_property CONFIG.C_FLEX_PORT2_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-port2-mode-c0" $FLEX_PORT2_MODE_C0 string $dts_file
        set FLEX_PORT2_MODE_C1 [hsi get_property CONFIG.C_FLEX_PORT2_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,flex-port2-mode-c1" $FLEX_PORT2_MODE_C1 string $dts_file
        set PORT2_1588v2_Clocking_C0 [hsi get_property CONFIG.PORT2_1588v2_Clocking_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,port2-1588v2-clocking-c0" $PORT2_1588v2_Clocking_C0 string $dts_file
        set PORT2_1588v2_Clocking_C1 [hsi get_property CONFIG.PORT2_1588v2_Clocking_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,port2-1588v2-clocking-c1" $PORT2_1588v2_Clocking_C1 string $dts_file
        set PORT2_1588v2_Operation_MODE_C0 [hsi get_property CONFIG.PORT2_1588v2_Operation_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,port2-1588v2-operation-mode-c0" $PORT2_1588v2_Operation_MODE_C0 string $dts_file
        set PORT2_1588v2_Operation_MODE_C1 [hsi get_property CONFIG.PORT2_1588v2_Operation_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,port2-1588v2-operation-mode-c1" $PORT2_1588v2_Operation_MODE_C1 string $dts_file
        set MAC_PORT2_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.MAC_PORT2_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-enable-time-stamping-c0" $MAC_PORT2_ENABLE_TIME_STAMPING_C0 int $dts_file
        set MAC_PORT2_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.MAC_PORT2_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-enable-time-stamping-c1" $MAC_PORT2_ENABLE_TIME_STAMPING_C1 int $dts_file
        set MAC_PORT2_RATE_C0 [hsi get_property CONFIG.MAC_PORT2_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $MAC_PORT2_RATE_C0 "10GE"]} {
                   set number 10000
                add_prop "${mrmac2_node}" "xlnx,mrmac-rate" $number int $dts_file
            } else {
                add_prop "${mrmac2_node}" "xlnx,mrmac-rate" $MAC_PORT2_RATE_C0 string $dts_file
        }
        set MAC_PORT2_RATE_C1 [hsi get_property CONFIG.MAC_PORT2_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rate-c1" $MAC_PORT2_RATE_C1 string $dts_file
        set MAC_PORT2_RX_ETYPE_GCP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gcp-c0" $MAC_PORT2_RX_ETYPE_GCP_C0 int $dts_file
        set MAC_PORT2_RX_ETYPE_GCP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gcp-c1" $MAC_PORT2_RX_ETYPE_GCP_C1 int $dts_file
        set MAC_PORT2_RX_ETYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gpp-c0" $MAC_PORT1_RX_ETYPE_GPP_C0 int $dts_file
        set MAC_PORT2_RX_ETYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-gpp-c1" $MAC_PORT2_RX_ETYPE_GPP_C1 int $dts_file
        set MAC_PORT2_RX_ETYPE_PCP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-pcp-c0" $MAC_PORT2_RX_ETYPE_PCP_C0 int $dts_file
        set MAC_PORT2_RX_ETYPE_PCP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-pcp-c1" $MAC_PORT2_RX_ETYPE_PCP_C1 int $dts_file
        set MAC_PORT2_RX_ETYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-ppp-c0" $MAC_PORT2_RX_ETYPE_PPP_C0 int $dts_file
        set MAC_PORT2_RX_ETYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_ETYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-etype-ppp-c1" $MAC_PORT2_RX_ETYPE_PPP_C1 int $dts_file
        set MAC_PORT2_RX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT2_RX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-flow-c0" $MAC_PORT2_RX_FLOW_C0 int $dts_file
        set MAC_PORT2_RX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT2_RX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-flow-c1" $MAC_PORT2_RX_FLOW_C1 int $dts_file
        set MAC_PORT2_RX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-gpp-c0" $MAC_PORT2_RX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT2_RX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-gpp-c1" $MAC_PORT2_RX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT2_RX_OPCODE_MAX_GCP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-gcp-c0" $MAC_PORT2_RX_OPCODE_MAX_GCP_C0 int $dts_file
        set MAC_PORT2_RX_OPCODE_MAX_GCP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-gcp-c1" $MAC_PORT2_RX_OPCODE_MAX_GCP_C1 int $dts_file
        set MAC_PORT2_RX_OPCODE_MAX_PCP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-pcp-c0" $MAC_PORT2_RX_OPCODE_MAX_PCP_C0 int $dts_file
        set MAC_PORT2_RX_OPCODE_MAX_PCP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MAX_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-max-pcp-c1" $MAC_PORT2_RX_OPCODE_MAX_PCP_C1 int $dts_file
        set MAC_PORT2_RX_OPCODE_MIN_GCP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-gcp-c0" $MAC_PORT2_RX_OPCODE_MIN_GCP_C0 int $dts_file
        set MAC_PORT2_RX_OPCODE_MIN_GCP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-gcp-c1" $MAC_PORT2_RX_OPCODE_MIN_GCP_C1 int $dts_file
        set MAC_PORT2_RX_OPCODE_MIN_PCP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-pcp-c0" $MAC_PORT2_RX_OPCODE_MIN_PCP_C0 int $dts_file
        set MAC_PORT2_RX_OPCODE_MIN_PCP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_MIN_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-min-pcp-c1" $MAC_PORT2_RX_OPCODE_MIN_PCP_C1 int $dts_file
        set MAC_PORT2_RX_OPCODE_PPP_C0 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-ppp-c0" $MAC_PORT2_RX_OPCODE_PPP_C0 int $dts_file
        set MAC_PORT2_RX_OPCODE_PPP_C1 [hsi get_property CONFIG.MAC_PORT2_RX_OPCODE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-opcode-ppp-c1" $MAC_PORT2_RX_OPCODE_PPP_C1 int $dts_file
        set MAC_PORT2_RX_PAUSE_DA_MCAST_C0 [hsi get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_MCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_RX_PAUSE_DA_MCAST_C0 [mrmac_check_size $MAC_PORT2_RX_PAUSE_DA_MCAST_C0 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-mcast-c0" $MAC_PORT2_RX_PAUSE_DA_MCAST_C0 int $dts_file
        set MAC_PORT2_RX_PAUSE_DA_MCAST_C1 [hsi get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_MCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_RX_PAUSE_DA_MCAST_C1 [mrmac_check_size $MAC_PORT2_RX_PAUSE_DA_MCAST_C1 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-mcast-c1" $MAC_PORT2_RX_PAUSE_DA_MCAST_C1 int $dts_file
        set MAC_PORT2_RX_PAUSE_DA_UCAST_C0 [hsi get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_UCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_RX_PAUSE_DA_UCAST_C0 [mrmac_check_size $MAC_PORT2_RX_PAUSE_DA_UCAST_C0 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-ucast-c0" $MAC_PORT2_RX_PAUSE_DA_UCAST_C0 int $dts_file
        set MAC_PORT2_RX_PAUSE_DA_UCAST_C1 [hsi get_property CONFIG.MAC_PORT2_RX_PAUSE_DA_UCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_RX_PAUSE_DA_UCAST_C1 [mrmac_check_size $MAC_PORT2_RX_PAUSE_DA_UCAST_C1 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-pause-da-ucast-c1" $MAC_PORT2_RX_PAUSE_DA_UCAST_C1 int $dts_file
        set MAC_PORT2_RX_PAUSE_SA_C0 [hsi get_property CONFIG.MAC_PORT2_RX_PAUSE_SA_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_RX_PAUSE_SA_C0 [mrmac_check_size $MAC_PORT2_RX_PAUSE_SA_C0 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-pause-sa-c0" $MAC_PORT2_RX_PAUSE_SA_C0 int $dts_file
        set MAC_PORT2_RX_PAUSE_SA_C1 [hsi get_property CONFIG.MAC_PORT2_RX_PAUSE_SA_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_RX_PAUSE_SA_C1 [mrmac_check_size $MAC_PORT2_RX_PAUSE_SA_C1 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-rx-pause-sa-c1" $MAC_PORT2_RX_PAUSE_SA_C1 int $dts_file
        set MAC_PORT2_TX_DA_GPP_C0 [hsi get_property CONFIG.MAC_PORT2_TX_DA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_DA_GPP_C0 [mrmac_check_size $MAC_PORT2_TX_DA_GPP_C0 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-da-gpp-c0" $MAC_PORT2_TX_DA_GPP_C0 int $dts_file
        set MAC_PORT2_TX_DA_GPP_C1 [hsi get_property CONFIG.MAC_PORT2_TX_DA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_DA_GPP_C1 [mrmac_check_size $MAC_PORT2_TX_DA_GPP_C1 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-da-gpp-c1" $MAC_PORT2_TX_DA_GPP_C1 int $dts_file
        set MAC_PORT2_TX_DA_PPP_C0 [hsi get_property CONFIG.MAC_PORT2_TX_DA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_DA_PPP_C0 [mrmac_check_size $MAC_PORT2_TX_DA_PPP_C0 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-da-ppp-c0" $MAC_PORT2_TX_DA_PPP_C0 int $dts_file
        set MAC_PORT2_TX_DA_PPP_C1 [hsi get_property CONFIG.MAC_PORT2_TX_DA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_DA_PPP_C1 [mrmac_check_size $MAC_PORT2_TX_DA_PPP_C1 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-da-ppp-c1" $MAC_PORT2_TX_DA_PPP_C1 int $dts_file
        set MAC_PORT2_TX_ETHERTYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-gpp-c0" $MAC_PORT2_TX_ETHERTYPE_GPP_C0 int $dts_file
        set MAC_PORT2_TX_ETHERTYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-gpp-c1" $MAC_PORT2_TX_ETHERTYPE_GPP_C1 int $dts_file
        set MAC_PORT2_TX_ETHERTYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-ppp-c0" $MAC_PORT2_TX_ETHERTYPE_PPP_C0 int $dts_file
        set MAC_PORT2_TX_ETHERTYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT2_TX_ETHERTYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-ethertype-ppp-c1" $MAC_PORT2_TX_ETHERTYPE_PPP_C1 int $dts_file
        set MAC_PORT2_TX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT2_TX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-flow-c0" $MAC_PORT2_TX_FLOW_C0 int $dts_file
        set MAC_PORT2_TX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT2_TX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-flow-c1" $MAC_PORT2_TX_FLOW_C1 int $dts_file
        set MAC_PORT2_TX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT2_TX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-opcode-gpp-c0" $MAC_PORT2_TX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT2_TX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT2_TX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-opcode-gpp-c1" $MAC_PORT2_TX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT2_TX_SA_GPP_C0 [hsi get_property CONFIG.MAC_PORT2_TX_SA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_SA_GPP_C0 [mrmac_check_size $MAC_PORT2_TX_SA_GPP_C0 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-sa-gpp-c0" $MAC_PORT2_TX_SA_GPP_C0 int $dts_file
        set MAC_PORT2_TX_SA_GPP_C1 [hsi get_property CONFIG.MAC_PORT2_TX_SA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_SA_GPP_C1 [mrmac_check_size $MAC_PORT2_TX_SA_GPP_C1 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-sa-gpp-c1" $MAC_PORT2_TX_SA_GPP_C1 int $dts_file
        set MAC_PORT2_TX_SA_PPP_C0 [hsi get_property CONFIG.MAC_PORT2_TX_SA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_SA_PPP_C0 [mrmac_check_size $MAC_PORT2_TX_SA_PPP_C0 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-sa-ppp-c0" $MAC_PORT2_TX_SA_PPP_C0 int $dts_file
        set MAC_PORT2_TX_SA_PPP_C1 [hsi get_property CONFIG.MAC_PORT2_TX_SA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT2_TX_SA_PPP_C1 [mrmac_check_size $MAC_PORT2_TX_SA_PPP_C1 $mrmac2_node]
        add_prop "${mrmac2_node}" "xlnx,mac-port2-tx-sa-ppp-c1" $MAC_PORT2_TX_SA_PPP_C1 int $dts_file
        set GT_CH2_RXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-enable-c0" $GT_CH2_RXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH2_RXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-enable-c1" $GT_CH2_RXPROGDIV_FREQ_ENABLE_C1 string $dts_file

        set GT_CH2_RXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-source-c0" $GT_CH2_RXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH2_RXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-source-c1" $GT_CH2_RXPROGDIV_FREQ_SOURCE_C1 string $dts_file
        set GT_CH2_RXPROGDIV_FREQ_VAL_C0 [hsi get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_VAL_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-val-c0" $GT_CH2_RXPROGDIV_FREQ_VAL_C0 string $dts_file
        set GT_CH2_RXPROGDIV_FREQ_VAL_C1 [hsi get_property CONFIG.GT_CH2_RXPROGDIV_FREQ_VAL_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rxprogdiv-freq-val-c1" $GT_CH2_RXPROGDIV_FREQ_VAL_C1 string $dts_file
        set GT_CH2_RX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH2_RX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-buffer-mode-c0" $GT_CH2_RX_BUFFER_MODE_C0 int $dts_file
        set GT_CH2_RX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH2_RX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-buffer-mode-c1" $GT_CH2_RX_BUFFER_MODE_C1 int $dts_file
        set GT_CH2_RX_DATA_DECODING_C0 [hsi get_property CONFIG.GT_CH2_RX_DATA_DECODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-data-decoding-c0" $GT_CH2_RX_DATA_DECODING_C0 string $dts_file
        set GT_CH2_RX_DATA_DECODING_C1 [hsi get_property CONFIG.GT_CH2_RX_DATA_DECODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-data-decoding-c1" $GT_CH2_RX_DATA_DECODING_C1 string $dts_file

        set GT_CH2_RX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH2_RX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-int-data-width-c0" $GT_CH2_RX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH2_RX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH2_RX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-int-data-width-c1" $GT_CH2_RX_INT_DATA_WIDTH_C1 int $dts_file

        set GT_CH2_RX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH2_RX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-line-rate-c0" $GT_CH2_RX_LINE_RATE_C0 string $dts_file
        set GT_CH2_RX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH2_RX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-line-rate-c1" $GT_CH2_RX_LINE_RATE_C1 string $dts_file

        set GT_CH2_RX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH2_RX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-outclk-source-c0" $GT_CH2_RX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH2_RX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH2_RX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-outclk-source-c1" $GT_CH2_RX_OUTCLK_SOURCE_C1 string $dts_file

        set GT_CH2_RX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH2_RX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-refclk-frequency-c0" $GT_CH2_RX_REFCLK_FREQUENCY_C0 string $dts_file
        set GT_CH2_RX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH2_RX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-refclk-frequency-c1" $GT_CH2_RX_REFCLK_FREQUENCY_C1 string $dts_file

        set GT_CH2_RX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH2_RX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-user-data-width-c0" $GT_CH2_RX_USER_DATA_WIDTH_C0 string $dts_file
        set GT_CH2_RX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH2_RX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-rx-user-data-width-c1" $GT_CH2_RX_USER_DATA_WIDTH_C1 string $dts_file

        set GT_CH2_TXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-txprogdiv-freq-enable-c0" $GT_CH2_TXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH2_TXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac1_node}" "xlnx,gt-ch2-txprogdiv-freq-enable-c1" $GT_CH2_TXPROGDIV_FREQ_ENABLE_C1 string $dts_file

        set GT_CH2_TXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-txprogdiv-freq-source-c0" $GT_CH2_TXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH2_TXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH2_TXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-txprogdiv-freq-source-c1" $GT_CH2_TXPROGDIV_FREQ_SOURCE_C1 string $dts_file

        set GT_CH2_TX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH2_TX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-buffer-mode-c0" $GT_CH2_TX_BUFFER_MODE_C0 int $dts_file
        set GT_CH2_TX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH2_TX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-buffer-mode-c1" $GT_CH2_TX_BUFFER_MODE_C1 int $dts_file

        set GT_CH2_TX_DATA_ENCODING_C0 [hsi get_property CONFIG.GT_CH2_TX_DATA_ENCODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-data-encoding-c0" $GT_CH2_TX_DATA_ENCODING_C0 string $dts_file
        set GT_CH2_TX_DATA_ENCODING_C1 [hsi get_property CONFIG.GT_CH2_TX_DATA_ENCODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-data-encoding-c1" $GT_CH2_TX_DATA_ENCODING_C1 string $dts_file

        set GT_CH2_TX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH2_TX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-int-data-width-c0" $GT_CH2_TX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH2_TX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH2_TX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-int-data-width-c1" $GT_CH2_TX_INT_DATA_WIDTH_C1 int $dts_file

        set GT_CH2_TX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH2_TX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-line-rate-c0" $GT_CH2_TX_LINE_RATE_C0 string $dts_file
        set GT_CH2_TX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH2_TX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-line-rate-c1" $GT_CH2_TX_LINE_RATE_C1 string $dts_file

        set GT_CH2_TX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH2_TX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-outclk-source-c0" $GT_CH2_TX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH2_TX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH2_TX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-outclk-source-c1" $GT_CH2_TX_OUTCLK_SOURCE_C1 string $dts_file

        set GT_CH2_TX_PLL_TYPE_C0 [hsi get_property CONFIG.GT_CH2_TX_PLL_TYPE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-pll-type-c0" $GT_CH2_TX_PLL_TYPE_C0 string $dts_file
        set GT_CH2_TX_PLL_TYPE_C1 [hsi get_property CONFIG.GT_CH2_TX_PLL_TYPE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-pll-type-c1" $GT_CH2_TX_PLL_TYPE_C1 string $dts_file

        set GT_CH2_TX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH2_TX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-refclk-frequency-c0" $GT_CH2_TX_REFCLK_FREQUENCY_C0 string $dts_file
        set GT_CH2_TX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH2_TX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-refclk-frequency-c1" $GT_CH2_TX_REFCLK_FREQUENCY_C1 string $dts_file

            set GT_CH2_TX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH2_TX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-user-data-width-c0" $GT_CH2_TX_USER_DATA_WIDTH_C0 int $dts_file
        set GT_CH2_TX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH2_TX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac2_node}" "xlnx,gt-ch2-tx-user-data-width-c1" $GT_CH2_TX_USER_DATA_WIDTH_C1 int $dts_file

        set mrmac3_base [format 0x%x [expr $base_addr + 0x3000]]
        set mrmac3_base_hex [format %x $mrmac3_base]
        set mrmac3_highaddr_hex [format 0x%x [expr $mrmac3_base + 0xFFF]]
        set port3 3
        append label3 $drv_handle "_" $port3
        set mrmac3_node [create_node -n "mrmac" -l "$label3" -u $mrmac3_base_hex -d $dts_file -p $bus_node]
        add_prop "$mrmac3_node" "compatible" "$compatible" stringlist $dts_file
        mrmac_generate_reg_property $mrmac3_node $mrmac3_base $mrmac3_highaddr_hex
        set port3_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "rx_axis_tdata6"]]
        foreach pin $port3_pins {
                set sink_periph [hsi::get_cells -of_objects $pin]
                set mux_ip ""
                set fifo_ip ""
                if {[llength $sink_periph]} {
                           if {[string match -nocase [hsi get_property IP_NAME $sink_periph] "axis_data_fifo"]} {
                                   set fifo_width_bytes [hsi get_property CONFIG.TDATA_NUM_BYTES $sink_periph]
                                   if {[string_is_empty $fifo_width_bytes]} {
                                           set fifo_width_bytes 1
                                   }
                                   set rxethmem [hsi get_property CONFIG.FIFO_DEPTH $sink_periph]
                                   # FIFO can be other than 8 bits, and we need the rxmem in bytes
                                   set rxethmem [expr $rxethmem * $fifo_width_bytes]
                                   add_prop "${mrmac3_node}" "xlnx,rxmem" $rxethmem int
                                   set fifo3_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $sink_periph] "m_axis_tdata"]]
                                   set mux_per3 [hsi::get_cells -of_objects $fifo3_pin]
                                   if {[string match -nocase [hsi get_property IP_NAME $mux_per3] "mrmac_10g_mux"]} {
                                           set data_fifo_pin3 [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mux_per3] "rx_m_axis_tdata"]]
                                           set data_fifo_per3 [hsi::get_cells -of_objects $data_fifo_pin3]
                                           if {[string match -nocase [hsi get_property IP_NAME $data_fifo_per3] "axis_data_fifo"]} {
                                                   set fiforx_connect_ip3 [get_connected_stream_ip [hsi::get_cells -hier $data_fifo_per3] "M_AXIS"]
                                                   set fiforx3_pin [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $data_fifo_per3] "m_axis_tdata"]]
                                                   set fiforx3_per [::hsi::get_cells -of_objects $fiforx3_pin]
                                                   if {[string match -nocase [hsi::get_property IP_NAME $fiforx3_per] "RX_PTP_PKT_DETECT_TS_PREPEND"]} {
                                                           set fiforx_connect_ip3 [get_connected_stream_ip [hsi::get_cells -hier $fiforx3_per] "M_AXIS"]
                                                   }
                                                   if {[llength $fiforx_connect_ip3]} {
                                               
                                                   if {[string match -nocase [hsi get_property IP_NAME $fiforx_connect_ip3] "axi_mcdma"]} {
                                                           add_prop "$mrmac3_node" "axistream-connected" "$fiforx_connect_ip3" reference
                                                           set num_queues [hsi get_property CONFIG.c_num_mm2s_channels $fiforx_connect_ip3]
                                                           set inhex [format %x $num_queues]
                                                           append numqueues3 "/bits/ 16 <0x$inhex>"
                                                           add_prop $mrmac3_node "xlnx,num-queues" $numqueues3 stringlist $dts_file
                                                           set id 1
                                                           for {set i 2} {$i <= $num_queues} {incr i} {
                                                                   set i [format "%" $i]
                                                                   append id "\""
                                                                   append id ",\"" $i
                                                                   set i [expr 0x$i]
                                                           }
                                                           add_prop $mrmac3_node "xlnx,num-queues" $numqueues3 stringlist $dts_file
                                                           add_prop $mrmac3_node "xlnx,channel-ids" $id stringlist $dts_file
                                                           mrmac_generate_intr_info  $drv_handle $mrmac3_node $fiforx_connect_ip3
                                                   }
                                               }
                                        }
                                }
                        }
                   }
           }
           set txtodport3_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "tx_ptp_tstamp_tag_out_3"]]
        if {[llength $txtodport3_pins]} {
               set tod3_sink_periph [::hsi::get_cells -of_objects $txtodport3_pins]
                   if {[string match -nocase [hsi::get_property IP_NAME $tod3_sink_periph] "mrmac_ptp_timestamp_if"]} {
                           set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $tod3_sink_periph] "tx_timestamp_tod"]]
                           set tod3_sink_periph [::hsi::get_cells -of_objects $port_pins]
                   }
           if {[string match -nocase [hsi get_property IP_NAME $tod3_sink_periph] "xlconcat"]} {
                   set intf "dout"
                   set in3_pin [hsi::get_pins -of_objects $tod3_sink_periph -filter "NAME==$intf"]
                   set in3sink_pins [get_sink_pins $in3_pin]
                   set xl_per3 [hsi::get_cells -of_objects $in3sink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $xl_per3] "axis_dwidth_converter"]} {
                           set port3pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $xl_per3] "m_axis_tdata"]]
                           set axis_per3 [hsi::get_cells -of_objects $port3pins]
                           if {[string match -nocase [hsi get_property IP_NAME $axis_per3] "axis_clock_converter"]} {
                                   set tx3_ip [get_connected_stream_ip [hsi::get_cells -hier $axis_per3] "M_AXIS"]
                                   if {[llength $tx3_ip]} {
                                           add_prop "$mrmac3_node" "axififo-connected" $tx3_ip reference $dts_file
                                }
                           }
                   }
           }
        } else {
                dtg_warning "tx_timestamp_tod_3 connected pins are NULL...please check the design..."
        }
           set rxtod3_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $mrmac_ip] "rx_timestamp_tod_3"]]
        if {[llength $rxtod3_pins]} {
           set rx_periph3 [::hsi::get_cells -of_objects $rxtod3_pins]
           if {[string match -nocase [hsi get_property IP_NAME $rx_periph3] "xlconcat"]} {
                   set intf "dout"
                   set inrx3_pin [hsi::get_pins -of_objects $rx_periph3 -filter "NAME==$intf"]
                   set rxtodsink_pins [get_sink_pins $inrx3_pin]
                   set rx_per3 [hsi::get_cells -of_objects $rxtodsink_pins]
                   if {[string match -nocase [hsi get_property IP_NAME $rx_per3] "axis_dwidth_converter"]} {
                           set port_pins [get_sink_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $rx_per3] "m_axis_tdata"]]
                           set rx_axis_per3 [hsi::get_cells -of_objects $port_pins]
                           if {[string match -nocase [hsi get_property IP_NAME $rx_axis_per3] "axis_clock_converter"]} {
                                   set rx_ip3 [get_connected_stream_ip [hsi::get_cells -hier $rx_axis_per3] "M_AXIS"]
                                   if {[llength $rx_ip3]} {
                                           add_prop "$mrmac3_node" "xlnx,rxtsfifo" $rx_ip3 reference $dts_file
                                }
                        }
                }
        }
        } else {
                dtg_warning "rx_timestamp_tod_3 connected pins are NULL...please check the design..."
        }
           if {[llength $handle]} {
                   add_prop "$mrmac3_node" "xlnx,gtctrl" $handle reference $dts_file
           }
           if {[llength $mask_handle]} {
                   add_prop "$mrmac3_node" "xlnx,gtpll" $mask_handle reference $dts_file
           }
           if {[llength $gt_reset_per]} {
                   add_prop "$mrmac3_node" "xlnx,gtctrl" $gt_reset_per reference $dts_file
           }
           if {[llength $gt_pll_per]} {
                   add_prop "$mrmac3_node" "xlnx,gtpll" $gt_pll_per reference $dts_file
           }

           add_prop "$mrmac3_node" "xlnx,phcindex" 3 int $dts_file
           add_prop "$mrmac3_node" "xlnx,gtlane" 3 int $dts_file
        lappend clknames3 "$s_axi_aclk" "$rx_axi_clk3" "$rx_flexif_clk3" "$rx_ts_clk3" "$tx_axi_clk3" "$tx_flexif_clk3" "$tx_ts_clk3"
        set index3 [lindex $clk_list $s_axi_aclk_index0]
        regsub -all "\<&" $index3 {} index3
        regsub -all "\<&" $index3 {} index3
        set txindex3 [lindex $clk_list $tx_ts_clk_index3]
        regsub -all "\>" $txindex3 {} txindex3
        append clkvals3  "$index3,[lindex $clk_list $rx_axi_clk_index3], [lindex $clk_list $rx_flexif_clk_index3], [lindex $clk_list $rx_ts_clk3_index3], [lindex $clk_list $tx_axi_clk_index3], [lindex $clk_list $tx_flexif_clk_index3], $txindex3"
        add_prop "${mrmac3_node}" "clocks" $clkvals3 reference $dts_file
        add_prop "${mrmac3_node}" "clock-names" $clknames3 stringlist $dts_file


        set FEC_SLICE3_CFG_C0 [hsi get_property CONFIG.C_FEC_SLICE3_CFG_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-slice3-cfg-c0" $FEC_SLICE3_CFG_C0 string $dts_file
        set FEC_SLICE3_CFG_C1 [hsi get_property CONFIG.C_FEC_SLICE3_CFG_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-slice3-cfg-c1" $FEC_SLICE3_CFG_C1 string $dts_file
        set FLEX_PORT3_DATA_RATE_C0 [hsi get_property CONFIG.C_FLEX_PORT3_DATA_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-port3-data-rate-c0" $FLEX_PORT3_DATA_RATE_C0 string $dts_file
        set FLEX_PORT3_DATA_RATE_C1 [hsi get_property CONFIG.C_FLEX_PORT3_DATA_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-port3-data-rate-c1" $FLEX_PORT3_DATA_RATE_C1 string $dts_file
        set FLEX_PORT3_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.C_FLEX_PORT3_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-port3-enable-time-stamping-c0" $FLEX_PORT3_ENABLE_TIME_STAMPING_C0 int $dts_file
        set FLEX_PORT3_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.C_FLEX_PORT3_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-port3-enable-time-stamping-c1" $FLEX_PORT3_ENABLE_TIME_STAMPING_C1 int $dts_file
        set FLEX_PORT3_MODE_C0 [hsi get_property CONFIG.C_FLEX_PORT3_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-port3-mode-c0" $FLEX_PORT3_MODE_C0 string $dts_file
        set FLEX_PORT3_MODE_C1 [hsi get_property CONFIG.C_FLEX_PORT3_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,flex-port3-mode-c1" $FLEX_PORT3_MODE_C1 string $dts_file
        set PORT3_1588v2_Clocking_C0 [hsi get_property CONFIG.PORT3_1588v2_Clocking_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,port3-1588v2-clocking-c0" $PORT3_1588v2_Clocking_C0 string $dts_file
        set PORT3_1588v2_Clocking_C1 [hsi get_property CONFIG.PORT3_1588v2_Clocking_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,port3-1588v2-clocking-c1" $PORT3_1588v2_Clocking_C1 string $dts_file
        set PORT3_1588v2_Operation_MODE_C0 [hsi get_property CONFIG.PORT3_1588v2_Operation_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,port3-1588v2-operation-mode-c0" $PORT3_1588v2_Operation_MODE_C0 string $dts_file
        set PORT3_1588v2_Operation_MODE_C1 [hsi get_property CONFIG.PORT3_1588v2_Operation_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,port3-1588v2-operation-mode-c1" $PORT3_1588v2_Operation_MODE_C1 string $dts_file
        set MAC_PORT3_ENABLE_TIME_STAMPING_C0 [hsi get_property CONFIG.MAC_PORT3_ENABLE_TIME_STAMPING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-enable-time-stamping-c0" $MAC_PORT3_ENABLE_TIME_STAMPING_C0 int $dts_file
        set MAC_PORT3_ENABLE_TIME_STAMPING_C1 [hsi get_property CONFIG.MAC_PORT3_ENABLE_TIME_STAMPING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-enable-time-stamping-c1" $MAC_PORT3_ENABLE_TIME_STAMPING_C1 int $dts_file
        set MAC_PORT3_RATE_C0 [hsi get_property CONFIG.MAC_PORT3_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $MAC_PORT3_RATE_C0 "10GE"]} {
                   set number 10000
                add_prop "${mrmac3_node}" "xlnx,mrmac-rate" $number int $dts_file
            } else {
                add_prop "${mrmac3_node}" "xlnx,mrmac-rate" $MAC_PORT3_RATE_C0 string $dts_file
        }
        set MAC_PORT3_RATE_C1 [hsi get_property CONFIG.MAC_PORT3_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rate-c1" $MAC_PORT3_RATE_C1 string $dts_file
        set MAC_PORT3_RX_ETYPE_GCP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gcp-c0" $MAC_PORT3_RX_ETYPE_GCP_C0 int $dts_file
        set MAC_PORT3_RX_ETYPE_GCP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gcp-c1" $MAC_PORT3_RX_ETYPE_GCP_C1 int $dts_file
        set MAC_PORT3_RX_ETYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gpp-c0" $MAC_PORT3_RX_ETYPE_GPP_C0 int $dts_file
        set MAC_PORT3_RX_ETYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-gpp-c1" $MAC_PORT3_RX_ETYPE_GPP_C1 int $dts_file
        set MAC_PORT3_RX_ETYPE_PCP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-pcp-c0" $MAC_PORT3_RX_ETYPE_PCP_C0 int $dts_file
        set MAC_PORT3_RX_ETYPE_PCP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-pcp-c1" $MAC_PORT3_RX_ETYPE_PCP_C1 int $dts_file
        set MAC_PORT3_RX_ETYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-ppp-c0" $MAC_PORT3_RX_ETYPE_PPP_C0 int $dts_file
        set MAC_PORT3_RX_ETYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_ETYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-etype-ppp-c1" $MAC_PORT3_RX_ETYPE_PPP_C1 int $dts_file
        set MAC_PORT3_RX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT3_RX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-flow-c0" $MAC_PORT3_RX_FLOW_C0 int $dts_file
        set MAC_PORT3_RX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT3_RX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-flow-c1" $MAC_PORT3_RX_FLOW_C1 int $dts_file
        set MAC_PORT3_RX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-gpp-c0" $MAC_PORT3_RX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT3_RX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-gpp-c1" $MAC_PORT3_RX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT3_RX_OPCODE_MAX_GCP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-gcp-c0" $MAC_PORT3_RX_OPCODE_MAX_GCP_C0 int $dts_file
        set MAC_PORT3_RX_OPCODE_MAX_GCP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-gcp-c1" $MAC_PORT3_RX_OPCODE_MAX_GCP_C1 int $dts_file
        set MAC_PORT3_RX_OPCODE_MAX_PCP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-pcp-c0" $MAC_PORT3_RX_OPCODE_MAX_PCP_C0 int $dts_file

        set MAC_PORT3_RX_OPCODE_MAX_PCP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MAX_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-max-pcp-c1" $MAC_PORT3_RX_OPCODE_MAX_PCP_C1 int $dts_file
        set MAC_PORT3_RX_OPCODE_MIN_GCP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_GCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-gcp-c0" $MAC_PORT3_RX_OPCODE_MIN_GCP_C0 int $dts_file
        set MAC_PORT3_RX_OPCODE_MIN_GCP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_GCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-gcp-c1" $MAC_PORT3_RX_OPCODE_MIN_GCP_C1 int $dts_file
        set MAC_PORT3_RX_OPCODE_MIN_PCP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_PCP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-pcp-c0" $MAC_PORT3_RX_OPCODE_MIN_PCP_C0 int $dts_file
        set MAC_PORT3_RX_OPCODE_MIN_PCP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_MIN_PCP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-min-pcp-c1" $MAC_PORT3_RX_OPCODE_MIN_PCP_C1 int $dts_file
        set MAC_PORT3_RX_OPCODE_PPP_C0 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-ppp-c0" $MAC_PORT3_RX_OPCODE_PPP_C0 int $dts_file
        set MAC_PORT3_RX_OPCODE_PPP_C1 [hsi get_property CONFIG.MAC_PORT3_RX_OPCODE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-opcode-ppp-c1" $MAC_PORT3_RX_OPCODE_PPP_C1 int $dts_file
        set MAC_PORT3_RX_PAUSE_DA_MCAST_C0 [hsi get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_MCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_RX_PAUSE_DA_MCAST_C0 [mrmac_check_size $MAC_PORT3_RX_PAUSE_DA_MCAST_C0 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-mcast-c0" $MAC_PORT3_RX_PAUSE_DA_MCAST_C0 int $dts_file
        set MAC_PORT3_RX_PAUSE_DA_MCAST_C1 [hsi get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_MCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_RX_PAUSE_DA_MCAST_C1 [mrmac_check_size $MAC_PORT3_RX_PAUSE_DA_MCAST_C1 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-mcast-c1" $MAC_PORT3_RX_PAUSE_DA_MCAST_C1 int $dts_file
        set MAC_PORT3_RX_PAUSE_DA_UCAST_C0 [hsi get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_UCAST_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_RX_PAUSE_DA_UCAST_C0 [mrmac_check_size $MAC_PORT3_RX_PAUSE_DA_UCAST_C0 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-ucast-c0" $MAC_PORT3_RX_PAUSE_DA_UCAST_C0 int $dts_file
        set MAC_PORT3_RX_PAUSE_DA_UCAST_C1 [hsi get_property CONFIG.MAC_PORT3_RX_PAUSE_DA_UCAST_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_RX_PAUSE_DA_UCAST_C1 [mrmac_check_size $MAC_PORT3_RX_PAUSE_DA_UCAST_C1 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-pause-da-ucast-c1" $MAC_PORT3_RX_PAUSE_DA_UCAST_C1 int $dts_file
        set MAC_PORT3_RX_PAUSE_SA_C0 [hsi get_property CONFIG.MAC_PORT3_RX_PAUSE_SA_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_RX_PAUSE_SA_C0 [mrmac_check_size $MAC_PORT3_RX_PAUSE_SA_C0 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-pause-sa-c0" $MAC_PORT3_RX_PAUSE_SA_C0 int $dts_file
        set MAC_PORT3_RX_PAUSE_SA_C1 [hsi get_property CONFIG.MAC_PORT3_RX_PAUSE_SA_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_RX_PAUSE_SA_C1 [mrmac_check_size $MAC_PORT3_RX_PAUSE_SA_C1 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-rx-pause-sa-c1" $MAC_PORT3_RX_PAUSE_SA_C1 int $dts_file
        set MAC_PORT3_TX_DA_GPP_C0 [hsi get_property CONFIG.MAC_PORT3_TX_DA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_DA_GPP_C0 [mrmac_check_size $MAC_PORT3_TX_DA_GPP_C0 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-da-gpp-c0" $MAC_PORT3_TX_DA_GPP_C0 int $dts_file
        set MAC_PORT3_TX_DA_GPP_C1 [hsi get_property CONFIG.MAC_PORT3_TX_DA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_DA_GPP_C1 [mrmac_check_size $MAC_PORT3_TX_DA_GPP_C1 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-da-gpp-c1" $MAC_PORT3_TX_DA_GPP_C1 int $dts_file
        set MAC_PORT3_TX_DA_PPP_C0 [hsi get_property CONFIG.MAC_PORT3_TX_DA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_DA_PPP_C0 [mrmac_check_size $MAC_PORT3_TX_DA_PPP_C0 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-da-ppp-c0" $MAC_PORT3_TX_DA_PPP_C0 int $dts_file
        set MAC_PORT3_TX_DA_PPP_C1 [hsi get_property CONFIG.MAC_PORT3_TX_DA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_DA_PPP_C1 [mrmac_check_size $MAC_PORT3_TX_DA_PPP_C1 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-da-ppp-c1" $MAC_PORT3_TX_DA_PPP_C1 int $dts_file
        set MAC_PORT3_TX_ETHERTYPE_GPP_C0 [hsi get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-gpp-c0" $MAC_PORT3_TX_ETHERTYPE_GPP_C0 int $dts_file
        set MAC_PORT3_TX_ETHERTYPE_GPP_C1 [hsi get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-gpp-c1" $MAC_PORT3_TX_ETHERTYPE_GPP_C1 int $dts_file
        set MAC_PORT3_TX_ETHERTYPE_PPP_C0 [hsi get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-ppp-c0" $MAC_PORT3_TX_ETHERTYPE_PPP_C0 int $dts_file
        set MAC_PORT3_TX_ETHERTYPE_PPP_C1 [hsi get_property CONFIG.MAC_PORT3_TX_ETHERTYPE_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-ethertype-ppp-c1" $MAC_PORT3_TX_ETHERTYPE_PPP_C1 int $dts_file
        set MAC_PORT3_TX_FLOW_C0 [hsi get_property CONFIG.MAC_PORT3_TX_FLOW_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-flow-c0" $MAC_PORT3_TX_FLOW_C0 int $dts_file
        set MAC_PORT3_TX_FLOW_C1 [hsi get_property CONFIG.MAC_PORT3_TX_FLOW_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-flow-c1" $MAC_PORT3_TX_FLOW_C1 int $dts_file
        set MAC_PORT3_TX_OPCODE_GPP_C0 [hsi get_property CONFIG.MAC_PORT3_TX_OPCODE_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-opcode-gpp-c0" $MAC_PORT3_TX_OPCODE_GPP_C0 int $dts_file
        set MAC_PORT3_TX_OPCODE_GPP_C1 [hsi get_property CONFIG.MAC_PORT3_TX_OPCODE_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-opcode-gpp-c1" $MAC_PORT2_TX_OPCODE_GPP_C1 int $dts_file
        set MAC_PORT3_TX_SA_GPP_C0 [hsi get_property CONFIG.MAC_PORT3_TX_SA_GPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_SA_GPP_C0 [mrmac_check_size $MAC_PORT3_TX_SA_GPP_C0 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-sa-gpp-c0" $MAC_PORT3_TX_SA_GPP_C0 int $dts_file
        set MAC_PORT3_TX_SA_GPP_C1 [hsi get_property CONFIG.MAC_PORT3_TX_SA_GPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_SA_GPP_C1 [mrmac_check_size $MAC_PORT3_TX_SA_GPP_C1 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-sa-gpp-c1" $MAC_PORT3_TX_SA_GPP_C1 int $dts_file
        set MAC_PORT3_TX_SA_PPP_C0 [hsi get_property CONFIG.MAC_PORT3_TX_SA_PPP_C0 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_SA_PPP_C0 [mrmac_check_size $MAC_PORT3_TX_SA_PPP_C0 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-sa-ppp-c0" $MAC_PORT3_TX_SA_PPP_C0 int $dts_file
        set MAC_PORT3_TX_SA_PPP_C1 [hsi get_property CONFIG.MAC_PORT3_TX_SA_PPP_C1 [hsi::get_cells -hier $drv_handle]]
        set MAC_PORT3_TX_SA_PPP_C1 [mrmac_check_size $MAC_PORT3_TX_SA_PPP_C1 $mrmac3_node]
        add_prop "${mrmac3_node}" "xlnx,mac-port3-tx-sa-ppp-c1" $MAC_PORT3_TX_SA_PPP_C1 int $dts_file
        set GT_CH3_RXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-enable-c0" $GT_CH3_RXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH3_RXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-enable-c1" $GT_CH3_RXPROGDIV_FREQ_ENABLE_C1 string $dts_file

        set GT_CH3_RXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-source-c0" $GT_CH3_RXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH3_RXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-source-c1" $GT_CH3_RXPROGDIV_FREQ_SOURCE_C1 string $dts_file
        set GT_CH3_RXPROGDIV_FREQ_VAL_C0 [hsi get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_VAL_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-val-c0" $GT_CH3_RXPROGDIV_FREQ_VAL_C0 string $dts_file
        set GT_CH3_RXPROGDIV_FREQ_VAL_C1 [hsi get_property CONFIG.GT_CH3_RXPROGDIV_FREQ_VAL_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rxprogdiv-freq-val-c1" $GT_CH3_RXPROGDIV_FREQ_VAL_C1 string $dts_file
        set GT_CH3_RX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH3_RX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-buffer-mode-c0" $GT_CH3_RX_BUFFER_MODE_C0 int $dts_file
        set GT_CH3_RX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH3_RX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-buffer-mode-c1" $GT_CH3_RX_BUFFER_MODE_C1 int $dts_file
        set GT_CH3_RX_DATA_DECODING_C0 [hsi get_property CONFIG.GT_CH3_RX_DATA_DECODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-data-decoding-c0" $GT_CH3_RX_DATA_DECODING_C0 string $dts_file
        set GT_CH3_RX_DATA_DECODING_C1 [hsi get_property CONFIG.GT_CH3_RX_DATA_DECODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-data-decoding-c1" $GT_CH3_RX_DATA_DECODING_C1 string $dts_file


        set GT_CH3_RX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH3_RX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-int-data-width-c0" $GT_CH3_RX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH3_RX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH3_RX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-int-data-width-c1" $GT_CH3_RX_INT_DATA_WIDTH_C1 int $dts_file


        set GT_CH3_RX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH3_RX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-line-rate-c0" $GT_CH3_RX_LINE_RATE_C0 string $dts_file
        set GT_CH3_RX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH3_RX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-line-rate-c1" $GT_CH3_RX_LINE_RATE_C1 string $dts_file


        set GT_CH3_RX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH3_RX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-outclk-source-c0" $GT_CH3_RX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH3_RX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH3_RX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-outclk-source-c1" $GT_CH3_RX_OUTCLK_SOURCE_C1 string $dts_file


        set GT_CH3_RX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH3_RX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-refclk-frequency-c0" $GT_CH3_RX_REFCLK_FREQUENCY_C0 string $dts_file
        set GT_CH3_RX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH3_RX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-refclk-frequency-c1" $GT_CH3_RX_REFCLK_FREQUENCY_C1 string $dts_file


        set GT_CH3_RX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH3_RX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-user-data-width-c0" $GT_CH3_RX_USER_DATA_WIDTH_C0 string $dts_file
        set GT_CH3_RX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH3_RX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-rx-user-data-width-c1" $GT_CH3_RX_USER_DATA_WIDTH_C1 string $dts_file

        set GT_CH3_TXPROGDIV_FREQ_ENABLE_C0 [hsi get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_ENABLE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-enable-c0" $GT_CH3_TXPROGDIV_FREQ_ENABLE_C0 string $dts_file
        set GT_CH3_TXPROGDIV_FREQ_ENABLE_C1 [hsi get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_ENABLE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-enable-c1" $GT_CH3_TXPROGDIV_FREQ_ENABLE_C1 string $dts_file


        set GT_CH3_TXPROGDIV_FREQ_SOURCE_C0 [hsi get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-source-c0" $GT_CH3_TXPROGDIV_FREQ_SOURCE_C0 string $dts_file
        set GT_CH3_TXPROGDIV_FREQ_SOURCE_C1 [hsi get_property CONFIG.GT_CH3_TXPROGDIV_FREQ_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-txprogdiv-freq-source-c1" $GT_CH3_TXPROGDIV_FREQ_SOURCE_C1 string $dts_file
        
        set GT_CH3_TX_BUFFER_MODE_C0 [hsi get_property CONFIG.GT_CH3_TX_BUFFER_MODE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-buffer-mode-c0" $GT_CH3_TX_BUFFER_MODE_C0 int $dts_file
        set GT_CH3_TX_BUFFER_MODE_C1 [hsi get_property CONFIG.GT_CH3_TX_BUFFER_MODE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-buffer-mode-c1" $GT_CH3_TX_BUFFER_MODE_C1 int $dts_file


        set GT_CH3_TX_DATA_ENCODING_C0 [hsi get_property CONFIG.GT_CH3_TX_DATA_ENCODING_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-data-encoding-c0" $GT_CH3_TX_DATA_ENCODING_C0 string $dts_file
        set GT_CH3_TX_DATA_ENCODING_C1 [hsi get_property CONFIG.GT_CH3_TX_DATA_ENCODING_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-data-encoding-c1" $GT_CH3_TX_DATA_ENCODING_C1 string $dts_file

        set GT_CH3_TX_INT_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH3_TX_INT_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-int-data-width-c0" $GT_CH3_TX_INT_DATA_WIDTH_C0 int $dts_file
        set GT_CH3_TX_INT_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH3_TX_INT_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-int-data-width-c1" $GT_CH3_TX_INT_DATA_WIDTH_C1 int $dts_file

        set GT_CH3_TX_LINE_RATE_C0 [hsi get_property CONFIG.GT_CH3_TX_LINE_RATE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-line-rate-c0" $GT_CH3_TX_LINE_RATE_C0 string $dts_file
        set GT_CH3_TX_LINE_RATE_C1 [hsi get_property CONFIG.GT_CH3_TX_LINE_RATE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-line-rate-c1" $GT_CH3_TX_LINE_RATE_C1 string $dts_file


        set GT_CH3_TX_OUTCLK_SOURCE_C0 [hsi get_property CONFIG.GT_CH3_TX_OUTCLK_SOURCE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-outclk-source-c0" $GT_CH3_TX_OUTCLK_SOURCE_C0 string $dts_file
        set GT_CH3_TX_OUTCLK_SOURCE_C1 [hsi get_property CONFIG.GT_CH3_TX_OUTCLK_SOURCE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-outclk-source-c1" $GT_CH3_TX_OUTCLK_SOURCE_C1 string $dts_file


        set GT_CH3_TX_PLL_TYPE_C0 [hsi get_property CONFIG.GT_CH3_TX_PLL_TYPE_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-pll-type-c0" $GT_CH3_TX_PLL_TYPE_C0 string $dts_file
        set GT_CH3_TX_PLL_TYPE_C1 [hsi get_property CONFIG.GT_CH3_TX_PLL_TYPE_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-pll-type-c1" $GT_CH3_TX_PLL_TYPE_C1 string $dts_file


        set GT_CH3_TX_REFCLK_FREQUENCY_C0 [hsi get_property CONFIG.GT_CH3_TX_REFCLK_FREQUENCY_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-refclk-frequency-c0" $GT_CH3_TX_REFCLK_FREQUENCY_C0 string $dts_file
        set GT_CH3_TX_REFCLK_FREQUENCY_C1 [hsi get_property CONFIG.GT_CH3_TX_REFCLK_FREQUENCY_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-refclk-frequency-c1" $GT_CH3_TX_REFCLK_FREQUENCY_C1 string $dts_file


        set GT_CH3_TX_USER_DATA_WIDTH_C0 [hsi get_property CONFIG.GT_CH3_TX_USER_DATA_WIDTH_C0 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-user-data-width-c0" $GT_CH3_TX_USER_DATA_WIDTH_C0 int $dts_file
        set GT_CH3_TX_USER_DATA_WIDTH_C1 [hsi get_property CONFIG.GT_CH3_TX_USER_DATA_WIDTH_C1 [hsi::get_cells -hier $drv_handle]]
        add_prop "${mrmac3_node}" "xlnx,gt-ch3-tx-user-data-width-c1" $GT_CH3_TX_USER_DATA_WIDTH_C1 int $dts_file
    }

    proc mrmac_generate_reg_property {node base high} {
        set size [format 0x%x [expr {${high} - ${base} + 1}]]

        set proctype [hsi get_property IP_NAME [hsi::get_cells -hier [get_sw_processor]]]
        if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
                if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                        set temp $base
                        set temp [string trimleft [string trimleft $temp 0] x]
                        set len [string length $temp]
                        set rem [expr {${len} - 8}]
                        set high_base "0x[string range $temp $rem $len]"
                        set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                        set low_base [format 0x%08x $low_base]
                        if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                                set temp $size
                                set temp [string trimleft [string trimleft $temp 0] x]
                                set len [string length $temp]
                                set rem [expr {${len} - 8}]
                                set high_size "0x[string range $temp $rem $len]"
                                set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
                                set low_size [format 0x%08x $low_size]
                                set reg "$low_base $high_base $low_size $high_size"
                        } else {
                                set reg "$low_base $high_base 0x0 $size"
                        }
                } else {
                        set reg "0x0 $base 0x0 $size"
                }
        } else {
                set reg "$base $size"
        }
        add_prop "${node}" "reg" $reg int $dts_filehexlist
    }

    proc mrmac_generate_intr_info {drv_handle node fifo_ip} {
        set ips [hsi::get_cells -hier $drv_handle]
        foreach ip [get_drivers 1] {
                if {[string compare -nocase $ip $fifo_ip] == 0} {
                        set target_handle $ip
                }
        }
        set temp_node [get_node $target_handle]
        set intr_val $dts_filer_val [pldt get $temp_node interrupts]
        set intr_parent $dts_filer_parent [pldt get $temp_node interrupt-parent]
        set int_names $dts_file_names [pldt get $temp_node interrupt-names]
    #   set int $dts_filer_val [hsi get_property CONFIG.interrupts $target_handle]
    #   set int $dts_filer_parent [hsi get_property CONFIG.interrupt-parent $target_handle]
    #   set int $dts_file_names  [hsi get_property CONFIG.interrupt-names $target_handle]
        add_prop "${node}" "interrupts" $intr_val int $dts_file
        add_prop "${node}" "interrupt-parent" $intr_parent reference $dts_file
        add_prop "${node}" "interrupt-names" $int_names stringlist $dts_file
    }

    proc mrmac_check_size {base node} {
        if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                set temp $base
                set temp [string trimleft [string trimleft $temp 0] x]
                set len [string length $temp]
                set rem [expr {${len} - 8}]
                set high_base "0x[string range $temp $rem $len]"
                set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                set low_base [format 0x%08x $low_base]
                set reg "$low_base $high_base"
        } else {
                set reg "$base"
        }
        return $reg
    }

    proc mrmac_gen_mrmac_clk_property {drv_handle} {
        set dts_file [set_drv_def_dts $drv_handle]
        set proctype [get_hw_family]
        if {[regexp "kintex*" $proctype match]} {
                return
        }
        set clocks ""
        set axi 0
        set is_clk_wiz 0
        set is_pl_clk 0
        set updat ""
        global bus_clk_list
        set clocknames ""
        set clk_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $drv_handle] -filter {TYPE==clk&&DIRECTION==I}]
        set ip [get_ip_property $drv_handle IP_NAME]
        foreach clk $clk_pins {
                set ip [hsi::get_cells -hier $drv_handle]
                set port_width [get_port_width $clk]
                set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] $clk]]
                if {$port_width >= 2} {
                        for {set i 0} { $i < $port_width} {incr i} {
                                set peri [hsi::get_cells -of_objects $pins]
                                set mrclk "$clk$i"
                                if {[llength $peri]} {
                                           if {[string match -nocase [hsi get_property IP_NAME $peri] "xlconcat"]} {
                                                   set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects [hsi::get_cells $peri] In$i]] -filter "DIRECTION==O"]
                                                   set clk_peri [hsi::get_cells -of_objects $pins]
                                           }
                                }
                                set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
                                set pl_clk ""
                                set clkout ""
                                foreach pin $pins {
                                        if {[lsearch $valid_clk_list $pin] >= 0} {
                                                set clkout $pin
                                                set is_clk_wiz 1
                                                set periph [hsi::get_cells -of_objects $pin]
                                        }
                                }
                                if {[llength $clkout]} {
                                        set number [regexp -all -inline -- {[0-9]+} $clkout]
                                        set clk_wiz [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                                        set axi_clk "s_axi_aclk"
                                        foreach clk1 $clk_wiz {
                                                if {[regexp $axi_clk $clk1 match]} {
                                                        set axi 1
                                                }
                                }

                                if {[string match -nocase $axi "0"]} {
                                        dtg_warning "no s_axi_aclk for clockwizard"
                                        set pins [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                                        set clk_list "pl_clk*"
                                        set clk_pl ""
                                        set num ""
                                        foreach clk_wiz_pin $pins {
                                                        set clk_wiz_pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects $clk_wiz_pin]]
                                                        foreach pin $clk_wiz_pins {
                                                                if {[regexp $clk_list $pin match]} {
                                                                        set clk_pl $pin
                                                                }
                                                        }
                                        }
                                        if {[llength $clk_pl]} {
                                                set num [regexp -all -inline -- {[0-9]+} $clk_pl]
                                        }       
                                        if {[string match -nocase $proctype "psu_cortexa53"]} {
                                                        switch $num {
                                                                        "0" {
                                                                                set def_dts "pcw.dtsi"
                                                                                set fclk_node [create_node -n "&fclk0" -d $def_dts -p root]
                                                                                add_prop "${fclk_node}" "status" "okay" string $def_file
                                                                                }
                                                                        "1" {
                                                                                set def_dts "pcw.dtsi"
                                                                                 set fclk_node [create_node -n "&fclk1" -d $def_dts -p root]
                                                                                add_prop "${fclk_node}" "status" "okay" string $def_file
                                                                                }
                                                                        "2" {
                                                                                set def_dts "pcw.dtsi"
                                                                                set fclk_node [create_node -n "&fclk2" -d $def_dts -p root]
                                                                                add_prop "${fclk_node}" "status" "okay" string $def_file
                                                                        }
                                                                        "3" {
                                                                                set def_dts "pcw.dtsi"
                                                                                set fclk_node [create_node -n "&fclk3" -d $def_dts -p root]
                                                                                add_prop "${fclk_node}" "status" "okay" string $def_file
                                                                        }
                                                        }
                                        }
                                        set dts_file "pl.dtsi"
                                        set bus_node [get_node $drv_handle]
                                        set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                                        if {[llength $clk_freq] == 0} {
                                                dtg_warning "clock frequency for the $clk is NULL"
                                                continue
                                        }
                                        set clk_freq [expr int $dts_file($clk_freq)]
                                        set iptype [get_ip_property $drv_handle IP_NAME]
                                        if {![string equal $clk_freq ""]} {
                                                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                                        set bus_clk_list [lappend bus_clk_list $clk_freq]
                                                }
                                                set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                                set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                                -d ${dts_file} -p ${bus_node}]
                                                set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                                set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                                add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                                add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                                add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                                        }
                                }
                                if {![string match -nocase $axi "0"]} {
                                                switch $number {
                                                                "1" {
                                                                        set peri "$periph 0"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "2" {
                                                                        set peri "$periph 1"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "3" {
                                                                        set peri "$periph 2"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "4" {
                                                                        set peri "$periph 3"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "5" {
                                                                        set peri "$periph 4"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "6" {
                                                                        set peri "$periph 5"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                                "7" {
                                                                        set peri "$periph 6"
                                                                        set clocks [lappend clocks $peri]
                                                                        set updat [lappend updat $peri]
                                                                }
                                                }
                                }
                        }
                        if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
                                set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
                        } elseif {[string match -nocase $proctype "ps7_cortexa9"]} {
                                set clklist "FCLK_CLK0 FCLK_CLK1 FCLK_CLK2 FCLK_CLK3"
                        }
                        foreach pin $pins {
                                if {[lsearch $clklist $pin] >= 0} {
                                        set pl_clk $pin
                                        set is_pl_clk 1
                                }
                        }
                        if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
                                switch $pl_clk {
                                                "pl_clk0" {
                                                                set pl_clk0 "versal_clk 65"
                                                                set clocks [lappend clocks $pl_clk0]
                                                                set updat  [lappend updat $pl_clk0]
                                                }
                                                "pl_clk1" {
                                                                set pl_clk1 "versal_clk 66"
                                                                set clocks [lappend clocks $pl_clk1]
                                                                set updat  [lappend updat $pl_clk1]
                                                }
                                                "pl_clk2" {
                                                                set pl_clk2 "versal_clk 67"
                                                                set clocks [lappend clocks $pl_clk2]
                                                                set updat [lappend updat $pl_clk2]
                                                }
                                                "pl_clk3" {
                                                                set pl_clk3 "versal_clk 68"
                                                                set clocks [lappend clocks $pl_clk3]
                                                                set updat [lappend updat $pl_clk3]
                                                }
                                                default {
                                                                dtg_debug "not supported pl_clk:$pl_clk"
                                                }
                                        }
                        }
                        if {[string match -nocase $proctype "psu_cortexa53"]} {
                                        switch $pl_clk {
                                                        "pl_clk0" {
                                                                        set pl_clk0 "zynqmp_clk 71"
                                                                        set clocks [lappend clocks $pl_clk0]
                                                                        set updat  [lappend updat $pl_clk0]
                                                        }
                                                        "pl_clk1" {
                                                                        set pl_clk1 "zynqmp_clk 72"
                                                                        set clocks [lappend clocks $pl_clk1]
                                                                        set updat  [lappend updat $pl_clk1]
                                                        }
                                                        "pl_clk2" {
                                                                        set pl_clk2 "zynqmp_clk 73"
                                                                        set clocks [lappend clocks $pl_clk2]
                                                                        set updat [lappend updat $pl_clk2]
                                                        }
                                                        "pl_clk3" {
                                                                        set pl_clk3 "zynqmp_clk 74"
                                                                        set clocks [lappend clocks $pl_clk3]
                                                                        set updat [lappend updat $pl_clk3]
                                                        }
                                                        default {
                                                                        dtg_debug "not supported pl_clk:$pl_clk"
                                                        }
                                        }
                        }
                        if {[string match -nocase $proctype "ps7_cortexa9"]} {
                                                switch $pl_clk {
                                                        "FCLK_CLK0" {
                                                                        set pl_clk0 "clkc 15"
                                                                        set clocks [lappend clocks $pl_clk0]
                                                                        set updat  [lappend updat $pl_clk0]
                                                        }
                                                        "FCLK_CLK1" {
                                                                        set pl_clk1 "clkc 16"
                                                                        set clocks [lappend clocks $pl_clk1]
                                                                        set updat  [lappend updat $pl_clk1]
                                                        }
                                                        "FCLK_CLK2" {
                                                                        set pl_clk2 "clkc 17"
                                                                        set clocks [lappend clocks $pl_clk2]
                                                                        set updat [lappend updat $pl_clk2]
                                                        }
                                                        "FCLK_CLK3" {
                                                                        set pl_clk3 "clkc 18"
                                                                        set clocks [lappend clocks $pl_clk3]
                                                                        set updat [lappend updat $pl_clk3]
                                                        }       
                                                        default {
                                                                        dtg_debug "not supported pl_clk:$pl_clk"
                                                        }
                                                }
                        }
                        if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
                                        set dts_file "pl.dtsi"
                                        set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                                        set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                                        if {[llength $clk_freq] == 0} {
                                                dtg_warning "clock frequency for the $clk is NULL"
                                                continue
                                        }
                                        set clk_freq [expr int $dts_file($clk_freq)]
                                        set iptype [get_ip_property $drv_handle IP_NAME]
                                        if {![string equal $clk_freq ""]} {
                                                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                                        set bus_clk_list [lappend bus_clk_list $clk_freq]
                                                }
                                                set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                                set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                                -d ${dts_file} -p ${bus_node}]
                                                set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                                set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                                add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                                add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                                add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                                        }
                        }
                        append clocknames " " "$mrclk"
                        set is_pl_clk 0
                        set is_clk_wiz 0
                        set axi 0
                }
        } else {
                set valid_clk_list "clk_out0 clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 clk_out8 clk_out9"
                set pl_clk ""
                set clkout ""
                foreach pin $pins {
                        if {[lsearch $valid_clk_list $pin] >= 0} {
                                set clkout $pin
                                set is_clk_wiz 1
                                set periph [hsi::get_cells -of_objects $pin]
                        }
                }
                if {[llength $clkout]} {
                        set number [regexp -all -inline -- {[0-9]+} $clkout]
                        set clk_wiz [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                        set axi_clk "s_axi_aclk"
                        foreach clk1 $clk_wiz {
                                if {[regexp $axi_clk $clk1 match]} {
                                        set axi 1
                                }
                        }
                        if {[string match -nocase $axi "0"]} {
                                dtg_warning "no s_axi_aclk for clockwizard"
                                set pins [hsi::get_pins -of_objects [hsi::get_cells -hier $periph] -filter TYPE==clk]
                                set clk_list "pl_clk*"
                                set clk_pl ""
                                set num ""
                                foreach clk_wiz_pin $pins {
                                        set clk_wiz_pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects $clk_wiz_pin]]
                                        foreach pin $clk_wiz_pins {
                                                if {[regexp $clk_list $pin match]} {
                                                        set clk_pl $pin
                                                }
                                        }
                                }
                                if {[llength $clk_pl]} {
                                        set num [regexp -all -inline -- {[0-9]+} $clk_pl]
                                }
                                set dts_file "pl.dtsi"
                                set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                                set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                                if {[llength $clk_freq] == 0} {
                                        dtg_warning "clock frequency for the $clk is NULL"
                                        continue
                                }
                                set clk_freq [expr int $dts_file($clk_freq)]
                                set iptype [get_ip_property $drv_handle IP_NAME]
                                if {![string equal $clk_freq ""]} {
                                        if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                                set bus_clk_list [lappend bus_clk_list $clk_freq]
                                        }
                                        set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                        set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                        -d ${dts_file} -p ${bus_node}]
                                        set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                        set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                        add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                        add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                        add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                                }
                        }
                        if {![string match -nocase $axi "0"]} {
                                switch $number {
                                        "1" {
                                                set peri "$periph 0"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "2" {
                                                set peri "$periph 1"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "3" {
                                                set peri "$periph 2"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "4" {
                                                set peri "$periph 3"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "5" {
                                                set peri "$periph 4"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "6" {
                                                set peri "$periph 5"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                        "7" {
                                                set peri "$periph 6"
                                                set clocks [lappend clocks $peri]
                                                set updat [lappend updat $peri]
                                        }
                                }
                        }
                }
                if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
                        set clklist "pl_clk0 pl_clk1 pl_clk2 pl_clk3"
                } elseif {[string match -nocase $proctype "ps7_cortexa9"]} {
                        set clklist "FCLK_CLK0 FCLK_CLK1 FCLK_CLK2 FCLK_CLK3"
                }
                foreach pin $pins {
                        if {[lsearch $clklist $pin] >= 0} {
                                set pl_clk $pin
                                set is_pl_clk 1
                        }
                }
                if {[string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
                        switch $pl_clk {
                                "pl_clk0" {
                                                set pl_clk0 "versal_clk 65"
                                                set clocks [lappend clocks $pl_clk0]
                                                set updat  [lappend updat $pl_clk0]
                                }
                                "pl_clk1" {
                                                set pl_clk1 "versal_clk 66"
                                                set clocks [lappend clocks $pl_clk1]
                                                set updat  [lappend updat $pl_clk1]
                                }
                                "pl_clk2" {
                                                set pl_clk2 "versal_clk 67"
                                                set clocks [lappend clocks $pl_clk2]
                                                set updat [lappend updat $pl_clk2]
                                }
                                "pl_clk3" {
                                                set pl_clk3 "versal_clk 68"
                                                set clocks [lappend clocks $pl_clk3]
                                                set updat [lappend updat $pl_clk3]
                                }
                                default {
                                                dtg_warning "not supported pl_clk:$pl_clk"
                                }
                        }
                }
                if {[string match -nocase $proctype "psu_cortexa53"]} {
                        switch $pl_clk {
                                "pl_clk0" {
                                                set pl_clk0 "zynqmp_clk 71"
                                                set clocks [lappend clocks $pl_clk0]
                                                set updat  [lappend updat $pl_clk0]
                                }
                                "pl_clk1" {
                                                set pl_clk1 "zynqmp_clk 72"
                                                set clocks [lappend clocks $pl_clk1]
                                                set updat  [lappend updat $pl_clk1]
                                }
                                "pl_clk2" {
                                                set pl_clk2 "zynqmp_clk 73"
                                                set clocks [lappend clocks $pl_clk2]
                                                set updat [lappend updat $pl_clk2]
                                }
                                "pl_clk3" {
                                                set pl_clk3 "zynqmp_clk 74"
                                                set clocks [lappend clocks $pl_clk3]
                                                set updat [lappend updat $pl_clk3]
                                }
                                default {
                                                dtg_warning "not supported pl_clk:$pl_clk"
                                }
                        }
                }
                if {[string match -nocase $proctype "ps7_cortexa9"]} {
                        switch $pl_clk {
                                "FCLK_CLK0" {
                                                set pl_clk0 "clkc 15"
                                                set clocks [lappend clocks $pl_clk0]
                                                set updat  [lappend updat $pl_clk0]
                                }
                                "FCLK_CLK1" {
                                                set pl_clk1 "clkc 16"
                                                set clocks [lappend clocks $pl_clk1]
                                                set updat  [lappend updat $pl_clk1]
                                }
                                "FCLK_CLK2" {
                                                set pl_clk2 "clkc 17"
                                                set clocks [lappend clocks $pl_clk2]
                                                set updat [lappend updat $pl_clk2]
                                }
                                "FCLK_CLK3" {
                                                set pl_clk3 "clkc 18"
                                                set clocks [lappend clocks $pl_clk3]
                                                set updat [lappend updat $pl_clk3]
                                }
                                default {
                                                dtg_warning "not supported pl_clk:$pl_clk"
                                }
                        }
                }
                if {[string match -nocase $is_clk_wiz "0"]&& [string match -nocase $is_pl_clk "0"]} {
                        set dts_file "pl.dtsi"
                        set bus_node [add_or_get_bus_node $drv_handle $dts_file]
                        set clk_freq [mrmac_get_clk_frequency [hsi::get_cells -hier $drv_handle] "$clk"]
                        if {[llength $clk_freq] == 0} {
                                dtg_warning "clock frequency for the $clk is NULL"
                                continue
                        }
                        set clk_freq [expr int $dts_file($clk_freq)]
                        set iptype [get_ip_property $drv_handle IP_NAME]
                        if {![string equal $clk_freq ""]} {
                                if {[lsearch $bus_clk_list $clk_freq] < 0} {
                                        set bus_clk_list [lappend bus_clk_list $clk_freq]
                                }
                                set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                                set misc_clk_node [create_node -n "misc_clk_${bus_clk_cnt}" -l "misc_clk_${bus_clk_cnt}" \
                                -d ${dts_file} -p ${bus_node}]
                                set clk_refs [lappend clk_refs misc_clk_${bus_clk_cnt}]
                                set updat [lappend updat misc_clk_${bus_clk_cnt}]
                                add_prop "${misc_clk_node}" "compatible" "fixed-clock" stringlist $dts_file
                                add_prop "${misc_clk_node}" "#clock-cells" 0 int $dts_file
                                add_prop "${misc_clk_node}" "clock-frequency" $clk_freq int $dts_file
                        }
                }
                append clocknames " " "$clk"
                set is_pl_clk 0
                set is_clk_wiz 0
                set axi 0
        }
        }
        set node [get_node $drv_handle]
        set_drv_prop_if_empty $drv_handle "zclock-names1" $clocknames $node stringlist
        set ip [get_ip_property $drv_handle IP_NAME]
        set len [llength $updat]
        switch $len {
                "1" {
                        set refs [lindex $updat 0]
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "2" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "3" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "4" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "5" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "6" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "7" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "8" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "9" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "10" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "11" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "12" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "13" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "14" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "15" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "16" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "17" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "18" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "19" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "20" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "21" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "22" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "23" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "24" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "25" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "26" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "27" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "28" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]>,<&[lindex $updat 27]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "29" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]>,<&[lindex $updat 27]>, <&[lindex $updat 28]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
                "30" {
                        set refs [lindex $updat 0]
                        append refs ">, <&[lindex $updat 1]>, <&[lindex $updat 2]>, <&[lindex $updat 3]>, <&[lindex $updat 4]>, <&[lindex $updat 5]>, <&[lindex $updat 6]>, <&[lindex $updat 7]>, <&[lindex $updat 8]>, <&[lindex $updat 9]>, <&[lindex $updat 10]>, <&[lindex $updat 11]>, <&[lindex $updat 12]>, <&[lindex $updat 13]>, <&[lindex $updat 14]>, <&[lindex $updat 15]>, <&[lindex $updat 16]>, <&[lindex $updat 17]>, <&[lindex $updat 18]>, <&[lindex $updat 19]>, <&[lindex $updat 20]>, <&[lindex $updat 21]>, <&[lindex $updat 22]>, <&[lindex $updat 23]>, <&[lindex $updat 24]>, <&[lindex $updat 25]>, <&[lindex $updat 26]>,<&[lindex $updat 27]>, <&[lindex $updat 28]>, <&[lindex $updat 29]"
                        set_drv_prop $drv_handle "zclocks1" "$refs" $node reference
                }
        }
    }

    proc mrmac_get_clk_frequency {ip_handle portname} {
        set clk ""
        set clkhandle [hsi::get_pins -of_objects $ip_handle $portname]
        set width [get_port_width $clkhandle]
        if {[string compare -nocase $clkhandle ""] != 0} {
                if {$width >= 2} {
                        set clk [hsi get_property CLK_FREQ $clkhandle ]
                        regsub -all ":" $clk { } clk
                        set clklen [llength $clk]
                        if {$clklen > 1} {
                                set clk [lindex $clk 0]
                        }
                } else {
                        set clk [hsi get_property CLK_FREQ $clkhandle ]
                }
        }
        return $clk
    }


