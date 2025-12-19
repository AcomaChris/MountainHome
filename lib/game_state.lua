-- Game state management for Mountain Home.
-- Handles action points, resources, month progression, and game state updates.

local GameState = {
    -- Default starting values
    STARTING_ACTION_POINTS = 10,
}

-- Create initial game state
-- @param location_id string: Location ID
-- @return table: Initial game state
function GameState.create_new(location_id)
    return {
        location = location_id,
        month = 1,
        season = "Spring",
        action_points = GameState.STARTING_ACTION_POINTS,
        max_action_points = GameState.STARTING_ACTION_POINTS,
        resources = {
            wood = 0,
            money = 100,  -- Starting money
            stone = 0,
            fruit = 0,
            vegetables = 0,
            meat = 0,
        },
        guests = {},  -- Array of guest data
        hex_map_data = nil,  -- Will store hex tile states
    }
end

-- Advance to next month
-- @param game_state table: Current game state
function GameState.advance_month(game_state)
    game_state.month = game_state.month + 1
    if game_state.month > 12 then
        game_state.month = 1
    end
    
    -- Update season based on month
    if game_state.month >= 3 and game_state.month <= 5 then
        game_state.season = "Spring"
    elseif game_state.month >= 6 and game_state.month <= 8 then
        game_state.season = "Summer"
    elseif game_state.month >= 9 and game_state.month <= 11 then
        game_state.season = "Fall"
    else
        game_state.season = "Winter"
    end
    
    -- Refresh action points
    game_state.action_points = game_state.max_action_points
    
    -- Process guest upkeep (feed guests, etc.)
    -- TODO: Implement guest upkeep logic
end

-- Spend action points
-- @param game_state table: Current game state
-- @param amount number: Action points to spend
-- @return boolean: True if successful, false if not enough points
function GameState.spend_action_points(game_state, amount)
    if game_state.action_points >= amount then
        game_state.action_points = game_state.action_points - amount
        return true
    end
    return false
end

-- Add resources
-- @param game_state table: Current game state
-- @param resources table: Resource changes {wood = 5, money = -10, ...}
function GameState.add_resources(game_state, resources)
    for resource, amount in pairs(resources) do
        if game_state.resources[resource] then
            game_state.resources[resource] = math.max(0, game_state.resources[resource] + amount)
        end
    end
end

return GameState

