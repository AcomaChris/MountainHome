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
        }
    },
    
    invermere = {
        id = "invermere",
        name = "Invermere",
        difficulty = "Easy",
        description = "A lakeside community with rich natural resources.",
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
        }
    },
    
    -- Medium difficulty locations
    radium_hot_springs = {
        id = "radium_hot_springs",
        name = "Radium Hot Springs",
        difficulty = "Medium",
        description = "A resort town with geothermal features and challenging terrain.",
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
        }
    },
    
    golden = {
        id = "golden",
        name = "Golden",
        difficulty = "Medium",
        description = "A historic mining town with rugged mountain surroundings.",
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
        }
    },
    
    -- Hard difficulty locations
    jasper = {
        id = "jasper",
        name = "Jasper",
        difficulty = "Hard",
        description = "A remote national park town with pristine wilderness.",
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
        }
    },
    
    kananaskis_village = {
        id = "kananaskis_village",
        name = "Kananaskis Village",
        difficulty = "Hard",
        description = "An isolated mountain community with extreme weather.",
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
        }
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

