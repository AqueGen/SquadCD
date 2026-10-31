import argparse
import csv
import json
import os
import urllib.request

WAGO_BUILD = "12.1.5.70575"
WAGO_URL = "https://wago.tools/db2/%s/csv?build=" + WAGO_BUILD
EFFECT_APPLY_AURA = 6
EFFECT_APPLY_AREA_AURA_PARTY = 35
EFFECT_TRIGGER_SPELL = 64
ON_USE = 0
COMBAT_POTION_CATEGORY = 4
ITEM_CLASS_CONSUMABLE = "0"
ITEM_SUBCLASS_POTION = "1"
FRIENDLY_TARGETS = {1, 5, 21, 25, 29, 30, 31, 57}
HOSTILE_TARGETS = {6, 15, 16, 24, 104}
TRIGGER_DEPTH = 2
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
            if t0 in FRIENDLY_TARGETS or t1 in FRIENDLY_TARGETS:
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


def applies_hostile_aura(spell_id, effects):
    for effect, t0, t1, _ in effects.get(spell_id, []):
        if effect == EFFECT_APPLY_AURA and (t0 in HOSTILE_TARGETS or t1 in HOSTILE_TARGETS):
            return True
    return False


def debuff_ids(spell_id, effects, debuff_overrides):
    if str(spell_id) in debuff_overrides:
        return list(debuff_overrides[str(spell_id)])
    ids = []
    level = [spell_id]
    for _ in range(TRIGGER_DEPTH + 1):
        nxt = []
        for sid in level:
            if sid not in ids and applies_hostile_aura(sid, effects):
                ids.append(sid)
            for effect, _, _, trigger in effects.get(sid, []):
                if trigger:
                    nxt.append(trigger)
        level = nxt
    return ids


def track_kind(spell_type, buffs):
    if spell_type in TRACK_BY_TYPE:
        return TRACK_BY_TYPE[spell_type]
    return "buff" if buffs else "none"


def derive_potions(items, item_effects, spell_categories, spell_cooldowns, effects):
    potions = []
    for item in sorted(items):
        for eff in item_effects.get(item, []):
            spell = eff["SpellID"]
            if eff["TriggerType"] != ON_USE:
                continue
            if COMBAT_POTION_CATEGORY not in (eff["SpellCategoryID"], spell_categories.get(spell)):
                continue
            buffs = buff_ids(spell, effects, {})
            if not buffs:
                continue
            if eff["SpellCategoryID"] == COMBAT_POTION_CATEGORY:
                ms = eff["CategoryCoolDownMSec"]
            else:
                ms = spell_cooldowns.get(spell, (0, 0))[1]
            if ms > 0:
                potions.append({"item": item, "spell": spell, "buff": buffs[0], "cd": ms / 1000})
    return potions


def load_potions(cache_dir, effects):
    def table(name):
        with open(fetch_table(name, cache_dir), encoding="utf8", newline="") as f:
            yield from csv.DictReader(f)

    potion_items = {int(r["ID"]) for r in table("Item")
                    if r["ClassID"] == ITEM_CLASS_CONSUMABLE and r["SubclassID"] == ITEM_SUBCLASS_POTION}
    expansion = {int(r["ID"]): int(r["ExpansionID"]) for r in table("ItemSparse") if int(r["ID"]) in potion_items}
    current = max(expansion.values())
    items = {i for i, e in expansion.items() if e == current}
    effect_rows = {int(r["ID"]): r for r in table("ItemEffect")}
    item_effects = {}
    for r in table("ItemXItemEffect"):
        item, row = int(r["ItemID"]), effect_rows.get(int(r["ItemEffectID"]))
        if item in items and row:
            item_effects.setdefault(item, []).append({
                "TriggerType": int(row["TriggerType"]),
                "SpellID": int(row["SpellID"]),
                "SpellCategoryID": int(row["SpellCategoryID"]),
                "CoolDownMSec": int(row["CoolDownMSec"]),
                "CategoryCoolDownMSec": int(row["CategoryCoolDownMSec"]),
            })
    spells = {e["SpellID"] for effs in item_effects.values() for e in effs}
    categories = {int(r["SpellID"]): int(r["Category"]) for r in table("SpellCategories")
                  if r["DifficultyID"] == "0" and int(r["SpellID"]) in spells}
    cooldowns = {int(r["SpellID"]): (int(r["RecoveryTime"]), int(r["CategoryRecoveryTime"])) for r in table("SpellCooldowns")
                 if r["DifficultyID"] == "0" and int(r["SpellID"]) in spells}
    return derive_potions(items, item_effects, categories, cooldowns, effects)


