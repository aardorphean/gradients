-- Colr
-- A Lua port of tinycolor2 for Mushclient
-- Augmented with xterm256 specific support, removes wcag readability functionality
-- and support for internet explorer filters.
-- orphean@aardwolf
-- Tinycolor2: https://github.com/bgrins/TinyColor/blob/master/mod.js

local abs, min, max, floor, pow = math.abs, math.min, math.max, math.floor, math.pow
local unpack = table.unpack or unpack
local rex = require("rex")

----------------------------------------------------------

--  Types

----------------------------------------------------------

---@alias ColorFormat
---| "prgb"
---| "rgb"
---| "hsl"
---| "hsv"
---| "hex"
---| "hex8"

---@alias RGBColor { r: number, g: number, b: number }
---@alias RGBColorTuple { [1]: number, [2]: number, [3]: number }
---@alias HSVColor { h: number, s: string|number, v: string|number }
---@alias HSLColor { h: number, s: string|number, l: string|number }
---@alias PRGBColor{ r: string, g: string, b: string}
---@alias RGBAColor { r: number, g: number, b: number, a: number }
---@alias PRGBAColor {r: string, g: string, b: string, a: string}
---@alias HSVAColor { h: number, s: string|number, v: string|number, a: number }
---@alias HSLAColor { h: number, s: string|number, l: string|number, a: number }

---@class Class
---@field new fun(members: table): Class
---@field copy fun(obj: Class, ...): Class

---@class ColrOptions
---@field format string
---@field gradientType string

---@class Colr: Class
---@field _ok boolean
---@field isColor fun(color: Colr): boolean Static function.
---@field equals fun(color1: Colr, color2: Colr): boolean Static function
---@field mix fun(color1: Colr, color2: Colr, amount: number?): Colr
---@field names { [string]: string } Color name to hex value.
---@field hexNames { [string]: string } Hex value to Color name
---@field isValid fun(): boolean
---@field getOriginalInput fun(): string
---@field getBrightness fun(): number
---@field getLuminance fun(): number
---@field isDark fun(): boolean
---@field isLight fun(): boolean
---@field toRgbString fun(): string
---@field toHsvString fun(): string
---@field toHslString fun(): string
---@field toPercentageRgbString fun(): string
---@field toHex fun(self: Colr, allow3Char: boolean?): string
---@field toHexString fun(self: Colr, allow3Char: boolean?): string
---@field toHex8 fun(self: Colr, allow4Char: boolean?): string
---@field toHex8String fun(self: Colr, allow4Char: boolean?): string
---@field toRgb fun(): RGBAColor
---@field toHsl fun(): HSLAColor
---@field toHsv fun(): HSVAColor
---@field toPercentageRgb fun(): PRGBAColor
---@field getAlpha fun(): number
---@field setAlpha fun(self: Colr, value: number): Colr
---@field getFormat fun(): string
---@field toString fun(self: Colr, format: ColorFormat?): string
---@field toName fun(): string
---@field clone fun(): Colr
---@field toRgbTuple fun(): RGBColorTuple
---@field nearestXTermColorIndex fun(color: Colr): number
---@field lighten fun(self: Colr, amount: number?): Colr
---@field brighten fun(self: Colr, amount: number?): Colr
---@field darken fun(self: Colr, amount: number?): Colr
---@field desaturate fun(self: Colr, amount: number?): Colr
---@field saturate fun(self: Colr, amount: number?): Colr
---@field greyscale fun(): Colr
---@field spin fun(self: Colr, amount: number): Colr
---@field analogous fun(self: Colr, results: number?, slices: number?): Colr[]
---@field complement fun(): Colr
---@field monochromatic fun(self: Colr, results: number?): Colr[]
---@field splitcomplement fun(self: Colr): Colr[]
---@field triad fun(): Colr[]
---@field tetrad fun(): Colr[]

----------------------------------------------------------

--  Local Data

----------------------------------------------------------

