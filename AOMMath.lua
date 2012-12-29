
AOMMath = {}

-- Round a number to the precision specified.
function AOMMath:round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

-- Count the number of entries in a table.
function AOMMath:count(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end