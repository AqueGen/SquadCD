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
