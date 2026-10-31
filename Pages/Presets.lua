local _, ns = ...

local T = ns.Theme
local Widgets = ns.Widgets
local Parts = ns.LayoutParts
local Model = ns.LayoutModel
local Preview = ns.Preview

local DEMO = { { value = "Off", text = "Off" }, { value = "Me", text = "Only me" }, { value = "Group", text = "Whole group" } }
local PRESETS = {
    { name = "Everything together, horizontal", hint = "One panel, types side by side" },
    { name = "Everything together, vertical", hint = "One panel, types stacked" },
    { name = "At party frames, left + panel", hint = "Defensives, burst, racials left of each frame" },
    { name = "At party frames, right + panel", hint = "Defensives, burst, racials right of each frame" },
    { name = "At party frames, below + panel", hint = "For party frames in a row" },
    { name = "At party frames, above + panel", hint = "For party frames in a row" },
}
local PLACES = { { value = "panel", text = "Panel", w = 56 }, { value = "member", text = "At party frames", w = 104 }, { value = "off", text = "Off", w = 44 } }
local ROLE_NAMES = { Tank = "Tank", Melee = "Melee", Ranged = "Ranged", Healer = "Healer" }
local COLUMNS, CARD_GAP, CARD_H, THUMB_W, THUMB_H = 3, 8, 132, 120, 62
local ROW_H, NAME_X, PLACE_X, SPLIT_X, ORDER_X = 24, 22, 160, 380, 452
local ITEM_W, ITEM_H, CLASS_X, CLASS_COLUMNS = 150, 22, 180, 2

local CARD_FILL = { 20 / 255, 22 / 255, 27 / 255, 0.9 }
local FRAME_FILL = { 0x5B / 255, 0x3F / 255, 0x6E / 255, 1 }
local THUMB = { "Burst", "Personal", "External", "Group", "Kick", "Control", "Dispel", "Purge", "Movement" }
local PANEL = { "Kick", "Control", "Dispel", "Purge" }

local function fill(t)
    local c = T.TYPES[t].fill
    return { c[1], c[2], c[3], 1 }
end

