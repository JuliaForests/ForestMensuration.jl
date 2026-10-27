# Calculates the number of classes using Sturges' formula.
_sturges(n::Int) = ceil(Int, log2(n)) + 1
# Index of the class [k hi, (k + 1) hi) that holds a value. The quotient is rounded to 10 digits
# so that a value on a limit (0.3 with a width of 0.1) is not sent down by floating-point noise.
_classindex(x::Real, hi::Real) = floor(Int, round(x / hi, digits=10))
# Calculates the amplitude (range) of a vector of values.
_amplitude(x::AbstractVector) = maximum(x) - minimum(x)
# Calculates the class breadth (width) for a given amplitude and number of classes.
function _classbreadth(amp::Real, nclass::Int)
  hi = amp / nclass
  loghi = log10(hi)
  if loghi >= 0
    step = exp10(floor(loghi))
    rate = hi / step
    if rate <= 1.1
      nothing
    elseif rate <= 2.2
      step *= 2
    elseif rate <= 5.5
      step *= 5
    else
      step *= 10
    end
    return step
  else
    step = exp10(-floor(loghi))
    rate = hi * step
    if rate <= 1.1
      nothing
    elseif rate <= 2.2
      step /= 2
    elseif rate <= 5.5
      step /= 5
    else
      step /= 10
    end
    return step^-1
  end
end

# Unit of a unitful sample: the unit the observations themselves are expressed in.
_sampleunit(x::AbstractVector{<:Quantity}) = unit(first(x))

# Class width chosen from Sturges' rule for the amplitude of the sample, in the type of the sample
# (a plain number, or a quantity in the unit of the observations).
_autowidth(x::AbstractVector{<:Real}) = _classbreadth(_amplitude(x), _sturges(length(x)))

function _autowidth(x::AbstractVector{<:Quantity})
  ux = _sampleunit(x)
  return _classbreadth(ustrip(uconvert(ux, _amplitude(x))), _sturges(length(x))) * ux
end

"""
    frequencytable(x::AbstractVector{<:Real}, hi::Real)
    frequencytable(x::AbstractVector{<:Quantity}, hi::Quantity)

Creates a frequency table for a vector of values given a class width.

# Arguments
- `x::AbstractVector{<:Real}`: The vector of values.
- `hi::Real`: The class width.

# Units

`frequencytable` is unit-agnostic: it classifies whatever variable it is given
(diameters, heights, volumes, ages). When `x` carries `Unitful` quantities, the class
limits `LI`, `Xi` and `LS` are returned in the same unit as `x`, and the class width `hi`
must then be a quantity too (it may be in another unit and is converted). When `x` holds
plain numbers the table is returned unitless — no unit is assumed, because the variable
is unknown. Use [`diametrictable`](@ref) for diameter-specific tables, which require units.

# Returns
- `DataFrame`: A DataFrame with a row per class, from the class of the smallest value to the class of the largest one (the empty classes included, with frequency zero), and the columns:
  - `LI`, `Xi`, `LS`: the lower limit, the center and the upper limit of the class. A class is the interval ``[LI, LS)``, closed on the left, so a value on a limit belongs to the class that starts there (12 is in the class 12-14, not in 10-12);
  - `fi`: the absolute frequency, the number of observations in the class;
  - `Fi`: the cumulative absolute frequency;
  - `fri`: the relative frequency, in percent of the observations;
  - `Fri`: the cumulative relative frequency, in percent.

# Example
```julia-repl

# Define the vector of values
julia> x = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0];

# Calculate the frequency table with a class width of 2
julia> frequencytable(x, 2)
8×7 DataFrame
 Row │ LI       Xi       LS       fi     Fi     fri      Fri
     │ Float64  Float64  Float64  Int64  Int64  Float64  Float64
─────┼───────────────────────────────────────────────────────────
   1 │    10.0     11.0     12.0      1      1     10.0     10.0
   2 │    12.0     13.0     14.0      2      3     20.0     30.0
   3 │    14.0     15.0     16.0      1      4     10.0     40.0
   4 │    16.0     17.0     18.0      1      5     10.0     50.0
   5 │    18.0     19.0     20.0      2      7     20.0     70.0
   6 │    20.0     21.0     22.0      1      8     10.0     80.0
   7 │    22.0     23.0     24.0      1      9     10.0     90.0
   8 │    24.0     25.0     26.0      1     10     10.0    100.0

# the same sample carrying units keeps them in the class limits
julia> frequencytable([10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm", 2u"cm")
8×7 DataFrame
 Row │ LI         Xi         LS         fi     Fi     fri      Fri
     │ Quantity…  Quantity…  Quantity…  Int64  Int64  Float64  Float64
─────┼─────────────────────────────────────────────────────────────────
   1 │   10.0 cm    11.0 cm    12.0 cm      1      1     10.0     10.0
   2 │   12.0 cm    13.0 cm    14.0 cm      2      3     20.0     30.0
  ⋮
```
"""
function frequencytable(x::AbstractVector{<:Real}, hi::Real)
  if hi <= 0
    throw(DomainError("The class width must be positive."))
  end
  n = length(x)
  k = _classindex.(x, hi)
  # every class from the first to the last, the empty ones included (frequency zero)
  classes = minimum(k):maximum(k)
  LI = classes .* float(hi)
  Xi = LI .+ float(hi) / 2
  LS = LI .+ float(hi)
  fi = [count(==(c), k) for c in classes]
  Fi = cumsum(fi)
  fri = (fi ./ n) .* 100
  Fri = cumsum(fri)
  DataFrame(LI=LI, Xi=Xi, LS=LS, fi=fi, Fi=Fi, fri=fri, Fri=Fri)
