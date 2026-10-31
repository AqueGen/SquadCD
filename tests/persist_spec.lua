-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\][^/\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Persistence", function()
    local server, clock
    local ns
    local PS, SEF = 33206, 137639
    local now, t

    local function members()
        return {
            { guid = "A", unit = "party1", class = "PRIEST", spec = 256, talents = { [PS] = 1 } },
            { guid = "B", unit = "party2", class = "PRIEST", spec = 256, talents = { [PS] = 1 } },
            { guid = "C", unit = "party3", class = "MONK", spec = 269, talents = {} },
        }
    end

    local function fresh(clockStart)
        now = clockStart
        local tr = ns.Tracker.New(function() return now end)
        tr:SetMembers(members())
        return tr
    end

    before_each(function()
        server, clock = 1000000, 100
        ns = helpers.load({ "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/Persist.lua" }, {
            GetServerTime = function() return server end,
            GetTime = function() return clock end,
        })
        ns.DB = ns.Defaults({})
        t = fresh(100)
    end)

    it("restores running timer after reload", function()
        t:Used("A", PS, true)
        now = 130
        local snap = t:Snapshot(1000030, 130)
        assert.are.equal(1000000, snap.A[PS].usedServer)
        local t2 = fresh(5000)
        t2:Restore(snap, 1000060, 5000)
        local s = t2:State("A", PS)
        assert.is_false(s.ready)
        assert.are.equal(120, s.remaining)
        now = 5120
        assert.is_true(t2:State("A", PS).ready)
    end)

    it("restores charges and a maybe use that a later sighting can confirm", function()
        t:Used("C", SEF, true)
        now = 110
        t:Used("C", SEF, false)
        local snap = t:Snapshot(1000010, 110)
        local t2 = fresh(900)
        t2:Restore(snap, 1000010, 900)
        local s = t2:State("C", SEF)
        assert.are.equal(0, s.charges)
        assert.is_true(s.maybe)
        t2:Confirm("C", SEF)
        assert.is_false(t2:State("C", SEF).maybe)
    end)

    it("restored maybe is cleared by a certain sighting of another member", function()
        t:External(PS, "C")
        assert.is_true(t:State("A", PS).maybe)
        local snap = t:Snapshot(1000000, 100)
        local t2 = fresh(100)
        t2:Restore(snap, 1000000, 100)
        t2:Used("A", PS, true)
        assert.is_false(t2:State("B", PS).maybe)
        assert.is_true(t2:State("B", PS).ready)
    end)

    it("drops members no longer in group", function()
        t:Used("A", PS, true)
        t:Used("B", PS, true)
        local snap = t:Snapshot(1000000, 100)
        local t2 = fresh(100)
        t2:SetMembers({ members()[1] })
        t2:Restore(snap, 1000000, 100)
        assert.is_false(t2:State("A", PS).ready)
        assert.is_nil(t2.entries.B)
    end)

    it("drops stale entries", function()
        t:Used("A", PS, true)
        local snap = t:Snapshot(1000000, 100)
        local t2 = fresh(100)
        t2:Restore(snap, 1000180, 100)
        assert.is_nil(t2.entries.A)
        assert.is_true(t2:State("A", PS).ready)
    end)

    it("saves on logout and loads into a tracker", function()
        ns.Persist.Load(t)
        t:Used("A", PS, true)
        now, clock, server = 110, 110, 1000010
        helpers.fire("PLAYER_LOGOUT")
        assert.are.equal(1000000, ns.DB.timers.A[PS].usedServer)
        local t2 = fresh(7000)
        clock, server = 7000, 1000050
        ns.Persist.Load(t2)
        assert.are.equal(130, t2:State("A", PS).remaining)
    end)

    it("logout without a tracker keeps the saved timers", function()
        ns.DB.timers = { A = { [PS] = { usedServer = 1, spent = 1 } } }
        ns.Persist.tracker = nil
        helpers.fire("PLAYER_LOGOUT")
        assert.is_not_nil(ns.DB.timers.A)
    end)
end)
