<h1 align="center">plenary-busted</h1>

Extracted test harness from [plenary.nvim]

It was cleaned of the legacy dependencies of [plenary.nvim], like Job, Path etc.

Changes from test harness of plenary.nvim:
- Added summary for test results
- Added `winbar` for floating window
- Removed asynchronous running of tests (read this as `sequential` option is always enabled).
- Renamed `<Plug>PlenaryTestFile` to `<Plug>PlenaryBustedFile`

---

### Usage

Supports (simple) busted-style testing. It implements a mock-ed busted interface, that will allow you to run simple
busted style tests in separate neovim instances.

To run the current spec file in a floating window, you can use the keymap `<Plug>PlenaryBustedFile`. For example:

```
nmap <leader>t <Plug>PlenaryBustedFile
```
or in lua

```lua
vim.keymap.set('n', '<leader>t', '<Plug>PlenaryBustedFile')
```

In this case, the test is run with a minimal configuration, that includes in
its runtimepath only `plenary-busted` and the current working directory.

To run a whole directory from the command line, you could do something like:

```
nvim --headless -c "PlenaryBustedDirectory tests/plenary/ {options}"
```

Where the first argument is the directory you'd like to test. It will search for files with
the pattern `*_spec.lua` and execute them in separate neovim instances.

Without second argument, `PlenaryBustedDirectory` is also run with a minimal
configuration. Otherwise it is a Lua option table with the following fields:
- `nvim_cmd`: specify the command to launch this neovim instance (defaults to `vim.v.progpath`)
- `init`: specify an init.vim to use for this instance
- `minimal_init`: as for `init`, but also run the neovim instance with `--noplugin`
- `keep_going`: if `sequential`, whether to continue on test failure (default true)
- `timeout`: controls the maximum time allotted to each job in parallel or
  sequential operation (defaults to 50,000 milliseconds)

The exit code is 0 when success and 1 when fail, so you can use it easily in a `Makefile`!

NOTE:

Supported busted items are:

- `describe`
- `it`
- `pending`
- `before_each`
- `after_each`
- `clear`
- `assert.*` etc. (from luassert, which is bundled)

---

### TODO

- [ ] Populate quickfix list with failed tests

---

### License

MIT license

[plenary.nvim]: https://github.com/nvim-lua/plenary.nvim
