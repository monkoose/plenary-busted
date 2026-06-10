local ansi = require("plenary-busted.ansi")

local RES_SUCCESS = ansi.format(ansi.GREEN, " Success: ")
local RES_FAILED = ansi.format(ansi.RED, " Failed:  ")
local RES_ERRORS = ansi.format(ansi.RED, " Errors:  ")

return {
  SUCCESS = ansi.format(ansi.GREEN, " Success"),
  FAIL = ansi.format(ansi.RED, " Fail"),
  PENDING = ansi.format(ansi.YELLOW, " Pending"),
  DOUBLE_LINE = string.rep("=", 50),
  SINGLE_LINE = string.rep("-", 50),
  RES_SUCCESS = RES_SUCCESS,
  RES_FAILED = RES_FAILED,
  RES_ERRORS = RES_ERRORS,
  SUCCESS_PATTERN = RES_SUCCESS:gsub("%[", "%%[") .. "\t(%d+)",
  FAILED_PATTERN = RES_FAILED:gsub("%[", "%%[") .. "\t(%d+)",
  ERRORS_PATTERN = RES_ERRORS:gsub("%[", "%%[") .. "\t(%d+)",
}
