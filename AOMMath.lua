
AOM.Math = math

function AOM.Math:round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end