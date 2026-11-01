-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Icon = {}
Icon.__index = Icon
ns.Icon = Icon

local T = ns.Theme
local SWIPE_EPSILON = 0.05
local WHITE = { 1, 1, 1 }

local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local function usable(v)
    return issecretvalue(v) or v ~= nil
end

local function texture(spell)
    local tex
    if spell.id == "potion" then
        tex = C_Item.GetItemIconByID(ns.Potions[1].item)
    else
        tex = C_Spell.GetSpellTexture(spell.id)
        if not usable(tex) and spell.icon then tex = "Interface\\Icons\\" .. spell.icon end
    end
    if usable(tex) then return tex end
    return QUESTION
end

local function resolve(spell, member)
    if spell.id == "potion" then
        return ns.Potions[1].cd, 1
    end
    local r = ns.Cooldowns.Resolve(spell.id, member.spec, member.talents)
    if r then return r.cd, r.charges end
    return 0, 1
end

function Icon.New(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop(T.FLAT)
    f:SetBackdropColor(0, 0, 0, 1)

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 1, -1)
    tex:SetPoint("BOTTOMRIGHT", -1, 1)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints(tex)
    cd:SetDrawEdge(false)
    cd:SetHideCountdownNumbers(true)

    local over = CreateFrame("Frame", nil, f)
    over:SetAllPoints(f)
    over:SetFrameLevel(cd:GetFrameLevel() + 2)

    local time = over:CreateFontString(nil, "OVERLAY")
    time:SetPoint("CENTER", 0, 0)
    local mark = over:CreateFontString(nil, "OVERLAY")
    mark:SetPoint("CENTER", 0, 0)
    local count = over:CreateFontString(nil, "OVERLAY")
    count:SetPoint("BOTTOMRIGHT", -1, 1)
    local dot = over:CreateTexture(nil, "OVERLAY")
    dot:SetColorTexture(unpack(T.unread))
    dot:SetPoint("TOPRIGHT", -2, -2)
    local label = f:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOP", f, "BOTTOM", 0, -1)

    return setmetatable({ frame = f, tex = tex, cd = cd, time = time, mark = mark, count = count, dot = dot, label = label, buf = {} }, Icon)
end

function Icon:SetSpell(spell, member, size)
    self.spell, self.member = spell, member
    self.duration, self.maxCharges = resolve(spell, member)
    self.start, self.text, self.charges, self.look, self.maybe, self.unread, self.next = nil, nil, nil, nil, nil, nil, nil
    self.frame:SetSize(size, size)
    self.tex:SetTexture(texture(spell))
    self.time:SetFont(T.FONT, math.max(8, math.floor(size * 0.42)), "OUTLINE")
    self.mark:SetFont(T.FONT, math.max(8, math.floor(size * 0.55)), "OUTLINE")
    self.count:SetFont(T.FONT, math.max(7, math.floor(size * 0.32)), "OUTLINE")
    self.label:SetFont(T.FONT, 9, "OUTLINE")
    self.dot:SetSize(math.max(3, math.floor(size / 6)), math.max(3, math.floor(size / 6)))
    self.label:SetText("")
    self.cd:Clear()
    self:BindSecret(spell, member, size)
    self:BindActive(spell, member, size)
end

function Icon:BindActive(spell, member, size)
    local list = not self.secret and ns.SecretTracks and ns.SecretTracks.WatchFor and ns.SecretTracks.WatchFor(member, spell.id) or {}
    if #list == 0 and not self.overlay then return end
    xpcall(function()
        self.overlay = self.overlay or ns.ActiveOverlay.New(self.frame, self.frame:GetFrameLevel() + 8)
        self.overlay:SetLook(texture(spell), size)
        self.overlay:Watch(list)
    end, geterrorhandler())
end

function Icon:BindSecret(spell, member, size)
    self.secret = false
    if not (ns.SecretTracks and ns.SecretLayer) then return end
    if not self.layer and not ns.SecretTracks.Track(member.guid, spell.id) then return end
    local ok = xpcall(function()
        self.layer = self.layer or ns.SecretLayer.New(self)
        self.layer:SetLook(texture(spell), size)
        self.secret = ns.SecretTracks.Bind(self.layer, member.guid, spell.id)
        self.layer:Show(self.secret)
    end, geterrorhandler())
    if not ok then
        self.secret = false
        if self.layer then
            ns.SecretTracks.Unbind(self.layer)
            pcall(self.layer.Show, self.layer, false)
        end
    end
