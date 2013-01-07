
HUDCounter.Achievement = {}
HUDCounter.Achievement.Event = {}

--
-- Initialize achievement configuration and event handling.
--
-- @return
--   (nil)
-- @todo Load in configuration from storage.
--
function HUDCounter.Achievement:init(window)
  self.Config = {}
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

  -- Setup our UI
  self.UI = {}

  -- Register callbacks.
  table.insert(Command.Slash.Register("hudach"), {HUDCounter.Achievement.SlashHandler, "HUDCounter", "Slash Command"})
  table.insert(Event.Achievement.Update, {HUDCounter.Achievement.Event.Update, "HUDCounter", "Handle Achievement Update"})
end

--
function HUDCounter.Achievement:Redraw(window)
  -- Add room for our achievement notice.
  window:SetHeight(window:GetHeight() + 60)
  -- Add our icon
  position = { width = 48, height = 48, bottom = 2, left = 4 }
  self.UI.icon = AOMRift.UI:Content(window.content, position, { alpha = 0.75 }, "Texture")
  -- Add our text box.
  position = { height = 48, left = 56, bottom = 2, right = 2 }
  background = { red = 1, green = 1, blue = 1, alpha = 0.1 }
  self.UI.text = AOMRift.UI:Content(window.content, position, background, "Text")
  self.UI.text:SetWordwrap(true)
  self.UI.text:SetFontSize(10)
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
function HUDCounter.Achievement:ignore(ach_id)
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
    print("/hudach ignore")
    print("  List all ignored achievement ids.")
    print("/hudach ignore {ach_id}")
    print("  Toggle the ignore status of an achievement.")
  elseif (elements[1] == "ignore") then
    ach_ids = HUDCounter.Achievement:ignore(elements[2])
    dump(ach_ids)
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
  -- Count each achievement. Limit maximum processed.
  local maxcount = 0
  if (HUDCounter.Config.Debug.achievements == true) then
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
      -- Debug output.
      if (HUDCounter.Config.Debug.achievements == true) then
        print("----------------------------------------")
        print(AOMLua:print_r(achievement, "Achievement " .. achievement.id))
      end
      -- Output the achievement information.
      self.UI.icon:SetTexture("Rift", achievement.detail.icon)
      achText = achievement.category.name .. ": " .. achievement.name .. ": " .. achievement.description .. ": "
      -- Output the requirements.
      for req_key, req_value in ipairs(achievement:get_incomplete()) do
        req = achievement:get_req(req_key)
        if (HUDCounter.Config.Debug.achievements == true) then
          print(AOMLua:print_r(req, "Requirement"))
        end
        achText = achText .. req.name .. " (" .. req.done .. "/" .. req.total .. ")"
      end
      self.UI.text:SetText(achText)
    end
  end
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
