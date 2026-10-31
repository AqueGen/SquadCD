local here = debug.getinfo(1, "S").source:match("^@(.*)[/\][^/\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/Persist.lua", "Game/Inspect.lua", "Game/Group.lua" }

local function game(mode)
    local units = {
        player = { guid = "P", class = "PALADIN", role = "TANK" },
        party1 = { guid = "A", class = "PRIEST", role = "HEALER" },
    }
    return {
        IsInRaid = function() return mode == "raid" end,
        IsInGroup = function() return mode ~= "solo" end,
        IsInInstance = function() return false, "none" end,
        UnitGUID = function(u) return units[u] and units[u].guid end,
        UnitClass = function(u) if units[u] then return "x", units[u].class, 0 end end,
        UnitGroupRolesAssigned = function(u) return units[u] and units[u].role or "NONE" end,
        GetTime = function() return 100 end,
        GetServerTime = function() return 1000000 end,
        C_SpecializationInfo = {
            GetSpecialization = function() return 2 end,
            GetSpecializationInfo = function() return 66 end,
        },
        C_ClassTalents = { GetActiveConfigID = function() return nil end },
    }
end

local function start(mode)
    local ns = helpers.load(FILES, game(mode))
    helpers.fire("ADDON_LOADED", "Huddle")
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

    it("solo roster stays empty and does not load", function()
        local ns, rosters = start("solo")
        assert.are.equal("solo", ns.Group.Mode())
        assert.are.same({}, rosters[1])
        assert.is_nil(ns.Persist.tracker)
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
