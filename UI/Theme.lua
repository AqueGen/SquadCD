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
