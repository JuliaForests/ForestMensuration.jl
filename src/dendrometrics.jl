"""
    arithmeticmeandiameter(d::AbstractVector{<:Length})

Calculates the arithmetic mean diameter (``\\bar{D}``) of a forest stand or sample.

# Arguments
- `d`: vector of diameters at breast height with length units (e.g., cm or inch).

# Returns
- `Quantity`: the arithmetic mean diameter in the same units as input.

# Mathematical basis
The simple average of all measured diameters:

```math
\\bar{D} = \\frac{\\sum_{i=1}^{n} D_i}{n}
```

# Technical description

The arithmetic mean is primarily used to characterize the frequency distribution of a stand.
It is essential for biological research and serves as the base for the Hohenadl diameters.
In even-aged stands the arithmetic mean is generally smaller than the quadratic mean
diameter ``D_g``, following the sequence ``D_- < \\bar{D} < D_g < D_w < d_z < D_+``. Unlike
``D_g``, the arithmetic mean is highly sensitive to thinning interventions.

# Examples

```julia-repl
julia> d = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm";
julia> arithmeticmeandiameter(d)
17.25 cm
```

# References
Finger, C. A. G. (2006). *Biometria Florestal*. Santa Maria: UFSM, Section 12.1.1, p. 177.
"""
arithmeticmeandiameter(d::AbstractVector{<:Length}) = mean(d)

"""
    quadraticmeandiameter(d::AbstractVector{<:Length})

Calculates the quadratic mean diameter (``D_g``) of a forest stand or sample. This metric
represents the diameter of the tree with the mean basal area.

# Arguments
- `d`: vector of diameters at breast height with length units (e.g., cm or inch).

# Returns
- `Quantity`: quadratic mean diameter in the same unit as input.

# Mathematical basis
Calculated as the square root of the average of squared diameters:

```math
D_g = \\sqrt{\\frac{\\sum_{i=1}^{n} D_i^2}{n}}
```

Alternatively, derived from the arithmetic mean and the variance:

```math
D_g = \\sqrt{\\bar{D}^2 + s_D^2}
```

# Technical description

``D_g`` is fundamental in forest mensuration and production models. It is preferred over the
arithmetic mean because it correlates more strongly with stand volume, giving additional weight
to the larger diameters, which hold most of the biomass. In even-aged stands ``D_g`` is always
greater than or equal to the arithmetic mean.

# Examples

```julia-repl
julia> d = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm";
julia> quadraticmeandiameter(d)
17.779904386694547 cm
```

# References
Finger, C. A. G. (2006). *Biometria Florestal*. Santa Maria: UFSM, Section 12.1.2, p. 178.
"""
quadraticmeandiameter(d::AbstractVector{<:Length}) = √(mean(abs2, d))

"""
    weisediameter(d::AbstractVector{<:Length})

Calculates Weise's diameter (``D_w``), the diameter of the tree at the position where 60 % of
the trees are below it, with the diameters in increasing order.

# Arguments
- `d`: vector of diameters at breast height with length units (e.g., cm or inch).

# Returns
- `Quantity`: diameter of the tree at the 60 % position, in the same unit as input.

# Mathematical basis
With the ``n`` diameters sorted in increasing order, it is the one at the position
``\\operatorname{round}(0.6\\,n)``, a measured diameter (no interpolation):

```math
D_w = D_{(\\operatorname{round}(0.6\\,n))}
```

# Technical description

Proposed by Weise (1880), this diameter approximates the tree with mean stand volume. In
even-aged stands it separates the 60 percent smallest trees from the 40 percent largest.

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Section 2.6.4.
Finger, C. A. G. (2006). *Biometria Florestal*. Santa Maria: UFSM, Section 12.1.3, p. 180.

# Examples

```julia-repl
julia> d = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm";
julia> weisediameter(d)
18.0 cm
```
"""
weisediameter(d::AbstractVector{<:Length}) = sort(d)[max(1, round(Int, 0.6length(d)))]

