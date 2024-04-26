# System Device Tree Generator (SDTGen / DTG++)

A TCL package that can generate System Device Tree.
More info on the evolution can be read in following segments.

## Device Tree (DT)
A device tree is a data structure and language for describing hardware. It is a description
of hardware that is readable by an operating system so that the operating system doesn't
need to hard code details of the machine.
Info courtesy: https://www.kernel.org/doc/html/latest/devicetree/usage-model.html#linux-and-the-devicetree

## System Device Tree (SDT)
The System Device Tree is a superset of a traditional Linux-compatible devicetree.
An overview of System Device Tree concept can be found on the Linaro site [here](https://static.linaro.org/connect/lvc20/presentations/LVC20-314-0.pdf).
System Device Tree is architected to be compatible with traditional device-tree files and acts as a superset extension of the original syntax.
In general, System Device Tree represents the entirety of the system, including components not historically relevant to an operating system.
Unlike regular Linux device tree which represents hardware information that is only needed for
Linux/APU, System Device Tree represents complete hardware information in device tree format.
For example, System Device Tree can carry information about the CPU cluster and memory associated with the Cortex-R CPU cluster in a device such as Zynq UltraScale+ MPSoC. While this information isn't needed for Linux to operate properly it can be used in the context of the Lopper tool (refer [link](https://static.linaro.org/connect/lvc20/presentations/LVC20-314-0.pdf)) to allow complex inter-software architectures to be specified in simple configuration files.
More details on the System Device Tree spec can be found inside devicetree-org lopper repository [here](https://github.com/devicetree-org/lopper/tree/master/specification/source).

## Hardware Software Interface (HSI)
An AMD-Xilinx proprietary TCL based utility that can extract the hardware specific data from
the XSA (Xilinx Support Archive) file into a human readable format. The extracted hardware
meta-data can then be passed on to the software world.

## XSCT
XSCT (Xilinx Software Command-Line) is a tool that allows us to create complete Xilinx SDK
workspaces using the batch mode, investigate the hardware and software, debug and run the
project, all from the command line. It is capable of running TCL scripts. It is an ‘umbrella’
tool that covers; HSI, XSDB, SDTGen, Bootgen, and the debugger. More info on how to use HSI
from XSCT command line can be found from these sections at:
[Extracting HW info using HSI from the XSCT command line](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841693/HSI+debugging+and+optimization+techniques#HSIdebuggingandoptimizationtechniques-ExtractingHWinfousingHSIfromtheXSCTcommandline:) and [Internal HSI utilities](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841693/HSI+debugging+and+optimization+techniques#HSIdebuggingandoptimizationtechniques-InternalHSIutilities:).
More details on XSCT tool can be accessed at [UG-1208](https://usermanual.wiki/Document/ug1208xsctreferenceguide.1558655150/view).

## SDTGen (DTG++)
An XSCT package that uses TCL scripts and Hardware HSI APIs to read the hardware information
from XSA and put it in System Device Tree (SDT) format. The TCL source files for this
package is kept in present repository and the same can be found in the installed xsct tool. Let's call this path the SDT repo from here on. Sample SDT repo location inside Vitis install may look like /home/abc/Xilinx/Vitis/2024.1/data/system-device-tree-xlnx. By default, the package sources the device_tree.tcl file from
&lt;SDT repo&gt;/device_tree/data/device_tree.tcl and exports the following three procs as sdtgen commands:
* set_dt_param
* get_dt_param
* generate_sdt

## Input for SDTGen

Vivado generated XSA.

## Output of SDTGen
System Device Tree files.
```bash
The generated system device tree contains following files.
	soc.dtsi:	which is a static SOC specific file.
			e.g.: versal.dtsi
	pl.dtsi:	which contains Programmable Logic(soft IPs) information.
	board.dtsi:	which is Board file.
			Ex: versal-vck190-reva
	clk.dtsi:	which is clock information.
			Ex: versal-clk.dtsi
	system-top.dts:	which is top level system information which
			contains memory, clusters, aliases etc.
	pcw.dtsi:	which contains peripheral configuration wizard information
			of the peripherals.
```
##### Note: Clock files, SOC file, BOARD files are static files which resides inside the DTG++.

## Steps to use SDTGen
			
```bash
XSCT Setup:
-------------
        Get the path of XSCT binary from the installed Vitis tool
        (say: /home/abc/Xilinx/Vitis/2024.1/bin/xsct)

Put commands like below in a TCL file (say sdt.tcl)
------------
	set outdir [lindex $argv 1]
	set xsa [lindex $argv 0]
	exec rm -rf $outdir
	sdtgen set_dt_param -xsa $xsa -dir $outdir -board_dts zcu102-rev1.0
	sdtgen generate_sdt
------------

Run XSCT command like below to get the SDT directory
------------
<xsct binary path> sdt.tcl <Vivado generated xsa path> <sdt outdir where files will be generated>
e.g.
/home/abc/Xilinx/Vitis/2024.1/bin/xsct sdt.tcl design1_wrapper.xsa sdt_outdir
```

## Command line arguments available with SDTGen
### set_dt_param
Takes the user inputs to set the parameters needed for the system device tree generation.
* Has two mandatory arguments:
	* -xsa : sets the XSA path for which SDT has to be generated.
	* -dir : sets the output directory where the SDT has to be generated.
* Other available optional arguments are:
	* Category 1: Arguments that help in including dtsi files into final SDT
		* -board_dts :
			* includes the static board specific DTSI file available at
				<SDT repo>/device_tree/data/kernel_dtsi/2024.1/BOARD inside the final SDT
			* Mostly useful for Linux use cases.
		* -include_dts :
			* includes a user defined custom dtsi file inside the final SDT
			* useful in providing customized use case specific data which can not be generated by the SDTGen tool
			* Can be a handy workaround when SDTGen tool is generating a wrong data, can be used to override the existing data in the final SDT
	* Category 2: Arguments that can help in debugging issues while generating SDT (Useful for developers)
		* -trace :
			* enables traces of the procs called to generate the SDT
			* gives the sequence of APIs called, helps in debugging which proc call actually failed
		* -debug :
			* enables the warning prints wherever mentioned in the TCL scripts
			* Helpful in getting more info on what might go missing in the final SDT even though the SDT generation is successful.
			* Less frequently used.
* Usage:
```bash
# Note that the Multiple parameter setting in one line is allowed for all the available arguments of set_dt_param.

# Set the mandatory set_dt_param arguments.
xsct% sdtgen set_dt_param -dir outdir
xsct% sdtgen set_dt_param -xsa design_1_wrapper.xsa

# Multiple options in a single command
xsct% sdtgen set_dt_param -xsa system.xsa -dir sdt_outdir

# Sample optional arguments with set_dt_param

# Category 1: Arguments that help in including dtsi files into final SDT

# Include board specific dtsi file from <SDT repo>/device_tree/data/kernel_dtsi/2024.1/BOARD path
# Below command copies the <SDT repo>/device_tree/data/kernel_dtsi/2024.1/BOARD/zcu102-rev1.0.dtsi file into SDT output directory and add include statement in system-top.dts
xsct% sdtgen set_dt_param -board_dts zcu102-rev1.0

# Include a user defined custom dtsi file inside the final SDT
# Below command copies the custom.dtsi file into SDT output directory and add include statement in system-top.dts
xsct% sdtgen -include_dts <path>/custom.dtsi

# Category 2 : Arguments that can help in debugging issues while generating SDT (Useful for developers)

# Enable the trace i.e. the flow of TCL procs that are getting invoked during SDT generation. The default trace option is "disable".
xsct% sdtgen set_dt_param -trace enable

# Enable the debug option to get warning prints. The default debug option is "disable".
xsct% sdtgen set_dt_param -debug enable

# Command Help
xsct% sdtgen set_dt_param -help
            Usage: set/get_dt_param \[OPTION\]
            -xsa              Vivado hw design file
            -board_dts        board specific file
            -dir              Directory where the dt files will be generated
            -include_dts      DTS file to be include into final device tree
            -debug            Enable DTG++ debug
            -trace            Enable DTG++ traces

# Combining everything in one command
xsct% sdtgen set_dt_param -xsa system.xsa -dir sdt_outdir -board_dts zcu102-rev1.0 -include_dts ./custom.dtsi -trace enable -debug enable
```
### get_dt_param
Returns the values set for the given argument. Returns the default values if the argument is not set using the "sdtgen set_dt_param".
Do mark the usage of -repo. Helpful in finding the path of the system device tree TCLs being used.
* Usage:
```bash
# Unlike "sdtgen set_dt_param", "sdtgen get_dt_param" expects only one argument in one command.

xsct% sdtgen get_dt_param -help
            Usage: set/get_dt_param \[OPTION\]
            -repo             system device tree repo source
            -xsa              Vivado hw design file
            -board_dts        board specific file
            -dir              Directory where the dt files will be generated
            -include_dts      DTS file to be include into final device tree
            -debug            Enable DTG++ debug
            -trace            Enable DTG++ traces


xcst% sdtgen get_dt_param -board_dts
zcu102-rev1.0
xcst% sdtgen get_dt_param -dir
sdt_outdir
xsct% sdtgen get_dt_param -xsa
system.xsa
xsct% sdtgen get_dt_param -repo
/home/abc/Xilinx/Vitis/2024.1/data/system-device-tree-xlnx
```
### generate_sdt
Generates the system device tree with the set parameters.
Usage:
```bash
sdtgen generate_sdt
```

### How to use custom system device tree repository path with SDTGen
#### Usage of CUSTOM_SDT_REPO (New in 2024.1):
 As mentioned in earlier section, by default the TCL source files for sdtgen package is residing in the installed xsct tool under &lt;Installed Vitis Path&gt;/2024.1/data/system-device-tree-xlnx. If user wants to use the local SDT repo instead of the installed one, CUSTOM_SDT_REPO variable has to be set in the environment.

```bash
# Say the local SDT repo is kept at /home/abc/local_sdt_repo/system-device-tree-xlnx
# Set the environment variable CUSTOM_SDT_REPO to the above local path to use TCL sources from this local path.
# In BASH, it can be done using export command.
# e.g.
export CUSTOM_SDT_REPO=/home/abc/local_sdt_repo/system-device-tree-xlnx

# Use the same tcl as generated above (without any change) and call xsct command
/home/abc/Xilinx/Vitis/2024.1/bin/xsct sdt.tcl design1_wrapper.xsa sdt_outdir

# This will lead to prints like below while launching XSCT which ensures that these local tcls are being sourced
# Info: Detected Custom SDT repo path at /home/abc/local_sdt_repo/system-device-tree-xlnx Verifying...
# Successfully sourced custom SDT Repo path.
```
#### Old flow (adopted till 2023.2, deprecated in 2024.1):
##### If there is NO change in the device_tree.tcl file:
* Use -repo option with sdtgen set_dt_param command.
* Usage:
```bash
sdtgen set_dt_param -xsa design1_wrapper.xsa -dir outdir -repo /home/abc/local_sdt_repo/system-device-tree-xlnx
```

##### If there is a change in device_tree.tcl file along with other files:
* When the installed XSCT path is write protected:
	* Copy scripts folder from Vitis installation directory (say: /home/abc/Xilinx/Vitis/2024.1/scripts) to another path (eg./tmp/path/)
	* Set MYVIVADO variable to the copied XSCT scripts path (eg. export MYVIVADO=/tmp/path/)
	* Update the sdt_path variable in sdtgen.tcl kept at the copied XSCT scripts path. sdtgen.tcl can be found inside /tmp/path/scripts/xsct/sdtgen/sdtgen.tcl
* When the installed XSCT path is NOT write protected:
	* Update the sdt_path variable in sdtgen.tcl kept at /home/abc/Xilinx/Vitis/2024.1/scripts/xsct/sdtgen/sdtgen.tcl with local SDT repo path.
* Set the -repo option to the local SDT repo path in conjunction with above steps when other file changes are also involved in addition to device_tree.tcl changes
* Usage:
```bash
# Copy the scripts folder into a local location
mkdir /tmp/path
cp -r /home/abc/Xilinx/Vitis/2024.1/scripts /tmp/path/

# Set the MYVIVADO variable to the copied XSCT scipts path
export MYVIVADO=/tmp/path

# Open the /tmp/path/scripts/xsct/sdtgen/sdtgen.tcl file and update the sdt_path with the local SDT repo path
# eg. set sdt_path $env(XILINX_VITIS) -> set sdt_path /home/abc/local_sdt_repo/system-device-tree-xlnx

# If there are changes in files other than device_tree.tcl
sdtgen set_dt_param -xsa design1_wrapper.xsa -dir outdir -repo /home/abc/local_sdt_repo/system-device-tree-xlnx
```
