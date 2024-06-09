--[[
    Notes on server simulation:

    This is designed to help you test your MessagingService uses in a less hacky way (e.g., using two laptops).  However, please be aware of the following:
        Roblox environment still affects your module requires - I cannot change that.
            E.g., modules require once (in a way that executes the code) per environment (server or client).  Requiring a module here (on the server) will only excute the code once, so please keep that in mind and use functions/methods instead
        Utilize randomization to best replicate dynamic server behavior
]]

local MessagingServiceEmulatorModule = script.Parent

local module = {}

function module.RunServerSimulation(MessagingService: table, SimulatedDataModel)
    local game: DataModel = SimulatedDataModel --// Returns a DataModel simulation with a JobId that you can use in Studio.  Preserves all other properties and methods, so use as a 1:1 replacement of the global 'game'

    --// Dump your server simulation code here
    
    --[[
        Example code:

        MessagingServiceEmulator:SubscribeAsync("Test", function(Message: table)
            print(game.JobId, "simulated server received", Message.Data) --> as servers are automatically generated, they will all begin outputting their receipt of the message with simulated server/game JobId
        end)

        MessagingServiceEmulator:PublishAsync("Test", "New server created by " .. game.JobId .. " - look at my server/JobId in studio!")
    ]]
end

return module