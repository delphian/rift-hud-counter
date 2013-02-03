
HUDCounter.Rows = {}
HUDCounter.Rows.Event = {}
HUDCounter.Rows.History = {}
HUDCounter.Rows.DefaultConfig = {
  -- Enable any achievements on the HUD.
  enableAchievement = true,
  enableCurrency = true,
  enableItem = true,
  -- Ignore achievements in this table. Do not display.
  ignore = {},
  -- Assign a special area where achievements in this table will always be
  -- displayed.
  watch = {},
  -- Keep track of the current last displayed achievement.
  current = nil,
  -- Queue up achievements for display.
  queue = {},
  -- Delay in seconds before displaying the next achievement in queue.
  delay = 5,
  -- Height of each row
  rowHeight = 55,
  rowFade = 0.50,
  rowFadeWatch = 0.25,
  rowFadeDelay = 2.0,
  rowAlpha = 0.50,
  rowR = 0.75,
  rowG = 0.75,
  rowB = 1,
  -- Font size for description
  rowFontSize = 22,
  fontColorR = 1,
  fontColorG = 1,
  fontColorB = 1,
  -- Size of rows.
  winWidth = 500,
  winAlpha = 0,
  -- Enable the border
  enableBorder = false,
  -- Debugging.
  debug = false,
}

--
-- Initialize achievement configuration and event handling.
--
-- @return
--   (nil)
-- @todo Load in configuration from storage.
--
function HUDCounter.Rows:init(window, content)
  -- Save the reference to window
  self.window = window
  self.content = content

  -- Container to be keyed by achievement id the value of which will hold a
  -- row table. The row table will contain an icon and a text description.
  self.rows = {}

  self.UI = {}

  self.window:SetWidth(self.Config.winWidth)
  self.content:SetWidth(self.Config.winWidth)
  self.window.background:SetAlpha(self.Config.winAlpha)
  if (self.Config.enableBorder == false) then
    self.window.borderTop:SetAlpha(0)
    self.window.borderBottom:SetAlpha(0)
    self.window.borderLeft:SetAlpha(0)
    self.window.borderRight:SetAlpha(0)
  end

  -- Register callbacks.
  table.insert(Command.Slash.Register("hud"), {HUDCounter.Rows.Event.Slash, "HUDCounter", "Slash Command"})
  table.insert(Event.Achievement.Update, {HUDCounter.Rows.Event.Update, "HUDCounter", "Handle Achievement Update"})
  table.insert(Event.Item.Update, {HUDCounter.Rows.Event.ItemUpdate, "HUDCounter", "Handle Item Updates"})
  table.insert(Event.System.Update.Begin, {HUDCounter.Rows.Event.SystemUpdateBegin, "HUDCounter", "Handle Timer"})
  table.insert(Event.Currency, {HUDCounter.Rows.Event.Currency, "HUDCounter", "Handle Currency Update"})
  table.insert(Event.Item.Slot, {HUDCounter.Rows.Event.ItemSlot, "HUDCounter", "Handle Item Slot Updates"})
end

--
-- Save all configuration variables.
--
-- @see table.insert(Event.Addon.SavedVariables.Load.Begin)
--
function HUDCounter.Rows.ConfigSave()
  HUDCounterRowsConfig = HUDCounter.Rows.Config
  HUDCounterRowsHistory = self.History
end

--
-- Load all configuration variables.
--
-- @see table.insert(Event.Addon.SavedVariables.Load.Begin)
--
function HUDCounter.Rows.ConfigLoad()
  if (not PHP.empty(HUDCounterRowsConfig)) then
    print("Loading saved configuration")
    HUDCounter.Rows.Config = HUDCounterRowsConfig
  else
    print("Loading default configuration")
    HUDCounter.Rows.Config = HUDCounter.Rows.DefaultConfig
  end
  if (not PHP.empty(HUDCounterRowsHistory)) then
    HUDCounter.Rows.History = HUDCounterRowsHistory
  end
end

