# Authors

## Contributors

| Name | GitHub / Email |
|------|---------------|
| Natesh Garg | `InfinitesimalSweven` · natgarg132@gmail.com |
| Tanzeem Hasan | tanzeem.hasan@cooper.edu |

---

## Contributions by area

### SystemVerilog source (`pipelined_cache_computer/src/`)

| File | Primary author | Notes |
|------|---------------|-------|
| `computer.sv` | Natesh Garg | Initial implementation; updated by both authors across multiple commits |
| `cpu.sv` | Tanzeem Hasan | JAL/JR support added; further fixes by Natesh |
| `datapath.sv` | Tanzeem Hasan | All five pipeline stages, pipeline registers, forwarding muxes; JAL/JR additions; major rework by Natesh for program 3 |
| `controller.sv` | Tanzeem Hasan | JAL/JR control signals added |
| `maindec.sv` | Tanzeem Hasan | JAL/JR opcode decoding added |
| `aludec.sv` | Tanzeem Hasan | Minor fix |
| `hazard.sv` | Tanzeem Hasan | JAL forwarding support added; major rework by Natesh for program 3 |
| `cache_direct_mapped.sv` | Natesh Garg | Full implementation |
| `cache_set_associative.sv` | Natesh Garg | Full implementation (later replaced by fully-associative) |
| `cache_fully_associative.sv` | Natesh Garg | Full implementation; selected as active cache in final design |
| `dmem.sv` | Tanzeem Hasan | Latency-modeled data memory |
| `imem.sv` | Tanzeem Hasan | Instruction ROM |
| `alu.sv` | Tanzeem Hasan | 32-bit ALU |
| `regfile.sv` | Tanzeem Hasan | 32×32 register file |
| `adder.sv` | Natesh Garg | Parameterized adder |
| `mux2.sv` / `mux3.sv` / `mux4.sv` | Natesh Garg | Parameterized multiplexers |
| `signext.sv` | Natesh Garg | 16→32 sign extension |
| `sl2.sv` | Natesh Garg | Shift-left-by-2 for branch offset |
| `dff.sv` | Natesh Garg | D flip-flop; minor fix in program-3 rework |
| `flopenr.sv` / `flopenrc.sv` | Natesh Garg | Pipeline register primitives |
| `eqcmp.sv` | Natesh Garg | BEQ equality comparator |
| `clock.sv` | Natesh Garg | Testbench clock generator |
| `mem.sv` | Tanzeem Hasan | Generic memory primitive |
| `_timescale.sv` | Natesh Garg | Global timescale |

---

### Testbenches (`pipelined_cache_computer/tb/`)

| File | Author | Notes |
|------|--------|-------|
| `tb_computer.sv` | Tanzeem Hasan | Top-level computer testbench; updated by Natesh for program 3 |
| `tb_cpu.sv` | Natesh Garg | CPU-level testbench |
| `tb_datapath.sv` | Natesh Garg | Datapath testbench |
| `tb_hazard.sv` | Natesh Garg | Hazard unit testbench; minor fix by Natesh |
| `tb_controller.sv` | Natesh Garg | Controller testbench |
| `tb_maindec.sv` | Natesh Garg | Main decoder testbench |
| `tb_aludec.sv` | Natesh Garg | ALU decoder testbench |
| `tb_alu.sv` | Natesh Garg | ALU testbench |
| `tb_regfile.sv` | Natesh Garg | Register file testbench |
| `tb_cache_direct_mapped.sv` | Natesh Garg | Direct-mapped cache testbench |
| `tb_cache_set_associative.sv` | Natesh Garg | Set-associative cache testbench (removed in final commit) |
| `tb_cache_fully_associative.sv` | Natesh Garg | Fully-associative cache testbench (removed in final commit) |
| `tb_adder.sv` | Tanzeem Hasan | Adder testbench |
| `tb_dmem.sv` | Natesh Garg | Data memory testbench |
| `tb_imem.sv` | Natesh Garg | Instruction memory testbench |
| `tb_exceptions.sv` | Natesh Garg | Exception handling testbench |
| `tb_clock.sv` | Natesh Garg | Clock testbench |
| `tb_mem.sv` | Natesh Garg | Memory testbench |
| `tb_mux2.sv` / `tb_mux3.sv` / `tb_mux4.sv` | Natesh Garg | Mux testbenches |
| `tb_flopenr.sv` / `tb_flopenrc.sv` | Natesh Garg | Flip-flop testbenches |
| `tb_signext.sv` | Natesh Garg | Sign-extension testbench |
| `tb_sl2.sv` | Natesh Garg | Shift-left-2 testbench |
| `tb_dff.sv` | Natesh Garg | D flip-flop testbench |
| `tb_eqcmp.sv` | Natesh Garg | Equality comparator testbench |

---

### Test programs (`programs/`)

| File | Author | Notes |
|------|--------|-------|
| `prog_0_simple.asm` / `.exe` | Tanzeem Hasan | Simple sequential program; assembled and verified |
| `prog_1_leaf.asm` / `.exe` | Tanzeem Hasan | Leaf function call (JAL/JR); assembled by Natesh |
| `prog_2_nested.asm` / `.exe` | Tanzeem Hasan | Nested function calls; final `.exe` produced by Natesh |
| `prog_3_recursive.asm` / `.exe` | Tanzeem Hasan | Recursive function; working execution confirmed by Natesh |
| `prog_rtype.asm` | Tanzeem Hasan | R-type instruction timing test |
| `prog_itype.asm` | Tanzeem Hasan | I-type instruction timing test |
| `prog_jtype.asm` | Tanzeem Hasan | J-type instruction timing test |

---

### Documentation & diagrams

| File | Author | Notes |
|------|--------|-------|
| `README.md` | Natesh Garg | Initial draft ("Made and added readMe"); sections added and restructured by Tanzeem Hasan; TOC fix by Tanzeem |
| `diagrams/mips_cpu_pipeline_diagram.svg` | Tanzeem Hasan | Full pipeline datapath diagram |
| `diagrams/mips_memory_hierarchy_diagram.svg` | Tanzeem Hasan | Memory and cache hierarchy diagram |
| `diagrams/rtype_timing.png` | Tanzeem Hasan | R-type instruction timing diagram |
| `diagrams/itype_timing.png` | Tanzeem Hasan | I-type instruction timing diagram |
| `diagrams/jtype_timing.png` | Tanzeem Hasan | J-type instruction timing diagram |

---

### Tools

| File | Author | Notes |
|------|--------|-------|
| `tools/assembler.py` | Natesh Garg | MIPS assembler (noted as "hard to implement"); initially committed as `patch.py`, later cleaned up and moved to `tools/` by Tanzeem Hasan |
| `pipelined_cache_computer/Makefile` | Tanzeem Hasan | Build system; updated by Natesh |