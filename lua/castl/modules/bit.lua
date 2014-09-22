--[[
    Copyright (c) 2014, Paul Bernier
    
    CASTL is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    CASTL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License
    along with CASTL. If not, see <http://www.gnu.org/licenses/>.
--]]

local luajit = jit ~= nil
local band, bor, bnot, bxor, lshift, rshift

-- if executed by LuaJIT use its bit library as base
if luajit then
    band, bor, bnot, bxor, lshift, rshift = bit.band, bit.bor, bit.bnot, bit.bxor, bit.lshift, bit.rshift
else
    -- else use bit32 lib of Lua 5.2
    band, bor, bnot, bxor, lshift, rshift = bit32.band, bit32.bor, bit32.bnot, bit32.bxor, bit32.lshift, bit32.rshift
end

local bit = {}

local ToNumber = require("castl.internal").ToNumber
local floor = math.floor

_ENV = nil

local castToInt = function(v)
    local number = ToNumber(v)
    if (number % 1) ~= 0 then
        return number > 0 and floor(number) or floor(number + 1)
    else
        return number
    end
end

local ToUint32 = function(n)
    return n % 0x100000000
end

bit.lshift = function(x, disp)
    x, disp = castToInt(x), castToInt(disp)
    local shiftCount = band(ToUint32(disp), 0x1F)
    local ret = lshift(x, shiftCount);

    -- Ones' complement
    if band(ret, 0x80000000) > 0 then
        ret = -(bnot(ret) + 1)
    end

    return ret
end

bit.rshift = function(x, disp)
    x, disp = castToInt(x), castToInt(disp)
    if luajit and disp == 0 then
        return ToUint32(x)
    end

    local shiftCount = band(ToUint32(disp), 0x1F)
    return rshift(x, shiftCount)
end

bit.arshift = function(x, disp)
    x, disp = castToInt(x), castToInt(disp)
    local shiftCount = band(ToUint32(disp), 0x1F)
    local ret = rshift(x, shiftCount)

    if x < 0 then
        for i = 31, 31 - shiftCount, -1 do
            -- set bit to 1
            ret = bor(ret, lshift(1,i))
        end
        -- Ones' complement
        ret = -(bnot(ret) + 1)
    end

    return ret
end

bit.band = function(x, y)
    return band(castToInt(x), castToInt(y))
end

bit.bor = function(x, y)
    return bor(castToInt(x), castToInt(y))
end

bit.bxor = function(x, y)
    return bxor(castToInt(x), castToInt(y))
end

bit.bnot = function(x)
    return bnot(castToInt(x))
end

return bit
