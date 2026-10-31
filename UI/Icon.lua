local _, ns = ...

local Icon = {}
Icon.__index = Icon
ns.Icon = Icon

local T = ns.Theme
local SWIPE_EPSILON = 0.05

local function texture(spell)
    if spell.id == "potion" then
        return C_Item.GetItemIconByID(ns.Potions[1].item)
    end
    if spell.icon then
        return "Interface\\Icons\\" .. spell.icon
    end
    return C_Spell.GetSpellTexture(spell.id)
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
    local count = over:CreateFontString(nil, "OVERLAY")
    count:SetPoint("BOTTOMRIGHT", -1, 1)
    local dot = over:CreateTexture(nil, "OVERLAY")
    dot:SetColorTexture(unpack(T.unread))
    dot:SetPoint("TOPRIGHT", -2, -2)
    local label = f:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOP", f, "BOTTOM", 0, -1)

    return setmetatable({ frame = f, tex = tex, cd = cd, time = time, count = count, dot = dot, label = label }, Icon)
end

function Icon:SetSpell(spell, member, size)
    self.spell, self.member = spell, member
    self.duration, self.maxCharges = resolve(spell, member)
    self.start, self.state = nil, nil
    self.frame:SetSize(size, size)
    self.tex:SetTexture(texture(spell))
    self.time:SetFont(T.FONT, math.max(8, math.floor(size * 0.42)), "OUTLINE")
    self.count:SetFont(T.FONT, math.max(7, math.floor(size * 0.32)), "OUTLINE")
    self.label:SetFont(T.FONT, 9, "OUTLINE")
    self.dot:SetSize(math.max(3, math.floor(size / 6)), math.max(3, math.floor(size / 6)))
    self.label:SetText("")
    self.cd:Clear()
end

function Icon:SetLabel(text, r, g, b)
    self.label:SetText(text)
    self.label:SetTextColor(r, g, b)
end

function Icon:Update(state, now)
    if not state then return end
    local cooling = not state.ready
    if cooling then
        local start = now - (self.duration - state.remaining)
        if not self.start or math.abs(start - self.start) > SWIPE_EPSILON then
            self.start = start
            self.cd:SetCooldown(start, self.duration)
        end
    elseif self.start then
        self.start = nil
        self.cd:Clear()
    end
    self.time:SetText(cooling and ns.LayoutRules.FormatRemaining(state.remaining) or "")
    self.count:SetText(self.maxCharges > 1 and state.charges or "")
    self.tex:SetDesaturated(cooling)
    self.tex:SetAlpha(cooling and 0.55 or 1)
    if state.maybe then
        self.frame:SetBackdropBorderColor(unpack(T.maybe))
        self.time:SetTextColor(unpack(T.maybe))
    else
        self.frame:SetBackdropBorderColor(unpack(T.border))
        self.time:SetTextColor(1, 1, 1)
    end
    self.dot:SetAlpha(state.talentsKnown == false and 1 or 0)
end
