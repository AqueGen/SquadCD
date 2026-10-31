local helpers = {}

local ADDON = "Huddle"
local root = debug.getinfo(1, "S").source:match("^@(.*)[/\\]tests[/\\][^/\\]*$") or "."
local frames
local applied = {}

local function newFrame()
    local f = { events = {}, scripts = {}, shown = true, width = 0, height = 0 }
    function f:RegisterEvent(e) self.events[e] = true end
    function f:RegisterUnitEvent(e) self.events[e] = true end
    function f:UnregisterEvent(e) self.events[e] = nil end
    function f:UnregisterAllEvents() self.events = {} end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:GetScript(name) return self.scripts[name] end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:IsShown() return self.shown end
    function f:SetPoint(...) self.points = self.points or {} self.points[#self.points + 1] = { ... } end
    function f:ClearAllPoints() self.points = nil end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetParent(p) self.parent = p end
    function f:EnableMouse(v) self.mouse = v end
    frames[#frames + 1] = f
    return f
end

helpers.newFrame = newFrame

function helpers.load(files, stubs)
    for k, saved in pairs(applied) do
        _G[k] = saved.prev
    end
    applied = {}
    frames = {}
    _G.HuddleDB = nil
    _G.SlashCmdList = {}
    _G.CreateFrame = newFrame
    _G.geterrorhandler = function() return function() end end
    _G.issecretvalue = function() return false end
    for k, v in pairs(stubs or {}) do
        applied[k] = { prev = _G[k] }
        _G[k] = v
    end

    local ns = {}
    for _, file in ipairs(files) do
        local chunk = assert(loadfile(root .. "/" .. file))
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
