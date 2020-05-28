
local castSpellName = "Power Infusion" --  "Power Infusion"  -- "Power Infusion" -- "Power Word: Shield"
local cdSpellName =  "Power Infusion"

local prioPlayerName = "Taddymayson"
local prioPlayerStatus = false

local lastPlayerName = nil
local lastPlayerStatus = false

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

local function buildButton(frame, x, y)

	local button = CreateFrame("CheckButton", "myFirstButton", frame, 'SecureUnitButtonTemplate')
	button:SetSize(80,50)
	button:SetPoint("CENTER",x,y)
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

local prioButton = buildButton(frame, 0, 0)
local lastButton = buildButton(frame, 0, -60)

local prioButtonTex = prioButton:CreateTexture("ARTWORK");
prioButtonTex:SetAllPoints();
prioButtonTex:SetColorTexture(1.0, 0.5, 0); 
prioButtonTex:SetAlpha(0.5);

local lastButtonTex = lastButton:CreateTexture("ARTWORK");
lastButtonTex:SetAllPoints();
lastButtonTex:SetColorTexture(1.0, 0.5, 0); 
lastButtonTex:SetAlpha(0.5);

local function isPlayerOnline(playerName)

	if playerName ~= nil then
		return UnitExists(playerName)
	end

	return false 
end

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
	if msg ~= nil then
		SendChatMessage(msg , "WHISPER", nil, player);
	end
end

local function containsPITrigger(msg)
	
	for word in msg:gmatch("%w+") do
		if string.lower(word) == "pi" then
			return true
		end
	end
	return false
end

local function updateButton(cdLeft, playerName, playerStatus, button, buttonTex)

	if isPlayerOnline(playerName) then 
		
		alpha = .5
		buttonText = playerName

		if cdLeft == 0 then

			macrotext = "/target "..playerName.."\n/use ".. castSpellName.."\n".."/w "..playerName.." Power Infusion casted. Light then up!"

			if playerStatus then
				-- Green 
				buttonTex:SetColorTexture(0.0, 1.0, 0.0);
			else 
				-- Yellow
				buttonTex:SetColorTexture(1.0, 1.0, 0.0); 
			end 
		else

			buttonText = buttonText.."\n"..cdLeft.." sec"
			macrotext = ""

			-- Red 
			buttonTex:SetColorTexture(1.0, 0.0, 0.0); 
		end 
	else 
		
		alpha = 0
		buttonText = nil
		macrotext = ""
	end

	button.text:SetText(buttonText)
	button:SetAttribute("macrotext",macrotext)

	buttonTex:SetAlpha(alpha)
end

local function updateLastButton(cdLeft)
	updateButton(cdLeft, lastPlayerName, lastPlayerStatus, lastButton, lastButtonTex)
end

local function updatePrioButton(cdLeft)
	updateButton(cdLeft, prioPlayerName, prioPlayerStatus, prioButton, prioButtonTex)
end

local function myEventHandler(self, event, ...)
	if event == "CHAT_MSG_WHISPER" then
		local msg, sender = ...

		if containsPITrigger(msg) and self.cdLeft >=0 then
			
			PlaySoundFile("Sound\\Spells\\PVPFlagTaken.ogg") 

			local playerName = huFilter(sender)

			local responseMessage = nil

			if prioPlayerName == playerName then 
				prioPlayerStatus = true
				updatePrioButton(self.cdLeft)
			else
				lastPlayerName = playerName
				lastPlayerStatus = true
				updateLastButton(self.cdLeft)
			end

			if self.cdLeft == 0 then
				if isPlayerOnline(prioPlayerName) and prioPlayerName ~= playerName then
					responseMessage = "Power Infusion is ready"
				else 
					responseMessage = nil -- "Power Infusion is ready"
				end 
			else 
				responseMessage = "Power Infusion is on cooldown, wait " .. self.cdLeft .. " seconds for the next one"
			end	

			if responseMessage ~= nil and isPlayerOnline(prioPlayerName) and prioPlayerName ~= playerName then
				responseMessage = responseMessage .. " (Note: you are not marked as the primary receiver)"
			end 

			whisperPlayer(sender, responseMessage)
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

		if (self.cdLeft > lastCdLeft) then
			prioPlayerStatus = false
			lastPlayerStatus = false
		end 

		updatePrioButton(self.cdLeft)
		updateLastButton(self.cdLeft)

		if self.cdLeft == 0 and lastCdLeft ~= nil and lastCdLeft ~= 0 then
			if isPlayerOnline(prioPlayerName) then 
				whisperPlayer(prioPlayerName, "Power Infusion is ready")
			elseif isPlayerOnline(lastPlayerName) then 
				whisperPlayer(lastPlayerName, "Power Infusion is ready")
			end 
		end

		self.sinceLastUpdate = 0;
	end
end