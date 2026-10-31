local _, ns = ...

local WHITE = ns.Theme.text

ns.Window.Register("about", function(page)
    local does = page:Group("What Huddle does")
    does:Note({ color = WHITE, text = "Huddle shows your party's cooldowns. Each member gets a row of icons next to their party frame (defensives, burst, racials, potions by default), and one group panel collects the shared tools: externals, kicks, stuns, CC and raid defensives." })
    does:Note("An icon counts down from the moment the spell was used and lights up when it is ready. Blue border: \"maybe\" - two members could have used it and Huddle cannot tell who. Orange dot: that member's talents are not read yet, so the timer uses the base cooldown.")

    local cannot = page:Group("What it cannot do")
    cannot:Note({ color = WHITE, text = "Party only. In a raid group or when you are not in a group, Huddle shows nothing and does no work." })
    cannot:Note("A teammate's spell shows only when it leaves a buff or a debuff the game lets addons see. Spells with no such aura (most dispels, many burst cooldowns) show on your own row only; the Spells page marks them \"not trackable for others\".")
    cannot:Note("When the game hides party buffs from addons (secret mode), teammates' defensives and externals are not tracked. Your own row and kicks still work. The Status page shows which mode is on and why.")

    local start = page:Group("Getting started")
    start:Note("Demo (title bar) shows sample rows and the panel. Unlock panel (title bar) lets you drag the panel; Lock panel fixes it in place. Both work out of combat only. Layout picks Row, Panel or Off per spell type; Look sets sizes and the side of the row.")
end)
