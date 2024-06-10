--[[
    This provides an emulation of the DataModel (aka global 'game') and also provides all of your servers a unique JobId for Studio testing, since this is normally not generated unless actually playing
]]

local HttpService = game:GetService("HttpService") --// For generating a GUID

local MessagingServiceEmulatorModule = script.Parent

local Signal = require(MessagingServiceEmulatorModule.Signal)

--// This gives you a simulation of the game data model, so that you can deal with having different JobIds, etc.
return function()
    local SimulateCloseSignal = Signal.new()

    --[=[
        @class SimulatedDataModel
        @server

        A unique DataModel simulated for each virtual server being simulated and for the actual Studio session using MessagingServiceEmulator.
    ]=]
    local SimulatedDataModel = {
        ["JobId"] = HttpService:GenerateGUID(false),
    }

    --// For game methods, we need to reroute all of these, because there's no way to capture the arguments of a method call using metamethods

    --[=[
        @method BindToClose
        @within SimulatedDataModel

        See documentation for [DataModel:BindToClose]
    ]=]
    function SimulatedDataModel:BindToClose(...)
        SimulateCloseSignal:Connect(...) --// Simulates BindToClose
    end

    --[=[
        @method GetJobsInfo
        @within SimulatedDataModel

        See documentation for [DataModel:GetJobsInfo]
    ]=]
    function SimulatedDataModel:GetJobsInfo()
        return game:GetJobsInfo() --// Method doesn't take arguments
    end

    --[=[
        @method GetObjects
        @within SimulatedDataModel

        See documentation for [DataModel:GetObjects]
    ]=]
    function SimulatedDataModel:GetObjects(...)
        return game:GetObjects(...)
    end

    --[=[
        @method IsLoaded
        @within SimulatedDataModel

        See documentation for [DataModel:IsLoaded]
    ]=]
    function SimulatedDataModel:IsLoaded()
        return game:IsLoaded() --// Method doesn't take arguments
    end

    --[=[
        @method SetPlaceId
        @within SimulatedDataModel

        See documentation for [DataModel:SetPlaceId]
    ]=]
    function SimulatedDataModel:SetPlaceId(...)
        return game:SetPlaceId(...)
    end

    --[=[
        @method SetUniverseId
        @within SimulatedDataModel

        See documentation for [DataModel:SetUniverseId]
    ]=]
    function SimulatedDataModel:SetUniverseId(...)
        return game:SetUniverseId(...)
    end

    --// ServiceProvider methods

    --[=[
        @method FindService
        @within SimulatedDataModel

        See documentation for [DataModel:FindService]
    ]=]
    function SimulatedDataModel:FindService(...)
        return game:FindService(...)
    end

    --[=[
        @method GetService
        @within SimulatedDataModel

        See documentation for [DataModel:GetService]
    ]=]
    function SimulatedDataModel:GetService(...)
        return game:GetService(...)
    end

    --// Custom methods

    --[=[
        @method SimulateClose
        @within SimulatedDataModel

        Simulates the DataModel closing and fires all functions bound via [SimulatedDataModel:BindToClose]
    ]=]
    function SimulatedDataModel:SimulateClose()
        SimulateCloseSignal:Fire()
    end

    setmetatable(SimulatedDataModel, {
        __index = function(Table, Index) --// Used for retrieving/reading game properties
            return game[Index]
        end,
    })

    return SimulatedDataModel
end
