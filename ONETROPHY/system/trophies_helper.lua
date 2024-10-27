--[[ 
	----------Trophy Manager------------
	Tool to preview or modify your psvita trophies

	Licensed by GNU General Public License v3.0

	Designed By:
	- Gdljjrod (https://twitter.com/gdljjrod).

	trophies_helper.lua: constants & functions to help operate bytes or date related to trophy file
	Origin by @ AnalogMan151 (https://github.com/AnalogMan151/PSVTrophyIsGreat)
	Port & implement by @ indefined (https://github.com/indefined)
]]

-- Constants
LOCKED, UNLOCKED = 0x0, 0x1          -- Values for locked and unlocked status of trophy
SYNCED, NOTSYNCED = 0x20, 0x00       -- Values for if a trophy was synced online or not
PL, GO, SI, BR = 0x1, 0x2, 0x3, 0x4  -- Values for trophy types (Platinum, Gold, Silver, Bronze)
NUMOFTROPHY = 0xFF                   -- OFFSET for Number of trophies, found in header of trptitle.dat
BASEPROGRESS = 0x124                 -- OFFSET for base progress
GAMEID1 = 0X290                      -- OFFSET FOR game GAMEID1
GAMEID2 = 0X2D0                      -- OFFSET FOR game GAMEID2
BASETROP1 = 0X104                    -- OFFSET FOR BASE TROP BLOCK1
BASETROP2 = 0X164                    -- OFFSET FOR BASE TROP BLOCK2
GAMEIDSIZE = 9                       -- SIZE OF ID
GROUPSIZE = 0x70                     -- Size of a trophy group block
TRPBLOCK1 = 0x70                     -- Size of TRPTITLE trophy data block1
TRPBLOCK2 = 0x60                     -- Size of TRPTITLE trophy data block2
TRANBLOCK = 0xB0                     -- Size of TRPTRANS trophy block
TROPHYID = 0x13                      -- OFFSET for TROPHY ID, 0 for platinum
TROPTYPE = 0X14                      -- OFFSET for TROPHY TYPE`in block1
TROPGROUP = 0x24                     -- OFFSET for trophy group id in block1
TROPHYSTATE = 0x17                   -- offset in block2, 0 for lock, 1 for unlock
TROPHYSSYNC = 0x1A                   -- offset in block2, 0x00 for unsynced and 0x20 for synced
TROPHYDATE1 = 0x20                   -- offset in block2, Date trophy was unlocked
TROPHYDATE2 = 0x28                   -- offset in block2, Date trophy was synced to PSN?
EMPTYDATE = string.char(0, 0, 0, 0, 0, 0, 0, 0) -- Empty date value

-- Retrieve 4 bytes of data in big endian from passed data set starting at passed offset
function readBE4(data, offset)
    local byteString = data:sub(offset + 1, offset + 4)
	local num = 0
	for i = 1, 4 do num = bit.lshift(num,8) + byteString:byte(i) end
    return num
end

-- Convert int32 number to 4 bytes of data in big endian
function toBE4(num)
	return string.char(
		bit.rshift(num,24),
		bit.rshift(bit.lshift(num,8),24),
		bit.rshift(bit.lshift(num,16),24),
		bit.band(num, 0xff)
	)
end

-- Set a bit of a byte to 1 in position
function clearbit(chr, position)
	local mask = 2^position
	return mask == bit.band(chr, mask) and (chr - mask) or chr
end

-- Clear a bit of a byte to 0 in position
function setbit(chr, position)
	return bit.bor(chr, 2^position)
end

-- Convert a string to HEX string
function toHex(str)
  local hex = ""
  for i = 1, #str do
    hex = hex .. string.format("%02X", str:byte(i))
  end
  return hex
end

-- SonyTime Constants
TIMEDIFF = -3703570395.920896        -- UTC(0001-01-01 00:00:00.000,000) / 0XFFFFFF
TIMESCALE = 16.777252                -- supposed to be 0xFFFFFF / 1e6 = 16.777216, maybe there is error on lua calculation

-- Convert a unix timestamp (seconds) to Sony time bytes
-- Only work with utc 1970 to 2400 or so otherwise it will overflow
function encodeTimestamp(utctime)
	-- convert to microseconds since UTC 1-1-1 00:00:00, first 5 bytes
	local itime = utctime / TIMESCALE - TIMEDIFF
	-- convert remainder to 3 bytes, not accurate but just make it not 0
	local ptime = (itime % 1) * 0xffffff
	local sonytimebytes = string.char(
		0,
		bit.rshift(itime,24),
		bit.rshift(bit.lshift(itime,8),24),
		bit.rshift(bit.lshift(itime,16),24),
		bit.band(itime, 0xff),
		bit.rshift(ptime, 16),
		bit.rshift(bit.band(ptime,0xffff),8),
		bit.band(ptime, 0xff)
	)
	-- print(string.format("encode time: %d, %X, %s", utctime, itime, toHex(sonytimebytes)))
	return sonytimebytes
end

-- Convert Sony time bytes to unix timestamp
function decodeTimestamp(sonytimebytes)
	local sonytime = 0.0
	-- convert only byte 2 to byte 5 because lua can't deal with int64 caculation
	for i = 2, 5 do
		sonytime = sonytime * 256 + sonytimebytes:byte(i)
	end
	-- convert one more byte is enough as lua can only handle 1 second timestamp
	local utctime = (sonytime + sonytimebytes:byte(6)/0xff + TIMEDIFF) * TIMESCALE
	-- print(string.format("decode time: %s, %X", toHex(sonytimebytes), sonytime))
	return utctime
end

-- Sort sony timebyte
function sortTimestamp(timea, timeb)
	if timea == EMPTYDATE then return false
	elseif timeb == EMPTYDATE then return true
	else return timea < timeb end
end

function formatTimestamp(utctime)
	local timestring = os.date("%Y-%m-%d %H:%M:%S ", utctime)
	if timestring==nil then
		return ""
	end
	-- print(string.format("formatTimestamp: %d, %s", utctime, timestring))
	return timestring
end

MONTHS = {31,28,31,30,31,30,31,31,30,31,30,31}
function maxDayOfMonth(year, month)
	if (month > 12 or month <= 0) then
		return 0
	elseif (month == 2 and (((year % 4 == 0) and (year % 100 ~= 0)) or (year % 400 == 0))) then 
		return 29
	else
		return MONTHS[month] 
	end
end