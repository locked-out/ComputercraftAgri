-- PARAMETERS
origin_direction_verbose = "SOUTH"
mutatations_file_path = "Mutations.txt"

cfg_file_path = "agri.cfg" 
fuel_threshold = 50

CROPS_STICK_ID = "AgriCraft:cropsItem"
CROP_ANALYZER_ID = "AgriCraft:peripheral"


-- BEGIN CODE
found_fuel = false
known_fuel = 0

function refuel()
    if found_fuel then
        if not turtle.refuel(1) then
            found_fuel = false
            refuel()
        end
    else
        while found_fuel == false do
            for slot=1, 16 do
                turtle.select(slot)
                if turtle.refuel(1) then
                    known_fuel = slot
                    found_fuel = true
                    break
                end
            end
            if (found_fuel == false) then
                print("Out of fuel, hit enter once turtle has been refueled")
                read()
            end
        end
    end
end

fuel_limit = turtle.getFuelLimit()
-- fuel_threshold = fuel_limit * fuel_threshold_ratio

function attempt_refuel()
    while turtle.getFuelLevel() < fuel_threshold do
        refuel()
    end
end

stick_slot = -1
analyzer_slot = -1

function find_crop_tools()
    stick_slot = -1
    analyzer_slot = -1
    while (stick_slot == -1) or (analyzer_slot == -1) do
        for slot=1, 16 do
            local count = turtle.getItemCount(slot)
            if count > 0 then
                local data = turtle.getItemDetail(slot)
                if (data.name == CROPS_STICK_ID) then
                    stick_slot = slot
                end
                if (data.name == CROP_ANALYZER_ID) then
                    analyzer_slot = slot
                end
            end
        end
        if stick_slot == -1 then
            print("Out of crop sticks, hit enter once more crop sticks are given")
            read()
        end
        if analyzer_slot == -1 then
            print("Cant find seed analyzer, please provide agricraft computer controlled seed analyzer then hit enter")
            read()
        end
    end
end


function analyze_seeds()
    find_crop_tools()

    turtle.up()
    turtle.select(analyzer_slot)
    turtle.placeDown()

    local analyzer = peripheral.wrap("bottom")

    local seeds = {}
    for slot=1, 16 do
        turtle.select(slot)
        local count = turtle.getItemCount()
        if count > 0 then
            local data = turtle.getItemDetail()
            if turtle.dropDown() then
                analyzer.analyze()
                while not analyzer.isAnalyzed() do
                    os.sleep(1)
                end
                local stats = {analyzer.getSpecimenStats()}
                if seeds[data.name] == nil then
                    seeds[data.name] = {}
                end
                local seedSlot = {}
                seedSlot.slot = slot
                seedSlot.count = count
                seedSlot.stats = stats
                seeds[data.name][slot] = seedSlot
                turtle.suckDown()
            end
        end
    end

    turtle.select(analyzer_slot)
    turtle.digDown()
    turtle.down()

    return seeds
end
-- {
--     slot = 11
--     count = 64
--     stats = {
--         1,
--         1,
--         1,
--     }
-- }
function select_seeds(seeds)

    local targetSeeds = false
    while not targetSeeds do
        local availableSeeds = {}

        for seedName, seedInfo in pairs(seeds) do
            local nseeds = 0
            for slot, seed in pairs(seedInfo) do
                nseeds = nseeds + seed.count
            end
            if nseeds >= 2 then
                table.insert(availableSeeds, seedName)
            end
        end

        if #availableSeeds == 0 then
            print("Couldn't find enough of any seed, please insert at least 2 of the same seed and hit enter")
            read()
            seeds = analyze_seeds()
        end
        if #availableSeeds == 1 then
            targetSeeds = availableSeeds[1]
        end
        if #availableSeeds > 1 then
            while not targetSeeds do
                print("Multiple seeds found, please specify which one:")
                for i, seedName in pairs(availableSeeds) do
                    print("["..i.."] "..seedName)
                end
                write("> ")
                local n = math.floor(tonumber(read()))
                if n > 0 and n <= #availableSeeds then
                    targetSeeds = availableSeeds[n]
                end
            end
        end
    end


    return targetSeeds
end


function compareSeeds(aSeed, bSeed) 
    for i=1, 3 do
        if not (aSeed.stats[i] == bSeed.stats[i]) then
            return aSeed.stats[i] > bSeed.stats[i]
        end
    end
    return 0
end

