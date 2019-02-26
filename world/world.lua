local COMMON = require "libs.common"
local ECS = require "libs.ecs"
local SYSTEMS = require "world.systems"
local RX = require "libs.rx"

---@class World:Observable
local M = COMMON.class("World")

function M:reset()
	self.ecs_world:clear()
	SYSTEMS.init_systems(self.ecs_world)
end

function M:initialize()
	self.ecs_world = ECS.world()
	self.ecs_world.world = self
	self.rx = RX.Subject()
	self:reset()
end

local frame = 0
function M:update(dt, no_save)
	self.ecs_world:update(dt)
	for i=1,5 do
		self.rx:onNext(frame)
		--print("frame1:" .. frame)
	end
	frame = frame + 1
end

function M:dispose()
	self:reset()
end

return M()