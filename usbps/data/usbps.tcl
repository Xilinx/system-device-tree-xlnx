    proc usbps_generate {drv_handle} {
        ps7_reset_handle $drv_handle CONFIG.C_USB_RESET CONFIG.usb-reset
        set proctype [get_hw_family]
        set node [get_node $drv_handle]
        set default_dts [set_drv_def_dts $drv_handle]
        if {[string match -nocase $proctype "zynq"] } {
        set_drv_prop $drv_handle phy_type ulpi $node string
        } else {
        global env
        set path $env(REPO)

        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]

        if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_cortexr5"] || [string match -nocase $proctype "psv_pmc"]} {
                #TODO:Remove this once the versal dts is fully updated.
                return
        }
        if {[string match -nocase $mainline_ker "none"]} {
             set index [string index $drv_handle end]
             add_prop $node "status" "okay" string $default_dts
        }
        }
    }


