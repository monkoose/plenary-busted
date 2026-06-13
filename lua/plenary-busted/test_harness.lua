local ansi = require("plenary-busted.ansi")
local constants = require("plenary-busted.constants")

local api = vim.api
local fn = vim.fn

local HEADLESS = #api.nvim_list_uis() == 0
local plenary_busted_dir = fn.fnamemodify(debug.getinfo(1).source:match("@?(.*[/\\])"), ":p:h:h:h")

local M = {}

local function print_output(_, ...)
  for _, v in ipairs({ ... }) do
    io.stdout:write(tostring(v))
  end
end

local function nvim_outputter(job_id)
  return function(bufnr, ...)
    if api.nvim_buf_is_valid(bufnr) then
      for _, v in ipairs({ ... }) do
        api.nvim_chan_send(job_id, v)
      end
    end
  end
end

---@param directory string
---@return string[]
local function find_test_files(directory)
  local test_files = vim.fs.find(function(name)
    return name:match(".*_spec%.lua$")
  end, {
    path = directory,
    type = "file",
    limit = math.huge,
  })
  return test_files
end

--- Create window that takes up certain percentags of the current screen.
---@param col_range number # center the window taking up this percentage of the screen.
---@param row_range number # center the window taking up this percentage of the screen.
local function open_floating_window(col_range, row_range)
  local win_opts = {
    relative = "editor",
    row = math.ceil(vim.o.lines * (1 - row_range) / 2),
    col = math.floor(vim.o.columns * (1 - col_range) / 2),
    width = math.floor(vim.o.columns * col_range),
    height = math.ceil(vim.o.lines * row_range),
    title = " BustedTest ",
    title_pos = "center",
    style = "minimal",
  }

  local bufnr = api.nvim_create_buf(false, true)
  local win_id = api.nvim_open_win(bufnr, true, win_opts)
  return bufnr, win_id
end

---@param winid integer
---@param summary table
local function set_winbar(winid, summary)
  local winbar = {}
  table.insert(winbar, string.format(" %%#PlenaryBustedWhite# %s %%* ", summary.status))
  table.insert(winbar, string.format(" %%#PlenaryBustedGreen# Success: %d %%* ", summary.pass))
  table.insert(winbar, string.format(" %%#PlenaryBustedRed# Failed: %d %%* ", summary.fail))
  table.insert(winbar, string.format(" %%#PlenaryBustedRed# Errors: %d %%* ", summary.errs))
  api.nvim_set_option_value("winbar", table.concat(winbar, ""), { win = winid })
  api.nvim__redraw({ win = winid, winbar = true })
end

---@param files string[]
---@param opts? table
local function test_files(files, opts)
  if #files == 0 then
    vim.notify("No test files found.", vim.log.levels.WARN)
    if HEADLESS then
      vim.notify("\n")
      vim.cmd.cquit(0)
    end
    return
  end

  opts = vim.tbl_deep_extend("force", {
    nvim_cmd = vim.v.progpath,
    keep_going = true,
    timeout = 50000,
  }, opts or {})

  local bufnr, winid
  local outputter = print_output
  local failure = false
  local summary = { status = "Running ", pass = 0, fail = 0, errs = 0 }

  if not HEADLESS then
    bufnr, winid = open_floating_window(0.8, 0.7)
    local job_id = api.nvim_open_term(bufnr, {})
    outputter = nvim_outputter(job_id)

    api.nvim_buf_set_keymap(bufnr, "n", "q", ":q<CR>", { silent = true })

    api.nvim_set_option_value("winhl", "WinBar:Normal", { win = winid })
    api.nvim_set_option_value("conceallevel", 3, { win = winid })
    api.nvim_set_option_value("concealcursor", "n", { win = winid })
    api.nvim_set_option_value("filetype", "PlenaryBustedPopup", { buf = bufnr })
    set_winbar(winid, summary)
  end

  local args = {
    opts.nvim_cmd,
    "--headless",
    "-c",
    "set rtp+=.," .. fn.escape(plenary_busted_dir, " "),
  }
  local minimal = not opts.init or opts.minimal or opts.minimal_init
  if minimal then
    table.insert(args, "--noplugin")
    if opts.minimal_init then
      table.insert(args, "-u")
      table.insert(args, opts.minimal_init)
    end
  elseif opts.init ~= nil then
    table.insert(args, "-u")
    table.insert(args, opts.init)
  end
  table.insert(args, "-c")

  -- Scheduling will open a window in not HEADLESS, before processing test files
  vim.schedule(function()
    for _, file in ipairs(files) do
      local cmd = vim.deepcopy(args)
      table.insert(
        cmd,
        string.format(
          'lua require("plenary-busted").run("%s")',
          vim.fs.abspath(file):gsub("\\", "\\\\")
        )
      )

      local out = vim.system(cmd, { text = true }):wait(opts.timeout)

      outputter(bufnr, out.stderr)
      outputter(bufnr, out.stdout)

      -- Failed to load file
      if out.code == 3 then
        summary.errs = summary.errs + 1
      else
        if out.code == 2 then
          local e = out.stdout:match(constants.ERRORS_PATTERN)
          if e then
            summary.errs = summary.errs + tonumber(e)
          end
        end
        local s = out.stdout:match(constants.SUCCESS_PATTERN)
        if s then
          summary.pass = summary.pass + tonumber(s)
        end
        local f = out.stdout:match(constants.FAILED_PATTERN)
        if f then
          summary.fail = summary.fail + tonumber(f)
        end
      end

      if not HEADLESS then
        set_winbar(winid, summary)
      end

      if out.code ~= 0 or out.signal ~= 0 then
        failure = true
        if not opts.keep_going then
          break
        end
      end
    end

    if HEADLESS then
      -- Add summary for multiple files
      if #files > 1 then
        outputter(bufnr, "\n", constants.DOUBLE_LINE, "\n")
        outputter(bufnr, ansi.format(ansi.BOLD, " SUMMARY"), "\n")
        outputter(bufnr, constants.SINGLE_LINE, "\n")
        outputter(bufnr, string.format(constants.RES_SUCCESS .. "\t%d\n", summary.pass))
        outputter(bufnr, string.format(constants.RES_FAILED .. "\t%d\n", summary.fail))
        outputter(bufnr, string.format(constants.RES_ERRORS .. "\t%d\n\n", summary.errs))
      end

      if failure then
        vim.cmd.cquit(1)
      else
        vim.cmd.cquit(0)
      end
    else
      summary.status = "Finished"
      set_winbar(winid, summary)
    end
  end)
end

---@param path string
---@param opts? table
function M.test(path, opts)
  if fn.isdirectory(path) == 1 then
    local files = find_test_files(path)
    test_files(files, opts)
  elseif fn.filereadable(path) == 1 then
    test_files({ vim.fs.normalize(path) }, opts)
  else
    vim.notify(string.format(" Path '%s' does not exist.", path), vim.log.levels.WARN)
    if HEADLESS then
      vim.notify("\n")
      vim.cmd.cquit(1)
    end
  end
end

return M
