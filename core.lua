local _, Xeer = ...

Xeer.Version = '1.8.11'
Xeer.Branch = 'RELEASE'
Xeer.Name = 'NerdPack - Xeer Routines'
Xeer.Author = 'Xeer'
Xeer.addonColor = 'ADFF2F'
Xeer.Logo = 'Interface\\AddOns\\NerdPack-Xeer\\media\\logo.blp'
Xeer.Splash = 'Interface\\AddOns\\NerdPack-Xeer\\media\\splash.blp'

local frame = CreateFrame('GameTooltip', 'Xeer_ScanningTooltip', UIParent, 'GameTooltipTemplate')

Xeer.class = select(3,UnitClass("player"))
Xeer.spell_timers = {}

--[[
local classTaunt = {
  [1] = 'Taunt',
  [2] = 'Hand of Reckoning',
  [6] = 'Dark Command',
  [10] = 'Provoke',
  [11] = 'Growl',
  [12] = 'Torment'
}
--]]

-- Temp Hack
function Xeer.ExeOnLoad()
  Xeer.Splash()
  --[[
  NeP.Interface:AddToggle({
      key = 'xopener',
      name = 'Opener rotation',
      text = 'Start opener rotation',
      icon = 'Interface\\Icons\\Ability_warrior_charge',
    })

  NeP.Interface:AddToggle({
      key = 'AutoTarget',
      name = 'Auto Target',
      text = 'Automatically target the nearest enemy when target dies or does not exist',
      icon = 'Interface\\Icons\\ability_hunter_snipershot',
    })
  --]]
end

function Xeer.Taunt(eval, args)
  local spell = NeP.Engine:Spell(args)
  if not spell then return end
  for i=1,#NeP.OM['unitEnemie'] do
    local Obj = NeP.OM['unitEnemie'][i]
    local Threat = UnitThreatSituation('player', Obj.key)
    if Threat and Threat >= 0 and Threat < 3 and Obj.distance <= 30 then
      eval.spell = spell
      eval.target = Obj.key
      return NeP.Engine:STRING(eval)
    end
  end
end

function Xeer.Round(num, idp)
  if num then
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
  else
    return 0
  end
end

function Xeer.ShortNumber(number)
  local affixes = { "", "k", "m", "b", }
  local affix = 1
  local dec = 0
  local num1 = math.abs(number)
  while num1 >= 1000 and affix < #affixes do
    num1 = num1 / 1000
    affix = affix + 1
  end
  if affix > 1 then
    dec = 2
    local num2 = num1
    while num2 >= 10 do
      num2 = num2 / 10
      dec = dec - 1
    end
  end
  if number < 0 then
    num1 = - num1
  end
  return string.format("%."..dec.."f"..affixes[affix], num1)
end

--------------------------------------------------------------------------------
--------------------------NeP CombatHelper Targeting ---------------------------
--------------------------------------------------------------------------------
--[[ disabled for now

local NeP_forceTarget = {
  -- WOD DUNGEONS/RAIDS
  [75966] = 100, -- Defiled Spirit (Shadowmoon Burial Grounds)
  [75911] = 100, -- Defiled Spirit (Shadowmoon Burial Grounds)
}

local function getTargetPrio(Obj)
  local objectType, _, _, _, _, npc_id, _ = strsplit('-', UnitGUID(Obj))
  local ID = tonumber(npc_id) or '0'
  local prio = 1
  -- Elite
  if NeP.DSL:Get('elite')(Obj) then
    prio = prio + 30
  end
  -- If its forced
  if NeP_forceTarget[tonumber(Obj)] ~= nil then
    prio = prio + NeP_forceTarget[tonumber(Obj)]
  end
  return prio
end

function Xeer.Targeting()
  -- If dont have a target, target is friendly or dead
  if not UnitExists('target') or UnitIsFriend('player', 'target') or UnitIsDeadOrGhost('target') then
    local setPrio = {}
    for GUID, Obj in pairs(NeP.OM:Get('Enemy')) do
      if UnitExists(Obj.key) and Obj.distance <= 40 then
        if (UnitAffectingCombat(Obj.key) or NeP.DSL:Get('isdummy')(Obj.key))
        and NeP.Protected:LineOfSight('player', Obj.key) then
          setPrio[#setPrio+1] = {
            key = Obj.key,
            bonus = getTargetPrio(Obj.key),
            name = Obj.name
          }
        end
      end
    end
    table.sort(setPrio, function(a,b) return a.bonus > b.bonus end)
    if setPrio[1] then
      NeP.Protected.Macro('/target '..setPrio[1].key)
    end
  end
end,
}

--]]

--------------------------------------------------------------------------------
------------------------------ Auto Dotting ------------------------------------
--------------------------------------------------------------------------------
--/dump GetSpellInfo('Frostbolt')
--/dump UnitDebuff('target', 'Moonfire', "",'PLAYER')
--/dump UnitDebuff('target', 'Chilled', "",'PLAYER')
--spell='Rake', debuff='Infected Wound'

--local _,_,_,_,_,_,debuffDuration = UnitDebuff(Obj.key, debuff, '', 'PLAYER')
--if debuffDuration == nil then debuffDuration = 0 end
--if (debuffDuration - GetTime() < NeP.DSL:Get('gcd')()) then
--print('target: '..Obj.key..'duration: '..NeP.DSL:Get('debuff.duration')(Obj.key, debuff))

function Xeer.AutoDoT(debuff,spellx)
	for _, Obj in pairs(NeP.OM:Get('Enemy')) do
	  if UnitExists(Obj.key) then
	    if (NeP.DSL:Get('combat')(Obj.key) or Obj.isdummy) then
	      local objRange = NeP.DSL:Get('range')(Obj.key)
	      local _,_,_, cast_time_ms, minRange, maxRange = GetSpellInfo(spellx)
				local cast_time_sec = cast_time_ms / 1000
	      if maxRange == 0 then maxRange = 5 end
	      --print('spell: '..spellx..' skill range: '..minRange..', '..maxRange..' obj range: '..objRange)
	      if (NeP.DSL:Get('infront')(Obj.key) and objRange >= minRange and objRange <= maxRange) then
					local travel_time = Xeer.Round((NeP.DSL:Get('travel_time')(Obj.key, spellx)), 3)
					local _, _, _, lagWorld = GetNetStats()
					local latency = ((((lagWorld / 1000) * 1.1) + (travel_time * 1.25)))
					local debuffDuration = NeP.DSL:Get('debuff.duration')(Obj.key, debuff)
	        if (debuffDuration < (NeP.DSL:Get('gcd')() + latency + cast_time_sec)) then
						--print('debuff: '..debuff..' key: '..Obj.key..' duration: '..debuffDuration)
						--print(' lag: '..(lagWorld / 1000)..' traveltime: '..travel_time..' latency: '..latency)
	          C_Timer.After(latency, function ()
	            if (debuffDuration < (NeP.DSL:Get('gcd')() + cast_time_sec)) then
								--print('/run CastSpellByName("'..spellx..'","'..Obj.key..'")')
								RunMacroText('/run CastSpellByName("'..spellx..'","'..Obj.key..'")')
								--NeP:Queue(debuff, Obj.key)
	              return true
							end
	          end)
	        end
	      end
	    end
	  end
	end
