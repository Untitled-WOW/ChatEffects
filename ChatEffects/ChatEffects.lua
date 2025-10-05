-- -- WoW 3.3.5 client-side addon to colorize “rainbow:” and static-color prefixes
local MAX_LEN  = 255
local ICON_SIZE = 14  
local QUILL_FONT = "fonts\\runescape_quill.ttf"

-- ========= Color Data =========
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

-- ========= ICON COMMANDS =========
local IconCommands = {
    ["Interface\\Icons\\Skills\\Attackicon"] = { "attack", "atk" },
    ["Interface\\Icons\\Skills\\Strengthicon"] = { "strength", "str" },
    ["Interface\\Icons\\Skills\\Defenceicon"] = { "defence", "def" },
    ["Interface\\Icons\\Skills\\Rangedicon"] = { "ranged", "range" },
    ["Interface\\Icons\\Skills\\Prayericon"] = { "prayer", "pray" },
    ["Interface\\Icons\\Skills\\Magicicon"] = { "magic", "mage"},
    ["Interface\\Icons\\Skills\\Runecrafticon"] = { "runecrafting", "runecraft", "rc" },
    ["Interface\\Icons\\Skills\\Constructionicon"] = { "construction", "con" },
    ["Interface\\Icons\\Skills\\Hitpointsicon"] = { "hitpoints", "hp" },
    ["Interface\\Icons\\Skills\\Agilityicon"] = { "agility", "agi" },
    ["Interface\\Icons\\Skills\\Herbloreicon"] = { "herblore", "herb" },
    ["Interface\\Icons\\Skills\\Thievingicon"] = { "thieving", "thieve", "thiev" },
    ["Interface\\Icons\\Skills\\Craftingicon"] = { "crafting", "craft" },
    ["Interface\\Icons\\Skills\\Fletchingicon"] = { "fletching", "fletch" },
    ["Interface\\Icons\\Skills\\Slayericon"] = { "slayer", "slay" },
    ["Interface\\Icons\\Skills\\Huntericon"] = { "hunter", "hunt" },
    ["Interface\\Icons\\Skills\\Miningicon"] = { "mining", "mine" },
    ["Interface\\Icons\\Skills\\Smithingicon"] = { "smithing", "smith" },
    ["Interface\\Icons\\Skills\\Fishingicon"] = { "fishing", "fish" },
    ["Interface\\Icons\\Skills\\Cookingicon"] = { "cooking", "cook" },
    ["Interface\\Icons\\Skills\\Firemakingicon"] = { "firemaking", "fire","fm" },
    ["Interface\\Icons\\Skills\\Woodcuttingicon"] = { "woodcutting", "wood", "wc" },
    ["Interface\\Icons\\Skills\\Farmingicon"] = { "farming", "farm" },
    ["Interface\\Icons\\Skills\\Dungeoneeringicon"] = { "dungeoneering", "dung" },
}

-- Build alias -> path (lowercased)
local ICON_ALIAS = {}
do
    for path, list in pairs(IconCommands) do
        for _, alias in ipairs(list) do
            ICON_ALIAS[alias:lower()] = path
        end
    end
end

-- Replace :alias: with |Tpath:w:h|t (case-insensitive)
local function ReplaceIconsInText(text)
    if not text or text == "" then return text end
    local function repl(token)
        local alias = token:sub(2, -2)  -- strip leading/trailing :
        local path  = ICON_ALIAS[alias:lower()]
        if path then
            return ("|T%s:%d:%d|t"):format(path, ICON_SIZE, ICON_SIZE)
        else
            return token
        end
    end
    return (text:gsub(":%w+:", repl))
end

-- Split plain text into pieces, isolating |T...|t textures so we never color inside them
local function SplitByTextures(txt)
    local pieces, last = {}, 1
    for s, e in txt:gmatch("()|T.-|t()") do
        if s > last then table.insert(pieces, { text = txt:sub(last, s - 1), isTexture = false }) end
        table.insert(pieces, { text = txt:sub(s, e - 1), isTexture = true })
        last = e
    end
    if last <= #txt then table.insert(pieces, { text = txt:sub(last), isTexture = false }) end
    return pieces
