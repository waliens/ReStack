
-- Namespace
local _, ns = ...;

local Util = ns.Util;
local Restacker = {};

-- Constants
GLAND_ID = 4338; -- 12586; -- 
MAX_GLAND_STACK_SIZE = 20; -- 50; -- 

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
  -- read player's containers to track glands and empty slots
  -- build a count cache (cnt_cache) to keep track of gland stack sizes
  -- not relying on on the unreliable GetContainerItemInfo
  local empty_slots = {};
  local gland_slots = {};
  local cnt_cache = {};
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

local function move_item(cnt_cache, src_bag, src_slot, quantity, dst_bag, dst_slot)
  -- Move an stack or part of a stack from a container slot to another
  ClearCursor();
  -- check not locked
  repeat
    local _, _, locked1 = GetContainerItemInfo(src_bag, src_slot);
    local _, _, locked2 = GetContainerItemInfo(dst_bag, dst_slot);

    if locked1 or locked2 then
        coroutine.yield();
    end
  until not (locked1 or locked2)

  -- actual move
  if quantity == -1 or Util.cache_get(cnt_cache, {src_bag, src_slot}) == quantity then
    PickupContainerItem(src_bag, src_slot)
  else
    SplitContainerItem(src_bag, src_slot, quantity);
  end
  PickupContainerItem(dst_bag, dst_slot); 
end

local function extract_bag_slot(bag_slots)
  -- extract a bag slot from the bag_slots structure, takes the first available
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
  -- extract a bag slot from the bag_slots structure
  -- if min is true, the slot with the smallest stack size is returned
  -- if min is false, the slot with the largest stack size is returned
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

local function split_stack(cnt_cache, empty, src_bag, src_slot, max_splits)
  -- Split stack - split a source item stack ($src_bag, $src_slot) into as many piles of size 1
  -- as possible. Splitted stacks are placed in slots listed in empty slots.
  --
  -- empty: list of empty slots
  -- cnt_cache: cache mapping (bag_id, slot_id) => item_count
  -- src_bag_id: (int) source_bag_id
  -- src_slot: (int) src_slot
  -- max_splits: (int) maximum number of splits out of the source stack
  local stack_size = Util.cache_get(cnt_cache, {src_bag, src_slot});
  local nb_splits = math.min(max_splits, stack_size - 1);
  local maxed = {};
  Util.add_list_value(maxed, to_bag_tag(src_bag), src_slot);

  local cnt = 0;
  while cnt < nb_splits and table.getn(Util.table_keys(empty)) > 0 do
    local dst_bag_tag, dst_bag, dst_slot = extract_bag_slot(empty); 
    move_item(cnt_cache, src_bag, src_slot, 1, dst_bag, dst_slot);
    -- update item count cache
    cache_increment(cnt_cache, {src_bag, src_slot}, -1);
    cache_increment(cnt_cache, {dst_bag, dst_slot}, 1);
    -- update slots structures
    Util.remove_list_value(empty, dst_bag_tag, dst_slot);
    Util.add_list_value(maxed, dst_bag_tag, dst_slot);
    cnt = cnt + 1;
  end

  return maxed;
end

local function select_and_merge_stacks(cnt_cache, empty, src_slots, dst_slots, merge_to_largest)
  -- merge_to_largest : true if smaller stacks should be merged into larger stacks
  local src_bag, src_slot, src_stack_size = extract_bag_slot_opt(cnt_cache, src_slots, merge_to_largest);
  Util.remove_list_value(src_slots, to_bag_tag(src_bag), src_slot); -- in case src_slots == dst_slots and stacks have the same size
  local dst_bag, dst_slot, dst_stack_size = extract_bag_slot_opt(cnt_cache, dst_slots, not merge_to_largest);
  local amount = math.min(MAX_GLAND_STACK_SIZE - dst_stack_size, src_stack_size);
  move_item(cnt_cache, src_bag, src_slot, amount, dst_bag, dst_slot);

  -- update count cache
  cache_increment(cnt_cache, {src_bag, src_slot}, -amount);
  cache_increment(cnt_cache, {dst_bag, dst_slot}, amount);
  
  -- if source stack is not empty, add it back to the list of source slots
  if src_stack_size ~= amount then
    Util.add_list_value(src_slots, to_bag_tag(src_bag), src_slot);
  else
    Util.add_list_value(empty, to_bag_tag(src_bag), src_slot);
  end
  -- return dst slot info (bag, slot, size)
  return dst_bag, dst_slot, dst_stack_size + amount;
end 

