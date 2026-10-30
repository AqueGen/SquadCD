local helpers = {}

local ADDON = "Huddle"
local frames

local function newFrame()
    local f = { events = {}, scripts = {} }
    function f:RegisterEvent(e) self.events[e] = true end
    function f:UnregisterEvent(e) self.events[e] = nil end
    function f:UnregisterAllEvents() self.events = {} end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:GetScript(name) return self.scripts[name] end
    frames[#frames + 1] = f
    return f
end

function helpers.load(files)
    frames = {}
    _G.HuddleDB = nil
    _G.SlashCmdList = {}
    _G.CreateFrame = newFrame
    _G.geterrorhandler = function() return function() end end
    _G.issecretvalue = function() return false end

    local ns = {}
    for _, file in ipairs(files) do
        local chunk = assert(loadfile(file))
        chunk(ADDON, ns)
    end
    return ns
end

function helpers.fire(event, ...)
    for _, f in ipairs(frames) do
        local handler = f.scripts.OnEvent
        if handler and f.events[event] then
            handler(f, event, ...)
        end
    end
end

return helpers
