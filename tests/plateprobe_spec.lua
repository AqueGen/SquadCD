-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Game/PlateProbe.lua" }

describe("PlateProbe", function()
    local ns, w

    before_each(function()
        w = { made = {}, lit = {}, ticks = {} }
        ns = helpers.load(FILES, {
            C_CurveUtil = { EvaluateColorValueFromBoolean = function(b, t, f) if b then return t end return f end },
            C_Timer = { NewTicker = function(_, fn) w.tick = fn return { Cancel = function() w.cancelled = true end } end },
            UnitExists = function(u) return u == "nameplate1" or u == "nameplate2" end,
        })
        ns.Probes = {
            New = function(unit, filter, ids)
                local p = { unit = unit, filter = filter, ids = ids, on = true }
                w.made[#w.made + 1] = p
                return p
            end,
            Lit = function(p) return w.lit[p.unit] or false end,
            Point = function(p, unit) p.pointed = (p.pointed or 0) + 1 p.unit = unit end,
            Enable = function(p, on) p.on = on end,
            Filter = function(p, ids) p.ids = ids end,
        }
    end)

    it("collects the debuff ids of the member's own stuns and CC", function()
        local ids, names = ns.PlateProbe.OwnIds({ class = "WARLOCK", spec = 266, talents = { [30283] = 1, [6789] = 1 }, pets = { [89766] = true } })
        assert.is_true(#ids >= 3)
        local set = {}
        for _, id in ipairs(ids) do set[id] = true end
        assert.is_true(set[30283] and set[6789] and set[89766])
        assert.is_nil(set[5484])
        assert.is_true(#names >= 3)
    end)

    it("puts one HARMFUL probe on every nameplate unit and lights the squares through the engine curve", function()
        ns.PlateProbe.Start({ 30283 })
        assert.equal(20, #w.made)
        assert.equal("nameplate1", w.made[1].unit)
        assert.equal("nameplate20", w.made[20].unit)
        assert.equal("HARMFUL", w.made[1].filter)
        w.lit.nameplate2 = true
        w.tick()
        local a = ns.PlateProbe.Alphas()
        assert.equal(0.15, a[1])
        assert.equal(1, a[2])
    end)

    it("re-points every probe and reuses them on a restart with other ids", function()
        ns.PlateProbe.Start({ 30283 })
        ns.PlateProbe.Repoint()
        assert.equal(1, w.made[7].pointed)
        ns.PlateProbe.Start({ 6789 })
        assert.equal(20, #w.made)
        assert.same({ 6789 }, w.made[1].ids)
    end)

    it("says so when the engine refuses a probe", function()
        ns.Probes.New = function() return nil, "aura group setup failed" end
        assert.is_false(ns.PlateProbe.Start({ 30283 }))
        assert.is_nil(w.tick)
    end)

    it("watches one buff on one unit and switches it off again", function()
        _G.C_Spell = { GetSpellName = function() return "Fire Elemental" end }
        ns.Theme = { FLAT = {} }
        local function any() return setmetatable({}, { __index = function() return any end }) end
        _G.CreateFrame = any
        assert.is_true(ns.PlateProbe.Aura("party1", 188592))
        local p = w.made[#w.made]
        assert.same({ "party1", "HELPFUL", 188592 }, { p.unit, p.filter, p.ids[1] })
        ns.PlateProbe.Aura(nil)
        assert.is_false(p.on)
    end)

    it("stops the ticker and switches the probes off", function()
        ns.PlateProbe.Start({ 30283 })
        ns.PlateProbe.Stop()
        assert.is_true(w.cancelled)
        assert.is_false(w.made[3].on)
    end)
end)
