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

    it("counts every skipped party event by reason", function()
        local ns = helpers.load(FILES, { issecretvalue = function(v) return v == SECRET end })
        ns.DB = {}
        ns.AuraFlags:Enable()
        helpers.fire("UNIT_AURA", "party1", nil)
        helpers.fire("UNIT_AURA", "party1", { isFullUpdate = true })
        helpers.fire("UNIT_AURA", "party2", { addedAuras = SECRET })
        helpers.fire("UNIT_AURA", "party2", { addedAuras = { SECRET } })
        assert.same({ ["no info"] = 1, ["full update"] = 1, ["no added"] = 1, ["secret added"] = 1, ["secret aura"] = 1 },
            ns.AuraFlags.Live().drops)
    end)
end)

describe("AuraFlags.Snapshot", function()
    it("reads current party aura keys and the big defensive count", function()
        local ns = helpers.load(FILES, {
            issecretvalue = function(v) return v == SECRET end,
            UnitExists = function(unit) return unit == "party1" end,
            C_UnitAuras = {
                GetUnitAuraInstanceIDs = function(_, filter)
                    if filter == "HELPFUL|BIG_DEFENSIVE" then return { 5 } end
                    return { 5, 6, SECRET }
                end,
                IsAuraFilteredOutByInstanceID = function(_, id, filter)
                    return not (id == 5 and (filter == "HELPFUL|BIG_DEFENSIVE" or filter == "HELPFUL|IMPORTANT"))
                end,
                GetAuraDataByAuraInstanceID = function(_, id)
                    if id == 5 then return { spellId = 48792, name = "Icebound Fortitude" } end
                    if id == 6 then return { spellId = SECRET } end
                end,
            },
        })
        assert.same({ { unit = "party1", helpful = 3, big = 1, keys = { ["B-I-"] = 1, ["----"] = 1, ["secret id"] = 1 },
            named = { "48792 Icebound Fortitude B-I-" }, spells = { 48792 } } }, ns.AuraFlags.Snapshot())
    end)
end)
