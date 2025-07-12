-- OBS Countdown Timer Script
-- Features:
-- 1. Displays a countdown timer on a specified text source.
-- 2. Blinks the text during the last 10 seconds.
-- 3. Gradually changes the text color to red as it approaches 0.
-- 4. Fully red when timer reaches 0.

obs           = obslua
local bit = require("bit")  -- Import bit library for bitwise operations
source_name   = ""
duration      = 60      -- Countdown duration in seconds (default: 60)
end_text      = "TIME'S UP!"
timer_active  = false
end_time      = 0
blink_state   = true
timer_finished = false
last_blink_time = 0
blink_interval = 0.2 -- seconds (was 1.0, now a bit faster)
debug = true

-- Helper: Linear interpolation
function lerp(a, b, t)
    return a + (b - a) * t
end

-- Helper: Convert RGB to OBS color integer
function rgb_to_obs_color(r, g, b)
    return bit.bor(bit.lshift(b, 16), bit.lshift(g, 8), r)
end

-- Called every frame (~60 times per second)
function script_tick(seconds)
    if debug then obs.script_log(obs.LOG_INFO, "script_tick called, timer_active=" .. tostring(timer_active)) end
    if not timer_active and not timer_finished then return end

    local now = os.time()
    local time_left = math.max(0, math.floor(end_time - os.time()))
    local text = ""
    local color = 0xFFFFFF -- Default: white

    -- Format time as HH:MM:SS
    local hours = math.floor(time_left / 3600)
    local mins = math.floor((time_left % 3600) / 60)
    local secs = time_left % 60
    text = string.format("%02d:%02d:%02d", hours, mins, secs)

    -- Blinking and color logic for last 10 seconds
    if time_left <= 10 and not timer_finished then
        if now - last_blink_time >= blink_interval then
            blink_state = not blink_state
            last_blink_time = now
        end
        -- Gradually change color to red
        local t = (10 - time_left) / 10 -- 0 at 10s, 1 at 0s
        local r = 255
        local g = math.floor(lerp(255, 0, t))
        local b = math.floor(lerp(255, 0, t))
        if blink_state then
            color = rgb_to_obs_color(r, g, b)
        else
            color = rgb_to_obs_color(100, 0, 0) -- Dim red for blink
        end
    end

    -- When timer reaches 0, start blinking end text
    if time_left == 0 then
        timer_active = false
        timer_finished = true
    end

    if timer_finished and time_left == 0 then
        if now - last_blink_time >= blink_interval then
            blink_state = not blink_state
            last_blink_time = now
        end
        text = end_text
        if blink_state then
            color = rgb_to_obs_color(255, 0, 0) -- Bright red
        else
            color = rgb_to_obs_color(100, 0, 0) -- Dim red for blink
        end
    end

    -- Update the text source
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", text)
        obs.obs_data_set_int(settings, "color", color)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

-- Start the timer
function start_timer(props, prop)
    if debug then obs.script_log(obs.LOG_INFO, "Start timer called") end
    if source_name == "" then
        obs.script_log(obs.LOG_WARNING, "No source selected!")
        return
    end
    end_time = os.time() + duration * 60
    timer_active = true
    blink_state = true
    last_blink_time = os.time()  -- Set to current time in seconds
    timer_finished = false
end

-- Stop the timer
function stop_timer(props, prop)
    timer_active = false
end

-- Script properties (UI in OBS)
function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "source_name", "Text Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_int(props, "duration", "Countdown Duration (minutes)", 1, 3600, 1)
    obs.obs_properties_add_text(props, "end_text", "End Text", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_button(props, "start_button", "Start Timer", start_timer)
    obs.obs_properties_add_button(props, "stop_button", "Stop Timer", stop_timer)
    return props
end

-- Script defaults
function script_defaults(settings)
    obs.obs_data_set_default_int(settings, "duration", 1)
    obs.obs_data_set_default_string(settings, "end_text", "TIME'S UP!")
end

-- Script update (when properties change)
function script_update(settings)
    source_name = obs.obs_data_get_string(settings, "source_name")
    duration    = obs.obs_data_get_int(settings, "duration")
    end_text    = obs.obs_data_get_string(settings, "end_text")
end

-- Script description
function script_description()
    return [[
Countdown Timer with Blinking and Color Fade

- Displays a countdown on a text source.
- Blinks in the last 10 seconds.
- Gradually turns red as it approaches 0.
- Fully red and shows end text at 0.

Set the text source and duration in the script properties.
]]
end 