end

--[[
function Xeer.AutoDoT2(debuff)
    for _, Obj in pairs(NeP.OM:Get('Enemy')) do
        if UnitExists(Obj.key) then
            if (NeP.DSL:Get('combat')(Obj.key) or Obj.isdummy) then
								local objRange = NeP.DSL:Get('range')(Obj.key)
							  local _,_,_,_, minRange, maxRange = GetSpellInfo(debuff)
                if (NeP.DSL:Get('infront')(Obj.key) and objRange >= minRange and objRange <= maxRange) then
                    if (NeP.DSL:Get('debuff.duration')(Obj.key, debuff) < NeP.DSL:Get('gcd')()) then
                        local _, _, _, lagWorld = GetNetStats()
                        local latency = lagWorld / 1000
                        C_Timer.After(latency, function ()
                        if (NeP.DSL:Get('debuff.duration')(Obj.key, debuff) < NeP.DSL:Get('gcd')()) then
                            NeP:Queue(debuff, Obj.key)
                            return true
                        end
                    end)
                    end
                end
            end
        end
    end
end
--]]
--------------------------------------------------------------------------------
----------------------------------ToolTips--------------------------------------
--------------------------------------------------------------------------------

--/dump Xeer.Scan_SpellCost('Rake')
function Xeer.Scan_SpellCost(spell)
  local spellID = NeP.Core:GetSpellID(spell)
  frame:SetOwner(UIParent, 'ANCHOR_NONE')
  frame:SetSpellByID(spellID)
  for i = 2, frame:NumLines() do
    local tooltipText = _G['Xeer_ScanningTooltipTextLeft' .. i]:GetText()
    return tooltipText
  end
  return false
end

--/dump Xeer.Scan_IgnorePain()
function Xeer.Scan_IgnorePain()
  for i = 1, 40 do
    local qqq = select(11,UnitBuff('player', i))
    if qqq == 190456 then
      frame:SetOwner(UIParent, 'ANCHOR_NONE')
      frame:SetUnitBuff('player', i)
      local tooltipText = _G['Xeer_ScanningTooltipTextLeft2']:GetText()
      local match = tooltipText:lower():match('of the next.-$')
      return gsub(match, '%D', '') + 0
    end
  end
  return false
end

--------------------------------------------------------------------------------
-------------------------------NeP HoT / DoT API -------------------------------
--------------------------------------------------------------------------------

local function oFilter(owner, spell, spellID, caster)
if not owner then
  if spellID == tonumber(spell) and (caster == 'player' or caster == 'pet') then
    return false
  end
elseif owner == 'any' then
  if spellID == tonumber(spell) then
    return false
  end
end
return true
end

function Xeer.UnitHot(target, spell, owner)
local name, count, caster, expires, spellID
if tonumber(spell) then
  local go, i = true, 0
  while i <= 40 and go do
    i = i + 1
    name,_,_,count,_,duration,expires,caster,_,_,spellID = _G['UnitBuff'](target, i)
    go = oFilter(owner, spell, spellID, caster)
  end
else
  name,_,_,count,_,duration,expires,caster = _G['UnitBuff'](target, spell)
end
-- This adds some random factor
return name, count, expires, caster
end

function Xeer.UnitDot(target, spell, owner)
local name, count, caster, expires, spellID, power
if tonumber(spell) then
  local go, i = true, 0
  while i <= 40 and go do
    i = i + 1
    name,_,_,count,_,duration,expires,caster,_,_,spellID,_,_,_,power = _G['UnitDebuff'](target, i)
    go = oFilter(owner, spell, spellID, caster)
  end
else
  name,_,_,count,_,duration,expires,caster = _G['UnitDebuff'](target, spell)
end
-- This adds some random factor
return name, count, duration, expires, caster, power
end

--------------------------------------------------------------------------------
-------------------------------- WARRIOR ---------------------------------------
--------------------------------------------------------------------------------

--/dump Xeer.getIgnorePain()
function Xeer.getIgnorePain()
--output
local matchTooltip = false
local showPercentage = false
local simpleOutput = false
--Rage
local curRage = UnitPower('player')
local costs = GetSpellPowerCost(190456)
local minRage = costs[1].minCost or 20
local maxRage = costs[1].cost or 60
local calcRage = math.max(minRage, math.min(maxRage, curRage))

--attack power
local apBase, apPos, apNeg = UnitAttackPower('player')

--Versatility rating
local vers = 1 + ((GetCombatRatingBonus(29) + GetVersatilityBonus(30)) / 100)

--[[
--Dragon Skin
--check artifact traits
local currentRank = 0
local loaded = true
if loaded then
  artifactID = NeP.DSL:Get('artifact.active_id')()
  if not artifactID then
    NeP.DSL:Get['artifact.force_update']()
  end
  local _, traits = NeP.DSL:Get('artifact.traits')(artifactID)
  if traits then
    for _,v in ipairs(traits) do
      if v.spellID == 203225 then
        currentRank = v.currentRank
        break
      end
    end
  end
end
local trait = 1 + 0.02 * currentRank
--]]

--Dragon Scales
local scales = UnitBuff('player', GetSpellInfo(203581)) and 1.6 or 1

--Never Surrender
local curHP = UnitHealth('player')
local maxHP = UnitHealthMax('player')
local misPerc = (maxHP - curHP) / maxHP
local nevSur = select(4, GetTalentInfo(5, 2, 1))
local nevSurPerc = nevSur and (1 + 0.75 * misPerc) or 1

