-- Namespace
local _, ns = ...;

local Restack = ns.Restack;
local Util = ns.Util;

-------------
-- Restack --
-------------
local function createButton(parent_frame, button_name, text, size, point_ref, point_offset)
  -- extract offset
  local xoff, yoff = {0, 0};
  if point_offset ~= nil then
    xoff, yoff = point_offset[1], point_offset[2];
  end
  local button = CreateFrame("Button", button_name, parent_frame, "GameMenuButtonTemplate");
  button:SetPoint(point_ref[1], point_ref[2], point_ref[3], xoff, yoff);
  button:SetSize(size[1], size[2]);
  button:SetText(text);
  return button;
end

local function createFontString(frame, name, layer, point_ref, point_offset)
  local xoff, yoff = {0, 0};
  if point_offset ~= nil then
    xoff, yoff = point_offset[1], point_offset[2];
  end
  local font_string = frame:CreateFontString(name, layer);
  font_string:SetFontObject("GameFontHighlight");
  font_string:SetPoint(point_ref[1], point_ref[2], point_ref[3], xoff, yoff);
  return font_string;
end

local function updateText(rs_frame, count, maxtime, mintime)
  rs_frame.countString:SetText("Glands: " .. count);
  rs_frame.maxTimeString:SetText("Max time: " .. maxtime);
  rs_frame.minTimeString:SetText("Min time: " .. mintime);
end

local function execute_item_moving_fn(fn)
  local launch_fn = function(self, event)
    -- create coroutine
    local co = coroutine.create(fn);
    -- resume coroutine when item unlocked is fired

    local f = CreateFrame("Frame");
      f:RegisterEvent("ITEM_UNLOCKED");
      f:RegisterEvent("BAG_UPDATE");
      f:SetScript("OnEvent", function(self, event, ...)
      if coroutine.status(co) == "dead" then
        f:UnregisterEvent("ITEM_UNLOCKED");
        f:UnregisterEvent("BAG_UPDATE");
      end
      if event == "ITEM_UNLOCKED" or event == "BAG_UPDATE" then
        coroutine.resume(co);
      end
    end);

    -- launch
    coroutine.resume(co);
  end
  return launch_fn;
end

local function createMenu() 
  local frame = CreateFrame("Frame", "ReStack_MainFrame", UIParent, "BasicFrameTemplateWithInset");
  frame:SetSize(300, 200);
  frame:SetPoint("CENTER", UIParent, "CENTER");

  -- title
  frame.title = createFontString(frame, "ReStack_MainFrameTitle", "OVERLAY", {"LEFT", frame.TitleBg, "LEFT"}, {5, 0});
  frame.title:SetText("ReStack");

  -- texts
  frame.countString = createFontString(frame, "ReStack_CountString", "OVERLAY", {"CENTER", frame, "CENTER"}, {0, 35});
  frame.maxTimeString = createFontString(frame, "ReStack_MaxTimeString", "OVERLAY", {"CENTER", frame.countString, "CENTER"}, {0, -20});
  frame.minTimeString = createFontString(frame, "ReStack_MinTimeString", "OVERLAY", {"CENTER", frame.maxTimeString, "CENTER"}, {0, -20});
  updateText(frame, 0, 0, 0);

  -- buttons
  frame.countButton = createButton(frame, "ReStack_CountButton", "Count", {65, 20}, {"RIGHT", frame, "BOTTOM"}, {-45, 25});
  frame.restackButton = createButton(frame, "ReStack_RestackButton", "Restack", {65, 20}, {"LEFT", frame.countButton, "RIGHT"}, {10, 0});
  frame.cleanupButton = createButton(frame, "ReStack_CleanupButton", "Clean up", {65; 20}, {"LEFT", frame.restackButton, "RIGHT"}, {10, 0})

  frame.countButton:SetScript("OnClick", function(self, event)
    local _, _, _, item_count = Restack.analyze_slots();
    updateText(frame, item_count, 0, 0);
  end);

  frame.restackButton:SetScript("OnClick", execute_item_moving_fn(Restack.do_restack));
  frame.cleanupButton:SetScript("OnClick", execute_item_moving_fn(Restack.do_cleanup));

  -- make the menu movable 
  frame:SetMovable(true);
  frame:EnableMouse(true);
  frame:RegisterForDrag("LeftButton");
  frame:SetScript("OnDragStart", frame.StartMoving);
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing);

  return frame;
end

local function toggleMenu(menu) 
  -- hide window at bootstrap
  if menu == nil then
    menu = createMenu();
  end
  menu:SetShown(not menu:IsShown());
  return menu;
end

ns.RestackUI = {};
ns.RestackUI.toggleMenu = toggleMenu;
ns.RestackUI.createButton = createButton;
ns.RestackUI.createMenu = createMenu;