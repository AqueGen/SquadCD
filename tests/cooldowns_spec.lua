local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Cooldowns", function()
    local ns = helpers.load({ "Core.lua", "Data.lua", "Logic/Cooldowns.lua" })
    local C = ns.Cooldowns

    it("base cooldown when talents unknown", function()
        local r = C.Resolve(46968, 73, nil)
        assert.are.equal(40, r.cd)
        assert.is_false(r.talentsKnown)
    end)

    it("flat mod", function()
        local r = C.Resolve(46968, 73, { [440992] = 1 })
        assert.are.equal(35, r.cd)
        assert.is_true(r.talentsKnown)
    end)

    it("pct mod applied after flat mods", function()
        assert.are.equal(27, C.Resolve(107570, 73, { [391271] = 1 }).cd)
        assert.are.equal(36, C.Resolve(107570, 73, { [391271] = 1, [436162] = 1 }).cd)
    end)

    it("charges add", function()
        assert.are.equal(1, C.Resolve(871, 73, {}).charges)
        assert.are.equal(2, C.Resolve(871, 73, { [397103] = 1 }).charges)
    end)

    it("talent read later shortens running timer", function()
        local elapsed = 12
        local before = C.Resolve(46968, 73, nil).cd - elapsed
        local after = C.Resolve(46968, 73, { [440992] = 1 }).cd - elapsed
        assert.are.equal(28, before)
        assert.are.equal(23, after)
    end)

    it("gated spell hidden when talents known and missing", function()
        assert.is_true(C.Has(46968, "WARRIOR", 73, nil))
        assert.is_false(C.Has(46968, "WARRIOR", 73, {}))
        assert.is_true(C.Has(46968, "WARRIOR", 73, { [46968] = 1 }))
    end)

    it("spec and class filter", function()
        assert.is_false(C.Has(498, "PALADIN", 66, nil))
        assert.is_true(C.Has(498, "PALADIN", 65, nil))
        assert.is_false(C.Has(46968, "MAGE", 73, nil))
    end)
end)
