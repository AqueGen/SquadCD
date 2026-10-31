local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local function loadCore(stubs)
    return helpers.load({ "Logic/LayoutModel.lua", "Core.lua" }, stubs)
end

describe("Core", function()
    it("Defaults fills missing keys", function()
        local ns = loadCore()
        local db = ns.Defaults({})
        assert.are.equal(2, db.version)
        assert.are.same(ns.LayoutModel.Defaults(), db.layout)
        assert.are.same({ point = { "CENTER", -360, 120 } }, db.row)
        assert.is_nil(db.placement)
        assert.is_nil(db.panel)
        assert.are.same({}, db.spells)
        assert.are.same({}, db.window)
        assert.are.same({}, db.timers)
        assert.is_nil(db.seenWhatsNew)
    end)

    it("Defaults moves v1 values into the layout and drops the v1 fields", function()
        local ns = loadCore()
        local db = ns.Defaults({ placement = { Kick = "Off" }, row = { size = 40, point = { "TOP", 1, 2 } }, panel = { point = { "TOP", 3, 4 } } })
        assert.are.equal("off", (ns.LayoutModel.PlaceOf(db.layout, "Kick")))
        assert.are.equal("member", (ns.LayoutModel.PlaceOf(db.layout, "Burst")))
        assert.are.equal(40, db.layout.groups[1].look.iconSize)
        assert.are.same({ "TOP", 3, 4 }, db.layout.panel.point)
        assert.are.same({ point = { "TOP", 1, 2 } }, db.row)
        assert.is_nil(db.placement)
        assert.is_nil(db.panel)
    end)

    it("Defaults migrates a v1 db and never refills a saved layout", function()
        local ns = loadCore()
        local db = ns.Defaults({ placement = { Kick = "Off" }, timers = { a = 5 } })
        assert.are.equal("off", (ns.LayoutModel.PlaceOf(db.layout, "Kick")))
        assert.are.same({ a = 5 }, db.timers)
        db.layout.sections = { db.layout.sections[1] }
        ns.Defaults(db)
        assert.are.equal(1, #db.layout.sections)
    end)

    it("Defaults does not share tables with DEFAULTS", function()
        local ns = loadCore()
        local db = ns.Defaults({})
        db.row.point[2] = 99
        assert.are.equal(-360, ns.DEFAULTS.row.point[2])
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
        assert.are.equal("off", (ns.LayoutModel.PlaceOf(ns.DB.layout, "Kick")))
    end)
end)
