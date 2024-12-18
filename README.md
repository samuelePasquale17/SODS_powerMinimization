# Low-Power Contest: Post-Synthesis Leakage Power Minimization

## Overview
This project focuses on minimizing **leakage power** in a post-synthesis phase using **Synopsys PrimeTime**. The optimization is constrained to multi-Vth techniques, where cells are swapped from Low-Vth (LVT) to Standard-Vth (SVT) or High-Vth (HVT). The approach ensures power savings while maintaining timing constraints, particularly avoiding negative slack.

---

## Objectives
- **Minimize leakage power** using multi-Vth optimization.
- Avoid timing violations by respecting slack constraints.
- Optimize runtime to meet a maximum threshold of 180 seconds.

---

## Optimization Algorithm
The optimization algorithm is divided into two main phases:

### 1. Priority-Based Dichotomic Optimization
- **Priority Definition**: Cells are prioritized based on their **slack**.
   - Cells with higher slack are assigned higher priority since they offer more flexibility for Vth swapping.
- **Dichotomic Algorithm**:
   - The ordered cells are split into two halves.
   - Left-side cells are swapped from LVT to HVT.
   - Slack is checked after each operation.
   - If slack is not met, the changes are reverted, and the group is further subdivided.
   - The process continues until the slack constraint is satisfied.

### 2. Fanout-Based Brute Force Optimization
- **Priority Definition**: Remaining LVT cells are prioritized based on their **fanout**.
   - Cells with lower fanout are processed first to minimize the impact on downstream arrival times.
- **Brute Force Approach**:
   - The first 20 cells are swapped from LVT to HVT.
   - From the 21st cell onward, swaps are made to SVT.
   - After each swap, the slack is validated.
   - If the slack becomes negative, a **backtrack phase** reverts changes to maintain timing integrity.

This two-phase approach ensures efficient power reduction while balancing runtime and timing constraints.

---

## Results
The algorithm was tested across multiple benchmarks with the following outcomes:

| Benchmark | Slack      | Leakage Power Savings [%] | Run Time [s] |
|-----------|------------|---------------------------|--------------|
| c1908.1   | 0.000115   | 15.61916352               | 48.581       |
| c3540.1   | 0.000213   | 19.07349763               | 51.313       |
| c5315.1   | 0.000284   | 27.49330755               | 57.474       |
| c7552.1   | 0.000431   | 34.35423985               | 69.147       |
| c1355.1   | 0.000742   | 64.96194448               | 91.611       |

---

## Tools Used
- **Synopsys PrimeTime**: Post-synthesis analysis and optimization.
- **TCL Scripting**: Automation of multi-Vth optimization processes.

---

## Conclusion
This project successfully reduced **post-synthesis leakage power** using an efficient multi-Vth optimization algorithm. The combination of dichotomic and brute-force strategies allowed significant power savings while adhering to timing constraints and runtime limitations.
