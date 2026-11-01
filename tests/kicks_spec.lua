-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = {
    "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/Persist.lua",
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

describe("Kicks own result", function()
    local ns, now

    before_each(function()
        now = 100
        ns = helpers.load(FILES, {
            UnitGUID = function(u) return u == "player" and "P" or nil end,
            GetTime = function() return now end,
            UnitCanAttack = function() return true end,
        })
    end)

    it("a kick that interrupts is a hit, one that does not is a miss, both fade after a while", function()
        assert.is_nil(ns.Kicks.OwnResult(now))
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 96231)
        assert.equal("cast", ns.Kicks.OwnResult(now))
        helpers.fire("UNIT_SPELLCAST_INTERRUPTED", "nameplate1", "x", 1, "P")
        assert.equal("hit", ns.Kicks.OwnResult(now))
        now = now + 4
        assert.is_nil(ns.Kicks.OwnResult(now))
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 96231)
        now = now + 1.5
        assert.equal("miss", ns.Kicks.OwnResult(now))
    end)

    it("target probe says for each unit whether mark and name read plain or secret", function()
        local SECRET = {}
        _G.issecretvalue = function(v) return v == SECRET end
        _G.UnitExists = function(u) return u == "focus" or u == "party1target" end
        _G.GetRaidTargetIndex = function(u) if u == "focus" then return 8 end return SECRET end
        _G.UnitName = function(u) if u == "focus" then return "Mob" end return SECRET end
        local lines = ns.Kicks.TargetProbe()
        assert.equal("focus: exists true, mark 8, name Mob", lines[1])
        assert.equal("party1target: exists true, mark secret, name secret", lines[2])
    end)

    it("focus text is the mark icon and the full name", function()
        _G.UnitExists = function(u) return u == "focus" end
        _G.GetRaidTargetIndex = function() return 8 end
        _G.UnitName = function() return "Felonious Mage" end
        assert.equal("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t Felonious Mage", ns.Kicks.FocusText())
    end)

    it("focus text without a mark is the name alone", function()
        _G.UnitExists = function(u) return u == "focus" end
        _G.GetRaidTargetIndex = function() return nil end
        _G.UnitName = function() return "Felonious Mage" end
        assert.equal("Felonious Mage", ns.Kicks.FocusText())
    end)

    it("focus version moves on focus change and raid mark change", function()
        local v = ns.Kicks.FocusVersion()
        helpers.fire("PLAYER_FOCUS_CHANGED")
        helpers.fire("RAID_TARGET_UPDATE")
        assert.equal(v + 2, ns.Kicks.FocusVersion())
    end)

    it("no focus gives nothing", function()
        _G.UnitExists = function() return false end
        assert.is_nil(ns.Kicks.FocusText())
    end)

    it("ignores casts that are not kicks and interrupts by someone else", function()
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 642)
        assert.is_nil(ns.Kicks.OwnResult(now))
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 96231)
        helpers.fire("UNIT_SPELLCAST_INTERRUPTED", "nameplate1", "x", 1, "B")
        now = now + 1.5
        assert.equal("miss", ns.Kicks.OwnResult(now))
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

    it("potion use spell maps to the potion pseudo-spell", function()
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", ns.Potions[1].spell)
        assert.same({ { "P", "potion", true } }, used)
    end)

    it("spell the player has keeps its own id", function()
        local druid = { class = "DRUID", spec = 103, talents = { [106898] = 1 } }
        assert.equal(106898, ns.OwnCasts.Resolve(106898, druid))
    end)

    it("replaced spell maps to the lowest replacer the player has", function()
        local druid = { class = "DRUID", spec = 103, talents = {} }
        assert.equal(77761, ns.OwnCasts.Resolve(106898, druid))
    end)

    it("Sigil of Misery stays Misery without Sigil of Silence", function()
        local dh = { class = "DEMONHUNTER", spec = 581, talents = { [207684] = 1 } }
        assert.equal(207684, ns.OwnCasts.Resolve(207684, dh))
    end)

    it("Berserk stays Berserk without Incarnation", function()
        local feral = { class = "DRUID", spec = 103, talents = { [106951] = 1 } }
        assert.equal(106951, ns.OwnCasts.Resolve(106951, feral))
    end)

    it("Berserk maps to Incarnation when only Incarnation is talented", function()
        local feral = { class = "DRUID", spec = 103, talents = { [102543] = 1 } }
        assert.equal(102543, ns.OwnCasts.Resolve(106951, feral))
    end)

    it("talented Guardian of Ancient Kings keeps 86659", function()
        local prot = { class = "PALADIN", spec = 66, talents = { [86659] = 1 } }
        assert.equal(86659, ns.OwnCasts.Resolve(86659, prot))
    end)

    it("secret spell id is counted and ignored", function()
        _G.issecretvalue = function(v) return v == SECRET end
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", SECRET)
        assert.equal(0, #used)
        assert.equal(1, ns.OwnCasts.Stats().secret)
    end)
end)