local function thumbRects(kind)
    local out = {}
    local function rect(x, y, w, h, color) out[#out + 1] = { x, y, w, h, color } end
    local function panel(x)
        rect(x, 6, 26, 30, CARD_FILL)
        for i, t in ipairs(PANEL) do
            rect(x + 2, 9 + (i - 1) * 6, 2, 4, fill(t))
            rect(x + 6, 9 + (i - 1) * 6, t == "Kick" and 16 or 9, 4, fill(t))
        end
    end
    if kind == 1 then
        rect(4, 14, 112, 34, CARD_FILL)
        for i, t in ipairs(THUMB) do
            rect(7 + (i - 1) * 12, 17, 10, 2, fill(t))
            rect(7 + (i - 1) * 12, 21, t == "Kick" and 10 or 6, 22, fill(t))
        end
    elseif kind == 2 then
        rect(8, 3, 44, 56, CARD_FILL)
        for i, t in ipairs(THUMB) do
            rect(11, 6 + (i - 1) * 6, 3, 4, fill(t))
            rect(16, 6 + (i - 1) * 6, t == "Kick" and 30 or 6 + (i - 1) * 7 % 5 * 4, 4, fill(t))
        end
    elseif kind == 3 or kind == 4 then
        local left = kind == 3
        panel(left and 4 or 88)
        for i = 1, 5 do
            local frame, row, y = left and 84 or 6, left and 64 or 34, 4 + (i - 1) * 11
            rect(frame, y, 26, 9, FRAME_FILL)
            rect(row, y + 1, 3, 6, fill("Burst"))
            rect(row + 4, y + 1, 6, 6, fill("Personal"))
            rect(row + 11, y + 1, 3, 6, fill("External"))
        end
    else
        panel(88)
        local below = kind == 5
        for i = 1, 5 do
            local x = 4 + (i - 1) * 16
            rect(x, below and 8 or 44, 14, 9, FRAME_FILL)
            rect(x, below and 19 or 36, 3, 6, fill("Burst"))
            rect(x + 4, below and 19 or 36, 6, 6, fill("Personal"))
            rect(x, below and 27 or 28, 6, 6, fill("External"))
        end
    end
    return out
end

local function newCard(parent, n, onClick)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetBackdrop(T.FLAT)
    card:SetBackdropColor(unpack(T.panel))
    card:SetHeight(CARD_H)
    card.thumb = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card.thumb:SetPoint("TOPLEFT", 8, -8)
    card.thumb:SetPoint("TOPRIGHT", -8, -8)
    card.thumb:SetHeight(THUMB_H + 6)
    card.thumb:SetBackdrop(T.FLAT)
    card.thumb:SetBackdropColor(unpack(T.bg))
    card.thumb:SetBackdropBorderColor(0, 0, 0, 0)
    local canvas = CreateFrame("Frame", nil, card.thumb)
    canvas:SetSize(THUMB_W, THUMB_H)
    canvas:SetPoint("CENTER")
    for _, r in ipairs(thumbRects(n)) do
        local tex = canvas:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", canvas, "TOPLEFT", r[1], -r[2])
        tex:SetSize(r[3], r[4])
        tex:SetColorTexture(unpack(r[5]))
    end
    card.badge = CreateFrame("Frame", nil, card.thumb, "BackdropTemplate")
    card.badge:SetPoint("TOPRIGHT", -4, -4)
    card.badge:SetFrameLevel(canvas:GetFrameLevel() + 2)
    card.badge:SetSize(60, 16)
    card.badge:SetBackdrop(T.FLAT)
    card.badge:SetBackdropBorderColor(0, 0, 0, 0)
    card.badge.text = card.badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.badge.text:SetPoint("CENTER")
    card.name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.name:SetPoint("TOPLEFT", card.thumb, "BOTTOMLEFT", 0, -8)
    card.name:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    card.name:SetJustifyH("LEFT")
    card.name:SetText(PRESETS[n].name)
    card.hint = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.hint:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
    card.hint:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    card.hint:SetJustifyH("LEFT")
    card.hint:SetTextColor(unpack(T.muted))
    card.hint:SetText(PRESETS[n].hint)
    local hover = card:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.05)
    card:SetScript("OnClick", function() onClick(n) end)
    return card
end

local function paintCard(card, used, previewing)
    local color = previewing and { 0.3, 0.8, 0.4, 1 } or used and T.gold or T.border
    card:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    card.badge:SetShown(used or previewing)
    if previewing then
        card.badge:SetBackdropColor(0.3, 0.8, 0.4, 1)
        card.badge.text:SetText("Preview")
        card.badge.text:SetTextColor(0.05, 0.16, 0.07)
    elseif used then
        card.badge:SetBackdropColor(T.gold[1], T.gold[2], T.gold[3], 1)
        card.badge.text:SetText("In use")
        card.badge.text:SetTextColor(0.08, 0.08, 0.08)
    end
    card.badge:SetWidth(math.ceil(card.badge.text:GetStringWidth()) + 12)
end

local function cancelPreview()
    if Preview.Cancel(ns.DB) then ns.Display.Changed() end
end

local logout = CreateFrame("Frame")
logout:RegisterEvent("PLAYER_LOGOUT")
logout:SetScript("OnEvent", function()
    if ns.DB then Preview.Cancel(ns.DB) end
end)

