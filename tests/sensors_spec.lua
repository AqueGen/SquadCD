local here = debug.getinfo(1, "S").source:match("^@(.*)[/\][^/\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/Persist.lua",
    "Game/Inspect.lua", "Game/Group.lua", "Game/Sensors.lua", "Game/Probe.lua",
}

local SECRET = setmetatable({}, { __tostring = function() return "secret" end })
local PAIN_SUPPRESSION, PAIN_BUFF = 33206, 33206
local SHIELD_WALL = 871
local POTION_BUFF = 1236994

local function world(opts)
    opts = opts or {}
    local w = { buffs = {}, containers = {}, timers = {}, combat = false, printed = {} }
    w.units = opts.units or {
        player = { guid = "P", class = "PRIEST", role = "HEALER" },
        party1 = { guid = "A", class = "WARRIOR", role = "TANK" },
        party2 = { guid = "B", class = "PRIEST", role = "HEALER" },
    }
    w.buffs.player = { [17] = true }

    local function slotFrame(container, id)
        local s = {}
        local function value()
            if w.secret then return SECRET end
            return w.buffs[container.unit] and w.buffs[container.unit][id] or false
        end
        function s:IsShown() return value() end
        function s:IsMouseOver() return value() end
        return s
    end

    local function container()
        local c = { slots = {}, enabled = {} }
        function c:SetPoint() end
        function c:SetSize() end
        function c:EnableMouse() end
        function c:SetEnabled(v) self.on = v end
        function c:SetUnit(u) self.unit = u end
        function c:GetAuraSlotFrame(key) return self.slots[key] end
        function c:SetAuraSlotEnabled(key, v) self.enabled[key] = v end
        function c:AddAuraSlot(key, filter, options)
            assert(filter == "HELPFUL")
            local id = next(options.candidateFilters.includeSpellIDs)
            assert(key == "b" .. id)
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
        GetTime = function() return w.now or 100 end,
        GetServerTime = function() return 1000000 end,
        UIParent = {},
        print = function(...) w.printed[#w.printed + 1] = table.concat({ ... }, " ") end,
        issecretvalue = function(v) return v == SECRET end,
        CreateFrame = function(kind, ...)
            if kind == "AuraContainer" then
                if opts.noContainer then error("Unknown frame type 'AuraContainer'") end
                return container()
            end
            return helpers.newFrame()
        end,
        C_Timer = {
            After = function(delay, fn) timer(delay, fn, 1) end,
            NewTicker = function(delay, fn, n) return timer(delay, fn, n) end,
        },
        C_UnitAuras = {
            GetAuraDataByIndex = function(unit, index)
                if unit == "player" and index == 1 then return { spellId = 17 } end
            end,
        },
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
                    if not t.cancelled then t.fn() end
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
    local calls = {}
    ns.tracker.Used = function(_, guid, spell, certain) calls[#calls + 1] = { "Used", guid, spell, certain } end
    ns.tracker.External = function(_, spell, target) calls[#calls + 1] = { "External", spell, target } end
    w.calls = calls
    return ns, w
end

local function aura(w, unit, id, on, ns)
    w.buffs[unit] = w.buffs[unit] or {}
    w.buffs[unit][id] = on
    helpers.fire("UNIT_AURA", unit)
    w.flush()
end

describe("Sensors", function()
    it("self-test on a player buff reports plain mode", function()
        local ns = start({ mode = "party" })
        assert.are.equal("plain", (ns.Sensors.Mode()))
    end)

    it("secret readout reports secret mode", function()
        local w = world({ mode = "party" })
        w.secret = true
        local ns = helpers.load(FILES, w.stubs)
        helpers.fire("ADDON_LOADED", "Huddle")
        helpers.fire("PLAYER_LOGIN")
        helpers.fire("PLAYER_ENTERING_WORLD")
        w.flush()
        local mode, reason = ns.Sensors.Mode()
        assert.are.equal("secret", mode)
        assert.is_string(reason)
        local sensor = ns.Sensors.Build("party1", { SHIELD_WALL })
        assert.are.same({ nil, "secret" }, { sensor:Read(SHIELD_WALL) })
        local data = ns.Probe.Data()
        assert.are.equal("secret", data.mode)
        assert.truthy(data.note:find("secret mode"))
    end)

    it("rising edge calls Used once", function()
        local ns, w = start({ mode = "party" })
        aura(w, "party1", SHIELD_WALL, true)
        aura(w, "party1", SHIELD_WALL, true)
        assert.are.same({ { "Used", "A", SHIELD_WALL, true } }, w.calls)
        local seen = {}
        for _, id in ipairs(ns.Probe.Data().seen) do seen[id] = true end
        assert.is_true(seen[SHIELD_WALL])
    end)

    it("held buff does not retrigger", function()
        local _, w = start({ mode = "party" })
        aura(w, "party1", SHIELD_WALL, true)
        aura(w, "party1", 99999, true)
        aura(w, "party1", SHIELD_WALL, false)
        assert.are.equal(1, #w.calls)
        aura(w, "party1", SHIELD_WALL, true)
        assert.are.equal(2, #w.calls)
    end)

    it("buff present when the sensor is built does not fire", function()
        local w = world({ mode = "party" })
        w.buffs.party1 = { [SHIELD_WALL] = true }
        local ns = helpers.load(FILES, w.stubs)
        helpers.fire("ADDON_LOADED", "Huddle")
        helpers.fire("PLAYER_LOGIN")
        helpers.fire("PLAYER_ENTERING_WORLD")
        w.flush()
        local calls = 0
        ns.tracker.Used = function() calls = calls + 1 end
        aura(w, "party1", SHIELD_WALL, true)
        assert.are.equal(0, calls)
    end)

    it("target buff calls External", function()
        local _, w = start({ mode = "party" })
        aura(w, "party1", PAIN_BUFF, true)
        assert.are.same({ { "External", PAIN_SUPPRESSION, "A" } }, w.calls)
    end)

    it("potion buff calls Used with the potion pseudo-spell", function()
        local _, w = start({ mode = "party" })
        aura(w, "party2", POTION_BUFF, true)
        assert.are.same({ { "Used", "B", "potion", true } }, w.calls)
    end)

    it("build failure reports unavailable", function()
        local ns, w = start({ mode = "party", noContainer = true })
        local mode, reason = ns.Sensors.Mode()
        assert.are.equal("unavailable", mode)
        assert.truthy(reason:find("AuraContainer"))
        assert.is_nil((ns.Sensors.Build("party1", { SHIELD_WALL })))
        aura(w, "party1", SHIELD_WALL, true)
        assert.are.same({}, w.calls)
        SlashCmdList.HUDDLE("probe")
        assert.truthy(table.concat(w.printed, "\n"):find("unavailable"))
    end)

    it("raid builds no party sensors", function()
        local _, w = start({ mode = "raid" })
        for _, c in ipairs(w.containers) do
            assert.are.equal("player", c.unit)
        end
        aura(w, "party1", SHIELD_WALL, true)
        assert.are.same({}, w.calls)
    end)

    it("roster change in combat waits for combat end", function()
        local ns, w = start({ mode = "party" })
        w.combat = true
        helpers.fire("PLAYER_REGEN_DISABLED")
        w.units.party3 = { guid = "C", class = "WARRIOR", role = "DAMAGER" }
        local before = #w.containers
        helpers.fire("GROUP_ROSTER_UPDATE")
        assert.are.equal(before, #w.containers)
        w.combat = false
        helpers.fire("PLAYER_REGEN_ENABLED")
        w.flush()
        assert.are.equal(before + 1, #w.containers)
        ns.tracker.Used = function(_, guid) w.calls[#w.calls + 1] = guid end
        aura(w, "party3", SHIELD_WALL, true)
        assert.are.same({ "C" }, w.calls)
    end)

    it("probe prints mode and per unit counts", function()
        local _, w = start({ mode = "party" })
        aura(w, "party1", SHIELD_WALL, true)
        w.printed = {}
        SlashCmdList.HUDDLE("probe")
        local out = table.concat(w.printed, "\n")
        assert.truthy(out:find("plain"))
        assert.truthy(out:find("party1"))
        assert.truthy(out:find(tostring(SHIELD_WALL)))
    end)
end)
