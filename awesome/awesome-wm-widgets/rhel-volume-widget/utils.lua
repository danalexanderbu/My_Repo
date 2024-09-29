local utils = {}

local function split(string_to_split, separator)
    if separator == nil then separator = "%s" end
    local t = {}

    for str in string.gmatch(string_to_split, "([^".. separator .."]+)") do
        table.insert(t, str)
    end

    return t
end

function utils.extract_sinks_and_sources(wpctl_output)
    local sinks = {}
    local sources = {}
    local device
    local in_sink = false
    local in_source = false

    -- Loop through each line of wpctl status output
    for line in wpctl_output:gmatch("[^\r\n]+") do
        -- Detect sink based on the line indicating its type
        if string.match(line, 'sink') then
            in_sink = true
            in_source = false
            device = {
                id = line:match('^(%d+)%.'),
                name = line:match('%d+%.%s+(.+)'),
                type = 'sink'
            }
            table.insert(sinks, device)
        -- Detect source based on the line indicating its type
        elseif string.match(line, 'source') then
            in_sink = false
            in_source = true
            device = {
                id = line:match('^(%d+)%.'),
                name = line:match('%d+%.%s+(.+)'),
                type = 'source'
            }
            table.insert(sources, device)
        end

        -- Get mute status
        if string.match(line, 'Mute:') and (in_sink or in_source) then
            device.mute = string.match(line, 'Mute:%s+(%w+)') == 'yes'
        end

        -- Get volume percentage
        if string.match(line, 'Volume:') and (in_sink or in_source) then
            local volume = string.match(line, 'Volume:%s+[%d%.]+%s*%[(%d+)%%%]')
            device.volume = tonumber(volume)
        end

        -- Check for active port, if available
        if string.match(line, 'active port:') and (in_sink or in_source) then
            device.active_port = line:match('active port:%s+<(.+)>')
        end
    end

    return sinks, sources
end

return utils
