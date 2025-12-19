-- Weather system for Mountain Home.
-- Manages weather cards with season-based probabilities.
-- Weather affects hex tile transformations and gameplay.

local Weather = {
    -- Weather types with effects
    types = {
        sunny = {
            id = "sunny",
            name = "Sunny",
            description = "Clear skies and warm weather",
            effects = {
                plant_growth_multiplier = 2.0,  -- Plants grow twice as fast
                animal_spawn_chance = 0.3,  -- 30% chance for animals to appear
                action_cost_modifier = 0,  -- No change to action costs
            },
        },
        overcast = {
            id = "overcast",
            name = "Overcast",
            description = "Cloudy skies",
            effects = {
                plant_growth_multiplier = 1.0,  -- Normal growth
                animal_spawn_chance = 0.1,  -- 10% chance for animals
                action_cost_modifier = 0,
            },
        },
        rain = {
            id = "rain",
            name = "Rain",
            description = "Light to moderate rainfall",
            effects = {
                plant_growth_multiplier = 1.0,  -- Normal growth
                animal_spawn_chance = 0.0,  -- Animals stay away
                action_cost_modifier = 0,
            },
        },
        storm = {
            id = "storm",
            name = "Storm",
            description = "Heavy rain and strong winds",
            effects = {
                plant_growth_multiplier = 0.5,  -- Slower growth due to damage
                animal_spawn_chance = 0.0,  -- No animals
                action_cost_modifier = 1,  -- Actions cost 1 more AP (dangerous conditions)
            },
        },
        snow = {
            id = "snow",
            name = "Snow",
            description = "Light snowfall",
            effects = {
                plant_growth_multiplier = 0.0,  -- No growth (dormant)
                animal_spawn_chance = 0.2,  -- Some animals still active
                action_cost_modifier = 1,  -- Actions cost 1 more AP (cold conditions)
            },
        },
        ice = {
            id = "ice",
            name = "Ice",
            description = "Freezing conditions and ice",
            effects = {
                plant_growth_multiplier = 0.0,  -- No growth
                animal_spawn_chance = 0.0,  -- No animals
                action_cost_modifier = 2,  -- Actions cost 2 more AP (very dangerous)
            },
        },
        fog = {
            id = "fog",
            name = "Fog",
            description = "Dense fog reduces visibility",
            effects = {
                plant_growth_multiplier = 0.8,  -- Slightly slower growth
                animal_spawn_chance = 0.0,  -- No animals (can't see)
                action_cost_modifier = 1,  -- Actions cost 1 more AP (reduced visibility)
            },
        },
        hail = {
            id = "hail",
            name = "Hail",
            description = "Hailstorms can damage crops",
            effects = {
                plant_growth_multiplier = 0.3,  -- Very slow growth (damage)
                animal_spawn_chance = 0.0,  -- No animals
                action_cost_modifier = 1,  -- Actions cost 1 more AP (dangerous)
            },
        },
        wind = {
            id = "wind",
            name = "Windy",
            description = "Strong winds",
            effects = {
                plant_growth_multiplier = 0.9,  -- Slightly slower growth
                animal_spawn_chance = 0.15,  -- Some animals
                action_cost_modifier = 0,  -- No change to action costs
            },
        },
    },
    
    -- Season-based weather probabilities (must sum to 1.0 per season)
    probabilities = {
        Spring = {
            sunny = 0.25,
            overcast = 0.20,
            rain = 0.25,
            storm = 0.10,
            snow = 0.05,
            ice = 0.02,
            fog = 0.08,
            hail = 0.03,
            wind = 0.02,
        },
        Summer = {
            sunny = 0.35,
            overcast = 0.15,
            rain = 0.15,
            storm = 0.15,
            snow = 0.0,
            ice = 0.0,
            fog = 0.05,
            hail = 0.10,
            wind = 0.05,
        },
        Fall = {
            sunny = 0.20,
            overcast = 0.25,
            rain = 0.20,
            storm = 0.10,
            snow = 0.05,
            ice = 0.02,
            fog = 0.15,
            hail = 0.01,
            wind = 0.02,
        },
        Winter = {
            sunny = 0.15,
            overcast = 0.15,
            rain = 0.05,
            storm = 0.05,
            snow = 0.30,
            ice = 0.15,
            fog = 0.10,
            hail = 0.03,
            wind = 0.02,
        },
    },
}

-- Get weather by ID
-- @param id string: Weather ID
-- @return table or nil: Weather data
function Weather.get(id)
    return Weather.types[id]
end

-- Draw a random weather card for a season and location
-- @param season string: Season name ("Spring", "Summer", "Fall", "Winter")
-- @param location_id string: Location ID (optional, for location-specific probabilities)
-- @return table: Weather data
function Weather.draw_for_season(season, location_id)
    local probs = Weather.probabilities[season]
    if not probs then
        -- Fallback to Spring if season not found
        probs = Weather.probabilities["Spring"]
    end
    
    -- If location has custom probabilities, use those instead
    if location_id then
        local Locations = require('lib.locations')
        local location = Locations.get_by_id(location_id)
        if location and location.weather_probabilities and location.weather_probabilities[season] then
            probs = location.weather_probabilities[season]
        end
    end
    
    -- Weighted random selection
    local roll = love.math.random()
    local cumulative = 0.0
    
    for weather_id, probability in pairs(probs) do
        cumulative = cumulative + probability
        if roll <= cumulative then
            return Weather.types[weather_id]
        end
    end
    
    -- Fallback to sunny if probabilities don't sum correctly
    return Weather.types.sunny
end

-- Get all weather types
-- @return table: Array of weather data
function Weather.get_all()
    local all = {}
    for _, weather in pairs(Weather.types) do
        table.insert(all, weather)
    end
    return all
end

return Weather

