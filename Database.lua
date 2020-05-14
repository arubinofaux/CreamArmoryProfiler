-----------------------------------------------
-- Namespaces
-----------------------------------------------
local _, core = ...;
core.db = {};

local Db = core.db;

-----------------------------------------------
-- Database Storage Variable
-----------------------------------------------
aldb = {  };

classDB = { };

-----------------------------------------------
-- Database Functions
-----------------------------------------------
function Db:AddClass(name, class)
	classDB[name] = class;
end

function Db:GetClass(name)
	return classDB[name];
end

function Db:Add(index, entry) 
	aldb[index] = entry;
end


function Db:Get(index)
	return aldb[index];

	--local count = 0
	--for key,val in pairs(aldb) do 
	--	count = count + 1 
	--	if count == index then
	--		return val;
	--	end
	--end
end

function Db:Remove(entry)
	print("NotImplementedException for function Db:Remove(entry) in armory_db.lua");
end

function Db:Clear()
	wipe(aldb);
end

function Db:Count()
  local count = 0
  for _ in pairs(aldb) do count = count + 1 end
  return count
end