local HttpService = game:GetService("HttpService") --// We just use this for GenerateUID
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

local DisplayNames = require(script:WaitForChild("DisplayNames"))
local GetSimulatedDataModel = require(script:WaitForChild("GetSimulatedDataModel"))
local ServerSimulator = require(script:WaitForChild("ServerSimulation"))
local Settings = require(script:WaitForChild("Settings"))
local Signal = require(script:WaitForChild("Signal")) --// stravant's GoodSignal with tweaks

local RandomSeed = Random.new(tick())

local ServersBeingAutomaticallyGenerated = false
local ServersCurrentlyBeingSimulated = 0

local AllTopicSignals = {} --// Format [Topic: string] = {[UID: string] = Signal}
local DisplayNameCorrelations = {} --// Format [UID: string] = Name: string,

local function CheckPercentageOccurrence(ChanceOfOccurrence: number)
    if not ChanceOfOccurrence then
        error("ChanceOfOccurrence not provided")
    end

    if ChanceOfOccurrence > 100 then
        error("ChanceOfOccurrence cannot exceed 100")
    end

    if ChanceOfOccurrence < 0 then
        error("ChanceOfOccurrence cannot be negative")
    end

    if ChanceOfOccurrence == 100 then
        return true
    end

    if ChanceOfOccurrence == 0 then
        return false
    end

    local RolledNumber = math.random(1, 100)

    if RolledNumber <= ChanceOfOccurrence then
        return true
    end

    return false
end

local function ReturnRandomizedNumberToHundredthsPlace(LowerBound: number, UpperBound: number)
	local function Round(Number, NumberOfDecimalPlaces)
		local Power = 10^NumberOfDecimalPlaces

		return math.round(Number * Power) / Power
	end

	if LowerBound < 0 then
		error('Error simulating MessagingService latency: LowerBound must be a non-zero number')
	end

	if UpperBound < 0 then
		error('Error simulating MessagingService latency: UpperBound must be a non-zero number')
	end

	if LowerBound > UpperBound then
		error('Error simulating MessagingService latency: UpperBound must be larger than LowerBound')
	end

	if LowerBound == UpperBound then
		return(LowerBound)
	end

	if UpperBound == 0 then
		return(0)
	end

	--[[Simulated latency time will be accurate to the hundreds place]]
	local RoundedLowerBound = Round(LowerBound, 2)
	local RoundedUpperBound = Round(UpperBound, 2)

	local LowerBoundWholeNumber, LowerBoundDecimal = math.modf(RoundedLowerBound)
	local UpperBoundWholeNumber, UpperBoundDecimal = math.modf(RoundedUpperBound)

	local RandomWholeNumber
	
	if (UpperBoundWholeNumber - LowerBoundWholeNumber) <= 1 then
		RandomWholeNumber = 0
	else
		RandomWholeNumber = RandomSeed:NextInteger(LowerBoundWholeNumber, UpperBoundWholeNumber - 1)
	end
	
	local RandomDecimalLowerBound = LowerBoundDecimal * 100
	local RandomDecimalUpperBound = UpperBoundDecimal * 100
	
	if RandomDecimalUpperBound == 0 then
		RandomDecimalUpperBound = 100
	end
	
	local RandomDecimal = RandomSeed:NextInteger(RandomDecimalLowerBound, RandomDecimalUpperBound) / 100

	local RandomNumber = RandomWholeNumber + RandomDecimal

	return RandomNumber
end

local function GetSimulatedLatencyTime()
	return ReturnRandomizedNumberToHundredthsPlace(Settings["Latency Lower Bound"], Settings["Latency Upper Bound"])
end

local function GetSimulatedServerGenerationTime()
    return ReturnRandomizedNumberToHundredthsPlace(Settings["Server Generation Time Lower Bound"], Settings["Server Generation Time Upper Bound"])
end

