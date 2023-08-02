    proc ipipsu_generate {drv_handle} {
        set ipi_list [hsi get_cells -hier -filter {IP_NAME == "psu_ipi" || IP_NAME == "psv_ipi" || IP_NAME == "psx_ipi"}]
        set node [get_node $drv_handle]
        add_prop $node "xlnx,ipi-target-count" [llength $ipi_list] int "pcw.dtsi"
    }