end



-- ========= Builders =========
local function BuildPattern(text, pat)
    local n, p = #text, #pat
    if n == 0 or p == 0 then return "" end
    local out = {}
    for i = 1, n do
        local code = pat:sub(((i-1)%p)+1, ((i-1)%p)+1):lower()
        local rgb  = patternMap[code] or {1,1,1}
        out[i] = string.format("|cff%02x%02x%02x%s|r", rgb[1]*255, rgb[2]*255, rgb[3]*255, text:sub(i,i))
    end
    return table.concat(out)
end

local function BuildGradient(text, stops)
    local len = #text
    if len == 0 or not stops or #stops == 0 then return text end
    if #stops == 1 then
        local c = stops[1]
        return string.format("|cff%02x%02x%02x%s|r", c[1]*255, c[2]*255, c[3]*255, text)
    end
    local out, nstops = {}, #stops
    for i = 1, len do
        local frac = (len == 1) and 0 or (i - 1) / (len - 1)
        local idxf = frac * (nstops - 1)
        local lo   = math.floor(idxf) + 1
        local hi   = math.min(lo + 1, nstops)
        local t    = idxf - math.floor(idxf)
        local c1, c2 = stops[lo], stops[hi]
        local r = c1[1] + (c2[1]-c1[1]) * t
        local g = c1[2] + (c2[2]-c1[2]) * t
        local b = c1[3] + (c2[3]-c1[3]) * t
        out[i] = string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, text:sub(i,i))
    end
    return table.concat(out)
end

local function BuildAlternate(text, colors)
    local len = #text
    if len == 0 or not colors or #colors == 0 then return text end
    local c1 = colors[1]; local c2 = colors[2] or colors[1]
    local out = {}
    for i = 1, len do
        local c = (i % 2 == 1) and c1 or c2
        out[i] = string.format("|cff%02x%02x%02x%s|r", c[1]*255, c[2]*255, c[3]*255, text:sub(i,i))
    end
    return table.concat(out)
end

local function BuildRainbow(text) return BuildGradient(text, rainbowColors) end

local function BuildStaticColor(msg)
    local lower = msg:lower()
    for name, rgb in pairs(staticColors) do
        local s, e = lower:find("^"..name..":%s*")
        if e then
            return string.format("|cff%02x%02x%02x%s|r", rgb[1]*255, rgb[2]*255, rgb[3]*255, msg:sub(e+1))
        end
    end
end