local function presetCards(page)
    local group = page:Group("Presets")
    group:Note("Click a preset to see it on screen. Apply keeps it, Cancel goes back. Leaving this page also goes back.")
    local holder = CreateFrame("Frame", nil, group.frame)
    local cards = {}
    local function pick(n)
        Preview.Show(ns.DB, n)
        ns.Display.Changed()
        page:Refresh()
    end
    for n = 1, #PRESETS do cards[n] = newCard(holder, n, pick) end
    local rows = math.ceil(#PRESETS / COLUMNS)
    local height = rows * CARD_H + (rows - 1) * CARD_GAP
    group:Add(holder, height, function()
        local room = math.max((group.frame:GetWidth() or 0) - 2 * Widgets.PAD, 300)
        local w = math.floor((room - (COLUMNS - 1) * CARD_GAP) / COLUMNS)
        holder:SetSize(room, height)
        local used = (Preview.Saved() or ns.DB.layout).preset
        for n, card in ipairs(cards) do
            local col, row = (n - 1) % COLUMNS, math.floor((n - 1) / COLUMNS)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", holder, "TOPLEFT", col * (w + CARD_GAP), -row * (CARD_H + CARD_GAP))
            card:SetWidth(w)
            paintCard(card, used == n and Preview.Showing() ~= n, Preview.Showing() == n)
        end
    end)

    local bar = CreateFrame("Frame", nil, group.frame)
    bar:SetSize(560, 22)
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT")
    text:SetTextColor(0.3, 0.8, 0.4)
    local cancel = Widgets.Button(bar, "Cancel", 80)
    cancel:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    local apply = Widgets.Button(bar, "Apply", 80)
    apply:SetPoint("RIGHT", cancel, "LEFT", -6, 0)
    apply:SetScript("OnClick", function()
        Preview.Apply()
        page:Refresh()
    end)
    cancel:SetScript("OnClick", function()
        cancelPreview()
        page:Refresh()
    end)
    local function previewing() return Preview.Showing() ~= nil end
    group:Add(bar, 22, function()
        local n = Preview.Showing()
        text:SetText("Previewing: " .. (n and PRESETS[n].name or ""))
    end, previewing)
    group:Note({
        text = "No party? Set the demo above to Whole group to see the preview.",
        visible = function() return previewing() and not ns.Display.HasMembers() and not ns.Demo.Running() end,
    })
    page.frame:HookScript("OnHide", cancelPreview)
end

local function newTypeRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_H)
    row.mark, row.paint = Parts.Mark(row, 14)
    row.mark:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row, "LEFT", NAME_X, 0)
    row.name:SetWidth(PLACE_X - NAME_X - 6)
    row.name:SetJustifyH("LEFT")
    row.places = {}
    local x = PLACE_X
    for i, p in ipairs(PLACES) do
        local b = Widgets.Button(row, p.text, p.w)
        b:SetPoint("LEFT", row, "LEFT", x, 0)
        b.value = p.value
        row.places[i] = b
        x = x + p.w - 1
    end
    row.split = CreateFrame("CheckButton", nil, row, "MinimalCheckboxTemplate")
    row.split:SetSize(22, 22)
    row.split:SetPoint("LEFT", row, "LEFT", SPLIT_X, 0)
    row.split.text = row.split:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.split.text:SetPoint("LEFT", row.split, "RIGHT", 2, 0)
    row.split.text:SetText("Split")
    row.number = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.number:SetPoint("RIGHT", row, "LEFT", ORDER_X + 18, 0)
    row.up = Widgets.Button(row, "Up", 40)
    row.up:SetPoint("LEFT", row, "LEFT", ORDER_X + 24, 0)
    row.down = Widgets.Button(row, "Down", 44)
    row.down:SetPoint("LEFT", row.up, "RIGHT", 4, 0)
    return row
end

