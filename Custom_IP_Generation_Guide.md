# Custom IP generation Using System Device Tree Generator (SDTGen)

How SDTGen handles custom IPs (third-party or user-authored Vivado
IPs that are not natively recognized) when generating a System Device
Tree from an `.xsa`, and what the user has to do to get the required output.

---

## 1. Default output for any IP

For every peripheral whose base address is mapped to a processor,
SDTGen runs a fixed sequence before any IP-specific TCL is sourced:

- `gen_peripheral_nodes` (`create_node_only`)
  - Creates the `<ip_name>@<unit_addr>` node under the right bus
    (e.g. `&amba_pl`); label = Vivado instance name.
  - Selects `pl.dtsi` for PL IPs, `pcw.dtsi` for PS IPs.
- `gen_reg_property`
  - Emits `reg = <base size>;` from the address map of every
    connected master.
- `gen_compatible_property`
  - Emits `compatible = "xlnx,<vlnv-name>-<vlnv-version>";` derived
    from the IP's VLNV (underscores replaced with `-`).
- `gen_drv_prop_from_ip`
  - Emits one `xlnx,<param> = <value>;` per Vivado `CONFIG.*`
    parameter, after stripping auto-blocked names (`*BASEADDR`,
    `*HIGHADDR`, AXI bus widths/clock periods, `INSTANCE`, `FAMILY`,
    `HW_VER`, etc.).
- `gen_interrupt_property`
  - Emits `interrupts` / `interrupt-parent` (and `#interrupt-cells`
    on the parent) when an interrupt port is connected.
- `gen_clk_property`
  - Emits `clocks` and `clock-names` for every connected clock pin.
- `gen_power_domains` / `gen_domain_data`
  - Adds `power-domains` for Versal/ZynqMP IPs and the `xlnx,domain`
    accounting used by isolation flows.

The resulting node looks like:

```dts
my_custom_ip_0: my_custom_ip@a0010000 {
    compatible       = "xlnx,my-custom-ip-1.0";
    reg              = <0x0 0xa0010000 0x0 0x10000>;
    interrupts       = <0 89 4>;
    interrupt-parent = <&gic>;
    clocks           = <&misc_clk_2>;
    clock-names      = "s_axi_aclk";
    xlnx,my-param-a  = <0x10>;
    xlnx,my-param-b  = "enabled";
    /* ...one xlnx,* entry per CONFIG.* parameter... */
};
```

To generate the DT:

```bash
sdtgen -xsa system.xsa -dir sdt_outdir
```

---

## 2. Per-IP TCL dispatch

After the default sequence, SDTGen looks up the IP in the dictionary
`::sdtgen::namespacelist`, which maps Vivado `IP_NAME` to a folder
under the SDT repo root:

```tcl
dict set ::sdtgen::namespacelist "axi_gpio"     "axi_gpio"
dict set ::sdtgen::namespacelist "axi_quad_spi" "axi_qspi"
dict set ::sdtgen::namespacelist "v_frmbuf_wr"  "framebuf_wr"
```

When iterating over peripherals:

```tcl
if { [dict exists $::sdtgen::namespacelist $ip_name] } {
    set drvname [dict get $::sdtgen::namespacelist $ip_name]
    source [file join $path $drvname "data" "${drvname}.tcl"]
    ${drvname}_generate $drv_handle
}
```

`<repo>/<drvname>/data/<drvname>.tcl` is sourced and `<drvname>_generate`
runs after the default sequence, so it can augment or override anything
the defaults produced. If `IP_NAME` is not in the dictionary, the legacy
lookup falls back to the `"generic"` driver, which adds nothing on top
of ##1.

---

## 3. Customizing the output

### 3.1. Add a native handler in the SDT repo

For IPs that ship with the design and should always emit the same
node.

1. Create the folder layout under the repo root:

   ```
   my_custom_ip/
     data/
       my_custom_ip.tcl
   ```

2. Define `<ip>_generate`:

   ```tcl
   proc my_custom_ip_generate {drv_handle} {
       set node [get_node $drv_handle]
       if {$node == 0} { return }

       # Override / append compatible
       pldt append $node compatible "\ \, \"vendor,my-ip\""

       # Add custom properties to pl.dtsi
       add_prop $node "vendor,mode"    "stream" string  "pl.dtsi"
       add_prop $node "#address-cells" 2        int     "pl.dtsi"
       add_prop $node "#size-cells"    2        int     "pl.dtsi"

       # Conditionally read a Vivado CONFIG parameter
       set has_dma [hsi get_property CONFIG.C_HAS_DMA \
                       [hsi::get_cells -hier $drv_handle]]
       if {[string match $has_dma "1"]} {
           add_prop $node "dma-coherent" "" boolean "pl.dtsi"
       }
   }
   ```

