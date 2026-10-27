# Getting Started

## Computing the Cubage

Two functions calculate the rigorous volume of felled trees from the diameters measured along the bole. The first argument of both is the **method**, the formula that matches where the diameters were measured on the bole: `Smalian` (at the ends of the sections), `Huber` (at their middles) or `Newton` (at both). The measurements are the heights annotated in the field (the absolute method), or only the length of the log, when the sections are equal (the relative method, see below).

- `cubage` gives the commercial volume, the one that was actually **measured**: the sections between the measurements, since the diameters are measured up to the commercial height. It only needs the heights and the diameters.
- `treevolume` extends it to the whole tree: the stump and the tip, which are not measured but modeled (a cylinder and a cone), and the form factor. It needs the diameter at breast height `D` and the total height `H` of each tree.

Variable names follow the symbology standardized by the Brazilian Association of Forest Mensuration (Silva et al., 2022; see the Bibliography): `D` is the diameter at breast height, `H` the total height, `d` and `h` a diameter and a height at any position of the stem, `E` the bark thickness, `v` a volume, `f` the form factor, and the suffix `s` means without bark.

Nothing is interpolated: the volumes use only the measured diameters, and `D` and `H` are always the annotated values, never read from the profile (the height of the diameter at breast height is not the same in every country). All lengths must carry units (e.g., `cm` for diameters and `m` for heights; any length unit works).

### The Measured Volume

The numerical examples are the tree of Machado & Figueiredo Filho (2003), Chapter 5, Tables 5.1 to 5.3 (diameter at breast height 22.3 cm, total height 15.9 m).

```@example ex_cub_01
using ForestMensuration
using Unitful

# Heights (m) and diameters with bark (cm) of the measurements, from the stump up (Table 5.1)
h = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3]u"m"
d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2]u"cm"

# Smalian's method: every measurement is the end of a section
cubage(Smalian, h, d)
```

\

With Huber's and Newton's methods the measurements alternate between the limit of a section and its middle, from a limit to a limit. Huber uses only the diameters at the middles, and Newton uses all of them.

```@example ex_cub_01
# Limits at 0.1, 1.3, 3.3, ..., 15.3 m; middles at 0.7, 2.3, 4.3, ..., 14.3 m (Table 5.3)
hn = [0.1, 0.7, 1.3, 2.3, 3.3, 4.3, 5.3, 6.3, 7.3, 8.3, 9.3, 10.3, 11.3, 12.3, 13.3, 14.3, 15.3]u"m"
dn = [27.7, 24.8, 22.3, 20.7, 20.3, 19.4, 18.8, 18.1, 17.5, 17.0, 14.3, 11.5, 9.5, 7.6, 6.0, 4.5, 1.2]u"cm"

cubage(Huber, hn, dn)
```

\

```@example ex_cub_01
cubage(Newton, hn, dn)
```

\

#### Including Bark Thickness

With the bark thickness it is possible to calculate the volume without bark, the volume of the bark and the bark factor. Note: the thickness `E` is the bark thickness (one side of the stem), as a length quantity; the diameter without bark is `ds = d - 2E`, and the function takes care of the factor 2.

```@example ex_cub_01
# Bark thickness at the corresponding heights (cm), (d - ds) / 2 with the diameters without bark of Table 5.1
E = [1.8, 1.7, 1.55, 1.2, 1.0, 0.7, 0.6, 0.4, 0.1]u"cm"

cubage(Smalian, h, d, E)
```

\

- `vm`, `vms`: Commercial volume with bark and without bark (suffix `s` = without bark)
- `vb`: Volume of the bark (`vm - vms`)
- `kb`: Bark factor
- `pb`: Percentage of bark, the share of the volume with bark that is bark (`barkpercentage(vm, vms)`)

#### Equal Sections: the Relative Method

In the relative method the log is divided into a number of equal sections, and what matters is the number of positions, not their percentages: only the length `l` of the log and the diameters, in order, are needed. There is no total height, no stump, no tip and so no form factor. It is called with the length of the log instead of the heights, `cubage(method, l, d)`.

