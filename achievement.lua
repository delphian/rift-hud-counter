
HUDCounter.Achievement = {}
HUDCounter.Achievement.Event = {}

--
-- Initialize achievement configuration and event handling.
--
-- @return
--   (nil)
-- @todo Load in configuration from storage.
--
function HUDCounter.Achievement:init(window, content)
  self.Config = {}
  -- Enable any achievements on the HUD.
  self.Config.enable = true
  -- Save the reference to window
  self.Config.window = window
  self.Config.content = content
  -- Ignore achievements in this table. Do not display.
  self.Config.ignore = {}
  -- Assign a special area where achievements in this table will always be
  -- displayed.
  self.Config.watch = {}
  -- Keep track of the current last displayed achievement.
  self.Config.current = nil
  -- Queue up achievements for display.
  self.Config.queue = {}
  -- Delay in seconds before displaying the next achievement in queue.
  self.Config.delay = 5
  -- Container to be keyed by achievement id the value of which will hold a
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
  table.insert(Command.Slash.Register("hudach"), {HUDCounter.Achievement.Event.Slash, "HUDCounter", "Slash Command"})
  table.insert(Event.Achievement.Update, {HUDCounter.Achievement.Event.Update, "HUDCounter", "Handle Achievement Update"})
  table.insert(Event.System.Update.Begin, {HUDCounter.Achievement.Event.SystemUpdateBegin, "HUDCounter", "Handle Timer"})
end

--
-- Display a single row.
--
-- Sets the row height, font and image sizes, then switches visible to true.
--
-- @param int index
--   The row index to show.
--
function HUDCounter.Achievement:ShowRow(index)
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
-- Remove and redraw all achievement monitor rows in the HUD window. This will
-- adjust the height of the window to faciliate achievement rows.
--
-- @param Frame window
--   The frame to adjust and insert achievement monitor rows into.
--
function HUDCounter.Achievement:Redraw()
  -- Initially set all rows to invisible and shrink container window.
  for key, value in ipairs(self.Config.rows) do
    if (self.Config.rows[key].icon:GetVisible() == true) then
      self.Config.rows[key].Content:SetVisible(false)
      self.Config.rows[key].achId = nil
      self.Config.window:SetHeight(self.Config.window:GetHeight() - self.Config.iconSize)
      self.Config.content:SetHeight(self.Config.content:GetHeight() - self.Config.iconSize)
    end
  end
  -- Return right now if HUD Achievements is disabled.
  if (self.Config.enable == false) then
    return
  end
  -- Create update row or visually enable it if it already exists. Index 1 will always
  -- be used as the row to display recently triggered achievement updates.
  if (self.Config.rows[1] == nil) then
    self.Config.rows[1] = self:DrawRow(self.Config.content, 1)
    bugFix = self.Config.rows[1].icon
    function bugFix.Event:LeftClick()
      HUDCounter.Achievement:Watch(HUDCounter.Achievement.Config.rows[1].achId)
      HUDCounter.Achievement:Redraw()
    end
  end
  self:ShowRow(1)
  -- Increase the containing window size for the above row.
  self.Config.window:SetHeight(self.Config.window:GetHeight() + self.Config.iconSize)
  self.Config.content:SetHeight(self.Config.content:GetHeight() + self.Config.iconSize)
  -- Setup any rows for achievements that are being specifically watched.
  local index = 2
  for key, value in pairs(self.Config.watch) do
    -- If the row table does not exist then create it.
    if (self.Config.rows[index] == nil) then
      self.Config.rows[index] = self:DrawRow(self.Config.content, index)
    end
    self:ShowRow(index)
    local achievement = AOMRift.Achievement:load(key)
    self.Config.rows[index].icon:SetTexture("Rift", achievement.detail.icon)
    self.Config.rows[index].text:SetText(self:makeDescription(achievement.id))
    self.Config.rows[index].achId = key
    self.Config.rows[index].icon.achId = key
    -- Attatch a click handler.
    bugFix = self.Config.rows[index].icon
    function bugFix.Event:LeftClick()
      HUDCounter.Achievement:Watch(self.achId)
      HUDCounter.Achievement:Redraw()
    end
    self.Config.window:SetHeight(self.Config.window:GetHeight() + self.Config.iconSize)
    self.Config.content:SetHeight(self.Config.content:GetHeight() + self.Config.iconSize)
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
function HUDCounter.Achievement:FindRow(achId)
  local Row = nil
  for i=2, PHP.count(self.Config.rows) do
    if (self.Config.rows[i].achId == achId) then
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
function HUDCounter.Achievement:DrawRow(parentFrame, index)
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
-- Add or remove an achievement id from ignore list. If the id already exists
-- then it will be removed.
--
-- @param string ach_id
--   The achievement id to remove or add.
--
-- @return
--   (table) A key/value pair of currently ignored ids after the operation.
--
function HUDCounter.Achievement:Ignore(ach_id)
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
-- Add or remove an achievement id from watch list. If the id already exists
-- then it will be removed.
--
-- @param string achId
--   The achievement id to remove or add.
--
-- @return
--   (table) A key/value pair of currently watched ids after the operation.
--
function HUDCounter.Achievement:Watch(achId)
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
-- @see HUDCounter.Achievement.Event.Slash()
--
function HUDCounter.Achievement:eventSlash(params)
  local elements = PHP.explode(" ", params)
  if (elements[1] == "") then
    print("HUD Achievement commands:")
    print("/hudach ignore {achievement_id}")
    print("  Toggle the ignore status of an achievement. List all achievements ignored if no parameter specified.")
    print("/hudach watch")
    print("  List all watched achievement ids. List all achievements watched if no parameter specified.")
    print("/hudach watch {achievement_id}")
    print("  Toggle the watch status of an achievement.")
    print("/hudach iconSize {new_pixel_iconSize}")
    print("/hudach fontsize {new_pixel_fontsize}")
    print("/hudach redraw")
    print("  Destroy all achievement rows in the HUD and redraw.")
    print("/hudach debug")
    print("  Toggle debug information to console.")
    print("/hudach enable|disable")
    print("  Enable or disable achievements on HUD.")
  elseif (elements[1] == "debug") then
    if (self.Config.debug == true) then
      self.Config.debug = false
      print("Achievement debug disabled.")
    else
      self.Config.debug = true
      print("Achievement debug enabled.")
    end
  elseif (elements[1] == "ignore") then
    achIds = HUDCounter.Achievement:Ignore(elements[2])
    dump(achIds)
  elseif (elements[1] == "watch") then
    achIds = HUDCounter.Achievement:Watch(elements[2])
    dump(achIds)
  elseif (elements[1] == "redraw") then
    print("Redrawing achievement rows...")
    self:Redraw()
  elseif (elements[1] == "enable") then
    self.Config.enable = true
    print("HUD Achievements enabled.")
    self:Redraw()
  elseif (elements[1] == "disable") then
    self.Config.enable = false
    print("HUD Achievements disabled.")
    self:Redraw()
  elseif (elements[1] == "iconsize") then
    self.Config.iconSize = tonumber(elements[2])
    self:Redraw()
  elseif (elements[1] == "fontsize") then
    self.Config.fontSize = tonumber(elements[2])
    self:Redraw()
  end