local function typesTable(page)
    local group = page:Group("Types: where they show and their order")
    group:Note("Panel: a section of the group panel (Panels page). At party frames: next to each member's party frame (At party frames page). Off: not shown. Split shows stuns and crowd control as two types.")
    local holder = CreateFrame("Frame", nil, group.frame)
    local header = CreateFrame("Frame", nil, holder)
    header:SetPoint("TOPLEFT")
    header:SetSize(560, 18)
    for _, h in ipairs({ { "Type", NAME_X }, { "Show in", PLACE_X }, { "Merge", SPLIT_X }, { "Order", ORDER_X } }) do
        local s = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        s:SetPoint("LEFT", header, "LEFT", h[2], 0)
        s:SetTextColor(unpack(T.gold))
        s:SetText(h[1])
    end
    local rows = {}
    for i = 1, #ns.LayoutRules.TYPES do
        local row = newTypeRow(holder)
        row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(18 + (i - 1) * ROW_H))
        row:SetPoint("RIGHT", holder, "RIGHT")
        for _, b in ipairs(row.places) do
            b:SetScript("OnClick", function(self)
                Parts.Edit(Model.SetPlace, row.type, self.value)
                page:Refresh()
            end)
        end
        row.split:SetScript("OnClick", function(self)
            Parts.Edit(Model.SetSplit, self:GetChecked() and true or false)
            page:Refresh()
        end)
        row.up:SetScript("OnClick", function()
            Parts.Edit(Model.MoveType, row.type, -1)
            page:Refresh()
        end)
        row.down:SetScript("OnClick", function()
            Parts.Edit(Model.MoveType, row.type, 1)
            page:Refresh()
        end)
        rows[i] = row
    end
    local count = 0
    group:Add(holder, function() return 18 + count * ROW_H end, function()
        local layout = ns.DB.layout
        local order = layout.typeOrder
        count = #order
        holder:SetSize(math.max((group.frame:GetWidth() or 0) - 2 * Widgets.PAD, 300), 18 + count * ROW_H)
        for i, row in ipairs(rows) do
            local t = order[i]
            row:SetShown(t ~= nil)
            if t then
                row.type = t
                row.paint(t)
                row.name:SetText(Parts.Label(t))
                local place = Model.PlaceOf(layout, t)
                for _, b in ipairs(row.places) do Widgets.PaintChoice(b, b.value == place) end
                local merged = t == "Control" or t == "Stun" or t == "CC"
                row.split:SetShown(merged)
                row.split:SetChecked(layout.split)
                row.number:SetText(i)
                row.number:SetTextColor(unpack(place == "off" and T.muted or T.text))
                row.up:SetEnabled(i > 1)
                row.up:SetAlpha(i > 1 and 1 or 0.35)
                row.down:SetEnabled(i < count)
                row.down:SetAlpha(i < count and 1 or 0.35)
            end
        end
    end)
    group:Note("Up and Down set the order of types inside every panel section and member group. Sections keep the order of the Panels page.")
end

local function newItem(parent)
    local item = CreateFrame("Button", nil, parent, "BackdropTemplate")
    item:SetSize(ITEM_W - 6, ITEM_H)
    item:SetBackdrop(T.FLAT)
    item:SetBackdropColor(unpack(T.panel))
    item:RegisterForDrag("LeftButton")
    item.number = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    item.number:SetPoint("LEFT", item, "LEFT", 6, 0)
    item.number:SetTextColor(unpack(T.muted))
    item.label = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    item.label:SetPoint("LEFT", item, "LEFT", 24, 0)
    local hover = item:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.06)
    return item
end

