import "species"

Community = Community or {}

local Community = Community

local max = math.max
local min = math.min

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local function clamp(value, low, high)
    return max(low, min(high, value))
end

local function titleCase(value)
    return value:sub(1, 1):upper() .. value:sub(2)
end

function Community.new(tilemap, imagetable, options)
    local self = {
        tilemap = tilemap,
        imagetable = imagetable,
        width = options.width or 25,
        height = options.height or 15,
        size = (options.width or 25) * (options.height or 15),
        modes = {"neutral", "filtering", "competition"},
        modeIndex = 2,
        mode = options.mode or "filtering",
        colrate = options.colrate or 0.05,
        ecologicalStrength = options.ecologicalStrength or 0.35,
        ecologicalStrengthLabel = options.ecologicalStrengthLabel or "Medium",
        environmentOptimum = options.environmentOptimum or 0,
        time = 0,
        tiles = {},
        species = {},
        counts = {},
        positionsBySpecies = {},
        founderId = nil,
        lastMigrantCount = 0,
        lastLocalCount = 0,
        lastRichness = 0,
        lastDominantAbundance = 0,
    }

    setmetatable(self, {__index = Community})

    for index, mode in ipairs(self.modes) do
        if mode == self.mode then
            self.modeIndex = index
        end
    end

    self.catalog = SpeciesCatalog.build(imagetable)
    self.frontierCells = self:buildFrontierCells()
    self.allCells = self:buildAllCells()
    self.neighborsRadius1, self.neighborsRadius2 = self:buildNeighborMaps()
    self:reset()

    return self
end

function Community:setEcologicalStrength(value, label)
    self.ecologicalStrength = value

    if label then
        self.ecologicalStrengthLabel = label
    end
end

function Community:getEcologicalStrengthLabel()
    return self.ecologicalStrengthLabel
end

