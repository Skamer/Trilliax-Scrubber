-- ========================================================================== --
-- 										 Trilliax Scrubber                                      --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/trilliaxscrubber        --
-- ========================================================================== --
Scorpio                   "TrilliaxScrubber"                             "1.2.3"
-- ========================================================================== --
namespace "TSC"
import "System"
import "System.Collections"
-- ========================[[ Logger ]]========================================
Log                 = Logger("EskaQuestTracker")

Trace               = Log:SetPrefix(1, "|cffa9a9a9[TrilliaxScrubber:Trace]|r", true)
Debug               = Log:SetPrefix(2, "|cff808080[TrilliaxScrubber:Debug]|r", true)
Info                = Log:SetPrefix(3, "|cffffffff[TrilliaxScrubber:Info]|r", true)
Warn                = Log:SetPrefix(4, "|cffffff00[TrilliaxScrubber:Warn]|r", true)
Error               = Log:SetPrefix(5, "|cffff0000[TrilliaxScrubber:Error]|r", true)
Fatal               = Log:SetPrefix(6, "|cff8b0000[TrilliaxScrubber:Fatal]|r", true)

Log.LogLevel = 3

Log:AddHandler(print)
-- =============================================================================
_BombTexture = [[Interface\AddOns\TrilliaxScrubber\Media\Bomb.tga]]

local TrilliaxEncounterID = 1867
local InEncounter = false

-- 10 LFR, 20 NM, 25 HM, 40 M
local GainManaByCast = 0
local ScrubbingSpellID = 211907
local ScrubbingExplodingSpellID = 207327


local IsCasting = {}

-- ========================================================================== --
-- Class Definition
-- ========================================================================== --
class "InfoBox"
  __Arguments__{ Number }
  function SetBombNum(self, num)
    self.frame.bombText:SetText(tostring(num))
  end

  __Arguments__ { String }
  function SetText(self, text)
    self.frame.text:SetText(text)
  end

  function Lock(self)
    self.frame:EnableMouse(false)
    self.frame:SetMovable(false)
  end

  function Unlock(self)
    self.frame:EnableMouse(true)
    self.frame:SetMovable(true)
  end

  __Arguments__ { Boolean }
  function SetLocked(self, locked)
    if locked then
      self:Lock()
    else
      self:Unlock()
    end
  end

  function Hide(self)
    self.frame:Hide()
  end

  function Show(self)
    self.frame:Show()
  end

  function ToggleShow(self)
    if self.frame:IsShown() then
      self:Hide()
    else
      self:Show()
    end
  end

  function ShowText(self)
    self.frame.text:Show()
  end

  function HideText(self)
    self.frame.text:Hide()
  end

  function SetPosition(self, x, y)
    self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
  end

  local function HandleFrameDragStop(frame)
    frame:StopMovingOrSizing()

    x = frame:GetLeft()
    y = frame:GetBottom()

    _DB.InfoBox.offsetX = x
    _DB.InfoBox.offsetY = y
  end

  function InfoBox(self)
    local frame = CreateFrame("Frame")
    frame:SetPoint("CENTER")
    frame:SetHeight(64)
    frame:SetWidth(200)

    local bombIcon = frame:CreateTexture()
    bombIcon:SetTexture(_BombTexture)
    bombIcon:SetHeight(24)
    bombIcon:SetWidth(24)
    bombIcon:SetPoint("LEFT")
    bombIcon:SetVertexColor(1, 0, 0)
    frame.bombIcon = bombIcon

    local bombText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bombText:SetText("3")
    bombText:SetPoint("CENTER", bombIcon, "CENTER", -2, -3)
    frame.bombText = bombText

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", bombIcon, "RIGHT", 0, -3)
    text:SetPoint("RIGHT")
    text:SetJustifyH("LEFT")
    text:SetText("1.7s  3.4s 4.5s")
    frame.text = text


    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", HandleFrameDragStop)
    frame:EnableMouse(true)
    frame:SetMovable(true)

    self.frame = frame
  end
endclass "InfoBox"
--------------------------------------------------------------------------------
class "Scrubber"
  property "guid" { TYPE = String }
  property "isActive" { TYPE = Boolean, DEFAULT = true }
  property "isExploding" { TYPE = Boolean, DEFAULT = false }
  property "startExploding"
