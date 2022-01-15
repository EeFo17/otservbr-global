CONTAINER_WEIGHT_CHECK = true -- true = enable / false = disable
CONTAINER_WEIGHT_MAX = 1000000 -- 1000000 = 10k = 10000.00 oz

local storeItemID = {
	-- registered item ids here are not tradable with players
	-- these items can be set to moveable at items.xml
	-- 500 charges exercise weapons
	32384, -- exercise sword
	32385, -- exercise axe
	32386, -- exercise club
	32387, -- exercise bow
	32388, -- exercise rod
	32389, -- exercise wand

	-- 50 charges exercise weapons
	32124, -- training sword
	32125, -- training axe
	32126, -- training club
	32127, -- training bow
	32128, -- training wand
	32129, -- training club

	-- magic gold and magic converter (activated/deactivated)
	32109, -- magic gold converter
	33299, -- magic gold converter
	26378, -- gold converter
	29020, -- gold converter

	-- foods
	35172, -- roasted wyvern wings
	35173, -- carrot pie
	35174, -- tropical marinated tiger
	35175, -- delicatessen salad
	35176, -- chilli con carniphila
	35177, -- svargrond salmon filet
	35178, -- carrion casserole
	35179, -- consecrated beef
	35180, -- overcooked noodles
}

-- Players cannot throw items on teleports if set to true
local blockTeleportTrashing = true

local titles = {
	{storageID = 14960, title = " Scout"},
	{storageID = 14961, title = " Sentinel"},
	{storageID = 14962, title = " Steward"},
	{storageID = 14963, title = " Warden"},
	{storageID = 14964, title = " Squire"},
	{storageID = 14965, title = " Warrior"},
	{storageID = 14966, title = " Keeper"},
	{storageID = 14967, title = " Guardian"},
	{storageID = 14968, title = " Sage"},
	{storageID = 14969, title = " Tutor"},
	{storageID = 14970, title = " Senior Tutor"},
	{storageID = 14971, title = " King"},
}

local function getTitle(uid)
	local player = Player(uid)
	if not player then return false end

	for i = #titles, 1, -1 do
		if player:getStorageValue(titles[i].storageID) == 1 then
			return titles[i].title
		end
	end

	return false
end

function Player:onBrowseField(position)
	if hasEventCallback(EVENT_CALLBACK_ONBROWSEFIELD) then
		return EventCallback(EVENT_CALLBACK_ONBROWSEFIELD, self, position)
	else
		return true
	end
end

local function getHours(seconds)
	return math.floor((seconds/60)/60)
end

local function getMinutes(seconds)
	return math.floor(seconds/60)
end

local function getSeconds(seconds)
	return seconds%60
end

local function getTime(seconds)
	local hours, minutes = getHours(seconds), getMinutes(seconds)
	if (minutes > 59) then
		minutes = minutes-hours*60
	end

	if (minutes < 10) then
		minutes = "0" ..minutes
	end

	return hours..":"..minutes.. "h"
end

local function getTimeinWords(secs)
	local hours, minutes, seconds = getHours(secs), getMinutes(secs), getSeconds(secs)
	if (minutes > 59) then
		minutes = minutes-hours*60
	end

	local timeStr = ''

	if hours > 0 then
		timeStr = timeStr .. ' hours '
	end

	timeStr = timeStr .. minutes .. ' minutes and '.. seconds .. ' seconds.'

	return timeStr
end

function Player:onLook(thing, position, distance)
	local ret = EventCallback(EVENT_CALLBACK_ONLOOK, self, thing, position, distance)
	self:sendTextMessage(MESSAGE_INFO_DESCR, ret)
end

function Player:onLookInBattleList(creature, distance)
	local ret = EventCallback(EVENT_CALLBACK_ONLOOKINBATTLELIST, self, creature, distance)
	self:sendTextMessage(MESSAGE_INFO_DESCR, ret)
end

function Player:onLookInTrade(partner, item, distance)
	local description = "You see " .. item:getDescription(distance)
	local ret = hasEventCallback(EVENT_CALLBACK_ONLOOKINTRADE) and EventCallback(EVENT_CALLBACK_ONLOOKINTRADE, self, partner, item, distance, description) or description
	self:sendTextMessage(MESSAGE_INFO_DESCR, ret)
end

function Player:onLookInShop(itemType, count, description)
	local description = "You see " .. description
	local ret = hasEventCallback(EVENT_CALLBACK_ONLOOKINSHOP) and EventCallback(EVENT_CALLBACK_ONLOOKINSHOP, self, itemType, count, description) or description
	self:sendTextMessage(MESSAGE_INFO_DESCR, ret)
end

local config = {
	maxItemsPerSeconds = 1,
	exhaustTime = 2000,
}

if not pushDelay then
	pushDelay = { }
end