The relative method is the way of **measuring**, the methodology of Hohenadl: equal sections, with the same relative positions in every log. The **calculation** is the formula of the method that matches where the diameters were taken:

| Where the diameters were measured | Method | Formula |
|:--|:--|:--|
| At the ends of the sections (0, 10, ..., 100 % of the length) | `Smalian` | mean of the areas of the two ends |
| At the middles of the sections (10, 30, 50, 70, 90 %, for 5 sections) | `Huber` | area at the middle; with equal sections it is the volume of Hohenadl, `l / n` times the sum of the areas |
| At the ends and at the middles (limit, middle, limit, ...) | `Newton` | weighted mean of the areas |

There is no `Hohenadl` method for that reason: it is how the diameters were measured, not another formula.

Sections v2 to v8 of Table 5.1 have the same length (2 m), so the book calculates them with the generic formula (0.2598 m³ in the book): `Smalian`, with the diameters at the ends.

```@example ex_cub_01
# 8 diameters, the ends of 7 sections, in a log of 14 m (from 1.3 m to 15.3 m)
cubage(Smalian, 14.0u"m", d[2:end])
```

\

The tree of Table 5.4 is measured by the methodology of Hohenadl: the 15.8 m of bole above the stump of 0.1 m (15.9 - 0.1) are divided into 10 sections, with the diameter at the middle of each one. The calculation is Huber's:

```@example ex_cub_01
dh = [24.0, 20.5, 19.7, 18.6, 17.7, 15.8, 11.5, 8.0, 5.9, 1.5]u"cm"

cubage(Huber, 15.8u"m", dh)
```

\

#### Logs from a Spreadsheet

The field sheets of this method have a row per log: its length and then its diameters at the same relative positions (0, 10, ..., 100 % of the length, for example). Read the sheet with the units in the headers, `name (unit)`, and `parseunits` attaches them to the columns. Then the call is the lengths and the columns of the diameters. The result has a row per log, in the same order, and the identifier columns stay in the table, beside the result. The rows below are logs of the sheet of the Flona do Jamari.

```@example ex_cub_01
using DataFrames

sheet = DataFrame(
    "log" => ["1A", "1B", "1C"],
    "l (m)" => [7.10, 7.67, 7.62],
    "d0 (cm)" => [81.5, 67.2, 61.1], "d1 (cm)" => [74.5, 63.7, 60.1], "d2 (cm)" => [72.9, 63.5, 60.2],
    "d3 (cm)" => [69.5, 62.7, 59.8], "d4 (cm)" => [67.2, 62.0, 58.6], "d5 (cm)" => [66.2, 61.3, 58.6],
    "d6 (cm)" => [65.8, 61.4, 58.3], "d7 (cm)" => [64.9, 61.7, 59.4], "d8 (cm)" => [64.9, 61.7, 58.7],
    "d9 (cm)" => [64.8, 59.5, 57.7], "d10 (cm)" => [65.3, 59.4, 57.7],
)
sheet = parseunits(sheet)

# the length and the diameters, the columns from the third on
hcat(select(sheet, :log), cubage(Smalian, sheet.l, sheet[:, 3:end]))
```


The diameters measured at the middles of the sections, as in Hohenadl's methodology, are calculated by Huber's formula, with the same layout. A single log is the same call with a length and a vector of diameters, `cubage(Smalian, sheet.l[1], Vector(sheet[1, 3:end]))`.

```@example ex_cub_01
# The diameters of the sheet at 10, 30, 50, 70 and 90 %: the middles of 5 equal sections
hcat(select(sheet, :log), cubage(Huber, sheet.l, sheet[:, [4, 6, 8, 10, 12]]))
```


### The Volume of the Whole Tree

`treevolume` partitions the volume into the stump, the commercial part (the measured sections, as in `cubage`) and the tip. When the last measurement is below the total height `H`, the tip is cubed as a cone above it. With Smalian's method, a last diameter of zero is the apex of the tree.

```@example ex_cub_01
# Diameter at breast height and total height, as annotated
treevolume(Smalian, h, d; D = 22.3u"cm", H = 15.9u"m")
```