--Indomitable
local indom = select(4, GetTalentInfo(5, 3, 1)) and 1.25 or 1

--T18
local t18 = UnitBuff("player", GetSpellInfo(12975)) and Xeer.GetNumberSetPieces("T18") >= 4 and 2 or 1

local curIP = select(17, UnitBuff('player', GetSpellInfo(190456))) or 0
if matchTooltip then
  curIP = curIP / 0.9 --get the tooltip value instead of the absorb
end

local maxIP = (apBase + apPos + apNeg) * 18.6 * vers * indom * scales
if not matchTooltip then --some TODO notes so i wont forget fix it:
  --maxIP = Xeer.Round(maxIP * 0.9) - missing dragon skin arti passive -> * trait!!! missing 0.02-0.06
  maxIP = Xeer.Round(maxIP * 1.04) -- tooltip value my test with 2/3 dragon skin
  --maxIP = Xeer.Round((maxIP * 0.9) * trait) -- need enable after got arti lib again
end

local newIP = Xeer.Round(maxIP * (calcRage / maxRage) * 1 * nevSurPerc * t18) --*t18 *trait instead 1

local cap = Xeer.Round(maxIP * 3)
if nevSur then
  cap = cap * 1.75
end

local diff = cap - curIP

local castIP = math.min(diff, newIP)

local castPerc = Xeer.Round((castIP / cap) * 100)
local curPerc = Xeer.Round((curIP / cap) * 100)

--[[
if showPercentage then
  if simpleOutput then
    return string.format('|c%s%.1f%%%%|r', color, curPerc*100)
  end
  return string.format('|c%s%.1f%%%%|r\n%.1f%%%%', color, castPerc*100, curPerc*100)
end
if simpleOutput then
  return string.format('|c%s%s|r', color, shortenNumber(curIP))
end
return string.format('|c%s%s|r\n%s', color, shortenNumber(castIP), shortenNumber(curIP))
--]]
return cap, diff, curIP, curPerc, castIP, castPerc, maxIP, newIP, minRage, maxRage, calcRage
--maxIP = 268634.7
end

--set bonuses
--/dump Xeer.GetNumberSetPieces('T18', 'WARRIOR')
function Xeer.GetNumberSetPieces(set, class)
class = class or select(2, UnitClass("player"))
local pieces = Xeer.sets[class][set] or {}
local counter = 0
for _, itemID in ipairs(pieces) do
  if IsEquippedItem(itemID) then
    counter = counter + 1
  end
end
return counter
end

Xeer.sets = {
["WARRIOR"] = {
  ["T18"] = {
    124319,
    124329,
    124334,
    124340,
    124346,
  },
},
}

--------------------------------------------------------------------------------
-------------------------------- WARLOCK ---------------------------------------
--------------------------------------------------------------------------------

Xeer.durations = {}
Xeer.durations["Wild Imp"] = 12
Xeer.durations["Dreadstalker"] = 12
Xeer.durations["Imp"] = 25
Xeer.durations["Felhunter"] = 25
Xeer.durations["Succubus"] = 25
Xeer.durations["Felguard"] = 25
Xeer.durations["Darkglare"] = 12
Xeer.durations["Doomguard"] = 25
Xeer.durations["Infernal"] = 25
Xeer.durations["Voidwalker"] = 25

Xeer.active_demons = {}
Xeer.empower = 0
Xeer.demon_count = 0

Xeer.minions = {"Wild Imp", "Dreadstalker", "Imp", "Felhunter", "Succubus", "Felguard", "Darkglare", "Doomguard", "Infernal", "Voidwalker"}

function Xeer.update_demons()
  --print('Xeer.update_demons')
  for key,value in pairs(Xeer.active_demons) do
    if (Xeer.is_demon_dead(Xeer.active_demons[key].name, Xeer.active_demons[key].time)) then
      Xeer.active_demons[key] = nil
      Xeer.demon_count = Xeer.demon_count - 1
      --Xeer.sort_demons()
    end
  end
end

function Xeer.is_demon_empowered(guid)
  --print('Xeer.is_demon_empowered')
  if (Xeer.active_demons[guid].empower_time ~= 0 and GetTime() - Xeer.active_demons[guid].empower_time <= 12) then
    return true
  end
  return false
end

function Xeer.Empower()
  --print('Xeer.Empower')
  if Xeer.demon_count == 0 and UnitExists("pet") then
    Xeer.empower = NeP.DSL:Get('buff.remains')('pet','Demonic Empowerment')
    return Xeer.empower
  end
  if Xeer.demon_count > 0 then
    for _,v in pairs(Xeer.active_demons) do
      if Xeer.is_demon_empowered(v.guid) then
        emp1 = Xeer.get_remaining_time('Empower', v.empower_time)
        emp2 = NeP.DSL:Get('buff.remains')('pet','Demonic Empowerment')
        if emp1 < emp2 then
          Xeer.empower = emp1
        else
          Xeer.empower = emp2
        end
      else
        Xeer.empower = 0
      end
    end
  end
  return Xeer.empower
end

function Xeer.count_active_demon_type(demon)
  --print('Xeer.count_active_demon_type')
  local count = 0
  for _,v in pairs(Xeer.active_demons) do
    if v.name == demon then
      count = count + 1
    end
  end
  return count
end

function Xeer.remaining_duration(demon)
  --print('Xeer.remaining_duration')
  for _,v in pairs(Xeer.active_demons) do
    if v.name == demon then
      return Xeer.get_remaining_time(v.name, v.time)
    end
  end
end

function Xeer.implosion_cast()
  --print('Xeer.implosion_cast')
  for key,v in pairs(Xeer.active_demons) do
    if (Xeer.active_demons[key].name == "Wild Imp") then
      Xeer.active_demons[key] = nil
      Xeer.demon_count = Xeer.demon_count - 1
      --Xeer.sort_demons()
    end
  end
end

function Xeer.is_demon_dead(name, spawn)
  --print('Xeer.is_demon_dead')
  if (Xeer.get_remaining_time(name, spawn) <= 0) then
    return true
  end
  return false
end

function Xeer.get_remaining_time(name, spawn)
  --print('Xeer.get_remaining_time')
  if name == 'Empower' then
    return 12 - (GetTime() - spawn)
  else
    return Xeer.durations[name] - (GetTime() - spawn)
  end
end

