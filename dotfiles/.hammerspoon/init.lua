require("hs.ipc") -- enables the `hs` command-line tool

-- Persist timer/watcher across the chunk's lifetime so the GC can't reap them.
DimmerState = DimmerState or {}

local dimmers = {}

local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"
local BAR_ITEMS = { "left_island", "right_island", "media_island", "calendar" } -- the visible bar islands
local ISLAND_RADIUS = 14 -- matches background.corner_radius in sketchybarrc
local ISLAND_HEIGHT = 34 -- matches background.height in sketchybarrc (rects report full bar height)
-- macOS standard window corner radius (no API to read it per-window; this matches
-- standard AppKit windows. Borderless/terminal/fullscreen windows may differ.)
local WINDOW_RADIUS = 12

-- 1. Build the canvases ONCE
local function initCanvases()
    for _, dimmer in pairs(dimmers) do
        dimmer:delete()
    end
    dimmers = {}

    for _, screen in ipairs(hs.screen.allScreens()) do
        local canvas = hs.canvas.new(screen:fullFrame())

        -- [1] dark overlay
        canvas[1] = {
            type = "rectangle",
            action = "fill",
            fillColor = { white = 0, alpha = 0.3 }
        }

        -- [2..4] bar island holes (up to 3: left, right, media)
        for i = 2, 4 do
            canvas[i] = {
                type = "rectangle",
                action = "fill",
                frame = { x = 0, y = 0, w = 0, h = 0 },
                roundedRectRadii = { xRadius = ISLAND_RADIUS, yRadius = ISLAND_RADIUS },
                compositeRule = "clear"
            }
        end

        -- [5] focused-window hole
        canvas[5] = {
            type = "rectangle",
            action = "fill",
            frame = { x = 0, y = 0, w = 0, h = 0 },
            roundedRectRadii = { xRadius = WINDOW_RADIUS, yRadius = WINDOW_RADIUS },
            compositeRule = "clear"
        }

        -- [6] window border
        canvas[6] = {
            type = "rectangle",
            action = "stroke",
            strokeColor = { white = 1.0, alpha = 0.2 },
            strokeWidth = 2,
            roundedRectRadii = { xRadius = WINDOW_RADIUS, yRadius = WINDOW_RADIUS },
            frame = { x = 0, y = 0, w = 0, h = 0 }
        }

        canvas:level(hs.canvas.windowLevels.floating)
        canvas:show()
        dimmers[screen:id()] = canvas
    end
end

-- Query SketchyBar for the global-coordinate rects of every visible island.
local function islandRects()
    local rects = {}
    for _, name in ipairs(BAR_ITEMS) do
        local out = hs.execute(SKETCHYBAR .. " --query " .. name .. " 2>/dev/null")
        if out and #out > 0 then
            local ok, data = pcall(hs.json.decode, out)
            if ok and data and data.bounding_rects then
                for _, r in pairs(data.bounding_rects) do
                    local o, s = r.origin, r.size
                    -- skip hidden items (parked at -9999 with 1x1 size)
                    if o and s and s[1] and s[1] > 2 and o[1] > -9000 then
                        rects[#rects + 1] = { x = o[1], y = o[2], w = s[1], h = s[2] }
                    end
                end
            end
        end
    end
    return rects
end

local function activeScreen()
    local win = hs.window.focusedWindow()
    return win and win:screen(), win
end

-- Fast path: move the focused-window hole (no shell-out, runs on every drag).
local function updateWindowHole()
    local scr, win = activeScreen()

    if not win or not scr then
        for _, canvas in pairs(dimmers) do
            canvas[5].frame = { x = 0, y = 0, w = 0, h = 0 }
            canvas[6].frame = { x = 0, y = 0, w = 0, h = 0 }
        end
        return
    end

    local activeID = scr:id()
    local sf = scr:fullFrame()
    local wf = win:frame()
    for screenID, canvas in pairs(dimmers) do
        if screenID == activeID then
            local f = { x = wf.x - sf.x, y = wf.y - sf.y, w = wf.w, h = wf.h }
            canvas[5].frame = f
            canvas[6].frame = f
        else
            canvas[5].frame = { x = 0, y = 0, w = 0, h = 0 }
            canvas[6].frame = { x = 0, y = 0, w = 0, h = 0 }
        end
    end
end

-- Bar islands: match each queried rect to a screen by coordinate containment
-- (robust to SketchyBar's display-number ordering), then undim it.
local function updateBarHoles()
    local scr = activeScreen()
    local activeID = scr and scr:id()

    local holes = {}
    if scr then
        local sf = scr:fullFrame()
        for _, r in ipairs(islandRects()) do
            local cx, cy = r.x + r.w / 2, r.y + r.h / 2
            if cx >= sf.x and cx < sf.x + sf.w and cy >= sf.y and cy < sf.y + sf.h then
                -- rects report the full bar height; shrink to the pill and re-center
                local y, h = r.y - sf.y, r.h
                if h > ISLAND_HEIGHT then
                    y = y + (h - ISLAND_HEIGHT) / 2
                    h = ISLAND_HEIGHT
                end
                holes[#holes + 1] = { x = r.x - sf.x, y = y, w = r.w, h = h }
            end
        end
    end

    for screenID, canvas in pairs(dimmers) do
        for i = 1, 3 do
            if screenID == activeID and holes[i] then
                canvas[i + 1].frame = holes[i]
            else
                canvas[i + 1].frame = { x = 0, y = 0, w = 0, h = 0 }
            end
        end
    end
end

local function updateAll()
    updateWindowHole()
    updateBarHoles()
end

-- Init
initCanvases()
updateAll()

-- Window events: cheap window-hole move on drag, full refresh on focus change
local wf = hs.window.filter.default
wf:subscribe(hs.window.filter.windowFocused, updateAll)
wf:subscribe(hs.window.filter.windowMoved, updateWindowHole)

-- Catch island width changes that aren't tied to window events (app name,
-- media appearing, spaces hiding) without polling the window hole.
if DimmerState.timer then DimmerState.timer:stop() end
DimmerState.timer = hs.timer.doEvery(2, updateBarHoles)

-- Rebuild on monitor change — DEBOUNCED. Dock/undock emits a burst of
-- screen-change events over many seconds; rebuilding on each one thrashes the
-- overlay against transient geometry until displays settle. Instead, reset a
-- timer on every event and rebuild once, 1.5s after the events stop.
if DimmerState.screenWatcher then DimmerState.screenWatcher:stop() end
DimmerState.screenWatcher = hs.screen.watcher.new(function()
    if DimmerState.rebuildTimer then DimmerState.rebuildTimer:stop() end
    DimmerState.rebuildTimer = hs.timer.doAfter(1.5, function()
        initCanvases()
        updateAll()
    end)
end)
DimmerState.screenWatcher:start()

hs.alert.show("Hammerspoon reloaded")
