-- WoW 3.3.5 client-side addon to colorize “rainbow:” and static-color prefixes

local MAX_LEN  = 255

-- Rainbow gradient for coloring
local rainbowColors = {
	{1,    0,   0  },  -- red
	{1,  0.5,   0  },  -- orange
	{1,    1,   0  },  -- yellow
	{0,    1,   0  },  -- green
	{0,    1,   1  },  -- cyan
	{0,	 0,	  1	 },  -- blue
	{0.5,  0, 0.5  },  -- purple 
	{1.00,0.41, 0.71},--pink   =
}

-- Static color definitions
local staticColors = {
	yellow = {1,   1,    0   },
	red    = {1,   0,    0   },
	green  = {0,   1,    0   },
	cyan   = {0,   1,    1   },
	purple = {0.5, 0,    0.5 },
	white  = {1,   1,    1   },
	blue   = {0,   0,    1   },
	pink   = {1.00,0.41, 0.71},
}


local patternMap = {
	-- letters q–z (row 1 of your chart)
	["q"] = {44/255,44/255,44/255},   -- black
	["r"] = {220/255,103/255,3/255},  -- red-brown
	["s"] = {231/255,255/255,255/255},-- pale
	["t"] = {1,235/255,102/255},      -- yellow
	["u"] = {74/255,129/255,35/255},  -- dark green
	["v"] = {0,56/255,184/255},       -- royal blue
	["w"] = {128/255,58/255,194/255}, -- violet
	["x"] = {1,1,1},                  -- white
	["y"] = {163/255,3/255,127/255},  -- fuchsia
	["z"] = {132/255,186/255,255/255},-- sky

	-- digits 0–9 (row 2 of your chart)
	["0"] = {1,1,1},       -- white
	["1"] = {228/255,3/255,3/255},   -- red
	["2"] = {1,140/255,0}, -- orange
	["3"] = {1,237/255,0}, -- yellow
	["4"] = {0,128/255,38/255}, -- green
	["5"] = {36/255,64/255,142/255}, -- blue
	["6"] = {115/255,41/255,130/255},-- purple
	["7"] = {1,33/255,140/255},-- magenta
	["8"] = {181/255,86/255,144/255},-- pink
	["9"] = {80/255,73/255,204/255}, -- violet


	-- letters a–j (row 3 of your chart)
	["a"] = {44/255,44/255,44/255},   -- black
	["b"] = {220/255,103/255,3/255},  -- red-brown
	["c"] = {1,140/255,0},            -- orange
	["d"] = {1,237/255,0},            -- yellow
	["e"] = {0,128/255,38/255},       -- green
	["f"] = {36/255,64/255,142/255},  -- blue
	["g"] = {115/255,41/255,130/255}, -- purple
	["h"] = {1,33/255,140/255},       -- magenta
	["i"] = {181/255,86/255,144/255}, -- pink
	["j"] = {80/255,73/255,204/255},  -- violet

	-- letters k–n (row 4 of your chart)
	["k"] = {44/255,44/255,44/255},   -- black
	["l"] = {220/255,103/255,3/255},  -- red-brown
	["m"] = {1,140/255,0},            -- orange
	["n"] = {1,237/255,0},            -- yellow

	
	-- letters o–p (row 5 of your chart)
	["o"] = {0,128/255,38/255},       -- green
	["p"] = {36/255,64/255,142/255},  -- blue

}


local glowColours = {
    glow1 = { {1, 0, 0}, {1, 0.5, 0}, {1, 1, 0}, {0, 1, 0}, {0, 1, 1} },
    glow2 = { {1, 0, 0}, {1, 0, 1}, {0, 0, 1}, {0.5, 0, 0} },
    glow3 = { {1, 1, 1}, {0, 1, 0}, {1, 1, 1}, {0, 1, 1} },
    glowrainbow = { {1, 0, 0}, {1, 0.5, 0}, {1, 1, 0}, {0, 1, 0}, {0, 1, 1}, {0, 0, 1}, {0.5, 0, 0.5}, {1, 0.41, 0.71} },
}

-- Hard snap colors (flashing)
local flashColours = {
    flash1 = { {1, 0, 0}, {1, 1, 0} },
    flash2 = { {0, 1, 1}, {0, 0, 1} },
    flash3 = { {0.5, 1, 0.5}, {0, 0.4, 0} },
}