\

- `v`: Total volume of the tree
- `vt`: Volume of the stump, a cylinder with the first measured diameter
- `vm`: Commercial volume, the measured sections (the same as `cubage`)
- `vp`: Volume of the tip, the cone above the last measurement
- `hm`: Commercial height, the height of the last measurement
- `D`, `H`: Diameter at breast height and total height, as annotated
- `f`: Artificial form factor

#### A Tree Cubed by the Three Methods

The tree of Table 2 of Floriano (2025) has a stump of 0.35 m, sections of different lengths and a tip, and the book gives its total volume by each method, stump and tip included. The measurements of Smalian's method are the limits of the sections; Huber's and Newton's also need the diameter at the middle of each section, interleaved with the limits (limit, middle, limit, ...).

```@example ex_cub_01
# limits of the sections (m) and diameters with bark (cm); the diameter at breast height is the one of the third limit
hf = [0.35, 0.95, 1.30, 2.50, 3.70, 4.90, 6.10, 7.30, 8.50, 9.70, 10.90, 12.10]u"m"
df = [19.6, 15.9, 14.3, 12.8, 12.6, 11.7, 10.5, 9.2, 7.2, 5.0, 2.9, 1.1]u"cm"
# diameters at the middle of each section
dmf = [16.5, 14.8, 13.4, 12.9, 11.9, 11.2, 9.6, 8.2, 5.9, 3.8, 1.8]u"cm"

hmf = (hf[1:end-1] .+ hf[2:end]) ./ 2
hn_f = [hf[1]; vec([hmf'; hf[2:end]'])]
dn_f = [df[1]; vec([dmf'; df[2:end]'])]

# the book: 0.11127 (Smalian), 0.10717 (Huber) and 0.10854 m³ (Newton)
treevolume(Smalian, hf, df; D = 14.3u"cm", H = 12.53u"m")
```


```@example ex_cub_01
treevolume(Huber, hn_f, dn_f; D = 14.3u"cm", H = 12.53u"m")
```


```@example ex_cub_01
treevolume(Newton, hn_f, dn_f; D = 14.3u"cm", H = 12.53u"m")
```


The stump is a cylinder and is part of the total volume `v` of this book. Other books do not count the stump: Machado & Figueiredo Filho (2003) add up the sections and the tip only. The columns are separate for that: the volume without the stump is `v - vt`, or `vm + vp`.

#### Including Bark Thickness

```@example ex_cub_01
treevolume(Smalian, h, d, E; D = 22.3u"cm", H = 15.9u"m")
```

\

The columns `v`, `vt`, `vm` and `vp` refer to the volumes with bark, and `vs`, `vts`, `vms` and `vps` to the volumes without bark. `vb` is the volume of the bark and `kb` the bark factor.

### Cubing Multiple Trees

To calculate cubage for many trees at once, organize your data in a DataFrame with columns for tree identifiers, heights, diameters, the diameter at breast height and the total height of the tree (repeated on every row of the tree), and optionally bark thickness. Pass the identifiers with the `id` keyword. `cubage` only needs the heights and diameters.

Do not broadcast `treevolume` over the columns (`treevolume.(Smalian, df.h, df.d; ...)`): each call needs the whole profile of a tree, not one measurement. The `id` keyword does that work, with `D` and `H` as columns of the data (a value per row; the value of the first row of each tree is used). The result has a row per tree and carries `D` and `H` as columns, so it can go straight into a regression such as `v ~ D + H`.

```@example ex_cub_02
using ForestMensuration
using DataFrames
using Unitful

# Two trees: the diameters with bark and the diameters without bark of Table 5.1, as if they were two trees
data = DataFrame(
    tree = repeat([1, 2], inner = 9),
    h = repeat([0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3], 2),
    d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2, 24.1, 18.9, 17.2, 16.4, 15.5, 12.9, 8.3, 5.2, 1.0],
    bark = repeat([1.8, 1.7, 1.55, 1.2, 1.0, 0.7, 0.6, 0.4, 0.1], 2),
    D = repeat([22.3, 18.9], inner = 9),
    H = fill(15.9, 18)
)

# The whole tree, for each tree
treevolume(Smalian, data.h .* u"m", data.d .* u"cm"; D = data.D .* u"cm", H = data.H .* u"m", id = data.tree)
```

