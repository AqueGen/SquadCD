import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_data


def row(effect, trigger=0, t0=1, t1=0):
    return (effect, t0, t1, trigger)


class GenDataTests(unittest.TestCase):
    def test_buff_ids_self_aura(self):
        self.assertEqual([871], gen_data.buff_ids(871, {871: [row(6)]}, {}))

    def test_buff_ids_trigger(self):
        effects = {1: [row(64, trigger=2, t0=0)], 2: [row(6)]}
        self.assertEqual([2], gen_data.buff_ids(1, effects, {}))

    def test_buff_ids_ignores_hostile_targets(self):
        self.assertEqual([], gen_data.buff_ids(5, {5: [row(6, t0=6)]}, {}))

    def test_buff_ids_area_aura_party(self):
        self.assertEqual([740], gen_data.buff_ids(740, {740: [row(35, t0=29)]}, {}))

    def test_debuff_ids_hostile_aura_on_the_spell(self):
        self.assertEqual([408], gen_data.debuff_ids(408, {408: [row(6, t0=6)]}, {}))

    def test_debuff_ids_ignores_friendly_aura(self):
        self.assertEqual([], gen_data.debuff_ids(5, {5: [row(6, t0=1)]}, {}))

    def test_debuff_ids_through_triggers_up_to_depth_two(self):
        effects = {1: [row(64, trigger=2, t0=0)], 2: [row(6, trigger=3, t0=1)], 3: [row(6, t0=22, t1=16)],
                   4: [row(64, trigger=5, t0=0)], 5: [row(64, trigger=6, t0=0)], 6: [row(64, trigger=7, t0=0)],
                   7: [row(6, t0=6)]}
        self.assertEqual([3], gen_data.debuff_ids(1, effects, {}))
        self.assertEqual([], gen_data.debuff_ids(4, effects, {}))

    def test_debuff_override_wins(self):
        self.assertEqual([9], gen_data.debuff_ids(408, {408: [row(6, t0=6)]}, {"408": [9]}))

    def test_unknown_debuff_override_key_raises(self):
        with self.assertRaisesRegex(ValueError, "debuffs override 999"):
            gen_data.check_overrides({"spells": [{"id": 871}]}, {"debuffs": {"999": [1]}})

    def test_spell_line_emits_debuffs_only_for_debuff_track(self):
        spell = {"id": 408, "name": "X", "icon": "i", "type": "Stun", "classId": 1, "specs": [],
                 "cdMs": 30000, "maxCharges": 0, "chargeMs": 0, "recoveryMs": 0, "talentGated": False,
                 "cdMods": {}, "cdPct": {}, "chargeMods": {}, "chargePct": {}, "specMods": {},
                 "chargeAdds": {}, "replaces": [], "races": [], "aoe": False}
        self.assertIn("debuffs={408,9},track=\"debuff\"", gen_data.spell_line(spell, "ROGUE", [], [408, 9]))
        spell["type"] = "Personal"
        self.assertNotIn("debuffs=", gen_data.spell_line(spell, "ROGUE", [], [408]))

    def test_spell_line_emits_buff_duration(self):
        spell = {"id": 48792, "name": "X", "icon": "i", "type": "Personal", "classId": 6, "specs": [],
                 "cdMs": 120000, "maxCharges": 0, "chargeMs": 0, "recoveryMs": 0, "talentGated": False,
                 "cdMods": {}, "cdPct": {}, "chargeMods": {}, "chargePct": {}, "specMods": {},
                 "chargeAdds": {}, "replaces": [], "races": [], "aoe": False}
        self.assertIn("buffs={48792},dur=8,track", gen_data.spell_line(spell, "DEATHKNIGHT", [48792], (), None, {48792: 8000}))
        self.assertNotIn("dur=", gen_data.spell_line(spell, "DEATHKNIGHT", [48792], (), None, {}))

    def test_same_name_buffs_adds_friendly_variants(self):
        effects = {
            48707: [(6, 1, 0, 0)],
            410358: [(6, 21, 0, 0)],
            444740: [(3, 92, 0, 0)],
            7121: [(6, 1, 0, 0)],
        }
        effects[31662] = [(6, 21, 0, 0)]
        names = {48707: "Anti-Magic Shell", 410358: "Anti-Magic Shell", 444740: "Anti-Magic Shell", 7121: "Anti-Magic Shield",
                 31662: "Anti-Magic Shell"}
        class_sets = {48707: 15, 410358: 15, 444740: 15, 31662: 0}
        self.assertEqual([48707, 410358], gen_data.same_name_buffs(48707, [48707], effects, names, class_sets))

    def test_load_durations_joins_misc_and_duration(self):
        import tempfile
        d = tempfile.mkdtemp()
        misc, dur = os.path.join(d, "m.csv"), os.path.join(d, "d.csv")
        with open(misc, "w", encoding="utf8") as f:
            f.write("ID,DifficultyID,DurationIndex,SpellID\n1,0,3,48792\n2,1,4,48792\n3,0,0,871\n")
        with open(dur, "w", encoding="utf8") as f:
            f.write("ID,Duration,MaxDuration,DurationPerResource\n3,8000,8000,0\n4,1,1,0\n")
        self.assertEqual({48792: 8000}, gen_data.load_durations(misc, dur))

    def test_render_starts_with_copyright(self):
        text = gen_data.render({"spells": [], "talentEntries": {}, "specs": {}, "classes": {}}, {}, {}, [])
        self.assertTrue(text.startswith("-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.\n"))

    def test_unknown_override_key_raises(self):
        catalog = {"spells": [{"id": 871}]}
        with self.assertRaisesRegex(ValueError, "999"):
            gen_data.check_overrides(catalog, {"buffs": {"999": [1]}})

    def test_derive_potions(self):
        def eff(spell, category=0, trigger=0, cd=-1, cat_cd=-1):
            return {"TriggerType": trigger, "SpellID": spell, "SpellCategoryID": category,
                    "CoolDownMSec": cd, "CategoryCoolDownMSec": cat_cd}

        item_effects = {
            20: [eff(200)],
            10: [eff(100, category=4, cat_cd=300000)],
            30: [eff(300)],
            40: [eff(400, trigger=1)],
            50: [eff(500)],
            60: [eff(600, category=4, cat_cd=300000)],
        }
        categories = {200: 4, 300: 30, 400: 4, 500: 4, 600: 37}
        cooldowns = {200: (0, 300000), 300: (0, 300000), 400: (0, 300000), 500: (0, 300000), 600: (0, 600000)}
        effects = {100: [row(6)], 200: [row(6)], 300: [row(6)], 400: [row(6)], 600: [row(6)]}
        self.assertEqual(
            [{"item": 10, "spell": 100, "buff": 100, "cd": 300}, {"item": 20, "spell": 200, "buff": 200, "cd": 300},
             {"item": 60, "spell": 600, "buff": 600, "cd": 300}],
            gen_data.derive_potions([60, 50, 40, 30, 20, 10], item_effects, categories, cooldowns, effects),
        )

    def test_override_wins(self):
        effects = {871: [row(6)]}
        self.assertEqual([99], gen_data.buff_ids(871, effects, {"871": [99]}))

    def test_track_kind_by_type(self):
        self.assertEqual("target", gen_data.track_kind("External", [1]))
        self.assertEqual("kick", gen_data.track_kind("Kick", []))
        self.assertEqual("debuff", gen_data.track_kind("Stun", [1]))
        self.assertEqual("debuff", gen_data.track_kind("CC", []))
        self.assertEqual("buff", gen_data.track_kind("Personal", [1]))
        self.assertEqual("none", gen_data.track_kind("Personal", []))

    def test_spell_line_emits_racial_classes_as_tokens(self):
        spell = {"id": 33702, "name": "Blood Fury", "icon": "i", "type": "Racial", "classId": None, "specs": [],
                 "cdMs": 120000, "maxCharges": 0, "chargeMs": 0, "recoveryMs": 0, "talentGated": False,
                 "cdMods": {}, "cdPct": {}, "chargeMods": {}, "chargePct": {}, "specMods": {},
                 "chargeAdds": {}, "replaces": [], "races": [2], "classes": [8, 9], "aoe": False}
        line = gen_data.spell_line(spell, None, [], (), {8: "MAGE", 9: "WARLOCK"})
        self.assertIn('races={2},classes={"MAGE","WARLOCK"}', line)
        del spell["classes"]
        self.assertNotIn("classes=", gen_data.spell_line(spell, None, [], (), {8: "MAGE"}))

    def test_spell_line_emits_charge_and_spec_modifiers(self):
        spell = {"id": 871, "name": "X", "icon": "i", "type": "Personal", "classId": 1, "specs": [],
                 "cdMs": 180000, "maxCharges": 1, "chargeMs": 180000, "recoveryMs": 8000,
                 "talentGated": True, "cdMods": {}, "cdPct": {"391271": -10},
                 "chargeMods": {"397103": -60000}, "chargePct": {"391271": -10},
                 "specMods": {"264": [137039]}, "chargeAdds": {}, "replaces": [], "races": [], "aoe": False}
        line = gen_data.spell_line(spell, "WARRIOR", [])
        self.assertIn("recovery=8,", line)
        self.assertIn("chargeMods={[397103]=-60}", line)
        self.assertIn("chargePct={[391271]=-10}", line)
        self.assertIn("specMods={[264]={137039}}", line)

    def test_lua_writer_escapes_names(self):
        bs = chr(92)
        self.assertEqual('"Say ' + bs + '"hi' + bs + '"' + bs + bs + '"', gen_data.lua_str('Say "hi"' + bs))


if __name__ == "__main__":
    unittest.main()