local function GetDisplayName(UID: string)
    if not Settings["Output Display Names"] then
        return
    end

    local DisplayName = DisplayNameCorrelations[UID]

    if DisplayName then
        return DisplayName
    end

    math.randomseed(tick())

    local RandomIndex = math.random(1, #DisplayNames)

    DisplayNameCorrelations[UID] = DisplayNames[RandomIndex]

    table.remove(DisplayNames, RandomIndex)

    return DisplayNameCorrelations[UID]
end

local function GetEmulator()
    local SimulatedDataModel = GetSimulatedDataModel()
    --[=[
        @class MessagingServiceEmulator
        @server

        An emulator for Roblox's MessagingService, because it is impossible to run multiple local servers at once.  
        This emulator can be used in place of MessagingService completely, because it returns the actual MessagingService for any non-Studio environment.

        Tweak Settings in the sub-module (Settings)
    ]=]
    local MessagingServiceEmulator = {
        ["__UID"] = SimulatedDataModel.JobId,
    }

    setmetatable(MessagingServiceEmulator, { --// Grants us access to MessagingService's actual properties (not sure why you'd need this, but the only thing really necessary to emulate are the methods)
        __index = function(Table, Index)
            return MessagingService[Index]
        end,
    })

    --[=[
        @method GetSimulatedDataModel
        @within MessagingServiceEmulator
        @server

        Returns an emulated replacement for the global DataModel (aka game).

        Useful methods include:
            JobId in Studio
            SimulateClose function

        @return SimulatedDataModel
    ]=]
    function MessagingServiceEmulator:GetSimulatedDataModel()
        return SimulatedDataModel
    end

    --[=[
        @method PublishAsync
        @within MessagingServiceEmulator
        @server
        @yields

        @param Topic string
        @param Message varaint

        Emulates [MessagingService:PublishAsync].  Read the official Roblox documentation for more information.
    ]=]
    function MessagingServiceEmulator:PublishAsync(Topic: string, MessageData: any): RBXScriptConnection
        local InternalUID = MessagingServiceEmulator["__UID"]

        local TopicSignals = AllTopicSignals[Topic]

        if not TopicSignals then
            warn("No servers are currently subscribed to", Topic)

            return
        end

        --// Package in the same way that MessagingService does
        local Message = {}

        Message["Data"] = MessageData
        Message["Sent"] = os.time()

        --// Simulate error
        local SimulatedErrorOccurred = CheckPercentageOccurrence(Settings["Failure Rate"])

        if SimulatedErrorOccurred then
            error("Simulated MessagingService error publishing message. Time sent: " .. Message.Sent .. "; Topic: " .. Topic .. "; MessageData: " .. Message.Data)
        end

        --// Simulate latency yield time (we are simulating how MessagingService:PublishAsync yields until the message is received by the backend.)
        local MessageBackendReceiptLatencyTime = GetSimulatedLatencyTime()
        task.wait(MessageBackendReceiptLatencyTime)

        local FiredSignal = false

        for UID: string, TopicSignal: RBXScriptSignal in pairs (TopicSignals) do
            if UID == InternalUID then --// Prevents sending the message to ourselves (the originating server)
                continue
            end

            TopicSignal:Fire(Message)
            FiredSignal = true
        end

        if Settings["Debug Mode Publish"] then
            local ServerName = if GetDisplayName(MessagingServiceEmulator.__UID) then MessagingServiceEmulator.__UID .. " (" .. GetDisplayName(MessagingServiceEmulator.__UID) .. ")" else MessagingServiceEmulator.__UID

            print("[MessagingServiceEmulator] Message sent by", ServerName, "at " .. Message.Sent .. "; Topic: " .. Topic .. "; MessageData: ")
            print(Message.Data)
        end

        if not FiredSignal and Settings["Debug Subscription"] then
            warn("[MessagingServiceEmulator] No other servers are currently subscribed to", Topic)
        end
    end

    --[=[
        @method SubscribeAsync
        @within MessagingServiceEmulator
        @server
        @yields

        @param Topic string
        @param CallbackFunction function

        Emulates [MessagingService:SubscribeAsync].  Read the official Roblox documentation for more information.

        @return RBXScriptConnection
    ]=]
    function MessagingServiceEmulator:SubscribeAsync(Topic: string, CallbackFunction): RBXScriptConnection
        --// Simulate latency yield time (we are simulating how MessagingService:SubscribeAsync yields until the subscription is properly registered and returns a connection object.)
        local TopicSubscriptionLatencyTime = GetSimulatedLatencyTime()
        task.wait(TopicSubscriptionLatencyTime)

        local InternalUID = MessagingServiceEmulator["__UID"]

        local TopicSignals = AllTopicSignals[Topic]

        if not TopicSignals then
            AllTopicSignals[Topic] = {}
        end

        local TopicSignalForUID = AllTopicSignals[Topic][InternalUID]

        if not TopicSignalForUID then
            AllTopicSignals[Topic][InternalUID] = Signal.new()

            TopicSignalForUID = AllTopicSignals[Topic][InternalUID]

            if Settings["Output Topic Subscription"] then
                warn("Server", MessagingServiceEmulator["__UID"], "subscribed to", Topic)
            end
        end

        local Connection

        Connection = TopicSignalForUID:Connect(function(Message: table)
            local SimulatedErrorOccurred = CheckPercentageOccurrence(Settings["Failure Rate"])

            if SimulatedErrorOccurred then
                error("Simulated MessagingService error receiving message. Time sent: " .. Message.Sent .. "; Topic: " .. Topic .. "; MessageData: " .. Message.Data)
            end

            local MessageReceiptLatencyTime = GetSimulatedLatencyTime()
            task.wait(MessageReceiptLatencyTime)

            if Settings["Debug Subscription"] then
                local ServerName = if GetDisplayName(MessagingServiceEmulator.__UID) then MessagingServiceEmulator.__UID .. " (" .. GetDisplayName(MessagingServiceEmulator.__UID) .. ")" else MessagingServiceEmulator.__UID

                print("[MessagingServiceEmulator] New message received by", ServerName, "after " .. tostring(MessageReceiptLatencyTime) .. "s. Time sent " .. Message.Sent .. "; Topic: " .. Topic .. "; MessageData: ")
                print(Message.Data)
            end

            CallbackFunction(Message)
        end)

        return Connection
    end

    return MessagingServiceEmulator
end

local function AutoSimulateServers()
    if Settings["Servers To Simulate"] < 1 then
        return
    end

    if ServersBeingAutomaticallyGenerated then --// Ensures this only runs once
        return
    end

    ServersBeingAutomaticallyGenerated = true

    task.wait(Settings["Wait Before Automatic Server Generation"])

    for Count = 1, Settings["Servers To Simulate"], 1 do
        task.wait(GetSimulatedServerGenerationTime())

        local Emulator = GetEmulator()
        local DataModel = Emulator:GetSimulatedDataModel()

        ServersCurrentlyBeingSimulated = ServersCurrentlyBeingSimulated + 1

        if Settings["Output When Simulated Servers Are Created"] then
            warn("[MessagingServiceEmulator] " .. tostring(ServersCurrentlyBeingSimulated) .. " of " .. tostring(Settings["Servers To Simulate"] .. " simulated servers generated"))
        end

        task.spawn(function()
            ServerSimulator.RunServerSimulation(Emulator, DataModel)
        end)
    end
end

if RunService:IsStudio() then
    task.spawn(function()
        AutoSimulateServers()
    end)

    return GetEmulator() --// Returns a specific MessagingServiceEmulator and simulated DataModel, so that we can screen messages to not accidentally send to ourselves
else
    return MessagingService
end