-- Preserve textures while coloring (applies fn to non-texture chunks)
local function ColorPreserveTextures(text, fn)
    local out = {}
    for _, piece in ipairs(SplitByTextures(text)) do
        if piece.isTexture then
            out[#out+1] = piece.text
        else
            out[#out+1] = fn(piece.text)
        end
    end
    return table.concat(out)
end

-- Convenience wrappers
local function BuildRainbowPreserve(text)
    return ColorPreserveTextures(text, function(t) return BuildRainbow(t) end)
end
local function BuildPatternPreserve(text, pat)
    return ColorPreserveTextures(text, function(t) return BuildPattern(t, pat) end)
end
local function BuildGradientPreserve(text, stops)
    return ColorPreserveTextures(text, function(t) return BuildGradient(t, stops) end)
end
local function BuildAlternatePreserve(text, colors)
    return ColorPreserveTextures(text, function(t) return BuildAlternate(t, colors) end)
end

-- ============================================================
-- Chat Box Filter (icon replacement first; then strip/color; quill is strip-only)
-- ============================================================
local function ChatPrefixFilter(self, event, msg, author, ...)
    -- split into segments (preserve links)
    local segments, lastEnd = {}, 1
    for s, e in msg:gmatch("()|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r()") do
        if s > lastEnd then table.insert(segments, { text = msg:sub(lastEnd, s-1), isLink = false }) end
        table.insert(segments, { text = msg:sub(s, e-1), isLink = true })
        lastEnd = e
    end
    if lastEnd <= #msg then table.insert(segments, { text = msg:sub(lastEnd), isLink = false }) end

    -- 0) ICONS: replace in non-link segments BEFORE any coloring/stripping
    local iconsChanged = false
    for _, seg in ipairs(segments) do
        if not seg.isLink then
            local new = ReplaceIconsInText(seg.text)
            if new ~= seg.text then
                seg.text = new
                iconsChanged = true
            end
        end
    end

    local function RecolorLink(linkText, rgb)
        if not rgb or not rgb[1] then return linkText end
        local new = string.format("|cff%02x%02x%02x", rgb[1]*255, rgb[2]*255, rgb[3]*255)
        return linkText:gsub("^|c%x%x%x%x%x%x%x%x", new, 1)
    end

    local function LeadingLower()
        for _, seg in ipairs(segments) do
            if not seg.isLink then
                return (seg.text or ""):lower()
            else
                break
            end
        end
        return ""
    end

    local function StripOnce(patternLower)
        for _, seg in ipairs(segments) do
            if not seg.isLink then
                local s, e = seg.text:lower():find(patternLower)
                if e then seg.text = seg.text:sub(e+1); return true end
            end
        end
        return false
    end

    -- Strip quill: (chat frame does not change font)
    local didStripQuill = false
    do
        local lead = LeadingLower()
        if lead:find("^quill:%s*") then
            didStripQuill = StripOnce("^quill:%s*")
        end
    end

    -- STATIC
    do
        local lead = LeadingLower()
        local colorName = lead:match("^([a-z]+):")
        if colorName and staticColors[colorName] then
            local rgb = staticColors[colorName]
            StripOnce("^"..colorName..":%s*")
            local out = {}
            for _, seg in ipairs(segments) do
                if seg.isLink then
                    out[#out+1] = RecolorLink(seg.text, rgb)
                else
                    -- preserve textures while coloring solid
                    for _, piece in ipairs(SplitByTextures(seg.text)) do
                        if piece.isTexture then
                            out[#out+1] = piece.text
                        else
                            out[#out+1] = string.format("|cff%02x%02x%02x%s|r", rgb[1]*255, rgb[2]*255, rgb[3]*255, piece.text)
                        end
                    end
                end
            end
            return false, table.concat(out), author, ...
        end
    end

    -- RAINBOW
    do
        local lead = LeadingLower()
        if lead:find("^rainbow:%s*") then
            StripOnce("^rainbow:%s*")
            local out = {}
            for _, seg in ipairs(segments) do
                if seg.isLink then out[#out+1] = seg.text
                else out[#out+1] = BuildRainbowPreserve(seg.text) end
            end
            return false, table.concat(out), author, ...
        end
    end

    -- PATTERN
    do
        local lead = LeadingLower()
        local pat = lead:match("^pattern([0-9a-z]+):")
        if pat then
            StripOnce("^pattern"..pat..":%s*")
            local out = {}
            for _, seg in ipairs(segments) do
                if seg.isLink then out[#out+1] = seg.text
                else out[#out+1] = BuildPatternPreserve(seg.text, pat) end
            end
            return false, table.concat(out), author, ...
        end
    end

    -- GLOW (chat-box signifier = gradient)
    do
        local lead = LeadingLower()
        local style = lead:match("^([a-z0-9_]+):")
        if style and glowColours[style] then
            StripOnce("^"..style..":%s*")
            local out = {}
            for _, seg in ipairs(segments) do
                if seg.isLink then out[#out+1] = seg.text
                else out[#out+1] = BuildGradientPreserve(seg.text, glowColours[style]) end
            end
            return false, table.concat(out), author, ...
        end
    end

    -- FLASH (chat-box signifier = alternating)
    do
        local lead = LeadingLower()
        local style = lead:match("^([a-z0-9_]+):")
        if style and flashColours[style] then
            StripOnce("^"..style..":%s*")
            local out = {}
            for _, seg in ipairs(segments) do
                if seg.isLink then out[#out+1] = seg.text
                else out[#out+1] = BuildAlternatePreserve(seg.text, flashColours[style]) end
            end
            return false, table.concat(out), author, ...
        end
    end

    -- GENERIC safe strip
    do
        local lead = LeadingLower()
        local style = lead:match("^([a-z0-9_]+):")
        if style and (style:match("^pattern[0-9a-z]+$") or staticColors[style]) then
            StripOnce("^"..style..":%s*")
            local out = {}
            for _, seg in ipairs(segments) do out[#out+1] = seg.text end
            return false, table.concat(out), author, ...
        end
    end

    -- Return the rebuilt message if icons changed OR we stripped 'quill:' only
    if iconsChanged or didStripQuill then
        local out = {}
        for _, seg in ipairs(segments) do out[#out+1] = seg.text end
        return false, table.concat(out), author, ...
    end

    return false
end

-- Register chat filter
do
    local events = {
        "CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_GUILD","CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER","CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_WHISPER","CHAT_MSG_CHANNEL",
    }
    for _, ev in ipairs(events) do ChatFrame_AddMessageEventFilter(ev, ChatPrefixFilter) end
end

-- ============================================================
-- Chat Bubbles (animated FX + quill font) + ICONS
-- ============================================================
local chatBubbleAnimations = {}

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

-- helper: color only non-texture chunks (prevents issues when text ends with |T...|t)
local function ApplyHexToNonTextures(s, hex)
    local out = {}
    for _, piece in ipairs(SplitByTextures(s)) do
        if piece.isTexture then
            out[#out+1] = piece.text
        else
            out[#out+1] = hex .. piece.text .. "|r"
        end
    end
    return table.concat(out)
end

-- helper: strip WoW color codes (keep textures intact)
local function StripColorCodes(s)
    if not s or s == "" then return s end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
    s = s:gsub("|r", "")
    return s
end

local throttle, updateInterval = 0, 0.033
local animationRunner = CreateFrame("Frame")
animationRunner:SetScript("OnUpdate", function(_, elapsed)
    throttle = throttle + elapsed
    if throttle < updateInterval then return end
    local dt = throttle; throttle = 0

    for fontString, data in pairs(chatBubbleAnimations) do
        local currentText = fontString:GetText()
        local stripped = StripColorCodes(currentText or "")

        -- Compare against the uncolored base (which includes textures), so per-chunk coloring doesn't break tracking.
        if not currentText or stripped == "" or not stripped:find(data.text, 1, true) then
            chatBubbleAnimations[fontString] = nil
        else
            data.phase = (data.phase + dt * data.speed) % 1

            local r, g, b
            local colors, count = data.colors, #data.colors

            if data.mode == "flash" then
                local index = (data.phase < 0.5) and 1 or 2
                r, g, b = unpack(colors[index])
            elseif count == 2 then
                local t = (math.sin(data.phase * math.pi * 2) + 1) / 2
                local c1, c2 = colors[1], colors[2]
                r = c1[1] + (c2[1]-c1[1]) * t
                g = c1[2] + (c2[2]-c1[2]) * t
                b = c1[3] + (c2[3]-c1[3]) * t
            else
                local idxf = data.phase * (count - 1)
                local i1 = math.floor(idxf) + 1
                local i2 = math.min(i1 + 1, count)
                local t = idxf - math.floor(idxf)
                local c1, c2 = colors[i1], colors[i2]
                r = c1[1] + (c2[1]-c1[1]) * t
                g = c1[2] + (c2[2]-c1[2]) * t
                b = c1[3] + (c2[3]-c1[3]) * t
            end

            -- Bubble-only FX (shadow/pulse/outline toggle)
            if data.wantPulse and data.baseFile and data.baseSize then
                local pulse = 1 + 0.03 * math.sin(data.phase * math.pi * 2)
                -- For glow, baseFlags is set to "THICKOUTLINE", so this keeps the outline during pulses.
                fontString:SetFont(data.baseFile, math.max(1, data.baseSize * pulse), data.baseFlags)
                fontString:SetShadowColor(0,0,0,0.8)
                fontString:SetShadowOffset(1,-1)
            end
            if data.wantOutlineSnap and data.baseFile and data.baseSize then
                -- Flash keeps its original toggle behavior
                local useOutline = (data.phase < 0.5)
                local flags = useOutline and "THICKOUTLINE" or data.baseFlags or ""
                fontString:SetFont(data.baseFile, data.baseSize, flags)
            end

            local hex = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
            local newText = ApplyHexToNonTextures(data.text, hex)
            if newText ~= data.lastColor then
                fontString:SetText(newText)
                data.lastColor = newText
            end
        end
    end
end)

local bubbleWatcher = CreateFrame("Frame")
bubbleWatcher:SetScript("OnUpdate", function()
    for _, bubble in ipairs(EnumerateChatBubbles()) do
        local textObj = bubble.textObj
        local raw = textObj:GetText()
        if raw then
            -- First, icon replacement in the whole bubble text
            local text = ReplaceIconsInText(raw)
            if text ~= raw then textObj:SetText(text) end

            local lower = text:lower()
            local s, e, styleLower = lower:find("^([a-z0-9_]+):%s*")
            local style = styleLower
            local cleanText = text

            if e then
                cleanText = text:sub(e + 1)
                if styleLower == "rainbow" then style = "glowrainbow" end
            end

            local handled = false

            -- quill: (bubble-only font swap)
            if style == "quill" then
                local file, size, flags = textObj:GetFont()
                textObj:SetFont(QUILL_FONT, size or 14, flags)

                -- Strip the "quill:" prefix from the visible bubble text immediately
                textObj:SetText(cleanText)

                -- Re-parse next prefix (case-insensitive)
                local lower2 = cleanText:lower()
                local s2, e2, st2 = lower2:find("^([a-z0-9_]+):%s*")
                if e2 then
                    style = (st2 == "rainbow") and "glowrainbow" or st2
                    cleanText = cleanText:sub(e2 + 1)
                else
                    -- Direct pattern/rainbow after quill
                    local pS, pE, patOnly = lower2:find("^pattern([0-9a-z]+):%s*")
                    if patOnly then
                        textObj:SetText(BuildPatternPreserve(cleanText:sub((pE or 0)+1), patOnly))
                        handled = true
                    else
                        local rS, rE = lower2:find("^rainbow:%s*")
                        if rE then
                            textObj:SetText(BuildRainbowPreserve(cleanText:sub(rE+1)))
                            handled = true
                        end
                    end
                end
            end

            if not handled then
                local existing = chatBubbleAnimations[textObj]
                if e and (not existing or existing.text ~= cleanText) then
                    local colors = glowColours[style] or flashColours[style]
                    if colors then
                        local baseFile, baseSize, baseFlags = textObj:GetFont()

                        -- Ensure glow ALWAYS uses THICKOUTLINE, without affecting flash's toggle
                        local isGlow = glowColours[style] ~= nil
                        local initFlags = baseFlags or ""
                        if isGlow then
                            initFlags = "THICKOUTLINE"
                            if baseFile and baseSize then
                                textObj:SetFont(baseFile, baseSize, "THICKOUTLINE")
                            end
                        end

                        chatBubbleAnimations[textObj] = {
                            text = cleanText, colors = colors, phase = math.random(),
                            speed = bubbleSpeeds[style] or 0.5, lastColor = "",
                            mode = flashColours[style] and "flash" or "glow",
                            baseFile = baseFile, baseSize = baseSize or 14, baseFlags = initFlags,
                            wantPulse = (glowColours[style] ~= nil),
                            wantOutlineSnap = (flashColours[style] ~= nil),
                        }
                        if glowColours[style] then
                            textObj:SetShadowColor(0,0,0,0.8)
                            textObj:SetShadowOffset(1,-1)
                        end
                    else
                        -- Static/Pattern/Rainbow inside bubbles
                        local rgb = staticColors[style]
                        if rgb then
                            textObj:SetText( ("|cff%02x%02x%02x%s|r"):format(rgb[1]*255, rgb[2]*255, rgb[3]*255, cleanText) )
                        else
                            local pS, pE, pat = cleanText:lower():find("^pattern([0-9a-z]+):%s*")
                            if pat then
                                textObj:SetText(BuildPatternPreserve(cleanText:sub((pE or 0)+1), pat))
                            else
                                local rS, rE = cleanText:lower():find("^rainbow:%s*")
                                if rE then textObj:SetText(BuildRainbowPreserve(cleanText:sub(rE+1))) end
                            end
                        end
                    end
                elseif not e and not chatBubbleAnimations[textObj] then
                    -- Fallbacks for plain bubble text (preserve textures)
                    local recolored
                    local pS, pE, pat = lower:find("^pattern([0-9a-z]+):%s*")
                    if pat then recolored = BuildPatternPreserve(text:sub((pE or 0)+1), pat) end
                    if not recolored then recolored = BuildStaticColor(text) end
                    if not recolored then
                        local rS, rE = lower:find("^rainbow:%s*")
                        if rE then recolored = BuildRainbowPreserve(text:sub(rE+1)) end
                    end
                    if recolored and recolored ~= text then textObj:SetText(recolored) end
                end
            end
        end
    end
end)

-- ============================================================
-- Edit Box Preview (no quill font; icons are just text while typing)
-- ============================================================
local function WORS_GetPreviewRGB(txt)
    if not txt or txt == "" then return end
    local lower = txt:lower()
    if lower:find("^quill:%s*") then lower = lower:gsub("^quill:%s*", "", 1) end

    local name = lower:match("^([a-z]+):")
    if name and staticColors[name] then local c=staticColors[name]; return c[1],c[2],c[3] end
    if lower:find("^rainbow:%s*") then local c=rainbowColors[1]; return c[1],c[2],c[3] end
    local pat = lower:match("^pattern([0-9a-z]+):")
    if pat and #pat>0 then local m=patternMap[pat:sub(1,1)]; if m then return m[1],m[2],m[3] end end
    local style = lower:match("^([a-z0-9_]+):")
    if style then
        local g=glowColours[style]; if g and g[1] then return g[1][1],g[1][2],g[1][3] end
        local f=flashColours[style]; if f and f[1] then return f[1][1],f[1][2],f[1][3] end
    end
end

-- Only set a preview color when a prefix is detected; otherwise keep channel color.
local function WORS_ApplyPreviewColor(box)
    if not box or not box:IsShown() then return end
    local r,g,b = WORS_GetPreviewRGB(box:GetText())
    if r and g and b then
        if box.SetTextColor then box:SetTextColor(r,g,b) end
        box._WORS_HadPreview = true
    else
        -- If a preview was previously applied but no longer present, restore channel color.
        if box._WORS_HadPreview then
            box._WORS_HadPreview = false
            if ChatEdit_UpdateHeader then ChatEdit_UpdateHeader(box) end
        end
        -- Do not touch text color when no preview prefix is present.
    end
end

local WORS_HookedBoxes = {}
local function WORS_TryHookBox(box)
    if not box or WORS_HookedBoxes[box] then return end
    box:HookScript("OnTextChanged", function(self, user) if user ~= false then WORS_ApplyPreviewColor(self) end end)
    if box:HasScript("OnShow") then box:HookScript("OnShow", WORS_ApplyPreviewColor) end
    if box:HasScript("OnEditFocusGained") then box:HookScript("OnEditFocusGained", WORS_ApplyPreviewColor) end
    WORS_HookedBoxes[box] = true
end

local function WORS_HookAllEditBoxes()
    local candidates = {
        _G.ChatFrameEditBox, _G.ChatFrame1EditBox, _G.CHAT_FRAME_EDIT_BOX,
        _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.editBox or nil,
    }
    for i = 1, (NUM_CHAT_WINDOWS or 10) do table.insert(candidates, _G["ChatFrame"..i.."EditBox"]) end
    for _, b in ipairs(candidates) do WORS_TryHookBox(b) end
end
WORS_HookAllEditBoxes()

-- Let the game set channel color first; then optionally apply preview color.
if hooksecurefunc then
    hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
        if editBox then WORS_ApplyPreviewColor(editBox) end
    end)
end

local WORS_ColorTicker = CreateFrame("Frame")
local accum = 0
WORS_ColorTicker:SetScript("OnUpdate", function(_, dt)
    accum = accum + dt
    if accum < 0.2 then return end
    accum = 0
    for box in pairs(WORS_HookedBoxes) do
        if box:IsShown() and box:HasFocus() then WORS_ApplyPreviewColor(box) end
    end
end)
