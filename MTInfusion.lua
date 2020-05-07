
local castSpellName = "Power Infusion" -- "Power Word: Shield"
local cdSpellName =  "Power Infusion"

-- local frame = CreateFrame("Frame")

local playerbuttons = {}

local function buildFrame()
	local frame = CreateFrame("Frame", "DragFrame2", UIParent)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseDown", function(self, button)
	  if button == "LeftButton" and not self.isMoving then
	   self:StartMoving();
	   self.isMoving = true;
	  end
	end)
	frame:SetScript("OnMouseUp", function(self, button)
	  if button == "LeftButton" and self.isMoving then
	   self:StopMovingOrSizing();
	   self.isMoving = false;
	  end
	end)
	frame:SetScript("OnHide", function(self)
	  if ( self.isMoving ) then
	   self:StopMovingOrSizing();
	   self.isMoving = false;
	  end
	end)
	-- The code below makes the frame visible, and is not necessary to enable dragging.
	frame:SetPoint("CENTER"); frame:SetWidth(64); frame:SetHeight(64);
	local tex = frame:CreateTexture("ARTWORK");
	tex:SetAllPoints();
	tex:SetTexture(1.0, 0.5, 0); tex:SetAlpha(0.5);

	return frame
end 

local frame = buildFrame()

local myButton = CreateFrame("CheckButton", "myFirstButton", frame, 'SecureUnitButtonTemplate')
myButton:SetSize(50,50)
myButton:SetPoint("CENTER",0,0)
myButton:SetText(player)
myButton:SetAlpha(1.0);

myButton:SetNormalFontObject("GameFontNormalSmall");
myButton:SetHighlightFontObject("GameFontHighlightSmall");
myButton:SetDisabledFontObject("GameFontDisableSmall");

myButton:SetAttribute("*type1", "macro") -- Target unit on left click

myButton.text = myButton:CreateFontString(nil, "OVERLAY")
myButton.text:SetPoint("CENTER")
myButton.text:SetFont(STANDARD_TEXT_FONT, 16, "THINOUTLINE")
myButton.text:SetText("NONE")

local function huFilter(player)
	local removestring = "-"..GetRealmName()
	if player:find(removestring) then
		return string.gsub(player, removestring, "")
	else 
		return player
	end
end

local function getPICooldown() 
	start, duration, enabled, modRate = GetSpellCooldown(cdSpellName)
	--start, duration, enabled, modRate = GetSpellCooldown("Power Infusion")

	if ( start > 0 and duration > 0) then
		local cdLeft = start + duration - GetTime()
		return math.ceil(cdLeft)
	else
		return 0
	end
end

local function castPi(playerName)
	print("casting pi")
	CastSpellByName(castSpellName);
end 

local function whisperPlayer(player, msg) 
	SendChatMessage(msg , "WHISPER", nil, player);
end

local function containsPITrigger(msg)
	
	for word in msg:gmatch("%w+") do
		if string.lower(word) == "pi" then
			return true
		end
	end
	return false
end

local function addButton(player) 
	local myButton = CreateFrame("CheckButton", "myFirstButton", frame, 'SecureUnitButtonTemplate')
	myButton:SetSize(64,64)
	myButton:SetPoint("CENTER",0,0)
	myButton:SetText(player)
	myButton:SetAlpha(1.0);

	myButton:SetNormalFontObject("GameFontNormalSmall");
	myButton:SetHighlightFontObject("GameFontHighlightSmall");
	myButton:SetDisabledFontObject("GameFontDisableSmall");
	
	myButton:SetAttribute("*type1", "macro") -- Target unit on left click
	myButton:SetAttribute("macrotext", "/target "..huFilter(player).."\n/use ".. castSpellName.."\n")

	myButton.text = myButton:CreateFontString(nil, "OVERLAY")
	myButton.text:SetPoint("CENTER")
	myButton.text:SetFont(STANDARD_TEXT_FONT, 16, "THINOUTLINE")
	myButton.text:SetText(huFilter(player))

end

local function getPlayerButton(playerName) 
	return nil
end 

local function addPlayerButton(playerName)
	print ("here")
	local existingButton = getPlayerButton(playerName)
	myButton:SetAttribute("macrotext", "/target "..huFilter(player).."\n/use ".. castSpellName.."\n")
	--if existingButton == nil then
		--addButton(playerName)
		--myButton:SetAttribute("macrotext", "/target "..huFilter(player).."\n/use ".. castSpellName.."\n")
		--print("addPlayerButton: button for" .. playerName)
	--else
		--print("addPlayerButton: button already exists for" .. playerName)
	--end

end

local function removePlayerButton(playerName)

	local existingButton = getPlayerButton(playerName)

	if existingButton ~= nil then
		print("removePlayerButton: button for" .. playerName)
	else
		print("removePlayerButton: button doesnt exist for" .. playerName)
	end

end 

local function myEventHandler(self, event, ...)
	if event == "CHAT_MSG_WHISPER" then
		local msg, sender = ...
		
		if containsPITrigger(msg) then

			--addButton(sender)
			--addPlayerButton(sender)
			local cdLeft = getPICooldown()
			if cdLeft == 0 then
				whisperPlayer(sender, "Power Infusion is ready")
			else 
				whisperPlayer(sender, "Power Infusion is on cooldown, wait " .. cdLeft .. " seconds for the next one")
			end
		end
	end
end

frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", myEventHandler)