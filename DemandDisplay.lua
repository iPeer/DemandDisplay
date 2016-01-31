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

function DemandDisplay.consoleLuaIsBadinThisGame()
    log("Both are floored");
    log("11 Hours: "..math.floor(((660 % 1440) / 60)));
    log("11 Hours 1 Minute: "..math.floor(((661 % 1440) / 60)));
end

-- The juicy stuff

function DemandDisplay:loadMap(name) 
    -- Do stuff when the map loads
    
    -- You can edit these values to tweak how it will render in game
    
    self.overlayWidth = 0.40; -- Width of the entire overlay
    self.guiPosY = (g_currentMission.weatherTimeBackgroundOverlay.y - g_currentMission.weatherTimeBackgroundOverlay.height) - 0.03; -- DEFAULT Y position of the GUI, changed depending on if the clock is hidden or not -- this is ADDED TO the offset if the clock is visible
    self.guiColumnMargin = 0.01; -- MINIMUM margin between each "column" of data
    self.guiMinOffsetRight = 0.02; -- MINIMUM offset from the right edge of the screen
    self.guiMinRowMarginBottom = 0.01; -- MINIMUM gap between each row of data
    
    -- Changing the following might break some layout stuff (but you can if you want!)
    
    self.textScale = 0.02;

    
    -- DO NOT EDIT BELOW THIS LINE
    
    --self.totalGUIRowWidth = 0.4 + 0.12 + 0.03; -- Apparently hard-coding is the only way I can do this (for now?)
    --self.totalGUIRowWidth = self.stationNameWidth + self.cropNameWidth + (self.startsTimeWidth * 2) + self.multiplierWidth + (self.guiColumnMargin * 4);
    
    --self.totalGUIRowWidth = (self.stationNameWidth + self.cropNameWidth + (self.startsTimeWidth * 2.0) + self.multiplierWidth) * (self.guiColumnMargin * 4.0) + self.guiMinOffsetRight;
    
    log(self.totalGUIRowWidth);
    
    self.guiPosX = 1.0 - self.guiMinOffsetRight;
    --math.abs(0.5 - (self.totalGUIRowWidth / 2));
    
    self.maxWarpUpdate = 120; -- Max warp time to run updates on, stops flooding updates when using mods like fastForward to warp
    self.maxFramesWithoutUpdate = 120; -- Max number of frames we can not update for
    self.visible = true;
    
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