endclass "Scrubber"
-- =============================================================================

function OnLoad(self)
  _DB = SVManager("TrilliaxScrubberDB")

  _DB:SetDefault("General", {
    enabled = true,
    predictMana = true,

  })

  _DB:SetDefault("BombIcon", {
    enabled = true,
    width = 64,
    height = 64,
    offsetX = 0,
    offsetY = -15,
    anchorFrom = "BOTTOM",
    anchorTo = "TOP",
  })

  _DB:SetDefault("Thresholds", {
    low = { enabled = false,  mana = 25,  cast = 4, color = { r = 0, g = 1, b = 0} },
    medium = { enabled = false, mana = 50, cast = 3, color = { r = 1, g = 1, b = 0} },
    high = { enabled = true, mana = 75, cast = 2, color = { r = 1, g = 0.5, b = 0} },
    urgent = { enabled = true, mana = 100,  cast = 1, color = { r = 1, g = 0, b = 0} },
  })

  _DB:SetDefault("ManaText", {
    enabled = true,
    size = 20,
    color = { r = 1, g = 1, b = 1},
    offsetX = -5,
    offsetY = -10,
    anchorToBombIcon = true,
    anchorFrom = "CENTER",
    anchorTo = "CENTER",
  })

  _DB:SetDefault("InfoBox", {
    enabled = true,
    locked = false,
    anchorTo = "CENTER",
    anchorFrom = "CENTER",
    offsetX = 497,
    offsetY = 334,
    hideTimers = false,
  })

  self.scrubbers = Dictionary()

  _InfoBox = InfoBox()
  _InfoBox:SetLocked(_DB.InfoBox.locked)
  _InfoBox:SetPosition(_DB.InfoBox.offsetX, _DB.InfoBox.offsetY)
  _InfoBox:Hide()
end

local function GetUnitByFrame(frame)
  if frame.namePlateUnitToken then
    return frame.namePlateUnitToken
  elseif frame.UnitFrame and frame.UnitFrame.unit then -- for Elvui Users
    return frame.UnitFrame.unit
  end

  return nil
end

function AddScrubber(self, guid)
  if not self.scrubbers[guid] then
    local scrubber = Scrubber()
    scrubber.guid = guid

    self.scrubbers[guid] = scrubber

    return scrubber
  end
end

function ClearScrubbers(self)
  for k,v in self.scrubbers:GetIterator() do
    self.scrubbers[k] = nil
  end
end


__SystemEvent__()
function NAME_PLATE_CREATED(frame, ...)
  local mana = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  mana:SetTextColor(1, 0, 0)
  mana:SetPoint("LEFT", frame, "RIGHT")
  mana:SetText("100")
  mana:SetParent(UIParent)
  mana:Hide()

  local bomb = frame:CreateTexture()
  bomb:SetTexture(_BombTexture)
  bomb:SetPoint("BOTTOM", frame, "TOP")
  bomb:SetHeight(64)
  bomb:SetWidth(64)
  bomb:SetVertexColor(1, 0, 0)
  bomb:SetParent(UIParent)
  bomb:Hide()

  frame.Trilliax = {
    mana = mana,
    bomb = bomb
  }
  _Addon:Refresh(frame)
end

__SystemEvent__()
function NAME_PLATE_UNIT_ADDED(unit)
  local frame = C_NamePlate.GetNamePlateForUnit(unit)
  local guid = UnitGUID(unit)
  if _Addon:IsScrubber(unit) and frame.Trilliax then
    frame.Trilliax.mana:Show()
    frame.Trilliax.bomb:Show()
  end
end

__SystemEvent__()
function NAME_PLATE_UNIT_REMOVED(unit)
  local frame = C_NamePlate.GetNamePlateForUnit(unit)
  if frame.Trilliax then
    frame.Trilliax.mana:Hide()
    frame.Trilliax.bomb:Hide()
  end
end

__SystemEvent__()
function ENCOUNTER_START(encounterID, encounterName, difficulty, size)
  if encounterID == TrilliaxEncounterID then
      --print("ENCOUNTER_START", encounterID, encounterName, difficulty, size)
      InEncounter = true
      if difficulty == 17 then -- LFR
        GainManaByCast = 10
      elseif difficulty == 15 then  -- HEROIC
        GainManaByCast = 25
      elseif difficulty == 16 then -- Mythic
        GainManaByCast = 40
      else  -- NORMAL
        GainManaByCast = 20
      end
      _Addon:UpdateAll()
  end