end

function frequencytable(x::AbstractVector{<:Quantity}, hi::Quantity)
  ux = _sampleunit(x)
  # classification happens on plain numbers in a single unit, then the class limits are
  # restored so the table speaks the same unit as the observations
  ftable = frequencytable(ustrip.(uconvert.(ux, x)), ustrip(uconvert(ux, hi)))
  ftable.LI = ftable.LI * ux
  ftable.Xi = ftable.Xi * ux
  ftable.LS = ftable.LS * ux
  return ftable
end

"""
    frequencytable(x::AbstractVector{<:Real})
    frequencytable(x::AbstractVector{<:Quantity})

Creates a frequency table for a vector of values, choosing the class width automatically
from Sturges' rule.

# Arguments
- `x::AbstractVector{<:Real}`: The vector of values.

# Units

The class limits are returned in the unit of `x` when it carries `Unitful` quantities,
and unitless otherwise.

# Returns
- `DataFrame`: A DataFrame with a row per class, from the class of the smallest value to the class of the largest one (the empty classes included, with frequency zero), and the columns:
  - `LI`, `Xi`, `LS`: the lower limit, the center and the upper limit of the class. A class is the interval ``[LI, LS)``, closed on the left, so a value on a limit belongs to the class that starts there (12 is in the class 12-14, not in 10-12);
  - `fi`: the absolute frequency, the number of observations in the class;
  - `Fi`: the cumulative absolute frequency;
  - `fri`: the relative frequency, in percent of the observations;
  - `Fri`: the cumulative relative frequency, in percent.

# Example
```julia-repl

# Define the vector of values
julia> x = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0];

# Calculate the frequency table with auto class width
julia> frequencytable(x)
3×7 DataFrame
 Row │ LI       Xi       LS       fi     Fi     fri      Fri
     │ Float64  Float64  Float64  Int64  Int64  Float64  Float64
─────┼───────────────────────────────────────────────────────────
   1 │    10.0     12.5     15.0      3      3     30.0     30.0
   2 │    15.0     17.5     20.0      4      7     40.0     70.0
   3 │    20.0     22.5     25.0      3     10     30.0    100.0
```
"""
frequencytable(x::AbstractVector{<:Real}) = frequencytable(x, _autowidth(x))

frequencytable(x::AbstractVector{<:Quantity}) = frequencytable(x, _autowidth(x))

"""
    frequencytable(group::Symbol, x::Symbol, data::AbstractDataFrame)

Creates a frequency table for grouped data in a DataFrame.

# Arguments
- `group::Symbol`: The column holding the grouping variable.
- `x::Symbol`: The column holding the values variable.
- `data::AbstractDataFrame`: The DataFrame containing the data.

# Units

The value column may hold either plain numbers or `Unitful` quantities (the class width
must then be a quantity too); the class limits are returned in the same form.

# Returns
- `DataFrame`: A DataFrame containing the frequency table for each group.

# Example
```julia-repl
julia> using DataFrames

# Define the data
julia> diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0];
julia> species = ["Oak", "Oak", "Oak", "Oak", "Oak", "Pine", "Pine", "Pine", "Pine", "Pine"];
julia> data = DataFrame(species=species, diameters=diameters);

# Calculate the frequency table by group with auto class width
julia> frequencytable(:species, :diameters, data)
8×8 DataFrame
 Row │ species  LI       Xi       LS       fi     Fi     fri      Fri
     │ String   Float64  Float64  Float64  Int64  Int64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────
   1 │ Oak         10.0     11.0     12.0      1      1     20.0     20.0
   2 │ Oak         12.0     13.0     14.0      2      3     40.0     60.0
   3 │ Oak         14.0     15.0     16.0      1      4     20.0     80.0
   4 │ Oak         16.0     17.0     18.0      1      5     20.0    100.0
   5 │ Pine        18.0     19.0     20.0      2      2     40.0     40.0
   6 │ Pine        20.0     21.0     22.0      1      3     20.0     60.0
   7 │ Pine        22.0     23.0     24.0      1      4     20.0     80.0
   8 │ Pine        24.0     25.0     26.0      1      5     20.0    100.0
```
"""
function frequencytable(group::Symbol, x::Symbol, data::AbstractDataFrame)
  combine(groupby(data, group)) do df
    frequencytable(df[:, x])
  end
