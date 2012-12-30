
AOMMath = {}
AOMLua = {}

-- Round a number to the precision specified.
function AOMMath:round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

-- Count the number of entries in a table.
function AOMMath:count(table)
  local count = 0
  if type(table) == "table" then
    for _ in pairs(table) do count = count + 1 end
  end
  return count
end

-- AOMLua:print_r(table, "My Table", 4)
function AOMLua:print_r (t, name, indent)
  local tableList = {}
  function table_r (t, name, indent, full)
    local id = not full and name
        or type(name)~="number" and tostring(name) or '['..name..']'
    local tag = indent .. id .. ' = '
    local out = {}	-- result
    if type(t) == "table" then
      if tableList[t] ~= nil then table.insert(out, tag .. '{} -- ' .. tableList[t] .. ' (self reference)')
      else
        tableList[t]= full and (full .. '.' .. id) or id
        if next(t) then -- Table not empty
          table.insert(out, tag .. '{')
          for key,value in pairs(t) do 
            table.insert(out,table_r(value,key,indent .. '    ',tableList[t]))
          end 
          table.insert(out,indent .. '}')
        else table.insert(out,tag .. '{}') end
      end
    else 
      local val = type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"' or tostring(t)
      table.insert(out, tag .. val)
    end
    return table.concat(out, '\n')
  end
  return table_r(t,name or 'Value',indent or '')
end
