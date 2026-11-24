# gmId-Analog-RF-Sizing-tool
PDK-agnostic gm/Id Analog &amp; RF Transistor Sizing Studio in MATLAB. Parses Cadence Spectre .vcsv sweeps into interactive 2D-interpolated LUTs &amp; design curves.

**A PDK-Agnostic MATLAB GUI for Automated \(g_m/I_D\)-Based Circuit Sizing from Cadence Spectre Sweeps**

![gm/Id Sizing Studio GUI](gui_preview.png)

##  Why This Tool?
Square-law hand calculations (\(I_D = \frac{1}{2}\mu C_{ox}\frac{W}{L}(V_{GS}-V_{th})^2\)) fail in weak and moderate inversion, forcing analog designers into tedious trial-and-error iterations in Cadence Virtuoso.

**`gmId_Sizing_tool.m`** automates the \(g_m/I_D\) design methodology by parsing raw Cadence Spectre `.vcsv` DC sweeps into an interactive 2D-interpolated Lookup Table (`pchip` across both channel length \(L\) and \(g_m/I_D\)).

###  Features
* **PDK-Agnostic & Auto-Aligning:** Automatically parses any number of `<L>.vcsv` and `<L>gm.vcsv` sweep files from any PDK (`gpdk180`, `gpdk90`, `gpdk45`, `sky130`, etc.), regardless of Cadence column export order.
* **Triple-Synced Length (\(L\)) Control:** Choose extracted lengths via dropdown or indexed slider, or type any intermediate length (e.g., `1.35 µm`) for live 2D interpolation.
* **Analog & RF Biasing Presets:** One-click \(g_m/I_D\) presets for Subthreshold Diff Pairs (`24`), Active Loads (`18`), Current Mirrors (`14`), RF LNAs (`10`), and Mixers/VCOs (`7`).
* **Bidirectional Solver:** Enter target current (\(I_D\) in nA/µA) or target transconductance (\(g_m\) in µS/mS) to instantly calculate width (\(W\)), finger count, gate capacitance (\(C_{gg}\)), and \(\vert{}V_{GS}\vert{}\).
* **4 Real-Time Diagnostic Curves:** Live crosshairs and `(X, Y)` callouts for **Intrinsic Gain (\(g_m/g_{ds}\))**, **Current Density (\(I_D/W\))**, **Transit Frequency (\(f_T\))**, and **Inversion Region (\(g_m/I_D\) vs. \(\vert{}V_{GS}\vert{}\))**, plus a multi-length overlay toggle.

---

## How to Extract `.vcsv` Curves in Cadence Virtuoso (ADE L / Explorer)

### 1. Testbench Setup
Place one NMOS and one PMOS instance (`W = w`, `L = l`, `m = 1`):
```text
         NMOS Testbench                            PMOS Testbench
              D (vds)                                   S, B (GND)

              |                                         |
    G (vgs) --| nmos (W=w, L=l)               G (-vgs) --| pmos (W=w, L=l)

              |                                         |
              S, B (GND)                                D (-vds)
```
* Set design variables: `w = 10u`, `l = 1u`, `vgs = 0.5`, `vds = 0.6` ($V_{DD}/2$).

### 2. Save DC Operating Points
1. Open **Launch → ADE L** (or **ADE Explorer**).
2. Click **Analyses → Choose... → `dc`**, enable **Save DC Operating Point**, sweep **Design Variable** `vgs` from `0` to `1.2` (Linear step `20m`).
3. Go to **Outputs → To Be Saved → Select OP Parameters...**, click each transistor, and add: `gm`, `gds`, `id`, `gmoverid`, `cgg`.
4. Click **Netlist and Run** once.

### 3. Calculator Expressions (`waveVsWave`)
Open **Tools → Calculator**, select `os` (Operating Point Sweep), and send these expressions to ADE Outputs:
* **Intrinsic Gain vs. $g_m/I_D$:** `waveVsWave(?x OS("/M0" "gmoverid") ?y (OS("/M0" "gm") / OS("/M0" "gds")))`
* **Current Density vs. $g_m/I_D$:** `waveVsWave(?x OS("/M0" "gmoverid") ?y (OS("/M0" "id") / VAR("w")))`
* **Transit Frequency vs. $g_m/I_D$:** `waveVsWave(?x OS("/M0" "gmoverid") ?y (OS("/M0" "gm") / (2 * 3.14159 * OS("/M0" "cgg"))))`
* **$g_m/I_D$ vs. $V_{GS}$:** `OS("/M0" "gmoverid")`

### 4. Sweep $L$ & Export `.vcsv`
1. Sweep `l` via **Tools → Parametric Analysis** (e.g., `300n` to `3u`).
2. For each length `<L>` (e.g., `600n`), export the first 3 curves as **`600n.vcsv`** and the $g_m/I_D$ vs. $V_{GS}$ curve as **`600ngm.vcsv`** into separate `nmos/` and `pmos/` folders.

---

##  Running the Tool
1. Open MATLAB (R2020b or newer) and run **`gmId_Sizing_tool.m`**.
2. Select your `nmos/` and `pmos/` folders in the pop-up dialog (`PDK_LUT.mat` is cached automatically for instant future launches).
