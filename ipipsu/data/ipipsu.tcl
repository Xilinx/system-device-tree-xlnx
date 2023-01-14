    proc ipipsu_generate {drv_handle} {
        if {0} {
        #foreach i [get_sw_cores device_tree] {
        #set common_tcl_file "[hsi get_property "REPOSITORY" $i]/data/common_proc.tcl"
        #if {[file exists $common_tcl_file]} {
        #    source $common_tcl_file
        #    break
        #}
        #}
        set proc_type [get_sw_proc_prop IP_NAME]
        if {[string match -nocase $proc_type "psv_pmc"]} {
        set cpumap [hsi get_property CONFIG.C_CPU_NAME [get_cells -hier $drv_handle]]
        if {![string match -nocase $cpumap "PMC"]} {
            return
        }
        }
        if {[string match -nocase $proc_type "psv_cortexa72"] } {
        set cpumap [hsi get_property CONFIG.C_CPU_NAME [get_cells -hier $drv_handle]]
        if {![string match -nocase $cpumap "A72"]} {
            return
        }
        } 
        if {[string match -nocase $proc_type "psv_cortexr5"] } {
        set cpumap [hsi get_property CONFIG.C_CPU_NAME [get_cells -hier $drv_handle]]
        if {![string match -nocase $cpumap "R5_0"] || ![string match -nocase $cpumap "R5_1"]} {
            return
        }
        } else {
        set default_dts [hsi get_property CONFIG.pcw_dts [get_os]]
        set node [add_or_get_dt_node -n "&$drv_handle" -d $default_dts]
        add_new_dts_param "$node" "status" "okay" string
        }
    }
    }


