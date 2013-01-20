
HUDCounter.Currency = {}
HUDCounter.Currency.Event = {}

--
-- Initialize currency configuration and event handling.
--
-- @return
--   (nil)
-- @todo Load in configuration from storage.
--
function HUDCounter.Currency:init(window, content)
  self.Config = {}
  -- Enable any currencies on the HUD.
  self.Config.enable = true
  -- Save the reference to window
  self.Config.window = window
  self.Config.content = content
  -- Ignore currencies in this table. Do not display.
  self.Config.ignore = {}
  -- Assign a special area where currencies in this table will always be
  -- displayed.
  self.Config.watch = {}
  -- Keep track of the current last displayed currency.
  self.Config.current = nil
  -- Queue up currencies for display.
  self.Config.queue = {}
  -- Delay in seconds before displaying the next currency in queue.
  self.Config.delay = 5
  -- Container to be keyed by currency id the value of which will hold a
  -- row table. The row table will contain an icon and a text description.
  self.Config.rows = {}
  -- Height of each row
  self.Config.iconSize = 60
  -- Font size for description
  self.Config.fontSize = 14  
  -- Debugging.
  self.Config.debug = false

  self.UI = {}

  -- Register callbacks.
  table.insert(Command.Slash.Register("hudcur"), {HUDCounter.Currency.Event.Slash, "HUDCounter", "Slash Command"})
  table.insert(Event.Currency, {HUDCounter.Currency.Event.Update, "HUDCounter", "Handle Currency Update"})
  table.insert(Event.System.Update.Begin, {HUDCounter.Currency.Event.SystemUpdateBegin, "HUDCounter", "Handle Timer"})
end

--
-- Display a single row.
--
-- Sets the row height, font and image sizes, then switches visible to true.
--
-- @param int index
--   The row index to show.
--
function HUDCounter.Currency:ShowRow(index)
  local row = self.Config.rows[index]
  -- If the new row height is greater or lesser then the old then adjust
  -- container windows.
  local newHeight = (self.Config.iconSize - row.icon:GetHeight())
  if (newHeight ~= 0) then
    self.Config.window:SetHeight(self.Config.window:GetHeight() + newHeight)
    self.Config.content:SetHeight(self.Config.content:GetHeight() + newHeight)
  end
  row.Content:SetHeight(self.Config.iconSize)
  -- Icon.
  row.icon:SetWidth(self.Config.iconSize)
  -- Description field.
  row.text:SetWidth(row.Content:GetWidth() - row.icon:GetWidth())
  row.text:SetWordwrap(true)
  row.text:SetFontSize(self.Config.fontSize)
  -- Show windows.
  row.Content:SetVisible(true)
end

--
-- Remove and redraw all currency monitor rows in the HUD window. This will
-- adjust the height of the window to faciliate currency rows.
--
function HUDCounter.Currency:Redraw()
  -- Initially set all rows to invisible and shrink container window.
  for key, value in ipairs(self.Config.rows) do
    if (self.Config.rows[key].icon:GetVisible() == true) then
      self.Config.rows[key].Content:SetVisible(false)
      self.Config.rows[key].achId = nil
      self.Config.window:SetHeight(self.Config.window:GetHeight() - self.Config.iconSize)
      self.Config.content:SetHeight(self.Config.content:GetHeight() - self.Config.iconSize)
    end
  end
  -- Return right now if HUD Currencies is disabled.
  if (self.Config.enable == false) then
    return
  end
  -- Create update row or visually enable it if it already exists. Index 1 will always
  -- be used as the row to display recently triggered currency updates.
  if (self.Config.rows[1] == nil) then
    self.Config.rows[1] = self:DrawRow(self.Config.content, 1)
    if (self.Config.rows[1] == nil) then
      print("Unable to create currency row 1.")
    end
    bugFix = self.Config.rows[1].icon
    function bugFix.Event:LeftClick()
      HUDCounter.Currency:Watch(HUDCounter.Currency.Config.rows[1].id)
      HUDCounter.Currency:Redraw()
    end
  end
  self:ShowRow(1)
  self.Config.window:SetHeight(self.Config.window:GetHeight() + self.Config.iconSize)
  self.Config.content:SetHeight(self.Config.content:GetHeight() + self.Config.iconSize)
  -- Setup any rows for currencies that are being specifically watched.
  local index = 2
  for key, value in pairs(self.Config.watch) do
    -- If the row table does not exist then create it.
    if (self.Config.rows[index] == nil) then
      self.Config.rows[index] = self:DrawRow(self.Config.content, index)
    -- If the row table already exists just make it visible. We are reusing
    -- frames because I have no idea how to remove them.
    end
    self:ShowRow(index)
    local currency = AOMRift.Currency:load(key)
    --self.Config.rows[index].icon:SetTexture("Rift", currency.detail.icon)
    self.Config.rows[index].text:SetText(self:makeDescription(currency.id))
    self.Config.rows[index].id = key
    self.Config.rows[index].icon.id = key
    -- Attatch a click handler.
    bugFix = self.Config.rows[index].icon
    function bugFix.Event:LeftClick()
      HUDCounter.Currency:Watch(self.id)
      HUDCounter.Currency:Redraw()
    end
    self.Config.window:SetHeight(self.Config.window:GetHeight() + self.Config.iconSize)
    self.Config.content:SetHeight(self.Config.content:GetHeight() + self.Config.iconSize)
    index = index + 1
  end