describe("OwnCasts roster gate", function()
    local ns, used

    local function solo()
        ns = helpers.load(FILES, {
            UnitGUID = function() return "P" end,
            IsInRaid = function() return false end,
            IsInGroup = function() return false end,
            InCombatLockdown = function() return false end,
            C_DamageMeter = { GetCombatSessionSourceFromType = function() end },
        })
        used = {}
        ns.tracker = { Used = function(_, guid, id) used[#used + 1] = { guid, id } end }
    end

    it("solo with the player in the roster tracks own casts", function()
        solo()
        ns.Group.OnRoster({ { guid = "P", unit = "player", class = "PALADIN", spec = 66 } })
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 642)
        assert.same({ { "P", 642 } }, used)
    end)

    it("solo with an empty roster tracks nothing", function()
        solo()
        ns.OwnCasts.Enable()
        ns.Group.OnRoster({})
        helpers.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "c", 642)
        assert.equal(0, #used)
    end)
end)

describe("Kicks.Deltas", function()
    local ns
    before_each(function() ns = helpers.load(FILES) end)

    it("two risers both attributed", function()
        assert.same({ "A", "B" }, ns.Kicks.Deltas({ A = 0, B = 2 }, { A = 1, B = 3 }))
    end)

    it("no risers none", function()
        assert.same({}, ns.Kicks.Deltas({ A = 1 }, { A = 1 }))
    end)

    it("baseline missing member ignored", function()
        assert.same({}, ns.Kicks.Deltas({}, { A = 4 }))
    end)
end)

describe("Kicks.SpellOf", function()
    local ns
    before_each(function() ns = helpers.load(FILES) end)

    local function pick(class, spec, talents)
        return ns.Kicks.SpellOf({ class = class, spec = spec, talents = talents })
    end

    it("paladin picks Rebuke", function()
        assert.equal(96231, pick("PALADIN", 66))
    end)

    it("feral and guardian pick Skull Bash", function()
        assert.equal(106839, pick("DRUID", 103))
        assert.equal(106839, pick("DRUID", 104))
    end)

    it("balance picks Solar Beam", function()
        assert.equal(78675, pick("DRUID", 102))
    end)

    it("survival picks Muzzle, BM and MM pick Counter Shot", function()
        assert.equal(187707, pick("HUNTER", 255))
        assert.equal(147362, pick("HUNTER", 253))
        assert.equal(147362, pick("HUNTER", 254))
    end)

    it("spec-owned kick beats others", function()
        assert.equal(15487, pick("PRIEST", 258))
    end)

    it("falls back when primary talent is absent", function()
        assert.equal(31935, pick("PALADIN", 66, { [31935] = 1 }))
    end)
end)

describe("Kicks events", function()
    local ns, used, baselineTotals, combat
    local members = {
        { guid = "A", class = "PALADIN", spec = 66 },
        { guid = "B", class = "HUNTER", spec = 255 },
    }

    before_each(function()
        baselineTotals = { A = 1, B = 1 }
        combat = false
        ns = helpers.load(FILES, {
            IsInRaid = function() return false end,
            IsInGroup = function() return true end,
            InCombatLockdown = function() return combat end,
            UnitCanAttack = function(_, unit) return unit == "nameplate1" end,
            C_DamageMeter = { GetCombatSessionSourceFromType = function(_, _, guid)
                return { totalAmount = baselineTotals[guid] }
            end },
        })
        used = {}
        ns.tracker = { Used = function(_, guid, id) used[#used + 1] = { guid, id } end }
        ns.Group.OnRoster(members)
    end)

    it("regen credits every member whose count rose", function()
        combat = true
        helpers.fire("PLAYER_REGEN_DISABLED")
        combat = false
        baselineTotals = { A = 2, B = 3 }
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.same({ { "A", 96231 }, { "B", 187707 } }, used)
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.equal(2, #used)
    end)

    it("interruptedBy credits once and regen skips it", function()
        helpers.fire("UNIT_SPELLCAST_INTERRUPTED", "nameplate1", "c", 1, "A")
        baselineTotals = { A = 2, B = 1 }
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.same({ { "A", 96231 } }, used)
    end)

    it("regen skips the player, whose kick OwnCasts already records", function()
        ns.Group.OnRoster({ { guid = "A", class = "PALADIN", spec = 66, unit = "player" }, members[2] })
        baselineTotals = { A = 2, B = 3 }
        helpers.fire("PLAYER_REGEN_ENABLED")
        assert.same({ { "B", 187707 } }, used)
    end)

    it("friendly nameplate ignored", function()
        helpers.fire("UNIT_SPELLCAST_INTERRUPTED", "nameplate2", "c", 1, "A")
        assert.equal(0, #used)
    end)

    it("channel stop without interruptedBy credits nothing", function()
        helpers.fire("UNIT_SPELLCAST_CHANNEL_STOP", "nameplate1", "c", 1, nil)
        assert.equal(0, #used)
    end)
end)
