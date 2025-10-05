pcall(function()
local ok, hui = pcall(function() return gethui() end)
    if not ok or not hui then return end
    local imageButton = hui:FindFirstChild("ImageButton")
    if imageButton then
        imageButton:Destroy()
    else
        game:GetService("CoreGui"):FindFirstChild("ImageButton"):Destroy()
    end
    for i,v in pairs(gethui():GetChildren()) do
        if v.Name == "Cascade" then
        v:Destroy()
        end
    end
end)
print("Executor "..identifyexecutor())
if not game:IsLoaded() then repeat game.Loaded:Wait() until game:IsLoaded() end
getgenv().Config = {
    Save_Member = true
}
_G.Check_Save_Setting = "CheckSaveSetting"
getgenv()['JsonEncode'] = function(msg)
    return game:GetService("HttpService"):JSONEncode(msg)
end
getgenv()['JsonDecode'] = function(msg)
    return game:GetService("HttpService"):JSONDecode(msg)
end
getgenv()['Check_Setting'] = function(Name)
    if not _G.Dis then
        if not isfolder('Dynamic Hub') then
            makefolder('Dynamic Hub')
        end
        if not isfolder('Dynamic Hub/Build A Zoo') then
            makefolder('Dynamic Hub/Build A Zoo')
        end
        if not isfile('Dynamic Hub/Build A Zoo/'..Name..'.json') then
            writefile('Dynamic Hub/Build A Zoo/'..Name..'.json', JsonEncode(getgenv().Config))
        end
    end
end
getgenv()['Get_Setting'] = function(Name)
    if not _G.Dis then
        if isfolder('Dynamic Hub') and isfile('Dynamic Hub/Build A Zoo/'..Name..'.json') then
            getgenv().Config = JsonDecode(readfile('Dynamic Hub/Build A Zoo/'..Name..'.json'))
            return getgenv().Config
        else
            getgenv()['Check_Setting'](Name)
        end
    end
end
getgenv()['Update_Setting'] = function(Name)
    if not _G.Dis then
        if isfolder('Dynamic Hub') and isfile('Dynamic Hub/Build A Zoo/'..Name..'.json') then
            writefile('Dynamic Hub/Build A Zoo/'..Name..'.json', JsonEncode(getgenv().Config))
        else
            getgenv()['Check_Setting'](Name)
        end
    end
end
getgenv()['Check_Setting'](_G.Check_Save_Setting)
getgenv()['Get_Setting'](_G.Check_Save_Setting)
if getgenv().Config.Save_Member then
    getgenv()['MyName'] = game.Players.LocalPlayer.Name
elseif getgenv().Config.Save_All_Member then
    getgenv()['MyName'] = "AllMember"
else
    getgenv()['MyName'] = "None"
    _G.Dis = true
end
getgenv()['Check_Setting'](getgenv()['MyName'])
getgenv()['Get_Setting'](getgenv()['MyName'])
getgenv().Config.Key = _G.wl_key
getgenv()['Update_Setting'](getgenv()['MyName'])
local Config = getgenv().Config
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local vector = { create = function(x, y, z) return Vector3.new(x, y, z) end }
local LocalPlayer = Players.LocalPlayer
local selectedTypeSet = {}
local selectedMutationSet = {}
local selectedFruits = {}
local selectedFeedFruits = {}
local updateCustomUISelection
local settingsLoaded = false
local function waitForSettingsReady(extraDelay)
    while not settingsLoaded do
        task.wait(0.1)
    end
    if extraDelay and extraDelay > 0 then
        task.wait(extraDelay)
    end
end
local autoFeedToggle
function buyEggByUID(eggUID)
    local args = {
        "BuyEgg",
        eggUID
    }
    local ok, err = pcall(function()
        ReplicatedStorage:WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack(args))
    end)
    if not ok then
        warn("Failed to fire BuyEgg for UID " .. tostring(eggUID) .. ": " .. tostring(err))
    end
