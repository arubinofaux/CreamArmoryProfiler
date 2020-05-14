-- This AddOn is client side and all output is considered untrusted.
-- We have many cross-server measures to ensure integrity of data.
-- This file simply acts as a simple first-line of defense against data manipulation.

--
-- As we have seen a growth in our service there was a big demand for a de-obfuscated version of the AddOn.
-- Obfuscation only served a deterence for people to submit invalid data, however; any client input will always be untrusted.
-- Please keep in mind that any kind of detected data manipulation will get you blacklisted ( beehived code ).
--

-----------------------------------------------
-- Namespaces
-----------------------------------------------
local _, core = ...;

-----------------------------------------------
-- Global Variables
-----------------------------------------------
obfuscator = {};

-----------------------------------------------
-- Obfuscator
-----------------------------------------------
function obfuscator:header( _timestamp )	
	-- append timestamp to key
	local key = 0x8219C + (_timestamp / 2);
	key = math.floor(key);
	
	-- create ulong to store timestamp (prevents intenger overflow)
	local tsUlong = core.ulong:i64( _timestamp );
		
	-- retrieves unit stats
	local str_base, _, _, _ = UnitStat("player", 1);
	local agi_base, _, _, _ = UnitStat("player", 2);
	local sta_base, _, _, _ = UnitStat("player", 3);
	local int_base, _, _, _ = UnitStat("player", 4);
	local spi_base, _, _, _ = UnitStat("player", 5);
	
	local base_total = str_base+agi_base+sta_base+int_base+spi_base;
	local stat_grid = string.format("%d;%d;%d;%d;%d;", 
		str_base, 
		agi_base, 
		sta_base, 
		int_base, 
		spi_base
	);
	
	-- unit name, realm & level
	local name = UnitName("player");
    local level = UnitLevel("player");
	local realm = GetRealmName();
	local gender = UnitSex("player")-1;
	
	-- Substract base stat from the timestamp (later we can use this to validate nobody maniuplated data)
	tsUlong = core.ulong:i64_sub(tsUlong, core.ulong:i64(base_total));

	-- converts the ulong epoch into a timestamp
	local timestampHex = core.ulong:i64_toString( tsUlong );	
	
	-- create real (required) user id.
	local ruid = string.format("%s:%s:%s:%s:%s:%s:%s", UnitGUID("player"), timestampHex, stat_grid, name, level, realm, gender);
	
	-- obfuscate userid further
	return enc(ruid, key); --ECB_256(encrypt, key, ruid);	
end

function obfuscator:body( _timestamp, content )
	local key = math.floor(0x8219C + (_timestamp/2));
	return enc(content, key);
end
