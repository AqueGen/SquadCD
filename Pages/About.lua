-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local WHITE = ns.Theme.text

ns.Window.Register("about", function(page)
    local does = page:Group("What SquadCD does")
    does:Note({ color = WHITE, text = "SquadCD shows your party's cooldowns. Each type of cooldown (defensives, externals, kicks, control, group defensives, dispels, burst, racials, potions, movement) shows either in a section of the group panel, in a member group next to each party frame, or not at all. By default kicks, control, externals and group defensives sit in the panel and each member's defensives, burst, racials and potions sit left of their party frame." })
    does:Note("An icon counts down from the moment the spell was used and lights up when it is ready. In the panel the Next marker shows who presses next on kicks, control, externals and group defensives: the first ready member by role and class priority. Blue border: \"maybe\" - two members could have used it and SquadCD cannot tell who. Orange dot: that member's talents are not read yet, so the timer uses the base cooldown. Grey icon with \"?\": SquadCD cannot see this spell for that member right now, so it may or may not be ready.")

    local cannot = page:Group("What it cannot do")
    cannot:Note({ color = WHITE, text = "No raids. In a raid group SquadCD shows nothing and does no work. Without a group it shows only your own cooldowns, or nothing when Show cooldowns on the Panels page is Only in a group." })
    cannot:Note("A teammate's spell shows only when it leaves a buff or a debuff the game lets addons see. Spells with no such aura (most dispels, many burst cooldowns) show for you only; the Spells page marks them \"not trackable for others\".")
    cannot:Note("When the game hides party buffs from addons (secret mode), teammates' defensives and externals are not tracked and show the grey \"?\". Your own cooldowns and kicks still work. The Status page shows which mode is on and why.")
    cannot:Note("Settings and panel moves change frames, which the game allows out of combat only. A change made in combat applies when combat ends.")

    local start = page:Group("Getting started")
    start:Note("Presets and types: pick a ready layout (Preview, then Apply or Cancel), set where each type shows and its order, and the role and class priority. The Layout wizard walks through the same steps.")
    start:Note("Panels: one panel or a window per section, each section's types, shape and look. At party frames: the member groups and their look.")
    start:Note("Demo (title bar or Presets and types) shows sample members. Move the panels (title bar or Panels) lets you drag and dock the panels; Done or Esc ends.")
end)
