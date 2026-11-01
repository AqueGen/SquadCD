-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local function stub(kind, made)
    local o = { kind = kind, calls = {}, log = {} }
    made[#made + 1] = o
    return setmetatable(o, { __index = function(_, k)
        return function(self, ...)
            self.calls[k] = { ... }
            self.log[#self.log + 1] = { k, ... }
            if k == "CreateTexture" or k == "CreateFontString" or k == "CreateAnimationGroup" or k == "CreateAnimation" then
                return stub(k, made)
            end
            if k == "GetFrameLevel" then return 1 end
        end
    end })
end

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "UI/Theme.lua", "UI/ActiveOverlay.lua" }

describe("ActiveOverlay", function()
    local ns, made, overlay, parent

    before_each(function()
        made = {}
        ns = helpers.load(FILES, { CreateFrame = function(kind) return stub(kind, made) end })
        parent = stub("Frame", made)
        overlay = ns.ActiveOverlay.New(parent, 5)
        overlay:SetLook("tex", 30)
    end)

    local function containers()
        local out = {}
        for _, o in ipairs(made) do
            if o.kind == "AuraContainer" then out[#out + 1] = o end
        end
        return out
    end

    local function button()
        overlay:Watch({ { unit = "party1", ids = { 48707, 410358 } } })
        local _, _, options = unpack(containers()[1].calls.AddAuraGroup)
        local b = stub("Button", made)
        options.initializeFrame(b)
        return b, options
    end

    it("watches the buff ids on each unit through the engine aura display", function()
        local _, options = button()
        local c = containers()
        assert.equal(1, #c)
        assert.same({ "party1" }, c[1].calls.SetUnit)
        assert.same({ [48707] = true, [410358] = true }, options.candidateFilters.includeSpellIDs)
        assert.same({ elementWidth = 30, elementHeight = 30 }, options.layout)
    end)

    it("dresses the aura button: lit spell icon, bright frame, breathing halo, engine-written time", function()
        local b = button()
        local textures, strings, groups = {}, {}, {}
        for _, o in ipairs(made) do
            if o.kind == "CreateTexture" then textures[#textures + 1] = o end
            if o.kind == "CreateFontString" then strings[#strings + 1] = o end
            if o.kind == "CreateAnimationGroup" then groups[#groups + 1] = o end
        end
        assert.equal(3, #textures)
        local icon = textures[3]
        assert.same({ "tex" }, icon.calls.SetTexture)
        assert.is_nil(icon.calls.SetDesaturated)
        assert.equal(strings[1], b.calls.SetDurationText[1])
        assert.equal(1, #groups)
        assert.same({ "BOUNCE" }, groups[1].calls.SetLooping)
        assert.is_not_nil(groups[1].calls.Play)
    end)

    it("re-points watched displays instead of building new ones", function()
        overlay:Watch({ { unit = "party1", ids = { 48707 } } })
        overlay:Watch({ { unit = "party2", ids = { 48707 } } })
        local c = containers()
        assert.equal(1, #c)
        assert.same({ "party2" }, c[1].calls.SetUnit)
    end)

    it("turns off displays it no longer needs", function()
        overlay:Watch({ { unit = "party1", ids = { 48707 } }, { unit = "party2", ids = { 48707 } } })
        overlay:Watch({ { unit = "party1", ids = { 48707 } } })
        assert.same({ false }, containers()[2].calls.SetEnabled)
    end)

    local function last(kind)
        local found
        for _, o in ipairs(made) do
            if o.kind == kind then found = o end
        end
        return found
    end

    it("never touches a dressed button again: a new texture gets its own display", function()
        button()
        local icon = last("CreateTexture")
        overlay:SetLook("other", 30)
        assert.same({ "tex" }, icon.calls.SetTexture)
        local c = containers()
        assert.equal(2, #c)
        assert.same({ false }, c[1].calls.SetEnabled)
        local _, _, options = unpack(c[2].calls.AddAuraGroup)
        options.initializeFrame(stub("Button", made))
        assert.same({ "other" }, last("CreateTexture").calls.SetTexture)
    end)

    it("goes back to the display already built for a look", function()
        overlay:Watch({ { unit = "party1", ids = { 48707 } } })
        overlay:SetLook("other", 30)
        overlay:SetLook("tex", 30)
        local c = containers()
        assert.equal(2, #c)
        assert.same({ true }, c[1].calls.SetEnabled)
    end)

    it("rebuilds displays when the icon size changes", function()
        overlay:Watch({ { unit = "party1", ids = { 48707 } } })
        overlay:SetLook("tex", 40)
        overlay:Watch({ { unit = "party1", ids = { 48707 } } })
        local c = containers()
        assert.equal(2, #c)
        assert.same({ false }, c[1].calls.SetEnabled)
        local _, _, options = unpack(c[2].calls.AddAuraGroup)
        assert.same({ elementWidth = 40, elementHeight = 40 }, options.layout)
    end)

    it("hides the time text when timers are off, on a display of its own", function()
        button()
        local shown = last("CreateFontString")
        overlay:SetTimers(false)
        assert.same({ 1 }, shown.calls.SetAlpha)
        local _, _, options = unpack(containers()[2].calls.AddAuraGroup)
        options.initializeFrame(stub("Button", made))
        assert.same({ 0 }, last("CreateFontString").calls.SetAlpha)
    end)
end)
