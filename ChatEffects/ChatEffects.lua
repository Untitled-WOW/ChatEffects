-- ChatEffects.lua (WoW 3.3.5)
-- Colorizes messages based on prefixes and previews them while typing.
-- Features:
--  - Static colors:   "cyan: Hello"
--  - Rainbow:         "rainbow: Hello"
--  - Patterns:        "patternabc: Hello" (per-char mapping)
--  - Animated bubbles: glow*/flash* styles via chat bubble recoloring
--  - Edit box preview: only for animated styles (glow/flash/rainbow).
--    Static colors tint the edit-box text. No preview box for static.
--    When no command is present, we DO NOT change the edit-box text color.

--------------------------------------------------------------
----------------------- Config / Tables ----------------------
--------------------------------------------------------------

local MAX_LEN  = 255

-- Rainbow gradient for coloring
local rainbowColors = {
    {1,    0,   0  },  -- red
    {1,  0.5,   0  },  -- orange
    {1,    1,   0  },  -- yellow
    {0,    1,   0  },  -- green
    {0,    1,   1  },  -- cyan
    {0,    0,   1  },  -- blue
    {0.5,  0, 0.5  },  -- purple
    {1.00,0.41, 0.71}, -- pink
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

-- Character pattern mapping
local patternMap = {
    -- letters q–z (row 1)
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

    -- digits 0–9 (row 2)
    ["0"] = {1,1,1},
    ["1"] = {228/255,3/255,3/255},    -- red
    ["2"] = {1,140/255,0},            -- orange
    ["3"] = {1,237/255,0},            -- yellow
    ["4"] = {0,128/255,38/255},       -- green
    ["5"] = {36/255,64/255,142/255},  -- blue
    ["6"] = {115/255,41/255,130/255}, -- purple
    ["7"] = {1,33/255,140/255},       -- magenta
    ["8"] = {181/255,86/255,144/255}, -- pink
    ["9"] = {80/255,73/255,204/255},  -- violet

    -- letters a–j (row 3)
    ["a"] = {44/255,44/255,44/255},
    ["b"] = {220/255,103/255,3/255},
    ["c"] = {1,140/255,0},
    ["d"] = {1,237/255,0},
    ["e"] = {0,128/255,38/255},
    ["f"] = {36/255,64/255,142/255},
    ["g"] = {115/255,41/255,130/255},
    ["h"] = {1,33/255,140/255},
    ["i"] = {181/255,86/255,144/255},
    ["j"] = {80/255,73/255,204/255},

    -- letters k–n (row 4)
    ["k"] = {44/255,44/255,44/255},
    ["l"] = {220/255,103/255,3/255},
    ["m"] = {1,140/255,0},
    ["n"] = {1,237/255,0},

    -- letters o–p (row 5)
    ["o"] = {0,128/255,38/255},       -- green
    ["p"] = {36/255,64/255,142/255},  -- blue
}

-- Animated palettes
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

-- Per-style speed for animations
local bubbleSpeeds = {
    glow1 = 0.6,
    glow2 = 0.3,
    glow3 = 0.5,
    glowrainbow = 0.4,
    flash1 = 1.5,
    flash2 = 1.5,
    flash3 = 1.5,
}

--------------------------------------------------------------
------------------------ Color Builders ----------------------
--------------------------------------------------------------

local function BuildPattern(text, pat)
    local n = #text
    local p = #pat
    if n == 0 or p == 0 then return "" end

    local out = {}
    for i = 1, n do
        local code = pat:sub(((i-1) % p) + 1, ((i-1) % p) + 1):lower()
        local rgb  = patternMap[code] or {1,1,1}
        out[i] = string.format(
            "|cff%02x%02x%02x%s|r",
            math.floor(rgb[1]*255 + 0.5), math.floor(rgb[2]*255 + 0.5), math.floor(rgb[3]*255 + 0.5),
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
        local frac = (len == 1) and 0 or (i - 1) / (len - 1)
        local idxf = frac * (stops - 1)
        local lo   = math.floor(idxf) + 1
        local hi   = math.min(lo + 1, stops)
        local t    = idxf - math.floor(idxf)

        local c1 = rainbowColors[lo]
        local c2 = rainbowColors[hi]
        local r  = c1[1] + (c2[1] - c1[1]) * t
        local g  = c1[2] + (c2[2] - c1[2]) * t
        local b  = c1[3] + (c2[3] - c1[3]) * t

        out[i] = string.format("|cff%02x%02x%02x%s|r",
            math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5),
            text:sub(i, i)
        )
    end

    return table.concat(out)
end

local function BuildStaticColor(msg)
    for name, rgb in pairs(staticColors) do
        local clean = msg:match("^"..name..":%s*(.+)")
        if clean then
            return string.format(
                "|cff%02x%02x%02x%s|r",
                math.floor(rgb[1]*255 + 0.5), math.floor(rgb[2]*255 + 0.5), math.floor(rgb[3]*255 + 0.5),
                clean
            )
        end
    end
end

--------------------------------------------------------------
------------------------ Chat Box Filter ---------------------
--------------------------------------------------------------

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
            local colored = BuildRainbow(clean)
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

    -- 4) Glow/flash prefix stripping (for chat box only, hide command prefix)
    do
        local style, clean = msg:match("^([a-z0-9_]+):%s*(.+)")
        if style and (glowColours[style] or flashColours[style]) then
            return false, clean, author, ...
        end
    end

    -- no prefix → normal
    return false