function DemandDisplay:getGreatDemands() 
    
    local economy = g_currentMission.economyManager;
    
    --if economy == nil then log("economy == nil"); end
    
    if economy ~= nil then
        
        local numDemands = economy.numberOfConcurrentDemands;
        local demandData = {};
        
        self.multiplierMaxWidth = getTextWidth(self.textScale, g_i18n:getText("hud_table_multiplier"));
        self.startTimerMaxWidth = getTextWidth(self.textScale, "10"..g_i18n:getText("hud_day").."23"..g_i18n:getText("hud_hour").."59"..g_i18n:getText("hud_min"));
        self.endDateMaxWidth = getTextWidth(self.textScale, g_i18n:getText("hud_table_days_ends").."999"..g_i18n:getText("hud_table_hours_ends").."23");
            
        self.stationMaxWidth = 0.0;
        self.cropMaxWidth = getTextWidth(self.textScale, g_i18n:getText("hud_table_crop"));
        
        --log("Number of demands: "..numDemands);
        
        for a=1, numDemands do
            
            local demand = {};
            local cDemand = economy.greatDemands[a];
            demand.isRunning = cDemand.isRunning;
            demand.multiplier = cDemand.demandMultiplier;
            --log("M: "..demand.multiplier.."/"..cDemand.demandMultiplier);
            demand.crop = getCropName(cDemand.fillTypeIndex);
            local cropWidth = getTextWidth(self.textScale, getCropName(demand.crop));
            if cropWidth > self.cropMaxWidth then self.cropMaxWidth = cropWidth end;
            --log("C: "..demand.crop.."/"..cDemand.fillTypeIndex);
            demand.startDay = cDemand.demandStart.day;
            demand.startHour = cDemand.demandStart.hour;
            demand.duration = cDemand.demandDuration;
            --demand.end = demand.startHour + demand.duration;
            -- TODO: Check if station is actually valid?
            demand.station = getStationName(cDemand.stationName);

            local stationWidth = getTextWidth(self.textScale, getStationName(demand.station));
            log(getStationName(demand.station).." / "..stationWidth.." vs "..self.stationMaxWidth.." / "..tostring((stationWidth > self.stationMaxWidth)));
            if stationWidth > self.stationMaxWidth then self.stationMaxWidth = stationWidth end
            demand.valid = cDemand.isValid;
            
            demandData[a] = demand;
            
        end
        
        --log(self.multiplierMaxWidth.." / "..self.startTimerMaxWidth.." / "..self.endDateMaxWidth.." / "..self.stationMaxWidth.." / "..self.cropMaxWidth);
        
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
        --log("Update requested");
        self.framesSinceUpdate = 0;
        self.demandData = self:getGreatDemands();
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
    
    -- Render column titles
    local x = self.guiPosX - self.multiplierMaxWidth;
    
    setTextBold(true);
    
    renderText(x, self.guiPosY, self.textScale, g_i18n:getText("hud_table_multiplier"));
    x = x  - (iif(demandisActive, self.startTimerMaxWidth, self.endDateMaxWidth) + self.guiColumnMargin);
    renderText(x, self.guiPosY, self.textScale, g_i18n:getText("hud_table_endsin"));
    x = x - (self.startTimerMaxWidth + self.guiColumnMargin);
    renderText(x, self.guiPosY, self.textScale, g_i18n:getText("hud_table_startsin"));
    x = x - (self.stationMaxWidth + self.guiColumnMargin)
    renderText(x, self.guiPosY, self.textScale, g_i18n:getText("hud_table_station"));
    x = x - (self.cropMaxWidth + self.guiColumnMargin);
    renderText(x, self.guiPosY, self.textScale, g_i18n:getText("hud_table_crop"));
    
    setTextBold(false);
   
    for i=1, table.maxn(self.demandData) do
       
        local demand = self.demandData[i];
        local xPos = self.guiPosX;
        local yPos = self.guiPosY - ((self.textScale + self.guiMinRowMarginBottom) * i);
        
        if demand.isRunning then
            setTextColor(0, 1, 0, 1); -- green
        else
            setTextColor(1, 1, 1, 1); -- white
        end
        setTextAlignment(RenderText.ALIGN_LEFT);
        --log("x: "..xPos..", y: "..yPos);
        
        -- Rendered "backwards" so we can make sure everything's nice and close to the right side without cutoff
        xPos = xPos - self.multiplierMaxWidth;
        --log(getTextWidth(self.textScale, demand.multiplier.."x"));
        renderText(xPos, yPos, self.textScale, string.format("%.1f", demand.multiplier).."x");
        xPos = xPos - (iif(demandisActive, self.startTimerMaxWidth, self.endDateMaxWidth) + self.guiColumnMargin);
        --setTextAlignment(RenderText.ALIGN_CENTER);
        if demand.isRunning then -- calculating END (right) timer
            
            local running = string.upper(g_i18n:getText("hud_running"));
            local seconds = getGameTimeSeconds();
            local remainingTime = ((demand.duration * 60) * 60) + 60;
            local timeData = {createTimeSeconds(seconds)};
            local endTime = (seconds - ((timeData[3] * 60) + timeData[4])) + remainingTime;
            --local dStartTime = ((((demand.startDay * 24) * 60) * 60) + ((demand.startHour * 60) * 60));
            --local dEndTime = dStartTime + ((demand.originalDuration * 60) * 60);
            local diff = endTime - seconds;
            
            local endStamp = createTimeStamp({createTimeSeconds(diff)}, true);
            
            log("Rem: "..remainingTime..", S: "..seconds..", end: "..endTime..", diff: "..diff);
            
            renderText(xPos, yPos, self.textScale, endStamp);
            xPos = xPos - (self.startTimerMaxWidth + self.guiColumnMargin);
            
            renderText(xPos, yPos, self.textScale, running);
            xPos = xPos - (self.stationMaxWidth + self.guiColumnMargin);
            
        else -- calculating START (left) timer
            
            local minutes = getGameTimeMinutes();
            local startTime = ((demand.startDay * 24) * 60) + (demand.startHour * 60);
            
            local endTime = startTime + (demand.duration * 60);
            
            local diff = startTime - minutes;
            
            local _startTime = createTimeStamp({createTime(diff)}, true);
            local _endTime = createEndTimestamp({createTime(endTime)});
            
            renderText(xPos, yPos, self.textScale, _endTime);
            xPos = xPos - (self.startTimerMaxWidth + self.guiColumnMargin);
            
            renderText(xPos, yPos, self.textScale, _startTime);
            xPos = xPos - (self.stationMaxWidth + self.guiColumnMargin);
            
        end
        --setTextAlignment(RenderText.ALIGN_LEFT);
        
        renderText(xPos, yPos, self.textScale, demand.station);
        xPos = xPos - (self.cropMaxWidth + self.guiColumnMargin);
        
        renderText(xPos, yPos, self.textScale, tostring(demand.crop));
        
    end
    
end

function createEndTimestamp(data)
    
    return string.upper(g_i18n:getText("hud_table_days_ends"))..tostring(data[1])..string.upper(g_i18n:getText("hud_table_hours_ends"))..tostring(data[2]);
    
end

function getGameTimeMinutes()
    return ((g_currentMission.environment.currentDay * 24) * 60) + (g_currentMission.environment.currentHour * 60) + g_currentMission.environment.currentMinute;
end

function getGameTimeSeconds()
    
    return (((g_currentMission.environment.currentDay * 24) * 60) * 60) + math.floor(g_currentMission.environment.dayTime / 1000);
    
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

function createTimeSeconds(seconds)
    
    local hours = math.floor(seconds / 3600);
    local minutes = math.floor((seconds % 3600) / 60);
    if minutes == 60 then
        hours = hours + 1;
        minutes = 0;
    end
    local _seconds = seconds % 60;
    local days = math.floor(hours / 24);
    hours = hours - (days * 24);
    
    return days, hours, minutes, _seconds;
    
end

function createTime(minutes)
    
    local days = math.floor(minutes / 1440);
    local hours = math.floor((minutes % 1440) / 60);
    local _minutes = math.floor(minutes % 60);
    
    return days, hours, _minutes;
    
end

function getStationName(name) -- TODO
    return name;
end

function getCropName(id) -- TODO
    return tostring(id);
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
addConsoleCommand("dd_11hours", "", "consoleLuaIsBadinThisGame", DemandDisplay);

-- Hook for events
addModEventListener(DemandDisplay);