"""
    centralbasalareadiameter(d::AbstractVector{<:Length})

Calculates the diameter of the central basal area tree (``d_z``), the diameter at the point
where the cumulative basal area reaches half of the total.

# Arguments
- `d`: vector of diameters at breast height with length units (e.g., cm or inch).

# Returns
- `Quantity`: diameter of the tree where the cumulative basal area reaches half of the total,
  in the same unit as input.

# Mathematical basis
With the ``n`` diameters sorted in increasing order, it is the first one ``D_{(k)}`` whose
cumulative basal area reaches half of the total, a measured diameter (no interpolation):

```math
d_z = D_{(k)}, \\quad k = \\min\\left\\{ j : \\sum_{i=1}^{j} D_{(i)}^2 \\ge \\frac{1}{2} \\sum_{i=1}^{n} D_{(i)}^2 \\right\\}
```

# Technical description

It splits the basal area in two equal halves, one with the smaller trees and one with the larger
ones, so it is larger than the diameter of the median tree. For grouped data the book interpolates
inside the class where the half is reached; with the diameters of the trees it is the tree itself.

# Examples

```julia-repl
julia> d = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm";
julia> centralbasalareadiameter(d)
19.5 cm
```

# References
Floriano, E. P. (2025). *Dendrometria*, 2nd edition, Section 2.2.11.
Finger, C. A. G. (2006). *Biometria Florestal*. Santa Maria: UFSM, Section 12.1.4, p. 181.
"""
function centralbasalareadiameter(d::AbstractVector{<:Length})
  sorted = sort(d)
  basalarea = cumsum(abs2.(sorted))
  return sorted[findfirst(≥(last(basalarea) / 2), basalarea)]
end


# Auxiliary function that calculates the target number of dominant trees (n_D) for the plot.
# Returns 0 if the sample size is insufficient; callers then answer with `NaN * first(d)`, a
# NaN that keeps the unit, so a missing dominant diameter still reads as a diameter and the
# DataFrame columns stay type-consistent.
function dominanttreecount(d::AbstractVector{<:Length}, area::Area)
  # detect unit system from the plot area and the matching dominant-tree sampling standard
  # (100 trees/ha for metric, 40 trees/ac for imperial)
  refarea = referencearea(area)
  standard = refarea == u"ha" ? 100 : 40
  nD = round(Int, ustrip(refarea, standard * area))
  # validate against sample size: zero if we need more trees than available
  return 0 < nD <= length(d) ? nD : 0
end

# Auxiliary function that picks the dominant trees: the indices of the nD thickest trees, or
# `nothing` if the sample is insufficient.
function _dominantindices(d::AbstractVector{<:Length}, area::Area)
  nD = dominanttreecount(d, area)
  return iszero(nD) ? nothing : partialsortperm(d, 1:nD, rev=true)
end

"""
    dominantdiameter(d::AbstractVector{<:Length}, area::Area)

Calculates the dominant diameter (``D_D``) based on Assmann's definition: the quadratic mean
diameter of the 100 thickest trees per hectare or 40 per acre.

# Arguments
- `d`: vector of diameters at breast height with length units (e.g., cm or inch).
- `area`: total sampled area used to determine the number of dominant trees.

# Returns
- `Quantity`: the quadratic mean diameter of the dominant trees in the same unit as input, or a `NaN` in that unit when the plot holds fewer trees than the dominant-tree standard requires.

# Mathematical basis
The number of dominant trees ``n_D`` is determined by the spatial density standard of
100 trees per hectare (metric) or 40 trees per acre (imperial):

```math
n_D = 100 \\times \\text{area}_{ha} \\qquad \\text{or} \\qquad n_D = 40 \\times \\text{area}_{ac}
```

then

```math
D_D = \\sqrt{\\frac{\\sum_{i=1}^{n_D} D_{(i)}^2}{n_D}}
```

where ``D_{(i)}`` are the diameters sorted in descending order.

# Technical description

The dominant diameter is a stable stand variable used to characterize the productive capacity
of the site. If ``n_D`` exceeds the sample size, the result is `NaN`.

# Examples

```julia-repl
# metric example, 100 per ha
julia> d = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm";
julia> plotArea = 500u"m^2";
julia> dominantdiameter(d, plotArea)
21.106870919205434 cm
```

# References
Finger, C. A. G. (2006). *Biometria Florestal*. Santa Maria: UFSM, Section 12.2.6.1, p. 187.
"""
function dominantdiameter(d::AbstractVector{<:Length}, area::Area)
  idx = _dominantindices(d, area)
  # return nan (in the diameter unit) if sample is insufficient or invalid
  isnothing(idx) && return NaN * first(d)
  # quadratic mean of the nD thickest trees (the diameter of their mean basal area)
  return quadraticmeandiameter(d[idx])