local function antiPush(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if toPosition.x == CONTAINER_POSITION then
		return true
	end

	local tile = Tile(toPosition)
	if not tile then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		return false
	end

	local cid = self:getId()
	if not pushDelay[cid] then
		pushDelay[cid] = {items = 0, time = 0}
	end

	pushDelay[cid].items = pushDelay[cid].items + 1

	local currentTime = os.mtime()
	if pushDelay[cid].time == 0 then
		pushDelay[cid].time = currentTime
	elseif pushDelay[cid].time == currentTime then
		pushDelay[cid].items = pushDelay[cid].items + 1
	elseif currentTime > pushDelay[cid].time then
		pushDelay[cid].time = 0
		pushDelay[cid].items = 0
	end

	if pushDelay[cid].items > config.maxItemsPerSeconds then
		pushDelay[cid].time = currentTime + config.exhaustTime
	end

	if pushDelay[cid].time > currentTime then
		self:sendCancelMessage("You can't move that item so fast.")
		return false
	end

	return true
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if hasEventCallback(EVENT_CALLBACK_ONMOVEITEM) then
		return EventCallback(EVENT_CALLBACK_ONMOVEITEM, self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	else
	return true
	end
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if hasEventCallback(EVENT_CALLBACK_ONITEMMOVED) then
		EventCallback(EVENT_CALLBACK_ONITEMMOVED, self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	if hasEventCallback(EVENT_CALLBACK_ONMOVECREATURE) then
		return EventCallback(EVENT_CALLBACK_ONMOVECREATURE, self, creature, fromPosition, toPosition)
	else
		return true
	end
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	if hasEventCallback(EVENT_CALLBACK_ONREPORTRULEVIOLATION) then
		EventCallback(EVENT_CALLBACK_ONREPORTRULEVIOLATION, self, targetName, reportType, reportReason, comment, translation)
	end
end

function Player:onReportBug(message, position, category)
	if hasEventCallback(EVENT_CALLBACK_ONREPORTBUG) then
		return EventCallback(EVENT_CALLBACK_ONREPORTBUG, self, message, position, category)
	else
		return true
	end
end

function Player:onTurn(direction)
	if hasEventCallback(EVENT_CALLBACK_ONTURN) then
		return EventCallback(EVENT_CALLBACK_ONTURN, self, direction)
	else
		return true
	end
end

function Player:onTradeRequest(target, item)
	if hasEventCallback(EVENT_CALLBACK_ONTRADEREQUEST) then
		return EventCallback(EVENT_CALLBACK_ONTRADEREQUEST, self, target, item)
	else
		return true
	end
end

function Player:onTradeAccept(target, item, targetItem)
	self:closeImbuementWindow()
	target:closeImbuementWindow()
		if hasEventCallback(EVENT_CALLBACK_ONTRADEACCEPT) then
		return EventCallback(EVENT_CALLBACK_ONTRADEACCEPT, self, target, item, targetItem)
	else
		return true
	end
end

local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	if hasEventCallback(EVENT_CALLBACK_ONTRADECOMPLETED) then
		EventCallback(EVENT_CALLBACK_ONTRADECOMPLETED, self, target, item, targetItem, isSuccess)
	end
end

local function useStamina(player)
	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	local currentTime = os.time()
	local timePassed = currentTime - nextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseStaminaTime[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseStaminaTime[playerId] = currentTime + 60
	end
	player:setStamina(staminaMinutes)
end

local function useStaminaXp(player)
	local staminaMinutes = player:getExpBoostStamina() / 60
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	local currentTime = os.time()
	local timePassed = currentTime - nextUseXpStamina[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseXpStamina[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseXpStamina[playerId] = currentTime + 60
	end
	player:setExpBoostStamina(staminaMinutes * 60)
end

function Player:onGainExperience(source, exp, rawExp)
	if not source or source:isPlayer() then
		return exp
	end

	-- Soul regeneration
	local vocation = self:getVocation()
	if self:getSoul() < vocation:getMaxSoul() and exp >= self:getLevel() then
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks())
		self:addCondition(soulCondition)
	end

	-- Experience Stage Multiplier
	local expStage = getRateFromTable(experienceStages, self:getLevel(), configManager.getNumber(configKeys.RATE_EXP))
	exp = exp * expStage
	baseExp = rawExp * expStage
	if Game.getStorageValue(GlobalStorage.XpDisplayMode) > 0 then
		displayRate = expStage
	else
		displayRate = 1
	end

	-- Prey Bonus
	for slot = CONST_PREY_SLOT_FIRST, CONST_PREY_SLOT_THIRD do
		if (self:getPreyCurrentMonster(slot) == source:getName()
		and self:getPreyBonusType(slot) == CONST_BONUS_XP_BONUS) then
			exp = exp + math.floor(exp * (self:getPreyBonusValue(slot) / 100))
			break
		end
		if (self:getPreyTimeLeft(slot) / 60) > 0 then
			preyTimeLeft(self, slot) -- slot consumption, outside of the mosnter check
		end
	end

	-- Store Bonus
	useStaminaXp(self) -- Use store boost stamina

	local Boost = self:getExpBoostStamina()
	local stillHasBoost = Boost > 0
	local storeXpBoostAmount = stillHasBoost and self:getStoreXpBoost() or 0

	self:setStoreXpBoost(storeXpBoostAmount)

	if (storeXpBoostAmount > 0) then
		exp = exp + (baseExp * (storeXpBoostAmount/100)) -- Exp Boost
	end

	-- Stamina Bonus
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		useStamina(self)
		local staminaMinutes = self:getStamina()
		if staminaMinutes > 2340 and self:isPremium() then
			exp = exp * 1.5
			self:setStaminaXpBoost(150)
		elseif staminaMinutes <= 840 then
			exp = exp * 0.5 --TODO destroy loot of people with 840- stamina
			self:setStaminaXpBoost(50)
		else
			self:setStaminaXpBoost(100)
		end
	end

	-- Boosted creature
	if source:getName():lower() == (Game.getBoostedCreature()):lower() then
		exp = exp * 2
	end

	-- Event scheduler
	if SCHEDULE_EXP_RATE ~= 100 then
		exp = (exp * SCHEDULE_EXP_RATE)/100
	end
	self:setBaseXpGain(displayRate * 100)
	return hasEventCallback(EVENT_CALLBACK_ONGAINEXPERIENCE) and EventCallback(EVENT_CALLBACK_ONGAINEXPERIENCE, self, source, exp, rawExp) or exp
end

function Player:onLoseExperience(exp)
	 return hasEventCallback(EVENT_CALLBACK_ONLOSEEXPERIENCE) and EventCallback(EVENT_CALLBACK_ONLOSEEXPERIENCE, self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
	-- Dawnport skills limit
	if isSkillGrowthLimited(self, skill) then
		return 0
	end
	if APPLY_SKILL_MULTIPLIER == false then
		return hasEventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES) and EventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES, self, skill, tries) or tries
	end

	-- Event scheduler skill rate
	if SCHEDULE_SKILL_RATE ~= 100 then
		tries = (tries * SCHEDULE_SKILL_RATE)/100
	end

	local skillRate = configManager.getNumber(configKeys.RATE_SKILL)
	local magicRate = configManager.getNumber(configKeys.RATE_MAGIC)

	if(skill == SKILL_MAGLEVEL) then -- Magic getLevel
	tries = tries * getRateFromTable(magicLevelStages, self:getBaseMagicLevel(), magicRate)
		return hasEventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES) and EventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES, self, skill, tries) or tries
	end

	tries = tries * getRateFromTable(skillsStages, self:getSkillLevel(skill), skillRate)
	return hasEventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES) and EventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES, self, skill, tries) or tries
