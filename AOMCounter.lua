-- API Reference Material:
-- http://pastebin.com/Ra9pix1k
-- http://www.seebs.net/rift/live/index.html
-- http://wiki.riftui.com/Main_Page

-- Main class.
AOMCounter = {
  UI = {
    lines = nil,
    window = nil,
    text = {},
  },
  Event = {},
  Currency = {
    last = nil,
  },
  Attunement = {
    last = nil,
    pctTotal = 0,
    pctChange = 0,
  },
  Experience = {
    last = nil,
    pctTotal = 0,
    pctChange = 0,
  },
  Config = {
    Debug = { achievements = false, }
  }
}

-- Update or initialize experience change.
-- @see AOMCounter.Event.Experience()
function AOMCounter.Experience:update()
  if self.last == nil then
    self.last = Inspect.Experience()
  end
  local experience = Inspect.Experience()
  local percent = (experience.accumulated / experience.needed) * 100
  local change = percent - ((self.last.accumulated / self.last.needed) * 100)
  -- If change percent is negative then we just gained a lavel. Reset counter.
  if change < 0 then
    self.last = Inspect.Experience()
    change = 0
  end
  self.pctTotal = AOMMath:round(percent, 1)
  self.pctChange = AOMMath:round(change, 1)
end
-- Update or initialize attunement change.
-- @see AOMCounter.Event.Attunement()
function AOMCounter.Attunement:update()
  if self.last == nil then
    self.last = Inspect.Attunement.Progress()
  end
  local attunement = Inspect.Attunement.Progress()
  local percent = (attunement.accumulated / attunement.needed) * 100
  local change = percent - ((self.last.accumulated / self.last.needed) * 100)
  -- If change percent is negative then we just gained a lavel. Reset counter.
  if change < 0 then
    self.last = Inspect.Attunement.Progress()
    change = 0
  end
  self.pctTotal = AOMMath:round(percent, 1)
  self.pctChange = AOMMath:round(change, 1)
end
-- Update or initialize currency change.
-- @see AOMCounter.Event.Currency()
function AOMCounter.Currency:update()
  if self.last == nil then
    self.last = Inspect.Currency.List() 
  end
end
-- Callback for Event.Experience.
function AOMCounter.Event.Experience()
  AOMCounter.Experience:update()
  AOMCounter:update()
end
-- Callback for Event.Experience.
function AOMCounter.Event.Attunement()
  AOMCounter.Attunement:update()
  AOMCounter:update()
end
-- Callback for Event.Currency
function AOMCounter.Event.Currency(currencies)
  AOMCounter.Currency:update()
  AOMCounter:update()
end

-- Initialize the graphic window.
function AOMCounter.UI:init()
  -- Calculate how tall a window we need. All our currencies will take up
  -- one line each, plus the experiecen and pa experience lines.
  self.lines = AOMMath:count(Inspect.Currency.List()) + 2
  self.window = AOMRift.UI:Window("title", 280, (13 * self.lines))
  function self.window.content.Event:LeftClick()
    print("Got it!")
  end
  self.text.name = UI.CreateFrame("Text", "Currency", self.window.content) 
  self.text.name:SetPoint("TOPLEFT", self.window.content, "TOPLEFT", 2, 2)
  self.text.name:SetVisible(true)
  self.text.total = UI.CreateFrame("Text", "Total", self.window.content) 
  self.text.total:SetPoint("TOPLEFT", self.window.content, "TOPLEFT", 150, 2)
  self.text.total:SetVisible(true)
  self.text.change = UI.CreateFrame("Text", "Change", self.window.content) 
  self.text.change:SetPoint("TOPLEFT", self.window.content, "TOPLEFT", 215, 2)
  self.text.change:SetVisible(true)
end

-- Initialize AOMCounter.
function AOMCounter:init()
  -- Calculate percents and totals to display.
  self.Currency:update()
  self.Experience:update()
  self.Attunement:update()
  -- Initialize window.
  self.UI:init()
  -- Register callbacks.
  table.insert(Event.Experience.Accumulated, {self.Event.Experience, "AOMCounter", "Handle Experience Change"})
  table.insert(Event.Currency, {self.Event.Currency, "AOMCounter", "Handle Currency Change"})
  table.insert(Event.Attunement.Progress.Accumulated, {self.Event.Attunement, "AOMCounter", "Handle Attunement Change"})
  print "AOM Counter loaded."  
