local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Tracker", function()
    local ns = helpers.load({ "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua" })
    local now, t
    local PS, PURIFY, SEF = 33206, 527, 137639

    local function members()
        return {
            { guid = "A", unit = "party1", class = "PRIEST", spec = 256, talents = { [PS] = 1 } },
            { guid = "B", unit = "party2", class = "PRIEST", spec = 256, talents = { [PS] = 1 } },
            { guid = "C", unit = "party3", class = "MONK", spec = 269, talents = {} },
        }
    end

    before_each(function()
        now = 100
        t = ns.Tracker.New(function() return now end)
        t:SetMembers(members())
    end)

    it("state and tick reuse the resolved cooldown until the roster changes", function()
        local real, calls = ns.Cooldowns.Resolve, 0
        ns.Cooldowns.Resolve = function(...)
            calls = calls + 1
            return real(...)
        end
        t:Used("A", PS, true)
        local buf = {}
        for _ = 1, 5 do
            t:Tick()
            t:State("A", PS, buf)
        end
        assert.are.equal(1, calls)
        t:SetMembers(members())
        t:State("A", PS, buf)
        ns.Cooldowns.Resolve = real
        assert.are.equal(2, calls)
    end)

    it("use of a replaced base lands on the shown replacer", function()
        t:SetMembers({ { guid = "H", unit = "party1", class = "PALADIN", spec = 65, talents = { [633] = 1 } } })
        t:Used("H", 633, true)
        assert.is_false(t:State("H", 471195).ready)
    end)

    it("used starts cooldown", function()
        t:Used("A", PS, true)
        local s = t:State("A", PS)
        assert.is_false(s.ready)
        assert.are.equal(180, s.remaining)
        assert.are.equal(0, s.charges)
        assert.is_false(s.maybe)
        assert.is_true(s.talentsKnown)
    end)

    it("ready after cd", function()
        t:Used("A", PS, true)
        now = 100 + 179
        assert.is_false(t:State("A", PS).ready)
        now = 100 + 180
        local s = t:State("A", PS)
        assert.is_true(s.ready)
        assert.are.equal(0, s.remaining)
        assert.are.equal(1, s.charges)
    end)

    it("charges recharge one at a time", function()
        t:Used("C", SEF, true)
        now = 110
        t:Used("C", SEF, true)
        local s = t:State("C", SEF)
        assert.are.equal(0, s.charges)
        assert.is_false(s.ready)
        assert.are.equal(80, s.remaining)
        now = 190
        s = t:State("C", SEF)
        assert.are.equal(1, s.charges)
        assert.is_true(s.ready)
        now = 280
        assert.are.equal(2, t:State("C", SEF).charges)
    end)

    it("charge left reports the recharge time", function()
        t:Used("C", SEF, true)
        now = 130
        local s = t:State("C", SEF)
        assert.is_true(s.ready)
        assert.are.equal(1, s.charges)
        assert.are.equal(0, s.remaining)
        assert.are.equal(60, s.recharge)
        now = 300
        assert.are.equal(0, t:State("C", SEF).recharge)
    end)

    it("State fills a given table", function()
        local out = {}
        t:Used("A", PS, true)
        assert.are.equal(out, t:State("A", PS, out))
        assert.are.equal(180, out.remaining)
        assert.are.equal(180, out.recharge)
    end)

    it("external single candidate is certain", function()
        t:SetMembers({ members()[1], members()[3] })
        t:External(PS, "C")
        local s = t:State("A", PS)
        assert.is_false(s.ready)
        assert.is_false(s.maybe)
    end)

    it("self-cast external with one caster is certain", function()
        t:SetMembers({ members()[1], members()[3] })
        t:External(PS, "A")
        local s = t:State("A", PS)
        assert.is_false(s.ready)
        assert.is_false(s.maybe)
    end)

    it("external on one of two casters is maybe for both", function()
        local BOP = 1022
        t:SetMembers({
            { guid = "A", unit = "party1", class = "PALADIN", spec = 65, talents = { [BOP] = 1 } },
            { guid = "B", unit = "party2", class = "PALADIN", spec = 70, talents = { [BOP] = 1 } },
        })
        t:External(BOP, "A")
        assert.is_true(t:State("A", BOP).maybe)
        assert.is_true(t:State("B", BOP).maybe)
    end)

    it("external without target excludes nobody", function()
        t:External(PS, nil)
        assert.is_true(t:State("A", PS).maybe)
        assert.is_true(t:State("B", PS).maybe)
    end)

    it("external two same-spec healers both maybe", function()
        t:External(PURIFY, "C")
        assert.is_true(t:State("A", PURIFY).maybe)
        assert.is_true(t:State("B", PURIFY).maybe)
        assert.is_false(t:State("A", PURIFY).ready)
    end)

    it("confirm clears the other maybe", function()
        t:External(PURIFY, "C")
        t:Confirm("A", PURIFY)
        assert.is_false(t:State("A", PURIFY).maybe)
        assert.is_false(t:State("A", PURIFY).ready)
        local b = t:State("B", PURIFY)
        assert.is_false(b.maybe)
        assert.is_true(b.ready)
    end)

    it("confirm keeps a maybe from a different use", function()
        t:External(PS, nil)
        now = 120
        t:Confirm("A", PS)
        assert.is_true(t:State("B", PS).maybe)
    end)

    it("members leaving are dropped", function()
        t:Used("B", PS, true)
        t:SetMembers({ members()[1] })
        assert.is_nil(t:State("B", PS))
        t:SetMembers(members())
        assert.is_true(t:State("B", PS).ready)
    end)

    it("potion pseudo-spell uses shared cd", function()
        t:Used("A", "potion", true)
        local s = t:State("A", "potion")
        assert.are.equal(ns.Potions[1].cd, s.remaining)
        assert.are.equal(0, s.charges)
    end)

    it("certain use clears the other maybe", function()
        t:External(PURIFY, "C")
        t:Used("A", PURIFY, true)
        assert.is_true(t:State("B", PURIFY).ready)
        assert.is_false(t:State("B", PURIFY).maybe)
    end)

    it("talent read later adds a charge", function()
        t:Used("A", PS, true)
        assert.is_false(t:State("A", PS).ready)
        local list = members()
        list[1].talents = { [PS] = 1, [373035] = 1 }
        t:SetMembers(list)
        local s = t:State("A", PS)
        assert.is_true(s.ready)
        assert.are.equal(1, s.charges)
    end)

    it("talent read later shortens running timer", function()
        local list = members()
        list[4] = { guid = "D", unit = "party4", class = "WARRIOR", spec = 73, talents = { [871] = 1 } }
        t:SetMembers(list)
        t:Used("D", 871, true)
        assert.are.equal(180, t:State("D", 871).remaining)
        list[4].talents = { [871] = 1, [391271] = 1 }
        t:SetMembers(list)
        assert.are.equal(162, t:State("D", 871).remaining)
    end)

    it("State is read-only so Tick still fires ready", function()
        local calls = 0
        t:Used("A", PS, true)
        t.OnChange = function() calls = calls + 1 end
        now = 100 + 180
        assert.is_true(t:State("A", PS).ready)
        t:Tick()
        assert.are.equal(1, calls)
    end)

    it("confirm of own maybe fires OnChange", function()
        t:External(PURIFY, "C")
        local calls = {}
        t.OnChange = function(g) calls[#calls + 1] = g end
        t:Confirm("A", PURIFY)
        assert.are.same({ "A", "B" }, calls)
    end)

    it("used on a maybe entry restarts", function()
        t:Used("A", PS, false)
        now = 150
        t:Used("A", PS, true)
        local s = t:State("A", PS)
        assert.are.equal(180, s.remaining)
        assert.is_false(s.maybe)
    end)

    it("State creates no entries and unknown entry is ready", function()
        assert.is_true(t:State("A", PS).ready)
        assert.is_nil(t.entries.A)
    end)

    it("unknown spell has no state", function()
        assert.is_nil(t:State("A", 1))
    end)

    it("OnChange fires on use and on ready", function()
        local calls = {}
        t.OnChange = function(g, s) calls[#calls + 1] = g .. ":" .. tostring(s) end
        t:Used("A", PS, true)
        assert.are.same({ "A:" .. PS }, calls)
        now = 100 + 100
        t:Tick()
        assert.are.equal(1, #calls)
        now = 100 + 180
        t:Tick()
        assert.are.same({ "A:" .. PS, "A:" .. PS }, calls)
        t:Tick()
        assert.are.equal(2, #calls)
    end)
end)
