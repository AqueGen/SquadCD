local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Logic/Preview.lua", "UI/Wizard.lua" }

describe("Wizard opens once", function()
    local ns, W, combat, editing, shown, printed, timers

    local function runTimers()
        local due = timers
        timers = {}
        for _, fn in ipairs(due) do fn() end
    end

    local function login(db)
        ns.DB = ns.Defaults(db)
        helpers.fire("PLAYER_LOGIN")
        helpers.fire("PLAYER_ENTERING_WORLD", true, false)
        runTimers()
        return ns.DB
    end

    before_each(function()
        combat, editing, shown, printed, timers = false, false, 0, {}, {}
        ns = helpers.load(FILES, {
            InCombatLockdown = function() return combat end,
            print = function(s) printed[#printed + 1] = s end,
            C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end },
        })
        W = ns.Wizard
        W.Show = function() shown = shown + 1 end
        W.IsOpen = function() return false end
        ns.EditMode = {
            Panels = function() return editing end,
            Members = function() return false end,
        }
    end)

    it("opens on a new install and not on the next login", function()
        local db = login({})
        assert.are.equal(1, shown)
        assert.is_nil(db.wizardDue)
        login(db)
        assert.are.equal(1, shown)
    end)

    it("opens after the entering-world handlers, which close every special window", function()
        ns.DB = ns.Defaults({})
        helpers.fire("PLAYER_LOGIN")
        helpers.fire("PLAYER_ENTERING_WORLD", true, false)
        assert.are.equal(0, shown)
        runTimers()
        assert.are.equal(1, shown)
    end)

    it("keeps the offer when showing the wizard fails", function()
        W.Show = function() error("boom") end
        assert.has_error(function() login({}) end)
        assert.is_true(ns.DB.wizardDue)
    end)

    it("opens once after a v1 migration", function()
        local db = login({ placement = { Kick = "Panel" }, row = { side = "LEFT", size = 24 } })
        assert.are.equal(1, shown)
        assert.is_nil(db.wizardDue)
        login(db)
        assert.are.equal(1, shown)
    end)

    it("stays closed for a layout that is already v2", function()
        login({ version = 2, layout = ns.LayoutModel.Defaults() })
        assert.are.equal(0, shown)
    end)

    it("waits for the end of combat", function()
        combat = true
        local db = login({})
        assert.are.equal(0, shown)
        assert.is_true(db.wizardDue)
        combat = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, shown)
        assert.is_nil(db.wizardDue)
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, shown)
    end)

    it("does not open while an edit mode is on", function()
        editing = true
        local db = login({})
        assert.are.equal(0, shown)
        assert.is_true(db.wizardDue)
        editing = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, shown)
    end)

    it("opened by hand in combat opens after combat", function()
        login({ version = 2, layout = ns.LayoutModel.Defaults() })
        combat = true
        W.Open()
        assert.are.equal(0, shown)
        assert.are.equal(1, #printed)
        combat = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(1, shown)
    end)

    it("opened by hand during an edit mode says so and stays closed", function()
        login({ version = 2, layout = ns.LayoutModel.Defaults() })
        editing = true
        W.Open()
        assert.are.equal(0, shown)
        assert.are.equal(1, #printed)
        editing = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.are.equal(0, shown)
    end)
end)
