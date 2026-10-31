-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/SecretTime.lua",
    "Game/Inspect.lua", "Game/Group.lua", "Game/SecretTracks.lua",
}
local IBF, PAIN = 48792, 33206

describe("SecretTracks", function()
    local ns, w

    local function member(guid, unit, class, spec, talents)
        return { guid = guid, unit = unit, class = class, spec = spec, talents = talents }
    end

    local function roster()
        return {
            member("P", "player", "PALADIN", 66, {}),
            member("A", "party1", "DEATHKNIGHT", 250, { [IBF] = 1 }),
            member("B", "party2", "PRIEST", 256, { [PAIN] = 1 }),
        }
    end

    local function fakeLayer()
        local l = { writes = {}, phases = {} }
        function l:Configure(cd, dur, U) self.config = { cd, dur, U } end
        function l:Write(slot, v) self.writes[slot] = { stamp = v.stamp, coolLo = v.coolLo, coolHi = v.coolHi, gateLo = v.gateLo } end
        function l:SetPhase(a, i) self.phases[#self.phases + 1] = { a, i } end
        return l
    end

    local function track(guid, spell)
        return ns.SecretTracks.Track(guid, spell)
    end

    before_each(function()
        w = { now = 1000, combat = false, lit = {}, made = {}, mask = {} }
        ns = helpers.load(FILES, {
            GetTime = function() return w.now end,
            InCombatLockdown = function() return w.combat end,
            UnitGUID = function(u) return u == "player" and "P" or nil end,
            C_CurveUtil = { EvaluateColorValueFromBoolean = function(b, t, f) if b then return t end return f end },
            C_Timer = { NewTicker = function() return { Cancel = function() end } end, After = function() end },
        })
        ns.Probes = {
            New = function(unit, filter, ids)
                local p = { unit = unit, filter = filter, ids = ids, on = true }
                w.made[#w.made + 1] = p
                return p
            end,
            Lit = function(p) return w.lit[p.unit .. ":" .. p.ids[1]] or false end,
            Point = function(p, unit) p.unit = unit end,
            Enable = function(p, on) p.on = on end,
        }
        ns.tracker = { UsedWithin = function(_, guid, spell) return guid == "P" and w.mask[spell] or false end }
        ns.SecretTracks.Rebuild(roster())
    end)

    local function settle()
        w.now = w.now + 1
        ns.SecretTracks.Tick(w.now)
    end

    it("stamps a rising edge", function()
        settle()
        local t = track("A", IBF)
        w.lit["party1:" .. IBF] = true
        w.now = 1010
        ns.SecretTracks.Tick(w.now)
        local base = t.base
        assert.equal(ns.SecretTime.Code(1010, base.slots[1].epoch, base.U), t.stamps[1])
        local stamp = t.stamps[1]
        w.now = 1011
        ns.SecretTracks.Tick(w.now)
        assert.equal(stamp, t.stamps[1])
    end)

    it("ignores an aura present at attach", function()
        w.lit["party1:" .. IBF] = true
        settle()
        settle()
        assert.equal(0, track("A", IBF).stamps[1])
    end)

    it("external lights on any unit and starts every priest who has it", function()
        local list = roster()
        list[#list + 1] = member("C", "party3", "PRIEST", 256, { [PAIN] = 1 })
        ns.SecretTracks.Rebuild(list)
        settle()
        w.lit["party1:" .. PAIN] = true
        settle()
        assert.is_true(track("B", PAIN).stamps[1] > 0)
        assert.is_true(track("C", PAIN).stamps[1] > 0)
    end)

    it("masks the player's own cast", function()
        local list = roster()
        list[1] = member("P", "player", "PRIEST", 256, { [PAIN] = 1 })
        ns.SecretTracks.Rebuild(list)
        settle()
        w.mask[PAIN] = true
        w.lit["party1:" .. PAIN] = true
        settle()
        assert.equal(0, track("B", PAIN).stamps[1])
    end)

    it("keeps stamps when a member changes unit", function()
        settle()
        w.lit["party1:" .. IBF] = true
        settle()
        local t = track("A", IBF)
        local stamp = t.stamps[1]
        assert.is_true(stamp > 0)
        local list = roster()
        list[2].unit, list[3].unit = "party2", "party1"
        w.lit = { ["party2:" .. IBF] = true }
        ns.SecretTracks.Rebuild(list)
        assert.equal(t, track("A", IBF))
        assert.equal(stamp, t.stamps[1])
        ns.SecretTracks.Tick(w.now + 0.1)
        assert.equal(stamp, t.stamps[1])
    end)

    it("rebuilds the base when the cooldown changes", function()
        settle()
        w.lit["party1:" .. IBF] = true
        settle()
        local t = track("A", IBF)
        t.cd = 1
        ns.SecretTracks.Rebuild(roster())
        assert.equal(0, t.stamps[1])
        assert.equal(120, t.cd)
    end)

    it("defers rebuild in combat", function()
        local before = #w.made
        w.combat = true
        local list = roster()
        list[#list + 1] = member("C", "party3", "DEATHKNIGHT", 250, { [IBF] = 1 })
        ns.SecretTracks.Rebuild(list)
        assert.equal(before, #w.made)
        w.combat = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.is_true(#w.made > before)
    end)

    it("writes windows and phase to bound layers", function()
        local layer = fakeLayer()
        assert.is_true(ns.SecretTracks.Bind(layer, "A", IBF))
        local t = track("A", IBF)
        assert.same({ 120, 8, t.base.U }, layer.config)
        settle()
        w.lit["party1:" .. IBF] = true
        settle()
        local lo, hi = ns.SecretTime.Window(w.now, t.base.slots[1].epoch, t.base.U, 120)
        assert.equal(lo, layer.writes[1].coolLo)
        assert.equal(hi, layer.writes[1].coolHi)
        assert.equal(t.stamps[1], layer.writes[1].stamp)
        assert.same({ 1, 0 }, layer.phases[#layer.phases])
    end)

    it("passes the self-test with a faithful curve", function()
        ns.SecretTracks.SelfTest()
        assert.is_true(ns.SecretTracks.Status().on)
    end)

    it("falls back when the self-test fails", function()
        C_CurveUtil.EvaluateColorValueFromBoolean = function() return 0 end
        ns.SecretTracks.SelfTest()
        local s = ns.SecretTracks.Status()
        assert.is_false(s.on)
        assert.truthy(s.why:find("curve"))
        assert.is_false(ns.SecretTracks.Bind(fakeLayer(), "A", IBF))
    end)

    it("does not bind guids outside the live roster", function()
        assert.is_false(ns.SecretTracks.Bind(fakeLayer(), "Z", IBF))
        assert.is_false(ns.SecretTracks.Bind(fakeLayer(), "P", IBF))
    end)
end)