--
-- Display a single row.
--
-- Sets the row height, font and image sizes, then switches visible to true.
--
-- @param int index
--   The row index to show.
--
function HUDCounter.Rows:ShowRow(index)
  local row = self.rows[index]
  -- If the new row height is greater or lesser then the old then adjust
  -- container windows.
  local newHeight = (self.Config.rowHeight - row.icon:GetHeight())
  if (newHeight ~= 0) then
    self.window:SetHeight(self.window:GetHeight() + newHeight)
    self.content:SetHeight(self.content:GetHeight() + newHeight)
  end
  row.Content:SetHeight(self.Config.rowHeight)
  row.Background:SetBackgroundColor(
    self.Config.rowR,
    self.Config.rowG,
    self.Config.rowB,
    self.Config.rowAlpha
  )
  -- Icon.
  row.icon:SetWidth(self.Config.rowHeight)
  -- Description field.
  row.text:SetPoint("TOPLEFT", row.Content, "TOPLEFT", row.icon:GetWidth(), 0)
  row.text:SetWordwrap(true)
  row.text:SetFontSize(self.Config.rowFontSize)
  row.text:SetFontColor(self.Config.fontColorR, self.Config.fontColorG, self.Config.fontColorB, 1)
  -- Show windows.
  row.Content:SetVisible(true)
end

--
-- Remove and redraw all achievement monitor rows in the HUD window. This will
-- adjust the height of the window to faciliate achievement rows.
--
-- @param Frame window
--   The frame to adjust and insert achievement monitor rows into.
--
function HUDCounter.Rows:Redraw()
  self.window.borderTop:SetAlpha(self.Config.enableBorder and 1 or 0)
  self.window.borderBottom:SetAlpha(self.Config.enableBorder and 1 or 0)
  self.window.borderLeft:SetAlpha(self.Config.enableBorder and 1 or 0)
  self.window.borderRight:SetAlpha(self.Config.enableBorder and 1 or 0)
  -- Initially set all rows to invisible and shrink container window.
  for key, value in ipairs(self.rows) do
    if (self.rows[key].Content:GetVisible() == true) then
      self.rows[key].Content:SetVisible(false)
      self.rows[key].achId = nil
      self.window:SetHeight(self.window:GetHeight() - self.Config.rowHeight)
      self.content:SetHeight(self.content:GetHeight() - self.Config.rowHeight)
    end
  end
  -- Return right now if HUD Achievements is disabled.
  if (self.Config.enable == false) then
    return
  end
  -- Create update row or visually enable it if it already exists. Index 1 will always
  -- be used as the row to display recently triggered achievement updates.
  if (self.rows[1] == nil) then
    self.rows[1] = self:DrawRow(self.content, 1)
    bugFix = self.rows[1].icon
    function bugFix.Event:MouseIn()
      if (HUDCounter.Rows:IdType(HUDCounter.Rows.rows[1].achId) == "item") then
        Command.Tooltip(HUDCounter.Rows.rows[1].achId)
      end
    end
    function bugFix.Event:MouseOut()
      Command.Tooltip(nil)
    end
    function bugFix.Event:LeftClick()
      HUDCounter.Rows:Watch(HUDCounter.Rows.rows[1].achId)
      HUDCounter.Rows:Redraw()
    end
  end
  self:ShowRow(1)
  -- Increase the containing window size for the above row.
  self.window:SetHeight(self.window:GetHeight() + self.Config.rowHeight)
  self.content:SetHeight(self.content:GetHeight() + self.Config.rowHeight)
  -- Setup any rows for achievements that are being specifically watched.
  local index = 2
  for key, value in pairs(self.Config.watch) do
    -- If the row table does not exist then create it.
    if (self.rows[index] == nil) then
      self.rows[index] = self:DrawRow(self.content, index)
    end
    self:ShowRow(index)
    self.rows[index].achId = key
    self:Print(key)
    -- Attatch a click handler.
    bugFix = self.rows[index].icon
    bugFix.achId = HUDCounter.Rows.rows[index].achId
    function bugFix.Event:LeftClick()
      HUDCounter.Rows:Watch(self.achId)
      HUDCounter.Rows:Redraw()
    end
    self.window:SetHeight(self.window:GetHeight() + self.Config.rowHeight)
    self.content:SetHeight(self.content:GetHeight() + self.Config.rowHeight)
    index = index + 1
  end
end