local function priority(page)
    local group = page:Group("Role and class priority")
    group:Note("Who goes first inside every type: the Next marker on kicks, control, externals and raid defensives, and the Fixed icon order.")
    group:Button({
        text = "Reset to default", width = 140,
        onClick = function() Parts.Edit(Model.ResetPriority) end,
    })
    local holder = CreateFrame("Frame", nil, group.frame)
    local roleTitle = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    roleTitle:SetPoint("TOPLEFT")
    roleTitle:SetTextColor(unpack(T.muted))
    roleTitle:SetText("Roles")
    local classTitle = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    classTitle:SetPoint("TOPLEFT", holder, "TOPLEFT", CLASS_X, 0)
    classTitle:SetTextColor(unpack(T.muted))

    local role = "Melee"
    local selected = { list = "role", index = 2 }
    local roles, classes, shownClasses = {}, {}, {}
    local keys = CreateFrame("Frame", nil, holder)

    local function move(list, from, to)
        if list == "role" then
            Parts.Edit(Model.MoveRole, from, to)
        else
            Parts.Edit(Model.MoveClass, role, shownClasses, from, to)
        end
        selected = { list = list, index = to }
        page:Refresh()
    end

    local function listening()
        if InCombatLockdown() then return end
        keys:SetPropagateKeyboardInput(true)
        keys:EnableKeyboard(true)
    end

    keys:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown() then return end
        local step = (key == "UP" and -1) or (key == "DOWN" and 1) or nil
        local count = selected.list == "role" and 4 or #shownClasses
        local to = step and selected.index + step
        local consume = step ~= nil and IsAltKeyDown() and to >= 1 and to <= count
        self:SetPropagateKeyboardInput(not consume)
        if consume then move(selected.list, selected.index, to) end
    end)
    keys:RegisterEvent("PLAYER_REGEN_DISABLED")
    keys:SetScript("OnEvent", function(self) self:EnableKeyboard(false) end)
    holder:SetScript("OnHide", function() if not InCombatLockdown() then keys:EnableKeyboard(false) end end)

    local function wire(item, list, index)
        item:SetScript("OnClick", function()
            if list == "role" then role = ns.DB.layout.rolePriority[index] end
            selected = { list = list, index = index }
            listening()
            page:Refresh()
        end)
        item:SetScript("OnDragStart", function() item.dragging = true end)
        item:SetScript("OnDragStop", function()
            item.dragging = nil
            local pool = list == "role" and roles or classes
            for to, other in ipairs(pool) do
                if other:IsShown() and other:IsMouseOver() and to ~= index then
                    move(list, index, to)
                    return
                end
            end
        end)
    end
    for i = 1, 4 do
        roles[i] = newItem(holder)
        roles[i]:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -(18 + (i - 1) * (ITEM_H + 4)))
        wire(roles[i], "role", i)
    end
    for i = 1, #ns.Classes do
        classes[i] = newItem(holder)
        local col, line = (i - 1) % CLASS_COLUMNS, math.floor((i - 1) / CLASS_COLUMNS)
        classes[i]:SetPoint("TOPLEFT", holder, "TOPLEFT", CLASS_X + col * ITEM_W, -(18 + line * (ITEM_H + 4)))
        wire(classes[i], "class", i)
    end

    local height = 0
    group:Add(holder, function() return height end, function()
        local layout = ns.DB.layout
        classTitle:SetText("Class order inside " .. ROLE_NAMES[role])
        for i, item in ipairs(roles) do
            local r = layout.rolePriority[i]
            item.number:SetText(i)
            item.label:SetText(ROLE_NAMES[r] or r)
            item.label:SetTextColor(unpack(r == role and T.gold or T.text))
            local on = selected.list == "role" and selected.index == i
            item:SetBackdropBorderColor(unpack(on and T.gold or T.border))
        end
        shownClasses = ns.LayoutGrid.ClassesIn(layout.classOrder[role], role)
        for i, item in ipairs(classes) do
            local id = shownClasses[i]
            item:SetShown(id ~= nil)
            if id then
                local token = ns.Classes[id]
                item.number:SetText(i)
                item.label:SetText(T.ClassName(token))
                item.label:SetTextColor(T.ClassColor(token))
                local on = selected.list == "class" and selected.index == i
                item:SetBackdropBorderColor(unpack(on and T.gold or T.border))
            end
        end
        local lines = math.max(4, math.ceil(#shownClasses / CLASS_COLUMNS))
        height = 18 + lines * (ITEM_H + 4)
        holder:SetSize(CLASS_X + CLASS_COLUMNS * ITEM_W, height)
    end)
    group:Note("A class counts in the role of its current spec. Click a role to order its classes. Drag a row, or click it and press Alt+Up or Alt+Down.")
    group:Note("Default: Tank > Melee > Ranged > Healer, classes in the game's class list order.")
end

ns.Window.Register("presets", function(page)
    local demo = page:Group("Demo and wizard")
    demo:Segmented({
        label = "Demo", options = DEMO,
        get = function() return ns.Demo.Mode() end,
        set = function(mode) ns.Demo.Set(mode) end,
        tooltip = "Sample members and cooldowns, so you can see the layout without a party. Out of combat only.",
    })
    demo:Button({
        text = "Layout wizard", width = 140,
        onClick = function() if ns.Wizard then ns.Wizard.Open() end end,
    })
    demo:Note("The wizard walks through a preset, the types and their order, then size and position.")
    presetCards(page)
    typesTable(page)
    priority(page)
end)
