local BaseScene = require "libs.sm.scene"
local Scene = BaseScene:subclass("LogoScene")
local SM = require "libs.sm.sm"
local WORLD = require "world.world"
local COMMON = require "libs.common"
--- Constructor
-- @param name Name of scene.Must be unique
function Scene:initialize()
    BaseScene.initialize(self, "LogoScene2", "/logo2#proxy", "logo2:/scene_controller")
end

function Scene:on_show(input)
end

function Scene:final(go_self)
end

function Scene:update(go_self, dt)
end

function Scene:on_transition(transition)
end

return Scene