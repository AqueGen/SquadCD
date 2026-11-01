-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local LayoutRules = {}
ns.LayoutRules = LayoutRules

LayoutRules.TYPES = {
    "Personal", "Burst", "Racial", "Potion", "External", "Kick", "Stun", "CC", "Group", "Dispel", "Purge", "Movement",
}

LayoutRules.LABELS = {
    Personal = "Defensives", Burst = "Burst", Racial = "Racial", Potion = "Potion", External = "External",
    Kick = "Kick", Control = "Control", Stun = "Stun", CC = "CC", Group = "Group defensives", Dispel = "Dispel", Purge = "Purge",
    Movement = "Movement",
}

LayoutRules.SHORT = {
    Personal = "Def", Burst = "Burst", Racial = "Race", Potion = "Pot", External = "Ext", Kick = "Kick",
    Control = "Ctrl", Stun = "Stun", CC = "CC", Group = "Group", Dispel = "Disp", Purge = "Purge", Movement = "Move",
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
            and ns.Cooldowns.Has(id, member.class, member.spec, member.talents, member.race, member.pets)
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

function LayoutRules.Route(layout, members)
    local Model = ns.LayoutModel
    local byType, rows = {}, {}
    for i, m in ipairs(members) do
        local perGroup = {}
        for _, spell in ipairs(m.spells) do
            local t = Model.VisibleTypeOf(layout, spell.type)
            local place, at = Model.PlaceOf(layout, t)
            if place == "panel" then
                byType[t] = byType[t] or {}
                table.insert(byType[t], { member = m.member, spell = spell, own = m.own })
            elseif place == "member" then
                perGroup[at] = perGroup[at] or {}
                perGroup[at][t] = perGroup[at][t] or {}
                table.insert(perGroup[at][t], spell)
            end
        end
        local groups = {}
        for gi, g in ipairs(layout.groups) do
            if g.shown then
                local runs = {}
                for _, t in ipairs(Model.TypeOrder(layout, g)) do
                    local list = perGroup[gi] and perGroup[gi][t]
                    if list then runs[#runs + 1] = { type = t, spells = list } end
                end
                groups[gi] = runs
            end
        end
        rows[i] = { member = m.member, own = m.own, groups = groups }
    end
    local lines = {}
    for _, s in ipairs(layout.sections) do
        if s.shown then
            for _, t in ipairs(Model.TypeOrder(layout, s)) do
                if byType[t] then lines[#lines + 1] = { section = s, type = t, entries = byType[t] } end
            end
        end
    end
    return lines, rows
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