end

--
-- Retrieve a currency row in the HUD associated with a currency id.
--
-- @param string id
--   The currency id to search for.
--
-- @return
--   (table|nil) The row object if found, nil otherwise.
--
function HUDCounter.Currency:FindRow(id)
  local Row = nil
  for i=2, PHP.count(self.Config.rows) do
    if (self.Config.rows[i].id == id) then
      Row = self.Config.rows[i]
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
function HUDCounter.Currency:DrawRow(parentFrame, index)
  offset = (index or 1) - 1
  offset = (offset * self.Config.iconSize)
  local Row = {}
  position = { height = self.Config.iconSize, top = 0, left = 4, right = 4 }
  Row.Content = AOMRift.UI:Content(parentFrame, position, {alpha=0})
  -- Add our icon
  position = { width = self.Config.iconSize, top = 0, bottom = 0, left = 0}
  Row.icon = AOMRift.UI:Content(Row.Content, position, { alpha = 0.75 }, "Texture")
  -- Add our text box.
  position = { width = Row.Content:GetWidth() - Row.icon:GetWidth()}
  Row.text = AOMRift.UI:Content(Row.Content, position, {alpha=0.25}, "Text")
  -- Attatch text box to right side of icon.
  AOMRift.UI:Attatch(Row.text, Row.icon, "right")
  Row.text:SetWordwrap(true)
  Row.text:SetFontSize(self.Config.fontSize)
  -- Attatch to bottom of previous row.
  if (index > 1) then
    AOMRift.UI:Attatch(Row.Content, self.Config.rows[index -1].Content, "bottom")
  end
  Row.time = Inspect.Time.Real()  
  return Row
end

--
-- Add or remove a currency id from ignore list. If the id already exists
-- then it will be removed.
--
-- @param string id
--   The currency id to remove or add.
--
-- @return
--   (table) A key/value pair of currently ignored ids after the operation.
--
function HUDCounter.Currency:Ignore(id)
  if (id ~= nil) then
    if (self.Config.ignore[id] ~= nil) then
      self.Config.ignore[id] = nil
    else
      self.Config.ignore[id] = id
    end
  end
  return self.Config.ignore
end

