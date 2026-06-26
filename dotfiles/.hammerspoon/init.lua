local dimmers = {}
local screenWatcher = nil

-- SketchyBar geometry (keep in sync with .config/sketchybar/sketchybarrc)
local bar = { height = 32, yOffset = 6, margin = 10, radius = 9 }

-- 1. Build the canvases ONCE
local function initCanvases()
    -- Clean up any existing canvases first
    for _, dimmer in pairs(dimmers) do
        dimmer:delete()
    end
    dimmers = {}

    -- Create a persistent overlay for each monitor
    for _, screen in ipairs(hs.screen.allScreens()) do
        local screenID = screen:id()
        local screenFrame = screen:fullFrame()
        local canvas = hs.canvas.new(screenFrame)
        
        -- Element 1: The dark background layer
        canvas[1] = {
            type = "rectangle",
            action = "fill",
            fillColor = { white = 0, alpha = 0.3 }
        }

        -- Element 2: SketchyBar hole (only shown on the focused window's screen)
        canvas[2] = {
            type = "rectangle",
            action = "fill",
            frame = { x = 0, y = 0, w = 0, h = 0 },
            roundedRectRadii = { xRadius = bar.radius, yRadius = bar.radius },
            compositeRule = "clear"
        }

        -- Element 3: The window hole punch (initially hidden/zero size)
        canvas[3] = {
            type = "rectangle",
            action = "fill",
            frame = { x = 0, y = 0, w = 0, h = 0 },
            roundedRectRadii = { xRadius = 15, yRadius = 15 },
            compositeRule = "clear"
        }

        -- Element 4: The Border/Stroke
        canvas[4] = {
            type = "rectangle",
            action = "stroke",
            strokeColor = { white = 1.0, alpha = 0.2 }, -- Soft white border
            strokeWidth = 2,
            roundedRectRadii = { xRadius = 15, yRadius = 15 },
            frame = { x = 0, y = 0, w = 0, h = 0 }
        }

        canvas:level(hs.canvas.windowLevels.floating)
        canvas:show()
        dimmers[screenID] = canvas
    end
end

-- 2. Only move the hole (Lightning Fast)
local function updateHole()
    local focusedWin = hs.window.focusedWindow()
    local activeScreen = focusedWin and focusedWin:screen()
    
    if not focusedWin or not activeScreen then
        -- If no window is active, hide both holes on all screens
        for _, canvas in pairs(dimmers) do
            canvas[2].frame = { x = 0, y = 0, w = 0, h = 0 }
            canvas[3].frame = { x = 0, y = 0, w = 0, h = 0 }
        end
        return
    end

    local activeScreenID = activeScreen:id()
    local winFrame = focusedWin:frame()

    -- Move the hole to match the window, and hide it on inactive screens
    for screenID, canvas in pairs(dimmers) do
        if screenID == activeScreenID then
            local screenFrame = activeScreen:fullFrame()
            canvas[3].frame = {
                x = winFrame.x - screenFrame.x,
                y = winFrame.y - screenFrame.y,
                w = winFrame.w,
                h = winFrame.h
            }
            -- Undim the SketchyBar on this screen only
            canvas[2].frame = {
                x = bar.margin,
                y = bar.yOffset,
                w = screenFrame.w - 2 * bar.margin,
                h = bar.height
            }

        else
            canvas[2].frame = { x = 0, y = 0, w = 0, h = 0 }
            canvas[3].frame = { x = 0, y = 0, w = 0, h = 0 }
        end
    end
end

-- 3. Initialize everything
initCanvases()
updateHole()

-- 4. Watch for window changes and update ONLY the hole
local wf = hs.window.filter.default
wf:subscribe(hs.window.filter.windowFocused, updateHole)
wf:subscribe(hs.window.filter.windowMoved, updateHole)

-- 5. Rebuild canvases if you plug or unplug a monitor
screenWatcher = hs.screen.watcher.new(function()
    initCanvases()
    updateHole()
end)
screenWatcher:start()

hs.alert.show("Hammerspoon reloaded")

