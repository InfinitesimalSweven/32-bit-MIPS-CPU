# 32-bit Pipelined MIPS Cache Computer

A fully pipelined 32-bit MIPS processor implemented in SystemVerilog, featuring a 5-stage pipeline with hazard detection and forwarding, a configurable cache subsystem, and a latency-modeled data memory.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [File Structure](#file-structure)
3. [Pipeline](#pipeline)
4. [Hazard Handling](#hazard-handling)
5. [Cache Subsystem](#cache-subsystem)
6. [Memory Model](#memory-model)
7. [Instruction Set Architecture (ISA)](#instruction-set-architecture-isa)
8. [ALU Control Encoding](#alu-control-encoding)
9. [Control Signal Reference](#control-signal-reference)

---

## Architecture Overview

```
         ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
  IMEM → │  IF    │ →  │  ID    │ →  │  EX    │ →  │  MEM   │ →  │  WB    │
         └────────┘    └────────┘    └────────┘    └────────┘    └────────┘
                            ↑              ↑              ↑
                        Forwarding     Forwarding     Forwarding
                         (Decode)      (Execute)      (Execute)
                                           ↑
                                      Hazard Unit
                                   (Stall / Flush)
                                           ↑
                                    Cache Subsystem
                                  (Direct / Set / Full)
```

The top-level `computer` module wires together:
- A pipelined `cpu` (5 stages: IF, ID, EX, MEM, WB)
- Synchronous instruction memory (`imem`)
- A cache hierarchy sitting between the CPU and data memory
- Latency-modeled data memory (`dmem`) with a `dmem_ready` handshake
- A `cache_en` bypass switch allowing direct CPU→DMEM access

---

## File Structure

| File | Module | Description |
|------|--------|-------------|
| `computer.sv` | `computer` | Top-level: wires CPU, IMEM, cache, DMEM |
| `cpu.sv` | `cpu` | Pipeline top-level: instantiates datapath, controller, hazard unit |
| `datapath.sv` | `datapath` | All 5 pipeline stages, pipeline registers, forwarding muxes |
| `controller.sv` | `controller` | Combines maindec + aludec; produces all control signals |
| `maindec.sv` | `maindec` | Opcode → control vector decoder |
| `aludec.sv` | `aludec` | funct/aluop → 4-bit ALU control |
| `alu.sv` | `alu` | 32-bit ALU with HI/LO register for MULT/DIV |
| `hazard.sv` | `hazard` | Forwarding, stall, flush, and exception logic |
| `regfile.sv` | `regfile` | 32×32 register file, write on negedge clk |
| `imem.sv` | `imem` | Instruction memory, loaded from `.exe` hex file |
| `dmem.sv` | `dmem` | Data memory with programmable cycle latency |
| `cache_direct_mapped.sv` | `cache_direct_mapped` | 16-block direct-mapped cache |
| `cache_set_associative.sv` | `cache_set_associative` | 8-set 2-way set-associative cache with LRU |
| `cache_fully_associative.sv` | `cache_fully_associative` | 16-block fully associative cache with FIFO replacement |
| `signext.sv` | `signext` | 16→32 sign extension |
| `adder.sv` | `adder` | Parameterized combinational adder |
| `sl2.sv` | `sl2` | Logical left shift by 2 (branch offset scaling) |
| `mux2.sv` | `mux2` | 2-to-1 mux, parameterized width |
| `mux3.sv` | `mux3` | 3-to-1 mux, parameterized width |
| `mux4.sv` | `mux4` | 4-to-1 mux, parameterized width |
| `dff.sv` | `dff` | Simple D flip-flop with synchronous reset |
| `flopenr.sv` | `flopenr` | D flip-flop with enable |
| `flopenrc.sv` | `flopenrc` | D flip-flop with enable and synchronous clear (pipeline register primitive) |
| `eqcmp.sv` | `eqcmp` | Equality comparator (used for BEQ in Decode stage) |
| `clock.sv` | `clock` | Testbench clock generator with enable |
| `_timescale.sv` | — | Global timescale: `1ns / 100ps` |

---

## Pipeline

The processor implements a classic 5-stage MIPS pipeline:

### Stage 1 — Instruction Fetch (IF)
- PC increments by 4 each cycle (`pcplus4F = pcF + 4`)
- Next-PC priority (highest to lowest): **Exception → JR → J/JAL → Branch → PC+4**
- Exception vectors to `0x8000_0180`
- Stalled by `stallF`; cannot update if hazard unit asserts hold

### Stage 2 — Instruction Decode (ID)
- Register file read (two ports, combinational)
- Branch equality resolved here using `eqcmp` on forwarded operands
- `pcsrcD = branchD & equalD` triggers branch redirect in the same stage
- Sign extension of 16-bit immediate
- Branch target computed as `pcplus4D + (signimm << 2)`
- IF/ID register flushed on branch taken, jump, JR, or exception

### Stage 3 — Execute (EX)
- ALU operands selected via 3-way forwarding muxes (`forwardaE`, `forwardbE`)
- `alusrcE` selects between register and sign-extended immediate
- Write register selected: `rd` for R-type, `rt` for I-type, hardwired `$31` for JAL
- Exception Program Counter (EPC) latched here if exception occurs

### Stage 4 — Memory (MEM)
- Issues `memwriteM` / `memreadM` to cache/DMEM
- Cache miss causes `mem_stall`, freezing all pipeline registers until `dmem_ready`

### Stage 5 — Writeback (WB)
- 3-way result mux selects between: ALU result, memory read data, or `pcplus4` (for JAL)
- Writes to register file on **negedge clk** (avoids write-then-read hazard within same cycle)

---

## Hazard Handling

All hazard logic is centralized in `hazard.sv`.

### Forwarding

**Execute-stage forwarding** (`forwardaE`, `forwardbE` — 2-bit):
- `2'b10` → forward from MEM stage ALU output
- `2'b01` → forward from WB stage result
- `2'b00` → use register file value

**Decode-stage forwarding** (`forwardaD`, `forwardbD` — 1-bit):
- Forwards MEM-stage ALU result into the branch equality comparator
- Covers the case where a branch immediately follows an instruction that writes its operand

JAL's effective write register (`$31`) is accounted for in all forwarding comparisons via `effWriteregE/M/W`.

### Stalls

| Condition | Signals Asserted |
|-----------|-----------------|
| Load-use hazard (`lw` followed immediately by dependent instruction) | `stallF`, `stallD`, `flushE` |
| Branch hazard (branch depends on result not yet written) | `stallF`, `stallD`, `flushE` |
| Cache/memory stall (`mem_stall` from cache miss) | `stallF`–`stallW` (full pipeline freeze) |

### Exceptions / Interrupts
- `intr` input asserts `Exception_Flag`
- Flushes Decode stage (`flushD`) and Execute stage (`flushE`)
- Redirects PC to exception vector `0x8000_0180`
- EPC saved in dedicated register in EX stage

---

## Cache Subsystem

All three cache variants share the same CPU-facing and DMEM-facing interfaces. The active cache in `computer.sv` is **`cache_fully_associative`**. `cache_direct_mapped` and `cache_set_associative` are included as alternates.

All caches implement:
- **Write-through** on hit (cache and DMEM updated simultaneously)
- **Write-allocate** on miss (block filled into cache before completing write)
- A 2-state FSM: `IDLE` → `FETCHING` → `IDLE`
- CPU stall via `mem_stall` during any miss

### Direct-Mapped Cache (`cache_direct_mapped`)

| Parameter | Value |
|-----------|-------|
| Blocks | 16 |
| Address mapping | `index = addr[5:2]` (4 bits), `tag = addr[31:6]` (26 bits) |
| Replacement | Direct (no choice) |

### 2-Way Set-Associative Cache (`cache_set_associative`)

| Parameter | Value |
|-----------|-------|
| Sets | 8 |
| Ways per set | 2 |
| Address mapping | `index = addr[4:2]` (3 bits), `tag = addr[31:5]` (27 bits) |
| Replacement | 1-bit pseudo-LRU per set |

LRU bit meaning: `0` = Way 0 is LRU (evict Way 0), `1` = Way 1 is LRU. Updated on every access (hit or miss allocation).

### Fully Associative Cache (`cache_fully_associative`) ← Active

| Parameter | Value |
|-----------|-------|
| Blocks | 16 |
| Address mapping | `tag = addr[31:2]` (30 bits, full word address) |
| Replacement | Round-robin FIFO via 4-bit `replace_ptr` |
| Hit detection | Parallel CAM search across all 16 blocks |

---

## Memory Model

### Instruction Memory (`imem`)
- 256-word (1KB) synchronous ROM
- Loaded at simulation start from a hex file
- Default file: `test_prog.exe`
- Override at runtime: `+PROG=<filename>` plusarg

### Data Memory (`dmem`)
- 256-word (1KB) RAM
- Parameterized latency: `LATENCY = 10` cycles by default
- Issues `dmem_ready` pulse after latency expires
- All pipeline stages stall on any memory access until `dmem_ready`
- Word-aligned: lower 2 address bits ignored (`addr[n-1:2]`)

---

## Instruction Set Architecture (ISA)

### I-Type Instructions

| Mnemonic | op [31:26] | Operation |
|----------|-----------|-----------|
| `LW rt, imm(rs)` | `100011` | `rt ← Mem[rs + SignExt(imm)]` |
| `SW rt, imm(rs)` | `101011` | `Mem[rs + SignExt(imm)] ← rt` |
| `BEQ rs, rt, imm` | `000100` | `if (rs == rt): PC ← PC+4 + SignExt(imm)<<2` |
| `ADDI rt, rs, imm` | `001000` | `rt ← rs + SignExt(imm)` |

All immediates are **sign-extended** from 16 bits to 32 bits.

### J-Type Instructions

| Mnemonic | op [31:26] | Operation |
|----------|-----------|-----------|
| `J target` | `000010` | `PC ← {PC[31:28], target[25:0], 2'b00}` |
| `JAL target` | `000011` | `$ra ← PC+4 ; PC ← {PC[31:28], target[25:0], 2'b00}` |

JAL writes the return address to `$31` (`$ra`). The return value is forwarded through the pipeline via `pcplus4W` and selected by the WB result mux when `jalW` is asserted.

### R-Type Instructions (op = `000000`)

| Mnemonic | funct [5:0] | ALU ctrl | Operation | Timing |
|----------|------------|----------|-----------|--------|
| `ADD rd, rs, rt` | `100000` | `0010` | `rd ← rs + rt` | Combinational |
| `SUB rd, rs, rt` | `100010` | `0110` | `rd ← rs − rt` | Combinational |
| `AND rd, rs, rt` | `100100` | `0000` | `rd ← rs & rt` | Combinational |
| `OR rd, rs, rt` | `100101` | `0001` | `rd ← rs \| rt` | Combinational |
| `SLT rd, rs, rt` | `101010` | `0111` | `rd ← (rs < rt) ? 1 : 0` (signed) | Combinational |
| `MULT rs, rt` | `011000` | `1000` | `{HI, LO} ← rs × rt` | **Latches on negedge clk** |
| `DIV rs, rt` | `011010` | `1001` | `LO ← rs / rt ; HI ← rs % rt` | **Latches on negedge clk** |
| `MFLO rd` | `010010` | `0100` | `rd ← LO` | Combinational |
| `MFHI rd` | `010000` | `0101` | `rd ← HI` | Combinational |
| `JR rs` | `001000` | — | `PC ← rs` | Combinational |

---

## ALU Control Encoding

| alucontrol [3:0] | Operation | Notes |
|-----------------|-----------|-------|
| `0000` | AND | |
| `0001` | OR | |
| `0010` | ADD | Also used as default/NOP |
| `0011` | NOR | |
| `0100` | MFLO | Returns `HiLo[31:0]` |
| `0101` | MFHI | Returns `HiLo[63:32]` |
| `0110` | SUB | Uses 2's complement adder: `a + ~b + 1` |
| `0111` | SLT | Sign-aware comparison with explicit overflow handling |
| `1000` | MULT | 64-bit result stored to HiLo on **negedge clk** |
| `1001` | DIV | Quotient→LO, Remainder→HI on **negedge clk** |

SUB and SLT both derive from the same combinational subtractor (`condinvb` + carry-in via `alucontrol[2]`). Bit 2 of the ALU control word acts as the invert-and-add-1 signal for 2's complement negation.

---

## Control Signal Reference

Decoded from `maindec.sv`. Control vector: `{regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop[1:0]}`.

| Instruction | regwrite | regdst | alusrc | branch | memwrite | memtoreg | jump | aluop |
|-------------|----------|--------|--------|--------|----------|----------|------|-------|
| R-type | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 10 |
| LW | 1 | 0 | 1 | 0 | 0 | 1 | 0 | 00 |
| SW | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 00 |
| BEQ | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 01 |
| ADDI | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 00 |
| J | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 00 |
| JAL | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 00 |

`jal` and `jr` are decoded as separate combinational signals outside the control vector:
- `jal = (op == 6'b000011)`
- `jr  = (op == 6'b000000) && (funct == 6'b001000)`

---
