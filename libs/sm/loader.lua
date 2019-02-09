local COMMON = require "libs.common"
local RX = require "libs.rx"
local TAG = "SceneLoader"
local M = {}

---@type Subject[]
M.scene_load = {}

---@param scene Scene
---@return Observable
function M.load(scene)
    assert(not M.scene_load[tostring(scene._url)], " scene is loading now:" .. scene._name)
    local s = RX.Subject()
    M.scene_load[tostring(scene._url)] = s
    msg.post("main:/scene_loader", COMMON.HASHES.MSG_SM_LOAD, { url = scene._url})
    return s
end

function M.load_done(url)
    local subject = M.scene_load[tostring(url)]
    if subject then
        M.scene_load[tostring(url)] = nil
        subject:onCompleted()
    else
        COMMON.w("scene:" .. tostring(url) .. " not wait for loading",TAG)
    end
end

function M.unload(scene)
    msg.post(scene._url, COMMON.HASHES.MSG_UNLOAD)
end

return M