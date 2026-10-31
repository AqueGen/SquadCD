-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/LayoutRules.lua", "UI/Theme.lua", "UI/Icon.lua" }

local function region()
    local r = helpers.newFrame()
    function r:SetTexture(path) self.texture = path end
    function r:SetVertexColor(...) self.vertex = { ... } end
    function r:SetText(t) self.text = t end
    function r:GetStringWidth() return #(self.text or "") * 5 end
    function r:SetShown(v) self.shown = v and true or false end
    return setmetatable(r, { __index = function(_, k)
        if k:match("^%u") then return function() end end
    end })
end

describe("Type label tab", function()
    local ns, parent

    before_each(function()
        ns = helpers.load(FILES, {
            CreateFrame = function()
                local f = region()
                function f:CreateTexture() return region() end
                function f:CreateFontString() return region() end
                return f
            end,
            C_Item = { GetItemIconByID = function(id) return "item:" .. id end },
            issecretvalue = function() return false end,
        })
        parent = region()
    end)

    it("shows the type glyph in the glyph colour and no text in Icon mode", function()
        local tab = ns.Icon.NewTab(parent)
        tab:Set("Kick", "Icon")
        assert.is_true(tab.icon.shown)
        assert.are.equal("Interface\\AddOns\\SquadCD\\Media\\Types\\Kick", tab.icon.texture)
        assert.are.same(ns.Theme.TYPES.Kick.text, { tab.icon.vertex[1], tab.icon.vertex[2], tab.icon.vertex[3] })
        assert.are.equal("", tab.text.text)
    end)

    it("hides the icon for text labels", function()
        local tab = ns.Icon.NewTab(parent)
        tab:Set("Kick", "Icon")
        tab:Set("Kick", "Glyph")
        assert.is_false(tab.icon.shown)
        assert.are.equal("K", tab.text.text)
    end)

    it("keeps Icon labels on panel and party frame looks", function()
        local d = ns.LayoutModel.Defaults()
        d.panelLook.labels, d.memberLook.labels = "Icon", "Icon"
        ns.LayoutModel.Normalize(d)
        assert.are.equal("Icon", d.panelLook.labels)
        assert.are.equal("Icon", d.memberLook.labels)
    end)

    it("has an icon for every type", function()
        for _, t in ipairs(ns.LayoutRules.TYPES) do
            assert.is_not_nil(ns.Icon.TypeIcon(t), t)
        end
        assert.is_not_nil(ns.Icon.TypeIcon("Control"))
    end)
end)