\

#### Including Bark Thickness for Multiple Trees

Additionally, bark thickness values can be provided to calculate bark factors and volumes without bark.

```@example ex_cub_02
# Calculate cubage including bark thickness
treevolume(Smalian, data.h .* u"m", data.d .* u"cm", data.bark .* u"cm"; D = data.D .* u"cm", H = data.H .* u"m", id = data.tree)
```

## Frequency and Statistical Functions

### Creating Frequency Tables

The [`frequencytable`](@ref) function creates frequency distributions for a vector of values, which is useful for analyzing the distribution of diameters or heights in your data.

```@example frequency
using ForestMensuration

D = [31.5, 30.0, 26.5, 31.0, 29.0, 26.5, 14.5, 28.8, 19.0, 31.5, 32.5, 33.8, 32.5, 33.3, 36.0]u"cm"
H = [20.9, 19.6, 13.2, 23.3, 19.2, 16.2, 8.3, 19.7, 11.0, 24.0, 25.8, 28.2, 24.2, 26.2, 28.3]u"m"

# Frequency table for diameters using Sturges' formula for class intervals
frequencytable(D)
```

\

- LI: Lower class limit
- Xi: Class center
- LS: Upper class limit
- fi: Frequency count
- Fi: Cumulative frequency
- fri: Relative frequency (%)
- Fri: Cumulative relative frequency (%)

A class is the interval ``[LI, LS)``, closed on the left: a value that falls on a limit belongs to the class that starts there (12 cm is in the class 12-14, not in 10-12). The table goes from the class of the smallest value to the class of the largest one, and the classes in between that hold no observation are listed with frequency zero.

\

#### Specifying Class Width

You can specify the class width (hi) to customize the intervals.

```@example frequency
# Frequency table for heights with class width of 4 meters
frequencytable(H, 4u"m")
```

### Diametric Tables

The [`diametrictable`](@ref) function is the frequency table of the diameters with the basal area of each class and the expansion to one hectare (one acre, if imperial). It needs the sampled area of the plot.

```@example frequency
diametrictable(D, 4u"cm", plotarea=500u"m^2")
```


In addition to the columns of the frequency table:

- g: Basal area of the tree of the class center
- ng: Basal area of the class in the plot (`fi` trees of area `g`), and Ng its cumulative sum
- Ni, NFi: Number of trees of the class per hectare, and its cumulative sum
- Gi, GFi: Basal area of the class per hectare, and its cumulative sum

## Stand Structure

[`standmetrics`](@ref) characterizes a stand from the diameters at breast height of its sampled trees: how many there are, how much basal area they have, their mean diameters and how heterogeneous they are, scaled to a hectare (or an acre, for imperial units) from the sampled area. It is the only summary function: the same call, with the species and the plots of the trees, gives the horizontal structure and the phytosociological indices of the community.

First, let's define our sample plot data using Unitful quantities:

```@example metrics
using ForestMensuration

D = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0] * u"cm"
plotArea = 500u"m^2"
nothing # hide

```

### The Stand

```@example metrics
standmetrics(D, plotArea)

```

The columns follow the standard symbology of forest mensuration, lowercase for the sample and uppercase for the values per unit area:

- **n**: Number of sampled trees.
- **g**: Basal area of the sample, the sum of the basal areas of the trees.
- **N**: Number of trees per hectare/acre, ``N = n F``, with ``F`` the expansion factor of the sampled area.
- **G**: Basal area per hectare/acre, ``G = g F``.
- **Dm**: Arithmetic mean diameter ``\bar{D}``.
- **Dg**: Quadratic mean diameter ``D_g``, the diameter of the tree with mean basal area, which links the number of trees to the basal area (``g = n \pi D_g^2 / 4``).
- **CD**: Coefficient of variation of the diameters (%), the heterogeneity of the sizes: low for an even-sized stand, high for a stand with many size classes.