end
function focusEggByUID(eggUID)
    local args = {
        "Focus",
        eggUID
    }
    local ok, err = pcall(function()
        ReplicatedStorage:WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack(args))
    end)
    if not ok then
        warn("Failed to fire Focus for UID " .. tostring(eggUID) .. ": " .. tostring(err))
    end
end
local m = {}
spawn(function()
    while wait() do
        if Config["Auto Buy Eggs"] then
            pcall(function()
                local data = game:GetService("HttpService"):JSONDecode(readfile("Dynamic Hub/Build A Zoo/SelectedEggs.json"))
                local selectedTypeSet = data.eggs or {}
                local selectedMutationSet = data.mutations or {}

                for eggName,_ in pairs(selectedTypeSet) do
                    for _, eggObj in pairs(workspace.Art[game:GetService("Players").LocalPlayer:GetAttribute("AssignedIslandName")].ENV.Conveyor.Conveyor1.Belt:GetChildren()) do
                        if eggObj:GetAttribute("Type") == eggName then
                            if next(selectedMutationSet) then
                                for mutation,_ in pairs(selectedMutationSet) do
                                    if eggObj.RootPart["GUI/EeggGUI"].Mutate.Text == mutation then
                                        buyEggByUID(eggObj.Name)
                                    end
                                end
                            else
                                buyEggByUID(eggObj.Name) 
                            end
                        end
                    end
                end
            end)
        end
    end
end)
local player = game.Players.LocalPlayer
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
local function positionpet()
    local pospet = {}
    for _, v in pairs(workspace.Pets:GetChildren()) do
        if v:GetAttribute("UserId") == player.UserId then
            table.insert(pospet, v:GetPivot().Position)
        end
    end
    return pospet
end
local function positionegg()
    local posegg = {}
    for _, v in pairs(workspace.PlayerBuiltBlocks:GetChildren()) do
        if v:GetAttribute("UserId") == player.UserId then
            table.insert(posegg, v:GetPivot().Position)
        end
    end
    return posegg
end
spawn(function()
    while wait() do
        if Config["Auto Place Eggs"] then
            pcall(function()
                for _, farm in pairs(workspace.Art[player:GetAttribute("AssignedIslandName")]:GetChildren()) do
                    if farm.Name ~= "SA_FarmLocks" and string.find(farm.Name, "Farm_split") and not string.find(farm.Name, "WaterFarm_split") then
                        local farmPos = farm:GetPivot().Position
                        local nearPet, nearEgg = false, false
                        for _, petPos in pairs(positionpet()) do
                            local dist = (farmPos - petPos).Magnitude
                            if dist < 8 then
                                nearPet = true
                                break
                            end
                        end
                        for _, eggPos in pairs(positionegg()) do
                            local dist = (farmPos - eggPos).Magnitude
                            if dist < 6 then
                                nearEgg = true
                                break
                            end
                        end
                        if not nearPet and not nearEgg then
                            if not game.Players.LocalPlayer.Character:FindFirstChild("HandObj") then
--[[                                 for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg:GetChildren()) do
                                    focusEggByUID(v.Name)
                                end *]]
                                local block2ID = game:GetService("Players").LocalPlayer.PlayerGui.Overlay.ActionFrame.LST.BLOCKS["2"]:GetAttribute("ID")
                                if block2ID and string.find(block2ID, "Rob") then
                                    firesignal(game:GetService("Players").LocalPlayer.PlayerGui.Overlay.ActionFrame.LST.BLOCKS["3"].COL.MouseButton1Click)
                                    wait(0.1)
                                else
                                    firesignal(game:GetService("Players").LocalPlayer.PlayerGui.Overlay.ActionFrame.LST.BLOCKS["2"].COL.MouseButton1Click)
                                end
                            elseif game.Players.LocalPlayer.Character:FindFirstChild("HandObj") then
                                for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Overlay.ActionFrame.LST.BLOCKS:GetChildren()) do
                                    local args = {
                                        "Place",
                                        {
                                            DST = farmPos + Vector3.new(0, 4, 0),
                                            ID = v:GetAttribute("ID")
                                        }
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack(args))
                                    task.wait(.05)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)
