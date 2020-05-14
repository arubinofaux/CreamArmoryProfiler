-----------------------------------------------
-- Namespaces
-----------------------------------------------
local _, core = ...;

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
	
	--addon_tableID.ntdb:Add(player .. "-" .. realm .. "-talents", talentsSelected);
	--addon_tableID.ntdb:Add(player .. "-" .. realm .. "-guid", serialNumber);
	
end
function craider:CommReceived (_, data, _, source)
	local prefix, player, realm, dversion, arg6, arg7, arg8, arg9 =  select (2, craider:Deserialize (data))
	csfn(player, realm, dversion, arg6, arg7, arg8, arg9);
end
craider:RegisterComm ("DTLS", "CommReceived")


