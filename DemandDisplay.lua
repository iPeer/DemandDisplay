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
    
    self.guiPosY = (g_currentMission.weatherTimeBackgroundOverlay.y - g_currentMission.weatherTimeBackgroundOverlay.height) + 0.015; -- DEFAULT Y position of the GUI, changed depending on if the clock is hidden or not
    self.guiColumnMargin = 0.01; -- MINIMUM margin between each "column" of data
    self.guiMinOffsetRight = 0.01; -- MINIMUM offset from the right edge of the screen
    self.guiMinRowMarginBottom = 0.01; -- MINIMUM gap between each row of data
    
    -- Changing the following might break some layout stuff (but you can if you want!)
    
    self.textScale = 0.02;

    
    -- DO NOT EDIT BELOW THIS LINE

    
    self.guiPosX = 1.0 - self.guiMinOffsetRight;
    
    self.maxWarpUpdate = 120; -- Max warp time to run updates on, stops flooding updates when using mods like fastForward to warp
    self.maxFramesWithoutUpdate = 120; -- Max number of frames we can not update for
    self.visible = true;
    
    loadFruitTypes();
    
end

function loadFruitTypes() 
    
    log("loading fruit types...");
    dd_fillTypes = {};
    log("----------------");
    for a=1, Fillable.NUM_FILLTYPES do
    
        local fruit = Fillable.fillTypeIndexToDesc[a];
        
        local name = fruit.nameI18N;
        if fruit.partOfEconomy or a == Fillable.FILLTYPE_SILAGE then -- LUA, Y U NO HAVE CONTINUE
            log(tostring(a)..": "..name);
            dd_fillTypes[a] = name;
        else
            log(string.format("Fruit Type '%s' (%d) ignored (not sellable to stations)", name, a));
        end
        
    end
    log("----------------");
    
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
    
    if economy ~= nil then
        
        local numDemands = economy.numberOfConcurrentDemands;
        local demandData = {};
        
        setTextBold(true);
        
        self.multiplierMaxWidth = getTextWidth(self.textScale, g_i18n:getText("hud_table_multiplier"));
        self.startTimerMaxWidth = getTextWidth(self.textScale, "10"..g_i18n:getText("hud_day").."23"..g_i18n:getText("hud_hour").."59"..g_i18n:getText("hud_min"));
        self.endDateMaxWidth = getTextWidth(self.textScale, g_i18n:getText("hud_table_days_ends").."999"..g_i18n:getText("hud_table_hours_ends").."23");
            
        self.stationMaxWidth = 0.0;
        self.cropMaxWidth = getTextWidth(self.textScale, g_i18n:getText("hud_table_crop"));
        
        for a=1, numDemands do
            
            local demand = {};
            local cDemand = economy.greatDemands[a];
            demand.isRunning = cDemand.isRunning;
            demand.multiplier = cDemand.demandMultiplier;
            demand.crop = getCropName(cDemand.fillTypeIndex);
        
            local cropWidth = getTextWidth(self.textScale, demand.crop);
            if cropWidth > self.cropMaxWidth then self.cropMaxWidth = cropWidth end;
            demand.startDay = cDemand.demandStart.day;
            demand.startHour = cDemand.demandStart.hour;
            demand.duration = cDemand.demandDuration;
            demand.station = getStationName(cDemand.stationName);

            local stationWidth = getTextWidth(self.textScale, getStationName(demand.station));
            if stationWidth > self.stationMaxWidth then self.stationMaxWidth = stationWidth end
            demand.valid = cDemand.isValid;
            
            demandData[a] = demand;
            
        end
        
        setTextBold(false);
        
        return demandData;
        
    end
    
    return {};
    
end

function DemandDisplay:update(dt)
    g_currentMission:addHelpButtonText(g_i18n:getText("DemandDisplay_input_key_combo"), InputBinding.DemandDisplay_input_key_combo);
    if InputBinding.hasEvent(InputBinding.DemandDisplay_input_key_combo) then
        if self.visible then
            self.visible = false;
        else
            self.visible = true;
        end
        log("GUI is now "..iif(self.visible, "visible", "hidden"));
    end        
    if self:shouldUpdate() then
        self.demandData = self:getGreatDemands();
    end
    
end

function DemandDisplay:shouldUpdate()

    if not self.visible or g_gui.currentGui ~= nill then return false end
    return true;
    
end

