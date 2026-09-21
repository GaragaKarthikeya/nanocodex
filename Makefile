BOARD ?= zcu104
PROJ  ?= hello_world

PROJ_DIR  := projects/$(PROJ)
BOARD_DIR := boards/$(BOARD)

.PHONY: build remote-build remote-status program clean new sync-nanoriscv

build:
	vivado -mode batch -source scripts/build.tcl -tclargs $(PROJ_DIR) $(BOARD_DIR) $(PROJ)

remote-build:
	scripts/remote_build.sh $(PROJ_DIR) $(BOARD_DIR) $(PROJ)

remote-status:
	scripts/remote_status.sh $(PROJ_DIR)

program:
	vivado -mode batch -source scripts/program.tcl -tclargs $(PROJ_DIR)/build/$(PROJ).bit

clean:
	rm -rf $(PROJ_DIR)/build

new:
	scripts/new_project.sh $(PROJ)

# Move the nanoriscv pointer to whatever its main branch is now. CI does this
# automatically on every nanoriscv push; this is for when you want it now, or
# are working offline from the automation.
sync-nanoriscv:
	@before=$$(git rev-parse HEAD:nanoriscv); \
	git submodule update --remote --force nanoriscv; \
	after=$$(git -C nanoriscv rev-parse HEAD); \
	short_b=$$(echo "$$before" | cut -c1-7); \
	short_a=$$(echo "$$after" | cut -c1-7); \
	if [ "$$before" = "$$after" ]; then \
		echo "nanoriscv already current at $$short_b"; \
		exit 0; \
	fi; \
	if ! git -C nanoriscv merge-base --is-ancestor "$$before" "$$after"; then \
		echo "refusing: $$short_b is not an ancestor of $$short_a" >&2; \
		echo "nanoriscv main was rewritten or rewound -- bump by hand" >&2; \
		git submodule update --force nanoriscv; \
		exit 1; \
	fi; \
	git add nanoriscv; \
	git commit -q -m "Bump nanoriscv to $$short_a" \
	           -m "$$(git -C nanoriscv log -1 --pretty=%s)"; \
	echo "bumped $$short_b -> $$short_a"
