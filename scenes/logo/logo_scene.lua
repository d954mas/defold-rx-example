local BaseScene = require "libs.sm.scene"
local Scene = BaseScene:subclass("LogoScene")
local SM = require "libs.sm.sm"
--local COMMON = require "libs.common"
--- Constructor
-- @param name Name of scene.Must be unique
function Scene:initialize()
    BaseScene.initialize(self, "LogoScene", "/logo#proxy", "logo:/scene_controller")
end

function Scene:on_show(input)
end

function Scene:final(go_self)
end

function Scene:update(go_self, dt)
end

function Scene:on_transition(transition)
    print("Transition:" .. tostring(msg.url()))
    for i=1,60 do
        coroutine.yield()
    end
end

return Scene