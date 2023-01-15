    proc norps_generate {drv_handle} {
      
        # TODO: if addr25 is used, should we consider set the reg size to 64MB?
        # enable reg generation for ps ip
        gen_reg_property $drv_handle "enable_ps_ip"
    }


