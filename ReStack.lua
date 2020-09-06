GLAND_ID = 4338; -- 12586;

--------------------------------------
-- UTIL                             --
--------------------------------------
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

local function print_table (t)
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
    count = count + table.getn(value);
  end
  return count;
end

--------------------------------------
-- SLOTS                            --
--------------------------------------
local function bag_tag(bag_id) 
  return "bag_" .. bag_id;
end

local function analyze_slots ()
  local empty_slots = {};
  local gland_slots = {};
  local number_gland = 0;
  for bag_id=0,4 do
    for slot_id=1,GetContainerNumSlots(bag_id) do 
      -- in current bag and slot
      local item_id = GetContainerItemID(bag_id, slot_id);
      if item_id == nil then 
        add_list_value(empty_slots, bag_tag(bag_id), slot_id);
      elseif item_id == GLAND_ID then
        add_list_value(gland_slots, bag_tag(bag_id), slot_id);
        _, item_count, _, _, _, _, _ = GetContainerItemInfo(bag_id, slot_id);
        number_gland = number_gland + item_count;
      end
    end
  end
  return gland_slots, empty_slots, number_gland;
end

local function updateText(count, maxtime, mintime)
  ReStackFrame_NbGland:SetText("Glands: " .. count);
  ReStackFrame_MaxTimer:SetText("Max time: " .. maxtime);
  ReStackFrame_MinTimer:SetText("Min time: " .. mintime);
end

local function updateButtonClick(self, arg1)
  glands, empty, number_glands = analyze_slots();
  updateText(number_glands, 0, 0);
  print_table(empty);
  print_table(glands);
end

function InitRS()
  updateButtonClick(nil, nil);
  print("ReStack has been initialized");
end