--// SERVICIOS
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// LISTA DE MOBS ACTUALIZADA
local listaDeMobs = {
    "Aevrul", "Baby Scarab", "Baby Shroom", "Baby Slime", "Baby Yeti", "Baby Yeti Tribute",
    "Bamboo Mage", "Bandit", "Bandit Skirmisher", "Battering Shroom", "Batty", "Bear",
    "Big Slime", "Birthday Mage", "Boar", "Book", "Bushi", "Chad", "Chicken", "Crabby",
    "Crow", "Cultist", "Dark Cleric", "Deathsting", "Dragon Boss", "Dragon Monk", "Dummy",
    "Dustwurm", "Eldering Shroom", "Elder Shroom", "Enchanted Slime", "Enchiridion",
    "Ent Sapling", "Ethera", "Ethereal Monarch", "Frightcrow", "Fish", "First Mate",
    "Fly Trap", "Gauntlet Gate", "Gecko", "Goblin", "Gorgog Guardian", "Guardian",
    "Guardian Dummy", "Hag", "Hermit Crabby", "Hitbox", "Hog", "Horseshoe Crab", "Humanoid",
    "Jellyfish", "Kobra", "Lil Shroomie Cage", "Lobster", "Lost Spirit", "Mama Hermit Crabby",
    "Master Miyamoto", "Mimic Jester", "Miner Prisoner", "Mo Ko Tu Aa", "Mogloko", "Moglo",
    "Monster", "Mosquito Parasite", "Mummy", "Orc", "Parasite", "Parasite Host",
    "Pirate", "Pirate Captain", "Pirate Summon", "Pit Ratty", "Possum the Devourer",
    "Prisoner", "Ram", "Ratty", "Reanimated Slime", "Reaper", "Redwood Bandit",
    "Redwood Bandit Leader", "Rock Slime", "Rootbeard", "Rubee", "Runic Titan",
    "Samurai", "Scarab", "Scarecrow", "Sensei", "Shade", "Shaman", "Shinobi", "Shroom",
    "Skeleton", "Skull Boss", "Slime", "Snel", "Soulcage", "Spider", "Spider Queen",
    "Spiderling", "Stingtail", "Sunken Savage", "Terror of the Deep", "The Yeti",
    "Toni", "Tortoise", "Treemuk", "Tribute Gate", "Trickster Spirit", "Tumbleweed",
    "Undead", "Wisp"
}

--// FUNCIONES DE UTILIDAD
local function isValidGUID(guid)
    return typeof(guid) == "string" and #guid == 36 and string.match(guid, "^%x+%-%x+%-%x+%-%x+%-%x+$") ~= nil
end

local function isValidExecutionData(data)
    return typeof(data) == "table" and data["id"] ~= 0 and isValidGUID(data["ability-guid"])
end

local function getAbilityInfoFromData(dataTable)
    for _, data in pairs(dataTable) do
        if isValidExecutionData(data) and data["args"] and typeof(data["args"]) == "table" then
            local guid = data["ability-guid"]
            local id = data["args"][4]
            local remoteName = data["args"][5]
            return guid, id, remoteName
        end
    end
    return nil, nil, nil
end

--// FUNCIÓN DE DETECCIÓN DEL ability-guid, id y remoteName desde JSON
local function getAbilityInfo()
    local player = Players.LocalPlayer
    local charModel = workspace.placeFolders.entityManifestCollection:FindFirstChild(player.Name)
    if not charModel then return nil end

    local Hitbox = charModel:FindFirstChild("hitbox")
    if not Hitbox then return nil end

    local ExecutionDataValue = Hitbox:FindFirstChild("activeAbilityExecutionData")
    if not ExecutionDataValue or not ExecutionDataValue.Value then return nil end

    local success, parsed = pcall(function()
        return HttpService:JSONDecode(ExecutionDataValue.Value)
    end)
    if not success or typeof(parsed) ~= "table" then
        return nil
    end

    if isValidExecutionData(parsed) and parsed["args"] then
        return parsed["ability-guid"], parsed["args"][4], parsed["args"][5]
    else
        return getAbilityInfoFromData(parsed)
    end
end

--// DETECTAR MOBS PRESENTES EN EL MAPA
local function obtenerMobsActuales()
    local mobs = {}
    for _, mobName in ipairs(listaDeMobs) do
        local mobPart = workspace.placeFolders.entityManifestCollection:FindFirstChild(mobName)
        if mobPart and mobPart:IsA("BasePart") then
            table.insert(mobs, mobPart)
        end
    end
    return mobs
end

--// DATOS CACHEADOS
local cachedGUID = nil
local cachedID = nil
local cachedRemoteName = nil
local cachedMobs = {}

--// ACTUALIZAR ability-guid, id y remoteName cada 0.1s
task.spawn(function()
    while true do
        local guid, id, remoteName = getAbilityInfo()
        if guid and guid ~= cachedGUID then
            cachedGUID = guid
            cachedID = id
            cachedRemoteName = remoteName
            print("Nuevo GUID detectado:", guid, "| ID:", id, "| RemoteName:", remoteName)
        end
        task.wait(0.1)
    end
end)

--// ACTUALIZAR MOBS CADA 0.1s
task.spawn(function()
    while true do
        cachedMobs = obtenerMobsActuales()
        task.wait(0.1)
    end
end)

--// ENVIAR RemoteEvent CADA 0.1s (1 mob a la vez, 15 ataques c/u)
task.spawn(function()
    while true do
        local success, err = pcall(function()
            if cachedGUID and cachedID and cachedRemoteName and #cachedMobs > 0 then
                local remoteEvent = ReplicatedStorage:WaitForChild("network"):WaitForChild("RemoteEvent"):WaitForChild("playerRequest_damageEntity_batch")

                for _, mobPart in ipairs(cachedMobs) do
                    local ataques = {}

                    for i = 1, 15 do
                        table.insert(ataques, {
                            mobPart,
                            mobPart.Position,
                            "ability",
                            cachedID,
                            cachedRemoteName,
                            cachedGUID
                        })
                    end

                    remoteEvent:FireServer(ataques)
                    print("Ataque x15 a:", mobPart.Name, "| Remote:", cachedRemoteName)
                    task.wait(0.01)
                end
            end
        end)

        if not success then
            warn("Error al enviar RemoteEvent:", err)
        end

        task.wait(0.1)
    end
end)
