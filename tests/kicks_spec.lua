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
