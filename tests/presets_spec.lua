-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/LayoutGrid.lua", "Logic/LayoutRules.lua", "Logic/Preview.lua", "Logic/Profiles.lua", "UI/Theme.lua",
    "UI/WidgetRules.lua", "UI/Widgets.lua", "UI/LayoutParts.lua", "UI/Window.lua", "Pages/Presets.lua", "Pages/Profiles.lua",
}
for i = #helpers.VELVET, 1, -1 do table.insert(FILES, 1, helpers.VELVET[i]) end

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

describe("Presets page", function()
    local ns, created, printed, editing, uiShown, cards

    local function frame(parent)
        local f = stub(helpers.newFrame())
        f.parentFrame = parent
        function f:GetParent() return self.parentFrame or stub(helpers.newFrame()) end
        function f:SetText(t) self.text = t end
        function f:HookScript(name, fn) self.hooks = self.hooks or {} self.hooks[name] = fn end
        created[#created + 1] = f
        return f
    end

    local function pageFrame()
        for _, f in ipairs(created) do
            if f.hooks and f.hooks.OnHide then return f end
        end
    end

    before_each(function()
        created, printed, editing, uiShown = {}, {}, false, true
        ns = helpers.load(FILES, {
            CreateFrame = function(_, name, parent)
                local f = frame(parent)
                if name then _G[name] = f end
                return f
            end,
            InCombatLockdown = function() return false end,
            print = function(s) printed[#printed + 1] = s end,
            UIParent = stub({ IsShown = function() return uiShown end }),
            UISpecialFrames = {},
            tinsert = table.insert,
            GameTooltip_Hide = function() end,
            IsAltKeyDown = function() return false end,
            C_ClassColor = { GetClassColor = function() return nil end },
        })
        ns.DB = ns.Defaults({ version = 2, layout = ns.LayoutModel.Defaults(), seenAbout = true })
        ns.Display = { Changed = function() end, HasMembers = function() return false end }
        ns.Demo = { Mode = function() return "Off" end, Running = function() return false end, Set = function() end }
        ns.EditMode = { Panels = function() return editing end, Members = function() return false end }
        ns.PanelPreview = { Attach = function() end, Refresh = function() end, SetFocus = function() end }
        ns.LayoutParts.Demo = function() end
        ns.LayoutParts.TypesTable = function() end
        ns.LayoutParts.PresetCards = function(_, opts) cards = opts end
        ns.ProfileSwitch = {
            Specs = function() return { { id = 65, name = "Holy" }, { id = 66, name = "Protection" } } end,
            CurrentSpec = function() return 65 end,
            KeyOf = function(id) return "Ann-Realm:" .. id end,
            Use = function(name) ns.Profiles.Switch(ns.DB, name) end,
        }
        ns.Window.Show("presets")
    end)

    it("refuses a preview while an edit mode is on and leaves the layout alone", function()
        local before = ns.DB.layout
        editing = true
        cards.pick(3)
        assert.is_nil(ns.Preview.Showing())
        assert.are.equal(before, ns.DB.layout)
        assert.truthy(printed[1]:find("Done"))
    end)

    it("keeps the preview when the page hides because UIParent hid", function()
        cards.pick(3)
        local page = pageFrame()
        uiShown = false
        page.hooks.OnHide(page)
        assert.are.equal(3, ns.Preview.Showing())
        uiShown = true
        page.hooks.OnHide(page)
        assert.is_nil(ns.Preview.Showing())
    end)
    it("the Profiles page lists the class specs with the profile each one uses", function()
        ns.Profiles.New(ns.DB, "Wide")
        ns.Profiles.Assign(ns.DB, "Ann-Realm:65", "Wide")
        ns.Window.Show("profiles")
        local picks = {}
        for _, f in ipairs(created) do
            if f.text == "Wide" or f.text == "Default" then picks[#picks + 1] = f.text end
        end
        assert.are.same({ "Wide", "Default" }, picks)
    end)
end)