--
-- Retrieve an achievement row in the HUD associated with a achievement id.
--
-- @param string achId
--   The achievement id to search for.
--
-- @return
--   (table|nil) The row object if found, nil otherwise.
--
function HUDCounter.Rows:FindRow(achId)
  local Row = nil
  for i=2, PHP.count(self.rows) do
    if (self.rows[i].achId == achId) then
      Row = self.rows[i]
      break
    end
  end
  return Row
end

--
-- Insert a single achievement row into a parent Frame.
--
-- An achievement row is a table which contains 2 frames. The first frame is a
-- texture and will be used to hold the achievement icon. The second frame is
-- a text and will contain the achievement description and requirements.
--
-- @param Frame parentFrame
--   The parent frame for which the icon and text frame will be attatched.
-- @param int offset
--   The row number, counting from the bottom, that this new row should
--   represent. This value will be used as a multiplier to calculate the
--   rows position.
--
-- @return
--   (table) The new row which has been created.
--
function HUDCounter.Rows:DrawRow(parentFrame, index)
  offset = (index or 1) - 1
  offset = (offset * self.Config.rowHeight)
  local Row = {}
  position = { height = self.Config.rowHeight, top = 0, left = 0, right = 0 }
  Row.Content = AOMRift.UI:Content(parentFrame, position, {alpha=0})
  Row.Content:SetLayer(10)
  -- Add our background
  position = {top=0, bottom=0, left=0, right=0}
  background = {red=self.Config.rowR, green=self.Config.rowG, blue=self.Config.rowB, alpha=self.Config.rowAlpha}
  Row.Background = AOMRift.UI:Content(Row.Content, position, background)
  Row.Background:SetLayer(11)
  -- Add our icon
  position = { width = self.Config.rowHeight, top = 0, bottom = 0, left = 0}
  Row.icon = AOMRift.UI:Content(Row.Content, position, {alpha=1}, "Texture")
  Row.icon:SetLayer(12)
  -- Add our text box.
  position = { left = Row.icon:GetWidth(), right = 0, top = 0, bottom = 0 }
  Row.text = AOMRift.UI:Content(Row.Content, position, {alpha=0}, "Text")
  Row.text:SetWordwrap(true)
  Row.text:SetFontSize(self.Config.rowFontSize)
  Row.text:SetLayer(12)
  -- Attatch to bottom of previous row.
  if (index > 1) then
    AOMRift.UI:Attatch(Row.Content, self.rows[index -1].Content, "bottom")
  end
  Row.time = Inspect.Time.Real()  
  return Row
end

--
-- Add or remove an achievement id from ignore list. If the id already exists
-- then it will be removed.
--
-- @param string ach_id
--   The achievement id to remove or add.
--
-- @return
--   (table) A key/value pair of currently ignored ids after the operation.
--
function HUDCounter.Rows:Ignore(ach_id)
  if (ach_id ~= nil) then
    if (self.Config.ignore[ach_id] ~= nil) then
      self.Config.ignore[ach_id] = nil
    else
      self.Config.ignore[ach_id] = ach_id
    end
  end
  return self.Config.ignore
end

--
-- Add or remove an achievement id from display queue. If the id already exists
-- then it will be removed.
--
-- @param string ach_id
--   The achievement id to remove or add.
--
-- @return
--   (table) A key/value pair of currently queued ids after the operation.
--
function HUDCounter.Rows:Queue(id)
  if (id ~= nil) then
    if (self.Config.queue[id] ~= nil) then
      self.Config.queue[id] = nil
    else
      self:UpdateHistory(id)
      self.Config.queue[id] = id
    end
  end
  return self.Config.queue
end

--
-- Add or remove an achievement id from watch list. If the id already exists
-- then it will be removed.
--
-- @param string achId
--   The achievement id to remove or add.
--
-- @return
--   (table) A key/value pair of currently watched ids after the operation.
--
function HUDCounter.Rows:Watch(achId)
  if (achId ~= nil) then
    if (self.Config.watch[achId] ~= nil) then
      self.Config.watch[achId] = nil
    else
      self.Config.watch[achId] = achId
    end
  end
  return self.Config.watch
end

