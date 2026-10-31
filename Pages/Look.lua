local _, ns = ...

local SIDES = {
    { value = "LEFT", text = "Left" }, { value = "RIGHT", text = "Right" },
    { value = "ABOVE", text = "Above" }, { value = "BELOW", text = "Below" },
}

local function Setting(section, key, after)
    return {
        get = function() return ns.DB[section][key] end,
        set = function(value)
            ns.DB[section][key] = value
            ns.Display.Changed()
            if after then after() end
        end,
    }
end

local function With(spec, extra)
    for k, v in pairs(extra) do spec[k] = v end
    return spec
end

ns.Window.Register("look", function(page)
    local preview = page:Group("Preview")
    local picture = ns.Picture.New(preview.frame)
    preview:Add(picture, function() return picture.height end, function() picture:Draw() end)

    local row = page:Group("Member rows")
    row:Note("Rows sit next to each party frame (Blizzard, EllesmereUI or a stack of names when neither is shown).")
    row:Segmented(With(Setting("row", "side"), { label = "Side of the frame", options = SIDES }))
    row:Slider(With(Setting("row", "size"), { label = "Icon size", min = 16, max = 48 }))
    row:Slider(With(Setting("row", "spacing"), { label = "Spacing", min = 0, max = 10 }))
    row:Slider(With(Setting("row", "max", function() page:Refresh() end), {
        label = "Most icons per row", min = 1, max = 16,
        tooltip = "Icons past this number are not shown; types further down the Layout list are cut first.",
    }))

    local panel = page:Group("Group panel")
    panel:Note("The panel shows in a party or in Demo mode. Click Unlock panel in the title bar (or clear Lock panel below), then drag the panel with the mouse; Lock panel fixes it in place. Out of combat only.")
    panel:Slider(With(Setting("panel", "size"), { label = "Icon size", min = 16, max = 48 }))
    panel:Check({
        label = "Lock panel",
        get = function() return ns.DB.layout.panel.locked end,
        set = function(value)
            ns.Panel.SetLocked(value)
            ns.Window.Refresh()
        end,
    })
end)
