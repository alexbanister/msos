local AceGUI = LibStub("AceGUI-3.0")

-- local rollingSteps = {
--    ms = "Main Spec",
--    os = "Off Spec",
--    special = "Special"
-- }

function MSOS:createButtonGroup(loot, index)
   local rollButtonGroup = AceGUI:Create("SimpleGroup")
   rollButtonGroup:SetFullWidth(true)
   rollButtonGroup:SetLayout("Flow")

   local MSRollButton = AceGUI:Create("Button")
   MSRollButton:SetText("Main Spec Roll")
   MSRollButton:ClearAllPoints()
   MSRollButton:SetPoint("TOPRIGHT")
   MSRollButton:SetWidth(125)
   MSRollButton:SetHeight(20)
   MSRollButton:SetCallback("OnClick", function() MSOS:StartRoll("ms", index) end)
   if not loot.rollButtonStatus.ms then
      MSRollButton:SetDisabled(true)
   end
   rollButtonGroup:AddChild(MSRollButton)

   local OSRollButton = AceGUI:Create("Button")
   OSRollButton:SetText("Off Spec Roll")
   OSRollButton:ClearAllPoints()
   OSRollButton:SetPoint("TOPRIGHT")
   OSRollButton:SetWidth(125)
   OSRollButton:SetHeight(20)
   OSRollButton:SetCallback("OnClick", function() MSOS:StartRoll("os", index) end)
   if not loot.rollButtonStatus.os then
      OSRollButton:SetDisabled(true)
   end
   rollButtonGroup:AddChild(OSRollButton)

   local SPRollButton = AceGUI:Create("Button")
   SPRollButton:SetText("Special Roll")
   SPRollButton:ClearAllPoints()
   SPRollButton:SetPoint("TOPRIGHT")
   SPRollButton:SetWidth(125)
   SPRollButton:SetHeight(20)
   SPRollButton:SetCallback("OnClick", function() MSOS:StartRoll("special", index) end)
   if not loot.rollButtonStatus.special then
      SPRollButton:SetDisabled(true)
   end
   rollButtonGroup:AddChild(SPRollButton)

   local itemDEButton = AceGUI:Create("Button")
   itemDEButton:SetText("Mats/DE")
   itemDEButton:ClearAllPoints()
   itemDEButton:SetPoint("TOPRIGHT")
   itemDEButton:SetWidth(125)
   itemDEButton:SetHeight(20)
   itemDEButton:SetCallback("OnClick", function() print("MATS/DE ACTION") end)
   if not loot.rollButtonStatus.mats then
      itemDEButton:SetDisabled(true)
   end
   rollButtonGroup:AddChild(itemDEButton)
   return rollButtonGroup
end

function MSOS:createItemBlock(loot, index)
   local item = loot.name
   if loot.itemId ~= nil then
      item = loot.itemId
   end
   local itemBlock = AceGUI:Create("InlineGroup")
   itemBlock:SetFullWidth(true)
   itemBlock:SetLayout("Flow")

   local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(item)
   local itemIcon = AceGUI:Create("Icon")
   itemIcon:SetWidth(44) 
   itemIcon:SetImage(itemTexture)
   itemIcon:SetImageSize(36,36)
   itemIcon:SetCallback("OnEnter", function(widget)
      GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
      GameTooltip:SetHyperlink(itemLink)
      GameTooltip:Show()
   end)
   itemIcon:SetCallback("OnLeave", function(widget)
      GameTooltip:Hide()
   end)
   itemBlock:AddChild(itemIcon)

   local textGroup = AceGUI:Create("SimpleGroup")
   textGroup:SetLayout("List")
   textGroup:SetRelativeWidth(.6)
   itemBlock:AddChild(textGroup)

   local itemText = AceGUI:Create("InteractiveLabel")
   itemText:SetText(itemLink)
   itemText:SetRelativeWidth(1)
   textGroup:AddChild(itemText)

   if loot.prio ~= nil then
      local itemPrio = AceGUI:Create("Label")
      itemPrio:SetText("Prio: "..loot.prio)
      itemPrio:SetRelativeWidth(1)
      textGroup:AddChild(itemPrio)
   end

   if loot.rollingState == "rolling" then
      itemBlock:AddChild(MSOS:createButtonGroup(loot, index))

      local rollBlock = AceGUI:Create("InlineGroup")
      rollBlock:SetFullWidth(true)
      rollBlock:SetTitle("Rolling "..MSOS.db.profile.rollingStepText[loot.rollingStep])
      itemBlock:AddChild(rollBlock)

      local scrollcontainer = AceGUI:Create("ScrollFrame")
         scrollcontainer:SetFullWidth(true)
         scrollcontainer:SetHeight(125)
         scrollcontainer:SetLayout("List") -- probably?
         rollBlock:AddChild(scrollcontainer)

      local headers = {
         position = {
            value = "#"
         },
         roll = {
            value = "Roll"
         },
         name = {
            value = "Name"
         },
         ms = {
            value = "MS"
         },
         os = {
            value = "OS"
         },
         special = {
            value = "SP"
         },
         count = {
            value = "Count"
         }
      }
      scrollcontainer:AddChild(MSOS:createRollsLine(headers, index, 0))
      for i = 1, #loot.rolls do
         scrollcontainer:AddChild(MSOS:createRollsLine(loot.rolls[i], index, i))
      end

      local cancelRoll = AceGUI:Create("Button")
      cancelRoll:SetText("Cancel Roll")
      cancelRoll:ClearAllPoints()
      cancelRoll:SetPoint("TOPRIGHT")
      cancelRoll:SetWidth(100)
      cancelRoll:SetHeight(20)
      if not loot.rollButtonStatus.cancel then
         cancelRoll:SetDisabled(true)
      end
      cancelRoll:SetCallback("OnClick", function() MSOS:CancelRoll(self.db.profile.loot[index].rollingStep, index) end)
      itemBlock:AddChild(cancelRoll)
   elseif loot.rollingState == "finished" then
      local lootAwared = AceGUI:Create("Label")
      lootAwared:SetText("Won by "..loot.awardedTo.name.." with a roll of "..loot.awardedTo.roll)
      lootAwared:SetRelativeWidth(1)
      lootAwared:SetPoint("CENTER")
      itemBlock:AddChild(lootAwared)

      local expandHistory = AceGUI:Create("Button")
      expandHistory:SetText("-")
      expandHistory:ClearAllPoints()
      expandHistory:SetPoint("TOPRIGHT")
      expandHistory:SetWidth(15)
      expandHistory:SetHeight(15)
      itemBlock:AddChild(expandHistory)

      local rollBlock = AceGUI:Create("InlineGroup")
      rollBlock:SetFullWidth(true)
      itemBlock:AddChild(rollBlock)

      local scrollcontainer = AceGUI:Create("ScrollFrame")
         scrollcontainer:SetFullWidth(true)
         scrollcontainer:SetHeight(75)
         scrollcontainer:SetLayout("List") -- probably?
         rollBlock:AddChild(scrollcontainer)

      local headers = {
         position = {
            value = "#"
         },
         roll = {
            value = "Roll"
         },
         name = {
            value = "Name"
         },
         ms = {
            value = "MS"
         },
         os = {
            value = "OS"
         },
         special = {
            value = "SP"
         },
         count = {
            value = "Count"
         }
      }
      scrollcontainer:AddChild(MSOS:createRollsLine(headers, index, 0))
      for i = 1, #loot.rolls do
         scrollcontainer:AddChild(MSOS:createRollsLine(loot.rolls[i], index, i))
      end
   else
      itemBlock:AddChild(MSOS:createButtonGroup(loot, index))
   end
   return itemBlock
