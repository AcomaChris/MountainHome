-- Weather system for Mountain Home.
-- Manages weather cards with season-based probabilities.
-- Weather affects hex tile transformations and gameplay.

local Weather = {
    -- Weather types
    types = {
        sunny = {
            id = "sunny",
            name = "Sunny",
            description = "Clear skies and warm weather",
        },
        overcast = {
            id = "overcast",
            name = "Overcast",
            description = "Cloudy skies",
        },
        rain = {
            id = "rain",
            name = "Rain",
            description = "Light to moderate rainfall",
        },
        storm = {
            id = "storm",
            name = "Storm",
            description = "Heavy rain and strong winds",
        },
        snow = {
            id = "snow",
            name = "Snow",
            description = "Light snowfall",
        },
        ice = {
            id = "ice",
            name = "Ice",
            description = "Freezing conditions and ice",
        },
        fog = {
            id = "fog",
            name = "Fog",
            description = "Dense fog reduces visibility",
        },
        hail = {
            id = "hail",
            name = "Hail",
            description = "Hailstorms can damage crops",
        },
        wind = {
            id = "wind",
            name = "Windy",
            description = "Strong winds",
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

-- Draw a random weather card for a season
-- @param season string: Season name ("Spring", "Summer", "Fall", "Winter")
-- @return table: Weather data
function Weather.draw_for_season(season)
    local probs = Weather.probabilities[season]
    if not probs then
        -- Fallback to Spring if season not found
        probs = Weather.probabilities["Spring"]
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

