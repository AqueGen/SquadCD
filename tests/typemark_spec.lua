-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/LayoutRules.lua", "UI/Theme.lua", "UI/Icon.lua", "UI/WidgetRules.lua",
    "UI/Widgets.lua", "UI/LayoutParts.lua",
}
for i = #helpers.VELVET, 1, -1 do table.insert(FILES, 1, helpers.VELVET[i]) end

local function region()
    local r = helpers.newFrame()
    function r:SetTexture(path) self.texture = path end
    function r:SetVertexColor(...) self.vertex = { ... } end
    function r:SetColorTexture(...) self.color = { ... } end
    function r:SetTexCoord() end
    function r:SetText(t) self.text = t end
    return setmetatable(r, { __index = function(_, k)
        if k:match("^%u") then return function() end end
    end })
end

describe("Type mark", function()
    local ns

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
            UIParent = setmetatable({}, { __index = function() return function() return 0 end end }),
        })
    end)

    it("shows the type glyph on a tile in the type colour", function()
        local parent = region()
        local mark, paint = ns.LayoutParts.Mark(parent, 16)
        paint("Kick")
        assert.are.equal("Interface\\AddOns\\SquadCD\\Media\\Types\\Kick", mark.glyph.texture)
        assert.are.same(ns.Theme.TYPES.Kick.fill, { mark.fill.color[1], mark.fill.color[2], mark.fill.color[3] })
        assert.are.same(ns.Theme.TYPES.Kick.text, { mark.glyph.vertex[1], mark.glyph.vertex[2], mark.glyph.vertex[3] })
    end)

    it("has a glyph for every type", function()
        for _, t in ipairs(ns.LayoutRules.TYPES) do
            assert.are.equal("Interface\\AddOns\\SquadCD\\Media\\Types\\" .. t, ns.Icon.TypeIcon(t))
        end
        assert.is_not_nil(ns.Icon.TypeIcon("Control"))
    end)
end)
