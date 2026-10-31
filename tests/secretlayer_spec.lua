-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

local function stub(kind, made)
    local o = { kind = kind, calls = {} }
    made[#made + 1] = o
    return setmetatable(o, { __index = function(_, k)
        return function(self, ...)
            self.calls[k] = { ... }
            if k == "CreateTexture" or k == "CreateFontString" then return stub(k, made) end
            if k == "GetStatusBarTexture" then
                if not rawget(self, "fill") then rawset(self, "fill", stub("Texture", made)) end
                return rawget(self, "fill")
            end
            if k == "GetFrameLevel" then return 1 end
            if k == "GetStringHeight" or k == "GetStringWidth" or k == "GetWidth" then return 10 end
        end
    end })
end

local FILES = { "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/LayoutRules.lua", "UI/Theme.lua", "UI/Icon.lua", "UI/SecretLayer.lua" }

describe("SecretLayer", function()
    local ns, made, layer

    before_each(function()
        made = {}
        ns = helpers.load(FILES, {
            CreateFrame = function(kind) return stub(kind, made) end,
            C_Spell = { GetSpellTexture = function() return "tex" end },
        })
        local icon = ns.Icon.New(stub("Frame", made))
        layer = ns.SecretLayer.New(icon)
        layer:SetLook("tex", 30)
        layer:Configure(120, 8, 2)
    end)

    local function lines(strip)
        local text = strip.calls.SetText[1]
        local out = {}
        for l in (text .. "\n"):gmatch("(.-)\n") do out[#out + 1] = l end
        return out
    end

    it("builds strips of remaining-time labels", function()
        local cool, act = lines(layer.slots[1].coolText), lines(layer.slots[1].actText)
        assert.equal(60, #cool)
        assert.equal("2", cool[1])
        assert.equal("1:00", cool[30])
        assert.equal(4, #act)
    end)

    it("writes slot values to its bars", function()
        layer:Write(1, { stamp = 0.2, coolLo = 0.1, coolHi = 0.3, actLo = 0.15, actHi = 0.25, gateLo = 0.05, gateHi = 0.06 })
        local s = layer.slots[1]
        assert.same({ 0.1, 0.3 }, s.cool.calls.SetMinMaxValues)
        assert.same({ 0.2 }, s.cool.calls.SetValue)
        assert.same({ 0.05, 0.06 }, s.gate.calls.SetMinMaxValues)
        assert.same({ 0.15, 0.25 }, s.act.calls.SetMinMaxValues)
    end)

    it("sets phase alphas", function()
        layer:SetPhase(1, 0)
        assert.same({ 1 }, layer.border.calls.SetAlpha)
        assert.same({ 0 }, layer.grey.calls.SetAlpha)
        assert.same({ 1 }, layer.active.calls.SetAlpha)
        assert.same({ 0 }, layer.cooling.calls.SetAlpha)
    end)

    it("hides timers when the setting is off", function()
        layer:SetTimers(false)
        assert.same({ false }, layer.window.calls.SetShown)
    end)
end)

describe("Icon with a secret track", function()
    it("keeps the plain ready look while bound", function()
        local made = {}
        local ns = helpers.load(FILES, {
            CreateFrame = function(kind) return stub(kind, made) end,
            C_Spell = { GetSpellTexture = function() return "tex" end },
        })
        ns.SecretTracks = { Bind = function() return true end, Unbind = function() end, Track = function() return {} end }
        local icon = ns.Icon.New(stub("Frame", made))
        icon:SetSpell({ id = 48792 }, { guid = "A", spec = 250 }, 30)
        icon:Update({ ready = true, unknown = true }, 100, true)
        assert.same({ "" }, icon.mark.calls.SetText)
        assert.is_not_true((icon.tex.calls.SetDesaturated or {})[1])
    end)
end)
