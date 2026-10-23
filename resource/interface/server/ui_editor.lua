local settingsPath = 'data/ui_settings.json'
local resourceName = GetCurrentResourceName()
local version = 1

local componentTargets = {
    'contextMenu',
    'notifications',
    'inputDialog',
    'alertDialog',
    'textUI',
    'progress',
    'skillCheck',
    'radialMenu',
    'menu',
}

local targetLabels = {
    global = 'Global',
    contextMenu = 'Context Menu',
    notifications = 'Notifications',
    inputDialog = 'Input Dialog',
    alertDialog = 'Alert Dialog',
    textUI = 'Text UI',
    progress = 'Progress',
    skillCheck = 'Skill Check',
    radialMenu = 'Radial Menu',
    menu = 'Menu',
}

local allowedTargets = {}
for i = 1, #componentTargets do allowedTargets[componentTargets[i]] = true end
allowedTargets.global = true

local presetIds = {
    accent = { default = true, custom = true },
    colorIntensity = { off = true, subtle = true, default = true, strong = true },
    background = { default = true, black = true, graphite = true, light = true, custom = true },
    transparency = { solid = true, default = true, transparent = true },
    corners = { sharp = true, default = true, soft = true },
    perspective = {
        off = true,
        left_normal = true,
        left_medium = true,
        left_strong = true,
        right_normal = true,
        right_medium = true,
        right_strong = true,
    },
}

local scopeKeys = {
    accent = true,
    colorIntensity = true,
    background = true,
    transparency = true,
    corners = true,
    perspective = true,
}

local perspectiveTargets = {
    contextMenu = true,
    notifications = true,
}

local function defaultSettings()
    return {
        version = version,
        language = 'en',
        global = {
            accent = { preset = 'default', customColor = '#1E90FF' },
            colorIntensity = 'default',
            background = { preset = 'default', customColor = '#000000' },
            transparency = 'default',
            corners = 'default',
            perspective = 'left_normal',
        },
        components = {
            notifications = { perspective = 'off' },
        },
    }
end

local function isHexColor(value)
    return type(value) == 'string' and value:match('^#%x%x%x%x%x%x$') ~= nil
end

local function copyColor(value)
    return { preset = value.preset, customColor = value.customColor }
end

local function copyScope(value)
    local result = {}
    if value.accent then result.accent = copyColor(value.accent) end
    if value.colorIntensity then result.colorIntensity = value.colorIntensity end
    if value.background then result.background = copyColor(value.background) end
    if value.transparency then result.transparency = value.transparency end
    if value.corners then result.corners = value.corners end
    if value.perspective then result.perspective = value.perspective end
    return result
end

local function copySettings(value)
    local result = {
        version = version,
        language = value.language,
        global = copyScope(value.global),
        components = {},
    }
    for i = 1, #componentTargets do
        local target = componentTargets[i]
        if value.components[target] then result.components[target] = copyScope(value.components[target]) end
    end
    return result
end

local function normaliseColor(value, ids, fallback, optional)
    if type(value) ~= 'table' or not ids[value.preset] then
        if optional then return nil end
        return copyColor(fallback)
    end
    return {
        preset = value.preset,
        customColor = isHexColor(value.customColor) and value.customColor:upper() or fallback.customColor,
    }
end

local function normalisePerspective(value, fallback)
    if presetIds.perspective[value] then return value end
    if value == 'default' then return 'left_normal' end
    if value == 'strong' then return 'left_strong' end
    return fallback
end

local function normaliseComponent(value, target)
    if type(value) ~= 'table' then return {} end
    local result = {}
    result.accent = normaliseColor(value.accent, presetIds.accent, { preset = 'default', customColor = '#1E90FF' }, true)
    result.background = normaliseColor(value.background, presetIds.background, { preset = 'default', customColor = '#000000' }, true)
    if presetIds.colorIntensity[value.colorIntensity] then result.colorIntensity = value.colorIntensity end
    if presetIds.transparency[value.transparency] then result.transparency = value.transparency end
    if presetIds.corners[value.corners] then result.corners = value.corners end
    local perspective = normalisePerspective(value.perspective)
    if perspectiveTargets[target] and perspective then
        result.perspective = perspective
    end
    return result
end

local function normaliseSettings(value)
    local defaults = defaultSettings()
    if type(value) ~= 'table' or value.version ~= version then return defaults end
    local global = type(value.global) == 'table' and value.global or {}
    local components = type(value.components) == 'table' and value.components or {}
    local result = {
        version = version,
        language = value.language == 'ar' and 'ar' or 'en',
        global = {
            accent = normaliseColor(global.accent, presetIds.accent, defaults.global.accent, false),
            colorIntensity = presetIds.colorIntensity[global.colorIntensity] and global.colorIntensity or 'default',
            background = normaliseColor(global.background, presetIds.background, defaults.global.background, false),
            transparency = presetIds.transparency[global.transparency] and global.transparency or 'default',
            corners = presetIds.corners[global.corners] and global.corners or 'default',
            perspective = normalisePerspective(global.perspective, defaults.global.perspective),
        },
        components = {},
    }

    for i = 1, #componentTargets do
        local target = componentTargets[i]
        local scope = normaliseComponent(components[target], target)
        if next(scope) then result.components[target] = scope end
    end
    return result
end

