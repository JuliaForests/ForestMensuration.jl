## [Unreleased]

### Breaking Changes

- **Variable, argument and column names follow the standardized symbology of Silva et al.
  (2022)** ("Padronização da simbologia em mensuração e manejo florestal", Associação
  Brasileira de Mensuração Florestal): one letter plus subscripts, `D` for the diameter at
  breast height, `H` for the total height, `g`/`G` and `v`/`V` for tree/stand basal area and volume.
  Function names are never symbols or letters, which are kept for variables, arguments and
  result columns: they are spelled out in full (`dmetrics`/`hmetrics` →
  `diametermetrics`/`heightmetrics`, and the internal mean functions of `dendrometrics.jl`,
  below). Requires a `ForestFoundations.jl` that provides `inreferencevolume`.
  - **The cubage was reorganized by how the measurements are annotated.** The file follows the
    order geometry (`cylindervolume`, `conevolume`), Smalian, Huber, Newton, form factor, bark and
    `cubage`.
    - **Absolute positions (the heights are annotated): `cubage(H, D, h, d)` is the volume of the
      whole tree**: the stump (the cylinder up to the first measurement), the measured sections by
      Smalian's method and the tip (the cone from the last measurement up to `H`), and the artificial
      form factor. Columns `v, vt, vm, vp, H, D, f`. With the bark thickness, `cubage(H, D, h, d, E)`
      adds, after them, the same volumes without bark and the bark: `vs, vts, vms, vps, vb, kb, pb`
      (suffix `s` = without bark, Silva et al., 2022; `vb`, `kb`, `pb` = volume, factor and
      percentage of bark, `b` of *bark*). `H` and `D` may be the columns of the table, repeated in
      every row of the tree (they must be the same in all of them), and many trees stacked in the
      same vectors are `cubage(id, H, D, h, d[, E])`, a row per tree in the order in which they
      appear. Output columns of the old version `vt, v0, vc, vr, vn, d, h, hc, aff, nff, qf` → the
      ones above (**`vt` now means the stump volume, not the total volume**).
    - **`treevolume`, `CubingMethod`, `Smalian`, `Huber` and `Newton` (the types) were removed**,
      together with the cubage of a tree by Huber's and Newton's methods (measurements limit, middle,
      limit, ...), the column `hm`, the dropping of a last diameter of zero and the relative method by
      Newton's formula. The volume of one section by each formula remains: `smalian(l, d1, d2)`,
      `huber(l, d12)` and `newton(l, d1, d12, d2)`.
    - **`smalian(h, d)` is the volume of the measured bole**, the sum of its sections by Smalian's
      method, with the heights of the measurements.
    - **Relative positions (only the length of the log is annotated, equal sections): the volume of
      the log**, with no stump, tip or form factor. `smalian(l, d)` takes the diameters at the limits of
      the sections (0, 10, ..., 100 % of the length) and `huber(l, d)` at their middles (10, 30, 50, 70
      and 90 %, for 5 sections), which is the methodology of Hohenadl, so **the function
      `hohenadl(l, d)` was removed**. A field sheet, a log per row, is `smalian(l, d)` or `huber(l, d)`
      with the vector of lengths and the matrix of diameters (`Matrix(sheet[:, columns])`), and the
      result is the vector of the volumes of the logs, ready to be a column of the sheet.
    - **The numerical examples of the docstrings, the tutorial and the tests are the tables of Machado &
      Figueiredo Filho (2003), *Dendrometria*, Chapter 5** (Tables 5.1 to 5.4: Smalian, Huber, Newton
      and Hohenadl), a tree of 22.3 cm of diameter at breast height and 15.9 m of total height, and the
      tree of Table 2 of Floriano (2025), whose totals (stump, sections and tip, by Smalian, Huber and
      Newton: 0.11127, 0.10717 and 0.10854 m³) the tests reproduce.
    - **Nothing is interpolated.** `diameterinterpolation`, `heightinterpolation` and the diameter
      at breast height read from the profile were removed. `D` and `H` are always the annotated values.
    - **The residual volume (`vr`, `vrs`) and the minimum diameter (`dlimit`, `dmin`) are gone.**
      The books split the bole into stump, sections and tip, and the profile is measured up to the
      commercial height. The keywords `ht`/`dbh`/`hdbh` → the arguments `H`/`D`.
    - The bark argument is now `E`, the bark thickness as defined by the manual (one side of the
      stem; `d_s = d - 2E`), where `e` used to be subtracted from the diameter as it was:
      **results with bark change** (bark factor, volumes without bark).
  - `smalian`, `huber`, `newton`, `cylindervolume`, `conevolume`, form factor
    functions: argument names changed (`l`, `d1`, `d2`, `d12`, `D`, `H`); positional use is
    unaffected.
  - **Function names are lower case, in full words, as the rest of the package.**
    `ForestInventory.jl` (re-exported here): the sampling designs `simpleCasualSampling`,
    `stratifiedSampling`, `systematicSampling`, `multistartSystematicSampling`, `clusterSampling`,
    `horizontalPointSampling`, `prodanSampling`, `strandSampling`, `threePSampling`,
    `twoStageSampling`, `independentOccasionsSampling`, `completeReplacementSampling`,
    `partialReplacementSampling` and `doubleSampling` → the same names in lower case
    (`simplecasualsampling`, ..., `threepsampling`, ...); the accessors of `SamplingReport`
    `resultTable`, `clusterTable`, `auxiliaryTable`, `pointTable`, `startTable` and `primaryTable`
    → `resulttable`, `clustertable`, ... (the property names change the same way:
    `report.resulttable`). `ForestMensuration.jl`: `countSpecies` → `countspecies`, and the
    internal `dominantTreeCount` and `simulationSummary` → `dominanttreecount`,
    `simulationsummary`.

  - The single diameter averages `dm, dg, dw, dz, dd, dh` → `arithmeticmeandiameter`,
    `quadraticmeandiameter`, `weisediameter`, `centralbasalareadiameter`, `dominantdiameter`,
    `hohenaldiameters` (returns `(Dl, Du)`); the summary functions that were built from them are
    gone (see the stand structure below).
  - `weisediameter` and `centralbasalareadiameter` no longer interpolate: `Dw` is the diameter of
    the tree at the position `round(0.6 n)` of the sorted diameters (Machado & Figueiredo Filho,
    2003, Section 2.6.4), and `dz` is the diameter of the tree where the cumulative basal area
    reaches half of the total (before, the square root of the median of `D²`, a different quantity).
  - `dominantdiameter` (`DD` in `diametermetrics` and `standmetrics`) is the quadratic mean of the
    thickest trees, the diameter of their mean basal area, as in Finger (2006, Section 12.2.6.1)
    (before, the arithmetic mean).
  - **`frequencytable` and `diametrictable` placed the observations in the wrong class**: the
    class center was found with `round`, which centers the classes on multiples of the width,
    while the limits `LI` and `LS` are printed for classes that start on multiples of the width
    (11.5 cm and 11.0 cm, for a width of 2 cm, fell in the class 12-14). It is now `floor`, the
    class being the interval `[LI, LS)` as in the book tables. The frequencies, and everything
    derived from them in `diametrictable`, change.
  - **`frequencytable` and `diametrictable` list every class** from the one of the smallest value to
    the one of the largest, the empty ones with frequency zero (before, the empty classes were
    left out and the table had holes). With groups, the class width stays computed by group.
  - `diametrictable`: the per-hectare columns `fi_ha`, `Fi_ha`, `ng_ha`, `Ng_ha` → `Ni`, `NFi`,
    `Gi`, `GFi`: uppercase is the manual's total per unit area (as `N` and `G` in `standmetrics`),
    the leading letter says what is counted (trees `N`, basal area `G`) and the index is the class.
  - `diametrictable`: the cumulative basal area columns `∑ng`, `∑ng_ha` → `Ng`, `Ng_ha`
    (uppercase marks the cumulative value, as in `fi`/`Fi` and `fri`/`Fri`).
  - `frequencytable`/`diametrictable` grouped methods: the grouping column argument is named
    `group`, and the diameters column `D`.
  - Naming convention for columns and variables, a middle ground with the manual: only
    ASCII (no combining marks such as `D̄`, no `∑`, no subscripts), so every column can be
    reached as `df.D` or `df[!, :D]`; the base symbol keeps the manual's letter and case, and the
    index is appended in lower case without a separator (`hm`, `vt`, `fH10`), with a trailing
    `s` always meaning without bark (`vs`, `vts`); symbols that the manual does not define
    are built the same way (`kb`, `Gp`, `CD`). Functions are the exception: they are always
    named in full, never by a symbol.
  - `phytosociology`: the diameters argument is named `D`.
  - `phytosociology`: the columns follow the symbols of `standmetrics`: `g` → `Gp` (basal area of the
    species in the sample), `ADe` → `N` and `ADo` → `G` (trees and basal area per hectare of the
    species). The totals over the species are the `N` and `G` of the stand.
  - **No underscores in public names**: the keyword `plot_area` of `diametrictable` is now
    `plotarea`. The per-hectare columns of `diametrictable` have no suffix either (see above).
  - **One calculation, one place** (internal, results unchanged): the automatic
    class width is a single helper for `frequencytable` and `diametrictable`; the volume
    with bark of `cubage` is calculated once and reused without bark (`d - 2E`); the relative
    `smalian(l, d)` and `huber(l, d)` reuse the formula of one section; `countspecies` uses `StatsBase.countmap`.
  - **Inventory designs** (re-exported from ForestInventory.jl): the keywords without `_`
    (`plotarea`, `totalarea`, `strataarea`, `pointarea`), the table columns in the symbols of
    Péllico Netto & Brena (1997) (`xm`, `cv`, `sxm`, `Ea`, `Er`, `X`, `nreq`, ...), the formulas of the
    book in every design (`partialreplacementsampling` is now Ware & Cunia's), and the examples and tests
    are the worked examples of the book; see the CHANGELOG of ForestInventory.jl.
  - The tutorial section "Logs from a Spreadsheet" used the removed `hohenadl` and the `id`
    argument of `smalian`; it now uses `smalian(l, d)` and `huber(l, d)` with the lengths and the matrix of diameters.
  - **Arguments are never uppercase**: the diameters `D` of the single averages
    (`arithmeticmeandiameter`, `quadraticmeandiameter`, `weisediameter`, `centralbasalareadiameter`,
    `dominantdiameter`, `hohenaldiameters`) and of `diametrictable` are now `d` (positional, so the calls do
    not change); the same in `basalarea` of ForestFoundations.jl.
  - **`standmetrics` is the only summary of the stand, and the heights are gone.**
    - `standmetrics(d, area)` returns `n, g, N, G, Dm, Dg, CD`: the number of trees, the basal area
      of the sample (`g`, it was `Gp`), the number of trees and the basal area per hectare (`N`, `G`;
      the expansion factor `F` is no longer a column), the arithmetic and quadratic mean diameters
      and the coefficient of variation. `Dg` and `g` come from the mean and the standard deviation,
      `Dg² = Dm² + (n - 1)/n sD²` and `g = n π Dg² / 4`, in a single pass through the data.
    - `standmetrics(species, plots, d, area)` returns the same for each species, plus `plots`, `RDe`,
      `RDo`, `AF`, `RF`, `VC` and `IVI`, sorted by IVI: it replaces `phytosociology`, with the same
      indices (the basal area column `Gp` is now `g`).
    - The old `standmetrics(D, H, area)` is gone: there is no height, and no `Dl, Dw, dz, DD, Du`
      column. Those averages are still available one by one, outside the summary:
      `hohenaldiameters` (`Dl`, `Du`), `weisediameter`, `centralbasalareadiameter` and
      `dominantdiameter`. The dominant diameter is a property of the stand, not of a species.

### Removed

- `diametermetrics` and `heightmetrics`: use `standmetrics` (`Dm`, `Dg`, `CD`) and the single
  averages above.
- All the heights of the stand: `arithmeticmeanheight`, `dominantheight`, `loreymeanheight` and the
  columns `Hl, Hm, HD, HL, Hu, CH`. The heights that remain are those of the cubage (`cubage`,
  `artificialformfactor`), which are inputs of the volume of each tree.
- `phytosociology`: use `standmetrics(species, plots, d, area)`.

- Unused dependencies `QuadGK` and `Roots`.

- **Stem taper application** (`taperdiameter`, `taperheight`, `taperedvolume`, `logassortment`)
  and **site classification** (`siteClassification`, `hdomClassification`, `siteTable`). They
  depended on the fitted models of `ForestModeling.jl` (`TaperFit`, `AllometricModel`); to be
  implemented again once the modeling scope is defined.
- **Dependency on `ForestModeling.jl` and its re-export.** The regression engine
  (`regression`, `fit`, `criteriaTable`/`criteriaSelection`, `regressionGrouped`, `fitRobust`,
  `fitGLM`, ...) is no longer re-exported from `ForestMensuration.jl`; fitting is left to
  specialised packages (GLM.jl, LsqFit.jl, MixedModels.jl). `ForestModeling.jl` and
  `ForestEcology.jl` are no longer developed as separate packages (kept under `Extras/`);
  the ecology functions live in `ForestMensuration.jl`. `StatsModels` and `Tables` were also
  dropped from the dependencies.

### Other Changes

- `cubage.jl` now uses `ForestFoundations.inreferencevolume` instead of its private
  `_asvolume`.
- Documentation (docstrings, tutorial, README) uses the standardized symbols and math
  notation; fixed the symbols rendered as code instead of math in the `cubage.jl`
  docstrings, the missing signature of the grouped `diametrictable` methods, and the
  tutorial's description of the bark thickness argument.

## [2.3.1] - 2026-08-20

### Other Changes

- `cubage.jl`'s internal metric/imperial volume normalization now goes through
  `ForestFoundations.referencevolume` (new in `ForestFoundations.jl`) instead of its own
  copy of the same `ImperialUnits` check — no behavior change.

## [2.3.0] - 2026-08-19

### Changed

- **Forest inventory sampling extracted to `ForestInventory.jl`:** the 11 sampling designs
  and `SamplingReport`/its accessors now live in
  [ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl), a new package
  in the `JuliaForests` org. `ForestMensuration.jl` depends on it and re-exports it exactly
  like it already does for `ForestModeling.jl`, so every inventory name is still available
  unqualified from `using ForestMensuration`. `Distributions` and `LinearAlgebra` were
  dropped from `ForestMensuration.jl`'s own dependencies (they were only used by the
  inventory module).