end

local events = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_WHISPER", "CHAT_MSG_CHANNEL",
}

for _, ev in ipairs(events) do
    ChatFrame_AddMessageEventFilter(ev, ChatPrefixFilter)
end

--------------------------------------------------------------
------------------------ Chat Bubbles ------------------------
--------------------------------------------------------------

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

local function SetBubbleFontSize(fontString, size)
    local font, _, flags = fontString:GetFont()
    if font then
        fontString:SetFont(font, size, flags)
    end
end

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

            local hex = string.format("|cff%02x%02x%02x",
                math.floor(r*255 + 0.5), math.floor(g*255 + 0.5), math.floor(b*255 + 0.5))
            local newText = hex .. data.text .. "|r"
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
        local text = textObj:GetText()

        if text then
            -- Optional: resize once
            -- if not textObj._WORS_FontResized then
            --     SetBubbleFontSize(textObj, 22)
            --     textObj._WORS_FontResized = true
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
                        local hexText = string.format("|cff%02x%02x%02x%s|r",
                            math.floor(rgb[1]*255 + 0.5), math.floor(rgb[2]*255 + 0.5), math.floor(rgb[3]*255 + 0.5),
                            cleanText)
                        textObj:SetText(hexText)
                    else
                        -- Pattern color support (e.g., patternabc:)
                        local pat = style and style:match("^pattern([0-9a-z]+)$")
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

--------------------------------------------------------------
-------------------- Edit Box Live Preview -------------------
--------------------------------------------------------------