function Xeer.IsMinion(name)
  --print('Xeer.IsMinion')
  for i = 1, #Xeer.minions do
    if (name == Xeer.minions[i]) then
      return true
    end
  end
  return false
end

NeP.Listener:Add('Xeer_Warlock_Pets', 'COMBAT_LOG_EVENT_UNFILTERED', function(timestamp, combatevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, ...)
  if Xeer.class == 9 then
    if (combatevent == "SPELL_SUMMON" and sourceName == UnitName("player")) then
      if (Xeer.IsMinion(destName)) then
        Xeer.active_demons[destGUID]              = {}
        Xeer.active_demons[destGUID].guid         = destGUID
        Xeer.active_demons[destGUID].name         = destName
        Xeer.active_demons[destGUID].time         = GetTime()
        Xeer.active_demons[destGUID].empower_time = 0
        Xeer.active_demons[destGUID].duration     = Xeer.durations[destName]
        Xeer.demon_count                          = Xeer.demon_count + 1
        --Xeer.sort_demons()
      end
    end

    if ((combatevent == "SPELL_AURA_APPLIED" or combatevent == "SPELL_AURA_REFRESH") and spellID == 193396 and sourceName == UnitName("player")) then
      --print('Demonic Empowerment')
      if(Xeer.IsMinion(destName)) then
        Xeer.active_demons[destGUID].empower_time = GetTime()
      end
    end

    if (combatevent == "SPELL_CAST_SUCCESS" and spellID == 196277 and sourceName == UnitName("player")) then
      --print('Implosion')
      Xeer.implosion_cast()
    end
    Xeer.update_demons()
    return true
  end
end)

--------------------------------------------------------------------------------
--------------------------------- PRIEST ---------------------------------------
--------------------------------------------------------------------------------

Xeer.Voidform_Summary = true
Xeer.S2M_Summary = true

--Xeer.Voidform_Drain_Stacks = 0
--Xeer.Voidform_Current_Drain_Rate = 0
--Xeer.SA_TOTAL = 0

function Xeer.SA_Cleanup(guid)
  if Xeer_SA_STATS[guid] then
    Xeer.SA_TOTAL = Xeer.SA_TOTAL - Xeer_SA_STATS[guid].Count
    if Xeer.SA_TOTAL < 0 then
      Xeer.SA_TOTAL = 0
    end
    Xeer_SA_STATS[guid].Count = nil
    Xeer_SA_STATS[guid].LastUpdate = nil
    Xeer_SA_STATS[guid] = nil
    Xeer_SA_NUM_UNITS = Xeer_SA_NUM_UNITS - 1
    if Xeer_SA_NUM_UNITS < 0 then
      Xeer_SA_NUM_UNITS = 0
    end
  end
end

NeP.Listener:Add('Xeer_SA', 'COMBAT_LOG_EVENT_UNFILTERED', function(timestamp,combatevent,_,sourceGUID,sourcename,_,_,destGUID,destname,_,_,spellid,spellname,_,_,_,_,_,_,_,spellcritical,_,_,_,spellmultistrike)
  if Xeer.class == 5 then
    local CurrentTime = GetTime()
    Xeer_SA_NUM_UNITS = Xeer_SA_NUM_UNITS or 0
    Xeer.SA_TOTAL     = Xeer.SA_TOTAL or 0
    -- Stats buffer
    Xeer_SA_STATS     = Xeer_SA_STATS or {}
    Xeer_SA_DEAD      = Xeer_SA_DEAD or {}
    Xeer_LAST_CONTINUITY_CHECK = Xeer_LAST_CONTINUITY_CHECK or GetTime()
    if sourceGUID == UnitGUID("player") then
      if spellid == 147193 and combatevent == "SPELL_CAST_SUCCESS" then -- Shadowy Apparition Spawned
        if not Xeer_SA_STATS[destGUID] or Xeer_SA_STATS[destGUID] == nil then
          Xeer_SA_STATS[destGUID]       = {}
          Xeer_SA_STATS[destGUID].Count = 0
          Xeer_SA_NUM_UNITS             = Xeer_SA_NUM_UNITS + 1
        end
        Xeer.SA_TOTAL = Xeer.SA_TOTAL + 1
        --print('SA spawn :'..Xeer.SA_TOTAL..' remaining SA')
        Xeer_SA_STATS[destGUID].Count      = Xeer_SA_STATS[destGUID].Count + 1
        Xeer_SA_STATS[destGUID].LastUpdate = CurrentTime
      elseif spellid == 148859 and combatevent == "SPELL_DAMAGE" then --Auspicious Spirit Hit
        if Xeer.SA_TOTAL < 0 then
          Xeer.SA_TOTAL = 0
        else
          Xeer.SA_TOTAL = Xeer.SA_TOTAL - 1
        end
        --print('SA hit :'..Xeer.SA_TOTAL..' remaining SA')
        if Xeer_SA_STATS[destGUID] and Xeer_SA_STATS[destGUID].Count > 0 then
          Xeer_SA_STATS[destGUID].Count      = Xeer_SA_STATS[destGUID].Count - 1
          Xeer_SA_STATS[destGUID].LastUpdate = CurrentTime
          if Xeer_SA_STATS[destGUID].Count <= 0 then
            Xeer.SA_Cleanup(destGUID)
          end
        end
      end
    end
    if Xeer.SA_TOTAL < 0 then
      Xeer.SA_TOTAL = 0
    end
    for guid,count in pairs(Xeer_SA_STATS) do
      if (CurrentTime - Xeer_SA_STATS[guid].LastUpdate) > 10 then
        --If we haven't had a new SA spawn in 10sec, that means all SAs that are out have hit the target (usually), or, the target disappeared.
        Xeer.SA_Cleanup(guid)
      end
    end
    if (combatevent == "UNIT_DIED" or combatevent == "UNIT_DESTROYED" or combatevent == "SPELL_INSTAKILL") then -- Unit Died, remove them from the target list.
      Xeer.SA_Cleanup(destGUID)
    end

    if UnitIsDeadOrGhost("player") or not UnitAffectingCombat("player") or not InCombatLockdown() then -- We died, or, exited combat, go ahead and purge the list
      for guid,count in pairs(Xeer_SA_STATS) do
        Xeer.SA_Cleanup(guid)
      end
      Xeer_SA_STATS     = {}
      Xeer_SA_NUM_UNITS = 0
      Xeer.SA_TOTAL     = 0
    end
    if CurrentTime - Xeer_LAST_CONTINUITY_CHECK > 10 then --Force check of unit count every 10sec
      local newUnits = 0
      for guid,count in pairs(Xeer_SA_STATS) do
        newUnits = newUnits + 1
      end
      Xeer_SA_NUM_UNITS          = newUnits
      Xeer_LAST_CONTINUITY_CHECK = CurrentTime
    end
    if Xeer_SA_NUM_UNITS > 0 then
      local totalSAs = 0
      for guid,count in pairs(Xeer_SA_STATS) do
        if Xeer_SA_STATS[guid].Count <= 0 or (UnitIsDeadOrGhost(guid)) then
          Xeer_SA_DEAD[guid] = true
        else
          totalSAs = totalSAs + Xeer_SA_STATS[guid].Count
        end
      end
      if totalSAs > 0 and Xeer.SA_TOTAL > 0 then
        return true
      end
    end
    return false
  end
end)

