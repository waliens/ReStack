
-- Namespace
local _, ns = ...;

local Util = ns.Util;
local Restacker = {};

-- Constants
GLAND_ID = 12586; -- = 4338;   
MAX_GLAND_STACK_SIZE = 50; -- 50; 

--------------------------------------
-- SLOTS                            --
--------------------------------------
local function to_bag_tag(bag_id) 
  return "bag_" .. bag_id;
end

local function to_bag_id(bag_tag)
  local id = string.sub(bag_tag, 5);
  return tonumber(id);
end

local function cache_increment(t, k, v) 
  local curr = Util.cache_get(t, k);
  if curr == nil then
    curr = 0;
  end
  Util.cache_set(t, k, curr + v);
end

local function analyze_slots ()
  local empty_slots = {};       -- maps bag_id with list of empty slots
  local gland_slots = {};       -- maps bag_id with list of slots containing glands
  local cnt_cache = {}; -- maps (bag_id, slot_id) with number of glands
  local number_gland = 0;
  for bag_id=0,4 do
    for slot_id=1,GetContainerNumSlots(bag_id) do 
      -- in current bag and slot
      local item_id = GetContainerItemID(bag_id, slot_id);
      if item_id == nil then 
        Util.add_list_value(empty_slots, to_bag_tag(bag_id), slot_id);
      elseif item_id == GLAND_ID then
        Util.add_list_value(gland_slots, to_bag_tag(bag_id), slot_id);
        local _, item_count, _, _, _, _, _ = GetContainerItemInfo(bag_id, slot_id);
        Util.cache_set(cnt_cache, {bag_id, slot_id}, item_count);
        number_gland = number_gland + item_count;
      end
    end
  end
  return gland_slots, empty_slots, cnt_cache, number_gland;
end

local function select_reference_stack(items) 
  -- select the stack to use for restacking 
  -- currently, selects the smallest stack
  local min_bag_id, min_slot, min_count = 0, 0, 9999;
  for bag_tag, slots in pairs(items) do
    local bag_id = to_bag_id(bag_tag);
    for _, slot in ipairs(slots) do
      local _, item_count, _, _, _, _, _ = GetContainerItemInfo(bag_id, slot);
      if item_count < min_count then
        min_count = item_count;
        min_bag_id = bag_id;
        min_slot = slot;
      end 
    end 
  end
  return min_bag_id, min_slot, min_count;
end

local function split_item(src_bag, src_slot, quantity, dst_bag, dst_slot)
  ClearCursor();
  SplitContainerItem(src_bag, src_slot, quantity);
  PickupContainerItem(dst_bag, dst_slot); 
  coroutine.yield();
end

local function extract_bag_slot_first(bag_slots)
  local keys = Util.table_keys(bag_slots);
  if table.getn(keys) == 0 then
    return nil, nil, nil;
  end
  local bag_tag = keys[1];
  local bag_id = to_bag_id(bag_tag);
  local slot_id = bag_slots[bag_tag][1];
  return bag_tag, bag_id, slot_id;
end

local function extract_bag_slot_opt(cnt_cache, bag_slots, min) 
  local opt_count, opt_slot, opt_bag = (min and 9999 or -1), 0, 0; 
  for bag_tag, slots in pairs(bag_slots) do
    local bag = to_bag_id(bag_tag);
    for _, slot in ipairs(slots) do
      local count = Util.cache_get(cnt_cache, {bag, slot});
      if count ~= nil and (min and count < opt_count) or (not min and count > opt_count) then
        opt_count = count;
        opt_slot = slot;
        opt_bag = bag;
      end
    end
  end
  return opt_bag, opt_slot, opt_count;
end