end

-- 1867, "Trilliax" 104596
__SystemEvent__()
function ENCOUNTER_END(encounterID, encounterName, difficulty, size, endStatus)
  if encounterID == TrilliaxEncounterID then
    _Addon:ClearScrubbers()
    _InfoBox:Hide()
    InEncounter = false
  end
end

__SystemEvent__()
function COMBAT_LOG_EVENT_UNFILTERED(timestamp, message, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, destFlags2, ...)
  if not InEncounter then return end

  if _M:IsScrubber(sourceGUID) then
    _M:AddScrubber(sourceGUID)
  elseif _M:IsScrubber(destGUID) then
    _M:AddScrubber(destGUID)
  end

  if message == "SPELL_CAST_START" then
    local spellID, spellName = ...

    if spellID == ScrubbingSpellID then
      IsCasting[sourceGUID] = true
    end
  elseif message == "SPELL_CAST_SUCCESS" or message == "SPELL_CAST_FAILED" then
    local spellID, spellName = ...

    if spellID == ScrubbingSpellID then
      IsCasting[sourceGUID] = nil
    end
  elseif message == "SPELL_AURA_APPLIED" then
    local spellID, spellName = ...
    if spellID == ScrubbingExplodingSpellID then
      _M.scrubbers[sourceGUID].startExploding = GetTime()
      _M.scrubbers[sourceGUID].isExploding = true
    end
  elseif message == "SPELL_AURA_REMOVED" then
    local spellID, spellName = ...
    if spellID == ScrubbingExplodingSpellID then
      _M.scrubbers[sourceGUID].isExploding = false
      _M.scrubbers[sourceGUID].isActive = false
    end
  end
end


function GetNpcID(self, guid)
  if not guid then return -1 end

  local _, _, _, _, _, npcID, _ = strsplit("-", guid)

  return tonumber(npcID)
end

function IsScrubber(self, guid)
  return self:GetNpcID(guid) == 104596
end


__Thread__()
function UpdateAll(self)
  while InEncounter do
    for _, frame in pairs(C_NamePlate.GetNamePlates()) do

      -- @NOTE : Need use this function to get a valid unit for the Elvui users.
      local unit = GetUnitByFrame(frame)
      if unit then
        local guid = UnitGUID(unit)
        if self:IsScrubber(guid) and frame.Trilliax then
          self:Update(unit, frame, guid, false)
        elseif frame.Trilliax then
          frame.Trilliax.mana:Hide()
          frame.Trilliax.bomb:Hide()
        end
      end
    end

    if _DB.InfoBox.enabled then
      local explodingList = self.scrubbers:Filter("k,v=>v.isExploding").Values:ToList():Sort("x,y=>x.startExploding<y.startExploding")
      local txt = ""
      for index, obj in explodingList:GetIterator() do
        if not _DB.InfoBox.hideTimers then
          local secLeft =  obj.startExploding + 7 - GetTime()
          if secLeft < 2 then
            txt = txt .. string.format("|cffff0000%.1fs|r", secLeft) .. " "
          elseif secLeft < 4 then
            txt = txt .. string.format("|cffff7f00%.1fs|r", secLeft) .. " "
          else
            txt = txt .. string.format("%.1fs", secLeft) .. " "
          end
        end
      end

      if _DB.InfoBox.hideTimers then
        _InfoBox:HideText()
      else
        _InfoBox:SetText(txt)
        _InfoBox:ShowText()
      end

      _InfoBox:SetBombNum(explodingList.Count)

      if explodingList.Count > 0 then
        _InfoBox:Show()
      else
        _InfoBox:Hide()
      end

    end
    Delay(0.04)
  end
end

