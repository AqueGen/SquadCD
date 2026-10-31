local _, ns = ...

local Picture = {}
ns.Picture = Picture

local T = ns.Theme
local ICON, GAP, PAD = 18, 2, 6
local FRAME_W, FRAME_H = 120, 30
local PANEL_LABEL_W, PANEL_ICONS, ROW_PER_TYPE, ROW_MAX = 96, 3, 2, 6
local SIDE_ROOM = ROW_MAX * (ICON + GAP) + 4
local ROW_AREA_W = 2 * SIDE_ROOM + FRAME_W
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local MEMBERS = { { "Frostwyn", "MAGE" }, { "Lumenia", "PRIEST" }, { "Aurik", "PALADIN" } }

local icons

local function Icons()
    if icons then return icons end
    icons = {}
    local ids = {}
    for id in pairs(ns.Spells) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local s = ns.Spells[id]
        icons[s.type] = icons[s.type] or {}
        if s.icon and s.icon ~= "inv_misc_questionmark" and #icons[s.type] < PANEL_ICONS then
            table.insert(icons[s.type], "Interface\\Icons\\" .. s.icon)
        end
    end
    local potion = C_Item.GetItemIconByID(ns.Potions[1].item)
    icons.Potion = { (issecretvalue(potion) or potion == nil) and QUESTION or potion }
    return icons
end

local function IconOf(t, i)
    local list = Icons()[t] or {}
    return list[(i - 1) % math.max(#list, 1) + 1] or QUESTION
end

function Picture.New(parent)
    local f = CreateFrame("Frame", nil, parent)
    local textures, texts = {}, {}
    local usedTex, usedText = 0, 0

    local function Tex()
        usedTex = usedTex + 1
        local t = textures[usedTex]
        if not t then
            t = f:CreateTexture(nil, "ARTWORK")
            textures[usedTex] = t
        end
        t:SetTexCoord(0, 1, 0, 1)
        t:ClearAllPoints()
        t:Show()
        return t
    end

    local function Text(color)
        usedText = usedText + 1
        local s = texts[usedText]
        if not s then
            s = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            s:SetJustifyH("LEFT")
            texts[usedText] = s
        end
        s:SetTextColor(unpack(color or T.muted))
        s:ClearAllPoints()
        s:Show()
        return s
    end

    local function Box(x, y, w, h, border)
        local edge = Tex()
        edge:SetColorTexture(unpack(border or T.border))
        edge:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
        edge:SetSize(w, h)
        local fill = Tex()
        fill:SetColorTexture(unpack(T.bg))
        fill:SetPoint("TOPLEFT", f, "TOPLEFT", x + 1, -y - 1)
        fill:SetSize(w - 2, h - 2)
    end

    local function Icon(t, i, x, y)
        local icon = Tex()
        icon:SetTexture(IconOf(t, i))
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
        icon:SetSize(ICON, ICON)
    end

    function f:Draw()
        for i = 1, usedTex do textures[i]:Hide() end
        for i = 1, usedText do texts[i]:Hide() end
        usedTex, usedText = 0, 0
        local db = ns.DB
        local rowTypes, panelTypes = {}, {}
        for _, t in ipairs(ns.LayoutRules.TYPES) do
            if db.placement[t] == "Row" then rowTypes[#rowTypes + 1] = t end
            if db.placement[t] == "Panel" then panelTypes[#panelTypes + 1] = t end
        end

        local caption = Text(T.gold)
        caption:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        caption:SetText("Party frames with their rows")
        local side = db.row.side
        local count = math.min(#rowTypes * ROW_PER_TYPE, db.row.max, ROW_MAX)
        local rowW = count * (ICON + GAP) - GAP
        local fx = SIDE_ROOM
        local vertical = side == "ABOVE" or side == "BELOW"
        local step = FRAME_H + GAP + (vertical and ICON + 4 or 0)
        local rowBottom = 20
        for i, member in ipairs(MEMBERS) do
            local fy = 20 + (i - 1) * step + (side == "ABOVE" and ICON + 4 or 0)
            Box(fx, fy, FRAME_W, FRAME_H)
            local name = Text({ T.ClassColor(member[2]) })
            name:SetPoint("LEFT", f, "TOPLEFT", fx + 8, -(fy + FRAME_H / 2))
            name:SetText(member[1])
            local x, y
            if side == "LEFT" then
                x, y = fx - 4 - rowW, fy + (FRAME_H - ICON) / 2
            elseif side == "RIGHT" then
                x, y = fx + FRAME_W + 4, fy + (FRAME_H - ICON) / 2
            elseif side == "ABOVE" then
                x, y = fx, fy - ICON - 4
            else
                x, y = fx, fy + FRAME_H + 4
            end
            for k = 1, count do
                local t = rowTypes[math.floor((k - 1) / ROW_PER_TYPE) + 1]
                Icon(t, (k - 1 + i) % ROW_PER_TYPE + 1, x + (k - 1) * (ICON + GAP), y)
            end
            rowBottom = 20 + i * step
        end
        if count == 0 then
            local none = Text()
            none:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(rowBottom + 2))
            none:SetText("No type is set to Row.")
            rowBottom = rowBottom + 16
        end

        local px = ROW_AREA_W + 24
        local title = Text(T.gold)
        title:SetPoint("TOPLEFT", f, "TOPLEFT", px, 0)
        title:SetText("Group panel")
        local panelH
        if #panelTypes == 0 then
            local none = Text()
            none:SetPoint("TOPLEFT", f, "TOPLEFT", px, -22)
            none:SetText("No type is set to Panel.")
            panelH = 40
        else
            local lineH = ICON + 4
            local w = PAD * 2 + PANEL_LABEL_W + PANEL_ICONS * (ICON + GAP) - GAP
            Box(px, 20, w, PAD * 2 + #panelTypes * lineH - 4, T.border)
            for i, t in ipairs(panelTypes) do
                local top = 20 + PAD + (i - 1) * lineH
                local label = Text()
                label:SetPoint("LEFT", f, "TOPLEFT", px + PAD, -(top + ICON / 2))
                label:SetText(ns.LayoutRules.LABELS[t])
                for k = 1, PANEL_ICONS do
                    Icon(t, k, px + PAD + PANEL_LABEL_W + (k - 1) * (ICON + GAP), top)
                end
            end
            panelH = 20 + PAD * 2 + #panelTypes * lineH
        end
        self.height = math.max(rowBottom, panelH)
        self:SetSize(px + PAD * 2 + PANEL_LABEL_W + PANEL_ICONS * (ICON + GAP), self.height)
    end

    return f
end
