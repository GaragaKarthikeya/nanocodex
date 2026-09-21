# Contributing

## What you need

Most of this repository cannot be exercised without hardware:

- **Vivado** (2026.1 is what the scripts assume) for `make build` and
  `make program`. It is not installable in CI, so synthesis is never
  automatically verified — only the automation around it is.
- **A ZCU104**, physically attached, for `make program`. Programming is always
  local; only building can be offloaded.

Without either, you can still change and review the scripts, the board
definitions and the docs, which is most of what lives here.

## Before opening a pull request

```
shellcheck scripts/*.sh
for f in scripts/*.sh; do bash -n "$f"; done
make new PROJ=smoke_test && rm -rf projects/smoke_test
```

CI runs exactly these.

## Remote builds

`scripts/remote_build.sh` and `scripts/remote_status.sh` require `REMOTE_HOST`
and `REMOTE_USER` and fail with instructions if they are unset. Please keep it
that way — these once defaulted to one specific workstation, which is a
portability bug and a privacy leak at the same time.

## Adding a board

**Before typing a single pin number out of a PDF: don't.** Board manuals get
things wrong more often than you would expect, and
`boards/zcu104/docs/errata.md` documents a real case that cost hours here. The
order of trust is in the README, and it matters more than any other convention
in this repository.

Whatever you find, write it down in `boards/<board>/docs/errata.md` in the same
format, so the next project on that board does not rediscover it.

## Relationship to nanoriscv

The RISC-V core this workstation exists to run lives in a separate repository,
[nanoriscv](https://github.com/GaragaKarthikeya/nanoriscv), tracked here as a
submodule. Emulator and RTL changes belong there; board bring-up, constraints
and build automation belong here.

Clone with `--recursive`, or run `git submodule update --init` afterwards.
