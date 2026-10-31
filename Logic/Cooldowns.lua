local _, ns = ...

local Cooldowns = {}
ns.Cooldowns = Cooldowns

local MIN_CD = 1

local function rank(s, specId, talents, id)
    local r = talents and talents[id]
    if r then return r end
    for _, m in ipairs(s.specMods and s.specMods[specId] or {}) do
        if m == id then return 1 end
    end
    return 0
end

local function apply(s, specId, talents, base, mods, pcts)
    local cd = base
    for id, v in pairs(mods or {}) do
        cd = cd + v * rank(s, specId, talents, id)
    end
    for id, v in pairs(pcts or {}) do
        cd = cd * (1 + v * rank(s, specId, talents, id) / 100)
    end
    return cd
end

function Cooldowns.Resolve(spellId, specId, talents)
    local s = ns.Spells[spellId]
    if not s then return nil end
    local cd
    if s.chargeCd then
        cd = math.max(
            apply(s, specId, talents, s.recovery or 0, s.cdMods, s.cdPct),
            apply(s, specId, talents, s.chargeCd, s.chargeMods, s.chargePct))
    else
        cd = apply(s, specId, talents, s.cd, s.cdMods, s.cdPct)
    end
    cd = math.floor(math.max(MIN_CD, cd) * 1000 + 0.5) / 1000
    local charges = s.charges or 1
    for id, n in pairs(s.chargeAdds or {}) do
        charges = charges + n * rank(s, specId, talents, id)
    end
    return {
        cd = cd,
        charges = math.max(1, charges),
        chargeCd = s.chargeCd and cd or 0,
        talentsKnown = talents ~= nil,
    }
end

local function contains(list, v)
    for _, x in ipairs(list) do
        if x == v then return true end
    end
    return false
end

function Cooldowns.Has(spellId, classToken, specId, talents, race)
    local s = ns.Spells[spellId]
    if not s then return false end
    if s.races then
        return race ~= nil and contains(s.races, race) and (not s.classes or contains(s.classes, classToken))
    end
    if s.class ~= classToken then return false end
    local specs = s.specs or {}
    for _, id in ipairs(specs) do
        if id == specId then return true end
    end
    if s.talentGated then
        if talents then return (talents[spellId] or 0) > 0 end
        return #specs == 0
    end
    return #specs == 0
end