local names = {
  aliceblue = "f0f8ff",
  antiquewhite = "faebd7",
  aqua = "0ff",
  aquamarine = "7fffd4",
  azure = "f0ffff",
  beige = "f5f5dc",
  bisque = "ffe4c4",
  black = "000",
  blanchedalmond = "ffebcd",
  blue = "00f",
  blueviolet = "8a2be2",
  brown = "a52a2a",
  burlywood = "deb887",
  burntsienna = "ea7e5d",
  cadetblue = "5f9ea0",
  chartreuse = "7fff00",
  chocolate = "d2691e",
  coral = "ff7f50",
  cornflowerblue = "6495ed",
  cornsilk = "fff8dc",
  crimson = "dc143c",
  cyan = "0ff",
  darkblue = "00008b",
  darkcyan = "008b8b",
  darkgoldenrod = "b8860b",
  darkgray = "a9a9a9",
  darkgreen = "006400",
  darkgrey = "a9a9a9",
  darkkhaki = "bdb76b",
  darkmagenta = "8b008b",
  darkolivegreen = "556b2f",
  darkorange = "ff8c00",
  darkorchid = "9932cc",
  darkred = "8b0000",
  darksalmon = "e9967a",
  darkseagreen = "8fbc8f",
  darkslateblue = "483d8b",
  darkslategray = "2f4f4f",
  darkslategrey = "2f4f4f",
  darkturquoise = "00ced1",
  darkviolet = "9400d3",
  deeppink = "ff1493",
  deepskyblue = "00bfff",
  dimgray = "696969",
  dimgrey = "696969",
  dodgerblue = "1e90ff",
  firebrick = "b22222",
  floralwhite = "fffaf0",
  forestgreen = "228b22",
  fuchsia = "f0f",
  gainsboro = "dcdcdc",
  ghostwhite = "f8f8ff",
  gold = "ffd700",
  goldenrod = "daa520",
  gray = "808080",
  green = "008000",
  greenyellow = "adff2f",
  grey = "808080",
  honeydew = "f0fff0",
  hotpink = "ff69b4",
  indianred = "cd5c5c",
  indigo = "4b0082",
  ivory = "fffff0",
  khaki = "f0e68c",
  lavender = "e6e6fa",
  lavenderblush = "fff0f5",
  lawngreen = "7cfc00",
  lemonchiffon = "fffacd",
  lightblue = "add8e6",
  lightcoral = "f08080",
  lightcyan = "e0ffff",
  lightgoldenrodyellow = "fafad2",
  lightgray = "d3d3d3",
  lightgreen = "90ee90",
  lightgrey = "d3d3d3",
  lightpink = "ffb6c1",
  lightsalmon = "ffa07a",
  lightseagreen = "20b2aa",
  lightskyblue = "87cefa",
  lightslategray = "789",
  lightslategrey = "789",
  lightsteelblue = "b0c4de",
  lightyellow = "ffffe0",
  lime = "0f0",
  limegreen = "32cd32",
  linen = "faf0e6",
  magenta = "f0f",
  maroon = "800000",
  mediumaquamarine = "66cdaa",
  mediumblue = "0000cd",
  mediumorchid = "ba55d3",
  mediumpurple = "9370db",
  mediumseagreen = "3cb371",
  mediumslateblue = "7b68ee",
  mediumspringgreen = "00fa9a",
  mediumturquoise = "48d1cc",
  mediumvioletred = "c71585",
  midnightblue = "191970",
  mintcream = "f5fffa",
  mistyrose = "ffe4e1",
  moccasin = "ffe4b5",
  navajowhite = "ffdead",
  navy = "000080",
  oldlace = "fdf5e6",
  olive = "808000",
  olivedrab = "6b8e23",
  orange = "ffa500",
  orangered = "ff4500",
  orchid = "da70d6",
  palegoldenrod = "eee8aa",
  palegreen = "98fb98",
  paleturquoise = "afeeee",
  palevioletred = "db7093",
  papayawhip = "ffefd5",
  peachpuff = "ffdab9",
  peru = "cd853f",
  pink = "ffc0cb",
  plum = "dda0dd",
  powderblue = "b0e0e6",
  purple = "800080",
  rebeccapurple = "663399",
  red = "f00",
  rosybrown = "bc8f8f",
  royalblue = "4169e1",
  saddlebrown = "8b4513",
  salmon = "fa8072",
  sandybrown = "f4a460",
  seagreen = "2e8b57",
  seashell = "fff5ee",
  sienna = "a0522d",
  silver = "c0c0c0",
  skyblue = "87ceeb",
  slateblue = "6a5acd",
  slategray = "708090",
  slategrey = "708090",
  snow = "fffafa",
  springgreen = "00ff7f",
  steelblue = "4682b4",
  tan = "d2b48c",
  teal = "008080",
  thistle = "d8bfd8",
  tomato = "ff6347",
  turquoise = "40e0d0",
  violet = "ee82ee",
  wheat = "f5deb3",
  white = "fff",
  whitesmoke = "f5f5f5",
  yellow = "ff0",
  yellowgreen = "9acd32"
}

local xtermIndices = {
  [0] = '#000000',
  '#800000',
  '#008000',
  '#808000',
  '#000080',
  '#800080',
  '#008080',
  '#c0c0c0',
  '#808080',
  '#ff0000',
  '#00ff00',
  '#ffff00',
  '#0000ff',
  '#ff00ff',
  '#00ffff',
  '#ffffff',
  '#000000',
  '#00005f',
  '#000087',
  '#0000af',
  '#0000d7',
  '#0000ff',
  '#005f00',
  '#005f5f',
  '#005f87',
  '#005faf',
  '#005fd7',
  '#005fff',
  '#008700',
  '#00875f',
  '#008787',
  '#0087af',
  '#0087d7',
  '#0087ff',
  '#00af00',
  '#00af5f',
  '#00af87',
  '#00afaf',
  '#00afd7',
  '#00afff',
  '#00d700',
  '#00d75f',
  '#00d787',
  '#00d7af',
  '#00d7d7',
  '#00d7ff',
  '#00ff00',
  '#00ff5f',
  '#00ff87',
  '#00ffaf',
  '#00ffd7',
  '#00ffff',
  '#5f0000',
  '#5f005f',
  '#5f0087',
  '#5f00af',
  '#5f00d7',
  '#5f00ff',
  '#5f5f00',
  '#5f5f5f',
  '#5f5f87',
  '#5f5faf',
  '#5f5fd7',
  '#5f5fff',
  '#5f8700',
  '#5f875f',
  '#5f8787',
  '#5f87af',
  '#5f87d7',
  '#5f87ff',
  '#5faf00',
  '#5faf5f',
  '#5faf87',
  '#5fafaf',
  '#5fafd7',
  '#5fafff',
  '#5fd700',
  '#5fd75f',
  '#5fd787',
  '#5fd7af',
  '#5fd7d7',
  '#5fd7ff',
  '#5fff00',
  '#5fff5f',
  '#5fff87',
  '#5fffaf',
  '#5fffd7',
  '#5fffff',
  '#870000',
  '#87005f',
  '#870087',
  '#8700af',
  '#8700d7',
  '#8700ff',
  '#875f00',
  '#875f5f',
  '#875f87',
  '#875faf',
  '#875fd7',
  '#875fff',
  '#878700',
  '#87875f',
  '#878787',
  '#8787af',
  '#8787d7',
  '#8787ff',
  '#87af00',
  '#87af5f',
  '#87af87',
  '#87afaf',
  '#87afd7',
  '#87afff',
  '#87d700',
  '#87d75f',
  '#87d787',
  '#87d7af',
  '#87d7d7',
  '#87d7ff',
  '#87ff00',
  '#87ff5f',
  '#87ff87',
  '#87ffaf',
  '#87ffd7',
  '#87ffff',
  '#af0000',
  '#af005f',
  '#af0087',
  '#af00af',
  '#af00d7',
  '#af00ff',
  '#af5f00',
  '#af5f5f',
  '#af5f87',
  '#af5faf',
  '#af5fd7',
  '#af5fff',
  '#af8700',
  '#af875f',
  '#af8787',
  '#af87af',
  '#af87d7',
  '#af87ff',
  '#afaf00',
  '#afaf5f',
  '#afaf87',
  '#afafaf',
  '#afafd7',
  '#afafff',
  '#afd700',
  '#afd75f',
  '#afd787',
  '#afd7af',
  '#afd7d7',
  '#afd7ff',
  '#afff00',
  '#afff5f',
  '#afff87',
  '#afffaf',
  '#afffd7',
  '#afffff',
  '#d70000',
  '#d7005f',
  '#d70087',
  '#d700af',
  '#d700d7',
  '#d700ff',
  '#d75f00',
  '#d75f5f',
  '#d75f87',
  '#d75faf',
  '#d75fd7',
  '#d75fff',
  '#d78700',
  '#d7875f',
  '#d78787',
  '#d787af',
  '#d787d7',
  '#d787ff',
  '#d7af00',
  '#d7af5f',
  '#d7af87',
  '#d7afaf',
  '#d7afd7',
  '#d7afff',
  '#d7d700',
  '#d7d75f',
  '#d7d787',
  '#d7d7af',
  '#d7d7d7',
  '#d7d7ff',
  '#d7ff00',
  '#d7ff5f',
  '#d7ff87',
  '#d7ffaf',
  '#d7ffd7',
  '#d7ffff',
  '#ff0000',
  '#ff005f',
  '#ff0087',
  '#ff00af',
  '#ff00d7',
  '#ff00ff',
  '#ff5f00',
  '#ff5f5f',
  '#ff5f87',
  '#ff5faf',
  '#ff5fd7',
  '#ff5fff',
  '#ff8700',
  '#ff875f',
  '#ff8787',
  '#ff87af',
  '#ff87d7',
  '#ff87ff',
  '#ffaf00',
  '#ffaf5f',
  '#ffaf87',
  '#ffafaf',
  '#ffafd7',
  '#ffafff',
  '#ffd700',
  '#ffd75f',
  '#ffd787',
  '#ffd7af',
  '#ffd7d7',
  '#ffd7ff',
  '#ffff00',
  '#ffff5f',
  '#ffff87',
  '#ffffaf',
  '#ffffd7',
  '#ffffff',
  '#080808',
  '#121212',
  '#1c1c1c',
  '#262626',
  '#303030',
  '#3a3a3a',
  '#444444',
  '#4e4e4e',
  '#585858',
  '#626262',
  '#6c6c6c',
  '#767676',
  '#808080',
  '#8a8a8a',
  '#949494',
  '#9e9e9e',
  '#a8a8a8',
  '#b2b2b2',
  '#bcbcbc',
  '#c6c6c6',
  '#d0d0d0',
  '#dadada',
  '#e4e4e4',
  '#eeeeee'
}

