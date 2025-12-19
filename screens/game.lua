-- Main Game Screen for Phase 2
-- Hex map gameplay with action points, resources, and month progression

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')
local SaveSystem = require('lib.save_system')
local Locations = require('lib.locations')
local GameState = require('lib.game_state')
local HexTiles = require('lib.hex_tiles')
local HexMap = require('lib.hex_map')
local Maps = require('data.maps')
local Weather = require('lib.weather')
local WeatherCard = require('lib.weather_card')
local log = require('lib.logger')
local text_utils = require('lib.text_utils')

local GameScreen = {
    buttons = {},
    game_data = nil,
    location_data = nil,
    selected_hex_index = nil,
    action_menu_visible = false,
    action_menu_hex = nil,
    current_slot = nil,  -- Store current save slot
    showing_weather_card = false,  -- Weather card is visible
    weather_card_dismissed = false,  -- Weather card has been revealed and can be dismissed
}

-- Initialize hex tiles and maps (call once)
local hex_initialized = false
local function ensure_hex_initialized()
    if not hex_initialized then
        HexTiles.init_defaults()
        Maps.init_defaults()
        hex_initialized = true
    end
end

function GameScreen.enter(ctx)
    GameScreen.last_transition = ctx
    
    -- Initialize hex system
    ensure_hex_initialized()
    
    -- Load game data from context or save slot
    GameScreen.current_slot = ctx and ctx.data and ctx.data.slot
    if GameScreen.current_slot then
        GameScreen.game_data = SaveSystem.load_game(GameScreen.current_slot)
        if GameScreen.game_data then
            GameScreen.location_data = Locations.get_by_id(GameScreen.game_data.location)
            
            -- Initialize game state if needed
            if not GameScreen.game_data.resources then
                GameScreen.game_data.resources = GameState.create_new(GameScreen.game_data.location).resources
            end
            if not GameScreen.game_data.action_points then
                GameScreen.game_data.action_points = GameState.STARTING_ACTION_POINTS
                GameScreen.game_data.max_action_points = GameState.STARTING_ACTION_POINTS
            end
            
            log.info("game:entered", { 
                slot = GameScreen.current_slot, 
                location = GameScreen.game_data.location,
                month = GameScreen.game_data.month 
            })
        end
    else
        GameScreen.game_data = nil
        GameScreen.location_data = nil
    end
    
    GameScreen.selected_hex_index = nil
    GameScreen.action_menu_visible = false
    GameScreen.showing_weather_card = false
    GameScreen.weather_card_dismissed = false
    WeatherCard.hide()
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Load hex map after we have screen dimensions
    if GameScreen.game_data then
        local map_data = nil
        if GameScreen.game_data.hex_map_data then
            map_data = GameScreen.game_data.hex_map_data
        else
            map_data = Maps.get(GameScreen.game_data.location)
            -- Save initial map data
            GameScreen.game_data.hex_map_data = map_data
        end
        
        -- Calculate top margin (timeline + info panel)
        local top_margin = 60 + 50  -- Timeline height + info panel height
        
        if map_data then
            HexMap.create_from_data(map_data, w, h, top_margin)
        else
            -- Fallback: create empty map
            HexMap.create_from_data({}, w, h, top_margin)
        end
    end
    local btn_w, btn_h = 220, 44
    
    GameScreen.buttons = {
        UIButton.new("Next Month", w - btn_w - 20, h - 60, btn_w, btn_h, function()
            if GameScreen.game_data and not GameScreen.showing_weather_card then
                -- Draw weather card for new month
                local season = GameScreen.game_data.season or "Spring"
                local weather = Weather.draw_for_season(season)
                
                -- Store weather in game state
                GameScreen.game_data.current_weather = weather.id
                GameScreen.game_data.weather_name = weather.name
                
                -- Show weather card
                WeatherCard.show(weather, w, h)
                GameScreen.showing_weather_card = true
                GameScreen.weather_card_dismissed = false
                
                log.info("game:weather_drawn", { season = season, weather = weather.id, month = GameScreen.game_data.month })
            elseif GameScreen.showing_weather_card and GameScreen.weather_card_dismissed then
                -- Weather card is revealed and dismissed - advance month
                GameState.advance_month(GameScreen.game_data)
                WeatherCard.hide()
                GameScreen.showing_weather_card = false
                GameScreen.weather_card_dismissed = false
                
                -- Save game after month advance
                if GameScreen.current_slot then
                    SaveSystem.save_game(GameScreen.current_slot, GameScreen.game_data)
                end
                log.info("game:month_advanced", { month = GameScreen.game_data.month })
            end
        end),
        UIButton.new("Back to Menu", 20, h - 60, btn_w, btn_h, function()
            -- Save game before leaving
            if GameScreen.current_slot and GameScreen.game_data then
                SaveSystem.save_game(GameScreen.current_slot, GameScreen.game_data)
            end
            bus.emit("game:back", { from = "game" })
        end),
    }
end

