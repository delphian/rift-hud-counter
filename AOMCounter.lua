-- API Reference Material:
-- http://pastebin.com/Ra9pix1k
-- http://www.seebs.net/rift/live/index.html
-- http://wiki.riftui.com/Main_Page

-- Window class.
AOMWindow = AOMRift.UI:window("title", 300, 290)
function AOMWindow:Init()
  function self.frame.Event:LeftClick()
     print("Got it!")
  end
  self.currencyName = UI.CreateFrame("Text", "Currency", self.frame) 
  self.currencyName:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, 2)
  self.currencyName:SetVisible(true)
  self.currencyTotal = UI.CreateFrame("Text", "Total", self.frame) 
  self.currencyTotal:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 150, 2)
  self.currencyTotal:SetVisible(true)
  self.currencyChange = UI.CreateFrame("Text", "Change", self.frame) 
  self.currencyChange:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 215, 2)
  self.currencyChange:SetVisible(true)
end

-- Main class.
AOMCounter = {
  Coin = {},
  -- Callbacks for all registered events.
  Event = {},
  Currencies = {},
}
-- Update the Currency textbox.
function AOMCounter:PrintCurrency()
  local textName = ""
  local textChange = ""
  local textTotal = ""
  local percent = 0
  local change = 0
  -- Currency.
  local currencies = Inspect.Currency.List()
  for k,v in pairs(currencies) do
    detail = Inspect.Currency.Detail(k);
    change = v - AOMCounter.Currencies[k]
    textName = textName .. detail.name .. "\n"
    textChange = textChange .. change .. "\n" 
    textTotal = textTotal .. v .. "\n"
  end
  -- Attunement.
  textName = textName .. "PA Experience" .. "\n"
  textChange = textChange .. AOMCounter.Attunement.pctChange .. "%\n"
  textTotal = textTotal .. AOMCounter.Attunement.pctTotal .. "%\n"
  -- Experience
  textName = textName .. "Experience" .. "\n"
  textChange = textChange .. AOMCounter.Experience.pctChange .. "%\n"
  textTotal = textTotal .. AOMCounter.Experience.pctTotal .. "%\n"
  AOMWindow.currencyName:SetText(textName)
  AOMWindow.currencyTotal:SetText(textTotal)
  AOMWindow.currencyChange:SetText(textChange)
end
-- Get the platinum portion of gathered coin.
function AOMCounter.Coin:Platinum(amount)
  platinum = 0;
  if amount > 9999 then
    platinum = math.modf(amount / 10000);
    platinum = platinum % 100;
  end
  return platinum;
end
-- Get the gold portion of gathered coin.
function AOMCounter.Coin:Gold(amount)
  gold = 0;
  if amount > 99 then
    gold = math.modf(amount / 100);
    gold = gold % 100;
  end
  return gold;
end
-- Get the silver portion of gathered coin.
function AOMCounter.Coin:Silver(amount)
  silver = 0
  if (amount > 0) then
    silver = amount % 100;
  end
  return silver;
end
-- Get the percent of coin compared to total carried coin.
function AOMCounter.Coin:Percent(amount)
  local percent = AOM.Math:round((amount / self.carried) * 100, 2)
  return percent
end

-- Callback for Command.Slash.Register
-- Process slash commands from the chat command line.
function AOMCounter.Event.SlashHandler(params)
  if params == "" then
    AOMCounter:PrintCurrency()
  end
  if params == "reset" then
    AOMCounter.Currencies = Inspect.Currency.List()
    AOMCounter:PrintCurrency()
  end
end
-- Callback for Event.Currency
-- Update our currency counter when user has picked up more coin.
function AOMCounter.Event.Currency(currencies)
  AOMCounter:PrintCurrency()
end
-- Callback for Event.Attunement.Progress.Accumulated
-- Update our attunment counter when user has recieved more attunement experience.
function AOMCounter.Event.Attunement()
  local attunement = Inspect.Attunement.Progress()
  local percent = (attunement.accumulated / attunement.needed) * 100  
  local change = percent - ((AOMCounter.Attunement.accumulated / AOMCounter.Attunement.needed) * 100)
  -- If change percent is negative then we just gained a level. Reset counter.
  if change < 0 then
    AOMCounter.Attunement = Inspect.Attunement.Progress()
    change = 0
  end
  AOMCounter.Attunement.pctTotal = AOM.Math:round(percent, 1)
  AOMCounter.Attunement.pctChange = AOM.Math:round(change, 1)
  AOMCounter:PrintCurrency()
end
-- Callback for Event.Experience.Accumulated
-- Update our experience counter when user has received more experience.
function AOMCounter.Event.Experience()
  local experience = Inspect.Experience()
  local percent = AOM.Math:round((experience.accumulated / experience.needed) * 100, 1)
  local change = percent - AOM.Math:round((AOMCounter.Experience.accumulated / AOMCounter.Experience.needed) * 100, 1)
  -- If change percent is negative then we just gained a lavel. Reset counter.
  if change < 0 then
    AOMCounter.Experience = Inspect.Experience()
    change = 0
  end
  AOMCounter.Experience.pctTotal = AOM.Math:round(percent, 1)
  AOMCounter.Experience.pctChange = AOM.Math:round(change, 1)
  AOMCounter:PrintCurrency()
end
-- Callback for Event.Addon.Load.End
-- Initialize variables after plugin has been loaded.
function AOMCounter.Event.Init(param)
  -- This callback actually will get fired each time *any* plugin gets
  -- loaded. Make sure to only execute code if the plugin being loaded
  -- is ours.
  if param == "AOMCounter" then
    AOMWindow:Init()
    AOMCounter.Currencies = Inspect.Currency.List()
    AOMCounter.Attunement = Inspect.Attunement.Progress()
    AOMCounter.Attunement.pctTotal = "0.0"
    AOMCounter.Attunement.pctChange = "0.0"
    AOMCounter.Experience = Inspect.Experience()
    AOMCounter.Experience.pctTotal = "0.0"
    AOMCounter.Experience.pctChange = "0.0"
    AOMCounter:PrintCurrency()
    print "AOM Counter loaded."  
  end
end


table.insert(Event.Addon.Load.End, {AOMCounter.Event.Init, "AOMCounter", "Initital Setup"})
table.insert(Command.Slash.Register("aom"), {AOMCounter.Event.SlashHandler, "AOMCounter", "Slash Command"})
table.insert(Event.Currency, {AOMCounter.Event.Currency, "AOMCounter", "Handle Currency Change"})
table.insert(Event.Attunement.Progress.Accumulated, {AOMCounter.Event.Attunement, "AOMCounter", "Handle Attunement Change"})
table.insert(Event.Experience.Accumulated, {AOMCounter.Event.Experience, "AOMCounter", "Handle Experience Change"})
 