local xtermLevels = { [0] = 0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff }

local CSS_INTEGER = "[-\\+]?\\d+%?"
local CSS_NUMBER = "[-\\+]?\\d*\\.\\d+%?"
local CSS_UNIT = "(?:" .. CSS_NUMBER .. ")|(?:" .. CSS_INTEGER .. ")"
local MATCH3 = "[\\s|\\(]+(" ..
    CSS_UNIT ..
    ")[,|\\s]+(" ..
    CSS_UNIT ..
    ")[,|\\s]+(" ..
    CSS_UNIT ..
    ")\\s*\\)?"
local MATCH4 = "[\\s|\\(]+(" ..
    CSS_UNIT ..
    ")[,|\\s]+(" ..
    CSS_UNIT ..
    ")[,|\\s]+(" ..
    CSS_UNIT ..
    ")[,|\\s]+(" ..
    CSS_UNIT ..
    ")\\s*\\)?"
local HEX3 = "^#?([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})$"
local HEX6 = "^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$"
local HEX4 = "^#?([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})$"
local HEX8 = "^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$"

local matchers = {
  CSS_UNIT = rex.new(CSS_UNIT),
  rgb = rex.new("rgb" .. MATCH3),
  rgba = rex.new("rgba" .. MATCH4),
  hsl = rex.new("hsl" .. MATCH3),
  hsla = rex.new("hsla" .. MATCH4),
  hsv = rex.new("hsv" .. MATCH3),
  hsva = rex.new("hsva" .. MATCH4),
  hex3 = rex.new(HEX3),
  hex6 = rex.new(HEX6),
  hex4 = rex.new(HEX4),
  hex8 = rex.new(HEX8)
}

----------------------------------------------------------

--  Utilities

----------------------------------------------------------

---Tests if passed value is NaN
---@param v any
---@return boolean
local function isNaN(v)
  return type(v) == "nil" or type(v) == "number" and v ~= v
end

---Trims whitespace from string
---@param str string
---@return string
local function trim(str)
  return str:match '^()%s*$' and '' or str:match '^%s*(.*%S)'
end

---Rounds input up to the nearest whole number.
---@param x number
---@return number
local function round(x)
  return floor(x + 0.5)
end

---Converts a hex string into an integer
---@param val string
---@return integer
local function parseIntFromHex(val)
  return tonumber(val, 16)
end

---Checks if passed string/number looks like a CSS unit.
---@param color string|number
---@return boolean
local function isValidCSSUnit(color)
  if color == nil then
    return false
  end

  local matched = matchers.CSS_UNIT:match(color)
  return matched ~= nil
end

---Converts passed in number to a hex representation.
---Decimal values are rounded up to the nearest integer.
---@param d number|string
---@return string
local function convertDecimalToHex(d)
  return string.format("%x", round(tonumber(d) * 255))
end

---Converts passed hex to a floating point representation
---@param h string
---@return number
local function convertHexToDecimal(h)
  return parseIntFromHex(h) / 255.0
end

---Replace a decimal with it's percentage value
---@param n number
---@return string|number
local function convertToPercentage(n)
  ---@type string|number
  local result = n

  if type(result) == "string" then
    result = result:gsub("%%", "")
    result = tonumber(result) --[[@as number]]
  end

  if result <= 1 then
    result = n * 100 .. "%"
  end

  if type(result) == "number" then
    result = result .. ""
  end

  return result
end

---Force a hex value to have 2 characters
---@param c string
---@return string
local function pad2(c)
  if #c == 1 then
    return "0" .. c
  else
    return c
  end
end

---Checks to see if string is a percentage
---@param n string|number
---@return boolean
local function isPercentage(n)
  if type(n) ~= "string" then
    return false
  end

  return (n:match("%%") ~= nil)
end

---Need to handle 1.0 as 100%
---@param n string|number
---@return boolean
local function isOnePointZero(n)
  if type(n) ~= "string" then
    return false
  end

  if n:match("%.") == nil then
    return false
  end

  return tonumber(n) == 1
end

---Take input from [0, n] and return it as [0, 1]
---@param n string|number
---@param maxn number
---@return integer
local function bound01(n, maxn)
  if isOnePointZero(n) then
    n = "100%"
  end

  local processPercent = isPercentage(n)
  if processPercent then
    n = n:gsub("%%", "")
  end

  n = min(maxn, max(0, tonumber(n)))

  if processPercent then
    n = floor(n * maxn) / 100.0
  end

  if abs(n - maxn) < 0.000001 then
    return 1
  end

  return (n % maxn) / (maxn + 0.0)