-- Per-style speed
local bubbleSpeeds = {
    glow1 = 0.6,
    glow2 = 0.3,
    glow3 = 0.5,
    glowrainbow = 0.4,
    flash1 = 1.5,
    flash2 = 1.5,
    flash3 = 1.5,
}

-- Build a per-character pattern (wraps pattern codes if message longer)
local function BuildPattern(text, pat)
	local n = #text
	local p = #pat
	if n == 0 or p == 0 then return "" end

	local out = {}
	for i = 1, n do
		-- cycle through pat: code at position ((i-1)%p)+1
		local code = pat:sub(((i-1) % p) + 1, ((i-1) % p) + 1):lower()
		local rgb  = patternMap[code] or {1,1,1}
		out[i] = string.format(
			"|cff%02x%02x%02x%s|r",
			rgb[1]*255, rgb[2]*255, rgb[3]*255,
			text:sub(i,i)
		)
	end
	return table.concat(out)
end

local function BuildRainbow(text)
	local len = #text
	if len == 0 then return "" end

	local stops = #rainbowColors
	local out   = {}

	for i = 1, len do
		-- fraction from 0 to 1 along the string
		local frac = (len == 1) and 0 or (i - 1) / (len - 1)
		-- map that to [0, stops-1]
		local idxf = frac * (stops - 1)
		local lo   = math.floor(idxf) + 1
		local hi   = math.min(lo + 1, stops)
		local t    = idxf - math.floor(idxf)

		-- interpolate between stops[lo] and stops[hi]
		local c1 = rainbowColors[lo]
		local c2 = rainbowColors[hi]
		local r  = c1[1] + (c2[1] - c1[1]) * t
		local g  = c1[2] + (c2[2] - c1[2]) * t
		local b  = c1[3] + (c2[3] - c1[3]) * t

		out[i] = string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text:sub(i, i))
	end

	return table.concat(out)
end

local function BuildStaticColor(msg)
	for name, rgb in pairs(staticColors) do
		local clean = msg:match("^"..name..":%s*(.+)")
		if clean then
			return string.format(
				"|cff%02x%02x%02x%s|r",
				rgb[1]*255, rgb[2]*255, rgb[3]*255,
				clean
			)
		end
	end
end



--------------------------------------------------------------
------------------------Chat Box---------------------------
--------------------------------------------------------------


-- The filter function
local function ChatPrefixFilter(self, event, msg, author, ...)
	-- 1) static-color prefixes
	local staticColored = BuildStaticColor(msg)
	if staticColored then
		return false, staticColored, author, ...
	end	
	
	-- 2) rainbow prefix
	do
		local clean = msg:match("^rainbow:%s*(.+)")
		if clean then
			local colored
			colored = BuildRainbow(clean)
			return false, colored, author, ...
		end
	end	
	
	-- 3) pattern:<codes>: message
	do
		local pat, clean = msg:match("^pattern([0-9a-z]+):%s*(.+)")
		if pat and clean then
		  return false, BuildPattern(clean, pat), author, ...
		end
	end	
	
	-- 4) Glow/flash prefix stripping (for chat bubbles only hide command prefix in chat box )
	do
		local style, clean = msg:match("^([a-z0-9_]+):%s*(.+)")
		if style and (glowColours[style] or flashColours[style]) then
			return false, clean, author, ...
		end
	end

  -- no prefix → don’t filter, let it display normally
	return false
end

-- Register this filter for all chat events, including numbered channels
local events = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL",           
	"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",       
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_WHISPER",	"CHAT_MSG_CHANNEL",       
}

for _, ev in ipairs(events) do
	ChatFrame_AddMessageEventFilter(ev, ChatPrefixFilter)
end

--------------------------------------------------------------
------------------------Chat Bubble---------------------------
--------------------------------------------------------------

-- Tracked bubbles
local chatBubbleAnimations = {}

-- Utility: find chat bubbles
local function EnumerateChatBubbles()
    local bubbles = {}
    for i = 1, WorldFrame:GetNumChildren() do
        local child = select(i, WorldFrame:GetChildren())
        if child:IsShown() and child:GetObjectType() == "Frame" then
            for j = 1, child:GetNumRegions() do
                local region = select(j, child:GetRegions())
                if region and region:GetObjectType() == "FontString" and region:GetText() then
                    table.insert(bubbles, { frame = child, textObj = region })
                end
            end
        end
    end
    return bubbles
