--[[
    This provides an emulation of the DataModel (aka global 'game') and also provides all of your servers a unique JobId for Studio testing, since this is normally not generated unless actually playing
]]

local HttpService = game:GetService("HttpService") --// For generating a GUID

local MessagingServiceEmulatorModule = script.Parent

local Signal = require(MessagingServiceEmulatorModule.Signal)

--// This gives you a simulation of the game data model, so that you can deal with having different JobIds, etc.
return function()
    local SimulateCloseSignal = Signal.new()

    local SimulatedDataModel = {
        ["JobId"] = HttpService:GenerateGUID(false),
    }

    --// For game methods, we need to reroute all of these, because there's no way to capture the arguments of a method call using metamethods
    function SimulatedDataModel:BindToClose(...)
        local Arguments = {...}

        SimulateCloseSignal:Connect(table.unpack(Arguments)) --// Simulates BindToClose
    end

    function SimulatedDataModel:GetJobsInfo(...)
        local Arguments = {...}

        return game:GetJobsInfo(table.unpack(Arguments)) --// This method doesn't take arguments, so this neither hurts or really does anything :/
    end

    function SimulatedDataModel:GetObjects(...)
        local Arguments = {...}

        return game:GetObjects(table.unpack(Arguments)) --// This method doesn't take arguments, so this neither hurts or really does anything :/
    end

    function SimulatedDataModel:IsLoaded(...)
        local Arguments = {...}

        return game:IsLoaded(table.unpack(Arguments)) --// This method doesn't take arguments, so this neither hurts or really does anything :/
    end

    function SimulatedDataModel:SetPlaceId(...)
        local Arguments = {...}

        return game:SetPlaceId(table.unpack(Arguments)) --// This method doesn't take arguments, so this neither hurts or really does anything :/
    end

    function SimulatedDataModel:SetUniverseId(...)
        local Arguments = {...}

        return game:SetUniverseId(table.unpack(Arguments)) --// This method doesn't take arguments, so this neither hurts or really does anything :/
    end

    --// ServiceProvider methods
    function SimulatedDataModel:FindService(...)
        local Arguments = {...}

        return game:FindService(table.unpack(Arguments)) --// This method doesn't take arguments, so this neither hurts or really does anything :/
    end

    function SimulatedDataModel:GetService(...)
        local Arguments = {...}

        return game:GetService(table.unpack(Arguments)) --// This method doesn't take arguments, so this neither hurts or really does anything :/
    end

    --// Custom methods
    function SimulatedDataModel:SimulateClose(...)
        SimulateCloseSignal:Fire()
    end

    setmetatable(SimulatedDataModel, {
        __index = function(Table, Index) --// Used for retrieving/reading game properties
            local ActualDataModel = workspace.Parent

            return ActualDataModel[Index]
        end,
    })

    return SimulatedDataModel
end