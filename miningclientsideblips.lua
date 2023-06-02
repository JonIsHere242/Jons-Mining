

QBCore = exports['qb-core']:GetCoreObject()



Citizen.CreateThread(function()
    
    local blip = AddBlipForCoord(2953.62, 2787.38)
    SetBlipSprite(blip, 618)
    SetBlipColour(blip, 22)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.9)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Quarry Mine")
    EndTextCommandSetBlipName(blip)  
    
    local blip3 = AddBlipForCoord(2682.2795, 2811.0244)
    SetBlipSprite(blip3, 618)
    SetBlipColour(blip3, 22)
    SetBlipAsShortRange(blip3, true)
    SetBlipScale(blip3, 0.9)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Stone Processing")
    EndTextCommandSetBlipName(blip3)

    local blip4 = AddBlipForCoord(Config.smelter.x, Config.smelter.y)
    SetBlipSprite(blip4, 618)
    SetBlipColour(blip4, 22)
    SetBlipAsShortRange(blip4, true)
    SetBlipScale(blip4, 0.9)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Ore Smelter")
    EndTextCommandSetBlipName(blip4)
end)