SpeciesCatalog = SpeciesCatalog or {}

local SpeciesCatalog = SpeciesCatalog

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local function weightedChoice(items, weightKey, totalWeight)
    if #items == 0 then
        return nil
    end

    local roll = math.random() * totalWeight
    local cumulative = 0

    for _, item in ipairs(items) do
        cumulative += item[weightKey]
        if roll <= cumulative then
            return item
        end
    end

    return items[#items]
end

function SpeciesCatalog.build(imagetable)
    local count = imagetable:getSize()
    local catalog = {
        list = {},
        metaList = {},
        byId = {},
        totalMetaWeight = 0,
    }

    for tileIndex = 2, count do
        local record = {
            id = "m" .. tileIndex,
            name = "Species " .. (tileIndex - 1),
            tileIndex = tileIndex,
            trait = math.random() * 2 - 1,
            metaWeight = 1,
            isMetaSpecies = true,
        }

        catalog.list[#catalog.list + 1] = record
        catalog.metaList[#catalog.metaList + 1] = record
        catalog.byId[record.id] = record
        catalog.totalMetaWeight += record.metaWeight
    end

    return catalog
end

function SpeciesCatalog.cloneFromCatalog(catalog, speciesId)
    local base = catalog.byId[speciesId]
    if not base then
        return nil
    end

    return shallowCopy(base)
end

function SpeciesCatalog.pickFounder(catalog)
    local base = catalog.metaList[math.random(#catalog.metaList)]
    return shallowCopy(base)
end

function SpeciesCatalog.sampleMigrantCounts(catalog, count)
    local counts = {}

    if count <= 0 then
        return counts
    end

    for _ = 1, count do
        local choice = weightedChoice(catalog.metaList, "metaWeight", catalog.totalMetaWeight)
        counts[choice.id] = (counts[choice.id] or 0) + 1
    end

    return counts
end

return SpeciesCatalog
