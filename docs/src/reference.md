```@meta
CurrentModule = ForestMensuration
```

Documentation for [ForestMensuration](https://github.com/JuliaForests/ForestMensuration.jl).

# Reference

```@docs
ForestMensuration
ForestInventory
```

## Cubage

```@docs
cubage
treevolume
CubingMethod
Smalian
Huber
Newton
smalian
newton
huber
artificialformfactor
barkfactor
barkpercentage
conevolume
cylindervolume
```

## Stand Structure

The structure of a stand, or of the species of a community, per hectare:

```@docs
standmetrics
```

The diameter averages that are not in the summary, one by one, for those who need them:

```@docs
arithmeticmeandiameter
quadraticmeandiameter
weisediameter
centralbasalareadiameter
dominantdiameter
hohenaldiameters
```

## Frequency and Diametric Tables

```@docs
frequencytable
diametrictable
```

## Forest Inventory Sampling (re-exported from ForestInventory.jl)

```@autodocs
Modules = [ForestInventory]
Order = [:function, :type, :constant]
```

## Forest Community Biodiversity

```@docs
communitymatrix
diversity
floristicdistance
floristicsimilarity
speciesaccumulation
```
