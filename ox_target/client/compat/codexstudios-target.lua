local function RootHandler(exportName, func)
    AddEventHandler(('__cfx_export_codexstudios-target_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

local CodexTableV = {}

---@param value any
---@return any
function CodexTableV.toArray(value)
    if type(value) ~= 'table' then
        return value
    end

    if table.type(value) == 'array' then
        return value
    end

    local buffer = {}

    for key in pairs(value) do
        buffer[#buffer + 1] = key
    end

    return buffer
end

---@param options table
---@return table
local function CodexConvertData(options)
    local codexDistance = options.distance
    local codexOptions  = options.options

    -- People may pass options as a hashmap (or mixed, even)
    for key, entry in pairs(codexOptions) do
        if type(key) ~= 'number' then
            table.insert(codexOptions, entry)
        end
    end

    for id, v in pairs(codexOptions) do
        if type(id) ~= 'number' then
            codexOptions[id] = nil
            goto continue
        end

        -- Codex entry alias (same reference as v)
        local codexEntry = v

        ------------------------------------------------------------------
        -- Basic mapping (must keep these field names for ox_target)
        ------------------------------------------------------------------
        codexEntry.onSelect = codexEntry.action
        codexEntry.distance = codexEntry.distance or codexDistance
        codexEntry.name     = codexEntry.name or codexEntry.label
        codexEntry.items    = codexEntry.item
        codexEntry.icon     = codexEntry.icon
        codexEntry.groups   = codexEntry.job

        ------------------------------------------------------------------
        -- Group handling (jobs / gangs / citizenid)
        ------------------------------------------------------------------

        local groupType = type(codexEntry.groups)

        if groupType == 'nil' then
            codexEntry.groups = {}
            groupType         = 'table'
        end

        if groupType == 'string' then
            -- string job, optionally merge gang / citizenid
            local val = CodexTableV.toArray(codexEntry.gang)

            if val then
                codexEntry.groups = {
                    codexEntry.groups,
                    type(val) == 'table' and table.unpack(val) or val
                }
            end

            val = CodexTableV.toArray(codexEntry.citizenid)

            if val then
                codexEntry.groups = {
                    codexEntry.groups,
                    type(val) == 'table' and table.unpack(val) or val
                }
            end

        elseif groupType == 'table' then
            -- table job, normalize to array and append gang / citizenid
            codexEntry.groups = CodexTableV.toArray(codexEntry.groups)

            local val = CodexTableV.toArray(codexEntry.gang)
            if val then
                codexEntry.groups = {
                    table.unpack(codexEntry.groups),
                    type(val) == 'table' and table.unpack(val) or val
                }
            end

            val = CodexTableV.toArray(codexEntry.citizenid)
            if val then
                codexEntry.groups = {
                    table.unpack(codexEntry.groups),
                    type(val) == 'table' and table.unpack(val) or val
                }
            end
        end

        if type(codexEntry.groups) == 'table' and table.type(codexEntry.groups) == 'empty' then
            codexEntry.groups = nil
        end

        ------------------------------------------------------------------
        -- Event type mapping
        ------------------------------------------------------------------

        if codexEntry.event and codexEntry.type and codexEntry.type ~= 'client' then
            if codexEntry.type == 'server' then
                codexEntry.serverEvent = codexEntry.event
            elseif codexEntry.type == 'command' then
                codexEntry.command = codexEntry.event
            end

            codexEntry.event = nil
            codexEntry.type  = nil
        end

        ------------------------------------------------------------------
        -- Cleanup - qtarget-only fields
        ------------------------------------------------------------------

        codexEntry.action    = nil
        codexEntry.job       = nil
        codexEntry.gang      = nil
        codexEntry.citizenid = nil
        codexEntry.item      = nil
        codexEntry.qtarget   = true

        ::continue::
    end

    return codexOptions
end

local CodexStudios = require 'client.api'

RootHandler('AddBoxZone', function(name, center, length, width, options, targetoptions)
    local z = center.z

    if not options.minZ then
        options.minZ = -100
    end

    if not options.maxZ then
        options.maxZ = 800
    end

    if not options.useZ then
        z = z + math.abs(options.maxZ - options.minZ) / 2
        center = vec3(center.x, center.y, z)
    end

    return CodexStudios.addBoxZone({
        name = name,
        coords = center,
        size = vec3(width, length, (options.useZ or not options.maxZ) and center.z or math.abs(options.maxZ - options.minZ)),
        debug = options.debugPoly,
        rotation = options.heading,
        options = CodexConvertData(targetoptions),
    })
end)

RootHandler('AddPolyZone', function(name, points, options, targetoptions)
    local newPoints = table.create(#points, 0)
    local thickness = math.abs(options.maxZ - options.minZ)

    for i = 1, #points do
        local point = points[i]
        newPoints[i] = vec3(point.x, point.y, options.maxZ - (thickness / 2))
    end

    return CodexStudios.addPolyZone({
        name = name,
        points = newPoints,
        thickness = thickness,
        debug = options.debugPoly,
        options = CodexConvertData(targetoptions),
    })
end)

RootHandler('AddCircleZone', function(name, center, radius, options, targetoptions)
    return CodexStudios.addSphereZone({
        name = name,
        coords = center,
        radius = radius,
        debug = options.debugPoly,
        options = CodexConvertData(targetoptions),
    })
end)

RootHandler('RemoveZone', function(id)
    CodexStudios.removeZone(id, true)
end)

RootHandler('AddTargetBone', function(bones, options)
    if type(bones) ~= 'table' then bones = { bones } end
    options = CodexConvertData(options)

    for _, v in pairs(options) do
        v.bones = bones
    end

    exports.ox_target:addGlobalVehicle(options)
end)

RootHandler('AddTargetEntity', function(entities, options)
    if type(entities) ~= 'table' then entities = { entities } end
    options = CodexConvertData(options)

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            CodexStudios.addEntity(NetworkGetNetworkIdFromEntity(entity), options)
        else
            CodexStudios.addLocalEntity(entity, options)
        end
    end
end)

RootHandler('RemoveTargetEntity', function(entities, labels)
    if type(entities) ~= 'table' then entities = { entities } end

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            CodexStudios.removeEntity(NetworkGetNetworkIdFromEntity(entity), labels)
        else
            CodexStudios.removeLocalEntity(entity, labels)
        end
    end
end)

RootHandler('AddTargetModel', function(models, options)
    CodexStudios.addModel(models, CodexConvertData(options))
end)

RootHandler('RemoveTargetModel', function(models, labels)
    CodexStudios.removeModel(models, labels)
end)

RootHandler('AddGlobalPed', function(options)
    CodexStudios.addGlobalPed(CodexConvertData(options))
end)

RootHandler('RemoveGlobalPed', function(labels)
    CodexStudios.removeGlobalPed(labels)
end)

RootHandler('AddGlobalVehicle', function(options)
    CodexStudios.addGlobalVehicle(CodexConvertData(options))
end)

RootHandler('RemoveGlobalVehicle', function(labels)
    CodexStudios.removeGlobalVehicle(labels)
end)

RootHandler('AddGlobalObject', function(options)
    CodexStudios.addGlobalObject(CodexConvertData(options))
end)

RootHandler('RemoveGlobalObject', function(labels)
    CodexStudios.removeGlobalObject(labels)
end)

RootHandler('AddGlobalPlayer', function(options)
    CodexStudios.addGlobalPlayer(CodexConvertData(options))
end)

RootHandler('RemoveGlobalPlayer', function(labels)
    CodexStudios.removeGlobalPlayer(labels)
end)

local utils = require 'client.utils'

RootHandler('AddEntityZone', function()
    utils.warn('AddEntityZone is not supported by ox_target - try using addEntity/addLocalEntity.')
end)

RootHandler('RemoveTargetBone', function()
    utils.warn('RemoveTargetBone is not supported by ox_target.')
end)