local function split_stack(empty_slots, cnt_cache, src_bag_id, src_slot_id, max_splits)
  -- Split stack - split a source item stack ($src_bag_id, $src_slot_id) into as many piles of size 1
  -- as possible. Splitted stacks are placed in slots listed in empty slots.
  --
  -- empty_slots: list of empty slots
  -- cnt_cache: cache mapping (bag_id, slot_id) => item_count
  -- src_bag_id: (int) source_bag_id
  -- src_slot_id: (int) src_slot_id
  -- max_splits: (int) maximum number of splits out of the source stack
  local stack_size = Util.cache_get(cnt_cache, {src_bag_id, src_slot_id});
  local nb_splits = math.min(max_splits, stack_size - 1);
  local maxxed_slots = {};
  Util.add_list_value(maxxed_slots, to_bag_tag(src_bag_id), src_slot_id);

  local cnt = 0;
  while cnt < nb_splits and table.getn(Util.table_keys(empty_slots)) > 0 do
    local dst_bag_tag, dst_bag_id, dst_slot_id = extract_bag_slot_first(empty_slots); 
    split_item(src_bag_id, src_slot_id, 1, dst_bag_id, dst_slot_id);
    -- update item count cache
    cache_increment(cnt_cache, {src_bag_id, src_slot_id}, -1);
    cache_increment(cnt_cache, {dst_bag_id, dst_slot_id}, 1);
    -- update slots structures
    Util.remove_list_value(empty_slots, dst_bag_tag, dst_slot_id);
    Util.add_list_value(maxxed_slots, dst_bag_tag, dst_slot_id);
    cnt = cnt + 1;
  end

  return empty_slots, maxxed_slots;
end

local function get_item_size(cache, bag_id, slot_id)
  local val = Util.tuple_table_get(cache, bag_id, slot_id);
  if val ~= nil then
    return val;
  else
    local _, count, _, _, _, _, _ = GetContainerItemInfo(bag_id, slot_id);
    val = count;
    Util.tuple_table_set(cache, bag_id, slot_id, val);
  end
  return val;
end

local function move_stacks(maxxed_slots, gland_slots, cnt_cache)
  -- maxxed_slots: slot filled with max time glands
  -- gland_slots: slot of glands to uptime
  local full_slots = {};
  while table.getn(Util.table_keys(maxxed_slots)) > 0 and table.getn(Util.table_keys(gland_slots)) > 0 do 
    local gland_bag_id, gland_slot_id, _ = extract_bag_slot_opt(cnt_cache, gland_slots, false);
    local maxxed_bag_id, maxxed_slot_id, _ = extract_bag_slot_opt(cnt_cache, maxxed_slots, true);

    -- how many item can we tansfer
    local gland_stack_size = Util.cache_get(cnt_cache, {gland_bag_id, gland_slot_id});
    local maxxed_stack_size = Util.cache_get(cnt_cache, {maxxed_bag_id, maxxed_slot_id});

    local amount = math.min(MAX_GLAND_STACK_SIZE - maxxed_stack_size, gland_stack_size);
    split_item(gland_bag_id, gland_slot_id, amount, maxxed_bag_id, maxxed_slot_id);

    cache_increment(cnt_cache, {gland_bag_id, gland_slot_id}, -amount);
    cache_increment(cnt_cache, {maxxed_bag_id, maxxed_slot_id}, amount);

    -- if gland stack was completely merged into another one
    if gland_stack_size == amount then
      Util.remove_list_value(gland_slots, to_bag_tag(gland_bag_id), gland_slot_id);
    end
    -- if stack is full, move it to full list 
    if maxxed_stack_size + amount == MAX_GLAND_STACK_SIZE then
      Util.remove_list_value(maxxed_slots, to_bag_tag(maxxed_bag_id), maxxed_slot_id);
      Util.add_list_value(full_slots, to_bag_tag(maxxed_bag_id), maxxed_slot_id);
    end
  end 
  return full_slots;
end

local function do_restack()
  -- identify empty slots and slots with glands and select seed stack
  local glands, empty, cnt_cache, _ = analyze_slots();
  local seed_bag_id, seed_slot_id, _ = select_reference_stack(glands);
  local maxxed = {}; -- glands that have max timer
  Util.remove_list_value(glands, to_bag_tag(seed_bag_id), seed_slot_id);
  Util.add_list_value(maxxed, to_bag_tag(seed_bag_id), seed_slot_id);
  -- split reference stack
  local full = nil; 
  while table.getn(Util.table_keys(glands)) > 0 do
    _, seed_bag_id, seed_slot_id = extract_bag_slot_first(maxxed);
    local remaining_stacks = Util.count_list_value(glands);
    local maxxed_splitted;
    empty, maxxed_splitted = split_stack(empty, cnt_cache, seed_bag_id, seed_slot_id, remaining_stacks + 1);
    maxxed = Util.merge_list_value(maxxed_splitted, maxxed);
    full = move_stacks(maxxed, glands, cnt_cache);
    maxxed = Util.merge_list_value(full, maxxed);
  end
  -- merge all
end

ns.Restack = {};
ns.Restack.bag_tag = bag_tag;
ns.Restack.analyze_slots = analyze_slots;
ns.Restack.do_restack = do_restack;