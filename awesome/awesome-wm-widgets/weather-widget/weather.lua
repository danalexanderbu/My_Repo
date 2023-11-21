-------------------------------------------------
-- Weather Widget based on the OpenWeatherMap
-- https://openweathermap.org/
--
-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------
local awful = require("awful")
local watch = require("awful.widget.watch")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. '/.config/awesome/awesome-wm-widgets/weather-widget'
local CALL_API_CMD = [[bash -c "curl -s --show-error -X GET '%s'"]]

local SYS_LANG = os.getenv("LANG"):sub(1, 2)
if SYS_LANG == "C" or SYS_LANG == "C." then
    -- C-locale is a common fallback for simple English
    SYS_LANG = "en"
end
-- default language is ENglish
local LANG = gears.filesystem.file_readable(WIDGET_DIR .. "/" .. "locale/" ..
                                      SYS_LANG .. ".lua") and SYS_LANG or "en"
local LCLE = require("awesome-wm-widgets.weather-widget.locale." .. LANG)


local function show_warning(message)
    naughty.notify {
        preset = naughty.config.presets.critical,
        title = LCLE.warning_title,
        text = message
    }
end

if SYS_LANG ~= LANG then
    show_warning("Your language is not supported yet. Language set to English")
end

local weather_widget = {}
local warning_shown = false
local tooltip = awful.tooltip {
    mode = 'outside',
    preferred_positions = {'bottom'}
}

local weather_popup = awful.popup {
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = {y = 5},
    hide_on_right_click = true,
    widget = {}
}

--- Maps openWeatherMap icon name to file name w/o extension
local icon_map = {
    ["01d"] = "clear-sky",
    ["02d"] = "few-clouds",
    ["03d"] = "scattered-clouds",
    ["04d"] = "broken-clouds",
    ["09d"] = "shower-rain",
    ["10d"] = "rain",
    ["11d"] = "thunderstorm",
    ["13d"] = "snow",
    ["50d"] = "mist",
    ["01n"] = "clear-sky-night",
    ["02n"] = "few-clouds-night",
    ["03n"] = "scattered-clouds-night",
    ["04n"] = "broken-clouds-night",
    ["09n"] = "shower-rain-night",
    ["10n"] = "rain-night",
    ["11n"] = "thunderstorm-night",
    ["13n"] = "snow-night",
    ["50n"] = "mist-night"
}

-- Parser functions for icon keys
local function parse_icon_num(icon)
    return tonumber(icon:sub(1, -2))
end

local function icon_is_day(icon)
    return icon:sub(-1) == 'd'
end

local function gen_time_str(epoch_time, time_format_12h)
    return os.date(time_format_12h and '%I %p' or '%H:00', epoch_time)
end

--- Return wind direction as a string
local function to_direction(degrees)
    -- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
    if degrees == nil then return "Unknown dir" end
    local directions = LCLE.directions
    return directions[math.floor((degrees % 360) / 22.5) + 1]
end

--- Convert degrees Celsius to Fahrenheit
local function celsius_to_fahrenheit(c) return c * 9 / 5 + 32 end

-- Convert degrees Fahrenheit to Celsius
local function fahrenheit_to_celsius(f) return (f - 32) * 5 / 9 end

local function gen_temperature_str(temp, fmt_str, show_other_units, units)
    local temp_str = string.format(fmt_str, temp)
    local s = temp_str .. '°' .. (units == 'metric' and 'C' or 'F')

    if (show_other_units) then
        local temp_conv, units_conv
        if (units == 'metric') then
            temp_conv = celsius_to_fahrenheit(temp)
            units_conv = 'F'
        else
            temp_conv = fahrenheit_to_celsius(temp)
            units_conv = 'C'
        end

        local temp_conv_str = string.format(fmt_str, temp_conv)
        s = s .. ' ' .. '(' .. temp_conv_str .. '°' .. units_conv .. ')'
    end
    return s
end