``D_g`` and ``g`` come from ``\bar{D}`` and the standard deviation, in a single pass through the data: ``D_g^2 = \bar{D}^2 + \frac{n - 1}{n} s_D^2``.

### The Species of a Community

With the species and the plot of every tree, the same function returns one row per species, sorted by the Importance Value Index. The area is the total sampled area, all the plots together:

```@example metrics
species = ["Oak", "Oak", "Pine", "Pine", "Pine", "Maple", "Oak", "Pine"]
plots = [1, 1, 1, 2, 2, 2, 3, 3]
d = [30.0, 22.5, 40.0, 35.2, 28.7, 15.4, 26.1, 33.9] * u"cm"

standmetrics(species, plots, d, 0.3u"ha")

```

Besides the columns above, calculated for each species (``N`` is the Absolute Density and ``G`` the Absolute Dominance), there are:

- **plots**: Number of plots where the species occurs.
- **RDe**: Relative Density (%), the density of the species over the total density.
- **RDo**: Relative Dominance (%), the basal area of the species over the total basal area.
- **AF**: Absolute Frequency (%), the plots where the species occurs over all the plots.
- **RF**: Relative Frequency (%), the frequency of the species over the sum of the frequencies.
- **VC**: Cover Value, ``RDe + RDo``.
- **IVI**: Importance Value Index, ``(RDe + RDo + RF) / 3``.

The sums of `N` and `G` over the species are the `N` and `G` of the stand. A species with a single tree has no standard deviation, so its `CD` is `NaN`.

## Forest Inventory Sampling

ForestMensuration.jl re-exports the 14 forest inventory sampling designs of
[ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl), each its own
function — plain vectors throughout, no `DataFrame`/column-name indirection. Every design
takes `plotarea`/`totalarea` as `Unitful` areas, but never assumes
a unit for the sampled quantity itself (usually named `value`): it might be volume, basal
area, a biomass, a tree count, or anything else, so a `Unitful` quantity is preserved as given and a
plain number stays unitless all the way through, unlike every other function in this
package (a count of trees per plot, with no unit, gives a mean per hectare in `ha^-1`). Designs that produce a single table return a plain `DataFrame`; designs that
produce several related tables (one per stratum/cluster, or one per inventory occasion)
return a [`SamplingReport`](@ref), whose tables are reachable through accessor functions
(`resulttable(report)`, `clustertable(report)`, ...) or directly as properties
(`report.resulttable`). The columns use the symbols of Péllico Netto & Brena (1997) in ASCII (`xm`, `cv`,
`sxm`, `Ea`, `Er`, `X`, `nreq`, ...), and every design reproduces the worked example of its chapter of
the book, which are the examples below. The complete tutorial, with every design, is in the documentation of
ForestInventory.jl.

### Simple Random Sampling

[`simplecasualsampling`](@ref) is the reference design every other method in this section
is compared against: each plot has an equal chance of being selected, with no further
structure. The example is that of chapter 5 of the book: 450 plots of 0.1 ha (45 ha) of *Pinus* sp.,
sampled with 70 plots, in m³ per plot (mean 21.797 m³, `cv` 39.58 %, total 9 808.71 m³):

```@example inv_simple
using ForestMensuration

v = [
    18.5, 22.8, 15.8, 9.8, 23.5, 20.7, 28.3, 6.9, 28.7, 26.4, 7.6, 10.3, 21.1, 26.3, 39.9, 12.7,
    11.5, 11.0, 18.9, 31.4, 9.6, 9.8, 7.1, 25.9, 25.7, 24.2, 19.0, 25.9, 37.7, 23.3, 24.6,
    32.3, 23.4, 17.1, 8.9, 32.7, 8.1, 29.2, 24.7, 25.6, 13.2, 25.7, 27.0, 20.4, 13.6, 32.4,
    31.3, 34.6, 9.5, 18.7, 28.9, 21.6, 8.3, 23.2, 26.6, 25.6, 8.0, 22.1, 21.9, 23.3, 9.9,
    30.7, 29.2, 28.0, 13.7, 27.6, 37.9, 27.3, 28.0, 30.7
]u"m^3"

simplecasualsampling(v, 0.1u"ha", 45u"ha"; e=10, α=0.95)
```