end

---Force a number between 0 and 1
---@param val number|string
---@return integer
local function clamp01(val)
  local value = val --[[@as number]]

  if type(val) == "string" then
    value = tonumber((string.gsub(val, "%%", ""))) --[[@as number]]
  end

  return min(1, max(0, value))
end

---Return a valid alpha value [0,1] with all invalid values being set to 1
---@param a string|number
---@return number
local function boundAlpha(a)
  local alpha

  if type(a) == "string" then
    alpha = tonumber(a) --[[@as number]]
  end

  if isNaN(alpha) or alpha < 0 or alpha > 1 then
    alpha = 1
  end

  return alpha
end

local function flip(o)
  local flipped = {}

  for k, v in pairs(o) do
    flipped[v] = k
  end

  return flipped
end

local hexNames = flip(names)

---Permissive string parsing.  Take in a number of formats, and output an object
---based on detected format.  Returns `{ r, g, b }` or `{ h, s, l }` or `{ h, s, v}`
---@param color string
---@return table|boolean
local function stringInputToObject(color)
  color = trim(color):lower()

  local named = false
  if names[color] ~= nil then
    color = names[color]
    named = true
  elseif color == "transparent" then
    return { r = 0, g = 0, b = 0, a = 0, format = "name" }
  end

  local s, ss

  s, _, ss = matchers.rgb:match(color)
  if s ~= nil then
    return {
      r = ss[1],
      g = ss[2],
      b = ss[3]
    }
  end

  s, _, ss = matchers.rgba:match(color)
  if s ~= nil then
    return {
      r = ss[1],
      g = ss[2],
      b = ss[3],
      a = ss[4]
    }
  end

  s, _, ss = matchers.hsl:match(color)
  if s ~= nil then
    return {
      h = ss[1],
      s = ss[2],
      l = ss[3]
    }
  end

  s, _, ss = matchers.hsla:match(color)
  if s ~= nil then
    return {
      h = ss[1],
      s = ss[2],
      l = ss[3],
      a = ss[4]
    }
  end

  s, _, ss = matchers.hsv:match(color)
  if s ~= nil then
    return {
      h = ss[1],
      s = ss[2],
      v = ss[3]
    }
  end

  s, _, ss = matchers.hsva:match(color)
  if s ~= nil then
    return {
      h = ss[1],
      s = ss[2],
      v = ss[3],
      a = ss[4]
    }
  end

  s, e, ss = matchers.hex8:match(color)
  if s ~= nil then
    local format = "hex8"

    if named then
      format = "name"
    end

    return {
      r = parseIntFromHex(ss[1]),
      g = parseIntFromHex(ss[2]),
      b = parseIntFromHex(ss[3]),
      a = parseIntFromHex(ss[4]),
      format = format
    }
  end

  s, e, ss = matchers.hex6:match(color)
  if s ~= nil then
    local format = "hex"

    if named then
      format = "name"
    end

    return {
      r = parseIntFromHex(ss[1]),
      g = parseIntFromHex(ss[2]),
      b = parseIntFromHex(ss[3]),
      format = format
    }
  end

  s, e, ss = matchers.hex4:match(color)
  if s ~= nil then
    local format = "hex8"

    if named then
      format = "name"
    end

    return {
      r = parseIntFromHex(ss[1] .. ss[1]),
      g = parseIntFromHex(ss[2] .. ss[2]),
      b = parseIntFromHex(ss[3] .. ss[3]),
      a = convertHexToDecimal(ss[4] .. ss[4]),
      format = format
    }
  end

  s, e, ss = matchers.hex3:match(color)
  if s ~= nil then
    local format = "hex"

    if named then
      format = "name"
    end

    return {
      r = parseIntFromHex(ss[1] .. ss[1]),
      g = parseIntFromHex(ss[2] .. ss[2]),
      b = parseIntFromHex(ss[3] .. ss[3]),
      format = format
    }
  end

  return false
end

---Handle bounds checking.
---@param r number
---@param g number
---@param b number
---@return table
local function rgbToRgb(r, g, b)
  return {
    r = bound01(r, 255) * 255,
    g = bound01(g, 255) * 255,
    b = bound01(b, 255) * 255
  }
end

---Converts an RGB color value to HSL.
---@param r number
---@param g number
---@param b number
---@return table
local function rgbToHsl(r, g, b)
  r = bound01(r, 255)
  g = bound01(g, 255)
  b = bound01(b, 255)

  local maxc = max(r, g, b)
  local minc = min(r, g, b)

  local h = (maxc + minc) / 2
  local s = h
  local l = h

  if maxc == minc then
    -- achromatic
    h = 0
    s = 0
  else
    local d = maxc - minc

    if l > 0.5 then
      s = d / (2 - maxc - minc)
    else
      s = d / (maxc + minc)
    end

    if maxc == r then
      local off = 0

      if g < b then
        off = 6
      end

      h = (g - b) / d + off
    elseif maxc == g then
      h = (b - r) / d + 2
    elseif maxc == b then
      h = (r - g) / d + 4
    end

    h = h / 6
  end

  return {
    h = h,
    s = s,
    l = l
  }
end

---Converts an HSL color value to RGB.
---@param h number|string
---@param s number|string
---@param l number|string
---@return table
local function hslToRgb(h, s, l)
  local r, g, b

  h = bound01(h, 360)
  s = bound01(s, 100)
  l = bound01(l, 100)

  local function hue2rgb(p, q, t)
    if t < 0 then
      t = t + 1
    end

    if t > 1 then
      t = t - 1
    end

    if t < 1 / 6 then
      return p + (q - p) * 6 * t
    end

    if t < 1 / 2 then
      return q
    end

    if t < 2 / 3 then
      return p + (q - p) * (2 / 3 - t) * 6
    end

    return p
  end

  if s == 0 then
    -- achromatic
    r = 1
    g = 1
    b = 1
  else
    local q
    if l < 0.5 then
      q = l * (1 + s)
    else
      q = l + s - l * s
    end
    local p = 2 * l - q
    r = hue2rgb(p, q, h + 1 / 3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1 / 3)
  end

  return {
    r = r * 255,
    g = g * 255,
    b = b * 255
  }
end

