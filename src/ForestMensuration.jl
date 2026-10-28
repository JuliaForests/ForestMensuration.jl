"""
Description:

ForestMensuration.jl is a Julia package that provides a comprehensive set of functions for performing dendrometric calculations, for both planted and native forests. Designed with ease of use in mind, the package offers tools that simplify complex forestry calculations, making it straightforward to:

- **Calculate the volume of felled trees (cubage)**: [`cubage`](@ref) gives the volume of the whole tree from the diameters measured at absolute heights (the stump, the sections by Smalian's method and the tip) and the form factor, with and without bark, for one tree or many trees told apart by `id`. Logs measured at relative positions (equal sections) give only the volume of the log, with [`smalian`](@ref) and [`huber`](@ref) and the length of the log, one log or a field sheet with a log per row. Nothing is interpolated: the diameter at breast height and the total height are always the annotated values.
- **Characterize the stand**: [`standmetrics`](@ref) gives the number of trees, the basal area, the mean and quadratic mean diameters and their coefficient of variation per hectare, and, with the species and the plots of the trees, the horizontal structure and the phytosociological indices (density, dominance, frequency, cover value and Importance Value Index) of each species. The other averages (Weise, central basal area, dominant and Hohenadl diameters) are available one by one.
- **Create frequency tables**: Generate frequency and diametric tables to analyze the distribution of dendrometric variables such as diameter and height.
- **Estimate forest inventory sampling designs**: all 14 designs, each its own
  function taking plain vectors — simple ([`simplecasualsampling`](@ref)), stratified
  ([`stratifiedsampling`](@ref)), systematic ([`systematicsampling`](@ref),
  [`multistartsystematicsampling`](@ref)), cluster/two-stage ([`clustersampling`](@ref),
  [`twostagesampling`](@ref)), horizontal point/Bitterlich angle-count sampling
  ([`horizontalpointsampling`](@ref)), and the four sampling-on-successive-occasions
  designs ([`independentoccasionssampling`](@ref), [`completereplacementsampling`](@ref),
  [`partialreplacementsampling`](@ref), [`doublesampling`](@ref)), plus horizontal line
  ([`strandsampling`](@ref)), Prodan's k-tree ([`prodansampling`](@ref)) and 3P
  ([`threepsampling`](@ref)) sampling — every one generic to
  any number of strata/clusters/plots and returning a [`SamplingReport`](@ref). Re-exported from
  [ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl).
- **Describe native forest community structure**: [`communitymatrix`](@ref), [`diversity`](@ref),
  [`floristicdistance`](@ref)/[`floristicsimilarity`](@ref), and
  [`speciesaccumulation`](@ref) cover biodiversity indices, floristic similarity, and
  species accumulation/rarefaction curves for native/mixed forest inventories, besides the
  Importance Value Index of [`standmetrics`](@ref).

The package facilitates the analysis of dendrometric and forest data, performs complex calculations with simple commands, and offers a user-friendly and intuitive interface.

# Units of measurement

Every function is built on `Unitful` quantities, so measurements carry their unit and are
converted automatically. Diameters may be given in `cm`, `mm`, `inch`, ... and heights in
`m`, `ft`, ..., in any combination; results are normalised to a single coherent unit:
areas come back in `m^2`, or in `ft^2` when the diameters are imperial, and volumes in
`m^3`, or in `ft^3` when the lengths (heights) are imperial.

Lengths, areas and volumes must always carry units: a plain number says nothing about
whether it was measured in `cm`, `m` or `inch`, so assuming a unit could fail silently.
Write `30u"cm"` (or `[30.0, 25.0]u"cm"` for a vector). The one deliberate exception is
`frequencytable`, which classifies any variable and therefore stays unitless when given
unitless data — use `diametrictable` for diameter-specific tables.

Results always carry units; use `stripunits`/`parseunits` (re-exported from
`ForestFoundations`) to move between unitful DataFrames and plain numeric ones for export.
"""
module ForestMensuration
using DataFrames, Distributions, ForestFoundations, ForestInventory, Random, Reexport, StatsBase

@reexport using ForestFoundations
@reexport using ForestInventory

include("distributiontables.jl")
include("dendrometrics.jl")
include("cubage.jl")
include("biodiversity.jl")
include("accumulation.jl")

export
  # Cubage
  artificialformfactor,
  barkfactor,
  barkpercentage,
  conevolume,
  cubage,
  cylindervolume,
  smalian,
  newton,
  huber,
  # Stand structure, and the single diameter averages for those who need them one by one
  standmetrics,
  arithmeticmeandiameter,
  quadraticmeandiameter,
  weisediameter,
  centralbasalareadiameter,
  dominantdiameter,
  hohenaldiameters,
  # Frequency tables
  diametrictable,
  frequencytable,
  # Native forest biodiversity
  communitymatrix,
  diversity,
  floristicdistance,
  floristicsimilarity,
  speciesaccumulation

end
