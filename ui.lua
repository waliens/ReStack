-- Namespace
local _, ns = ...;

ns.RestackUI = {};

local RestackUI = ns.RestackUI;

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
  frame.countButton = createButton(frame, "ReStack_CountButton", "Count", {90, 20}, {"RIGHT", frame, "BOTTOM"}, {-5, 25});
  frame.restackButton = createButton(frame, "ReStack_RestackButton", "Restack", {90, 20}, {"LEFT", frame.countButton, "RIGHT"}, {10, 0});

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

RestackUI.toggleMenu = toggleMenu;
RestackUI.createButton = createButton;
RestackUI.createMenu = createMenu;