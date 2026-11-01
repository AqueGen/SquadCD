-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("LayoutGrid", function()
    local ns = helpers.load({ "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/LayoutGrid.lua" })
    local G = ns.LayoutGrid

    local function shape(axis, perLine, origin, sort)
        return { axis = axis, perLine = perLine, origin = origin or "TopLeft", sort = sort or "Fixed" }
    end

    local function uniform(n, w, h)
        local out = {}
        for i = 1, n do out[i] = { w = w, h = h or w } end
        return out
    end

    local function flat(rects)
        local out = {}
        for _, c in ipairs(rects) do
            out[#out + 1] = c.x
            out[#out + 1] = c.y
        end
        return out
    end

    describe("Place", function()
        local cases = {
            { "Rows", 3, "TopLeft", 34, 10, { 0, 0, 12, 0, 24, 0 } },
            { "Rows", 3, "TopRight", 34, 10, { 24, 0, 12, 0, 0, 0 } },
            { "Rows", 3, "BottomLeft", 34, 10, { 0, 0, 12, 0, 24, 0 } },
            { "Rows", 3, "BottomRight", 34, 10, { 24, 0, 12, 0, 0, 0 } },
            { "Rows", 2, "TopLeft", 22, 22, { 0, 0, 12, 0, 0, 12 } },
            { "Rows", 2, "TopRight", 22, 22, { 12, 0, 0, 0, 12, 12 } },
            { "Rows", 2, "BottomLeft", 22, 22, { 0, 12, 12, 12, 0, 0 } },
            { "Rows", 2, "BottomRight", 22, 22, { 12, 12, 0, 12, 12, 0 } },
            { "Columns", 3, "TopLeft", 10, 34, { 0, 0, 0, 12, 0, 24 } },
            { "Columns", 3, "TopRight", 10, 34, { 0, 0, 0, 12, 0, 24 } },
            { "Columns", 3, "BottomLeft", 10, 34, { 0, 24, 0, 12, 0, 0 } },
            { "Columns", 3, "BottomRight", 10, 34, { 0, 24, 0, 12, 0, 0 } },
            { "Columns", 2, "TopLeft", 22, 22, { 0, 0, 0, 12, 12, 0 } },
            { "Columns", 2, "TopRight", 22, 22, { 12, 0, 12, 12, 0, 0 } },
            { "Columns", 2, "BottomLeft", 22, 22, { 0, 12, 0, 0, 12, 12 } },
            { "Columns", 2, "BottomRight", 22, 22, { 12, 12, 12, 0, 0, 12 } },
        }
        for _, c in ipairs(cases) do
            local axis, per, origin, w, h, expected = unpack(c)
            it(axis .. " " .. per .. " from " .. origin, function()
                local rects, gw, gh = G.Place(uniform(3, 10), shape(axis, per, origin), 2)
                assert.are.same(expected, flat(rects))
                assert.are.same({ w, h }, { gw, gh })
            end)
        end

        it("a short last row aligns to the origin edge", function()
            local rects, w, h = G.Place(uniform(3, 10), shape("Rows", 2, "TopRight"), 2)
            assert.are.same({ 12, 0, 0, 0, 12, 12 }, flat(rects))
            assert.are.same({ 22, 22 }, { w, h })
        end)

        it("a short last column aligns to the origin edge", function()
            local rects, w, h = G.Place(uniform(3, 10), shape("Columns", 2, "BottomRight"), 2)
            assert.are.same({ 12, 12, 12, 0, 0, 12 }, flat(rects))
            assert.are.same({ 22, 22 }, { w, h })
        end)

        it("per line clamps to 1..12", function()
            assert.are.same({ 0, 0, 0, 12, 0, 24 }, flat((G.Place(uniform(3, 10), shape("Rows", 0), 2))))
            local rects, w = G.Place(uniform(13, 10), shape("Rows", 20), 2)
            assert.are.same({ x = 0, y = 12, w = 10, h = 10 }, rects[13])
            assert.are.equal(12 * 10 + 11 * 2, w)
        end)

        it("no cells take no space", function()
            local rects, w, h = G.Place({}, shape("Rows", 4), 2)
            assert.are.same({}, rects)
            assert.are.same({ 0, 0 }, { w, h })
        end)

        it("mixed cell sizes: a line is as thick as its thickest cell", function()
            local cells = { { w = 10, h = 10 }, { w = 30, h = 20 }, { w = 10, h = 10 } }
            local rects, w, h = G.Place(cells, shape("Rows", 2), 2)
            assert.are.same({ 0, 0, 12, 0, 0, 22 }, flat(rects))
            assert.are.same({ x = 12, y = 0, w = 30, h = 20 }, rects[2])
            assert.are.same({ 42, 32 }, { w, h })
        end)

        it("mixed cell sizes from the bottom right keep each cell's own size", function()
            local cells = { { w = 10, h = 10 }, { w = 30, h = 20 }, { w = 10, h = 10 } }
            local rects = G.Place(cells, shape("Rows", 2, "BottomRight"), 2)
            assert.are.same({ x = 32, y = 22, w = 10, h = 10 }, rects[1])
            assert.are.same({ x = 0, y = 12, w = 30, h = 20 }, rects[2])
            assert.are.same({ x = 32, y = 0, w = 10, h = 10 }, rects[3])
        end)

        it("kick bars stack one per line", function()
            local rects, w, h = G.Place(uniform(3, 152, 20), shape("Rows", 1), 2)
            assert.are.same({ 0, 0, 0, 22, 0, 44 }, flat(rects))
            assert.are.same({ 152, 64 }, { w, h })
        end)
    end)

    describe("PlaceSections", function()
        it("one section per line whatever the per line count", function()
            local sections = { { w = 50, h = 20 }, { w = 30, h = 40 } }
            local rows, w, h = G.PlaceSections(sections, shape("Rows", 6), 6)
            assert.are.same({ 0, 0, 0, 26 }, flat(rows))
            assert.are.same({ 50, 66 }, { w, h })
            local cols, cw, ch = G.PlaceSections(sections, shape("Columns", 6, "TopRight"), 6)
            assert.are.same({ 36, 0, 0, 0 }, flat(cols))
            assert.are.same({ 86, 40 }, { cw, ch })
        end)
    end)

    describe("MemberOrigin", function()
        local cases = {
            { "TopLeft", "Left", "TopRight" }, { "BottomLeft", "Left", "BottomRight" },
            { "TopRight", "Right", "TopLeft" }, { "BottomRight", "Right", "BottomLeft" },
            { "TopLeft", "Above", "BottomLeft" }, { "TopRight", "Above", "BottomRight" },
            { "BottomLeft", "Below", "TopLeft" }, { "BottomRight", "Below", "TopRight" },
        }
        for _, c in ipairs(cases) do
            it(c[1] .. " on the " .. c[2] .. " grows from " .. c[3], function()
                assert.are.equal(c[3], G.MemberOrigin(c[1], c[2]))
            end)
        end
    end)

    describe("PlaceMemberRow", function()
        it("beside a frame, lines past its height start a new block further out", function()
            local rects, w, h = G.PlaceMemberRow(uniform(6, 10), shape("Rows", 2), "Left", 25, 2)
            assert.are.same({ 50, 22 }, { w, h })
            assert.are.same({ x = 40, y = 0, w = 10, h = 10 }, rects[1])
            assert.are.same({ x = 40, y = 12, w = 10, h = 10 }, rects[3])
            assert.are.same({ x = 12, y = 0, w = 10, h = 10 }, rects[5])
        end)

        it("above or below a frame there is no height limit", function()
            local _, w, h = G.PlaceMemberRow(uniform(6, 10), shape("Rows", 2), "Below", 25, 2)
            assert.are.same({ 22, 34 }, { w, h })
        end)

        it("no frame height means no limit", function()
            local _, w, h = G.PlaceMemberRow(uniform(6, 10), shape("Rows", 2), "Right", 0, 2)
            assert.are.same({ 22, 34 }, { w, h })
        end)
    end)

    describe("FitShape", function()
        it("beside a frame, per line is the count over the lines that fit its height", function()
            local fit = G.FitShape(shape("Rows", 12), "Left", 7, 10, 10, 0, 100, 40, 2)
            assert.are.equal(3, fit.perLine)
        end)

        it("above or below, lines are balanced over the frame width minus the lead", function()
            assert.are.equal(7, G.FitShape(shape("Rows", 3), "Below", 7, 10, 10, 13, 100, 40, 2).perLine)
            assert.are.equal(5, G.FitShape(shape("Rows", 3), "Above", 9, 10, 10, 13, 100, 40, 2).perLine)
        end)

        it("clamps to 12 and leaves the input alone", function()
            local s = shape("Rows", 3)
            assert.are.equal(12, G.FitShape(s, "Right", 30, 10, 10, 0, 100, 10, 2).perLine)
            assert.are.equal(3, s.perLine)
        end)

        it("columns, no frame or no icons keep the shape", function()
            local s = shape("Columns", 3)
            assert.are.equal(s, G.FitShape(s, "Left", 7, 10, 10, 0, 100, 40, 2))
            local r = shape("Rows", 3)
            assert.are.equal(r, G.FitShape(r, "Left", 7, 10, 10, 0, 100, 0, 2))
            assert.are.equal(r, G.FitShape(r, "Below", 7, 10, 10, 0, 0, 40, 2))
            assert.are.equal(r, G.FitShape(r, "Left", 0, 10, 10, 0, 100, 40, 2))
        end)
    end)

    describe("Tabs", function()
        it("a tab opens every type run and every line", function()
            assert.are.same({ true, false, true, true, true }, G.Tabs({ 3, 2 }, 2))
            assert.are.same({ true, false, false, true }, G.Tabs({ 3, 1 }, 6))
            assert.are.same({}, G.Tabs({}, 3))
        end)
    end)

    describe("MemberAnchor", function()
        it("pins the group corner at the frame on its side", function()
            assert.are.same({ "TOPRIGHT", "TOPLEFT", -4, 0 }, { G.MemberAnchor("Left", "TopRight", 4, 0) })
            assert.are.same({ "BOTTOMLEFT", "BOTTOMRIGHT", 8, 3 }, { G.MemberAnchor("Right", "BottomLeft", 8, 3) })
            assert.are.same({ "BOTTOMRIGHT", "TOPRIGHT", 5, 4 }, { G.MemberAnchor("Above", "BottomRight", 4, 5) })
            assert.are.same({ "TOPLEFT", "BOTTOMLEFT", 2, -4 }, { G.MemberAnchor("Below", "TopLeft", 4, 2) })
        end)
    end)

    describe("Line", function()
        local tab, entries = { w = 11, h = 26 }, { w = 80, h = 38 }

        it("rows: tab on the left, stretched to the line", function()
            local w, h, t, e = G.Line(tab, entries, false, false, false)
            assert.are.same({ 97, 38 }, { w, h })
            assert.are.same({ x = 0, y = 0, w = 11, h = 38 }, t)
            assert.are.same({ x = 17, y = 0, w = 80, h = 38 }, e)
        end)

        it("rows from the right: tab on the right", function()
            local _, _, t, e = G.Line(tab, entries, false, true, false)
            assert.are.same({ x = 86, y = 0, w = 11, h = 38 }, t)
            assert.are.equal(0, e.x)
        end)

        it("rows from the bottom: short entries sit at the bottom", function()
            local w, h, t, e = G.Line({ w = 11, h = 40 }, { w = 80, h = 20 }, false, false, true)
            assert.are.same({ 97, 40 }, { w, h })
            assert.are.equal(40, t.h)
            assert.are.equal(20, e.y)
        end)

        it("columns: tab on top across the line", function()
            local w, h, t, e = G.Line({ w = 30, h = 11 }, entries, true, false, false)
            assert.are.same({ 80, 53 }, { w, h })
            assert.are.same({ x = 0, y = 0, w = 80, h = 11 }, t)
            assert.are.same({ x = 0, y = 15, w = 80, h = 38 }, e)
        end)

        it("columns from the bottom right: tab under, entries right", function()
            local w, h, t, e = G.Line({ w = 100, h = 11 }, entries, true, true, true)
            assert.are.same({ 100, 53 }, { w, h })
            assert.are.equal(42, t.y)
            assert.are.same({ x = 20, y = 0, w = 80, h = 38 }, e)
        end)

        it("no tab: the line is the entries", function()
            local w, h, t, e = G.Line(nil, entries, false, false, false)
            assert.are.same({ 80, 38 }, { w, h })
            assert.is_nil(t)
            assert.are.same({ x = 0, y = 0, w = 80, h = 38 }, e)
        end)
    end)

    describe("RoleOf", function()
        it("tank and healer by spec role, damage split by ranged", function()
            assert.are.equal("Tank", G.RoleOf(73))
            assert.are.equal("Healer", G.RoleOf(105))
            assert.are.equal("Melee", G.RoleOf(71))
            assert.are.equal("Ranged", G.RoleOf(62))
            assert.are.equal("Ranged", G.RoleOf(258))
            assert.is_nil(G.RoleOf(0))
        end)

        it("every catalog spec has a role", function()
            for id in pairs(ns.Specs) do
                assert.is_not_nil(G.RoleOf(id))
            end
        end)
    end)

    describe("Sort", function()
        local ROLES = { "Tank", "Melee", "Ranged", "Healer" }

        local function keys(list)
            local out = {}
            for _, s in ipairs(list) do out[#out + 1] = s.key end
            return out
        end

        it("fixed orders by role priority then input order", function()
            local states = {
                { key = "heal", role = "Healer" }, { key = "rng", role = "Ranged" },
                { key = "tank", role = "Tank" }, { key = "mel", role = "Melee" }, { key = "rng2", role = "Ranged" },
            }
            assert.are.same({ "tank", "mel", "rng", "rng2", "heal" }, keys(G.Sort(states, shape("Rows", 6), ROLES)))
        end)

        it("fixed follows a changed role priority", function()
            local states = { { key = "tank", role = "Tank" }, { key = "heal", role = "Healer" } }
            assert.are.same({ "heal", "tank" }, keys(G.Sort(states, shape("Rows", 6), { "Healer", "Tank", "Melee", "Ranged" })))
        end)

        it("fixed ignores cooldown state", function()
            local states = { { key = "a", role = "Tank", ready = false }, { key = "b", role = "Tank", ready = true } }
            assert.are.same({ "a", "b" }, keys(G.Sort(states, shape("Rows", 6), ROLES)))
        end)

        it("ready first puts ready members before cooling ones", function()
            local states = {
                { key = "a", role = "Tank", ready = false, remaining = 30 },
                { key = "b", role = "Healer", ready = true, remaining = 0 },
                { key = "c", role = "Melee", ready = false, remaining = 10 },
                { key = "d", role = "Tank", ready = true, remaining = 0 },
            }
            assert.are.same({ "d", "b", "c", "a" }, keys(G.Sort(states, shape("Rows", 6, "TopLeft", "ReadyFirst"), ROLES)))
        end)

        it("ready first puts certain before unknown before maybe, dead last", function()
            local states = {
                { key = "dead", ready = true, remaining = 0, dead = true },
                { key = "maybe", ready = false, remaining = 5, maybe = true },
                { key = "sure", ready = false, remaining = 60 },
                { key = "unknown", ready = true, remaining = 0, unknown = true },
                { key = "ready", ready = true, remaining = 0 },
            }
            assert.are.same({ "ready", "unknown", "sure", "maybe", "dead" },
                keys(G.Sort(states, shape("Rows", 6, "TopLeft", "ReadyFirst"))))
        end)

        it("ready first breaks ties by role priority", function()
            local states = {
                { key = "heal", role = "Healer", ready = true, remaining = 0 },
                { key = "tank", role = "Tank", ready = true, remaining = 0 },
                { key = "heal9", role = "Healer", ready = false, remaining = 9 },
                { key = "tank9", role = "Tank", ready = false, remaining = 9 },
            }
            assert.are.same({ "tank", "heal", "tank9", "heal9" }, keys(G.Sort(states, shape("Rows", 6, "TopLeft", "ReadyFirst"), ROLES)))
        end)

        it("fixed orders a role by its class order, unlisted classes last", function()
            local states = {
                { key = "war", role = "Melee", classId = 1 }, { key = "rog", role = "Melee", classId = 4 },
                { key = "none", role = "Melee" }, { key = "tank", role = "Tank", classId = 1 },
            }
            local classes = { Melee = { 4, 1 }, Tank = {} }
            assert.are.same({ "tank", "rog", "war", "none" }, keys(G.Sort(states, shape("Rows", 6), ROLES, nil, classes)))
        end)

        it("without a class order classes keep input order", function()
            local states = { { key = "war", role = "Melee", classId = 1 }, { key = "rog", role = "Melee", classId = 4 } }
            assert.are.same({ "war", "rog" }, keys(G.Sort(states, shape("Rows", 6), ROLES)))
        end)

        it("ready first breaks ties by class order after role", function()
            local states = {
                { key = "war", role = "Melee", classId = 1, ready = true, remaining = 0 },
                { key = "rog", role = "Melee", classId = 4, ready = true, remaining = 0 },
            }
            assert.are.same({ "rog", "war" },
                keys(G.Sort(states, shape("Rows", 6, "TopLeft", "ReadyFirst"), ROLES, nil, { Melee = { 4, 1 } })))
        end)

        it("refills a given table and leaves the input alone", function()
            local a, b = { key = "a", ready = false, remaining = 5 }, { key = "b", ready = true, remaining = 0 }
            local out = { "stale", "stale", "stale" }
            assert.are.equal(out, G.Sort({ a, b }, shape("Rows", 6, "TopLeft", "ReadyFirst"), nil, out))
            assert.are.same({ b, a }, out)
            local input = { a, b }
            G.Sort(input, shape("Rows", 6, "TopLeft", "ReadyFirst"))
            assert.are.same({ a, b }, input)
        end)
    end)

    describe("Next", function()
        local ROLES = { "Tank", "Melee", "Ranged", "Healer" }

        it("picks the first ready member by role priority", function()
            local states = {
                { role = "Healer", ready = true }, { role = "Ranged", ready = true },
                { role = "Tank", ready = false }, { role = "Melee", ready = true },
            }
            assert.are.equal(4, G.Next(states, ROLES))
        end)

        it("ties go to the earlier member", function()
            local states = { { role = "Ranged", ready = true }, { role = "Ranged", ready = true } }
            assert.are.equal(1, G.Next(states, ROLES))
        end)

        it("skips cooling and dead members", function()
            local states = { { role = "Tank", ready = true, dead = true }, { role = "Healer", ready = true } }
            assert.are.equal(2, G.Next(states, ROLES))
        end)

        it("skips members whose state is unknown", function()
            local states = { { role = "Tank", ready = true, unknown = true }, { role = "Healer", ready = true } }
            assert.are.equal(2, G.Next(states, ROLES))
        end)

        it("nobody ready gives nil", function()
            assert.is_nil(G.Next({ { role = "Tank", ready = false } }, ROLES))
            assert.is_nil(G.Next({}, ROLES))
        end)

        it("a member with an unknown role comes after every known role", function()
            local states = { { ready = true }, { role = "Healer", ready = true } }
            assert.are.equal(2, G.Next(states, ROLES))
        end)

        it("inside a role the class order decides", function()
            local states = { { role = "Melee", classId = 1, ready = true }, { role = "Melee", classId = 4, ready = true } }
            assert.are.equal(2, G.Next(states, ROLES, { Melee = { 4, 1 } }))
            assert.are.equal(1, G.Next(states, ROLES))
        end)

        it("a kick queue by name goes before role and class; names not in it follow", function()
            local states = {
                { role = "Tank", name = "Ann", ready = true },
                { role = "Healer", name = "Bo", ready = true },
                { role = "Melee", name = "Cy", ready = true },
            }
            assert.are.equal(2, G.Next(states, ROLES, nil, { "Bo", "Cy" }))
            states[2].ready = false
            assert.are.equal(3, G.Next(states, ROLES, nil, { "Bo", "Cy" }))
            local sorted = G.Sort(states, { sort = "Fixed" }, ROLES, nil, nil, { "Cy" })
            assert.are.same({ "Cy", "Ann", "Bo" }, { sorted[1].name, sorted[2].name, sorted[3].name })
        end)

        it("all cooling only when every live member's kick is on cooldown", function()
            assert.is_true(G.AllCooling({ { ready = false }, { ready = false } }))
            assert.is_false(G.AllCooling({ { ready = false }, { ready = true } }))
            assert.is_false(G.AllCooling({ { ready = false }, { ready = false, dead = true } }))
            assert.is_false(G.AllCooling({}))
        end)

        it("kick lines put the shorter cooldown before role and class, after the queue", function()
            local states = {
                { role = "Tank", name = "Ann", cd = 15, ready = true },
                { role = "Melee", name = "Bo", cd = 15, ready = true },
                { role = "Ranged", name = "Cy", cd = 12, ready = true },
            }
            assert.are.equal(3, G.Next(states, ROLES, nil, {}))
            assert.are.equal(2, G.Next(states, ROLES, nil, { "Bo" }))
            assert.are.equal(1, G.Next(states, ROLES))
        end)
    end)

    describe("ClassesIn", function()
        it("lists the classes with a spec in the role, in the given order", function()
            local order = { 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }
            assert.are.same({ 12, 11, 10, 6, 2, 1 }, G.ClassesIn(order, "Tank"))
            assert.are.same({ 13, 11, 10, 7, 5, 2 }, G.ClassesIn(order, "Healer"))
        end)
    end)

    describe("ClassId", function()
        it("maps a class token to the game's class id", function()
            assert.are.equal(4, G.ClassId("ROGUE"))
            assert.are.equal(13, G.ClassId("EVOKER"))
            assert.is_nil(G.ClassId("NOPE"))
            assert.is_nil(G.ClassId(nil))
        end)
    end)

    describe("MemberStack", function()
        local groups = {
            { side = "Right", w = 50, h = 30, offsetX = 4, offsetY = 0 },
            { side = "Below", w = 80, h = 20, offsetX = 4, offsetY = 4 },
            { side = "Right", w = 60, h = 30, offsetX = 4, offsetY = 0 },
            { side = "Below", w = 70, h = 10, offsetX = 4, offsetY = 6 },
        }

        it("groups on one side stack outward, other sides are ignored", function()
            local right = G.MemberStack(groups, "Right")
            assert.are.same({ 4, nil, 58 }, { right[1], right[2], right[3] })
            assert.is_nil(right[4])
        end)

        it("below counts height and offsetY", function()
            local below = G.MemberStack(groups, "Below")
            assert.are.same({ 4, 30 }, { below[2], below[4] })
        end)

        it("a later offset counts from the far edge of earlier groups", function()
            local list = {
                { side = "Left", w = 50, h = 30, offsetX = 20, offsetY = 0 },
                { side = "Left", w = 50, h = 30, offsetX = 4, offsetY = 0 },
                { side = "Left", w = 50, h = 30, offsetX = -10, offsetY = 0 },
            }
            assert.are.same({ 20, 74, 114 }, G.MemberStack(list, "Left"))
        end)
    end)

    describe("Surplus", function()
        it("lists every index above keep in a sparse table, in order", function()
            assert.are.same({ 3, 5 }, G.Surplus({ [5] = {}, [1] = {}, [3] = {} }, 2))
            assert.are.same({ 1, 2 }, G.Surplus({ [2] = {}, [1] = {} }, 0))
            assert.are.same({}, G.Surplus({ [1] = {} }, 1))
        end)
    end)

    describe("ByMember", function()
        it("groups entries by member keeping first-seen order", function()
            local a, b = { guid = "A" }, { guid = "B" }
            local e1, e2, e3 = { member = a, n = 1 }, { member = b, n = 2 }, { member = a, n = 3 }
            local out = G.ByMember({ e1, e2, e3 })
            assert.are.same(2, #out)
            assert.are.same({ e1, e3 }, out[1])
            assert.are.same({ e2 }, out[2])
        end)
    end)

    describe("Best", function()
        it("prefers ready, then lowest remaining, then lowest cooldown, then first", function()
            assert.are.equal(2, G.Best({ { ready = false, remaining = 5 }, { ready = true, remaining = 0 } }, { 15, 15 }))
            assert.are.equal(2, G.Best({ { ready = false, remaining = 5 }, { ready = false, remaining = 2 } }, { 15, 15 }))
            assert.are.equal(2, G.Best({ { ready = true, remaining = 0 }, { ready = true, remaining = 0 } }, { 45, 15 }))
            assert.are.equal(1, G.Best({ { ready = true, remaining = 0 }, { ready = true, remaining = 0 } }, { 15, 15 }))
            assert.are.equal(1, G.Best({ { ready = true, remaining = 0 } }, { 15 }))
        end)
    end)
end)