function Community:getRankAbundanceData()
    local abundances = {}

    for _, abundance in pairs(self.counts) do
        abundances[#abundances + 1] = abundance
    end

    table.sort(abundances, function(left, right)
        return left > right
    end)

    return abundances
end

function Community:buildAllCells()
    local cells = {}
    for index = 1, self.size do
        cells[index] = index
    end
    return cells
end

function Community:buildFrontierCells()
    local edge = {}
    local nearEdge = {}

    for y = 1, self.height do
        for x = 1, self.width do
            local index = self:xyToIndex(x, y)
            local isEdge = x == 1 or x == self.width or y == 1 or y == self.height
            local isNearEdge = x == 2 or x == self.width - 1 or y == 2 or y == self.height - 1

            if isEdge then
                edge[#edge + 1] = index
            elseif isNearEdge then
                nearEdge[#nearEdge + 1] = index
            end
        end
    end

    local cells = {}
    for _, index in ipairs(edge) do
        cells[#cells + 1] = index
    end
    for _, index in ipairs(nearEdge) do
        cells[#cells + 1] = index
    end

    return cells
end

function Community:buildNeighborMaps()
    local radius1 = {}
    local radius2 = {}

    for index = 1, self.size do
        local x, y = self:indexToXY(index)
        local neighbors1 = {}
        local neighbors2 = {}

        for dy = -2, 2 do
            for dx = -2, 2 do
                if dx ~= 0 or dy ~= 0 then
                    local nx = x + dx
                    local ny = y + dy

                    if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
                        local neighborIndex = self:xyToIndex(nx, ny)

                        if math.abs(dx) <= 1 and math.abs(dy) <= 1 then
                            neighbors1[#neighbors1 + 1] = neighborIndex
                        end

                        neighbors2[#neighbors2 + 1] = neighborIndex
                    end
                end
            end
        end

        radius1[index] = neighbors1
        radius2[index] = neighbors2
    end

    return radius1, radius2
end

function Community:shuffle(values)
    for index = #values, 2, -1 do
        local swapIndex = math.random(index)
        values[index], values[swapIndex] = values[swapIndex], values[index]
    end
end

function Community:xyToIndex(x, y)
    return (y - 1) * self.width + x
end

function Community:indexToXY(index)
    local zeroBased = index - 1
    local x = (zeroBased % self.width) + 1
    local y = math.floor(zeroBased / self.width) + 1
    return x, y
end

function Community:reset()
    self.time = 0
    self.tiles = {}
    self.species = {}
    self.counts = {}
    self.positionsBySpecies = {}
    self.lastMigrantCount = 0
    self.lastLocalCount = self.size

    local founder = SpeciesCatalog.pickFounder(self.catalog)
    founder.abundance = self.size
    founder.migrantsLastStep = 0
    founder.isFounder = true
    founder.origin = "resident"

    self.founderId = founder.id
    self.species[founder.id] = founder

    for index = 1, self.size do
        self.tiles[index] = founder.id
    end

    self:recountFromTiles()
    self:redrawTilemap()
end

function Community:cycleMode(direction)
    self.modeIndex += direction

    if self.modeIndex < 1 then
        self.modeIndex = #self.modes
    elseif self.modeIndex > #self.modes then
        self.modeIndex = 1
    end

    self.mode = self.modes[self.modeIndex]
end

function Community:adjustColonizationRate(delta)
    self.colrate = clamp(self.colrate + delta, 0, 0.25)
end

function Community:recountFromTiles()
    local counts = {}
    local positions = {}

    for index = 1, self.size do
        local speciesId = self.tiles[index]
        if speciesId then
            counts[speciesId] = (counts[speciesId] or 0) + 1

            local speciesPositions = positions[speciesId]
            if not speciesPositions then
                speciesPositions = {}
                positions[speciesId] = speciesPositions
            end

            speciesPositions[#speciesPositions + 1] = index
        end
    end

    self.counts = counts
    self.positionsBySpecies = positions
    self.lastRichness = self:getRichness()
    self.lastDominantAbundance = self:getDominantAbundance()
end

function Community:getRichness()
    local richness = 0
    for _ in pairs(self.counts) do
        richness += 1
    end
    return richness
end

function Community:getDominantAbundance()
    local dominant = 0
    for _, abundance in pairs(self.counts) do
        if abundance > dominant then
            dominant = abundance
        end
    end
    return dominant
end

function Community:getModeLabel()
    return titleCase(self.mode)
end

function Community:getMeanTrait()
    local totalTrait = 0

    for speciesId, abundance in pairs(self.counts) do
        local record = self.species[speciesId]
        totalTrait += record.trait * abundance
    end

    if self.size == 0 then
        return 0
    end

    return totalTrait / self.size
end

function Community:getFitnessMultiplier(speciesId, meanTrait)
    if self.mode == "neutral" then
        return 1
    end

    local trait = self.species[speciesId].trait
    local strength = max(0.15, self.ecologicalStrength)

    if self.mode == "filtering" then
        local diff = trait - self.environmentOptimum
        return 0.05 + math.exp(-((diff * diff) / (2 * strength * strength)))
    end

    local distance = math.abs(trait - meanTrait)
    return 0.15 + min(1.5, distance / strength)
end

function Community:activeSpeciesIds()
    local ids = {}
    for speciesId in pairs(self.counts) do
        ids[#ids + 1] = speciesId
    end
    return ids
end

function Community:sampleLocalCounts(count)
    local results = {}
    local speciesIds = self:activeSpeciesIds()

    if count <= 0 or #speciesIds == 0 then
        return results
    end

    if #speciesIds == 1 then
        results[speciesIds[1]] = count
        return results
    end

    local meanTrait = self:getMeanTrait()
    local weightedSpecies = {}
    local totalWeight = 0

    for _, speciesId in ipairs(speciesIds) do
        local abundance = self.counts[speciesId]
        local weight = abundance * self:getFitnessMultiplier(speciesId, meanTrait)
        weight = max(weight, 0.0001)
        totalWeight += weight
        weightedSpecies[#weightedSpecies + 1] = {
            id = speciesId,
            weight = weight,
        }
    end

    for _ = 1, count do
        local roll = math.random() * totalWeight
        local cumulative = 0

        for _, entry in ipairs(weightedSpecies) do
            cumulative += entry.weight
            if roll <= cumulative then
                results[entry.id] = (results[entry.id] or 0) + 1
                break
            end
        end
    end

    return results
end

function Community:mergeCounts(localCounts, migrantCounts)
    local merged = {}

    for speciesId, count in pairs(localCounts) do
        merged[speciesId] = count
    end

    for speciesId, count in pairs(migrantCounts) do
        merged[speciesId] = (merged[speciesId] or 0) + count
    end

    return merged
end

function Community:createFreeCellState()
    local state = {
        freeCells = {},
        freeLookup = {},
        frontierCells = {},
        frontierLookup = {},
    }

    for _, index in ipairs(self.allCells) do
        state.freeCells[#state.freeCells + 1] = index
        state.freeLookup[index] = #state.freeCells
    end

    for _, index in ipairs(self.frontierCells) do
        state.frontierCells[#state.frontierCells + 1] = index
        state.frontierLookup[index] = #state.frontierCells
    end

    return state
end

function Community:removeFromPool(pool, lookup, index)
    local position = lookup[index]
    if not position then
        return
    end

    local lastIndex = pool[#pool]
    pool[position] = lastIndex
    lookup[lastIndex] = position
    pool[#pool] = nil
    lookup[index] = nil
end

function Community:claimFreeCell(state, index)
    self:removeFromPool(state.freeCells, state.freeLookup, index)
    self:removeFromPool(state.frontierCells, state.frontierLookup, index)
end

function Community:chooseRandomFromPool(pool)
    if #pool == 0 then
        return nil
    end

    return pool[math.random(#pool)]
end

function Community:chooseAnyFreeCell(state)
    return self:chooseRandomFromPool(state.freeCells)
end

function Community:chooseMigrantCell(state)
    local frontier = self:chooseRandomFromPool(state.frontierCells)
    if frontier then
        return frontier
    end

    return self:chooseAnyFreeCell(state)
end

function Community:attemptNeighborPlacement(state, seeds, neighborMap, attempts)
    local seedCount = #seeds
    if seedCount == 0 then
        return nil
    end

    for _ = 1, attempts do
        local seed = seeds[math.random(seedCount)]
        local neighbors = neighborMap[seed]

        if neighbors and #neighbors > 0 then
            local neighbor = neighbors[math.random(#neighbors)]
            if state.freeLookup[neighbor] then
                return neighbor
            end
        end
    end

    return nil
end

function Community:chooseClusteredCell(state, seeds)
    local cell = self:attemptNeighborPlacement(state, seeds, self.neighborsRadius1, 12)
    if cell then
        return cell
    end

    cell = self:attemptNeighborPlacement(state, seeds, self.neighborsRadius2, 20)
    if cell then
        return cell
    end

    return self:chooseAnyFreeCell(state)
end

function Community:placeSpeciesAtCell(nextTiles, state, positions, index, speciesId)
    nextTiles[index] = speciesId
    self:claimFreeCell(state, index)

    local speciesPositions = positions[speciesId]
    if not speciesPositions then
        speciesPositions = {}
        positions[speciesId] = speciesPositions
    end

    speciesPositions[#speciesPositions + 1] = index
end

function Community:buildPlacementOrder(counts)
    local order = {}
    for speciesId, count in pairs(counts) do
        order[#order + 1] = {
            id = speciesId,
            count = count,
        }
    end

    table.sort(order, function(left, right)
        return left.count > right.count
    end)

    return order
end

function Community:buildNextTiles(localCounts, migrantCounts)
    local nextTiles = {}
    local freeState = self:createFreeCellState()
    local nextPositions = {}

    local migrantQueue = {}
    for speciesId, count in pairs(migrantCounts) do
        for _ = 1, count do
            migrantQueue[#migrantQueue + 1] = speciesId
        end
    end
    self:shuffle(migrantQueue)

    for _, speciesId in ipairs(migrantQueue) do
        local cell = self:chooseMigrantCell(freeState)
        if cell then
            self:placeSpeciesAtCell(nextTiles, freeState, nextPositions, cell, speciesId)
        end
    end

    local localOrder = self:buildPlacementOrder(localCounts)

    for _, entry in ipairs(localOrder) do
        local seeds = {}
        local previous = self.positionsBySpecies[entry.id]
        local alreadyPlaced = nextPositions[entry.id]

        if previous then
            for _, index in ipairs(previous) do
                seeds[#seeds + 1] = index
            end
        end

        if alreadyPlaced then
            for _, index in ipairs(alreadyPlaced) do
                seeds[#seeds + 1] = index
            end
        end

        for _ = 1, entry.count do
            local cell = self:chooseClusteredCell(freeState, seeds)
            if cell then
                self:placeSpeciesAtCell(nextTiles, freeState, nextPositions, cell, entry.id)
                seeds[#seeds + 1] = cell
            end
        end
    end

    return nextTiles, nextPositions
end

function Community:rebuildSpeciesRecords(nextCounts, migrantCounts, previousCounts)
    local nextSpecies = {}

    for speciesId, abundance in pairs(nextCounts) do
        local record = shallowCopy(self.species[speciesId] or SpeciesCatalog.cloneFromCatalog(self.catalog, speciesId))
        record.abundance = abundance
        record.migrantsLastStep = migrantCounts[speciesId] or 0
        record.isFounder = speciesId == self.founderId
        record.origin = previousCounts[speciesId] and "resident" or "meta"
        nextSpecies[speciesId] = record
    end

    self.species = nextSpecies
end

function Community:redrawTilemap()
    for y = 1, self.height do
        for x = 1, self.width do
            local index = self:xyToIndex(x, y)
            local speciesId = self.tiles[index]
            local tileIndex = 1

            if speciesId and self.species[speciesId] then
                tileIndex = self.species[speciesId].tileIndex
            end

            self.tilemap:setTileAtPosition(x, y, tileIndex)
        end
    end
end

function Community:step()
    self:recountFromTiles()

    local previousCounts = shallowCopy(self.counts)
    local migrantCount = 0

    for _ = 1, self.size do
        if math.random() <= self.colrate then
            migrantCount += 1
        end
    end

    local migrantCounts = SpeciesCatalog.sampleMigrantCounts(self.catalog, migrantCount)
    local localCount = self.size - migrantCount
    local localCounts = self:sampleLocalCounts(localCount)
    local nextCounts = self:mergeCounts(localCounts, migrantCounts)
    local nextTiles, nextPositions = self:buildNextTiles(localCounts, migrantCounts)

    self.time += 1
    self.lastMigrantCount = migrantCount
    self.lastLocalCount = localCount
    self.tiles = nextTiles
    self.counts = nextCounts
    self.positionsBySpecies = nextPositions

    self:rebuildSpeciesRecords(nextCounts, migrantCounts, previousCounts)
    self.lastRichness = self:getRichness()
    self.lastDominantAbundance = self:getDominantAbundance()
    self:redrawTilemap()
end

return Community
