<h1 align="center">plenary-busted</h1>

Extracted test harness from [plenary.nvim]

It was cleaned of the legacy dependencies of [plenary.nvim], like Job, Path etc.

> [!IMPORTANT]
> Changes compared to the test harness of plenary.nvim:
> - Combined `:PlenaryBustedFile` and `PlenaryBustedDirectory` into one `:PlenaryBusted` command.
> - Renamed `<Plug>PlenaryTestFile` to `<Plug>PlenaryBustedFile`
> - Added summary for test results
> - Added `winbar` for the floating window
> - Removed asynchronous running of tests (read this as `sequential` option is always enabled).
> - Removed global `clear()` function. Just use api directly with `vim.api.nvim_buf_set_lines(0, 0, -1, false, {})` if you need it.

---

### Installation

With vim.pack (Neovim 0.12+):

```lua
vim.pack.add({ 'https://github.com/monkoose/plenary-busted' })
```

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ 'monkoose/plenary-busted' },
```

---

### Usage

`plenary-busted` provides a (simple) busted-style testing framework. It implements a
mocked busted interface that allows you to run simple busted-style tests
in separate Neovim instances.

Supported busted items are:
- `describe`
- `it`
- `pending`
- `before_each`
- `after_each`
- `assert.*` etc. (from luassert, which is bundled)

You can learn how to use them in [plenary-busted-testing] vimdoc help file.

The plugin adds `:PlenaryBusted` user command.

<details>
<summary><b>User command help</b></summary>

#### To run the current spec file in a floating window

Use `:PlenaryBusted` command without arguments or add the keymap `<Plug>PlenaryBustedFile`. For example:

```lua
vim.keymap.set('n', '<leader>t', '<Plug>PlenaryBustedFile')
```

In this case, the test is run with a minimal configuration, that includes in
its runtimepath only `plenary-busted` and the current working directory.

Or you can specify a filename to test with `:PlenaryBusted {path/to/file} {options}`.

#### To run a whole directory

Use `:PlenaryBusted {path/to/directory} {options}` command.

Where the first argument is the directory you would like to test. It will
search for files matching the pattern `*_spec.lua` and execute them in separate
Neovim instances.

Without second argument, `PlenaryBusted` is also run with a minimal
configuration. Otherwise it is a Lua option table with the following fields:
- `init`: specify an init.lua to use for this instance
- `minimal_init`: as for `init`, but also run the Neovim instance with `--noplugin`
- `nvim_cmd`: specify the command to launch this Neovim instance (defaults to `vim.v.progpath`)
- `keep_going`: whether to continue on test failure (default true)
- `timeout`: controls the maximum time allotted to each job in parallel or
  sequential operation (defaults to 50,000 milliseconds)

Or run it from command line:

```
nvim --headless -c "PlenaryBusted path/to/tests/dir {options}"
```

The exit code is `0` when success and `1` when any test fail, so you can use it
easily in a `Makefile`.

</details>

### Highlights

To configure winbar highlights you can change these groups:
- `PlenaryBustedWhite`
- `PlenaryBustedGreen`
- `PlenaryBustedRed`

---

### FAQ

<details>
<summary><b>How to test your plugin with GitHub Actions?</b></summary>

Create `Makefile` in your plugin's root directory:

```make
test:
	nvim --headless -c "PlenaryBusted tests { keep_going = false }"
```

Or you can omit creating `Makefile` and use `nvim --headless -c "PlenaryBusted
tests { keep_going = false }"` directly in the `tests.yml`.

Create `.github/workflows/tests.yml` (adjust `nvim-version` for your plugin
requirements):

```yaml
name: Tests

on: [ push, pull_request ]

jobs:
  tests:
    name: unit tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        nvim-version: [ v0.11.0, stable, nightly ]
    steps:
      - uses: actions/checkout@v6
      - uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: ${{ matrix.nvim-version }}
      - name: Install plenary-busted plugin
        run: |
          git clone --depth=1 https://github.com/monkoose/plenary-busted ~/.local/share/nvim/site/pack/test-workflow/start/plenary-busted
      - name: Run tests
        run: |
          make test
```

</details>

<details>
<summary><b>How to make Lua LSP know about `plenary-busted` (to fix diagnostics warnings)?</b></summary>

Create `.luarc.json` in your plugin's root directory:

```json
{
  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  "runtime.version": "LuaJIT",
  "workspace": {
    "library": [
      "lua",
      "$VIMRUNTIME/lua",
      "${3rd}/busted/library",
      "${3rd}/luassert/library"
    ],
    "checkThirdParty": false
  }
}
```

</details>

---

### TODO

- [ ] Populate quickfix list with failed tests

---

### License

MIT license

[plenary.nvim]: https://github.com/nvim-lua/plenary.nvim
[plenary-busted-testing]: https://github.com/monkoose/plenary-busted/blob/main/doc/plenary-busted-testing.txt
