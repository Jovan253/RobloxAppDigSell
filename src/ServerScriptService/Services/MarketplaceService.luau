-- Handles the "2x Cash" gamepass (ownership cache + cash multiplier) and
-- Cash Pack developer products (granted via ProcessReceipt, the reliable
-- purchase-completion callback -- unlike PromptProductPurchaseFinished,
-- ProcessReceipt is guaranteed to eventually fire even if the player
-- disconnects mid-purchase, and Roblox retries it until it returns
-- PurchaseGranted).
local MarketplaceAPI = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)

local CASH_BY_PRODUCT_ID = {}
for _, product in Config.CashProducts do
	CASH_BY_PRODUCT_ID[product.ProductId] = product.Cash
end

local MarketplaceService = {}

local ownedGamePasses = {} -- [player] = { [gamePassId] = true }

local function checkGamePasses(player)
	local owned = {}
	ownedGamePasses[player] = owned

	local gamePassId = Config.GamePasses.DoubleCash
	local ok, result = pcall(function()
		return MarketplaceAPI:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)
	owned[gamePassId] = ok and result or false

	DataService.SetOwnsDoubleCash(player, owned[gamePassId])
end

function MarketplaceService.GetCashMultiplier(player)
	local owned = ownedGamePasses[player]
	if owned and owned[Config.GamePasses.DoubleCash] then
		return 2
	end
	return 1
end

local function onGamePassPurchaseFinished(player, gamePassId, wasPurchased)
	if not wasPurchased then
		return
	end

	local owned = ownedGamePasses[player]
	if owned then
		owned[gamePassId] = true
	end

	if gamePassId == Config.GamePasses.DoubleCash then
		DataService.SetOwnsDoubleCash(player, true)
	end
end

-- Jumpscares every other player within Config.JumpscarePrankRadius of the
-- buyer's character (the buyer has to actually be in Dark Mines near people
-- for this to do anything -- it doesn't look them up by zone).
local function triggerJumpscarePrank(buyer)
	local buyerCharacter = buyer.Character
	local buyerRoot = buyerCharacter and buyerCharacter:FindFirstChild("HumanoidRootPart")
	if not buyerRoot then
		return
	end

	for _, target in Players:GetPlayers() do
		if target ~= buyer then
			local character = target.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - buyerRoot.Position).Magnitude <= Config.JumpscarePrankRadius then
				Remotes.JumpscareEffect:FireClient(target)
			end
		end
	end
end

local function onProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player isn't in this server (e.g. bought while offline, or left
		-- mid-purchase). Ask Roblox to retry later rather than losing it.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if Config.JumpscareProductId and receiptInfo.ProductId == Config.JumpscareProductId then
		triggerJumpscarePrank(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local cashAmount = CASH_BY_PRODUCT_ID[receiptInfo.ProductId]
	if not cashAmount then
		-- Unrecognized product: nothing to grant, but acknowledge the
		-- receipt so Roblox doesn't retry it forever.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if not DataService.GetProfile(player) then
		-- Profile hasn't finished loading yet; retry once it has.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.AddCash(player, cashAmount)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MarketplaceService.Init()
	Players.PlayerAdded:Connect(checkGamePasses)

	Players.PlayerRemoving:Connect(function(player)
		ownedGamePasses[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(checkGamePasses, player)
	end

	MarketplaceAPI.PromptGamePassPurchaseFinished:Connect(onGamePassPurchaseFinished)
	MarketplaceAPI.ProcessReceipt = onProcessReceipt
end

return MarketplaceService