spawn(function()
    while wait() do
        if Config["Auto Hatch Eggs"] then
            pcall(function()
                for _, v in pairs(workspace.PlayerBuiltBlocks:GetChildren()) do
                    if v:GetAttribute("UserId") == player.UserId then
                        if v.RootPart["GUI/HatchGUI"].Enabled == false then
                            v.RootPart.ProximityPrompt:SetAttribute("MaxActivationDistance", 10000000)
                            fireproximityprompt(v.RootPart.ProximityPrompt,100000000)
                        end
                    end
                end
            end)
        end
    end
end)
spawn(function()
    while wait() do
        if Config["Auto Claim Coins"] then
            pcall(function()
                for i,v in pairs(workspace.Pets:GetChildren()) do
                    if v:GetAttribute("UserId") == player.UserId then
                        local args = {
                            "Claim"
                        }
                        workspace:WaitForChild("Pets"):WaitForChild(v.Name):WaitForChild("RootPart"):WaitForChild("RE"):FireServer(unpack(args))
                    end
                end
            end)
        end
    end
end)
game:GetService("Players").LocalPlayer.PlayerGui.ScreenFoodStore.Enabled = true
task.wait(0.05)
game:GetService("Players").LocalPlayer.PlayerGui.ScreenFoodStore.Enabled = false
spawn(function()
    while task.wait(0.1) do
        if Config["Auto Buy Fruit"] then
            pcall(function()
                local data = game:GetService("HttpService"):JSONDecode(readfile("Dynamic Hub/Build A Zoo/SelectedFruit.json"))
                local selectedTypeSetf = data.fruit or {}
                for i,v in pairs(selectedTypeSetf)  do
                    local name_fruit = i
                    for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.ScreenFoodStore.Root.Frame.ScrollingFrame:GetChildren()) do
                        if v.Name == name_fruit then
                            local child_fruit = v
                            for i,v in pairs(child_fruit:GetChildren()) do
                                if v.Name == "ItemButton" then
                                    local stockNumber =  tonumber(v.StockLabel.Text:match("%d+")) ~= "0" and v.StockLabel.Text ~= "No Stock"
                                    if stockNumber then
                                        local args = {
                                            child_fruit.Name
                                        }
                                        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("FoodStoreRE"):FireServer(unpack(args))
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)
local function unlockTile(lockInfo)
    if not lockInfo then return false end
    local args = {
        "Unlock",
        lockInfo
    }
    local success = pcall(function()
        ReplicatedStorage:WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack(args))
    end)
    return success