### Stratified Random Sampling

[`stratifiedsampling`](@ref) divides the population into non-overlapping strata before
sampling within each — usually a variance reduction over simple random sampling of the
same total size. It returns a [`SamplingReport`](@ref) with an ANOVA table (is there
really a difference between strata?), an auxiliary table (per-stratum descriptive
statistics and allocation weights), and the final result table. The example is that of chapter 6 of the book:
the same population in 3 strata of 144, 164 and 142 plots, sampled with 22 plots (stratified mean 21.465 m³, total
9 659 m³, ``F = 24.42``):

```@example inv_stratified
using ForestMensuration

stratum = vcat(fill(1, 7), fill(2, 8), fill(3, 7))
value = [
    15.8, 7.6, 8.8, 12.5, 11.1, 16.2, 12.2, 20.4, 30.5, 26.8, 27.2, 28.4, 19.7, 20.4, 23.1, 21.3,
    24.3, 29.2, 21.8, 33.1, 35.8, 26.7
]u"m^3"
strataarea = Dict(1 => 14.4u"ha", 2 => 16.4u"ha", 3 => 14.2u"ha")   # one entry per stratum label

report = stratifiedsampling(stratum, value, 0.1u"ha", strataarea)
resulttable(report)
```

```@example inv_stratified
auxiliarytable(report)
```

```@example inv_stratified
anova(report)
```

With a single stratum, [`stratifiedsampling`](@ref) reduces exactly to
[`simplecasualsampling`](@ref). Since `strataarea` is a `Dict` keyed by the stratum
labels, `stratum`/`value` don't need to be pre-sorted by stratum.

### Systematic Sampling

[`systematicsampling`](@ref) estimates the variance of the mean from the successive differences between
the plots of each line. The example is that of chapter 7 of the book: 75 plots in 15 lines of 5 plots, in
the same stand (mean 22.11 m³, total 9 950 m³):

```@example inv_systematic
using ForestMensuration

rows = [
    8.0 9.4 7.3 10.1 8.7;
    8.6 12.7 9.8 11.6 8.8;
    13.1 7.6 9.5 8.5 10.4;
    16.6 19.0 18.6 10.8 22.9;
    21.6 15.1 15.8 18.0 16.2;
    23.6 23.7 23.3 23.0 24.0;
    19.7 18.4 22.8 27.1 19.5;
    30.6 29.4 27.8 28.7 30.5;
    20.4 24.6 19.2 28.2 19.9;
    28.0 38.6 28.3 34.9 22.9;
    30.1 27.6 23.1 28.4 21.4;
    22.6 24.7 26.7 31.7 28.7;
    26.7 24.8 26.9 31.8 21.8;
    31.8 28.7 33.9 28.3 30.7;
    25.5 33.1 35.1 30.1 28.3
]
value = vec(permutedims(rows)) * u"m^3"    # the plots of each line, in order
line = repeat(1:15, inner=5)

systematicsampling(value, 0.1u"ha", 45u"ha"; line=line)
```

### One-Stage Cluster Sampling

[`clustersampling`](@ref) treats a group of `M` neighboring plots as the sampling unit. The example is that of
chapter 9 of the book: 25 clusters of 4 plots of 0.25 ha in a stand of 4 000 ha (mean 64.548 m³, ``r = 0.0966``,
total 1 032 768 m³, 17 clusters required):

