-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Model = ns.LayoutModel
local copy = ns.Copy

local Profiles = {}
ns.Profiles = Profiles

local DEFAULT = "Default"
Profiles.DEFAULT = DEFAULT

-- db.layout and db.row stay the live copy of the active profile; the profile entry is refreshed when we leave it.
function Profiles.Init(db)
    db.profiles = db.profiles or {}
    db.specProfiles = db.specProfiles or {}
    db.profiles[DEFAULT] = db.profiles[DEFAULT] or {}
    if not db.profile or not db.profiles[db.profile] then db.profile = DEFAULT end
end

local function store(db)
    db.profiles[db.profile] = { layout = db.layout, row = db.row }
end

local function load(db, name)
    local p = db.profiles[name]
    db.layout = Model.Normalize(p.layout or copy(db.layout))
    db.row = p.row or copy(db.row)
    db.profile = name
end

function Profiles.Switch(db, name)
    if name == db.profile or not db.profiles[name] then return false end
    store(db)
    load(db, name)
    return true
end

local function valid(name)
    return type(name) == "string" and name:match("%S") ~= nil
end

function Profiles.New(db, name)
    if not valid(name) or db.profiles[name] then return false end
    store(db)
    db.profiles[name] = { layout = copy(db.layout), row = copy(db.row) }
    load(db, name)
    return true
end

function Profiles.Rename(db, old, new)
    if old == DEFAULT or not db.profiles[old] or not valid(new) or db.profiles[new] then return false end
    db.profiles[new], db.profiles[old] = db.profiles[old], nil
    for key, name in pairs(db.specProfiles) do
        if name == old then db.specProfiles[key] = new end
    end
    if db.profile == old then db.profile = new end
    return true
end

function Profiles.Delete(db, name)
    if name == DEFAULT or not db.profiles[name] then return false end
    db.profiles[name] = nil
    for key, assigned in pairs(db.specProfiles) do
        if assigned == name then db.specProfiles[key] = nil end
    end
    if db.profile == name then load(db, DEFAULT) end
    return true
end

function Profiles.Names(db)
    local names = {}
    for name in pairs(db.profiles) do
        if name ~= DEFAULT then names[#names + 1] = name end
    end
    table.sort(names)
    table.insert(names, 1, DEFAULT)
    return names
end

function Profiles.Key(character, specId)
    return character .. ":" .. tostring(specId)
end

function Profiles.Assign(db, key, name)
    if name ~= nil and not db.profiles[name] then return false end
    db.specProfiles[key] = name
    return true
end

function Profiles.ForSpec(db, key)
    local name = db.specProfiles[key]
    return name and db.profiles[name] and name or DEFAULT
end

-- SavedVariables would write the live layout twice (db.layout and the profile entry).
function Profiles.Pack(db)
    db.profiles[db.profile] = {}
end