end
spawn(function()
    while task.wait(0.1) do
        if Config["Auto Unlock Zone"] then
            pcall(function()
                for i,v in pairs(workspace.Art[game:GetService("Players").LocalPlayer:GetAttribute("AssignedIslandName")].ENV.Locks:GetChildren()) do
                    if v.Name ~= "SA_FarmLocks" then
                        if v.Farm.Transparency ~= 1 then
                            unlockTile(v.Farm)
                        end
                    end
                end
            end)
        end
    end
end)
spawn(function()
    while wait() do
        if Config["Auto Feed"] then
            pcall(function()
                local data = game:GetService("HttpService"):JSONDecode(readfile("Dynamic Hub/Build A Zoo/SelectedFeed.json"))
                local selectedTypeSetfeed = data.feeds or {}
                for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Overlay.ActionFrame.LST.BLOCKS:GetChildren()) do
                    if v:FindFirstChild("COL") then
                        local button = v.COL
                        local name_feed = v:GetAttribute("ID")
                        for i,v in pairs(selectedTypeSetfeed) do
                            if i == name_feed and button then
                            firesignal(button.MouseButton1Click)
                                for i,v in pairs(workspace.Pets:GetChildren()) do
                                    if v:GetAttribute("UserId") == game.Players.LocalPlayer.UserId then
                                        if v.RootPart:FindFirstChild("GUI/BigPetGUI") then
                                            if v.RootPart["GUI/BigPetGUI"].Feed.Visible ~= true then
                                                print(i,v)
                                                local args = {
                                                    "Feed",
                                                    v.Name
                                                }
                                                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PetRE"):FireServer(unpack(args))
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)
spawn(function()
    while wait() do
        if Config["Auto Upgrade Conveyor"] then
            pcall(function()
                for i = 1,10 do task.wait()
                    local args = {
                        "Upgrade",
                        i
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("ConveyorRE"):FireServer(unpack(args))
                end
            end)
        end
    end
end)
local bait_num
spawn(function()
    while wait() do
        if Config["Auto Fishing"] then
            pcall(function()
                if Config["Select Bait"] then
                    if Config["Select Bait"] == "Cheese Bait" then
                        bait_num = 1
                    elseif Config["Select Bait"] == "Fly Bait" then
                        bait_num = 2
                    elseif Config["Select Bait"] == "Fish Bait" then
                        bait_num = 3
                    end
                else
                    bait_num = 1
                end
                local args = {
                    "Throw",
                    {
                        Bait = "FishingBait"..bait_num,
                        Pos = vector.create(-220.4755401611328, 11, 429.5377197265625)
                    }
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("FishingRE"):FireServer(unpack(args))
                local args = {
                    "POUT",
                    {
                        SUC = 1
                    }
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("FishingRE"):FireServer(unpack(args))
            end)
        end
    end
end)
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
_G.Logo = 83452741766028
if game.CoreGui:FindFirstChild("ImageButton") then
    game.CoreGui:FindFirstChild("ImageButton"):Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")
local ClickSound = Instance.new("Sound")
local FlashFrame = Instance.new("Frame")
local UICorner2 = Instance.new("UICorner")
ScreenGui.Name = "ImageButton"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.120833337, 0, 0.0952890813, 0)
ImageButton.Size = UDim2.new(0, 55, 0, 53)
ImageButton.Draggable = true
ImageButton.Image = "http://www.roblox.com/asset/?id=" .. (_G.Logo)
UICorner.Parent = ImageButton
FlashFrame.Size = UDim2.new(0, 20, 0, 20)
FlashFrame.Position = UDim2.new(0, 0, 0, 0)
FlashFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FlashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FlashFrame.BackgroundTransparency = 1
FlashFrame.ZIndex = 2
FlashFrame.Parent = ImageButton
UICorner2.Parent = FlashFrame
UICorner2.CornerRadius = UDim.new(1, 10)
local function playClickFlash()
    local mousePos = Mouse.X, Mouse.Y
    local relX = (Mouse.X - ImageButton.AbsolutePosition.X) / ImageButton.AbsoluteSize.X
    local relY = (Mouse.Y - ImageButton.AbsolutePosition.Y) / ImageButton.AbsoluteSize.Y
    FlashFrame.Position = UDim2.new(relX, 0, relY, 0)
    FlashFrame.Size = UDim2.new(0, 20, 0, 20)
    FlashFrame.BackgroundTransparency = 0.3
    local TweenFlash = TweenService:Create(
        FlashFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1, Size = UDim2.new(1.8, 0, 1.8, 0)}
    )
    TweenFlash:Play()
end
ImageButton.MouseButton1Click:Connect(function()
    ClickSound:Play()
    playClickFlash()
    game:GetService("VirtualInputManager"):SendKeyEvent(true, "LeftAlt", false, game)
    game:GetService("VirtualInputManager"):SendKeyEvent(false, "LeftAlt", false, game)
end)
local cascade = loadstring(game:HttpGet("https://raw.githubusercontent.com/tun9811/wddaaadd3wfefeewgwee/refs/heads/main/AutoFarmtest.luau"))()
local EggSelection = loadstring(game:HttpGet("https://pastebin.com/raw/5iPKF6um"))()
local FruitSelection = loadstring(game:HttpGet("https://pastebin.com/raw/801CKrg6"))()
local FeedSelection = loadstring(game:HttpGet("https://pastebin.com/raw/hHNA74ig"))()
local userInputService = cloneref and cloneref(game:GetService("UserInputService")) or
game:GetService("UserInputService")
local minimizeKeybind = Enum.KeyCode.LeftAlt
local function titledRow(parent, title, subtitle) -- You can use this to automate the process of creating similar rows.
    local row = parent:Row({
        SearchIndex = title,
    })
    row:Left():TitleStack({
        Title = title,
        Subtitle = subtitle,
    })
    return row
end
local app = cascade.New({
    WindowPill = true,
    Theme = cascade.Themes.Light,
})
local window = app:Window({
    Title = "Dynamic Hub [ Build A Zoo ]",
    Subtitle = "Make By x2Livex",
    Size = userInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530),
})
userInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == minimizeKeybind and not gameProcessedEvent then
        window.Minimized = not window.Minimized
    end
