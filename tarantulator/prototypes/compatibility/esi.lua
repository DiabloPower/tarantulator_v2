---- This file provides compatibility with the "Exotic Space Industries" (ESI) mod.
---- It ensures that the Tarantulator can utilize the custom fuel categories provided by ESI.

local spider = data.raw["spider-vehicle"]["tarantulator"]

if spider then
    -- If ESI wiped the burner or changed it, re-declare the essentials
    if not spider.energy_source then
        spider.energy_source = {
            type = "burner",
            fuel_inventory_size = 2,
            burnt_inventory_size = 1,
            effectivity = 0.5,
            fuel_categories = {"nuclear"}
        }
    end

    -- Explicitly set the table to include ESI categories
    spider.energy_source.fuel_categories = {
        "nuclear",
        "ei-nuclear-fuel",
        "ei-nuclear-fuel-cell",
        "ei-fusion-fuel"
    }
    
    -- Debugging: Uncomment the line below to see a message in the logs (factorio-current.log) 
    -- to confirm this script actually ran.
    -- log("Tarantulator: Successfully injected ESI fuel categories.")
end
