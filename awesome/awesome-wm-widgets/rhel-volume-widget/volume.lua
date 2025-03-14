-------------------------------------------------
-- The Ultimate Volume Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @auther Daniel Burke 
-- @copyright 2024 Daniel Burke
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local spawn = require("awful.spawn")
local gears = require("gears")
local beautiful = require("beautiful")
local watch = require("awful.widget.watch")
local utils = require("awesome-wm-widgets.rhel-volume-widget.utils")


local LIST_DEVICES_CMD = [[sh -c "wpctl status"]]
-- Function to get the current volume of a sink using wpctl
local function GET_VOLUME_CMD(sink_id)
    return [[sh -c "wpctl status | grep -A 10 ']] .. sink_id .. [[' | grep 'Volume:'"]]
end

-- Function to increment the volume by a given step using wpctl
local function INC_VOLUME_CMD(sink_id, step)
    -- Ensure step is a number and default it to 5 if not provided
    local step_value = tonumber(step) or 5
    return string.format('wpctl set-volume %s %d%%+', sink_id, step_value)
end

-- Function to decrement the volume by a given step using wpctl
local function DEC_VOLUME_CMD(sink_id, step)
    -- Ensure step is a number and default it to 5 if not provided
    local step_value = tonumber(step) or 5
    return string.format('wpctl set-volume %s %d%%-', sink_id, step_value)
end

-- Function to toggle mute using wpctl
local function TOG_VOLUME_CMD(sink_id)
    return string.format('wpctl set-mute %s toggle', sink_id)
end


local widget_types = {
    icon_and_text = require("awesome-wm-widgets.rhel-volume-widget.widgets.icon-and-text-widget"),
    icon = require("awesome-wm-widgets.rhel-volume-widget.widgets.icon-widget"),
    arc = require("awesome-wm-widgets.rhel-volume-widget.widgets.arc-widget"),
    horizontal_bar = require("awesome-wm-widgets.rhel-volume-widget.widgets.horizontal-bar-widget"),
    vertical_bar = require("awesome-wm-widgets.rhel-volume-widget.widgets.vertical-bar-widget")
}
local volume = {}

local rows  = { layout = wibox.layout.fixed.vertical }

local popup = awful.popup{
    bg = beautiful.bg_normal,
    fg = beautiful.fg_normal,
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}

local function build_main_line(device)
    if device.active_port ~= nil and device.ports[device.active_port] ~= nil then
        return device.properties.device_description .. ' · ' .. device.ports[device.active_port]
    else
        return device.properties.device_description
    end
end

