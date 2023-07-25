proc sysmon_generate {drv_handle} {
        set dts_file [set_drv_def_dts $drv_handle]
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        add_prop $node "xlnx,ip-type" 1 hexint $dts_file
}