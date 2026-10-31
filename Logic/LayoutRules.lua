local _, ns = ...

local LayoutRules = {}
ns.LayoutRules = LayoutRules

LayoutRules.TYPES = {
    "Personal", "Burst", "Racial", "Potion", "External", "Kick", "Stun", "CC", "Group", "Dispel", "Purge", "Movement",
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
            and ns.Cooldowns.Has(id, member.class, member.spec, member.talents) then
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

function LayoutRules.Order(states)
    local keyed = {}
    for i, s in ipairs(states) do keyed[i] = { s = s, i = i } end
    table.sort(keyed, function(a, b)
        local x, y = a.s, b.s
        if x.ready ~= y.ready then return x.ready end
        if (x.maybe or false) ~= (y.maybe or false) then return not x.maybe end
        if x.remaining ~= y.remaining then return x.remaining < y.remaining end
        return a.i < b.i
    end)
    local out = {}
    for i, k in ipairs(keyed) do out[i] = k.s end
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
