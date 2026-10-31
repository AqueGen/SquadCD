-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local SECRET = setmetatable({}, { __tostring = function() return "secret" end })

local function node(opts)
    local f = { kids = {}, opts = opts or {} }
    function f:GetChildren() return unpack(self.kids) end
    function f:GetParent() return self.parent end
    function f:IsForbidden() return false end
    function f:IsVisible() return self.opts.visible == nil and true or self.opts.visible end
    function f:IsObjectType(kind) return kind == (self.opts.kind or "Frame") end
    function f:GetAttribute(key) return key == "unit" and self.opts.unit or nil end
    return f
end

local function add(parent, child)
    parent.kids[#parent.kids + 1] = child
    child.parent = parent
    return child
end

describe("Anchors", function()
    local ns, root

    before_each(function()
        root = node()
        ns = helpers.load({ "UI/Anchors.lua" }, {
            UIParent = root,
            issecretvalue = function(v) return v == SECRET end,
        })
        ns.Theme = { MakeMovable = function() end }
    end)

    it("skips a subtree whose visibility is secret", function()
        local auras = add(root, node({ visible = SECRET }))
        add(auras, node({ kind = "Button", unit = "party1" }))
        local header = add(root, node())
        local party2 = add(header, node({ kind = "Button", unit = "party2" }))

        ns.Anchors.Scan()

        assert.are.equal(party2, (ns.Anchors.FrameFor("party2")))
        local _, stacked = ns.Anchors.FrameFor("party1")
        assert.is_true(stacked)
    end)

    it("ignores a button whose unit attribute is secret", function()
        local header = add(root, node())
        add(header, node({ kind = "Button", unit = SECRET }))

        assert.has_no.errors(function() ns.Anchors.Scan() end)
    end)
end)
