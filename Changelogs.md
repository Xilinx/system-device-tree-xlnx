Changes for 2026.1
===============================
- ai_engine:
Part number check update

- ai_layout_formatter_wr:
New driver for AI accelerator layout formatting with RGBA/RGB/NHWC/NCHW format support

- axis_subset_converter:
New driver for AXI4-Stream subset converter with transparent hierarchy handling and MIPI CSI2 RX integration

- axis_switch:
Add debug logging and Improve connection logic with fallback handling for MIPI CSI2 RX

- axi_bram:
Add microblaze_riscv support
Update SRAM compatibility with mmio-sram
Add address cell configuration

- axi_clk_wiz:
Add xlnx,prim-in-freq primary input frequency property

- axi_ethernet:
Add device_type "network" property
Improve interrupt handling with conditional check for existing interrupt properties
Add expanded clock handling for multi-core ethernet configurations
Add EOE (Ethernet Offload Engine) support

- axi_gpio:
Add device_type "gpio" property

- axi_iic:
Add clock frequency acquisition from CONFIG.C_S_AXI_ACLK_FREQ_HZ

- axi_mmi_dc:
Refactored with conditional logic based on operating_mode and presentation_mode

- axi_pcie:
Fix xdma interrupt mapping from 0-based to 1-based indexing

- axi_qspi:
Add bootph-all property for microblaze family

- axi_vcu2:
Add NSU path support to skip interrupts when NSU is enabled

- axi_vdma:
Add label_prefix handling for baseaddr edge cases

- cpm_pcie:
Fix config register value

- cpu:
Add MicroBlaze RISC-V ISA extension support
Refactored cpus node generation into separate cpus container and cpu child nodes

- ddrps:
Add 64_bit_mb support
Update 32-bit format condition for microblaze_riscv platforms

- device_tree:
Version bumped from 2025.2 to 2026.1
Add JSON-based ISS file parsing support
Add 50+ new IP-to-driver mappings for Versal-Net platform
New list_board_files function for pattern-based board file discovery with -list_boards command-line option
Enhanced set_dt_param with -user_dts validation, kernel_dtsi path resolution and marked -board_dts as deprecated starting from 2026.2
New PMC domain device tree generation support
Add peripheral node generation per domain and stdout management for PMC domain

- common_proc:
Add new IP-to-driver mappings for psx_* variants
New is_external_intf procedure for external interface port detection
Refactored write_dt into recursive write_dt_node helper for cleaner DT generation
Add environment variable safety checks for verbose, debug, and trace modes

- xillib_internal:
Replaced get_intc_cascade_id_offset implementation with alias to get_intc_cascade_offset
Removed 40+ deprecated xget_*/xdefine_*/xprint_* wrapper functions

- xillib_common:
Removed deprecated functions: compare_unsigned_addresses, compare_unsigned_int_values, find_file_in_xilinx_install, load_xilinx_library

- xillib_hw:
Add DFX decoupler interrupt support for WIDTH>1 interrupt buses
Add pattern-based interrupt pin filtering for dynamic reconfigurable modules
Removed deprecated get_net_name, get_intfnet_name, and xget_* wrapper functions

- xillib_sw:
~40% reduction in deprecated wrappers
Add DTS support functions
Add versal_net processor support
Removed deprecated xdefine_zynq_*, xdefine_processor_params, and memory banking utilities

- partial_proc:
Refactored RM workspace handling with separate absolute path for each RM
Add Versal NoC DFX bridge detection fallback for RP containers
Improve RP region dict handling and fpga instance resolution

- video_utils:
Add axis_subset_converter handling in video pipeline traversal
Improve ISPPipeline endpoint label and remote-endpoint logic
Enhance axis_switch output endpoint labeling

- emaclite:
Add device_type "network" property

- framebuf_rd:
Add v-frmbuf-rd-v3.0 compatible string
Add 16+ new video codec formats and tile format support

- framebuf_wr:
Add v-frmbuf-wr-v3.0 compatible string
Add new video codec formats and tile format support
Add preprocess_accel support

- hdmi_gt_ctrl:
Add VEK280/VEK385 board detection
Add XFMC node generation and I2C helper nodes
Add GT overrides for VEK boards
Add versal_gen2 DRU properties

- hdmi_phy1:
Add board detection for ZCU102/ZCU106
Add XFMC HDMI FMC node generation
Add I2C client nodes and reference clock support

- intc:
Add cascade mode detection
Add intc-type property for PG099 cascade master/leaf/intermediate modes

- isppipeline:
Fix endpoint label and remote-endpoint reference for direct input connections

- mailbox:
Add AXI-Stream dummy base address generation
Add per-port interrupt splitting for PS GIC vs PL interrupt controllers
Improve NOC address translation filtering

- mipi_csi2_rx_ss:
Update xlnx,en-active-lanes from int to boolean
Add axis_data_fifo and axis_subset_converter transparency support
Add duplicate endpoint guard

- mixer:
Add v-mix-6.0 compatible string
Add tile mode support with xlnx,tile-formats property for layers 1-6
Update video format name XV24 to XVUY

- mrmac:
Add mrmac_aux_mux_gpio procedure
Add managed and phy-mode properties
Add GT aux-mux-gpios support
Update stream connectivity function signature

- mutex:
Update processor mapping to iterate all interface_inst entries
Renamed configure_memmap to map_node_to_processor

- preprocess:
New driver for AI preprocessing accelerator with RGB/BGR to RGBA conversion support

- prc:
Add VSM ID and RM ID properties for all VSMs/RMs

- sdi_rxss:
Update xlnx,dyn-bpc property from int to boolean type

- sdi_txss:
Add xlnx,dyn-bpc boolean property
Add xlnx,bpc property (10 or 12 bits per component)

- tpg:
Add axis_register_slice transparency fix
Add axis_subset_converter endpoint support
Add frmbuf_accel support

- trngpsx:
Add Versal part-specific compatible string

- uartlite:
Add port-number and device_type "serial" properties
Add microblaze_riscv bootph-all support

- uartns:
Add device_type "serial" property

- uartps:
Add device_type "serial" property

- tsn:
Fix PTP timer interrupt routing to prevent mac1 conflicts

- visp_ss:
Refactored RPU/mbox initialization into centralized procedure call
New rpu_info_mbox_create and get_visp_baseaddr procedures
Update mbox compatible from xlnx,mimo-mbox/xlnx,mbox to xlnx,isp-mbox with IPI resolution
Add xlnx,atomic_streamon property to frmbuf_wr nodes

- vproc_ss:
Fix duplicate endpoint node creation under port@0
Refactored subcore address calculation into update_subcore_absolute_addr helper


## New Board Support
- Versal-Net: vn-x-b2197-01
- Versal: vpk360, vr-r-a2488-01
- Versal_gen2: ve-p-a1225-00
- ZynqMP: sc-k24, sc-scu200, sc-ve-p-a1225-00, sc-vek386, sc-vpk360, sck-kd-g, sck-kr-g, sck-kv-g (revA/revB), scm-vp-g-c3340-00, scm-vp-p-c3340-00

## New Driver Support
- ai_layout_formatter_wr
- axis_subset_converter
- preprocess
