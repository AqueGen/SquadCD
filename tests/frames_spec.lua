local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local SECRET = {}

local function stub(f)
    return setmetatable(f, {
        __index = function(_, k)
            if not k:match("^%u") then return nil end
            if k:match("^Create") then return function() return stub(helpers.newFrame()) end end
            if k:match("^Get") then return function() return 0 end end
            return function() end
        end,
    })
end

local function frameStub()
    return stub(helpers.newFrame())
end

local BASE = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/LayoutGrid.lua", "Logic/LayoutRules.lua", "Logic/Docking.lua", "UI/Theme.lua",
}

local icons

local function fakeIcon()
    local w = { frame = frameStub(), buf = {} }
    function w:SetSpell(spell, member) self.spell, self.member = spell, member end
    function w:SetLabel() return 20 end
    function w:Update() end
    function w:SetNext(on) self.next = on end
    icons[#icons + 1] = w
    return w
end

local function load(extra, stubs)
    icons = {}
    local files = {}
    for _, f in ipairs(BASE) do files[#files + 1] = f end
    for _, f in ipairs(extra) do files[#files + 1] = f end
    local all = {
        CreateFrame = function(_, name)
            local f = frameStub()
            if name then _G[name] = f end
            return f
        end,
        UIParent = stub({ GetWidth = function() return 1000 end, GetHeight = function() return 800 end, GetTop = function() return 800 end }),
        InCombatLockdown = function() return false end,
        UISpecialFrames = {},
        tinsert = table.insert,
        issecretvalue = function(v) return v == SECRET end,
        wipe = function(t)
            for k in pairs(t) do t[k] = nil end
            return t
        end,
        C_ClassColor = { GetClassColor = function() return nil end },
    }
    for k, v in pairs(stubs or {}) do all[k] = v end
    local ns = helpers.load(files, all)
    ns.DB = ns.Defaults({ version = 2, layout = ns.LayoutModel.Defaults() })
    ns.Icon = { New = fakeIcon, NewTab = function() return { frame = frameStub(), text = frameStub(), Set = function() return 10 end } end }
    return ns
end

describe("Panel Next marker", function()
    local function marked(deadOf, sight)
        local ns = load({ "UI/Panel.lua" }, { UnitIsDeadOrGhost = deadOf })
        local spell = { id = 999001, type = "External" }
        local entries = {
            { spell = spell, member = { guid = "A", unit = "party1", class = "PRIEST", spec = 256, name = "A" } },
            { spell = spell, member = { guid = "B", unit = "party2", class = "PRIEST", spec = 256, name = "B" } },
            { spell = spell, member = { guid = "C", class = "PRIEST", spec = 256, name = "C" } },
        }
        ns.Panel.Build({ { section = ns.DB.layout.sections[1], type = "External", entries = entries } })
        local tracker = {
            State = function(_, _, _, buf)
                buf.ready, buf.remaining = true, 0
                return buf
            end,
        }
        ns.Panel.Update(tracker, 100, sight)
        local out = {}
        for _, w in ipairs(icons) do
            if w.next then out[#out + 1] = w.member.guid end
        end
        return out
    end

    it("skips a dead member", function()
        local out = marked(function(unit) return unit == "party1" end, { plain = true, secret = {}, timers = true, live = true })
        assert.are.same({ "B" }, out)
    end)

    it("reads a secret death as alive and skips members with no unit", function()
        local out = marked(function(unit)
            assert.is_not_nil(unit)
            return SECRET
        end, { plain = true, secret = {}, timers = true, live = true })
        assert.are.same({ "A" }, out)
    end)

    it("ignores deaths in the demo", function()
        local out = marked(function() return true end, { plain = true, secret = {}, timers = true, live = false })
        assert.are.same({ "A" }, out)
    end)
end)

describe("Rows spacing", function()
    it("places party frame icons with the group gap", function()
        local ns = load({ "UI/Rows.lua" })
        ns.Anchors = {
            FrameFor = function() return frameStub(), false end,
            SizeOf = function() return 0, 0 end,
            Stack = function() return frameStub() end,
            PlaceStack = function() end,
        }
        ns.EditMode = { Panels = function() return false end }
        local layout = ns.DB.layout
        layout.memberFit = false
        layout.memberLook.labels = "None"
        layout.groups = { { types = { "Personal" }, side = "Right", shape = { axis = "Rows", perLine = 8, origin = "TopLeft", sort = "Fixed" }, offsetX = 0, offsetY = 0, gap = 10 } }
        local spells = { { id = 1 }, { id = 2 } }
        ns.Rows.Build({ { member = { guid = "A", unit = "player", class = "PRIEST" }, own = true, groups = { [1] = { { type = "Personal", spells = spells } } } } })
        local a, b = icons[1].frame.points[1], icons[2].frame.points[1]
        assert.are.equal(layout.memberLook.iconSize + 10, math.abs(b[4] - a[4]) + math.abs(b[5] - a[5]))
    end)
end)

describe("Member chip", function()
    it("goes below a holder whose top is secret", function()
        local ns = load({ "Logic/MemberEdit.lua", "Logic/Preview.lua", "UI/Anchors.lua", "UI/EditMode.lua", "UI/MemberChip.lua" })
        local holder = frameStub()
        function holder:GetTop() return SECRET end
        ns.Rows = { Holder = function() return holder end, Outline = function() end }
        ns.Display = { Rebuild = function() ns.EditMode.Refresh() end, HasMembers = function() return true end }
        ns.Demo = { Running = function() return false end }
        ns.Widgets = {
            Button = function()
                local b = frameStub()
                b.label = frameStub()
                return b
            end,
            PaintChoice = function() end,
        }
        assert.is_true(ns.EditMode.StartMembers())
        local at = SquadCDMemberChip.points[1]
        assert.are.same({ "TOPLEFT", "BOTTOMLEFT" }, { at[1], at[3] })
        assert.are.equal(holder, at[2])
    end)
end)