end

function Player:onRemoveCount(item)
	self:sendWaste(item:getId())
end

function Player:onRequestQuestLog()
	self:sendQuestLog()
end

function Player:onRequestQuestLine(questId)
	self:sendQuestLine(questId)
end

function Player:onStorageUpdate(key, value, oldValue, currentFrameTime)
	self:updateStorage(key, value, oldValue, currentFrameTime)
end

function Player:onCombat(target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)
	if not item or not target then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	if ItemType(item:getId()):getWeaponType() == WEAPON_AMMO then
		if isInArray({ITEM_OLD_DIAMOND_ARROW, ITEM_DIAMOND_ARROW}, item:getId()) then
			return primaryDamage, primaryType, secondaryDamage, secondaryType
		else
			item = self:getSlotItem(CONST_SLOT_LEFT)
		end
	end

	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

function Player:onChangeZone(zone)
	if self:isPremium() then
		local event = staminaBonus.eventsPz[self:getId()]

		if configManager.getBoolean(configKeys.STAMINA_PZ) then
			if zone == ZONE_PROTECTION then
				if self:getStamina() < 2520 then
					if not event then
						local delay = configManager.getNumber(configKeys.STAMINA_ORANGE_DELAY)
						if self:getStamina() > 2400 and self:getStamina() <= 2520 then
							delay = configManager.getNumber(configKeys.STAMINA_GREEN_DELAY)
						end

						self:sendTextMessage(MESSAGE_STATUS,
                                             string.format("In protection zone. \
                                                           Every %i minutes, gain %i stamina.",
                                                           delay, configManager.getNumber(configKeys.STAMINA_PZ_GAIN)
                                             )
                        )
						staminaBonus.eventsPz[self:getId()] = addEvent(addStamina, delay * 60 * 1000, nil, self:getId(), delay * 60 * 1000)
					end
				end
			else
				if event then
					self:sendTextMessage(MESSAGE_STATUS, "You are no longer refilling stamina, \z
                                         since you left a regeneration zone.")
					stopEvent(event)
					staminaBonus.eventsPz[self:getId()] = nil
				end
			end
			return not configManager.getBoolean(configKeys.STAMINA_PZ)
		end
	end
	return false
end

