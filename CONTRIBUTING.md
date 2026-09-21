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

### How the pointer stays current

A submodule pointer is a recorded SHA — git has no floating reference, so
"track the latest" has to mean "something commits the new SHA promptly". Here
that is automatic: every push to nanoriscv's `main` pings this repository
(`notify-nanocodex.yml` there, `sync-nanoriscv.yml` here), which bumps the
pointer and commits it, usually within a minute. A daily schedule catches
anything the ping misses.

The recorded SHA is still a real pin, so checking out an old nanocodex commit
recursively gets you the nanoriscv it was built against. Only the tip moves on
its own.

To move it yourself:

```
make sync-nanoriscv
```

Both the workflow and that target refuse to move the pointer **backward** —
they require the old SHA to be an ancestor of the new one. Without that check,
a force-push or a revert in nanoriscv would silently rewind this repository.