end

function MSOS:createRollsLine(roll, index, i)
   local rollLine = AceGUI:Create("SimpleGroup")
   rollLine:SetFullWidth(true)
   rollLine:SetLayout("Flow")

   local rollPostion = AceGUI:Create("Label")
   rollPostion:SetText(i)
   if roll.position.color then
      rollPostion:SetColor(roll.position.color.r, roll.position.color.g, roll.position.color.b)
   end
   rollPostion:SetRelativeWidth(.1)
   rollPostion:SetPoint("CENTER")
   rollLine:AddChild(rollPostion)

   local rollNumer = AceGUI:Create("Label")
   rollNumer:SetText(roll.roll.value)
   if roll.roll.color then
      rollNumer:SetColor(roll.roll.color.r, roll.roll.color.g, roll.roll.color.b)
   end
   rollNumer:SetRelativeWidth(.1)
   rollLine:AddChild(rollNumer)

   local rollName = AceGUI:Create("Label")
   rollName:SetText(roll.name.value)
   if roll.name.color then
      rollName:SetColor(GetClassColor(roll.name.color))
   end
   rollName:SetRelativeWidth(.2)
   rollLine:AddChild(rollName)

   local rollMSCount = AceGUI:Create("Label")
   rollMSCount:SetText(roll.ms.value)
   if roll.ms.color then
      rollMSCount:SetColor(roll.ms.color.r, roll.ms.color.g, roll.ms.color.b)
   end
   rollMSCount:SetRelativeWidth(.1)
   rollLine:AddChild(rollMSCount)

   local rollOSCount = AceGUI:Create("Label")
   rollOSCount:SetText(roll.os.value)
   if roll.os.color then
      rollOSCount:SetColor(roll.os.color.r, roll.os.color.g, roll.os.color.b)
   end
   rollOSCount:SetRelativeWidth(.1)
   rollLine:AddChild(rollOSCount)

   local rollSPCount = AceGUI:Create("Label")
   rollSPCount:SetText(roll.special.value)
   if roll.os.color then
      rollSPCount:SetColor(roll.os.color.r, roll.os.color.g, roll.os.color.b)
   end
   rollSPCount:SetRelativeWidth(.1)
   rollLine:AddChild(rollSPCount)

   local rollAttempts = AceGUI:Create("Label")
   rollAttempts:SetText(roll.count.value)
   if roll.count.color then
      rollAttempts:SetColor(roll.count.color.r, roll.count.color.g, roll.count.color.b)
   end
   rollAttempts:SetRelativeWidth(.1)
   rollLine:AddChild(rollAttempts)

   if roll.awardable then
      local rollLootAward = AceGUI:Create("Button")
      rollLootAward:SetText("Award")
      rollLootAward:SetRelativeWidth(.15)
      rollLootAward:SetHeight(20)
      rollLootAward:SetCallback("OnClick", function() print("AWARD ACTION FOR INDEX: ", index, "i: ", i) end)
      rollLine:AddChild(rollLootAward)
   else
      local placeholder = AceGUI:Create("SimpleGroup")
      placeholder:SetRelativeWidth(.15)
      placeholder:SetHeight(20)
      rollLine:AddChild(placeholder)
   end
   return rollLine
end

function render(frame, loot)
   frame:ReleaseChildren()
   for k, v in pairs(loot) do
      frame:AddChild(MSOS:createItemBlock(v, k))
   end
   frame:SetWidth(650)
end