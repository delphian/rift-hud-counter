
AOMMath = {}

-- Round a number to the precision specified.
function AOMMath:round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

-- Count the number of entries in a table.
function AOMMath:count(table)
  assert(type(table) == "table", "Expected a table")
  local count = 0
  if type(table) == "table" then
    for _ in pairs(table) do count = count + 1 end
  end
  return count
end