end

local function SetBubbleFontSize(fontString, size)
    local font, _, flags = fontString:GetFont()
    if font then
        fontString:SetFont(font, size, flags)
    end
end

-- Animation runner
local throttle = 0
local updateInterval = 0.033 -- ~30 FPS
local animationRunner = CreateFrame("Frame")
animationRunner:SetScript("OnUpdate", function(_, elapsed)
    throttle = throttle + elapsed
    if throttle < updateInterval then return end
    local dt = throttle
    throttle = 0

    for fontString, data in pairs(chatBubbleAnimations) do
        local currentText = fontString:GetText()
        if not currentText or not currentText:find(data.text, 1, true) then
            chatBubbleAnimations[fontString] = nil
        else
            data.phase = (data.phase + dt * data.speed) % 1

            local r, g, b
            local colors = data.colors
            local count = #colors

            if data.mode == "flash" then
                local index = (data.phase < 0.5) and 1 or 2
                r, g, b = unpack(colors[index])
            elseif count == 2 then
                local t = (math.sin(data.phase * math.pi * 2) + 1) / 2
                local c1, c2 = colors[1], colors[2]
                r = c1[1] + (c2[1] - c1[1]) * t
                g = c1[2] + (c2[2] - c1[2]) * t
                b = c1[3] + (c2[3] - c1[3]) * t
            else
                local idxf = data.phase * (count - 1)
                local i1 = math.floor(idxf) + 1
                local i2 = math.min(i1 + 1, count)
                local t = idxf - math.floor(idxf)

                local c1, c2 = colors[i1], colors[i2]
                r = c1[1] + (c2[1] - c1[1]) * t
                g = c1[2] + (c2[2] - c1[2]) * t
                b = c1[3] + (c2[3] - c1[3]) * t
            end

            local hex = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
            local newText = hex .. data.text .. "|r"
            if newText ~= data.lastColor then
                fontString:SetText(newText)
                data.lastColor = newText
            end
        end
    end
end)

-- Bubble watcher
local bubbleWatcher = CreateFrame("Frame")
bubbleWatcher:SetScript("OnUpdate", function()
    for _, bubble in ipairs(EnumerateChatBubbles()) do
        local textObj = bubble.textObj
        local text = textObj:GetText()

        if text then
		    -- 🔠 Increase font size once per bubble
            -- if not textObj._WORS_FontResized then
                -- SetBubbleFontSize(textObj, 22) 
                -- textObj._WORS_FontResized = true
            -- end
		
		
            local rawStyle, cleanText = text:match("^([a-z0-9_]+):%s*(.+)")
            local style = rawStyle == "rainbow" and "glowrainbow" or rawStyle
            local existing = chatBubbleAnimations[textObj]


			if style and (not existing or existing.text ~= cleanText) then
				local colors = glowColours[style] or flashColours[style]
				if colors then
					chatBubbleAnimations[textObj] = {
						text = cleanText,
						colors = colors,
						phase = math.random(),
						speed = bubbleSpeeds[style] or 0.5,
						lastColor = "",
						mode = flashColours[style] and "flash" or "glow",
					}
				else
					-- Static color support (e.g., red:, blue:)
					local rgb = staticColors[style]
					if rgb then
						local hexText = string.format("|cff%02x%02x%02x%s|r", rgb[1]*255, rgb[2]*255, rgb[3]*255, cleanText)
						textObj:SetText(hexText)
					else
						-- Pattern color support (e.g., patternabc:)
						local pat = style:match("^pattern([0-9a-z]+)$")
						if pat then
							local recolored = BuildPattern(cleanText, pat)
							textObj:SetText(recolored)
						end
					end
				end
			elseif not style and not chatBubbleAnimations[textObj] then

                -- Fallback: static/pattern/rainbow
                local recolored
                local pat, clean = text:match("^pattern([0-9a-z]+):%s*(.+)")
                if pat and clean then
                    recolored = BuildPattern(clean, pat)
                end

                if not recolored then
                    recolored = BuildStaticColor(text)
                end

                if not recolored then
                    local cleanRainbow = text:match("^rainbow:%s*(.+)")
                    if cleanRainbow then
                        recolored = BuildRainbow(cleanRainbow)
                    end
                end

                if recolored and recolored ~= text then
                    textObj:SetText(recolored)
                end
            end
        end
    end
end)


------------------------------------
