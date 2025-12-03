-- Shared Template Registry
-- Scans ReplicatedStorage.Paradis.Templates for Model children and exposes simple lookup APIs

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Paradis = ReplicatedStorage:WaitForChild("Paradis")
local Templates = Paradis:WaitForChild("Templates")

local TemplateRegistry = {}

export type TemplateInfo = {
	name: string,
	model: Model,
	category: string,
	price: number,
}

local function readOne(model: Instance): TemplateInfo?
	if not model:IsA("Model") then
		return nil
	end
	local name = model.Name
	local category = model:GetAttribute("Category")
	if typeof(category) ~= "string" or category == "" then
		category = "decoration"
	end
	local price = model:GetAttribute("Price")
	if typeof(price) ~= "number" then
		price = 0
	end
	return {
		name = name,
		model = model,
		category = category :: string,
		price = price :: number,
	}
end

function TemplateRegistry.getAll(): { TemplateInfo }
	local list = {}
	for _, child in Templates:GetChildren() do
		local info = readOne(child)
		if info then
			list[#list+1] = info
		end
	end
	return list
end

function TemplateRegistry.getByName(name: string): TemplateInfo?
	for _, child in Templates:GetChildren() do
		if child.Name == name then
			return readOne(child)
		end
	end
	return nil
end

return TemplateRegistry
