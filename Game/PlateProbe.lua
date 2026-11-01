-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local PlateProbe = {}
ns.PlateProbe = PlateProbe

local PLATES, TICK, DIM = 20, 0.2, 0.15
local SIZE, GAP, COLUMNS, PAD, TITLE_H, BAR_H = 34, 4, 5, 10, 34, 26
local LIT = { 0.25, 0.87, 1 }

local frame, ticker
local probes, squares, alphas = {}, {}, {}

function PlateProbe.OwnIds(member)
    local ids, names, seen = {}, {}, {}
    for id, s in pairs(ns.Spells) do
        if (s.type == "Stun" or s.type == "CC") and s.debuffs
            and ns.Cooldowns.Has(id, member.class, member.spec, member.talents, member.race, member.pets) then
            names[#names + 1] = s.name
            for _, d in ipairs(s.debuffs) do
                if not seen[d] then
                    seen[d] = true
                    ids[#ids + 1] = d
                end
            end
        end
    end
    table.sort(ids)
    table.sort(names)
    return ids, names
end

local function build()
    local rows = math.ceil(PLATES / COLUMNS)
    frame = CreateFrame("Frame", "SquadCDPlateProbe", UIParent, "BackdropTemplate")
    frame:SetSize(PAD * 2 + COLUMNS * SIZE + (COLUMNS - 1) * GAP, TITLE_H + rows * (SIZE + GAP) + BAR_H + PAD)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    frame:SetBackdrop(ns.Theme.FLAT)
    frame:SetBackdropColor(0, 0, 0, 0.85)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.title:SetPoint("TOPLEFT", PAD, -PAD)
    frame.title:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    frame.title:SetJustifyH("LEFT")
    for i = 1, PLATES do
        local col, row = (i - 1) % COLUMNS, math.floor((i - 1) / COLUMNS)
        local sq = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        sq:SetSize(SIZE, SIZE)
        sq:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + col * (SIZE + GAP), -(TITLE_H + row * (SIZE + GAP)))
        sq:SetBackdrop(ns.Theme.FLAT)
        sq:SetBackdropColor(0.1, 0.1, 0.1, 1)
        sq.fill = sq:CreateTexture(nil, "ARTWORK")
        sq.fill:SetPoint("TOPLEFT", 1, -1)
        sq.fill:SetPoint("BOTTOMRIGHT", -1, 1)
        sq.fill:SetColorTexture(LIT[1], LIT[2], LIT[3], 1)
        sq.label = sq:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sq.label:SetPoint("CENTER")
        sq.label:SetText(i)
        squares[i] = sq
    end
    local repoint = ns.Widgets and ns.Widgets.Button(frame, "Re-point", 80) or CreateFrame("Button", nil, frame)
    repoint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)
    repoint:SetScript("OnClick", function() PlateProbe.Repoint() end)
    local close = ns.Widgets and ns.Widgets.Button(frame, "Close", 60) or CreateFrame("Button", nil, frame)
    close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    close:SetScript("OnClick", function() PlateProbe.Stop() end)
end

-- Lit is a secret boolean; only the engine curve turns it into the square's alpha.
local function tick()
    for i, p in ipairs(probes) do
        local sq = squares[i]
        local ok, lit = pcall(ns.Probes.Lit, p)
        if ok then
            alphas[i] = C_CurveUtil.EvaluateColorValueFromBoolean(lit, 1, DIM)
            if sq then sq.fill:SetAlpha(alphas[i]) end
        end
        if sq then
            local okExists, exists = pcall(UnitExists, "nameplate" .. i)
            local plain = okExists and not (issecretvalue and issecretvalue(exists))
            sq.label:SetTextColor(1, 1, 1, plain and not exists and 0.3 or 1)
        end
    end
end

function PlateProbe.Alphas()
    return alphas
end

function PlateProbe.Start(ids, caption)
    if not frame and not pcall(build) then
        if frame then frame:Hide() end
        frame, squares = nil, {}
    end
    for i = 1, PLATES do
        local unit = "nameplate" .. i
        if probes[i] then
            ns.Probes.Filter(probes[i], ids)
            ns.Probes.Point(probes[i], unit)
            ns.Probes.Enable(probes[i], true)
        else
            local p, why = ns.Probes.New(unit, "HARMFUL", ids)
            if not p then
                print("SquadCD plateprobe: " .. tostring(why))
                if frame then frame:Hide() end
                return false
            end
            probes[i] = p
        end
    end
    if frame then
        frame.title:SetText(caption or ("Plate probe: " .. table.concat(ids, ", ")))
        frame:Show()
    end
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(TICK, tick)
    return true
