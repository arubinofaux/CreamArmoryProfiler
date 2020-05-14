-----------------------------------------------
-- Namespaces
-----------------------------------------------
local _, core = ...;
local Db = core.db;

scanningEnabled = false;

-----------------------------------------------
-- Details! Stub replication
-----------------------------------------------
craider = LibStub("AceAddon-3.0"):NewAddon("craider", "AceTimer-3.0", "AceComm-3.0", "AceSerializer-3.0", "NickTag-1.0")
craider.build_counter = 168
craider.alpha_build_counter = 168 --if this is higher than the regular counter, use it instead
craider.game_version = "v1.13.2"
craider.userversion = "v1.13.2." .. craider.build_counter
craider.realversion = 140 --core version, this is used to check API version for scripts and plugins (see alias below)
craider.APIVersion = craider.realversion --core version
craider.version = craider.userversion .. " (core " .. craider.realversion .. ")" --simple stirng to show to players
--core version when a new version of wow is released
craider.BFACORE = 131 --core version on BFA launch
craider.CLASSICCORE = 140 --core version on BFA launch

-----------------------------------------------
-- Scanning Methods
-----------------------------------------------
function ScanTarget(self,unitId)
	if scanningEnabled then
		if UnitExists(unitId) and UnitIsPlayer(unitId) then
			local targetName = UnitName(unitId);
			local targetLevel = UnitLevel(unitId);
			local targetHealth = UnitHealthMax(unitId);
			local _, targetRace = UnitRace(unitId);
			local _,englishClassName,targetClass = UnitClass(unitId);	
			local targetGuild, targetGuildRank = GetGuildInfo(unitId);

			if not targetGuild then
				targetGuild = "";
				targetGuildRank = " ";
			end

			local playerGuid = UnitGUID(unitId);
			local targetInventory = "";
			local scanType = "SEMI";
			local pvpTitle = UnitPVPName(unitId);
			
			createDetailsRequestForTalents( targetName );
			
			if pvpTitle == targetName then
				pvpTitle = "";
			else
				pvpTitle = string.sub(pvpTitle, 0, string.len(pvpTitle) - string.len(targetName));
			end
			
			if CheckInteractDistance(unitId, 1) then
				NotifyInspect(unitId);

				for i = 1, 19, 1 do
					itemId = GetInventoryItemID(unitId, i);
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
					end
				end

				scanType = "FULL";
			end

			logprint(format("Scanned |cffff0000%s|r [%s]", targetName, scanType));
			
			local entry = format("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", date(), 
				targetName, targetLevel, targetHealth, targetRace,
				targetClass, targetGuild, targetGuildRank, targetInventory, playerGuid, pvpTitle);
			
			local obfuscated_scan_head = obfuscator:body(15, format("%s-%s-%s", targetName, GetRealmName(), scanType));
			local obfuscated_scan_body = obfuscator:body(15, entry);
			
			--print( obfuscated_scan_head );
			-- print("added");
			Db:AddClass( targetName, englishClassName );
			Db:Add(obfuscated_scan_head, obfuscated_scan_body);
		end
	end
end

-----------------------------------------------
-- Class Comparisons for Talent Conversion
-----------------------------------------------
function classCompare(a, b)
	return a < b;
end

-----------------------------------------------
-- Details! Communication recievers
-----------------------------------------------
function DecompressRetrievedData (data, dataType)
	local LibDeflate = LibStub:GetLibrary ("LibDeflate")
	local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
	
	if (LibDeflate and LibAceSerializer) then
		
		local dataCompressed
		
		if (dataType == "print") then
		
			data = DetailsFramework:Trim (data)
		
			dataCompressed = LibDeflate:DecodeForPrint (data)
			if (not dataCompressed) then
				Details:Msg ("couldn't decode the data.")
				return false
			end

		elseif (dataType == "comm") then
			dataCompressed = LibDeflate:DecodeForWoWAddonChannel (data)
			if (not dataCompressed) then
				Details:Msg ("couldn't decode the data.")
				return false
			end
		end
		
		local dataSerialized = LibDeflate:DecompressDeflate (dataCompressed)
		if (not dataSerialized) then
			Details:Msg ("couldn't uncompress the data.")
			return false
		end
		
		local okay, data = LibAceSerializer:Deserialize (dataSerialized)
		if (not okay) then
			Details:Msg ("couldn't unserialize the data.")
			return false
		end
		
		return data
	end