function DemandDisplay:draw()
    
    if not self:shouldUpdate() then return end
    
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
        
        setTextAlignment(RenderText.ALIGN_LEFT);
        
        local demandEnd = "--";
        local demandStart = "--";
        
        if demand.isRunning then -- calculating END (right) timer
            
            setTextBold(true);
            
            local seconds = getGameTimeSeconds();
            local startTime = (((demand.startDay * 24) * 60) * 60) + ((demand.startHour * 60) * 60);
            local remainingTime = ((demand.duration * 60) * 60) + 60;
            local timeData = {createTimeSeconds(seconds)};
            local endTime = (seconds - ((timeData[3] * 60) + timeData[4])) + remainingTime;
            local diff = endTime - seconds;
            
            local endStamp = createTimeStamp({createTimeSeconds(diff)}, true);
            
            demandEnd = endStamp;

            -- Calculate how red-shifted the text should be
            
            local maxDiff = endTime - startTime;
            local colourDec = 1.0 / maxDiff; -- how much to change each colour by per number
            --local changesPerColour = 1.0 / colourDec; -- How many changes, per colour, can there be
            
            local currDiff = maxDiff - diff; -- Current difference;
            local changeFactor = (colourDec * currDiff) * 2; -- Calculate how much we change a colour by - We have to double it for reasons I don't understand.
            local colourR, colourG, colourB = changeFactor, 1, 0;
            
            if colourR > 1.0 then
                colourG = colourG - (changeFactor - 1.0);
            end
            
            -- Sanity checking
            
            if colourR > 1.0 then colourR = 1.0 end
            if colourG > 1.0 then colourG = 1.0 end
            if colourB > 1.0 then colourB = 1.0 end
            
            if colourR < 0.0 then colourR = 0.0 end
            if colourG < 0.0 then colourG = 0.0 end
            if colourB < 0.0 then colourB = 0.0 end
            
            setTextColor(colourR, colourG, colourB, 1);
            
            
            
        else -- calculating START (left) timer
            
            setTextBold(false);
            
            local minutes = getGameTimeMinutes();
            local startTime = ((demand.startDay * 24) * 60) + (demand.startHour * 60);
            
            local endTime = startTime + (demand.duration * 60);
            
            local diff = startTime - minutes;
            
            local _startTime = createTimeStamp({createTime(diff)}, true);
            local _endTime = createEndTimestamp({createTime(endTime)});
            
            demandStart = _startTime;
            demandEnd = _endTime;
            
            setTextColor(1, 1, 1, 1);
            
        end
        
        -- Rendered "backwards" so we can make sure everything's nice and close to the right side without cutoff
        xPos = xPos - self.multiplierMaxWidth;
        renderText(xPos, yPos, self.textScale, string.format("%.1f", demand.multiplier).."x");
        xPos = xPos - (iif(demandisActive, self.startTimerMaxWidth, self.endDateMaxWidth) + self.guiColumnMargin);
        
        -- Countdown timers
        
        if demand.isRunning then
            
            renderText(xPos, yPos, self.textScale, demandEnd);
            xPos = xPos - (self.startTimerMaxWidth + self.guiColumnMargin);
            
            --renderText(xPos, yPos, self.textScale, running); -- Empty data looks better than "RUNNING"
            xPos = xPos - (self.stationMaxWidth + self.guiColumnMargin);
            
        else
            
            renderText(xPos, yPos, self.textScale, demandEnd);
            xPos = xPos - (self.startTimerMaxWidth + self.guiColumnMargin);
            
            renderText(xPos, yPos, self.textScale, demandStart);
            xPos = xPos - (self.stationMaxWidth + self.guiColumnMargin);
            
        end
        
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

function getStationName(name)
    if g_i18n:hasText(name) then
        return g_i18n:getText(name);
    end
    return name;
end

function getCropName(id) -- TODO
    if dd_fillTypes[id] ~= nil then
        return dd_fillTypes[id];
    end
    return "Unknown product id: "..tostring(id)
end

function log(str)
    print("[DemandDisplay]: "..tostring(str));
end

function iif(c,t,f)
    if c then return t else return f end;
end
    
addConsoleCommand("dd_getcurrentwarp", "", "consoleDisplayWarp", DemandDisplay);
addConsoleCommand("dd_disableupdates", "", "consoleToggleUpdates", DemandDisplay);
addConsoleCommand("dd_displayfirstgdend", "", "consoleDisplayFirstDemandDuration", DemandDisplay);

-- Hook for events
addModEventListener(DemandDisplay);