local _, ns = ...

local Theme = {
    bg = { 0.063, 0.075, 0.09, 0.99 },
    panel = { 0.082, 0.098, 0.125, 1 },
    border = { 0.235, 0.251, 0.282, 1 },
    control = { 0.36, 0.38, 0.43, 1 },
    gold = { 1, 0.82, 0 },
    text = { 0.9, 0.9, 0.9 },
    muted = { 0.66, 0.68, 0.72 },
    selected = { 0.165, 0.192, 0.251, 1 },
    maybe = { 0.3, 0.62, 1, 1 },
    unread = { 1, 0.55, 0.1, 1 },
    FLAT = { bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 },
    FONT = "Fonts\\FRIZQT__.TTF",
}
ns.Theme = Theme

local DARK, LIGHT = { 0.078, 0.086, 0.102 }, { 0.961, 0.953, 0.98 }
local function style(r, g, b, text, glyph)
    return { fill = { r, g, b }, text = text, glyph = glyph }
end
Theme.TYPES = {
    Personal = style(0.478, 0.384, 0.757, LIGHT, "P"), External = style(0.184, 0.627, 1, DARK, "E"),
    Group = style(0.533, 0.886, 0.8, DARK, "G"), Kick = style(0.867, 0.784, 0.169, DARK, "K"),
    Control = style(0.616, 0.369, 0.51, LIGHT, "C"), Stun = style(0.894, 0.631, 0.525, DARK, "S"),
    CC = style(0.616, 0.369, 0.51, LIGHT, "C"), Dispel = style(0.071, 0.722, 0.737, DARK, "D"),
    Purge = style(0.055, 0.486, 0.502, LIGHT, "X"), Burst = style(0.514, 0.608, 0, DARK, "B"),
    Racial = style(0.784, 0.537, 0.29, DARK, "R"), Potion = style(0.753, 0.314, 0.302, LIGHT, "+"),
    Movement = style(0.443, 0.514, 0.294, LIGHT, "M"),
}
Theme.BACKGROUNDS = { Default = { 0.078, 0.086, 0.106 }, Black = { 0, 0, 0 }, Slate = { 0.165, 0.192, 0.251 } }

function Theme.Backdrop(frame, look)
    frame:SetBackdrop(Theme.FLAT)
    local rgb = Theme.BACKGROUNDS[look.background]
    if rgb then
        frame:SetBackdropColor(rgb[1], rgb[2], rgb[3], look.opacity / 100)
    else
        frame:SetBackdropColor(0, 0, 0, 0)
    end
    if rgb then
        frame:SetBackdropBorderColor(unpack(Theme.border))
    else
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

function Theme.Panel(frame)
    frame:SetBackdrop(Theme.FLAT)
    frame:SetBackdropColor(unpack(Theme.bg))
    frame:SetBackdropBorderColor(unpack(Theme.border))
end

function Theme.ClassColor(class)
    local c = class and C_ClassColor.GetClassColor(class)
    if c then return c.r, c.g, c.b end
    return unpack(Theme.text)
end

function Theme.ClassName(class)
    return LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class
end

function Theme.MakeMovable(frame, isLocked, save)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not isLocked() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local cx, cy = UIParent:GetCenter()
        save({ "CENTER", math.floor(x - cx + 0.5), math.floor(y - cy + 0.5) })
    end)
end
