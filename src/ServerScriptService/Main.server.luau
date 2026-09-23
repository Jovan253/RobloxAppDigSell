-- Single entry point: wires up services in dependency order so, e.g.,
-- MiningService never grants cash to a player DataService hasn't loaded yet.
local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService:WaitForChild("Services")

local DataService = require(Services.DataService)
local EnvironmentService = require(Services.EnvironmentService)
local MarketplaceService = require(Services.MarketplaceService)
local MiningService = require(Services.MiningService)
local ShopService = require(Services.ShopService)
local RebirthService = require(Services.RebirthService)
local LeaderboardService = require(Services.LeaderboardService)
local PickaxeToolService = require(Services.PickaxeToolService)

DataService.Init()
EnvironmentService.Init()
MarketplaceService.Init()
MiningService.Init()
ShopService.Init()
RebirthService.Init()
LeaderboardService.Init()
PickaxeToolService.Init()