function discardUnusedSeeds(seeds, target) 
    turtle.turnLeft()
    turtle.turnLeft()
    local targetSeeds = {}
    for seedName, seedInfos in pairs(seeds) do
        if seedName == target then
            for slot, seedInfo in pairs(seedInfos) do
                table.insert(targetSeeds, seedInfo)
            end

        else
            for slot, seedInfo in pairs(seedInfos) do
                turtle.select(slot)
                turtle.drop()
            end
        end
    end

    
    table.sort(targetSeeds, compareSeeds)
    
    
    local bestSeeds = {}
    local seedsLeft = 2
    for i, seed in ipairs(targetSeeds) do
        if seedsLeft > 0 then
            local available = math.min(seedsLeft, seed.count)
            for j=1, available do
                table.insert(bestSeeds, seed.slot)
                seedsLeft = seedsLeft - 1
            end
            if available < seed.count then
                turtle.select(seed.slot)
                turtle.drop(seed.count-available)
            end
        else
            turtle.select(seed.slot)
            turtle.drop()
        end
    end
    
    -- for i, slot in ipairs(bestSeeds) do
    --     turtle.select(slot)
    --     turtle.transferTo(i, 1)
    -- end

    -- print(textutils.serialize(targetSeeds))

    turtle.turnRight()
    turtle.turnRight()
    return bestSeeds
end

orientationMappingBackwards = {}
orientationMappingBackwards["WEST"] = 0
orientationMappingBackwards["SOUTH"] = 1
orientationMappingBackwards["EAST"] = 2
orientationMappingBackwards["NORTH"] = 3

origin_direction = orientationMappingBackwards[origin_direction_verbose]

orientationMapping = {}
orientationMapping[0] = "WEST"
orientationMapping[1] = "SOUTH"
orientationMapping[2] = "EAST"
orientationMapping[3] = "NORTH"



function useStick()
    if stick_slot == -1 then
        while (stick_slot == -1) do
            for slot=1, 16 do
                local count = turtle.getItemCount(slot)
                if count > 0 then
                    local data = turtle.getItemDetail(slot)
                    if (data.name == CROPS_STICK_ID) then
                        stick_slot = slot
                        break
                    end
                end
            end
            if stick_slot == -1 then
                print("Out of crop sticks, hit enter once more crop sticks are given")
                read()
            end
        end
    end
    local retval = stick_slot
    if turtle.getItemCount(stick_slot) == 1 then
        stick_slot = -1
    end
    return retval
end


function cropSetup(seed1Slot, seed2Slot)
    find_crop_tools()
    attempt_refuel()

    turtle.up()
    turtle.forward()

    turtle.forward()
    turtle.select(useStick())
    turtle.placeDown()
    turtle.forward()
    turtle.select(seed1Slot)
    turtle.dropDown(1)

    local activator = peripheral.wrap("bottom")
    redstone.setOutput("bottom", true)
    while activator.getStackInSlot(1) do os.sleep(0.1) end
    redstone.setOutput("bottom", false)
    turtle.back()
    turtle.back()

 
    turtle.turnRight()
    turtle.forward()
    if seed2Slot ~= -1 then
        turtle.select(useStick())
        turtle.placeDown()
        turtle.forward()
        turtle.select(seed2Slot)
        turtle.dropDown(1)

        activator = peripheral.wrap("bottom")
        redstone.setOutput("bottom", true)
        while activator.getStackInSlot(1) do os.sleep(0.1) end
        redstone.setOutput("bottom", false)

        turtle.back()
    end 

    turtle.turnLeft()
    turtle.forward()
    turtle.select(analyzer_slot)
    turtle.placeDown()
    local analyzer = peripheral.wrap("bottom")

    local plant1 = (origin_direction+1)%4
    local plant2 = (plant1+1)%4
    while (analyzer.getGrowthStage(orientationMapping[plant1]) < 100) do os.sleep(3) end
    if seed2Slot ~= -1 then
        while (analyzer.getGrowthStage(orientationMapping[plant2]) < 100) do os.sleep(3) end
    end
    turtle.digDown()


    turtle.back()
    turtle.turnRight()
    turtle.back()
    turtle.turnLeft()
end


