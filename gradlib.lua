local Colr = dofile(GetInfo(60) .. "colr.lua")

local max, floor = math.max, math.floor
local unpack = table.unpack or unpack

---@alias RGBTuple { [1]: number, [2]: number, [3]: number }
---@alias ColorInput RGBTuple|string|number

---@class GradientOptions
---@field reversed boolean? Iterate through the color stops backwards. Defaults to false.
---@field cycles number? Number of times to iterate through the color stops. Defaults to 1.

--------------------------------------------
---       General utility functions      ---
--------------------------------------------

---Rounds input up to the nearest whole number.
---@param x number
---@return number
local function round(x)
  return floor(x + 0.5)
end

---Splits a string by chunkSize, remainder
---characters are added to the last chunk
---@param text string
---@param chunkSize number
---@return string[]
local function chunkString(text, chunkSize)
  local s = {}

  if chunkSize > #text then
    for i = 1, #text do
      local c = text:sub(i, 1 + 1)
      table.insert(s, c)
    end

    return s
  end

  if #text == 0 then
    return s
  end

  if #text == 1 then
    s[1] = text
    return s
  end

  for i = 1, #text, chunkSize do
    local chunk = text:sub(i, i + chunkSize - 1)

    if #chunk ~= chunkSize then
      s[#s] = s[#s] .. chunk
    else
      s[#s + 1] = chunk
    end
  end

  return s
end

--------------------------------------------
---              Gradient                ---
--------------------------------------------

---Generates a gradient between first and last color for
---the given text string. Returns Aard-encoded string.
---@param text string The text to colorize
---@param startColor ColorInput Starting color
---@param endColor ColorInput Ending color
---@param previous number? Last color generated in a previous call to the function
---@return string, number result Text encoded as aard color string
local function stop(text, startColor, endColor, previous)
  local color1
  local color2

  if type(startColor) == "string" then
    color1 = startColor
  end

  if type(endColor) == "string" then
    color2 = endColor
  end

  if tonumber(startColor) then
    local index = tonumber(startColor) --[[@as number]]
    color1 = Colr.xtermIndices[floor(index)]
  end

  if tonumber(endColor) then
    local index = tonumber(endColor) --[[@as number]]
    color2 = Colr.xtermIndices[floor(index)]
  end

  if type(startColor) == "table" and not Colr.isColor(startColor) then
    color1 = "rgb(" .. startColor[1] .. ", " .. startColor[2] .. ", " .. startColor[3] .. ")"
  end

  if type(startColor) == "table" and not Colr.isColor(endColor) then
    color2 = "rgb(" .. endColor[1] .. ", " .. endColor[2] .. ", " .. endColor[3] .. ")"
  end

  if Colr.isColor(startColor) then
    color1 = startColor
  end

  if Colr.isColor(endColor) then
    color2 = endColor
  end

  local sc = Colr:new(color1)
  local ec = Colr:new(color2)

  local r, g, b = unpack(sc:toRgbTuple())
  local dr, dg, db = unpack(ec:toRgbTuple())
  local pattern = "[^\128-\191][\128-\191]*"
  local n = max(1, select(2, text:gsub(pattern, "")) - 1)

  -- Calculate color step - the ghettoist of lerps
  -- FIXME: Replace this with a better perceptual lerp
  dr, dg, db = (dr - r) / n, (dg - g) / n, (db - b) / n

  local result = ""
  local prevColor = previous

  for c in text:gmatch(pattern) do
    local cstring = "rgb(" .. round(r) .. ", " .. round(g) .. ", " .. round(b) .. ")"
    local color = Colr.nearestXTermColorIndex(Colr:new(cstring))

    if color == prevColor then -- Don't add duplicate color codes one after another
      result = result .. c
    else
      local digits = 3

      if (color < 10) then
        digits = 1
      elseif (color < 100) then
        digits = 2
      end

      result = result .. ("@x%0" .. digits .. "d"):format(color) .. c
    end

    prevColor = color
    r, g, b = r + dr, g + dg, b + db
  end

  return result, prevColor
end

Gradient = {}
Gradient_mt = Class(Gradient)

function Gradient:new()
  return setmetatable({}, Gradient_mt)
end

---Generate a gradient given a string and a
---table containing color inputs. Inputs may be
---HTML style hex strings, xterm color numbers, or
---RGBTuples
---@param text string The text to use
---@param colors ColorInput[] A list of color stops
---@param options GradientOptions? Gradient Options
---@return string result Aard-encoded string
function Gradient:generate(text, colors, options)
  local colorCount = #colors
  local length = string.len(text)
  local reversed = false
  local cycles = 1

  if options then
    if options.cycles then
      cycles = options.cycles
    end

    if options.reversed then
      reversed = options.reversed
    end
  end

  if length == 0 then
    error("Gradient.generate: Empty text")
  end

  if colorCount < 2 then
    error("Gradient.generate: Must include at least two colors to generate a gradient")
  end

  if cycles > 1 then
    local copy = {}

    for _, v in ipairs(colors) do
      table.insert(copy, v)
    end

    for _ = 1, cycles do
      for _, v in ipairs(copy) do
        table.insert(colors, v)
      end
    end
  end

  local stopCount
  local chunked

  if colorCount >= length then
    stopCount = (length - 1) * cycles
    chunked = chunkString(text, length)
  else
    stopCount = (colorCount - 1) * cycles
    chunked = chunkString(text, round(length / stopCount))
  end
  local result = ""
  local styled, previous

  for i, chunk in ipairs(chunked) do
    local index1 = i
    local index2 = i + 1

    if reversed then
      index1 = #colors - i + 1
      index2 = #colors - i
    end

    if index1 > #colors or index2 > #colors then
      index1 = #colors - 1
      index2 = #colors
    end

    if index1 < 1 then
      index1 = 1
      index2 = 2
    end

    styled, previous = stop(chunk, colors[index1], colors[index2], previous)
    result = result .. styled
  end

  return result .. "@w"
end

return Gradient