function Update(self, unit, frame, guid, testMode, testManaAmount)
  local mana = not testMode and UnitPower(unit, SPELL_POWER_MANA) or testManaAmount

  local manaText = frame.Trilliax.mana
  local bombIcon = frame.Trilliax.bomb

  if _DB.ManaText.enabled then
    manaText:Show()
    manaText:SetText(tostring(mana))
    manaText:SetTextColor(_DB.ManaText.color.r, _DB.ManaText.color.g, _DB.ManaText.color.b)
  end

  if _DB.BombIcon.enabled then
    bombIcon:Show()
  end

  if IsCasting[guid] and _DB.General.predictMana then
    mana = mana + GainManaByCast
  end

  -- Thresholds
  local low = _DB.Thresholds.low
  local medium = _DB.Thresholds.medium
  local high = _DB.Thresholds.high
  local urgent = _DB.Thresholds.urgent

  local color
  if urgent.enabled and mana >= urgent.mana then
    color = urgent.color
  elseif high.enabled and mana >= high.mana then
    color = high.color
  elseif medium.enabled and mana >= medium.mana then
    color = medium.color
  elseif low.enabled and mana >= low.mana then
    color = low.color
  else
    bombIcon:Hide()
  end

  if color then
    if _M.scrubbers[sourceGUID] and M.scrubbers[sourceGUID].isExploding then
      bombIcon:SetVertexColor(urgent.color.r, urgent.color.g, urgent.color.b)
    else
      bombIcon:SetVertexColor(color.r, color.g, color.b)
    end
  end

end

function RefreshAll(self)
  for _, frame in pairs(C_NamePlate.GetNamePlates()) do
    if frame.Trilliax then
      self:Refresh(frame)
    end
  end
end

function Refresh(self, frame)
    local manaText = frame.Trilliax.mana
    local bombIcon = frame.Trilliax.bomb

    manaText:ClearAllPoints()
    bombIcon:ClearAllPoints()


    local font = manaText:GetFont()
    manaText:SetFont(font, _DB.ManaText.size)

    local color = _DB.ManaText.color
    manaText:SetTextColor(color.r, color.g, color.b)

    local anchorFrame = _DB.ManaText.anchorToBombIcon and bombIcon or frame
    manaText:SetPoint(_DB.ManaText.anchorFrom, anchorFrame, _DB.ManaText.anchorTo, _DB.ManaText.offsetX, _DB.ManaText.offsetY)

    bombIcon:SetWidth(_DB.BombIcon.width)
    bombIcon:SetHeight(_DB.BombIcon.height)
    bombIcon:SetPoint(_DB.BombIcon.anchorFrom, frame, _DB.BombIcon.anchorTo, _DB.BombIcon.offsetX, _DB.BombIcon.offsetY)

end

__SlashCmd__ "trilliax" "sim"
__Thread__() __SlashCmd__ "tsc" "sim"
function StartSimulationMode()
  local frame = C_NamePlate.GetNamePlateForUnit("target")
  local guid = UnitGUID("target")
  if frame and frame.Trilliax then
    Warn("Start the simulation mode")
    _Addon:Update("target", frame, guid, true, 0)
    Info("The target has 0 mana")
    Delay(3)
    _Addon:Update("target", frame, guid, true, 20)
    Info("The target has 20 mana")
    Delay(3)
    _Addon:Update("target", frame, guid, true, 40)
    Info("The target has 40 mana")
    Delay(3)
    _Addon:Update("target", frame, guid, true, 60)
    Info("The target has 60 mana")
    Delay(3) -- 4s delay
    _Addon:Update("target", frame, guid, true, 80)
    Info("The target has 80 mana and near exploding")
    Delay(3) -- 4s delay
    _Addon:Update("target", frame, guid, true, 100)
    Info("The target has 100 mana and will explode")
    Delay(3)
    frame.Trilliax.mana:Hide()
    frame.Trilliax.bomb:Hide()
    Warn("The simulation mode is ended")
  end

end

local inConfigMode = false
__SlashCmd__ "trilliax" "config"
__SlashCmd__ "tsc" "config"
function ToggleConfigMode()
  inConfigMode = not inConfigMode

  if inConfigMode then _Addon:StartConfigMode() else _Addon:StopConfigMode() end
end


function StartConfigMode(self)
  for _, frame in pairs(C_NamePlate.GetNamePlates()) do
    if frame.Trilliax then
      frame.Trilliax.mana:Show()
      frame.Trilliax.bomb:Show()
    end
  end

  _InfoBox:Show()
end

function StopConfigMode(self)
  for _, frame in pairs(C_NamePlate.GetNamePlates()) do
    if frame.Trilliax then
      frame.Trilliax.mana:Hide()
      frame.Trilliax.bomb:Hide()
    end
  end

  _InfoBox:Hide()
end
