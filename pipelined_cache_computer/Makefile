PROJECT_NAME=pipelined_cpu
SRCS=src/*.sv
# Default assembly program if none is specified
ASM ?= prog_0_simple
PROG_DIR = ../programs
TOOLS_DIR = ../tools

# Default cache state (1=enabled, 0=disabled)
CACHE_EN ?= 1

# Individual components
COMPONENTS = alu adder aludec controller datapath hazard regfile maindec \
             cache_direct_mapped \
             cpu dff dmem eqcmp flopenr flopenrc \
             imem mem mux2 mux3 mux4 signext sl2

all: clean check_asm asm compile run

check_asm:
	@if [ ! -f $(PROG_DIR)/$(ASM).asm ]; then \
		echo "ERROR: Assembly file '$(PROG_DIR)/$(ASM).asm' not found!"; \
		echo "Available test files in $(PROG_DIR):"; \
		ls -1 $(PROG_DIR)/*.asm | sed "s|$(PROG_DIR)/||" | sed 's/\.asm//'; \
		exit 1; \
	fi

compile:
	iverilog -g2012 -I src -o $(PROJECT_NAME).vvp tb/tb_computer.sv $(SRCS)

run:
	vvp $(PROJECT_NAME).vvp +PROG=$(PROG_DIR)/$(ASM).exe +CACHE_EN=$(CACHE_EN) > debug_output.txt
	@echo "\nSimulation complete! Summary metrics are displayed above."
	@echo "Check debug_output.txt for cycle-by-cycle logs."

asm:
	python3 $(TOOLS_DIR)/assembler.py $(PROG_DIR)/$(ASM).asm $(PROG_DIR)/$(ASM).exe

# Individual component testbenches: make alu, make hazard, etc.
$(COMPONENTS): clean
	iverilog -g2012 -I src -o tb_$@.vvp tb/tb_$@.sv $(SRCS)
	vvp tb_$@.vvp > debug_output.txt
	@echo "\nDone! Check debug_output.txt for output."

test_exceptions: clean
	@echo "Running Exception Testbench..."
	python3 $(TOOLS_DIR)/assembler.py $(PROG_DIR)/test_exceptions.asm $(PROG_DIR)/test_exceptions.exe
	iverilog -g2012 -I src -o exceptions.vvp tb/tb_exceptions.sv $(SRCS)
	vvp exceptions.vvp +PROG=$(PROG_DIR)/test_exceptions.exe > debug_output.txt
	@echo "\nSimulation complete! Check debug_output.txt for cycle-by-cycle logs."

clean:
	rm -f *.vvp *.vcd debug_output.txt