--// SERVICIOS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// VARIABLES GLOBALES
local player = Players.LocalPlayer
local originalFireServer
local cachedGUID = nil
local cachedID = nil
local cachedRemoteName = nil
local cachedMobs = {}

--// MOBS A ATACAR
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

--// DETECTAR MOBS ACTIVOS
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

--// HOOKEAR FireServer
local function hookRemote()
    local remote = ReplicatedStorage:WaitForChild("network"):WaitForChild("RemoteEvent"):WaitForChild("playerRequest_damageEntity_batch")

    originalFireServer = hookfunction(remote.FireServer, function(self, ...)
        local args = { ... }

        if typeof(args[1]) == "table" then
            local firstAttack = args[1][1]
            if typeof(firstAttack) == "table" and #firstAttack >= 6 then
                local newMob = firstAttack[1]
                local newID = firstAttack[4]
                local newRemoteName = firstAttack[5]
                local newGUID = firstAttack[6]

                local changed = false

                if newGUID ~= cachedGUID then
                    cachedGUID = newGUID
                    changed = true
                    print("🧠 Nuevo abilityGUID:", cachedGUID)
                end
                if newID ~= cachedID then
                    cachedID = newID
                    changed = true
                    print("📌 Nuevo ID:", cachedID)
                end
                if newRemoteName ~= cachedRemoteName then
                    cachedRemoteName = newRemoteName
                    changed = true
                    print("🔁 Nuevo RemoteName:", cachedRemoteName)
                end

                if changed then
                    print("⚡ Nueva configuración detectada desde FireServer, se aplicará al autofarm.")
                end
            end
        end

        return originalFireServer(self, ...)
    end)
end

--// LOOP DE ATAQUE MASIVO AUTOMÁTICO CON DATOS CACHEADOS
task.spawn(function()
    while true do
        local success, err = pcall(function()
            if cachedGUID and cachedID and cachedRemoteName then
                cachedMobs = obtenerMobsActuales()
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
                    print("🔥 Auto ataque a:", mobPart.Name)
                    task.wait(0.01)
                end
            end
        end)

        if not success then
            warn("❌ Error en ataque automático:", err)
        end

        task.wait(0.2) -- Más relajado para no sobrecargar
    end
end)

--// INICIAR HOOK
hookRemote()