--
-- Process instructions from the command line.
--
-- @param string params
--   Optional parameters typed after the initial slash command.
--
-- @see HUDCounter.Rows.Event.Slash()
--
function HUDCounter.Rows:eventSlash(params)
  local elements = PHP.explode(" ", params)
  if (elements[1] == "") then
    print("\ngit://github.com/delphian/rift-hud-counter.git")
    print("\nCommands:")
    print("/hud ignore {id} (Add id to ignore list)")
    print("/hud watch {id} (Add id to watch row)")
    print("/hud queue {id} (Add id to queue)")
    print("/hud rows (Dump row debug data)")
    print("/hud watch {id} (Add row to watch this id)")
    print("/hud redraw (Redraw the HUD)")
    print("/hud debug (Toggle general debug code.")
    print("/hud achievement (Toggle achievement handling)")
    print("/hud item (Toggle item handling)")
    print("/hud currency (Toggle currency handling)")
    print("/hud winwidth {window width in pixels}")
    print("/hud winborder (Toggle window border)")
    print("/hud winopacity {window opacity} (0.0 - 1.0)")
    print("/hud rowfontsize {font size in pixels}")
    print("/hud rowfontcolor {r} {g} {b} (red, green, blue = 0.0-1.0)")
    print("/hud rowbackcolor {r} {g} {b} (red, green, blue = 0.0-1.0)")
    print("/hud rowopacity {opacity} (0.0 - 1.0)")
    print("/hud rowheight {height in pixels}")
    print("/hud rowfade {opacity} (0.0-1.0, fade active row to this)")
    print("/hud rowfadewatch {opacity} (0.0-1.0 fade watch row to this)")
    print("/hud save (Save configuration variables)")
    print("/hud reset {config} (Resets counters, or configuration")
  elseif (elements[1] == "debug") then
    if (self.Config.debug == true) then
      self.Config.debug = false
      print("Debug disabled.")
    else
      self.Config.debug = true
      print("Debug enabled.")
    end
  elseif (elements[1] == "ignore") then
    achIds = HUDCounter.Rows:Ignore(elements[2])
    dump(achIds)
  elseif (elements[1] == "watch") then
    achIds = HUDCounter.Rows:Watch(elements[2])
    dump(achIds)
  elseif (elements[1] == "queue") then
    achIds = HUDCounter.Rows:Queue()
    PHP.print_r(achIds)
  elseif (elements[1] == "redraw") then
    print("Redrawing achievement rows...")
    self:Redraw()
  elseif (elements[1] == "achievement") then
    if (self.Config.enableAchievement == true) then
      self.Config.enableAchievement = false
      print("HUD Achievements disabled.")
    else
      self.Config.enableAchievement = true
      print("HUD Achievements enabled.")
    end
  elseif (elements[1] == "item") then
    if (self.Config.enableItem == true) then
      self.Config.enableItem = false
      print("HUD Items disabled.")
    else
      self.Config.enableItem = true
      print("HUD Items enabled.")
    end
  elseif (elements[1] == "currency") then
    if (self.Config.enableCurrency == true) then
      self.Config.enableCurrency = false
      print("HUD Currency disabled.")
    else
      self.Config.enableCurrency = true
      print("HUD Currency enabled.")
    end
  elseif (elements[1] == "rows") then
    PHP.print_r(self.rows)
    PHP.print_r(Event)
  -- Window related commands.
  elseif (elements[1] == "winborder") then
    if (self.Config.enableBorder == true) then
      self.Config.enableBorder = false
    else
      self.Config.enableBorder = true
    end
    self:Redraw()
  elseif (elements[1] == "winwidth") then
    if (elements[2] ~= nil) then
      self.window:SetWidth(tonumber(elements[2]))
      self.content:SetWidth(tonumber(elements[2]))
    end
    print(self.Config.window:GetWidth())
  elseif (elements[1] == "winopacity") then
    if (elements[2] ~= nil) then
      self.window.background:SetAlpha(tonumber(elements[2]))
    end
    print(self.window.background:GetAlpha())
  -- Row related commands.
  elseif (elements[1] == "rowfontsize") then
    if (elements[2] ~= nil) then
      self.Config.rowFontSize = tonumber(elements[2])
    end
    print(self.Config.rowFontSize)
    self:Redraw()
  elseif (elements[1] == "rowheight") then
    if (elements[2] ~= nil) then
      self.Config.rowHeight = tonumber(elements[2])
    end
    print(self.Config.rowHeight)
    self:Redraw()
  elseif (elements[1] == "rowopacity") then
    if (elements[2] ~= nil) then
      self.Config.rowAlpha = tonumber(elements[2])
      self:Redraw()
    end
    print(self.Config.rowAlpha)
  elseif (elements[1] == "rowfade") then
    if (elements[2] ~= nil) then
      self.Config.rowFade = tonumber(elements[2])
    end
    print(self.Config.rowFade)
  elseif (elements[1] == "rowfadewatch") then
    if (elements[2] ~= nil) then
      self.Config.rowFadeWatch = tonumber(elements[2])
    end
    print(self.Config.rowFadeWatch)
  elseif (elements[1] == "rowfontcolor") then
    if (elements[2] ~= nil and elements[3] ~= nil and elements[4] ~= nil) then
      self.Config.fontColorR = tonumber(elements[2])
      self.Config.fontColorG = tonumber(elements[3])
      self.Config.fontColorB = tonumber(elements[4])
      self:Redraw()
    end
    print("Red: " .. self.Config.fontColorR .. ", " ..
          "Green: " .. self.Config.fontColorG .. ", " ..
          "Blue: " .. self.Config.fontColorB)
  elseif (elements[1] == "rowbackcolor") then
    if (elements[2] ~= nil and elements[3] ~= nil and elements[4] ~= nil) then
      self.Config.rowR = tonumber(elements[2])
      self.Config.rowG = tonumber(elements[3])
      self.Config.rowB = tonumber(elements[4])
      self:Redraw()
    end
    print("Red: " .. self.Config.rowR .. ", " ..
          "Green: " .. self.Config.rowG .. ", " ..
          "Blue: " .. self.Config.rowB)
  elseif (elements[1] == "save") then
    self:ConfigSave()
  elseif (elements[1] == "reset") then
    if (elements[2] == "config") then
      self.Config = self.DefaultConfig
    else
      self.History = {}
    end
  else
    print("Unknown command.")
  end
