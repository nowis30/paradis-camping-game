--[[
    ConfigValidator
    Vérifie au démarrage que chaque objet plaçable possède une entrée économie.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

local configFolder = ReplicatedStorage:WaitForChild("Config")
local ObjectsConfig = require(configFolder:WaitForChild("ObjectsConfig"))
local EconomyConfig = require(configFolder:WaitForChild("EconomyConfig"))

local missingEconomy = {}
for objectName in pairs(ObjectsConfig) do
    if not EconomyConfig.Objects[objectName] then
        table.insert(missingEconomy, objectName)
    end
end

if #missingEconomy > 0 then
    warn("[Paradis][Config] Objets sans configuration d'économie:", table.concat(missingEconomy, ", "))
else
    TestService:Message("[Paradis] Tous les objets ont une configuration d'économie.")
end

for econName in pairs(EconomyConfig.Objects) do
    if not ObjectsConfig[econName] then
        TestService:Message("[Paradis] Entrée économie inutilisée: " .. econName)
    end
end
