-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
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

describe("Panel instances", function()
    local ns, parent

    local function entries(type)
        local spell = { id = 999001, type = type }
        return {
            { spell = spell, member = { guid = "A", class = "PRIEST", spec = 256, name = "A" } },
            { spell = spell, member = { guid = "B", class = "MAGE", spec = 64, name = "B" } },
        }
    end

    local function external()
        return { section = ns.DB.layout.sections[3], type = "External", entries = entries("External") }
    end

    before_each(function()
        ns = load({ "UI/Panel.lua" })
        parent = frameStub()
    end)

    it("draws a preview on its parent and leaves the live panel alone", function()
        local preview = ns.Panel.New({ parent = parent })
        local w, h = preview.Build({ external() })
        assert.is_true(w > 0 and h > 0)
        local c = preview.Containers()[1]
        assert.are.equal(parent, c.frame.points[1][2])
        assert.are.same({ "TOPLEFT", "TOPLEFT", 0, 0 }, { c.frame.points[1][1], c.frame.points[1][3], c.frame.points[1][4], c.frame.points[1][5] })
        assert.are.equal(0, #ns.Panel.Containers())
    end)

    it("keeps the live panel's positions when a preview builds", function()
        ns.Panel.Build({ external() })
        local before = ns.Panel.Positions().panel
        ns.Panel.New({ parent = parent }).Build({ external() })
        assert.are.equal(before, ns.Panel.Positions().panel)
        assert.are.equal(1, #ns.Panel.Containers())
    end)

    it("returns an empty size for no lines", function()
        local w, h = ns.Panel.New({ parent = parent }).Build({})
        assert.are.same({ 0, 0 }, { w, h })
    end)

    it("chains a freely placed section window next to the panel", function()
        local layout = ns.DB.layout
        layout.kickStyle = "Icons"
        local kick = layout.sections[1]
        kick.ownWindow, kick.pos = true, { x = 900, y = 700 }
        local preview = ns.Panel.New({ parent = parent })
        preview.Build({ external(), { section = kick, type = "Kick", entries = entries("Kick") } })
        local panel, window
        for _, c in ipairs(preview.Containers()) do
            if c.key == "panel" then panel = c.frame else window = c.frame end
        end
        local at = window.points[1]
        local right = at[4] == panel.width + ns.Docking.GAP and at[5] == 0
        local below = at[4] == 0 and at[5] == -(panel.height + ns.Docking.GAP)
        assert.is_true(right or below)
    end)
end)

describe("Panel preview docking", function()
    it("chains a window whose dock target has no lines next to the panel", function()
        local ns = load({ "UI/Panel.lua" })
        local layout = ns.DB.layout
        local group = layout.sections[4]
        group.ownWindow = true
        group.pos = { x = 1400, y = 650, dockTo = layout.sections[1].id, side = "Below", offset = 0 }
        local function line(section, type)
            local spell = { id = 999001, type = type }
            return { section = section, type = type, entries = { { spell = spell, member = { guid = "A", class = "PRIEST", spec = 256, name = "A" } } } }
        end
        local preview = ns.Panel.New({ parent = frameStub() })
        local w, h = preview.Build({ line(layout.sections[3], "External"), line(group, "Group") })
        local panel
        for _, c in ipairs(preview.Containers()) do
            if c.key == "panel" then panel = c.frame end
        end
        assert.is_true(w < panel.width * 2 + ns.Docking.GAP + 1 and h < panel.height * 2 + ns.Docking.GAP + 1)
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