function GameScreen.update(dt)
    if not GameScreen.game_data then return end
    
    -- Update weather card animation
    if GameScreen.showing_weather_card then
        WeatherCard.update(dt)
    end
    
    -- Update hex map hover (only if weather card not showing)
    if not GameScreen.showing_weather_card then
        local mx, my = love.mouse.getPosition()
        HexMap.update_hover(mx, my)
    end
end

function GameScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.15, 0.1)
    
    if not GameScreen.game_data or not GameScreen.location_data then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Screen", 0, h * 0.3, w, "center")
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.printf("(No game data loaded)", 0, h * 0.4, w, "center")
        return
    end
    
    -- Draw month timeline at top
    local timeline_y = 10
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", 0, timeline_y, w, 50)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", 0, timeline_y, w, 50)
    
    love.graphics.setColor(1, 1, 1)
    local month_names = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
    local month_width = w / 12
    for i = 1, 12 do
        local x = (i - 1) * month_width + month_width / 2
        local color = (i == GameScreen.game_data.month) and {1, 1, 0.5} or {0.7, 0.7, 0.7}
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.printf(month_names[i], x - 20, timeline_y + 15, 40, "center")
    end
    
    -- Draw action points and resources
    local info_x = 10
    local info_y = timeline_y + 60
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Action Points: " .. GameScreen.game_data.action_points .. "/" .. GameScreen.game_data.max_action_points, info_x, info_y, 300, "left")
    
    local resource_y = info_y + 25
    love.graphics.setColor(0.8, 0.8, 0.9)
    local resource_text = string.format("Wood: %d | Money: %d | Stone: %d | Fruit: %d | Veg: %d | Meat: %d",
        GameScreen.game_data.resources.wood or 0,
        GameScreen.game_data.resources.money or 0,
        GameScreen.game_data.resources.stone or 0,
        GameScreen.game_data.resources.fruit or 0,
        GameScreen.game_data.resources.vegetables or 0,
        GameScreen.game_data.resources.meat or 0
    )
    love.graphics.printf(text_utils.clean(resource_text), info_x, resource_y, w - 20, "left")
    
    -- Draw weather card overlay if showing
    if GameScreen.showing_weather_card then
        -- Darken background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        -- Draw weather card
        WeatherCard.draw()
        
        -- Draw dismiss instruction if revealed
        if WeatherCard.revealed and WeatherCard.flip_progress >= 1.0 then
            GameScreen.weather_card_dismissed = true
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.printf("Click 'Next Month' to continue", 0, h - 100, w, "center")
        end
    end
    
    -- Draw hex map (only if weather card not showing)
    if not GameScreen.showing_weather_card then
        local hover_animation_time = love.timer.getTime() * 2
        for i, hex in ipairs(HexMap.hexes) do
        local tile = HexTiles.get(hex.tile_id)
        if not tile then
            tile = HexTiles.get("blank")
        end
        
        local sprite = HexTiles.get_sprite(hex.tile_id) or HexTiles.get_sprite("blank")
        local quad = HexTiles.get_quad(hex.tile_id)
        
        if sprite then
            local scale = 1.0
            local draw_y = hex.y
            
            -- Hover animation
            if i == HexMap.hovered_hex_index then
                local progress = (math.sin(hover_animation_time) + 1) / 2
                draw_y = hex.y - (progress * 10)
                scale = 1.0 + (progress * 0.1)
            end
            
            -- Selected highlight
            if i == GameScreen.selected_hex_index then
                love.graphics.setColor(1, 1, 0.5, 0.3)
                love.graphics.circle("fill", hex.x, hex.y, HexMap.SPRITE_WIDTH / 2)
            end
            
            love.graphics.setColor(1, 1, 1)
            if quad then
                love.graphics.draw(sprite, quad, hex.x, hex.y, 0, scale, scale, HexTiles.SPRITE_WIDTH / 2, HexTiles.SPRITE_HEIGHT / 2)
            else
                love.graphics.draw(sprite, hex.x, hex.y, 0, scale, scale, HexTiles.SPRITE_WIDTH / 2, HexTiles.SPRITE_HEIGHT / 2)
            end
        end
    end
    
    -- Draw action menu if hex is selected (only if weather card not showing)
    if GameScreen.action_menu_visible and GameScreen.action_menu_hex then
        local hex = HexMap.get_hex(GameScreen.action_menu_hex)
        if hex then
            local tile = HexTiles.get(hex.tile_id)
            if tile and #tile.actions > 0 then
                local menu_x = hex.x + 80
                local menu_y = hex.y - 40
                local menu_w = 200
                local menu_h = #tile.actions * 40 + 30
                
                -- Menu background
                love.graphics.setColor(0.15, 0.17, 0.2)
                love.graphics.rectangle("fill", menu_x, menu_y, menu_w, menu_h, 6, 6)
                love.graphics.setColor(0.3, 0.35, 0.4)
                love.graphics.rectangle("line", menu_x, menu_y, menu_w, menu_h, 6, 6)
                
                -- Menu title
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(tile.name, menu_x + 10, menu_y + 10, menu_w - 20, "left")
                
                -- Action buttons (simplified - just show actions)
                -- Store action menu position for click detection
                GameScreen.action_menu_pos = {x = menu_x, y = menu_y, w = menu_w, h = menu_h}
                for i, action in ipairs(tile.actions) do
                    local action_y = menu_y + 35 + (i - 1) * 35
                    local can_afford = GameScreen.game_data.action_points >= action.cost
                    local color = can_afford and {0.7, 0.9, 0.7} or {0.5, 0.5, 0.5}
                    love.graphics.setColor(color[1], color[2], color[3])
                    local action_text = action.name .. " (" .. action.cost .. " AP)"
                    love.graphics.printf(action_text, menu_x + 10, action_y, menu_w - 20, "left")
                end
            end
        end
    end
    end  -- Close "if not GameScreen.showing_weather_card" for hex map drawing
    
    -- Draw buttons (disable "Next Month" button if weather card is showing but not dismissed)
    for i, btn in ipairs(GameScreen.buttons) do
        if i == 1 and GameScreen.showing_weather_card and not GameScreen.weather_card_dismissed then
            -- Dim the button when weather card is showing
            local old_bg = btn.bg
            local old_fg = btn.fg
            btn.bg = {old_bg[1] * 0.5, old_bg[2] * 0.5, old_bg[3] * 0.5}
            btn.fg = {old_fg[1] * 0.5, old_fg[2] * 0.5, old_fg[3] * 0.5}
            btn:draw()
            btn.bg = old_bg
            btn.fg = old_fg
        else
            btn:draw()
        end
    end
