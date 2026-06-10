---@alias AnsiCode integer

local M = {
  BOLD = 1, ---@type AnsiCode
  RED = 31, ---@type AnsiCode
  GREEN = 32, ---@type AnsiCode
  YELLOW = 33, ---@type AnsiCode
}

---@param code AnsiCode
---@param str string
---@return string
function M.format(code, str)
  return string.format("%s[%sm%s%s[%sm", string.char(27), code, str, string.char(27), 0)
end

return M
