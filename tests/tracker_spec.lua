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

    it("external single candidate is certain", function()
        t:External(PS, "B")
        local s = t:State("A", PS)
        assert.is_false(s.ready)
        assert.is_false(s.maybe)
        assert.is_true(t:State("B", PS).ready)
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
        t:External(PURIFY, "C")
        now = 120
        t:Confirm("A", PURIFY)
        assert.is_true(t:State("B", PURIFY).maybe)
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
