import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_data


def row(effect, trigger=0, t0=1, t1=0):
    return (effect, t0, t1, trigger)


def spell(**fields):
    base = {"id": 1, "name": "X", "icon": "i", "type": "Personal", "classId": 1, "specs": [],
            "cdMs": 60000, "maxCharges": 0, "chargeMs": 0, "recoveryMs": 0, "talentGated": False,
            "cdMods": {}, "cdPct": {}, "chargeMods": {}, "chargePct": {}, "specMods": {},
            "chargeAdds": {}, "replaces": [], "races": [], "aoe": False}
    base.update(fields)
    return base


class GenDataTests(unittest.TestCase):
    def test_potion_buff_ids_self_aura_and_trigger(self):
        self.assertEqual([871], gen_data.buff_ids(871, {871: [row(6)]}))
        self.assertEqual([2], gen_data.buff_ids(1, {1: [row(64, trigger=2, t0=0)], 2: [row(6)]}))
        self.assertEqual([], gen_data.buff_ids(5, {5: [row(6, t0=6)]}))

    def test_spell_line_takes_buffs_debuffs_and_duration_from_the_catalog(self):
        line = gen_data.spell_line(spell(id=48792, buffs=[48792, 444741], durMs=8000), "DEATHKNIGHT")
        self.assertIn("buffs={48792,444741},dur=8,track=\"buff\"", line)
        self.assertNotIn("dur=", gen_data.spell_line(spell(buffs=[1], durMs=0), "DEATHKNIGHT"))

    def test_spell_line_emits_debuffs_only_for_debuff_track(self):
        self.assertIn("debuffs={408,9},track=\"debuff\"", gen_data.spell_line(spell(id=408, type="Stun", debuffs=[408, 9]), "ROGUE"))
        self.assertNotIn("debuffs=", gen_data.spell_line(spell(debuffs=[408]), "ROGUE"))

    def test_render_copies_talent_entries_and_starts_with_copyright(self):
        catalog = {"spells": [spell(id=48707, classId=6, cdMods={"205727": -20000})], "talentEntries": {"96210": 48792},
                   "specs": {}, "classes": {"6": {"token": "DEATHKNIGHT"}}}
        text = gen_data.render(catalog, [])
        self.assertTrue(text.startswith("-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.\n"))
        self.assertIn("cdMods={[205727]=-20}", text)
        self.assertIn("ns.TalentEntries[96210]=48792", text)

    def test_derive_potions(self):
        def eff(spell_id, category=0, trigger=0, cd=-1, cat_cd=-1):
            return {"TriggerType": trigger, "SpellID": spell_id, "SpellCategoryID": category,
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

    def test_track_kind_by_type(self):
        self.assertEqual("target", gen_data.track_kind("External", [1]))
        self.assertEqual("kick", gen_data.track_kind("Kick", []))
        self.assertEqual("debuff", gen_data.track_kind("Stun", [1]))
        self.assertEqual("debuff", gen_data.track_kind("CC", []))
        self.assertEqual("buff", gen_data.track_kind("Personal", [1]))
        self.assertEqual("none", gen_data.track_kind("Personal", []))

    def test_spell_line_emits_racial_classes_as_tokens(self):
        racial = spell(id=33702, name="Blood Fury", type="Racial", classId=None, cdMs=120000, races=[2], classes=[8, 9])
        self.assertIn('races={2},classes={"MAGE","WARLOCK"}', gen_data.spell_line(racial, None, {8: "MAGE", 9: "WARLOCK"}))
        del racial["classes"]
        self.assertNotIn("classes=", gen_data.spell_line(racial, None, {8: "MAGE"}))

    def test_spell_line_emits_charge_and_spec_modifiers(self):
        line = gen_data.spell_line(spell(id=871, cdMs=180000, maxCharges=1, chargeMs=180000, recoveryMs=8000, talentGated=True,
                                         cdPct={"391271": -10}, chargeMods={"397103": -60000}, chargePct={"391271": -10},
                                         specMods={"264": [137039]}), "WARRIOR")
        self.assertIn("recovery=8,", line)
        self.assertIn("chargeMods={[397103]=-60}", line)
        self.assertIn("chargePct={[391271]=-10}", line)
        self.assertIn("specMods={[264]={137039}}", line)

    def test_lua_writer_escapes_names(self):
        bs = chr(92)
        self.assertEqual('"Say ' + bs + '"hi' + bs + '"' + bs + bs + '"', gen_data.lua_str('Say "hi"' + bs))


if __name__ == "__main__":
    unittest.main()
