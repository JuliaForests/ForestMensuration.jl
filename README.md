# ForestMensuration

ForestMensuration.jl provides advanced functions for dendrometric calculations in Julia,
for both **planted and native forests**. Its focus is on accurate **tree cubage (volume
estimation)**, **stand structure** (number of trees, basal area, mean diameters per hectare), **frequency/diametric distribution tables**, **forest inventory sampling** (14 designs), and **native forest
community structure & biodiversity** (phytosociology/IVI, diversity, floristic
similarity, species accumulation), built on top of
[ForestFoundations.jl](https://github.com/JuliaForests/ForestFoundations.jl) (units) and
[ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl) (the sampling designs,
re-exported here) so every measurement carries its unit and is converted automatically. These methods are essential for forest mensuration and biometrics,
supporting forest inventory, management, and research.

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaForests.github.io/ForestMensuration.jl/stable/forestmensuration/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaForests.github.io/ForestMensuration.jl/dev/forestmensuration/)
[![Build Status](https://github.com/JuliaForests/ForestMensuration.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaForests/ForestMensuration.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaForests/ForestMensuration.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaForests/ForestMensuration.jl)

## Installation

Install the package via Julia's package manager:

```julia-repl
using Pkg
Pkg.add("ForestMensuration")
```

## Overview

ForestMensuration.jl is designed for professionals and researchers in forestry,
dendrometry, and forest biometrics. Its key features include:

- **Cubage (Tree Volume Estimation):**
  Rigorous section methods (Smalian, Huber, Newton) for individual logs, and `cubage`, the
  volume of the whole tree from the diameters measured at absolute heights: the stump, the
  sections by Smalian's method and the tip, and the form factor, with and without bark, for
  one tree or many trees told apart by `id`. Logs measured at relative positions (equal
  sections) give only the volume of the log: `smalian` and `huber` with the length of the log
  (Huber's at the middles of the sections is the methodology of Hohenadl), for one log or a
  field sheet with a log per row. Nothing is interpolated.

- **Stand Structure:**
  Number of trees, basal area, arithmetic and quadratic mean diameter and their coefficient
  of variation, per hectare or acre (`standmetrics`); with the species and the plots of the
  trees, the same per species together with the horizontal structure and the Curtis & McIntosh
  Importance Value Index (IVI). The Weise, central basal-area, dominant (Assmann) and
  Hohenadl's diameters are available one by one (`weisediameter`, `centralbasalareadiameter`,
  `dominantdiameter`, `hohenaldiameters`).

- **Frequency and Diametric Distribution Tables:**
  Class-based frequency tables for any variable (`frequencytable`), and a
  diameter-specific version that also reports basal area and per-hectare/per-acre
  expansions (`diametrictable`).

- **Forest Inventory Sampling:**
  All 14 designs, one function each, generic to any number of strata/clusters/plots
  and taking plain vectors throughout (no `DataFrame`/column-name indirection): simple
  (`simplecasualsampling`), stratified (`stratifiedsampling`), systematic
  (`systematicsampling`, `multistartsystematicsampling`), cluster/two-stage
  (`clustersampling`, `twostagesampling`), horizontal point/Bitterlich angle-count
  sampling (`horizontalpointsampling`), and the four sampling-on-successive-occasions
  designs used in continuous forest inventory (`independentoccasionssampling`,
  `completereplacementsampling`, `partialreplacementsampling`, `doublesampling`).
  Provided by [ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl),
  re-exported here.

- **Native Forest Biodiversity:**
  Shannon-Wiener, Simpson, inverse Simpson, Pielou's
  evenness, Berger-Parker dominance, and the Chao1 richness estimator (`diversity`);
  pairwise plot similarity/dissimilarity via Jaccard, Sørensen, or Bray-Curtis
  (`floristicsimilarity`, `floristicdistance`); and sample-based/individual-based
  species accumulation (collector/rarefaction) curves via Monte Carlo resampling with
  95% confidence intervals (`speciesaccumulation`).

Lengths, areas and volumes must be `Unitful` quantities (`30u"cm"`, `20u"m"`, `0.05u"ha"`): a plain number
says nothing about its unit, so none is assumed. Any unit works, imperial included, and
results always carry units.

## Example Usage

### Cubage Calculation

Compute the volume of a single log, of a whole tree with its stump and tip, or of the logs
of a field sheet measured at relative positions.

```julia-repl
using ForestMensuration

# a single log, the first section of the tree of Machado & Figueiredo Filho (2003), Table 5.1:
# 1.2 m long, 27.7 cm base diameter, 22.3 cm top diameter
julia> smalian(1.2u"m", 27.7u"cm", 22.3u"cm")
0.05959192856814871 m^3

# the whole tree: the heights and the diameters from the ground up, the total height and the
# diameter at breast height (the annotated values; nothing is interpolated)
julia> h = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3]u"m";
julia> d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2]u"cm";
julia> cubage(15.9u"m", 22.3u"cm", h, d)
1×7 DataFrame
 Row │ v             vt              vm            vp              H          D          f
     │ Quantity…     Quantity…       Quantity…     Quantity…       Quantity…  Quantity…  Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 0.325118 m^3  0.00602628 m^3  0.319069 m^3  2.26195e-5 m^3     15.9 m    22.3 cm  0.523534

# v: tree volume; vt: stump (a cylinder); vm: the measured sections (Smalian); vp: tip (the cone above
# the last measurement, up to H); H: total height; D: diameter at breast height; f: form factor

# with the bark thickness E (one side, ds = d - 2E): the same volumes without bark and the bark
julia> E = [1.8, 1.7, 1.55, 1.2, 1.0, 0.7, 0.6, 0.4, 0.1]u"cm";
julia> select(cubage(15.9u"m", 22.3u"cm", h, d, E), :v, :vs, :vb, :kb, :pb)
1×5 DataFrame
 Row │ v             vs           vb             kb        pb
     │ Quantity…     Quantity…    Quantity…      Float64   Float64
─────┼─────────────────────────────────────────────────────────────
   1 │ 0.325118 m^3  0.24458 m^3  0.0805388 m^3  0.868459  24.7722

# relative positions: equal sections of a log, only its length and the diameters in order matter
# (Smalian, diameters at the limits: sections v2 to v8 of Table 5.1, 7 sections of 2 m)
julia> smalian(14.0u"m", d[2:end])
0.2594774890287588 m^3

# a field sheet, a log per row: the length and the diameters at 0, 50 and 100 % of each log
# (the units are in the headers, `parseunits` attaches them)
julia> sheet = parseunits(DataFrame("log" => ["1A", "1B"], "l (m)" => [7.10, 7.67],
         "d0 (cm)" => [81.5, 67.2], "d50 (cm)" => [74.5, 63.7], "d100 (cm)" => [72.9, 63.5]));
julia> sheet.vm = smalian(sheet.l, Matrix(sheet[:, r"^d"]));
julia> sheet
2×6 DataFrame
 Row │ log     l          d0         d50        d100       vm
     │ String  Quantity…  Quantity…  Quantity…  Quantity…  Quantity…
─────┼─────────────────────────────────────────────────────────────────
   1 │ 1A          7.1 m    81.5 cm    74.5 cm    72.9 cm  3.21436 m^3
   2 │ 1B         7.67 m    67.2 cm    63.7 cm    63.5 cm  2.50952 m^3

# the methodology of Hohenadl (10 equal sections, diameters at their middles, Table 5.4) is
# Huber's formula: 15.8 m of bole above the stump of 0.1 m
julia> huber(15.8u"m", [24.0, 20.5, 19.7, 18.6, 17.7, 15.8, 11.5, 8.0, 5.9, 1.5]u"cm")
0.3135257003685299 m^3
```

### Stand Structure

Summarize the structure of a plot per hectare, and of the species of a community.

```julia-repl
using ForestMensuration

julia> D = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm";

julia> standmetrics(D, 0.05u"ha")
1×7 DataFrame
 Row │ n      g             N            G                  Dm         Dg          CD
     │ Int64  Quantity…     Quantity…    Quantity…          Quantity…  Quantity…   Float64
─────┼─────────────────────────────────────────────────────────────────────────────────────
   1 │    10  0.248284 m^2  200.0 ha^-1  4.96568 m^2 ha^-1   17.25 cm  17.7799 cm  26.3274

# with the species and the plots of the trees: per species, with the horizontal structure and the
# Importance Value Index, sorted by IVI
julia> species = ["Oak", "Oak", "Pine", "Pine", "Pine", "Maple", "Oak", "Pine"];
julia> plots = [1, 1, 1, 2, 2, 2, 3, 3];
julia> d = [30.0, 22.5, 40.0, 35.2, 28.7, 15.4, 26.1, 33.9]u"cm";

julia> standmetrics(species, plots, d, 0.03u"ha")
3×15 DataFrame
 Row │ species  n      g              N              G                   Dm         Dg          CD        plots  RDe      RDo       AF        RF       VC        IVI
     │ String   Int64  Quantity…      Quantity…      Quantity…           Quantity…  Quantity…   Float64   Int64  Float64  Float64   Float64   Float64  Float64   Float64
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Pine         4   0.377929 m^2  133.333 ha^-1   12.5976 m^2 ha^-1   34.45 cm  34.6841 cm   13.4835      3     50.0  67.4266   100.0     50.0     117.427   55.8089
   2 │ Oak          3   0.163949 m^2    100.0 ha^-1   5.46496 m^2 ha^-1    26.2 cm  26.3784 cm   14.3168      2     37.5  29.2502    66.6667  33.3333   66.7502  33.3612
   3 │ Maple        1  0.0186265 m^2  33.3333 ha^-1  0.620883 m^2 ha^-1    15.4 cm     15.4 cm  NaN           1     12.5   3.32317   33.3333  16.6667   15.8232  10.8299
```

### Frequency and Diametric Tables

Build a class-based frequency table for any variable, or a diameter-specific table with
basal area and per-hectare expansion.

```julia-repl
using ForestMensuration

julia> frequencytable(diameters, 2u"cm")
8×7 DataFrame
 Row │ LI         Xi         LS         fi     Fi     fri      Fri
     │ Quantity…  Quantity…  Quantity…  Int64  Int64  Float64  Float64
─────┼─────────────────────────────────────────────────────────────────
   1 │   10.0 cm    11.0 cm    12.0 cm      1      1     10.0     10.0
   2 │   12.0 cm    13.0 cm    14.0 cm      2      3     20.0     30.0
   3 │   14.0 cm    15.0 cm    16.0 cm      1      4     10.0     40.0
   4 │   16.0 cm    17.0 cm    18.0 cm      1      5     10.0     50.0
   5 │   18.0 cm    19.0 cm    20.0 cm      2      7     20.0     70.0
   6 │   20.0 cm    21.0 cm    22.0 cm      1      8     10.0     80.0
   7 │   22.0 cm    23.0 cm    24.0 cm      1      9     10.0     90.0
   8 │   24.0 cm    25.0 cm    26.0 cm      1     10     10.0    100.0

julia> diametrictable(diameters, 2u"cm", plotarea=plotarea)
8×14 DataFrame
 Row │ LI         Xi         LS         fi     Fi     fri      Fri      g               ng              Ng              Ni          NFi          Gi                  GFi
     │ Quantity…  Quantity…  Quantity…  Int64  Int64  Float64  Float64  Quantity…       Quantity…       Quantity…       Quantity…   Quantity…    Quantity…           Quantity…
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │   10.0 cm    11.0 cm    12.0 cm      1      1     10.0     10.0  0.00950332 m^2  0.00950332 m^2  0.00950332 m^2  20.0 ha^-1   20.0 ha^-1  0.190066 m^2 ha^-1  0.190066 m^2 ha^-1
   2 │   12.0 cm    13.0 cm    14.0 cm      2      3     20.0     30.0   0.0132732 m^2   0.0265465 m^2   0.0360498 m^2  40.0 ha^-1   60.0 ha^-1  0.530929 m^2 ha^-1  0.720996 m^2 ha^-1
  ⋮
```

### Forest Inventory Sampling

Estimate a stand's total — with its confidence interval, coefficient of variation, and
required sample size — from any of the 14 sampling designs, each its own function
taking plain vectors (no `DataFrame`/column-name indirection). Every design takes `plotarea`/`totalarea` as `Unitful` areas, and never assumes a unit for the
sampled quantity itself — it might be volume, basal area, a biomass, a tree count, or anything else,
so a `Unitful` quantity is preserved as given and a plain number stays unitless throughout
(a count of trees per plot gives a mean per hectare in `ha^-1`), unlike every other function in this package.
The columns use the symbols of Péllico Netto & Brena (1997) in ASCII, and every design reproduces the worked
example of its chapter of the book, which are the examples of the tutorial.

Every result table is a single-row, one-column-per-statistic `DataFrame` — the same shape
as `standmetrics` — so every value that carries a physical unit is a real
`Unitful` quantity rather than a plain number paired with a separate units column. That
means `stripunits`/`parseunits` (re-exported from ForestFoundations.jl) work on it
directly, just like on any other table in this package.

The example is that of chapter 5 of the book: 450 plots of 0.1 ha (a stand of 45 ha) of *Pinus* sp., sampled
with 70 plots, in m³ per plot (the book gets a mean of 21.797 m³, `cv` 39.58 % and a total of 9 808.71 m³):

```julia-repl
using ForestMensuration

julia> v = [18.5, 22.8, 15.8, 9.8, 23.5, 20.7, 28.3, 6.9, 28.7, 26.4, 7.6, 10.3, 21.1, 26.3, 39.9, 12.7,
        11.5, 11.0, 18.9, 31.4, 9.6, 9.8, 7.1, 25.9, 25.7, 24.2, 19.0, 25.9, 37.7, 23.3,
        24.6, 32.3, 23.4, 17.1, 8.9, 32.7, 8.1, 29.2, 24.7, 25.6, 13.2, 25.7, 27.0, 20.4,
        13.6, 32.4, 31.3, 34.6, 9.5, 18.7, 28.9, 21.6, 8.3, 23.2, 26.6, 25.6, 8.0, 22.1,
        21.9, 23.3, 9.9, 30.7, 29.2, 28.0, 13.7, 27.6, 37.9, 27.3, 28.0, 30.7]u"m^3";

julia> report = simplecasualsampling(v, 0.1u"ha", 45u"ha"; e=10, α=0.95)
1×17 DataFrame
 Row │ xm           cv       s2xm          sxm           Ea           Er       xha                X            Xl          Xu           population  f        n      nreq   nadd   N      A
     │ Quantity…    Float64  Quantity…     Quantity…     Quantity…    Float64  Quantity…          Quantity…    Quantity…   Quantity…    String      Float64  Int64  Int64  Int64  Int64  Quantity…
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 21.7971 m^3    39.58  0.897789 m^6  0.947518 m^3  1.89025 m^3     8.67  217.971 m^3 ha^-1  9808.71 m^3  8958.1 m^3  10659.3 m^3  finite        0.156     70     56      0    450      45 ha

julia> report.xm[1]
21.79714285714286 m^3

julia> stripunits(report)[:, ["xm (m^3)", "X (m^3)"]]
1×2 DataFrame
 Row │ xm (m^3)  X (m^3)
     │ Float64   Float64
─────┼───────────────────
   1 │  21.7971  9808.71
```

Multi-table designs (stratified, cluster, two-stage, and the four successive-occasions
designs) return a `SamplingReport` instead of a bare `DataFrame`, so the per-group/
per-occasion tables travel together — each one reachable as a property. The example is that of
chapter 6 of the book: the same population in 3 strata of 144, 164 and 142 plots, sampled with 22 plots:

```julia-repl
julia> stratum = vcat(fill(1, 7), fill(2, 8), fill(3, 7));

julia> value = [15.8, 7.6, 8.8, 12.5, 11.1, 16.2, 12.2, 20.4, 30.5, 26.8, 27.2, 28.4, 19.7, 20.4, 23.1, 21.3,
        24.3, 29.2, 21.8, 33.1, 35.8, 26.7]u"m^3";

julia> strataarea = Dict(1 => 14.4u"ha", 2 => 16.4u"ha", 3 => 14.2u"ha");   # one entry per stratum label

julia> report = stratifiedsampling(stratum, value, 0.1u"ha", strataarea);

julia> resulttable(report).xm[1]
21.46506349206349 m^3

julia> resulttable(report).X[1]
9659.278571428571 m^3

julia> resulttable(report).nh[1]   # per-stratum measured plots, as a tuple
(7, 8, 7)

julia> auxiliarytable(report)   # per-stratum nh, xmh, s2h, sh and the weights Wh, Whsh, Whs2h
julia> anova(report)             # test for a difference between strata means
```

`strataarea` is a `Dict` keyed by the same labels used in `stratum`, rather than a
plainly ordered vector — so the rows above don't need to be pre-sorted by stratum, they
can be listed in whatever order the plots were actually collected in.

The remaining designs follow the same pattern — see the
[Forest Inventory Sampling tutorial](https://JuliaForests.github.io/ForestMensuration.jl/dev/tutorial/#Forest-Inventory-Sampling)
for a complete, runnable example of the main ones, and the documentation of
[ForestInventory.jl](https://JuliaForests.github.io/ForestInventory.jl/dev/tutorial/) for every one:

| Function | Design |
|:-------------------------|:-------|
| `simplecasualsampling` | Simple random sampling |
| `stratifiedsampling` | Stratified random sampling |
| `systematicsampling` | Systematic sampling (method of successive differences) |
| `multistartsystematicsampling` | Systematic sampling with multiple random starts |
| `clustersampling` | One-stage cluster sampling |
| `twostagesampling` | Two-stage sampling |
| `horizontalpointsampling` | Horizontal point sampling (Bitterlich's angle-count method) |
| `strandsampling` | Horizontal line sampling (Strand) |
| `prodansampling` | Prodan's k-tree distance sampling (plotless, descriptive spread only) |
| `threepsampling` | 3P sampling (probability proportional to prediction) |
| `independentoccasionssampling` | Successive occasions, independent samples |
| `completereplacementsampling` | Successive occasions, complete replacement (matched plots) |
| `partialreplacementsampling` | Successive occasions, partial replacement |
| `doublesampling` | Successive occasions, double sampling with regression |

### Native Forest Biodiversity

Compute biodiversity and similarity indices from the plot/species records of a forest community
(the phytosociological indices are in `standmetrics`).

```julia-repl
using ForestMensuration

julia> species = ["Oak", "Oak", "Pine", "Pine", "Pine", "Maple", "Oak", "Pine"];
julia> plots = [1, 1, 1, 2, 2, 2, 3, 3];

julia> diversity(plots, species)
4×9 DataFrame
 Row │ plots   richness  abundance  shannon   simpson   invsimpson  jevenness  berger    chao1
     │ Any     Int64     Int64      Float64   Float64   Float64     Float64    Float64   Float64
─────┼───────────────────────────────────────────────────────────────────────────────────────────
   1 │ 1              2          3  0.636514  0.444444     1.8       0.918296  0.666667      2.5
   2 │ 2              2          3  0.636514  0.444444     1.8       0.918296  0.666667      2.5
   3 │ 3              2          2  0.693147  0.5          2.0       1.0       0.5           3.0
   4 │ pooled         3          8  0.974315  0.59375      2.46154   0.88686   0.5           3.0
```

## Keywords

Forest mensuration, dendrometry, forest inventory, tree cubage, dendrometric averages,
frequency distribution, diametric distribution, forest inventory sampling, stratified
sampling, cluster sampling, systematic sampling, successive occasions, continuous forest
inventory, forest biometrics, native forests, planted
forests, phytosociology, community ecology, importance value index, biodiversity,
species diversity, floristic similarity, species accumulation, rarefaction.

## License

This project is licensed under the MIT License.
