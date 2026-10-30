import argparse
import csv
import json
import os
import urllib.request

WAGO_BUILD = "12.1.5.70575"
WAGO_URL = "https://wago.tools/db2/SpellEffect/csv?build=" + WAGO_BUILD
EFFECT_APPLY_AURA = 6
EFFECT_APPLY_AREA_AURA_PARTY = 35
EFFECT_TRIGGER_SPELL = 64
# SpellImplicitTarget ids that point at the caster, a pet, an ally or the party
FRIENDLY_TARGETS = {1, 5, 21, 25, 29, 30, 31, 57}
TRACK_BY_TYPE = {"External": "target", "Kick": "kick", "Stun": "debuff", "CC": "debuff"}


def load_effects(path):
    effects = {}
    with open(path, encoding="utf8", newline="") as f:
        for r in csv.DictReader(f):
            if r["DifficultyID"] != "0" or int(r["Effect"]) not in (
                EFFECT_APPLY_AURA, EFFECT_APPLY_AREA_AURA_PARTY, EFFECT_TRIGGER_SPELL
            ):
                continue
            effects.setdefault(int(r["SpellID"]), []).append(
                (int(r["Effect"]), int(r["ImplicitTarget_0"]), int(r["ImplicitTarget_1"]), int(r["EffectTriggerSpell"]))
            )
    return effects


def applies_friendly_aura(spell_id, effects):
    for effect, t0, t1, _ in effects.get(spell_id, []):
        if effect in (EFFECT_APPLY_AURA, EFFECT_APPLY_AREA_AURA_PARTY):
            if t0 in FRIENDLY_TARGETS or t1 in FRIENDLY_TARGETS or (t0 == 0 and t1 == 0):
                return True
    return False


def buff_ids(spell_id, effects, buff_overrides):
    if str(spell_id) in buff_overrides:
        return list(buff_overrides[str(spell_id)])
    ids = []
    if applies_friendly_aura(spell_id, effects):
        ids.append(spell_id)
    for effect, _, _, trigger in effects.get(spell_id, []):
        if effect == EFFECT_TRIGGER_SPELL and trigger and trigger not in ids and applies_friendly_aura(trigger, effects):
            ids.append(trigger)
    return ids


def track_kind(spell_type, buffs):
    if spell_type in TRACK_BY_TYPE:
        return TRACK_BY_TYPE[spell_type]
    return "buff" if buffs else "none"


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def num(v):
    return str(int(v)) if v == int(v) else repr(v)


def seconds(ms):
    return num(ms / 1000)


def lua_list(values):
    return "{" + ",".join(values) + "}"


def lua_map(mapping, conv):
    return "{" + ",".join("[%s]=%s" % (k, conv(v)) for k, v in sorted(mapping.items(), key=lambda kv: int(kv[0]))) + "}"


def spell_line(spell, token, buffs):
    fields = [
        "name=" + lua_str(spell["name"]),
        "icon=" + lua_str(spell["icon"]),
        "type=" + lua_str(spell["type"]),
    ]
    if token:
        fields.append("class=" + lua_str(token))
    fields.append("specs=" + lua_list(str(s) for s in spell["specs"]))
    fields.append("cd=" + seconds(spell["cdMs"]))
    if spell["maxCharges"]:
        fields.append("charges=%d" % spell["maxCharges"])
    if spell["chargeMs"]:
        fields.append("chargeCd=" + seconds(spell["chargeMs"]))
    if spell["talentGated"]:
        fields.append("talentGated=true")
    if spell["cdMods"]:
        fields.append("cdMods=" + lua_map(spell["cdMods"], seconds))
    if spell["cdPct"]:
        fields.append("cdPct=" + lua_map(spell["cdPct"], num))
    if spell["chargeAdds"]:
        fields.append("chargeAdds=" + lua_map(spell["chargeAdds"], num))
    if spell["replaces"]:
        fields.append("replaces=" + lua_list(str(s) for s in spell["replaces"]))
    if spell["races"]:
        fields.append("races=" + lua_list(str(s) for s in spell["races"]))
    if spell["aoe"]:
        fields.append("aoe=true")
    if buffs:
        fields.append("buffs=" + lua_list(str(b) for b in buffs))
    fields.append("track=" + lua_str(track_kind(spell["type"], buffs)))
    return "ns.Spells[%d]={%s}" % (spell["id"], ",".join(fields))


def render(catalog, effects, overrides):
    tokens = {int(k): v["token"] for k, v in catalog["classes"].items()}
    buff_overrides = overrides.get("buffs", {})
    out = ["local _, ns = ...", "ns.Spells = {}", "ns.TalentEntries = {}", "ns.Specs = {}", "ns.Classes = {}"]
    for spell in sorted(catalog["spells"], key=lambda s: s["id"]):
        token = tokens.get(spell["classId"])
        out.append(spell_line(spell, token, buff_ids(spell["id"], effects, buff_overrides)))
    for entry, talent in sorted(catalog["talentEntries"].items(), key=lambda kv: int(kv[0])):
        out.append("ns.TalentEntries[%s]=%d" % (entry, talent))
    for spec_id, spec in sorted(catalog["specs"].items(), key=lambda kv: int(kv[0])):
        out.append("ns.Specs[%s]={class=%s,role=%s,name=%s}" % (
            spec_id, lua_str(tokens[spec["classId"]]), lua_str(spec["role"]), lua_str(spec["name"])))
    for class_id, token in sorted(tokens.items()):
        out.append("ns.Classes[%d]=%s" % (class_id, lua_str(token)))
    potions = ",".join("{buff=%d,cd=%s}" % (p["buff"], num(p["cd"])) for p in overrides.get("potions", []))
    out.append("ns.Potions={%s}" % potions)
    return "\n".join(out) + "\n"


def fetch_effects(cache_dir):
    os.makedirs(cache_dir, exist_ok=True)
    path = os.path.join(cache_dir, "SpellEffect-%s.csv" % WAGO_BUILD)
    if not os.path.exists(path):
        req = urllib.request.Request(WAGO_URL, headers={"User-Agent": "Huddle-gen/1.0"})
        with urllib.request.urlopen(req, timeout=600) as resp, open(path, "wb") as f:
            f.write(resp.read())
    return path


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument("--catalog", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cache", default="F:/claude-data/huddle-docs/cache")
    ap.add_argument("--overrides", default=os.path.join(here, "overrides.json"))
    args = ap.parse_args()
    with open(args.catalog, encoding="utf8") as f:
        catalog = json.load(f)
    with open(args.overrides, encoding="utf8") as f:
        overrides = json.load(f)
    text = render(catalog, load_effects(fetch_effects(args.cache)), overrides)
    with open(args.out, "w", encoding="utf8", newline="\n") as f:
        f.write(text)


if __name__ == "__main__":
    main()
