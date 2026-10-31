-- Copyright (c) 2026 AqueGen. All rights reserved. See LICENSE.
local _, ns = ...

local SecretTime = {}
ns.SecretTime = SecretTime

local CODES = 255
local SPAN = 254

function SecretTime.Unit(cd, dur)
    return math.max(1, math.ceil(2 * (cd + dur + 1) / SPAN))
end

function SecretTime.Period(cd, dur, U)
    return SPAN * U - cd - dur - U
end

function SecretTime.Code(now, epoch, U)
    return math.floor((now - epoch) / U) / CODES
end

function SecretTime.Window(now, epoch, U, span)
    local units = (now - epoch) / U
    return (units - span / U) / CODES, units / CODES
end

function SecretTime.Gate(now, epoch, U, cd)
    local lo = SecretTime.Window(now, epoch, U, cd)
    return lo, lo + 0.5 / CODES
end

local function open(base, slot, now)
    slot.opened = now
    slot.epoch = now - (base.cd + base.dur + base.U)
end

function SecretTime.NewBase(now, cd, dur)
    local U = SecretTime.Unit(cd, dur)
    local base = { U = U, P = SecretTime.Period(cd, dur, U), cd = cd, dur = dur, write = 1, slots = { {}, {} } }
    open(base, base.slots[1], now)
    open(base, base.slots[2], now)
    return base
end

function SecretTime.Roll(base, now)
    if now - base.slots[base.write].opened < base.P then return nil end
    base.write = 3 - base.write
    open(base, base.slots[base.write], now)
    return base.write
end
