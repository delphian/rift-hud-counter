
-- Main class.
HUDCounter = {
  UI = {
    lines = nil,
    window = nil,
    text = {},
    achievement = {},
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
    Debug = { achievements = false, },
    Achievement = {
      ignore = {},
      watch = {},
      queue = {},
    },
  },
}

-- Update or initialize experience change.
-- @see HUDCounter.Event.Experience()
function HUDCounter.Experience:update()
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
-- @see HUDCounter.Event.Attunement()
function HUDCounter.Attunement:update()
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
-- @see HUDCounter.Event.Currency()
function HUDCounter.Currency:update()
  if self.last == nil then
    self.last = Inspect.Currency.List() 
  end
end
-- Callback for Event.Experience.
function HUDCounter.Event.Experience()
  HUDCounter.Experience:update()
  HUDCounter:update()
end
-- Callback for Event.Experience.
function HUDCounter.Event.Attunement()
  HUDCounter.Attunement:update()
  HUDCounter:update()
end
-- Callback for Event.Currency
function HUDCounter.Event.Currency(currencies)
  HUDCounter.Currency:update()
  HUDCounter:update()
end

-- Initialize the graphic window.
function HUDCounter.UI:init()
  -- Calculate how tall a window we need. All our currencies will take up
  -- one line each, plus the experiecen and pa experience lines.
  self.lines = AOMMath:count(Inspect.Currency.List()) + 2
  self.window = AOMRift.UI:Window("title", 280, (13 * self.lines))
  function self.window.content.Event:LeftClick()
    print("Got it!")
  end

  HUDCounter.Achievement:Redraw(self.window)

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

-- Initialize HUDCounter.
function HUDCounter:init()
  self.Achievement:init()
  -- Calculate percents and totals to display.
  self.Currency:update()
  self.Experience:update()
  self.Attunement:update()
  -- Initialize window.
  self.UI:init()
  -- Register callbacks.
  table.insert(Event.Experience.Accumulated, {self.Event.Experience, "HUDCounter", "Handle Experience Change"})
  table.insert(Event.Currency, {self.Event.Currency, "HUDCounter", "Handle Currency Change"})
  table.insert(Event.Attunement.Progress.Accumulated, {self.Event.Attunement, "HUDCounter", "Handle Attunement Change"})
  print("AOM Counter loaded. (".._VERSION.."). Type /aom for help.")  
end

-- Reset all the counters.
function HUDCounter:reset()
  self.Experience.last = Inspect.Experience()
  self.Attunement.last = Inspect.Attunement.Progress()
  self.Currency.last = Inspect.Currency.List()
  self.Experience:update()
  self.Attunement:update()
  self.Currency:update()
end
-- Update the window.
function HUDCounter:update()
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
function HUDCounter.Event.SlashHandler(params)
  if params == "" then
    print("/aom init, initialize the counter")
    print("/aom show, show the counter")
    print("/aom reset, reset the counter")
    print("/aom dbgach, debug achievements")
  end
  if params == "resize" then
    AOMRift.UI:resize(HUDCounter.UI.window, 400, 400)
  end
  if params == "init" then
    HUDCounter:init()
    HUDCounter:update()
  end
  if params == "reset" then
    HUDCounter:reset()
    HUDCounter:update()
    print "Counters reset."
  end
  if params == "show" then
    HUDCounter.UI.window:SetVisible(true)
  end
  if params == "debug achievements" or params == "dbgach" then
    if HUDCounter.Config.Debug.achievements == true then
      HUDCounter.Config.Debug.achievements = false
      print("Debugging achievements OFF")
    else
      HUDCounter.Config.Debug.achievements = true
      print("Debugging achievements ON")
    end
  end
end

-- Register callbacks.
table.insert(Command.Slash.Register("aom"), {HUDCounter.Event.SlashHandler, "HUDCounter", "Slash Command"})