def check_overrides(catalog, overrides):
    known = {str(s["id"]) for s in catalog["spells"]}
    for field in ("buffs", "debuffs"):
        for key in overrides.get(field, {}):
            if key not in known:
                raise ValueError("%s override %s matches no catalog spell" % (field, key))


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


def spell_line(spell, token, buffs, debuffs=(), tokens=None):
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
    if spell["recoveryMs"]:
        fields.append("recovery=" + seconds(spell["recoveryMs"]))
    if spell["talentGated"]:
        fields.append("talentGated=true")
    if spell["cdMods"]:
        fields.append("cdMods=" + lua_map(spell["cdMods"], seconds))
    if spell["cdPct"]:
        fields.append("cdPct=" + lua_map(spell["cdPct"], num))
    if spell["chargeMods"]:
        fields.append("chargeMods=" + lua_map(spell["chargeMods"], seconds))
    if spell["chargePct"]:
        fields.append("chargePct=" + lua_map(spell["chargePct"], num))
    if spell["specMods"]:
        fields.append("specMods=" + lua_map(spell["specMods"], lambda ids: lua_list(str(i) for i in ids)))
    if spell["chargeAdds"]:
        fields.append("chargeAdds=" + lua_map(spell["chargeAdds"], num))
    if spell["replaces"]:
        fields.append("replaces=" + lua_list(str(s) for s in spell["replaces"]))
    if spell["races"]:
        fields.append("races=" + lua_list(str(s) for s in spell["races"]))
    if spell.get("classes") and tokens:
        fields.append("classes=" + lua_list(lua_str(tokens[c]) for c in spell["classes"]))
    if spell["aoe"]:
        fields.append("aoe=true")
    if buffs:
        fields.append("buffs=" + lua_list(str(b) for b in buffs))
    track = track_kind(spell["type"], buffs)
    if debuffs and track == "debuff":
        fields.append("debuffs=" + lua_list(str(d) for d in debuffs))
    fields.append("track=" + lua_str(track))
    return "ns.Spells[%d]={%s}" % (spell["id"], ",".join(fields))


def render(catalog, effects, overrides, potions):
    check_overrides(catalog, overrides)
    tokens = {int(k): v["token"] for k, v in catalog["classes"].items()}
    buff_overrides = overrides.get("buffs", {})
    debuff_overrides = overrides.get("debuffs", {})
    out = ["local _, ns = ...", "ns.Spells = {}", "ns.TalentEntries = {}", "ns.Specs = {}", "ns.Classes = {}"]
    for spell in sorted(catalog["spells"], key=lambda s: s["id"]):
        token = tokens.get(spell["classId"])
        out.append(spell_line(spell, token, buff_ids(spell["id"], effects, buff_overrides),
                              debuff_ids(spell["id"], effects, debuff_overrides), tokens))
    for entry, talent in sorted(catalog["talentEntries"].items(), key=lambda kv: int(kv[0])):
        out.append("ns.TalentEntries[%s]=%d" % (entry, talent))
    for spec_id, spec in sorted(catalog["specs"].items(), key=lambda kv: int(kv[0])):
        out.append("ns.Specs[%s]={class=%s,role=%s,name=%s%s}" % (
            spec_id, lua_str(tokens[spec["classId"]]), lua_str(spec["role"]), lua_str(spec["name"]),
            ",ranged=true" if spec.get("ranged") else ""))
    for class_id, token in sorted(tokens.items()):
        out.append("ns.Classes[%d]=%s" % (class_id, lua_str(token)))
    out.append("ns.Potions={" + ",".join(
        "{item=%d,spell=%d,buff=%d,cd=%s}" % (p["item"], p["spell"], p["buff"], num(p["cd"])) for p in potions) + "}")
    return "\n".join(out) + "\n"


def fetch_table(name, cache_dir):
    os.makedirs(cache_dir, exist_ok=True)
    path = os.path.join(cache_dir, "%s-%s.csv" % (name, WAGO_BUILD))
    if not os.path.exists(path):
        req = urllib.request.Request(WAGO_URL % name, headers={"User-Agent": "SquadCD-gen/1.0"})
        tmp = path + ".part"
        with urllib.request.urlopen(req, timeout=600) as resp, open(tmp, "wb") as f:
            f.write(resp.read())
        os.replace(tmp, path)
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
    effects = load_effects(fetch_table("SpellEffect", args.cache))
    text = render(catalog, effects, overrides, load_potions(args.cache, effects))
    with open(args.out, "w", encoding="utf8", newline="\n") as f:
        f.write(text)


if __name__ == "__main__":
    main()