end

function PlateProbe.Repoint()
    for i, p in ipairs(probes) do ns.Probes.Point(p, "nameplate" .. i) end
end

function PlateProbe.Stop()
    if ticker then ticker:Cancel() end
    ticker = nil
    for _, p in ipairs(probes) do ns.Probes.Enable(p, false) end
    if frame then frame:Hide() end
end

local function ownMember()
    for _, m in ipairs((ns.Group.Members())) do
        if m.unit == "player" then return m end
    end
end

ns.Slash("plateprobe", function(rest)
    if rest == "off" then
        PlateProbe.Stop()
        print("SquadCD plateprobe: off")
        return
    end
    local id = tonumber(rest)
    if id then
        if not PlateProbe.Start({ id }, "Plate probe: debuff " .. id) then return end
        print("SquadCD plateprobe: watching debuff " .. id .. " on nameplate1-20")
        return
    end
    local me = ownMember()
    local ids, names = {}, {}
    if me then ids, names = PlateProbe.OwnIds(me) end
    if #ids == 0 then
        print("SquadCD plateprobe: no own stun or CC found; use /scd plateprobe <debuff spell id>")
        return
    end
    if not PlateProbe.Start(ids, "Plate probe: " .. table.concat(names, ", ")) then return end
    print("SquadCD plateprobe: watching " .. table.concat(names, ", ") .. " (" .. table.concat(ids, ", ") .. "); /scd plateprobe off to stop")
end)

-- One buff on one unit, for checking whether the engine sees a given aura id (some are hidden from the aura bar).
local aura = {}

function PlateProbe.Aura(unit, id)
    if aura.ticker then aura.ticker:Cancel() end
    if aura.probe then ns.Probes.Enable(aura.probe, false) end
    if not unit then
        if aura.frame then aura.frame:Hide() end
        return true
    end
    local p, why = ns.Probes.New(unit, "HELPFUL", { id })
    if not p then
        print("SquadCD auraprobe: " .. tostring(why))
        return false
    end
    aura.probe = p
    if not aura.frame then
        local f = CreateFrame("Frame", "SquadCDAuraProbe", UIParent, "BackdropTemplate")
        f:SetSize(220, 64)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 260)
        f:SetBackdrop(ns.Theme.FLAT)
        f:SetBackdropColor(0, 0, 0, 0.85)
        f.square = f:CreateTexture(nil, "ARTWORK")
        f.square:SetSize(40, 40)
        f.square:SetPoint("LEFT", 12, 0)
        f.square:SetColorTexture(LIT[1], LIT[2], LIT[3], 1)
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.text:SetPoint("LEFT", f.square, "RIGHT", 10, 0)
        f.text:SetPoint("RIGHT", -8, 0)
        f.text:SetJustifyH("LEFT")
        aura.frame = f
    end
    aura.frame.text:SetText(("%s on %s\n%s"):format(id, unit, C_Spell.GetSpellName(id) or ""))
    aura.frame:Show()
    aura.ticker = C_Timer.NewTicker(TICK, function()
        local ok, lit = pcall(ns.Probes.Lit, aura.probe)
        if ok then aura.frame.square:SetAlpha(C_CurveUtil.EvaluateColorValueFromBoolean(lit, 1, DIM)) end
    end)
    return true
end

ns.Slash("auraprobe", function(rest)
    if rest == "off" then
        PlateProbe.Aura(nil)
        return
    end
    local unit, id = (rest or ""):match("^(%S+)%s+(%d+)$")
    if not unit then
        print("SquadCD auraprobe: /scd auraprobe <unit> <spell id>, for example /scd auraprobe party1 188592; /scd auraprobe off")
        return
    end
    if PlateProbe.Aura(unit, tonumber(id)) then
        print(("SquadCD auraprobe: watching %s on %s; the square lights while the buff is on"):format(id, unit))
    end
end)
