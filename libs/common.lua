local M = {}

M.HASHES = require "libs.hashes"
M.MSG = require "libs.msg_receiver"
M.CLASS = require "libs.middleclass"
M.LUME = require "libs.lume"



M.GLOBAL = {} 

--region input
M.INPUT = require "libs.input_receiver"
function M.input_acquire(url)
	M.INPUT.acquire(url)
end

function M.input_release(url)
	M.INPUT.release(url)
end
--endregion

--region log
M.LOG = require "libs.log"

function M.t(message, tag)
	M.LOG.t(message, tag,2)
end

function M.trace(message, tag)
	M.LOG.trace(message,tag,2)
end

function M.d(message, tag)
	M.LOG.d(message,tag,2)
end

function M.debug(message, tag)
	M.LOG.debug(message,tag,2)
end

function M.i(message, tag)
	M.LOG.i(message,tag,2)
end

function M.info(message, tag)
	M.LOG.info(message,tag,2)
end

-- WARNING
function M.w(message, tag)
	M.LOG.w(message,tag,2)
end

function M.warning(message, tag)
	M.LOG.warning(message,tag,2)
end

-- ERROR
function M.e(message, tag)
	M.LOG.e(message,tag,2)
end

function M.error(message, tag)
	M.LOG.error(message,tag,2)
end

-- CRITICAL
function M.c(message, tag)
	M.LOG.c(message,tag,2)
end

function M.critical(message, tag)
	M.LOG.critical(message,tag,2)
end
--endregion

function M.weakref(t)
	local weak = setmetatable({content=assert(t)}, {__mode="v"})
	return function() return weak.content end
end

---@generic T
---@param t T
---@return T
function M.read_only(t)
	return setmetatable({}, {
		__index = t,
		__newindex = function(table, key, value)
			error("Attempt to modify read-only table")
		end,
		__metatable = false
	});
end

--region class
function M.class(name, super)
	return M.CLASS.class(name, super)
end
--endregion

function M.coroutine_resume(cor,...)
	local ok, res = coroutine.resume(cor,...)
	if not ok then
		M.e(res, "COROUTINE")
	end
end

return M