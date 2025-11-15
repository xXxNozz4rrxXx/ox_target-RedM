-- client/framework/codexcore.lua

local CodexCore = exports['codex_core']:getLibClient()
local utils      = require 'client.utils'

-- ===================== DEBUG =====================
local DEBUG = true

local function dprint(...)
    if not DEBUG then return end
    print('[CodexCore-Groups]', ...)
end
-- =================================================

local groups       = { 'job', 'group' }
local playerGroups = {}
local playerItems  = utils.getItems and utils.getItems() or {}

local function wipeTable(t)
    if table.wipe then
        table.wipe(t)
    else
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

-- Refresh from CodexCore
local function setPlayerData()
    dprint('setPlayerData() called')

    wipeTable(playerGroups)
    wipeTable(playerItems)

    local jobName  = CodexCore.GetJob()
    local jobGrade = CodexCore.GetJobGrade() or 0

    dprint(('Job: %s | Grade: %s'):format(tostring(jobName), tostring(jobGrade)))

    if jobName then
        playerGroups.job = {
            name  = jobName,
            grade = jobGrade
        }
    end

    if CodexCore.GetGroup then
        local groupName = CodexCore.GetGroup()
        dprint(('Group: %s'):format(tostring(groupName)))

        if groupName then
            playerGroups.group = {
                name  = groupName,
                grade = 0
            }
        end
    end

    for k, v in pairs(playerGroups) do
        dprint(('playerGroups[%s] = { name = %s, grade = %s }'):format(
            k,
            tostring(v.name),
            tostring(v.grade)
        ))
    end
end

-- Initial load
CreateThread(function()
    dprint('Init thread started, waiting for CodexCore.IsLoaded()')

    if CodexCore.IsLoaded() then
        dprint('CodexCore already loaded, calling setPlayerData()')
        setPlayerData()
        return
    end

    while not CodexCore.IsLoaded() do
        Wait(500)
    end

    dprint('CodexCore.IsLoaded() became true, calling setPlayerData()')
    setPlayerData()
end)

-- Refresh on CodexCore events
RegisterNetEvent('codex-core:playerLoaded', function()
    dprint('Event: codex-core:playerLoaded')
    setPlayerData()
end)

RegisterNetEvent('codex-core:jobUpdated', function()
    dprint('Event: codex-core:jobUpdated')
    setPlayerData()
end)

-- Override stub from utils.lua
---@param filter string | string[] | table<string, number>
---@return boolean
function utils.hasPlayerGotGroup(filter)
    local _type = type(filter)
    dprint('hasPlayerGotGroup() called, filter type:', _type)

    if _type == 'string' then
        dprint('  filter string =', filter)
    elseif _type == 'table' then
        dprint('  filter table received')
    else
        dprint('  unsupported filter type:', _type)
    end

    for i = 1, #groups do
        local groupKey = groups[i]
        local data     = playerGroups[groupKey]

        if data then
            dprint(('  checking group "%s": name=%s grade=%s'):format(
                groupKey,
                tostring(data.name),
                tostring(data.grade)
            ))
        else
            dprint(('  group "%s" has no data yet'):format(groupKey))
        end

        if _type == 'string' then
            if data and filter == data.name then
                dprint('  MATCH (string) on group', groupKey)
                return true
            end

        elseif _type == 'table' then
            local tabletype = table.type and table.type(filter) or nil
            dprint('  tabletype =', tostring(tabletype))

            if tabletype == 'hash' or (not tabletype and next(filter) ~= nil) then
                for name, grade in pairs(filter) do
                    local playerGrade = (data and data.grade) or 0
                    dprint(('  hash check: name=%s, minGrade=%s vs player {name=%s, grade=%s}'):format(
                        tostring(name),
                        tostring(grade),
                        data and tostring(data.name) or 'nil',
                        tostring(playerGrade)
                    ))

                    if data and data.name == name and playerGrade >= grade then
                        dprint('  MATCH (hash) on group', groupKey)
                        return true
                    end
                end

            elseif tabletype == 'array' then
                for j = 1, #filter do
                    local name = filter[j]
                    dprint(('  array check: name=%s vs player name=%s'):format(
                        tostring(name),
                        data and tostring(data.name) or 'nil'
                    ))

                    if data and data.name == name then
                        dprint('  MATCH (array) on group', groupKey)
                        return true
                    end
                end
            end
        end
    end

    dprint('hasPlayerGotGroup() -> no match, returning false')
    return false
end
