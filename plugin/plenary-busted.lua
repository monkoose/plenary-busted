local api = vim.api
local expand = vim.fn.expand

api.nvim_create_user_command("PlenaryBusted", function(opts)
  local path, test_opts
  if #opts.fargs == 0 then
    path = expand("%")
  else
    path = expand(table.remove(opts.fargs, 1))
    test_opts = assert(loadstring("return " .. table.concat(opts.fargs, " ")))()
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  require("plenary-busted.test_harness").test(path, test_opts)
end, {
  nargs = "*",
  complete = "file",
  desc = "Run a single test file or a directory of test files.",
})

vim.keymap.set("n", "<Plug>PlenaryBustedFile", function()
  require("plenary-busted.test_harness").test(expand("%"))
end)

local augroup = api.nvim_create_augroup("PlenaryBusted", {})

local function set_highlights()
  api.nvim_set_hl(0, "PlenaryBustedWhite", {
    fg = "#b0b0b0",
    bg = "#303030",
    ctermfg = 7,
    ctermbg = 235,
    default = true,
  })
  api.nvim_set_hl(0, "PlenaryBustedGreen", {
    fg = "#70d070",
    bg = "#303030",
    ctermfg = 2,
    ctermbg = 235,
    default = true,
  })
  api.nvim_set_hl(0, "PlenaryBustedRed", {
    fg = "#d07070",
    bg = "#303030",
    ctermfg = 1,
    ctermbg = 235,
    default = true,
  })
end

api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = set_highlights,
})

if vim.v.vim_did_enter == 1 then
  set_highlights()
else
  api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    once = true,
    callback = function()
      set_highlights()
    end,
  })
end
