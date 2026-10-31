-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Probe = {}
ns.Probe = Probe

local SECRET_NOTE = "Party buffs are hidden by the game right now (secret mode); own row and kicks still work"
local UNITS = { "party1", "party2", "party3", "party4" }

function Probe.Data()
    local mode, reason = ns.Sensors.Mode()
    local stats, seen = ns.Sensors.Stats()
    local units = {}
    for _, unit in ipairs(UNITS) do
        local s = stats[unit]
        if s then units[#units + 1] = { unit = unit, read = s.read, hit = s.hit } end
    end
    local ids = {}
    for id in pairs(seen) do ids[#ids + 1] = id end
    table.sort(ids)
    return {
        group = ns.Group.Mode(),
        mode = mode,
        reason = reason,
        note = mode == "secret" and SECRET_NOTE or nil,
        units = units,
        seen = ids,
    }
end

function Probe.Run()
    local d = Probe.Data()
    print(("SquadCD probe: group %s, sensors %s%s"):format(d.group, d.mode, d.reason and (" (" .. d.reason .. ")") or ""))
    if d.note then print("SquadCD probe: " .. d.note) end
    for _, u in ipairs(d.units) do
        local r, h = u.read, u.hit
        print(("SquadCD probe: %s shown: plain %d (true %d), secret %d, error %d - hit-test: true %d, false %d, secret %d, error %d"):format(
            u.unit, r["true"] + r["false"], r["true"], r.secret, r.error, h["true"], h["false"], h.secret, h.error))
    end
    print("SquadCD probe: buffs seen since login: " .. (#d.seen > 0 and table.concat(d.seen, ", ") or "none"))
    Probe.Flags()
end

local function counts(t)
    local keys = {}
    for k, n in pairs(t) do keys[#keys + 1] = k .. "=" .. n end
    table.sort(keys)
    return #keys > 0 and table.concat(keys, ", ") or "none"
end

local function secretFlag(fn)
    local ok, v = pcall(fn)
    if not ok then return "error" end
    return issecretvalue(v) and "secret" or tostring(v)
end

function Probe.Flags()
    local F = ns.AuraFlags
    print(("SquadCD flags: auras secret now %s, restrictions %s"):format(
        secretFlag(C_Secrets.ShouldAurasBeSecret), secretFlag(C_Secrets.HasSecretRestrictions)))
    local live = F.Live()
    print(("SquadCD flags: party auras seen - instance id plain %d, secret %d; keys: %s"):format(
        live.ids.plain, live.ids.secret, counts(live.keys)))
    local learned = ns.DB.probe and ns.DB.probe.auraKeys or {}
    local n = 0
    for _ in pairs(learned) do n = n + 1 end
    print(("SquadCD flags: spell -> live key pairs saved: %d"):format(n))
    local catalog = F.Catalog()
    local a = F.Ambiguity(catalog)
    print(("SquadCD flags: catalog %d buffs - unique key within class %d, shared %d, no flags %d; aura secrecy: %s"):format(
        #catalog, a.unique, a.shared, a.none, counts(F.Secrecy(catalog))))
    local sated = {}
    for _, s in ipairs(F.Sated()) do sated[#sated + 1] = s.id .. " " .. s.state end
    print("SquadCD flags: sated " .. table.concat(sated, ", "))
    ns.DB.probe = ns.DB.probe or {}
    ns.DB.probe.catalog = catalog
end

ns.Slash("probe", Probe.Run)
