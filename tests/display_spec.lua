local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/LayoutGrid.lua", "Logic/LayoutRules.lua",
    "Game/Inspect.lua", "Game/Group.lua", "UI/Display.lua",
}

describe("Display combat end", function()
    local ns, builds, changed, combat, timers

    before_each(function()
        builds, changed, combat, timers = 0, false, false, {}
        ns = helpers.load(FILES, {
            InCombatLockdown = function() return combat end,
            UnitGUID = function() return "P" end,
            UnitName = function() return "Name" end,
            GetTime = function() return 100 end,
            C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end },
        })
        ns.DB = ns.Defaults({})
        ns.Rows = { Build = function() builds = builds + 1 end, Update = function() end, Hide = function() end }
        ns.Panel = { Build = function() end, Update = function() end, Hide = function() end }
        ns.Anchors = { Scan = function() return changed end }
        ns.EditMode = { Refresh = function() end }
        local tracker = ns.Tracker.New(function() return 100 end)
        ns.Display.SetSource({ members = { { guid = "P", unit = "player", class = "PALADIN", spec = 66 } }, tracker = tracker })
        builds = 0
    end)

    it("does not rebuild when nothing changed", function()
        helpers.fire("PLAYER_REGEN_ENABLED")
        for _, fn in ipairs(timers) do fn() end
        assert.are.equal(0, builds)
    end)

    it("rebuilds once when anchors changed", function()
        changed = true
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, builds)
    end)

    it("rebuilds once for a change made in combat", function()
        combat = true
        ns.Display.Rebuild()
        combat = false
        timers = {}
        helpers.fire("PLAYER_REGEN_ENABLED")
        for _, fn in ipairs(timers) do fn() end
        assert.are.equal(1, builds)
    end)
end)
