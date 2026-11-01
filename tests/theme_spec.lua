-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("settings theme", function()
    local ns
    before_each(function()
        local files = {}
        for _, f in ipairs(helpers.VELVET) do files[#files + 1] = f end
        for _, f in ipairs({ "UI/Theme.lua", "UI/WidgetRules.lua", "UI/Widgets.lua" }) do files[#files + 1] = f end
        ns = helpers.load(files)
    end)

    it("leaves the in-game palette as it was", function()
        assert.same({ 1, 0.82, 0 }, ns.Theme.gold)
        assert.same({ 0.235, 0.251, 0.282, 1 }, ns.Theme.border)
        assert.same({ 0.36, 0.38, 0.43, 1 }, ns.Theme.control)
        assert.equal(1, ns.Theme.FLAT.edgeSize)
    end)

    it("gives the settings window the soft tokens and falls back to the in-game helpers", function()
        assert.same({ 0.18, 0.20, 0.235, 1 }, ns.SettingsTheme.border)
        assert.same({ 0.275, 0.295, 0.337, 1 }, ns.SettingsTheme.control)
        assert.equal(ns.Theme.TYPES, ns.SettingsTheme.TYPES)
        assert.equal(ns.Theme.ClassColor, ns.SettingsTheme.ClassColor)
    end)

    it("passes the hover token through for row highlights", function()
        assert.same({ 1, 1, 1, 0.04 }, ns.SettingsTheme.hover)
    end)
end)
