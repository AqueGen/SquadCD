local _, ns = ...

local NOTES = {
    Personal = "defensives on self",
    Burst = "damage cooldowns",
    Racial = "racial abilities",
    Potion = "combat potions",
    External = "defensives cast on others",
    Kick = "interrupts",
    Stun = "stuns",
    CC = "crowd control",
    Group = "group-wide defensives",
    Dispel = "dispels",
    Purge = "purges and soothes",
    Movement = "group speed boosts",
}
local OPTIONS = { { value = "Row", text = "Row" }, { value = "Panel", text = "Panel" }, { value = "Off", text = "Off" } }

ns.Window.Register("layout", function(page)
    local intro = page:Group("Where each type shows")
    intro:Note("Row: next to the member's party frame. Panel: one shared panel for the group. Off: not shown. Changes apply at once; in combat they wait until combat ends.")

    local preview = page:Group("Preview")
    local picture = ns.Picture.New(preview.frame)
    preview:Add(picture, function() return picture.height end, function() picture:Draw() end)

    local types = page:Group("Types")
    for _, t in ipairs(ns.LayoutRules.TYPES) do
        types:Segmented({
            label = ns.LayoutRules.LABELS[t],
            note = NOTES[t],
            options = OPTIONS,
            width = 180,
            get = function() return ns.DB.placement[t] end,
            set = function(value)
                ns.DB.placement[t] = value
                ns.Display.Changed()
            end,
        })
    end
end)
