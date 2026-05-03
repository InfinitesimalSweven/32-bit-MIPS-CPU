PROJECT_NAME=pipelined_cpu
SRCS=tb_computer.sv
VVPOPTS=-s tb_computer
# Default assembly program if none is specified
ASM ?= loop_test
PROG_DIR = ../programs
TOOLS_DIR = ../tools

# Default cache state (1=enabled, 0=disabled)
CACHE_EN ?= 1

all: clean check_asm asm compile run

check_asm:
	@if [ ! -f $(PROG_DIR)/$(ASM).asm ]; then \
		echo "ERROR: Assembly file '$(PROG_DIR)/$(ASM).asm' not found!"; \
		echo "Available test files in $(PROG_DIR):"; \
		ls -1 $(PROG_DIR)/*.asm | sed "s|$(PROG_DIR)/||" | sed 's/\.asm//'; \
		exit 1; \
	fi

compile:
	iverilog -g2012 -o $(PROJECT_NAME).vvp $(SRCS)

run:
	vvp $(PROJECT_NAME).vvp +PROG=$(PROG_DIR)/$(ASM).exe +CACHE_EN=$(CACHE_EN) > debug_output.txt
	@echo "\nSimulation complete! Summary metrics are displayed above."
	@echo "Check debug_output.txt for cycle-by-cycle logs."

asm:
	python3 $(TOOLS_DIR)/assembler.py $(PROG_DIR)/$(ASM).asm $(PROG_DIR)/$(ASM).exe

test_exceptions: clean
	@echo "Running Exception Testbench..."
	python3 $(TOOLS_DIR)/assembler.py $(PROG_DIR)/test_exceptions.asm $(PROG_DIR)/test_exceptions.exe
	iverilog -g2012 -o exceptions.vvp tb_exceptions.sv
	vvp exceptions.vvp +PROG=$(PROG_DIR)/test_exceptions.exe > debug_output.txt
	@echo "\nSimulation complete! Check debug_output.txt for cycle-by-cycle logs."

clean:
	rm -f *.vvp *.vcd debug_output.txt