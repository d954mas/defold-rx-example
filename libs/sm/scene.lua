--BASE SCENE MODULE.
local COMMON = require "libs.common"
local LOADER = require "libs.sm.loader"

---@class SceneConfig
---@field modal boolean

---@class Scene
---@field _input table data for scene
---@field _state number Scene state
---@field _name string unique name. Used for changing scenes
---@field _modals Scene[] modal windows for current scene
---@field _url url proxy url
---@field _controller_url url scene controller url
---@field _config SceneConfig SceneConfig
---@field _sm SceneManager
local Scene = COMMON.class('Scene')

local STATES = COMMON.read_only({
    UNLOADED = "UNLOADED",
    HIDE = "HIDE", --scene is loaded.But not showing on screen
    PAUSED = "PAUSED", --scene is showing.But update not called.
    RUNNING = "RUNNING", --scene is running
    LOADING = "LOADING",
})

local TRANSITIONS = COMMON.read_only({
    ON_HIDE = "ON_HIDE",
    ON_SHOW = "ON_SHOW",
    ON_BACK_SHOW = "ON_BACK_SHOW",
    ON_BACK_HIDE = "ON_BACK_HIDE",
})


---@param name string of scene.Must be unique
function Scene:initialize(name,url,controller_url)
    self._name = assert(name)
    self._input = nil
    self._url = msg.url(assert(url))
    self._controller_url = msg.url(assert(controller_url))
    self._STATES = STATES
    self._in_transition = false
    self._TRANSITIONS = TRANSITIONS
    self._state = STATES.UNLOADED
    self.__loaded = nil
    self._config = {}
end


--region BASE
--used by scene manager to manipulate scene
--can be called outside of go context

---@return Observable
function Scene:load()
    local s = LOADER.load(self)
    s:subscribe(nil,nil,function()   self.__loaded = true end)
    return s
end

function Scene:unload()
    self.__loaded = false
    LOADER.unload(self)
end

function Scene:hide()
    msg.post(self._controller_url, COMMON.HASHES.MSG_SM_HIDE)
    msg.post(self._url, COMMON.HASHES.MSG_DISABLE)
end
function Scene:show()
    msg.post(self._url, COMMON.HASHES.MSG_ENABLE)
    if self.__loaded then
        msg.post(self._controller_url, COMMON.HASHES.MSG_SM_INIT, {scene_name = self._name})
        self.__loaded = nil
    end
    msg.post(self._controller_url, COMMON.HASHES.MSG_SM_SHOW)
end

function Scene:pause()
    msg.post(self._controller_url, COMMON.HASHES.MSG_SM_PAUSE)
    msg.post(self.url, "set_time_step", {factor = 0, mode = 0})
end
function Scene:resume()
    msg.post(self._controller_url, COMMON.HASHES.MSG_SM_RESUME)
    msg.post(self.url, "set_time_step", {factor = 1, mode = 0})
end

---@param transition string
function Scene:transition(transition)
    msg.post(self._controller_url, COMMON.HASHES.MSG_SM_TRANSITION,{transition = transition})

end


--endregion

--region ON
--called in go context. Use messages for it.
function Scene:on_hide()
end
function Scene:on_show()
end

function Scene:on_pause()
end
function Scene:on_resume()
end

--called in go context. Can use yeild
---@param transition number
function Scene:on_transition(transition)

end
--endregion

--region GO

--not go init. Is is scene init.
function Scene:init(go_self) end

function Scene:final(go_self)
end

function Scene:update(go_self, dt)
end

function Scene:on_message(go_self, message_id, message, sender)
end

function Scene:on_input(go_self, action_id, action)
end

function Scene:on_reload(go_self)
end
--endregion

return Scene