local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local function loadCore(stubs)
    return helpers.load({ "Core.lua" }, stubs)
end

describe("Core", function()
    it("Defaults fills missing keys", function()
        local ns = loadCore()
        local db = ns.Defaults({})
        assert.are.equal(1, db.version)
        assert.are.equal("Row", db.placement.Personal)
        assert.are.equal("Panel", db.placement.Kick)
        assert.are.equal("Off", db.placement.Movement)
        assert.are.equal("LEFT", db.row.side)
        assert.are.equal(8, db.row.max)
        assert.are.same({ "CENTER", 0, -200 }, db.panel.point)
        assert.are.same({}, db.spells)
        assert.are.same({}, db.window)
        assert.are.same({}, db.timers)
        assert.is_nil(db.seenWhatsNew)
    end)

    it("Defaults keeps user values", function()
        local ns = loadCore()
        local db = ns.Defaults({ placement = { Kick = "Off" }, row = { size = 40 } })
        assert.are.equal("Off", db.placement.Kick)
        assert.are.equal("Row", db.placement.Burst)
        assert.are.equal(40, db.row.size)
        assert.are.equal(2, db.row.spacing)
    end)

    it("Defaults does not share tables with DEFAULTS", function()
        local ns = loadCore()
        local db = ns.Defaults({})
        db.placement.Kick = "Off"
        db.panel.point[2] = 99
        assert.are.equal("Panel", ns.DEFAULTS.placement.Kick)
        assert.are.equal(0, ns.DEFAULTS.panel.point[2])
    end)

    it("module Enable errors do not stop later modules", function()
        local errors = {}
        local ns = loadCore({ geterrorhandler = function() return function(e) errors[#errors + 1] = e end end })
        local second = false
        ns.RegisterModule("bad", { Enable = function() error("boom") end })
        ns.RegisterModule("good", { Enable = function() second = true end })
        helpers.fire("ADDON_LOADED", "Huddle")
        helpers.fire("PLAYER_LOGIN")
        assert.is_true(second)
        assert.are.equal(1, #errors)
        assert.is_truthy(tostring(errors[1]):find("boom", 1, true))
    end)

    it("Enable runs in registration order", function()
        local ns = loadCore()
        local order = {}
        ns.RegisterModule("a", { Enable = function() order[#order + 1] = "a" end })
        ns.RegisterModule("b", { Enable = function() order[#order + 1] = "b" end })
        helpers.fire("ADDON_LOADED", "Huddle")
        helpers.fire("PLAYER_LOGIN")
        assert.are.same({ "a", "b" }, order)
    end)

    it("slash registered before Enable", function()
        local ns = loadCore()
        local seen = false
        ns.RegisterModule("m", {
            Enable = function()
                assert(type(SlashCmdList.HUDDLE) == "function", "slash not registered")
                seen = true
            end,
        })
        helpers.fire("ADDON_LOADED", "Huddle")
        helpers.fire("PLAYER_LOGIN")
        assert.is_true(seen)
    end)

    it("helpers.load restores stubbed globals on the next load", function()
        local original = print
        loadCore({ print = function() end })
        assert.are_not.equal(original, print)
        loadCore()
        assert.are.equal(original, print)
    end)

    it("unknown subcommand prints usage listing subcommands", function()
        local lines = {}
        local ns = loadCore({ print = function(s) lines[#lines + 1] = s end })
        ns.Slash("status", function() end)
        SlashCmdList.HUDDLE("nope")
        assert.are.equal(1, #lines)
        assert.is_truthy(lines[1]:find("status", 1, true))
    end)

    it("bare /huddle toggles the window and subcommands dispatch", function()
        local ns = loadCore()
        local toggled, got = 0, nil
        ns.ToggleWindow = function() toggled = toggled + 1 end
        ns.Slash("status", function(rest) got = rest end)
        SlashCmdList.HUDDLE("")
        SlashCmdList.HUDDLE("Status  now")
        assert.are.equal(1, toggled)
        assert.are.equal("now", got)
    end)

    it("sets ns.DB from HuddleDB on ADDON_LOADED", function()
        local ns = loadCore()
        _G.HuddleDB = { placement = { Kick = "Off" } }
        helpers.fire("ADDON_LOADED", "Huddle")
        assert.are.equal(_G.HuddleDB, ns.DB)
        assert.are.equal("Off", ns.DB.placement.Kick)
        assert.are.equal("Row", ns.DB.placement.Burst)
    end)
end)