3. Register the IP in `init_proclist`:

   ```tcl
   dict set ::sdtgen::namespacelist "my_custom_ip" "my_custom_ip"
   ```

   Key = Vivado `IP_NAME` (case-sensitive). One handler can serve
   several IP names (e.g. `axi_clk_wiz` is reused for `clk_wiz`,
   `clkx5_wiz`, `clk_wizard`).

4. Point SDTGen at your modified repo and regenerate:

   ```bash
   export CUSTOM_SDT_REPO=/absolute/path/to/local/system-device-tree-xlnx
   sdtgen -xsa system.xsa -dir sdt_outdir -trace enable -debug enable
   ```

   `-trace` / `-debug` confirm that `my_custom_ip_generate` ran (Optional).

The resulting node in `pl.dtsi`:

```dts
my_custom_ip_0: my_custom_ip@a0010000 {
    compatible       = "vendor,my-ip", "xlnx,my-custom-ip-1.0";
    reg              = <0x0 0xa0010000 0x0 0x10000>;
    interrupts       = <0 89 4>;
    interrupt-parent = <&gic>;
    clocks           = <&misc_clk_2>;
    clock-names      = "s_axi_aclk";
    #address-cells   = <2>;
    #size-cells      = <2>;
    dma-coherent;                     /* added because CONFIG.C_HAS_DMA == 1 */
    vendor,mode      = "stream";
    xlnx,my-param-a  = <0x10>;
    xlnx,my-param-b  = "enabled";
};
```

### 3.2. Modification tips

- Add a property
  - `add_prop $node <name> <value> <type> <dts_file>`
- Append to an existing list (e.g. add a 2nd `compatible`)
  - `pldt append $node compatible "\, \"vendor,xyz\""`
- Replace a property emitted by the defaults
  - call `add_prop` again — last writer wins
- Send the node to a different file (e.g. `pcw.dtsi` instead of `pl.dtsi`)
  - use `set_drv_def_dts` and pass the returned `dts_file` to every
    `add_prop` (Note: this works reliably only when the target node
    already exists in the destination DTS.)
- Add child sub-nodes
  - `create_node -n <name> -l <label> -u <unit_addr> -p <parent> -d <dts_file>`
- Resolve interrupts on a non-default port
  - `gen_interrupt_property $drv_handle <port_name>`
- Add a `clock-names` mapping
  - `set_drv_prop_if_empty $drv_handle clock-names "<list>" $node stringlist`
- Phandle to another IP (e.g. DMA peer)
  - `get_node` for the peer + `add_prop ... reference`

### 3.3. Non-memory-mapped IPs

The default sequence in ##1 is keyed on the IP's base address. If the IP
has no entry in any processor's address map, `get_node` returns `""`,
`gen_peripheral_nodes` exits early on `unit_addr == -1`, and the rest
of the sequence skips the IP — nothing is emitted by default. The
handler has to build the node by hand:

```tcl
proc my_streaming_ip_generate {drv_handle} {
    # Pick the parent bus and the destination file.
    set bus_node [detect_bus_name $drv_handle]
    set dts_file "pl.dtsi"
    update_system_dts_include $dts_file

    # No unit address -> use the instance name as both label and node name.
    set node [create_node -n $drv_handle -l $drv_handle \
                          -p $bus_node   -d $dts_file]

    # compatible is mandatory; reg is omitted on purpose.
    add_prop $node compatible \
        "vendor,my-streaming-ip [gen_compatible_string $drv_handle]" \
        stringlist $dts_file

    # Replicate the bits of the default sequence that still make sense.
    gen_drv_prop_from_ip   $drv_handle   ;# xlnx,* from CONFIG.*
    gen_interrupt_property $drv_handle   ;# safe to call; no-op if none
    gen_clk_property       $drv_handle   ;# safe to call; no-op if none

    # If the IP only exposes AXI-Stream ports, model the pipeline:
    set ports_node [create_node -n "ports" -p $node -d $dts_file]
    add_prop $ports_node "#address-cells" 1 int $dts_file
    add_prop $ports_node "#size-cells"    0 int $dts_file
    set port0 [create_node -n "port" -u 0 -p $ports_node -d $dts_file]
    add_prop $port0 "reg" 0 int $dts_file
    # ...endpoint / remote-endpoint via the helpers in common_proc.tcl
}
```

Reference handlers in the repo that build nodes without a `reg`:
`axis_broadcaster`, `axis_subset_converter` (pure stream IPs modelled
with `ports / port / endpoint`); `audio_formatter`, `audio_embed`
(media-pipeline endpoints).

# NOTE: Don't fabricate a fake `reg`; drivers that need register access for a
non-memory-mapped IP usually go through a sibling controller (DMA,
mixer, etc.) via a phandle. If the IP is partially mapped, let the
default sequence handle the AXI-Lite address and add the streaming
child nodes from the handler.

---
