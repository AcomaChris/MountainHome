-- Location definitions for Mountain Home world map.
-- Each location has difficulty, fauna, flora, and special starting events.
-- Used by the world map screen to display location information.

local Locations = {
    -- Easy difficulty locations
    revelstoke = {
        id = "revelstoke",
        name = "Revelstoke",
        difficulty = "Easy",
        description = "A welcoming mountain town with established infrastructure.",
        starting_weather = "sunny",  -- Starting weather condition
        strengths = {
            "Well-maintained roads and services",
            "Active community support",
            "Moderate climate year-round"
        },
        challenges = {
            "Higher land costs",
            "More competition for resources"
        },
        fauna = {
            "Deer",
            "Elk",
            "Black Bear",
            "Moose"
        },
        flora = {
            "Wild Berries",
            "Pine Trees",
            "Wildflowers",
            "Mushrooms"
        },
        starting_events = {
            "Farmers Market - Extra resources available in first month"
        },
        -- Location-specific weather probabilities (overrides season defaults)
        weather_probabilities = {
            Spring = {
                sunny = 0.30,
                overcast = 0.20,
                rain = 0.25,
                storm = 0.08,
                snow = 0.05,
                ice = 0.02,
                fog = 0.05,
                hail = 0.03,
                wind = 0.02,
            },
            Summer = {
                sunny = 0.40,
                overcast = 0.15,
                rain = 0.15,
                storm = 0.12,
                snow = 0.0,
                ice = 0.0,
                fog = 0.03,
                hail = 0.10,
                wind = 0.05,
            },
            Fall = {
                sunny = 0.25,
                overcast = 0.25,
                rain = 0.20,
                storm = 0.08,
                snow = 0.05,
                ice = 0.02,
                fog = 0.12,
                hail = 0.01,
                wind = 0.02,
            },
            Winter = {
                sunny = 0.20,
                overcast = 0.15,
                rain = 0.03,
                storm = 0.03,
                snow = 0.35,
                ice = 0.12,
                fog = 0.08,
                hail = 0.02,
                wind = 0.02,
            },
        },
    },
    
    invermere = {
        id = "invermere",
        name = "Invermere",
        difficulty = "Easy",
        description = "A lakeside community with rich natural resources.",
        starting_weather = "sunny",
        strengths = {
            "Abundant water sources",
            "Fertile soil",
            "Tourist economy provides opportunities"
        },
        challenges = {
            "Seasonal population fluctuations",
            "Limited winter access"
        },
        fauna = {
            "Deer",
            "Elk",
            "Waterfowl",
            "Fish"
        },
        flora = {
            "Wild Berries",
            "Aspen Trees",
            "Wildflowers",
            "Aquatic Plants"
        },
        starting_events = {
            "Great Summer Weather - Extended growing season bonus"
        },
        weather_probabilities = {
            Spring = {
                sunny = 0.35,
                overcast = 0.15,
                rain = 0.20,
                storm = 0.08,
                snow = 0.05,
                ice = 0.02,
                fog = 0.10,
                hail = 0.03,
                wind = 0.02,
            },
            Summer = {
                sunny = 0.45,
                overcast = 0.12,
                rain = 0.12,
                storm = 0.12,
                snow = 0.0,
                ice = 0.0,
                fog = 0.04,
                hail = 0.10,
                wind = 0.05,
            },
            Fall = {
                sunny = 0.30,
                overcast = 0.20,
                rain = 0.18,
                storm = 0.08,
                snow = 0.05,
                ice = 0.02,
                fog = 0.15,
                hail = 0.01,
                wind = 0.01,
            },
            Winter = {
                sunny = 0.18,
                overcast = 0.12,
                rain = 0.02,
                storm = 0.02,
                snow = 0.40,
                ice = 0.15,
                fog = 0.08,
                hail = 0.02,
                wind = 0.01,
            },
        },
    },
    
    -- Medium difficulty locations
    radium_hot_springs = {
        id = "radium_hot_springs",
        name = "Radium Hot Springs",
        difficulty = "Medium",
        description = "A resort town with geothermal features and challenging terrain.",
        starting_weather = "overcast",
        strengths = {
            "Geothermal heating potential",
            "Tourist infrastructure",
            "Unique natural features"
        },
        challenges = {
            "Steep terrain limits building",
            "Wildlife encounters more common",
            "Harsh winters"
        },
        fauna = {
            "Elk",
            "Mountain Goat",
            "Black Bear",
            "Coyote"
        },
        flora = {
            "Coniferous Trees",
            "Wild Berries",
            "Mountain Flowers",
            "Lichens"
        },
        starting_events = {
            "Winter Workforce - Extra help available during first winter"
        },
        weather_probabilities = {
            Spring = {
                sunny = 0.20,
                overcast = 0.25,
                rain = 0.20,
                storm = 0.12,
                snow = 0.08,
                ice = 0.03,
                fog = 0.08,
                hail = 0.02,
                wind = 0.02,
            },
            Summer = {
                sunny = 0.30,
                overcast = 0.18,
                rain = 0.15,
                storm = 0.18,
                snow = 0.0,
                ice = 0.0,
                fog = 0.06,
                hail = 0.10,
                wind = 0.03,
            },
            Fall = {
                sunny = 0.15,
                overcast = 0.28,
                rain = 0.22,
                storm = 0.12,
                snow = 0.08,
                ice = 0.03,
                fog = 0.10,
                hail = 0.01,
                wind = 0.01,
            },
            Winter = {
                sunny = 0.10,
                overcast = 0.18,
                rain = 0.05,
                storm = 0.08,
                snow = 0.35,
                ice = 0.18,
                fog = 0.05,
                hail = 0.01,
                wind = 0.00,
            },
        },
    },
    
    golden = {
        id = "golden",
        name = "Golden",
        difficulty = "Medium",
        description = "A historic mining town with rugged mountain surroundings.",
        starting_weather = "rain",
        strengths = {
            "Established trade routes",
            "Mining heritage provides tools",
            "Strong community bonds"
        },
        challenges = {
            "Rocky soil limits farming",
            "Avalanche risk in winter",
            "Limited flat land"
        },
        fauna = {
            "Elk",
            "Mountain Goat",
            "Black Bear",
            "Wolverine"
        },
        flora = {
            "Coniferous Trees",
            "Wild Berries",
            "Mountain Herbs",
            "Mosses"
        },
        starting_events = {
            "Farmers Market - Extra resources available in first month"
        },
        weather_probabilities = {
            Spring = {
                sunny = 0.18,
                overcast = 0.22,
                rain = 0.25,
                storm = 0.15,
                snow = 0.08,
                ice = 0.04,
                fog = 0.05,
                hail = 0.02,
                wind = 0.01,
            },
            Summer = {
                sunny = 0.25,
                overcast = 0.20,
                rain = 0.18,
                storm = 0.20,
                snow = 0.0,
                ice = 0.0,
                fog = 0.05,
                hail = 0.10,
                wind = 0.02,
            },
            Fall = {
                sunny = 0.12,
                overcast = 0.30,
                rain = 0.25,
                storm = 0.15,
                snow = 0.10,
                ice = 0.05,
                fog = 0.08,
                hail = 0.02,
                wind = 0.03,
            },
            Winter = {
                sunny = 0.08,
                overcast = 0.20,
                rain = 0.08,
                storm = 0.12,
                snow = 0.35,
                ice = 0.12,
                fog = 0.04,
                hail = 0.01,
                wind = 0.00,
            },
        },
    },
    
    -- Hard difficulty locations
    jasper = {
        id = "jasper",
        name = "Jasper",
        difficulty = "Hard",
        description = "A remote national park town with pristine wilderness.",
        starting_weather = "snow",
        strengths = {
            "Abundant wildlife",
            "Protected natural resources",
            "Tourism opportunities"
        },
        challenges = {
            "Strict building regulations",
            "Long, harsh winters",
            "Limited infrastructure",
            "Predator encounters"
        },
        fauna = {
            "Elk",
            "Moose",
            "Grizzly Bear",
            "Wolf",
            "Mountain Goat"
        },
        flora = {
            "Coniferous Trees",
            "Wild Berries",
            "Alpine Flowers",
            "Mountain Herbs"
        },
        starting_events = {
            "Great Summer Weather - Extended growing season bonus"
        },
        weather_probabilities = {
            Spring = {
                sunny = 0.15,
                overcast = 0.20,
                rain = 0.18,
                storm = 0.10,
                snow = 0.15,
                ice = 0.08,
                fog = 0.10,
                hail = 0.02,
                wind = 0.02,
            },
            Summer = {
                sunny = 0.25,
                overcast = 0.20,
                rain = 0.15,
                storm = 0.15,
                snow = 0.05,
                ice = 0.02,
                fog = 0.08,
                hail = 0.08,
                wind = 0.02,
            },
            Fall = {
                sunny = 0.10,
                overcast = 0.25,
                rain = 0.20,
                storm = 0.12,
                snow = 0.15,
                ice = 0.08,
                fog = 0.08,
                hail = 0.01,
                wind = 0.01,
            },
            Winter = {
                sunny = 0.05,
                overcast = 0.15,
                rain = 0.02,
                storm = 0.05,
                snow = 0.45,
                ice = 0.20,
                fog = 0.05,
                hail = 0.02,
                wind = 0.01,
            },
        },
    },
    
    kananaskis_village = {
        id = "kananaskis_village",
        name = "Kananaskis Village",
        difficulty = "Hard",
        description = "An isolated mountain community with extreme weather.",
        starting_weather = "ice",
        strengths = {
            "Secluded location",
            "Rich mineral deposits",
            "Untouched wilderness"
        },
        challenges = {
            "Extreme winter conditions",
            "Very limited access roads",
            "High elevation affects crops",
            "Dangerous wildlife"
        },
        fauna = {
            "Elk",
            "Moose",
            "Grizzly Bear",
            "Wolf",
            "Cougar"
        },
        flora = {
            "Coniferous Trees",
            "Wild Berries",
            "Alpine Flowers",
            "Hardy Mountain Plants"
        },
        starting_events = {
            "Winter Workforce - Extra help available during first winter"
        },
        weather_probabilities = {
            Spring = {
                sunny = 0.12,
                overcast = 0.18,
                rain = 0.15,
                storm = 0.12,
                snow = 0.20,
                ice = 0.12,
                fog = 0.08,
                hail = 0.02,
                wind = 0.01,
            },
            Summer = {
                sunny = 0.20,
                overcast = 0.22,
                rain = 0.15,
                storm = 0.18,
                snow = 0.08,
                ice = 0.05,
                fog = 0.08,
                hail = 0.03,
                wind = 0.01,
            },
            Fall = {
                sunny = 0.08,
                overcast = 0.22,
                rain = 0.18,
                storm = 0.15,
                snow = 0.20,
                ice = 0.10,
                fog = 0.05,
                hail = 0.01,
                wind = 0.01,
            },
            Winter = {
                sunny = 0.03,
                overcast = 0.12,
                rain = 0.01,
                storm = 0.08,
                snow = 0.50,
                ice = 0.22,
                fog = 0.03,
                hail = 0.01,
                wind = 0.00,
            },
        },
    },
}

-- Get all locations as an array
-- @return table: Array of location data
function Locations.get_all()
    local locations = {}
    for _, location in pairs(Locations) do
        if type(location) == "table" and location.id then
            table.insert(locations, location)
        end
    end
    return locations
end

-- Get a location by ID
-- @param id string: Location ID (e.g., "revelstoke")
-- @return table or nil: Location data or nil if not found
function Locations.get_by_id(id)
    for _, location in pairs(Locations) do
        if type(location) == "table" and location.id == id then
            return location
        end
    end
    return nil
end

-- Get locations by difficulty
-- @param difficulty string: "Easy", "Medium", or "Hard"
-- @return table: Array of locations with matching difficulty
function Locations.get_by_difficulty(difficulty)
    local filtered = {}
    for _, location in pairs(Locations) do
        if type(location) == "table" and location.id and location.difficulty == difficulty then
            table.insert(filtered, location)
        end
    end
    return filtered
end

return Locations

