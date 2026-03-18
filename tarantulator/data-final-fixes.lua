for type, equipment in pairs(data.raw) do
	if type ~= 'solar-panel-equipment' and type ~= 'generator-equipment' then
		for _, equipment in pairs(equipment) do
			local categories = equipment.categories
			if categories and equipment.sprite and equipment.shape and equipment.energy_source then
				categories[#categories + 1] = 'tarantulator'
			end
		end
	end
end

local tarantulator = data.raw["spider-vehicle"]["tarantulator"]
if tarantulator then
	tarantulator.allow_remote_driving = true
end

-- Check for the presence of the "Exotic Space Industries Remembrance" mod and load compatibility if it is installed.
if mods["exotic-space-industries-remembrance"] then
    require("prototypes.compatibility.esi")
end