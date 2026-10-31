-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/LayoutRules.lua", "UI/Theme.lua", "UI/WidgetRules.lua",
    "UI/Widgets.lua", "UI/LayoutParts.lua",
}
for i = #helpers.VELVET, 1, -1 do table.insert(FILES, 1, helpers.VELVET[i]) end

local function region()
    local r = helpers.newFrame()
    function r:SetTexture(path) self.texture = path end
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
            UIParent = setmetatable({}, { __index = function() return function() return 0 end end }),
        })
    end)

    it("shows a spell icon and a stripe in the type colour", function()
        local parent = region()
        function parent:CreateTexture() return region() end
        function parent:CreateFontString() return region() end
        local mark, paint = ns.LayoutParts.Mark(parent, 16)
        paint("Kick")
        assert.are.equal("Interface\\Icons\\ability_kick", mark.icon.texture)
        assert.are.same(ns.Theme.TYPES.Kick.fill, { mark.stripe.color[1], mark.stripe.color[2], mark.stripe.color[3] })
    end)

    it("shows the potion item icon for Potion", function()
        local parent = region()
        function parent:CreateTexture() return region() end
        function parent:CreateFontString() return region() end
        local mark, paint = ns.LayoutParts.Mark(parent, 16)
        paint("Potion")
        assert.are.equal("item:" .. ns.Potions[1].item, mark.icon.texture)
    end)

    it("has an icon for every type", function()
        for _, t in ipairs(ns.LayoutRules.TYPES) do
            assert.is_not_nil(ns.LayoutParts.TypeIcon(t), t)
        end
        assert.is_not_nil(ns.LayoutParts.TypeIcon("Control"))
    end)
end)
