-----------------------------------------------
-- Global Variables
-----------------------------------------------
include_debug_info = false;

-----------------------------------------------
-- Logging
-----------------------------------------------
function logprint(msg)
	if include_debug_info then
		print(msg);
	end
end