-- Main Game Screen for Phase 2
-- Stub screen that displays the current game state (location, month, etc.)
-- Will be expanded with hex grid and gameplay in later phases

local bus = require('lib.event_bus')
local UIButton = require('lib.ui_button')
local SaveSystem = require('lib.save_system')
local Locations = require('lib.locations')
local log = require('lib.logger')
local text_utils = require('lib.text_utils')

local GameScreen = {
    buttons = {},
    game_data = nil,
    location_data = nil,
}

function GameScreen.enter(ctx)
    GameScreen.last_transition = ctx
    
    -- Load game data from context or save slot
    local slot = ctx and ctx.data and ctx.data.slot
    if slot then
        GameScreen.game_data = SaveSystem.load_game(slot)
        if GameScreen.game_data then
            GameScreen.location_data = Locations.get_by_id(GameScreen.game_data.location)
            log.info("game:entered", { 
                slot = slot, 
                location = GameScreen.game_data.location,
                month = GameScreen.game_data.month 
            })
        end
    else
        -- No game data - this shouldn't happen, but handle gracefully
        GameScreen.game_data = nil
        GameScreen.location_data = nil
    end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 220, 44
    
    GameScreen.buttons = {
        UIButton.new("Back to Menu", (w - btn_w) / 2, h - 80, btn_w, btn_h, function()
            bus.emit("game:back", { from = "game" })
        end),
    }
end

function GameScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.clear(0.1, 0.15, 0.1)
    
    if GameScreen.game_data and GameScreen.location_data then
        -- Show game info
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Your Homestead", 0, 40, w, "center")
        
        love.graphics.setColor(0.8, 0.8, 0.9)
        local info_y = 80
        love.graphics.printf(text_utils.clean("Location: " .. GameScreen.location_data.name), 0, info_y, w, "center")
        love.graphics.printf(text_utils.clean("Difficulty: " .. GameScreen.game_data.difficulty), 0, info_y + 25, w, "center")
        love.graphics.printf(text_utils.clean("Month: " .. GameScreen.game_data.month), 0, info_y + 50, w, "center")
        love.graphics.printf(text_utils.clean("Season: " .. (GameScreen.game_data.season or "Spring")), 0, info_y + 75, w, "center")
        
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.printf("(Hex grid and gameplay coming soon)", 0, info_y + 120, w, "center")
    else
        -- No game data loaded
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Screen", 0, h * 0.3, w, "center")
        
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.printf("(No game data loaded)", 0, h * 0.4, w, "center")
    end
    
    for _, btn in ipairs(GameScreen.buttons) do
        btn:draw()
    end
end

function GameScreen.mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(GameScreen.buttons) do
        if btn:mousepressed(x, y) then
            return
        end
    end
end

return GameScreen
