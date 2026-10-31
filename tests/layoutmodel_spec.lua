local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local function load()
    return helpers.load({ "Logic/LayoutModel.lua" }).LayoutModel
end

local ALL = { "Personal", "Burst", "Racial", "Potion", "External", "Kick", "Control", "Group", "Dispel", "Purge", "Movement" }
local SPLIT = { "Personal", "Burst", "Racial", "Potion", "External", "Kick", "Stun", "CC", "Group", "Dispel", "Purge", "Movement" }

local function placements(L, layout)
    local out = {}
    for _, t in ipairs(L.VisibleTypes(layout)) do
        out[t] = out[t] or {}
        for _, s in ipairs(layout.sections) do
            for _, x in ipairs(s.types) do if x == t then table.insert(out[t], "s:" .. s.id) end end
        end
        for i, g in ipairs(layout.groups) do
            for _, x in ipairs(g.types) do if x == t then table.insert(out[t], "g:" .. i) end end
        end
    end
    return out
end

local function assertOnePlaceEach(L, layout)
    for t, where in pairs(placements(L, layout)) do
        assert.is_true(#where <= 1, t .. " placed in " .. table.concat(where, ","))
    end
end

local function v1db(over)
    local db = {
        version = 1,
        placement = {
            Personal = "Row", Burst = "Row", Racial = "Row", Potion = "Row",
            External = "Panel", Kick = "Panel", Stun = "Panel", CC = "Panel", Group = "Panel",
            Dispel = "Off", Purge = "Off", Movement = "Off",
        },
        row = { side = "LEFT", size = 24, spacing = 2, max = 8, point = { "CENTER", -360, 120 } },
        panel = { point = { "CENTER", 0, -200 }, size = 22, locked = true },
        spells = { [1234] = false },
        window = { x = 1 },
        timers = { a = 5 },
    }
    for k, v in pairs(over or {}) do db[k] = v end
    return db
end

describe("LayoutModel.Defaults", function()
    it("matches the spec", function()
        local L = load()
        local d = L.Defaults()
        assert.are.equal(2, d.version)
        assert.are.equal("OnePanel", d.overlay)
        assert.is_false(d.split)
        assert.is_true(d.timers)
        assert.is_true(d.memberFit)
        assert.are.equal("Bars", d.kickStyle)
        assert.are.same(ALL, d.typeOrder)
        local ids = {}
        for i, s in ipairs(d.sections) do
            ids[i] = s.id
            assert.are.same({ s.id }, s.types)
            assert.is_true(s.shown)
            assert.is_false(s.ownWindow)
            assert.is_nil(s.shape)
            assert.is_nil(s.look)
        end
        assert.are.same({ "Kick", "Control", "External", "Group" }, ids)
        assert.are.equal(1, #d.groups)
        local g = d.groups[1]
        assert.are.same({ "Personal", "Burst", "Racial", "Potion" }, g.types)
        assert.are.equal("Left", g.side)
        assert.are.same({ axis = "Rows", perLine = 3, origin = "TopLeft", sort = "Fixed" }, g.shape)
        assert.are.equal(4, g.offsetX)
        assert.are.equal(0, g.offsetY)
        assert.is_true(g.shown)
        assert.are.same({ axis = "Rows", perLine = 6, origin = "TopLeft", sort = "Fixed" }, d.panelShape)
        assert.are.same({ iconSize = 26, labels = "Glyph", background = "Default", opacity = 90, nameLetters = 5 }, d.panelLook)
        assert.are.same({ iconSize = 26, labels = "Glyph", background = "None", opacity = 100, nameLetters = 5 }, d.memberLook)
        assert.are.same({ "Tank", "Melee", "Ranged", "Healer" }, d.rolePriority)
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }, d.classOrder.Tank)
    end)

    it("returns independent copies", function()
        local L = load()
        local a, b = L.Defaults(), L.Defaults()
        a.sections[1].types[1] = "x"
        a.groups[1].shape.perLine = 9
        a.classOrder.Tank[1] = 99
        assert.are.equal("Kick", b.sections[1].types[1])
        assert.are.equal(3, b.groups[1].shape.perLine)
        assert.are.equal(1, b.classOrder.Tank[1])
    end)
end)

