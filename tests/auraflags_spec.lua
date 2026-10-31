-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Game/AuraFlags.lua" }
local SECRET = {}

describe("AuraFlags.Key", function()
    it("false means the aura matches; secret and errors are marked", function()
        local answers = {
            ["HELPFUL|BIG_DEFENSIVE"] = false,
            ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
            ["HELPFUL|IMPORTANT"] = SECRET,
        }
        local ns = helpers.load(FILES, {
            issecretvalue = function(v) return v == SECRET end,
            C_UnitAuras = { IsAuraFilteredOutByInstanceID = function(_, _, filter)
                if answers[filter] == nil then error("blocked") end
                return answers[filter]
            end },
        })
        assert.equal("B-sx", ns.AuraFlags.Key("party1", 7))
    end)
end)

describe("AuraFlags.Ambiguity", function()
    it("counts unique, shared and flagless keys per class", function()
        local ns = helpers.load(FILES)
        local a = ns.AuraFlags.Ambiguity({
            { id = 1, class = "PRIEST", key = "B-I?" },
            { id = 2, class = "PRIEST", key = "B-I?" },
            { id = 3, class = "MAGE", key = "B-I?" },
            { id = 4, class = "MAGE", key = "---?" },
            { id = 5, class = "MAGE", key = "---?" },
        })
        assert.same({ unique = 1, shared = 2, none = 2 }, { unique = a.unique, shared = a.shared, none = a.none })
    end)
end)

describe("AuraFlags recorder", function()
    it("saves the live key per readable spell id and counts secret instance ids", function()
        local ns = helpers.load(FILES, {
            issecretvalue = function(v) return v == SECRET end,
            C_UnitAuras = { IsAuraFilteredOutByInstanceID = function(_, _, filter) return filter ~= "HELPFUL|EXTERNAL_DEFENSIVE" end },
        })
        ns.DB = {}
        ns.AuraFlags:Enable()
        helpers.fire("UNIT_AURA", "party1", { addedAuras = { { auraInstanceID = 9, spellId = 33206 }, { auraInstanceID = SECRET } } })
        helpers.fire("UNIT_AURA", "nameplate1", { addedAuras = { { auraInstanceID = 10, spellId = 1 } } })
        local live = ns.AuraFlags.Live()
        assert.same({ plain = 1, secret = 1 }, live.ids)
        assert.same({ [33206] = "-E--" }, ns.DB.probe.auraKeys)
    end)
end)
