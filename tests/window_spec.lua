-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "UI/Theme.lua", "UI/WidgetRules.lua", "UI/Widgets.lua", "UI/Window.lua",
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

describe("Settings window preview zone", function()
    local ns, pane, refreshed, settings

    local function point(f, name)
        for _, p in ipairs(f.points or {}) do
            if p[1] == name then return p end
        end
    end

    before_each(function()
        pane, refreshed, settings = nil, 0, nil
        ns = helpers.load(FILES, {
            CreateFrame = function(_, name, parent)
                local f = stub(helpers.newFrame())
                f.parentFrame = parent
                function f:GetParent() return self.parentFrame or stub(helpers.newFrame()) end
                function f:SetText(t) self.text = t end
                function f:SetWidth(w) self.width = w end
                function f:SetHeight(h) self.height = h end
                function f:HookScript(event, fn)
                    local prev = self.scripts[event]
                    self.scripts[event] = function(...)
                        if prev then prev(...) end
                        fn(...)
                    end
                end
                if name then
                    _G[name] = f
                    if name == "SquadCDSettings" then
                        settings = f
                        f.scripts.OnSizeChanged = function() f.backdropResized = true end
                    end
                end
                return f
            end,
            InCombatLockdown = function() return false end,
            UIParent = stub({}),
            UISpecialFrames = {},
            tinsert = table.insert,
            GameTooltip_Hide = function() end,
        })
        ns.DB = ns.Defaults({ version = 2, layout = ns.LayoutModel.Defaults() })
        ns.Demo = { Running = function() return false end }
        ns.EditMode = { Panels = function() return false end }
        ns.PanelPreview = {
            Attach = function(p) pane = p end,
            Refresh = function() refreshed = refreshed + 1 end,
        }
        ns.Window.Register("about", function() end)
        ns.Window.Register("panels", function() end, { preview = "panel" })
    end)

    it("shows the pane beside the column on a page with a preview", function()
        ns.Window.Show("panels")
        assert.is_true(pane.shown)
        assert.is_not_nil(point(pane, "TOPRIGHT"))
        assert.is_not_nil(point(pane, "BOTTOMRIGHT"))
        assert.is_true(refreshed > 0)
    end)

    it("hides the pane on a page without a preview", function()
        ns.Window.Show("panels")
        ns.Window.Show("about")
        assert.is_false(pane.shown)
    end)

    it("moves the pane to a band above the column in a narrow window", function()
        ns.Window.Show("panels")
        settings:SetSize(820, 560)
        settings.scripts.OnSizeChanged(settings, 820, 560)
        assert.is_true(pane.shown)
        assert.is_not_nil(point(pane, "TOPLEFT"))
        assert.is_nil(point(pane, "BOTTOMRIGHT"))
        assert.are.equal(150, pane.height)
        assert.is_true(settings.backdropResized)
    end)

    it("opens wide enough for the side zone by default", function()
        ns.Window.Show("panels")
        assert.are.equal(1000, settings.width)
    end)
end)
