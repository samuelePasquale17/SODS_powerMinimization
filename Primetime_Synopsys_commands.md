# Commands

## Menu
- [Primetime Synopsys commands](#primetime-synopsys-commands)

    - [Getting Started](#getting-started)
    - [Collections](#collections)
    - [Querying collections](#querying-collections)
    - [Attributes](#attributes)
    - [Manipulating collections](#manipulating-collections)
    - [Iteration](#iteration)
    - [Sorting](#sorting)
    - [Filtering](#filtering)
    - [Static Timing Analysis with PrimeTime](#static-timing-analysis-with-primetime)
    - [Working with Timing Path Collections](#working-with-timing-path-collections)
    - [Storing Timing Attributes](#storing-timing-attributes)
    - [Defining a New Procedure](#defining-a-new-procedure)
    - [Dynamic Power Optimization: Clock Gating](#dynamic-power-optimization-clock-gating)
    - [Leakage Power Optimization: Enabling Multi-Vth Synthesis](#leakage-power-optimization-enabling-multi-vth-synthesis)
    - [Post synthesis refinement: Swap a Gate from different libraries](#post-synthesis-refinement-swap-a-gate-from-different-libraries)

- [Git commands](#git-commands)

## Primetime Synopsys commands
## Getting Started

Open PrimeTime and load the post-synthesis design with the `pt_analysis.tcl` script:

```sh
cd WORK_SYNTHESIS 
pt_shell 
source ./scripts/pt_analysis.tcl 
```

## Collections

Synopsys applications build an internal database of objects and attributes applied to them. These databases consist of several classes of objects, including:

- designs
- libraries (libs)
- library cells (lib_cells)
- library pins (lib_pins)
- ports
- cells
- pins
- nets
- timing_points
- timing_paths

By definition, a collection is a group of objects exported to the Tcl user interface. Collections have an internal representation (the objects) and represent an ordered sequence of database objects.

You can read the reference documentation about collections with the following command:

```sh
man collections 
```

## Querying collections

You can store collections in variables with the `get_*` command, where `*` is the class, e.g., `get_libs`, `get_ports`, `get_cells`, `get_pins`, `get_nets`, and so on. For example, we can get all the cells of our design with the following command:

```sh
set cells [get_cells] 
```

The collection returned by the `get_cells` command will be stored in the `cells` variable.

We can get a cell with a specific name:

```sh
set cell [get_cells U17067] 
```

We can create a collection of objects connected to a specific object with `-of_objects` options. For example, we can get all the pins of a cell with:

```sh
get_pins -of_objects $cell 
```

Or, we can get the cell related to a pin with:

```sh
set pin [get_pins U17067/A] 
set cell [get_cells -of_objects $pin] 
```

## Attributes

Design objects are associated with a list of attributes that store all the information about the object itself. Attributes can be of different types, like string, float, integer, or even collection.

We can get a description of all the attributes of a specific class with the following commands:

```sh
man port_attributes 
man cell_attributes 
man pin_attributes 
man net_attributes 
```

Or, we can display a sorted list of all the attributes of a specific class with the `list_attribute` command. For example:

```sh
list_attribute -application -class port 
list_attribute -application -class cell 
list_attribute -application -class pin 
list_attribute -application -class net 
```

We can retrieve the value of an attribute on an object with the `get_attribute` command, e.g.:

```sh
set cell [get_cells U17067] 
get_attribute $cell full_name 
get_attribute $cell ref_name 
get_attribute $cell area 
get_attribute [get_ports "key[107]"] direction 
```

## Manipulating collections

We can get the number of elements in a collection with the `sizeof_collection` command:

```sh
# Get the number of cells 
sizeof_collection [get_cells] 

# Get the number of ports 
sizeof_collection [get_ports] 
```

We can merge multiple collections with the `add_to_collection` command:

```sh
add_to_collection [get_cells U11347] [get_cells U17088] 
```

We can remove elements from a collection with the `remove_from_collection` command:

```sh
# Remove the clock port from the collection of all the design ports 
remove_from_collection [get_ports] [get_ports clk] 
```

## Iteration

To iterate over the objects in a collection, use the `foreach_in_collection` command. You cannot use the Tcl-supplied `foreach` iterator to iterate over the objects in a collection, because the `foreach` command requires a list, and a collection is not a list. For example:

```sh
set cells [get_cells] 
foreach_in_collection point_cell $cells { 
    set full_name [get_attribute $point_cell full_name] 
    set ref_name [get_attribute $point_cell ref_name] 
    set area [get_attribute $point_cell area] 
    puts "$full_name is a $ref_name with area $area" 
} 
```

## Sorting

We can use the `sort_collection` command to order the objects in a collection based on one or more attributes. Sorting is ascending, by default, or descending when we specify the `-descending` option. For example:

```sh
# Sort by area 
sort_collection [get_cells] area 
 
# Sort by leakage power 
sort_collection [get_cells] leakage_power 
 
# Sort by area, then by leakage power 
sort_collection [get_cells] {area leakage_power} 
```

See `man sort_collection` for more examples.

## Filtering

We can filter a collection according to the value of a specific attribute with the `-filter` option. Some examples are reported as follows:

```sh
# Get all primary inputs 
get_ports -filter "direction == in" 
 
# Get all primary outputs 
get_ports -filter "direction == out" 
 
# Get all combinational cells 
get_cells -filter "is_combinational == true" 
 
# Get cells with area larger than 2.0 
get_cells -filter "area > 2.0" 
 
# Get the input pins of cell U11335 
get_pins -of_object [get_cells U11335] -filter "direction == in"

```

## Static Timing Analysis with PrimeTime

The `report_timing` command returns a textual description of the most critical timing paths and provides options to control the reporting of:

- Path delay constraints
- Startpoints, endpoints, and intermediate points along the path
- Path types
- Number of paths

This tutorial covers only the main parameters. For a complete overview, refer to the manual page with the `man report_timing` command.

### Path delay constraints

We can control the type of path delay constraint to consider with the `-delay_type` option.

For the setup checks (max delay analysis), use the max value (which is also the default value):

```sh
report_timing -delay_type max 
```

For the hold checks (min delay analysis), use the min value:
```sh
report_timing -delay_type min 
```

### Startpoints, Endpoints, Intermediate Points
We can focus the analysis on paths traversing a specific startpoint, endpoint, or any intermediate point. Use the following options:

- `-from`: to specify the startpoint
- `-to`: to specify the endpoint
- `-through`: to specify a pin, port, cell, or net

For example, the following command reports a path that starts at A1, then passes through either B1 or B2, then passes through C1, and ends at D1.
```sh
report_timing -from A1 -through {B1 B2} -through C1 -to D1 
```

### Path Types
Timing paths can be classified into four categories:

- Input-to-Register
- Register-to-Register
- Register-to-Output
- Input-to-Output

We can use the `-from` and `-to` options to analyze paths belonging to each category:

```sh
# Input-to-Register 
report_timing -from [all_inputs] -to [all_registers -data_pins] 

# Register-to-Register 
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] 

# Register-to-Output 
report_timing -from [all_registers -clock_pins] -to [all_outputs] 

# Input-to-Output 
report_timing -from [all_inputs] -to [all_outputs] 
```

### Number of paths
We can control the number of paths to consider in the report with the `-nworst` and `-max_paths` options.

The `-nworst` option specifies the maximum number of paths per endpoint. The default is 1. A larger value results in more runtime.
```sh
report_timing -delay_type max -nworst 3
```

The `-max_paths` option specifies the overall total maximum number of paths reported. The default is equal to the `-nworst` setting, or 1 if the `-nworst` option is not used.

When `-max_paths` is set to any value larger than 1, the command only reports paths that have negative slack. To include positive-slack paths in multiple-paths reports, use the `-slack_lesser_than` option, as in the following example:
```sh
report_timing -delay_type max -nworst 3 -max_paths 6 -slack_lesser_than 1000
```
This example will report the six paths with the worst slack; at most three reported paths will share the same endpoint.

## Working with Timing Path Collections

PrimeTime stores the timing information in dedicated objects that can be used for custom reporting or other processing. The main classes are `timing_path` and `timing_point`.

To create a collection of timing paths, we can use the `get_timing_paths` command, which provides the same options as `report_timing`.

A timing-path is a collection of timing-points. Each timing-point is an object containing several attributes (Note: a row in the output of the report_timing command represents a single timing-point, and all the information shown in that row are the timing-point attributes).

A timing-point can be a port or a pin. The corresponding port/pin can be retrieved with the `object` attribute of the timing-point.

Use the following commands to get the list of attributes:
```sh
man timing_path_attributes 
man timing_point_attributes 
```

Two commands are usually used to analyze timing path collections:

- `foreach_in_collection`: to scan the obtained timing collection
- `get_attribute`: to extract attributes of each timing point
The following examples show how to work with timing path collections:

- Extract the arrival time and the slack of the most critical path:
```sh
set wrt_arrival [get_attribute [get_timing_path] arrival] 
set wrt_slack [get_attribute [get_timing_path] slack] 
```

- Extract the list of cells belonging to the most critical paths:
```sh
set wrt_path_collection [get_timing_paths] 
# Scan the collection of timing points belonging to the path 
foreach_in_collection timing_point [get_attribute $wrt_path_collection points] { 
    # Get the object at this point in the timing path. 
    set point_object [get_attribute $timing_point object] 

    # Get the object name (it can be a port or pin). 
    set point_name [get_attribute $point_object full_name] 
    # For each timing point, we can extract multiple attributes (e.g., arrival time) 
    set arrival [get_attribute $timing_point arrival] 
    puts "$point_name --> $arrival" 
}
```

## Storing Timing Attributes

In PrimeTime, we can annotate the slack of the most critical path traversing each pin of the design with a simple command.

Modify the `pt_analysis.tcl` script, adding the following command at the beginning:

```sh
set timing_save_pin_arrival_and_slack true 
```
If the `timing_save_pin_arrival_and_slack` variable is set to true, then the attributes `max_fall_slack`, `max_rise_slack`, `max_fall_arrival`, and `max_rise_arrival` are annotated on all pins of the design. If the variable `timing_save_pin_arrival_and_slack` is set to false (the default), then the attributes are valid only for timing path endpoints. These attributes are useful to retrieve information about the longest path with a transition on a pin. In fact, `max_fall_slack (max_rise_slack)` returns the worst slack at a pin for falling (rising) maximum path delays; `max_fall_arrival (max_rise_arrival)` returns the arrival time for the longest path with a falling (rising) transition on the pin.

## Defining a New Procedure

Using the TCL command `proc`, we can create new custom TCL commands in the current environment space (`dc_shell` or `pt_shell`).

Like any other programming language, a procedure gets input parameters, processes them, and returns some result.

By default, all the input parameters are passed by value; if you need to modify the content of some parameters, you can use the `global` attribute.

Variables defined inside the procedure are deleted from the procedure workspace once the procedure returns.

The following example shows a standard procedure definition:

```sh
set var_reference 10 

proc cmd_example {par1 par2} { 
    global var_reference 
    set product [expr $par1 * $par2] 
    if {$product == $var_reference} { 
        return 1 
    } else { 
        return 0 
    } 
}
```

The procedure `cmd_example` receives three input parameters: `par1` and `par2`, and `var_reference` (which is a global variable defined outside the procedure).

**NOTE**: We can define the procedure in a dedicated TCL script. Before using it, we have to run the script containing the procedure definition with the `source` command.


## Dynamic Power Optimization: Clock Gating

### Introduction
Clock gating is an important technique for reducing the dynamic power consumption of a design. The figure shows a latch-based clock-gating cell and the waveforms of the signals are shown with respect to the clock signal, CLK. The clock input to the register bank, ENCLK, is gated on or off by the AND gate. ENL is the enabling signal that controls the gating. The register bank is triggered by the rising edge of the ENCLK signal.

The AND gate blocks unnecessary clock transitions by maintaining the clock signal’s value after the trailing edge.

The latch prevents glitches on the EN signal from propagating to the register’s clock pin. When the CLK input of the 2-input AND gate is at logic state 1, any glitching of the EN signal could, without the latch, propagate and corrupt the register clock signal. The latch eliminates this possibility because it blocks signal changes when the clock is at logic state 1.

### Enabling Clock Gating
Design Compiler provides us with two commands for enabling RTL-level clock-gating:
- `set_clock_gating_style`: set the clock gating style defining parameters like the bank-register width, or maximum fan-out for each clock-gating element;
- `compile_ultra –gate_clock`: recognize clock-gating condition and perform the synthesis/optimization of the circuit.

In practice:
1. In the scripts folder, create (if does not exist) a TCL file titled `clock_gating.tcl` with the following code:
    ```tcl
    set clockGateMinBitWidth 1 ;# minimum bit-width of the cg bank-register
    set clockGateMaxFanout 1024 ;# maximum number of registers driven by the same cg-element 

    set_clock_gating_style \ 
        -minimum_bitwidth $clockGateMinBitWidth \ 
        -max_fanout $clockGateMaxFanout 
    ```

2. Copy the `synthesis.tcl` script to `synthesis_cg.tcl`.

3. Source the file `clock_gating.tcl` in the `synthesis_cg.tcl` and replace the command compile with the following code:
    ```tcl
    # compile
    source "./scripts/clock_gating.tcl" 
    compile_ultra -gate_clock 
    set_dont_retime [all_fanout -from [get_pins -filter is_clock_gate_output_pin] -only_cells] 
    ```

4. Comment the exit command at the end of `synthesis_cg.tcl`.

5. Open the dc_shell and run the synthesis with clock gating:
    ```sh
    cd WORK_SYNTHESIS 
    dc_shell-xg-t 
    source ./scripts/synthesis_cg.tcl 
    ```

6. Use the command `report_clock_gating` at the end of the synthesis to analyze the % of gated registers:
    ```sh
    report_clock_gating 
    report_clock_gating -structure 
    report_clock_gating -enable_conditions 
    ```

For running the STA of a design with clock-gating, we need to apply the following modifications:
- In the `synopsys_pt.setup` file replace the last line with:
    ```tcl
    lappend link_library [lindex $libraries 2] 
    ```

- In the `pt_analysis.tcl` script add the link_design command after the `read_verilog` command:
    ```tcl
    read_verilog $in_verilog_filename 
    link_design $blockName 
    ```

## Leakage Power Optimization: Enabling Multi-Vth Synthesis

### Pre-requisites
For leakage power optimization, we will adopt as benchmark a small combinational circuit named c432. The RTL verilog and the SDC files of this circuit can be found in the `c432.zip` archive on the Portal (in Labs/LAB5). Copy the files in the working directory following the instructions reported below:
- Download `c432.zip` from the Portal and copy it to `./WORK_SYNTHESIS/rtl/`.
- Extract the folder in the zip archive:
    ```sh
    unzip WORK_SYNTHESIS/rtl/c432.zip -d WORK_SYNTHESIS/rtl/ 
    ```

- Modify the value of the `blockName` variable in the `synthesis.tcl` and `pt_analysis.tcl` scripts:
    ```tcl
    set blockName "c432"
    ```

### Leakage-Aware Synthesis
Multi-threshold (Multi-Vth) technologies provide designers with logic gates having multiple threshold voltages (Vth); this enables leakage power optimization. For our 65nm technology:
- `./tech/STcmos65/CORE65LPLVT_nom_1.20V_25C.db`
- `./tech/STcmos65/CORE65LPHVT_nom_1.20V_25C.db`

A common practice is to use Low-Vth (LVT) gates on critical paths to maintain the performance, while High-Vth (HVT) gates are used on non-critical paths to reduce static leakage power without incurring a delay penalty. To enable this feature into Design Compiler:
- Include LVT and HVT libraries in the list of target libraries in `synopsys_dc.setup`; the resulting code should be:
    ```tcl
    set target_library ""
    lappend target_library [lindex $link_library 3] 
    lappend target_library [lindex $link_library 4] 
    ```

- Include LVT and HVT libraries in the list of link libraries in `synopsys_pt.setup`:
    ```tcl
    lappend link_library [lindex $libraries 3] 
    lappend link_library [lindex $libraries 4] 
    ```

- In the script `synthesis.tcl` replace the following line:
    ```tcl
    set_operating_condition -library  "${target_library}:CORE65LPSVT" nom_1.20V_25C 
    ```

  with:
    ```tcl
    set_operating_condition -library  "[lindex $target_library 0]:CORE65LPLVT" nom_1.20V_25C 
    ```

  Replace also:
    ```tcl
    set_wire_load_model -library "${target_library}:CORE65LPSVT" -name area_12Kto18K [find design *] 
    ```

  with:
    ```tcl
    set_wire_load_model -library "[lindex $target_library 0]:CORE65LPLVT" -name area_12Kto18K [find design *] 
    ```

- Replace the command compile with the following lines:
    ```tcl
    set_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT -type string 
    set_attribute [find library CORE65LPHVT] default_threshold_voltage_group HVT -type string 
    compile_ultra 
    ```

In PrimeTime, use the following code for defining threshold groups:
    ```tcl
    set_user_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT 
    set_user_attribute [find library CORE65LPHVT] default_threshold_voltage_group HVT 
    ```

Use the command `report_threshold_voltage_group` to analyze the % of LVT/HVT cells.

## Post synthesis refinement: Swap a Gate from different libraries
In Prime-Time, using the `size_cell` command we can re-size a given cell and/or map it using different Vth.

Example:
- The cell `U101`, which is a High-VT BFX2, is mapped as a Low-VT BFX2:
    ```tcl
    size_cell U101 CORE65LPLVT/HS65_LL_BFX2 
    ```

- The cell `U101`, previously remapped with the Low-VT BFX2, is now resized as a High-VT BFX4:
    ```tcl
    size_cell U101 CORE65LPHVT/HS65_LH_BFX4 
    ```

**NOTE**: Use the command `get_alternative_lib_cells` to get a collection of library cells logically equivalent to the specified cell (see man `get_alternative_lib_cells`):
    ```tcl
    get_alternative_lib_cells U101 
    ```



## Git commands
### git init
`git init` initializes a new Git repository.

### git clone
`git clone` copies an existing Git repository.

### git status
`git status` displays the state of the working directory and the staging area.

### git add
`git add` stages changes for the next commit.

### git commit
`git commit` records changes to the repository.

### git push
`git push` updates the remote repository with local changes.

### git pull
`git pull` fetches and merges changes from the remote repository to the local repository.

### git branch
`git branch` lists, creates, or deletes branches.

### git checkout
`git checkout` switches branches or restores working tree files.

### git merge
`git merge` joins two or more development histories together.

### git log
`git log` shows the commit history.

### git diff
`git diff` shows the changes between commits, commit and working tree, etc.

### git reset
`git reset` resets the current HEAD to a specified state.

### git rm
`git rm` removes files from the working tree and from the index.

### git restore
`git restore` restores working tree files.

### git stash
`git stash` temporarily shelves changes in the working directory.

### git tag
`git tag` creates, lists, or deletes tags.

### git remote
`git remote` manages the set of repositories whose branches you track.

### git fetch
`git fetch` downloads objects and refs from another repository.
