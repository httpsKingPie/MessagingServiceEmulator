local module = {
    --// [Studio only]
    ["Debug Mode Publish"] = false, --// Outputs whenever a message is published (outputs the message dictionary)
    ["Debug Subscription"] = false, --// Outputs whenever a topic subscription/RBXScriptConnection goes live and whenever a message is received

    ["Failure Rate"] = 0, --// Percentage that messages are not received (this can be set to 0), to practice catching errors.  Remember: "Delivery is best effort and not guaranteed. Make sure to architect your experience so delivery failures are not critical." (https://create.roblox.com/docs/reference/engine/classes/MessagingService)

    ["Latency Lower Bound"] = 0.01, --// The fastest a message can be sent
    ["Latency Upper Bound"] = 0.45, --// The slowest a message can be sent

    ["Output Display Names"] = false, --// Provides an English name for display purposes only, to make it easier to track messages sent from various servers (vs scrutinizing pure hexadecimal UID strings)
    ["Output Topic Subscription"] = false, --// Outputs when a server subscribes to a given topic
    ["Output When Simulated Servers Are Created"] = true, --// Outputs via warning (for visual distinction, in case of print spam from other debug settings)
    
    ["Servers To Simulate"] = 0, --// Servers (excluding the actual one running) that MessagingServiceEmulator will simulate generation of

    ["Server Generation Time Lower Bound"] = 0.01, --// The shortest time a server can be generated (simulated)
    ["Server Generation Time Upper Bound"] = 0.75, --// The longest time a server can be generated (simulated)

    ["Wait Before Automatic Server Generation"] = 1, --// Once this time amount elapses, the server will begin auto generation of simulated servers.
}

return module