local breedIteration = 0
function upgrade(target)
    -- Requires starting above the center grow field

    attempt_refuel()

    turtle.select(useStick())
    turtle.placeDown()
    turtle.turnLeft()
    turtle.forward()
    turtle.select(useStick())
    turtle.dropDown(1)
    local activator = peripheral.wrap("bottom")
    redstone.setOutput("bottom", true)
    while activator.getStackInSlot(1) do os.sleep(0.1) end
    redstone.setOutput("bottom", false)
    turtle.back()
    turtle.turnRight()

    turtle.back()
    turtle.select(analyzer_slot)
    turtle.placeDown()

    local analyzer = peripheral.wrap("bottom")
    while (not analyzer.hasPlant(orientationMapping[origin_direction])) do os.sleep(1) end
    turtle.forward()

    turtle.select(1)
    turtle.digDown()

    turtle.back()

    local newSeedSlot = -1

    while newSeedSlot == -1 do
        for slot=1, 16 do
            local count = turtle.getItemCount(slot)
            if count > 0 then
                local data = turtle.getItemDetail(slot)
                if (data.name == target) then
                    newSeedSlot = slot
                end
            end
        end

        if newSeedSlot == -1 then
            print("Could not find the new seed of type "..target)
            print("Please give the seed and hit enter, or restart the program")
            read()
        end
    end

    turtle.select(newSeedSlot)
    turtle.dropDown(1)

    analyzer = peripheral.wrap("bottom")
    analyzer.analyze()
    while not analyzer.isAnalyzed() do
        os.sleep(1)
    end
    local stats = {analyzer.getSpecimenStats()}
    local perfect = true
    for i, v in ipairs(stats) do
        if v < 10 then
            perfect = false
            break
        end
    end


    turtle.suckDown()

    turtle.select(1)
    turtle.digDown()

    if perfect then
        turtle.down()
        turtle.turnRight()
        turtle.turnRight()
        turtle.select(newSeedSlot)
        turtle.drop(1)
        turtle.turnLeft()
        turtle.turnLeft()
        return true
    end

    turtle.forward()

    if breedIteration == 0 then
        turtle.turnRight()
    end

    turtle.forward()
    turtle.select(1)
    turtle.digDown()
    turtle.select(useStick())
    turtle.placeDown()

    turtle.forward()

    local oldSeedSlot = -1

    while oldSeedSlot == -1 do
        for slot=1, 16 do
            local count = turtle.getItemCount(slot)
            if count > 0 and (slot ~= newSeedSlot or count == 2) then
                local data = turtle.getItemDetail(slot)
                if (data.name == target) then
                    oldSeedSlot = slot
                end
            end
        end

        if oldSeedSlot == -1 then
            print("Could not find the old seed of type "..target)
            print("Please give the seed and hit enter, or restart the program")
            read()
        end
    end

    turtle.select(newSeedSlot)
    turtle.dropDown(1)
 
    activator = peripheral.wrap("bottom")
    redstone.setOutput("bottom", true)
    while activator.getStackInSlot(1) do os.sleep(0.1) end
    redstone.setOutput("bottom", false)

    turtle.back()
    turtle.turnLeft()
    turtle.forward()
    find_crop_tools()
    turtle.select(analyzer_slot)
    turtle.placeDown()
    
    local dir = origin_direction + 2
    dir = (dir + breedIteration)%4
    analyzer = peripheral.wrap("bottom")
    while (analyzer.getGrowthStage(orientationMapping[dir]) < 100) do os.sleep(3) end
    turtle.digDown()

    turtle.back()
    turtle.turnRight()
    turtle.back()

    if breedIteration == 0 then
        turtle.turnLeft()
    end

    breedIteration = (breedIteration + 1) % 2


    turtle.back()
    turtle.back()
    turtle.select(oldSeedSlot)
    turtle.dropDown(1)
    turtle.forward()
    turtle.forward()

    return false
end

function reset(plantedCrop1, plantedCrop2)
    -- Sitting in front of chest
    turtle.select(0)
    turtle.up()
    turtle.forward()
    turtle.digDown()

    local crop1Slot = -1

    for slot=1, 16 do
        local count = turtle.getItemCount(slot)
        if count > 0 then
            local data = turtle.getItemDetail(slot)
            if (data.name == plantedCrop1) then
                crop1Slot = slot
            end
        end
    end

    turtle.back()

    turtle.turnRight()
    turtle.forward()
    turtle.digDown()
    local crop2Slot = -1

    for slot=1, 16 do
        local count = turtle.getItemCount(slot)
        if count > 0 then
            local data = turtle.getItemDetail(slot)
            if (data.name == plantedCrop2 and (slot ~= crop1Slot or count == 2)) then
                crop2Slot = slot
            end
        end
    end

    turtle.back()
    turtle.turnLeft()

    turtle.back()
    turtle.down()
    
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.select(crop1Slot)
    turtle.drop(1)
    turtle.select(crop2Slot)
    turtle.drop(1)
    turtle.turnRight()
    turtle.turnRight()
end

-- function clone(slot)
--     local target = turtle.getItemDetail(slot).name

--     cropSetup(slot, -1)
--     attempt_refuel()