---Converts an RGB color value to HSV
---@param r number
---@param g number
---@param b number
---@return table
local function rgbToHsv(r, g, b)
  r = bound01(r, 255)
  g = bound01(g, 255)
  b = bound01(b, 255)

  local maxc = max(r, g, b)
  local minc = min(r, g, b)

  local h = maxc
  local s = h
  local v = h
  local d = maxc - minc

  if maxc == 0 then
    s = 0
  else
    s = d / maxc
  end

  if maxc == minc then
    h = 0 -- achromatic
  else
    if maxc == r then
      local off = 0

      if g < b then
        off = 6
      end

      h = (g - b) / d + off
    elseif maxc == g then
      h = (b - r) / d + 2
    elseif maxc == b then
      h = (r - g) / d + 4
    end

    h = h / 6
  end

  return {
    h = h,
    s = s,
    v = v
  }
end

---Converts an HSV color value to RGB.
---@param h number|string
---@param s number|string
---@param v number|string
---@return table
local function hsvToRgb(h, s, v)
  h = bound01(h, 360) * 6
  s = bound01(s, 100)
  v = bound01(v, 100)

  local i = floor(h)
  local f = h - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  local mod = i % 6
  local r = ({ [0] = v, q, p, p, t, v })[mod]
  local g = ({ [0] = t, v, v, q, p, p })[mod]
  local b = ({ [0] = p, p, t, v, v, q })[mod]

  return {
    r = r * 255,
    g = g * 255,
    b = b * 255
  }
end

---Converts an RGB color to hex
---@param r number
---@param g number
---@param b number
---@param allow3Char boolean
---@return string
local function rgbToHex(r, g, b, allow3Char)
  local hex = {
    [0] = pad2(string.format("%x", round(r))),
    pad2(string.format("%x", round(g))),
    pad2(string.format("%x", round(b)))
  }

  if allow3Char and
      hex[0]:sub(1, 1) == hex[0]:sub(2, 2) and
      hex[1]:sub(1, 1) == hex[1]:sub(2, 2) and
      hex[2]:sub(1, 1) == hex[2]:sub(2, 2) then
    return hex[0]:sub(1, 1) .. hex[1]:sub(1, 1) .. hex[2]:sub(1, 1)
  end

  return hex[0] .. hex[1] .. hex[2]
end

---Converts an RGBA color to hex
---@param r number
---@param g number
---@param b number
---@param a number
---@param allow4Char boolean
---@return string
local function rgbaToHex(r, g, b, a, allow4Char)
  local hex = {
    [0] = pad2(string.format("%x", round(r))),
    pad2(string.format("%x", round(g))),
    pad2(string.format("%x", round(b))),
    pad2(convertDecimalToHex(a))
  }

  if allow4Char and
      hex[0]:sub(1, 1) == hex[0]:sub(2, 2) and
      hex[1]:sub(1, 1) == hex[1]:sub(2, 2) and
      hex[2]:sub(1, 1) == hex[2]:sub(2, 2) and
      hex[3]:sub(1, 1) == hex[3]:sub(2, 2) then
    return hex[0]:sub(1, 1) .. hex[1]:sub(1, 1) .. hex[2]:sub(1, 1) .. hex[3]:sub(1, 1)
  end

  return hex[0] .. hex[1] .. hex[2] .. hex[3]
end

local function inputToRGB(color)
  local rgb = { r = 0, g = 0, b = 0 }
  local a = 1
  local s = nil
  local v = nil
  local l = nil
  local ok = false
  local format

  if type(color) == "string" then
    color = stringInputToObject(color)
  end

  if type(color) == "table" then
    if isValidCSSUnit(color.r) and
        isValidCSSUnit(color.g) and
        isValidCSSUnit(color.b) then
      rgb = rgbToRgb(color.r, color.g, color.b)
      ok = true
      local st = string.find(color.r, "%%")

      if st ~= nil then
        format = "prgb"
      else
        format = "rgb"
      end
    elseif isValidCSSUnit(color.h) and
        isValidCSSUnit(color.s) and
        isValidCSSUnit(color.v) then
      s = convertToPercentage(color.s)
      v = convertToPercentage(color.v)
      rgb = hsvToRgb(color.h, s, v)
      ok = true
      format = "hsv"
    elseif isValidCSSUnit(color.h) and
        isValidCSSUnit(color.s) and
        isValidCSSUnit(color.l) then
      s = convertToPercentage(color.s)
      l = convertToPercentage(color.l)
      rgb = hslToRgb(color.h, s, l)
      ok = true
      format = "hsl"
    end

    if color.a ~= nil then
      a = color.a
    end
  end

  a = boundAlpha(a)

  local returnFormat

  if type(color) == "table" and color.format ~= nil then
    returnFormat = color.format
  else
    returnFormat = format
  end

  return {
    ok = ok,
    format = returnFormat,
    r = min(255, max(rgb.r, 0)),
    g = min(255, max(rgb.g, 0)),
    b = min(255, max(rgb.b, 0)),
    a = a
  }
end

---Converts Colr object to a string
---@param color Colr
---@param overrideFormat ColorFormat?
local function toString(color, overrideFormat)
  local formatSet = overrideFormat ~= nil
  local alpha = color:getAlpha()
  local format

  if formatSet then
    format = overrideFormat
  else
    format = color:getFormat()
  end

  local formattedString = nil
  local hasAlpha = alpha < 1 and alpha >= 0
  local needsAlphaFormat = not formatSet and hasAlpha and
      (format == "hex" or
        format == "hex6" or
        format == "hex3" or
        format == "hex4" or
        format == "hex8" or
        format == "name")

  if needsAlphaFormat then
    if format == "name" and alpha == 0 then
      return color:toName()
    end

    return color:toRgbString()
  end

  if format == "rgb" then
    formattedString = color:toRgbString()
  end

  if format == "prgb" then
    formattedString = color:toPercentageRgbString()
  end

  if format == "hex" or format == "hex6" then
    formattedString = color:toHexString()
  end

  if format == "hex3" then
    formattedString = color:toHexString(true)
  end

  if format == "hex4" then
    formattedString = color:toHex8String(true)
  end

  if format == "hex8" then
    formattedString = color:toHex8String()
  end

  if format == "name" then
    formattedString = color:toName()
  end

  if format == "hsl" then
    formattedString = color:toHslString()
  end

  if format == "hsv" then
    formattedString = color:toHsvString()
  end

  if formattedString ~= nil then
    return formattedString
  else
    return color:toHexString()
  end
