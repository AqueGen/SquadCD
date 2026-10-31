-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Probes", function()
    local ns, made, groupError

    before_each(function()
        made, groupError = {}, false
        ns = helpers.load({ "Logic/LayoutModel.lua", "Core.lua", "Game/Probes.lua" }, {
            UIParent = {},
            CreateFrame = function(kind)
                local f = helpers.newFrame()
                if kind == "AuraContainer" then
                    function f:AddAuraGroup(key, filter, options)
                        if groupError then error("boom") end
                        self.group = { key = key, filter = filter, options = options }
                    end
                    function f:SetUnit(u) self.unit = u end
                    function f:SetEnabled(v) self.on = v end
                    function f:IsMouseOver(...) self.over = { ... } return true end
                    made[#made + 1] = f
                end
                return f
            end,
        })
    end)

    it("builds one aura group over the whole id set", function()
        local p = ns.Probes.New("party1", "HELPFUL", { 48792, 1 })
        assert.equal("HELPFUL", p.group.filter)
        assert.same({ [48792] = true, [1] = true }, p.group.options.candidateFilters.includeSpellIDs)
        assert.equal(1, p.group.options.maxFrameCount)
        assert.equal(50000, p.group.options.layout.elementWidth)
        assert.equal("party1", p.unit)
        assert.is_true(p.on)
    end)

    it("reports a failed group setup", function()
        groupError = true
        local p, why = ns.Probes.New("party1", "HELPFUL", { 1 })
        assert.is_nil(p)
        assert.truthy(why:find("aura group setup failed"))
    end)

    it("hit-tests across the whole screen", function()
        local p = ns.Probes.New("party1", "HELPFUL", { 1 })
        assert.is_true(ns.Probes.Lit(p))
        assert.same({ 1e5, -1e5, 0, 0 }, p.over)
    end)

    it("re-points and switches probes", function()
        local p = ns.Probes.New("party1", "HELPFUL", { 1 })
        ns.Probes.Point(p, "party2")
        ns.Probes.Enable(p, false)
        assert.equal("party2", p.unit)
        assert.is_false(p.on)
    end)
end)
