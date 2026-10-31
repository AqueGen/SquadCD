-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("SecretTime", function()
    local T
    before_each(function()
        T = helpers.load({ "Logic/LayoutModel.lua", "Core.lua", "Logic/SecretTime.lua" }).SecretTime
    end)

    it("picks the time unit from cooldown and duration", function()
        assert.equal(2, T.Unit(120, 8))
        assert.equal(5, T.Unit(600, 0))
        assert.equal(1, T.Unit(30, 0))
    end)

    it("gives the write period", function()
        assert.equal(378, T.Period(120, 8, 2))
    end)

    it("codes time since the epoch", function()
        assert.equal(5 / 255, T.Code(110, 100, 2))
    end)

    it("maps a stamp to the remaining share", function()
        local lo, hi = T.Window(130, 0, 2, 120)
        assert.is_true(math.abs((50 / 255 - lo) / (hi - lo) - 0.75) < 1e-9)
    end)

    it("gates cooling against expired", function()
        local lo, hi = T.Gate(130, 0, 2, 120)
        assert.is_true(50 / 255 >= hi)
        assert.is_true(4 / 255 < lo)
    end)

    it("rolls to the other slot after the write period", function()
        local b = T.NewBase(1000, 120, 8)
        assert.is_nil(T.Roll(b, 1377))
        assert.equal(2, T.Roll(b, 1378))
        assert.equal(2, b.write)
        assert.equal(1378 - 130, b.slots[2].epoch)
    end)
end)
