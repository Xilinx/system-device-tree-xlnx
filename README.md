# Table of contents

- [Overview](#Overview)
- [Requirements](#Requirements)
- [Supported devices](<#Supported devices">)
- [Usage](#Usage)
- [Output of SDTGen](#output-of-sdtgen)
- [Tutorial](#tutorial)
  - [sdtgen as a binary](#sdtgen-as-a-binary)
  - [sdtgen as a TCL shell](#sdtgen-as-a-tcl-shell)
- [Background/History](#Background/History)

# Overview

SDTGen is a tool that implements a TCL interface to generate [System
Device
Trees](https://github.com/devicetree-org/lopper/blob/master/specification/source/chapter1-introduction.rst)
for AMD&trade; FPGAs using an XSA file as input.

# Requirements

This tool requires that you have access to [AMD Vivado&trade;  Design
Suite](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html)
or [AMD Vitis&trade; Unified Software
Platform](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vitis.html)

# Supported devices

System Device Tree Generator (SDTGen) currently only supports AMD&trade;
SoCs and designs based on ARM&trade; processors. Support for AMD
MicroBlaze&trade; Processors and AMD MicroBlaze&trade; V Processors is
limited and will not provide Linux&reg; device trees. 

# Usage

## Command line arguments available with SDTGen
Takes the user inputs as command line arguments and generates the System Device Tree (SDT) files in the specified output directory.
* Mandatory arguments: 
  * `-xsa` : Sets the XSA path for which SDT has to be generated. 
  * `-dir` : Sets the output directory where the SDT is to be generated.
* Optional arguments:
  * `-board_dts` : Includes the static AMD&trade; development board
  	specific DTSI file available at `<this
  	repo>/device_tree/data/kernel_dtsi/<release>/<board>` inside the
  	final SDT
  * `-user_dts` : Includes a user defined custom `.dtsi` file inside the
  	final SDT 
	* Can be used to workaround when SDTGen tool is generating
  	incorrect data, can be used to override the existing data in the
  	final SDT, or add a custom board `.dtsi` file.
  * `-trace` : Enables traces of the procs called to generate the SDT
  * `-debug` : Enables the warning prints wherever mentioned in the
  	TCL scripts 
  	* Helpful in getting more info on what might go missing
  	in the final SDT even though the SDT generation is successful.
  * `-zocl` : Add zocl nodes for extended interrupts usecase
    (enable/disable, default: disable)
  * `-rm_xsa` : Pass partial hw design files for dfx use cases
    (can take multiple .xsa files as input)
  * `-domain` : Generate PMC domain specific device tree
    (only valid input: pmc)
  * `-h|--help` : Prints the usage of the command line arguments.
  * `-eval` : Evaluate the given command string. This can be used to
    run SDTGen in interactive mode or run a TCL script file.
    * For more details, see [sdtgen as a TCL
    shell](#sdtgen-as-a-tcl-shell).

Refer to the [Tutorial](#tutorial) section for more details on how to use the command line arguments.

## How to use custom system device tree repository path with SDTGen
### Usage of CUSTOM_SDT_REPO:
 By default SDTGen will run from the installed tool under <i>&lt;Installed
 Vitis Path&gt;</i>/data/system-device-tree-xlnx or <i>&lt;Installed
 Vivado Path&gt;</i>/data/system-device-tree-xlnx. If you want to use
 the local SDT repo instead of the installed one, use the environment
 variable `CUSTOM_SDT_REPO`.

```bash
# Say the local SDT repo is kept at /home/abc/local_sdt_repo/system-device-tree-xlnx
# Set the environment variable CUSTOM_SDT_REPO to the above local path to use TCL sources from this local path.
# In BASH, it can be done using export command.
# e.g.
export CUSTOM_SDT_REPO=/home/abc/local_sdt_repo/system-device-tree-xlnx

# Call sdtgen command
/home/abc/Xilinx/2025.2/Vitis/bin/sdtgen -xsa design1_wrapper.xsa -dir sdt_outdir

# This will lead to prints like below while launching SDTGen which ensures that these local tcls are being sourced
# Info: Detected Custom SDT repo path at /home/abc/local_sdt_repo/system-device-tree-xlnx Verifying...
# Successfully sourced custom SDT Repo path.
```

# Output of SDTGen

SDTGen outputs both hardware configuration information in the form of
System Device Trees, but also binary files containing "firmware"
(initial bootloaders, hardware configuration files) for the device.

## System Device Tree files.

The generated system device tree contains following files.
* Files that are static for a given device family:	
  * soc.dtsi: A SOC specific file containing information about the CPU . e.x.: versal.dtsi
  * board.dtsi: A board file copied from AMD&trade;'s prebuilt board repository. e.x.: versal-vck190-reva
  * clk.dtsi: Clock information for the device. e.x.: versal-clk.dtsi
* Files dynamically generated based on AMD Vivado&trade; Design Suite output: 
  * pl.dtsi: Contains Programmable Logic(soft IPs) information.
  * system-top.dts: System information about memory, CPU clusters, aliases etc.
  * pcw.dtsi: Information about the configuration of the processing system from the AMD Vivado&trade;  Design Suite peripheral configuration wizard. 

## Binary files
Apart from the `.dtsi` files and `system-top.dts`, the SDTGen output directory also contains some files that are needed to configure the hardware. These files are available within XSA and are extracted and placed into the output directory.

For different platforms, extracted files are:
* Microblaze / Microblaze RISCV: - bitstream (.bit)
* Zynq:
     - ps7_inits (.c, .h, .tcl etc)
     - bitstream(.bit)
* ZynqMP:
     - psu_inits (.c, .h, .tcl etc)
     - bitstream(.bit)
* Versal:
     - PDI (.pdi)
     - A folder named "extracted" that contains:
     	- ELFs like plm, psm
     	- CDOs like lpd, fpd, pmc_data etc.
     	- bif file that can re-construct the PDI using above artifacts

# Tutorial

The following shows how to use SDTGen to create a System Device Tree from a `.xsa` file.

1. Determine the path of SDTGen binary path from the installed Vitis tool

	For example
	```
	/home/abc/Xilinx/2025.2/Vitis/bin/sdtgen
	```

2. Run Below command
	```
	sdtgen -xsa system.xsa -dir sdt_outdir
	```

Note: sdtgen binary can be used in two ways as described below:
- [sdtgen as a binary](#sdtgen-as-a-binary)
- [sdtgen as a TCL shell](#sdtgen-as-a-tcl-shell)

### sdtgen as a binary
#### Basic usage:
```bash
sdtgen -xsa system.xsa -dir sdt_outdir
sdtgen -xsa system.xsa -dir sdt_outdir -board_dts zcu102-rev1.0
```

#### PMC domain specific device tree:
```bash
sdtgen -xsa system.xsa -dir sdt_outdir -domain pmc
```

#### Advanced usage with multiple options:
```bash
sdtgen -xsa system.xsa -dir sdt_outdir -board_dts zcu102-rev1.0 -user_dts ./user1.dtsi ./user2.dtsi -trace enable -debug enable
```

#### DFX (Dynamic Function eXchange) use cases:
```bash
sdtgen -xsa full.xsa -dir dfx_dts -rm_xsa rp0_rm0.xsa -rm_xsa rp0_rm1.xsa
```

### sdtgen as a TCL shell:
#### Interactive mode:
```bash
sdtgen -eval "set_dt_param -xsa system.xsa -dir sdt_outdir -board_dts zcu102-rev1.0; generate_sdt"
sdtgen -eval "hsi::open_hw_design system.xsa; puts [hsi::get_cells -hier -filter IP_TYPE==PROCESSOR]"
```

#### TCL file mode:
```bash
sdtgen sdt.tcl system.xsa sdt_outdir
```

Where `sdt.tcl` contains:
```tcl
set outdir [lindex $argv 1]
set xsa [lindex $argv 0]
exec rm -rf $outdir
set_dt_param -xsa $xsa -dir $outdir -board_dts zcu102-rev1.0 -user_dts /home/abc/xyz.dtsi
generate_sdt
```

For more details on the available commands inside the interactive shell, please refer to the [Example](#example) section below.

# Background/History
## Device Tree (DT)
A [device
tree](https://www.kernel.org/doc/html/latest/devicetree/usage-model.html#linux-and-the-devicetree
) is a data structure and language for describing hardware. It is a
description of hardware that is readable by an operating system so that
the operating system doesn't need to hard code details of the machine.

## System Device Tree (SDT)
The System Device Tree is a superset of a traditional Linux-compatible
devicetree intended to support more complex software including
hypervisors and RTOSs. System Device Tree is architected to be
compatible with traditional device-tree files and acts as a superset
extension of the original syntax. In general, the System Device Tree
represents the entirety of the system, including components not
historically relevant to an individual operating system, in contrast the
regular Linux device tree represents hardware information that is only
needed for Linux/APU.

System Device Tree uses the same syntax as traditional Device Tree. 

For example, a System Device Tree can include information about the CPU
cluster and memory associated with the Cortex-R CPU cluster in a device
such as AMD Zynq&trade; UltraScale+&trade; MPSoC in addition to the
Cortex-A cluster available in traditional Device Tree.

 System Device Trees are intended to be parsed with a tool like
[Lopper](https://github.com/devicetree-org/lopper/tree/master) to allow
complex inter-software architectures to be specified in simple
configuration files. More details on the System Device Tree spec can be
found inside [devicetree-org lopper
repository](https://github.com/devicetree-org/lopper/tree/master/specification/source).

## Hardware Software Interface (HSI)
An AMD-Xilinx proprietary TCL based utility that can extract the
hardware specific data from the XSA (Xilinx Support Archive) file into a
human readable format. The extracted hardware meta-data can then be
passed on to the software world. HSI is provided by AMD Vivado&trade;
Design Suite or AMD Vitis&trade; Unified Software Platform.

More info on how to use HSI commands can be found at:

[Extracting HW info using
HSI](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841693/HSI+debugging+and+optimization+techniques#HSIdebuggingandoptimizationtechniques-ExtractingHWinfousingHSIfromtheXSCTcommandline:)
and [Internal HSI
utilities](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841693/HSI+debugging+and+optimization+techniques#HSIdebuggingandoptimizationtechniques-InternalHSIutilities:)


## SDTGen
SDTGen (this tool) is a tool that uses TCL scripts and Hardware HSI APIs
to read the hardware information from XSA and put it in System Device
Tree (SDT) format. The TCL source files for the tool is kept in present
repository and the same can be found in the install directory for AMD
Vitis&trade; Unified Software Platform or AMD Vivado&trade;  Design
Suite. 

SDTGen exports the following three procs from system device tree repository
into its interactive environment:

* set_dt_param
* get_dt_param
* generate_sdt

### set_dt_param
#### Example
```bash
# Note that the Multiple parameter setting in one line is allowed for all the available arguments of set_dt_param.

# Set the mandatory set_dt_param arguments.
sdtgen% set_dt_param -dir outdir
sdtgen% set_dt_param -xsa design_1_wrapper.xsa

# Multiple options in a single command
sdtgen% set_dt_param -xsa system.xsa -dir sdt_outdir

# Sample optional arguments with set_dt_param

# Include board specific dtsi file from <SDT repo>/device_tree/data/kernel_dtsi/2025.2/BOARD path
# Below command copies the <SDT repo>/device_tree/data/kernel_dtsi/2025.2/BOARD/zcu102-rev1.0.dtsi file
# into SDT output directory and add include statement in system-top.dts
sdtgen% set_dt_param -board_dts zcu102-rev1.0

# Include a user defined custom dtsi file inside the final SDT
# Below command copies the custom.dtsi file into SDT output directory and add include statement in system-top.dts
sdtgen% set_dt_param -user_dts <path>/custom.dtsi

# Enable the trace i.e. the flow of TCL procs that are getting invoked during SDT generation. The default trace option is "disable".
sdtgen% set_dt_param -trace enable

# Enable the debug option to get warning prints. The default debug option is "disable".
sdtgen% set_dt_param -debug enable

# Enable zocl nodes for extended interrupts usecase. The default zocl option is "disable".
sdtgen% set_dt_param -zocl enable

# Pass partial hw design files for dfx use cases
sdtgen% set_dt_param -rm_xsa rp0_rm0.xsa -rm_xsa rp0_rm1.xsa

# Generate PMC domain specific device tree
sdtgen% set_dt_param -domain pmc

# Command Help
sdtgen% set_dt_param -help
            Usage: set/get_dt_param \[OPTION\]
            -xsa              Vivado hw design file
            -board_dts        board specific file
            -dir              Directory where the dt files will be generated
            -user_dts         DTS file to be include into final device tree
            -debug            Enable DTG++ debug
            -trace            Enable DTG++ traces
            -zocl             add zocl nodes for extended interrupts usecase
            -rm_xsa           pass partial hw design files for dfx use cases
            -domain           generate PMC domain specific device tree

# Combining everything in one command
sdtgen% set_dt_param -xsa system.xsa -dir sdt_outdir -board_dts zcu102-rev1.0 -user_dts ./custom.dtsi -trace enable -debug enable -zocl enable -domain pmc
```
### get_dt_param
Returns the values set for the given argument. Returns the default
values if the argument has not been set using the "set_dt_param".
#### Example
```bash
# Unlike set_dt_param, get_dt_param expects only one argument in one command.

sdtgen% get_dt_param -help
            Usage: set/get_dt_param \[OPTION\]
            -repo             system device tree repo source
            -xsa              Vivado hw design file
            -board_dts        board specific file
            -dir              Directory where the dt files will be generated
            -user_dts         DTS file to be include into final device tree
            -debug            Enable DTG++ debug
            -trace            Enable DTG++ traces
            -zocl             add zocl nodes for extended interrupts usecase
            -rm_xsa           pass partial hw design files for dfx use cases
            -domain           generate PMC domain specific device tree


sdtgen% get_dt_param -board_dts
zcu102-rev1.0
sdtgen% get_dt_param -dir
sdt_outdir
sdtgen% get_dt_param -xsa
system.xsa
sdtgen% get_dt_param -repo
/home/abc/Xilinx/2025.2/Vitis/data/system-device-tree-xlnx
```
### generate_sdt
Generates the system device tree with the set parameters. Usage:
```bash
sdtgen% generate_sdt
```
