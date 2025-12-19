-- Text utility functions for user-facing strings.
-- Removes characters that aren't supported by the game font (like semicolons and periods).

local TextUtils = {}

-- Remove semicolons from a string (font doesn't support them)
-- @param text string: Text to clean
-- @return string: Text with semicolons removed
function TextUtils.remove_semicolons(text)
    if type(text) ~= "string" then
        return text
    end
    return text:gsub(";", "")
end

-- Remove periods from a string (font doesn't support them)
-- @param text string: Text to clean
-- @return string: Text with periods removed
function TextUtils.remove_periods(text)
    if type(text) ~= "string" then
        return text
    end
    return text:gsub("%.", "")
end

-- Clean text for display (removes unsupported characters)
-- @param text string: Text to clean
-- @return string: Cleaned text
function TextUtils.clean(text)
    text = TextUtils.remove_semicolons(text)
    text = TextUtils.remove_periods(text)
    return text
end

return TextUtils

