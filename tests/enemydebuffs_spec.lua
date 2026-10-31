local here = debug.getinfo(1, "S").source:match("^@(.*)[/\][^/\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/LayoutRules.lua", "Logic/Persist.lua",
    "Game/Inspect.lua", "Game/Group.lua", "Game/Sensors.lua", "Game/EnemyDebuffs.lua", "Game/Probe.lua",
}

local SECRET = setmetatable({}, { __tostring = function() return "secret" end })
local KIDNEY_SHOT, HAMMER = 408, 853

local function world(opts)
    opts = opts or {}
    local w = { debuffs = {}, containers = {}, timers = {}, combat = false, filters = {}, setUnitCombat = 0, exist = {} }
    w.units = opts.units or {
        player = { guid = "P", class = "PRIEST", role = "HEALER" },
        party1 = { guid = "A", class = "ROGUE", role = "DAMAGER" },
        party2 = { guid = "B", class = "WARRIOR", role = "TANK" },
    }

    local function slotFrame(container, id)
        local s = {}
        function s:IsShown()
            w.reads = (w.reads or 0) + 1
            if w.secret then return SECRET end
            return w.debuffs[container.unit] and w.debuffs[container.unit][id] or false
        end
        function s:IsMouseOver() return false end
        return s
    end

    local function container()
        local c = { slots = {}, enabled = {} }
        function c:SetPoint() end
        function c:EnableMouse() end
        function c:SetEnabled(v) self.on = v end
        function c:SetUnit(u)
            if w.combat then w.setUnitCombat = w.setUnitCombat + 1 end
            self.unit = u
        end
        function c:GetAuraSlotFrame(key) return self.slots[key] end
        function c:SetAuraSlotEnabled(key, v) self.enabled[key] = v end
        function c:AddAuraSlot(key, filter, options)
            assert(not w.combat, "slot added in combat")
            w.filters[filter] = (w.filters[filter] or 0) + 1
            local id = next(options.candidateFilters.includeSpellIDs)
            self.slots[key] = slotFrame(self, id)
            self.enabled[key] = true
            return self.slots[key]
        end
        w.containers[#w.containers + 1] = c
        return c
    end

    local function timer(delay, fn, n)
        local t = { delay = delay, fn = fn, n = n or 1 }
        function t:Cancel() self.cancelled = true end
        w.timers[#w.timers + 1] = t
        return t
    end

    w.stubs = {
        IsInRaid = function() return opts.mode == "raid" end,
        IsInGroup = function() return opts.mode ~= "solo" end,
        IsInInstance = function() return false, "none" end,
        InCombatLockdown = function() return w.combat end,
        UnitGUID = function(u) return w.units[u] and w.units[u].guid end,
        UnitClass = function(u) if w.units[u] then return "x", w.units[u].class, 0 end end,
        UnitGroupRolesAssigned = function(u) return w.units[u] and w.units[u].role or "NONE" end,
        UnitRace = function(u) if w.units[u] then return "x", "X", w.units[u].race end end,
        UnitExists = function(u) return w.exist[u] == true end,
        UnitCanAttack = function() return not w.friendly end,
        GetTime = function() return w.now or 100 end,
        GetServerTime = function() return 1000000 end,
        UIParent = {},
        print = function() end,
        issecretvalue = function(v) return v == SECRET end,
        CreateFrame = function(kind)
            if kind == "AuraContainer" then return container() end
            return helpers.newFrame()
        end,
        C_Timer = {
            After = function(delay, fn) timer(delay, fn, 1) end,
            NewTicker = function(delay, fn, n) return timer(delay, fn, n or math.huge) end,
        },
        C_UnitAuras = { GetAuraDataByIndex = function() end },
        C_SpecializationInfo = {
            GetSpecialization = function() return 1 end,
            GetSpecializationInfo = function() return 256 end,
        },
        C_ClassTalents = { GetActiveConfigID = function() return nil end },
    }

    function w.flush()
        while #w.timers > 0 do
            local list = w.timers
            w.timers = {}
            for _, t in ipairs(list) do
                for _ = 1, t.n do
                    if t.cancelled then break end
                    t.fn()
                end
            end
        end
    end
    return w
end

local function start(opts)
    local w = world(opts)
    local ns = helpers.load(FILES, w.stubs)
    helpers.fire("ADDON_LOADED", "Huddle")
    helpers.fire("PLAYER_LOGIN")
    helpers.fire("PLAYER_ENTERING_WORLD")
    w.flush()
    return ns, w
end

local function plate(w, unit, id, on)
    w.debuffs[unit] = w.debuffs[unit] or {}
    w.debuffs[unit][id] = on
    helpers.fire("UNIT_AURA", unit)
    w.flush()
end

local function add(w, unit)
    w.exist[unit] = true
    helpers.fire("NAME_PLATE_UNIT_ADDED", unit)
    w.flush()
    w.now = (w.now or 100) + 1
end

local function remove(w, unit)
    w.exist[unit] = false
    helpers.fire("NAME_PLATE_UNIT_REMOVED", unit)
end

describe("EnemyDebuffs", function()
    it("debuff from unique class is certain", function()
        local ns, w = start({ mode = "party" })
        add(w, "nameplate1")
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        local state = ns.tracker:State("A", KIDNEY_SHOT)
        assert.is_false(state.ready)
        assert.is_false(state.maybe)
    end)

    it("debuff two candidates maybe", function()
        local ns, w = start({
            mode = "party",
            units = {
                player = { guid = "P", class = "PRIEST", role = "HEALER" },
                party1 = { guid = "A", class = "PALADIN", role = "TANK" },
                party2 = { guid = "B", class = "PALADIN", role = "DAMAGER" },
            },
        })
        add(w, "nameplate1")
        plate(w, "nameplate1", HAMMER, true)
        assert.is_true(ns.tracker:State("A", HAMMER).maybe)
        assert.is_true(ns.tracker:State("B", HAMMER).maybe)
    end)

    it("secret debuff listed not trackable", function()
        local ns, w = start({ mode = "party" })
        w.secret = true
        add(w, "nameplate1")
        w.flush()
        local listed = {}
        for _, e in ipairs(ns.EnemyDebuffs.Status().secret) do listed[e.id] = true end
        assert.is_true(listed[KIDNEY_SHOT])
        assert.is_true(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)

    it("secret debuff id is not read again", function()
        local _, w = start({ mode = "party" })
        w.secret = true
        add(w, "nameplate1")
        local reads = w.reads
        assert.is_true(reads > 0)
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        assert.are.equal(reads, w.reads)
    end)

    it("secret read in combat is read again after combat", function()
        local ns, w = start({ mode = "party" })
        w.combat = true
        w.secret = true
        add(w, "nameplate1")
        assert.is_true(ns.LayoutRules.Unknown(KIDNEY_SHOT, false, true, ns.EnemyDebuffs.SecretIds()))
        w.combat = false
        w.secret = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.is_false(ns.LayoutRules.Unknown(KIDNEY_SHOT, false, true, ns.EnemyDebuffs.SecretIds()))
        plate(w, "nameplate1", KIDNEY_SHOT, false)
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        assert.is_false(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)

    it("repeated aura events extend one poll ticker", function()
        local _, w = start({ mode = "party" })
        w.exist.nameplate1 = true
        helpers.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
        local first = #w.timers
        helpers.fire("UNIT_AURA", "nameplate1")
        helpers.fire("UNIT_AURA", "nameplate1")
        assert.are.equal(first, #w.timers)
    end)

    it("debuff already on the plate when it appears does not fire", function()
        local ns, w = start({ mode = "party" })
        w.debuffs.nameplate1 = { [KIDNEY_SHOT] = true }
        add(w, "nameplate1")
        assert.is_true(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)

    it("one stun on several plates is one use", function()
        local ns, w = start({ mode = "party" })
        add(w, "nameplate1")
        add(w, "nameplate2")
        w.debuffs.nameplate1 = { [KIDNEY_SHOT] = true }
        w.debuffs.nameplate2 = { [KIDNEY_SHOT] = true }
        local n = 0
        ns.tracker.External = function() n = n + 1 end
        helpers.fire("UNIT_AURA", "nameplate1")
        w.flush()
        assert.are.equal(1, n)
    end)

    it("pool is capped and reused", function()
        local ns, w = start({ mode = "party" })
        local before = #w.containers
        assert.are.equal(20, before)
        for i = 1, 25 do add(w, "nameplate" .. i) end
        assert.are.equal(before, #w.containers)
        assert.are.equal(before, #w.containers)
        assert.is_true(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)

    it("overflow plate attaches when a pool slot frees", function()
        local ns, w = start({ mode = "party" })
        for i = 1, 21 do add(w, "nameplate" .. i) end
        remove(w, "nameplate1")
        w.now = w.now + 1
        plate(w, "nameplate21", KIDNEY_SHOT, false)
        plate(w, "nameplate21", KIDNEY_SHOT, true)
        assert.is_false(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)

    it("edge inside the settle window after attach is a baseline", function()
        local ns, w = start({ mode = "party" })
        w.exist.nameplate1 = true
        helpers.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
        w.flush()
        w.now = 100.2
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        assert.is_true(ns.tracker:State("A", KIDNEY_SHOT).ready)
        w.now = 101
        plate(w, "nameplate1", KIDNEY_SHOT, false)
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        assert.is_false(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)

    it("own cast is not double counted", function()
        local ns, w = start({ mode = "party", units = {
            player = { guid = "P", class = "PALADIN", role = "TANK" },
            party1 = { guid = "A", class = "PALADIN", role = "DAMAGER" },
        } })
        add(w, "nameplate1")
        ns.tracker:Used("P", HAMMER, true)
        plate(w, "nameplate1", HAMMER, true)
        assert.is_true(ns.tracker:State("A", HAMMER).ready)
    end)

    it("debuff edge without an own cast skips the player", function()
        local ns, w = start({ mode = "party", units = {
            player = { guid = "P", class = "PALADIN", role = "TANK" },
            party1 = { guid = "A", class = "PALADIN", role = "DAMAGER" },
        } })
        add(w, "nameplate1")
        plate(w, "nameplate1", HAMMER, true)
        local state = ns.tracker:State("A", HAMMER)
        assert.is_false(state.ready)
        assert.is_false(state.maybe)
        assert.is_true(ns.tracker:State("P", HAMMER).ready)
    end)

    it("spell without a verified debuff id is listed and has no slot", function()
        local ns, w = start({ mode = "party", units = {
            player = { guid = "P", class = "PRIEST", role = "HEALER" },
            party1 = { guid = "A", class = "MONK", role = "DAMAGER" },
        } })
        local listed = {}
        for _, e in ipairs(ns.EnemyDebuffs.Status().noId) do listed[e.id] = true end
        assert.is_true(listed[116844])
        add(w, "nameplate1")
        plate(w, "nameplate1", 116844, true)
        assert.is_true(ns.tracker:State("A", 116844).ready)
    end)

    it("plate added in combat reuses a pooled container without building", function()
        local ns, w = start({ mode = "party" })
        local before = #w.containers
        w.combat = true
        add(w, "nameplate1")
        plate(w, "nameplate1", KIDNEY_SHOT, false)
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        assert.are.equal(before, #w.containers)
        assert.is_false(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)

    it("uses the HARMFUL filter", function()
        local _, w = start({ mode = "party" })
        assert.is_truthy(w.filters.HARMFUL)
    end)

    it("raid roster idles", function()
        local ns, w = start({ mode = "raid" })
        assert.are.equal(0, #w.containers)
        add(w, "nameplate1")
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        assert.are.same({}, ns.EnemyDebuffs.Status().secret)
    end)

    it("friendly plate is ignored", function()
        local ns, w = start({ mode = "party" })
        w.friendly = true
        add(w, "nameplate1")
        plate(w, "nameplate1", KIDNEY_SHOT, true)
        assert.is_true(ns.tracker:State("A", KIDNEY_SHOT).ready)
    end)
end)
