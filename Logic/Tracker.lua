local _, ns = ...

local Tracker = {}
Tracker.__index = Tracker
ns.Tracker = Tracker

local SAME_USE = 1

local function resolve(member, spellId)
    if spellId == "potion" then
        return { cd = ns.Potions[1].cd, charges = 1, chargeCd = 0, talentsKnown = true }
    end
    return ns.Cooldowns.Resolve(spellId, member.spec, member.talents)
end

function Tracker.New(clock)
    return setmetatable({ clock = clock, members = {}, order = {}, entries = {} }, Tracker)
end

function Tracker:SetMembers(list)
    self.members, self.order = {}, {}
    for _, m in ipairs(list) do
        self.members[m.guid] = m
        self.order[#self.order + 1] = m.guid
    end
    for guid in pairs(self.entries) do
        if not self.members[guid] then self.entries[guid] = nil end
    end
end

-- Moves the entry to `now`, returns how many charges came back.
local function advance(e, r, now)
    local step = r.chargeCd > 0 and r.chargeCd or r.cd
    local gained = 0
    while e.start and e.charges < r.charges and e.start + step <= now do
        e.charges = e.charges + 1
        e.start = e.start + step
        gained = gained + 1
    end
    if e.charges >= r.charges then
        e.charges, e.start = r.charges, nil
    end
    return gained, step
end

function Tracker:Entry(guid, spellId)
    local m = self.members[guid]
    if not m then return end
    local r = resolve(m, spellId)
    if not r then return end
    local byGuid = self.entries[guid]
    if not byGuid then
        byGuid = {}
        self.entries[guid] = byGuid
    end
    local e = byGuid[spellId]
    if not e then
        e = { charges = r.charges }
        byGuid[spellId] = e
    end
    return e, r
end

function Tracker:Notify(guid, spellId)
    if self.OnChange then self.OnChange(guid, spellId) end
end

function Tracker:Used(guid, spellId, certain)
    local e, r = self:Entry(guid, spellId)
    if not e then return end
    local now = self.clock()
    advance(e, r, now)
    e.prev = { charges = e.charges, start = e.start }
    if e.charges > 0 then
        if not e.start then e.start = now end
        e.charges = e.charges - 1
    end
    e.maybe = not certain
    e.useAt = now
    self:Notify(guid, spellId)
end

function Tracker:External(spellId, targetGuid)
    local candidates = {}
    for _, guid in ipairs(self.order) do
        local m = self.members[guid]
        if guid ~= targetGuid and ns.Cooldowns.Has(spellId, m.class, m.spec, m.talents) then
            candidates[#candidates + 1] = guid
        end
    end
    local certain = #candidates == 1
    for _, guid in ipairs(candidates) do
        self:Used(guid, spellId, certain)
    end
end

function Tracker:Confirm(guid, spellId)
    local now = self.clock()
    local own = self.entries[guid] and self.entries[guid][spellId]
    if own and own.useAt and now - own.useAt <= SAME_USE then
        own.maybe = false
    else
        self:Used(guid, spellId, true)
    end
    for other, byGuid in pairs(self.entries) do
        local e = byGuid[spellId]
        if other ~= guid and e and e.maybe and e.useAt and math.abs(now - e.useAt) <= SAME_USE then
            e.charges, e.start = e.prev.charges, e.prev.start
            e.maybe, e.useAt, e.prev = false, nil, nil
            self:Notify(other, spellId)
        end
    end
end

function Tracker:State(guid, spellId)
    local e, r = self:Entry(guid, spellId)
    if not e then return end
    local now = self.clock()
    local _, step = advance(e, r, now)
    return {
        ready = e.charges > 0,
        remaining = e.charges > 0 and 0 or math.max(0, e.start + step - now),
        charges = e.charges,
        maybe = e.maybe or false,
        talentsKnown = r.talentsKnown,
    }
end

function Tracker:Tick()
    local now = self.clock()
    for guid, byGuid in pairs(self.entries) do
        for spellId, e in pairs(byGuid) do
            local r = resolve(self.members[guid], spellId)
            if r and advance(e, r, now) > 0 then
                self:Notify(guid, spellId)
            end
        end
    end
end
