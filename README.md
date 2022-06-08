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
XSCT Setup:
-------------
        Launch XSCT tool
        linux# xsct

Once xsct launched, at xsct prompt enter sdtgen commands as hown below for
generating system device tree.
SDT Command:
------------
	xsct% sdtgen set_dt_param -board_dts <board file> -dir <directory name>
		-xsa <Vivado XSA file>
	Ex:
	xsct% sdtgen set_dt_param -board_dts versal-vck190-reva -dir sdt
		-xsa design_1_wrapper.xsa
	xsct% sdtgen generate_sdt
	xsct% ls sdt/
```

## Optional command line arguments
### Dt parameter setting:
Setting the dt parameters individually instead of
Single line command mentioned above DTS generation, it is useful if
we want to change only one parameter.
```bash
xsct% sdtgen set_dt_param -dir output_dts
xsct% sdtgen set_dt_param -xsa design_1_wrapper.xsa
xsct% sdtgen set_dt_param -board_dts versal-vck190-reva
```

### Enabling the debug:
The below command enables the debug, like warnings.
The default debug option is disabled, so there won't be any warnings
```bash
xsct% sdtgen set_dt_param -debug enable
```

### Enabling the trace:
The below command enables the tracing.
i.e. The flow of tcl procs that are getting invoked during sdt generation
The default trace option is disabled
```bash
xsct% sdtgen set_dt_param -trace enable
```
 
### Checking the dt parameters:
```bash
xsct% sdtgen get_dt_param -board_dts
versal-vck190-reva
xsct% sdtgen get_dt_param -dir
output_dts
xsct% sdtgen get_dt_param -xsa
design_1_wrapper.xsa
```

### Copy hw artifacts from xsa
```bash
Copy hardware artifacts from a given xsa to output directory.
USAGE: sdtgen set_dt_param -dir <output directory path> -xsa <xsa file>
       sdtgen copy_hw_files
```

### Using external repo
```bash
Sometimes user may want to modify the system device tree repo locally and use that for testing, insuch scenarios user can specify local repo using -repo option at set_dt_param.
Please note that though the -repo option works for most of the cases where change is not in the core file i.e device_tree/data/device_tree.tcl, it will not work if change that needs to tested is in this file.
In such cases, please follow below steps.
1. Copy scripts/ folder from Vitis installation directory to local directory(ex: /tmp/path/)
2. Set MYVIVADO environment variable with this path (ex: #export MYVIVADO=/tmp/path/)
3. Now open file at /tmp/path/scripts/xsct/sdtgen/sdtgen.tcl and update it to source your own local device_tree.tcl instead of sourcing device_tree.tcl in installation path.
4. Launch xsct now and continue with testing.
```

### Command Help:
```bash
xsct% sdtgen set_dt_param -help
Usage: set/get_dt_param [OPTION]
	-repo                  system device tree repo source
	-xsa                   Vivado hw design file
	-board_dts             board specific file
	-mainline_kernel       mainline kernel version
	-kernel_ver            kernel version
	-dir                   Directory where the dt files will be
	                       generated
	-debug                 Enable DTG++ debug
	-trace                 Enable DTG++ traces
xsct% sdtgen get_dt_param -help
Usage: set/get_dt_param [OPTION]
	-repo                  system device tree repo source
	-xsa                   Vivado hw design file
	-board_dts             board specific file
	-mainline_kernel       mainline kernel version
	-kernel_ver            kernel version
	-dir                   Directory where the dt files will be
	                       generated
	-debug                 Enable DTG++ debug
	-trace                 Enable DTG++ traces
``` 
### Notes
1. Support added for Versal and ZynqMP.
2. Clock files, SOC file, BOARD files are static files which resides
   inside the DTG++.
3. DTG++ generates all peripherals and its properties except for the
   peripherals of type BUS, MONITOR and interconnects, noc_nmu,
   noc_nsu, zynq_ultra_ps, versal_cips, noc_nsw axis_ila and ila.