end

--
-- Construct description text for achievement update.
--
-- @param string achId
--   The achievement id or achievement object to construct description from.
--
-- @return
--   (string) Description for achievement.
--
function HUDCounter.Rows:makeDescription(achId)
  local achievement = achId
  if (type(achId) ~= table) then
    achievement = AOMRift.Achievement:load(achId)
  end
  local achText = achievement.category.name .. ": " .. achievement.name .. ": "
  -- Output the requirements.
  for req_key, req_value in ipairs(achievement:get_incomplete()) do
    req = achievement:get_req(req_key)
    req_history = self.History[achId]:get_req(req_key)
    if (self.Config.debug == true) then
      PHP.print_r(req)
    end
    achText = achText .. req.name .. ": " .. req.done .. "/" .. req.total .. " (" .. ((req.done - req_history.done) + 1) .. ")"
  end
  return achText  
end

--
-- Determine the type based on an id number.
--
function HUDCounter.Rows:IdType(id)
  local idType = nil
  if (type(id) == "string") then
    if (id == "coin") then
      idType = "coin"
    elseif (string.sub(id, 1, 1) == "i") then
      idType = "item"
    elseif (string.sub(id, 1, 1) == "c") then
      idType = "achievement"
    elseif (string.sub(id, 1, 1) == "I") then
      idType = "currency"
    end
  end
  if (self.Config.debug == true) then
    print(id .. " is " .. (idType or "nil"))
  end    
  return idType
end

--
-- Record items if this is the first time they have been aquired since
-- the last counter reset.
--
function HUDCounter.Rows:UpdateHistory(id)
  if (self.History[id] == nil) then
    local idType = self:IdType(id)
    if (idType == "item") then
      self.History[id] = AOMRift.Item:Load(id)
    elseif ((idType == "currency") or (idType == "coin")) then
      self.History[id] = AOMRift.Currency:load(id)
    elseif (idType == "achievement") then
      self.History[id] = AOMRift.Achievement:load(id)
    end
  end
end