end

---Scales value from RGB
---@param value number 0-255
---@return number
local function halfScale(value)
  return floor(max((value - 35) / 40, value / 58))
end

---Returns color index in the range 16 to 231 and
---the approximate values for the given r, g, and b.
---@param r number 0-255
---@param g number 0-255
---@param b number 0-255
---@return number, number, number, number
local function nearestXtermColor(r, g, b)
  r, g, b = halfScale(r), halfScale(g), halfScale(b)
  return 16 + 36 * r + 6 * g + b, xtermLevels[r], xtermLevels[g], xtermLevels[b]
end

---Returns xterm grayscale color index and
---the grayscale values for the given r, g, and b.
---Uses an approximation of gray = 0.2126 * r + 0.7152 * g + 0.0722 * b
---for grayscale calculation.
---@param r number 0-255
---@param g number 0-255
---@param b number 0-255
---@return number, number, number, number
local function nearestXtermGrayscaleColor(r, g, b)
  local gray = (3 * r + 10 * g + b) / 14
  local index = min(23, max(0, floor((gray - 3) / 10)))
  gray = 8 + index * 10
  return 232 + index, gray, gray, gray
end

---Pretty jank RGB-based distance function. No attempt
---is made for high accuracy.
---@param r1 number 0-255
---@param g1 number 0-255
---@param b1 number 0-255
---@param r2 number 0-255
---@param g2 number 0-255
---@param b2 number 0-255
---@return number distanceToColor
local function colorDistance(r1, g1, b1, r2, g2, b2)
  return abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
end

---A base class factory.
---@param members table A table of members to add to the generated class.
---@return Class
function Class(members)
  members = members or {}

  local mt = {
    __metatable = members,
    __index     = members,
  }

  local function new(_, init)
    return setmetatable(init or {}, mt)
  end

  local function copy(obj, ...)
    local newobj = obj:new(unpack(arg))
    for n, v in pairs(obj) do newobj[n] = v end
    return newobj
  end

  members.new  = members.new or new
  members.copy = members.copy or copy

  return mt
end

---Desaturates Colr
---@param color Colr
---@param amount number?
local function desaturate(color, amount)
  amount = amount or 10
  local hsl = color:toHsl()
  hsl.s = hsl.s - (amount / 100)
  hsl.s = clamp01(hsl.s)
  return Colr:new(hsl)
end

---Saturates Colr
---@param color Colr
---@param amount number?
local function saturate(color, amount)
  amount = amount or 10
  local hsl = color:toHsl()
  hsl.s = hsl.s + (amount / 100)
  hsl.s = clamp01(hsl.s)
  return Colr:new(hsl)
end

---Converts color to greyscale
---@param color Colr
---@return Colr
local function greyscale(color)
  return desaturate(color, 100)
end

---Lightens color
---@param color Colr
---@param amount number?
---@return Colr
local function lighten(color, amount)
  amount = amount or 10
  local hsl = color:toHsl()
  hsl.l = hsl.l + (amount / 100)
  hsl.l = clamp01(hsl.l)
  return Colr:new(hsl)
end

---Darkens color
---@param color Colr
---@param amount number?
---@return Colr
local function darken(color, amount)
  amount = amount or 10
  local hsl = color:toHsl()
  hsl.l = hsl.l - (amount / 100)
  hsl.l = clamp01(hsl.l)
  return Colr:new(hsl)
end

---Brightens Colr
---@param color Colr
---@param amount number?
---@return Colr
local function brighten(color, amount)
  amount = amount or 10
  local rgb = color:toRgb()
  rgb.r = max(0, min(255, rgb.r - round(255 * -(amount / 100))))
  rgb.g = max(0, min(255, rgb.g - round(255 * -(amount / 100))))
  rgb.b = max(0, min(255, rgb.b - round(255 * -(amount / 100))))
  return Colr:new(rgb)
end

---Spin takes a positive or negative amount within [-360, 360] indicating the change of hue.
---Values outside of this range will be wrapped into this range.
---@param color Colr
---@param amount number
---@return Colr
local function spin(color, amount)
  local hsl = color:toHsl()
  local hue = (hsl.h + amount) % 360
  if hue < 0 then
    hsl.h = 360 + hue
  else
    hsl.h = hue
  end

  return Colr:new(hsl)
end

---Calculates and returns the complement of the passed Colr
---@param color Colr
---@return Colr
local function complement(color)
  local hsl = color:toHsl()
  hsl.h = (hsl.h + 180) % 360
  return Colr:new(hsl)
end

---Calculates and returns the split complement of the passed Colr
---@param color Colr
---@return Colr[]
local function splitcomplement(color)
  local hsl = Colr:new(color):toHsl()
  local h = hsl.h
  return {
    color:clone(),
    Colr:new({ h = (h + 72) % 360, s = hsl.s, l = hsl.l }),
    Colr:new({ h = (h + 216) % 360, s = hsl.s, l = hsl.l })
  }
end

---Returns a list of colors spread equally around the color circle.
---@param color Colr
---@param number number
---@return Colr[]
local function polyad(color, number)
  if isNaN(number) or number <= 0 then
    error("Argument to polyad must be a postive number")
  end

  local hsl = color:toHsl()
  local result = {
    color:clone()
  }

  local step = 360 / number

  for i = 1, number do
    table.insert(result, Colr:new({
      h = (hsl.h + i * step) % 360,
      s = hsl.s,
      l = hsl.l
    }))
  end

  return result
end

---Computes and returns list of analogous colors
---@param color Colr
---@param results number?
---@param slices number?
---@return Colr[]
local function analogous(color, results, slices)
  results = results or 6
  slices = slices or 30

  local hsl = color:toHsl()
  local part = 360 / slices
  local ret = {
    color:clone()
  }

  hsl.h = (hsl.h - ((part * results) / 2) + 720) % 360

  repeat
    hsl.h = (hsl.h + part) % 360
    table.insert(ret, Colr:new(hsl))
    results = results - 1
  until results == 0

  return ret
end

---Create monochromatic palette
---@param color Colr
---@param results number?
---@return Colr[]
local function monochromatic(color, results)
  results = results or 6
  local hsv = color:toHsv()
  local h = hsv.h
  local s = hsv.s
  local v = hsv.v
  local ret = {}
  local mod = 1 / results

  while results ~= 0 do
    table.insert(ret, Colr:new({ h = h, s = s, v = v }))
    v = (v + mod) % 1
    results = results - 1
  end

  return ret
