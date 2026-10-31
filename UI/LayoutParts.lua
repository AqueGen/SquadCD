local _, ns = ...

local Parts = {}
ns.LayoutParts = Parts

local T = ns.Theme
local Widgets = ns.Widgets
local CHIP_GAP, CHIP_H = 4, 22

Parts.SIDES = { { value = "Left", text = "Left" }, { value = "Right", text = "Right" }, { value = "Above", text = "Above" }, { value = "Below", text = "Below" } }
local AXES = { { value = "Rows", text = "Rows first" }, { value = "Columns", text = "Columns first" } }
local CORNERS = {
    { value = "TopLeft", text = "Top left" }, { value = "TopRight", text = "Top right" },
    { value = "BottomLeft", text = "Bottom left" }, { value = "BottomRight", text = "Bottom right" },
}
local SORTS = { { value = "Fixed", text = "Fixed" }, { value = "ReadyFirst", text = "Ready first" } }
local LABELS = { { value = "None", text = "None" }, { value = "Glyph", text = "Glyph" }, { value = "Short", text = "Short text" }, { value = "Full", text = "Full text" } }
local BACKGROUNDS = { { value = "Default", text = "Default" }, { value = "Black", text = "Black" }, { value = "Slate", text = "Slate" }, { value = "None", text = "None" } }
local WIDE = 280

function Parts.Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = Parts.Copy(x) end
    return t
end

function Parts.Edit(fn, ...)
    fn(ns.DB.layout, ...)
    ns.LayoutModel.Normalize(ns.DB.layout)
    ns.Display.Changed()
end

function Parts.Label(t)
    return ns.LayoutRules.LABELS[t] or t
end

function Parts.Mark(parent, size)
    local mark = parent:CreateTexture(nil, "ARTWORK")
    mark:SetSize(size, size)
    local glyph = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    glyph:SetPoint("CENTER", mark, "CENTER", 0, 0)
    return mark, function(t)
        local style = T.TYPES[t] or T.TYPES.Personal
        mark:SetColorTexture(style.fill[1], style.fill[2], style.fill[3], 1)
        glyph:SetText(style.glyph)
        glyph:SetTextColor(unpack(style.text))
    end
end

local function both(a, b)
    return function()
        return (not a or a()) and (not b or b())
    end
end

function Parts.Look(group, opts)
    local function setting(key)
        return function(value) opts.set(key, value) end
    end
    local function get(key)
        return function() return opts.get()[key] end
    end
    local backdrop = both(opts.visible, opts.backdrop)
    group:Slider({ label = "Icon size", min = opts.member and 12 or 20, max = 40, get = get("iconSize"), set = setting("iconSize"), visible = opts.visible })
    local labels = opts.member and { LABELS[1], LABELS[2], LABELS[3] } or LABELS
    group:Segmented({ label = "Type labels", options = labels, width = WIDE, get = get("labels"), set = setting("labels"), visible = opts.visible })
    group:Segmented({ label = "Background", options = BACKGROUNDS, width = WIDE, get = get("background"), set = setting("background"), visible = backdrop })
    if opts.member then return end
    group:Slider({ label = "Opacity", min = 0, max = 100, step = 5, format = "%d%%", get = get("opacity"), set = setting("opacity"), visible = backdrop })
    group:Slider({
        label = "Name letters", min = 3, max = 6, get = get("nameLetters"), set = setting("nameLetters"), visible = opts.visible,
        tooltip = "Letters of each name under the icons.",
    })
end

function Parts.Shape(group, opts)
    local function setting(key)
        return function(value) opts.set(key, value) end
    end
    local function get(key)
        return function() return opts.get()[key] end
    end
    group:Segmented({ label = "Fill order", options = AXES, get = get("axis"), set = setting("axis"), visible = opts.visible })
    group:Slider({ label = "Icons per line", min = 1, max = 12, get = get("perLine"), set = setting("perLine"), visible = opts.visible })
    group:Segmented({ label = "Grows from corner", options = CORNERS, width = WIDE, get = get("origin"), set = setting("origin"), visible = opts.visible })
    if opts.member then return end
    group:Segmented({
        label = "Order inside a type", options = SORTS, get = get("sort"), set = setting("sort"), visible = opts.visible,
        note = "Fixed: role and class priority",
    })
end

local function newChip(holder)
    local chip = Widgets.Button(holder, "", 60)
    chip.rail = chip:CreateTexture(nil, "ARTWORK")
    chip.rail:SetPoint("TOPLEFT", 1, -1)
    chip.rail:SetPoint("BOTTOMLEFT", 1, 1)
    chip.rail:SetWidth(4)
    chip.label:ClearAllPoints()
    chip.label:SetPoint("LEFT", chip, "LEFT", 10, 0)
    return chip
end

function Parts.Types(group, opts)
    local holder = CreateFrame("Frame", nil, group.frame)
    local chips, height = {}, CHIP_H
    local add = Widgets.Button(holder, "Add type", 80)
    add:SetScript("OnClick", function(self)
        local list = opts.choices()
        if #list == 0 or not MenuUtil then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            for _, t in ipairs(list) do
                root:CreateButton(Parts.Label(t), function()
                    opts.add(t)
                    group.page:Refresh()
                end)
            end
        end)
    end)
    group:Add(holder, function() return height end, function()
        local room = math.max((group.frame:GetWidth() or 0) - 2 * Widgets.PAD, 200)
        local x, y = 0, 0
        local types = opts.get()
        local function place(frame, w)
            if x > 0 and x + w > room then x, y = 0, y + CHIP_H + CHIP_GAP end
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", holder, "TOPLEFT", x, -y)
            x = x + w + CHIP_GAP
        end
        for i, t in ipairs(types) do
            local chip = chips[i] or newChip(holder)
            chips[i] = chip
            chip.type = t
            chip:SetText(Parts.Label(t))
            local fill = (T.TYPES[t] or T.TYPES.Personal).fill
            chip.rail:SetColorTexture(fill[1], fill[2], fill[3], 1)
            local w = math.floor(chip.label:GetStringWidth() + 20)
            chip:SetWidth(w)
            chip:SetScript("OnClick", function(self)
                opts.remove(self.type)
                group.page:Refresh()
            end)
            chip:Show()
            place(chip, w)
        end
        for i = #types + 1, #chips do chips[i]:Hide() end
        local any = #opts.choices() > 0
        add:SetEnabled(any)
        add:SetAlpha(any and 1 or 0.35)
        place(add, 80)
        height = y + CHIP_H
        holder:SetSize(room, height)
    end, opts.visible)
end