--     turtle.select(useStick())
--     turtle.placeDown()
--     turtle.turnLeft()
--     turtle.forward()
--     turtle.select(useStick())
--     turtle.dropDown(1)
--     local activator = peripheral.wrap("bottom")
--     redstone.setOutput("bottom", true)
--     while activator.getStackInSlot(1) do os.sleep(0.1) end
--     redstone.setOutput("bottom", false)
--     turtle.back()
--     turtle.turnRight()

--     turtle.back()
--     turtle.select(analyzer_slot)
--     turtle.placeDown()

--     local analyzer = peripheral.wrap("bottom")
--     while (not analyzer.hasPlant(orientationMapping[origin_direction])) do os.sleep(1) end
--     turtle.forward()

--     turtle.select(1)
--     turtle.digDown()

--     turtle.back()

--     local newSeedSlot = -1

--     while newSeedSlot == -1 do
--         for slot=1, 16 do
--             local count = turtle.getItemCount(slot)
--             if count > 0 then
--                 local data = turtle.getItemDetail(slot)
--                 if (data.name == target) then
--                     newSeedSlot = slot
--                 end
--             end
--         end

--         if newSeedSlot == -1 then
--             print("Could not find the new seed of type "..target)
--             print("Please give the seed and hit enter, or restart the program")
--             read()
--         end
--     end

-- end


function taskUpgrade(target)
    local seeds = analyze_seeds()
    if not target then
        target = select_seeds(seeds)
    end

    local bestSeeds = discardUnusedSeeds(seeds, target)

    cropSetup(bestSeeds[1], bestSeeds[2])
    while not upgrade(target) do end
    -- reset(target, target)
end

function getRecipes()
    local recipes = {}
    
    if fs.exists(cfg_file_path) then
        local cfg_file = fs.open(cfg_file_path, "r")
        local cfg = textutils.unserialize(cfg_file.readAll())
        cfg_file.close()
        return cfg.recipes
    end
    
    if not fs.exists(mutatations_file_path) then
        perror("Mutations.txt file is missing, this is required for the recipes for plant breeding\n"
        .."This is commonly found in _MCInstallDirectory_/config/agricraft/Mutations.txt\n"
        .."Please copy this file and place it in the same directory as the program")
    end

    local mutations_file = fs.open(mutatations_file_path, "r")
    local line = mutations_file.readLine()
    while line ~= nil do
        if str ~= '' and line[1] ~= '#' then
            line = string.lower(line)
            local equals = string.find(line, "=")
            if equals then
                local plus = string.find(line, "+", equals)
                if plus then
                    local childId = string.sub(line, 1, equals-1)
                    local parentIds = {}
                    parentIds[1] = string.sub(line, equals+1, plus-1)
                    parentIds[2] = string.sub(line, plus+1)
                    recipes[childId] = parentIds 
                end
            end
        end
        line = mutations_file.readLine()
    end
    mutations_file.close()

    local cfg = {}
    cfg.recipes = recipes

    local cfg_file = fs.open(cfg_file_path, "w")
    cfg_file.write(textutils.serialize(cfg))
    cfg_file.close()

    return recipes
end

function getKnownSeeds(seedRecipes)
    local knownSeeds = {}
    
    for seed, parents in pairs(seedRecipes) do
        knownSeeds[string.lower(seed)] = true
        knownSeeds[string.lower(parents[1])] = true
        knownSeeds[string.lower(parents[2])] = true
    end

    return knownSeeds
end

function getOwnedSeeds(knownSeeds)
    local ownedSeeds = {}

    local chest = peripheral.wrap("back")

    local stacks = chest.getAllStacks()
    for slot, stack in ipairs(stacks) do
        local basic = stack.basic()
        local id = string.lower(basic.id)
        if knownSeeds[id] then
            ownedSeeds[id] = true
        end
    end

    return ownedSeeds
end