end
----------------------------------------------------------

--  Class

----------------------------------------------------------

Colr = {
  names = names,
  hexNames = hexNames,
  xtermIndices = xtermIndices
}

local Colr_mt = Class(Colr)
Colr_mt.__tostring = toString

---Tests if color is a Colr
---@param color any
---@return boolean
Colr.isColor = function(color)
  if type(color) ~= "table" then
    return false
  end

  return color["__color"] ~= nil
end

---Tests for equality of Colr's
---@param color1 Colr
---@param color2 Colr
---@return boolean
Colr.equals = function(color1, color2)
  return color1:toString() == color2:toString()
end

---Mixes colors 1 and 2 by amount%, and returns new Colr
---@param color1 Colr
---@param color2 Colr
---@param amount number? Defaults to 50%
---@return Colr
Colr.mix = function(color1, color2, amount)
  amount = amount or 50

  local rgb1 = Colr:new(color1):toRgb()
  local rgb2 = Colr:new(color2):toRgb()

  local p = amount / 100

  local rgba = {
    r = (rgb2.r - rgb1.r) * p + rgb1.r,
    g = (rgb2.g - rgb1.g) * p + rgb1.g,
    b = (rgb2.b - rgb1.b) * p + rgb1.b,
    a = (rgb2.a - rgb1.a) * p + rgb1.a,
  }

  return Colr:new(rgba)
end

---Returns index to the closest xterm color (or grayscale color)
---@param color Colr
---@return number
Colr.nearestXTermColorIndex = function(color)
  local rgb = color:toRgb()

  local idx1, r1, g1, b1 = nearestXtermColor(rgb.r, rgb.g, rgb.b)
  local idx2, r2, g2, b2 = nearestXtermGrayscaleColor(rgb.r, rgb.g, rgb.b)
  local dist1 = colorDistance(rgb.r, rgb.g, rgb.b, r1, g1, b1)
  local dist2 = colorDistance(rgb.r, rgb.g, rgb.b, r2, g2, b2)
  return dist1 < dist2 and idx1 or idx2
end

---Creates a new Colr instance
---@param color Colr|number|string?
---@param options ColrOptions?
---@return Colr
function Colr:new(color, options)
  local c = color or ""
  local opts = options or {}

  if Colr.isColor(c) then
    return color --[[@as Colr]]
  end

  local rgb = inputToRGB(color)

  if rgb.r < 1 then
    rgb.r = round(rgb.r)
  end

  if rgb.g < 1 then
    rgb.g = round(rgb.g)
  end

  if rgb.b < 1 then
    rgb.b = round(rgb.b)
  end

  local format

  if opts.format ~= nil then
    format = opts.format
  else
    format = rgb.format
  end

  local r = rgb.r
  local g = rgb.g
  local b = rgb.b
  local a = rgb.a
  local roundA = round(100 * a) / 100
  local gradType = opts.gradientType
  local ok = rgb.ok

  return setmetatable({
    _r = r,
    _g = g,
    _b = b,
    _a = a,
    _roundA = roundA,
    _gradientType = gradType,
    _format = format,
    _ok = ok,
    _originalInput = color,
    __color = true
  }, Colr_mt)
end

---Returns an RGBAColor
---@return RGBAColor
function Colr:toRgb()
  return {
    r = round(self._r),
    g = round(self._g),
    b = round(self._b),
    a = round(self._a)
  }
end

---Converts to HSLA and returns HSLAColor
---@return HSLAColor
function Colr:toHsl()
  local hsl = rgbToHsl(self._r, self._g, self._b)
  return {
    h = hsl.h * 360,
    s = hsl.s,
    l = hsl.l,
    a = self._a
  }
end

---Converts to HSVA and returns HSVAColor
---@return HSVAColor
function Colr:toHsv()
  local hsv = rgbToHsv(self._r, self._g, self._b)
  return {
    h = hsv.h * 360,
    s = hsv.s,
    v = hsv.v,
    a = self._a
  }
end

---Converts to RGB Tuple and returns.
---@return RGBColorTuple
function Colr:toRgbTuple()
  local rgb = self:toRgb()
  return {
    rgb.r,
    rgb.g,
    rgb.b
  }
end

---Converts to a percentage-based RGB value.
---@return PRGBAColor
function Colr:toPercentageRgb()
  return {
    r = round(bound01(self._r, 255) * 100) .. "%",
    g = round(bound01(self._g, 255) * 100) .. "%",
    b = round(bound01(self._b, 255) * 100) .. "%",
    a = self._a
  }
end

---Returns CSS-style RGB String
---@return string
function Colr:toRgbString()
  local r = round(self._r)
  local g = round(self._g)
  local b = round(self._b)

  if self._a == 1 then
    return "rgb(" .. r .. ", " .. g .. ", " .. b .. ")"
  else
    return "rgba(" .. r .. ", " .. g .. ", " .. b .. ", " .. self._roundA .. ")"
  end
end

---Returns CSS-style HSV string
---@return string
function Colr:toHsvString()
  local hsv = rgbToHsv(self._r, self._g, self._b)
  local h = round(hsv.h * 360)
  local s = round(hsv.s * 100)
  local v = round(hsv.v * 100)

  if self._a == 1 then
    return "hsv(" .. h .. ", " .. s .. "%, " .. v .. "%)"
  else
    return "hsva(" .. h .. ", " .. s .. "%, " .. v .. "%, " .. self._roundA .. ")"
  end
end

---Returns CSS-Style HSL String
---@return string
function Colr:toHslString()
  local hsl = rgbToHsl(self._r, self._g, self._b)
  local h = round(hsl.h * 360)
  local s = round(hsl.s * 100)
  local l = round(hsl.l * 100)

  if self._a == 1 then
    return "hsl(" .. h .. ", " .. s .. "%, " .. l .. "%)"
  else
    return "hsla(" .. h .. ", " .. s .. "%, " .. l .. "%, " .. self._roundA .. ")"
  end
end