```@example inv_cluster
using ForestMensuration

rows = [
    84.7 78.2 63.0 88.5;
    70.1 65.4 59.6 58.1;
    75.6 77.7 66.1 43.5;
    81.3 38.7 62.8 31.1;
    99.5 47.0 82.1 77.4;
    97.3 66.1 57.4 113.9;
    70.2 43.5 48.3 69.3;
    81.7 68.8 22.6 78.2;
    60.9 71.4 75.2 81.1;
    67.3 90.5 72.6 67.1;
    75.4 88.5 104.6 105.5;
    71.0 57.0 79.3 71.8;
    61.8 100.9 69.4 61.0;
    116.9 91.0 36.9 57.3;
    56.0 22.9 94.8 130.2;
    68.2 32.5 68.2 58.6;
    55.4 61.3 76.3 40.0;
    55.0 63.0 56.8 36.8;
    78.8 59.6 68.1 46.8;
    33.6 44.4 34.1 79.6;
    48.8 26.6 67.5 51.0;
    82.4 61.8 23.4 60.2;
    69.8 49.5 53.9 0.0;
    58.4 61.5 45.5 50.2;
    27.4 63.6 69.4 60.8
]
value = vec(permutedims(rows)) * u"m^3"    # the plots of each cluster, in order
cluster = repeat(1:25, inner=4)

report = clustersampling(cluster, value, 0.25u"ha", 4000u"ha")
resulttable(report)
```

### Successive Occasions

The four designs for continuous forest inventory return a [`SamplingReport`](@ref) with the tables `occasion1`,
`occasion2` and `change`. The example of [`doublesampling`](@ref) is that of chapter 11 of the book: a stand of 500 ha
of *Pinus elliottii* (500 plots of 1 000 m²), with 56 plots in 1975, 30 temporary and 26 permanent, and the 26
permanent plots remeasured in 1976 (the volumes of the book are per hectare, so they are given as the volumes of
plots of 1 ha). The book gets a mean of 169.952 m³ with a standard error of 6.664 m³ and a change of 49.86 m³:

```@example inv_double
using ForestMensuration

xu = [132.3, 122.9, 133.3, 124.8, 127.5, 116.4, 120.0, 140.6, 116.8, 113.9, 138.7, 144.5, 104.0,
    157.4, 116.2, 100.1, 164.4, 195.7, 129.8, 102.1, 140.7, 187.0, 64.6, 129.6, 147.3, 151.9,
    110.7, 147.1, 101.8, 146.5]
xm = [139.1, 190.3, 100.7, 102.7, 98.4, 68.2, 42.2, 91.6, 91.6, 77.4, 91.4, 91.6, 123.5, 108.7,
    108.7, 93.6, 42.0, 53.8, 138.0, 173.1, 121.1, 81.8, 64.0, 145.9, 168.9, 186.8]
ym = [177.6, 232.9, 165.5, 180.8, 164.3, 103.6, 68.0, 145.5, 137.6, 123.7, 146.6, 141.3, 174.4,
    164.9, 164.9, 134.0, 57.4, 84.4, 202.0, 207.9, 171.8, 154.0, 101.2, 189.2, 226.9, 239.3]

value1 = vcat(xu, xm) * u"m^3"
value2 = vcat(fill(missing, 30), ym) * u"m^3"    # missing: the temporary plots were not remeasured

report = doublesampling(value1, value2, 1u"ha", 500)
occasion2(report)
```

```@example inv_double
change(report)
```

### The Other Designs

| Function | Design |
|:---------|:-------|
| [`multistartsystematicsampling`](@ref) | Systematic sampling with multiple random starts (chapter 10) |
| [`twostagesampling`](@ref) | Two-stage sampling (chapter 8) |
| [`independentoccasionssampling`](@ref) | Successive occasions, independent samples (chapter 11) |
| [`completereplacementsampling`](@ref) | Successive occasions, complete replacement (chapter 11) |
| [`partialreplacementsampling`](@ref) | Successive occasions, partial replacement, Ware & Cunia (chapter 11) |
| [`horizontalpointsampling`](@ref) | Horizontal point sampling (Bitterlich) |
| [`strandsampling`](@ref) | Horizontal line sampling (Strand) |
| [`prodansampling`](@ref) | Prodan's k-tree distance sampling |
| [`threepsampling`](@ref) | 3P sampling |

Each one follows the same pattern, with its complete formulas in its docstring; see the
[ForestInventory.jl documentation](https://JuliaForests.github.io/ForestInventory.jl/dev/tutorial/) for a runnable
example of every one.
