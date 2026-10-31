local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Docking", function()
    local ns = helpers.load({ "Logic/Docking.lua" })
    local D = ns.Docking
    local anchor = { id = "a", x = 100, y = 100, w = 200, h = 50 }

    local function snap(rect, others)
        local x, y, id, side, offset = D.Snap(rect, others)
        return { x, y, id, side, offset }
    end

    describe("Snap", function()
        it("snaps below with the gap and aligns left edges", function()
            assert.are.same({ 100, 156, "a", "Below", 0 }, snap({ x = 110, y = 160, w = 150, h = 40 }, { anchor }))
        end)

        it("snaps to the right side with the gap", function()
            assert.are.same({ 306, 100, "a", "Right", 0 }, snap({ x = 310, y = 105, w = 80, h = 50 }, { anchor }))
        end)

        it("snaps to the left and above too", function()
            assert.are.same({ 14, 100, "a", "Left", 0 }, snap({ x = 10, y = 103, w = 80, h = 50 }, { anchor }))
            assert.are.same({ 100, 44, "a", "Above", 0 }, snap({ x = 104, y = 40, w = 100, h = 50 }, { anchor }))
        end)

        it("leaves far rects alone and reports no dock", function()
            assert.are.same({ 600, 600 }, snap({ x = 600, y = 600, w = 80, h = 50 }, { anchor }))
        end)

        it("does not snap sideways to a rect far above", function()
            local x = D.Snap({ x = 305, y = 400, w = 80, h = 50 }, { anchor })
            assert.are.equal(305, x)
        end)

        it("snaps to the screen without a dock when the screen has no id", function()
            local x, y, id = D.Snap({ x = 10, y = 12, w = 200, h = 50 }, { { x = 0, y = 0, w = 1000, h = 800 } })
            assert.are.same({ 0, 0 }, { x, y })
            assert.is_nil(id)
        end)

        it("docks to the nearest touching rect, not the first in the list", function()
            local far = { id = "far", x = 100, y = 156, w = 100, h = 10 }
            local near = { id = "near", x = 100, y = 158, w = 100, h = 10 }
            local _, _, id = D.Snap({ x = 100, y = 98, w = 100, h = 50 }, { far, near })
            assert.are.equal("far", id)
            local _, _, id2 = D.Snap({ x = 100, y = 98, w = 100, h = 50 }, { near, far })
            assert.are.equal("far", id2)
        end)

        it("keeps a custom gap and distance", function()
            local x, y = D.Snap({ x = 100, y = 170, w = 50, h = 20 }, { anchor }, 10, 30)
            assert.are.same({ 100, 160 }, { x, y })
        end)
    end)

    describe("SideOf", function()
        local function sideOf(...)
            local side, offset = D.SideOf(...)
            return { side, offset }
        end

        it("reports the side and offset of a docked rect", function()
            assert.are.same({ "Right", 4 }, sideOf({ x = 306, y = 104, w = 80, h = 50 }, anchor))
            assert.are.same({ "Below", 20 }, sideOf({ x = 120, y = 156, w = 100, h = 40 }, anchor))
            assert.are.same({ "Left", 4 }, sideOf({ x = 14, y = 104, w = 80, h = 50 }, anchor))
            assert.are.same({ "Above", 20 }, sideOf({ x = 120, y = 44, w = 100, h = 50 }, anchor))
            assert.is_nil(D.SideOf({ x = 330, y = 100, w = 80, h = 50 }, anchor))
        end)
    end)

    describe("Group", function()
        it("clusters a chain of touching rects and leaves the rest alone", function()
            local panels = { anchor, { x = 100, y = 156, w = 100, h = 40 }, { x = 206, y = 156, w = 80, h = 40 }, { x = 600, y = 600, w = 80, h = 40 } }
            assert.are.same({ { 1, 2, 3 }, { 4 } }, D.Group(panels))
        end)

        it("stops at a gap", function()
            assert.are.same({ { 1 }, { 2 } }, D.Group({ anchor, { x = 100, y = 180, w = 100, h = 40 } }))
        end)
    end)

    describe("Clamp", function()
        local screen = { x = 0, y = 0, w = 1000, h = 800 }

        it("keeps a rect that fits where it is", function()
            assert.are.same({ 10, 20 }, { D.Clamp({ x = 10, y = 20, w = 100, h = 50 }, screen) })
        end)

        it("pulls a rect back from every edge", function()
            assert.are.same({ 900, 750 }, { D.Clamp({ x = 990, y = 790, w = 100, h = 50 }, screen) })
            assert.are.same({ 0, 0 }, { D.Clamp({ x = -30, y = -5, w = 100, h = 50 }, screen) })
        end)

        it("aligns a rect larger than the screen to the top left", function()
            assert.are.same({ 0, 0 }, { D.Clamp({ x = 50, y = 50, w = 1200, h = 900 }, screen) })
        end)

        it("respects a screen that does not start at the origin", function()
            assert.are.same({ -100, 0 }, { D.Clamp({ x = -300, y = 0, w = 50, h = 50 }, { x = -100, y = 0, w = 500, h = 500 }) })
        end)
    end)

    describe("Resolve", function()
        local screen = { x = 0, y = 0, w = 1000, h = 800 }
        local sizes = { panel = { w = 200, h = 50 }, Kick = { w = 80, h = 40 }, Control = { w = 60, h = 30 } }

        it("keeps absolute positions", function()
            local r = D.Resolve({ panel = { x = 100, y = 100 } }, sizes)
            assert.are.same({ x = 100, y = 100, w = 200, h = 50 }, r.panel)
        end)

        it("places docked windows on each side of their target", function()
            local pos = { panel = { x = 100, y = 100 } }
            local cases = {
                { "Right", 4, 306, 104 },
                { "Left", 4, 100 - 6 - 80, 104 },
                { "Below", 10, 110, 156 },
                { "Above", 10, 110, 100 - 6 - 40 },
            }
            for _, c in ipairs(cases) do
                pos.Kick = { x = 0, y = 0, dockTo = "panel", side = c[1], offset = c[2] }
                local r = D.Resolve(pos, sizes)
                assert.are.same({ c[3], c[4] }, { r.Kick.x, r.Kick.y })
            end
        end)

        it("follows the target when it grows or moves", function()
            local pos = { panel = { x = 100, y = 100 }, Kick = { x = 100, y = 156, dockTo = "panel", side = "Below", offset = 0 } }
            local r = D.Resolve(pos, { panel = { w = 200, h = 80 }, Kick = sizes.Kick })
            assert.are.equal(186, r.Kick.y)
            pos.panel.x = 300
            assert.are.equal(300, D.Resolve(pos, sizes).Kick.x)
        end)

        it("resolves a chain regardless of table order", function()
            local pos = {
                panel = { x = 100, y = 100 },
                Kick = { x = 0, y = 0, dockTo = "panel", side = "Below", offset = 0 },
                Control = { x = 0, y = 0, dockTo = "Kick", side = "Below", offset = 0 },
            }
            local r = D.Resolve(pos, sizes)
            assert.are.same({ 100, 202 }, { r.Control.x, r.Control.y })
        end)

        it("falls back to the stored absolute spot when the target is hidden or missing", function()
            local pos = {
                Kick = { x = 500, y = 400, dockTo = "panel", side = "Below", offset = 0 },
                Control = { x = 20, y = 30, dockTo = "gone", side = "Right", offset = 0 },
            }
            local r = D.Resolve(pos, sizes)
            assert.are.same({ 500, 400 }, { r.Kick.x, r.Kick.y })
            assert.are.same({ 20, 30 }, { r.Control.x, r.Control.y })
        end)

        it("terminates on a dock cycle and resolves both windows", function()
            local pos = {
                Kick = { x = 10, y = 10, dockTo = "Control", side = "Right", offset = 0 },
                Control = { x = 300, y = 300, dockTo = "Kick", side = "Right", offset = 0 },
            }
            local r = D.Resolve(pos, sizes)
            assert.is_not_nil(r.Control)
            assert.is_not_nil(r.Kick)
        end)

        it("leaves out windows with no size (not shown)", function()
            local r = D.Resolve({ Kick = { x = 1, y = 2 } }, {})
            assert.is_nil(r.Kick)
        end)

        it("keeps docked windows on screen after a resolution change", function()
            local pos = { panel = { x = 900, y = 700 }, Kick = { x = 0, y = 0, dockTo = "panel", side = "Right", offset = 0 } }
            local small = { x = 0, y = 0, w = 1000, h = 800 }
            local r = D.Resolve(pos, sizes, small)
            assert.are.same({ 800, 700 }, { r.panel.x, r.panel.y })
            assert.is_true(r.Kick.x >= 0 and r.Kick.x + 80 <= 1000)
            assert.is_true(r.Kick.y >= 0 and r.Kick.y + 40 <= 800)
            local tiny = D.Resolve(pos, sizes, { x = 0, y = 0, w = 400, h = 300 })
            for _, id in ipairs({ "panel", "Kick" }) do
                local w = tiny[id]
                assert.is_true(w.x >= 0 and w.x + w.w <= 400 and w.y >= 0 and w.y + w.h <= 300)
            end
        end)
    end)

    describe("FromPoint", function()
        local screen = { x = 0, y = 0, w = 1000, h = 800 }
        local size = { w = 100, h = 40 }

        it("a CENTER point gives the top-left corner, y down", function()
            assert.are.same({ x = 450, y = 580 }, D.FromPoint({ "CENTER", 0, -200 }, size, screen))
        end)

        it("corner and edge points pin that corner or edge", function()
            assert.are.same({ x = 10, y = 20 }, D.FromPoint({ "TOPLEFT", 10, -20 }, size, screen))
            assert.are.same({ x = 890, y = 750 }, D.FromPoint({ "BOTTOMRIGHT", -10, 10 }, size, screen))
            assert.are.same({ x = 0, y = 380 }, D.FromPoint({ "LEFT", 0, 0 }, size, screen))
            assert.are.same({ x = 455, y = 0 }, D.FromPoint({ "TOP", 5, 0 }, size, screen))
        end)

        it("a missing offset counts as zero", function()
            assert.are.same({ x = 450, y = 380 }, D.FromPoint({ "CENTER" }, size, screen))
        end)
    end)

    describe("Near", function()
        it("keeps rects within the snap distance, nearest first", function()
            local rect = { x = 100, y = 100, w = 50, h = 50 }
            local far = { id = "far", x = 400, y = 100, w = 50, h = 50 }
            local close = { id = "close", x = 152, y = 100, w = 50, h = 50 }
            local edge = { id = "edge", x = 100, y = 160, w = 50, h = 50 }
            local ids = {}
            for i, r in ipairs(D.Near(rect, { far, edge, close }, 16)) do ids[i] = r.id end
            assert.are.same({ "close", "edge" }, ids)
        end)
    end)

    describe("Drop", function()
        local rects

        before_each(function()
            rects = {
                panel = { x = 100, y = 100, w = 200, h = 50 },
                Kick = { x = 100, y = 156, w = 100, h = 40 },
                Group = { x = 600, y = 600, w = 80, h = 40 },
            }
        end)

        it("writes x, y and a dock to the touching panel for a moved section", function()
            local out = D.Drop(rects, { Kick = true }, {})
            assert.are.same({ x = 100, y = 156, dockTo = "panel", side = "Below", offset = 0 }, out.Kick)
        end)

        it("writes only x, y when the moved section touches nothing", function()
            local out = D.Drop(rects, { Group = true }, { Group = { x = 1, y = 1, dockTo = "panel", side = "Right", offset = 0 } })
            assert.are.same({ x = 600, y = 600 }, out.Group)
        end)

        it("keeps a dock inside the moved cluster", function()
            rects.panel = { x = 300, y = 300, w = 200, h = 50 }
            rects.Kick = { x = 300, y = 356, w = 100, h = 40 }
            local out = D.Drop(rects, { panel = true, Kick = true }, { Kick = { x = 100, y = 156, dockTo = "panel", side = "Below", offset = 0 } })
            assert.are.same({ x = 300, y = 356, dockTo = "panel", side = "Below", offset = 0 }, out.Kick)
            assert.are.same({ x = 300, y = 300 }, out.panel)
        end)

        it("undocks a panel left behind by an Alt-drag of its target", function()
            rects.panel = { x = 400, y = 100, w = 200, h = 50 }
            local out = D.Drop(rects, { panel = true }, { Kick = { x = 100, y = 156, dockTo = "panel", side = "Below", offset = 0 } })
            assert.are.same({ x = 100, y = 156 }, out.Kick)
        end)

        it("docks a resting section to the main panel dropped flush against it", function()
            local out = D.Drop(rects, { panel = true }, { Kick = { x = 100, y = 156 } })
            assert.are.same({ x = 100, y = 156, dockTo = "panel", side = "Below", offset = 0 }, out.Kick)
            assert.are.same({ x = 100, y = 100 }, out.panel)
        end)

        it("leaves a resting section on its own still-touching dock when the main panel lands beside it", function()
            rects.Group = { x = 100, y = 202, w = 80, h = 40 }
            local positions = { Kick = { x = 100, y = 156, dockTo = "Group", side = "Above", offset = 0 } }
            local out = D.Drop(rects, { panel = true }, positions)
            assert.is_nil(out.Kick)
        end)

        it("never docks a moved panel to one that docks to it, even through a chain", function()
            rects.Group = { x = 206, y = 156, w = 80, h = 40 }
            local positions = {
                Kick = { x = 100, y = 156, dockTo = "panel", side = "Below", offset = 0 },
                Group = { x = 206, y = 156, dockTo = "Kick", side = "Right", offset = 0 },
            }
            local out = D.Drop(rects, { panel = true }, positions)
            assert.is_nil(out.Kick)
            assert.is_nil(out.Group)
            assert.are.same({ x = 100, y = 100 }, out.panel)
        end)
    end)
end)
