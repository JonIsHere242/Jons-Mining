local QBCore = exports['qb-core']:GetCoreObject()
local RockTable = {}

local quarry = vector3(2947.0, 2790.0, 48.0)

local stones = {
    [1]  = "lightstone",
    [2]  = "normalstone",
    [3]  = "heavystone",
}

Citizen.CreateThread(function()
    for i = 1, Config.NumberOfRocks do
        Citizen.Wait(1)
        math.randomseed(GetGameTimer()- math.random(1, 300))
        --get the quarry coords
        local x = math.random(quarry.x - Config.RockSpawningYYY, quarry.x + Config.RockSpawningYYY)
        local y = math.random(quarry.y - Config.RockSpawningXXX, quarry.y + Config.RockSpawningXXX)
        local z = quarry.z+15

        RockHealth = math.random(200, 300)

        for j = 1, #RockTable do
            if y > RockTable[j].coords.y - Config.MinimumSpaceBetweenRocks and y < RockTable[j].coords.y + Config.MinimumSpaceBetweenRocks then
                y = math.random(quarry.y - Config.RockSpawningYYY, quarry.y + Config.RockSpawningYYY)
            end
        end

        for j = 1, #RockTable do
            if x > RockTable[j].coords.x - Config.MinimumSpaceBetweenRocks and x < RockTable[j].coords.x + Config.MinimumSpaceBetweenRocks then
                x = math.random(quarry.x - Config.RockSpawningXXX, quarry.x + Config.RockSpawningXXX)
            end
        end

        table.insert(RockTable, {
            hash = Config.RockHashes[math.random(1, #Config.RockHashes)],
            coords = vector3(x, y, z),
            heading = math.random(0, 360),
            health = RockHealth,
            maxHealth = RockHealth,
            rockEntity = nil,
        })
    end

    -------LOGO Needs to be moved into its own thing later but here is fine for now
    print(" _  ___                        ____                            _____  _____  ")
    print("| |/ (_)                ___   / __ \\                          |  __ \\|  __ \\ ")
    print("| ' / _ _ __   __ _ ___( _ ) | |  | |_   _  ___  ___ _ __  ___| |__) | |__) |")
    print("|  < | | '_ \\ / _` |_  / _ \\/\\ |  | | | | |/ _ \\/ _ \\ '_ \\/ __|  _  /|  ___/ ")
    print("| . \\| | | | | (_| |/ / (_>  < |__| | |_| |  __/  __/ | | \\__ \\ | \\ \\| |     ")
    print("|_|\\_\\_|_| |_|\\__, /___\\___/\\/\\___\\_\\ __,_|\\___|\\___|_| |_|___/_|  \\_\\_|     ")
    print("               __/ |                                                         ")
    print("              |___/                                                          ")
end)

RegisterNetEvent('rock:server:RequestRockTable')
AddEventHandler('rock:server:RequestRockTable', function()
    local src = source
    print("sending rock table to client")
    TriggerClientEvent("rock:client:RockTable", src, RockTable)
end)

--Smelter / Item Stuff


RegisterNetEvent("rock:server:RemoveRockFromRockTable")
AddEventHandler("rock:server:RemoveRockFromRockTable", function()
    local src = source


end)





RegisterNetEvent("rock:server:ReduceJerrycanHealth")
AddEventHandler("rock:server:ReduceJerrycanHealth", function()
    print("reducing jerrycan health")
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local jerrycan = Player.Functions.GetItemByName("weapon_petrolcan")
    local newHealth = jerrycan.info.quality - 10
    print(newHealth)
    if newHealth <= 0 then
        Player.Functions.RemoveItem(jerrycan.name, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[jerrycan.name], "remove")
    else
        Player.Functions.SetMetaData(jerrycan, jerrycan.info.quality - 10)
        print("new jerrycan health = " .. newHealth)
    end
end)

RegisterNetEvent("mining:server:breaktool", function(tool)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    print('player #' .. src .. " used " .. tool)
    Player.Functions.RemoveItem(tool, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[tool], "remove")
end)

RegisterNetEvent("mining:server:giveitem", function(stone)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    print("player #" ..src .. " got " .. Config.Stones[stone].item)
   
    Player.Functions.AddItem(Config.Stones[stone].item, 1)
    TriggerClientEvent('mining:client:miningEffects', src)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Stones[stone].item], "add")
end)

RegisterNetEvent("mining:server:giveore", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ore = math.random(1, #Config.Ores)

    for i = 1, #stones do
        local stone = Player.Functions.GetItemByName(stones[i])
        if stone ~= nil and stone.amount >= 1 then
            CurrentStone = Player.Functions.GetItemByName(stone.name)
            Player.Functions.RemoveItem(CurrentStone.name, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, CurrentStone, "remove")
            
            oreSpawn(i,Player,src)
            break

        end
        if i == #stones then
            TriggerClientEvent('QBCore:Notify', src, "You need to have a stone to crush", "error")
        end
    end
end)

function oreSpawn(StoneType,Player,src)
    local ore = math.random(1, #Config.Ores)

    if StoneType == 0 then
      print("stone type 0")

    elseif StoneType == 1 then
        print("stone type 1")
    
        ore = math.random(1, #Config.LightOres)
        print("player got " .. Config.LightOres[ore])
        Player.Functions.AddItem(Config.LightOres[ore], 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LightOres[ore]], "add")
    
    elseif StoneType == 2 then
        ore = math.random(1, #Config.NormalOres)
        print("player got " .. Config.NormalOres[ore])
        Player.Functions.AddItem(Config.NormalOres[ore], 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.NormalOres[ore]], "add")
    
    elseif StoneType == 3 then
        ore = math.random(1, #Config.HeavyOres)
        ore = ore -math.random(0, 7)
        
        if ore < 1 then
            ore = math.random(1, 3)
        end
        
        if ore < 3 then
            ore = math.random(2, #Config.NormalOres)
            print("player got " .. Config.Ores[ore].item)
            Player.Functions.AddItem(Config.Ores[ore].item, math.random(1, 2))
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Ores[ore].item], "add")
    
        else
            print("player got " .. Config.HeavyOres[ore])
            Player.Functions.AddItem(Config.HeavyOres[ore], 1)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.HeavyOres[ore]], "add")
        end
        print(ore)
    end
end

RegisterNetEvent("server:mining:SyncCrusherHealth", function(crusher, health)
    while true do 
        Citizen.Wait(1000)
        if health <= 0 then
            TriggerClientEvent("mining:client:syncCrusherHealth", -1, crusher, 0)
            break
        end
        health = health - 1
        TriggerClientEvent("mining:client:syncCrusherHealth", -1, crusher, health)
    end
end)

RegisterNetEvent("server:rock:syncHealth", function(rock, health, typeoftool, CurrentRockHash)
    if typeoftool == nil then healthreduction = 1 end
    if typeoftool == "jackhammer" then 
        healthreduction = 2
    end

    newhealth = health - healthreduction
    TriggerClientEvent("rock:client:syncHeath", -1, rock, newhealth, CurrentRockHash)
end)