end

"""
    frequencytable(group::Symbol, x::Symbol, hi::Union{Quantity,Real}, data::AbstractDataFrame)

Creates a frequency table for grouped data in a DataFrame with a specified class width.

# Arguments
- `group::Symbol`: The column holding the grouping variable.
- `x::Symbol`: The column holding the values variable.
- `hi`: The class width: a number when the value column is unitless, a quantity when it carries units.
- `data::AbstractDataFrame`: The DataFrame containing the data.

# Returns
- `DataFrame`: A DataFrame containing the frequency table for each group.

# Example
```julia-repl
julia> using DataFrames

# Define the data
julia> diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0];
julia> species = ["Oak", "Oak", "Oak", "Oak", "Oak", "Pine", "Pine", "Pine", "Pine", "Pine"];
julia> data = DataFrame(species=species, diameters=diameters);

# Calculate the frequency table by group with a class width of 2
julia> frequencytable(:species, :diameters, 2, data)
8×8 DataFrame
 Row │ species  LI       Xi       LS       fi     Fi     fri      Fri
     │ String   Float64  Float64  Float64  Int64  Int64  Float64  Float64
─────┼────────────────────────────────────────────────────────────────────
   1 │ Oak         10.0     11.0     12.0      1      1     20.0     20.0
   2 │ Oak         12.0     13.0     14.0      2      3     40.0     60.0
   3 │ Oak         14.0     15.0     16.0      1      4     20.0     80.0
   4 │ Oak         16.0     17.0     18.0      1      5     20.0    100.0
   5 │ Pine        18.0     19.0     20.0      2      2     40.0     40.0
   6 │ Pine        20.0     21.0     22.0      1      3     20.0     60.0
   7 │ Pine        22.0     23.0     24.0      1      4     20.0     80.0
   8 │ Pine        24.0     25.0     26.0      1      5     20.0    100.0
```
"""
function frequencytable(group::Symbol, x::Symbol, hi::Union{Quantity,Real}, data::AbstractDataFrame)
  combine(groupby(data, group)) do df
    frequencytable(df[:, x], hi)
  end
end

