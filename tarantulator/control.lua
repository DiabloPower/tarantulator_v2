-- Defines the mod path for resource referencing
path = "__tarantulator__"

-- Stores entity health to manage friendly fire
-- ensures that transfer_efficiency is initialized
local function ensure_initialized()
    storage = storage or {}
    storage.entity_health = storage.entity_health or {}
    storage.tarantulators = storage.tarantulators or {}
    if not storage.transfer_efficiency then
        storage.transfer_efficiency = settings.startup["tarantulator-energy-grid-efficiency"].value / 100 * 0.05
    end
end

-- Runs every 240 game ticks to check Tarantulators and manage their energy
script.on_nth_tick(240, function(event)
    ensure_initialized()
    storage.tarantulators = storage.tarantulators or {}

    for id, spider in pairs(storage.tarantulators) do
        if spider and spider.valid and spider.grid then
            local grid = spider.grid
            -- Loops through all equipment in the spider's grid
            for _, equipment in pairs(grid.equipment) do
                if equipment.max_energy and equipment.energy then
                    local missing = equipment.max_energy - equipment.energy
                    -- Transfers fuel energy to equipment if needed
                    if missing > 0 and spider.burner and spider.burner.remaining_burning_fuel then
                        if spider.burner.remaining_burning_fuel > 0 then
                            if missing > 0 then
                                if spider.burner.remaining_burning_fuel < missing / storage.transfer_efficiency then
                                    -- Transfers all remaining fuel energy to the equipment
                                    equipment.energy = equipment.energy + spider.burner.remaining_burning_fuel * storage.transfer_efficiency
                                    spider.burner.remaining_burning_fuel = 0
                                else
                                    -- Reduces fuel and fully charges the equipment
                                    spider.burner.remaining_burning_fuel = spider.burner.remaining_burning_fuel - (missing / storage.transfer_efficiency)
                                    equipment.energy = equipment.energy + missing
                                end
                            end
                        end                        
                    end
                end
            end
        else
            -- Removes invalid Tarantulator references
            storage.tarantulators[id] = nil
        end
    end
end)

-- Function triggered when a Tarantulator is built
local function tarantulator_built(event)
    local entity = event.created_entity or event.entity
    -- Automatically places a reactor in the equipment grid
    entity.grid.put{
        name = 'tarantulator-reactor',
        position = {3, 4},
    }
    -- Registers the new Tarantulator in the global table
    storage.tarantulators[entity.unit_number] = entity
end

-- Filters for detecting Tarantulator entity creation events
local filter = {{filter = 'name', name = 'tarantulator'}, {filter = 'type', type = 'spider-vehicle', mode = 'and'}}

-- Triggers when a Tarantulator is built manually, by a robot, or revived
script.on_event(defines.events.on_built_entity, tarantulator_built, filter)
script.on_event(defines.events.on_robot_built_entity, tarantulator_built, filter)
script.on_event(defines.events.script_raised_built, tarantulator_built, filter)
script.on_event(defines.events.script_raised_revive, tarantulator_built, filter)

-- Ensures the Tarantulator reactor is always present in the equipment grid
script.on_event(defines.events.on_player_removed_equipment, function(event)
    if event.equipment == 'tarantulator-reactor' then
        event.grid.put{
            name = 'tarantulator-reactor',
            position = {3, 4},
        }
        -- Prevents players from removing the reactor entirely
        game.players[event.player_index].remove_item{name = 'tarantulator-reactor', count = 100}
    end
end)

-- Updates entity health on each tick to track changes
local function update_tick_handler()
    if next(storage.tarantulators) then
        script.on_event(defines.events.on_tick, track_health)
    else
        script.on_event(defines.events.on_tick, nil)
    end
end

local function track_health(event)
    for _, spider in pairs(storage.tarantulators) do
        if spider.valid and spider.health then
            storage.entity_health[spider.unit_number] = spider.health
        end
    end
end

-- Initial setup for the mod when loaded or reconfigured
local function setup()
    ensure_initialized()
    update_tick_handler()
end

script.on_init(setup)
script.on_configuration_changed(setup)

-- Loads the necessary prototypes for the Tarantulator mod
local protected_entity_names = {
    ["tarantulator"] = true,
    ["tarantulator-leg"] = true,
    ["tarantulator-leg-small"] = true
}

-- Checks if an entity is a Tarantulator or its legs
local function is_tarantulator_entity(entity)
    return entity and entity.valid and protected_entity_names[entity.name] == true
end

-- Handles friendly fire prevention for Tarantulator entities
script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= "tarantulator-line-damage" then return end

    local source = event.source_entity
    local target = event.target_entity

    if not source or not target then return end

    if is_tarantulator_entity(target) then
        return
    end

    local friendly_fire_enabled = settings.startup["tarantulator-enable-friendly-fire"].value

    if friendly_fire_enabled or source.force ~= target.force then
        target.damage(4000, source.force, "physical")
    end
end)