-- 3.3.5: primary edit box is ChatFrameEditBox; some UIs expose ChatFrame1EditBox
local EB = _G.ChatFrameEditBox or _G.ChatFrame1EditBox
if EB then
    -- Remember whatever color the edit box already had; restore to this when leaving command mode.
    local baseR, baseG, baseB = EB:GetTextColor()
    local textColorOverridden = false

    local function ApplyTextColor(r,g,b)
        if not textColorOverridden then
            -- capture current base color just before first override
            baseR, baseG, baseB = EB:GetTextColor()
        end
        local font, size, flags = EB:GetFont()
        EB:SetTextColor(r or baseR, g or baseG, b or baseB)
        if font then EB:SetFont(font, size, flags) end
        textColorOverridden = true
    end

    local function RestoreTextColor()
        if textColorOverridden then
            local font, size, flags = EB:GetFont()
            EB:SetTextColor(baseR, baseG, baseB)
            if font then EB:SetFont(font, size, flags) end
            textColorOverridden = false
        end
    end

    -- Tiny swatch on the left side of the edit box to preview animated styles only
    local preview = CreateFrame("Frame", nil, EB)
    preview:SetSize(10, EB:GetHeight() > 6 and (EB:GetHeight() - 6) or 14)
    preview:SetPoint("LEFT", EB, "LEFT", 4, 0)
    preview:Hide()

    preview.tex = preview:CreateTexture(nil, "OVERLAY")
    preview.tex:SetAllPoints(preview)

    preview._mode   = nil   -- "glow" | "flash"
    preview._colors = nil
    preview._speed  = 0.5
    preview._phase  = 0

    local function StopPreview()
        preview._mode, preview._colors = nil, nil
        preview._phase = 0
        preview:SetScript("OnUpdate", nil)
        preview:Hide()
        -- IMPORTANT: do NOT force white; just restore whatever it was.
        RestoreTextColor()
    end

    local function Lerp(a,b,t) return a + (b-a)*t end

    local function StartAnimatedPreview(mode, colors, speed)
        preview._mode   = mode
        preview._colors = colors
        preview._speed  = speed or 0.5
        preview._phase  = math.random()

        preview:Show()
        -- Keep text readable for animated styles, but remember and restore original later.
        ApplyTextColor(1,1,1)

        preview:SetScript("OnUpdate", function(_, elapsed)
            local c = preview._colors
            if not c or #c == 0 then return end

            local r,g,b
            if mode == "flash" then
                preview._phase = (preview._phase + elapsed * preview._speed) % 1
                local idx = (preview._phase < 0.5) and 1 or 2
                local t = c[idx]; r,g,b = t[1], t[2], t[3]
            elseif #c == 2 then
                preview._phase = (preview._phase + elapsed * preview._speed) % 1
                local t = (math.sin(preview._phase * math.pi * 2) + 1) / 2
                r = Lerp(c[1][1], c[2][1], t)
                g = Lerp(c[1][2], c[2][2], t)
                b = Lerp(c[1][3], c[2][3], t)
            else
                preview._phase = (preview._phase + elapsed * preview._speed) % 1
                local idxf = preview._phase * (#c - 1)
                local i1 = math.floor(idxf) + 1
                local i2 = math.min(i1 + 1, #c)
                local t  = idxf - math.floor(idxf)
                r = Lerp(c[i1][1], c[i2][1], t)
                g = Lerp(c[i1][2], c[i2][2], t)
                b = Lerp(c[i1][3], c[i2][3], t)
            end

            preview.tex:SetTexture(1,1,1,1)
            preview.tex:SetVertexColor(r,g,b)
        end)
    end

    local function StartStaticTint(rgb)
        -- Static colors: no preview box, just tint the text.
        preview:SetScript("OnUpdate", nil)
        preview:Hide()
        ApplyTextColor(rgb[1], rgb[2], rgb[3])
    end

    -- Decide what to do based on the typed prefix
    local function DetectPrefixInfo(text)
        local style = text:match("^([%w_]+):")
        if not style then return nil end
        style = style:lower()

        if staticColors[style] then
            return { kind = "static", rgb = staticColors[style] }
        end

        if style == "rainbow" then
            return { kind = "animated", mode = "glow", colors = glowColours.glowrainbow, speed = bubbleSpeeds.glowrainbow or 0.4 }
        end

        if glowColours[style] then
            return { kind = "animated", mode = "glow", colors = glowColours[style], speed = bubbleSpeeds[style] or 0.5 }
        end

        if flashColours[style] then
            return { kind = "animated", mode = "flash", colors = flashColours[style], speed = bubbleSpeeds[style] or 1.5 }
        end

        if style:match("^pattern[%da-z]+$") then
            -- Pattern: no preview, no color change to edit box
            return { kind = "pattern" }
        end

        return nil
    end

    EB:HookScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local txt = self:GetText() or ""
        if txt == "" then
            StopPreview()
            return
        end

        local info = DetectPrefixInfo(txt)

        if not info then
            -- Not a command → restore original state
            StopPreview()
            return
        end

        if info.kind == "static" then
            StartStaticTint(info.rgb)
        elseif info.kind == "animated" then
            StartAnimatedPreview(info.mode, info.colors, info.speed)
        elseif info.kind == "pattern" then
            -- Valid but non-animated → no preview, no tint (restore if previously overridden)
            StopPreview()
        end
    end)

    EB:HookScript("OnEditFocusLost", StopPreview)
    EB:HookScript("OnHide", StopPreview)
end

--------------------------------------------------------------
-- End of ChatEffects.lua
--------------------------------------------------------------
