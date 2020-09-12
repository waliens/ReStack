
local addon_name, ns = ...;

local Util = ns.Util;
local RestackUI = ns.RestackUI;

function ns:init(event, name) -- DEBUG --
  if event ~= "ADDON_LOADED" or name ~= addon_name then
    return;
  end
  
  -- DEBUG --
  SLASH_FRAMESTK1 = "/fs";
  SlashCmdList.FRAMESTK = function() 
    LoadAddOn("Blizzard_DebugTools");
    FrameStackTooltip_Toggle();
  end
  -- DEBUG --

  -- creates a hidden menu
  local UIConfig = RestackUI.toggleMenu(nil);
  
  SLASH_RESTACK1 = "/restack";
  SLASH_RESTACK2 = "/rs";
  SlashCmdList.RESTACK = function()
    UIConfig = RestackUI.toggleMenu(UIConfig);
  end
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", ns.init);