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

local function copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = copy(x) end
    return t
end

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

local function panelLook()
    return { iconSize = 26, labels = "Glyph", background = "Default", opacity = 90, nameLetters = 5 }
end

local function memberLook()
    return { iconSize = 26, labels = "Glyph", background = "None", opacity = 100, nameLetters = 5 }
end

function LayoutModel.Defaults()
    local classOrder = {}
    for _, role in ipairs(ROLES) do
        classOrder[role] = {}
        for i = 1, CLASS_COUNT do classOrder[role][i] = i end
    end
    return {
        version = 2,
        overlay = "OnePanel",
        split = false,
        typeOrder = copy(ORDER),
        sections = {
            section("Kick", { "Kick" }), section("Control", { "Control" }),
            section("External", { "External" }), section("Group", { "Group" }),
        },
        groups = { group({ "Personal", "Burst", "Racial", "Potion" }, "Left", newGroupShape()) },
        panelShape = shape("Rows", 6, "TopLeft"),
        panelLook = panelLook(),
        memberLook = memberLook(),
        panel = { point = { "CENTER", 0, -200 }, locked = true },
        timers = true,
        memberFit = true,
        kickStyle = "Bars",
        rolePriority = copy(ROLES),
        classOrder = classOrder,
    }
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
            layout.groups[1] = group({}, "Right", newGroupShape())
        end
        local types = layout.groups[1].types
        types[#types + 1] = type
    end
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
            if c.shape and c.shape.typeOrder then
                c.shape.typeOrder = remap(c.shape.typeOrder, split, {})
            end
        end
    end
    containers(layout.sections)
    containers(layout.groups)
    return layout
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
    local override = container.shape and container.shape.typeOrder
    for _, t in ipairs(override or {}) do add(t) end
    for _, t in ipairs(layout.typeOrder) do add(t) end
    for _, t in ipairs(container.types) do add(t) end
    return out
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
    layout.panel = { point = copy(panel.point or layout.panel.point), locked = panel.locked ~= false }
    return layout
end

function LayoutModel.Migrate(db)
    if db.layout then return db end
    if db.placement == nil and db.row == nil and db.panel == nil then
        db.layout = LayoutModel.Defaults()
    else
        db.layout = migrated(db)
    end
    db.version = 2
    return db
end
