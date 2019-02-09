local ECS = require "libs.ecs"
local M = {}

---@class ECSEntity
---@field time number
---@field total_time number
---@field time_progress number
---@field on_time function
---@field hp number


local tick_system = ECS.processingSystem()
tick_system.filter = ECS.requireAll("time", "total_time", "time_progress")

---@param e ECSEntity
function tick_system:process(e, dt)
	if not e.hp or e.hp > 0 then
		e.time = e.time + dt
	end
	if e.time >= e.total_time then
		e.time = 0
		e.time_progress = 1
		return
	end
	e.time_progress = e.time/e.time_progress
end

local on_time_system = ECS.processingSystem()
on_time_system.filter = ECS.requireAll("on_time","time_progress")
function on_time_system:process(e, dt)
	if e.time_progress == 1 then
		e.on_time(e,self.world.world)
	end
end


---@param world ECSWorld
function M.init_systems(world)
	world:addSystem(tick_system)
	world:addSystem(on_time_system)

end

return M