local COMMON = require "libs.common"
local Stack = require "libs.sm.stack"
local Scene = require "libs.sm.scene"
local LOADER = require "libs.sm.loader"
local TAG = "SM"

---@class SceneManager
local M = COMMON.class("SceneManager")

function M:initialize()
    self.stack = Stack()
    ---@type Scene[]
    self.scenes = {}
    self.co = nil
end

---@param scenes Scene[]
function M:register(scenes)
    assert(#self.scenes == 0, "register_scenes can be called only once")
    assert(scenes, "scenes can't be nil")
    assert(#scenes ~= 0, "scenes should have one or more scene")
    for _, scene in ipairs(scenes) do
        assert(not scene.__declaredMethods, "register instance not class(add ())")
        assert(scene._name, "scene name can't be nil")
        assert(not self.scenes[scene._name], "scene:" .. scene._name .. " already exist")
        self.scenes[scene._name] = scene
        scene._sm = self
    end
end

---@param self SceneManager
---@param scene Scene
local function check(self,scene)
    assert(self.co, "no running co")
    assert(scene, "scene can't be nil")
end

---@param self SceneManager
---@param scene Scene
local function unload(self, scene)
    check(self, scene)
    COMMON.i("unload scene:" .. scene._name, TAG)
    scene:unload()
    scene._state = scene._STATES.UNLOADED
end
---@param self SceneManager
---@param scene Scene
local function load(self,scene)
    check(self,scene)
    COMMON.i("start load scene:" .. scene._name, TAG)
    local start_loading_time = os.clock()
    scene._state = scene._STATES.LOADING
    scene:load():subscribe(nil,nil,function()
        scene._state = scene._STATES.HIDE
        COMMON.i("load scene:" .. scene._name .. " done", TAG)
        COMMON.i("load time:" .. os.clock() - start_loading_time, TAG)
    end)

end
---@param self SceneManager
---@param scene Scene
local function pause(self, scene)
    check(self,scene)
    COMMON.i("pause scene:" .. scene._name, TAG)
    scene:pause()
    scene._state = scene._STATES.PAUSED
end

---@param self SceneManager
---@param scene Scene
local function resume(self, scene)
    check(self,scene)
    COMMON.i("resume scene:" .. scene._name, TAG)
    scene:resume()
    scene._state = scene._STATES.RUNNING
end

---@param self SceneManager
---@param scene Scene
local function hide(self, scene)
    check(self, scene)
    COMMON.i("hide scene:" .. scene._name, TAG)
    scene:hide()
    scene._state = scene._STATES.HIDE
end
---@param self SceneManager
---@param scene Scene
local function show(self, scene, input)
    check(self, scene)
    COMMON.i("show scene:" .. scene._name, TAG)
    scene._input = input
    scene:show()
    scene._state = scene._STATES.PAUSED
end

---@param self SceneManager
---@param scene Scene
---@param transition string
local function scene_transition(self,scene,transition)
    check(self, scene)
    COMMON.i("transition " ..  transition .. ":" .. scene._name, TAG)
    scene._in_transition = true
    scene:transition(transition)
    while scene._in_transition do
        coroutine.yield()
    end
    COMMON.i("transition " ..  transition .. " end:" .. scene._name, TAG)
end


---unload prev scene with all it modals. If next scene is modal then do not hide current
---@param self SceneManager
---@param scene Scene
---@param new_scene Scene|nil need for waiting next scene loading done before hide scene
local function unload_scene(self,scene,new_scene)
    assert(self, "self can't be nil")
    assert(scene, "scene can't be nil")
    local STATES = scene._STATES
   -- for _=scene._modals,1,-1 do
      --  local modal = table.remove(scene._modals)
     --   unload_scene(self,modal)
   -- end
    COMMON.i("release input for scene:" .. scene._name, TAG)
    msg.post(scene._url,COMMON.HASHES.INPUT_RELEASE_FOCUS)
    if scene._state == STATES.RUNNING then
        pause(self,scene)
    end
    local modal = new_scene and new_scene._config.modal
    --wait next scene loaded
    while new_scene and new_scene._state == STATES.LOADING do coroutine.yield() end
    if scene._state == STATES.PAUSED and not modal then
        hide(self,scene)
    end

    if scene._state == STATES.HIDE then
        unload(self,scene)
    end
end


--COROUTUINES FUN
--show new scene, hide old scene
---@param old_scenes Scene|nil
---@param new_scene Scene
local function show_new_scene(self, old_scene, new_scene, input,options)
    assert(self, "self can't be nil")
    assert(new_scene, "new_scene can't be nil")
    local STATES  = new_scene._STATES
    COMMON.i("change scene from " .. (old_scene and old_scene._name or "nil") .. " to " .. new_scene._name)
    options = {}
    if new_scene == old_scene and not options.reload then
        COMMON.i("scene:" .. new_scene._name .. " already on top")
        self.co = nil
        return
    end
    --try preload scene
    if new_scene._state == STATES.UNLOADED then
        load(self,new_scene)
    end

    if old_scene then unload_scene(self,old_scene,new_scene) end

    --wait next scene loaded
    while new_scene._state == STATES.LOADING do coroutine.yield() end

    if new_scene._state == STATES.HIDE then
        show(self,new_scene, input)
    end
    if new_scene._state == STATES.PAUSED then
        resume(self,new_scene, self.co)
        scene_transition(self,new_scene,new_scene._TRANSITIONS.ON_SHOW)
    end

    COMMON.i("acquire input for scene:" .. new_scene._name, TAG)
    msg.post(new_scene._url,COMMON.HASHES.INPUT_ACQUIRE_FOCUS)
    self.co = nil
    COMMON.i("scene changed", TAG)
end

function M:show(scene_name, input, options)
    assert(not self.co, "work in progress.Can't show new scene")
    input = input or {}
    options = options or {}
    local scene = assert(self:get_scene_by_name(scene_name))
   
    local current_scene =  scene._config.modal and self.stack:peek() or self.stack:pop()
    self.stack:push(scene)
    self.co = coroutine.create(show_new_scene)
    local ok, res = coroutine.resume(self.co, self, current_scene, scene, input, options)
    if not ok then
        COMMON.e(res, TAG)
        self.co = nil
    end
end

function M:back(input, options)
    assert(not self.co, "work in progress.Can't show new scene")
    local prev_scene =  self.stack:pop()

    self.co = coroutine.create(show_new_scene)
    
    local ok, res = coroutine.resume(self.co, self, prev_scene, self.stack:peek(), input, options)
    if not ok then
        COMMON.e(res, TAG)
        self.co = nil
    end
end

function M:reload()
   self:show(self.stack:peek()._name,self.stack:peek()._input, {reload = true})
end

--region UTILS

---@return Scene
function M:get_scene_by_name(name)
    local scene = self.scenes[assert(name, "name can't be nil")]
    return assert(scene, "unknown scene:" .. name)
end
--endregion

--keep loading or transitions
--call it from main
function M:update(dt)
    if self.co then
        local ok, res = coroutine.resume(self.co,dt)
        if not ok then
            COMMON.e(res, TAG)
            self.co = nil
        end
    end
end


return M