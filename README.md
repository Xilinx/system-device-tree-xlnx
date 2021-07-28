# System Device Tree Generator

System Device Tree Generator aka DTG++. System device tree represents
complete hw information in the form of device trees.

DTG++ uses tcls and HW HSI APIs in order to read the hardware
information from XSA. The output dts represents all peripheral information
and its properties, memories, clusters, soc peripheral information and soft
IP information etc. It complies with system device tree specification.

## Input

Vivado generated XSA.

## Output
System Device Tree files.
```bash
The generated dts has the following files.
	soc.dtsi:	which is static soc specific file.
			Ex: versal.dtsi
	pl.dtsi:	which contains Programmable Logic(soft IPs) information.
	board.dtsi:	which is board file.
			Ex: versal-vck190-reva
	clk.dtsi:	which is clock information.
			Ex: versal-clk.dtsi
	system-top.dts:	which is top level system information which
			contains memory, clusters, aliases etc.
	pcw.dtsi:	which contains peripheral configuration wizard information
			of the peripherals.
```
## DTS generation
			
```bash
Repository setup
----------------
	linux# git clone https://gitenterprise.xilinx.com/decoupling/system-device-tree-xlnx.git

	Change the directory to the cloned tree system-device-tree.
	linux# cd system-device-tree-xlnx

Vivado Setup:
-------------
	Setup the Vivado tool and launch the Vivado in tcl mode
	linux# vivado -mode tcl

SDT Command:
------------
	Vivado% source -notrace device_tree/data/device_tree.tcl
	Vivado% set_dt_param --board_dts <board file> --dir <directory name>
		--xsa <Vivado XSA file>
	Ex:
	Vivado% set_dt_param --board_dts versal-vck190-reva --dir sdt
		--xsa design_1_wrapper.xsa
	Vivado% generate_sdt
	Vivado% ls sdt/
```

## Optional command line arguments
### Dt parameter setting:
Setting the dt parameters individually instead of
Single line command mentioned above DTS generation, it is useful if
we want to change only one parameter.
```bash
Vivado% set_dt_param --dir output_dts
Vivado% set_dt_param --xsa design_1_wrapper.xsa
Vivado% set_dt_param --board_dts versal-vck190-reva
```

### Enabling the debug:
The below command enables the debug, like warnings.
The default debug option is disabled, so there won't be any warnings
```bash
Vivado% set_dt_param --debug enable
```

### Enabling the trace:
The below command enables the tracing.
i.e. The flow of tcl procs that are getting invoked during sdt generation
The default trace option is disabled
```bash
Vivado% set_dt_param --trace enable
```
 
### Checking the dt parameters:
```bash
Vivado% get_dt_param --board_dts
versal-vck190-reva
Vivado% get_dt_param --dir
output_dts
Vivado% get_dt_param --xsa
design_1_wrapper.xsa
``` 

### Command Help:
```bash
Vivado% set_dt_param --help
Usage: set/get_dt_param [OPTION]
	--repo                  system device tree repo source
	--xsa                   Vivado hw design file
	--board_dts             board specific file
	--mainline_kernel       mainline kernel version
	--kernel_ver            kernel version
	--dir                   Directory where the dt files will be
				generated
	--debug                 Enable DTG++ debug
	--trace                 Enable DTG++ traces
Vivado% get_dt_param --help
Usage: set/get_dt_param [OPTION]
	--repo                  system device tree repo source
	--xsa                   Vivado hw design file
	--board_dts             board specific file
	--mainline_kernel       mainline kernel version
	--kernel_ver            kernel version
	--dir                   Directory where the dt files will be
				generated
	--debug                 Enable DTG++ debug
	--trace                 Enable DTG++ traces
``` 
### Notes
1. Support added for Versal and ZynqMP.
2. Clock files, SOC file, BOARD files are static files which resides
   inside the DTG++.
3. DTG++ generates all peripherals and its properties except for the
   peripherals of type BUS, MONITOR and interconnects, noc_nmu,
   noc_nsu, zynq_ultra_ps, versal_cips, noc_nsw axis_ila and ila.