describe("LayoutModel.PlaceOf / SetPlace", function()
    it("derives placement", function()
        local L = load()
        local d = L.Defaults()
        local p, i = L.PlaceOf(d, "Kick")
        assert.are.equal("panel", p) assert.are.equal(1, i)
        p, i = L.PlaceOf(d, "Group")
        assert.are.equal("panel", p) assert.are.equal(4, i)
        p, i = L.PlaceOf(d, "Potion")
        assert.are.equal("member", p) assert.are.equal(1, i)
        p, i = L.PlaceOf(d, "Purge")
        assert.are.equal("off", p) assert.is_nil(i)
    end)

    it("moves a panel type to the party frames and drops its emptied section", function()
        local L = load()
        local d = L.Defaults()
        L.SetPlace(d, "Kick", "member")
        assert.are.same({ "Personal", "Burst", "Racial", "Potion", "Kick" }, d.groups[1].types)
        assert.are.equal(3, #d.sections)
        assert.are.equal("member", (L.PlaceOf(d, "Kick")))
        assertOnePlaceEach(L, d)
    end)

    it("moves a member type into a new section and an off type into the panel", function()
        local L = load()
        local d = L.Defaults()
        L.SetPlace(d, "Racial", "panel")
        L.SetPlace(d, "Purge", "panel")
        local p, i = L.PlaceOf(d, "Racial")
        assert.are.equal("panel", p) assert.are.equal(5, i)
        assert.are.equal("Racial", d.sections[5].id)
        assert.are.same({ "Purge" }, d.sections[6].types)
        assert.are.same({ "Personal", "Burst", "Potion" }, d.groups[1].types)
        assertOnePlaceEach(L, d)
    end)

    it("moves to off", function()
        local L = load()
        local d = L.Defaults()
        L.SetPlace(d, "Control", "off")
        L.SetPlace(d, "Burst", "off")
        assert.are.equal("off", (L.PlaceOf(d, "Control")))
        assert.are.equal("off", (L.PlaceOf(d, "Burst")))
        assert.are.equal(3, #d.sections)
    end)

    it("is a no-op when the type is already there", function()
        local L = load()
        local d = L.Defaults()
        L.SetPlace(d, "External", "panel")
        L.SetPlace(d, "Burst", "member")
        local _, i = L.PlaceOf(d, "External")
        assert.are.equal(3, i)
        assert.are.same({ "Personal", "Burst", "Racial", "Potion" }, d.groups[1].types)
    end)

    it("creates the first member group when there is none", function()
        local L = load()
        local d = L.Defaults()
        d.groups = {}
        L.SetPlace(d, "Kick", "member")
        assert.are.equal(1, #d.groups)
        assert.are.same({ "Kick" }, d.groups[1].types)
        assert.are.same({ axis = "Rows", perLine = 3, origin = "TopLeft", sort = "Fixed" }, d.groups[1].shape)
    end)

    it("takes a fresh section id when the type name is already used", function()
        local L = load()
        local d = L.Defaults()
        d.sections[1].id = "Purge"
        L.SetPlace(d, "Purge", "panel")
        assert.are.equal("s1", d.sections[#d.sections].id)
    end)

    it("keeps one place per type through a shuffle", function()
        local L = load()
        local d = L.Defaults()
        local places = { "panel", "member", "off" }
        for n = 1, 60 do
            L.SetPlace(d, ALL[(n * 7) % #ALL + 1], places[(n * 5) % 3 + 1])
            assertOnePlaceEach(L, d)
        end
    end)
end)

describe("LayoutModel.SetSplit", function()
    it("splits Control into Stun and CC in place", function()
        local L = load()
        local d = L.Defaults()
        L.SetSplit(d, true)
        assert.is_true(d.split)
        assert.are.same({ "Stun", "CC" }, d.sections[2].types)
        assert.are.equal("panel", (L.PlaceOf(d, "Stun")))
        assert.are.equal("panel", (L.PlaceOf(d, "CC")))
        assert.are.equal("off", (L.PlaceOf(d, "Control")))
        assert.are.same(SPLIT, d.typeOrder)
    end)

    it("merges back to one Control at the first position", function()
        local L = load()
        local d = L.Defaults()
        L.SetSplit(d, true)
        L.SetPlace(d, "CC", "member")
        L.SetSplit(d, false)
        assert.is_false(d.split)
        assert.are.same({ "Control" }, d.sections[2].types)
        assert.are.same({ "Personal", "Burst", "Racial", "Potion" }, d.groups[1].types)
        assert.are.same(ALL, d.typeOrder)
        assertOnePlaceEach(L, d)
    end)

    it("remaps a per-section order override", function()
        local L = load()
        local d = L.Defaults()
        d.groups[1].types = { "Personal", "Control" }
        d.groups[1].shape.typeOrder = { "Control", "Personal" }
        L.SetSplit(d, true)
        assert.are.same({ "Stun", "CC", "Personal" }, d.groups[1].shape.typeOrder)
    end)
end)

describe("LayoutModel.VisibleTypes", function()
    it("shows Control merged, Stun and CC when split", function()
        local L = load()
        local d = L.Defaults()
        assert.are.same(ALL, L.VisibleTypes(d))
        L.SetSplit(d, true)
        assert.are.same(SPLIT, L.VisibleTypes(d))
    end)
end)

describe("LayoutModel.TypeOrder / RoleOrder", function()
    it("orders a container by the global order", function()
        local L = load()
        local d = L.Defaults()
        d.groups[1].types = { "Potion", "Personal", "Racial" }
        assert.are.same({ "Personal", "Racial", "Potion" }, L.TypeOrder(d, d.groups[1]))
    end)

    it("uses a container override and appends types it does not list", function()
        local L = load()
        local d = L.Defaults()
        d.groups[1].types = { "Potion", "Personal", "Racial" }
        d.groups[1].shape.typeOrder = { "Racial", "Gone", "Potion" }
        assert.are.same({ "Racial", "Potion", "Personal" }, L.TypeOrder(d, d.groups[1]))
    end)

    it("reorders the global order when it changes", function()
        local L = load()
        local d = L.Defaults()
        d.typeOrder = { "Kick", "Control", "External", "Group", "Personal", "Burst", "Racial", "Potion", "Dispel", "Purge", "Movement" }
        assert.are.same({ "External", "Group" }, L.TypeOrder(d, { types = { "Group", "External" } }))
        assert.are.same({ "Personal", "Burst", "Racial", "Potion" }, L.TypeOrder(d, d.groups[1]))
        assert.are.same({ "Kick", "Control" }, L.TypeOrder(d, { types = { "Control", "Kick" } }))
    end)

    it("keeps role priority complete and valid", function()
        local L = load()
        local d = L.Defaults()
        assert.are.same({ "Tank", "Melee", "Ranged", "Healer" }, L.RoleOrder(d))
        d.rolePriority = { "Healer", "Bogus", "Healer", "Tank" }
        assert.are.same({ "Healer", "Tank", "Melee", "Ranged" }, L.RoleOrder(d))
    end)
end)

describe("LayoutModel presets", function()
    local function sectionTypes(p)
        local out = {}
        for i, s in ipairs(p.sections) do out[i] = table.concat(s.types, "+") end
        return out
    end

    it("has six", function()
        local L = load()
        assert.are.equal(6, #L.Presets())
    end)

    it("1 and 2 put everything in the panel, one section per type", function()
        local L = load()
        local p = L.Presets()
        assert.are.same(ALL, sectionTypes(p[1]))
        assert.are.same(ALL, sectionTypes(p[2]))
        assert.are.same({ axis = "Columns", perLine = 3, origin = "TopLeft", sort = "Fixed" }, p[1].panelShape)
        assert.are.same({ axis = "Rows", perLine = 6, origin = "TopLeft", sort = "Fixed" }, p[2].panelShape)
        assert.are.equal(0, #p[1].groups)
        assert.are.equal(0, #p[2].groups)
    end)

    it("3 to 6 keep Kick, Control, Dispel and Purge in the panel and the rest at the frames", function()
        local L = load()
        local p = L.Presets()
        for n = 3, 6 do
            assert.are.same({ "Kick", "Control", "Dispel", "Purge" }, sectionTypes(p[n]))
            assert.are.same({ axis = "Rows", perLine = 6, origin = "TopLeft", sort = "Fixed" }, p[n].panelShape)
            assert.are.equal(1, #p[n].groups)
            assert.are.same({ "Personal", "Burst", "Racial", "Potion", "External", "Group" }, p[n].groups[1].types)
        end
        local g = function(n) return p[n].groups[1] end
        assert.are.equal("Left", g(3).side) assert.are.equal("TopRight", g(3).shape.origin)
        assert.are.equal("Right", g(4).side) assert.are.equal("TopLeft", g(4).shape.origin)
        assert.are.equal("Below", g(5).side) assert.are.equal("TopLeft", g(5).shape.origin)
        assert.are.equal("Above", g(6).side) assert.are.equal("BottomLeft", g(6).shape.origin)
        assert.are.equal(3, g(3).shape.perLine)
        assert.are.equal("Rows", g(6).shape.axis)
    end)

    it("returns fresh copies", function()
        local L = load()
        L.Presets()[3].groups[1].types[1] = "x"
        assert.are.equal("Personal", L.Presets()[3].groups[1].types[1])
    end)

    it("ApplyPreset rewrites the arrangement and keeps member offsets", function()
        local L = load()
        local d = L.Defaults()
        d.groups[1].offsetX, d.groups[1].offsetY = 17, -5
        L.SetSplit(d, true)
        d.overlay = "Windows"
        L.ApplyPreset(d, 4)
        assert.is_false(d.split)
        assert.are.same(ALL, d.typeOrder)
        assert.are.equal("Windows", d.overlay)
        assert.are.same({ "Kick", "Control", "Dispel", "Purge" }, { d.sections[1].id, d.sections[2].id, d.sections[3].id, d.sections[4].id })
        assert.are.equal("Right", d.groups[1].side)
        assert.are.equal(17, d.groups[1].offsetX)
        assert.are.equal(-5, d.groups[1].offsetY)
        assert.are.equal(4, d.preset)
        assertOnePlaceEach(L, d)
        assert.are.equal("off", (L.PlaceOf(d, "Movement")))
    end)

    it("ApplyPreset 1 drops member groups", function()
        local L = load()
        local d = L.Defaults()
        L.ApplyPreset(d, 1)
        assert.are.equal(0, #d.groups)
        assert.are.equal("panel", (L.PlaceOf(d, "Potion")))
        assert.are.equal("Columns", d.panelShape.axis)
    end)

    it("ApplyPreset does not share tables with the preset", function()
        local L = load()
        local d = L.Defaults()
        L.ApplyPreset(d, 3)
        d.groups[1].types[1] = "x"
        d.panelShape.perLine = 1
        assert.are.equal("Personal", L.Presets()[3].groups[1].types[1])
        assert.are.equal(6, L.Presets()[3].panelShape.perLine)
    end)
end)

describe("LayoutModel.Migrate", function()
    it("gives a fresh install the defaults", function()
        local L = load()
        local db = {}
        L.Migrate(db)
        assert.are.same(L.Defaults(), db.layout)
        assert.are.equal(2, db.version)
    end)

    it("keeps v1 choices", function()
        local L = load()
        local db = v1db({
            placement = {
                Personal = "Panel", Burst = "Row", Racial = "Off", Potion = "Row",
                External = "Row", Kick = "Panel", Stun = "Panel", CC = "Panel", Group = "Panel",
                Dispel = "Panel", Purge = "Off", Movement = "Row",
            },
            row = { side = "RIGHT", size = 30, spacing = 4, max = 5, point = { "CENTER", 1, 2 } },
            panel = { point = { "TOP", 10, -20 }, size = 28, locked = false },
        })
        L.Migrate(db)
        local d = db.layout
        assert.are.equal(2, db.version)
        assert.are.equal(2, d.version)
        local ids = {}
        for i, s in ipairs(d.sections) do
            ids[i] = s.id
            assert.are.same({ s.id }, s.types)
        end
        assert.are.same({ "Personal", "Kick", "Control", "Group", "Dispel" }, ids)
        assert.are.same({ "Burst", "Potion", "External", "Movement" }, d.groups[1].types)
        assert.are.equal("Right", d.groups[1].side)
        assert.are.equal(5, d.groups[1].shape.perLine)
        assert.are.equal("Rows", d.groups[1].shape.axis)
        assert.are.equal(30, d.groups[1].look.iconSize)
        assert.are.equal(4, d.groups[1].gap)
        assert.are.equal(28, d.panelLook.iconSize)
        assert.are.same({ "TOP", 10, -20 }, d.panel.point)
        assert.is_false(d.panel.locked)
        assert.is_false(d.split)
        assert.are.equal("off", (L.PlaceOf(d, "Racial")))
        assert.are.equal("off", (L.PlaceOf(d, "Purge")))
        assertOnePlaceEach(L, d)
        assert.are.same(ALL, d.typeOrder)
    end)

    it("keeps spells, timers, window and the v1 fields", function()
        local L = load()
        local db = v1db()
        L.Migrate(db)
        assert.are.same({ [1234] = false }, db.spells)
        assert.are.same({ a = 5 }, db.timers)
        assert.are.same({ x = 1 }, db.window)
        assert.are.equal("Row", db.placement.Personal)
        assert.are.equal("LEFT", db.row.side)
        assert.are.equal(22, db.panel.size)
    end)

    it("splits Control when Stun and CC were placed differently", function()
        local L = load()
        local db = v1db()
        db.placement.CC = "Row"
        L.Migrate(db)
        local d = db.layout
        assert.is_true(d.split)
        assert.are.equal("panel", (L.PlaceOf(d, "Stun")))
        assert.are.equal("member", (L.PlaceOf(d, "CC")))
        assertOnePlaceEach(L, d)
    end)

    it("migrates a Control that was off in v1", function()
        local L = load()
        local db = v1db()
        db.placement.Stun, db.placement.CC = "Off", "Off"
        L.Migrate(db)
        assert.is_false(db.layout.split)
        assert.are.equal("off", (L.PlaceOf(db.layout, "Control")))
    end)

    it("clamps odd v1 sizes and maps missing fields to v1 defaults", function()
        local L = load()
        local db = { placement = { Kick = "Off" }, row = { size = 99, max = 0 }, panel = { size = 5 } }
        L.Migrate(db)
        local d = db.layout
        assert.are.equal("off", (L.PlaceOf(d, "Kick")))
        assert.are.equal("member", (L.PlaceOf(d, "Personal")))
        assert.are.equal(40, d.groups[1].look.iconSize)
        assert.are.equal(1, d.groups[1].shape.perLine)
        assert.are.equal("Left", d.groups[1].side)
        assert.are.equal(20, d.panelLook.iconSize)
        assert.are.same({ "CENTER", 0, -200 }, d.panel.point)
        assert.is_true(d.panel.locked)
    end)

    it("does nothing when the layout already exists", function()
        local L = load()
        local db = { version = 2, layout = L.Defaults() }
        db.layout.sections = {}
        L.Migrate(db)
        assert.are.equal(0, #db.layout.sections)
    end)

    it("is idempotent", function()
        local L = load()
        local db = v1db()
        L.Migrate(db)
        local once = db.layout
        L.Migrate(db)
        assert.are.equal(once, db.layout)
    end)
end)

describe("LayoutModel fix round 1", function()
    it("unsplit of a migrated db leaves no empty section", function()
        local L = load()
        local db = v1db()
        db.placement.CC = "Panel"
        db.placement.Stun = "Off"
        L.Migrate(db)
        local d = db.layout
        assert.is_true(d.split)
        L.SetSplit(d, false)
        for _, s in ipairs(d.sections) do assert.is_true(#s.types > 0) end
        assertOnePlaceEach(L, d)
    end)

    it("unsplit drops the duplicate section", function()
        local L = load()
        local d = L.Defaults()
        L.SetSplit(d, true)
        d.sections[2].types = { "Stun" }
        d.sections[#d.sections + 1] = { id = "CC", types = { "CC" }, shown = true, ownWindow = false }
        L.SetSplit(d, false)
        assert.are.equal(4, #d.sections)
        assert.are.same({ "Control" }, d.sections[2].types)
    end)

    it("SetPlace ignores an unknown place and ApplyPreset an invalid preset", function()
        local L = load()
        local d = L.Defaults()
        L.SetPlace(d, "Kick", "bogus")
        L.ApplyPreset(d, 0)
        L.ApplyPreset(d, 7)
        L.ApplyPreset(d, "x")
        assert.are.same(L.Defaults(), d)
    end)

    it("VisibleTypeOf maps spell types", function()
        local L = load()
        local d = L.Defaults()
        assert.are.equal("Control", L.VisibleTypeOf(d, "Stun"))
        assert.are.equal("Control", L.VisibleTypeOf(d, "CC"))
        assert.are.equal("Kick", L.VisibleTypeOf(d, "Kick"))
        assert.is_nil(L.VisibleTypeOf(d, "Bogus"))
        L.SetSplit(d, true)
        assert.are.equal("Stun", L.VisibleTypeOf(d, "Stun"))
        assert.are.equal("CC", L.VisibleTypeOf(d, "CC"))
        assert.is_nil(L.VisibleTypeOf(d, "Control"))
    end)

    it("Normalize leaves defaults unchanged", function()
        local L = load()
        assert.are.same(L.Defaults(), L.Normalize(L.Defaults()))
        assert.are.same(L.Defaults(), L.Normalize("junk"))
    end)

    it("Normalize fills a partial layout", function()
        local L = load()
        local d = L.Normalize({ sections = { { types = { "Kick" } } }, groups = { { types = { "Burst" } } } })
        assert.are.equal(2, d.version)
        assert.are.equal("OnePanel", d.overlay)
        assert.are.same(ALL, d.typeOrder)
        assert.are.same({ "Tank", "Melee", "Ranged", "Healer" }, d.rolePriority)
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }, d.classOrder.Healer)
        assert.are.equal("s1", d.sections[1].id)
        assert.are.equal("Left", d.groups[1].side)
        assert.are.same({ axis = "Rows", perLine = 3, origin = "TopLeft", sort = "Fixed" }, d.groups[1].shape)
        assert.are.equal(4, d.groups[1].offsetX)
        assert.are.same(L.Defaults().panelLook, d.panelLook)
        assert.is_true(d.timers)
        assert.are.same({ "CENTER", 0, -200 }, d.panel.point)
    end)

    it("Normalize clamps out-of-range values", function()
        local L = load()
        local d = L.Defaults()
        d.panelLook = { iconSize = 5, labels = "Bogus", background = "Pink", opacity = 500, nameLetters = 1 }
        d.memberLook = { iconSize = 99, labels = "Full", background = "None", opacity = -4, nameLetters = 9 }
        d.panelShape.perLine = 50
        d.groups[1].shape.perLine = 0
        d.groups[1].offsetX, d.groups[1].offsetY = 9999, -9999
        d.groups[1].look = { iconSize = 3, labels = "Full" }
        d.sections[1].look = { iconSize = 3 }
        d.overlay, d.kickStyle, d.groups[1].side = "x", "y", "z"
        L.Normalize(d)
        assert.are.same({ iconSize = 20, labels = "Glyph", background = "Default", opacity = 100, nameLetters = 3 }, d.panelLook)
        assert.are.same({ iconSize = 40, labels = "Short", background = "None", opacity = 0, nameLetters = 6 }, d.memberLook)
        assert.are.equal(12, d.panelShape.perLine)
        assert.are.equal(1, d.groups[1].shape.perLine)
        assert.are.equal(400, d.groups[1].offsetX)
        assert.are.equal(-400, d.groups[1].offsetY)
        assert.are.equal(12, d.groups[1].look.iconSize)
        assert.are.equal("Short", d.groups[1].look.labels)
        assert.are.equal(20, d.sections[1].look.iconSize)
        assert.are.equal("OnePanel", d.overlay)
        assert.are.equal("Bars", d.kickStyle)
        assert.are.equal("Left", d.groups[1].side)
    end)

    it("Normalize drops unknown and duplicate types, empty sections, and fixes orders", function()
        local L = load()
        local d = L.Defaults()
        d.typeOrder = { "Kick", "Bogus", "Kick", "Group" }
        d.sections[1].types = { "Kick", "Kick", "Stun", "Bogus" }
        d.sections[2].types = { "Bogus" }
        d.groups[1].shape.typeOrder = { "Personal", "Bogus", "Personal" }
        d.rolePriority = { "Healer", "Healer", "Nope" }
        d.classOrder.Tank = { 5, 5, 99, "x", 2 }
        L.Normalize(d)
        assert.are.same({ "Kick" }, d.sections[1].types)
        assert.are.equal("External", d.sections[2].id)
        assert.are.equal(3, #d.sections)
        assert.are.same({ "Kick", "Group", "Personal", "Burst", "Racial", "Potion", "External", "Control", "Dispel", "Purge", "Movement" }, d.typeOrder)
        assert.are.same({ "Personal" }, d.groups[1].shape.typeOrder)
        assert.are.same({ "Healer", "Tank", "Melee", "Ranged" }, d.rolePriority)
        assert.are.same({ 5, 2, 1, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13 }, d.classOrder.Tank)
    end)

    it("Normalize keeps a type in one container only", function()
        local L = load()
        local d = L.Defaults()
        d.groups[1].types = { "Personal", "Kick", "Burst" }
        d.sections[3].types = { "External", "Personal" }
        L.Normalize(d)
        assert.are.equal("panel", (L.PlaceOf(d, "Kick")))
        assert.are.equal("panel", (L.PlaceOf(d, "Personal")))
        assert.are.same({ "Burst" }, d.groups[1].types)
        assertOnePlaceEach(L, d)
    end)

    it("Normalize honours split when judging known types", function()
        local L = load()
        local d = L.Defaults()
        d.sections[2].types = { "Stun", "CC" }
        L.Normalize(d)
        assert.are.equal("External", d.sections[2].id)
        L.SetSplit(d, true)
        d.sections[#d.sections + 1] = { id = "x", types = { "Stun" } }
        L.Normalize(d)
        assertOnePlaceEach(L, d)
    end)

    it("Normalize keeps a section window position and its dock", function()
        local L = load()
        local d = L.Defaults()
        d.sections[1].pos = { x = 10, y = 20, dockTo = "panel", side = "Below", offset = 4, junk = 1 }
        d.sections[2].pos = { x = 30, y = 40, dockTo = "Kick", side = "Right", offset = -3 }
        L.Normalize(d)
        assert.are.same({ x = 10, y = 20, dockTo = "panel", side = "Below", offset = 4 }, d.sections[1].pos)
        assert.are.same({ x = 30, y = 40, dockTo = "Kick", side = "Right", offset = -3 }, d.sections[2].pos)
    end)

    it("Normalize renames a section whose id is the reserved panel id", function()
        local L = load()
        local d = L.Defaults()
        d.sections[2].id = "panel"
        L.Normalize(d)
        assert.are.equal("Kick", d.sections[1].id)
        assert.are.equal("s1", d.sections[2].id)
    end)

    it("Normalize drops broken positions and docks to self or unknown windows", function()
        local L = load()
        local d = L.Defaults()
        d.sections[1].pos = { x = "a", y = 1 }
        d.sections[2].pos = { x = 5, y = 6, dockTo = "Control", side = "Right", offset = 0 }
        d.sections[3].pos = { x = 5, y = 6, dockTo = "gone", side = "Right", offset = 0 }
        d.sections[4].pos = { x = 5, y = 6, dockTo = "Kick", side = "Diagonal", offset = 0 }
        L.Normalize(d)
        assert.is_nil(d.sections[1].pos)
        assert.are.same({ x = 5, y = 6 }, d.sections[2].pos)
        assert.are.same({ x = 5, y = 6 }, d.sections[3].pos)
        assert.are.same({ x = 5, y = 6 }, d.sections[4].pos)
    end)

    it("Normalize breaks a dock cycle at the first section in array order", function()
        local L = load()
        local d = L.Defaults()
        d.sections[1].pos = { x = 1, y = 2, dockTo = "Control", side = "Right", offset = 0 }
        d.sections[2].pos = { x = 3, y = 4, dockTo = "Kick", side = "Below", offset = 5 }
        d.sections[3].pos = { x = 7, y = 8, dockTo = "Control", side = "Left", offset = 9 }
        L.Normalize(d)
        assert.are.same({ x = 1, y = 2 }, d.sections[1].pos)
        assert.are.same({ x = 3, y = 4, dockTo = "Kick", side = "Below", offset = 5 }, d.sections[2].pos)
        assert.are.same({ x = 7, y = 8, dockTo = "Control", side = "Left", offset = 9 }, d.sections[3].pos)
    end)

    it("Normalize drops an infinite dock offset", function()
        local L = load()
        local d = L.Defaults()
        d.sections[1].pos = { x = 1, y = 2, dockTo = "panel", side = "Right", offset = math.huge }
        L.Normalize(d)
        assert.are.same({ x = 1, y = 2 }, d.sections[1].pos)
    end)

    describe("line shape and look", function()
        local own = { axis = "Columns", perLine = 2, origin = "BottomRight", sort = "ReadyFirst" }

        it("a section in the one panel uses the panel shape", function()
            local L = load()
            local d = L.Defaults()
            d.sections[2].shape = own
            assert.is_false(L.OwnWindow(d, d.sections[2]))
            assert.are.same(d.panelShape, L.LineShape(d, d.sections[2], "Control"))
        end)

        it("a section in its own window uses its own shape, or the panel shape without one", function()
            local L = load()
            local d = L.Defaults()
            d.sections[2].shape, d.sections[2].ownWindow = own, true
            assert.is_true(L.OwnWindow(d, d.sections[2]))
            assert.are.same(own, L.LineShape(d, d.sections[2], "Control"))
            d.overlay = "Windows"
            assert.is_true(L.OwnWindow(d, d.sections[3]))
            assert.are.same(d.panelShape, L.LineShape(d, d.sections[3], "External"))
        end)

        it("the kick line keeps its own shape in the one panel, at the panel origin", function()
            local L = load()
            local d = L.Defaults()
            d.kickStyle = "Icons"
            d.sections[1].shape = own
            assert.are.same({ axis = "Columns", perLine = 2, origin = "TopLeft", sort = "ReadyFirst" }, L.LineShape(d, d.sections[1], "Kick"))
            assert.are.equal("BottomRight", own.origin)
        end)

        it("kick bars are one per line", function()
            local L = load()
            local d = L.Defaults()
            assert.is_true(L.Bars(d, "Kick"))
            assert.is_false(L.Bars(d, "Control"))
            local s = L.LineShape(d, d.sections[1], "Kick")
            assert.are.same({ "Rows", 1 }, { s.axis, s.perLine })
            d.kickStyle = "Icons"
            assert.is_false(L.Bars(d, "Kick"))
            assert.are.equal(6, L.LineShape(d, d.sections[1], "Kick").perLine)
        end)

        it("look is the container's own or the panel or member look", function()
            local L = load()
            local d = L.Defaults()
            assert.are.equal(d.panelLook, L.LookOf(d, d.sections[1]))
            assert.are.equal(d.memberLook, L.LookOf(d, d.groups[1], true))
            local mine = { iconSize = 30 }
            d.sections[1].look, d.groups[1].look = mine, mine
            assert.are.equal(mine, L.LookOf(d, d.sections[1]))
            assert.are.equal(mine, L.LookOf(d, d.groups[1], true))
        end)
    end)
end)