NeP.Listener:Add('Xeer_VF_S2M', 'COMBAT_LOG_EVENT_UNFILTERED', function(timestamp,combatevent,_,sourceGUID,sourcename,_,_,destGUID,destname,_,_,spellid,spellname,_,_,_,_,_,_,_,spellcritical,_,_,_,spellmultistrike)
  if Xeer.class == 5 then
    local CurrentTime = GetTime()
    Xeer.Voidform_Total_Stacks        = Xeer.Voidform_Total_Stacks or 0
    Xeer.Voidform_Previous_Stack_Time = Xeer.Voidform_Previous_Stack_Time or 0
    Xeer.Voidform_Drain_Stacks        = Xeer.Voidform_Drain_Stacks or 0
    Xeer.Voidform_VoidTorrent_Stacks  = Xeer.Voidform_VoidTorrent_Stacks or 0
    Xeer.Voidform_Dispersion_Stacks   = Xeer.Voidform_Dispersion_Stacks or 0
    Xeer.Voidform_Current_Drain_Rate  = Xeer.Voidform_Current_Drain_Rate or 0
    if Xeer.Voidform_Total_Stacks >= 100 then
      if (CurrentTime - Xeer.Voidform_Previous_Stack_Time) >= 1 then
        Xeer.Voidform_Previous_Stack_Time  = CurrentTime
        Xeer.Voidform_Total_Stacks         = Xeer.Voidform_Total_Stacks + 1
        if Xeer.Voidform_VoidTorrent_Start == nil and Xeer.Voidform_Dispersion_Start == nil then
          Xeer.Voidform_Drain_Stacks       = Xeer.Voidform_Drain_Stacks + 1
          -- print('Xeer.Voidform_Drain_Stacks1: '..Xeer.Voidform_Drain_Stacks)
          Xeer.Voidform_Current_Drain_Rate = (9.0 + ((Xeer.Voidform_Drain_Stacks - 1) / 2))
          -- print('Xeer.Voidform_Current_Drain_Rate1: '..Xeer.Voidform_Current_Drain_Rate)
        elseif Xeer.Voidform_VoidTorrent_Start ~= nil then
          Xeer.Voidform_VoidTorrent_Stacks = Xeer.Voidform_VoidTorrent_Stacks + 1
        else
          Xeer.Voidform_Dispersion_Stacks  = Xeer.Voidform_Dispersion_Stacks + 1
        end
      end
    end
    if sourceGUID == UnitGUID("player") then
      if spellid == 194249 then
        if combatevent == "SPELL_AURA_APPLIED" then -- Entered Voidform
          Xeer.Voidform_Previous_Stack_Time = CurrentTime
          Xeer.Voidform_VoidTorrent_Start   = nil
          Xeer.Voidform_Dispersion_Start    = nil
          Xeer.Voidform_Drain_Stacks        = 1
          Xeer.Voidform_Start_Time          = CurrentTime
          Xeer.Voidform_Total_Stacks        = 1
          Xeer.Voidform_VoidTorrent_Stacks  = 0
          Xeer.Voidform_Dispersion_Stacks   = 0
        elseif combatevent == "SPELL_AURA_APPLIED_DOSE" then -- New Voidform Stack
          Xeer.Voidform_Previous_Stack_Time  = CurrentTime
          Xeer.Voidform_Total_Stacks         = Xeer.Voidform_Total_Stacks + 1
          if Xeer.Voidform_VoidTorrent_Start == nil and Xeer.Voidform_Dispersion_Start == nil then
            Xeer.Voidform_Drain_Stacks       = Xeer.Voidform_Drain_Stacks + 1
            -- print('Xeer.Voidform_Drain_Stacks2: '..Xeer.Voidform_Drain_Stacks)
            Xeer.Voidform_Current_Drain_Rate = (9.0 + ((Xeer.Voidform_Drain_Stacks - 1) / 2))
            -- print('Xeer.Voidform_Current_Drain_Rate2: '..Xeer.Voidform_Current_Drain_Rate)
          elseif Xeer.Voidform_VoidTorrent_Start ~= nil then
            Xeer.Voidform_VoidTorrent_Stacks = Xeer.Voidform_VoidTorrent_Stacks + 1
          else
            Xeer.Voidform_Dispersion_Stacks  = Xeer.Voidform_Dispersion_Stacks + 1
          end
        elseif combatevent == "SPELL_AURA_REMOVED" then -- Exited Voidform
          if Xeer.Voidform_Summary == true then
            print("Voidform Info:")
            print("--------------------------")
            print(string.format("Voidform Duration: %.2f seconds", (CurrentTime-Xeer.Voidform_Start_Time)))
            if Xeer.Voidform_Total_Stacks > 100 then
              print(string.format("Voidform Stacks: 100 (+%.0f)", (Xeer.Voidform_Total_Stacks - 100)))
            else
              print(string.format("Voidform Stacks: %.0f", Xeer.Voidform_Total_Stacks))
            end
            print(string.format("Dispersion Stacks: %.0f", Xeer.Voidform_Dispersion_Stacks))
            print(string.format("Void Torrent Stacks: %.0f", Xeer.Voidform_VoidTorrent_Stacks))
            print("Final Drain: "..Xeer.Voidform_Drain_Stacks.." stacks, "..Xeer.Voidform_Current_Drain_Rate.." / sec")
          end
          Xeer.Voidform_VoidTorrent_Start  = nil
          Xeer.Voidform_Dispersion_Start   = nil
          Xeer.Voidform_Drain_Stacks       = 0
          Xeer.Voidform_Current_Drain_Rate = 0
          Xeer.Voidform_Start_Time         = nil
          Xeer.Voidform_Total_Stacks       = 0
          Xeer.Voidform_VoidTorrent_Stacks = 0
          Xeer.Voidform_Dispersion_Stacks  = 0
        end

      elseif spellid == 205065 then
        if combatevent == "SPELL_AURA_APPLIED" then -- Started channeling Void Torrent
          Xeer.Voidform_VoidTorrent_Start = CurrentTime
        elseif combatevent == "SPELL_AURA_REMOVED" and Xeer.Voidform_VoidTorrent_Start ~= nil then -- Stopped channeling Void Torrent
          Xeer.Voidform_VoidTorrent_Start = nil
        end

      elseif spellid == 47585 then
        if combatevent == "SPELL_AURA_APPLIED" then -- Started channeling Dispersion
          Xeer.Voidform_Dispersion_Start  = CurrentTime
        elseif combatevent == "SPELL_AURA_REMOVED" and Xeer.Voidform_Dispersion_Start ~= nil then -- Stopped channeling Dispersion
          Xeer.Voidform_Dispersion_Start  = nil
        end

      elseif spellid == 212570 then
        if combatevent == "SPELL_AURA_APPLIED" then -- Gain Surrender to Madness
          Xeer.Voidform_S2M_Activated     = true
          Xeer.Voidform_S2M_Start         = CurrentTime
        elseif combatevent == "SPELL_AURA_REMOVED" then -- Lose Surrender to Madness
          Xeer.Voidform_S2M_Activated     = false
        end
      end

    elseif destGUID == UnitGUID("player") and (combatevent == "UNIT_DIED" or combatevent == "UNIT_DESTROYED" or combatevent == "SPELL_INSTAKILL") and Xeer.Voidform_S2M_Activated == true then
      Xeer.Voidform_S2M_Activated = false
      if Xeer.S2M_Summary == true then
        print("Surrender to Madness Info:")
        print("--------------------------")
        print(string.format("S2M Duration: %.2f seconds", (CurrentTime-Xeer.Voidform_S2M_Start)))
        print(string.format("Voidform Duration: %.2f seconds", (CurrentTime-Xeer.Voidform_Start_Time)))
        if Xeer.Voidform_Total_Stacks > 100 then
          print(string.format("Voidform Stacks: 100 (+%.0f)", (Xeer.Voidform_Total_Stacks - 100)))
        else
          print(string.format("Voidform Stacks: %.0f", Xeer.Voidform_Total_Stacks))
        end
        print(string.format("Dispersion Stacks: %.0f", Xeer.Voidform_Dispersion_Stacks))
        print(string.format("Void Torrent Stacks: %.0f", Xeer.Voidform_VoidTorrent_Stacks))
        print("Final Drain: "..Xeer.Voidform_Drain_Stacks.." stacks, "..Xeer.Voidform_Current_Drain_Rate.." / sec")
      end
      Xeer.Voidform_S2M_Start          = nil
      Xeer.Voidform_VoidTorrent_Start  = nil
      Xeer.Voidform_Dispersion_Start   = nil
      Xeer.Voidform_Drain_Stacks       = 0
      Xeer.Voidform_Current_Drain_Rate = 0
      Xeer.Voidform_Start_Time         = nil
      Xeer.Voidform_Total_Stacks       = 0
      Xeer.Voidform_VoidTorrent_Stacks = 0
      Xeer.Voidform_Dispersion_Stacks  = 0
    end
  end
end)

