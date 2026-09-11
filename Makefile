BOARD ?= zcu104
PROJ  ?= hello_world

PROJ_DIR  := projects/$(PROJ)
BOARD_DIR := boards/$(BOARD)

.PHONY: build program clean new

build:
	vivado -mode batch -source scripts/build.tcl -tclargs $(PROJ_DIR) $(BOARD_DIR) $(PROJ)

program:
	vivado -mode batch -source scripts/program.tcl -tclargs $(PROJ_DIR)/build/$(PROJ).bit

clean:
	rm -rf $(PROJ_DIR)/build

new:
	scripts/new_project.sh $(PROJ)
