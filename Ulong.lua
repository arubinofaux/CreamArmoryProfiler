-----------------------------------------------
-- Namespaces
-----------------------------------------------
local _, core = ...;
core.ulong = {};

-----------------------------------------------
-- Lua unsigned 64bit emulated bitwises
-----------------------------------------------
function core.ulong:i64(v) local o = {}; o.l = v; o.h = 0; return o; end -- constructor +assign 32-bit value
function core.ulong:i64_ax(h,l) local o = {}; o.l = l; o.h = h; return o; end -- +assign 64-bit v.as 2 regs

function core.ulong:i64u(x) return ( ( (bit.rshift(x,1) * 2) + bit.band(x,1) ) % (0xFFFFFFFF+1)); end -- keeps [1+0..0xFFFFFFFFF]
function core.ulong:i64_clone(x) local o = {}; o.l = x.l; o.h = x.h; return o; end -- +assign regs

-- Type conversions
function core.ulong:i64_toInt(a) return (a.l + (a.h * (0xFFFFFFFF+1))); end -- value=2^53 or even less, so better use a.l value
function core.ulong:i64_toString(a)
  local s1=string.format("%x",a.l);
  local s2=string.format("%x",a.h);
  local s3="0000000000000000";
  s3=string.sub(s3,1,16-string.len(s1))..s1;
  s3=string.sub(s3,1,8-string.len(s2))..s2..string.sub(s3,9);
  return "0x"..string.upper(s3);
end

-- Bitwise operators (the main functionality)
function core.ulong:i64_and(a,b)
 local o = {}; o.l = core.ulong:i64u( bit.band(a.l, b.l) ); o.h = core.ulong:i64u( bit.band(a.h, b.h) ); return o;
end
function core.ulong:i64_or(a,b)
 local o = {}; o.l = core.ulong:i64u( bit.bor(a.l, b.l) ); o.h = core.ulong:i64u( bit.bor(a.h, b.h) ); return o;
end
function core.ulong:i64_xor(a,b)
 local o = {}; o.l = core.ulong:i64u( bit.bxor(a.l, b.l) ); o.h = core.ulong:i64u( bit.bxor(a.h, b.h) ); return o;
end
function core.ulong:i64_not(a)
 local o = {}; o.l = core.ulong:i64u( bit.bnot(a.l) ); o.h = core.ulong:i64u( bit.bnot(a.h) ); return o;
end
function core.ulong:i64_neg(a)
 return core.ulong:i64_add( core.ulong:i64_not(a), core.ulong:i64(1) );
end  -- negative is inverted and incremented by +1

-- Simple Math-functions
-- just to add, not rounded for overflows
function core.ulong:i64_add(a,b)
 local o = {};
 o.l = a.l + b.l;
 local r = o.l - 0xFFFFFFFF;
 o.h = a.h + b.h;
 if( r>0 ) then
   o.h = o.h + 1;
   o.l = r-1;
 end
 return o;
end

-- verify a>=b before usage
function core.ulong:i64_sub(a,b)
  local o = {}
  o.l = a.l - b.l;
  o.h = a.h - b.h;
  if( o.l<0 ) then
    o.h = o.h - 1;
    o.l = o.l + 0xFFFFFFFF+1;
  end
  return o;
end

-- x n-times
function core.ulong:i64_by(a,n)
 local o = {};
 o.l = a.l;
 o.h = a.h;
 for i=2, n, 1 do
   o = core.ulong:i64_add(o,a);
 end
 return o;
end
-- no divisions   

-- Bit-shifting
function core.ulong:i64_lshift(a,n)
 local o = {};
 if(n==0) then
   o.l=a.l; o.h=a.h;
 else
   if(n<32) then
     o.l= core.ulong:i64u( bit.lshift( a.l, n) ); o.h=core.ulong:i64u( bit.lshift( a.h, n) )+ bit.rshift(a.l, (32-n));
   else
     o.l=0; o.h=core.ulong:i64u( bit.lshift( a.l, (n-32)));
   end
  end
  return o;
end
function core.ulong:i64_rshift(a,n)
 local o = {};
 if(n==0) then
   o.l=a.l; o.h=a.h;
 else
   if(n<32) then
     o.l= bit.rshift(a.l, n)+core.ulong:i64u( bit.lshift(a.h, (32-n))); o.h=bit.rshift(a.h, n);
   else
     o.l=bit.rshift(a.h, (n-32)); o.h=0;
   end
  end
  return o;
end

-- Comparisons
function core.ulong:i64_eq(a,b)
 return ((a.h == b.h) and (a.l == b.l));
end

function core.ulong:i64_ne(a,b)
 return ((a.h ~= b.h) or (a.l ~= b.l));
end

function core.ulong:i64_gt(a,b)
 return ((a.h > b.h) or ((a.h == b.h) and (a.l >  b.l)));
end

function core.ulong:i64_ge(a,b)
 return ((a.h > b.h) or ((a.h == b.h) and (a.l >= b.l)));
end

function core.ulong:i64_lt(a,b)
 return ((a.h < b.h) or ((a.h == b.h) and (a.l <  b.l)));
end

function core.ulong:i64_le(a,b)
 return ((a.h < b.h) or ((a.h == b.h) and (a.l <= b.l)));
end