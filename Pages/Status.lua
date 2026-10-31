local _, ns = ...

local T = ns.Theme
local WHITE = T.text
local INTERVAL = 1

local roster = {}

local previous = ns.Group.OnRoster
ns.Group.OnRoster = function(list)
    previous(list)
    roster = list
end

local MODES = {
    plain = "plain - teammates' buffs are readable, their defensives and externals are tracked",
    secret = "secret - the game hides party buffs from addons right now",
    unavailable = "unavailable - party buffs are not read",
}

local function Colored(text, r, g, b)
    return ("|cff%02x%02x%02x%s|r"):format(r * 255, g * 255, b * 255, text)
end

local function SpellName(id)
    if id == "potion" then return "Potion" end
    return ns.Spells[id] and ns.Spells[id].name or tostring(id)
end

local function Names(list)
    if #list == 0 then return "none" end
    local out = {}
    for i, e in ipairs(list) do out[i] = e.name end
    return table.concat(out, ", ")
end

local function ModeText()
    local d = ns.Probe.Data()
    local lines = { "Group: " .. d.group .. (d.group == "party" and "" or " - Huddle works in a party only") }
    lines[2] = "Buff readout: " .. (MODES[d.mode] or d.mode)
    if d.reason then lines[3] = "Reason: " .. d.reason end
    if d.note then lines[#lines + 1] = d.note end
    return table.concat(lines, "\n")
end

local function Inspecting(guid)
    local s = ns.Inspect.state
    if s.inFlight and s.inFlight.guid == guid then return "inspect running" end
    if s.queue[guid] then return "inspect queued" end
    local tries = s.tries[guid] or 0
    if tries == 0 then return "inspect runs inside a dungeon" end
    return ("inspect gave up after %d tries"):format(tries)
end

local function Readout(unit)
    local stats = ns.Sensors.Stats()
    local s = stats[unit]
    if not s then return "buffs: not read" end
    local r = s.read
    return ("buffs: plain %d, secret %d, error %d - last seen: %s"):format(
        r["true"] + r["false"], r.secret, r.error, s.last and SpellName(s.last) or "none")
end

local function RaceName(race)
    if race == nil then return nil end
    local info = C_CreatureInfo.GetRaceInfo(race)
    if issecretvalue(info) or info == nil then return nil end
    local name = info.raceName
    if issecretvalue(name) then return nil end
    return name
end

local function MembersText()
    if ns.Group.Status() == "secret" then return "The party roster is secret right now." end
    if #roster == 0 then return "No party members. Huddle works in a party only." end
    local lines = {}
    for _, m in ipairs(roster) do
        local name = UnitName(m.unit)
        if issecretvalue(name) or name == nil then name = m.unit end
        local spec = ns.Specs[m.spec]
        local race = RaceName(m.race)
        local who = Colored(name, T.ClassColor(m.class)) .. " - " .. (race and (race .. " ") or "")
            .. T.ClassName(m.class) .. (spec and (" " .. spec.name) or "")
        local talents = "talents read: yes"
        if not m.talents then
            talents = m.unit == "player" and "talents read: no" or ("talents read: no (" .. Inspecting(m.guid) .. ")")
        end
        lines[#lines + 1] = who .. " - " .. talents
        lines[#lines + 1] = "    " .. (m.unit == "player" and "you: own casts are read directly" or Readout(m.unit))
    end
    return table.concat(lines, "\n")
end

local function OwnText()
    local own, kicks = ns.OwnCasts.Stats(), ns.Kicks.Stats()
    return ("Own casts tracked: %d, hidden by the game (secret): %d\nKicks attributed to a member: %d"):format(own.used, own.secret, kicks.attributed)
end

local function DebuffText()
    local s = ns.EnemyDebuffs.Status()
    return ("Hidden by the game (secret): %s\nNo debuff id, not trackable for others: %s"):format(Names(s.secret), Names(s.noId))
end

ns.Window.Register("status", function(page)
    page:Group("Party buff readout"):Note({ color = WHITE, text = ModeText })
    page:Group("Members"):Note({ color = WHITE, text = MembersText })
    page:Group("Own casts and kicks"):Note({ color = WHITE, text = OwnText })
    page:Group("Enemy stops and CC"):Note({ color = WHITE, text = DebuffText })
    local probe = page:Group("Probe")
    probe:Note("Prints the full readout, with hit-test counts and every buff id seen since login, to the chat window.")
    probe:Button({ text = "Run probe", width = 120, onClick = ns.Probe.Run })

    local elapsed = 0
    page.frame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < INTERVAL then return end
        elapsed = 0
        page:Refresh()
    end)
end)
