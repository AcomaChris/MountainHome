-- Save/Load system for Mountain Home game.
-- Manages 5 save slots stored as JSON files in Love2D's save directory.
-- Each save slot contains game state including location, progress, and metadata.
-- Example:
--   local save = require('lib.save_system')
--   local slot = save.find_empty_slot()
--   save.save_game(slot, game_data)
--   local data = save.load_game(1)

local json = require('lunajson')
local log = require('lib.logger')

local SaveSystem = {
    SAVE_DIR = "saved/games",
    MAX_SLOTS = 5,
}

-- Ensure save directory exists
local function ensure_save_dir()
    love.filesystem.createDirectory(SaveSystem.SAVE_DIR)
end

-- Get file path for a save slot
-- @param slot number: Slot number (1-5)
-- @return string: File path
local function get_slot_path(slot)
    assert(slot >= 1 and slot <= SaveSystem.MAX_SLOTS, "slot must be 1-5")
    return SaveSystem.SAVE_DIR .. "/slot_" .. slot .. ".json"
end

-- Check if a save slot exists and has valid data
-- @param slot number: Slot number (1-5)
-- @return boolean: True if slot has a valid save
function SaveSystem.slot_exists(slot)
    local path = get_slot_path(slot)
    return love.filesystem.getInfo(path) ~= nil
end

-- Get metadata for a save slot without loading full game data
-- @param slot number: Slot number (1-5)
-- @return table or nil: Metadata { location, difficulty, month, created_at, last_played } or nil if empty
function SaveSystem.get_slot_metadata(slot)
    if not SaveSystem.slot_exists(slot) then
        return nil
    end
    
    local path = get_slot_path(slot)
    local contents = love.filesystem.read(path)
    if not contents then
        return nil
    end
    
    local ok, data = pcall(json.decode, contents)
    if not ok or not data then
        return nil
    end
    
    -- Return just the metadata fields
    return {
        location = data.location,
        location_name = data.location_name,
        difficulty = data.difficulty,
        month = data.month or 1,
        created_at = data.created_at,
        last_played = data.last_played,
    }
end

-- Find the first empty save slot
-- @return number or nil: Slot number (1-5) or nil if all slots are full
function SaveSystem.find_empty_slot()
    for slot = 1, SaveSystem.MAX_SLOTS do
        if not SaveSystem.slot_exists(slot) then
            return slot
        end
    end
    return nil
end

-- Save game data to a slot
-- @param slot number: Slot number (1-5)
-- @param game_data table: Complete game state to save
-- @return boolean: True if save succeeded
function SaveSystem.save_game(slot, game_data)
    assert(slot >= 1 and slot <= SaveSystem.MAX_SLOTS, "slot must be 1-5")
    assert(type(game_data) == "table", "game_data must be a table")
    
    ensure_save_dir()
    
    -- Add/update metadata timestamps
    if not game_data.created_at then
        game_data.created_at = os.time()
    end
    game_data.last_played = os.time()
    
    local path = get_slot_path(slot)
    local json_data = json.encode(game_data)
    
    local ok = love.filesystem.write(path, json_data)
    if ok then
        log.info("save:game_saved", { 
            slot = slot, 
            location = game_data.location,
            difficulty = game_data.difficulty 
        })
    else
        log.info("save:game_save_failed", { slot = slot, path = path })
    end
    
    return ok
end

-- Load game data from a slot
-- @param slot number: Slot number (1-5)
-- @return table or nil: Game data or nil if slot is empty/invalid
function SaveSystem.load_game(slot)
    assert(slot >= 1 and slot <= SaveSystem.MAX_SLOTS, "slot must be 1-5")
    
    if not SaveSystem.slot_exists(slot) then
        return nil
    end
    
    local path = get_slot_path(slot)
    local contents = love.filesystem.read(path)
    if not contents then
        log.info("save:game_load_failed", { slot = slot, reason = "file_read_failed" })
        return nil
    end
    
    local ok, data = pcall(json.decode, contents)
    if not ok or not data then
        log.info("save:game_load_failed", { slot = slot, reason = "json_decode_failed", error = tostring(data) })
        return nil
    end
    
    -- Update last_played timestamp
    data.last_played = os.time()
    SaveSystem.save_game(slot, data)
    
    log.info("save:game_loaded", { slot = slot, location = data.location })
    return data
end

-- Delete a save slot
-- @param slot number: Slot number (1-5)
-- @return boolean: True if deletion succeeded
function SaveSystem.delete_slot(slot)
    assert(slot >= 1 and slot <= SaveSystem.MAX_SLOTS, "slot must be 1-5")
    
    local path = get_slot_path(slot)
    local info = love.filesystem.getInfo(path)
    if not info then
        return true -- Already doesn't exist
    end
    
    local ok = love.filesystem.remove(path)
    if ok then
        log.info("save:slot_deleted", { slot = slot })
    else
        log.info("save:slot_delete_failed", { slot = slot })
    end
    
    return ok
end

-- Get list of all save slots with their metadata
-- @return table: Array of { slot, metadata } for each non-empty slot
function SaveSystem.list_saves()
    local saves = {}
    for slot = 1, SaveSystem.MAX_SLOTS do
        local metadata = SaveSystem.get_slot_metadata(slot)
        if metadata then
            table.insert(saves, { slot = slot, metadata = metadata })
        end
    end
    return saves
end

return SaveSystem

