-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("Profiles", function()
    local ns, P, L

    before_each(function()
        ns = helpers.load({ "Logic/LayoutModel.lua", "Logic/Profiles.lua" })
        P, L = ns.Profiles, ns.LayoutModel
    end)

    local function db()
        local d = { layout = L.Defaults(), row = { point = { "CENTER", 0, 0 } } }
        P.Init(d)
        return d
    end

    it("starts every account on Default with its current layout", function()
        local d = db()
        local layout = d.layout
        assert.are.equal("Default", d.profile)
        assert.are.same({ "Default" }, P.Names(d))
        assert.are.equal(layout, d.layout)
    end)

    it("New copies the current layout and switches to it", function()
        local d = db()
        d.layout.sections[1].pos = { x = 5, y = 6 }
        assert.is_true(P.New(d, "Left"))
        assert.are.equal("Left", d.profile)
        assert.are.same({ x = 5, y = 6 }, d.layout.sections[1].pos)
        assert.is_false(P.New(d, "Left"))
        assert.is_false(P.New(d, ""))
        assert.are.same({ "Default", "Left" }, P.Names(d))
    end)

    it("Switch keeps edits made in each profile", function()
        local d = db()
        P.New(d, "Wide")
        d.layout.sections[1].pos = { x = 1, y = 1 }
        d.row.point = { "TOP", 1, 2 }
        assert.is_true(P.Switch(d, "Default"))
        assert.are_not.same({ x = 1, y = 1 }, d.layout.sections[1].pos)
        assert.are.same({ "CENTER", 0, 0 }, d.row.point)
        P.Switch(d, "Wide")
        assert.are.same({ x = 1, y = 1 }, d.layout.sections[1].pos)
        assert.are.same({ "TOP", 1, 2 }, d.row.point)
        assert.is_false(P.Switch(d, "Wide"))
        assert.is_false(P.Switch(d, "Missing"))
    end)

    it("a spec uses its assigned profile, Default otherwise", function()
        local d = db()
        P.New(d, "Wide")
        P.Assign(d, P.Key("Ann-Realm", 65), "Wide")
        assert.are.equal("Wide", P.ForSpec(d, P.Key("Ann-Realm", 65)))
        assert.are.equal("Default", P.ForSpec(d, P.Key("Ann-Realm", 70)))
        P.Assign(d, P.Key("Ann-Realm", 65), "Missing")
        assert.are.equal("Wide", P.ForSpec(d, P.Key("Ann-Realm", 65)))
        P.Assign(d, P.Key("Ann-Realm", 65), nil)
        assert.are.equal("Default", P.ForSpec(d, P.Key("Ann-Realm", 65)))
    end)

    it("Rename moves the profile and its spec assignments; Default keeps its name", function()
        local d = db()
        P.New(d, "Wide")
        P.Assign(d, P.Key("Ann-Realm", 65), "Wide")
        assert.is_true(P.Rename(d, "Wide", "Holy"))
        assert.are.equal("Holy", d.profile)
        assert.are.equal("Holy", P.ForSpec(d, P.Key("Ann-Realm", 65)))
        assert.is_false(P.Rename(d, "Default", "Other"))
        assert.is_false(P.Rename(d, "Holy", "Default"))
    end)

    it("Delete drops assignments and leaves the active profile for Default", function()
        local d = db()
        local defaultLayout = d.layout
        P.New(d, "Wide")
        P.Assign(d, P.Key("Ann-Realm", 65), "Wide")
        assert.is_true(P.Delete(d, "Wide"))
        assert.are.equal("Default", d.profile)
        assert.are.equal(defaultLayout, d.layout)
        assert.are.equal("Default", P.ForSpec(d, P.Key("Ann-Realm", 65)))
        assert.are.same({ "Default" }, P.Names(d))
        assert.is_false(P.Delete(d, "Default"))
    end)

    it("Pack leaves one copy of the active layout for saving, Init after reload finds it again", function()
        local d = db()
        P.New(d, "Wide")
        d.layout.sections[1].pos = { x = 9, y = 9 }
        P.Pack(d)
        assert.is_nil(d.profiles.Wide.layout)
        P.Init(d)
        P.Switch(d, "Default")
        P.Switch(d, "Wide")
        assert.are.same({ x = 9, y = 9 }, d.layout.sections[1].pos)
    end)

    it("an unknown saved profile name falls back to Default", function()
        local d = { layout = L.Defaults(), row = { point = { "CENTER", 0, 0 } }, profile = "Gone", profiles = {} }
        P.Init(d)
        assert.are.equal("Default", d.profile)
    end)
end)