end

"""
    hohenaldiameters(d::AbstractVector{<:Length})

Calculates Hohenadl's diameters ``D_-`` and ``D_+``. These metrics represent one standard
deviation below and above the mean diameter.

# Arguments
- `d`: vector of diameters at breast height with length units (e.g., cm or inch).

# Returns
- `NamedTuple`: containing keys `Dl` (``D_-``) and `Du` (``D_+``) in the same units as input.

# Mathematical basis
Calculated using the arithmetic mean ``\\bar{D}`` and the standard deviation ``s_D``:

```math
D_- = \\bar{D} - s_D \\qquad D_+ = \\bar{D} + s_D
```

# Technical description

Approximately 16 percent of the trees have diameters below ``D_-``, one standard deviation
below the mean, and approximately 84 percent have diameters below ``D_+``, one standard
deviation above the mean. These metrics are useful for understanding the variability and
distribution of diameters within the stand.

# Examples

```julia-repl
julia> d = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm";
julia> hohenadl = hohenaldiameters(d)
(Dl = 12.708524468853764 cm, Du = 21.791475531146236 cm)
# access specific values
julia> hohenadl.Dl
12.708524468853764 cm
julia> hohenadl.Du
21.791475531146236 cm

```

# References
Finger, C. A. G. (2006). *Biometria Florestal*. Santa Maria: UFSM, Section 12.1.5, p. 182.
"""
function hohenaldiameters(d::AbstractVector{<:Length})
  dmean, sD = mean_and_std(d)
  return (; Dl=dmean - sD, Du=dmean + sD)
end

