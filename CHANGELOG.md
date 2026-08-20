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
