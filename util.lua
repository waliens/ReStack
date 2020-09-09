-- Namespace
local _, ns = ...;

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

local function table_find(tab, el)
  for index, value in pairs(tab) do
    if value == el then
      return index;
    end
  end
  return 0;
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

local function remove_list_value (d, k, v)
  if d[k] == nil then return; end
  local index = table_find(d[k], v);
  if index == 0 then return; end
  table.remove(d[k], index);
  -- remove if list with key is empty
  if table.getn(d[k]) == 0 then
    d[k] = nil;
  end
end

local function has_list_value(d, k, v)
  return d[k] ~= nil and has_value(d[k], v);
end

local function merge_list_value (d1, d2) 
  local merged = {};
  for k, list in pairs(d1) do
    for _, v in ipairs(list) do
      add_list_value(merged, k, v);
    end
  end
  for k, list in pairs(d2) do
    for _, v in ipairs(list) do
      if merged[k] == nil or table_find(merged[k], v) == 0 then
        add_list_value(merged, k, v);
      end
    end 
  end
  return merged;
end

local function count_list_value(d)
  local count = 0;
  for index, value in pairs(d) do
    count = count + table.getn(value);
  end
  return count;
end

local function table_keys(t)
  local keyset = {};
  for k, v in pairs(t) do
    if v ~= nil then
      table.insert(keyset, k);
    end
  end
  return keyset;
end

local function mk_cache_key(key) 
  if type(key) == "table" then
    return table.concat(map(key, tostring), "_");
  else 
    return tostring(key);
  end
end

local function cache_get(t, k)
  return t[mk_cache_key(k)];
end

local function cache_set(t, k, v)
  t[mk_cache_key(k)] = v;
end

ns.Util = {};
ns.Util.map = map;
ns.Util.table_has_only_int_keys = table_has_only_int_keys;
ns.Util.format_table = format_table;
ns.Util.pprint = pprint;
ns.Util.table_find = table_find;
ns.Util.has_value = has_value;
ns.Util.add_list_value = add_list_value;
ns.Util.remove_list_value = remove_list_value;
ns.Util.count_list_value = count_list_value;
ns.Util.merge_list_value = merge_list_value;
ns.Util.has_list_value = has_list_value;
ns.Util.table_keys = table_keys;
ns.Util.cache_get = cache_get;
ns.Util.cache_set = cache_set;