--------------------------------------------------------------------------------
--------------------------------- DRUID ----------------------------------------
--------------------------------------------------------------------------------

--Feral

Xeer.f_pguid = UnitGUID("player")
Xeer.f_cp = 0
Xeer.f_cleanUpTimer = nil
Xeer.f_lastUpdate = 0
Xeer.f_nextUpdateDmg = nil

Xeer.f_buffs = {
  ["tigersFury"]  = 0,
  ["savageRoar"]  = 0,
  ["bloodtalons"] = 0,
  ["incarnation"] = 0,
  ["prowl"]       = 1,
  ["shadowmeld"]  = 1,
}

Xeer.f_events = {
  ["SPELL_AURA_APPLIED"] = true,
  ["SPELL_AURA_REFRESH"] = true,
  ["SPELL_AURA_REMOVED"] = true,
  ["SPELL_CAST_SUCCESS"] = true,
  ["SPELL_MISSED"]       = true,
}

Xeer.f_buffID = {
  [5217]   = "tigersFury",
  [52610]  = "savageRoar",
  [145152] = "bloodtalons",
  [102543] = "incarnation",
  [5215]   = "prowl",
  [102547] = "prowl",
  [58984]  = "shadowmeld",
}

Xeer.f_debuffID = {
  [163505] = "rake", --stun effect
  [1822]   = "rake", --initial dmg
  [1079]   = "rip",
  [106830] = "thrash",
  [155722] = "rake", --dot
  [155625] = "moonfire",
}

--Initialize tables to hold all snapshot data
Xeer.f_Snapshots = {
  ["rake"]     = {},
  ["rip"]      = {},
  ["thrash"]   = {},
  ["moonfire"] = {},
}

--Create localization strings
Xeer.f_strings = {
  ["tigersFury"]  = GetSpellInfo(5217) or "Tiger's Fury",
  ["savageRoar"]  = GetSpellInfo(52610) or "Savage Roar",
  ["bloodtalons"] = GetSpellInfo(145152) or "Bloodtalons",
  ["incarnation"] = GetSpellInfo(102543) or "Incarnation: King of the Jungle",
  ["prowl"]       = GetSpellInfo(5215) or "Prowl",
  ["shadowmeld"]  = GetSpellInfo(58984) or "Shadowmeld",
}

--Create update function for checking for buffs
function Xeer.f_update()
  local b = Xeer.f_buffs
  local s = Xeer.f_strings
  local now = GetTime()
  Xeer.f_lastUpdate = now

  b.tigersFury  = select(7,UnitBuff("player", s.tigersFury)) or b.tigersFury
  b.savageRoar  = select(7,UnitBuff("player", s.savageRoar)) or b.savageRoar
  b.bloodtalons = select(7,UnitBuff("player", s.bloodtalons)) or b.bloodtalons
  b.incarnation = select(7,UnitBuff("player", s.incarnation)) or b.incarnation
  b.prowl       = select(7,UnitBuff("player", s.prowl)) or b.prowl
  b.shadowmeld  = select(7,UnitBuff("player", s.shadowmeld)) or b.shadowmeld
  Xeer.f_updateDmg()
