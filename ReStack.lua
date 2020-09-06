
-- Namespace
local _, ns = ...;

ns.Restack = {};

local Restack = ns.ReStack;
local Util = ns.Util;

-- Constants
GLAND_ID = 4338; -- 12586;

--------------------------------------
-- SLOTS                            --
--------------------------------------
function Restack:bag_tag(bag_id) 
  return "bag_" .. bag_id;
end

function Restack:analyze_slots ()
  local empty_slots = {};
  local gland_slots = {};
  local number_gland = 0;
  for bag_id=0,4 do
    for slot_id=1,GetContainerNumSlots(bag_id) do 
      -- in current bag and slot
      local item_id = GetContainerItemID(bag_id, slot_id);
      if item_id == nil then 
        Util.add_list_value(empty_slots, bag_tag(bag_id), slot_id);
      elseif item_id == GLAND_ID then
        Util.add_list_value(gland_slots, bag_tag(bag_id), slot_id);
        _, item_count, _, _, _, _, _ = GetContainerItemInfo(bag_id, slot_id);
        number_gland = number_gland + item_count;
      end
    end
  end
  return gland_slots, empty_slots, number_gland;
end



-- local function updateButtonClick(self, arg1)
--   glands, empty, number_glands = analyze_slots();
--   updateText(number_glands, 0, 0);
--   pprint(empty);
--   pprint(glands);
-- end