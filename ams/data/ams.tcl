    proc ams_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
        if {[string match -nocase $mainline_ker "none"]} {
          set ams_list "ams_ps ams_pl"
        set family [hsi get_property FAMILY [hsi::current_hw_design]]
        set dts [set_drv_def_dts $drv_handle]
        if {[string match -nocase $family "versal"]} {
        } elseif {[is_zynqmp_platform $family]} {
        }
          foreach ams_name ${ams_list} {
                set node [create_node -n "&${ams_name}" -p root -d "pcw.dtsi"]
                add_prop $node "status" "okay" string "pcw.dtsi"
          }
        }
    }


