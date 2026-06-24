-- Define your modifier key
local mod = {"alt"}

-- Ignor hidden windows
local wf = hs.window.filter.new():setCurrentSpace(true)

-- Use hjkl to navigate
hs.hotkey.bind(mod, "h", function() wf:focusWindowWest() end)
hs.hotkey.bind(mod, "j", function() wf:focusWindowSouth() end)
hs.hotkey.bind(mod, "k", function() wf:focusWindowNorth() end)
hs.hotkey.bind(mod, "l", function() wf:focusWindowEast() end)

-- Last known position of active window
local lastKnownCenter = nil

-- Continuously track the center point of the currently focused window
wf:subscribe({hs.window.filter.windowFocused, hs.window.filter.windowMoved}, function(win)
    if win then
        local f = win:frame()
        lastKnownCenter = { x = f.x + (f.w / 2), y = f.y + (f.h / 2) }
    end
end)

-- Watch for windows being closed and jump to the nearest neighbor
wf:subscribe(hs.window.filter.windowDestroyed, function()
    hs.timer.doAfter(0.1, function()
        local currentFocus = hs.window.focusedWindow()
        
        -- If focus dropped to nothing or the Desktop
        if not currentFocus or not currentFocus:isStandard() then
            local availableWindows = wf:getWindows()
            
            if #availableWindows > 0 then
                -- Fallback: if we don't have a saved location, pick the first available
                if not lastKnownCenter then
                    availableWindows[1]:focus()
                    return
                end
                
                local closestWindow = availableWindows[1]
                local shortestDistance = math.huge
                
                -- Loop through all open windows to find the one physically closest
                for _, win in ipairs(availableWindows) do
                    local f = win:frame()
                    local center = { x = f.x + (f.w / 2), y = f.y + (f.h / 2) }
                    
                    -- Calculate the distance between the two center points
                    local distance = (center.x - lastKnownCenter.x)^2 + (center.y - lastKnownCenter.y)^2
                    
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestWindow = win
                    end
                end
                
                -- Jump focus to the winner
                closestWindow:focus()
            end
        end
    end)
end)

-- Styling
hs.hints.fontName = ".AppleSystemUIFont"
hs.hints.fontSize = 22


hs.hints.hintChars = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B", "C", "D", "E", "F"}
hs.hints.showTitleThresh = 0
hs.hints.iconAlpha = 0.9

-- Use alt+space to show all windows
-- By default hammerspoon numbers windows by last used, this sorts them spatially (so numbers are more meaningful)
hs.hotkey.bind({"alt"}, "space", function()
    -- Get all windows on the current space
    local windows = hs.window.filter.new():setCurrentSpace(true):getWindows()
    
    -- Sort windows spatially (Left-to-Right, Top-to-Bottom)
    table.sort(windows, function(a, b)
        local frameA = a:frame()
        local frameB = b:frame()
        
        -- If windows are on the same horizontal row (within a 20-pixel tolerance)
        if math.abs(frameA.y - frameB.y) < 20 then
            return frameA.x < frameB.x -- Sort left to right
        else
            return frameA.y < frameB.y -- Sort top to bottom
        end
    end)
    
    hs.hints.windowHints(windows)
end)


hs.alert.show("Hammerspoon reloaded")