local function build_rows(devices, on_checkbox_click, device_type)
    local device_rows  = { layout = wibox.layout.fixed.vertical }
    for _, device in pairs(devices) do

        local checkbox = wibox.widget {
            checked = device.is_default,
            color = beautiful.fg_normal,
            paddings = 2,
            shape = gears.shape.circle,
            forced_width = 20,
            forced_height = 20,
            check_color = beautiful.fg_normal,
            widget = wibox.widget.checkbox
        }

        checkbox:connect_signal("button::press", function()
            -- Construct the wpctl command to set the default device
            local wpctl_command = string.format([[sh -c 'wpctl set-default %s']], device.name)
        
            -- Execute the command asynchronously
            spawn.easy_async(wpctl_command, function()
                -- Callback when command is finished
                on_checkbox_click()
            end)   
        end)

        local row = wibox.widget {
            {
                {
                    {
                        checkbox,
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    {
                        {
                            text = build_main_line(device),
                            align = 'left',
                            widget = wibox.widget.textbox
                        },
                        left = 10,
                        layout = wibox.container.margin
                    },
                    spacing = 8,
                    layout = wibox.layout.align.horizontal
                },
                margins = 4,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            fg = beautiful.fg_normal,
            widget = wibox.container.background
        }

        row:connect_signal("mouse::enter", function(c)
            checkbox:set_color(beautiful.fg_focus)
            checkbox:set_check_color(beautiful.fg_focus)
            c:set_fg(beautiful.fg_focus)
            c:set_bg(beautiful.bg_focus)
        end)
        row:connect_signal("mouse::leave", function(c)
            checkbox:set_color(beautiful.fg_normal)
            checkbox:set_check_color(beautiful.fg_normal)
            c:set_fg(beautiful.fg_normal)
            c:set_bg(beautiful.bg_normal)
        end)

        local old_cursor, old_wibox
        row:connect_signal("mouse::enter", function()
            local wb = mouse.current_wibox
            old_cursor, old_wibox = wb.cursor, wb
            wb.cursor = "hand1"
        end)
        row:connect_signal("mouse::leave", function()
            if old_wibox then
                old_wibox.cursor = old_cursor
                old_wibox = nil
            end
        end)

        row:connect_signal("button::press", function()
            -- Construct the wpctl command to set the default device (sink/source)
            local wpctl_command = string.format([[sh -c 'wpctl set-default %s']], device.name)
        
            -- Execute the command asynchronously
            spawn.easy_async(wpctl_command, function()
                -- Callback after the command completes
                on_checkbox_click()
            end)
        end)

        table.insert(device_rows, row)
    end

    return device_rows
end

local function build_header_row(text)
    return wibox.widget{
        {
            markup = "<b>" .. text .. "</b>",
            align = 'center',
            widget = wibox.widget.textbox
        },
        bg = beautiful.bg_normal,
        fg = beautiful.fg_normal,
        widget = wibox.container.background
    }
end

local function rebuild_popup()
    spawn.easy_async(LIST_DEVICES_CMD, function(wpctl_output)

        local sinks, sources = utils.extract_sinks_and_sources(wpctl_output)

        for i = 0, #rows do rows[i]=nil end

        table.insert(rows, build_header_row("SINKS"))
        table.insert(rows, build_rows(sinks, function() rebuild_popup() end, "sink"))
        table.insert(rows, build_header_row("SOURCES"))
        table.insert(rows, build_rows(sources, function() rebuild_popup() end, "source"))

        popup:setup(rows)
    end)
end


local function worker(user_args)

    local args = user_args or {}

    local mixer_cmd = args.mixer_cmd or 'pavucontrol' -- Defaults to pavucontrol for the GUI
    local widget_type = args.widget_type
    local refresh_rate = args.refresh_rate or 1
    local step = args.step or 5
    local sink = args.sink or '@DEFAULT_AUDIO_SINK@' -- Default sink in wpctl
    local toggle_cmd = args.toggle_cmd or nil

    if widget_types[widget_type] == nil then
        volume.widget = widget_types['icon_and_text'].get_widget(args.icon_and_text_args)
    else
        volume.widget = widget_types[widget_type].get_widget(args)
    end

    local function update_graphic(widget, wpctl_output)
        local mute = string.match(wpctl_output, "Mute:%s+(%w+)") -- Look for Mute: yes/no
        if mute == 'yes' then widget:mute()
        elseif mute == 'no' then widget:unmute()
        end
	local volume_level = nil -- Simulate a case where volume_level is nil

	-- Safeguard the formatting process
	volume_level = tonumber(volume_level) or 0
	volume_level = string.format("%3d", volume_level)
        widget:set_volume_level(volume_level)
    end

    -- Increment volume using wpctl
    function volume:inc(s)
        spawn.easy_async(string.format("wpctl set-volume %s %d%%+", sink, s or step), function(wpctl_output)
            update_graphic(volume.widget, wpctl_output)
        end)
    end

    -- Decrement volume using wpctl
    function volume:dec(s)
        spawn.easy_async(string.format("wpctl set-volume %s %d%%-", sink, s or step), function(wpctl_output)
            update_graphic(volume.widget, wpctl_output)
        end)
    end

    -- Toggle mute using wpctl
    function volume:toggle()
        if toggle_cmd == nil then
            spawn.easy_async(string.format("wpctl set-mute %s toggle", sink), function(wpctl_output)
                spawn.easy_async(string.format("wpctl get-volume %s", sink), function(wpctl_output)
                    update_graphic(volume.widget, wpctl_output)
                end)
            end)
        else
            spawn.easy_async(toggle_cmd, function(_wpctl_output)
                spawn.easy_async(string.format("wpctl get-volume %s", sink), function(wpctl_output)
                    update_graphic(volume.widget, wpctl_output)
                end)
            end)
        end
    end

    -- Open mixer (GUI control)
    function volume:mixer()
        if mixer_cmd then
            spawn.easy_async(mixer_cmd)
        end
    end

    volume.widget:buttons(
        awful.util.table.join(
            awful.button({}, 3, function()
                if popup.visible then
                    popup.visible = not popup.visible
                else
                    rebuild_popup()
                    popup:move_next_to(mouse.current_widget_geometry)
                end
            end),
            awful.button({}, 4, function() volume:inc() end),
            awful.button({}, 5, function() volume:dec() end),
            awful.button({}, 2, function() volume:mixer() end),
            awful.button({}, 1, function() volume:toggle() end)
        )
    )

    watch(string.format("wpctl get-volume %s", sink), refresh_rate, update_graphic, volume.widget)

    return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker(...) end })
