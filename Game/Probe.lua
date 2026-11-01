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
        if s then units[#units + 1] = { unit = unit, read = s.read } end
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
        local r = u.read
        print(("SquadCD probe: %s hit-test: plain %d (true %d), secret %d, error %d"):format(
            u.unit, r["true"] + r["false"], r["true"], r.secret, r.error))
    end
    print("SquadCD probe: buffs seen since login: " .. (#d.seen > 0 and table.concat(d.seen, ", ") or "none"))
    print("SquadCD probe: " .. Probe.TrackLine())
end

function Probe.TrackLine()
    local t = ns.SecretTracks and ns.SecretTracks.Status()
    if not t then return "secret tracks: not loaded" end
    if not t.on then return ("secret tracks: off (%s)"):format(tostring(t.why)) end
    return ("secret tracks: on, tracks %d, probes %d, plates %d of %d"):format(t.tracks, t.probes, t.plates, t.platePool)
end

ns.Slash("probe", Probe.Run)
