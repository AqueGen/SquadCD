local _, ns = ...

local OwnCasts = {}
ns.OwnCasts = OwnCasts

local frame = CreateFrame("Frame")
local stats = { secret = 0, used = 0 }
local replaced

local function build()
    replaced = {}
    for id, s in pairs(ns.Spells) do
        for _, r in ipairs(s.replaces or {}) do
            if not replaced[r] or id < replaced[r] then replaced[r] = id end
        end
    end
end

function OwnCasts.Stats()
    return stats
end

frame:SetScript("OnEvent", function(_, _, unit, _, spellId)
    if issecretvalue(unit) or unit ~= "player" then return end
    if issecretvalue(spellId) then
        stats.secret = stats.secret + 1
        return
    end
    local id = replaced[spellId] or spellId
    if not ns.Spells[id] then return end
    local guid = UnitGUID("player")
    if issecretvalue(guid) or guid == nil then return end
    stats.used = stats.used + 1
    ns.tracker:Used(guid, id, true)
end)

function OwnCasts.Enable()
    if not replaced then build() end
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end

function OwnCasts.Disable()
    frame:UnregisterAllEvents()
end

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    if ns.Group.Mode() == "party" then OwnCasts.Enable() else OwnCasts.Disable() end
end
