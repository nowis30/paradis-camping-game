-- Configuration pour la boutique ProShop
local ProShopConfig = {}

-- Types de produits
ProShopConfig.ProductTypes = {
	AXE = "Axe",
	MAGIC_LOG = "MagicLog"
}

-- Durée des bûches magiques (24 heures en secondes)
ProShopConfig.MAGIC_LOG_DURATION = 24 * 60 * 60 -- 86400 secondes

-- Bonus de feu pour les bûches magiques
ProShopConfig.MAGIC_LOG_FIRE_BONUS = 50 -- +50 au lieu de +20 pour une bûche normale

-- Catalogue des produits
ProShopConfig.Products = {
	-- Haches permanentes
	{
		Id = "axe_bronze",
		Name = "Hache Bronze",
		Description = "Hache améliorée - Coupe 2x plus vite",
		ProductType = ProShopConfig.ProductTypes.AXE,
		Price = 5000, -- Argent (Money)
		AxePower = 2,
		Icon = "🪓",
		Color = Color3.fromRGB(205, 127, 50) -- Bronze
	},
	{
		Id = "axe_argent",
		Name = "Hache Argent",
		Description = "Hache puissante - Coupe 3x plus vite",
		ProductType = ProShopConfig.ProductTypes.AXE,
		Price = 15000,
		AxePower = 3,
		Icon = "⛏️",
		Color = Color3.fromRGB(192, 192, 192) -- Argent
	},
	{
		Id = "axe_or",
		Name = "Hache Or",
		Description = "Hache d'élite - Coupe 4x plus vite",
		ProductType = ProShopConfig.ProductTypes.AXE,
		Price = 35000,
		AxePower = 4,
		Icon = "⚒️",
		Color = Color3.fromRGB(255, 215, 0) -- Or
	},
	
	-- Bûches magiques (boost temporaire 24h)
	{
		Id = "magic_log_1",
		Name = "Bûche Magique x1",
		Description = "Alimente le feu +50 pendant 24h",
		ProductType = ProShopConfig.ProductTypes.MAGIC_LOG,
		Price = 1000,
		Quantity = 1,
		Icon = "✨",
		Color = Color3.fromRGB(138, 43, 226) -- Violet
	},
	{
		Id = "magic_log_5",
		Name = "Pack Bûches Magiques x5",
		Description = "5 bûches magiques - Économisez 20%!",
		ProductType = ProShopConfig.ProductTypes.MAGIC_LOG,
		Price = 4000, -- Au lieu de 5000
		Quantity = 5,
		Icon = "✨✨",
		Color = Color3.fromRGB(138, 43, 226)
	},
	{
		Id = "magic_log_10",
		Name = "Pack Bûches Magiques x10",
		Description = "10 bûches magiques - Économisez 30%!",
		ProductType = ProShopConfig.ProductTypes.MAGIC_LOG,
		Price = 7000, -- Au lieu de 10000
		Quantity = 10,
		Icon = "✨✨✨",
		Color = Color3.fromRGB(138, 43, 226)
	}
}

-- Fonction pour récupérer un produit par ID
function ProShopConfig.GetProductById(productId)
	for _, product in ipairs(ProShopConfig.Products) do
		if product.Id == productId then
			return product
		end
	end
	return nil
end

-- Fonction pour filtrer les produits par type
function ProShopConfig.GetProductsByType(productType)
	local filtered = {}
	for _, product in ipairs(ProShopConfig.Products) do
		if product.ProductType == productType then
			table.insert(filtered, product)
		end
	end
	return filtered
end

return ProShopConfig
