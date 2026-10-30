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

    it("charge spell: recovery with flat and pct mods, then max with charge cooldown mods", function()
        assert.are.equal(90, C.Resolve(227847, 71, { [382953] = 1 }).cd)
        assert.are.equal(120, C.Resolve(871, 73, { [397103] = 1 }).cd)
        assert.are.equal(108, C.Resolve(871, 73, { [397103] = 1, [391271] = 1 }).cd)
        assert.are.equal(48, C.Resolve(204021, 581, { [389732] = 1 }).cd)
    end)

    it("spec mod counts as rank 1", function()
        assert.are.equal(30, C.Resolve(57994, 264, {}).cd)
        assert.are.equal(12, C.Resolve(57994, 263, {}).cd)
        assert.are.equal(120, C.Resolve(115203, 270, nil).cd)
    end)

    it("fractional seconds are kept", function()
        assert.are.equal(13.5, C.Resolve(6552, 73, { [391271] = 1 }).cd)
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

    it("spec match overrides gating, a gated spell otherwise needs the talent", function()
        assert.is_true(C.Has(51490, "SHAMAN", 262, {}))
        assert.is_false(C.Has(51490, "SHAMAN", 263, {}))
        assert.is_true(C.Has(51490, "SHAMAN", 263, { [51490] = 1 }))
        assert.is_true(C.Has(122470, "MONK", 269, {}))
        assert.is_false(C.Has(122470, "MONK", 270, {}))
        assert.is_true(C.Has(122470, "MONK", 270, { [122470] = 1 }))
    end)

    it("spec and class filter", function()
        assert.is_false(C.Has(498, "PALADIN", 66, nil))
        assert.is_true(C.Has(498, "PALADIN", 65, nil))
        assert.is_false(C.Has(46968, "MAGE", 73, nil))
    end)
end)
