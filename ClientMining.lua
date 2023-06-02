
--get qbcore object and set it to QBCore
QBCore = exports['qb-core']:GetCoreObject()

local rocks = {}
local crushers = {}
local hasjerrycan = false
local DevMode = true
local SpawnedProps = false



local function round(num)
    return num + (2^52 + 2^51) - (2^52 + 2^51)
end

----------- Getting The Rock Table From The Server --------------

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Citizen.Wait(10000)    
    CreateCrushers()
    --TriggerServerEvent('rock:server:RequestRockTable')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    CreateCrushers()
    



    --TriggerServerEvent('rock:server:RequestRockTable')
end)

RegisterNetEvent('rock:client:RockTable')
AddEventHandler('rock:client:RockTable', function(RockTable)
    print("recieved rock table from server creating them now")
    CreateCrushers()
    PlaceRock(RockTable)
end)

Citizen.CreateThread(function()
    print("Main mining thread created")
    while true do
        Citizen.Wait(10000)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local quarry = vector3(2947.0, 2790.0, 48.0)
        local distance = #(playerCoords - quarry)

        if distance > 1000 then
            Citizen.Wait(12000)
        end

        if distance < 150 then
            if SpawnedProps == false then
                print("player is close to quarry and props have not been spawned yet")
                TriggerServerEvent('rock:server:RequestRockTable')
                SpawnedProps = true
                break
            end
        end
    end
end)

----- Spawning ROCKS -----