end

-- Reset all the counters.
function AOMCounter:reset()
  self.Experience.last = Inspect.Experience()
  self.Attunement.last = Inspect.Attunement.Progress()
  self.Currency.last = Inspect.Currency.List()
  self.Experience:update()
  self.Attunement:update()
  self.Currency:update()
end
-- Update the window.
function AOMCounter:update()
  local tName = ""
  local tTotal = ""
  local tChange = ""
  local percent = 0
  local change = 0
  -- Currency.
  local currencies = Inspect.Currency.List()
  for k,v in pairs(currencies) do
    detail = Inspect.Currency.Detail(k)
    change = v - self.Currency.last[k]
    tName = tName .. detail.name .. "\n"
    tChange = tChange .. change .. "\n" 
    tTotal = tTotal .. v .. "\n"
  end
  -- Attunement.
  tName = tName .. "PA Experience" .. "\n"
  tChange = tChange .. self.Attunement.pctChange .. "%\n"
  tTotal = tTotal .. self.Attunement.pctTotal .. "%\n"
  -- Experience
  tName = tName .. "Experience" .. "\n"
  tChange = tChange .. self.Experience.pctChange .. "%\n"
  tTotal = tTotal .. self.Experience.pctTotal .. "%\n"
  -- Update the actual window with the new text.
  self.UI.text.name:SetText(tName)
  self.UI.text.total:SetText(tTotal)
  self.UI.text.change:SetText(tChange)
end

-- Callback for Command.Slash.Register
-- Process slash commands from the chat command line.
function AOMCounter.Event.SlashHandler(params)
  if params == "init" then
    AOMCounter:init()
    AOMCounter:update()
  end
  if params == "reset" then
    AOMCounter:reset()
    AOMCounter:update()
    print "Counters reset."
  end
  if params == "debug achievements" or params == "dbgach" then
    if AOMCounter.Config.Debug.achievements == true then
      AOMCounter.Config.Debug.achievements = false
      print("Debugging achievements OFF")
    else
      AOMCounter.Config.Debug.achievements = true
      print("Debugging achievements ON")
    end
  end
end

-- Callback for Event.Achievement.Update
-- Inform the player that they just performed an action that increased their
-- progress in an achievement.
function AOMCounter.Event.Achievement(achievements)
  -- Count each achievement. Limit maximum processed.
  local maxcount = 0
  if (AOMCounter.Config.Debug.achievements == true) then
    print("========================================")
  end
  for achievement_key, v in pairs(achievements) do
    -- Place a cap on how many achievements we will do. The rest get ignored, sorry.
    if (maxcount >= 10) then
      break;
    end
    maxcount = maxcount + 1
    local achievement = AOMRift.Achievement:load(achievement_key)
    if ((not achievement.complete) and achievement.current and (AOMMath:count(achievement.requirement) == 1)) then
      -- Debug output. 
      if (AOMCounter.Config.Debug.achievements == true) then
        print("----------------------------------------")
        print(AOMLua:print_r(achievement, "Achievement " .. achievement.id))
      end
      -- Output the achievement information.
      print(achievement.category.name .. ": " .. achievement.name .. ": " .. achievement.description)
      -- Output the requirements.    
      for req_key, req_value in ipairs(achievement:get_incomplete()) do
        req = achievement:get_req(req_key)
        if (AOMCounter.Config.Debug.achievements == true) then
          print(AOMLua:print_r(req, "Requirement"))
        end
        print("  " .. req.type .. ": " .. req.name .. " (" .. req.done .. "/" .. req.total .. ")")
      end 
    end
  end
end

-- Register callbacks.
table.insert(Command.Slash.Register("aom"), {AOMCounter.Event.SlashHandler, "AOMCounter", "Slash Command"})
table.insert(Event.Achievement.Update, {AOMCounter.Event.Achievement, "AOMCounter", "Handle Achievement Change"})
 