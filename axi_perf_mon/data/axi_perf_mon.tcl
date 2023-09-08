#
# (C) Copyright 2014-2022 Xilinx, Inc.
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

    proc axi_perf_mon_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        pldt append $node compatible "\ \, \"xlnx,axi-perf-monitor\""
        set check_list "enable-profile enable-trace num-monitor-slots enable-event-count enable-event-log have-sampled-metric-cnt num-of-counters metric-count-width metrics-sample-count-width global-count-width metric-count-scale"
        foreach p ${check_list} {
                set ip_conf [string toupper "c_${p}"]
                regsub -all {\-} $ip_conf {_} ip_conf
                set_drv_conf_prop $drv_handle ${ip_conf} xlnx,${p} $node hexint
        }
    }


