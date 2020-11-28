local rc = LibStub("LibRangeCheck-2.0")

local castSpellName = "Power Infusion" --  "Power Infusion"  -- "Power Infusion" -- "Power Word: Shield"
local cdSpellName = "Power Infusion"
local cdSpellSeconds = 120

local prioPlayerName = nil
local lastPlayerName = nil

local targetList = {} 

local function isPlayerOnline(playerName)

	if playerName ~= nil then
		return true -- UnitExists(playerName)
	end

	return false 
end

local function getTarget(playerName)
	for i, target in ipairs(targetList) do
		if target.playerName == playerName then
			return target, i
		end
	end 

	return nil, -1
end 

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

local function buildPlayerButton(frame, target)

	target.isPendingSetup=false

	local playerName = target.playerName
	
	local button = CreateFrame("CheckButton", "playerButton"..target.playerName, frame, 'SecureUnitButtonTemplate')
	button:SetSize(80,50)
	button:SetPoint("CENTER",0,-60 * target.index)
	button:SetAlpha(1.0);
	
	button:SetNormalFontObject("GameFontNormalSmall");
	button:SetHighlightFontObject("GameFontHighlightSmall");
	button:SetDisabledFontObject("GameFontDisableSmall");
	
	button:SetAttribute("*type1", "macro") -- Target unit on left click
	
	button.text = button:CreateFontString(nil, "OVERLAY")
	button.text:SetPoint("CENTER")
	button.text:SetFont(STANDARD_TEXT_FONT, 16, "THINOUTLINE")
	button.text:SetText(target.playerName)
	
	target.macrotext = "/target "..target.playerName.."\n/use ".. castSpellName.."\n".."/w "..target.playerName.." Power Infusion casted. Light them up!"

	button:SetAttribute("macrotext",target.macrotext)
	target.button = button

	target.buttonTex = target.button:CreateTexture("ARTWORK");
	target.buttonTex:SetAllPoints();
	target.buttonTex:SetColorTexture(1.0, 0.5, 0); 
	target.buttonTex:SetAlpha(0.5);


	local button2 = CreateFrame("CheckButton", "playerButton"..target.playerName, frame, 'SecureUnitButtonTemplate')
	button2:SetSize(20,20)
	button2:SetPoint("CENTER",60,-60 * target.index)
	button2:SetAlpha(1.0);
	
	button2:SetNormalFontObject("GameFontNormalSmall");
	button2:SetHighlightFontObject("GameFontHighlightSmall");
	button2:SetDisabledFontObject("GameFontDisableSmall");
	
	button2:SetAttribute("*type1", "macro") -- Target unit on left click
	
	button2.text = button2:CreateFontString(nil, "OVERLAY")
	button2.text:SetPoint("CENTER")
	button2.text:SetFont(STANDARD_TEXT_FONT, 16, "THINOUTLINE")
	button2.text:SetText("LOS")
	
	target.macrotext2 = "/target "..target.playerName.."\n".."/w "..target.playerName.." Cannot cast PI right now due to Range/LoS/Dont give a shit about your parses"
	button2:SetAttribute("macrotext",target.macrotext2)
	target.button2 = button2

	target.buttonTex2 = target.button2:CreateTexture("ARTWORK");
	target.buttonTex2:SetAllPoints();
	target.buttonTex2:SetColorTexture(1.0, 0.5, 0); 
	target.buttonTex2:SetAlpha(0.5);

	return button
end 

local frame = buildFrame()

local function addTarget(playerName)

	if playerName == nil then
		return
	end 

	local existingTarget, index = getTarget(playerName) 

	if existingTarget ~= nil then
		return existingTarget
	end 

	local target = {}
	target.playerName = playerName
	target.index = getn(targetList)
	target.requested = false

	target.isPendingSetup = InCombatLockdown()

	target.macrotext = "/target "..playerName.."\n/use ".. castSpellName.."\n".."/w "..playerName.." Power Infusion casted. Light then up!"

	table.insert(targetList, target)

	if target.isPendingSetup==false then 
		buildPlayerButton(frame, target)
	end 

	return target

end

local function removeTarget(playerName)

	local existingTarget, index = getTarget(playerName) 
	if existingTarget == nil then
		return
	end

	existingTarget.button:Hide();
	existingTarget.button2:Hide();

	table.remove(targetList, index)

	for i, target in ipairs(targetList) do

		if target.index >= index then
			target.index = target.index-1
			target.button:SetPoint("CENTER",0,-60 * target.index)
			target.button2:SetPoint("CENTER",60,-60 * target.index)
		end
	end 


