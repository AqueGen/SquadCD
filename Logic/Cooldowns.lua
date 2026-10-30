local _, ns = ...

local Cooldowns = {}
ns.Cooldowns = Cooldowns

local MIN_CD = 1

local function rank(talents, id)
    return talents and talents[id] or 0
end

local function apply(base, mods, pcts, talents)
    local cd = base
    for id, v in pairs(mods or {}) do
        cd = cd + v * rank(talents, id)
    end
    for id, v in pairs(pcts or {}) do
        cd = cd * (1 + v * rank(talents, id) / 100)
    end
    return cd
end

function Cooldowns.Resolve(spellId, specId, talents)
    local s = ns.Spells[spellId]
    if not s then return nil end
    local base = s.chargeCd or s.cd
    local cd = math.max(MIN_CD, math.floor(apply(base, s.cdMods, s.cdPct, talents) + 0.5))
    local charges = s.charges or 1
    for id, n in pairs(s.chargeAdds or {}) do
        charges = charges + n * rank(talents, id)
    end
    return {
        cd = cd,
        charges = math.max(1, charges),
        chargeCd = s.chargeCd and cd or 0,
        talentsKnown = talents ~= nil,
    }
end

function Cooldowns.Has(spellId, classToken, specId, talents)
    local s = ns.Spells[spellId]
    if not s or s.class ~= classToken then return false end
    if s.specs and #s.specs > 0 then
        local ok = false
        for _, id in ipairs(s.specs) do
            if id == specId then ok = true break end
        end
        if not ok then return false end
    end
    if s.talentGated and talents then
        return (talents[spellId] or 0) > 0
    end
    return true
end
