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

    def test_buff_ids_unspecified_targets_count_as_self(self):
        # Metamorphosis 187827 in the real SpellEffect CSV: Effect 6, aura 226, targets 0/0
        self.assertEqual([187827], gen_data.buff_ids(187827, {187827: [row(6, t0=0, t1=0)]}, {}))

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
        }
        categories = {200: 4, 300: 30, 400: 4, 500: 4}
        cooldowns = {200: (0, 300000), 300: (0, 300000), 400: (0, 300000), 500: (0, 300000)}
        effects = {100: [row(6)], 200: [row(6)], 300: [row(6)], 400: [row(6)]}
        self.assertEqual(
            [{"item": 10, "buff": 100, "cd": 300}, {"item": 20, "buff": 200, "cd": 300}],
            gen_data.derive_potions([50, 40, 30, 20, 10], item_effects, categories, cooldowns, effects),
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

    def test_lua_writer_escapes_names(self):
        bs = chr(92)
        self.assertEqual('"Say ' + bs + '"hi' + bs + '"' + bs + bs + '"', gen_data.lua_str('Say "hi"' + bs))


if __name__ == "__main__":
    unittest.main()
