local _, ns = ...

local LayoutRules = {}
ns.LayoutRules = LayoutRules

LayoutRules.TYPES = {
    "Personal", "Burst", "Racial", "Potion", "External", "Kick", "Stun", "CC", "Group", "Dispel", "Purge", "Movement",
}

LayoutRules.LABELS = {
    Personal = "Personal", Burst = "Burst", Racial = "Racial", Potion = "Potion", External = "External",
    Kick = "Kick", Stun = "Stun", CC = "CC", Group = "Raid defensives", Dispel = "Dispel", Purge = "Purge",
    Movement = "Movement",
}

local rank = {}
for i, t in ipairs(LayoutRules.TYPES) do rank[t] = i end

function LayoutRules.TypeRank(t)
    return rank[t] or #LayoutRules.TYPES + 1
end

function LayoutRules.SpellsFor(member, own, enabled)
    local list = {}
    for id, s in pairs(ns.Spells) do
        if enabled[id] ~= false and (own or s.track ~= "none")
            and ns.Cooldowns.Has(id, member.class, member.spec, member.talents, member.race)
            and ns.Cooldowns.Canonical(id, member) == id then
            list[#list + 1] = { id = id, type = s.type, name = s.name, icon = s.icon }
        end
    end
    if enabled.potion ~= false then
        list[#list + 1] = { id = "potion", type = "Potion", name = "Potion" }
    end
    table.sort(list, function(a, b)
        local ra, rb = LayoutRules.TypeRank(a.type), LayoutRules.TypeRank(b.type)
        if ra ~= rb then return ra < rb end
        return a.name < b.name
    end)
    return list
end

function LayoutRules.Catalog(class)
    local list = {}
    for id, s in pairs(ns.Spells) do
        if class == nil or s.class == class then
            list[#list + 1] = {
                id = id, name = s.name, type = s.type, cd = s.cd, icon = s.icon,
                untrackable = s.track == "none" or (s.track == "debuff" and not s.debuffs),
            }
        end
    end
    table.sort(list, function(a, b)
        local ra, rb = LayoutRules.TypeRank(a.type), LayoutRules.TypeRank(b.type)
        if ra ~= rb then return ra < rb end
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    return list
end

function LayoutRules.Split(spells, placement)
    local row, panel = {}, {}
    for _, s in ipairs(spells) do
        local where = placement[s.type]
        if where == "Row" then
            row[#row + 1] = s
        elseif where == "Panel" then
            panel[s.type] = panel[s.type] or {}
            table.insert(panel[s.type], s)
        end
    end
    return row, panel
end

local POTION = { track = "buff", buffs = {} }

function LayoutRules.Unknown(spellId, own, plain, secret)
    if own then return false end
    local s = spellId == "potion" and POTION or ns.Spells[spellId]
    if not s then return false end
    if s.track == "buff" or s.track == "target" then return not plain or not s.buffs end
    if s.track == "debuff" then
        for _, id in ipairs(s.debuffs or {}) do
            if not secret[id] then return false end
        end
        return true
    end
    return false
end

local index = {}

local function before(x, y)
    if x.ready ~= y.ready then return x.ready end
    if (x.unknown or false) ~= (y.unknown or false) then return not x.unknown end
    if (x.maybe or false) ~= (y.maybe or false) then return not x.maybe end
    if x.remaining ~= y.remaining then return x.remaining < y.remaining end
    return index[x] < index[y]
end

function LayoutRules.Order(states, out)
    out = out or {}
    for i = #states + 1, #out do out[i] = nil end
    for i, s in ipairs(states) do
        out[i] = s
        index[s] = i
    end
    table.sort(out, before)
    for _, s in ipairs(states) do index[s] = nil end
    return out
end

function LayoutRules.FormatRemaining(remaining)
    local r = math.ceil(remaining)
    if r <= 0 then return "" end
    if r < 60 then return tostring(r) end
    if r < 120 then return string.format("%d:%02d", math.floor(r / 60), r % 60) end
    return math.ceil(r / 60) .. "m"
end

function LayoutRules.ShortName(name, n)
    local out, count = {}, 0
    for ch in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > n then break end
        out[count] = ch
    end
    return table.concat(out)
end
