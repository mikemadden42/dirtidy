# dirtidy

Show files by extension in Swift.

`dirtidy` lists the files in a directory grouped by extension. Files without
an extension come first, then extensions alphabetically. Subdirectories and
symlinks to directories are skipped.

## Usage

```
Usage: dirtidy [-a|--all] [-h|--help] [path]
  -a, --all   Include hidden files (those starting with '.')
  -h, --help  Show this help message
  path        Directory to inspect (default: current directory)
```

Example:

```
$ dirtidy
No Extension:
- LICENSE
- Makefile

md:
- README.md

sh:
- build.sh

swift:
- dirtidy.swift
```

Errors go to stderr. A missing path, a path that isn't a directory, or an
unreadable directory exits with status 1; an unknown option or extra argument
exits with status 2.

## Building

Requires a Swift toolchain (`swiftc`) on your `PATH`.

```
make        # build ./dirtidy
make clean  # remove the binary
```

On macOS, `make` builds a stripped universal binary (x86_64 and arm64). On
Linux, it builds a stripped native binary.
