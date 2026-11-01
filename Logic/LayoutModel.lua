-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local LayoutModel = {}
ns.LayoutModel = LayoutModel

local ORDER = { "Personal", "Burst", "Racial", "Potion", "External", "Kick", "Control", "Group", "Dispel", "Purge", "Movement" }
local ROLES = { "Tank", "Melee", "Ranged", "Healer" }
local CLASS_COUNT = 13

local V1_ORDER = { "Personal", "Burst", "Racial", "Potion", "External", "Kick", "Stun", "CC", "Group", "Dispel", "Purge", "Movement" }
local V1_PLACEMENT = {
    Personal = "Row", Burst = "Row", Racial = "Row", Potion = "Row",
    External = "Panel", Kick = "Panel", Stun = "Panel", CC = "Panel", Group = "Panel",
    Dispel = "Off", Purge = "Off", Movement = "Off",
}
local V1_SIDES = { LEFT = "Left", RIGHT = "Right", ABOVE = "Above", BELOW = "Below" }

function ns.Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = ns.Copy(x) end
    return t
end

local copy = ns.Copy

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function shape(axis, perLine, origin)
    return { axis = axis, perLine = perLine, origin = origin, sort = "Fixed" }
end

local function section(id, types)
    return { id = id, types = types, shown = true, ownWindow = false }
end

local function group(types, side, groupShape)
    return { types = types, side = side, shape = groupShape, shown = true, offsetX = 4, offsetY = 0 }
end

local function newGroupShape()
    return shape("Rows", 3, "TopLeft")
end

function LayoutModel.NewGroup(types, side)
    return group(types, side, newGroupShape())
end

local function panelLook()
    return { iconSize = 26, labels = "Icon", background = "None", opacity = 90, nameLetters = 5 }
end

local function memberLook()
    return { iconSize = 26, labels = "Icon", background = "None", opacity = 100, nameLetters = 5 }
end

local function defaultClassOrder()
    local classOrder = {}
    for _, role in ipairs(ROLES) do
        classOrder[role] = {}
        for i = 1, CLASS_COUNT do classOrder[role][i] = i end
    end
    return classOrder
end

function LayoutModel.Defaults()
    return {
        version = 2,
        overlay = "OnePanel",
        split = false,
        typeOrder = copy(ORDER),
        sections = {
            section("Kick", { "Kick" }), section("Control", { "Control" }),
            section("External", { "External" }), section("Group", { "Group" }),
        },
        groups = { LayoutModel.NewGroup({ "Personal", "Burst", "Racial", "Potion" }, "Left") },
        panelShape = shape("Rows", 6, "TopLeft"),
        panelLook = panelLook(),
        memberLook = memberLook(),
        panel = { point = { "CENTER", 0, -200 } },
        timers = true,
        memberFit = true,
        kickStyle = "Bars",
        showWhen = "always",
        rolePriority = copy(ROLES),
        classOrder = defaultClassOrder(),
    }
end

local function move(list, from, to)
    if not list[from] or not list[to] or from == to then return end
    table.insert(list, to, table.remove(list, from))
end

function LayoutModel.MoveType(layout, type, step)
    local order = layout.typeOrder
    for i, t in ipairs(order) do
        if t == type then
            if order[i + step] then order[i], order[i + step] = order[i + step], order[i] end
            return layout
        end
    end
    return layout
end

