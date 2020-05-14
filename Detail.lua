-----------------------------------------------
-- Namespaces
-----------------------------------------------
local _, core = ...;

-----------------------------------------------
-- Global Variables
-----------------------------------------------
detail = {};
scanning_enabled = true;

-----------------------------------------------
-- String Extensions
-----------------------------------------------
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-----------------------------------------------
-- Equipment Location Translator
-----------------------------------------------

function TranslateEquipLoc( ItemEquipLoc, fingerCount, trinketCount, weaponCount )

	if ItemEquipLoc == "INVTYPE_HEAD" then
		return 1;
	elseif ItemEquipLoc == "INVTYPE_NECK" then
		return 2;
	elseif ItemEquipLoc == "INVTYPE_SHOULDER" then
		return 3;
	elseif ItemEquipLoc == "INVTYPE_CLOAK" then
		return 15;
	elseif ItemEquipLoc == "INVTYPE_CHEST" then
		return 5;
	elseif ItemEquipLoc == "INVTYPE_WRIST" then
		return 9;
	elseif ItemEquipLoc == "INVTYPE_HAND" then
		return 10;
	elseif ItemEquipLoc == "INVTYPE_FEET" then
		return 8;
	elseif ItemEquipLoc == "INVTYPE_WAIST" then
		return 6;
	elseif ItemEquipLoc == "INVTYPE_LEGS" then
		return 7;
	elseif ItemEquipLoc == "INVTYPE_FINGER" then
		return 11 + fingerCount;--11,12
	elseif ItemEquipLoc == "INVTYPE_TRINKET" then
		return 13 + trinketCount;--13,14
	elseif ItemEquipLoc == "INVTYPE_WEAPON" then
		return 16 + weaponCount;--19,20
	elseif ItemEquipLoc == "INVTYPE_SHIELD" then
		return 17;
	elseif ItemEquipLoc == "INVTYPE_2HWEAPON" then
		return 16;
	elseif ItemEquipLoc == "INVTYPE_WEAPONMAINHAND" then
		return 16;
	elseif ItemEquipLoc == "INVTYPE_WEAPONOFFHAND" then
		return 17;
	elseif ItemEquipLoc == "INVTYPE_HOLDABLE" then
		return 17;
	elseif ItemEquipLoc == "INVTYPE_RANGED" then
		return 18;
	elseif ItemEquipLoc == "INVTYPE_THROWN" then
		return 18;
	elseif ItemEquipLoc == "INVTYPE_RANGEDRIGHT" then
		return 18;
	elseif ItemEquipLoc == "INVTYPE_RELIC" then
		return 18;
	
	end
	
	return 0;
end

-----------------------------------------------
-- Scanning Methods
-----------------------------------------------
function GetPlayerInfo(unitId)
  if UnitExists(unitId) and UnitIsPlayer(unitId)  then
    local targetName = UnitName(unitId);
    local targetLevel = UnitLevel(unitId);
    local targetHealth = UnitHealthMax(unitId);
	local targetRace = UnitRace(unitId);
	local _,_,targetClass = UnitClass(unitId);	
	local targetGuild, targetGuildRank = GetGuildInfo(unitId);
	local pvpTitle = UnitPVPName(unitId);
	
	if pvpTitle == targetName then
		pvpTitle = "";
	else
		pvpTitle = string.sub(pvpTitle, 0, string.len(pvpTitle) - string.len(targetName));
	end
	
	if not targetGuild then
		targetGuild = "";
		targetGuildRank = "";
	end
	
	local playerGuid = UnitGUID(unitId);
	local targetInventory = "";
	NotifyInspect(unitId);

	for i = 1, 19, 1 do
		local itemId = GetInventoryItemID(unitId, i);
		local link = GetInventoryItemLink(unitId, i);
		local enchantId = 0;
		
		if not (link == null) then		
			--local _, enchantId, gem1, gem2, gem3, gem4 = link:match("item:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)");
			local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(link, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
			enchantId = tonumber(Enchant);
			
			if enchantId == nil then
				enchantId = 0;
			end
		end
			
		if targetInventory == "" then
			targetInventory = format("%d:%d", itemId, enchantId);
		else
			targetInventory = format("%s %d:%d", targetInventory, itemId, enchantId);
			--enchantList = format("%s %d", enchantList, enchantId);
		end
	end
	
	local numTabs = GetNumTalentTabs();
	local talent_info = "";
	for t=1, numTabs do	
		talent_info = string.format("%s%s[", talent_info, GetTalentTabInfo(t));
		
		local numTalents = GetNumTalents(t);
		for i=1, numTalents do
			name, iconPath, tier, column, currentRank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(t,i);
			local talent_entry = string.format("%s;%s;%d;%d;%d;%d-", name, iconPath, tier, column, currentRank, maxRank);
			talent_info = string.format("%s%s", talent_info, talent_entry);
		end	
		talent_info = string.format("%s]", talent_info);
	end
	
	-- name;item_id;
	-- EXTENSION: ItemRack
	-- If player uses addon (ItemRack) then store his gear sets!
	local item_rack_extra = "";		
	if not (ItemRackUser == nil) then
		for gear_set_name,value in pairs(ItemRackUser["Sets"]) do
			if not string.starts(gear_set_name, "~") then
				-- Append Header
				if not (item_rack_extra == "") then
					item_rack_extra = item_rack_extra .. "|";
				end	
				item_rack_extra = item_rack_extra .. string.gsub(gear_set_name, " ", "_");
					
				-- Create item rack array for gear set.
				item_rack_details = { };
				for i=0, 19 do
					table.insert(item_rack_details, string.format("%d:%d", 0, 0));
				end	
				item_rack_extra = string.format("%s", item_rack_extra);
				
				-- Put gear info into the item_rack_detail array
				local fingerCount 	= 0;
				local trinketCount 	= 0;
				local weaponCount 	= 0;
				
				for _,item_info in pairs(value["equip"]) do	
					local _enchantId = 0;--needs to be implemented
					if not (item_info == 0) then -- parse item id
					
						--7720::::::::43:::1::::
						local iid, eid = item_info:match("^([0-9]+):([0-9]+)");
						if not (eid == nil) then
							_enchantId = tonumber(eid);
						end
						
						item_info=tonumber(strmatch(item_info, "[0-9]+"));
					end
					
					local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount, itemEquipLoc = GetItemInfo( item_info );	
					item_rack_details[TranslateEquipLoc( itemEquipLoc, fingerCount, trinketCount, weaponCount )] = string.format("%d:%d", item_info, _enchantId);
					
					if itemEquipLoc == "INVTYPE_FINGER" then
						fingerCount = fingerCount + 1;--12,13
					elseif itemEquipLoc == "INVTYPE_TRINKET" then
						trinketCount = trinketCount + 1;--13,14
					elseif itemEquipLoc == "INVTYPE_WEAPON" then
						weaponCount = weaponCount + 1;--16,17
					end
				end
				
				-- Append Body from item_rack_detail
				for _,itemid in pairs(item_rack_details) do	
					--print(itemid);
					item_rack_extra = string.format("%s %s", item_rack_extra, itemid);
				end
				
			end	
		end		
	end		
		
	-- serialize & return scanned unit
	return format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", GetServerTime(), 
		targetName, targetLevel, targetHealth, targetRace,
		targetClass, targetGuild, targetGuildRank, targetInventory, 
		playerGuid, talent_info, item_rack_extra, pvpTitle); -- Untrusted Client Entry	
  end
end



-----------------------------------------------
-- Frames
-----------------------------------------------
function detail:getplayer()
	return GetPlayerInfo("player");
end