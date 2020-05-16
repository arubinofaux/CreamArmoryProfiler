-----------------------------------------------
-- Namespaces
-----------------------------------------------
local _, core = ...;
local Db = core.db;

-----------------------------------------------
-- Frames
-----------------------------------------------
local UIConfig = CreateFrame("Frame", "SearchFrame", UIParent, "BasicFrameTemplateWithInset");
UIConfig:SetSize(300, 360);
UIConfig:SetPoint("CENTER", UIParent, "CENTER");
UIConfig:Hide();
UIConfig:SetMovable(true);
UIConfig:EnableMouse(true);
UIConfig:RegisterForDrag("LeftButton");
UIConfig:SetScript("OnDragStart", UIConfig.StartMoving);
UIConfig:SetScript("OnDragStop", UIConfig.StopMovingOrSizing);

local s = CreateFrame("ScrollFrame", nil, UIConfig, "UIPanelScrollFrameTemplate") -- or you actual parent instead
s:SetSize(200,200);
s:SetPoint("CENTER");

local e = CreateFrame("EditBox", nil, s);
e:SetMultiLine(true);
e:SetFontObject(ChatFontNormal);
e:SetWidth(200);
s:SetScrollChild(e);
e:SetAutoFocus(false);

e:SetScript("OnEscapePressed", function(self)
	e:ClearFocus();
end);

UIConfig.saveButton = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
UIConfig.saveButton:SetPoint("CENTER", UIConfig, "BOTTOM", 0, 55);
UIConfig.saveButton:SetSize(140, 40);
UIConfig.saveButton:SetText("Close");
UIConfig.saveButton:SetNormalFontObject("GameFontNormalLarge");
UIConfig.saveButton:SetHighlightFontObject("GameFontHighlightLarge");
UIConfig.saveButton:SetScript("OnClick", function(self, arg1)
	UIConfig:Hide();
end);

-----------------------------------------------
-- Slash Commands
-----------------------------------------------
SLASH_CRPROFILE1 = "/crp";

SlashCmdList["CRPROFILE"] = function(params)
	local arg1, arg2 = strsplit(" ", params);
	
	if params == "log" then
		if include_debug_info then
			include_debug_info = false;
			print("Logging disabled");
		else
			include_debug_info = true;
			print("Logging enabled");
		end
		
	elseif arg1 == "talent" then
		-- create a new net request
		local unitName = arg2;
		print(format("attempting to get talents from %s", unitName));
		local data = craider:Serialize ("AT", UnitName("player"), GetRealmName(), craider.realversion, UnitGUID ("player"));
		craider:SendCommMessage ("DTLS", data, "WHISPER", unitName);
		
	elseif params == "scan" then
		if scanningEnabled then
			print("|cffff0000Cream Armory|r Scanning has been disabled. You will no longer automatically scan players you interact with.");
			scanningEnabled = false;
		else
			print("|cffff0000Cream Armory|r Scanning has been enabled. You will now automatically scan players you interact with. Thank you for contributing!");
			Db:Clear()
			scanningEnabled = true;
		end
	else
		local ts = GetServerTime();
		local header = obfuscator:header(ts);	
		local header_length = strlen(header);
		local body = obfuscator:body(ts, detail:getplayer());	
		local content = string.format("%d %d %s%s", ts, header_length, header, body);
			
		UIConfig:Show();
		e:SetFocus();
		e:SetText(content);
		e:HighlightText(0, strlen(content));
	end
end



print("|cffff0000Cream Armory v1.0.4|r Type '/crp scan' to enable scanning and help us scan other players!");