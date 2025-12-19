-- World Map screen for Phase 2: Location Selection
-- Displays 6 locations (Revelstoke, Invermere, Radium, Golden, Jasper, Kananaskis)
-- Clicking a location shows details (difficulty, fauna, flora, events)
-- Confirming selection creates a save file and starts the game

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')
local Locations = require('lib.locations')
local SaveSystem = require('lib.save_system')
local log = require('lib.logger')

local WorldMapScreen = {
    buttons = {},
    location_buttons = {},
    selected_location = nil,
    detail_panel_visible = false,
    confirm_button = nil,
    back_button = nil,
}

-- Create initial game state for a location
-- @param location table: Location data from Locations module
-- @return table: Initial game state
local function create_new_game_state(location)
    return {
        location = location.id,
        location_name = location.name,
        difficulty = location.difficulty,
        month = 1,
        season = "Spring", -- Starting in spring
        created_at = os.time(),
        last_played = os.time(),
        -- Placeholder for future game state
        resources = {},
        buildings = {},
        events = location.starting_events or {},
    }
end

function WorldMapScreen.enter(ctx)
    WorldMapScreen.last_transition = ctx
    WorldMapScreen.selected_location = nil
    WorldMapScreen.detail_panel_visible = false
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 200, 40
    
    -- Back button
    WorldMapScreen.back_button = UIButton.new("Back to Menu", 20, h - 60, btn_w, btn_h, function()
        bus.emit("new_game_location:back", { from = "new_game_location" })
    end)
    
    -- Location buttons (arranged in a grid)
    WorldMapScreen.location_buttons = {}
    local all_locations = Locations.get_all()
    local start_x = 50
    local start_y = 100
    local spacing_x = 220
    local spacing_y = 60
    local cols = 3
    
    for i, location in ipairs(all_locations) do
        local col = ((i - 1) % cols)
        local row = math.floor((i - 1) / cols)
        local x = start_x + col * spacing_x
        local y = start_y + row * spacing_y
        
        local label = location.name .. " (" .. location.difficulty .. ")"
        local btn = UIButton.new(label, x, y, btn_w, btn_h, function()
            WorldMapScreen.selected_location = location
            WorldMapScreen.detail_panel_visible = true
            log.info("world_map:location_selected", { location = location.id, name = location.name })
        end)
        table.insert(WorldMapScreen.location_buttons, btn)
    end
    
    -- Confirm button (hidden until location selected)
    WorldMapScreen.confirm_button = UIButton.new("Confirm & Start Game", (w - 250) / 2, h - 60, 250, btn_h, function()
        if WorldMapScreen.selected_location then
            -- Find empty save slot
            local slot = SaveSystem.find_empty_slot()
            if not slot then
                log.info("world_map:no_empty_slot", { note = "All 5 save slots are full" })
                -- TODO: Show error message to user
                return
            end
            
            -- Create new game state
            local game_state = create_new_game_state(WorldMapScreen.selected_location)
            
            -- Save to slot
            local saved = SaveSystem.save_game(slot, game_state)
            if saved then
                log.info("world_map:game_started", { 
                    slot = slot, 
                    location = WorldMapScreen.selected_location.id,
                    location_name = WorldMapScreen.selected_location.name
                })
                -- Navigate to game screen with save slot info
                bus.emit("world_map:start_game", { slot = slot, location = WorldMapScreen.selected_location.id })
            else
                log.info("world_map:save_failed", { slot = slot, location = WorldMapScreen.selected_location.id })
                -- TODO: Show error message to user
            end
        end
    end)
end

function WorldMapScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.12, 0.15)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Select Your Homestead Location", 0, 30, w, "center")
    
    -- Draw location buttons
    for _, btn in ipairs(WorldMapScreen.location_buttons) do
        btn:draw()
    end
    
    -- Draw detail panel if location is selected
    if WorldMapScreen.detail_panel_visible and WorldMapScreen.selected_location then
        local loc = WorldMapScreen.selected_location
        local panel_x = w - 400
        local panel_y = 80
        local panel_w = 380
        local panel_h = h - 160
        
        -- Panel background
        love.graphics.setColor(0.15, 0.17, 0.2)
        love.graphics.rectangle("fill", panel_x, panel_y, panel_w, panel_h, 8, 8)
        love.graphics.setColor(0.3, 0.35, 0.4)
        love.graphics.rectangle("line", panel_x, panel_y, panel_w, panel_h, 8, 8)
        
        -- Location name and difficulty
        love.graphics.setColor(1, 1, 1)
        local title_y = panel_y + 20
        love.graphics.printf(loc.name, panel_x + 10, title_y, panel_w - 20, "left")
        
        love.graphics.setColor(0.8, 0.8, 0.9)
        local diff_y = title_y + 25
        love.graphics.printf("Difficulty: " .. loc.difficulty, panel_x + 10, diff_y, panel_w - 20, "left")
        
        -- Description
        love.graphics.setColor(0.7, 0.75, 0.8)
        local desc_y = diff_y + 30
        love.graphics.printf(loc.description, panel_x + 10, desc_y, panel_w - 20, "left")
        
        local current_y = desc_y + 50
        
        -- Strengths
        love.graphics.setColor(0.6, 0.9, 0.6)
        love.graphics.printf("Strengths:", panel_x + 10, current_y, panel_w - 20, "left")
        current_y = current_y + 20
        love.graphics.setColor(0.7, 0.85, 0.7)
        for _, strength in ipairs(loc.strengths) do
            love.graphics.printf("• " .. strength, panel_x + 20, current_y, panel_w - 30, "left")
            current_y = current_y + 18
        end
        
        current_y = current_y + 10
        
        -- Challenges
        love.graphics.setColor(0.9, 0.6, 0.6)
        love.graphics.printf("Challenges:", panel_x + 10, current_y, panel_w - 20, "left")
        current_y = current_y + 20
        love.graphics.setColor(0.85, 0.7, 0.7)
        for _, challenge in ipairs(loc.challenges) do
            love.graphics.printf("• " .. challenge, panel_x + 20, current_y, panel_w - 30, "left")
            current_y = current_y + 18
        end
        
        current_y = current_y + 10
        
        -- Fauna
        love.graphics.setColor(0.7, 0.8, 0.9)
        love.graphics.printf("Available Fauna:", panel_x + 10, current_y, panel_w - 20, "left")
        current_y = current_y + 20
        love.graphics.setColor(0.75, 0.8, 0.85)
        local fauna_text = table.concat(loc.fauna, ", ")
        love.graphics.printf(fauna_text, panel_x + 20, current_y, panel_w - 30, "left")
        current_y = current_y + 30
        
        -- Flora
        love.graphics.setColor(0.7, 0.8, 0.9)
        love.graphics.printf("Available Flora:", panel_x + 10, current_y, panel_w - 20, "left")
        current_y = current_y + 20
        love.graphics.setColor(0.75, 0.8, 0.85)
        local flora_text = table.concat(loc.flora, ", ")
        love.graphics.printf(flora_text, panel_x + 20, current_y, panel_w - 30, "left")
        current_y = current_y + 30
        
        -- Starting Events
        if loc.starting_events and #loc.starting_events > 0 then
            love.graphics.setColor(0.9, 0.85, 0.6)
            love.graphics.printf("Starting Events:", panel_x + 10, current_y, panel_w - 20, "left")
            current_y = current_y + 20
            love.graphics.setColor(0.85, 0.8, 0.7)
            for _, event in ipairs(loc.starting_events) do
                love.graphics.printf("• " .. event, panel_x + 20, current_y, panel_w - 30, "left")
                current_y = current_y + 18
            end
        end
    end
    
    -- Draw buttons
    WorldMapScreen.back_button:draw()
    if WorldMapScreen.detail_panel_visible and WorldMapScreen.selected_location then
        WorldMapScreen.confirm_button:draw()
    end
end

function WorldMapScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check location buttons
    for _, btn in ipairs(WorldMapScreen.location_buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
    
    -- Check confirm button
    if WorldMapScreen.confirm_button and WorldMapScreen.detail_panel_visible then
        if WorldMapScreen.confirm_button:mousepressed(x, y) then
            return
        end
    end
    
    -- Check back button
    if WorldMapScreen.back_button:mousepressed(x, y) then
        return
    end
end

return WorldMapScreen