end)
window.Destroying:Connect(function()
    pcall(function()
    local ok, hui = pcall(function() return gethui() end)
        if not ok or not hui then return end
        local imageButton = hui:FindFirstChild("ImageButton")
        if imageButton then
            imageButton:Destroy()
        else
            game:GetService("CoreGui"):FindFirstChild("ImageButton"):Destroy()
        end
        for i,v in pairs(gethui():GetChildren()) do
            if v.Name == "Cascade" then
            v:Destroy()
            end
        end
    end)
end)
window.Destroying:Connect(function()
    for i, v in pairs(Config) do
        if v == true or v == false and i ~= "Save_Member" then
            Config[i] = false
            _G[i] = false
        end
    end
end)
if not isfolder("Dynamic Hub") then makefolder("Dynamic Hub") end
if not isfolder("Dynamic Hub/Build A Zoo") then makefolder("Dynamic Hub/Build A Zoo") end
local eggSelectionVisible = true
local selectedTypeSet = {}
local selectedMutationSet = {}
if isfile("Dynamic Hub/Build A Zoo/SelectedEggs.json") then
    local data = game:GetService("HttpService"):JSONDecode(readfile("Dynamic Hub/Build A Zoo/SelectedEggs.json"))
    selectedTypeSet = data.eggs or {}
    selectedMutationSet = data.mutations or {}
end
local function onSelectionChanged(selectedItems)
    selectedTypeSet = {}
    selectedMutationSet = {}
    if selectedItems then
        for itemId, isSelected in pairs(selectedItems) do
            if EggSelection.EggData and EggSelection.EggData[itemId] then
                selectedTypeSet[itemId] = true
            elseif EggSelection.MutationData and EggSelection.MutationData[itemId] then
                selectedMutationSet[itemId] = true
            end
        end
    end
    writefile("Dynamic Hub/Build A Zoo/SelectedEggs.json", game:GetService("HttpService"):JSONEncode({
        eggs = selectedTypeSet,
        mutations = selectedMutationSet
    }))
end
local selectedTypeSetf = {}
if isfile("Dynamic Hub/Build A Zoo/SelectedFruit.json") then
    local data = game:GetService("HttpService"):JSONDecode(readfile("Dynamic Hub/Build A Zoo/SelectedFruit.json"))
    selectedTypeSetf = data.fruit or {}
end
local function onSelectionChangedF(selectedItems)
    selectedTypeSetf = {}
    if selectedItems then
        for itemId, isSelected in pairs(selectedItems) do
            if FruitSelection.EggData and FruitSelection.EggData[itemId] then
                selectedTypeSetf[itemId] = true
            end
        end
    end
    writefile("Dynamic Hub/Build A Zoo/SelectedFruit.json", game:GetService("HttpService"):JSONEncode({
        fruit = selectedTypeSetf,
    }))
end
local selectedTypeSetfeed = {}
if isfile("Dynamic Hub/Build A Zoo/SelectedFeed.json") then
    local data = game:GetService("HttpService"):JSONDecode(readfile("Dynamic Hub/Build A Zoo/SelectedFeed.json"))
    selectedTypeSetfeed = data.feeds or {}
