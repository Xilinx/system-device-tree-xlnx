    proc gpiops_generate {drv_handle} {
         set count 32
         set dts_file [set_drv_def_dts $drv_handle]
         set node [get_node $drv_handle]
         set ip [hsi::get_cells -hier $drv_handle]
         add_prop $node "emio-gpio-width" [get_ip_param_value $ip C_EMIO_GPIO_WIDTH] hexint $dts_file
         set gpiomask [get_ip_param_value $ip "C_MIO_GPIO_MASK"]

         if {[llength $gpiomask]} {
         set mask [expr {$gpiomask & 0xffffffff}]
         add_prop $node "gpio-mask-low" $mask int $dts_file
         set mask [expr {$gpiomask>>$count}]
         set mask [expr {$mask & 0xffffffff}]
         add_prop $node "gpio-mask-high" "$mask" int $dts_file
         }
    }


