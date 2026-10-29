# EGO-XZ7 HW2 reproducible experiment

Vivado **2018.3** and SDK **2018.3**, EGO-XZ7 with XC7Z020 CLG484 **-1** (per the supplied V1.2 manual).
LED0: **T22**, central BTNC: **P16**, both active-high, LVCMOS33. Central button is marked **S6** on the user's board.

## Start here

Open PowerShell in this directory. Sources may be stored elsewhere, but choose an **ASCII build path without spaces**. All generated outputs default to `D:\hw2_rebuild`.

```powershell
.\run.ps1 -Action sim
.\run.ps1 -Action hardware
.\run.ps1 -Action sdk
```

- `sim`: creates two independent XSim projects and checks debounce plus the actual AXI GPIO IP. No board needed.
- `hardware`: regenerates the design, synthesizes, implements, checks DRC/timing and exports BIT/HDF. This recreates generated project data in the chosen build directory.
- `sdk`: creates/updates the hardware project, standalone BSP and application. Copies the supplied OCM linker script and builds the ELF.
- Tool installation directories may be supplied using `-VivadoRoot` and `-SdkRoot`. They must refer to the respective **2018.3** directories (the directory containing `bin`). Defaults match the original computer only.

Example on another machine:

```powershell
.\run.ps1 -Action sim -BuildDir D:\hw2_rebuild -VivadoRoot D:\Xilinx\Vivado\2018.3
.\run.ps1 -Action hardware -BuildDir D:\hw2_rebuild -VivadoRoot D:\Xilinx\Vivado\2018.3
.\run.ps1 -Action sdk -BuildDir D:\hw2_rebuild -SdkRoot D:\Xilinx\SDK\2018.3
```

Use the SAME `-BuildDir` for every step. No Vivado/SDK installation files are included.

## Open design and waveforms

```powershell
.\run.ps1 -Action open
.\run.ps1 -Action wave-debounce
.\run.ps1 -Action wave-irq
```

The waveform commands display the WDB produced by `sim`. Signal names and actual simulation values are shown in Vivado; use **Zoom Fit** to see the entire run. Saved original rebuild databases are also in `waveforms/`; from a Vivado Tcl console, source `scripts/view_debounce_saved.tcl` or `scripts/view_irq_saved.tcl` using their absolute file paths.

The Word report includes both actual VCD data plots and user-provided screenshots of the Vivado 2018.3 waveform GUI. Each is labeled separately. Original GUI images and actual Vivado IP Integrator PDF/SVG exports are in the sibling report figures directory.

## Use prebuilt hardware without rerunning implementation

```powershell
.\run.ps1 -Action prepare-prebuilt
.\run.ps1 -Action sdk
```

This copies the original verified BIT/HDF then builds the C application against that HDF. Do not mix unrelated hardware platforms with this application.

## Run on the board

1. Connect board power and J1 USB-JTAG/UART. Use the central BTNC/S6, not SRST or PROG.
2. Start local hardware server, for example Vivado **Open Hardware Manager > Open Target > Auto Connect**. The XSCT script connects to `localhost:3121`.
3. Run:

```powershell
.\run.ps1 -Action program
```

This temporarily programs FPGA and CPU0 over JTAG, resets the current application, runs PS initialization, and starts the ELF. It does **not** write QSPI or SD. If more than one board is connected, select an unambiguous target in the Tcl script first.

4. LED0 should initially be ON. Press and release BTNC once: LED0 should toggle OFF.
5. Read status:

```powershell
.\run.ps1 -Action read
```

Expected initial `app_status=1, led_state=1, irq_count=0, press_count=0`. After one full press/release: `led_state=0, irq_count=2, press_count=1, last_button=0`. Read temporarily halts CPU, reads OCM/GPIO, then resumes.

Power cycling requires reloading. No permanent boot image is created.

## What is tested

- `tb_button_conditioner.v`: bounce rejection, one press/release, stable hold, both active-high/low configurations.
- `tb_axi_gpio_irq.v`: actual generated AXI GPIO input IP, AXI-Lite access, press/release IRQ, high level until clear, no held-button retrigger, IPIER mask with pending delivery.
- Both simulations use `STABLE_CYCLES=4`; physical hardware uses **1,000,000 cycles at 50 MHz = about 20 ms**.
- Simulations do not execute ARM/GIC/C ISR. End-to-end CPU behavior was separately verified on hardware on 2026-10-27.
- Application source is identical to the successful original. `ButtonIsr` is custom application code; XGpio and XScuGic are BSP drivers.

## Rebuild verification

`evidence/rebuild/verification.json` records **15 passing checks** from a clean build under a new directory. Both tests passed, hardware generated BIT/HDF, SDK generated a new BSP and ELF, IRQ ID is 61, LED/Button bases are 0x41200000/0x41210000, and the HDF-embedded bitstream matches the exported BIT. Timing: WNS 12.833 ns, WHS 0.084 ns. C image size: text 28848, data 1952, bss 22648 bytes.

The rebuilt hardware was not separately reprogrammed during document preparation. Original physical evidence is under `evidence/`, and the complete original project archive is one directory up in `local_archive/`.

## Repository layout

- `src/`: RTL, two testbenches, XDC, C application, OCM linker script.
- `scripts/`, `run.ps1`: portable generation/build/run entry points. All source locations derive from the repository directory.
- `prebuilt/`: original verified BIT/HDF/ELF.
- `waveforms/`: saved XSim WDBs from the clean rebuild.
- `evidence/`: original board results and clean rebuild logs/data.
- Word reports and figures are in the parent `hw2/part1`, `part2`, `part3` directories.

Generated IP and BSP files are recreated using the installed Xilinx tools. Preserve existing Xilinx copyright notices in supplied files. Third-party reference manuals are identified in the reports by source and page; do not replace the source citations with invented register data.
