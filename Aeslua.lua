local _x = 1246
local x

function cr_encode(str,__x)
if not x then
  x = {}
  for M = 0, 127 do
	local inv = -1
	repeat inv = inv + 2
	until inv * (2*M + 1) % 256 == 1
	x[M] = inv
  end
end
local K, F = __x, 16384 + _x
return (str:gsub('.',
  function(m)
	local L = K % 274877906944  -- 2^38
	local H = (K - L) / 274877906944
	local M = H % 128
	m = m:byte()
	local c = (m * x[M] - (H - M) / 128) % 256
	K = L * F + H + c + m
	return ('%02x'):format(c)
  end
))
end