local function validateKeys(value, allowed)
    for key in pairs(value) do
        if not allowed[key] then return false end
    end
    return true
end

local function validateColor(value, ids, label)
    if type(value) ~= 'table' or not validateKeys(value, { preset = true, customColor = true }) then
        return nil, ('%s must contain only preset and customColor'):format(label)
    end
    if not ids[value.preset] then return nil, ('Invalid %s preset'):format(label) end
    if not isHexColor(value.customColor) then return nil, ('Invalid %s custom color'):format(label) end
    return { preset = value.preset, customColor = value.customColor:upper() }
end

local function validateScope(value, isGlobal)
    if type(value) ~= 'table' then return nil, 'Settings values must be an object' end
    local allowed = {}
    for key in pairs(scopeKeys) do allowed[key] = true end
    allowed.language = isGlobal or nil
    if not validateKeys(value, allowed) then return nil, 'Unsupported settings key' end
    if isGlobal and value.language ~= 'en' and value.language ~= 'ar' then return nil, 'Invalid language' end

    local result = {}
    local color, err
    if value.accent ~= nil then
        color, err = validateColor(value.accent, presetIds.accent, 'accent')
        if not color then return nil, err end
        result.accent = color
    end
    if value.background ~= nil then
        color, err = validateColor(value.background, presetIds.background, 'background')
        if not color then return nil, err end
        result.background = color
    end

    for _, key in ipairs({ 'colorIntensity', 'transparency', 'corners', 'perspective' }) do
        if value[key] ~= nil then
            if not presetIds[key][value[key]] then return nil, ('Invalid %s preset'):format(key) end
            result[key] = value[key]
        end
    end

    if isGlobal then
        for key in pairs(scopeKeys) do
            if result[key] == nil then return nil, 'Global settings must include every preset group' end
        end
        result.language = value.language
    end
    return result
end

local function validateUpdate(payload)
    if type(payload) ~= 'table' or not validateKeys(payload, { target = true, values = true }) then
        return nil, 'Invalid settings payload'
    end
    if not allowedTargets[payload.target] then return nil, 'Invalid settings target' end
    local values, err = validateScope(payload.values, payload.target == 'global')
    if not values then return nil, err end
    return { target = payload.target, values = values }
end

local function applyUpdate(current, update)
    local result = copySettings(current)
    if update.target == 'global' then
        result.language = update.values.language
        result.global = copyScope(update.values)
    elseif next(update.values) then
        result.components[update.target] = copyScope(update.values)
    else
        result.components[update.target] = nil
    end
    return result
end

local function encodeColor(value)
    return ('{"preset":%s,"customColor":%s}'):format(json.encode(value.preset), json.encode(value.customColor))
end

local function encodeScope(value)
    local fields = {}
    if value.accent then fields[#fields + 1] = '"accent":' .. encodeColor(value.accent) end
    if value.colorIntensity then fields[#fields + 1] = '"colorIntensity":' .. json.encode(value.colorIntensity) end
    if value.background then fields[#fields + 1] = '"background":' .. encodeColor(value.background) end
    if value.transparency then fields[#fields + 1] = '"transparency":' .. json.encode(value.transparency) end
    if value.corners then fields[#fields + 1] = '"corners":' .. json.encode(value.corners) end
    if value.perspective then fields[#fields + 1] = '"perspective":' .. json.encode(value.perspective) end
    return '{' .. table.concat(fields, ',') .. '}'
end

local function encodeSettings(value)
    local components = {}
    for i = 1, #componentTargets do
        local target = componentTargets[i]
        if value.components[target] and next(value.components[target]) then
            components[#components + 1] = json.encode(target) .. ':' .. encodeScope(value.components[target])
        end
    end
    return ('{"version":1,"language":%s,"global":%s,"components":{%s}}\n')
        :format(json.encode(value.language), encodeScope(value.global), table.concat(components, ','))
end

local function loadSettings()
    local contents = LoadResourceFile(resourceName, settingsPath)
    if not contents then return defaultSettings() end
    local ok, decoded = pcall(json.decode, contents)
    return normaliseSettings(ok and decoded or nil)
end

local settings = loadSettings()

local function hasPermission(source)
    return source > 0 and IsPlayerAceAllowed(source, 'probyte.ui')
end

lib.callback.register('ox_lib:getProByteUISettings', function()
    return copySettings(settings)
end)

lib.callback.register('ox_lib:saveProByteUISettings', function(source, payload)
    if not hasPermission(source) then return { ok = false, error = 'Permission denied' } end
    local update, err = validateUpdate(payload)
    if not update then return { ok = false, error = err } end
    local nextSettings = applyUpdate(settings, update)
    if not SaveResourceFile(resourceName, settingsPath, encodeSettings(nextSettings), -1) then
        return { ok = false, error = 'Unable to write data/ui_settings.json' }
    end
    settings = nextSettings
    TriggerClientEvent('ox_lib:updateProByteUISettings', -1, copySettings(settings))
    return {
        ok = true,
        settings = copySettings(settings),
        message = ('Saved %s selections'):format(targetLabels[update.target]),
    }
end)

RegisterCommand('pbui', function(source)
    if not hasPermission(source) then
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'You do not have permission to open the ProByte UI Editor.',
            })
        end
        return
    end
    TriggerClientEvent('ox_lib:openProByteUIEditor', source, copySettings(settings))
end, false)