end
local function onSelectionChangedFeed(selectedItems)
    selectedTypeSetfeed = {}
    if selectedItems then
        for itemId, isSelected in pairs(selectedItems) do
            if FeedSelection.feeds and FeedSelection.feeds[itemId] then
                selectedTypeSetfeed[itemId] = true
            end
        end
    end
    writefile("Dynamic Hub/Build A Zoo/SelectedFruit.json", game:GetService("HttpService"):JSONEncode({
        feeds = selectedTypeSetfeed,
    }))
end
local Tabs = { 
    General = window:Tab({Selected = true, Title = "General", Icon = cascade.Symbols.house }),
    Eggs = window:Tab({Title = "Eggs", Icon = cascade.Symbols.hexagon }),
    Fishing_Zone = window:Tab({Title = "Fishing Zone", Icon = cascade.Symbols.fish }),
    Shop = window:Tab({Title = "Shop", Icon = cascade.Symbols.cart }),
    Window = window:Tab({Title = "Window", Icon = cascade.Symbols.sidebarLeft }),
}
form = Tabs.General:PageSection({ Title = "Coins" }):Form()
row = titledRow(form, "Auto Claim Coins","Create a row in the form titled Auto Claim with a description under the title that says Auto Claim.")
row:Right():Toggle({
    Value = Config["Auto Claim Coins"] or false,
    ValueChanged = function(self, value)
        Config["Auto Claim Coins"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
form = Tabs.General:PageSection({ Title = "Zone" }):Form()
row = titledRow(form, "Auto Unlock Zone","Automatically unlocks new zones when the player has enough money or meets the required conditions. The system will open the zone instantly without manual action.")
row:Right():Toggle({
    Value = Config["Auto Unlock Zone"] or false,
    ValueChanged = function(self, value)
        Config["Auto Unlock Zone"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
form = Tabs.General:PageSection({ Title = "Conveyor" }):Form()
row = titledRow(form, "Auto Upgrade Conveyor","Automatically upgrades the conveyor when resources are sufficient.")
row:Right():Toggle({
    Value = Config["Auto Upgrade Conveyor"] or false,
    ValueChanged = function(self, value)
        Config["Auto Upgrade Conveyor"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
feedSelectionVisible = false
form = Tabs.General:PageSection({ Title = "Feed" }):Form()
local row = titledRow(form, "Open Food Selection UI","Opens a window to select which type of food to auto-use.")
row:Right():Button({
    Label = "Click here!",
    State = "Primary",
    Pushed = function(self)
        if feedSelectionVisible then
            FeedSelection.Hide()
            feedSelectionVisible = false
        else
            FeedSelection.Show(
                onSelectionChangedFeed,
                function(isVisible)
                    feedSelectionVisible = isVisible
                end,
                selectedTypeSetfeed
            )
            feedSelectionVisible = true
        end
    end,
})
row = titledRow(form, "Auto Feed","Automatically feeds your animals with the selected feed type without manual input.")
row:Right():Toggle({
    Value = Config["Auto Feed"] or false,
    ValueChanged = function(self, value)
        Config["Auto Feed"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
eggSelectionVisible = false
form = Tabs.Eggs:PageSection({ Title = "Buy Eggs" }):Form()
local row = titledRow(form, "Open Egg Selection UI","Open the modern glass-style egg selection interface")
row:Right():Button({
    Label = "Click here!",
    State = "Primary",
    Pushed = function(self)
        if eggSelectionVisible then
            EggSelection.Hide()
            eggSelectionVisible = false
        else
            EggSelection.Show(
                onSelectionChanged,
                function(isVisible)
                    eggSelectionVisible = isVisible
                end,
                selectedTypeSet,
                selectedMutationSet
            )
            eggSelectionVisible = true
        end
    end,
})
row = titledRow(form, "Auto Buy Eggs","Instantly buys eggs as soon as they appear on the conveyor belt!")
row:Right():Toggle({
    Value = Config["Auto Buy Eggs"] or false,
    ValueChanged = function(self, value)
        Config["Auto Buy Eggs"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
form = Tabs.Eggs:PageSection({ Title = "Place Eggs" }):Form()
row = titledRow(form, "Auto Place Eggs","Create a row in the form titled Auto Place Eggs with a description under the title that says Auto Place Eggs.")
row:Right():Toggle({
    Value = Config["Auto Place Eggs"] or false,
    ValueChanged = function(self, value)
        Config["Auto Place Eggs"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
form = Tabs.Eggs:PageSection({ Title = "Hatch Eggs" }):Form()
row = titledRow(form, "Auto Hatch Eggs","Create a row in the form titled Auto Hatch Eggs with a description under the title that says Auto Hatch Eggs.")
row:Right():Toggle({
    Value = Config["Auto Hatch Eggs"] or false,
    ValueChanged = function(self, value)
        Config["Auto Hatch Eggs"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
form = Tabs.Fishing_Zone:PageSection({ Title = "Fishing" }):Form()
row = titledRow(form, "Select Bait","Choose the bait for fishing")
local pullDownButton = row:Right():PullDownButton({
    Options = { "Cheese Bait", "Fly Bait", "Fish Bait" },
    Multi = false,
    Selected = "Select Bait",
    ValueLabel = 1,
        Value = (function()
        for i, v in ipairs({ "Cheese Bait", "Fly Bait", "Fish Bait" }) do
            if v == Config["Select Bait"] then
                return i
            end
        end
        return 1
    end)(),
    ValueChanged = function(self, value)
        local names = self.Selected
        if self.Multi then
            if self.ValueLabel == 1 then
                _G["selected" .. names] = {}
                for _, i in ipairs(value) do
                    table.insert(_G["selected" .. names], self.Options[i])
                end
                if #_G["selected" .. names] == 0 then
                    self.Label = "N/A"
                elseif #_G["selected" .. names] == 1 then
                    self.Label = _G["selected" .. names][1]
                else
                    self.Label = _G["selected" .. names][1] .. ", ..."
                end
            else
                _G["selected" .. names] = {}
                for _, i in ipairs(value) do
                    table.insert(_G["selected" .. names], self.Options[i])
                end
                if #_G["selected" .. names] == 0 then
                    self.Label = "N/A"
                else
                    self.Label = table.concat(_G["selected" .. names], ", ")
                end
            end
        else
            self.Label = self.Options[value] or "N/A"
        end
        Config["Select Bait"] = self.Options[value]
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
row = titledRow(form, "Auto Fishing","Automatically fishes using the selected bait without manual input")
row:Right():Toggle({
    Value = Config["Auto Fishing"] or false,
    ValueChanged = function(self, value)
        Config["Auto Fishing"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
local row = titledRow(form, "Unlock Zone")
row:Right():Button({
    Label = "Click here!",
    State = "Primary",
    Pushed = function(self)
        local args = {
            "UnlockFish"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("FishingRE"):FireServer(unpack(args))
    end,
})
fruitSelectionVisible = false
form = Tabs.Shop:PageSection({ Title = "Buy Fruit" }):Form()
local row = titledRow(form, "Open Fruit Selection UI","Opens the interface to select Devil Fruits for use or farming.")
row:Right():Button({
    Label = "Click here!",
    State = "Primary",
    Pushed = function(self)
        if fruitSelectionVisible then
            FruitSelection.Hide()
            fruitSelectionVisible = false
        else
            FruitSelection.Show(
                onSelectionChangedF,
                function(isVisible)
                    fruitSelectionVisible = isVisible
                end,
                selectedTypeSetf
            )
            fruitSelectionVisible = true
        end
    end,
})
row = titledRow(form, "Auto Buy Fruit","Instantly buys eggs as soon as they appear on the conveyor belt!")
row:Right():Toggle({
    Value = Config["Auto Buy Fruit"] or false,
    ValueChanged = function(self, value)
        Config["Auto Buy Fruit"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
local form = Tabs.Window:PageSection({ Title = "Appearance" }):Form()
local row = titledRow(
    form,
    "Dark mode",
    "An application appearance setting that uses a dark color palette to provide a comfortable viewing experience tailored for low-light environments."
)
row:Right():Toggle({
    Value = true,
    ValueChanged = function(self, value)
        app.Theme = value and cascade.Themes.Dark or cascade.Themes.Light
    end,
})
form = Tabs.Window:PageSection({ Title = "Advanced Settings" }):Form()
local row = form:Row({
    SearchIndex = "FPS",
})
local BT_D = row:Left():TitleStack({
    Title = "FPS",
})
spawn(function()
    while task.wait() do
        pcall(function()
            BT_D.Title = "FPS " .. "( " .. tostring(Config["FPS"]) .. " )"
        end)
    end
end)
row:Right():Slider({
    Minimum = 1,
    Maximum = 240,
    Value = Config["FPS"] or 60,
    ValueChanged = function(self, value)
    local num = tonumber(value)
        if num then
            num = math.floor(num)
            Config["FPS"] = num
            getgenv()['Update_Setting'](getgenv()['MyName'])
        end
    end,
})
row = titledRow(
    form,
    "FPS Look"
)
row:Right():Toggle({
    Value = Config["FPS Look"] or false,
    ValueChanged = function(self, value)
        Config["FPS Look"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
spawn(function()
    while task.wait() do
        if Config["FPS Look"] then
            pcall(function()
                setfpscap(Config["FPS"])
            end)
        else
            setfpscap(9999)
        end
    end
end)
row = titledRow(
    form,
    "Reset UI Size"
)
row:Right():Button({
    Label = "Click here!",
    State = "Primary",
    Pushed = function(self)
        window.Size = userInputService.TouchEnabled and UDim2.fromOffset(550, 325) or UDim2.fromOffset(850, 530)
    end,
})
row = titledRow(
    form,
    "Auto Hide UI"
)
row:Right():Toggle({
    Value = Config["Auto Hide UI"] or false,
    ValueChanged = function(self, value)
        Config["Auto Hide UI"] = value
        getgenv()['Update_Setting'](getgenv()['MyName'])
    end,
})
local form = Tabs.Window:PageSection({ Title = "Input" }):Form()
local row = titledRow(form, "Minimize shortcut")
row:Right():KeybindField({
    Value = minimizeKeybind,
    ValueChanged = function(self, value)
        minimizeKeybind = value
    end,
})
local row = titledRow(
    form,
    "Searchable",
    "Allows users to search for content in a page with a search-field in the titlebar."
)
row:Right():Toggle({
    Value = window.Searching,
    ValueChanged = function(self, value)
        window.Searching = value
    end,
})
local row = titledRow(form, "Draggable", "Allows users to move the window with a mouse or touch device.")
row:Right():Toggle({
    Value = window.Draggable,
    ValueChanged = function(self, value)
        window.Draggable = value
    end,
})
local row =
    titledRow(form, "Resizable", "Allows users to resize the window with a mouse or touch device.")
row:Right():Toggle({
    Value = window.Resizable,
    ValueChanged = function(self, value)
        window.Resizable = value
    end,
})
local form = Tabs.Window:PageSection({
    Title = "Effects",
    Subtitle = "These effects may be resource intensive across different systems.",
}):Form()
local row = titledRow(form, "Dropshadow", "Enables a dropshadow effect on the window.")
row:Right():Toggle({
    Value = window.Dropshadow,
    ValueChanged = function(self, value)
        window.Dropshadow = value
    end,
})
local row = titledRow(
    form,
    "Background blur",
    "Enables a UI background blur effect on the window. This can be detectable in some games."
)
row:Right():Toggle({
    Value = window.UIBlur,
    ValueChanged = function(self, value)
        window.UIBlur = value
    end,
})