"""
    standmetrics(d::AbstractVector{<:Length}, area::Area)
    standmetrics(species::AbstractVector, plots::AbstractVector, d::AbstractVector{<:Length}, area::Area)

Calculates the structure of a stand from the diameters at breast height of the sampled trees: the number of trees, the basal area, the mean diameters and their dispersion, scaled to a hectare (or an acre). With the species and the plots of the trees, it gives the same metrics for each species together with the horizontal structure and the phytosociological indices of the community.

# Arguments
- `d`: vector of diameters at breast height with length units (e.g., cm or inch).
- `area`: the sampled area, as an `Area` quantity: the area of the plot, or, with several plots, the total sampled area (all the plots together).
- `species`: the species of each tree, strings or symbols, in the order of `d`.
- `plots`: the plot (sampling unit) of each tree, in the order of `d`.

# Units

The diameters are reported in the unit of `d`. The basal area `g` is in square meters (`m^2`), or square feet (`ft^2`) when the diameters are imperial, and `N` and `G` are expressed per hectare (`ha^-1`) in the metric system and per acre (`ac^-1`) in the imperial one. The other columns are dimensionless.

# Returns
A `DataFrame` with a single row for the sample, or one row per species, sorted by the importance value index (IVI) descending. The columns follow the standard symbology of forest mensuration: lowercase for the sample, uppercase for the values per unit area.

**Sample and per unit area**
* `n`: number of trees in the sample.
* `g`: basal area of the sample, the sum of the basal areas of the trees.
* `N`: **Absolute Density**, the estimated number of trees per unit area (ha or ac), ``N = n F``. For a species it is the population density of the species.
* `G`: **Absolute Dominance**, the basal area per unit area (m²/ha or ft²/ac), ``G = g F``. It indicates the physical space occupied by the species.
* `Dm`: arithmetic mean diameter, ``\\bar{D}``.
* `Dg`: quadratic mean diameter, ``D_g``, the diameter of the tree with mean basal area, the one that links the number of trees to the basal area of the stand.
* `CD`: coefficient of variation of the diameters, ``C_D = 100 s_D / \\bar{D}``, in percent. It measures the heterogeneity of the sizes: a low value is an even-sized stand, a high one a stand with many size classes. It is `NaN` for a single tree, which has no standard deviation.

**Horizontal structure of the community** (only with `species` and `plots`)
* `plots`: **Plots**, the number of unique plots where the species was recorded.
* `AF`: **Absolute Frequency**, the percentage of the sampling units in which the species occurs, indicating the uniformity of its spatial distribution.
* `RDe`: **Relative Density**, the proportion of the density `N` of the species relative to the total density of all species in the community.
* `RDo`: **Relative Dominance**, the proportion of the basal area `G` of the species relative to the total stand basal area.
* `RF`: **Relative Frequency**, the frequency of the species expressed as a percentage of the sum of the absolute frequencies of all species.

**Integrated phytosociological indices** (only with `species` and `plots`)
* `VC`: **Cover Value**, the sum of the Relative Density and the Relative Dominance (RDe + RDo). This index characterizes the ecological importance and space utilization of a species, emphasizing abundance and dominance over distribution.
* `IVI`: **Importance Value Index**, the mean of the three relative parameters ((RDe + RDo + RF) / 3). It provides an overall "ecological score" for the species within the community.

# Mathematical basis
With the diameters ``D_i`` of the ``n`` trees, the arithmetic mean and the standard deviation (with ``n - 1``) are

```math
\\bar{D} = \\frac{\\sum_{i=1}^{n} D_i}{n} \\qquad
s_D = \\sqrt{\\frac{\\sum_{i=1}^{n} (D_i - \\bar{D})^2}{n - 1}} \\qquad
C_D = \\frac{s_D}{\\bar{D}} \\times 100
```

The quadratic mean diameter is the square root of the mean of the squared diameters, which is the arithmetic mean squared plus the variance of the population, so it comes from ``\\bar{D}`` and ``s_D`` without another pass through the data, and the basal area of the sample follows from it (``g_i = \\pi D_i^2 / 4``):

```math
D_g = \\sqrt{\\frac{\\sum_{i=1}^{n} D_i^2}{n}} = \\sqrt{\\bar{D}^2 + \\frac{n - 1}{n} s_D^2} \\qquad
g = \\sum_{i=1}^{n} g_i = n \\, \\frac{\\pi D_g^2}{4}
```

The expansion factor ``F`` (``F = 1\\,\\text{ha} / A``, with ``A`` the sampled area) scales the sample to a hectare:

```math
N = n F \\qquad G = g F
```

For the species ``i`` of a community of ``S`` species, with ``p_i`` the plots where it occurs out of ``P`` plots, the horizontal structure and the indices are:

```math
AF_i = \\frac{p_i}{P} \\times 100 \\qquad
RDe_i = \\frac{N_i}{\\sum_{j=1}^{S} N_j} \\times 100 \\qquad
RDo_i = \\frac{G_i}{\\sum_{j=1}^{S} G_j} \\times 100 \\qquad
RF_i = \\frac{AF_i}{\\sum_{j=1}^{S} AF_j} \\times 100
```

```math
VC_i = RDe_i + RDo_i \\qquad IVI_i = \\frac{RDe_i + RDo_i + RF_i}{3}
```

# Technical description
This is the primary entry point to characterize a stand or a community from the diameters. The expansion factor automatically detects whether the inputs are in the metric or imperial system. The sums of `N` and `G` over the species are the `N` and `G` of the stand. The metrics that are not here, the Weise, central basal area, dominant and Hohenadl diameters, are available one by one for those who need them: [`weisediameter`](@ref), [`centralbasalareadiameter`](@ref), [`dominantdiameter`](@ref) and [`hohenaldiameters`](@ref), besides [`arithmeticmeandiameter`](@ref) and [`quadraticmeandiameter`](@ref). The dominant diameter is a property of the stand (the thickest trees per hectare), not of a species, so it is not calculated by species.

# Examples

```julia-repl
julia> d = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm";
julia> standmetrics(d, 500u"m^2")
1×7 DataFrame
 Row │ n      g             N            G                  Dm         Dg          CD
     │ Int64  Quantity…     Quantity…    Quantity…          Quantity…  Quantity…   Float64
─────┼─────────────────────────────────────────────────────────────────────────────────────
   1 │    10  0.248284 m^2  200.0 ha^-1  4.96568 m^2 ha^-1   17.25 cm  17.7799 cm  26.3274

julia> species = ["Oak", "Oak", "Pine", "Pine", "Pine", "Maple", "Oak", "Pine"];
julia> plots = [1, 1, 1, 2, 2, 2, 3, 3];
julia> d = [30.0, 22.5, 40.0, 35.2, 28.7, 15.4, 26.1, 33.9]u"cm";
julia> standmetrics(species, plots, d, 0.3u"ha")
3×15 DataFrame
 Row │ species  n      g              N              G                    Dm         Dg          CD        plots  RDe      RDo       AF        RF       VC        IVI
     │ String   Int64  Quantity…      Quantity…      Quantity…            Quantity…  Quantity…   Float64   Int64  Float64  Float64   Float64   Float64  Float64   Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Pine         4   0.377929 m^2  13.3333 ha^-1    1.25976 m^2 ha^-1   34.45 cm  34.6841 cm   13.4835      3     50.0  67.4266   100.0     50.0     117.427   55.8089
   2 │ Oak          3   0.163949 m^2     10.0 ha^-1   0.546496 m^2 ha^-1    26.2 cm  26.3784 cm   14.3168      2     37.5  29.2502    66.6667  33.3333   66.7502  33.3612
   3 │ Maple        1  0.0186265 m^2  3.33333 ha^-1  0.0620883 m^2 ha^-1    15.4 cm     15.4 cm  NaN           1     12.5   3.32317   33.3333  16.6667   15.8232  10.8299
```

# References
Finger, C. A. G. (2006). *Biometria Florestal*. Santa Maria: UFSM, Section 12.1.
Curtis, J. T. & McIntosh, R. P. (1951). An upland forest continuum in the prairie-forest border region of Wisconsin. *Ecology*, 32(3), 476-496.
"""
function standmetrics(d::AbstractVector{<:Length}, area::Area)
  n = length(d)
  Dm, sD = mean_and_std(d)
  # Dg² = Dm² + variance of the population
  Dg = n > 1 ? sqrt(Dm^2 + sD^2 * (n - 1) / n) : Dm
  g = n * sectionalarea(Dg)
  EF = expansionfactor(area)
  return DataFrame(n=n, g=g, N=n * EF, G=g * EF, Dm=Dm, Dg=Dg, CD=sD / Dm * 100)
end

function standmetrics(species::AbstractVector, plots::AbstractVector, d::AbstractVector{<:Length}, area::Area)
  checklengths(:species => species, :plots => plots, :d => d)
  nplots = unique(plots) |> length
  ft = combine(groupby(DataFrame(species=species, plots=plots, d=d), :species)) do s
    hcat(standmetrics(s.d, area), DataFrame(plots=unique(s.plots) |> length))
  end
  # RDe: Relative Density (%)
  ft.RDe = (ft.N ./ sum(ft.N)) .* 100
  # RDo: Relative Dominance (%)
  ft.RDo = (ft.G ./ sum(ft.G)) .* 100
  # AF: Absolute Frequency (%)
  ft.AF = (ft.plots ./ nplots) .* 100
  # RF: Relative Frequency (%)
  ft.RF = (ft.AF ./ sum(ft.AF)) .* 100
  # VC: Cover Value (%)
  ft.VC = ft.RDe .+ ft.RDo
  # IVI: Importance Value Index (%)
  ft.IVI = (ft.VC .+ ft.RF) ./ 3
  # Sort by IVI descending
  sort!(ft, :IVI, rev=true)
  return ft
end