function PlaceRock(RockTable)
    for i, rock in ipairs(RockTable) do
        local hash = rock.hash
        local coords = rock.coords
        local heading = rock.heading
        local health = rock.health
        local maxHealth = rock.maxHealth
        local RockEntity = rock.rockEntity
        groundZBool, GroundZint  = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, 0)
        print("ground z bool is " .. groundZBool .. " and ground z int is " .. GroundZint)

        if groundZBool == 1 and GroundZint > 5  then
            local UpdatedGroundCoords = vector4(coords.x, coords.y, GroundZint - 0.5, heading)
            RequestModel(hash)

            while HasModelLoaded(hash) == 0 do
                print('waiting on rock model to load, possible connection issue')
            end
            
            if DoesEntityExist(RockTable[i].rockEntity) == false then
                if DoesObjectOfTypeExistAtCoords(UpdatedGroundCoords.x, UpdatedGroundCoords.y, UpdatedGroundCoords.z, 3.0, hash, 0) == true then
                    print('rock already exists')
                    break
                else

                    local CreatedRock = CreateObject(hash, UpdatedGroundCoords.x, UpdatedGroundCoords.y, UpdatedGroundCoords.z, false, true, false)
                    Citizen.Wait(10)
                    rocks[#rocks + 1] = CreatedRock
                    SetEntityHeading(CreatedRock, UpdatedGroundCoords.w)
                    SetEntityAsMissionEntity(CreatedRock, true, true)
                    SetEntityCanBeDamaged(CreatedRock,true)
                    SetEntityOnlyDamagedByPlayer(CreatedRock, true)
                    SetEntityHealth(CreatedRock, health)
                    SetEntityProofs(CreatedRock , false , true , false , true , true , true , 1 , true )
                    FreezeEntityPosition(CreatedRock, true)
                    RockTable[i].rockEntity = CreatedRock

                    if DoesEntityExist(RockTable[i].rockEntity) == 1 then
                        print(i .. ' rock created')
                    else 
                        print( i .. ' rock did not generate a valid vector3')

                    end
                end
            elseif DoesEntityExist(RockEntity) == true then
                print('rock already exists')
            end
        
        end
    end
end

function CreateCrushers()
    -----------------Create Crushers ---------------------
    for i,v in pairs(Config.CrusherProps) do 
        RequestModel(v.Hash)
        while HasModelLoaded(v.Hash) == 0 do
            Wait(100)    
            print('waiting on rock model to load, possible connection issue')
        end
 
        if DoesObjectOfTypeExistAtCoords(GetEntityCoords(crushers[i]), 1.0, v.Hash, 0) then 
            print("testing new rock already spawned")
        end



        if DoesEntityExist(crushers[i]) == true then 
            print('rock already exists')
        elseif HasModelLoaded(v.Hash) == 1 then
 
            if DoesEntityExist(crushers[i]) == false then
                local crusher = CreateObject(v.Hash, v.position.x, v.position.y, v.position.z, false, true, false)
                crushers[#crushers + 1] = crusher
                -----------------Create Crushers ---------------------
                SetEntityAsMissionEntity(crushers[i], false, false)
                SetEntityCanBeDamaged(crushers[i],true)
                SetEntityOnlyDamagedByPlayer(crushers[i], true)
                SetEntityHealth(crushers[i], v.Health)
                SetEntityProofs(crushers[i] , false , true , false , true , true , true , 1 , true )
                FreezeEntityPosition(crushers[i], true)
            else
                print('crusher already exists or model failed to load')
            end
        end
    end
end



Citizen.CreateThread(function()
    while true do 
        Wait(10)
        --get player ped
        local ped = PlayerPedId()
        --get player coords
        local Playercoords = GetEntityCoords(ped)
        local distance = #(Playercoords - vector3(2685.5308, 2804.3042, 40.2446))
        if distance > 100 then 
            Wait(3000)
        end
        

        if GetCurrentPedWeapon(ped, 883325847) then 
            hasjerrycan = true
        else 
            hasjerrycan = false
        end

        -- in pairs loop through all the rocks
        
        for i,v in pairs(crushers) do 
            local CrusherCoords = GetEntityCoords(crushers[i])
           
            
            if GetEntityType(crushers[i]) == 3 then

                
                exports['qb-target']:AddTargetEntity(crushers[i], {
                    options = {
                        {
                            type = "client",
                            event = "mining:client:fuelingprocess",
                            icon = "fas fa-box-circle-check",
                            label = "Fuel Crusher",
                            entitycoords = CrusherCoords,
                            hasfuel = hasjerrycan,
                            entity = crushers[i],
                        },
                        
                    },
                    distance = 3.0
                })
                --remove teh qbtarget if crusher has fuel
                if GetEntityHealth(crushers[i]) == 0 then
                    exports['qb-target']:RemoveTargetEntity(crushers[i])
                end

                if GetEntityHealth(crushers[i]) > 0 then
                    exports['qb-target']:AddTargetEntity(crushers[i], {
                        options = {
                            {
                                type = "client",
                                event = "mining:client:crushstone",
                                icon = "fas fa-box-circle-check",
                                label = "Smash Small Stone",
                                item = "lightstone",
                                entitycoords = CrusherCoords,
                                hasfuel = hasjerrycan,
                                entity = crushers[i],
                            },
                            {
                                type = "client",
                                event = "mining:client:crushstone",
                                icon = "fas fa-box-circle-check",
                                label = "Crush Stone",
                                item = "normalstone",
                                entitycoords = CrusherCoords,
                                hasfuel = hasjerrycan,
                                entity = crushers[i],
                            },
                            {
                                type = "client",
                                event = "mining:client:crushstone",
                                icon = "fas fa-box-circle-check",
                                label = "Destroy Bolder",
                                item = "heavystone",
                                entitycoords = CrusherCoords,
                                hasfuel = hasjerrycan,
                                entity = crushers[i],
                            },
                        },
                        distance = 4.5
                    })
                end
            end
        end

        if distance < 300 then
            for i,v in pairs(Config.CrusherHashes) do 
                local ClosestCrusher = GetClosestObjectOfType(Playercoords, 10.0, GetHashKey(v), false, true, true)
                if DoesEntityExist(ClosestCrusher) then
                    local CrusherCoords = GetEntityCoords(ClosestCrusher)
                    --get the distance between the player and the closest Crusher
                    local CrusherDistance = #(Playercoords - CrusherCoords)
                
                end
            end
        end
    end
end)


RegisterNetEvent("mining:client:crushstone", function(data)
    print("crush stone event")
    TriggerServerEvent("mining:server:giveore")
end)

RegisterNetEvent("mining:client:fuelingprocess", function(data)
    ---ADD fuling animation here along with facing the player towards the rock 



    --get if the player has a jerrycan currently selected
    if data.hasfuel == nil then 
        QBCore.Functions.Notify("Jerrycan = nil wtf?", "error")
    end

    
    if data.hasfuel then 
        print("has jerrycan")
        hasjerrycan = true
        local CrusherHealth = GetEntityHealth(data.entity)
        local crusherToFuel = data.entity
        

        for i = 1, #crushers, 1 do
            local crusherdiffrence = GetEntityCoords(crushers[i]) - GetEntityCoords(crusherToFuel) 
            local CrusherDiffSummed = crusherdiffrence.x+crusherdiffrence.y+crusherdiffrence.z
            if round(CrusherDiffSummed) == 0 then
                
                local PlayerPed = PlayerPedId()
                RequestAnimDict("weapon@w_sp_jerrycan")
                TaskTurnPedToFaceEntity(PlayerPed, crushers[i], 500)
                Citizen.Wait(500)

                
               
                local volumeOfFuelSound= 0.2
                waterSound = {
                    [1] = "https://www.youtube.com/watch?v=JoojjU827ZA&ab_channel=AudioStock",
                    [2] = 'https://www.youtube.com/watch?v=DUzT3KTA_Rc&ab_channel=AudioStock',
                    [3] = 'https://www.youtube.com/watch?v=TuCqJdhiEA0&ab_channel=SoundEffects%2810Hours%29',
                    [4] = 'https://www.youtube.com/watch?v=9tl1aVnFWaE&ab_channel=SoothingScenes'

                }
                waterurlvar = math.random(1,4)
                local FuelingUrl = waterSound[waterurlvar]
                local pos = GetEntityCoords(PlayerPed)
                local FuelingSound = "fuelcrusher"
                --["export"]PlayUrlPos(id ,"http://relisoft.cz/assets/brainleft.mp3",1,pos)
                exports['xsound']:PlayUrlPos(FuelingSound ,FuelingUrl,volumeOfFuelSound,pos)
                exports['xsound']:fadeIn(FuelingSound, 100, 0.2)

                


                TaskPlayAnim(PlayerPed, "weapon@w_sp_jerrycan", "fire", 8.0, 1.0, -1, 1, 0, 0, 0, 0 )
                
                QBCore.Functions.Progressbar("refuel-crusher", "Refueling", 10000, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                    }, {}, {}, {}, function() -- Done
            
                    SetPedAmmo(PlayerPed, 883325847, 4500)
                    QBCore.Functions.Notify("Refuled Crusher", "sucess")
                    local CrusherHealth = GetEntityHealth(crushers[i])
                    local CrusherHealthUpdated = CrusherHealth+Config.CrusherFuelTime
                    TriggerServerEvent('server:mining:SyncCrusherHealth', i, CrusherHealthUpdated)
                    exports['xsound']:fadeOut(FuelingSound, 100, 0.2)
                    StopAnimTask(PlayerPed, "weapon@w_sp_jerrycan", "fire", 3.0, 3.0, -1, 2, 0, 0, 0, 0)


                    --TRIGGER SERVER EVENT HERE TO REDUCE JERRYCAN AMMO
                    --TriggerServerEvent("rock:server:ReduceJerrycanHealth")

                end, function() -- Cancel
                    exports['xsound']:fadeOut(FuelingSound, 500, 0.2)
                    QBCore.Functions.Notify("Refueling Canceled", "error")
                    StopAnimTask(PlayerPed, "weapon@w_sp_jerrycan", "fire", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
                end)
            end
        end
    elseif not data.hasfuel then
        QBCore.Functions.Notify("You need a jarry can to fuel", "error")
    end
end)

-----------------------------------------------------------------------------------------

function OreSpawn(health, typeoftool)
	math.randomseed(GetGameTimer())
    local ore = math.random(1, #Config.Stones)

    if typeoftool == "jackhammer" then 
        health = health+10
    elseif typeoftool == "shovel" then
        health = health+1
    end

    if health > Config.Stones[ore].healthrequirement then
        local item = QBCore.Shared.Items[Config.Stones[ore].item]
        TriggerServerEvent('mining:server:giveitem', ore)
       
    elseif health < Config.Stones[ore].healthrequirement then
        ore = ore-1
        if ore == 0 then
            ore = 1
        end
        local item = QBCore.Shared.Items[Config.Stones[ore].item]
        TriggerServerEvent('mining:server:giveitem', ore)
       
    elseif health < Config.Stones[ore].healthrequirement then
        QBCore.Functions.Notify('You got nothing', 'error')
    end
end

function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(1)
	end
end

function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end
end

function MineRock(ClosestRock) 
    local ped = PlayerPedId()
    local PlayerLocation = GetEntityCoords(GetPlayerPed(-1))

    ------super expensive native use sparingly

    if IsEntityOnScreen(ClosestRock) then
        if HasEntityClearLosToEntityInFront(ped, ClosestRock) == false then

            TaskTurnPedToFaceEntity(ped, ClosestRock, 1000)
            Citizen.Wait(500)
            local health = GetEntityHealth(ClosestRock)
    
            for i = 1, #rocks, 1 do
                local rockdiffrence = GetEntityCoords(rocks[i]) - GetEntityCoords(ClosestRock) 
                local rockDiffSummed = rockdiffrence.x+rockdiffrence.y+rockdiffrence.z
                if round(rockDiffSummed) == 0 then
                    
                    QBCore.Functions.Progressbar("jackhammer", "Mining Stone...", math.random(1000, 5000), false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "amb@world_human_const_drill@male@drill@base",
                        anim = "base",
                        flags = 49,
                        task = nil,
    
                    }, {
                        model = "prop_tool_jackham",
                        bone = 57005,
                        coords = { x = 0.15, y = 0.25, z = 0.0 },
                        rotation = { x = 90.0, y = 15.0, z = 260.0 },
                    }, {}, function() -- Done
                        
                        local typeoftool = 'jackhammer'
                        
                        local CurrentRockHash = GetHashKey(ClosestRock)
                        TriggerServerEvent("server:rock:syncHealth", i, health, typeoftool, CurrentRockHash)
                        OreSpawn(health, typeoftool)
                    end, function() -- Cancel
                        QBCore.Functions.Notify('Mining canceled', 'error')
                    end)
                end
            end
        end
    end
end



RegisterNetEvent("mining:client:syncCrusherHealth", function(crusher, health)
    SetEntityHealth(crushers[crusher], health)
    if health == Config.CrusherFuelTime-1 then print("crusher health synced to ".. health) end

    if health == Config.CrusherFuelTime-1 then 

        local volumeOfCrusherSound = 0.2
        local CrusherUrl = "https://www.youtube.com/watch?v=se9Edeo2hXo&ab_channel=Greasedupdirtydiesel"
        local pos = GetEntityCoords(crushers[crusher])
        local id = "CrushersoundID"
        -- amend the sting to be unique for each crusher
        id = id .. crusher

        exports['xsound']:PlayUrlPos(id ,CrusherUrl,volumeOfCrusherSound,pos)
        exports['xsound']:fadeIn(id, 3000, 0.2)

        RequestNamedPtfxAsset("core")
        Wait(10)
        SetPtfxAssetNextCall("core")
        Wait(10)
        local effect = StartParticleFxLoopedOnEntity("ent_amb_generator_smoke", crushers[crusher], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, false, false, false)

    elseif health == 5 then
        exports['xsound']:fadeOut(id, 2500)

    elseif health == 0 then
        
        RemoveNamedPtfxAsset(effect) -- Clean up
        StopParticleFxLooped(effect, 0)
        RemoveParticleFxFromEntity(crushers[crusher])
    end
end)



RegisterNetEvent("rock:client:syncHeath", function(rock, health, CurrentRockHash)
    SetEntityHealth(rocks[rock], health)
    local CurrentRockHash = GetHashKey(rocks[rock])
    local RockHightAboveGround = GetEntityHeightAboveGround(rocks[rock])

    local CurrentCoords = GetEntityCoords(rocks[rock])
    
    local toX = CurrentCoords.x
    local toY = CurrentCoords.y
    local toZ = CurrentCoords.z -0.05

    if health <= 25 then
        
	    SlideObject(rocks[rock], toX, toY, toZ, 0.1, 0.1, 0.1, false)

    end

    if health <= 5 then 
        RequestNamedPtfxAsset("core")
        Wait(10)
        SetPtfxAssetNextCall("core")
        Wait(10)
        local effect = StartParticleFxLoopedOnEntity("ent_dst_rocks_small", rocks[rock], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, false, false, false)
        Wait(1000)
        RemoveNamedPtfxAsset(effect) -- Clean up
        StopParticleFxLooped(effect, 0)
        RemoveParticleFxFromEntity(rocks[rock])
    end
    
    if health <= 1 then
        RequestNamedPtfxAsset("core")
        Wait(10)
        SetPtfxAssetNextCall("core")
        Wait(10)
        local effect = StartParticleFxLoopedOnEntity("ent_dst_concrete_large", rocks[rock], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, false, false, false)
        Wait(5000)
        RemoveNamedPtfxAsset(effect) -- Clean up
        StopParticleFxLooped(effect, 0)
        RemoveParticleFxFromEntity(rocks[rock])
        NetworkFadeOutEntity(rocks[rock], true, true)
        local RockDeletionPos = GetEntityCoords(rocks[rock])
        DeleteEntity(rocks[rock])
        rocks[rock] = nil

       

        triggerServerEvent('mining:server:removeRock', rock, CurrentRockHash, RockDeletionPos)

    end
end)





RegisterNetEvent('mining:client:Usejackhammer', function()
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    local PlayerLocation = GetEntityCoords(ped)
    for i,v in pairs(Config.RockHashes) do 
  
        local ClosestRock = GetClosestObjectOfType(PlayerLocation, 4.0, GetHashKey(v), false, true, true)
        if DoesEntityExist(ClosestRock) then
            
            local DistanceToRock = #(PlayerLocation - GetEntityCoords(ClosestRock))
            
            if DistanceToRock < 3.5 then

                if GetEntityHealth(ClosestRock) > 0 then
                    MineRock(ClosestRock) 
                end 
            end            
        end
    end
end)



--Old Method of Creating Rocks using a config file not procedural generation
--good backup if you want to use a config file instead of procedural generation or if anything goes wrong with procedural generation

--Citizen.CreateThread(function()
--   -----------------Create Rocks ---------------------
--   if DevMode == false then 
--        for i,v in pairs(Config.ROCKLocations) do 
--            RequestModel(v.Hash)
--            while HasModelLoaded(v.Hash) == 0 do
--                Wait(100)    
--                print('waiting on rock model to load, possible connection issue')
--            end
--
--            if DoesEntityExist(rocks[i]) == true then 
--                print('rock already exists')
--            elseif HasModelLoaded(v.Hash) == 1 then
--
--            
--                if DoesEntityExist(rocks[i]) == false then
--
--
--                    local rock = CreateObject(v.Hash, v.ROCK.x, v.ROCK.y, v.ROCK.z, false, true, false)
--
--                    rocks[#rocks + 1] = rock
--                
--                    SetEntityAsMissionEntity(rocks[i], false, false)
--                    SetEntityCanBeDamaged(rocks[i],true)
--                    SetEntityOnlyDamagedByPlayer(rocks[i], true)
--                    SetEntityHealth(rocks[i], v.Health)
--                    SetEntityProofs(rocks[i] , false , true , false , true , true , true , 1 , true )
--                    FreezeEntityPosition(rocks[i], true)
--                    SetEntityRotation(rocks[i], math.random()*1, math.random()*3, math.random()*360, 2, p5)
--                    TriggerServerEvent('mining:server:holdrocks', rocks[i])  
--                else
--                    print('rock already exists')
--                end
--            end
--        end
--    end
--end)


--on recource stop 
AddEventHandler('onResourceStop', function(resource, RockTable)
    if resource == GetCurrentResourceName() then
        print('resource stopped, deleting rocks')
        print('rocks table length is '.. #rocks)

        for i,v in pairs(rocks) do
            print('deleting rock '.. i)
            DeleteEntity(rocks[i])
            rocks[i] = nil
        end 

        for i,v in pairs(crushers) do
            print('deleting crusher '.. i)
            DeleteEntity(crushers[i])
            crushers[i] = nil
        end

    end
end)



