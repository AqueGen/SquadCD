local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("MemberEdit", function()
    local ns, E, L, layout

    before_each(function()
        ns = helpers.load({ "Logic/LayoutModel.lua", "Logic/MemberEdit.lua" })
        E, L = ns.MemberEdit, ns.LayoutModel
        layout = L.Defaults()
    end)

    describe("ToggleType", function()
        it("moves a panel type into the group and drops its emptied section", function()
            E.ToggleType(layout, 1, "Kick")
            assert.are.same({ "member", 1 }, { L.PlaceOf(layout, "Kick") })
            for _, s in ipairs(layout.sections) do assert.are_not.equal("Kick", s.id) end
        end)

        it("turns a type in the group off", function()
            E.ToggleType(layout, 1, "Burst")
            assert.are.equal("off", L.PlaceOf(layout, "Burst"))
            assert.are.same({ "Personal", "Racial", "Potion" }, layout.groups[1].types)
        end)

        it("moves a type from another group", function()
            E.AddGroup(layout)
            E.ToggleType(layout, 2, "Racial")
            assert.are.same({ "member", 2 }, { L.PlaceOf(layout, "Racial") })
            assert.are.same({ "Personal", "Burst", "Potion" }, layout.groups[1].types)
        end)

        it("ignores a group that does not exist", function()
            E.ToggleType(layout, 5, "Kick")
            assert.are.same({ "panel", 1 }, { L.PlaceOf(layout, "Kick") })
        end)
    end)

    it("sets side and axis", function()
        E.SetSide(layout, 1, "Below")
        E.SetAxis(layout, 1, "Columns")
        assert.are.equal("Below", layout.groups[1].side)
        assert.are.equal("Columns", layout.groups[1].shape.axis)
    end)

    it("clamps per line to 1..12", function()
        E.SetPerLine(layout, 1, 20)
        assert.are.equal(12, layout.groups[1].shape.perLine)
        E.SetPerLine(layout, 1, 0)
        assert.are.equal(1, layout.groups[1].shape.perLine)
    end)

    describe("NextCorner", function()
        local function next(side, origin)
            return E.NextCorner({ side = side, shape = { origin = origin } })
        end

        it("flips top and bottom beside the frame", function()
            assert.are.equal("BottomLeft", next("Left", "TopLeft"))
            assert.are.equal("TopLeft", next("Left", "BottomLeft"))
            assert.are.equal("BottomRight", next("Right", "TopRight"))
        end)

        it("flips left and right above or below the frame", function()
            assert.are.equal("TopRight", next("Above", "TopLeft"))
            assert.are.equal("TopLeft", next("Below", "TopRight"))
            assert.are.equal("BottomRight", next("Below", "BottomLeft"))
        end)
    end)

    describe("SetLook", function()
        it("starts from the member look and keeps the shared one", function()
            E.SetLook(layout, 1, "background", "Slate")
            assert.are.equal("Slate", layout.groups[1].look.background)
            assert.are.equal(layout.memberLook.iconSize, layout.groups[1].look.iconSize)
            assert.are.equal("None", layout.memberLook.background)
        end)

        it("clamps icon size to 12..40", function()
            E.SetLook(layout, 1, "iconSize", 50)
            assert.are.equal(40, layout.groups[1].look.iconSize)
            E.SetLook(layout, 1, "iconSize", 3)
            assert.are.equal(12, layout.groups[1].look.iconSize)
        end)
    end)

    describe("MoveBy", function()
        local function moved(side, dx, dy)
            layout.groups[1].side = side
            layout.groups[1].offsetX, layout.groups[1].offsetY = 10, 10
            E.MoveBy(layout, 1, dx, dy)
            return { layout.groups[1].offsetX, layout.groups[1].offsetY }
        end

        it("maps screen moves (y down) to offsets per side", function()
            assert.are.same({ 11, 8 }, moved("Right", 1, 2))
            assert.are.same({ 9, 8 }, moved("Left", 1, 2))
            assert.are.same({ 11, 8 }, moved("Above", 1, 2))
            assert.are.same({ 11, 12 }, moved("Below", 1, 2))
        end)

        it("clamps to 400", function()
            assert.are.same({ 400, -400 }, moved("Right", 1000, 1000))
        end)
    end)

    describe("groups", function()
        it("resets the first group offset to the default", function()
            layout.groups[1].offsetX, layout.groups[1].offsetY = 50, -30
            E.ResetOffset(layout, 1)
            assert.are.same({ 4, 0 }, { layout.groups[1].offsetX, layout.groups[1].offsetY })
        end)

        it("resets a stacked group to the stack gap", function()
            layout.groups[1].side, layout.groups[1].offsetY = "Right", 7
            E.AddGroup(layout)
            layout.groups[2].offsetX, layout.groups[2].offsetY = 90, 90
            E.ResetOffset(layout, 2)
            assert.are.same({ 6, 7 }, { layout.groups[2].offsetX, layout.groups[2].offsetY })
        end)

        it("adds an empty Right group stacked on an earlier Right group", function()
            layout.groups[1].side, layout.groups[1].offsetX, layout.groups[1].offsetY = "Right", 12, 3
            assert.are.equal(2, E.AddGroup(layout))
            local g = layout.groups[2]
            assert.are.same({}, g.types)
            assert.are.equal("Right", g.side)
            assert.are.same({ axis = "Rows", perLine = 3, origin = "TopLeft", sort = "Fixed" }, g.shape)
            assert.are.same({ 6, 3 }, { g.offsetX, g.offsetY })
        end)

        it("adds a group with the first group's offset on a new side", function()
            layout.groups[1].offsetX, layout.groups[1].offsetY = 12, 3
            E.AddGroup(layout)
            assert.are.same({ 12, 3 }, { layout.groups[2].offsetX, layout.groups[2].offsetY })
        end)

        it("removes a group and hands its types to the first", function()
            E.AddGroup(layout)
            E.ToggleType(layout, 2, "Kick")
            E.RemoveGroup(layout, 2)
            assert.are.equal(1, #layout.groups)
            assert.are.same({ "Personal", "Burst", "Racial", "Potion", "Kick" }, layout.groups[1].types)
        end)

        it("never removes the last group", function()
            E.RemoveGroup(layout, 1)
            assert.are.equal(1, #layout.groups)
        end)
    end)

    it("keeps a layout that Normalize leaves unchanged", function()
        E.AddGroup(layout)
        E.ToggleType(layout, 2, "Dispel")
        E.SetLook(layout, 2, "labels", "Short")
        local before = L.Normalize(layout)
        assert.are.equal("Short", before.groups[2].look.labels)
        assert.are.same({ "Dispel" }, before.groups[2].types)
    end)
end)
