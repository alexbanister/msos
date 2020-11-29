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
         MSOS:Print("Loot rules")
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
      debug = true,
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
   if self.db.profile.debug then
      local hex = "990000";
      local prefix = string.format("|cff%s%s|r", hex:upper(), "MS/OS DEBUG:");	
      DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
   end
end

function MSOS:OnInitialize()
   self.db = LibStub("AceDB-3.0"):New("MSOSDB", self.defaults, true)

   LibStub("AceConfig-3.0"):RegisterOptionsTable("MSOS", self.options, {"MSOS", "MSOS"})
   self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MSOS", self.options.name)

   self:RegisterChatCommand("ms", "HandleSlashCommands")
   self:RegisterChatCommand("rl", "Reload")

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
   -- self:ScheduleTimer(function() self:SendMsg("10 Sec Remaining...") end, 20)
   -- self:ScheduleTimer(function() self:SendMsg("5") end, 25)
   -- self:ScheduleTimer(function() self:SendMsg("4") end, 26)
   -- self:ScheduleTimer(function() self:SendMsg("3") end, 27)
   -- self:ScheduleTimer(function() self:SendMsg("2") end, 28)
   -- self:ScheduleTimer(function() self:SendMsg("1") end, 29)
   self:ScheduleTimer(function() 
      self:SendMsg("Roll Has Ended")
      MSOS:FinishRoll(type, index)
   end, 3)
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
   self:SendMsg(self.db.profile.rollingStepText[type].." Roll for "..self.db.profile.loot[index].itemLink)
   if self.db.profile.loot[index].prio ~= nil then
      self:SendMsg(self.db.profile.loot[index].prio)
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
   self:SendMsg("Roll Canceled")
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
   -- if #self.db.profile.loot[index].rolls > 0 then
   --    for i=1, #self.db.profile.loot[index].rolls do
   --       if self.db.profile.loot[index].rolls[i].name.value == name then
   --          -- print("COUNT::: ", self.db.profile.loot[index].rolls[i].count.value)
   --          self.db.profile.loot[index].rolls[i].count.value = self.db.profile.loot[index].rolls[i].count.value + 1
   --          self.db.profile.loot[index].rolls[i].count.color = self.db.profile.colors.warning
   --       end
   --    end
   -- else
      table.insert(self.db.profile.loot[index].rolls, 1, rollLine)
   -- end
   MSOS:SortRolls(self.db.profile.loot[index].rolls)
   -- print("SORTED::: ", #sorted)
   render(MSOS.scroll, MSOS.db.profile.loot)
end

function MSOS:SortRolls(rolls)
   table.sort(rolls, function (a, b) return a.roll.value > b.roll.value end )
   for i = 1, #rolls do 
      rolls[i].position.color = nil
      rolls[i].roll.color = nil
   end
   rolls[1].position.color = self.db.profile.colors.ok
   rolls[1].roll.color = self.db.profile.colors.ok
end

function MSOS:HandleNewLoot()
   local guid1 = GetLootSourceInfo(1)
   if self.db.profile.lootSource[guid1] == nil then
      for i = GetNumLootItems(), 1, -1  do
         local itemLink =  GetLootSlotLink(i)
         local item = Item:CreateFromItemLink(itemLink)

         local name
         local itemId
         local itemIcon
         local itemLink
         item:ContinueOnItemLoad(function()
            name = item:GetItemName() 
            itemId = item:GetItemID()
            itemIcon = item:GetItemIcon()
            itemLink = item:GetItemLink()
         end)
         local item = {
            ["name"] = name,
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
      self.db.profile.lootSource[guid1] = true
   end
end

function MSOS:OnOpen()
   MSOS.MainWindow:Show()
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
      self:SendMsg(loot.name)
   elseif not loot.mats then
      if loot.special then
         prefix = "[Special Roll] "
         prioText = prioText.." Does not count toward MS roll"
      end
      msg = prefix..prioText
      self:SendMsg(loot.name)
      self:SendMsg(msg)
   end
end

function MSOS:SendMsg(msg)
   self:Print(msg)
end

function MSOS:OnEnterInstance(raidInfo)
   MSOS:Debug("ENTERING ZONE")
   local name, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
   MSOS:Debug("ZONE::: "..name)
   MSOS:Debug("TYPE::: "..instanceType)
   MSOS:Debug("ID::: "..instanceID)
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


-- -- function UpdateFrame()
-- --    DebugPrint("\n-----------\nUPDATE")

--    -- local roles = {}
--    -- local classes = {}
--    -- local healerList = {}

--    -- classes, roles = GetRaidRoster()

--    -- roles["DISPELS"] = {"DISPELS"}
--    -- roles["RAID"] = {"RAID"}

--    -- for class, players in pairs(classes) do
--    --    if healerColors[class] ~= nil then
--    --       for _, player in ipairs(players) do
--    --          if playerFrames[player] == nil then
--    --             local nameFrame = AceGUI:Create("DragLabel")
--    --             nameFrame:SetRelativeWidth(1)
--    --             local classColors = healerColors[class]
--    --             nameFrame:SetColor(classColors[1], classColors[2], classColors[3])
--    --             nameFrame:SetUserData("playerName", player)
--    --             nameFrame:SetCallback("OnDragStart", function(widget) DragStart(widget) end )    
--    --             nameFrame:SetCallback("OnDragStop", function(widget) DragStop(widget) end)
--    --             playerFrames[player] = nameFrame
--    --             playerFrames[player]:SetText(player)
--    --             local nameContainer = AceGUI:Create("SimpleGroup")
--    --             nameContainer:SetRelativeWidth(1)
--    --             nameContainer:AddChild(nameFrame)

--    --             -- add the player frame to the healer container only if they are unassigned
--    --             if reverseAssignments[player] == nil then
--    --                healerGroup:AddChild(nameContainer)
--    --             end
--    --          end

--    --          tinsert(healerList, player)

--    --          DebugPrint(player)
--    --       end
--    --    end
--    -- end

--    -- for role, players in pairs(roles) do
--    --    if role == "MAINTANK" then
--    --       for _, player in ipairs(players) do
--    --          if assignmentGroups[player] == nil then
--    --             CreateAssignmentGroup(player)
--    --          end
--    --          DebugPrint(player)
--    --       end
--    --    elseif role == "RAID" then
--    --       if assignmentGroups[role] == nil then
--    --          CreateAssignmentGroup("RAID")
--    --       end
--    --    elseif role == "DISPELS" then
--    --       if assignmentGroups[role] == nil then
--    --          CreateAssignmentGroup("DISPELS")
--    --       end
--    --    end
--    -- end

--    -- AssignmentPresetsUpdatePresets()
--    -- UpdateAssignments()

--    -- -- calling thrice to avoid inconsistencies between re-renders
--    -- mainWindow:DoLayout()
--    -- mainWindow:DoLayout()
--    -- mainWindow:DoLayout()
-- -- end


-- -- function CreateHealerDropdown(healers, assignment)
-- --    local dropdown = AceGUI:Create("Dropdown")
-- --    dropdown:SetList(healers)
-- --    dropdown:SetText("Assign healer")
-- --    dropdown:SetFullWidth(true)
-- --    dropdown:SetMultiselect(true)
-- --    if assignedHealers[assignment] ~= nil then
-- --       for _,v in ipairs(assignedHealers[assignment]) do
-- --          dropdown:SetItemValue(table.indexOf(healers, v), true)
-- --       end
-- --    end
-- --    return dropdown
-- -- end


-- -- function AnnounceHealers()
-- --    DebugPrint("\n-----------\nASSIGNMENTS")

-- --    AnnounceAssignments("Healing Assignments")
-- --    for target, healers in pairs(assignedHealers) do
-- --       if healers ~= nil then
-- --          local assignment = target ..': ' .. table.concat(healers, ", ")

-- --          DebugPrint(assignment)

-- --          AnnounceAssignments(assignment)
-- --       end
-- --    end

-- --    if selectedChannels["WHISPER"] ~= nil then
-- --      AnnounceWhispers()
-- --    end
-- -- end


-- -- function CreateAssignmentGroup(assignment)
-- --    local nameFrame = AceGUI:Create("InlineGroup")
-- --    nameFrame:SetTitle(assignment)
-- --    nameFrame:SetWidth(140)
-- --    assignmentGroups[assignment] = nameFrame
-- --    assignmentWindow:AddChild(nameFrame)
-- --    assignmentList[assignment] = nameFrame
-- -- end


-- -- function MSOS:HandleRosterChange()
-- --    if IsInRaid() then
-- --       CleanupFrame()
-- --       SetupFrameContainers()
-- --       UpdateFrame()
-- --    end
-- -- end


-- -- function SelectChannel(widget, event, key, checked)
-- --    local channels = GetAllChannelNames()
-- --    local s = channels[key]
-- --    if checked then
-- --       if key <= #defaultChannels then
-- --          selectedChannels[s] = "default"
-- --       else
-- --          selectedChannels[s] = activeChannels[s]
-- --       end
-- --    else
-- --       selectedChannels[s] = nil
-- --    end

-- --    DebugFunction(
-- --       function(ch, id)
-- --          print("Selected channels:")
-- --          for ch, id in pairs(selectedChannels) do
-- --             print("ch=" .. ch .. " id=" .. id)
-- --          end
-- --       end
-- --    )
-- -- end


-- -- function CreateChannelDropdown()
-- --    local dropdown = AceGUI:Create("Dropdown")
-- --    local channels = GetAllChannelNames()
-- --    dropdown:SetList(channels)
-- --    dropdown:SetLabel("Announcement channels")
-- --    dropdown:SetText("Select channels")
-- --    dropdown:SetWidth(200)
-- --    dropdown:SetMultiselect(true)
-- --    dropdown:SetUserData("name", "dropdown")
-- --    dropdown:SetCallback("OnValueChanged", function(widget, event, key, checked) SelectChannel(widget, event, key, checked) end)

-- --    -- looks through channel list to pull the index value & checks the channel in the list
-- --    local channels = GetAllChannelNames()
-- --    for channelName, selected in pairs(selectedChannels) do
-- --       if activeChannels ~= nil then
-- --          dropdown:SetItemValue(table.indexOf(channels, channelName), true)
-- --       end
-- --    end

-- --    return dropdown
-- -- end


-- -- -- Sends MSG to preselected channels
-- -- function AnnounceAssignments(msg)
-- --    for ch, id in pairs(selectedChannels) do
-- --       if id == "default" and ch ~= "WHISPER" then
-- --          SendChatMessage(msg, ch, nil)
-- --       else
-- --          SendChatMessage(msg, "CHANNEL", nil, id)
-- --       end
-- --    end
-- -- end


-- -- -- Sends assignments to all assigned players in a whisper
-- -- function AnnounceWhispers()
-- --     for healer, a in pairs(reverseAssignments) do
-- --       local msg = "Your healing assignments: "..table.concat(a, ", ")
-- --       SendChatMessage(msg, "WHISPER", nil, healer)
-- --     end
-- -- end


-- -- function UpdateChannels()
-- --    activeChannels = {}
-- --    local channels = {GetChannelList()} --returns triads of values: id,name,disabled
-- --    local blizzChannels = {EnumerateServerChannels()}
-- --    for i = 1, table.getn(channels), 3 do
-- --       local id, name = GetChannelName(channels[i])
-- --       if name ~= nil then
-- --          local prunedName = string.match(name, "(%w+)") --filter out blizzard channels
-- --          if not tContains(blizzChannels, prunedName) then
-- --             activeChannels[name] = id
-- --          end
-- --       else --only cleans selectedChannels if the channel name was removed from the list
-- --         if selectedChannels[name] ~= nil then
-- --             selectedChannels[name] = nil
-- --         end
-- --       end
-- --    end
-- -- end


-- -- function GetAllChannelNames()
-- --    local names = {}
-- --    table.merge(names, defaultChannels)
-- --    table.merge(names, table.getKeys(activeChannels))
-- --    return names
-- -- end


-- -- function MSOS:HandleChannelUpdate()
-- --    UpdateChannels()

-- --    DebugFunction(
-- --       function()
-- --          print("Selected announcement channels: " .. table.concat(table.getKeys(selectedChannels), ","))
-- --       end
-- --    )

-- --    if channelDropdown ~= nil then
-- --       local channels = GetAllChannelNames()
-- --       channelDropdown:SetList(channels)
-- --    end
-- --    CleanupFrame()
-- --    SetupFrameContainers()
-- --    UpdateFrame()
-- -- end


-- -- function CleanupFrame()
-- --    _, roles = GetRaidRoster()

-- --    -- unassign healers from assignment targets that have been unchecked
-- --    for assignment, assignmentFrame in pairs(assignmentGroups) do
-- --       if assignment ~= "RAID" and assignment ~= "DISPELS" and (roles["MAINTANK"] == nil or not tContains(roles["MAINTANK"], assignment)) then
-- --          assignedHealers[assignment] = nil
-- --       end
-- --    end

-- --    assignmentGroups = {}
-- --    playerFrames = {}
-- --    AssignmentPresetsCleanup()
-- --    mainWindow:ReleaseChildren()
-- -- end


-- MSOS.mainContainer = AceGUI:Create("SimpleGroup")
--    MSOS.mainContainer:SetFullWidth(true)
--    MSOS.mainContainer:SetFullHeight(true)
--    MSOS.mainContainer:SetLayout("Fill") -- important!
--    MSOS.MainWindow:AddChild(MSOS.mainContainer)

-- MSOS.scroller = AceGUI:Create("ScrollFrame")
--    MSOS.scroller:SetLayout("Flow") -- probably?
--    MSOS.mainContainer:AddChild(MSOS.scroller)

-- MSOS.scrollcontainer = AceGUI:Create("SimpleGroup")
--    MSOS.scrollcontainer:SetFullWidth(true)
--    MSOS.scrollcontainer:SetFullHeight(true)
--    MSOS.scrollcontainer:SetLayout("Fill") -- important!
--    MSOS.scroller:AddChild(MSOS.scrollcontainer)











-- function SetupFrame()
--    MSOS:Debug("SETUP FRAME")
--    -- uiRegisterCustomLayouts()

--    mainWindow = AceGUI:Create("Frame")
--    mainWindow:SetTitle("MS/OS Loot Master")
--    mainWindow:SetStatusText("Molten Core(1094328)")
--    mainWindow:SetLayout("mainWindowLayout")
--    mainWindow:SetWidth("600")
-- end


-- function SetupFrameContainers()

--    scrollcontainer = AceGUI:Create("ScrollFrame") -- "InlineGroup" is also good
-- 	scrollcontainer:SetFullWidth(true)
-- 	scrollcontainer:SetFullHeight(true)
-- 	scrollcontainer:SetLayout("List")
-- 	-- scrollcontainer:SetLayout("Fill") -- important!

-- 	mainWindow:AddChild(scrollcontainer)

-- 	s = AceGUI:Create("ScrollFrame")
-- 	s:SetLayout("Flow") -- probably?
--    scrollcontainer:AddChild(s)
   

--    -- finishLoot = AceGUI:Create("i")
--    -- finishLoot:SetUserData("name", "icon")
--    -- finishLoot:SetFullWidth(true)
--    -- mainWindow:AddChild(finishLoot)
   
--    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(19885)
--    MSOS:Debug("ITEM: ", itemName)
   -- local lbIcon = AceGUI:Create("Icon")
   -- lbIcon:SetRelativeWidth(1)
   -- lbIcon:SetImage(itemTexture)
   -- lbIcon:SetImageSize(36,36)
   -- lbIcon:SetCallback("OnEnter", function(widget)
   --    GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
   --    GameTooltip:SetHyperlink(itemLink)
   --    GameTooltip:Show()
   -- end)
   -- lbIcon:SetCallback("OnLeave", function(widget)
   --    GameTooltip:Hide()
   -- end)
   -- s:AddChild(lbIcon)

   -- local lbPrio = AceGUI:Create("InteractiveLabel")
   -- lbPrio:SetText(itemLink)
   -- lbPrio:SetRelativeWidth(0.20)
   -- s:AddChild(lbPrio)

   -- assignmentWindow = AceGUI:Create("InlineGroup")
   -- assignmentWindow:SetTitle("Assignments")
   -- assignmentWindow:SetRelativeWidth(0.9)
   -- assignmentWindow:SetLayout("Flow")
   -- assignmentWindow:SetUserData("name", "assignmentWindow")
   -- mainWindow:AddChild(assignmentWindow)

   -- AssignmentPresetsSetupFrameContainers(mainWindow)

   -- announceMaster = AceGUI:Create("SimpleGroup")
   -- announceMaster:SetWidth(200)
   -- announceMaster:SetHeight(65)
   -- announceMaster:SetUserData("name", "announceMaster")
   -- announceMaster:SetLayout("AnnouncementsPane")
   -- mainWindow:AddChild(announceMaster)

   -- channelDropdown = CreateChannelDropdown()
   -- announceMaster:AddChild(channelDropdown)

   -- local announceButton = AceGUI:Create("Button")
   -- announceButton:SetText("Announce assignments")
   -- announceButton:SetCallback("OnClick", function() AnnounceHealers() end)
   -- announceButton:SetHeight(20)
   -- announceButton:SetWidth(200)
   -- announceButton:SetUserData("name", "announceButton")
   -- announceMaster:AddChild(announceButton)

-- end


-- -- function GetRaidRoster()
-- --    local classes = {}
-- --    local roles = {}

-- --    for i=1, MAX_RAID_MEMBERS do
-- --       local name, _, _, _, class, _, _, _, _, role, _, _ = GetRaidRosterInfo(i);
-- --       if name then
-- --          if not classes[class] then
-- --             classes[class] = {}
-- --          end
-- --          if role ~= nil and not roles[role] then
-- --             roles[role] = {}
-- --          end

-- --          DebugPrint(role)

-- --          if not tContains(classes[class], name) then
-- --             DebugPrint(name .. " was added")

-- --             tinsert(classes[class], name)
-- --             if role ~= nil then
-- --                tinsert(roles[role], name)
-- --             end
-- --          end
-- --       end
-- --    end

-- --    return classes, roles
-- -- end


-- -- -- listens for 'heal' and replies the target's current healing assignments if any
-- -- -- only replies if character is in raid
-- -- function MSOS:ReplyWithAssignment(event, msg, character)
-- --    -- chopping off server tag that comes with character to parse it more easily
-- --    local characterParse = string.gsub(character, "-(.*)", "")
-- --    if msg == "heal" and UnitInRaid(characterParse) then
-- --       SendChatMessage("You are assigned to: " .. table.concat(GetAssignmentsForPlayer(characterParse), ", "), "WHISPER", nil, character)
-- --    end
-- -- end


-- -- function GetAssignmentsForPlayer(player)
-- --    if reverseAssignments[player] ~= nil then
-- --       return reverseAssignments[player]
-- --    else
-- --       return {}
-- --    end
-- -- end


-- -- function DragStart(widget)
-- --    widget.frame:ClearAllPoints()
-- --    widget.frame:StartMoving()
-- -- end


-- -- function DragStop(widget)
-- --    local uiScale = UIParent:GetEffectiveScale()
-- --    local cursorX, cursorY = GetCursorPosition()
-- --    local scaleCursorX = cursorX / uiScale
-- --    local scaleCursorY = cursorY / uiScale

-- --    local playerName = widget:GetUserData("playerName")

-- --    -- check the unassigned group
-- --    if scaleCursorX > healerGroup.frame:GetLeft() and scaleCursorX < healerGroup.frame:GetRight() then
-- --       if scaleCursorY > healerGroup.frame:GetBottom() and scaleCursorY < healerGroup.frame:GetTop() then
-- --          -- Cursor in the unassigned group. Just need to reset assignments
-- --          ClearAssignments(playerName)
-- --       end
-- --    else
-- --       for assignment, frame in pairs(assignmentList) do
-- --         -- check if the cursor drop is within the frame area
-- --         if scaleCursorX >= frame.frame:GetLeft() and scaleCursorX <= frame.frame:GetRight() then
-- --           if scaleCursorY >= frame.frame:GetBottom() and scaleCursorY <= frame.frame:GetTop() then
-- --             -- correct frame found, clearing all assignments for correct reassignment
-- --             ClearAssignments(playerName)
-- --             AssignHealer(assignment, playerName)
-- --           end
-- --          end
-- --       end
-- --    end
-- --      -- refresh frame
-- --       CleanupFrame()
-- --       SetupFrameContainers()
-- --       UpdateFrame()
-- -- end


-- -- function UpdateAssignments()
-- --    if assignmentList ~= nil then
-- --       for assignment, frame in pairs(assignmentList) do
-- --          if assignedHealers[assignment] ~= nil then
-- --             for _, healer in ipairs(assignedHealers[assignment]) do
-- --             -- uses nameContainer or else the healer frames will stick to each other
-- --                local nameContainer = AceGUI:Create("SimpleGroup") 
-- --                nameContainer:SetRelativeWidth(1)
-- --                nameContainer:AddChild(playerFrames[healer])
-- --                frame:AddChild(nameContainer)
-- --             end
-- --          end
-- --       end
-- --    end
-- -- end


-- -- -- Clears all assignments for the selected player
-- -- -- Alters both assignedHealers array and reverseAssignments array
-- -- function ClearAssignments(playerName)
-- --    -- if there aren't any assignments for the player, do nothing
-- --    if reverseAssignments[playerName] ~= nil then
-- --       for _, assignment in pairs (reverseAssignments[playerName]) do
-- --          -- if the assignment itself is empty, no reason to do anything
-- --          if assignedHealers[assignment] ~= nil then
-- --             local healerIndex = table.indexOf(assignedHealers[assignment], playerName)
-- --             tremove(assignedHealers[assignment], healerIndex)
-- --             local assignmentIndex = table.indexOf(reverseAssignments[playerName], assignment)
-- --             tremove(reverseAssignments[playerName], assignmentIndex)
            
-- --             -- if the tables are empty, clear them so they can be initialized on refresh
-- --             if table.isEmpty(reverseAssignments[playerName]) then
-- --                reverseAssignments[playerName] = nil
-- --             end

-- --             if table.isEmpty(assignedHealers[assignment]) then
-- --                assignedHealers[assignment] = nil
-- --             end
-- --          end
-- --       end
-- --    end
-- -- end

-- -- function AssignHealer(assignment, playerName)
-- -- -- set assignments, initialize if the tables are empty
-- --    if(assignedHealers[assignment] ~= nil) then
-- --       tinsert(assignedHealers[assignment], playerName)
-- --    else
-- --       assignedHealers[assignment] = {playerName}
-- --    end
   
-- --    -- separate if statement to check if the individual player's assignments are empty
-- --    if(reverseAssignments[player] ~= nil) then
-- --       tinsert(reverseAssignments[playerName], assignment)
-- --    else
-- --       reverseAssignments[playerName] = {assignment}				
-- --    end
-- -- end