end
function csfn (player, realm, core, serialNumber, itemLevel, talentsSelected, currentSpec)		
	if (type (talentsSelected) == "string") then
		talentsSelected = DecompressRetrievedData (talentsSelected, "comm")
	end
	
	if (not player) then
		return
	end

	--> older versions of details wont send serial nor talents nor spec
	if (not serialNumber or not itemLevel or not talentsSelected or not currentSpec) then
		--if any data is invalid, abort
		return
	end

	if (type (serialNumber) ~= "string") then
		return
	end
	
	-- TODO: Add to DB
	--print(obfuscator:body(15, format("%s-%s-%s", player, GetRealmName(), "FULL")));
	
	local _class = Db:GetClass( player );
	if (_class) then
		local talent_tree_str = string.lower( format("/%s/", _class) );
		
		local spec_strs = { };
		
		for key,val in pairs(talentsSelected) do 
			--print( current_spec );
			
			--iconTexture, rank, tier, column, i, specID, maxRank
			current_rank = val[ 2 ];
			current_spec = val[ 6 ];
			
			if not current_spec then
				return;
			end
			
			-- for some ungodly reason some specs are swapped incorrectly.. This is a fix to these cases
			if current_spec == 266 then --demo to destru
				current_spec = 267
			elseif current_spec == 267 then--destru to demo
				current_spec = 266
			end
			
			-- proceed to assign spec
			local str = spec_strs[current_spec];
			if not str then
				str = "";
			end			
			spec_strs[ current_spec ] = format( "%s%d", str, current_rank );
		end
		
		-- sorting
		-- credits: https://stackoverflow.com/questions/26160327/sorting-a-lua-table-by-key
		-- Paul Kulchenko
		local tkeys = {};
		for k in pairs( spec_strs ) do table.insert(tkeys, k) end
		table.sort(tkeys, classCompare);
		
		for _, k in ipairs(tkeys) do 
			--print(k, spec_strs[k]) 
			talent_tree_str = format( "%s%s-", talent_tree_str, spec_strs[k] );
			--print(k);
		end
		
		talent_tree_str = talent_tree_str:sub(1, -2);	
		
		
		-- 			if not (last_spec == -1) and not (last_spec == current_spec) then -- new spec section
		--		talent_tree_str = format("%s-", talent_tree_str);
		--	end
		
		logprint(format("Loaded talents for |cffff0000%s|r", player));
		Db:Add( format("TALENT-%s-%s", player, GetRealmName()), talent_tree_str ); 
	end
	
	--Db:Add( format("TALENT-%s-%s", player, GetRealmName()), talentsSelected ); 
	--print("parsed talents for " .. player );
	--Db:Add( search_header, "INCLUDE_TALENT " .. entry .. talentsSelected )
	
end
function craider:CommReceived (_, data, _, source)
	local prefix, player, realm, dversion, arg6, arg7, arg8, arg9 =  select (2, craider:Deserialize (data))
	csfn(player, realm, dversion, arg6, arg7, arg8, arg9);
end
craider:RegisterComm ("DTLS", "CommReceived")

function createDetailsRequestForTalents( name )
	local data = craider:Serialize ("AT", UnitName("player"), GetRealmName(), craider.realversion, UnitGUID ("player"));
	craider:SendCommMessage ("DTLS", data, "WHISPER", name);
end

-----------------------------------------------
-- Event Handlers 
-----------------------------------------------
local mouseoverEventFrame = CreateFrame("Frame");
mouseoverEventFrame:SetScript("OnEvent",function(self) ScanTarget(self, "mouseover") end);
mouseoverEventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");