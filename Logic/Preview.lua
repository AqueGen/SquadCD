-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local Model = ns.LayoutModel

local copy = ns.Copy

local function new()
    local Preview = {}
    local saved, showing

    function Preview.Show(db, n)
        if not Model.Presets()[n] then return end
        saved = saved or db.layout
        db.layout = Model.Normalize(Model.ApplyPreset(copy(saved), n))
        showing = n
    end

    function Preview.Hold(db)
        if saved then return end
        saved = db.layout
        db.layout = copy(saved)
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

    return Preview
end

ns.Preview = new()
ns.Preview.New = new
