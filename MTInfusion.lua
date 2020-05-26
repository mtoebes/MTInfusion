
local castSpellName ="Power Infusion"  -- "Power Infusion" -- "Power Word: Shield"
local cdSpellName ="Power Infusion"

local prioPlayerName = "Rortek"
local shortPlayerName = prioPlayerName

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
	frame:SetPoint("CENTER"); frame:SetWidth(100); frame:SetHeight(64);

	return frame
end 

local function buildPlayerButton(frame)

	local button = CreateFrame("CheckButton", "myFirstButton", frame, 'SecureUnitButtonTemplate')
	button:SetSize(80,50)
	button:SetPoint("CENTER",0,0)
	button:SetText(player)
	button:SetAlpha(1.0);
	
	button:SetNormalFontObject("GameFontNormalSmall");
	button:SetHighlightFontObject("GameFontHighlightSmall");
	button:SetDisabledFontObject("GameFontDisableSmall");
	
	button:SetAttribute("*type1", "macro") -- Target unit on left click
	
	button.text = button:CreateFontString(nil, "OVERLAY")
	button.text:SetPoint("CENTER")
	button.text:SetFont(STANDARD_TEXT_FONT, 16, "THINOUTLINE")
	button.text:SetText("NONE")
	
	return button;
end 

local frame = buildFrame()

local tex = frame:CreateTexture("ARTWORK");
tex:SetAllPoints();
tex:SetColorTexture(1.0, 0.5, 0); tex:SetAlpha(0.5);

local playerButton = buildPlayerButton(frame)

local function huFilter(player)

	if player == nil then
		return nil
	end 

	local removestring = "-"..GetRealmName()
	if player:find(removestring) then
		return string.gsub(player, removestring, "")
	else 
		return player
	end
end

local function getPICooldown() 
	start, duration, enabled, modRate = GetSpellCooldown(cdSpellName)

	if (start == nil or duration == nil) then
		return -1
	end 

	if ( start > 0 and duration > 0) then
		local cdLeft = start + duration - GetTime()
		return math.ceil(cdLeft)
	else
		return 0
	end
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

local function updatePlayerButton(time, playerName)

	shortPlayerName = huFilter(playerName)

	if playerName then

		if time == 0 then
			tex:SetColorTexture(0.0, 1.0, 0.0);
			buttonText = shortPlayerName
			macrotext = "/target "..shortPlayerName.."\n/use ".. castSpellName.."\n".."/w "..shortPlayerName.." Power Infusion casted. Light then up!"
		else 
			tex:SetColorTexture(1.0, 0.0, 0.0); 
			buttonText = shortPlayerName.."\n"..time.." sec"
			macrotext = ""
		end 

	else
		tex:SetColorTexture(1.0, 1.0, 0.0); 
		buttonText = time.." seconds"
		macrotext = ""
	end

	playerButton.text:SetText(buttonText)
	playerButton:SetAttribute("macrotext",macrotext)

end

local function isPlayerOnline(playerName)

	if playerName == nil then
		return false
	else
		return UnitExists(playerName)
	end
end

local function isPrioOnline()
	return isPlayerOnline(prioPlayerName)
end

local function myEventHandler(self, event, ...)
	if event == "CHAT_MSG_WHISPER" then
		local msg, sender = ...

		if containsPITrigger(msg) and self.cdLeft >=0 then
			
			if isPrioOnline()==false or prioPlayerName == huFilter(sender) then

				shortPlayerName = huFilter(sender)

				updatePlayerButton(self.cdLeft, shortPlayerName)

				if self.cdLeft == 0 then
					whisperPlayer(sender, "Power Infusion is ready")
				else 
					whisperPlayer(sender, "Power Infusion is on cooldown, wait " .. self.cdLeft .. " seconds for the next one")
				end		
			else
				if self.cdLeft == 0 then
					whisperPlayer(sender, "Power Infusion is ready (Note: you are not marked as the primary receiver)")
				else
					whisperPlayer(sender, "Power Infusion is on cooldown, wait " .. self.cdLeft .. " seconds for the next one (Note: you are not marked as the primary receiver)")
				end
			end 
		end
	end
end

frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", myEventHandler)

frame:SetScript("OnUpdate", function(self, sinceLastUpdate) frame:onUpdate(sinceLastUpdate); end);

function frame:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;

	interval = 5

	if (self.cdLeft ~= nil and self.cdLeft < 15) then
		interval = 1
	end

	if (self.cdLeft == nil) then
		self.cdLeft = getPICooldown()
	end 

	if ( self.sinceLastUpdate >= interval ) then 

		local lastCdLeft = self.cdLeft

		self.cdLeft = getPICooldown()

		updatePlayerButton(self.cdLeft, shortPlayerName)

		if self.cdLeft == 0 and lastCdLeft ~= nil and lastCdLeft ~= 0 then
			if isPrioOnline() then 
				whisperPlayer(prioPlayerName, "Power Infusion is ready")
			end 
		end

		self.sinceLastUpdate = 0;
	end
end