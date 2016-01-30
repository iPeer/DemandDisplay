DemandDisplay = {};
DemandDisplay.configDir = g_currentModDirectory; -- not currently used (future proofing, yaay!)
DemandDisplay.debug = true;
DemandDisplay.updatesEnabled = true;

-- Console commands

function DemandDisplay.consoleDisplayWarp()
    
    log("Current warp factor: "..g_currentMission.missionStats.timeScale);
    
end

function DemandDisplay.consoleDisplayFirstDemandDuration()
    
    log("First demand duration: "..self.demandData[1].duration);
    
end

function DemandDisplay.consoleToggleUpdates() 
    self.updatesEnabled = not self.updatesEnabled;
    log("Updated have been "..iif(selfUpdatesEnabled, "enabled", "disabled"));
end


-- The juicy stuff

function DemandDisplay:loadMap(name) 
    -- Do stuff when the map loads
    
    -- You can edit these values to tweak how it will render in game
    
    self.overlayWidth = 0.40; -- Width of the entire overlay
    --self.guiPosY = 0.03 + (1.0 - g_currentMission.weatherTimeBackgroundOverlay.y) + g_currentMission.weatherTimeBackgroundOverlay.height or 0.03; 
    self.guiPosY = 0.95; -- DEFAULT Y position of the GUI, changed depending on if the clock is hidden or not -- this is ADDED TO the offset if the clock is visible
    -- Previous value of yPos: (g_currentMission.weatherTimeBackgroundOverlay.y - g_currentMission.weatherTimeBackgroundOverlay.height) - 0.03
    self.guiColumnMargin = 0.03; -- MINIMUM margin between each "column" of data
    self.guiMinOffsetRight = 0.0; -- NOT USED - MINIMUM offset from the right edge of the screen
    self.guiMinRowMarginBottom = 0.01; -- MINIMUM gap between each row of data
    
    -- Changing the following might break some layout stuff (but you can if you want!)
    
    self.stationNameWidth = 0.1; -- 0.1
    self.cropNameWidth = 0.1; -- 0.1
    self.startsTimeWidth = 0.08; -- 0.06 - Also used for end time width
    self.multiplierWidth = 0.04; -- 0.04
    
    self.textScale = 0.03;

    
    -- DO NOT EDIT BELOW THIS LINE
    
    --self.totalGUIRowWidth = 0.4 + 0.12 + 0.03; -- Apparently hard-coding is the only way I can do this (for now?)
    self.totalGUIRowWidth = self.stationNameWidth + self.cropNameWidth + (self.startsTimeWidth * 2) + self.multiplierWidth + (self.guiColumnMargin * 4);
    
    --self.totalGUIRowWidth = (self.stationNameWidth + self.cropNameWidth + (self.startsTimeWidth * 2.0) + self.multiplierWidth) * (self.guiColumnMargin * 4.0) + self.guiMinOffsetRight;
    
    log(self.totalGUIRowWidth);
    
    self.guiPosX = 0.5 - (self.totalGUIRowWidth / 2);
    
    self.maxWarpUpdate = 120; -- Max warp time to run updates on, stops flooding updates when using mods like fastForward to warp
    self.maxFramesWithoutUpdate = 120; -- Max number of frames we can not update for
    self.visible = iif(self.debug, true, false);
    
end

function DemandDisplay:deleteMap(name)
    -- Cleanup when a map is unloaded
end

function DemandDisplay:keyEvent(unicode, sym, modifier, isDown)
    -- Check for key presses
end

function DemandDisplay:mouseEvent(x, y, isDown, isUp, button)
    -- Check for mouse inputs
end


function getGreatDemands() 
    
    local economy = g_currentMission.economyManager;
    
    if economy == nil then log("economy == nil"); end
    
    if economy ~= nil then
        
        local numDemands = economy.numberOfConcurrentDemands;
        local demandData = {};
        
        log("Number of demands: "..numDemands);
        
        for a=1, numDemands do
            
            local demand = {};
            local cDemand = economy.greatDemands[a];
            demand.isRunning = cDemand.isRunning;
            demand.multiplier = cDemand.demandMultiplier;
            demand.crop = cDemand.fillTypeIndex;
            demand.startDay = cDemand.demandStart.day;
            demand.startHour = cDemand.demandStart.hour;
            demand.duration = cDemand.demandDuration;
            --demand.end = demand.startHour + demand.duration;
            -- TODO: Check if station is actually valid?
            demand.station = cDemand.stationName;
            demand.valid = cDemand.isValid;
            
            demandData[a] = demand;
            
        end
        
        return demandData;
        
    end
    
    return {};
    
end

function DemandDisplay:update(dt)
    --log("Update!");
    g_currentMission:addHelpButtonText(g_i18n:getText("DemandDisplay_input_key_combo"), InputBinding.DemandDisplay_input_key_combo);
    if InputBinding.hasEvent(InputBinding.DemandDisplay_input_key_combo) then
        logDebug("Key combination pressed!");
        if self.visible then
            self.visible = false;
        else
            self.visible = true;
        end
        log("GUI is now "..iif(self.visible, "visible", "hidden"));
    end        
    if self:shouldUpdate() then
        log("Update requested");
        self.framesSinceUpdate = 0;
        self.demandData = getGreatDemands();
    end
    
