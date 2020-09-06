-- Namespace
local _, ns = ...;

ns.Util = {};

local Util = ns.Util;


----------
-- Util --
----------
local function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

local function table_has_only_int_keys (t)
  for index, value in pairs(t) do
    if type(index) ~= "number" then
      return false;
    end
  end
  return true;
end 

local function format_table (t, tab)
  local mtab = string.rep(" ", tab);
  if type(t) == "table" then
    if table_has_only_int_keys(t) then
      return "{" .. table.concat(map(t, tostring), ", ") .. "}";
    else
      local content = "{\n";
      for index, value in pairs(t) do
        content = content .. mtab .. " '" .. index .. "' = " .. format_table(value, tab + 1) .. ",\n";
      end
      return content .. mtab .. "}";
    end
  else 
    return tostring(t);
  end
end

local function pprint (t)
  print(format_table(t, 0));
end

local function has_value (tab, val)
  for index, value in pairs(tab) do
    if value == val then
      return true 
    end
  end
  return false
end

local function add_list_value (d, k, v)
  if d[k] == nil then
    d[k] = {};
  end
  table.insert(d[k], v);
end

local function count_list_values(d)
  local count = 0;
  for index, value in ipairs(tab) do
    count = count + #value;
  end
  return count;
end

Util.map = map;
Util.table_has_only_int_keys = table_has_only_int_keys;
Util.format_table = format_table;
Util.pprint = pprint;
Util.has_value = has_value;
Util.add_list_value = add_list_value;
Util.count_list_values = count_list_values;