end

--Create update function for calculating current snapshot strength
function Xeer.f_updateDmg()
  local b = Xeer.f_buffs
  local now = GetTime()
  local dmgMulti = 1
  local rakeMulti = 1
  local bloodtalonsMulti = 1
  local currentCP = UnitPower("player",4)
  if currentCP ~= 0 then
    Xeer.f_cp = currentCP
  end
  if b.tigersFury > now then dmgMulti = dmgMulti * 1.15 end
  if b.savageRoar > now then dmgMulti = dmgMulti * 1.25 end
  if b.bloodtalons > now then bloodtalonsMulti = 1.5 end
  if b.incarnation > now or b.prowl > now or b.shadowmeld > now then rakeMulti=2
  elseif b.prowl == 0 or b.shadowmeld == 0 then rakeMulti=2 end
  Xeer.f_Snapshots.rip.current      = dmgMulti*bloodtalonsMulti*Xeer.f_cp
  Xeer.f_Snapshots.rip.current5CP   = dmgMulti*bloodtalonsMulti*5
  Xeer.f_Snapshots.rake.current     = dmgMulti*bloodtalonsMulti*rakeMulti
  Xeer.f_Snapshots.thrash.current   = dmgMulti*bloodtalonsMulti
  Xeer.f_Snapshots.moonfire.current = dmgMulti
end

--Create function for handling clean up of the snapshot table
function Xeer.f_cleanUp()
  --Cancel existing scheduled cleanup first if there is one
  if Xeer.f_cleanUpTimer then Xeer.f_cancelCleanUp() end
  Xeer.f_cleanUpTimer = C_Timer.NewTimer(30,function()
    if UnitIsDeadOrGhost("player") or not UnitAffectingCombat("player") or not InCombatLockdown() then
    --if not UnitAffectingCombat("player") then
      Xeer.f_Snapshots = {
        ["rake"]     = {},
        ["rip"]      = {},
        ["thrash"]   = {},
        ["moonfire"] = {}
      }
    end
  end)
end

--Create clean up function
function Xeer.f_cancelCleanUp()
  if Xeer.f_cleanUpTimer then
    Xeer.f_cleanUpTimer:Cancel()
    Xeer.f_cleanUpTimer = nil
  end
end

NeP.Listener:Add('Xeer_f_update1', 'ZONE_CHANGED_NEW_AREA', function()
  if Xeer.class == 11 then
    Xeer.f_update()
  end
end)

NeP.Listener:Add('Xeer_f_update2', 'ACTIVE_TALENT_GROUP_CHANGED', function()
  if Xeer.class == 11 then
    Xeer.f_update()
  end
end)

NeP.Listener:Add('Xeer_f_updateDmg', 'UNIT_POWER', function(unit, type)
  if Xeer.class == 11 then
    if unit == "player" and type == "COMBO_POINTS" then
      Xeer.f_updateDmg()
    end
  end
end)

NeP.Listener:Add('Xeer_f_Snapshot', 'COMBAT_LOG_EVENT_UNFILTERED', function(timestamp, combatevent, _, sourceGUID, _,_,_, destGUID, _,_,_, spellID)
  if Xeer.class == 11 then
    --This trigger listens for bleed events to record snapshots.
    --This trigger also listens for changes in buffs to recalculate bleed damage.

    --Check for only relevant player events
    if not Xeer.f_buffID[spellID] and not Xeer.f_debuffID[spellID] then return end
    if not Xeer.f_events[combatevent] then return end
    if sourceGUID ~= Xeer.f_pguid then return end

    --Handle AURA_APPLY and AURA_REFRESH as the same event type
    if combatevent == "SPELL_AURA_REFRESH" then combatevent = "SPELL_AURA_APPLIED" end

    --Convert rake stun events into rake casts to handle corner case with prowl+rake
    if spellID == 163505 and (combatevent=="SPELL_MISSED" or combatevent=="SPELL_AURA_APPLIED") then
      spellID = 1822
      combatevent = "SPELL_CAST_SUCCESS"
    end

    --Listen for buff changes on player that affect snapshots
    if destGUID == Xeer.f_pguid then
      if combatevent == "SPELL_AURA_APPLIED" then Xeer.f_update() return
      elseif combatevent == "SPELL_AURA_REMOVED" then
      	local spellName = Xeer.f_buffID[spellID]
        local dur = 0
        --Add small timing window for buffs that can expire before cast
        if spellName == "bloodtalons" then dur    = 0.1
        elseif spellName == "prowl" then dur      = 0.1
        elseif spellName == "shadowmeld" then dur = 0.1
        end

        if spellName then
          Xeer.f_buffs[spellName] = GetTime() + dur
          Xeer.f_nextUpdateDmg    = GetTime() + dur + 0.01
          return
        end
      end
    end

    -- The following code handles application and expiration of bleeds

    -- 1. Snapshot dmg on spell cast success
    local fs = Xeer.f_Snapshots
    if combatevent == "SPELL_CAST_SUCCESS" then
      local spellName
      if spellID == 1822 then spellName       = "rake"
      elseif spellID == 1079 then spellName   = "rip"
      elseif spellID == 106830 then spellName = "thrash"
      elseif spellID == 155625 then spellName = "moonfire"
      end

      if spellName then
        Xeer.f_update()
        fs[spellName]["onCast"] = fs[spellName]["current"]
        return
      end

      --2. Record snapshot for target if and when the bleed is applied
    elseif combatevent == "SPELL_AURA_APPLIED" then
      local spellName
      if spellID == 155722 then spellName     = "rake"
      elseif spellID == 1079 then spellName   = "rip"
      elseif spellID == 106830 then spellName = "thrash"
      elseif spellID == 155625 then spellName = "moonfire"
      end

      if spellName then
        fs[spellName][destGUID] = fs[spellName]["onCast"]
        return
      end

      --3. Remove snapshot for target when bleed expires
    elseif combatevent == "SPELL_AURA_REMOVED" then
      local spellName
      if spellID == 155722 then spellName     = "rake"
      elseif spellID == 1079 then spellName   = "rip"
      elseif spellID == 106830 then spellName = "thrash"
      elseif spellID == 155625 then spellName = "moonfire"
      end

      if spellName then
        fs[spellName][destGUID] = nil
        return
      end
    end
  end
end)