end

function Icon:SetLabel(text, r, g, b)
    self.label:SetText(text)
    self.label:SetTextColor(r, g, b)
    self.label:ClearAllPoints()
    if text ~= "" and self.label:GetStringWidth() > self.frame:GetWidth() then
        self.label:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 0, -1)
    else
        self.label:SetPoint("TOP", self.frame, "BOTTOM", 0, -1)
    end
    return math.ceil(self.label:GetStringWidth())
end

function Icon:SetNext(on)
    if on == self.next then return end
    self.next = on
    self:Border()
end

function Icon:Border()
    local color = self.next and T.gold or self.maybe and T.maybe or T.border
    self.frame:SetBackdropBorderColor(unpack(color))
end

function Icon:Update(state, now, timers)
    if self.secret then
        self.layer:SetTimers(timers ~= false)
        if self.look ~= "secret" then
            self.look, self.start, self.text, self.charges = "secret", nil, "", ""
            self.cd:Clear()
            self.time:SetText("")
            self.count:SetText("")
            self.mark:SetText("")
            self.tex:SetDesaturated(false)
            self.tex:SetAlpha(1)
        end
        return
    end
    if not state then return end
    if self.overlay then self.overlay:SetTimers(timers ~= false) end
    local cooling = not state.ready
    local unknown = not cooling and state.unknown or false
    local timer = unknown and 0 or cooling and state.remaining or state.recharge or 0
    if timer > 0 then
        local start = now - (self.duration - timer)
        if not self.start or math.abs(start - self.start) > SWIPE_EPSILON then
            self.start = start
            self.cd:SetCooldown(start, self.duration)
        end
    elseif self.start then
        self.start = nil
        self.cd:Clear()
    end
    local text = timers ~= false and timer > 0 and ns.LayoutRules.FormatRemaining(timer) or ""
    if text ~= self.text then
        self.text = text
        self.time:SetText(text)
    end
    local count = self.maxCharges > 1 and state.charges or ""
    if count ~= self.charges then
        self.charges = count
        self.count:SetText(count)
    end
    local look = cooling and "cooling" or unknown and "unknown" or "ready"
    if look ~= self.look then
        self.look = look
        self.tex:SetDesaturated(look ~= "ready")
        self.tex:SetAlpha(look == "cooling" and 0.55 or 1)
        self.mark:SetText(unknown and "?" or "")
    end
    local maybe = state.maybe or false
    if maybe ~= self.maybe then
        self.maybe = maybe
        self:Border()
        self.time:SetTextColor(unpack(maybe and T.maybe or WHITE))
    end
    local unread = state.talentsKnown == false
    if unread ~= self.unread then
        self.unread = unread
        self.dot:SetAlpha(unread and 1 or 0)
    end
end

local Tab = {}
Tab.__index = Tab

local GLYPHS = "Interface\\AddOns\\SquadCD\\Media\\Types\\"

function Icon.TypeIcon(type)
    return T.TYPES[type] and GLYPHS .. type or nil
end

function Icon.NewTab(parent)
    local f = CreateFrame("Frame", nil, parent)
    local fill = f:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints(f)
    local text = f:CreateFontString(nil, "OVERLAY")
    text:SetFont(T.FONT, 9, "")
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    icon:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    icon:Hide()
    return setmetatable({ frame = f, fill = fill, text = text, icon = icon }, Tab)
end

function Icon.TabText(type, labels)
    if labels == "Glyph" then return T.TYPES[type] and T.TYPES[type].glyph or "" end
    if labels == "Short" then return ns.LayoutRules.SHORT[type] or type end
    if labels == "Full" then return ns.LayoutRules.LABELS[type] or type end
    return ""
end

function Tab:Set(type, labels)
    local style = T.TYPES[type] or { fill = T.control, text = T.text }
    self.fill:SetColorTexture(style.fill[1], style.fill[2], style.fill[3], 1)
    self.text:SetFont(T.FONT, 9, "")
    self.text:SetTextColor(unpack(style.text))
    self.text:SetText(Icon.TabText(type, labels))
    local icon = labels == "Icon"
    self.icon:SetShown(icon)
    if icon then
        self.icon:SetTexture(Icon.TypeIcon(type))
        self.icon:SetVertexColor(unpack(style.text))
        self.icon:SetHeight(Icon.TAB_ICON)
        return Icon.TAB_ICON
    end
    return math.ceil(self.text:GetStringWidth())
end

Icon.TAB_ICON = 16
