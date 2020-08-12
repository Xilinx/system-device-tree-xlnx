package require Tcl 8.5.14
package require yaml
#****************************************************************
# check if file exists
#****************************************************************
proc check_file { file_name } {
    set file_content ""
    if { [ file exists  $file_name ] } {
        set fp [open $file_name r]
        set file_content [read $fp]
        close $fp
    } else {
        lib_error YAML "Cannot open filename $file_name..."
    }
    return $file_content
}

#****************************************************************
# load yaml file into dict
#****************************************************************
proc get_yaml_dict { config_file } {
	set data ""
	if {[file exists $config_file]} {
		set fd [open $config_file r]
		set data [read $fd]
		close $fd
	} else {
		error "YAML:: No such file $config_file"
	}
    return [yaml::yaml2dict $data]
}

#****************************************************************
# set global dict_prj
#****************************************************************
set dict_devicetree  {}

set config_file "config.yaml"

set cfg [get_yaml_dict $config_file]
set dict_devicetree [dict get $cfg dict_devicetree]
set user [dict get $dict_devicetree dict_user]
set path [dict get $user repo_path]
set overlay [dict get $user dt_overlay]
set config_dts [dict get $user prj_config_dts]