function breed(seedRecipes, ownedSeeds, target)
    if ownedSeeds[target] then
        return true
    end

    if not seedRecipes[target] then
        print("Missing seed "..target)
        return false
    end

    local p1 = seedRecipes[target][1]
    local p2 = seedRecipes[target][2]

    
    if not breed(seedRecipes, ownedSeeds, p1) then return false end
    if not ownedSeeds[p2] then
        if not breed(seedRecipes, ownedSeeds, p2) then return false end
    end
    
    if ownedSeeds[target] then
        print(target.." already owned after breeding parents, very weird")
        return true
    end
    
    print("Breeding "..target)

    local chest = peripheral.wrap("back")
    
    local p1Slot, p2Slot
    local stacks = chest.getAllStacks()
    for slot, stack in ipairs(stacks) do
        local basic = stack.basic()
        local id = string.lower(basic.id)
        if id == p1 then
            p1Slot = slot
        end
        if id == p2 then
            p2Slot = slot
        end
    end
    
    chest.pushItem(origin_direction_verbose, p1Slot, 1)
    chest.pushItem(origin_direction_verbose, p2Slot, 1)

    for slot=1, 16 do
        local count = turtle.getItemCount(slot)
        if count > 0 then
            local data = turtle.getItemDetail(slot)
            local name = string.lower(data.name)
            if name == p1 then
                p1Slot = slot
            end
            if name == p2 then
                p2Slot = slot
            end
        end
    end
    
    cropSetup(p1Slot, p2Slot)

    attempt_refuel()

    turtle.back()
    turtle.select(analyzer_slot)
    turtle.placeDown()
  

    local success = false
    while not success do
        attempt_refuel()
        turtle.forward()
        turtle.select(useStick())
        turtle.placeDown()
        turtle.turnLeft()
        turtle.forward()
        turtle.select(useStick())
        turtle.dropDown(1)
        local activator = peripheral.wrap("bottom")
        redstone.setOutput("bottom", true)
        while activator.getStackInSlot(1) do os.sleep(0.1) end
        redstone.setOutput("bottom", false)
        turtle.back()
        turtle.turnRight()

        turtle.back()
        local analyzer = peripheral.wrap("bottom")
        while (not analyzer.hasPlant(orientationMapping[origin_direction])) do os.sleep(1) end
        turtle.forward()

        turtle.select(1)
        turtle.digDown()

        local newSeedSlot = -1

        while newSeedSlot == -1 do
            for slot=1, 16 do
                local count = turtle.getItemCount(slot)
                if count > 0 then
                    local data = turtle.getItemDetail(slot)
                    local name = string.lower(data.name)
                    if name == target then
                        newSeedSlot = slot
                        success = true
                    elseif name == p1 or name == p2 then
                        newSeedSlot = slot
                    end
                end
            end

            if newSeedSlot == -1 then
                print("Could not find the new seed that was just harvested")
                print("Please give the seed and hit enter, or restart the program")
                read()
            end
        end

        turtle.back()
        turtle.back()

        turtle.select(newSeedSlot)
        turtle.dropDown(1)
        turtle.forward()
    end

    turtle.select(1)
    turtle.forward()
    turtle.forward()
    turtle.digDown()
    turtle.back()
    turtle.turnRight()
    turtle.forward()
    turtle.digDown()
    turtle.back()
    turtle.turnLeft()
    turtle.back()
    turtle.back()
    
    p1Slot = -1
    for slot=1, 16 do
        local count = turtle.getItemCount(slot)
        if count > 0 then
            local data = turtle.getItemDetail(slot)
            local name = string.lower(data.name)
            if name == p1 and p1Slot == -1 then 
                p1Slot = slot
            end
            if name == p2 then
                p2Slot = slot
            end
        end
    end

    turtle.select(p1Slot)
    turtle.dropDown(1)
    turtle.select(p2Slot)
    turtle.dropDown(1)

    turtle.forward()

    turtle.select(1)
    turtle.digDown()
    find_crop_tools()

    turtle.down()

    table.insert(ownedSeeds, target)
    return true
end


function taskBreed(target)
    local targetRaw = target
    target = string.lower(target)

    local seedRecipes = getRecipes()
    local knownSeeds = getKnownSeeds(seedRecipes)
    if not knownSeeds[target] then
        print("Unknown seed "..targetRaw)
        print("Seeds must be formatted like: minecraft:melon_seeds")
        return
    end

    local ownedSeeds = getOwnedSeeds(knownSeeds)

    if ownedSeeds[target] then
        print("Seed already owned")
        return
    end

    if not seedRecipes[target] then
        print("Don't know how to make seed "..targetRaw)
    end

    breed(seedRecipes, ownedSeeds, target)
end


function main(args)    
    if #args == 0 then
        local progName = shell.getRunningProgram()
        print("Usage: "..progName.." upgrade")
        print("or   : "..progName.." breed <seedId> ")
        return 0
    end

    if args[1] == "breed" then
        if #args < 2 then
            print("seedId not specified, please specify a seed")
            return 0
        end
        for i=2,#args do
            taskBreed(args[i])
        end
            
    elseif args[1] == "upgrade" then
        taskUpgrade()
    else
        print("Unknown mode '" + args[1] + "'")
        return 0
    end
end

main({...})