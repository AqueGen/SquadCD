local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("LayoutRules", function()
    local ns = helpers.load({ "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/LayoutRules.lua" })
    local R = ns.LayoutRules
    local placement = ns.DEFAULTS.placement

    local function ids(list)
        local out = {}
        for _, s in ipairs(list) do out[#out + 1] = s.id end
        return out
    end

    it("split by placement", function()
        local spells = {
            { id = 1, type = "Personal" },
            { id = 2, type = "Kick" },
            { id = 3, type = "External" },
            { id = 4, type = "Kick" },
            { id = "potion", type = "Potion" },
        }
        local row, panel = R.Split(spells, placement)
        assert.are.same({ 1, "potion" }, ids(row))
        assert.are.same({ 2, 4 }, ids(panel.Kick))
        assert.are.same({ 3 }, ids(panel.External))
    end)

    it("off types dropped", function()
        local spells = { { id = 1, type = "Dispel" }, { id = 2, type = "Movement" }, { id = 3, type = "Unknown" } }
        local row, panel = R.Split(spells, placement)
        assert.are.same({}, row)
        assert.are.same({}, panel)
    end)

    it("order ready first", function()
        local states = {
            { key = "a", ready = false, remaining = 30, maybe = false },
            { key = "b", ready = true, remaining = 0, maybe = false },
            { key = "c", ready = false, remaining = 10, maybe = false },
            { key = "d", ready = true, remaining = 0, maybe = false },
        }
        local keys = {}
        for _, s in ipairs(R.Order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ "b", "d", "c", "a" }, keys)
    end)

    it("maybe after certain", function()
        local states = {
            { key = "maybe", ready = false, remaining = 5, maybe = true },
            { key = "sure", ready = false, remaining = 60, maybe = false },
            { key = "ready", ready = true, remaining = 0, maybe = false },
        }
        local keys = {}
        for _, s in ipairs(R.Order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ "ready", "sure", "maybe" }, keys)
    end)

    it("ready maybe after ready certain, before cooling", function()
        local states = {
            { key = "cool", ready = false, remaining = 3, maybe = false },
            { key = "readyMaybe", ready = true, remaining = 0, maybe = true },
            { key = "ready", ready = true, remaining = 0, maybe = false },
            { key = "coolMaybe", ready = false, remaining = 1, maybe = true },
        }
        local keys = {}
        for _, s in ipairs(R.Order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ "ready", "readyMaybe", "cool", "coolMaybe" }, keys)
    end)

    it("order ties keep input order", function()
        local states = {}
        for i = 1, 12 do states[i] = { key = i, ready = true, remaining = 0, maybe = false } end
        local keys = {}
        for _, s in ipairs(R.Order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, keys)
    end)

    it("order refills a given table", function()
        local a, b = { ready = false, remaining = 5 }, { ready = true, remaining = 0 }
        local out = { "stale", "stale", "stale" }
        assert.are.equal(out, R.Order({ a, b }, out))
        assert.are.same({ b, a }, out)
    end)

    it("order keeps input untouched", function()
        local states = { { key = "a", ready = false, remaining = 9 }, { key = "b", ready = true, remaining = 0 } }
        R.Order(states)
        assert.are.equal("a", states[1].key)
    end)

    describe("SpellsFor", function()
        local priest = { guid = "P", unit = "party1", class = "PRIEST", spec = 258, talents = nil }

        local function has(list, id)
            for _, s in ipairs(list) do
                if s.id == id then return s end
            end
        end

        it("lists class and race spells with their type and the potion", function()
            local orcPriest = { guid = "Q", unit = "party1", class = "PRIEST", spec = 258, race = 2 }
            local list = R.SpellsFor(orcPriest, false, {})
            local pot = has(list, "potion")
            assert.are.equal("Potion", pot.type)
            assert.is_not_nil(has(list, 20572))
            for _, s in ipairs(list) do
                if s.id ~= "potion" then
                    local spell = ns.Spells[s.id]
                    if spell.races then
                        assert.are.equal(2, spell.races[1])
                    else
                        assert.are.equal("PRIEST", spell.class)
                    end
                    assert.are.equal(ns.Spells[s.id].type, s.type)
                end
            end
        end)

        it("racials follow the race, one icon per name", function()
            local orc = { guid = "O", unit = "party2", class = "MAGE", spec = 64, race = 2 }
            local elf = { guid = "E", unit = "party3", class = "PRIEST", spec = 258, race = 10 }
            local function racials(m)
                local out = {}
                for _, s in ipairs(R.SpellsFor(m, true, {})) do
                    if s.type == "Racial" then out[#out + 1] = s end
                end
                return out
            end
            local o = racials(orc)
            assert.are.equal(1, #o)
            assert.are.equal("Blood Fury", o[1].name)
            assert.are.equal(20572, o[1].id)
            local e = racials(elf)
            assert.are.equal(1, #e)
            assert.are.equal("Arcane Torrent", e[1].name)
            assert.are.equal(0, #racials(priest))
        end)

        it("drops disabled spells", function()
            local list = R.SpellsFor(priest, false, { potion = false })
            assert.is_nil(has(list, "potion"))
        end)

        it("untracked spells only in own row", function()
            local id
            for spellId, s in pairs(ns.Spells) do
                if s.class == "PRIEST" and s.track == "none" and ns.Cooldowns.Has(spellId, "PRIEST", 258, nil) then
                    id = spellId
                    break
                end
            end
            assert.is_not_nil(id)
            assert.is_nil(has(R.SpellsFor(priest, false, {}), id))
            assert.is_not_nil(has(R.SpellsFor(priest, true, {}), id))
        end)

        it("orders by type then name", function()
            local list = R.SpellsFor(priest, true, {})
            for i = 2, #list do
                local a, b = list[i - 1], list[i]
                local ra, rb = R.TypeRank(a.type), R.TypeRank(b.type)
                assert.is_true(ra < rb or (ra == rb and a.name <= b.name))
            end
        end)
    end)

    it("formats remaining time", function()
        assert.are.equal("", R.FormatRemaining(0))
        assert.are.equal("9", R.FormatRemaining(8.2))
        assert.are.equal("59", R.FormatRemaining(59))
        assert.are.equal("1:20", R.FormatRemaining(80))
        assert.are.equal("2m", R.FormatRemaining(119.5))
        assert.are.equal("4m", R.FormatRemaining(230))
    end)

    it("short name keeps whole UTF-8 characters", function()
        assert.are.equal("Felk", R.ShortName("Felkasha", 4))
        assert.are.equal("Al", R.ShortName("Al", 4))
        assert.are.equal("Óðin", R.ShortName("Óðinn", 4))
    end)
end)
