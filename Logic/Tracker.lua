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

local function project(e, r, now)
    local step = r.chargeCd > 0 and r.chargeCd or r.cd
    local spent, start, gained = e.spent, e.start, 0
    while spent > 0 and start + step <= now do
        spent = spent - 1
        start = start + step
        gained = gained + 1
    end
    if spent == 0 then start = nil end
    return spent, start, gained, step
end

local function commit(e, spent, start)
    e.spent, e.start = spent, start
    if spent == 0 then e.maybe, e.useAt, e.prev = false, nil, nil end
end

function Tracker:Find(guid, spellId)
    local m = self.members[guid]
    local r = m and resolve(m, spellId)
    if not r then return end
    local byGuid = self.entries[guid]
    return byGuid and byGuid[spellId], r
end

function Tracker:Notify(list)
    if not self.OnChange then return end
    for _, c in ipairs(list) do self.OnChange(c[1], c[2]) end
end

local function sameUse(a, b)
    return a and b and math.abs(a - b) <= SAME_USE
end

function Tracker:Used(guid, spellId, certain)
    local m = self.members[guid]
    local r = m and resolve(m, spellId)
    if not r then return end
    local now = self.clock()
    local byGuid = self.entries[guid]
    if not byGuid then
        byGuid = {}
        self.entries[guid] = byGuid
    end
    local e = byGuid[spellId]
    if not e then
        e = { spent = 0 }
        byGuid[spellId] = e
    end
    local changes = {}
    if certain and e.spent > 0 and not e.maybe and sameUse(e.useAt, now) then
        -- same sighting reported twice
    else
        if certain and e.maybe and e.prev then
            e.spent, e.start = e.prev.spent, e.prev.start
        end
        local spent, start = project(e, r, now)
        e.prev = { spent = spent, start = start }
        if spent < r.charges then
            if spent == 0 then start = now end
            spent = spent + 1
        end
        commit(e, spent, start)
        e.maybe = not certain
        e.useAt = now
        changes[1] = { guid, spellId }
    end
    if certain then
        for other, list in pairs(self.entries) do
            local o = list[spellId]
            if other ~= guid and o and o.maybe and sameUse(o.useAt, e.useAt) then
                o.spent, o.start = o.prev.spent, o.prev.start
                o.maybe, o.useAt, o.prev = false, nil, nil
                changes[#changes + 1] = { other, spellId }
            end
        end
    end
    self:Notify(changes)
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
    self:Used(guid, spellId, true)
end

function Tracker:State(guid, spellId)
    local e, r = self:Find(guid, spellId)
    if not r then return end
    local spent, start, step = 0, nil, 0
    if e then spent, start, _, step = project(e, r, self.clock()) end
    local charges = math.max(0, r.charges - spent)
    return {
        ready = charges > 0,
        remaining = charges > 0 and 0 or math.max(0, start + step - self.clock()),
        charges = charges,
        maybe = e ~= nil and spent > 0 and e.maybe or false,
        talentsKnown = r.talentsKnown,
    }
end

function Tracker:Tick()
    local now = self.clock()
    local changes = {}
    for guid, byGuid in pairs(self.entries) do
        for spellId, e in pairs(byGuid) do
            local _, r = self:Find(guid, spellId)
            if r then
                local spent, start, gained = project(e, r, now)
                if gained > 0 then
                    commit(e, spent, start)
                    changes[#changes + 1] = { guid, spellId }
                end
            end
        end
    end
    self:Notify(changes)
end
