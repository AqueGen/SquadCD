local here = debug.getinfo(1, "S").source:match("^@(.*)[/\\][^/\\]*$") or "tests"
local helpers = dofile(here .. "/helpers.lua")

describe("LayoutRules", function()
    local ns = helpers.load({ "Logic/LayoutModel.lua", "Core.lua", "Data.lua", "Logic/Cooldowns.lua", "Logic/Tracker.lua", "Logic/LayoutGrid.lua", "Logic/LayoutRules.lua" })
    local R = ns.LayoutRules

    local function ids(list)
        local out = {}
        for _, s in ipairs(list) do out[#out + 1] = s.id end
        return out
    end

    local function order(states, out)
        return ns.LayoutGrid.Sort(states, { sort = "ReadyFirst" }, nil, out)
    end

    describe("Route", function()
        local m1, m2 = { guid = "A" }, { guid = "B" }
        local function spell(id, type) return { id = id, type = type, name = tostring(id) } end
        local function input()
            return {
                { member = m1, own = true, spells = {
                    spell(1, "Personal"), spell(2, "Kick"), spell(3, "Stun"), spell(4, "CC"), spell(5, "External"), spell(6, "Dispel"),
                } },
                { member = m2, own = false, spells = { spell(7, "Kick") } },
            }
        end
        local function lineIds(line)
            local out = {}
            for _, e in ipairs(line.entries) do out[#out + 1] = e.spell.id end
            return out
        end

        it("panel types make one line per type in section order, others go to member groups, off types drop", function()
            local layout = ns.LayoutModel.Defaults()
            local lines, rows = R.Route(layout, input())
            local types = {}
            for i, l in ipairs(lines) do types[i] = l.type end
            assert.are.same({ "Kick", "Control", "External" }, types)
            assert.are.same({ 2, 7 }, lineIds(lines[1]))
            assert.are.same({ 3, 4 }, lineIds(lines[2]))
            assert.are.equal(layout.sections[2], lines[2].section)
            assert.are.equal(m2, lines[1].entries[2].member)
            assert.is_false(lines[1].entries[2].own)
            assert.are.equal(1, #rows[1].groups[1])
            assert.are.equal("Personal", rows[1].groups[1][1].type)
            assert.are.same({ 1 }, ids(rows[1].groups[1][1].spells))
            assert.are.same({}, rows[2].groups[1])
            assert.are.equal(m2, rows[2].member)
        end)

        it("split shows stun and CC on lines of their own", function()
            local layout = ns.LayoutModel.SetSplit(ns.LayoutModel.Defaults(), true)
            local lines = R.Route(layout, input())
            assert.are.same({ "Stun", "CC" }, { lines[2].type, lines[3].type })
        end)

        it("hidden sections and groups show nothing", function()
            local layout = ns.LayoutModel.Defaults()
            layout.sections[1].shown, layout.groups[1].shown = false, false
            local lines, rows = R.Route(layout, input())
            assert.are.equal("Control", lines[1].type)
            assert.is_nil(rows[1].groups[1])
        end)

        it("runs follow the group type order", function()
            local layout = ns.LayoutModel.Defaults()
            ns.LayoutModel.SetPlace(layout, "External", "member")
            layout.groups[1].shape.typeOrder = { "External", "Personal" }
            local _, rows = R.Route(layout, input())
            assert.are.same({ "External", "Personal" }, { rows[1].groups[1][1].type, rows[1].groups[1][2].type })
        end)
    end)

    it("order ready first", function()
        local states = {
            { key = "a", ready = false, remaining = 30, maybe = false },
            { key = "b", ready = true, remaining = 0, maybe = false },
            { key = "c", ready = false, remaining = 10, maybe = false },
            { key = "d", ready = true, remaining = 0, maybe = false },
        }
        local keys = {}
        for _, s in ipairs(order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ "b", "d", "c", "a" }, keys)
    end)

    it("maybe after certain", function()
        local states = {
            { key = "maybe", ready = false, remaining = 5, maybe = true },
            { key = "sure", ready = false, remaining = 60, maybe = false },
            { key = "ready", ready = true, remaining = 0, maybe = false },
        }
        local keys = {}
        for _, s in ipairs(order(states)) do keys[#keys + 1] = s.key end
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
        for _, s in ipairs(order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ "ready", "readyMaybe", "cool", "coolMaybe" }, keys)
    end)

    it("ready unknown after ready known, before cooling", function()
        local states = {
            { key = "cool", ready = false, remaining = 3 },
            { key = "unknown", ready = true, remaining = 0, unknown = true },
            { key = "ready", ready = true, remaining = 0 },
        }
        local keys = {}
        for _, s in ipairs(order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ "ready", "unknown", "cool" }, keys)
    end)

    describe("Unknown", function()
        local SHIELD_WALL, PAIN_SUPPRESSION, LAY_ON_HANDS, KIDNEY_SHOT, RING_OF_PEACE, KICK = 871, 33206, 471195, 408, 116844, 6552
        local none = {}

        it("own icons are never unknown", function()
            assert.is_false(R.Unknown(SHIELD_WALL, true, false, none))
            assert.is_false(R.Unknown(RING_OF_PEACE, true, true, none))
        end)

        it("party buff, target and potion icons are unknown unless sensors are plain", function()
            assert.is_true(R.Unknown(SHIELD_WALL, false, false, none))
            assert.is_true(R.Unknown(PAIN_SUPPRESSION, false, false, none))
            assert.is_true(R.Unknown("potion", false, false, none))
            assert.is_false(R.Unknown(SHIELD_WALL, false, true, none))
            assert.is_false(R.Unknown(PAIN_SUPPRESSION, false, true, none))
            assert.is_false(R.Unknown("potion", false, true, none))
        end)

        it("target spell with no buff id is unknown even in plain mode", function()
            assert.is_true(R.Unknown(LAY_ON_HANDS, false, true, none))
        end)

        it("stun or CC is unknown with no debuff id or a secret readout", function()
            assert.is_false(R.Unknown(KIDNEY_SHOT, false, false, none))
            assert.is_true(R.Unknown(KIDNEY_SHOT, false, true, { [408] = true }))
            assert.is_true(R.Unknown(RING_OF_PEACE, false, true, none))
        end)

        it("kicks are not affected", function()
            assert.is_false(R.Unknown(KICK, false, false, none))
        end)
    end)

    it("order ties keep input order", function()
        local states = {}
        for i = 1, 12 do states[i] = { key = i, ready = true, remaining = 0, maybe = false } end
        local keys = {}
        for _, s in ipairs(order(states)) do keys[#keys + 1] = s.key end
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }, keys)
    end)

    it("order refills a given table", function()
        local a, b = { ready = false, remaining = 5 }, { ready = true, remaining = 0 }
        local out = { "stale", "stale", "stale" }
        assert.are.equal(out, order({ a, b }, out))
        assert.are.same({ b, a }, out)
    end)

    it("order keeps input untouched", function()
        local states = { { key = "a", ready = false, remaining = 9 }, { key = "b", ready = true, remaining = 0 } }
        order(states)
        assert.are.equal("a", states[1].key)
    end)

    describe("SpellsFor", function()
        local priest = { guid = "P", unit = "party1", class = "PRIEST", spec = 258, talents = nil }

        local function has(list, id)
            for _, s in ipairs(list) do
                if s.id == id then return s end
            end
        end

        it("Lay on Hands shows once, as the replacer, with talents known or unknown", function()
            for _, talents in ipairs({ { [633] = 1 }, false }) do
                local paladin = { guid = "H", unit = "party1", class = "PALADIN", spec = 65, talents = talents or nil }
                local list = R.SpellsFor(paladin, false, {})
                assert.is_not_nil(has(list, 471195))
                assert.is_nil(has(list, 633))
            end
        end)

        it("talent-gated replacer shows only when the member has it", function()
            local base, replacer = 207684, 202137
            local function dh(talents) return { guid = "D", unit = "party1", class = "DEMONHUNTER", spec = 581, talents = talents } end
            local list = R.SpellsFor(dh({ [replacer] = 1 }), false, {})
            assert.is_not_nil(has(list, replacer))
            assert.is_nil(has(list, base))
            list = R.SpellsFor(dh({ [base] = 1 }), false, {})
            assert.is_not_nil(has(list, base))
            assert.is_nil(has(list, replacer))
            list = R.SpellsFor(dh(nil), false, {})
            assert.is_not_nil(has(list, base))
            assert.is_nil(has(list, replacer))
        end)

        it("lists class and race spells with their type and the potion", function()
            local orcPriest = { guid = "Q", unit = "party1", class = "PRIEST", spec = 258, race = 2 }
            local list = R.SpellsFor(orcPriest, false, {})
            local pot = has(list, "potion")
            assert.are.equal("Potion", pot.type)
            assert.is_not_nil(has(list, 33702))
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
            assert.are.equal(33702, o[1].id)
            local e = racials(elf)
            assert.are.equal(1, #e)
            assert.are.equal("Arcane Torrent", e[1].name)
            assert.are.equal(0, #racials(priest))
        end)

        it("cast of a racial variant lands on the shown icon", function()
            local orc = { guid = "O", unit = "party2", class = "MAGE", spec = 64, race = 2 }
            local t = ns.Tracker.New(function() return 100 end)
            t:SetMembers({ orc })
            local shown = has(R.SpellsFor(orc, false, {}), 33702)
            assert.is_not_nil(shown)
            t:Used("O", 33702, true)
            assert.is_false(t:State("O", shown.id).ready)
        end)

        it("non-lowest variant without a class list maps to the lowest", function()
            ns.Spells[-3] = { name = "Test Racial", type = "Racial", specs = {}, cd = 60, races = { 2 }, track = "buff" }
            ns.Spells[-2] = { name = "Test Racial", type = "Racial", specs = {}, cd = 60, races = { 2 }, track = "buff" }
            local orc = { guid = "O", unit = "party2", class = "MAGE", spec = 64, race = 2 }
            local list = R.SpellsFor(orc, false, {})
            assert.is_not_nil(has(list, -3))
            assert.is_nil(has(list, -2))
            assert.are.equal(-3, ns.Cooldowns.Canonical(-2, orc))
            local t = ns.Tracker.New(function() return 100 end)
            t:SetMembers({ orc })
            t:Used("O", -2, true)
            assert.is_false(t:State("O", -3).ready)
            assert.is_true(t:UsedWithin("O", -2, 1))
            ns.Spells[-3], ns.Spells[-2] = nil, nil
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

    describe("Catalog", function()
        it("class tab lists only that class, by type then name", function()
            local list = R.Catalog("ROGUE")
            assert.is_true(#list > 0)
            for i, e in ipairs(list) do
                assert.are.equal("ROGUE", ns.Spells[e.id].class)
                if i > 1 then
                    local a, b = list[i - 1], e
                    local ra, rb = R.TypeRank(a.type), R.TypeRank(b.type)
                    assert.is_true(ra < rb or (ra == rb and a.name <= b.name))
                end
            end
        end)

        it("all lists every spell", function()
            local n = 0
            for _ in pairs(ns.Spells) do n = n + 1 end
            assert.are.equal(n, #R.Catalog(nil))
        end)

        it("flags spells nobody else can see", function()
            local byId = {}
            for _, e in ipairs(R.Catalog(nil)) do byId[e.id] = e end
            assert.is_true(byId[475].untrackable)
            assert.is_false(byId[408].untrackable)
            assert.is_false(byId[498].untrackable)
            assert.are.equal(30, byId[408].cd)
        end)

        it("flags a debuff spell with no debuff ids", function()
            ns.Spells[999001] = { name = "Fake", type = "CC", class = "ROGUE", specs = {}, cd = 10, track = "debuff" }
            local found
            for _, e in ipairs(R.Catalog("ROGUE")) do
                if e.id == 999001 then found = e end
            end
            ns.Spells[999001] = nil
            assert.is_true(found.untrackable)
        end)
    end)
end)
