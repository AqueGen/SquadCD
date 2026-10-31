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
        if s then units[#units + 1] = { unit = unit, plain = s.plain, secret = s.secret, error = s.error } end
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
    print(("Huddle probe: group %s, sensors %s%s"):format(d.group, d.mode, d.reason and (" (" .. d.reason .. ")") or ""))
    if d.note then print("Huddle probe: " .. d.note) end
    for _, u in ipairs(d.units) do
        print(("Huddle probe: %s plain %d, secret %d, error %d"):format(u.unit, u.plain, u.secret, u.error))
    end
    print("Huddle probe: buffs seen since login: " .. (#d.seen > 0 and table.concat(d.seen, ", ") or "none"))
end

ns.Slash("probe", Probe.Run)
