local _, ns = ...

local Preview = {}
ns.Preview = Preview

local Model = ns.LayoutModel
local saved, showing

local function copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = copy(x) end
    return t
end

function Preview.Show(db, n)
    if not Model.Presets()[n] then return end
    saved = saved or db.layout
    db.layout = Model.Normalize(Model.ApplyPreset(copy(saved), n))
    showing = n
end

function Preview.Apply()
    saved, showing = nil, nil
end

function Preview.Cancel(db)
    if not saved then return false end
    db.layout = saved
    saved, showing = nil, nil
    return true
end

function Preview.Showing()
    return showing
end

function Preview.Saved()
    return saved
end
