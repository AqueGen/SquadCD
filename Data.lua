-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...
ns.Spells = {}
ns.TalentEntries = {}
ns.Specs = {}
ns.Classes = {}
ns.Spells[99]={name="Incapacitating Roar",icon="ability_druid_demoralizingroar",type="CC",class="DRUID",specs={},cd=30,talentGated=true,aoe=true,debuffs={99},track="debuff"}
ns.Spells[408]={name="Kidney Shot",icon="ability_rogue_kidneyshot",type="Stun",class="ROGUE",specs={},cd=30,debuffs={408},track="debuff"}
ns.Spells[475]={name="Remove Curse",icon="spell_nature_removecurse",type="Dispel",class="MAGE",specs={},cd=8,talentGated=true,track="none"}
ns.Spells[498]={name="Divine Protection",icon="spell_holy_divineprotection",type="Personal",class="PALADIN",specs={65},cd=60,cdMods={[1258011]=30},cdPct={[114154]=-30},specMods={[70]={1258011}},buffs={498},track="buff"}
ns.Spells[527]={name="Purify",icon="spell_holy_dispelmagic",type="Dispel",class="PRIEST",specs={256,257},cd=8,charges=1,chargeCd=8,recovery=8,track="none"}
ns.Spells[633]={name="Lay on Hands",icon="spell_holy_layonhands",type="External",class="PALADIN",specs={},cd=600,talentGated=true,cdPct={[114154]=-30,[378425]=-15,[414720]=-40},track="target"}
ns.Spells[642]={name="Divine Shield",icon="spell_holy_divineshield",type="Personal",class="PALADIN",specs={},cd=300,cdPct={[114154]=-30,[378425]=-15},buffs={642},track="buff"}
ns.Spells[740]={name="Tranquility",icon="spell_nature_tranquility",type="Group",class="DRUID",specs={},cd=180,talentGated=true,buffs={740},track="buff"}
ns.Spells[853]={name="Hammer of Justice",icon="spell_holy_sealofmight",type="Stun",class="PALADIN",specs={},cd=45,cdMods={[234299]=-15},debuffs={853},track="debuff"}
ns.Spells[871]={name="Shield Wall",icon="ability_warrior_shieldwall",type="Personal",class="WARRIOR",specs={},cd=180,charges=1,chargeCd=180,recovery=8,talentGated=true,cdPct={[391271]=-10},chargeMods={[397103]=-60},chargePct={[391271]=-10},chargeAdds={[397103]=1},buffs={871},track="buff"}
ns.Spells[1022]={name="Blessing of Protection",icon="spell_holy_sealofprotection",type="External",class="PALADIN",specs={},cd=300,charges=1,chargeCd=300,recovery=1.5,talentGated=true,chargeMods={[384909]=-60},chargePct={[378425]=-15},buffs={1022},track="target"}
ns.Spells[1122]={name="Summon Infernal",icon="spell_shadow_summoninfernal",type="Burst",class="WARLOCK",specs={},cd=120,talentGated=true,cdMods={[387084]=-60,[1280483]=-30},track="none"}
ns.Spells[1719]={name="Recklessness",icon="warrior_talent_icon_innerrage",type="Burst",class="WARRIOR",specs={},cd=90,talentGated=true,buffs={1719},track="buff"}
ns.Spells[1766]={name="Kick",icon="ability_kick",type="Kick",class="ROGUE",specs={},cd=15,track="kick"}
ns.Spells[1776]={name="Gouge",icon="ability_gouge",type="CC",class="ROGUE",specs={},cd=25,talentGated=true,debuffs={1776},track="debuff"}
ns.Spells[1833]={name="Cheap Shot",icon="ability_cheapshot",type="Stun",class="ROGUE",specs={},cd=12,charges=1,chargeCd=12,recovery=1,debuffs={1833},track="debuff"}
ns.Spells[2094]={name="Blind",icon="spell_shadow_mindsteal",type="CC",class="ROGUE",specs={},cd=120,talentGated=true,cdPct={[200733]=-50,[256165]=-25,[441415]=-10},debuffs={2094},track="debuff"}
ns.Spells[2139]={name="Counterspell",icon="spell_frost_iceshock",type="Kick",class="MAGE",specs={},cd=25,track="kick"}
ns.Spells[2782]={name="Remove Corruption",icon="spell_holy_removecurse",type="Dispel",class="DRUID",specs={},cd=8,talentGated=true,track="none"}
ns.Spells[2908]={name="Soothe",icon="ability_hunter_beastsoothe",type="Purge",class="DRUID",specs={},cd=10,talentGated=true,track="none"}
ns.Spells[4987]={name="Cleanse",icon="spell_holy_purify",type="Dispel",class="PALADIN",specs={65},cd=8,charges=1,chargeCd=8,recovery=8,track="none"}
ns.Spells[5211]={name="Mighty Bash",icon="ability_druid_bash",type="Stun",class="DRUID",specs={},cd=60,talentGated=true,debuffs={5211},track="debuff"}
ns.Spells[5246]={name="Intimidating Shout",icon="ability_golemthunderclap",type="CC",class="WARRIOR",specs={},cd=90,talentGated=true,cdMods={[424742]=-15},aoe=true,debuffs={5246},track="debuff"}
ns.Spells[5277]={name="Evasion",icon="spell_shadow_shadowward",type="Personal",class="ROGUE",specs={},cd=120,talentGated=true,buffs={5277},track="buff"}
ns.Spells[5484]={name="Howl of Terror",icon="ability_warlock_howlofterror",type="CC",class="WARLOCK",specs={},cd=40,talentGated=true,cdMods={[429072]=-10,[1270255]=-5},aoe=true,debuffs={5484},track="debuff"}
ns.Spells[5938]={name="Shiv",icon="inv_throwingknife_04",type="Purge",class="ROGUE",specs={},cd=30,charges=1,chargeCd=30,talentGated=true,chargeMods={[1267182]=-15},track="none"}
ns.Spells[6552]={name="Pummel",icon="inv_gauntlets_04",type="Kick",class="WARRIOR",specs={},cd=15,cdMods={[383115]=-1},cdPct={[391271]=-10},track="kick"}
ns.Spells[6789]={name="Mortal Coil",icon="ability_warlock_mortalcoil",type="CC",class="WARLOCK",specs={},cd=45,talentGated=true,debuffs={6789},track="debuff"}
ns.Spells[6940]={name="Blessing of Sacrifice",icon="spell_holy_sealofsacrifice",type="External",class="PALADIN",specs={},cd=120,talentGated=true,cdMods={[384820]=-60},buffs={6940},track="target"}
ns.Spells[7744]={name="Will of the Forsaken",icon="spell_shadow_raisedead",type="Racial",specs={},cd=120,races={5},buffs={7744},track="buff"}
ns.Spells[8122]={name="Psychic Scream",icon="spell_shadow_psychicscream",type="CC",class="PRIEST",specs={},cd=40,talentGated=true,cdMods={[196704]=-10},aoe=true,debuffs={8122},track="debuff"}
ns.Spells[10060]={name="Power Infusion",icon="spell_holy_powerinfusion",type="Burst",class="PRIEST",specs={},cd=120,talentGated=true,buffs={10060},track="buff"}
ns.Spells[10326]={name="Turn Evil",icon="ability_paladin_turnevil",type="CC",class="PALADIN",specs={},cd=15,talentGated=true,debuffs={10326},track="debuff"}
ns.Spells[12975]={name="Last Stand",icon="spell_holy_ashestoashes",type="Personal",class="WARRIOR",specs={},cd=180,talentGated=true,buffs={12975},track="buff"}
ns.Spells[13750]={name="Adrenaline Rush",icon="spell_shadow_shadowworddominate",type="Burst",class="ROGUE",specs={},cd=180,talentGated=true,buffs={13750},track="buff"}
ns.Spells[15286]={name="Vampiric Embrace",icon="spell_shadow_unsummonbuilding",type="Group",class="PRIEST",specs={258},cd=120,buffs={15286},track="buff"}
ns.Spells[15487]={name="Silence",icon="ability_priest_silence",type="Kick",class="PRIEST",specs={258},cd=30,track="kick"}
ns.Spells[19236]={name="Desperate Prayer",icon="spell_holy_testoffaith",type="Personal",class="PRIEST",specs={},cd=90,talentGated=true,buffs={19236},track="buff"}
ns.Spells[19505]={name="Devour Magic",icon="spell_nature_purge",type="Purge",class="WARLOCK",specs={},cd=15,track="none"}
ns.Spells[19574]={name="Bestial Wrath",icon="ability_druid_ferociousbite",type="Burst",class="HUNTER",specs={},cd=90,talentGated=true,cdMods={[231548]=-60},buffs={19574},track="buff"}
ns.Spells[19577]={name="Intimidation",icon="ability_devour",type="Stun",class="HUNTER",specs={},cd=60,talentGated=true,cdMods={[459507]=-20},debuffs={24394},track="debuff"}
ns.Spells[19647]={name="Spell Lock",icon="spell_shadow_mindrot",type="Kick",class="WARLOCK",specs={},cd=24,track="kick"}
ns.Spells[19801]={name="Tranquilizing Shot",icon="spell_nature_drowsy",type="Purge",class="HUNTER",specs={},cd=10,talentGated=true,track="none"}
ns.Spells[20549]={name="War Stomp",icon="ability_warstomp",type="Racial",specs={},cd=90,races={6},track="none"}
ns.Spells[20572]={name="Blood Fury",icon="racial_orc_berserkerstrength",type="Racial",specs={},cd=120,races={2},classes={"WARRIOR","HUNTER","ROGUE","DEATHKNIGHT"},buffs={20572},track="buff"}
ns.Spells[20589]={name="Escape Artist",icon="ability_rogue_trip",type="Racial",specs={},cd=60,races={7},track="none"}
ns.Spells[20594]={name="Stoneform",icon="spell_shadow_unholystrength",type="Racial",specs={},cd=120,races={3},buffs={65116},track="buff"}
ns.Spells[22570]={name="Maim",icon="ability_druid_mangle.tga",type="Stun",class="DRUID",specs={},cd=30,talentGated=true,debuffs={203126},track="debuff"}
ns.Spells[22812]={name="Barkskin",icon="spell_nature_stoneclawtotem",type="Personal",class="DRUID",specs={},cd=60,cdMods={[137010]=-15},cdPct={[203965]=-12},specMods={[104]={137010}},buffs={22812},track="buff"}
ns.Spells[25046]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"ROGUE"},track="none"}
ns.Spells[26297]={name="Berserking",icon="racial_troll_berserk",type="Racial",specs={},cd=180,races={8},buffs={26297},track="buff"}
ns.Spells[28730]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"MAGE","WARLOCK"},track="none"}
ns.Spells[28880]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"WARRIOR"},buffs={28880},track="buff"}
ns.Spells[30283]={name="Shadowfury",icon="ability_warlock_shadowfurytga",type="Stun",class="WARLOCK",specs={},cd=60,talentGated=true,cdMods={[264874]=-15,[1270255]=-15},aoe=true,debuffs={30283},track="debuff"}
ns.Spells[31224]={name="Cloak of Shadows",icon="spell_shadow_nethercloak",type="Personal",class="ROGUE",specs={},cd=120,talentGated=true,buffs={31224,35729},track="buff"}
ns.Spells[31661]={name="Dragon's Breath",icon="inv_misc_head_dragon_01",type="CC",class="MAGE",specs={},cd=45,talentGated=true,cdMods={[387807]=-5},cdPct={[431067]=-30},aoe=true,debuffs={31661},track="debuff"}
ns.Spells[31821]={name="Aura Mastery",icon="spell_holy_auramastery",type="Group",class="PALADIN",specs={},cd=180,talentGated=true,cdMods={[392911]=-30},buffs={31821},track="buff"}
ns.Spells[31850]={name="Ardent Defender",icon="spell_holy_ardentdefender",type="Personal",class="PALADIN",specs={},cd=90,talentGated=true,cdPct={[114154]=-30},buffs={31850},track="buff"}
ns.Spells[31884]={name="Avenging Wrath",icon="spell_holy_avenginewrath",type="Burst",class="PALADIN",specs={},cd=120,talentGated=true,cdMods={[1241511]=-30,[1258011]=-60},cdPct={[204074]=-50},specMods={[70]={1258011}},buffs={31884},track="buff"}
ns.Spells[31935]={name="Avenger's Shield",icon="spell_holy_avengersshield",type="Kick",class="PALADIN",specs={},cd=15,talentGated=true,track="kick"}
ns.Spells[32375]={name="Mass Dispel",icon="spell_arcane_massdispel",type="Purge",class="PRIEST",specs={},cd=120,talentGated=true,track="none"}
ns.Spells[33206]={name="Pain Suppression",icon="spell_holy_painsupression",type="External",class="PRIEST",specs={},cd=180,charges=1,chargeCd=180,recovery=1.5,talentGated=true,chargeAdds={[373035]=1},buffs={33206},track="target"}
ns.Spells[33697]={name="Blood Fury",icon="racial_orc_berserkerstrength",type="Racial",specs={},cd=120,races={2},classes={"SHAMAN","MONK"},buffs={33697},track="buff"}
ns.Spells[33702]={name="Blood Fury",icon="racial_orc_berserkerstrength",type="Racial",specs={},cd=120,races={2},classes={"PRIEST","MAGE","WARLOCK"},buffs={33702},track="buff"}
ns.Spells[33891]={name="Incarnation: Tree of Life",icon="ability_druid_improvedtreeform",type="Group",class="DRUID",specs={},cd=180,talentGated=true,cdMods={[391174]=-60},buffs={33891},track="buff"}
ns.Spells[42650]={name="Army of the Dead",icon="spell_deathknight_armyofthedead",type="Burst",class="DEATHKNIGHT",specs={},cd=90,talentGated=true,buffs={42650},track="buff"}
ns.Spells[45438]={name="Ice Block",icon="spell_frost_frost",type="Personal",class="MAGE",specs={},cd=240,charges=1,chargeCd=240,talentGated=true,chargeMods={[382424]=-30,[1244110]=-30,[1265517]=-30},chargeAdds={[1244110]=1},buffs={45438},track="buff"}
ns.Spells[46968]={name="Shockwave",icon="ability_warrior_shockwave",type="Stun",class="WARRIOR",specs={},cd=40,talentGated=true,cdMods={[440992]=-5},aoe=true,debuffs={132168},track="debuff"}
ns.Spells[47528]={name="Mind Freeze",icon="spell_deathknight_mindfreeze",type="Kick",class="DEATHKNIGHT",specs={},cd=15,talentGated=true,track="kick"}
ns.Spells[47585]={name="Dispersion",icon="spell_shadow_dispersion",type="Personal",class="PRIEST",specs={258},cd=120,cdMods={[288733]=-30},buffs={47585},track="buff"}
ns.Spells[47788]={name="Guardian Spirit",icon="spell_holy_guardianspirit",type="External",class="PRIEST",specs={},cd=180,talentGated=true,buffs={47788},track="target"}
ns.Spells[48707]={name="Anti-Magic Shell",icon="spell_shadow_antimagicshell",type="Personal",class="DEATHKNIGHT",specs={},cd=60,cdMods={[205727]=-20,[457574]=20},buffs={48707},track="buff"}
ns.Spells[48743]={name="Death Pact",icon="spell_shadow_deathpact",type="Personal",class="DEATHKNIGHT",specs={},cd=120,talentGated=true,cdMods={[1266818]=-30},buffs={48743},track="buff"}
ns.Spells[48792]={name="Icebound Fortitude",icon="spell_deathknight_iceboundfortitude",type="Personal",class="DEATHKNIGHT",specs={},cd=120,talentGated=true,buffs={48792},track="buff"}
ns.Spells[49028]={name="Dancing Rune Weapon",icon="inv_sword_07",type="Personal",class="DEATHKNIGHT",specs={},cd=120,talentGated=true,cdMods={[377637]=-30},buffs={49028},track="buff"}
ns.Spells[49039]={name="Lichborne",icon="spell_shadow_raisedead",type="Personal",class="DEATHKNIGHT",specs={},cd=120,cdMods={[389682]=-30,[437122]=-30},buffs={49039},track="buff"}
ns.Spells[50334]={name="Berserk",icon="ability_druid_berserk",type="Personal",class="DRUID",specs={},cd=180,talentGated=true,buffs={50334},track="buff"}
ns.Spells[50613]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"DEATHKNIGHT"},track="none"}
ns.Spells[51052]={name="Anti-Magic Zone",icon="spell_deathknight_antimagiczone",type="Group",class="DEATHKNIGHT",specs={},cd=240,talentGated=true,cdMods={[374383]=-60},buffs={145629},track="buff"}
ns.Spells[51271]={name="Pillar of Frost",icon="ability_deathknight_pillaroffrost",type="Burst",class="DEATHKNIGHT",specs={},cd=45,talentGated=true,buffs={51271},track="buff"}
ns.Spells[51490]={name="Thunderstorm",icon="spell_shaman_thunderstorm",type="CC",class="SHAMAN",specs={262},cd=30,talentGated=true,cdMods={[378779]=-5},aoe=true,debuffs={51490},track="debuff"}
ns.Spells[51514]={name="Hex",icon="spell_shaman_hex",type="CC",class="SHAMAN",specs={},cd=30,talentGated=true,cdMods={[204268]=-15},debuffs={51514},track="debuff"}
ns.Spells[51886]={name="Cleanse Spirit",icon="ability_shaman_cleansespirit",type="Dispel",class="SHAMAN",specs={},cd=8,talentGated=true,track="none"}
ns.Spells[53480]={name="Roar of Sacrifice",icon="ability_hunter_fervor",type="External",class="HUNTER",specs={},cd=120,talentGated=true,buffs={53480},track="target"}
ns.Spells[55233]={name="Vampiric Blood",icon="spell_shadow_lifedrain",type="Personal",class="DEATHKNIGHT",specs={},cd=90,talentGated=true,buffs={55233},track="buff"}
ns.Spells[55342]={name="Mirror Image",icon="spell_magic_lesserinvisibilty",type="Personal",class="MAGE",specs={},cd=120,talentGated=true,cdMods={[1244025]=-30},buffs={55342},track="buff"}
ns.Spells[57994]={name="Wind Shear",icon="spell_nature_cyclone",type="Kick",class="SHAMAN",specs={},cd=12,talentGated=true,cdMods={[137039]=18},specMods={[264]={137039}},track="kick"}
ns.Spells[58984]={name="Shadowmeld",icon="ability_ambush",type="Racial",specs={},cd=120,races={4},buffs={58984},track="buff"}
ns.Spells[59542]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"PALADIN"},buffs={59542},track="buff"}
ns.Spells[59543]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"HUNTER"},buffs={59543},track="buff"}
ns.Spells[59544]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"PRIEST"},buffs={59544},track="buff"}
ns.Spells[59545]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"DEATHKNIGHT"},buffs={59545},track="buff"}
ns.Spells[59547]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"SHAMAN"},buffs={59547},track="buff"}
ns.Spells[59548]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"MAGE"},buffs={59548},track="buff"}
ns.Spells[59752]={name="Will to Survive",icon="spell_shadow_charm",type="Racial",specs={},cd=180,races={1},buffs={59752},track="buff"}
ns.Spells[61336]={name="Survival Instincts",icon="ability_druid_tigersroar",type="Personal",class="DRUID",specs={},cd=180,charges=1,chargeCd=180,recovery=6,talentGated=true,chargePct={[203965]=-12},specMods={[104]={137010}},chargeAdds={[137010]=1},buffs={61336},track="buff"}
ns.Spells[62618]={name="Power Word: Barrier",icon="spell_holy_powerwordbarrier",type="Group",class="PRIEST",specs={},cd=180,talentGated=true,buffs={81782},track="buff"}
ns.Spells[64843]={name="Divine Hymn",icon="spell_holy_divinehymn",type="Group",class="PRIEST",specs={},cd=180,talentGated=true,cdMods={[419110]=-60},buffs={64843},track="buff"}
ns.Spells[68992]={name="Darkflight",icon="ability_racial_darkflight",type="Racial",specs={},cd=90,races={22},classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","MONK","DRUID"},buffs={68992},track="buff"}
ns.Spells[69041]={name="Rocket Barrage",icon="inv_gizmo_rocketlauncher",type="Racial",specs={},cd=90,races={9},track="none"}
ns.Spells[69070]={name="Rocket Jump",icon="ability_racial_rocketjump",type="Racial",specs={},cd=90,races={9},track="none"}
ns.Spells[69179]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"WARRIOR"},track="none"}
ns.Spells[77130]={name="Purify Spirit",icon="ability_shaman_cleansespirit",type="Dispel",class="SHAMAN",specs={264},cd=8,charges=1,chargeCd=8,track="none"}
ns.Spells[77761]={name="Stampeding Roar",icon="spell_druid_stamedingroar",type="Movement",class="DRUID",specs={},cd=120,cdMods={[288826]=-60},replaces={106898},buffs={77761},track="buff"}
ns.Spells[77764]={name="Stampeding Roar",icon="spell_druid_stampedingroar_cat",type="Movement",class="DRUID",specs={},cd=120,cdMods={[288826]=-60},replaces={106898},buffs={77764},track="buff"}
ns.Spells[78675]={name="Solar Beam",icon="ability_vehicle_sonicshockwave",type="Kick",class="DRUID",specs={},cd=60,talentGated=true,track="kick"}
ns.Spells[80483]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"HUNTER"},track="none"}
ns.Spells[86659]={name="Guardian of Ancient Kings",icon="spell_holy_heroism",type="Personal",class="PALADIN",specs={},cd=180,charges=1,chargeCd=180,recovery=8,talentGated=true,chargeAdds={[1246481]=1},buffs={86659},track="buff"}
ns.Spells[88423]={name="Nature's Cure",icon="ability_shaman_cleansespirit",type="Dispel",class="DRUID",specs={105},cd=8,charges=1,chargeCd=8,track="none"}
ns.Spells[88625]={name="Holy Word: Chastise",icon="spell_holy_chastise",type="CC",class="PRIEST",specs={},cd=60,talentGated=true,cdMods={[1215275]=-15,[1272359]=-5},debuffs={200196,200200},track="debuff"}
ns.Spells[89766]={name="Axe Toss",icon="ability_warrior_titansgrip",type="Stun",class="WARLOCK",specs={},cd=30,debuffs={89766},track="debuff"}
ns.Spells[89808]={name="Singe Magic",icon="spell_fire_elementaldevastation",type="Dispel",class="WARLOCK",specs={},cd=15,track="none"}
ns.Spells[96231]={name="Rebuke",icon="spell_holy_rebuke",type="Kick",class="PALADIN",specs={},cd=15,talentGated=true,track="kick"}
ns.Spells[97462]={name="Rallying Cry",icon="ability_warrior_rallyingcry",type="Group",class="WARRIOR",specs={},cd=180,talentGated=true,buffs={97463},track="buff"}
ns.Spells[98008]={name="Spirit Link Totem",icon="spell_shaman_spiritlink",type="Group",class="SHAMAN",specs={},cd=180,charges=1,chargeCd=180,talentGated=true,track="none"}
ns.Spells[102342]={name="Ironbark",icon="spell_druid_ironbark",type="External",class="DRUID",specs={},cd=90,talentGated=true,cdMods={[382552]=-20},buffs={102342},track="target"}
ns.Spells[102359]={name="Mass Entanglement",icon="spell_druid_massentanglement",type="CC",class="DRUID",specs={},cd=30,talentGated=true,aoe=true,debuffs={102359},track="debuff"}
ns.Spells[102543]={name="Incarnation: Avatar of Ashamane",icon="spell_druid_incarnation",type="Burst",class="DRUID",specs={},cd=180,talentGated=true,cdMods={[391174]=-60},replaces={106951},buffs={102543,252071},track="buff"}
ns.Spells[102558]={name="Incarnation: Guardian of Ursoc",icon="spell_druid_incarnation",type="Personal",class="DRUID",specs={},cd=180,talentGated=true,cdMods={[391174]=-60},replaces={50334},buffs={102558},track="buff"}
ns.Spells[102560]={name="Incarnation: Chosen of Elune",icon="spell_druid_incarnation",type="Burst",class="DRUID",specs={},cd=180,charges=1,chargeCd=180,recovery=1,talentGated=true,cdMods={[391174]=-60},chargeMods={[390378]=-60,[468743]=-60},chargeAdds={[468743]=1},replaces={194223},buffs={102560},track="buff"}
ns.Spells[102793]={name="Ursol's Vortex",icon="spell_druid_ursolsvortex",type="CC",class="DRUID",specs={},cd=60,talentGated=true,aoe=true,debuffs={127797},track="debuff"}
ns.Spells[104773]={name="Unending Resolve",icon="spell_shadow_demonictactics",type="Personal",class="WARLOCK",specs={},cd=180,cdMods={[386659]=-45},buffs={104773},track="buff"}
ns.Spells[106839]={name="Skull Bash",icon="inv_bone_skull_04",type="Kick",class="DRUID",specs={},cd=15,talentGated=true,track="kick"}
ns.Spells[106898]={name="Stampeding Roar",icon="spell_druid_stampedingroar_cat",type="Movement",class="DRUID",specs={},cd=120,talentGated=true,cdMods={[288826]=-60},buffs={106898},track="buff"}
ns.Spells[106951]={name="Berserk",icon="ability_druid_berserk",type="Burst",class="DRUID",specs={},cd=180,talentGated=true,cdMods={[391174]=-60},buffs={106951},track="buff"}
ns.Spells[107079]={name="Quaking Palm",icon="pandarenracial_quiveringpain",type="Racial",specs={},cd=120,races={24,25,26},track="none"}
ns.Spells[107570]={name="Storm Bolt",icon="warrior_talent_icon_stormbolt",type="Stun",class="WARRIOR",specs={},cd=30,talentGated=true,cdMods={[436162]=10},cdPct={[391271]=-10},debuffs={132169},track="debuff"}
ns.Spells[107574]={name="Avatar",icon="warrior_talent_icon_avatar",type="Burst",class="WARRIOR",specs={},cd=90,talentGated=true,buffs={107574},track="buff"}
ns.Spells[108199]={name="Gorefiend's Grasp",icon="ability_deathknight_aoedeathgrip",type="CC",class="DEATHKNIGHT",specs={},cd=90,talentGated=true,aoe=true,debuffs={108199},track="debuff"}
ns.Spells[108271]={name="Astral Shift",icon="ability_shaman_astralshift",type="Personal",class="SHAMAN",specs={},cd=120,talentGated=true,cdMods={[381647]=-30},buffs={108271},track="buff"}
ns.Spells[108280]={name="Healing Tide Totem",icon="ability_shaman_healingtide",type="Group",class="SHAMAN",specs={},cd=180,talentGated=true,cdMods={[462440]=-60},buffs={108280},track="buff"}
ns.Spells[108416]={name="Dark Pact",icon="spell_shadow_deathpact",type="Personal",class="WARLOCK",specs={},cd=60,talentGated=true,buffs={108416},track="buff"}
ns.Spells[109248]={name="Binding Shot",icon="spell_shaman_bindelemental",type="Stun",class="HUNTER",specs={},cd=45,talentGated=true,aoe=true,debuffs={117526},track="debuff"}
ns.Spells[109304]={name="Exhilaration",icon="ability_hunter_onewithnature",type="Personal",class="HUNTER",specs={},cd=120,cdMods={[270581]=-30},track="none"}
ns.Spells[110959]={name="Greater Invisibility",icon="ability_mage_greaterinvisibility",type="Personal",class="MAGE",specs={},cd=120,talentGated=true,cdMods={[210476]=-60},buffs={110960},track="buff"}
ns.Spells[113724]={name="Ring of Frost",icon="spell_frost_ring-of-frost",type="CC",class="MAGE",specs={},cd=45,talentGated=true,cdMods={[387807]=-5},cdPct={[431067]=-30},aoe=true,buffs={136511},debuffs={82691},track="debuff"}
ns.Spells[114050]={name="Ascendance",icon="inv_misc_questionmark",type="Burst",class="SHAMAN",specs={},cd=180,talentGated=true,cdMods={[381785]=-45,[384444]=-60,[462440]=-60},buffs={114050,114051},track="buff"}
ns.Spells[114051]={name="Ascendance",icon="inv_misc_questionmark",type="Burst",class="SHAMAN",specs={},cd=180,talentGated=true,cdMods={[381785]=-45,[384444]=-60,[462440]=-60},replaces={384352},buffs={114051},track="buff"}
ns.Spells[114052]={name="Ascendance",icon="inv_misc_questionmark",type="Group",class="SHAMAN",specs={},cd=180,talentGated=true,cdMods={[381785]=-45,[384444]=-60,[462440]=-60},buffs={114052},track="buff"}
ns.Spells[115078]={name="Paralysis",icon="ability_monk_paralysis",type="CC",class="MONK",specs={},cd=45,talentGated=true,cdMods={[344359]=-15},debuffs={115078},track="debuff"}
ns.Spells[115176]={name="Zen Meditation",icon="ability_monk_zenmeditation",type="Personal",class="MONK",specs={},cd=300,talentGated=true,cdPct={[387035]=-25},buffs={115176},track="buff"}
ns.Spells[115203]={name="Fortifying Brew",icon="ability_monk_fortifyingale_new",type="Personal",class="MONK",specs={},cd=360,talentGated=true,cdMods={[388813]=-30,[1258122]=-240,[1258138]=-240},specMods={[269]={1258122},[270]={1258138}},buffs={120954},track="buff"}
ns.Spells[115310]={name="Revival",icon="spell_monk_revival",type="Group",class="MONK",specs={},cd=180,charges=1,chargeCd=180,recovery=1,talentGated=true,chargeMods={[388551]=-30},track="none"}
ns.Spells[115450]={name="Detox",icon="ability_rogue_imrovedrecuperate",type="Dispel",class="MONK",specs={270},cd=8,charges=1,chargeCd=8,track="none"}
ns.Spells[115750]={name="Blinding Light",icon="ability_paladin_blindinglight",type="CC",class="PALADIN",specs={},cd=90,talentGated=true,cdMods={[469325]=-15},aoe=true,debuffs={105421},track="debuff"}
ns.Spells[116705]={name="Spear Hand Strike",icon="ability_monk_spearhand",type="Kick",class="MONK",specs={},cd=15,talentGated=true,track="kick"}
ns.Spells[116844]={name="Ring of Peace",icon="spell_monk_ringofpeace",type="CC",class="MONK",specs={},cd=45,talentGated=true,cdMods={[450448]=-5},aoe=true,track="debuff"}
ns.Spells[116849]={name="Life Cocoon",icon="ability_monk_chicocoon",type="External",class="MONK",specs={},cd=120,charges=1,chargeCd=120,recovery=0.75,talentGated=true,chargeMods={[202424]=-45},buffs={116849},track="target"}
ns.Spells[118038]={name="Die by the Sword",icon="ability_warrior_challange",type="Personal",class="WARRIOR",specs={},cd=120,talentGated=true,cdMods={[383338]=-30},cdPct={[391271]=-10},buffs={118038},track="buff"}
ns.Spells[119381]={name="Leg Sweep",icon="ability_monk_legsweep",type="Stun",class="MONK",specs={},cd=60,cdMods={[344359]=-10},aoe=true,debuffs={119381},track="debuff"}
ns.Spells[121093]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"MONK"},buffs={121093},track="buff"}
ns.Spells[121471]={name="Shadow Blades",icon="inv_knife_1h_grimbatolraid_d_03",type="Burst",class="ROGUE",specs={},cd=90,talentGated=true,buffs={121471},track="buff"}
ns.Spells[122278]={name="Dampen Harm",icon="ability_monk_dampenharm",type="Personal",class="MONK",specs={},cd=120,talentGated=true,buffs={122278},track="buff"}
ns.Spells[122470]={name="Touch of Karma",icon="ability_monk_touchofkarma",type="Personal",class="MONK",specs={269},cd=90,talentGated=true,buffs={122470},track="buff"}
ns.Spells[122783]={name="Diffuse Magic",icon="spell_monk_diffusemagic",type="Personal",class="MONK",specs={},cd=90,talentGated=true,buffs={122783},track="buff"}
ns.Spells[123904]={name="Invoke Xuen, the White Tiger",icon="ability_monk_summontigerstatue",type="Burst",class="MONK",specs={},cd=120,talentGated=true,cdMods={[388212]=-60,[392986]=-30,[450989]=-25},buffs={123904},track="buff"}
ns.Spells[129597]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"MONK"},track="none"}
ns.Spells[132469]={name="Typhoon",icon="ability_druid_typhoon",type="CC",class="DRUID",specs={},cd=30,talentGated=true,cdMods={[400140]=-5},aoe=true,debuffs={61391},track="debuff"}
ns.Spells[137639]={name="Storm, Earth, and Fire",icon="spell_nature_giftofthewild",type="Burst",class="MONK",specs={},cd=90,charges=2,chargeCd=90,recovery=16,talentGated=true,chargeMods={[280197]=-20,[450989]=-10},buffs={137639},track="buff"}
ns.Spells[147362]={name="Counter Shot",icon="inv_ammo_arrow_03",type="Kick",class="HUNTER",specs={},cd=24,talentGated=true,track="kick"}
ns.Spells[155145]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"PALADIN"},track="none"}
ns.Spells[157980]={name="Supernova",icon="spell_mage_supernova",type="CC",class="MAGE",specs={},cd=45,talentGated=true,cdMods={[387807]=-5},aoe=true,track="debuff"}
ns.Spells[179057]={name="Chaos Nova",icon="spell_fire_felfirenova",type="Stun",class="DEMONHUNTER",specs={},cd=45,talentGated=true,aoe=true,debuffs={179057},track="debuff"}
ns.Spells[183752]={name="Disrupt",icon="ability_demonhunter_consumemagic",type="Kick",class="DEMONHUNTER",specs={},cd=15,track="kick"}
ns.Spells[184364]={name="Enraged Regeneration",icon="ability_warrior_focusedrage",type="Personal",class="WARRIOR",specs={},cd=120,talentGated=true,cdPct={[391271]=-10},buffs={184364},track="buff"}
ns.Spells[186265]={name="Aspect of the Turtle",icon="ability_hunter_pet_turtle",type="Personal",class="HUNTER",specs={},cd=180,cdMods={[266921]=-15,[1258485]=-30},buffs={186265},track="buff"}
ns.Spells[187650]={name="Freezing Trap",icon="spell_frost_chainsofice",type="CC",class="HUNTER",specs={},cd=30,cdMods={[343247]=-5},debuffs={3355},track="debuff"}
ns.Spells[187707]={name="Muzzle",icon="ability_hunter_negate",type="Kick",class="HUNTER",specs={},cd=15,talentGated=true,track="kick"}
ns.Spells[187827]={name="Metamorphosis",icon="ability_demonhunter_metamorphasistank",type="Personal",class="DEMONHUNTER",specs={581},cd=120,charges=1,chargeCd=120,recovery=1,cdMods={[321068]=0},specMods={[581]={321068}},buffs={187827},track="buff"}
ns.Spells[190319]={name="Combustion",icon="spell_fire_sealoffire",type="Burst",class="MAGE",specs={},cd=120,talentGated=true,cdMods={[1254194]=-60},buffs={190319},track="buff"}
ns.Spells[191427]={name="Metamorphosis",icon="ability_demonhunter_metamorphasisdps",type="Burst",class="DEMONHUNTER",specs={577,1456},cd=120,buffs={162264,201453},track="buff"}
ns.Spells[192058]={name="Capacitor Totem",icon="spell_nature_brilliance",type="Stun",class="SHAMAN",specs={},cd=60,talentGated=true,cdMods={[265046]=-15},aoe=true,debuffs={118905},track="debuff"}
ns.Spells[192077]={name="Wind Rush Totem",icon="ability_shaman_windwalktotem",type="Movement",class="SHAMAN",specs={},cd=120,talentGated=true,track="none"}
ns.Spells[192249]={name="Storm Elemental",icon="inv_stormelemental",type="Burst",class="SHAMAN",specs={},cd=120,charges=1,chargeCd=120,talentGated=true,track="none"}
ns.Spells[194223]={name="Celestial Alignment",icon="spell_nature_natureguardian",type="Burst",class="DRUID",specs={},cd=180,charges=1,chargeCd=180,recovery=1,talentGated=true,chargeMods={[390378]=-60,[468743]=-60},chargeAdds={[468743]=1},buffs={194223},track="buff"}
ns.Spells[196718]={name="Darkness",icon="ability_demonhunter_darkness",type="Group",class="DEMONHUNTER",specs={},cd=300,talentGated=true,cdMods={[389783]=-120},buffs={196718},track="buff"}
ns.Spells[198067]={name="Fire Elemental",icon="spell_fire_elemental_totem",type="Burst",class="SHAMAN",specs={},cd=120,charges=1,chargeCd=120,talentGated=true,track="none"}
ns.Spells[198589]={name="Blur",icon="ability_demonhunter_blur",type="Personal",class="DEMONHUNTER",specs={577,1480},cd=60,charges=1,chargeCd=60,recovery=0.5,chargeAdds={[1266307]=1},buffs={212800},track="buff"}
ns.Spells[198838]={name="Earthen Wall Totem",icon="spell_nature_stoneskintotem",type="Group",class="SHAMAN",specs={},cd=60,talentGated=true,track="none"}
ns.Spells[198898]={name="Song of Chi-Ji",icon="inv_chaos_orb",type="CC",class="MONK",specs={},cd=30,talentGated=true,debuffs={198909},track="debuff"}
ns.Spells[202137]={name="Sigil of Silence",icon="ability_demonhunter_sigilofsilence",type="CC",class="DEMONHUNTER",specs={},cd=90,charges=1,chargeCd=90,talentGated=true,chargeMods={[320418]=-15},chargePct={[209281]=0,[389718]=-15},replaces={207684},aoe=true,debuffs={204490},track="debuff"}
ns.Spells[202138]={name="Sigil of Chains",icon="ability_demonhunter_sigilofchains",type="CC",class="DEMONHUNTER",specs={581},cd=60,charges=1,chargeCd=60,chargePct={[209281]=0,[389718]=-15},aoe=true,debuffs={204843},track="debuff"}
ns.Spells[202719]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"DEMONHUNTER"},track="none"}
ns.Spells[204018]={name="Blessing of Spellwarding",icon="spell_holy_blessingofprotection",type="External",class="PALADIN",specs={},cd=300,charges=1,chargeCd=300,recovery=1.5,talentGated=true,chargeMods={[384909]=-60},chargePct={[378425]=-15},buffs={204018},track="target"}
ns.Spells[204021]={name="Fiery Brand",icon="ability_demonhunter_fierybrand",type="Personal",class="DEMONHUNTER",specs={},cd=60,charges=1,chargeCd=60,talentGated=true,chargeMods={[389732]=-12},chargeAdds={[389732]=1},track="none"}
ns.Spells[205180]={name="Summon Darkglare",icon="inv_beholderwarlock",type="Burst",class="WARLOCK",specs={},cd=120,talentGated=true,cdMods={[387084]=-30},buffs={205180},track="buff"}
ns.Spells[207167]={name="Blinding Sleet",icon="spell_frost_chillingblast",type="CC",class="DEATHKNIGHT",specs={},cd=60,talentGated=true,aoe=true,debuffs={207167},track="debuff"}
ns.Spells[207399]={name="Ancestral Protection Totem",icon="spell_nature_reincarnation",type="Group",class="SHAMAN",specs={},cd=300,talentGated=true,buffs={207498},track="buff"}
ns.Spells[207684]={name="Sigil of Misery",icon="ability_demonhunter_sigilofmisery",type="CC",class="DEMONHUNTER",specs={},cd=120,charges=1,chargeCd=120,talentGated=true,chargeMods={[320418]=-30},chargePct={[209281]=0,[389718]=-15},aoe=true,debuffs={207685},track="debuff"}
ns.Spells[212641]={name="Guardian of Ancient Kings",icon="spell_holy_heroism",type="Personal",class="PALADIN",specs={},cd=180,charges=1,chargeCd=180,recovery=8,chargeAdds={[1246481]=1},replaces={86659},buffs={212641},track="buff"}
ns.Spells[213634]={name="Purify Disease",icon="spell_holy_nullifydisease",type="Dispel",class="PRIEST",specs={},cd=8,charges=1,chargeCd=8,recovery=8,talentGated=true,track="none"}
ns.Spells[213644]={name="Cleanse Toxins",icon="spell_holy_renew",type="Dispel",class="PALADIN",specs={},cd=8,charges=1,chargeCd=8,recovery=8,talentGated=true,track="none"}
ns.Spells[216331]={name="Avenging Crusader",icon="ability_paladin_veneration",type="Burst",class="PALADIN",specs={},cd=60,talentGated=true,cdMods={[1241511]=-30},replaces={31884},buffs={216331},track="buff"}
ns.Spells[217832]={name="Imprison",icon="ability_demonhunter_imprison",type="CC",class="DEMONHUNTER",specs={},cd=45,talentGated=true,debuffs={217832},track="debuff"}
ns.Spells[218164]={name="Detox",icon="ability_rogue_imrovedrecuperate",type="Dispel",class="MONK",specs={},cd=8,charges=1,chargeCd=8,talentGated=true,track="none"}
ns.Spells[221562]={name="Asphyxiate",icon="ability_deathknight_asphixiate",type="Stun",class="DEATHKNIGHT",specs={},cd=45,talentGated=true,debuffs={221562},track="debuff"}
ns.Spells[227847]={name="Bladestorm",icon="ability_warrior_bladestorm",type="Burst",class="WARRIOR",specs={},cd=90,charges=1,chargeCd=90,recovery=90,talentGated=true,cdMods={[382953]=-90},chargeAdds={[382953]=1},buffs={227847},track="buff"}
ns.Spells[228260]={name="Voidform",icon="spell_priest_void-blast",type="Burst",class="PRIEST",specs={},cd=120,talentGated=true,buffs={194249},track="buff"}
ns.Spells[228920]={name="Ravager",icon="warrior_talent_icon_ravager",type="Burst",class="WARRIOR",specs={},cd=90,charges=1,chargeCd=90,recovery=8,talentGated=true,cdMods={[382953]=-90},chargeAdds={[382953]=1},buffs={228920},track="buff"}
ns.Spells[232633]={name="Arcane Torrent",icon="spell_shadow_teleport",type="Racial",specs={},cd=120,races={10},classes={"PRIEST"},track="none"}
ns.Spells[255647]={name="Light's Judgment",icon="ability_racial_orbitalstrike",type="Racial",specs={},cd=150,races={30},track="none"}
ns.Spells[255654]={name="Bull Rush",icon="ability_racial_bullrush",type="Racial",specs={},cd=120,races={28},buffs={255654},track="buff"}
ns.Spells[256948]={name="Spatial Rift",icon="ability_racial_spatialrift",type="Racial",specs={},cd=180,races={29},buffs={256948},track="buff"}
ns.Spells[260364]={name="Arcane Pulse",icon="ability_racial_forceshield",type="Racial",specs={},cd=180,races={27},track="none"}
ns.Spells[264735]={name="Survival of the Fittest",icon="spell_nature_spiritarmor",type="Personal",class="HUNTER",specs={},cd=90,charges=1,chargeCd=90,talentGated=true,chargeAdds={[459450]=1},buffs={264735},track="buff"}
ns.Spells[265187]={name="Summon Demonic Tyrant",icon="inv_summondemonictyrant",type="Burst",class="WARLOCK",specs={},cd=60,talentGated=true,cdMods={[387084]=-30},buffs={265187},track="buff"}
ns.Spells[265221]={name="Fireblood",icon="ability_racial_fireblood",type="Racial",specs={},cd=120,races={34},buffs={265226},track="buff"}
ns.Spells[274738]={name="Ancestral Call",icon="ability_racial_ancestralcall",type="Racial",specs={},cd=120,races={36},buffs={274738},track="buff"}
ns.Spells[278326]={name="Consume Magic",icon="spell_misc_zandalari_council_soulswap",type="Purge",class="DEMONHUNTER",specs={},cd=10,talentGated=true,track="none"}
ns.Spells[279302]={name="Frostwyrm's Fury",icon="achievement_boss_sindragosa",type="Burst",class="DEATHKNIGHT",specs={},cd=90,talentGated=true,track="none"}
ns.Spells[287712]={name="Haymaker",icon="ability_racial_haymaker",type="Racial",specs={},cd=150,races={32},track="none"}
ns.Spells[288613]={name="Trueshot",icon="ability_trueshot",type="Burst",class="HUNTER",specs={},cd=120,talentGated=true,cdMods={[260404]=-30},buffs={288613},track="buff"}
ns.Spells[291944]={name="Regeneratin'",icon="ability_racial_regeneratin",type="Racial",specs={},cd=180,races={31},buffs={291944},track="buff"}
ns.Spells[305483]={name="Lightning Lasso",icon="shaman_pvp_lightninglasso",type="Stun",class="SHAMAN",specs={},cd=45,talentGated=true,debuffs={305485},track="debuff"}
ns.Spells[312411]={name="Bag of Tricks",icon="ability_racial_bagoftricks",type="Racial",specs={},cd=90,races={35},track="none"}
ns.Spells[312924]={name="Hyper Organic Light Originator",icon="ability_racial_hyperorganiclightoriginator",type="Racial",specs={},cd=180,races={37},buffs={312924},track="buff"}
ns.Spells[322507]={name="Celestial Brew",icon="ability_monk_ironskinbrew",type="Personal",class="MONK",specs={},cd=90,charges=1,chargeCd=90,talentGated=true,chargePct={[325093]=-20},chargeAdds={[450892]=1},buffs={322507},track="buff"}
ns.Spells[342245]={name="Alter Time",icon="spell_mage_altertime",type="Personal",class="MAGE",specs={},cd=60,talentGated=true,buffs={342246},track="buff"}
ns.Spells[351338]={name="Quell",icon="ability_evoker_quell",type="Kick",class="EVOKER",specs={},cd=20,talentGated=true,cdMods={[371016]=-20},track="kick"}
ns.Spells[357170]={name="Time Dilation",icon="ability_evoker_timedilation",type="External",class="EVOKER",specs={},cd=60,charges=1,chargeCd=60,recovery=1,talentGated=true,chargeMods={[376204]=-10},chargeAdds={[376204]=1},buffs={357170},track="target"}
ns.Spells[357210]={name="Deep Breath",icon="ability_evoker_deepbreath",type="Burst",class="EVOKER",specs={1468},cd=120,charges=1,chargeCd=120,recovery=1,chargeMods={[386348]=-60},buffs={357210},track="buff"}
ns.Spells[357214]={name="Wing Buffet",icon="ability_racial_wingbuffet",type="CC",class="EVOKER",specs={},cd=180,aoe=true,debuffs={357214},track="debuff"}
ns.Spells[358385]={name="Landslide",icon="ability_earthen_pillar",type="CC",class="EVOKER",specs={},cd=90,talentGated=true,cdMods={[375528]=-30},aoe=true,debuffs={355689},track="debuff"}
ns.Spells[359816]={name="Dream Flight",icon="ability_evoker_dreamflight",type="Group",class="EVOKER",specs={},cd=120,talentGated=true,buffs={359816},track="buff"}
ns.Spells[360194]={name="Deathmark",icon="ability_rogue_deathmark",type="Burst",class="ROGUE",specs={},cd=120,talentGated=true,track="none"}
ns.Spells[360823]={name="Naturalize",icon="ability_evoker_fontofmagic_green",type="Dispel",class="EVOKER",specs={1468},cd=8,track="none"}
ns.Spells[363534]={name="Rewind",icon="ability_evoker_rewind",type="Group",class="EVOKER",specs={},cd=240,charges=1,chargeCd=240,talentGated=true,chargeMods={[381922]=-60},buffs={363534},track="buff"}
ns.Spells[363916]={name="Obsidian Scales",icon="inv_artifact_dragonscales",type="Personal",class="EVOKER",specs={},cd=90,charges=1,chargeCd=90,recovery=1,talentGated=true,chargePct={[412713]=-10},chargeAdds={[375406]=1},buffs={363916},track="buff"}
ns.Spells[365350]={name="Arcane Surge",icon="ability_mage_arcanesurge",type="Burst",class="MAGE",specs={},cd=90,talentGated=true,buffs={365362},track="buff"}
ns.Spells[365585]={name="Expunge",icon="ability_evoker_fontofmagic_green",type="Dispel",class="EVOKER",specs={},cd=8,talentGated=true,track="none"}
ns.Spells[368970]={name="Tail Swipe",icon="ability_racial_tailswipe",type="CC",class="EVOKER",specs={},cd=180,aoe=true,debuffs={368970},track="debuff"}
ns.Spells[370626]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"ROGUE"},buffs={370626},track="buff"}
ns.Spells[370965]={name="The Hunt",icon="inv_ability_demonhunter_thehunt",type="Burst",class="DEMONHUNTER",specs={},cd=90,talentGated=true,buffs={370965,370967},track="buff"}
ns.Spells[374227]={name="Zephyr",icon="ability_evoker_hoverblack",type="Group",class="EVOKER",specs={},cd=120,talentGated=true,buffs={374227},track="buff"}
ns.Spells[374251]={name="Cauterizing Flame",icon="ability_evoker_fontofmagic_red",type="Dispel",class="EVOKER",specs={},cd=60,talentGated=true,track="none"}
ns.Spells[374968]={name="Time Spiral",icon="ability_evoker_timespiral",type="Movement",class="EVOKER",specs={},cd=120,talentGated=true,track="none"}
ns.Spells[375087]={name="Dragonrage",icon="ability_evoker_dragonrage",type="Burst",class="EVOKER",specs={},cd=120,talentGated=true,buffs={375087},track="buff"}
ns.Spells[378773]={name="Greater Purge",icon="spell_shaman_focusedstrikes",type="Purge",class="SHAMAN",specs={},cd=12,talentGated=true,track="none"}
ns.Spells[383013]={name="Poison Cleansing Totem",icon="spell_nature_poisoncleansingtotem",type="Dispel",class="SHAMAN",specs={},cd=120,talentGated=true,track="none"}
ns.Spells[383121]={name="Mass Polymorph",icon="spell_nature_doublepolymorph1",type="CC",class="MAGE",specs={},cd=60,talentGated=true,aoe=true,debuffs={383121},track="debuff"}
ns.Spells[383762]={name="Bitter Immunity",icon="spell_nature_shamanrage",type="Personal",class="WARRIOR",specs={},cd=180,talentGated=true,track="none"}
ns.Spells[384352]={name="Doom Winds",icon="ability_ironmaidens_swirlingvortex",type="Burst",class="SHAMAN",specs={},cd=60,talentGated=true,buffs={466772},track="buff"}
ns.Spells[386071]={name="Disrupting Shout",icon="ability_bullrush",type="Kick",class="WARRIOR",specs={},cd=90,talentGated=true,track="kick"}
ns.Spells[388615]={name="Restoral",icon="ability_monk_tigerstyle",type="Group",class="MONK",specs={},cd=180,charges=1,chargeCd=180,recovery=1,talentGated=true,chargeMods={[388551]=-30},track="none"}
ns.Spells[389539]={name="Sentinel",icon="spell_holy_holynova",type="Personal",class="PALADIN",specs={},cd=120,talentGated=true,cdPct={[204074]=-50},replaces={31884},buffs={389539},track="buff"}
ns.Spells[391528]={name="Convoke the Spirits",icon="inv_ability_druid_convokethespirits",type="Burst",class="DRUID",specs={},cd=120,talentGated=true,cdPct={[393414]=-50,[393991]=-50},buffs={391528},track="buff"}
ns.Spells[403631]={name="Breath of Eons",icon="ability_evoker_breathofeons",type="Burst",class="EVOKER",specs={},cd=120,talentGated=true,replaces={357210},buffs={403631},track="buff"}
ns.Spells[403876]={name="Divine Protection",icon="spell_holy_divineprotection",type="Personal",class="PALADIN",specs={70},cd=60,cdMods={[1258011]=30},cdPct={[114154]=-30},specMods={[70]={1258011}},buffs={403876},track="buff"}
ns.Spells[404977]={name="Time Skip",icon="ability_evoker_timeskip",type="Burst",class="EVOKER",specs={},cd=180,talentGated=true,buffs={404977},track="buff"}
ns.Spells[414658]={name="Ice Cold",icon="spell_fire_bluefire",type="Personal",class="MAGE",specs={},cd=240,charges=1,chargeCd=240,talentGated=true,chargeMods={[382424]=-30,[1244110]=-30,[1265517]=-30},chargeAdds={[1244110]=1},replaces={45438},buffs={414658},track="buff"}
ns.Spells[416250]={name="Gift of the Naaru",icon="spell_holy_holyprotection",type="Racial",specs={},cd=120,races={11},classes={"WARLOCK"},buffs={416250},track="buff"}
ns.Spells[421453]={name="Ultimate Penitence",icon="ability_priest_ascendance",type="Group",class="PRIEST",specs={},cd=240,talentGated=true,buffs={421453},track="buff"}
ns.Spells[433874]={name="Deep Breath",icon="ability_evoker_deepbreath",type="Burst",class="EVOKER",specs={},cd=120,charges=1,chargeCd=120,recovery=1,chargeMods={[386348]=-60},replaces={1236943},buffs={433874},track="buff"}
ns.Spells[436344]={name="Azerite Surge",icon="ability_earthen_azeritesurge",type="Racial",specs={},cd=120,races={84,85},buffs={436344},track="buff"}
ns.Spells[446035]={name="Bladestorm",icon="ability_warrior_bladestorm",type="Burst",class="WARRIOR",specs={},cd=90,charges=1,chargeCd=90,recovery=90,cdMods={[382953]=-90},chargeAdds={[382953]=1},replaces={227847},buffs={446035},track="buff"}
ns.Spells[471195]={name="Lay on Hands",icon="spell_holy_layonhands",type="External",class="PALADIN",specs={},cd=600,cdPct={[114154]=-30,[378425]=-15,[414720]=-40},replaces={633},track="target"}
ns.Spells[474421]={name="Intimidation",icon="artifactability_survivalhunter_eaglesbite",type="Stun",class="HUNTER",specs={},cd=60,talentGated=true,cdMods={[459507]=-20},debuffs={24394},track="debuff"}
ns.Spells[1233448]={name="Dark Transformation",icon="achievement_boss_festergutrotface",type="Burst",class="DEATHKNIGHT",specs={},cd=45,talentGated=true,buffs={1233448},track="buff"}
ns.Spells[1234195]={name="Void Nova",icon="inv_12_voiddh_ability_voidnova",type="Stun",class="DEMONHUNTER",specs={},cd=45,talentGated=true,aoe=true,debuffs={1234195},track="debuff"}
ns.Spells[1236943]={name="Deep Breath",icon="ability_evoker_deepbreath",type="Burst",class="EVOKER",specs={1467},cd=120,buffs={1236943},track="buff"}
ns.Spells[1237885]={name="Thorn Bloom",icon="inv_12_haranir_ability_thornbloom",type="Racial",specs={},cd=180,races={86,91},buffs={1238467},track="buff"}
ns.Spells[1246167]={name="The Hunt",icon="inv_12_voiddh_ability_thehunt",type="Burst",class="DEMONHUNTER",specs={},cd=90,talentGated=true,buffs={1246167,370967},track="buff"}
ns.Spells[1249625]={name="Zenith",icon="inv_ability_monk_weaponsoforder",type="Burst",class="MONK",specs={},cd=90,charges=2,chargeCd=90,recovery=16,talentGated=true,chargeMods={[280197]=-20,[450989]=-10},buffs={1249625},track="buff"}
ns.Spells[1249658]={name="Breath of Sindragosa",icon="spell_deathknight_breathofsindragosa",type="Burst",class="DEATHKNIGHT",specs={},cd=90,talentGated=true,buffs={1249658},track="buff"}
ns.Spells[1250646]={name="Takedown",icon="inv12_ability_hunter_takedown",type="Burst",class="HUNTER",specs={},cd=90,talentGated=true,cdMods={[1251790]=-15},buffs={1250646},track="buff"}
ns.Spells[1263569]={name="Abomination Limb",icon="ability_maldraxxus_deathknight",type="CC",class="DEATHKNIGHT",specs={},cd=120,talentGated=true,buffs={1263569},debuffs={1263566},track="debuff"}
ns.Spells[1276452]={name="Grimoire: Imp Lord",icon="inv_imp3_purple",type="Burst",class="WARLOCK",specs={},cd=120,talentGated=true,track="none"}
ns.TalentEntries[24540]=394207
ns.TalentEntries[51794]=394182
ns.TalentEntries[51798]=394181
ns.TalentEntries[51808]=394178
ns.TalentEntries[51812]=394177
ns.TalentEntries[80141]=414658
ns.TalentEntries[80142]=1265517
ns.TalentEntries[80144]=113724
ns.TalentEntries[80153]=382268
ns.TalentEntries[80174]=342245
ns.TalentEntries[80175]=475
ns.TalentEntries[80181]=45438
ns.TalentEntries[80182]=382424
ns.TalentEntries[80183]=55342
ns.TalentEntries[80189]=387807
ns.TalentEntries[87584]=375528
ns.TalentEntries[87597]=359816
ns.TalentEntries[87601]=376204
ns.TalentEntries[87612]=363534
ns.TalentEntries[87613]=357170
ns.TalentEntries[87619]=381922
ns.TalentEntries[87623]=376150
ns.TalentEntries[87639]=411164
ns.TalentEntries[87654]=386348
ns.TalentEntries[87665]=375087
ns.TalentEntries[87667]=371016
ns.TalentEntries[87676]=374968
ns.TalentEntries[87680]=375577
ns.TalentEntries[87682]=374227
ns.TalentEntries[87686]=365933
ns.TalentEntries[87687]=374346
ns.TalentEntries[87692]=351338
ns.TalentEntries[87700]=374251
ns.TalentEntries[87701]=375406
ns.TalentEntries[87702]=363916
ns.TalentEntries[87708]=358385
ns.TalentEntries[87716]=365585
ns.TalentEntries[91440]=386113
ns.TalentEntries[91444]=108416
ns.TalentEntries[91451]=1270255
ns.TalentEntries[91452]=6789
ns.TalentEntries[91457]=30283
ns.TalentEntries[91458]=5484
ns.TalentEntries[91467]=386659
ns.TalentEntries[91489]=1280483
ns.TalentEntries[91502]=1122
ns.TalentEntries[91554]=205180
ns.TalentEntries[91581]=388827
ns.TalentEntries[91587]=231793
ns.TalentEntries[96170]=108199
ns.TalentEntries[96172]=207167
ns.TalentEntries[96174]=205727
ns.TalentEntries[96176]=374383
ns.TalentEntries[96178]=457574
ns.TalentEntries[96187]=389682
ns.TalentEntries[96193]=221562
ns.TalentEntries[96194]=51052
ns.TalentEntries[96204]=48743
ns.TalentEntries[96210]=48792
ns.TalentEntries[96213]=47528
ns.TalentEntries[96215]=454786
ns.TalentEntries[96222]=1249658
ns.TalentEntries[96236]=279302
ns.TalentEntries[96260]=377637
ns.TalentEntries[96269]=49028
ns.TalentEntries[96308]=55233
ns.TalentEntries[96322]=1233448
ns.TalentEntries[96333]=42650
ns.TalentEntries[100543]=187707
ns.TalentEntries[101377]=388615
ns.TalentEntries[101378]=115310
ns.TalentEntries[101381]=388212
ns.TalentEntries[101389]=202424
ns.TalentEntries[101390]=116849
ns.TalentEntries[101398]=388551
ns.TalentEntries[101416]=218164
ns.TalentEntries[101420]=122470
ns.TalentEntries[101427]=280197
ns.TalentEntries[101429]=137639
ns.TalentEntries[101431]=391330
ns.TalentEntries[101439]=387035
ns.TalentEntries[101443]=387230
ns.TalentEntries[101448]=325093
ns.TalentEntries[101463]=322507
ns.TalentEntries[101470]=115203
ns.TalentEntries[101471]=343743
ns.TalentEntries[101473]=123904
ns.TalentEntries[101481]=392986
ns.TalentEntries[101496]=115203
ns.TalentEntries[101497]=388813
ns.TalentEntries[101503]=115173
ns.TalentEntries[101504]=116705
ns.TalentEntries[101505]=344359
ns.TalentEntries[101506]=115078
ns.TalentEntries[101515]=122783
ns.TalentEntries[101516]=116844
ns.TalentEntries[101521]=394123
ns.TalentEntries[101522]=122278
ns.TalentEntries[101531]=328669
ns.TalentEntries[101541]=383707
ns.TalentEntries[101547]=115176
ns.TalentEntries[101806]=334033
ns.TalentEntries[101813]=384444
ns.TalentEntries[101824]=384352
ns.TalentEntries[101825]=319930
ns.TalentEntries[101850]=333919
ns.TalentEntries[101860]=114050
ns.TalentEntries[101899]=382030
ns.TalentEntries[101900]=392916
ns.TalentEntries[101912]=114052
ns.TalentEntries[101913]=462440
ns.TalentEntries[101924]=98008
ns.TalentEntries[101942]=333919
ns.TalentEntries[102440]=204074
ns.TalentEntries[102445]=31850
ns.TalentEntries[102448]=31884
ns.TalentEntries[102456]=86659
ns.TalentEntries[102466]=389539
ns.TalentEntries[102471]=31935
ns.TalentEntries[102476]=213644
ns.TalentEntries[102491]=383228
ns.TalentEntries[102505]=405461
ns.TalentEntries[102519]=31884
ns.TalentEntries[102547]=392911
ns.TalentEntries[102548]=31821
ns.TalentEntries[102556]=414720
ns.TalentEntries[102568]=216331
ns.TalentEntries[102569]=31884
ns.TalentEntries[102572]=1241511
ns.TalentEntries[102583]=633
ns.TalentEntries[102584]=115750
ns.TalentEntries[102591]=96231
ns.TalentEntries[102592]=230332
ns.TalentEntries[102595]=384820
ns.TalentEntries[102600]=204023
ns.TalentEntries[102602]=6940
ns.TalentEntries[102603]=114154
ns.TalentEntries[102604]=1022
ns.TalentEntries[102606]=384909
ns.TalentEntries[102623]=10326
ns.TalentEntries[102626]=218164
ns.TalentEntries[103102]=382550
ns.TalentEntries[103108]=740
ns.TalentEntries[103119]=391528
ns.TalentEntries[103120]=33891
ns.TalentEntries[103139]=382552
ns.TalentEntries[103141]=102342
ns.TalentEntries[103161]=391174
ns.TalentEntries[103162]=106951
ns.TalentEntries[103174]=1244544
ns.TalentEntries[103177]=391528
ns.TalentEntries[103178]=102543
ns.TalentEntries[103180]=61336
ns.TalentEntries[103193]=61336
ns.TalentEntries[103199]=393414
ns.TalentEntries[103200]=391528
ns.TalentEntries[103201]=102558
ns.TalentEntries[103210]=203965
ns.TalentEntries[103216]=50334
ns.TalentEntries[103229]=377811
ns.TalentEntries[103285]=102359
ns.TalentEntries[103287]=132469
ns.TalentEntries[103299]=22570
ns.TalentEntries[103307]=2908
ns.TalentEntries[103308]=288826
ns.TalentEntries[103312]=106898
ns.TalentEntries[103315]=5211
ns.TalentEntries[103316]=99
ns.TalentEntries[103320]=2782
ns.TalentEntries[103322]=106839
ns.TalentEntries[103674]=228260
ns.TalentEntries[103687]=62618
ns.TalentEntries[103713]=33206
ns.TalentEntries[103714]=373035
ns.TalentEntries[103720]=390684
ns.TalentEntries[103721]=322115
ns.TalentEntries[103733]=1215275
ns.TalentEntries[103743]=235587
ns.TalentEntries[103747]=419110
ns.TalentEntries[103755]=64843
ns.TalentEntries[103774]=47788
ns.TalentEntries[103776]=88625
ns.TalentEntries[103795]=406788
ns.TalentEntries[103834]=10060
ns.TalentEntries[103836]=390670
ns.TalentEntries[103849]=390620
ns.TalentEntries[103851]=8122
ns.TalentEntries[103854]=213634
ns.TalentEntries[103860]=196704
ns.TalentEntries[103871]=1246549
ns.TalentEntries[109838]=391528
ns.TalentEntries[109839]=102560
ns.TalentEntries[109847]=394121
ns.TalentEntries[109849]=194223
ns.TalentEntries[109850]=1240188
ns.TalentEntries[109855]=390378
ns.TalentEntries[109856]=468743
ns.TalentEntries[109864]=393991
ns.TalentEntries[109867]=78675
ns.TalentEntries[111886]=204018
ns.TalentEntries[112121]=118038
ns.TalentEntries[112125]=316405
ns.TalentEntries[112131]=385571
ns.TalentEntries[112156]=871
ns.TalentEntries[112174]=397103
ns.TalentEntries[112188]=97462
ns.TalentEntries[112198]=107570
ns.TalentEntries[112210]=1271925
ns.TalentEntries[112219]=202163
ns.TalentEntries[112242]=46968
ns.TalentEntries[112249]=103827
ns.TalentEntries[112259]=383854
ns.TalentEntries[112264]=184364
ns.TalentEntries[112281]=1719
ns.TalentEntries[112284]=227847
ns.TalentEntries[112285]=107574
ns.TalentEntries[112305]=107574
ns.TalentEntries[112314]=227847
ns.TalentEntries[112530]=1259480
ns.TalentEntries[112545]=13750
ns.TalentEntries[112556]=272026
ns.TalentEntries[112560]=256188
ns.TalentEntries[112572]=2094
ns.TalentEntries[112575]=231691
ns.TalentEntries[112583]=394931
ns.TalentEntries[112585]=31224
ns.TalentEntries[112614]=121471
ns.TalentEntries[112616]=382503
ns.TalentEntries[112630]=5938
ns.TalentEntries[112631]=1776
ns.TalentEntries[112646]=423647
ns.TalentEntries[112654]=5277
ns.TalentEntries[112662]=360194
ns.TalentEntries[112830]=370965
ns.TalentEntries[112858]=320418
ns.TalentEntries[112859]=207684
ns.TalentEntries[112860]=389849
ns.TalentEntries[112864]=204021
ns.TalentEntries[112876]=389732
ns.TalentEntries[112878]=389718
ns.TalentEntries[112881]=202137
ns.TalentEntries[112886]=320387
ns.TalentEntries[112906]=209281
ns.TalentEntries[112911]=179057
ns.TalentEntries[112912]=389763
ns.TalentEntries[112914]=391397
ns.TalentEntries[112919]=389783
ns.TalentEntries[112921]=196718
ns.TalentEntries[112926]=278326
ns.TalentEntries[112927]=217832
ns.TalentEntries[112944]=389688
ns.TalentEntries[114291]=114051
ns.TalentEntries[114828]=404436
ns.TalentEntries[115023]=403745
ns.TalentEntries[115168]=379391
ns.TalentEntries[115458]=1240906
ns.TalentEntries[115464]=198898
ns.TalentEntries[115465]=379391
ns.TalentEntries[115467]=379391
ns.TalentEntries[115473]=406646
ns.TalentEntries[115533]=404977
ns.TalentEntries[115536]=403631
ns.TalentEntries[115544]=376150
ns.TalentEntries[115570]=381922
ns.TalentEntries[115573]=359816
ns.TalentEntries[115576]=375528
ns.TalentEntries[115597]=375406
ns.TalentEntries[115602]=374251
ns.TalentEntries[115606]=374346
ns.TalentEntries[115613]=363916
ns.TalentEntries[115614]=358385
ns.TalentEntries[115615]=365585
ns.TalentEntries[115629]=411164
ns.TalentEntries[115639]=386348
ns.TalentEntries[115643]=375087
ns.TalentEntries[115645]=351338
ns.TalentEntries[115648]=376204
ns.TalentEntries[115650]=357170
ns.TalentEntries[115651]=363534
ns.TalentEntries[115661]=374227
ns.TalentEntries[115666]=374968
ns.TalentEntries[115667]=365933
ns.TalentEntries[115686]=412713
ns.TalentEntries[115690]=351338
ns.TalentEntries[115877]=110959
ns.TalentEntries[115881]=414969
ns.TalentEntries[115899]=387084
ns.TalentEntries[115902]=265187
ns.TalentEntries[115946]=388827
ns.TalentEntries[115949]=231793
ns.TalentEntries[115955]=387084
ns.TalentEntries[115958]=1122
ns.TalentEntries[115992]=386113
ns.TalentEntries[115998]=6789
ns.TalentEntries[115999]=5484
ns.TalentEntries[116008]=386659
ns.TalentEntries[116011]=30283
ns.TalentEntries[116013]=264874
ns.TalentEntries[116028]=108416
ns.TalentEntries[116035]=389630
ns.TalentEntries[116057]=387084
ns.TalentEntries[116059]=205180
ns.TalentEntries[116182]=421453
ns.TalentEntries[116376]=414073
ns.TalentEntries[116739]=383115
ns.TalentEntries[116754]=386071
ns.TalentEntries[116769]=397103
ns.TalentEntries[116770]=871
ns.TalentEntries[116775]=12975
ns.TalentEntries[116781]=5246
ns.TalentEntries[116841]=316405
ns.TalentEntries[116854]=385571
ns.TalentEntries[116861]=118038
ns.TalentEntries[116888]=1719
ns.TalentEntries[116897]=184364
ns.TalentEntries[116900]=383115
ns.TalentEntries[116902]=383762
ns.TalentEntries[116922]=107574
ns.TalentEntries[116924]=391271
ns.TalentEntries[116927]=107574
ns.TalentEntries[116930]=107574
ns.TalentEntries[116933]=202163
ns.TalentEntries[116945]=382953
ns.TalentEntries[116946]=228920
ns.TalentEntries[116952]=383115
ns.TalentEntries[116957]=97462
ns.TalentEntries[116959]=46968
ns.TalentEntries[116964]=103827
ns.TalentEntries[116966]=391572
ns.TalentEntries[116980]=107570
ns.TalentEntries[116990]=388903
ns.TalentEntries[116992]=382953
ns.TalentEntries[116993]=228920
ns.TalentEntries[116995]=388049
ns.TalentEntries[116998]=383854
ns.TalentEntries[117000]=383293
ns.TalentEntries[117009]=227847
ns.TalentEntries[117010]=383338
ns.TalentEntries[117146]=423662
ns.TalentEntries[117236]=431067
ns.TalentEntries[117282]=440681
ns.TalentEntries[117286]=1248423
ns.TalentEntries[117414]=436162
ns.TalentEntries[117421]=449707
ns.TalentEntries[117466]=443418
ns.TalentEntries[117486]=454026
ns.TalentEntries[117544]=431715
ns.TalentEntries[117545]=429483
ns.TalentEntries[117547]=1264269
ns.TalentEntries[117577]=1253887
ns.TalentEntries[117618]=450892
ns.TalentEntries[117646]=437122
ns.TalentEntries[117651]=444099
ns.TalentEntries[117715]=441274
ns.TalentEntries[117740]=200733
ns.TalentEntries[117741]=427775
ns.TalentEntries[117755]=1266307
ns.TalentEntries[117759]=320416
ns.TalentEntries[117768]=429211
ns.TalentEntries[117802]=122278
ns.TalentEntries[117804]=122278
ns.TalentEntries[117876]=432804
ns.TalentEntries[117895]=428937
ns.TalentEntries[118837]=429072
ns.TalentEntries[118850]=391271
ns.TalentEntries[119249]=443047
ns.TalentEntries[119753]=442640
ns.TalentEntries[119840]=442630
ns.TalentEntries[119844]=442626
ns.TalentEntries[119858]=440992
ns.TalentEntries[120133]=441415
ns.TalentEntries[122402]=449950
ns.TalentEntries[122408]=449238
ns.TalentEntries[122663]=453797
ns.TalentEntries[122665]=453796
ns.TalentEntries[122667]=453765
ns.TalentEntries[122669]=453764
ns.TalentEntries[123416]=1264365
ns.TalentEntries[123751]=449025
ns.TalentEntries[123868]=451211
ns.TalentEntries[124756]=190319
ns.TalentEntries[124771]=205029
ns.TalentEntries[124789]=1254194
ns.TalentEntries[124793]=387044
ns.TalentEntries[124809]=451485
ns.TalentEntries[124812]=451576
ns.TalentEntries[124824]=280197
ns.TalentEntries[124826]=1249625
ns.TalentEntries[124835]=391330
ns.TalentEntries[124841]=322507
ns.TalentEntries[124842]=115203
ns.TalentEntries[124844]=1262334
ns.TalentEntries[124852]=387230
ns.TalentEntries[124858]=325093
ns.TalentEntries[124867]=218164
ns.TalentEntries[124869]=388551
ns.TalentEntries[124875]=116849
ns.TalentEntries[124878]=202424
ns.TalentEntries[124894]=388212
ns.TalentEntries[124918]=388615
ns.TalentEntries[124919]=115310
ns.TalentEntries[124925]=198898
ns.TalentEntries[124926]=116844
ns.TalentEntries[124932]=115078
ns.TalentEntries[124941]=218164
ns.TalentEntries[124943]=116705
ns.TalentEntries[124957]=450448
ns.TalentEntries[124963]=449582
ns.TalentEntries[124968]=115203
ns.TalentEntries[124969]=388813
ns.TalentEntries[124975]=394123
ns.TalentEntries[124982]=115173
ns.TalentEntries[124983]=344359
ns.TalentEntries[124999]=383707
ns.TalentEntries[125036]=450892
ns.TalentEntries[125062]=123904
ns.TalentEntries[125072]=450989
ns.TalentEntries[125076]=1272844
ns.TalentEntries[125140]=454433
ns.TalentEntries[125141]=455530
ns.TalentEntries[125145]=455529
ns.TalentEntries[125155]=455527
ns.TalentEntries[125159]=455526
ns.TalentEntries[125614]=382513
ns.TalentEntries[125619]=394930
ns.TalentEntries[125818]=157980
ns.TalentEntries[125819]=31661
ns.TalentEntries[125850]=265187
ns.TalentEntries[125874]=51271
ns.TalentEntries[125932]=173841
ns.TalentEntries[126015]=356367
ns.TalentEntries[126060]=1244031
ns.TalentEntries[126345]=264332
ns.TalentEntries[126352]=147362
ns.TalentEntries[126402]=19574
ns.TalentEntries[126431]=269737
ns.TalentEntries[126436]=231548
ns.TalentEntries[126458]=459507
ns.TalentEntries[126461]=19577
ns.TalentEntries[126465]=270581
ns.TalentEntries[126466]=147362
ns.TalentEntries[126470]=459450
ns.TalentEntries[126476]=459546
ns.TalentEntries[126481]=266921
ns.TalentEntries[126483]=343247
ns.TalentEntries[126488]=264735
ns.TalentEntries[126490]=1258485
ns.TalentEntries[126519]=365350
ns.TalentEntries[126545]=384651
ns.TalentEntries[126885]=381785
ns.TalentEntries[126892]=392714
ns.TalentEntries[126902]=334033
ns.TalentEntries[126928]=262624
ns.TalentEntries[126934]=319930
ns.TalentEntries[126936]=384352
ns.TalentEntries[126939]=384444
ns.TalentEntries[126941]=114051
ns.TalentEntries[126950]=392916
ns.TalentEntries[126953]=98008
ns.TalentEntries[126960]=382030
ns.TalentEntries[126963]=207399
ns.TalentEntries[126964]=198838
ns.TalentEntries[126974]=462440
ns.TalentEntries[126975]=114052
ns.TalentEntries[126976]=333919
ns.TalentEntries[126977]=108280
ns.TalentEntries[126984]=382046
ns.TalentEntries[126997]=392763
ns.TalentEntries[127013]=114050
ns.TalentEntries[127016]=378266
ns.TalentEntries[127023]=333919
ns.TalentEntries[127027]=192249
ns.TalentEntries[127028]=198067
ns.TalentEntries[127041]=378773
ns.TalentEntries[127045]=381647
ns.TalentEntries[127046]=108271
ns.TalentEntries[127048]=381867
ns.TalentEntries[127050]=204268
ns.TalentEntries[127051]=51514
ns.TalentEntries[127053]=265046
ns.TalentEntries[127054]=192058
ns.TalentEntries[127055]=57994
ns.TalentEntries[127058]=192077
ns.TalentEntries[127061]=51886
ns.TalentEntries[127062]=392915
ns.TalentEntries[127065]=305483
ns.TalentEntries[127066]=378779
ns.TalentEntries[127067]=51490
ns.TalentEntries[127072]=383013
ns.TalentEntries[127076]=381678
ns.TalentEntries[127080]=192088
ns.TalentEntries[127099]=454026
ns.TalentEntries[127107]=443418
ns.TalentEntries[127141]=381785
ns.TalentEntries[127148]=392714
ns.TalentEntries[127158]=334033
ns.TalentEntries[127184]=262624
ns.TalentEntries[127190]=319930
ns.TalentEntries[127192]=384352
ns.TalentEntries[127195]=384444
ns.TalentEntries[127197]=114051
ns.TalentEntries[127206]=392916
ns.TalentEntries[127209]=98008
ns.TalentEntries[127216]=382030
ns.TalentEntries[127219]=207399
ns.TalentEntries[127220]=198838
ns.TalentEntries[127230]=462440
ns.TalentEntries[127231]=114052
ns.TalentEntries[127232]=333919
ns.TalentEntries[127233]=108280
ns.TalentEntries[127240]=382046
ns.TalentEntries[127253]=392763
ns.TalentEntries[127269]=114050
ns.TalentEntries[127272]=378266
ns.TalentEntries[127279]=333919
ns.TalentEntries[127283]=192249
ns.TalentEntries[127284]=198067
ns.TalentEntries[127297]=378773
ns.TalentEntries[127301]=381647
ns.TalentEntries[127302]=108271
ns.TalentEntries[127304]=381867
ns.TalentEntries[127306]=204268
ns.TalentEntries[127307]=51514
ns.TalentEntries[127309]=265046
ns.TalentEntries[127310]=192058
ns.TalentEntries[127311]=57994
ns.TalentEntries[127314]=192077
ns.TalentEntries[127317]=51886
ns.TalentEntries[127318]=392915
ns.TalentEntries[127321]=305483
ns.TalentEntries[127322]=378779
ns.TalentEntries[127323]=51490
ns.TalentEntries[127328]=383013
ns.TalentEntries[127332]=381678
ns.TalentEntries[127336]=192088
ns.TalentEntries[127355]=454026
ns.TalentEntries[127363]=443418
ns.TalentEntries[127851]=192058
ns.TalentEntries[127863]=392915
ns.TalentEntries[127875]=204268
ns.TalentEntries[127884]=51886
ns.TalentEntries[127888]=381647
ns.TalentEntries[127892]=57994
ns.TalentEntries[127893]=108271
ns.TalentEntries[127896]=265046
ns.TalentEntries[127903]=51514
ns.TalentEntries[127904]=378773
ns.TalentEntries[127908]=192088
ns.TalentEntries[127909]=192077
ns.TalentEntries[127912]=378266
ns.TalentEntries[127921]=462440
ns.TalentEntries[128223]=468571
ns.TalentEntries[128247]=469325
ns.TalentEntries[128253]=469409
ns.TalentEntries[128278]=1246481
ns.TalentEntries[128367]=288613
ns.TalentEntries[128379]=260404
ns.TalentEntries[128412]=19577
ns.TalentEntries[128413]=474421
ns.TalentEntries[128582]=400140
ns.TalentEntries[128589]=102793
ns.TalentEntries[128715]=321460
ns.TalentEntries[128902]=1227943
ns.TalentEntries[128906]=1227935
ns.TalentEntries[128916]=1228064
ns.TalentEntries[128920]=1228062
ns.TalentEntries[129353]=1223016
ns.TalentEntries[130226]=1225600
ns.TalentEntries[130815]=1226061
ns.TalentEntries[130819]=1226060
ns.TalentEntries[132133]=1233206
ns.TalentEntries[132135]=1233203
ns.TalentEntries[132289]=1234195
ns.TalentEntries[132880]=228920
ns.TalentEntries[132886]=386071
ns.TalentEntries[133503]=1241704
ns.TalentEntries[133546]=377580
ns.TalentEntries[134033]=424742
ns.TalentEntries[134180]=1244110
ns.TalentEntries[134185]=1244069
ns.TalentEntries[134186]=321708
ns.TalentEntries[134189]=210476
ns.TalentEntries[134192]=1244025
ns.TalentEntries[134194]=321745
ns.TalentEntries[134197]=1244340
ns.TalentEntries[134198]=383121
ns.TalentEntries[134254]=5246
ns.TalentEntries[134280]=1246555
ns.TalentEntries[134282]=179057
ns.TalentEntries[134846]=19236
ns.TalentEntries[134850]=288733
ns.TalentEntries[135486]=108280
ns.TalentEntries[135487]=1254251
ns.TalentEntries[135490]=1253035
ns.TalentEntries[135511]=1251790
ns.TalentEntries[135514]=1250646
ns.TalentEntries[135592]=381867
ns.TalentEntries[135608]=416719
ns.TalentEntries[135659]=1253402
ns.TalentEntries[135706]=1258486
ns.TalentEntries[135708]=1258407
ns.TalentEntries[135711]=109248
ns.TalentEntries[135712]=19801
ns.TalentEntries[135719]=462762
ns.TalentEntries[135733]=256165
ns.TalentEntries[135736]=1246167
ns.TalentEntries[135743]=1260484
ns.TalentEntries[135924]=1260616
ns.TalentEntries[135984]=1260644
ns.TalentEntries[136033]=1272326
ns.TalentEntries[136041]=1272359
ns.TalentEntries[136157]=32375
ns.TalentEntries[136213]=1263569
ns.TalentEntries[136466]=205036
ns.TalentEntries[136487]=234299
ns.TalentEntries[136499]=1239537
ns.TalentEntries[136525]=1266818
ns.TalentEntries[136567]=383013
ns.TalentEntries[136581]=1270827
ns.TalentEntries[136594]=96231
ns.TalentEntries[136599]=116705
ns.TalentEntries[136683]=1272136
ns.TalentEntries[136686]=53480
ns.TalentEntries[136699]=1244220
ns.TalentEntries[136702]=228920
ns.TalentEntries[136703]=107574
ns.TalentEntries[136726]=1276452
ns.TalentEntries[136744]=392986
ns.TalentEntries[136883]=1267182
ns.TalentEntries[137032]=1263249
ns.TalentEntries[137507]=200383
ns.TalentEntries[137630]=342245
ns.TalentEntries[137631]=1244340
ns.TalentEntries[137857]=378425
ns.Specs[62]={class="MAGE",role="Damage",name="Arcane",ranged=true}
ns.Specs[63]={class="MAGE",role="Damage",name="Fire",ranged=true}
ns.Specs[64]={class="MAGE",role="Damage",name="Frost",ranged=true}
ns.Specs[65]={class="PALADIN",role="Healer",name="Holy"}
ns.Specs[66]={class="PALADIN",role="Tank",name="Protection"}
ns.Specs[70]={class="PALADIN",role="Damage",name="Retribution"}
ns.Specs[71]={class="WARRIOR",role="Damage",name="Arms"}
ns.Specs[72]={class="WARRIOR",role="Damage",name="Fury"}
ns.Specs[73]={class="WARRIOR",role="Tank",name="Protection"}
ns.Specs[102]={class="DRUID",role="Damage",name="Balance",ranged=true}
ns.Specs[103]={class="DRUID",role="Damage",name="Feral"}
ns.Specs[104]={class="DRUID",role="Tank",name="Guardian"}
ns.Specs[105]={class="DRUID",role="Healer",name="Restoration",ranged=true}
ns.Specs[250]={class="DEATHKNIGHT",role="Tank",name="Blood"}
ns.Specs[251]={class="DEATHKNIGHT",role="Damage",name="Frost"}
ns.Specs[252]={class="DEATHKNIGHT",role="Damage",name="Unholy"}
ns.Specs[253]={class="HUNTER",role="Damage",name="Beast Mastery",ranged=true}
ns.Specs[254]={class="HUNTER",role="Damage",name="Marksmanship",ranged=true}
ns.Specs[255]={class="HUNTER",role="Damage",name="Survival"}
ns.Specs[256]={class="PRIEST",role="Healer",name="Discipline",ranged=true}
ns.Specs[257]={class="PRIEST",role="Healer",name="Holy",ranged=true}
ns.Specs[258]={class="PRIEST",role="Damage",name="Shadow",ranged=true}
ns.Specs[259]={class="ROGUE",role="Damage",name="Assassination"}
ns.Specs[260]={class="ROGUE",role="Damage",name="Outlaw"}
ns.Specs[261]={class="ROGUE",role="Damage",name="Subtlety"}
ns.Specs[262]={class="SHAMAN",role="Damage",name="Elemental",ranged=true}
ns.Specs[263]={class="SHAMAN",role="Damage",name="Enhancement"}
ns.Specs[264]={class="SHAMAN",role="Healer",name="Restoration",ranged=true}
ns.Specs[265]={class="WARLOCK",role="Damage",name="Affliction",ranged=true}
ns.Specs[266]={class="WARLOCK",role="Damage",name="Demonology",ranged=true}
ns.Specs[267]={class="WARLOCK",role="Damage",name="Destruction",ranged=true}
ns.Specs[268]={class="MONK",role="Tank",name="Brewmaster"}
ns.Specs[269]={class="MONK",role="Damage",name="Windwalker"}
ns.Specs[270]={class="MONK",role="Healer",name="Mistweaver"}
ns.Specs[577]={class="DEMONHUNTER",role="Damage",name="Havoc"}
ns.Specs[581]={class="DEMONHUNTER",role="Tank",name="Vengeance"}
ns.Specs[1444]={class="SHAMAN",role="Damage",name="Initial",ranged=true}
ns.Specs[1446]={class="WARRIOR",role="Damage",name="Initial"}
ns.Specs[1447]={class="DRUID",role="Damage",name="Initial",ranged=true}
ns.Specs[1448]={class="HUNTER",role="Damage",name="Initial",ranged=true}
ns.Specs[1449]={class="MAGE",role="Damage",name="Initial",ranged=true}
ns.Specs[1450]={class="MONK",role="Damage",name="Initial"}
ns.Specs[1451]={class="PALADIN",role="Damage",name="Initial"}
ns.Specs[1452]={class="PRIEST",role="Healer",name="Initial",ranged=true}
ns.Specs[1453]={class="ROGUE",role="Damage",name="Initial"}
ns.Specs[1454]={class="WARLOCK",role="Damage",name="Initial",ranged=true}
ns.Specs[1455]={class="DEATHKNIGHT",role="Damage",name="Initial"}
ns.Specs[1456]={class="DEMONHUNTER",role="Damage",name="Initial"}
ns.Specs[1465]={class="EVOKER",role="Damage",name="Initial",ranged=true}
ns.Specs[1467]={class="EVOKER",role="Damage",name="Devastation",ranged=true}
ns.Specs[1468]={class="EVOKER",role="Healer",name="Preservation",ranged=true}
ns.Specs[1473]={class="EVOKER",role="Damage",name="Augmentation",ranged=true}
ns.Specs[1480]={class="DEMONHUNTER",role="Damage",name="Devourer",ranged=true}
ns.Classes[1]="WARRIOR"
ns.Classes[2]="PALADIN"
ns.Classes[3]="HUNTER"
ns.Classes[4]="ROGUE"
ns.Classes[5]="PRIEST"
ns.Classes[6]="DEATHKNIGHT"
ns.Classes[7]="SHAMAN"
ns.Classes[8]="MAGE"
ns.Classes[9]="WARLOCK"
ns.Classes[10]="MONK"
ns.Classes[11]="DRUID"
ns.Classes[12]="DEMONHUNTER"
ns.Classes[13]="EVOKER"
ns.Potions={{item=241288,spell=1236994,buff=1236994,cd=300},{item=241289,spell=1236994,buff=1236994,cd=300},{item=241292,spell=1236998,buff=1236998,cd=300},{item=241293,spell=1236998,buff=1236998,cd=300},{item=241294,spell=1239479,buff=1239479,cd=300},{item=241295,spell=1239479,buff=1239479,cd=300},{item=241296,spell=1238443,buff=1238443,cd=300},{item=241297,spell=1238443,buff=1238443,cd=300},{item=241302,spell=1236551,buff=1236551,cd=300},{item=241303,spell=1236551,buff=1236551,cd=300},{item=241308,spell=1236616,buff=1236616,cd=300},{item=241309,spell=1236616,buff=1236616,cd=300},{item=241338,spell=1236652,buff=1236652,cd=300},{item=241339,spell=1236652,buff=1236652,cd=300},{item=245897,spell=1236616,buff=1236616,cd=300},{item=245898,spell=1236616,buff=1236616,cd=300},{item=245900,spell=1238443,buff=1238443,cd=300},{item=245901,spell=1238443,buff=1238443,cd=300},{item=245902,spell=1236994,buff=1236994,cd=300},{item=245903,spell=1236994,buff=1236994,cd=300},{item=245904,spell=1239479,buff=1239479,cd=300},{item=245905,spell=1239479,buff=1239479,cd=300},{item=245910,spell=1236998,buff=1236998,cd=300},{item=245911,spell=1236998,buff=1236998,cd=300},{item=259092,spell=1264446,buff=1264446,cd=300},{item=259245,spell=1264689,buff=1264689,cd=300},{item=271886,spell=1295132,buff=1295132,cd=300},{item=271887,spell=1295132,buff=1295132,cd=300},{item=271889,spell=1295015,buff=1295015,cd=300},{item=271890,spell=1295015,buff=1295015,cd=300},{item=274763,spell=1295132,buff=1295132,cd=300},{item=274764,spell=1295132,buff=1295132,cd=300},{item=274765,spell=1295015,buff=1295015,cd=300}}
