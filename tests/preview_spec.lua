local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Preview", function()
    local ns, P, L

    before_each(function()
        ns = helpers.load({ "Logic/LayoutModel.lua", "Logic/Preview.lua" })
        P, L = ns.Preview, ns.LayoutModel
    end)

    local function db()
        local layout = L.Defaults()
        layout.sections[1].pos = { x = 10, y = 20 }
        layout.typeOrder[1], layout.typeOrder[2] = layout.typeOrder[2], layout.typeOrder[1]
        return { layout = layout }
    end

    it("shows a preset without touching the saved layout", function()
        local d = db()
        local saved = d.layout
        local before = db().layout
        P.Show(d, 3)
        assert.are_not.equal(saved, d.layout)
        assert.are.equal(3, d.layout.preset)
        assert.are.equal(3, P.Showing())
        assert.are.equal(saved, P.Saved())
        assert.are.same(before, saved)
    end)

    it("cancel puts the saved layout back exactly", function()
        local d = db()
        local saved = d.layout
        P.Show(d, 1)
        P.Show(d, 4)
        d.layout.timers = false
        assert.is_true(P.Cancel(d))
        assert.are.equal(saved, d.layout)
        assert.are.same({ x = 10, y = 20 }, d.layout.sections[1].pos)
        assert.is_true(d.layout.timers)
        assert.is_nil(P.Showing())
    end)

    it("switching previews starts each from the saved layout", function()
        local d = db()
        P.Show(d, 1)
        d.layout.kickStyle = "Icons"
        P.Show(d, 2)
        assert.are.equal("Bars", d.layout.kickStyle)
        assert.are.equal(2, d.layout.preset)
    end)

    it("apply keeps the preview and ends it", function()
        local d = db()
        P.Show(d, 5)
        local shown = d.layout
        P.Apply()
        assert.are.equal(shown, d.layout)
        assert.is_nil(P.Showing())
        assert.is_false(P.Cancel(d))
        assert.are.equal(shown, d.layout)
    end)

    it("an unknown preset changes nothing", function()
        local d = db()
        local saved = d.layout
        P.Show(d, 9)
        assert.are.equal(saved, d.layout)
        assert.is_nil(P.Showing())
    end)
end)