### Breaking Changes

- **Forest inventory sampling API redesigned** (in `ForestInventory.jl`, re-exported here):
  the `sampling(::Type{Design}, ...)` dispatcher and its 11 `SamplingDesign` subtypes are
  gone — each design is now its own direct function (`simpleCasualSampling`,
  `stratifiedSampling`, `clusterSampling`, ...). The 5 designs that took a `DataFrame` +
  column-`Symbol`s (`stratifiedSampling`, `clusterSampling`,
  `multistartSystematicSampling`, `twoStageSampling`, `horizontalPointSampling`) now take
  plain vectors, matching the other 6. `stratifiedSampling`'s `strata_area` is now an
  `AbstractDict` (stratum label → area) instead of a vector implicitly ordered by sorted
  stratum — the previous vector form silently mismatched a stratum's area if the caller's
  plots weren't already sorted by stratum. Every design's sampled-quantity argument
  (previously `volume`, always defaulting a bare number to `m^3`) is renamed `value`/
  `value1`/`value2` and no longer assumes any unit — a bare number now stays unitless,
  since the sampled quantity may not be volume at all (basal area, tree count, ...).
  Result-table columns are renamed from short abbreviations to full words throughout
  (`vm`→`mean`, `cv`→`coefficientOfVariation`, `pop`→`population`, `vha`→`meanPerHectare`,
  ...) — see each function's docstring for the full column list.

## [2.0.0] - 2025-02-09

### Breaking Changes

- **Regression Implementation Refactored:**  
  The underlying implementation of the `regression` function has been completely refactored.  
  Previously, it relied on the `GLM.lm` function and its associated structure.  
  It now uses a custom-built regression structure and implementation.  
  **Note:** Although the public API (function call and usage) remains unchanged, this internal change may affect any code that depended on the internal structure of the regression result.

### Other Changes

- Bumped version from 1.0.0 to 2.0.0 to reflect the breaking change in the regression implementation.