NeP.Listener:Add('Xeer_OutOfCombat', 'PLAYER_REGEN_ENABLED', function()
  if Xeer.class == 9 then
    --This trigger manages clean up of snapshots when it is safe to do so
    --1. Schedule cleanup of snapshots when combat ends
  	Xeer.f_cleanUp()
  end
end)

NeP.Listener:Add('Xeer_InCombat', 'PLAYER_REGEN_DISABLED', function()
  if Xeer.class == 9 then
    --2. Check for and cancel scheduled cleanup when combat starts
  	Xeer.f_cancelCleanUp()

    C_Timer.NewTicker(1.5, (function()
      --This trigger runs the update function if there have been no updates recently
      --due to a lack of relevant combat events.
    	if not UnitIsDeadOrGhost("player") and (UnitAffectingCombat("player") or InCombatLockdown()) then
        if GetTime() - Xeer.f_lastUpdate >= 3 then Xeer.f_update() end
        --if GetTime() - Xeer.lastDmgUpdate >= 0.045 then Xeer.f_updateDmg() end
        if Xeer.f_nextUpdateDmg and GetTime() > Xeer.f_nextUpdateDmg then
          Xeer.f_nextUpdateDmg = nil
          Xeer.f_updateDmg()
        end
      end
    end), nil)
  end
end)

--Guardian--

--------------------------------------------------------------------------------
-------------------------------- TRAVEL SPEED-----------------------------------
--------------------------------------------------------------------------------

-- List of know spells travel speed. Non charted spells will be considered traveling 40 yards/s
-- To recover travel speed, open up /eventtrace, calculate difference between SPELL_CAST_SUCCESS and SPELL_DAMAGE events

local Travel_Chart = {
  [116]    = 23.174, -- Frostbolt
  [228597] = 23.174, -- Frostbolt
  [133]    = 45.805, -- Fireball
  [11366]  = 52, -- Pyroblast
  [29722]  = 18, -- Incinerate
  [30455]  = 25.588, -- Ice Lance
  [105174] = 33, -- Hand of Gul'dan
  [120644] = 10, -- Halo
  [122121] = 25, -- Divine Star
  [127632] = 19, -- Cascade
  [210714] = 38, -- Icefury
  [51505]  = 38.090, -- Lava Burst
  [205181] = 32.737, -- Shadowflame
}

-- Return the time a spell will need to travel to the current target
function Xeer.TravelTime(unit, spell)
	local spellID = NeP.Core:GetSpellID(spell)
	if Travel_Chart[spellID] then
		TravelSpeed = Travel_Chart[spellID]
		return NeP.DSL:Get("distance")(unit) / TravelSpeed
	else
		return 0
	end
end

--[[
--Travel Time Track Listener

Xeer.TTTL_table = {}
Xeer.TTTL_enable = false
Xeer.start_timer = nil

--/dump NeP.DSL:Get('tttlz')()
function Xeer.TTTL_calc_tt()
for k,v in pairs(Xeer.TTTL_table) do
  if k and v.finish then
		print(v.finish..' '..v.start)
    v.travel_time = v.finish - v.start
    if v.travel_time ~= 0 then
      v.travel_speed = v.distance / v.travel_time
     	local write_itx = "["..v.spellID.."] = "..v.travel_speed..", -- "..v.name.."\n"
			local write_it = v.travel_speed.."\n"
      print(write_itx)
      WriteFile('mage.lua', write_it, true)
    end
    wipe(Xeer.TTTL_table)
  end
end
end
--]]

--------------------------------------------------------------------------------
----------------------------- MISC LISTENERS -----------------------------------
--------------------------------------------------------------------------------

NeP.Listener:Add('Xeer_Listener4', 'COMBAT_LOG_EVENT_UNFILTERED', function(timestamp, combatevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, ...)
  if (combatevent == "SPELL_CAST_SUCCESS" and sourceName == UnitName("player")) then
    Xeer.spell_timers[spellID]      = {}
    Xeer.spell_timers[spellID].name = spellName
    Xeer.spell_timers[spellID].id   = spellID
    Xeer.spell_timers[spellID].time = GetTime()
  end
  if UnitIsDeadOrGhost("player") or not UnitAffectingCombat("player") or not InCombatLockdown() then
    Xeer.spell_timers = {}
  end
end)


--[[
NeP.Listener:Add('Xeer_Listener_TravelSpeed', 'COMBAT_LOG_EVENT_UNFILTERED', function(timestamp, combatevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, amount, ...)
  if Xeer.TTTL_enable == true then
    if (combatevent == "SPELL_CAST_SUCCESS" and sourceName == UnitName("player")) then
			if spellID ~= 228597 then
	      print('SPELL_CAST_SUCCESS: '..spellName..', '..spellID)
				Xeer.start_timer = GetTime()
	      mirror_name = spellName
			end
    end
    if (combatevent == "SPELL_DAMAGE" and spellName == mirror_name and sourceName == UnitName("player")) then
      print('SPELL_DAMAGE: '..spellName..', '..spellID)
				if uniqID == nil then uniqID = 0 end
				uniqID = uniqID + 1
				Xeer.TTTL_table[uniqID] = {}
				Xeer.TTTL_table[uniqID].name = spellName
				Xeer.TTTL_table[uniqID].spellID = spellID
				Xeer.TTTL_table[uniqID].start = Xeer.start_timer
				Xeer.TTTL_table[uniqID].distance = NeP.DSL:Get('range')('target')
	      Xeer.TTTL_table[uniqID].finish = GetTime()
	      Xeer.TTTL_table[uniqID].travel_time = 0
	      Xeer.TTTL_table[uniqID].travel_speed = 0
	      Xeer.TTTL_calc_tt()
    end
  end
end)
--]]

--------------------------------------------------------------------------------
-------------------------------- GABBZ_START -----------------------------------
--------------------------------------------------------------------------------

--your stuffs here, for now

--------------------------------------------------------------------------------
-------------------------------- GABBZ_END -------------------------------------
--------------------------------------------------------------------------------

NeP.Library:Add('Xeer', Xeer)