"""
    diametrictable(d::AbstractVector{<:Length}, hi::Length; plotarea::Area=1.0u"ha")

Creates a diametric table for a vector of diameters at breast height given a class width and plot area.

# Arguments
- `d::AbstractVector{<:Length}`: The vector of diameters at breast height.
- `hi::Length`: The class width.
- `plotarea::Area=1.0u"ha"`: The sampled plot area.

# Units

Unlike the general-purpose [`frequencytable`](@ref), this function is diameter-specific:
diameters, class width and plot area must all carry units, and any length and area unit may
be used (imperial included). The returned table carries units:

- `LI`, `Xi`, `LS` in the unit of `d`;
- `g`, `ng` and `Ng` in square feet (`ft^2`) when `d` is imperial and square meters (`m^2`) otherwise, where `g` is the basal area of the class center `Xi`, `ng` the basal area of the class (`fi` trees of area `g`) and `Ng` its cumulative sum (uppercase marks the cumulative value, as in `fi` and `Fi`);
- `Ni` and `NFi` per acre (`ac^-1`) when `d` is imperial and per hectare (`ha^-1`) otherwise, with `Gi` and `GFi` following the same reference area.

The per-area columns are omitted when the plot already covers exactly one reference area
(1 ha in the metric system, 1 ac in the imperial one), since the expansion would be a
no-op.

# Returns
- `DataFrame`: A DataFrame with the columns of [`frequencytable`](@ref) (`LI`, `Xi`, `LS`, `fi`, `Fi`, `fri`, `Fri`, the classes being the intervals ``[LI, LS)``) plus:
  - `g`: the basal area of the tree of the class center, ``g = \\pi X_i^2 / 4``;
  - `ng`: the basal area of the class in the plot, ``fi \\, g``, and `Ng` its cumulative sum;
  - `Ni`, `NFi`: the number of trees of the class and its cumulative sum, per hectare (per acre if imperial);
  - `Gi`, `GFi`: the basal area of the class and its cumulative sum, per hectare (per acre if imperial).

# Example
```julia-repl

# Define the vector of diameter values
julia> diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm";

# Calculate the diametric table with a class width of 2 cm and plot area of 500 m² (0.05 ha)
julia> diametrictable(diameters, 2u"cm", plotarea=500u"m^2")
8×14 DataFrame
 Row │ LI         Xi         LS         fi     Fi     fri      Fri      g               ng              Ng              Ni          NFi          Gi                  GFi
     │ Quantity…  Quantity…  Quantity…  Int64  Int64  Float64  Float64  Quantity…       Quantity…       Quantity…       Quantity…   Quantity…    Quantity…           Quantity…
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │   10.0 cm    11.0 cm    12.0 cm      1      1     10.0     10.0  0.00950332 m^2  0.00950332 m^2  0.00950332 m^2  20.0 ha^-1   20.0 ha^-1  0.190066 m^2 ha^-1  0.190066 m^2 ha^-1
   2 │   12.0 cm    13.0 cm    14.0 cm      2      3     20.0     30.0   0.0132732 m^2   0.0265465 m^2   0.0360498 m^2  40.0 ha^-1   60.0 ha^-1  0.530929 m^2 ha^-1  0.720996 m^2 ha^-1
  ⋮
```
"""
function diametrictable(d::AbstractVector{<:Length}, hi::Length; plotarea::Area=1.0u"ha")
  if hi <= zero(hi)
    throw(DomainError("The class width must be positive."))
  elseif plotarea <= zero(plotarea)
    throw(DomainError("The plot area must be positive."))
  elseif any(x -> x <= zero(x), d)
    throw(DomainError("Diameters must be positive"))
  end
  ftable = frequencytable(d, hi)
  ftable.g = basalarea.(ftable.Xi)
  ftable.ng = ftable.fi .* ftable.g
  ftable.Ng = cumsum(ftable.ng)
  # expansion factor to the reference area (ha or ac) of the plot area
  EF = expansionfactor(plotarea)
  if !isone(ustrip(EF))
    ftable.Ni = ftable.fi * EF
    ftable.NFi = cumsum(ftable.Ni)
    ftable.Gi = ftable.ng * EF
    ftable.GFi = cumsum(ftable.Gi)
  end
  return ftable
end

"""
    diametrictable(d::AbstractVector{<:Length}; plotarea::Area=1.0u"ha")

Creates a diametric table for a vector of diameters at breast height, choosing the class width
automatically from Sturges' rule.

# Arguments
- `d::AbstractVector{<:Length}`: The vector of diameters at breast height.
- `plotarea::Area=1.0u"ha"`: The sampled plot area.

# Units

Same as [`diametrictable(d, hi)`](@ref): diameters and plot area must carry units, and the returned table carries units.

# Returns
- `DataFrame`: A DataFrame containing the diametric table.

# Example
```julia-repl

# Define the vector of diameter values
julia> diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm";

# Calculate the diametric table with auto class width and plot area of 500 m² (0.05 ha)
julia> diametrictable(diameters, plotarea=500u"m^2")
3×14 DataFrame
 Row │ LI         Xi         LS         fi     Fi     fri      Fri      g              ng             Ng             Ni          NFi          Gi                  GFi
     │ Quantity…  Quantity…  Quantity…  Int64  Int64  Float64  Float64  Quantity…      Quantity…      Quantity…      Quantity…   Quantity…    Quantity…           Quantity…
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │   10.0 cm    12.5 cm    15.0 cm      3      3     30.0     30.0  0.0122718 m^2  0.0368155 m^2  0.0368155 m^2  60.0 ha^-1   60.0 ha^-1  0.736311 m^2 ha^-1  0.736311 m^2 ha^-1
   2 │   15.0 cm    17.5 cm    20.0 cm      4      7     40.0     70.0  0.0240528 m^2  0.0962113 m^2   0.133027 m^2  80.0 ha^-1  140.0 ha^-1   1.92423 m^2 ha^-1   2.66054 m^2 ha^-1
  ⋮
```
"""
diametrictable(d::AbstractVector{<:Length}; plotarea::Area=1.0u"ha") = diametrictable(d, _autowidth(d), plotarea=plotarea)

