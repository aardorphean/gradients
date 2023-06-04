---Disable to ignore 7th 'hidden' parameter in Hyperlink
---@diagnostic disable: redundant-parameter

dofile(GetInfo(60) .. "aardwolf_colors.lua")

local Gradient = dofile(GetInfo(60) .. "gradlib.lua")
local utils = require("utils")
local sqlite3 = require("sqlite3")

local VERSION = "1.0"

----------------------------------------------------------

--  Types

----------------------------------------------------------

---@alias Gradient { name: string, colors: Colr[], cycles: number?, reversed: boolean? }

---@alias TokenType
---| "string"
---| "keyword"
---| "number"
---| "boolean"
---| "any"

---@alias Token { value: string|number|boolean?, type: TokenType }

---@alias HelpCategory
---| "Meta"
---| "Use"
---| "Manage"

---@alias HelpEntry { command: string, summary: string, body: string}

----------------------------------------------------------

--  Data Tables

----------------------------------------------------------

---@type ColorInput[]
local uiGradientColors = {
  "#ffff00",
  "#00ffff",
  "#ff00ff"
}

---@type { [HelpCategory]: {[string]: HelpEntry} }
local helpFiles = {
  Meta = {
    Help = {
      command = "grad help [topic]",
      summary = "Help about Help!",
      body = [[grad help by itself will show a categorized index of all help files.

Passing in a topic will pull up the help file for that specific command for
more detailed help.]],
    }
  },
  Use = {
    Send = {
      command = "grad send <gradient name> <command>",
      summary = "Use a saved gradient to send to a channel, tell, say, etc.",
      body = [[This uses a saved gradient to send colored text to whereever you tell it to go.
The command passed in is whatever you would normally send to the mud when
you're using channels, says, tells, etc.

Examples:
  grad send rainbow say This text will be all rainbowy yay.

  grad send pastelbow tell neeper womble time!

  grad send purplish gt Hey group look at my colored text zomg.]],
    },
    Print = {
      command = "grad print <gradient name> <text>",
      summary = "Print an Aard color string using a saved gradient.",
      body = [[This prints an Aard-encoded colored string with color codes for use in item
descriptions, room descriptions, restrings, etc whatever.

The output gives you the string for easy copy and pasting and also provides the
length of the string with and without color codes included.

Examples:
  grad print rainbow My Awesome Item]],
    },
    Escaped = {
      command = "grad escaped <gradient name> <text>",
      summary = "Print an escaped Aard color string using a saved gradient.",
      body = [[This prints an escaped Aard-encoded colored string with color codes. Mostly
useful for when you need to send a colored string that needs to be parsed
again.  For example, when renaming groups using one of the many group inviter
plugins.

The output gives you the string for easy copy and pasting and also provides the
length of the string with and without color codes included.

Examples:
  grad escaped rainbow My Awesome Item]],
    },
    MSend = {
      command = "grad msend <color1,color2,...>:<cycles>:<reversed>|<target>=<text>",
      summary = "Specify a gradient on the fly to send to a channel, tell, say, etc.",
      body = [[This is similar to Send but Manual hence MSend. Instead of using a saved
gradient, you pass in a specially formatted string to specify a gradient on an
ad-hoc basis. Useful for quick testing and messing around.

The format is more complicated but we'll step through it item by item:

<color1, color2,...> - It starts with a list of colors. These can be HTML style
hex codes, xterm indices (the number after @x when doing Aard colors), or
simple color names (red, orange, etc). There is no effective limit on the
number of colors provided but there must be at least two.

<cycles> - This is the number of times the list of colors will be cycled
through over a given piece of text. Hard to explain, easy to see. Play around
with it. Optional, if you don't provide a value, it defaults to 1.

<reversed> - Tells the plugin to go through the colors in reverse order. Can
sometimes be helpful to create a different color layout over a piece of text.
Values accepted are true and false. Optional, if you don't provide a value, it
defaults to false.

<target> - The command you want to send to the mud. E.g.; say, gt, tell Saraid,
clantalk, etc.

<text> - The actual text you want to be all colorful and pretty.

Examples:
  grad msend red,blue|say=This will be a blend from red to blue.

  grad msend #ffff00, #00ffff, #ff00ff:2|gt=Print pastel colors to group.

  grad msend orange,#f00,#00f:4:true|tell saraid=4 cycles and reversed order.]],
    },
    MPrint = {
      command = "grad mprint <color1,color2,...>:<cycles>:<reversed>|<text>",
      summary = "Print an Aard color string using an ad-hoc gradient.",
      body = [[This is similar to Print but Manual hence MPrint. Instead of using a saved
gradient, you pass in a specially formatted string to specify a gradient in an
ad-hoc basis.  Useful for quick testing and messing around.

The format is more complicated but we'll step through it item by item:

<color1, color2,...> - It starts with a list of colors. These can be HTML style
hex codes, xterm indices (the number after @@x when doing Aard colors), or
simple color names (red, orange, etc). There is no effective limit on the
number of colors provided but there must be at least two.

<cycles> - This is the number of times the list of colors will be cycled
through over a given piece of text. Hard to explain, easy to see. Play around
with it. Optional, if you don't provide a value, it defaults to 1.

<reversed> - Tells the plugin to go through the colors in reverse order. Can
sometimes be helpful to create a different color layout over a piece of text.
Values accepted are true and false. Optional, if you don't provide a value, it
defaults to false.

<text> - The actual text you want to be all colorful and pretty.

Examples:
  grad mprint red,blue|This will be a blend from red to blue.

  grad msend #ffff00, #00ffff, #ff00ff:2|Print as pastel colors with 2 cycles.

  grad msend orange, #f00, #00f:4:true|Print with 4 cycles and reversed order.]],
    },
    MEscaped = {
      command = "grad mescaped <color1,color2,...>:<cycles>:<reversed>|<text>",
      summary = "Print an escaped Aard color string using an ad-hoc gradient.",
      body = [[This is the same command as MPrint but - like Escaped - prints an
escaped Aard-encoded string for passing to a group rename command, etc.

See grad help mprint for details on the format.]],
    },
    Report = {
      command = "grad report <target> <gradientName>",
      summary = "Generates an export string and reports it to the given target.",
      body = [[This command is used to easily share gradients with other people without having
to copy and paste the export string.

<target> is the command you want to send to the mud. For example, say, clantalk,
tell saori, gossip, etc.

<gradientName> is the name of the gradient you want to report.

Examples:
      grad report gt rainbow

      grad report tell rhymes pastelbow]]
    }
  },
  Manage = {
    List = {
      command = "grad list",
      summary = "Show all saved gradients and manage them.",
      body = [[Shows a list of all saved gradients. New gradients may be created here by
clicking New Gradient.

Existing gradients may be removed by clicking on their corresponding Remove
link. View will show the gradient settings in more detail and allow you to
edit them.]],
    },
    View = {
      command = "grad view <gradient name>",
      summary = "View details for a specific saved gradient.",
      body = [[Views the details of the passed gradient name.

Allows you to rename the gradient, edit the cycle count, and toggle
the reversed status.

A color management table allows for the addition, removal, moving, and
editing of colors.  All the links have tool tips and it should be fairly
self explanatory.]]
    },
    Gradient = {
      command = "grad gradient <subcommand> <arguemtns>",
      summary = "Creates and deletes gradients.",
      body = [[You may never use this command directly since the user interface will
call it for you. But this is the command to create and delete existing
gradients. There are two subcommands described as follows:

grad gradient new prompt|<name>

The new subcommand will create a gradient with default values for later
editing. If 'prompt' is used instead of a name, then a dialog box will
open and prompt you to enter the name for the new gradient.  Otherwise,
the passed in name will be used.

grad gradient remove <name>

The remove subcommand deletes the passed in gradient. There is a
confirmation step required before the gradient is actually removed.]]
    },
    Export = {
      command = "grad export all|<gradient name>",
      summary = "Generates an export string for all gradients or just the given one.",
      body = [[This is used to export gradients for sharing, backup, etc. It has a single
parameter.  If the parameter is 'all' then it will export every saved
gradient currently in the plugin.  Otherwise, it will attempt to export
the gradient whose name matches the value you passed into it.

Examples:
      grad export all

      grad export rainbow]]
    },
    Import = {
      command = "grad import <import string>",
      summary = "Attempts to import gradients from the provided import string.",
      body = [[This command is used to import gradients that were generated by the export or
report commands. It takes a single parameter which is the generated export
string you're trying to import. If importing multiple gradients and one fails
it will continue importing all the ones it can and show a total imported value.

Example:

      grad import pastelbow```#ffff00|#00ffff|#ff00ff```2```false]]
    },
    Sampler = {
      command = "grad sampler <sample text>",
      summary = "Prints the given text using all saved gradients.",
      body = [[This simply prints out the name of each gradient and what the
passed in text looks like using that gradient. Like a design sampler.]],
    },
    Modify = {
      command = "grad modify <gradient name> <subcommand> <subcommand options>",
      summary = "Change All the Things about a saved gradient.",
      body = [[This is a fairly large command. Luckily, chances are you will rarely if ever
use this command directly. The user interface uses this command to do all
the different modifications that are supported.

This command is really multiple sub-commands grouped under a common banner.
We'll go through each of these sub-commands one by one:

grad modify <gradient name> color <index number> move up

Moves the color located at 'index number' in the color list higher in the list
of colors that belong to the gradient.

grad modify <gradient name> color <index number> move down

Moves the color located at 'index number' in the color list lower in the list
of colors that belong to the gradient.

grad modify <gradient name> color <index number> lighten

Lightens the color located at 'index number' in the color list. If the color
is greyscale then the mathematical result is considred achromatic and the
color is set to white.  Use on non-grey colors.

grad modify <gradient name> color <index number> darken

Darkens the color located at 'index number' in the color list. If the color
is greyscale then the mathematical result is considred achromatic and the
color is set to white.  Use on non-grey colors.

grad modify <gradient name> color <index number> edit prompt|<color value>

This edits the color located at 'index number' in the color list. If the
value is 'prompt' instead of a color value then a dialog will display asking
for the new color value for the color. Otherwise, any valid color input is
accepted. These include HTML-style hex codes, plain color names (lightblue,
orange, red, etc), and Xterm color indices (the number after the @@x when you
are using Aard-colors.)

grad modify <gradient name> color <index number> remove

This will remove the color located at 'index number' from the color list. A
gradient must have at least two colors and it will not allow you remove the
color if there would only be a single remaining color.

grad modify <gradient name> color new prompt|<color input>

This adds a new color to the end of the gradient's color list. If the value
is 'prompt' instead of a color value then a dialog will display asking for
the new color value. Otherwise, any valid color input is accepted. These
include HTML-style hex codes, plain color names (lightblue, orange, red, etc),
and Xterm color indices (the number after the @@x when you are using
Aard-colors.)

grad modify <gradient name> cycles increase <amount>

Increases the cycle count of the given gradient by amount. A common value for
amount would be 1.

grad modify <gradient name> cycles decrease <amount>

Decreases the cycle count of the given gradient by amount. A common value for
amount would be 1. Cycles cannot be lower than 1.

grad modify <gradient name> reversed toggle|true|false

Modifies the given gradient's reversed flag. A value of 'true' enables the flag,
a value of 'false' disables it.  Lastly, a value of toggle will reverse the flag
based on its current value.

grad modify <gradient name> rename prompt|<name>

Renames the given gradient. If the value provided is 'prompt' then a dialog box
will be shown asking for the new name. Otherwise, the given name is used. The name
cannot be blank or only consist of numbers.]]
    }
  },
}

---@type { [string]: boolean }
local keywords = {
  increase = true,
  decrease = true,
  remove = true,
  prompt = true,
  new = true,
  rename = true,
  cycles = true,
  reversed = true,
  toggle = true,
  color = true,
  move = true,
  up = true,
  down = true,
  lighten = true,
  darken = true,
  gradient = true,
  edit = true,
  msend = true,
  mescaped = true,
  mprint = true,
  sampler = true,
  all = true,
  export = true,
  import = true
}

---@type { [string]: Token[][] }
local parameters = {
  msend = {
    {
      {
        type = "any"
      }
    }
  },
  mprint = {
    {
      {
        type = "any"
      }
    }
  },
  mescaped = {
    {
      {
        type = "any"
      }
    }
  },
  send = {
    {
      {
        type = "any"
      }
    }
  },
  print = {
    {
      {
        type = "any"
      }
    }
  },
  escaped = {
    {
      {
        type = "any"
      }
    }
  },
  sampler = {
    {
      { type = "any" }
    }
  },
  view = {
    {
      {
        type = "string"
      }
    }
  },
  export = {
    {
      { type = "keyword", value = "all" }
    },
    {
      { type = "string" }
    }
  },
  import = {
    {
      { type = "keyword", value = "prompt" }
    },
    {
      { type = "any" }
    }
  },
  report = {
    {
      { type = "string" }
    }
  },
  modify = {
    {
      { type = "string" },
      { type = "keyword", value = "cycles" },
      { type = "keyword", value = "increase" },
      { type = "number" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "cycles" },
      { type = "keyword", value = "decrease" },
      { type = "number" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "reversed" },
      { type = "keyword", value = "toggle" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "reversed" },
      { type = "boolean" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "rename" },
      { type = "keyword", value = "prompt" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "rename" },
      { type = "string" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "number" },
      { type = "keyword", value = "lighten" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "number" },
      { type = "keyword", value = "darken" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "number" },
      { type = "keyword", value = "remove" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "number" },
      { type = "keyword", value = "edit" },
      { type = "keyword", value = "prompt" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "number" },
      { type = "keyword", value = "edit" },
      { type = "string" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "number" },
      { type = "keyword", value = "move" },
      { type = "keyword", value = "up" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "number" },
      { type = "keyword", value = "move" },
      { type = "keyword", value = "down" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "keyword", value = "new" },
      { type = "keyword", value = "prompt" }
    },
    {
      { type = "string" },
      { type = "keyword", value = "color" },
      { type = "keyword", value = "new" },
      { type = "string" }
    }
  },
  gradient = {
    {
      { type = "keyword", value = "new" },
      { type = "string" }
    },
    {
      { type = "keyword", value = "new" },
      { type = "keyword", value = "prompt" }
    },
    {
      { type = "keyword", value = "remove" },
      { type = "string" }
    }
  }
}

----------------------------------------------------------

--  Utilities

----------------------------------------------------------

---Returns iterator that traverses table following order of its keys.
---From Programming in Lua 19.3
---@param t table
---@param f function?
---@return function
function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0             -- iterator variable
  local iter = function() -- iterator function
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end

  return iter
end

---Converts token to string
---@param token Token
---@return string
local function tokenToString(token)
  local tokenType = "<" .. token["type"] .. ">"

  if type(token["value"]) == "nil" then
    return tokenType
  else
    return token["value"] .. " " .. tokenType
  end
end

---Returns a shallow copy of a subset of a table.
---@param t table
---@param s integer
---@param e integer
---@return table
local function slice(t, s, e)
  local pos, new = 1, {}

  for i = s, e do
    new[pos] = t[i]
    pos = pos + 1
  end

  return new
end

---Escapes special characters for pattern matching
---@param str string
---@return string
local function escapePattern(str)
  return (str:gsub('%%', '%%%%')
    :gsub('^%^', '%%^')
    :gsub('%$$', '%%$')
    :gsub('%(', '%%(')
    :gsub('%)', '%%)')
    :gsub('%.', '%%.')
    :gsub('%[', '%%[')
    :gsub('%]', '%%]')
    :gsub('%*', '%%*')
    :gsub('%+', '%%+')
    :gsub('%-', '%%-')
    :gsub('%?', '%%?'))
end

---Trims whitespace from string
---@param str string
---@return string
local function trim(str)
  return str:match '^()%s*$' and '' or str:match '^%s*(.*%S)'
end

---Returns the first word in a string
---@param str string The deliminated string
---@param delimiter string? The separator character. Defaults to space.
---@return string head The first 'word' in the string
local function head(str, delimiter)
  local delim = delimiter or " "

  if not str then
    return ""
  end

  local result = string.match(str, "^[^" .. escapePattern(delim) .. "]+")

  return result or ""
end

---Returns the rest of the words in a string
---@param str string The deliminated string
---@param delimiter string? The separator character. Defaults to space.
---@return string body The every after the head of the string
local function body(str, delimiter)
  local head = head(str, delimiter)
  local delim = delimiter or " "
  local hasMatches = string.match(str, head .. delim)

  if hasMatches then
    return (string.gsub(str, escapePattern(head .. delim), "", 1))
  else
    return ""
  end
end

---From GMCP Mapper: Formats booleans for database queries.
---@param b boolean
---@return integer
function fixbool(b)
  if b then
    return 1
  else
    return 0
  end
end

---Iterates through a delimiter separated string.
---Each chunk is passed through the supplied callback.
---@param str string
---@param callback fun(chunk: string): nil
---@param delimiter string? The delimiter to use. Defaults to space.
---@return nil
local function iter(str, callback, delimiter)
  local delim = delimiter or " "
  local head = head(str, delim)

  if head:len() ~= 0 then
    callback(head)
    iter(body(str, delim), callback, delim)
  end
end

---Strips color codes from passed string.
---@param str string
---@return string
local function stripCodes(str)
  local stripped = (str:gsub("@[Xx]%d%d?%d?", ""))
  return (stripped:gsub("@[a-zA-Z]", ""))
end

---Prints passed in text to console using
---provided colors for gradient.
---@param text string
---@param colors ColorInput[]
---@param reversed boolean?
local function printColor(text, colors, reversed)
  local rev = reversed or false
  local colored = Gradient:new():generate(text, colors, {
    reversed = rev
  })
  local styled = ColoursToANSI(colored)

  AnsiNote(styled)
end

---Prints a string using the gradient UI
---standard gradient.
---@param text string
---@param reversed boolean?
local function printUIString(text, reversed)
  local rev = reversed or false
  printColor(text, uiGradientColors, rev)
end

---Repeats a string a given number of times with an optional border.
---@param item string
---@param times number
---@param border string?
---@return string
local function strrepeat(item, times, border)
  local result = ""
  local borderChar = border and border or ""

  for _ = 1, times do
    result = result .. item
  end

  if (border) then
    result = borderChar .. result:sub(2, #result - 1) .. borderChar
  end

  return result
end

---Centers a string within a given width, an optional fill character,
---and an optional border string.
---@param item string
---@param width number
---@param char string? Defaults to space
---@param border string? Defaults to no border
local function center(item, width, char, border)
  local itemHalfLen = math.ceil(string.len(item) / 2)
  local widthHalfLen = math.ceil((width / 2))
  local itemStart = widthHalfLen - itemHalfLen
  local remainder = width - itemStart - string.len(item)
  local result = ""
  local centerChar = char and char or " "
  local borderChar = border and border or nil

  result = strrepeat(centerChar, itemStart) .. item .. strrepeat(centerChar, remainder)

  if (border) then
    result = borderChar .. result:sub(2, #result - 1) .. borderChar
  end

  return result
end

---Right pads the given string
---@param str string
---@param width number
---@param char? string Defaults to space
---@return string
local function rightpad(str, width, char)
  local char = char and char or " "
  local stripped = stripCodes(str)

  if #stripped == width then
    return str
  end

  if #stripped > width then
    str = stripped:sub(1, width)
  end

  return str .. string.rep(char, width - #stripped)
end

---Left pads the given string
---@param str string
---@param width number
---@param char? string Defaults to space
---@return string
local function leftpad(str, width, char)
  local char = char and char or " "
  local stripped = stripCodes(str)

  if #stripped == width then
    return str
  end

  if #stripped > width then
    str = stripped:sub(1, width)
  end

  return string.rep(char, width - #stripped) .. str
end

---Parses a gradient options text string and applies
---the result to the passed in text. Returns rendered string.
---@param optionsString string colors:cycles:reversed|target=text
---@param text string
---@return string renderedString
local function parseGradient(optionsString, text)
  local cycles = 1
  local reversed = false
  local options = {}
  local colors = {}

  iter(optionsString, function(o)
    options[#options + 1] = trim(o)
  end, ":")

  if #options == 1 then
    iter(options[1], function(c)
      if tonumber(c) then
        local index = math.floor(tonumber(c) --[[@as number]])

        if index >= 0 and index < 256 then
          c = Colr.xtermIndices[index]
        end
      end

      colors[#colors + 1] = Colr:new(trim(c))
    end, ",")
  elseif #options == 2 then
    iter(options[1], function(c)
      if tonumber(c) then
        local index = math.floor(tonumber(c) --[[@as number]])

        if index >= 0 and index < 256 then
          c = Colr.xtermIndices[index]
        end
      end

      colors[#colors + 1] = Colr:new(trim(c))
    end, ",")
    cycles = tonumber(options[2]) or 1
  elseif #options >= 3 then
    iter(options[1], function(c)
      if tonumber(c) then
        local index = math.floor(tonumber(c) --[[@as number]])

        if index >= 0 and index < 256 then
          c = Colr.xtermIndices[index]
        end
      end

      colors[#colors + 1] = Colr:new(trim(c))
    end, ",")
    cycles = tonumber(options[2]) or 1
    reversed = options[3] ~= "false"
  else
    error("Invalid options count.")
  end

  for k, v in ipairs(colors) do
    if tonumber(v) then
      local num = tonumber(v) --[[@as number]]
      colors[k] = Colr:new(num)
    end
  end

  return Gradient:new():generate(text, colors, {
    cycles = cycles,
    reversed = reversed
  })
end

----------------------------------------------------------

--  UI

----------------------------------------------------------

---Prints the header for UI elements
---@param title string
local function header(title)
  local titleStr = "--[ " .. title .. " ]"
  local headerStr = titleStr .. strrepeat("-", 80 - string.len(titleStr))

  printUIString(headerStr)
end

---Prints the footer for UI elements.
local function footer()
  local footerStr = strrepeat("_", 80)

  printUIString(footerStr)
end

---Prints a separator UI elements.
---@param reversed boolean?
local function separator(reversed)
  local rev = reversed or false
  local sep = strrepeat("-", 80)

  printUIString(sep, rev)
end

---Prints a titled separator for UI elements
---@param title string
---@param reversed boolean?
local function titledSeparator(title, reversed)
  local titleStr = "-- " .. title .. " "
  local headerStr = titleStr .. strrepeat("-", 80 - string.len(titleStr))

  printUIString(headerStr, reversed)
end

---Helper function to standardize error printing.
---@param title string
---@param msg string
---@param errorMsg string?
local function reportError(title, msg, errorMsg)
  local guru = Gradient:new():generate("Guru Meditation:", uiGradientColors)
  local message = "@w" .. msg

  if errorMsg ~= nil then
    message = message .. "\n\n" .. guru .. "\n" .. errorMsg
  end

  local colored = ColoursToANSI(message)

  header(title)
  AnsiNote(colored)
  footer()
end

----------------------------------------------------------

--  State

----------------------------------------------------------

---Opens and returns a handle to the database.
---@return userdata
local function openDatabase()
  local db = sqlite3.open(GetInfo(60) .. "Gradients.db")
  local db_tables = {}
  local query = "SELECT name FROM sqlite_master WHERE type='table'"
  local create_tables = {}

  for row in db:nrows(query) do
    db_tables[row.name] = true
  end

  if not db_tables["gradients"] then
    table.insert(
      create_tables,
      [[
				CREATE TABLE gradients (
                    name        TEXT NOT NULL,
                    colors      TEXT NOT NULL,
                    cycles      INTEGER,
                    reversed    INTEGER );
			]]
    )
  end

  if #create_tables > 0 then
    local result = db:execute(table.concat(create_tables, ""))

    if result ~= sqlite3.OK then
      reportError("Gradient Database Error", "I couldn't open or create our database!", result)
    end
  end

  return db
end

---Closes the database using the given handle.
---@param db userdata
local function closeDatabase(db)
  db:close_vm()
end

---Removes Gradient from the database
---@param gradient Gradient
local function removeGradient(gradient)
  local db = openDatabase()
  local deleteQuery = string.format(
    [[
          delete from gradients where name="%s"
    ]], gradient.name)

  local result = db:execute(deleteQuery)

  if result ~= sqlite3.OK then
    reportError("Gradient Database Error", "I couldn't remove the gradient!", result)
  end

  closeDatabase(db)
end

---Inserts or Updates Gradient to database
---@param gradient Gradient
local function upsertGradient(gradient)
  local db = openDatabase()
  local colrs = {}

  for _, color in pairs(gradient.colors) do
    table.insert(colrs, color:toHexString())
  end
  local saveColors = table.concat(colrs, "|")

  local existsQuery = string.format(
    [[
          select * from gradients where name = '%s'
    ]], gradient.name)

  local results = {}
  for _, v in db:urows(existsQuery) do
    table.insert(results, v)
  end
  local exists = #results > 0

  if exists then
    local updateQuery = string.format(
      [[
        update gradients set name="%s", colors="%s", cycles=%s, reversed=%s where name="%s"
      ]], gradient.name,
      saveColors,
      gradient.cycles,
      fixbool(gradient.reversed),
      gradient.name)

    local result = db:execute(updateQuery)

    if result ~= sqlite3.OK then
      reportError("Gradient Database Error", "I couldn't save the gradient!", result)
    end

    closeDatabase(db)
  else
    local insertQuery = string.format(
      [[
            INSERT INTO gradients VALUES ("%s", "%s", %s, %s)
        ]], gradient.name,
      saveColors,
      gradient.cycles,
      fixbool(gradient.reversed))

    local result = db:execute(insertQuery)

    if result ~= sqlite3.OK then
      reportError("Gradient Database Error", "I couldn't save the gradient!", result)
    end

    closeDatabase(db)
  end
end

---Returns a list of all saved gradients.
---@return Gradient[]
local function getGradients()
  local db = openDatabase()
  local query = "select * from gradients"
  local gradients = {}

  for row in db:nrows(query) do
    local reversed = false
    local colors = {}

    if row["reversed"] == 1 then
      reversed = true
    end

    iter(row["colors"], function(c)
      table.insert(colors, Colr:new(c))
    end, "|")

    if row["name"] and #row["name"] ~= 0 then
      table.insert(gradients, {
        name = row["name"],
        colors = colors,
        cycles = row["cycles"],
        reversed = reversed
      })
    end
  end

  closeDatabase(db)

  return gradients
end

---Gets Gradient by name
---@param name string
---@return Gradient
local function getGradientByName(name)
  local gradients = getGradients()
  local gradient

  for _, v in pairs(gradients) do
    if v["name"] == name then
      gradient = v
      break
    end
  end

  return gradient
end

----------------------------------------------------------

--  Argument Parsing

----------------------------------------------------------

---Parses args into a list of tokens.
---@param args string
---@param noCollapse boolean? If true, consequtive string tokens will not be collapsed into a single token.
---@return Token[]
local function parseArgs(args, noCollapse)
  local tokens = {}

  for chunk in args:gmatch("[^ ]+") do
    local token = {
      value = "",
      type = "string"
    }

    if chunk == "true" or chunk == "false" then
      token.type = "boolean"
      token.value = chunk == "true"
    elseif keywords[chunk] then
      token.type = "keyword"
      token.value = trim(chunk)
    elseif tonumber(chunk) then
      token.type = "number"
      token.value = tonumber(chunk) --[[@as number]]
    else
      token.type = "string"
      token.value = trim(chunk)
    end

    table.insert(tokens, token)
  end

  --Collapses consequtive string tokens into a single token.
  --Probably should have made this happen during the initial
  --tokenization but lazy :(  So we get this post-processing instead.
  if not noCollapse then
    local stringValue = ""
    local newTokens = {}

    for _, token in ipairs(tokens) do
      if token.type ~= "string" then
        if #stringValue > 0 then
          table.insert(newTokens, {
            type = "string",
            value = stringValue
          })
          stringValue = ""
        end

        table.insert(newTokens, token)
      else
        if #stringValue > 0 then
          stringValue = stringValue .. " " .. token.value
        else
          stringValue = token.value
        end
      end
    end

    -- Make sure to insert any leftover string bits as a token.
    if #stringValue > 0 then
      table.insert(newTokens, {
        type = "string",
        value = stringValue
      })
    end

    tokens = newTokens
  end

  return tokens
end

---Checks tokens against all possible sub-commands.
---Returns matching token list if a valid sub-command is found.
---@param command string
---@param args Token[]
---@return Token[]|nil
local function getCommand(command, args)
  if type(parameters[command]) == "nil" then
    return nil
  end

  local anyFound = false
  for _, format in ipairs(parameters[command]) do
    local matched = true

    for i = 1, #format do
      if type(args[i]) ~= "nil" then
        if format[i].type == "any" then
          anyFound = true
        end

        if args[i].type ~= format[i].type and not anyFound then
          matched = false
          break
        end

        if args[i].type == "keyword" and format[i].value ~= args[i].value then
          matched = false
          break
        end
      else
        matched = false
        break
      end
    end

    if matched then
      return format
    end
  end

  return nil
end

---Concatentes a token list to a single string token.
---@param tokens Token[]
---@return Token
local function concatTokens(tokens)
  local result = {
    type = "string",
    value = ""
  }

  for _, token in ipairs(tokens) do
    if type(token.value) == "boolean" then
      token.value = token.value and "true" or "false"
    end

    result.value = result.value .. " " .. token.value
  end

  result.value = trim(result.value)

  return result
end

----------------------------------------------------------

--  Sub-commands

----------------------------------------------------------

---Modifies a Gradient's Color array
---@param gradientName string
---@param args Token[]
---@param format Token[]
local function gradients_modify_color(gradientName, args, format)
  local gradient = getGradientByName(gradientName)

  if type(gradient) == "nil" then
    return
  end

  if format[1].type == "number" then
    local operation = format[2].value
    local opparams = slice(format, 3, #format)

    if operation == "move" then
      if opparams[1].value == "up" and args[1].value ~= 1 then
        local index = args[1].value --[[@as number]]

        gradient.colors[index], gradient.colors[index - 1] = gradient.colors[index - 1], gradient.colors[index]
        upsertGradient(gradient)
      end

      if opparams[1].value == "down" and args[1].value ~= #(gradient.colors) then
        local index = args[1].value --[[@as number]]

        gradient.colors[index], gradient.colors[index + 1] = gradient.colors[index + 1], gradient.colors[index]
        upsertGradient(gradient)
      end
    end

    if operation == "lighten" then
      gradient.colors[args[1].value] = gradient.colors[args[1].value]:lighten()
      upsertGradient(gradient)
    end

    if operation == "darken" then
      gradient.colors[args[1].value] = gradient.colors[args[1].value]:darken()
      upsertGradient(gradient)
    end

    if operation == "edit" then
      if opparams[1].type == "keyword" and opparams[1].value == "prompt" then
        local color = utils.inputbox("Please enter new value for color:", "Edit Color",
          gradient.colors[args[1].value]:toHexString())

        if color and #color ~= 0 then
          local c = Colr:new(color)

          if tonumber(color) then
            local index = math.floor(tonumber(color) --[[@as number]])

            if index >= 0 and index < 256 then
              c = Colr:new(Colr.xtermIndices[index])
            end
          end

          if not c or not c._ok then
            reportError("Error Creating Color?", "I couldn't figure out how to create a color based on what you gave me!")
          else
            gradient.colors[args[1].value] = c
            upsertGradient(gradient)
          end
        else
          reportError("Missing Color Value", "The color value can't be blank!")
        end
      end

      if opparams[1].type == "string" then
        local value = args[3].value --[[@as string]]
        local c = Colr:new(value)

        if tonumber(value) then
          local index = math.floor(tonumber(value) --[[@as number]])

          if index >= 0 and index < 256 then
            c = Colr:new(Colr.xtermIndices[index])
          end
        end

        if not c or not c._ok then
          reportError("Error Creating Color?", "I couldn't figure out how to create a color based on what you gave me!")
        else
          gradient.colors[args[1].value] = Colr:new(value)
          upsertGradient(gradient)
        end
      end
    end

    if operation == "remove" then
      if #(gradient.colors) == 2 then
        Note(" ")
        reportError("Gradient Must Have Two Colors",
          "Oops, a gradient must have at least two colors!\nTry to edit the color instead of removing it.")
        Note(" ")
      else
        local response = utils.msgbox("Are you sure you want to remove this color?", "Really remove color?", "yesno",
          "!", 2)

        if response ~= "no" then
          local index = args[1].value --[[@as number]]
          table.remove(gradient.colors, index)
          upsertGradient(gradient)
        end
      end
    end
  end

  if format[1].type == "keyword" and format[1].value == "new" then
    if format[2].type == "keyword" and format[2].value == "prompt" then
      local color = utils.inputbox("Please enter the color to add:", "Add New Color", "black", nil, nil)

      if color and #color ~= 0 then
        local c = Colr:new(color)

        if tonumber(color) then
          local index = math.floor(tonumber(color) --[[@as number]])

          if index >= 0 and index < 256 then
            c = Colr:new(Colr.xtermIndices[index])
          end
        end

        if not c or not c._ok then
          reportError("Error Creating Color?",
            "I couldn't figure out how to create a color based on what you gave me!")
        else
          gradient.colors[args[1].value] = c
          upsertGradient(gradient)
        end
      else
        reportError("Missing Color Value", "The color value can't be blank!")
      end
    end

    if format[2].type == "string" then
      local value = args[2].value --[[@as string|number]]
      local c = Colr:new(value)
      if not c or not c._ok then
        reportError("Error Creating Color?",
          "I couldn't figure out how to create a color based on what you gave me!")
      else
        gradient.colors[args[1].value] = c
        upsertGradient(gradient)
      end
    end
  end
end

---Modifies a Gradients cycle count
---@param gradientName string
---@param args Token[]
---@param format Token[]
local function gradients_modify_cycles(gradientName, args, format)
  local gradient = getGradientByName(gradientName)

  if type(gradient) == "nil" then
    return
  end

  local operation = format[1].value
  local amount = args[2].value

  if operation == "increase" then
    gradient.cycles = gradient.cycles + amount
    upsertGradient(gradient)
  end

  if operation == "decrease" and gradient.cycles > 1 then
    if gradient.cycles - amount < 1 then
      gradient.cycles = 1
    else
      gradient.cycles = gradient.cycles - amount
    end
    upsertGradient(gradient)
  end
end

---Modifies a Gradient's reversed attribute
---@param gradientName string
---@param args Token[]
---@param format Token[]
local function gradients_modify_reversed(gradientName, args, format)
  local gradient = getGradientByName(gradientName)

  if type(gradient) == "nil" then
    return
  end

  if format[1].type == "boolean" then
    gradient.reversed = args[1].value --[[@as boolean]]
    upsertGradient(gradient)
  end

  if format[1].type == "keyword" and format[1].value == "toggle" then
    gradient.reversed = not gradient.reversed
    upsertGradient(gradient)
  end
end

---Modifies a Gradient's name
---@param gradientName string
---@param args Token[]
---@param format Token[]
local function gradients_modify_rename(gradientName, args, format)
  local gradient = getGradientByName(gradientName)

  if type(gradient) == "nil" then
    return
  end

  if format[1].type == "keyword" and format[1].value == "prompt" then
    local name = utils.inputbox("Please enter a new name for the gradient:", "Rename " .. gradientName)

    if name then
      if #name == 0 then
        reportError("No Name Provided", "Please provide a name for the new gradient!")
      else
        local existing = getGradientByName(name)

        if type(existing) ~= "nil" then
          reportError("Duplicate Gradient Name", "Sorry, all gradients must have a unique name.")
        else
          removeGradient(gradient)
          gradient.name = name
          upsertGradient(gradient)
        end
      end
    end
  end

  if format[1].type == "string" then
    local newName = args[1].value --[[@as string]]

    local existing = getGradientByName(newName)

    if type(existing) ~= "nil" then
      reportError("Duplicate Gradient Name", "Sorry, all gradients must have a unique name.")
    else
      removeGradient(gradient)
      gradient.name = newName
      upsertGradient(gradient)
    end
  end
end

----------------------------------------------------------

--  Commands

----------------------------------------------------------

---List all Gradients
local function gradients_list()
  local gradients = getGradients()
  local headers = rightpad(" Name", 24) .. center("Cycles", 16) .. center("Reversed", 16) .. center("Actions", 24)

  header("Gradients")
  printUIString(headers)
  separator()
  for _, gradient in ipairs(gradients) do
    local reversed = "No"

    if gradient["reversed"] then
      reversed = "Yes"
    end

    local row = rightpad(" " ..
          gradient["name"], 24) ..
        center(gradient["cycles"] .. "", 16) ..
        center(reversed, 16)

    ColourTell("#FFEEEE", "", row .. "      ")
    Hyperlink("grad view " .. gradient["name"], "View", "View Gradient Details", "white", "", false)
    Tell(" ")
    Hyperlink("grad export " .. gradient["name"], "Export", "Export Gradient", "white", "", false)
    Tell(" ")
    Hyperlink("grad gradient remove " .. gradient["name"], "Remove", "Remove Gradient", "red", "", false)
    Note("")
  end
  separator()
  Tell(" ")
  Hyperlink("grad gradient new prompt", "Make New Gradient", "Create a new gradient!", "#FFEEEE", "", false)
  Tell(strrepeat(" ", 33))
  Hyperlink("grad import prompt", "Import Gradient(s)", "Import Gradient(s) from an Import String", "#FFEEEE", "",
    false)
  Tell(" ")
  Hyperlink("grad export all", "Export All", "Exports all gradients", "#FFEEEE", "", false)
  Note("")
  footer()
end

---View a specific Gradient's details
---@param args Token[]
local function gradients_view(args)
  local name = args[1].value --[[@as string]]
  local gradient = getGradientByName(name)

  if type(gradient) == "nil" then
    reportError("Gradient Not Found", "Couldn't find a gradient with the name " .. name .. "!")
    return
  end

  local reversed = "No"

  if gradient["reversed"] then
    reversed = "Yes"
  end

  Note(" ")
  header("View Gradient: " .. gradient["name"])
  ColourTell("#FFEEEE", "", leftpad(" Name: ", 12))
  ColourTell("#ffeeee", "", gradient["name"] .. " ")
  Hyperlink("grad modify " .. gradient["name"] .. " rename prompt", "Rename", "Rename Gradient", "white", "", false)
  Note("")
  ColourTell("#FFEEEE", "", leftpad(" Cycles: ", 12))
  Hyperlink("grad modify " .. gradient["name"] .. " cycles increase 1", "+", "Increase Cycle Count", "lime", "", false)
  ColourTell("#FFEEEE", "", "   " .. gradient["cycles"] .. "   ")
  Hyperlink("grad modify " .. gradient["name"] .. " cycles decrease 1", "-", "Decrease Cycle Count", "red", "", false)
  Note("")
  ColourTell("#FFEEEE", "", leftpad(" Reversed: ", 12))
  ColourTell("#ffeeee", "", reversed .. " ")
  Hyperlink("grad modify " .. gradient["name"] .. " reversed toggle", "Toggle", "Toggle Reversed", "white", "", false)
  Note("")
  separator()
  local headers = rightpad(" Move     Color", 32) .. strrepeat(" ", 30) .. "Actions"
  printUIString(headers)
  separator()

  for index, color in pairs(gradient["colors"]) do
    Tell(" ")
    Hyperlink("grad modify " .. gradient["name"] .. " color " .. index .. " move up", "/\\", "Move Up", "dodgerblue", "",
      false, true)
    Tell("  ")
    Hyperlink("grad modify " .. gradient["name"] .. " color " .. index .. " move down", "\\/", "Move Down", "dodgerblue",
      "", false, true)
    Tell("  ")

    ColourTell("#FFEEEE", "", " " .. color:toHexString() .. " ")
    ColourTell("", color:toHexString(), "  ")
    Tell(strrepeat(" ", 31))

    Hyperlink("grad modify " .. gradient["name"] .. " color " .. index .. " edit prompt", "Edit", "Edit Color",
      "#FFEEEE", "", false)
    Tell("  ")

    Hyperlink("grad modify " .. gradient["name"] .. " color " .. index .. " lighten", "Lighten", "Lighten Color",
      "#FFEEEE", "", false)
    Tell("  ")
    Hyperlink("grad modify " .. gradient["name"] .. " color " .. index .. " darken", "Darken", "Darken Color", "#FFEEEE",
      "", false)
    Tell("  ")

    Hyperlink("grad modify " .. gradient["name"] .. " color " .. index .. " remove", "Remove", "Remove Color", "red", "",
      false)

    Note("")
  end

  separator()
  Tell(" ")
  Hyperlink("grad modify " .. gradient["name"] .. " color new prompt", "Add New Color", "Add New Color", "#FFEEEE", "",
    false)

  Note("")

  footer()
end

---Gradient Modification Command
---@param args Token[]
---@param format Token[]
local function gradients_modify(args, format)
  local dispatch = {
    color = gradients_modify_color,
    cycles = gradients_modify_cycles,
    reversed = gradients_modify_reversed,
    rename = gradients_modify_rename
  }

  local name = args[1].value
  local subcommand = args[2].value
  local subargs = slice(args, 3, #args)
  local subformat = slice(format, 3, #format)
  local method = dispatch[subcommand]

  if type(method) ~= "nil" then
    method(name, subargs, subformat)

    if subcommand == "rename" then
      gradients_list()
    else
      gradients_view({ {
        type = "string",
        value = name
      } })
    end
  end
end

---Creates and sends a gradient with arbitrary options
---@param args Token[] colors:cycles:reversed|target=text
local function gradients_msend(args)
  local text = args[1].value --[[@as string]]
  local options = head(text, "|")
  local rest = body(text, "|")
  local target = head(rest, "=")
  local text = body(rest, "=")
  local ok, gradient = pcall(parseGradient, options, text)

  if ok ~= true then
    reportError("Gradient Options Parse Error", "I'm sorry, something is wrong with your color options!\n\n" .. options,
      gradient)
  else
    Send(target .. " " .. gradient)
  end
end

---Creates and prints a gradient string.
---@param args Token[] colors:cycles:reversed|target=text
local function gradients_mprint(args)
  local text = args[1].value --[[@as string]]
  local options = head(text, "|")
  text = body(text, "|")
  local ok, gradient = pcall(parseGradient, options, text)

  if ok ~= true then
    reportError("Gradient Options Parse Error", "I'm sorry, something is wrong with your color options!\n\n" .. options,
      gradient)
  else
    header("Gradient Print")
    ColourNote("white", "", "\n" .. gradient .. "\n")
    separator(true)
    local rendered = ColoursToANSI(gradient)
    AnsiNote(rendered)
    separator()
    local ansied = ColoursToANSI(rightpad("@wLength with Colors: @G" .. #gradient, 40) ..
      leftpad("@w Length without Colors: @G" .. #text .. "@w", 40))
    AnsiNote(ansied)
    footer()
  end
end

---Creates and prints an escaped gradient string.
---@param args Token[] colors:cycles:reversed|target=text
local function gradients_mescaped(args)
  local text = args[1].value --[[@as string]]
  local options = head(text, "|")
  local text = body(text, "|")
  local ok, gradient = pcall(parseGradient, options, text)

  if ok ~= true then
    reportError("Gradient Options Parse Error",
      "I'm sorry, something is wrong with your color options!\n\n" .. options,
      gradient)
  else
    local colorLength = #gradient

    gradient = string.gsub(
      gradient --[[@as string]]
      , "@"
      , "@@")

    header("Gradient Escaped")
    ColourNote("white", "", "\n" .. gradient .. "\n")
    separator(true)
    local rendered = ColoursToANSI("@w" .. gradient)
    AnsiNote(rendered)
    separator()
    local ansied = ColoursToANSI(rightpad("@wLength with Colors: @G" .. colorLength, 40) ..
      leftpad("@w Length without Colors: @G" .. #text .. "@w", 40))
    AnsiNote(ansied)
    footer()
  end
end

---Sends a gradient with arbitrary options
---@param args Token[] colors:cycles:reversed|target=text
local function gradients_send(args)
  local params = args[1].value --[[@as string]]
  local gradientName = head(params)
  local gradient = getGradientByName(gradientName)

  if not gradient then
    reportError("Couldn't find Gradient! :(", "Sorry, I couldn't find a gradient with the name: " .. gradientName)
    return
  end

  local colrs = {}

  for _, c in ipairs(gradient.colors) do
    table.insert(colrs, c:toHexString())
  end

  local rest = body(params)
  local command = head(rest)
  rest = body(rest)

  if #rest == 0 then
    reportError("No text to send?", "It looks like you tried to send nothing, this is bad!")
    return
  end

  -- Special case tells since they need a target.
  if command:lower() == "tell" then
    local target = head(rest)
    command = command .. " " .. target
    rest = body(rest)
  end

  local colored = Gradient:new():generate(rest, colrs, {
    cycles = gradient.cycles,
    reversed = gradient.reversed
  })

  Send(command .. " " .. colored)
end

---Prints an escaped gradient string.
---@param args Token[]
local function gradients_escaped(args)
  local params = args[1].value --[[@as string]]
  local gradientName = head(params)
  local gradient = getGradientByName(gradientName)

  if not gradient then
    reportError("Couldn't find Gradient! :(", "Sorry, I couldn't find a gradient with the name: " .. gradientName)
    return
  end

  local colrs = {}

  for _, c in ipairs(gradient.colors) do
    table.insert(colrs, c:toHexString())
  end

  local rest = body(params)

  if #rest == 0 then
    reportError("No text to escape?", "It looks like you tried to escape nothing, this is bad!")
    return
  end

  local colored = Gradient:new():generate(rest, colrs, {
    cycles = gradient.cycles,
    reversed = gradient.reversed
  })

  local colorLength = #colored

  colored = string.gsub(
    colored --[[@as string]]
    , "@"
    , "@@")

  header("Gradient Escaped")
  ColourNote("white", "", "\n" .. colored .. "\n")
  separator(true)
  local rendered = ColoursToANSI("@w" .. colored)
  AnsiNote(rendered)
  separator()
  local ansied = ColoursToANSI(rightpad("@wLength with Colors: @G" .. colorLength, 40) ..
    leftpad("@w Length without Colors: @G" .. #rest .. "@w", 40))
  AnsiNote(ansied)
  footer()
end

---Prints a gradient string.
---@param args Token[]
local function gradients_print(args)
  local params = trim(args[1].value --[[@as string]])
  local gradientName = head(params)
  local gradient = getGradientByName(gradientName)

  if not gradient then
    reportError("Couldn't find Gradient! :(", "Sorry, I couldn't find a gradient with the name: " .. gradientName)
    return
  end

  local colrs = {}

  for _, c in ipairs(gradient.colors) do
    table.insert(colrs, c:toHexString())
  end

  local rest = body(params)

  if #rest == 0 then
    reportError("No text to print?", "It looks like you tried to print nothing, this is bad!")
    return
  end

  local colored = Gradient:new():generate(rest, colrs, {
    cycles = gradient.cycles,
    reversed = gradient.reversed
  })

  local colorLength = #colored

  header("Gradient Print")
  ColourNote("white", "", "\n" .. colored .. "\n")
  separator(true)
  local rendered = ColoursToANSI("@w" .. colored)
  AnsiNote(rendered)
  separator()
  local ansied = ColoursToANSI(rightpad("@wLength with Colors: @G" .. colorLength, 40) ..
    leftpad("@w Length without Colors: @G" .. #rest .. "@w", 40))
  AnsiNote(ansied)
  footer()
end

---Gradient Meta Operations
---@param args Token[]
local function gradients_gradient(args)
  local command = args[1].value --[[@as string]]

  if command == "remove" then
    local name = args[2].value --[[@as string]]
    local target = getGradientByName(name)

    if type(target) == "nil" then
      reportError("Gradient Not Found", "Sorry, I couldn't find a gradient with the name: " .. name)
      gradients_list()
      return
    end

    local response = utils.msgbox(
      string.format("Are you sure you want to remove gradient \"%s\"?",
        args[2].value), "Really remove gradient?", "yesno",
      "!", 2)

    if response ~= "no" then
      removeGradient(target)
    end

    gradients_list()
  end

  if command == "new" then
    if args[2].type == "keyword" and args[2].value == "prompt" then
      local response = utils.inputbox("Please enter the name of the gradient:", "Add New Gradient", nil, nil, nil)

      if response then
        if #response == 0 then
          reportError("No Name Provided", "Please provide a name for the new gradient!")
          gradients_list()
        elseif tonumber(response) then
          reportError("Name Cannot be a Number", "For annoying reasons, the name can't be a number, sorry!")
          gradients_list()
        else
          local newGradient = {
            name = response,
            colors = {
              Colr:new("#333333"),
              Colr:new("#ffffff")
            },
            cycles = 1,
            reversed = false
          }

          local existing = getGradientByName(response)

          if type(existing) ~= "nil" then
            reportError("Duplicate Gradient Name", "Sorry, all gradients must have a unique name.")
          else
            upsertGradient(newGradient)
          end

          gradients_list()
        end
      end
    end

    if args[2].type == "string" then
      local newGradient = {
        name = args[2].value,
        colors = {
          Colr:new("#333333"),
          Colr:new("#ffffff")
        },
        cycles = 1,
        reversed = false
      }

      local existing = getGradientByName(args[2].value --[[@as string]])

      if type(existing) ~= "nil" then
        reportError("Duplicate Gradient Name", "Sorry, all gradients must have a unique name.")
      elseif tonumber(args[2].value) then
        reportError("Name Cannot be a Number", "For annoying reasons, the name can't be a number, sorry!")
        gradients_list()
      else
        upsertGradient(newGradient)
      end

      gradients_list()
    end
  end
end

---Help
---@param args string?
local function gradients_help(args)
  if not args or #args == 0 then
    header("Gradients Help")

    titledSeparator("Usage")

    for title, entry in pairsByKeys(helpFiles.Use) do
      Tell(" ")
      Hyperlink("grad help " .. title, leftpad(title, 8), "Help for " .. title, "dodgerblue", "", false, true)
      ColourTell("silver", "", " - " .. entry.command)
      Note("")
      ColourNote("silver", "", "    " .. entry.summary .. "\n")
    end

    titledSeparator("Manage")

    for title, entry in pairsByKeys(helpFiles.Manage) do
      Tell(" ")
      Hyperlink("grad help " .. title, leftpad(title, 8), "Help for " .. title, "dodgerblue", "", false, true)
      ColourTell("silver", "", " - " .. entry.command)
      Note("")
      ColourNote("silver", "", "    " .. entry.summary .. "\n")
    end

    titledSeparator("Meta")

    for title, entry in pairsByKeys(helpFiles.Meta) do
      Tell(" ")
      Hyperlink("grad help " .. title, leftpad(title, 8), "Help for " .. title, "dodgerblue", "", false, true)
      ColourTell("silver", "", " - " .. entry.command)
      Note("")
      ColourNote("silver", "", "    " .. entry.summary .. "\n")
    end

    footer()
  else
    local entry
    local entryTitle
    local found = false

    for _, articles in pairs(helpFiles) do
      for title, article in pairs(articles) do
        if args and args:lower() == title:lower() then
          entryTitle = title
          entry = article
          found = true
          break
        end
      end
      if found then
        break
      end
    end

    if not found then
      gradients_help()
      return
    end

    header("Gradients Help: " .. entryTitle)
    ColourNote("silver", "", " " .. entry.command)
    ColourNote("silver", "", " " .. entry.summary)
    separator()
    ColourNote("silver", "", entry.body)
    footer()
  end
end

---Prints a sampler of all the gradients.
---@param args Token[]
local function gradients_sampler(args)
  local gradients = getGradients()
  local text = args[1].value --[[@as string]]

  header("Sampler")
  for _, gradient in ipairs(gradients) do
    local colors = {}

    for _, c in ipairs(gradient["colors"]) do
      table.insert(colors, c:toHexString())
    end

    local g = Gradient:new():generate(text, colors, {
      cycles = gradient["cycles"],
      reversed = gradient["reversed"]
    })

    ColourNote("#FFEEEE", "", leftpad(gradient["name"], 16))
    local ansied = ColoursToANSI(g)
    AnsiNote("\n  " .. ansied .. "\n")
  end
  footer()
end

---Exports a given or all Gradients
---@param args Token[]
local function gradients_export(args)
  if args[1].type == "keyword" and args[1].value == "all" then
    local gradients = getGradients()
    local exports = {}

    for _, gradient in ipairs(gradients) do
      local colors = {}

      for _, c in ipairs(gradient["colors"]) do
        table.insert(colors, c:toHexString())
      end

      local grad = gradient["name"] .. "```" ..
          table.concat(colors, "|") .. "```" ..
          gradient["cycles"] .. "```" ..
          (gradient["reversed"] and "true" or "false")

      table.insert(exports, grad)
    end

    local exportString = table.concat(exports, "+")

    header("Gradient Export: All")
    Note(" ")
    ColourNote("#ffeeee", "", exportString)
    Note(" ")
    footer()
  end

  if args[1].type == "string" and #(args[1].value) > 0 then
    local gradient = getGradientByName(args[1].value --[[@as string]])

    if type(gradient) == "nil" then
      reportError("Gradient Not Found", "Sorry, I couldn't find a gradient with the name: " .. args[1].value)
    else
      local colors = {}

      for _, c in ipairs(gradient["colors"]) do
        table.insert(colors, c:toHexString())
      end

      local grad = gradient["name"] .. "```" ..
          table.concat(colors, "|") .. "```" ..
          gradient["cycles"] .. "```" ..
          (gradient["reversed"] and "true" or "false")

      header("Gradient Export: " .. args[1].value)
      Note(" ")
      ColourNote("#ffeeee", "", grad)
      Note(" ")
      footer()
    end
  end
end

---Imports a given import string.
---@param args Token[]
local function gradients_import(args)
  local data

  if args[1].type == "keyword" and args[1].value == "prompt" then
    local name = utils.inputbox("Please enter an import string:", "Import!")

    if type(name) ~= "string" or #name == 0 then
      reportError("No Import String", "Whoops, looks like you didn't provide anything to import!")
      return
    else
      data = trim(name)
    end
  else
    data = trim(args[1].value --[[@as string]])
  end

  local imports = {}
  local count = 0

  data = data:gsub("+", "\n")

  iter(data, function(import)
    table.insert(imports, import)
  end, "\n")

  for _, import in ipairs(imports) do
    local data = {}

    iter(import, function(i) table.insert(data, i) end, "```")


    if not data[1] or not data[2] or not data[3] or not data[4] then
      reportError("Gradient Import Error", "Looks like you passed a bogus import string, whoops!")
      return
    end

    local name = data[1]

    local exists = getGradientByName(name)

    if type(exists) ~= "nil" then
      printUIString("[Gradients Import]-[ " .. name .. " already exists, skipping!" .. " ]")
    else
      local colors = {}
      iter(data[2], function(c) table.insert(colors, Colr:new(c)) end, "|")
      local cycles = tonumber(data[3]) --[[@as number]]
      local reversed = data[4] == "true"

      local newGradient = {
        name = name,
        colors = colors,
        cycles = cycles,
        reversed = reversed
      }

      upsertGradient(newGradient)
      count = count + 1

      printUIString("[Gradients Import]-[ " .. name .. " imported!" .. " ]")
    end
  end

  printUIString(string.format("[Gradients Import]-[ Finished. Imported %s/%s]\n", count, #imports))
  gradients_list()
end

---Report an export string to a given target.
---@param args Token[]
local function gradients_report(args)
  local data = trim(args[1].value --[[@as string]])

  if #data == 0 then
    reportError("No Report String", "Whoops, you didn't give me anything to report!")
    return
  end

  local command = head(data)
  local rest = body(data)

  if #rest == 0 then
    reportError("Nothing to report?", "It looks like you tried to report nothing, this is bad!")
    return
  end

  -- Special case tells since they need a target.
  if command:lower() == "tell" then
    local target = head(rest)
    command = command .. " " .. target
    rest = body(rest)
  end

  local gradientName = trim(rest)
  local gradient = getGradientByName(gradientName)

  if not gradient then
    reportError("Gradient Not Found", "Sorry, I couldn't find a gradient with the name: " .. gradientName)
    return
  end

  local colors = {}

  for _, c in ipairs(gradient["colors"]) do
    table.insert(colors, c:toHexString())
  end

  local grad = gradient["name"] .. "```" ..
      table.concat(colors, "|") .. "```" ..
      gradient["cycles"] .. "```" ..
      (gradient["reversed"] and "true" or "false")

  Send(command .. " " .. grad)
end

---Prints version information.
local function gradients_about()
  header("Gradients v" .. VERSION)
  titledSeparator("About")
  ColourTell("#ffeeee", "", center("This travesty brought to you by Orphean", 80))
  Note(" ")
  titledSeparator("Basic Usage")

  local ansied = ColoursToANSI(
    "@w\n  Use @Cgrad list@w to get started - just start clicking on things.\n\n" ..
    "  To use the provided gradients use @Cgrad send@w.\n  For example: @Cgrad send pastelbow say Wow it works!@w\n\n" ..
    "  When you're ready for more detailed help then checkout @Cgrad help@w.\n")
  AnsiNote(ansied)
  footer()
end
----------------------------------------------------------

--  Mushclient Hooks

----------------------------------------------------------

function OnPluginInstall()
  gradients_about()
end

----------------------------------------------------------

--  Entry Point

----------------------------------------------------------

---Parses input from Mushclient and dispatches commands.
---@param raw string[] The unparsed arguments from mush.
function gradients_dispatch(_, _, raw)
  local args = raw[#raw]
  local command = head(args)
  local commandArgs = body(args)
  local dispatch = {
    escaped = gradients_escaped,
    export = gradients_export,
    gradient = gradients_gradient,
    help = gradients_help,
    import = gradients_import,
    list = gradients_list,
    mescaped = gradients_mescaped,
    modify = gradients_modify,
    mprint = gradients_mprint,
    msend = gradients_msend,
    print = gradients_print,
    report = gradients_report,
    sampler = gradients_sampler,
    send = gradients_send,
    view = gradients_view,
  }

  if command == "test" then
    gradients_about()
    return
  end

  local method = dispatch[command] or gradients_help

  if type(dispatch[command]) ~= "nil" and
      type(parameters[command]) ~= "nil" then
    local parsed = parseArgs(commandArgs)
    local format = getCommand(command, parsed)

    if type(format) == "nil" then
      gradients_help(command)
    else
      if format[1].type == "any" then
        parsed = { concatTokens(parsed) }
      end

      method(parsed, format)
    end
  else
    method(commandArgs)
  end
end