end 

local function updateTarget(cdLeft, target)
	
	local playerName = target.playerName
	local button = target.button
	local buttonTex = target.buttonTex
	local playerStatus = target.requested

	if button == nil then
		return
	end 

	
	local minRange, maxRange = rc:GetRange(playerName, false)

	alpha = .5
	buttonText = playerName

	if not minRange or minRange >= 40 then
	
		buttonTex:SetColorTexture(0.8, 0.4, 0.0);

	elseif cdLeft == 0 then

		buttonText =  buttonText.. " (" .. minRange .. ")"

		if playerStatus then
			-- Green 
			buttonTex:SetColorTexture(0.0, 1.0, 0.0);
		else 
			-- Yellow
			buttonTex:SetColorTexture(1.0, 1.0, 0.0); 
		end 
	else

		buttonText = buttonText.."\n"..cdLeft.." sec"

		-- Red 
		buttonTex:SetColorTexture(1.0, 0.0, 0.0); 
	end 

	button.text:SetText(buttonText)
	buttonTex:SetAlpha(alpha)

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

local function myEventHandler(self, event, ...)
	if event == "CHAT_MSG_WHISPER" then
		local msg, sender = ...
		self.cdLeft = getPICooldown()

		if containsPITrigger(msg) and self.cdLeft >=0 then
			
			if isPlayerOnline(sender)==false then
				return
			end 

			PlaySoundFile("Sound\\Spells\\PVPFlagTaken.ogg") 

			local playerExists = getTarget(sender) ~= nil

			local playerName = huFilter(sender)

			local responseMessage = nil

			lastPlayerName = playerName

			local target = addTarget(playerName)
			target.requested = true

			if self.cdLeft == 0 then
				if isPlayerOnline(prioPlayerName) and prioPlayerName ~= playerName then
					responseMessage = nil -- "Power Infusion is ready"
				else 
					responseMessage = nil -- "Power Infusion is ready"
				end 
			else 
				responseMessage = "Power Infusion is on cooldown, wait " .. self.cdLeft .. " seconds for the next one"
			end	

			if responseMessage ~= nil and isPlayerOnline(prioPlayerName) and prioPlayerName ~= playerName then
				responseMessage = responseMessage .. " (Note: you are not marked as the primary receiver)"
			end 

			updateTarget(self.cdLeft, target)
			whisperPlayer(sender, responseMessage)
		end
	end
end

frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", myEventHandler)
frame:SetScript("OnUpdate", function(self, sinceLastUpdate) frame:onUpdate(sinceLastUpdate); end);

function frame:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;

	interval = 1

	if (self.cdLeft == nil) then
		self.cdLeft = getPICooldown()
		self.lastCdLeft = self.cdLeft
		self.onCd = false
	end 

	if (self.cdLeft < 15) then
		interval = 1
	end

	if ( self.sinceLastUpdate >= interval) then 
		
		local combatLockdown = InCombatLockdown()

		self.lastCdLeft = self.cdLeft

		self.cdLeft = getPICooldown()

		if self.onCd then
			if self.cdLeft == 0 then
				self.onCd = false
				
				if isPlayerOnline(lastPlayerName) then 
					whisperPlayer(lastPlayerName, "Power Infusion is ready")
				end 
			end
		else 
			self.onCd = false
			if self.cdLeft > 120 then
				self.onCd = true

				for i, target in ipairs(targetList) do
					target.requested = false
				end
			end
		end
	
		if combatLockdown == false then
			for i, target in ipairs(targetList) do
				if target.isPendingSetup then
					buildPlayerButton(frame, target)
				end
			end 
		end 

		for i, target in ipairs(targetList) do
			updateTarget(self.cdLeft, target)
		end

		self.sinceLastUpdate = 0;
	end
end

local function MyAddonCommands(msg, editbox)

	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if cmd == "add" and args ~= "" then
		-- Handle adding of the contents of rest... to something.
		local target = addTarget(args)	
	elseif cmd == "remove" and args ~= "" then
		removeTarget(args)  
	else
		-- If not handled above, display some sort of help message
		print("Syntax: /mtpi (add|remove) someIdentifier");
	end

  end
  
  SLASH_HELLOWORLD1 = '/mtpi'
  
  SlashCmdList["HELLOWORLD"] = MyAddonCommands   -- add /hiw and /hellow to command list