
HUDCounter.Achievement = {}

--
-- Initialize achievement configuration and event handling.
--
-- @return
--   (nil)
-- @todo Load in configuration from storage.
--
function HUDCounter.Achievement:init()
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
  -- Register callbacks.
  table.insert(Command.Slash.Register("hudach"), {HUDCounter.Achievement.SlashHandler, "HUDCounter", "Slash Command"})
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
function HUDCounter.Achievement.SlashHandler(params)
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

