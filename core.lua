local MSOS = LibStub("AceAddon-3.0"):NewAddon("MSOS", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");
local icon = LibStub("LibDBIcon-1.0", true)
_G["MSOS"] = MSOS
local AceGUI = LibStub("AceGUI-3.0")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject("MSOS", {
   type = "launcher",
   text = "MS/OS Master Loot",
   icon = "133641",
   OnTooltipShow = function(tooltip)
      tooltip:AddLine("MS/OS Master Loot")
      tooltip:AddLine(format("|cFFC41F3B%s:|r %s", "Left-Click", "Open Loot Panel"))
      tooltip:AddLine(format("|cFFC41F3B%s:|r %s", "Right-Click", "Open Config"))
      tooltip:AddLine(format("|cFFC41F3B%s:|r %s", "Shift + Left-Click", "Post Loot Rules"))
   end,
   OnClick = function(self, button)
      if (button == "LeftButton" and IsShiftKeyDown()) then
         MSOS:SendMsg("Loot rules", 1)
         MSOS:SendMsg("Put Loot Rules here", 1)
      elseif (button == "LeftButton") then
         MSOS:ToggleFrame()
      elseif (button == "RightButton") then
         if (InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown()) then
            InterfaceOptionsFrame:Hide();
         else
            MSOS:OpenConfig();
         end
      end
   end
})

---------------------------------------------
-- Options
---------------------------------------------
MSOS.options = {
   name = "MS/OS Master Loot",
   handler = MSOS,
   type = 'group',
   args = {
      debug = {
         type = "toggle",
         name = "Enable Debug Mode",
         desc = "Enables or Disables Debug Printouts",
         get  = function() return MSOS.db.profile.debug end,
         set  = function(_, value) MSOS.db.profile.debug = value end,
         order = 1,
      },
      icon = {
         type = "toggle",
         name = "Hide Minimap Icon",
         desc = "Shows or Hides minimap icon",
         get = function() return MSOS.db.profile.icon.hide end,
         set = function(_, value) MSOS.db.profile.icon.hide = value end,
         order = 1,

      },
      resetPrio = {
         type = "execute",
         name = "Reset Prio List",
         order = 1,
         func = function() MSOS:ResetPrio() end,
      },
      resetLoot = {
         type = "execute",
         name = "Reset Loot",
         order = 1,
         func = function() MSOS:ResetLoot() end,
      },
   },
}

---------------------------------------------
-- Message and enable option defaults
---------------------------------------------
MSOS.defaults = {
   profile = {
      setting = true,
      debug = false,
      icon  = {
         hide = false,
      },
      theme = {
         r = 0, 
         g = 0.8, -- 204/255
         b = 1,
         hex = "00ccff"
      },
      colors = {
         error = {
            r = 0.8,
            g = 0,
            b = 0,
            hex = "CC0000"
         },
         warning = {
            r = 1,
            g = 0.5,
            b = 0,
            hex = "FF8000"
         },
         ok = {
            r = 0,
            g = 0.6,
            b = 0,
            hex = "009900"
         },
      },
      rollingStepText = {
         ms = "Main Spec",
         os = "Off Spec",
         special = "Special"
      },
      prioList = {},
      loot = {},
      MatsTable = {},
      members = {},
      lootSource = {}
   }
}

function MSOS:HandleSlashCommands()	
   MSOS.ToggleFrame()
end

function MSOS:Reload()	
	ReloadUI()
end

function MSOS:GetThemeColor()
	local c = self.db.profile.theme;
	return c.r, c.g, c.b, c.hex;
end

function MSOS:Print(...)
   local hex = select(4, self:GetThemeColor());
   local prefix = string.format("|cff%s%s|r", hex:upper(), "MS/OS:");	
   DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

function MSOS:Debug(...)
   if MSOS.db.profile.debug then
      local hex = "990000";
      local prefix = string.format("|cff%s%s|r", hex:upper(), "MS/OS DEBUG:");	
      DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
   end
end

function MSOS:OnInitialize()
   self.db = LibStub("AceDB-3.0"):New("MSOSDB", self.defaults, true)

   LibStub("AceConfig-3.0"):RegisterOptionsTable("MSOS", self.options, {"MSOS", "MSOS"})
   self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MSOS", self.options.name)

   if self.db.profile.debug then
      self:RegisterChatCommand("ms", "HandleSlashCommands")
      self:RegisterChatCommand("rl", "Reload")
   end

   self.db:RegisterDefaults(self.defaults)
   self.db.profile.prioList = defaultPrio
   self:Debug("Initialized")
end

function MSOS:OnEnable()
   MSOS:Print("MS/OS Loot Master addon loaded")

   -- Minimap button.
   if icon and not icon:IsRegistered("MSOS") then
      icon:Register("MSOS", dataobj, self.db.profile.icon)
   end
  
   -- UpdateFrame()
   MSOS:RegisterEvents()
   MSOS:setupFrame()

   if self.db.profile.debug then
      self.MainWindow:Show()
   end
end

function MSOS:OnDisable()
   MSOS:Debug("DISABLED")
end


function MSOS:RegisterEvents()
   MSOS:Debug("REGISTERING")

   self:RegisterEvent("LOOT_READY", "HandleNewLoot")
   self:RegisterEvent("LOOT_OPENED", "OnOpen")
   self:RegisterEvent("LOOT_CLOSED", "OnClose")
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEnterInstance")   

   -- ITEM_DATA_LOAD_RESULT
   -- CHAT_MSG_LOOT
   -- LOOT_CLOSED  Fired when a player ceases looting a corpse. Note that this will fire before the last CHAT_MSG_LOOT event for that loot.
   -- LOOT_OPENED  Fired when a corpse is looted
   -- LOOT_SLOT_CLEARED Fired when loot is removed from a corpse
   -- OPEN_MASTER_LOOT_LIST
   -- RAID_INSTANCE_WELCOME  Fired when the player enters an instance that saves raid members after a boss is killed.
   -- MSOS:RegisterEvent("CHANNEL_UI_UPDATE", "HandleChannelUpdate")
   -- MSOS:RegisterEvent("GROUP_ROSTER_UPDATE", "HandleRosterChange")
   -- MSOS:RegisterEvent("CHAT_MSG_WHISPER", "ReplyWithAssignment")
end

function MSOS:DataLoaded(itemId, sucess)
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:ToggleFrame()
   MSOS:Debug("TOGGLE FRAME")

   if MSOS.MainWindow:IsVisible() then
      MSOS.scroll:ReleaseChildren()
      self.OnClose()
   else
      self.OnOpen()
   end
end

function MSOS:RollTimer(type, index)
   self:CancelAllTimers()
   self:ScheduleTimer(function() self:SendMsg("10 Sec Remaining...", 1) end, 20)
   self:ScheduleTimer(function() self:SendMsg("5", 1) end, 25)
   self:ScheduleTimer(function() self:SendMsg("4", 1) end, 26)
   self:ScheduleTimer(function() self:SendMsg("3", 1) end, 27)
   self:ScheduleTimer(function() self:SendMsg("2", 1) end, 28)
   self:ScheduleTimer(function() self:SendMsg("1", 1) end, 29)
   self:ScheduleTimer(function() 
      self:SendMsg("Roll Has Ended", 2)
      MSOS:FinishRoll(type, index)
   end, 30)
end

function MSOS:StartRoll(type, index)
   MSOS:RegisterEvent('CHAT_MSG_SYSTEM', "GetRolls")
   self.db.profile.currentRollIndex = index
   self.db.profile.loot[index].rollButtonStatus = {
      ms = false,
      os = false,
      special = false,
      mats = true,
      cancel = true,
   }
   self.db.profile.loot[index].rollingState = "rolling"
   self.db.profile.loot[index].rollingStep = type
   self.db.profile.loot[index].rolls = {}
   self:SendMsg(self.db.profile.rollingStepText[type].." Roll for "..self.db.profile.loot[index].itemLink, 1)
   if self.db.profile.loot[index].prio ~= nil then
      self:SendMsg(self.db.profile.loot[index].prio, 1)
   end
   self:RollTimer(type, index)
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:FinishRoll(type)
   if type == "ms" then
      self.db.profile.loot[self.db.profile.currentRollIndex].rollButtonStatus.os = true
   end
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:CancelRoll(type)
   self:CancelAllTimers()
   self:SendMsg("Roll Canceled", 1)
   self.db.profile.loot[self.db.profile.currentRollIndex].rollButtonStatus.cancel = false
   self.db.profile.loot[self.db.profile.currentRollIndex].rollButtonStatus.ms = true
   self.db.profile.loot[self.db.profile.currentRollIndex].rollButtonStatus.os = true
   self.db.profile.loot[self.db.profile.currentRollIndex].rollButtonStatus.special = true
   render(MSOS.scroll, MSOS.db.profile.loot)
   MSOS:LootItemCloseOut()
end

function MSOS:LootItemCloseOut()
   MSOS:UnregisterEvent('CHAT_MSG_SYSTEM')
end

function MSOS:GetRolls(event, msg)
   self:Debug("READING ROLLS")
   local name, roll, low, high
   local found = strfind(msg,"rolls",1,true)

   if found ~= nil then
      _,_,name, roll, low, high = string.find(msg, "(%a+) rolls (%d+) %((%d+)%-(%d+)%)$")
   end
   
   roll = tonumber(roll, 10)
   low = tonumber(low, 10)
   high = tonumber(high, 10)

   if not name or not roll or low ~= 1 or high ~= 100 then
      return
   end
   MSOS:ProcessRoll(name, roll)
end

function MSOS:ProcessRoll(name, roll)
   local index = self.db.profile.currentRollIndex
   local default = {
      name = name,
      class = UnitClass(name),
      ms = 0,
      os = 0,
      special = 0
   }

   if self.db.profile.members[name] == nil then
      self.db.profile.members[name] = default
   end

   local rollLine = {
      position = {
         value = 1,
      },
      roll = {
         value = roll,
      },
      name = {
         value = self.db.profile.members[name].name,
         color = self.db.profile.members[name].class
      },
      ms = {
         value = self.db.profile.members[name].ms,
      },
      os = {
         value = self.db.profile.members[name].os,
      },
      special = {
         value = self.db.profile.members[name].special,
      },
      count = {
         value = 1,
      },
      awardable = true
   }
   local dupe = false
   if #self.db.profile.loot[index].rolls > 0 then
      for i=1, #self.db.profile.loot[index].rolls do
         if self.db.profile.loot[index].rolls[i].name.value == name then
            self.db.profile.loot[index].rolls[i].count.value = self.db.profile.loot[index].rolls[i].count.value + 1
            self.db.profile.loot[index].rolls[i].count.color = self.db.profile.colors.warning
            dupe = true
         end
      end
      if not dupe then
         table.insert(self.db.profile.loot[index].rolls, 1, rollLine)
      end
   else
      table.insert(self.db.profile.loot[index].rolls, 1, rollLine)
   end
   MSOS:SortRolls(self.db.profile.loot[index].rolls)
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:SortRolls(rolls)
   local type = self.db.profile.loot[self.db.profile.currentRollIndex].rollingStep
   table.sort(rolls, function (a, b) return a.roll.value > b.roll.value end )
   table.sort(rolls, function(a, b)
      if a[type].value ~= b[type].value then
          return a[type].value < b[type].value
      end

      return a.roll.value > b.roll.value
   end)
   for i = 1, #rolls do 
      rolls[i].position.color = nil
      rolls[i].roll.color = nil
      if rolls[i].ms.value > 0 then
         rolls[i].ms.color = self.db.profile.colors.error
      end
   end
   rolls[1].position.color = self.db.profile.colors.ok
   rolls[1].roll.color = self.db.profile.colors.ok
end

function MSOS:HandleNewLoot()
   if not self.db.profile.debug then
      local _,masterlooterPartyID = GetLootMethod()
      -- Only print loot if we are the master looter and there is loot

      if masterlooterPartyID ~= 0 or GetNumLootItems() == 0 then
         return
      end
   end

   local guid1 = GetLootSourceInfo(1)
   if self.db.profile.lootSource[guid1] == nil then
      for i = 1, GetNumLootItems()  do
         local itemLink =  GetLootSlotLink(i)
         if itemLink ~= nil then
            local item = Item:CreateFromItemLink(itemLink)

            local name
            local itemId
            local itemIcon
            local itemLink
            local itemQuality
            item:ContinueOnItemLoad(function()
               name = item:GetItemName() 
               itemId = item:GetItemID()
               itemIcon = item:GetItemIcon()
               itemLink = item:GetItemLink()
               itemQuality = item:GetItemQuality()
            end)
            if itemQuality >= GetLootThreshold() then
               local item = {
                  ["name"] = name,
                  ["lootSlot"] = i,
                  ["itemId"] = itemId,
                  ["itemLink"] = itemLink,
                  ["inList"] = false,
                  ["prio"] = nil,
                  ["mats"] = false,
                  ["special"] = false,
                  ["rollingState"] = "waiting",
                  ["active"] = true,
                  ["awardedTo"] = {},
                  ["rolls"] = {},
                  ["rollButtonStatus"] = {
                     ms = true,
                     os = false,
                     special = true,
                     mats = true,
                     cancel = false,
                  }
               }
               if self.db.profile.prioList[name] then
                  item.prio = self.db.profile.prioList[name].prio
                  if self.db.profile.prioList[name].mats then
                     item.mats = true
                     item.rollButtonStatus.special = false
                     item.rollButtonStatus.ms = false
                  end
                  if self.db.profile.prioList[name].special then
                     item.special = true
                     item.rollButtonStatus.ms = false
                  end
                  item.inList = true
                  if self.db.profile.prioList[name].special then
                     item.rollButtonStatus.special = true
                     item.rollButtonStatus.ms = false
                  end
               end
               table.insert(self.db.profile.loot, 1, item)
               self:AnnounceLoot(item)
            end
         end
      end
      self.db.profile.lootSource[guid1] = true
   end
end

function MSOS:OnOpen()
   if not MSOS.db.profile.debug then
      local _,masterlooterPartyID = GetLootMethod()
      -- Only print loot if we are the master looter and there is loot
      if masterlooterPartyID ~= 0 or GetNumLootItems() == 0 then
         return
      end
   end
   MSOS.MainWindow:Show()
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:PlayIsEligible(name)
   local lootSlot = self.db.profile.loot[self.db.profile.currentRollIndex].lootSlot
   for ci = 1, 40 do
      if GetMasterLootCandidate(lootSlot, ci) == name then 
         return ci
      end
   end
   return false
end

function MSOS:AwardLoot(name)
   self:CancelAllTimers()
   local winnerIndex = MSOS:PlayIsEligible(name)
   local lootSlot = self.db.profile.loot[self.db.profile.currentRollIndex].lootSlot
   GiveMasterLoot(lootSlot, winnerIndex)
   local type = self.db.profile.loot[self.db.profile.currentRollIndex].rollingStep
   self.db.profile.members[name][type] = self.db.profile.members[name][type] +1
   self.db.profile.loot[self.db.profile.currentRollIndex].awardedTo.name = name
   self.db.profile.loot[self.db.profile.currentRollIndex].rollingState = "finished"
   self.db.profile.loot[self.db.profile.currentRollIndex].active = false
   self:SendMsg("Congrats "..name..". You won "..self.db.profile.loot[self.db.profile.currentRollIndex].itemLink, 2)
   MSOS:LootItemCloseOut()
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:OnClose()
   CloseLoot()
   MSOS.scroll:ReleaseChildren()
   MSOS.MainWindow:Hide()
end

function MSOS:AnnounceLoot(loot)
   local prefix = ""
   local prioText = "No Prio, Open roll."
   local msg = ""
   if not loot.inList then
      self:SendMsg(loot.itemLink, 1)
   elseif not loot.mats then
      if loot.special then
         prefix = "[Special Roll] "
         prioText = prioText.." Does not count toward MS roll"
      end
      msg = prefix..prioText
      self:SendMsg(loot.itemLink, 1)
      self:SendMsg(msg, 1)
   end
end

function MSOS:SendMsg(msg, lvl)
   local channels
   if IsInRaid() then
      channels = { "RAID_WARNING", "RAID"}
   else
      channels = { "PARTY", "PARTY"}
   end
   if self.db.profile.debug then
      -- self:Print(msg)
      SendChatMessage(msg, channels[lvl])
   else
      SendChatMessage(msg, channels[lvl])
   end
end

function MSOS:BuildMatsList()
   local MatsTable = {}
   for i = 1, 40 do
      local name = GetRaidRosterInfo(i)
      if name ~= nil then
         table.insert(MatsTable, {["name"] = name, ["count"] = 0})
      end
   end
   for i = 1, #MatsTable do
      if self.db.profile.MatsTable[MatsTable[i].name] ~= nil then
         MatsTable[i].count = self.db.profile.MatsTable[MatsTable[i].name]
      else
         self.db.profile.MatsTable[MatsTable[i].name] = 0
      end
   end
   table.sort(MatsTable, function (a, b) return a.count > b.count end )
   local orderedTable = {}
   for i = 1, #MatsTable do
      local name = MatsTable[i].name
      orderedTable[name] = name
   end
   return orderedTable
end

function MSOS:HandleMats(loot, name, index)
   self.db.profile.MatsTable[name] = self.db.profile.MatsTable[name] + 1
   local winnerIndex = MSOS:PlayIsEligible(name)
   GiveMasterLoot(loot.lootSlot, winnerIndex)
   self.db.profile.loot[index].awardedTo.name = name
   self.db.profile.loot[index].rollingState = "finished"
   self.db.profile.loot[index].active = false
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:OnEnterInstance(raidInfo)
   MSOS:Debug("ENTERING ZONE")
   local name, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
   if (instanceType == "raid") then
      self:Print("Loot set for "..name)
   elseif (instanceType == "party") then
      self:Print("Loot set for "..name)
   end
end

function MSOS:HideTheIcon(input)
   self.db.profile.icon.hide = not self.db.profile.icon.hide
   if self.db.profile.icon.hide then
       icon:Hide("MSOS")
   else
       icon:Show("MSOS")
   end
end

function MSOS:ResetPrio()
   self.db.profile.prioList = defaultPrio
end 

function MSOS:ResetLoot()
   self.db.profile.loot = {}
   self.db.profile.lootSource = {}
   self.db.profile.MatsTable = {}
   self.db.profile.members = {}
   self.db.profile.lootSource = {}
   self.db.profile.currentRollIndex = nil
end 

function MSOS:setupFrame()
   MSOS.MainWindow = AceGUI:Create("Window")
      MSOS.MainWindow:SetTitle(self.options.name)
      MSOS.MainWindow:SetLayout("Fill")
      MSOS.MainWindow:SetCallback("OnClose", function() self:OnClose() end)

   MSOS.scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
      MSOS.scrollcontainer:SetFullWidth(true)
      MSOS.scrollcontainer:SetFullHeight(true) -- probably?
      MSOS.scrollcontainer:SetLayout("Fill") -- important!
      MSOS.MainWindow:AddChild(MSOS.scrollcontainer)
   
   MSOS.scroll = AceGUI:Create("ScrollFrame")
      MSOS.scroll:SetLayout("Flow") -- probably?
      MSOS.scrollcontainer:AddChild(MSOS.scroll)

   _G["MyGlobalFrameName"] = MSOS.MainWindow
   -- Register the global variable `MyGlobalFrameName` as a "special frame"
   -- so that it is closed when the escape key is pressed.
   tinsert(UISpecialFrames, "MyGlobalFrameName")
end

function MSOS:OpenConfig()
   MSOS:Debug("OPEN CONFIG")
   --Opening the frame needs to be run twice to avoid a bug.
   -- InterfaceOptionsFrame:Show();
	InterfaceOptionsFrame_OpenToCategory(self.options.name);
	--Hack to fix the issue of interface options not opening to menus below the current scroll range.
	--This addon name starts with N and will always be closer to the middle so just scroll to the middle when opening.
	local min, max = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues();
	if (min < max) then
		InterfaceOptionsFrameAddOnsListScrollBar:SetValue(math.floor(max/2));
	end
	InterfaceOptionsFrame_OpenToCategory(self.options.name);
end