end

--
-- Callback for Event.Achievement.Update
--
-- Inform the player that they just performed an action that increased their
-- progress in an achievement.
--
-- @see HUDCounter.Achievement.Event.Update()
--
function HUDCounter.Achievement:eventUpdate(achievements)
  if (self.Config.enable == false) then
    return
  end
  -- Count each achievement. Limit maximum processed.
  local maxcount = 0
  if (self.Config.debug == true) then
    print("========================================")
  end
  for achievement_key, v in pairs(achievements) do
    -- Place a cap on how many achievements we will do. The rest get ignored, sorry.
    if (maxcount >= 1) then
      break;
    end
    local achievement = AOMRift.Achievement:load(achievement_key)
    if ((not achievement.complete) and achievement.current and (AOMMath:count(achievement.requirement) == 1)) then
      maxcount = maxcount + 1
      -- If we are watching this achievement send it to the correct achievement
      -- row in the HUD, otherwise default to the bottom most row.
      local Row = self:FindRow(achievement.id)
      if (Row == nil) then
        Row = self.Config.rows[1]
      end
      -- Debug output.
      if (self.Config.debug == true) then
        print("----------------------------------------")
        print(AOMLua:print_r(achievement, "Achievement " .. achievement.id))
      end
      -- Output the achievement information.
      Row.time = Inspect.Time.Real()
      Row.icon:SetTexture("Rift", achievement.detail.icon)
      Row.text:SetText(self:makeDescription(achievement.id))
      Row.icon:SetAlpha(1)
      Row.text:SetAlpha(1)
      Row.achId = achievement.id
    end
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
function HUDCounter.Achievement:makeDescription(achId)
  local achievement = achId
  if (type(achId) ~= table) then
    achievement = AOMRift.Achievement:load(achId)
  end
  local achText = achievement.category.name .. ": " .. achievement.name .. ": " -- .. achievement.description .. ": "
  -- Output the requirements.
  for req_key, req_value in ipairs(achievement:get_incomplete()) do
    req = achievement:get_req(req_key)
    if (self.Config.debug == true) then
      print(AOMLua:print_r(req, "Requirement"))
    end
    achText = achText .. req.name .. " (" .. req.done .. "/" .. req.total .. ")"
  end
  return achText  
end

--
-- Callback for System.Update.Begin
--
-- Fades an achievement row if it has been displayed long enough.
--
-- @see HUDCounter.Achievement.Event.SystemUpdateBegin()
--
function HUDCounter.Achievement:EventSystemUpdateBegin()
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
function HUDCounter.Achievement.Event.SystemUpdateBegin()
  HUDCounter.Achievement:EventSystemUpdateBegin()
end

--
-- Callback for Event.Achievement.Update
--
function HUDCounter.Achievement.Event.Update(achievements)
  HUDCounter.Achievement:eventUpdate(achievements)
end

--
-- Callback for Command.Slash.Register("hudach")
--
function HUDCounter.Achievement.Event.Slash(params)
  HUDCounter.Achievement:eventSlash(params)
end
