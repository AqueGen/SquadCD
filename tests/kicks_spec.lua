local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/Persist.lua",
    "Game/Inspect.lua", "Game/Group.lua", "Game/OwnCasts.lua", "Game/Kicks.lua",
}

describe("Kicks.Attribute", function()
    local ns
    before_each(function() ns = helpers.load(FILES) end)

    it("one riser attributed", function()
        assert.equal("B", ns.Kicks.Attribute({ A = 1, B = 0 }, { A = 1, B = 1 }))
    end)

    it("two risers unattributed", function()
        assert.is_nil(ns.Kicks.Attribute({ A = 0, B = 0 }, { A = 1, B = 1 }))
    end)

    it("no change unattributed", function()
        assert.is_nil(ns.Kicks.Attribute({ A = 1 }, { A = 1 }))
    end)
end)

describe("OwnCasts", function()
    local SECRET = {}
    local ns, used

    before_each(function()
        ns = helpers.load(FILES, { UnitGUID = function() return "P" end })
        used = {}
        ns.tracker = { Used = function(_, guid, id, certain) used[#used + 1] = { guid, id, certain } end }
        ns.OwnCasts.Enable()
    end)

    it("known spell is certain use", function()
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 642)
        assert.same({ { "P", 642, true } }, used)
    end)

    it("replaced spell maps to lowest tracked id", function()
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 106898)
        assert.equal(77761, used[1][2])
    end)

    it("secret spell id is counted and ignored", function()
        _G.issecretvalue = function(v) return v == SECRET end
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", SECRET)
        assert.equal(0, #used)
        assert.equal(1, ns.OwnCasts.Stats().secret)
    end)
end)