end

function DemandDisplay:shouldUpdate()

    --if not self.visible or not self.updatesEnabled or g_gui.currentGui ~= nil then return false end
    --if g_currentMission.missionStats.timeScale > self.maxWarpUpdate then
    --    if self.framesSinceUpdate > self.maxFramesWithoutUpdate then return true end
    --    return false
    --end
    return true;
    
end



function DemandDisplay:draw()
    --log("Draw");
    setTextColor(1,1,1,1);
    --renderText(self.guiPosX, self.guiPosY, self.textScale, "Test");
    renderText(0, 0.9, self.textScale, "0 0.9");
    renderText(0.9, 0, self.textScale, "0.9 0");
    local yPos = self.guiPosY;
    local xPos = self.guiPosX;
    setTextColor(1,1,1,1);
    setTextAlignment(RenderText.ALIGN_CENTER);
    --setTextBold(true);
    local titleWidth = getTextWidth(self.textScale, g_i18n:getText("hud_title"));
    local titleHeight = getTextHeight(self.textScale, g_i18n:getText("hud_title"));
    --renderText(xPos + (titleWidth / 2.0), yPos, self.textScale, g_i18n:getText("hud_title"));
    --yPos = yPos + self.guiMinRowMarginBottom;
    --setTextBold(false);
    for i=1, table.maxn(self.demandData) do
        
        local demand = self.demandData[i];
        local x = xPos;
        
        --log("Text X: "..x.."/"..xPos);
        --log("Text Y: "..yPos)
        
        if demand.isActive then
            setTextColor(0, 1, 0, 1); -- green
        else
            setTextColor(1, 1, 1, 1); -- white
        end

        local textHeight = getTextHeight(self.textScale, demand.station);
        
        -- Station
        renderText(x, yPos, self.fontScale, "Test");
        renderText(x, yPos, self.fontScale, demand.station);
        x = x + (self.stationNameWidth + self.guiColumnMargin);

        -- Crop
        
        renderText(x, yPos, self.fontScale, demand.crop);
        x = x + (self.cropNameWidth + self.guiColumnMargin);
        
        -- Starts in/ACTIVE
        local text = g_i18n:getText("hud_running");
        local endText = "--";
        
        if not demand.isRunning then
            
            local currentDay = g_currentMission.environment.currentDay;
            local currentHour = g_currentMission.environment.currentHour;
            local currentMinute = g_currentMission.environment.currentMinute;
            
            local time = (currentHour * 60) + ((currentDay * 24) * 60) + currentMinute; -- total game time, in minutes
            local endTime = time + ((demand.duration * 24) * 60);
            
            local timeToStart = time - (((demand.startDay * 24) * 60) + (demand.startHour * 60));
            local duration = endTime - time;

            local startTimeData = {createTime(timeToStart)};
            local endTimeData = {createTime(endTime)};
            local timeToEndData = {createTime(duration)};
            
            text = createTimeStamp(startTimeData, true);
            endText = createTimeStamp(timeToEndData, false);
            
        end
        
        log("Start text: "..text);
        renderText(x, yPos, self.fontScale, text);
        x = x + (self.startsTimeWidth + self.guiColumnMargin);
        
        -- Ends in
        log("End text: "..endText);
        renderText(x, yPos, self.fontScale, endText);
        x = x + (self.startsTimeWidth + self.guiColumnMargin);
        
        -- Multiplier
        log("Multiplier: "..demand.multiplier);
        renderText(x, yPos, self.fontScale, string.format("%.1f", demand.multiplier).."x");
        
        
        yPos = yPos - (textHeight + self.guiMinRowMarginBottom);
        
    end

        self.framesSinceUpdate = self.framesSinceUpdate + 1;

end    
    
function createTimeStamp(data, forceMins) 
        --logDebug(data);
        local time = "";
        if forceMins or data[3] > 0 then
            time = tostring(data[3])..g_i18n:getText("hud_min");
        end
        if data[2] > 0 then -- hours > 0
            time = tostring(data[2])..g_i18n:getText("hud_hour")..time;
        end
        if data[1] > 0 then -- days > 0
            time = tostring(data[1])..g_i18n:getText("hud_day")..time;
        end  
        return time;
end

function createTime(minutes)
    
    local days = math.floor((minutes / 24) / 60);
    local hours = math.floor((minutes / 60) % 24);
    local minutes = math.floor(minutes % 60);
    
    return days, hours, minutes;
    
end

function log(str)
    print("[DemandDisplay]: "..tostring(str));
end

function logDebug(str)
    log("(DEBUG) "..tostring(str));
end

function iif(c,t,f)
    if c then return t else return f end;
end
    
addConsoleCommand("dd_getcurrentwarp", "", "consoleDisplayWarp", DemandDisplay);
addConsoleCommand("dd_disableupdates", "", "consoleToggleUpdates", DemandDisplay);
addConsoleCommand("dd_displayfirstgdend", "", "consoleDisplayFirstDemandDuration", DemandDisplay);

-- Hook for events
addModEventListener(DemandDisplay);