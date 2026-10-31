# Changelog

## 0.1.0 (2026-10-31)


### Features

* aura sensors and probe ([8df87ed](https://github.com/AqueGen/SquadCD/commit/8df87ed4a4d567918f99e44065700508d6fa0ba4))
* cooldown maths ([b5a459b](https://github.com/AqueGen/SquadCD/commit/b5a459bb477f1fbec698be0210bcf0fb2fecb5c6))
* edit mode for panels and member chip at party frames ([cbfe2b8](https://github.com/AqueGen/SquadCD/commit/cbfe2b84b8370592d3fa59163e915a2b24158877))
* emit potion use spell ids in Data.lua ([172024a](https://github.com/AqueGen/SquadCD/commit/172024ad7bd83afed79bd787e99576f6f24b610d))
* enemy stops and CC ([6a1d910](https://github.com/AqueGen/SquadCD/commit/6a1d9102551f028cef914831a82834826165cbe0))
* generated spell data ([accf608](https://github.com/AqueGen/SquadCD/commit/accf608b9363fa304ed8977a3726b0d895aac42e))
* group, spec and talents ([c85b27f](https://github.com/AqueGen/SquadCD/commit/c85b27f3e520ac920bd9e9bb30023690a0e632d0))
* keep timers across reload ([abe11d8](https://github.com/AqueGen/SquadCD/commit/abe11d8c9aafd1348a4d63d399ac8f57d4d289ac))
* layout grid maths, member ordering, next pick and ranged spec flag ([980d457](https://github.com/AqueGen/SquadCD/commit/980d457a83264e7d802f8dc48289a3f94ed07c18))
* layout model with sections, member groups, presets and v1 migration ([fbb9f9a](https://github.com/AqueGen/SquadCD/commit/fbb9f9ad52e2a9004159e4bdf3f68f277ff13565))
* layout wizard with preset, types and order, size and position steps ([4ce0f6a](https://github.com/AqueGen/SquadCD/commit/4ce0f6a15b4a14be9f258dfde80af527424af45f))
* own casts and kicks ([51b7806](https://github.com/AqueGen/SquadCD/commit/51b7806ec082e05c7544939cc861af7da99d042b))
* render panel sections and member groups from the v2 layout ([6cd0e72](https://github.com/AqueGen/SquadCD/commit/6cd0e726a46690e24a33a311e9d3fd07dbfc3468))
* rows and group panel ([bd22b49](https://github.com/AqueGen/SquadCD/commit/bd22b49f353d6010fa1b290e76406b7be8e8d50a))
* settings pages for presets and types, panels and party frames ([ddf6c88](https://github.com/AqueGen/SquadCD/commit/ddf6c88655039908c352b7fb68e132ebf512fd40))
* settings window ([cd0530e](https://github.com/AqueGen/SquadCD/commit/cd0530ef4107554b7e6eabbce2ea19bb084eb57a))
* SquadCD icon - party frames with their cooldown icons ([4e9b822](https://github.com/AqueGen/SquadCD/commit/4e9b822f3f5c51bd4a16b4043fc3d6b150f4f214))
* tracker and attribution ([a376a41](https://github.com/AqueGen/SquadCD/commit/a376a417bc952756ea000a8fc53b74fc8eea8482))


### Bug Fixes

* block preset previews in edit mode, ignore UIParent hides, skip dead members for Next, keep migrated icon gap, hold rebuilds during a drag, guard the chip top read ([0d99fa8](https://github.com/AqueGen/SquadCD/commit/0d99fa88e7ee6e7308c22aa1553ab93abe1c885d))
* break dock cycles in Normalize, snap to nearest touching rect, guard infinite offset ([5a43536](https://github.com/AqueGen/SquadCD/commit/5a4353681fd4eccdcfaf185ccf07a10824a831e1))
* canonical racial id for tracking and display, emit racial classes ([45b9e61](https://github.com/AqueGen/SquadCD/commit/45b9e61d09f2e7a861ca99183e10a687e3aab2fe))
* charge, spec and gating rules in cooldown maths ([353bdae](https://github.com/AqueGen/SquadCD/commit/353bdae619092033a63fe0c41c5e3dd13ad69002))
* derive potions from game tables, harden generator ([fb8ce66](https://github.com/AqueGen/SquadCD/commit/fb8ce667a71ffc17e1e84827e802339ecd99b572))
* do not credit the player's kick twice at combat end ([59bb613](https://github.com/AqueGen/SquadCD/commit/59bb61343eb8d4a7fbd0abb5f43ac8a7b8386367))
* dock resting windows to the dropped main panel, clamp after snap, retry demo release, one group constructor ([00ccb9f](https://github.com/AqueGen/SquadCD/commit/00ccb9f26dbd712d4aec929fd547ba58784c02ef))
* drop unspecified-target aura rule, use shared potion cooldown ([61a9a6a](https://github.com/AqueGen/SquadCD/commit/61a9a6a5a5c5d9a9b1bfb5e6163d0dae22fbd8f8))
* forget secret debuff reads after combat ([741bc09](https://github.com/AqueGen/SquadCD/commit/741bc098e06bedcddb7e90fdf0326c3b14ba67cd))
* harden test helpers, xpcall on Lua 5.1, slash usage ([20df495](https://github.com/AqueGen/SquadCD/commit/20df495dffd5c14c4c40e87e0629ba4a10f93b2a))
* hide stale member holders, handle screen resize, one kick per member, reserve panel id ([1e00c2b](https://github.com/AqueGen/SquadCD/commit/1e00c2b0bf9fe6c2c0ce6fc7c1e866ec2d3ba759))
* keep the previous roster when the read is partial ([d89ddee](https://github.com/AqueGen/SquadCD/commit/d89ddeee2aacb8da4cc8172a48f0a03a03f66541))
* move panel sections from the types table, end previews before edit mode, one combat notice per combat ([d77474b](https://github.com/AqueGen/SquadCD/commit/d77474baaabb5cd29a11ccca4e47085740e75ae4))
* normalize saved layouts, drop empty sections on unsplit, add VisibleTypeOf ([aeb106f](https://github.com/AqueGen/SquadCD/commit/aeb106f149b1964dcab9a1905fbe53e27c73cb9a))
* out-of-combat kick settle and kick spell choice ([644a021](https://github.com/AqueGen/SquadCD/commit/644a0212c737bd436891a5b7c77d46e06b7aaaa3))
* panel starts locked ([c8fced6](https://github.com/AqueGen/SquadCD/commit/c8fced63d58f1e796b241b059329fd29482eec20))
* racials by race, icon fallbacks, recharge swipe, tick reuse, late anchor rescan ([df2eb8b](https://github.com/AqueGen/SquadCD/commit/df2eb8b2869e8cb42fd0dcf3df43e592ba5a6b29))
* rebuild at combat end only when pending or anchors changed ([190ff03](https://github.com/AqueGen/SquadCD/commit/190ff031d06a0dd96506f12bc245c964246c45a6))
* reopen settings after the close loop, keep the wizard offer on errors, block edit modes while the wizard is open ([1e483a5](https://github.com/AqueGen/SquadCD/commit/1e483a536976826f02a8dda44bf051e59f5eb53a))
* restore stubbed globals between helper loads ([005eef8](https://github.com/AqueGen/SquadCD/commit/005eef86cb19f7f6bc430d5f16bcd447c9c7abba))
* secret-first checks, valid inspect data, stale units and retry state ([5720536](https://github.com/AqueGen/SquadCD/commit/57205369f2d6fcce35e96cf8e1215272d39893db))
* sense externals on the player, skip stale units and secret ids, extend poll tickers ([66cda5c](https://github.com/AqueGen/SquadCD/commit/66cda5c319dfc2369a3452f4228d5b5c370399dd))
* settings window review round 1 ([88067e1](https://github.com/AqueGen/SquadCD/commit/88067e11b3d8ed72e011c599399803fd82f5ced5))
* show one icon per replaced spell pair ([7eb50ee](https://github.com/AqueGen/SquadCD/commit/7eb50ee99968fcda3c1521af22d3e3539911343d))
* show unseeable party cooldowns as unknown instead of ready ([f71f7f5](https://github.com/AqueGen/SquadCD/commit/f71f7f5fc44105424feae400e09c9a65f135edff))
* shown-only readout, self-test control and retries, self-cast externals ([ad674e8](https://github.com/AqueGen/SquadCD/commit/ad674e8543d04cc6f38fdd58fd8dda480c370be0))
* skip frames with secret visibility when scanning for party buttons ([df2f749](https://github.com/AqueGen/SquadCD/commit/df2f7499dc782fff1a28e65e52518751a008f322))
* track own potions, keep cast id unless the player has the replacer ([8d108e9](https://github.com/AqueGen/SquadCD/commit/8d108e9637c4e7a26beff1e3a37b8dcc6dfa8920))
* tracker derives charges from current talents, read-only State, certain use clears maybes ([3b152be](https://github.com/AqueGen/SquadCD/commit/3b152be1eda96f057f3fb80c44085b659d63bbfa))
* verified enemy debuff ids, own casts, attach settle ([43dd874](https://github.com/AqueGen/SquadCD/commit/43dd874202401dfb29c6e27567b3547e5d2d4243))


### Performance Improvements

* reuse resolved cooldowns per member until the roster changes ([c6be9bd](https://github.com/AqueGen/SquadCD/commit/c6be9bde2061053f367c588b9f9d58f3e2e742ae))


### Continuous Integration

* release pipeline to GitHub and CurseForge ([#4](https://github.com/AqueGen/SquadCD/issues/4)) ([8f42281](https://github.com/AqueGen/SquadCD/commit/8f422812a6430a1e15bf2e1f78e98c1f780955da))