function LayoutModel.MoveSection(layout, id, step)
    local slots, at = {}, nil
    for i, s in ipairs(layout.sections) do
        if s.shown and not LayoutModel.OwnWindow(layout, s) then
            slots[#slots + 1] = i
            if s.id == id then at = #slots end
        end
    end
    local other = at and slots[at + step]
    if other then
        local list, i = layout.sections, slots[at]
        list[i], list[other] = list[other], list[i]
    end
    return layout
end

-- Reorders a type inside one container only: layout.groups[index] or layout.sections[index].
function LayoutModel.MoveWithin(layout, kind, index, type, step)
    local c = layout[kind] and layout[kind][index]
    if not c then return layout end
    local order = LayoutModel.TypeOrder(layout, c)
    for i, t in ipairs(order) do
        if t == type then
            if order[i + step] then
                order[i], order[i + step] = order[i + step], order[i]
                c.order = order
            end
            return layout
        end
    end
    return layout
end

function LayoutModel.MoveInOrder(layout, type, step)
    LayoutModel.MoveType(layout, type, step)
    local place, at = LayoutModel.PlaceOf(layout, type)
    local s = place == "panel" and layout.sections[at]
    if s and #s.types == 1 then LayoutModel.MoveSection(layout, s.id, step) end
    return layout
end

function LayoutModel.MoveRole(layout, from, to)
    move(layout.rolePriority, from, to)
    return layout
end

function LayoutModel.MoveClass(layout, role, shown, from, to)
    local moved = copy(shown)
    move(moved, from, to)
    local isShown = {}
    for _, c in ipairs(shown) do isShown[c] = true end
    local next = 0
    for i, c in ipairs(layout.classOrder[role]) do
        if isShown[c] then
            next = next + 1
            layout.classOrder[role][i] = moved[next]
        end
    end
    return layout
end

function LayoutModel.ResetPriority(layout)
    layout.rolePriority = copy(ROLES)
    layout.classOrder = defaultClassOrder()
    return layout
end

function LayoutModel.PlaceOf(layout, type)
    for i, s in ipairs(layout.sections) do
        for _, t in ipairs(s.types) do
            if t == type then return "panel", i end
        end
    end
    for i, g in ipairs(layout.groups) do
        for _, t in ipairs(g.types) do
            if t == type then return "member", i end
        end
    end
    return "off"
end

local function without(layout, type)
    local function strip(types)
        local out = {}
        for _, t in ipairs(types) do
            if t ~= type then out[#out + 1] = t end
        end
        return out
    end
    local kept = {}
    for _, s in ipairs(layout.sections) do
        s.types = strip(s.types)
        if #s.types > 0 then kept[#kept + 1] = s end
    end
    layout.sections = kept
    for _, g in ipairs(layout.groups) do g.types = strip(g.types) end
end

function LayoutModel.SetPlace(layout, type, place)
    if place ~= "panel" and place ~= "member" and place ~= "off" then return layout end
    if LayoutModel.PlaceOf(layout, type) == place then return layout end
    without(layout, type)
    if place == "panel" then
        local used = {}
        for _, s in ipairs(layout.sections) do used[s.id] = true end
        local id, n = type, 1
        while used[id] do
            id = "s" .. n
            n = n + 1
        end
        layout.sections[#layout.sections + 1] = section(id, { type })
    elseif place == "member" then
        if #layout.groups == 0 then
            layout.groups[1] = LayoutModel.NewGroup({}, "Right")
        end
        local types = layout.groups[1].types
        types[#types + 1] = type
    end
    return layout
end

local USUAL_PLACE = { Personal = "member", Burst = "member", Racial = "member", Potion = "member" }

local PACKS = {
    { id = "minimal", name = "Minimal", hint = "Defensives at party frames", place = { Personal = "member" } },
    { id = "essentials", name = "Essentials", hint = "Defensives, burst at frames; kicks in the panel",
        place = { Personal = "member", Burst = "member", Kick = "panel" } },
    { id = "caller", name = "Dungeon caller", hint = "Essentials plus stuns, CC and externals",
        place = { Personal = "member", Burst = "member", Kick = "panel", Control = "panel", External = "panel" } },
    { id = "healer", name = "Healer", hint = "Defensives at frames; externals, group saves in the panel",
        place = { Personal = "member", External = "panel", Group = "panel" } },
    { id = "everything", name = "Everything", hint = "All but dispels, purges and movement",
        place = { Personal = "member", Burst = "member", Racial = "member", Potion = "member", Kick = "panel", Control = "panel", External = "panel", Group = "panel" } },
}

function LayoutModel.Packs()
    return PACKS
end

function LayoutModel.ApplyPack(layout, id)
    for _, p in ipairs(PACKS) do
        if p.id == id then
            for _, t in ipairs(LayoutModel.VisibleTypes(layout)) do
                local want = p.place[(t == "Stun" or t == "CC") and "Control" or t] or "off"
                LayoutModel.SetPlace(layout, t, want)
            end
            layout.pack = id
        end
    end
    return layout
end

-- Switching a type back on puts it where it usually lives; one already shown stays put.
function LayoutModel.SetTracked(layout, type, on)
    layout.pack = nil
    if not on then return LayoutModel.SetPlace(layout, type, "off") end
    if LayoutModel.PlaceOf(layout, type) ~= "off" then return layout end
    return LayoutModel.SetPlace(layout, type, USUAL_PLACE[type] or "panel")
end

function LayoutModel.PlaceAll(layout, place)
    layout.pack = nil
    for _, t in ipairs(LayoutModel.VisibleTypes(layout)) do
        if LayoutModel.PlaceOf(layout, t) ~= "off" then LayoutModel.SetPlace(layout, t, place) end
    end
    return layout
end

function LayoutModel.AddToSection(layout, id, type)
    local target
    for _, s in ipairs(layout.sections) do
        if s.id == id then target = s end
    end
    if not target then return layout end
    for _, t in ipairs(target.types) do
        if t == type then return layout end
    end
    without(layout, type)
    target.types[#target.types + 1] = type
    return layout
end

local function remap(types, split, seen)
    local out = {}
    local function add(t)
        if not seen[t] then
            seen[t] = true
            out[#out + 1] = t
        end
    end
    for _, t in ipairs(types) do
        if split and t == "Control" then
            add("Stun")
            add("CC")
        elseif not split and (t == "Stun" or t == "CC") then
            add("Control")
        else
            add(t)
        end
    end
    return out
end

function LayoutModel.SetSplit(layout, split)
    split = split and true or false
    if layout.split == split then return layout end
    layout.split = split
    layout.typeOrder = remap(layout.typeOrder, split, {})
    local placed = {}
    local function containers(list)
        for _, c in ipairs(list) do
            c.types = remap(c.types, split, placed)
            if c.order then c.order = remap(c.order, split, {}) end
        end
    end
    containers(layout.sections)
    containers(layout.groups)
    local kept = {}
    for _, s in ipairs(layout.sections) do
        if #s.types > 0 then kept[#kept + 1] = s end
    end
    layout.sections = kept
    return layout
end

function LayoutModel.VisibleTypeOf(layout, spellType)
    if not layout.split and (spellType == "Stun" or spellType == "CC") then return "Control" end
    for _, t in ipairs(LayoutModel.VisibleTypes(layout)) do
        if t == spellType then return t end
    end
end

function LayoutModel.VisibleTypes(layout)
    return remap(ORDER, layout.split, {})
end

function LayoutModel.TypeOrder(layout, container)
    local members = {}
    for _, t in ipairs(container.types) do members[t] = true end
    local out, seen = {}, {}
    local function add(t)
        if members[t] and not seen[t] then
            seen[t] = true
            out[#out + 1] = t
        end
    end
    for _, t in ipairs(container.order or {}) do add(t) end
    for _, t in ipairs(layout.typeOrder) do add(t) end
    for _, t in ipairs(container.types) do add(t) end
    return out
end

function LayoutModel.OwnWindow(layout, section)
    return layout.overlay == "Windows" or section.ownWindow == true
end

function LayoutModel.Bars(layout, type)
    return type == "Kick" and layout.kickStyle == "Bars"
end

function LayoutModel.LineShape(layout, section, type)
    local own = LayoutModel.OwnWindow(layout, section)
    local shape = own and section.shape or layout.panelShape
    if not own and type == "Kick" and section.shape then
        shape = copy(section.shape)
        shape.origin = layout.panelShape.origin
    end
    if LayoutModel.Bars(layout, type) then
        shape = copy(shape)
        shape.axis, shape.perLine = "Rows", 1
    end
    return shape
end

function LayoutModel.LookOf(layout, container, member)
    return container.look or (member and layout.memberLook or layout.panelLook)
end

function LayoutModel.RoleOrder(layout)
    local valid, out, seen = {}, {}, {}
    for _, r in ipairs(ROLES) do valid[r] = true end
    for _, r in ipairs(layout.rolePriority) do
        if valid[r] and not seen[r] then
            seen[r] = true
            out[#out + 1] = r
        end
    end
    for _, r in ipairs(ROLES) do
        if not seen[r] then out[#out + 1] = r end
    end
    return out
end

local function sectionsOf(types)
    local out = {}
    for i, t in ipairs(types) do out[i] = section(t, { t }) end
    return out
end

local FRAME_TYPES = { "Personal", "Burst", "Racial", "Potion", "External", "Group" }
local ANCHORED = { "Kick", "Control", "Dispel", "Purge" }

function LayoutModel.Presets()
    local function beside(side, origin)
        return { group(copy(FRAME_TYPES), side, shape("Rows", 3, origin)) }
    end
    return {
        { id = 1, sections = sectionsOf(ORDER), panelShape = shape("Columns", 3, "TopLeft"), groups = {} },
        { id = 2, sections = sectionsOf(ORDER), panelShape = shape("Rows", 6, "TopLeft"), groups = {} },
        { id = 3, sections = sectionsOf(ANCHORED), panelShape = shape("Rows", 6, "TopLeft"), groups = beside("Left", "TopRight") },
        { id = 4, sections = sectionsOf(ANCHORED), panelShape = shape("Rows", 6, "TopLeft"), groups = beside("Right", "TopLeft") },
        { id = 5, sections = sectionsOf(ANCHORED), panelShape = shape("Rows", 6, "TopLeft"), groups = beside("Below", "TopLeft") },
        { id = 6, sections = sectionsOf(ANCHORED), panelShape = shape("Rows", 6, "TopLeft"), groups = beside("Above", "BottomLeft") },
    }
end

function LayoutModel.ApplyPreset(layout, n)
    local preset = LayoutModel.Presets()[n]
    if not preset then return layout end
    local first = layout.groups[1]
    layout.split = false
    layout.typeOrder = copy(ORDER)
    layout.sections = preset.sections
    layout.groups = preset.groups
    layout.panelShape = preset.panelShape
    layout.preset = n
    for _, g in ipairs(layout.groups) do
        g.offsetX = first and first.offsetX or 4
        g.offsetY = first and first.offsetY or 0
    end
    return layout
end

local function oneOf(v, list, default)
    for _, x in ipairs(list) do
        if v == x then return v end
    end
    return default
end

local function num(v, lo, hi, default)
    if type(v) ~= "number" or v ~= v then return default end
    return clamp(v, lo, hi)
end

local function bool(v, default)
    if type(v) == "boolean" then return v end
    return default
end

local AXES = { "Rows", "Columns" }
local CORNERS = { "TopLeft", "TopRight", "BottomLeft", "BottomRight" }
local SORTS = { "Fixed", "ReadyFirst" }
local SIDES = { "Right", "Left", "Above", "Below" }
local LABELS = { "None", "Icon", "Glyph", "Short", "Full" }
local BACKGROUNDS = { "Default", "Black", "Slate", "None" }

local function cleanLook(look, fallback, minSize, member)
    if type(look) ~= "table" then return nil end
    local labels = oneOf(look.labels, LABELS, fallback.labels)
    if member and labels == "Full" then labels = "Short" end
    return {
        iconSize = num(look.iconSize, minSize, 40, fallback.iconSize),
        labels = labels,
        background = oneOf(look.background, BACKGROUNDS, fallback.background),
        opacity = num(look.opacity, 0, 100, fallback.opacity),
        nameLetters = num(look.nameLetters, 3, 6, fallback.nameLetters),
    }
end

local function cleanShape(s, fallback, known)
    if type(s) ~= "table" then return fallback and copy(fallback) end
    local base = fallback or shape("Rows", 3, "TopLeft")
    local out = {
        axis = oneOf(s.axis, AXES, base.axis),
        perLine = num(s.perLine, 1, 12, base.perLine),
        origin = oneOf(s.origin, CORNERS, base.origin),
        sort = oneOf(s.sort, SORTS, base.sort),
    }
    return out
end

-- order replaced shape.typeOrder; an old saved shape.typeOrder is read once and moved.
local function cleanOrder(c, known)
    local list = c.order or type(c.shape) == "table" and c.shape.typeOrder
    if type(list) ~= "table" then return nil end
    local out, seen = {}, {}
    for _, t in ipairs(list) do
        if known[t] and not seen[t] then
            seen[t] = true
            out[#out + 1] = t
        end
    end
    return out
end

local function cleanPos(p)
    if type(p) ~= "table" or type(p.x) ~= "number" or type(p.y) ~= "number" or p.x ~= p.x or p.y ~= p.y then return nil end
    local out = { x = p.x, y = p.y }
    if type(p.dockTo) == "string" and p.dockTo ~= "" and type(p.offset) == "number" and p.offset == p.offset and math.abs(p.offset) ~= math.huge
        and oneOf(p.side, SIDES, nil) then
        out.dockTo, out.side, out.offset = p.dockTo, p.side, p.offset
    end
    return out
end

function LayoutModel.Normalize(layout)
    local d = LayoutModel.Defaults()
    if type(layout) ~= "table" then return d end
    layout.version = 2
    layout.overlay = oneOf(layout.overlay, { "OnePanel", "Windows" }, d.overlay)
    layout.kickStyle = oneOf(layout.kickStyle, { "Bars", "Icons" }, d.kickStyle)
    layout.showWhen = oneOf(layout.showWhen, { "always", "group" }, d.showWhen)
    layout.split = bool(layout.split, d.split)
    layout.timers = bool(layout.timers, d.timers)
    layout.memberFit = bool(layout.memberFit, d.memberFit)
    layout.panelShape = cleanShape(layout.panelShape, d.panelShape, {})
    layout.panelShape.typeOrder = nil
    layout.panelLook = cleanLook(layout.panelLook, d.panelLook, 20) or d.panelLook
    layout.memberLook = cleanLook(layout.memberLook, d.memberLook, 12, true) or d.memberLook
    local panel = type(layout.panel) == "table" and layout.panel or {}
    local point = type(panel.point) == "table" and #panel.point >= 1 and panel.point or d.panel.point
    layout.panel = { point = point }

    local shown = LayoutModel.VisibleTypes(layout)
    local known = {}
    for _, t in ipairs(shown) do known[t] = true end
    local order, seen = {}, {}
    for _, list in ipairs({ type(layout.typeOrder) == "table" and layout.typeOrder or {}, shown }) do
        for _, t in ipairs(list) do
            if known[t] and not seen[t] then
                seen[t] = true
                order[#order + 1] = t
            end
        end
    end
    layout.typeOrder = order

    local placed = {}
    local function claim(types)
        local out = {}
        for _, t in ipairs(type(types) == "table" and types or {}) do
            if known[t] and not placed[t] then
                placed[t] = true
                out[#out + 1] = t
            end
        end
        return out
    end
    local ids, sections = {}, {}
    for _, s in ipairs(type(layout.sections) == "table" and layout.sections or {}) do
        if type(s) == "table" then
            local types = claim(s.types)
            if #types > 0 then
                local id = type(s.id) == "string" and s.id ~= "" and s.id ~= "panel" and not ids[s.id] and s.id or nil
                if not id then
                    local n = 1
                    while ids["s" .. n] do n = n + 1 end
                    id = "s" .. n
                end
                ids[id] = true
                sections[#sections + 1] = {
                    id = id, types = types, shown = bool(s.shown, true), ownWindow = bool(s.ownWindow, false),
                    shape = cleanShape(s.shape, nil, known),
                    order = cleanOrder(s, known),
                    look = cleanLook(s.look, layout.panelLook, 20),
                    pos = cleanPos(s.pos),
                }
            end
        end
    end
    local byId = {}
    for _, s in ipairs(sections) do byId[s.id] = s end
    local function undock(p)
        p.dockTo, p.side, p.offset = nil, nil, nil
    end
    for _, s in ipairs(sections) do
        local p = s.pos
        if p and p.dockTo and (p.dockTo == s.id or not (byId[p.dockTo] or p.dockTo == "panel")) then undock(p) end
    end
    for _, s in ipairs(sections) do
        local at, steps = s, 0
        while at and at.pos and at.pos.dockTo and steps <= #sections do
            at = byId[at.pos.dockTo]
            steps = steps + 1
            if at == s then
                undock(s.pos)
                break
            end
        end
    end
    layout.sections = sections

    local groups = {}
    for _, g in ipairs(type(layout.groups) == "table" and layout.groups or {}) do
        if type(g) == "table" then
            groups[#groups + 1] = {
                types = claim(g.types),
                side = oneOf(g.side, SIDES, "Left"),
                shape = cleanShape(g.shape, newGroupShape(), known),
                order = cleanOrder(g, known),
                look = cleanLook(g.look, layout.memberLook, 12, true),
                shown = bool(g.shown, true),
                offsetX = num(g.offsetX, -400, 400, 4),
                offsetY = num(g.offsetY, -400, 400, 0),
                gap = num(g.gap, 0, 40, nil),
            }
        end
    end
    layout.groups = groups

    if type(layout.rolePriority) ~= "table" then layout.rolePriority = {} end
    layout.rolePriority = LayoutModel.RoleOrder(layout)
    local classOrder = type(layout.classOrder) == "table" and layout.classOrder or {}
    layout.classOrder = {}
    for _, role in ipairs(ROLES) do
        local out, have = {}, {}
        local src = type(classOrder[role]) == "table" and classOrder[role] or {}
        for i = 1, #src + CLASS_COUNT do
            local c = i <= #src and src[i] or i - #src
            if type(c) == "number" and c >= 1 and c <= CLASS_COUNT and c % 1 == 0 and not have[c] then
                have[c] = true
                out[#out + 1] = c
            end
        end
        layout.classOrder[role] = out
    end
    return layout
end

local function migrated(db)
    local layout = LayoutModel.Defaults()
    local placement = db.placement or {}
    local function where(t)
        return placement[t] or V1_PLACEMENT[t]
    end
    local split = where("Stun") ~= where("CC")
    layout.split = split
    layout.typeOrder = remap(ORDER, split, {})
    layout.sections, layout.groups[1].types = {}, {}
    local members = layout.groups[1].types
    for _, t in ipairs(V1_ORDER) do
        local name = (not split and (t == "Stun" or t == "CC")) and "Control" or t
        if not (t == "CC" and not split) then
            local w = where(t)
            if w == "Panel" then
                layout.sections[#layout.sections + 1] = section(name, { name })
            elseif w == "Row" then
                members[#members + 1] = name
            end
        end
    end
    local row, panel = db.row or {}, db.panel or {}
    local g = layout.groups[1]
    g.side = V1_SIDES[row.side] or "Left"
    g.shape.perLine = clamp(row.max or 8, 1, 12)
    g.gap = row.spacing or 2
    g.look = memberLook()
    g.look.iconSize = clamp(row.size or 24, 12, 40)
    layout.panelLook.iconSize = clamp(panel.size or 22, 20, 40)
    layout.panel = { point = copy(panel.point or layout.panel.point) }
    return layout
end

function LayoutModel.Migrate(db)
    if db.layout then return db end
    if db.placement == nil and db.row == nil and db.panel == nil then
        db.layout = LayoutModel.ApplyPack(LayoutModel.Defaults(), "essentials")
    else
        db.layout = migrated(db)
    end
    db.version = 2
    db.wizardDue = true
    return db
end