--
-- Add or remove a currency id from watch list. If the id already exists
-- then it will be removed.
--
-- @param string id
--   The currency id to remove or add.
--
-- @return
--   (table) A key/value pair of currently watched ids after the operation.
--
function HUDCounter.Currency:Watch(id)
  if (id ~= nil) then
    if (self.Config.watch[id] ~= nil) then
      self.Config.watch[id] = nil
    else
      self.Config.watch[id] = id
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
-- @see HUDCounter.Currency.Event.Slash()
--
function HUDCounter.Currency:EventSlash(params)
  local elements = PHP.explode(" ", params)
  if (elements[1] == "") then
    print("HUD Currency commands:")
    print("/hudcur ignore {currency_id}")
    print("  Toggle the ignore status of a currency. List all currencies ignored if no parameter specified.")
    print("/hudcur watch")
    print("  List all watched currency ids. List all currencies watched if no parameter specified.")
    print("/hudcur watch {currency_id}")
    print("  Toggle the watch status of a currency.")
    print("/hudcur redraw")
    print("  Destroy all currency rows in the HUD and redraw.")
    print("/hudcur debug")
    print("  Toggle debug information to console.")
    print("/hudcur enable|disable")
    print("  Enable or disable currencies on HUD.")
    print("/hudcur detail {currency_id}")
    print("  Detail specified currency. List all known currencies if no id is specified.")
    print("/hudcur print {currency_id}")
    print("  Force the HUD to show a currency as if it updated.")
    print("/hudcur icon {icon_path}")
    print("  Force the HUD latest row icon to show an arbitrary icon")
  elseif (elements[1] == "debug") then
    if (self.Config.debug == true) then
      self.Config.debug = false
      print("Currency debug disabled.")
    else
      self.Config.debug = true
      print("Currency debug enabled.")
    end
  elseif (elements[1] == "ignore") then
    ids = self:Ignore(elements[2])
    dump(ids)
  elseif (elements[1] == "watch") then
    ids = self:Watch(elements[2])
    dump(ids)
  elseif (elements[1] == "redraw") then
    print("Redrawing currency rows...")
    self:Redraw()
  elseif (elements[1] == "enable") then
    self.Config.enable = true
    print("HUD Currencies enabled.")
    self:Redraw()
  elseif (elements[1] == "disable") then
    self.Config.enable = false
    print("HUD Currencies disabled.")
    self:Redraw()
  elseif (elements[1] == "detail") then
    if (elements[2] ~= nil) then
      print(PHP.print_r(Inspect.Currency.Detail(elements[2]), true))
    else
      print(PHP.print_r(Inspect.Currency.List(), true))
    end
  elseif (elements[1] == "print") then
    if (AOMRift.Currency.exists(elements[2])) then
      self:Print(elements[2])
    else
      print("Currency does not exist.")
    end
  elseif (elements[1] == "icon") then
    self.Config.rows[1].icon.SetTexture("Rift", elements[2])
  elseif (elements[1] == "iconsize") then
    self.Config.iconSize = tonumber(elements[2])
    self:Redraw()
  elseif (elements[1] == "fontsize") then
    self.Config.fontSize = tonumber(elements[2])
    self:Redraw()
  end
end

--
-- Print a currency to the window.
--
-- @param string currency_id
--   Currency id to update window with.
--
function HUDCounter.Currency:Print(currency_id)
  local currency = AOMRift.Currency:load(currency_id)
  -- If we are watching this currency send it to the correct currency
  -- row in the HUD, otherwise default to the bottom most row.
  local Row = self:FindRow(currency.id) or self.Config.rows[1]
  -- Debug output.
  if (self.Config.debug == true) then
    print("----------------------------------------")
    print(AOMLua:print_r(currency, "Currency " .. currency.id))
  end
  -- Output the currency information.
  if (currency.icon ~= nil) then
    Row.icon:SetTexture("Rift", currency.icon)
  end
  Row.text:SetText(self:makeDescription(currency.id))
  Row.icon:SetAlpha(0.75)
  Row.text:SetAlpha(0.75)
  Row.time = Inspect.Time.Real()
  Row.id = currency.id
end

--
-- Callback for Event.Currency.Update
--
-- Inform the player that they just earned currency.
--
-- @see HUDCounter.Currency.Event.Update()
--
function HUDCounter.Currency:EventUpdate(currencies)
  if (self.Config.enable == false) then
    return
  end
  if (self.Config.debug == true) then
    print("========================================")
  end
  for currency_key, v in pairs(currencies) do
    self:Print(currency_key)
  end
end

--
-- Construct description text for currency update.
--
-- @param string id
--   The currency id or currency object to construct description from.
--
-- @return
--   (string) Description for currency.
--
function HUDCounter.Currency:makeDescription(id)
  local currency = id
  if (type(id) ~= table) then
    currency = AOMRift.Currency:load(id)
  end
  local curText = currency.name .. ": " .. currency.value
  return curText  
end

--
-- Callback for System.Update.Begin
--
-- Fades a currency row if it has been displayed long enough.
--
-- @see HUDCounter.Currency.Event.SystemUpdateBegin()
--
function HUDCounter.Currency:EventSystemUpdateBegin()
  local currentTime = Inspect.Time.Real()
  for key, Row in pairs(self.Config.rows) do
    if (currentTime > (Row.time + 5)) then
      Row.icon:SetAlpha(0.25)
      Row.text:SetAlpha(0.25)
    end
  end  
end

--
-- Callback for System.Update.Begin
--
function HUDCounter.Currency.Event.SystemUpdateBegin()
  HUDCounter.Currency:EventSystemUpdateBegin()
end

--
-- Callback for Event.Currency
--
function HUDCounter.Currency.Event.Update(currencies)
  HUDCounter.Currency:EventUpdate(currencies)
end

--
-- Callback for Command.Slash.Register("hudach")
--
function HUDCounter.Currency.Event.Slash(params)
  HUDCounter.Currency:EventSlash(params)
end
