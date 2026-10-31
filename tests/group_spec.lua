-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\][^/\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/Persist.lua", "Game/Inspect.lua", "Game/Group.lua" }

local function game(mode, units, extra)
    units = units or {
        player = { guid = "P", class = "PALADIN", role = "TANK", race = 1 },
        party1 = mode ~= "solo" and { guid = "A", class = "PRIEST", role = "HEALER", race = 10 } or nil,
    }
    local stubs = {
        IsInRaid = function() return mode == "raid" end,
        IsInGroup = function() return mode ~= "solo" end,
        IsInInstance = function() return false, "none" end,
        UnitGUID = function(u) return units[u] and units[u].guid end,
        UnitClass = function(u) if units[u] then return "x", units[u].class, 0 end end,
        UnitGroupRolesAssigned = function(u) return units[u] and units[u].role or "NONE" end,
        UnitRace = function(u) if units[u] then return "x", "X", units[u].race end end,
        GetTime = function() return 100 end,
        GetServerTime = function() return 1000000 end,
        C_SpecializationInfo = {
            GetSpecialization = function() return 2 end,
            GetSpecializationInfo = function() return 66 end,
        },
        C_ClassTalents = { GetActiveConfigID = function() return nil end },
    }
    for k, v in pairs(extra or {}) do stubs[k] = v end
    return stubs
end

local function start(mode, units, extra)
    local ns = helpers.load(FILES, game(mode, units, extra))
    helpers.fire("ADDON_LOADED", "SquadCD")
    ns.DB.timers = { A = { [33206] = { usedServer = 1000000, spent = 1 } } }
    local rosters = {}
    ns.Group.OnRoster = function(list) rosters[#rosters + 1] = list end
    helpers.fire("PLAYER_LOGIN")
    helpers.fire("PLAYER_ENTERING_WORLD")
    return ns, rosters
end

describe("Group", function()
    it("role guess picks the single tank spec of a class", function()
        local ns = helpers.load(FILES, game("party"))
        assert.are.equal(66, ns.Group.GuessSpec("PALADIN", "TANK"))
        assert.are.equal(70, ns.Group.GuessSpec("PALADIN", "DAMAGER"))
        assert.is_nil(ns.Group.GuessSpec("PRIEST", "HEALER"))
        assert.is_nil(ns.Group.GuessSpec("MAGE", "TANK"))
        assert.is_nil(ns.Group.GuessSpec("PALADIN", "NONE"))
    end)

    it("raid roster idles", function()
        local ns, rosters = start("raid")
        assert.are.equal("raid", ns.Group.Mode())
        assert.are.equal(1, #rosters)
        assert.are.same({}, rosters[1])
        assert.are.same({}, ns.tracker.order)
        assert.is_nil(ns.Persist.tracker)
    end)

    it("party roster feeds the tracker and loads saved timers once", function()
        local ns, rosters = start("party")
        assert.are.equal("party", ns.Group.Mode())
        local list = rosters[1]
        assert.are.equal(2, #list)
        assert.are.equal("P", list[1].guid)
        assert.are.equal(66, list[1].spec)
        assert.are.equal("A", list[2].guid)
        assert.is_nil(list[2].spec)
        assert.are.same({ "P", "A" }, ns.tracker.order)
        assert.are.equal(ns.tracker, ns.Persist.tracker)
        assert.is_false(ns.tracker:State("A", 33206).ready)
        local loads = 0
        ns.Persist.Load = function() loads = loads + 1 end
        helpers.fire("GROUP_ROSTER_UPDATE")
        assert.are.equal(0, loads)
        assert.are.equal(2, #rosters)
    end)

    it("members carry the race id", function()
        local _, rosters = start("party")
        assert.are.equal(1, rosters[1][1].race)
        assert.are.equal(10, rosters[1][2].race)
    end)

    it("secret race is left out", function()
        local _, rosters = start("party", nil, { issecretvalue = function(v) return v == 10 end })
        assert.are.equal(2, #rosters[1])
        assert.is_nil(rosters[1][2].race)
    end)

    it("solo roster with show always holds the player only and does not load", function()
        local ns, rosters = start("solo")
        assert.are.equal("solo", ns.Group.Mode())
        assert.are.equal(1, #rosters[1])
        assert.are.equal("P", rosters[1][1].guid)
        assert.are.equal(66, rosters[1][1].spec)
        assert.are.same({ "P" }, ns.tracker.order)
        assert.is_nil(ns.Persist.tracker)
    end)

    it("solo roster with show always follows the player's spec change", function()
        local spec = 66
        local ns, rosters = start("solo", nil, {
            C_SpecializationInfo = { GetSpecialization = function() return 1 end, GetSpecializationInfo = function() return spec end },
        })
        spec = 70
        helpers.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        assert.are.equal(70, rosters[#rosters][1].spec)
        assert.are.equal(70, ns.tracker.members.P.spec)
    end)

    it("solo roster with show only in a group stays empty", function()
        local ns = helpers.load(FILES, game("solo"))
        helpers.fire("ADDON_LOADED", "SquadCD")
        ns.DB.layout.showWhen = "group"
        local rosters = {}
        ns.Group.OnRoster = function(list) rosters[#rosters + 1] = list end
        helpers.fire("PLAYER_LOGIN")
        helpers.fire("PLAYER_ENTERING_WORLD")
        assert.are.same({}, rosters[1])
        helpers.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        assert.are.equal(1, #rosters)
    end)

    it("changing showWhen and refreshing switches the solo list at once", function()
        local ns, rosters = start("solo")
        ns.DB.layout.showWhen = "group"
        ns.Group.Refresh()
        assert.are.same({}, rosters[#rosters])
        assert.are.same({}, ns.tracker.order)
        ns.DB.layout.showWhen = "always"
        ns.Group.Refresh()
        assert.are.equal("P", rosters[#rosters][1].guid)
    end)

    it("party roster ignores showWhen", function()
        local ns, rosters = start("party")
        ns.DB.layout.showWhen = "group"
        ns.Group.Refresh()
        assert.are.equal(2, #rosters[#rosters])
    end)
end)

describe("Inspect", function()
    it("talent entries map to spell ids", function()
        local ns = helpers.load(FILES, game("party"))
        local talents = ns.Inspect.MapNodes({
            { activeEntry = { entryID = 24540, rank = 2 } },
            { activeEntry = { entryID = 51794, rank = 1 }, subTreeID = 1, subTreeActive = false },
            { activeEntry = { entryID = 1, rank = 1 } },
            { activeEntry = { entryID = 24540, rank = 0 } },
            {},
        })
        assert.are.same({ [394207] = 2 }, talents)
    end)

    it("secret talent data reports secret", function()
        local ns = helpers.load(FILES, game("party"))
        _G.issecretvalue = function(v) return v == 24540 end
        local talents, why = ns.Inspect.MapNodes({ { activeEntry = { entryID = 24540, rank = 2 } } })
        assert.is_nil(talents)
        assert.are.equal("secret", why)
    end)
end)

describe("Group status", function()
    it("secret roster reports secret and does not load", function()
        local ns = helpers.load(FILES, game("party"))
        _G.issecretvalue = function(v) return v == "A" end
        helpers.fire("ADDON_LOADED", "SquadCD")
        helpers.fire("PLAYER_LOGIN")
        helpers.fire("GROUP_ROSTER_UPDATE")
        assert.are.equal("secret", ns.Group.Status())
        assert.is_nil(ns.Persist.tracker)
    end)

    it("partial secret roster keeps the previous member list", function()
        local ns, rosters = start("party")
        _G.issecretvalue = function(v) return v == "A" end
        helpers.fire("GROUP_ROSTER_UPDATE")
        assert.are.equal("secret", ns.Group.Status())
        assert.are.same({ "P", "A" }, ns.tracker.order)
        assert.are.equal(2, #rosters[#rosters])
    end)

    it("no player spec yet leaves the spec to the guess", function()
        local units = { player = { guid = "P", class = "PRIEST", role = "NONE" }, party1 = { guid = "A", class = "PRIEST", role = "HEALER" } }
        local ns, rosters = start("party", units, {
            C_SpecializationInfo = { GetSpecialization = function() return nil end, GetSpecializationInfo = error },
        })
        assert.is_nil(ns.Group.Status())
        assert.is_nil(rosters[1][1].spec)
    end)
end)

describe("Inspect queue", function()
    local ns, I, s, env, guids, ready

    before_each(function()
        ns = helpers.load(FILES, game("party"))
        I = ns.Inspect
        s = I.NewState()
        guids, ready = { party1 = "A", party2 = "B" }, { party1 = true, party2 = true }
        env = { guid = function(u) return guids[u] end, ready = function(u) return ready[u] end }
    end)

    it("five tries per guid with backoff, kept across re-queues", function()
        I.Add(s, "A", "party1")
        for i = 1, 4 do
            I.Fail(s, "A", 100)
            assert.are.equal(115, s.queue.A.at)
            assert.is_true(I.Add(s, "A", "party1"))
        end
        I.Fail(s, "A", 100)
        assert.is_nil(s.queue.A)
        assert.is_false(I.Add(s, "A", "party1"))
    end)

    it("re-queue refreshes the unit token", function()
        I.Add(s, "A", "party1")
        I.Add(s, "A", "party2")
        assert.are.equal("party2", s.queue.A.unit)
    end)

    it("step drops a stale unit", function()
        I.Add(s, "A", "party2")
        assert.is_nil((I.Step(s, 100, env)))
        assert.is_nil(s.queue.A)
    end)

    it("step sends one at a time, spaces sends and times out", function()
        I.Add(s, "A", "party1")
        I.Add(s, "B", "party2")
        local action, unit = I.Step(s, 100, env)
        assert.are.equal("send", action)
        local first = s.inFlight.guid
        local what, wait = I.Step(s, 101, env)
        assert.are.same({ "wait", 4 }, { what, wait })
        assert.are.equal(unit, I.Ready(s, first, 102))
        assert.are.same({ "wait", 2 }, { I.Step(s, 102, env) })
        s.queue[first] = nil
        assert.are.equal("send", (I.Step(s, 104, env)))
        local second = s.inFlight.guid
        assert.are.same({ "wait", 15 }, { I.Step(s, 109, env) })
        assert.are.equal(1, s.tries[second])
        assert.are.equal(124, s.queue[second].at)
    end)

    it("unreachable unit counts as a failed try", function()
        ready.party1 = false
        I.Add(s, "A", "party1")
        assert.are.same({ "wait", 15 }, { I.Step(s, 100, env) })
        assert.are.equal(1, s.tries.A)
    end)
end)

describe("Inspect results", function()
    local timers, sent, units, valid

    local function inspectGame()
        timers, sent, valid = {}, {}, false
        units = {
            player = { guid = "P", class = "PALADIN", role = "TANK" },
            party1 = { guid = "A", class = "PRIEST", role = "HEALER" },
        }
        return {
            IsInInstance = function() return true, "party" end,
            C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end },
            CanInspect = function() return true end,
            UnitIsConnected = function() return true end,
            NotifyInspect = function(u) sent[#sent + 1] = u end,
            ClearInspectPlayer = function() end,
            Constants = { TraitConsts = { INSPECT_TRAIT_CONFIG_ID = -1 } },
            C_Traits = {
                HasValidInspectData = function() return valid end,
                GetConfigInfo = function() return { treeIDs = { 7 } } end,
                GetTreeNodes = function() return { 1 } end,
                GetNodeInfo = function() return { activeEntry = { entryID = 24540, rank = 1 } } end,
            },
        }
    end

    local function begin()
        local extra = inspectGame()
        extra.C_SpecializationInfo = {
            GetSpecialization = function() return 2 end,
            GetSpecializationInfo = function() return 66 end,
            GetInspectSpecialization = function() return 256 end,
        }
        local ns, rosters = start("party", units, extra)
        timers[#timers]()
        assert.are.same({ "party1" }, sent)
        return ns, rosters
    end

    it("invalid inspect data keeps talents unknown and retries", function()
        local ns, rosters = begin()
        helpers.fire("INSPECT_READY", "A")
        local a = rosters[#rosters][2]
        assert.are.equal(256, a.spec)
        assert.is_nil(a.talents)
        assert.are.equal(256, ns.tracker.members.A.spec)
        assert.are.equal(1, ns.Inspect.state.tries.A)
        assert.is_not_nil(ns.Inspect.state.queue.A)
    end)

    it("valid inspect data stores talents and leaves the queue", function()
        local ns, rosters = begin()
        valid = true
        helpers.fire("INSPECT_READY", "A")
        assert.are.same({ [394207] = 1 }, rosters[#rosters][2].talents)
        assert.is_nil(ns.Inspect.state.queue.A)
        helpers.fire("GROUP_ROSTER_UPDATE")
        assert.is_nil(ns.Inspect.state.queue.A)
    end)

    it("stale unit at INSPECT_READY is a failed try and re-resolves the unit", function()
        local ns, rosters = begin()
        local before = #rosters
        units.party2, units.party1 = units.party1, nil
        helpers.fire("INSPECT_READY", "A")
        assert.are.equal(before, #rosters)
        assert.are.equal(1, ns.Inspect.state.tries.A)
        assert.are.equal("party2", ns.Inspect.state.queue.A.unit)
    end)
end)