--
-- Print to one of our rows.
--
-- @param string|int id
--
function HUDCounter.Rows:Print(id)
  local object = nil
  local description = nil
  if (self:IdType(id) == "item") then
    object = AOMRift.Item:Load(id);
    if (object ~= nil) then
      description = object.name .. ": " .. object.value
    end
  elseif (self:IdType(id) == "achievement") then
    object = AOMRift.Achievement:load(id)
    if (object ~= nil) then
      description = self:makeDescription(id)
    end
  elseif ((self:IdType(id) == "currency") or (self:IdType(id) == "coin")) then
    object = AOMRift.Currency:load(id)
    if (object ~= nil) then
      description = object.name .. ": " .. object.value .. " ("
        .. (object.value - self.History[id].value) .. ")"
    end
  end
  if (self.Config.debug == true) then
    print("----------------------------------------")
    PHP.print_r(object)
  end

  if (object ~= nil) then
    local row = self:FindRow(id)
    if (row == nil) then
      row = self.rows[1]
    end
    row.time = Inspect.Time.Real()
    row.Content:SetAlpha(1)
    row.Background:SetAlpha(self.Config.rowAlpha)
    row.icon:SetTexture("Rift", object.icon)
    row.text:SetText(description)
    row.achId = id
  else
    print("Unknown id: " .. id)
  end
end

--
-- Callback for System.Update.Begin
--
-- Fades an achievement row if it has been displayed long enough.
--
-- @see HUDCounter.Rows.Event.SystemUpdateBegin()
--
function HUDCounter.Rows:EventSystemUpdateBegin()
  local currentTime = Inspect.Time.Real()
  for key, Row in pairs(self.rows) do
    if (currentTime > (Row.time + self.Config.rowFadeDelay)) then
      local currentAlpha = Row.Content:GetAlpha()
      if (key == 1 and currentAlpha > self.Config.rowFade) then
        Row.Content:SetAlpha(currentAlpha - 0.01)
      end
      if (key > 1 and currentAlpha > self.Config.rowFadeWatch) then
        Row.Content:SetAlpha(currentAlpha - 0.01)
      end
    end
    if (currentTime > (Row.time + 4)) then
      -- Print a new achievement if one is in the queue.
      if (key == 1) then
        for id, data in pairs(self.Config.queue) do
          self:Queue(id)
          self:Print(data)
          break
        end
      end
    end
  end  
end

--
-- Callback for System.Update.Begin
--
function HUDCounter.Rows.Event.SystemUpdateBegin()
  HUDCounter.Rows:EventSystemUpdateBegin()
end

--
-- Callback for Command.Slash.Register("hudach")
--
function HUDCounter.Rows.Event.Slash(params)
  HUDCounter.Rows:eventSlash(params)
end

--
-- Callback for Event.Rows.Update
--
function HUDCounter.Rows.Event.Update(achievements)
  if (HUDCounter.Rows.Config.enableAchievement == false) then
    return
  end
  if (PHP.count(achievements) <= 10) then
    for achievement_key, v in pairs(achievements) do
      local achievement = AOMRift.Achievement:load(achievement_key)
      if ((not achievement.complete) and achievement.current and (PHP.count(achievement.requirement) == 1)) then
        HUDCounter.Rows:Queue(achievement.id)
      end
    end
  end
end

function HUDCounter.Rows.Event.ItemSlot(params)
  if (HUDCounter.Rows.Config.enableItem == false) then
    return
  end
  if (PHP.count(params) <= 3) then
    for key, item_id in pairs(params) do
      if (type(item_id) == "string") then
        HUDCounter.Rows:Queue(item_id)
      else
        print("Item Slot id is not a string: " .. type(item_id))
      end
    end
  end
end

function HUDCounter.Rows.Event.ItemUpdate(params)
  if (HUDCounter.Rows.Config.enableItem == false) then
    return
  end
  if (PHP.count(params) <= 3) then
    for key, item_id in pairs(params) do
      if (type(item_id) == "string") then
        HUDCounter.Rows:Queue(item_id)
      else
        print("Item id is not a string: " .. type(item_id))
      end
    end
  end
end

function HUDCounter.Rows.Event.Currency(params)
  if (HUDCounter.Rows.Config.enableCurrency == false) then
    return
  end
  if (PHP.count(params) <= 3) then
    for currency_id, value in pairs(params) do
      HUDCounter.Rows:Queue(currency_id)
    end
  end
end

table.insert(Event.Addon.SavedVariables.Save.Begin, {HUDCounter.Rows.ConfigSave, "HUDCounter", "Save variables"})
table.insert(Event.Addon.SavedVariables.Load.End, {HUDCounter.Rows.ConfigLoad, "HUDCounter", "Load variables"})
