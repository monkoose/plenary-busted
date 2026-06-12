local ansi = require("plenary-busted.ansi")
local constants = require("plenary-busted.constants")

---@param p string
---@return string
local function dirname(p)
  return vim.fn.fnamemodify(p, ":h")
end

---@param level number
---@return string
local function get_traceback(level)
  level = level or 3

  local thisdir = dirname(debug.getinfo(1, "Sl").source)
  local debug_info = debug.getinfo(level, "Sl")
  while
    debug_info.what == "C"
    or debug_info.short_src:match("luassert[/\\].*%.lua$")
    or (debug_info.source:sub(1, 1) == "@" and thisdir == dirname(debug_info.source))
  do
    level = level + 1
    debug_info = debug.getinfo(level, "Sl")
  end

  local traceback = debug.traceback("", level)
  local index = traceback:find("\n%s*%[C]")
  return traceback:sub(1, index)
end

-- We are shadowing print so people can reliably print messages
print = function(...)
  for _, v in ipairs({ ... }) do
    io.stdout:write(tostring(v))
    io.stdout:write("\t")
  end

  io.stdout:write("\r\n")
end

local current_description = {}
local current_before_each = {}
local current_after_each = {}

---@param desc string
local function add_description(desc)
  table.insert(current_description, desc)

  return vim.deepcopy(current_description)
end

local function pop_description()
  current_description[#current_description] = nil
end

local function add_new_each()
  current_before_each[#current_description] = {}
  current_after_each[#current_description] = {}
end

local function clear_last_each()
  current_before_each[#current_description] = nil
  current_after_each[#current_description] = nil
end

---@param desc string
---@param func function
local function call_inner(desc, func)
  local desc_stack = add_description(desc)
  add_new_each()
  local ok, msg = xpcall(func, function(msg)
    local traceback = get_traceback(3)
    return msg .. "\n" .. traceback
  end)
  clear_last_each()
  pop_description()

  return ok, msg, desc_stack
end

local M = {}
local results = {}

---@param res table
function M.format_results(res)
  print()
  print(constants.RES_SUCCESS, #res.pass)
  print(constants.RES_FAILED, #res.fail)
  print(constants.RES_ERRORS, #res.errs)
  print()
end

---@param desc string
---@param func function
function M.describe(desc, func)
  results.pass = results.pass or {}
  results.fail = results.fail or {}
  results.errs = results.errs or {}

  describe = M.inner_describe
  local ok, msg, desc_stack = call_inner(desc, func)
  describe = M.describe

  if not ok then
    table.insert(results.errs, {
      descriptions = desc_stack,
      msg = msg,
    })
  end
end

---@param desc string
---@param func function
function M.inner_describe(desc, func)
  local ok, msg, desc_stack = call_inner("> " .. desc, func)

  if not ok then
    table.insert(results.errs, {
      descriptions = desc_stack,
      msg = msg,
    })
  end
end

---@param fn function
function M.before_each(fn)
  table.insert(current_before_each[#current_description], fn)
end

---@param fn function
function M.after_each(fn)
  table.insert(current_after_each[#current_description], fn)
end

---@param msg string
---@param tabs? number
local function indent(msg, tabs)
  tabs = tabs or 1
  local prefix = string.rep("\t", tabs)
  return prefix .. msg:gsub("\n", "\n" .. prefix)
end

---@param tbl table
local function run_each(tbl)
  for _, v in ipairs(tbl) do
    for _, w in ipairs(v) do
      if type(w) == "function" then
        w()
      end
    end
  end
end

---@param desc string
---@param func function
function M.it(desc, func)
  run_each(current_before_each)
  local ok, msg, desc_stack = call_inner("  " .. desc, func)
  run_each(current_after_each)

  local test_result = {
    descriptions = desc_stack,
    msg = nil,
  }

  local to_insert
  if not ok then
    to_insert = results.fail
    test_result.msg = msg

    local separator = string.rep("-", 29)
    local separator_open = ansi.format(ansi.RED, indent(">" .. separator, 2))
    local separator_close = ansi.format(ansi.RED, indent(separator .. "<", 2))
    print(constants.FAIL, "", table.concat(test_result.descriptions, " "))
    print(separator_open)
    print(indent(msg, 2))
    print(separator_close)
  else
    to_insert = results.pass
    print(constants.SUCCESS, table.concat(test_result.descriptions, " "))
  end

  table.insert(to_insert, test_result)
end

---@param desc string
function M.pending(desc)
  local curr_stack = vim.deepcopy(current_description)
  table.insert(curr_stack, desc)
  print(constants.PENDING, table.concat(curr_stack, " "))
end

_PlenaryBustedOldAssert = _PlenaryBustedOldAssert or assert

describe = M.describe
it = M.it
pending = M.pending
before_each = M.before_each
after_each = M.after_each
assert = require("luassert")

---@param file string
M.run = function(file)
  file = file:gsub("\\", "/")

  print()
  print(constants.DOUBLE_LINE)
  print(ansi.format(ansi.BOLD, " " .. file))
  print(constants.SINGLE_LINE)

  local loaded, err = loadfile(file)
  if err then
    print(ansi.format(ansi.RED, "Error: FAILED TO LOAD FILE"))
    print(err)
    print()
    return vim.cmd.cquit(3)
  end

  loaded() ---@diagnostic disable-line: need-check-nil

  -- When nothing was run (empty file without top level describe)
  if not results.pass then
    print(" Tests are empty.")
    return vim.cmd.cquit(0)
  end

  M.format_results(results)

  if #results.errs > 0 then
    print(ansi.format(ansi.RED, "Unexpected Error: "))
    print(vim.inspect(results.errs), vim.inspect(results))
    print()
    return vim.cmd.cquit(2)
  elseif #results.fail > 0 then
    return vim.cmd.cquit(1)
  end

  return vim.cmd.cquit(0)
end

return M
