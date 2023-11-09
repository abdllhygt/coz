# [GLOB](glob.red)

Allows you to recursively list files.

**Features:**
- non-recursive implementation won't blow the stack
- thoroughly tested against 100-item paths, should work with 32'000-item paths on Windows once Red gets to UNC support and with up to 2'000-item paths on \*nix (you can test it with `glob-test.red` but be aware that it creates a very deep directory tree)
- allows filtering with inclusive and exclusive masks (supports multiple masks as well)
- masks support `*` and `?` wildcards but no `[]` charsets (do we need that?)

**Usage:**

See `? glob` generally ;)

Some examples:
- `glob` to get a list of all files in all subdirectories of current working directory (CWD)
- `glob/limit 0` - do not recurse
- `glob/only/files "*.red"` - list only `.red` files (and no directories names "something.red/")
- `glob/only/files/omit ["*.red" "*.reds"] "*-test.*"` - list only Red & R/S scripts, excluding tests

**Notes:**
- returned filenames are relative to the given *root* directory (to save RAM)
- how masking works: list all files, then exclude those not matching imask(s), then exclude also those matching xmask(s)
- see comments `glob.red` for some OS limitations and tips

