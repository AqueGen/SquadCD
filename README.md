# SquadCD

SquadCD shows the cooldowns of your party in one place: personal defensives, bursts, interrupts, stuns and CC, external and group saves, racials and potions, as icons that count down when a member uses them. It works in party groups; your own cooldowns can also show without a group.

## What an icon tells you

- Ready: the spell icon is lit.
- Active: the buff is still on the member. The icon stays lit inside a bright frame with a soft glow, and the seconds left are shown in the middle. The game itself supplies that time, so talents that lengthen a buff are included.
- On cooldown: the icon is grey with the seconds left until it is ready.

## Where icons go

- Each type of cooldown goes to the group panel, next to every party frame (Blizzard or EllesmereUI frames), or nowhere. Presets and a layout wizard set this up in a few clicks.
- Click a type in a group or panel section to move it left or right, or to turn it off.
- Layout profiles: each spec of a character can use its own layout, for example panels on the left for damage specs and a horizontal row for a healer. The profile switches with the spec.

## Limits

- Party members have to be near you; the game sends their auras only then.
- Stuns and CC on enemies are seen through enemy nameplates, so nameplates have to be on. If two members have the same stun, both icons start.
- Pet abilities: yours follow your current pet; another member's pet abilities show whatever pet they have out.
- A /reload clears the timers of party members.

## Commands

- `/scd` opens the settings.
- `/scd profile <name>` switches to a layout profile; `/scd profile` lists them.
- `/scd probe` prints what SquadCD can read in your group right now.

Made in Ukraine