local function refresh_stacks(cnt_cache, empty, glands, maxed)
  -- Move stacks so that timers are maxed out
  -- Stops whenever everything is maxed out or when all maxed slots are full
  -- maxed: slot filled with max time glands
  -- glands: slot of glands to uptime
  local full = {};
  while table.getn(Util.table_keys(maxed)) > 0 and table.getn(Util.table_keys(glands)) > 0 do 
    local bag, slot, stack_size = select_and_merge_stacks(cnt_cache, empty, glands, maxed, false);
    if stack_size == MAX_GLAND_STACK_SIZE then
      Util.remove_list_value(maxed, to_bag_tag(bag), slot);
      Util.add_list_value(full, to_bag_tag(bag), slot);
    end
  end 
  return full;
end

local function check_full_slots(cnt_cache, bag_slots)
  -- checks which slots in bag_slots contain a full stack
  -- full stacks are removed from bag_slots
  local full = {};
  for bag_tag, slots in pairs(bag_slots) do
    local bag = to_bag_id(bag_tag);
    for _, slot in ipairs(slots) do
      if Util.cache_get(cnt_cache, {bag, tag}) == MAX_GLAND_STACK_SIZE then
        Util.remove_list_value(bag_slots, bag_tag, slot);
        Util.add_list_value(full, bag_tag, slot);
      end
    end
  end
  return full;
end

local function clean_up(cnt_cache, empty, glands)
  -- remerge all stacks so that it fills a minimum number of bag slots
  -- first checks which ones are already full 
  if table.getn(Util.table_keys(glands)) == 0 then
    return;
  end

  -- filter full slots
  local full = check_full_slots(cnt_cache, glands);

  -- until there is only one stack not full, merge stacks
  while Util.count_list_value(glands) > 1 do
    local dst_bag, dst_slot, dst_stack_size = select_and_merge_stacks(cnt_cache, empty, glands, glands, true);
    if dst_stack_size == MAX_GLAND_STACK_SIZE then
      Util.remove_list_value(glands, to_bag_tag(dst_bag), dst_slot);
      Util.add_list_value(full, to_bag_tag(dst_bag), dst_slot);
    end
  end

  -- move last gland stack into full structure
  local to_move = full;
  local b, _, s = extract_bag_slot(glands);
  Util.add_list_value(to_move, b, s);

  -- count number of stacks in bag
  local number_stacks = Util.count_list_value(to_move);
  local valid_empty = {};

  -- move to first bag slots
  local bag, slot = 0, 0;
  while number_stacks > 0 and bag < 4 do
    local bag_tag = to_bag_tag(bag);
    slot = 1;
    while number_stacks > 0 and slot <= GetContainerNumSlots(bag) do
      local is_empty = Util.has_list_value(empty, bag_tag, slot);
      local has_glands = Util.has_list_value(to_move, bag_tag, slot);
      if is_empty then
        Util.add_list_value(valid_empty, bag_tag, slot);
        number_stacks = number_stacks - 1;
      elseif has_glands then
        Util.remove_list_value(to_move, bag_tag, slot);
        number_stacks = number_stacks - 1;
      end
      slot = slot + 1;
    end
    bag = bag + 1;
  end

  while Util.count_list_value(valid_empty) > 0 and  Util.count_list_value(to_move) > 0 do
    local empty_bag_tag, empty_bag, empty_slot = extract_bag_slot(valid_empty);
    local gland_bag_tag, gland_bag, gland_slot = extract_bag_slot(to_move);
    move_item(cnt_cache, gland_bag, gland_slot, -1, empty_bag, empty_slot)
    Util.remove_list_value(valid_empty, empty_bag_tag, empty_slot);
    Util.remove_list_value(to_move, gland_bag_tag, gland_slot);
  end
end 

local function do_restack()
  -- execute the restacking 
  local glands, empty, cnt_cache, _ = analyze_slots();
  local seed_bag, seed_slot, _ = extract_bag_slot_opt(cnt_cache, glands, true);
  local maxed = {}; -- gland slots that have max timer
  Util.remove_list_value(glands, to_bag_tag(seed_bag), seed_slot);
  Util.add_list_value(maxed, to_bag_tag(seed_bag), seed_slot);

  while table.getn(Util.table_keys(glands)) > 0 do
    seed_bag, seed_slot, _ = extract_bag_slot_opt(cnt_cache, maxed, false);
    local remaining = Util.count_list_value(glands);
    local splitted = split_stack(cnt_cache, empty, seed_bag, seed_slot, remaining + 1);
    maxed = Util.merge_list_value(splitted, maxed);
    local full = refresh_stacks(cnt_cache, empty, glands, maxed);
    maxed = Util.merge_list_value(full, maxed);
  end

  print("ReStack has restacked your stack(s).")
end

local function do_cleanup()
  local glands, empty, cnt_cache, _ = analyze_slots();
  clean_up(cnt_cache, empty, glands);
end

ns.Restack = {};
ns.Restack.analyze_slots = analyze_slots;
ns.Restack.do_restack = do_restack;
ns.Restack.do_cleanup = do_cleanup;