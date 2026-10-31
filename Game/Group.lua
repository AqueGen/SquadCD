local _, ns = ...

local Group = {}
ns.Group = Group

local ROLES = { TANK = "Tank", HEALER = "Healer", DAMAGER = "Damage" }
local UNITS = { "player", "party1", "party2", "party3", "party4" }

function Group.OnRoster() end
function Group.OnRefresh() end

local guess = {}
for specId, s in pairs(ns.Specs) do
    if s.name ~= "Initial" then
        guess[s.class] = guess[s.class] or {}
        local byRole = guess[s.class]
        byRole[s.role] = byRole[s.role] == nil and specId or false
    end
end

function Group.GuessSpec(class, role)
    local byRole = guess[class]
    return byRole and byRole[ROLES[role]] or nil
end

local function plain(v)
    if not issecretvalue(v) then return v end
end

function Group.Mode()
    if plain(IsInRaid()) then return "raid" end
    if plain(IsInGroup()) then return "party" end
    return "solo"
end

local known = {}

local function own()
    local index = C_SpecializationInfo.GetSpecialization()
    local spec = not issecretvalue(index) and C_SpecializationInfo.GetSpecializationInfo(index)
    if issecretvalue(spec) or not ns.Specs[spec] then spec = nil end
    return { spec = spec, talents = ns.Inspect.ReadTalents(C_ClassTalents.GetActiveConfigID()) }
end

function Group.Members()
    local list, secret = {}, false
    for _, unit in ipairs(UNITS) do
        local guid = UnitGUID(unit)
        local _, class = UnitClass(unit)
        local role = UnitGroupRolesAssigned(unit)
        if issecretvalue(guid) or issecretvalue(class) or issecretvalue(role) then
            secret = true
        elseif guid and class then
            local k = unit == "player" and own() or known[guid]
            list[#list + 1] = {
                guid = guid,
                unit = unit,
                class = class,
                spec = k and k.spec or Group.GuessSpec(class, role),
                talents = k and k.talents,
            }
        end
    end
    return list, secret and "secret" or nil
end

local loaded = false
local frame = CreateFrame("Frame")
local PARTY_EVENTS = { "PLAYER_SPECIALIZATION_CHANGED", "TRAIT_CONFIG_UPDATED" }

function Group.Refresh()
    local party = Group.Mode() == "party"
    local list, why = {}, nil
    if party then list, why = Group.Members() end
    for _, event in ipairs(PARTY_EVENTS) do
        if party then frame:RegisterEvent(event) else frame:UnregisterEvent(event) end
    end
    ns.Inspect.SetActive(party)
    local present = {}
    for _, m in ipairs(list) do present[m.guid] = known[m.guid] end
    known = present
    ns.tracker:SetMembers(list)
    if not loaded and #list > 1 and not why then
        loaded = true
        ns.Persist.Load(ns.tracker)
    end
    Group.OnRoster(list)
    Group.OnRefresh()
    for _, m in ipairs(list) do
        if m.unit ~= "player" and not known[m.guid] then ns.Inspect.Queue(m.unit) end
    end
end

function ns.Inspect.OnResult(guid, spec, talents)
    known[guid] = { spec = spec, talents = talents }
    Group.Refresh()
end

frame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if issecretvalue(unit) then return end
        local guid = unit and UnitGUID(unit)
        if guid and not issecretvalue(guid) then known[guid] = nil end
    end
    Group.Refresh()
end)

function Group:Enable()
    ns.tracker = ns.Tracker.New(GetTime)
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
end

ns.RegisterModule("Group", Group)