end

function GameScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check weather card click first
    if GameScreen.showing_weather_card and not WeatherCard.revealed then
        if WeatherCard.contains(x, y) then
            WeatherCard.reveal()
            log.info("game:weather_revealed", { weather = WeatherCard.weather and WeatherCard.weather.id })
            return
        end
    end
    
    -- Check buttons first (but disable "Next Month" if weather card showing and not dismissed)
    for i, btn in ipairs(GameScreen.buttons) do
        if i == 1 and GameScreen.showing_weather_card and not GameScreen.weather_card_dismissed then
            -- Button is disabled - don't process click
        else
            if btn:mousepressed(x, y) then
                return
            end
        end
    end
    
    -- Don't process hex clicks if weather card is showing
    if GameScreen.showing_weather_card then
        return
    end
    
    -- Check action menu clicks first
    if GameScreen.action_menu_visible and GameScreen.action_menu_pos then
        local menu = GameScreen.action_menu_pos
        if x >= menu.x and x <= menu.x + menu.w and y >= menu.y and y <= menu.y + menu.h then
            local hex = HexMap.get_hex(GameScreen.action_menu_hex)
            if hex then
                local tile = HexTiles.get(hex.tile_id)
                if tile then
                    -- Calculate which action was clicked
                    local action_index = math.floor((y - menu.y - 35) / 35) + 1
                    if action_index >= 1 and action_index <= #tile.actions then
                        local action = tile.actions[action_index]
                        -- Check if player can afford
                        if GameState.spend_action_points(GameScreen.game_data, action.cost) then
                            -- Execute action
                            if action.result_tile then
                                HexMap.set_tile(GameScreen.action_menu_hex, action.result_tile)
                                -- Update saved map data
                                local hex = HexMap.get_hex(GameScreen.action_menu_hex)
                                if hex and GameScreen.game_data.hex_map_data then
                                    for _, map_hex in ipairs(GameScreen.game_data.hex_map_data) do
                                        if map_hex.q == hex.q and map_hex.r == hex.r then
                                            map_hex.tile_id = action.result_tile
                                            break
                                        end
                                    end
                                end
                            end
                            if action.resources then
                                GameState.add_resources(GameScreen.game_data, action.resources)
                            end
                            -- Save game
                            if GameScreen.current_slot then
                                SaveSystem.save_game(GameScreen.current_slot, GameScreen.game_data)
                            end
                            log.info("game:action_executed", { action = action.name, tile_id = hex.tile_id })
                            -- Close menu
                            GameScreen.action_menu_visible = false
                            GameScreen.selected_hex_index = nil
                        end
                    end
                end
            end
            return
        end
    end
    
    -- Check hex clicks
    local hovered = HexMap.find_hovered_hex(x, y)
    if hovered then
        local hex = HexMap.get_hex(hovered)
        if hex then
            GameScreen.selected_hex_index = hovered
            GameScreen.action_menu_hex = hovered
            local tile = HexTiles.get(hex.tile_id)
            GameScreen.action_menu_visible = (tile and #tile.actions > 0)
            log.info("game:hex_selected", { hex_index = hovered, tile_id = hex.tile_id })
        end
    else
        -- Click outside - close menu
        GameScreen.action_menu_visible = false
        GameScreen.selected_hex_index = nil
    end
end

return GameScreen
