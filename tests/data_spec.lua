-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Data", function()
    local ns = helpers.load({ "Data.lua" })

    it("every spell has a type and cd", function()
        local n = 0
        for id, s in pairs(ns.Spells) do
            n = n + 1
            assert.is_string(s.type, tostring(id))
            assert.is_number(s.cd, tostring(id))
        end
        assert.is_true(n > 200)
    end)

    it("Shockwave 46968 has cd 40 and cdMods[440992] == -5", function()
        assert.are.equal(40, ns.Spells[46968].cd)
        assert.are.equal(-5, ns.Spells[46968].cdMods[440992])
    end)

    it("Storm Bolt 107570 cdPct[391271] == -10", function()
        assert.are.equal(-10, ns.Spells[107570].cdPct[391271])
    end)

    it("talent entry 24540 maps to 394207", function()
        assert.are.equal(394207, ns.TalentEntries[24540])
    end)

    it("potions are listed with item, buff and cd", function()
        assert.is_true(#ns.Potions > 0)
        for _, p in ipairs(ns.Potions) do
            assert.is_number(p.item)
            assert.is_number(p.buff)
            assert.is_true(p.cd > 0)
        end
    end)

    it("count of track none stays under 30% of non-Kick spells", function()
        local none, total = 0, 0
        for _, s in pairs(ns.Spells) do
            if s.type ~= "Kick" then
                total = total + 1
                if s.track == "none" then none = none + 1 end
            end
        end
        print(("track none: %d of %d non-Kick spells"):format(none, total))
        assert.is_true(none < total * 0.3)
    end)
end)