---Returns a Percentage-based RGBA String
---@return string
function Colr:toPercentageRgbString()
  local r = round(bound01(self._r, 255) * 100)
  local g = round(bound01(self._g, 255) * 100)
  local b = round(bound01(self._b, 255) * 100)

  if self._a == 1 then
    return "rgb(" .. r .. "%, " .. g .. "%, " .. b .. "%)"
  else
    return "rgba(" .. r .. "%, " .. g .. "%, " .. b .. "%, " .. self._roundA .. ")"
  end
end

---Returns hex value for color
---@param allow3Char boolean Allow shortened rgb format (fff vs ffffff) if applicable.
---@return string
function Colr:toHex(allow3Char)
  return rgbToHex(self._r, self._g, self._b, allow3Char)
end

---Returns hex string for color
---@param allow3Char boolean Allow shortened rgb format (#fff vs #ffffff) if applicable.
---@return string
function Colr:toHexString(allow3Char)
  return "#" .. self:toHex(allow3Char)
end

---Returns hex value for color including alpha
---@param allow4Char boolean Allow shortened rgb format (ffff vs ffffffff) if applicable.
---@return string
function Colr:toHex8(allow4Char)
  return rgbaToHex(self._r, self._g, self._b, self._a, allow4Char)
end

---Returns hex string for color including alpha
---@param allow4Char boolean Allow shortened rgb format (#ffff vs #ffffffff) if applicable.
---@return string
function Colr:toHex8String(allow4Char)
  return "#" .. self:toHex8(allow4Char)
end

---Returns if input was parsed to a valid state.
---@return boolean
function Colr:isValid()
  return self._ok
end

---Returns original input string
---@return string
function Colr:getOriginalInput()
  return self._originalInput
end

---Returns color format
---@return ColorFormat
function Colr:getFormat()
  return self._format
end

---Returns alpha value
---@return number
function Colr:getAlpha()
  return self._a
end

---Sets alpha value, returns instance.
---@param value number
---@return Colr
function Colr:setAlpha(value)
  self._a = boundAlpha(value)
  self._roundA = round(100 * self._a) / 100
  return self
end

---Calculates and returns brightness of color
---@return number
function Colr:getBrightness()
  local rgb = self:toRgb()
  return (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000.0
end

---Calculates and returns luminance of color
---@return number
function Colr:getLuminance()
  local rgb = self:toRgb()
  local RsRGB, GsRGB, BsRGB, R, G, B
  RsRGB = rgb.r / 255
  GsRGB = rgb.g / 255
  BsRGB = rgb.b / 255

  if RsRGB <= 0.03928 then
    R = RsRGB / 12.92
  else
    R = pow((RsRGB + 0.055) / 1.055, 2.4)
  end

  if GsRGB <= 0.03928 then
    G = GsRGB / 12.92
  else
    G = pow((GsRGB + 0.055) / 1.055, 2.4)
  end

  if BsRGB <= 0.03928 then
    B = BsRGB / 12.92
  else
    B = pow((BsRGB + 0.055) / 1.055, 2.4)
  end

  return 0.2126 * R + 0.07152 * G + 0.0722 * B
end

---Is color perceptually dark?
---@return boolean
function Colr:isDark()
  return self:getBrightness() < 128
end

---Is color perceptually light?
---@return boolean
function Colr:isLight()
  return not self:isDark()
end

---Return the color name if it exists, false otherwise.
---@return string|boolean
function Colr:toName()
  if self._a == 0 then
    return "transparent"
  end

  return Colr.hexNames[rgbToHex(self._r, self._g, self._b, true)] or false
end

---Renders color as string
---@param format ColorFormat?
---@return string
function Colr:toString(format)
  return toString(self, format)
end

---Returns a clone of the Colr instance.
---@return Colr
function Colr:clone()
  return Colr:new(self:toString())
end

---Lightens color by amount.
---@param amount number? Default is 10
---@return Colr
function Colr:lighten(amount)
  return lighten(self, amount)
end

---Brightens color by amount
---@param amount number? Default is 10
---@return Colr
function Colr:brighten(amount)
  return brighten(self, amount)
end

---Darkens color by amount
---@param amount number? Default is 10
---@return Colr
function Colr:darken(amount)
  return darken(self, amount)
end

---Desaturates color by amount
---@param amount number? Default is 10
---@return Colr
function Colr:desaturate(amount)
  return desaturate(self, amount)
end

---Saturates color by amount
---@param amount number? Default is 10
---@return Colr
function Colr:saturate(amount)
  return saturate(self, amount)
end

---Converts color to greyscale
---@return Colr
function Colr:greyscale()
  return greyscale(self)
end

---Spins color by amount degrees.
---@param amount number
---@return Colr
function Colr:spin(amount)
  return spin(self, amount)
end

---Computes and results list of analogous colors
---@param results number? Number of colors to generate. Defaults to 6
---@param slices number? Size of the slices. Defaults to 30
---@return Colr[]
function Colr:analogous(results, slices)
  return analogous(self, results, slices)
end

---Computes and returns the complement of the Colr
---@return Colr
function Colr:complement()
  return complement(self)
end

---Computes and returns a palette of colors based on the same hue.
---@param results number? Number of colors to generate. Defaults to 6
---@return Colr[]
function Colr:monochromatic(results)
  return monochromatic(self, results)
end

---Returns the split complement of the color.
---@return Colr[]
function Colr:splitcomplement()
  return splitcomplement(self)
end

---Computes and returns the triad of the passed Colr
---@return Colr[]
function Colr:triad()
  return polyad(self, 3)
end

---Computes and returns the tetrad of the passed Colr
function Colr:tetrad()
  return polyad(self, 4)
end

return Colr

----------------------------------------------------------

--  Terminal

----------------------------------------------------------

-- local function dump(color)
--   for k, v in pairs(color) do
--     print(k, v)
--   end
-- end

-- local test2 = Colr:new("#ffff00")
-- dump(test2)

-- print(test2:isValid())
-- print(test2:getOriginalInput())
-- print(test2:getBrightness())
-- print(test2:getLuminance())
-- print(test2:isDark())
-- print(test2:isLight())
-- print(test2:toRgbString())
-- print(test2:toHsvString())
-- print(test2:toHslString())
-- print(test2:toHex())
-- print(test2:toHexString())
-- print(test2:toHex8())
-- print(test2:toHex8String())
-- print(test2.names["red"])
-- print(test2.hexNames["f00"])
-- dump(test2:toPercentageRgb())
-- print(test2:toPercentageRgbString())
-- dump(test2:toRgbTuple())
-- print("---")
-- dump(test2:monochromatic())