local function uvi_index_color(uvi)
    local color
    if uvi >= 0 and uvi < 3 then color = '#A3BE8C'
    elseif uvi >= 3 and uvi < 6 then color = '#EBCB8B'
    elseif uvi >= 6 and uvi < 8 then color = '#D08770'
    elseif uvi >= 8 and uvi < 11 then color = '#BF616A'
    elseif uvi >= 11 then color = '#B48EAD'
    end

    return '<span weight="bold" foreground="' .. color .. '">' .. uvi .. '</span>'
end

local function worker(user_args)

    local args = user_args or {}

    --- Validate required parameters
    if args.coordinates == nil or args.api_key == nil then
        show_warning(LCLE.parameter_warning ..
                     (args.coordinates == nil and '<b>coordinates</b>' or '') ..
                     (args.api_key == nil and ', <b>api_key</b> ' or ''))
        return
    end

    local coordinates = args.coordinates
    local api_key = args.api_key
    local font_name = args.font_name or beautiful.font:gsub("%s%d+$", "")
    local units = args.units or 'metric'
    local time_format_12h = args.time_format_12h or false
    local both_units_widget = args.both_units_widget or false
    local show_hourly_forecast = args.show_hourly_forecast or false
    local show_daily_forecast = args.show_daily_forecast or false
    local icon_pack_name = args.icons or 'weather-underground-icons'
    local icons_extension = args.icons_extension or '.png'

    -- API limit is 60 calls/min for the free plan
    local current_weather_timeout = args.current_weather_timeout or 30
    local forecast_timeout = args.forecast_timeout or 180

    local ICONS_DIR = WIDGET_DIR .. '/icons/' .. icon_pack_name .. '/'

    local owm_api_options = ('?lat=' .. coordinates[1] .. '&lon=' .. coordinates[2] ..
        '&appid=' .. api_key .. '&units=' .. units .. '&lang=' .. LANG)

    local owm_weather_api = 'https://api.openweathermap.org/data/2.5/weather' .. owm_api_options
    local owm_forecast_api = 'https://api.openweathermap.org/data/2.5/forecast' .. owm_api_options

    weather_widget = wibox.widget {
        {
            {
                {
                    {
                        id = 'icon',
                        resize = true,
                        widget = wibox.widget.imagebox
                    },
                    valign = 'center',
                    widget = wibox.container.place,
                },
                {
                    id = 'txt',
                    widget = wibox.widget.textbox
                },
                layout = wibox.layout.fixed.horizontal,
            },
            left = 4,
            right = 4,
            layout = wibox.container.margin
        },
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        widget = wibox.container.background,
        set_image = function(self, path)
            self:get_children_by_id('icon')[1].image = path
        end,
        set_text = function(self, text)
            self:get_children_by_id('txt')[1].text = text
        end,
        is_ok = function(self, is_ok)
            if is_ok then
                self:get_children_by_id('icon')[1]:set_opacity(1)
                self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
            else
                self:get_children_by_id('icon')[1]:set_opacity(0.2)
                self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
            end
        end
    }

    local current_weather_widget = wibox.widget {
        {
            {
                {
                    id = 'icon',
                    resize = true,
                    forced_width = 128,
                    forced_height = 128,
                    widget = wibox.widget.imagebox
                },
                align = 'center',
                widget = wibox.container.place
            },
            {
                id = 'description',
                font = font_name .. ' 10',
                align = 'center',
                widget = wibox.widget.textbox
            },
            forced_width = 128,
            layout = wibox.layout.align.vertical
        },
        {
            {
                {
                    id = 'temp',
                    font = font_name .. ' 36',
                    widget = wibox.widget.textbox
                },
                {
                    id = 'feels_like_temp',
                    align = 'center',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                layout = wibox.layout.fixed.vertical
            },
            {
                {
                    id = 'wind',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                {
                    id = 'humidity',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                {
                    id = 'uv',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                expand = 'inside',
                layout = wibox.layout.align.vertical
            },
            spacing = 16,
            forced_width = 150,
            layout = wibox.layout.fixed.vertical
        },
        forced_width = 300,
        layout = wibox.layout.flex.horizontal,
        update = function(self, weather)
            self:get_children_by_id('icon')[1]:set_image(
                ICONS_DIR .. icon_map[weather.weather[1].icon] .. icons_extension)
            self:get_children_by_id('temp')[1]:set_text(gen_temperature_str(weather.main.temp, '%.0f', false, units))
            self:get_children_by_id('feels_like_temp')[1]:set_text(
                LCLE.feels_like .. gen_temperature_str(weather.main.feels_like, '%.0f', true, units))
            self:get_children_by_id('description')[1]:set_text(weather.weather[1].description)
            self:get_children_by_id('wind')[1]:set_markup(
                LCLE.wind .. '<b>' .. weather.wind.speed .. ' ' ..
                (units == 'metric' and 'm/s' or 'mph') ..
                ' (' .. to_direction(weather.wind.deg) .. ')</b>')
            self:get_children_by_id('humidity')[1]:set_markup(LCLE.humidity .. '<b>' .. weather.main.humidity .. '%</b>')
        end
    }


    local daily_forecast_widget = {
        forced_width = 300,
        layout = wibox.layout.flex.horizontal,
        update = function(self, forecast)
            local count = #self
            for i = 0, count do self[i]=nil end

            -- Collect 3-hour data into 5-day data
            local abridged_forecast = {}
            for i, data in ipairs(forecast) do
                local current_data = {
                    day_of_week = os.date('%a', data.dt),
                    -- Use coordinate temp, main.temp_min/temp_max are city-wide
                    temp_max = data.main.temp,
                    temp_min = data.main.temp,
                    weather = {
                        icon = data.weather[1].icon,
                        description = data.weather[1].description,
                        time = gen_time_str(data.dt, time_format_12h),
                    }
                }

                local length = #abridged_forecast
                local last_data = (length == 0 and nil or abridged_forecast[length])

                if last_data == nil or current_data.day_of_week ~= last_data.day_of_week then
                    table.insert(abridged_forecast, current_data)
                else
                    if current_data.temp_max > last_data.temp_max then
                        abridged_forecast[length].temp_max = current_data.temp_max
                    end
                    if current_data.temp_min < last_data.temp_min then
                        abridged_forecast[length].temp_min = current_data.temp_min
                    end

                    local current_icon_num = parse_icon_num(current_data.weather.icon)
                    local last_icon_num = parse_icon_num(last_data.weather.icon)
                    -- Naively show the largest as the "most unique" weather condition.
                    -- If they are equal, prioritize showing the daytime icon.
                    if (current_icon_num > last_icon_num) or (current_icon_num == last_icon_num and
                            icon_is_day(current_data.weather.icon) and
                            not icon_is_day(last_data.weather.icon)) then
                        abridged_forecast[length].weather = current_data.weather
                    end
                end
            end

            for i, data in ipairs(abridged_forecast) do
                if i > 5 then break end
                local day_forecast = wibox.widget {
                    {
                        text = data.day_of_week,
                        align = 'center',
                        font = font_name .. ' 9',
                        widget = wibox.widget.textbox
                    },
                    {
                        {
                            {
                                image = ICONS_DIR .. icon_map[data.weather.icon] .. icons_extension,
                                resize = true,
                                forced_width = 48,
                                forced_height = 48,
                                widget = wibox.widget.imagebox
                            },
                            align = 'center',
                            layout = wibox.container.place
                        },
                        {
                            text = data.weather.description .. '\n' .. data.weather.time,
                            font = font_name .. ' 8',
                            align = 'center',
                            forced_height = 50,
                            widget = wibox.widget.textbox
                        },
                        layout = wibox.layout.fixed.vertical
                    },
                    {
                        {
                            text = '\u{25b2} ' .. gen_temperature_str(data.temp_max, '%.0f', false, units),
                            align = 'center',
                            font = font_name .. ' 9',
                            widget = wibox.widget.textbox
                        },
                        {
                            text = '\u{25bd} ' .. gen_temperature_str(data.temp_min, '%.0f', false, units),
                            align = 'center',
                            font = font_name .. ' 9',
                            widget = wibox.widget.textbox
                        },
                        layout = wibox.layout.fixed.vertical
                    },
                    spacing = 8,
                    layout = wibox.layout.fixed.vertical
                }
                table.insert(self, day_forecast)
            end
        end
    }

    local hourly_forecast_graph = wibox.widget {
        step_width = 12,
        color = '#EBCB8B',
        background_color = beautiful.bg_normal,
        forced_height = 100,
        forced_width = 300,
        widget = wibox.widget.graph,
        set_max_value = function(self, new_max_value)
            self.max_value = new_max_value
        end,
        set_min_value = function(self, new_min_value)
            self.min_value = new_min_value
        end
    }
    local hourly_forecast_negative_graph = wibox.widget {
        step_width = 12,
        color = '#5E81AC',
        background_color = beautiful.bg_normal,
        forced_height = 100,
        forced_width = 300,
        widget = wibox.widget.graph,
        set_max_value = function(self, new_max_value)
            self.max_value = new_max_value
        end,
        set_min_value = function(self, new_min_value)
            self.min_value = new_min_value
        end
    }

    local hourly_forecast_widget = {
        layout = wibox.layout.fixed.vertical,
        update = function(self, forecast)
            local hours_below = {
                id = 'hours',
                forced_width = 300,
                layout = wibox.layout.flex.horizontal
            }
            local temp_below = {
                id = 'temp',
                forced_width = 300,
                layout = wibox.layout.flex.horizontal
            }

            local max_temp = -1000
            local min_temp = 1000
            local values = {}
            for i, data in ipairs(forecast) do
                if i > 25 then break end
                local hour_temp = data.main.temp
                values[i] = hour_temp
                if max_temp < hour_temp then max_temp = hour_temp end
                if min_temp > hour_temp then min_temp = hour_temp end
                if (i - 1) % 4 == 0 then
                    table.insert(hours_below, wibox.widget {
                        text = gen_time_str(data.dt, time_format_12h),
                        align = 'left',
                        font = font_name .. ' 9',
                        widget = wibox.widget.textbox
                    })
                    table.insert(temp_below, wibox.widget {
                        markup = '<span foreground="'
                                .. (tonumber(hour_temp) > 0 and '#2E3440' or '#ECEFF4') .. '">'
                                .. string.format('%.0f', hour_temp) .. '°' .. '</span>',
                        align = 'left',
                        font = font_name .. ' 9',
                        widget = wibox.widget.textbox
                    })
                end
            end

            hourly_forecast_graph:set_max_value(math.max(max_temp, math.abs(min_temp)))
            hourly_forecast_graph:set_min_value(min_temp > 0 and min_temp * 0.7 or 0) -- move graph a bit up

            hourly_forecast_negative_graph:set_max_value(math.abs(min_temp))
            hourly_forecast_negative_graph:set_min_value(max_temp < 0 and math.abs(max_temp) * 0.7 or 0)

            for _, value in ipairs(values) do
                if value >= 0 then
                    hourly_forecast_graph:add_value(value)
                    hourly_forecast_negative_graph:add_value(0)
                else
                    hourly_forecast_graph:add_value(0)
                    hourly_forecast_negative_graph:add_value(math.abs(value))
                end
            end

            local count = #self
            for i = 0, count do self[i]=nil end

            -- all temperatures are positive
            if min_temp > 0 then
                table.insert(self, wibox.widget{
                    {
                        hourly_forecast_graph,
                        reflection = {horizontal = true},
                        widget = wibox.container.mirror
                    },
                    {
                        temp_below,
                        valign = 'bottom',
                        widget = wibox.container.place
                    },
                    id = 'graph',
                    layout = wibox.layout.stack
                })
                table.insert(self, hours_below)

            -- all temperatures are negative
            elseif max_temp < 0 then
                table.insert(self, hours_below)
                table.insert(self, wibox.widget{
                    {
                        hourly_forecast_negative_graph,
                        reflection = {horizontal = true, vertical = true},
                        widget = wibox.container.mirror
                    },
                    {
                        temp_below,
                        valign = 'top',
                        widget = wibox.container.place
                    },
                    id = 'graph',
                    layout = wibox.layout.stack
                })

            -- there are both negative and positive temperatures
            else
                table.insert(self, wibox.widget{
                    {
                        hourly_forecast_graph,
                        reflection = {horizontal = true},
                        widget = wibox.container.mirror
                    },
                    {
                        temp_below,
                        valign = 'bottom',
                        widget = wibox.container.place
                    },
                    id = 'graph',
                    layout = wibox.layout.stack
                })
                table.insert(self, wibox.widget{
                    {
                        hourly_forecast_negative_graph,
                        reflection = {horizontal = true, vertical = true},
                        widget = wibox.container.mirror
                    },
                    {
                        hours_below,
                        valign = 'top',
                        widget = wibox.container.place
                    },
                    id = 'graph',
                    layout = wibox.layout.stack
                })
            end
        end
    }

    -- Handle non-empty stderr, and return warning_shown
    local function handle_stderr(widget, stderr)
        if stderr ~= '' then
            if not warning_shown then
                if (stderr ~= 'curl: (52) Empty reply from server'
                and stderr ~= 'curl: (28) Failed to connect to api.openweathermap.org port 443: Connection timed out'
                and stderr:find('^curl: %(18%) transfer closed with %d+ bytes remaining to read$') ~= nil
                ) then
                    show_warning(stderr)
                end
                warning_shown = true
                widget:is_ok(false)
                tooltip:add_to_object(widget)

                widget:connect_signal('mouse::enter', function() tooltip.text = stderr end)
            end
        else
            warning_shown = false
            tooltip:remove_from_object(widget)
            widget:is_ok(true)
        end

        return warning_shown
    end

    -- Rethink what to render in the popup widget
    local function refresh_popup()
        local final_widget = {
            current_weather_widget,
            spacing = 16,
            layout = wibox.layout.fixed.vertical
        }

        if show_hourly_forecast then
            table.insert(final_widget, hourly_forecast_widget)
        end
        if show_daily_forecast then
            table.insert(final_widget, daily_forecast_widget)
        end

        weather_popup:setup({
            {
                final_widget,
                margins = 10,
                widget = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        })
    end

    -- Callback for the current weather API response
    local function update_current_weather(widget, stdout, stderr)
        if handle_stderr(widget, stderr) then
            return
        end

        local current_data = json.decode(stdout)

        widget:set_image(ICONS_DIR .. icon_map[current_data.weather[1].icon] .. icons_extension)
        widget:set_text(gen_temperature_str(current_data.main.temp, '%.0f', both_units_widget, units))

        current_weather_widget:update(current_data)

        refresh_popup()
    end

    -- Callback for the forecast API response
    local function update_forecast(widget, stdout, stderr)
        if handle_stderr(widget, stderr) then
            return
        end

        local forecast_data = json.decode(stdout)

        if show_hourly_forecast then
            hourly_forecast_widget:update(forecast_data.list)
        end
        if show_daily_forecast then
            daily_forecast_widget:update(forecast_data.list)
        end

        refresh_popup()
    end

    function weather_widget.hide()
        weather_widget:set_bg('#00000000')
        weather_popup.visible = false
    end

    weather_widget:buttons(gears.table.join(awful.button({}, 1, function()
            if weather_popup.visible then
                weather_widget.hide()
            else
                weather_widget:set_bg(beautiful.bg_focus)
                weather_popup:move_next_to(mouse.current_widget_geometry)
            end
        end)))

    watch(
        string.format(CALL_API_CMD, owm_weather_api),
        current_weather_timeout,
        update_current_weather, weather_widget
    )

    watch(
        string.format(CALL_API_CMD, owm_forecast_api),
        forecast_timeout,
        update_forecast, weather_widget
    )

    return weather_widget
end

return setmetatable(weather_widget, {__call = function(_, ...) return worker(...) end})