"""
    diametrictable(group::Symbol, d::Symbol, data::AbstractDataFrame; plotarea::Area=1.0u"ha")

Creates a diametric table for grouped data in a DataFrame.

# Arguments
- `group::Symbol`: The column holding the grouping variable.
- `d::Symbol`: The column holding the diameters at breast height.
- `data::AbstractDataFrame`: The DataFrame containing the data.
- `plotarea::Area=1.0u"ha"`: The sampled plot area.

# Units

The diameter column must hold `Unitful` quantities, and the output columns carry units.

# Returns
- `DataFrame`: A DataFrame containing the diametric table for each group.

# Example
```julia-repl
julia> using DataFrames

# Define the data
julia> diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm";
julia> species = ["Oak", "Oak", "Oak", "Oak", "Oak", "Pine", "Pine", "Pine", "Pine", "Pine"];
julia> data = DataFrame(species=species, diameters=diameters);

# Calculate the diametric table by group with auto class width and plot area of 0.05 ha (500 m²)
julia> diametrictable(:species, :diameters, data, plotarea=0.05u"ha")
8×15 DataFrame
 Row │ species  LI         Xi         LS         fi     Fi     fri      Fri      g               ng              Ng              Ni          NFi          Gi                  GFi
     │ String   Quantity…  Quantity…  Quantity…  Int64  Int64  Float64  Float64  Quantity…       Quantity…       Quantity…       Quantity…   Quantity…    Quantity…           Quantity…
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Oak        10.0 cm    11.0 cm    12.0 cm      1      1     20.0     20.0  0.00950332 m^2  0.00950332 m^2  0.00950332 m^2  20.0 ha^-1   20.0 ha^-1  0.190066 m^2 ha^-1  0.190066 m^2 ha^-1
   2 │ Oak        12.0 cm    13.0 cm    14.0 cm      2      3     40.0     60.0   0.0132732 m^2   0.0265465 m^2   0.0360498 m^2  40.0 ha^-1   60.0 ha^-1  0.530929 m^2 ha^-1  0.720996 m^2 ha^-1
  ⋮
```
"""
function diametrictable(group::Symbol, d::Symbol, data::AbstractDataFrame; plotarea::Area=1.0u"ha")
  combine(groupby(data, group)) do df
    diametrictable(df[:, d], plotarea=plotarea)
  end
end

"""
    diametrictable(group::Symbol, d::Symbol, hi::Length, data::AbstractDataFrame; plotarea::Area=1.0u"ha")

Creates a diametric table for grouped data in a DataFrame with a specified class width.

# Arguments
- `group::Symbol`: The column holding the grouping variable.
- `d::Symbol`: The column holding the diameters at breast height.
- `hi::Length`: The class width.
- `data::AbstractDataFrame`: The DataFrame containing the data.
- `plotarea::Area=1.0u"ha"`: The sampled plot area.

# Returns
- `DataFrame`: A DataFrame containing the diametric table for each group.

# Example
```julia-repl
julia> using DataFrames

# Define the data
julia> diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm";
julia> species = ["Oak", "Oak", "Oak", "Oak", "Oak", "Pine", "Pine", "Pine", "Pine", "Pine"];
julia> data = DataFrame(species=species, diameters=diameters);

# Calculate the diametric table by group with a class width of 3 cm and plot area of 0.05 ha (500 m²)
julia> diametrictable(:species, :diameters, 3u"cm", data, plotarea=0.05u"ha")
6×15 DataFrame
 Row │ species  LI         Xi         LS         fi     Fi     fri      Fri      g               ng              Ng              Ni          NFi          Gi                  GFi
     │ String   Quantity…  Quantity…  Quantity…  Int64  Int64  Float64  Float64  Quantity…       Quantity…       Quantity…       Quantity…   Quantity…    Quantity…           Quantity…
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Oak         9.0 cm    10.5 cm    12.0 cm      1      1     20.0     20.0  0.00865901 m^2  0.00865901 m^2  0.00865901 m^2  20.0 ha^-1   20.0 ha^-1   0.17318 m^2 ha^-1   0.17318 m^2 ha^-1
   2 │ Oak        12.0 cm    13.5 cm    15.0 cm      2      3     40.0     60.0   0.0143139 m^2   0.0286278 m^2   0.0372868 m^2  40.0 ha^-1   60.0 ha^-1  0.572555 m^2 ha^-1  0.745736 m^2 ha^-1
  ⋮
```
"""
function diametrictable(group::Symbol, d::Symbol, hi::Length, data::AbstractDataFrame; plotarea::Area=1.0u"ha")
  combine(groupby(data, group)) do df
    diametrictable(df[:, d], hi, plotarea=plotarea)
  end
end
