local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("LayoutGrid", function()
    local ns = helpers.load({ "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/LayoutGrid.lua" })
    local G = ns.LayoutGrid

    local function shape(axis, perLine, origin, sort)
        return { axis = axis, perLine = perLine, origin = origin or "TopLeft", sort = sort or "Fixed" }
    end

    local function flat(cells)
        local out = {}
        for _, c in ipairs(cells) do out[#out + 1] = c.x out[#out + 1] = c.y end
        return out
    end

    describe("Cells", function()
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
                local cells, gw, gh = G.Cells(3, shape(axis, per, origin), 10, 2)
                assert.are.same(expected, flat(cells))
                assert.are.same({ w, h }, { gw, gh })
            end)
        end

        it("a short last line aligns to the origin edge", function()
            local cells, w, h = G.Cells(3, shape("Rows", 2, "TopRight"), 10, 2)
            assert.are.same({ 12, 0, 0, 0, 12, 12 }, flat(cells))
            assert.are.same({ 22, 22 }, { w, h })
        end)

        it("per line clamps to 1..12", function()
            assert.are.same({ 0, 0, 0, 12, 0, 24 }, flat((G.Cells(3, shape("Rows", 0), 10, 2))))
            local cells, w = G.Cells(13, shape("Rows", 20), 10, 2)
            assert.are.same({ x = 0, y = 12 }, cells[13])
            assert.are.equal(12 * 10 + 11 * 2, w)
        end)

        it("no cells take no space", function()
            local cells, w, h = G.Cells(0, shape("Rows", 4), 10, 2)
            assert.are.same({}, cells)
            assert.are.same({ 0, 0 }, { w, h })
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

        it("nobody ready gives nil", function()
            assert.is_nil(G.Next({ { role = "Tank", ready = false } }, ROLES))
            assert.is_nil(G.Next({}, ROLES))
        end)

        it("a member with an unknown role comes after every known role", function()
            local states = { { ready = true }, { role = "Healer", ready = true } }
            assert.are.equal(2, G.Next(states, ROLES))
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
end)
