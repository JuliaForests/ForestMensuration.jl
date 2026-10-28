# Geometry

"""
    cylindervolume(h::Length, d::Length)

Calculates the volume of a cylinder (``v_{cil}``). With the stump height ``h_t`` and the diameter ``d_t`` at its top, it estimates the volume of the tree stump (``v_t``) remaining after clear-cutting.

# Arguments
- `h::Length`: The height of the cylinder. Must be non-negative; a stump measured at ground level yields a volume of zero.
- `d::Length`: The diameter of the cylinder. Must be non-negative.

# Returns
- `Quantity`: The volume of the cylinder in cubic feet `ft^3` when the diameter is given
  in imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
The volume of a cylinder is the product of its sectional area and its height:

```math
v_{cil} = \\frac{\\pi d^2}{4} h
```

# Examples

```julia-repl
julia> cylindervolume(0.1u"m", 27.7u"cm")
0.006026281567932282 m^3
```
"""
function cylindervolume(h::Length, d::Length)
  h < zero(h) && throw(DomainError(h, "The height must be a non-negative value."))
  v = sectionalarea(d) * h
  inreferencevolume(v, d)
end

"""
    conevolume(h::Length, d::Length)

Calculates the volume of a cone, used to estimate the volume of the tip of the tree (``v_p``).

# Arguments
- `h::Length`: The height of the cone (the tip length ``h_p``). Must be non-negative.
- `d::Length`: The diameter at the base of the cone. Must be non-negative; a bole whose last measured diameter is already zero yields a tip volume of zero.

# Returns
- `Quantity`: The volume of the cone in cubic feet `ft^3` when the diameter is given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
The volume of a cone is one third of the volume of a cylinder with the same base and height:

```math
v_p = \\frac{\\pi d^2}{12} h
```

# Examples

```julia-repl
julia> conevolume(0.6u"m", 1.2u"cm")
2.261946710584651e-5 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
conevolume(h::Length, d::Length) = cylindervolume(h, d) / 3

# Smalian: diameters at the ends of the sections (limits)

"""
    smalian(l::Length, d1::Length, d2::Length)

Calculates the volume of a single log (``v_a``) using Smalian's method.

# Arguments
- `l::Length`: Log length.
- `d1::Length`: Diameter at the large end of the log (base).
- `d2::Length`: Diameter at the small end of the log (top).

# Returns
- `Quantity`: The volume of the log in cubic feet `ft^3` when the diameters are given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
The volume is the mean of the sectional areas of the two ends times the length:

```math
v_a = \\frac{a_1 + a_2}{2} l
```

Where:

* ``a_1`` = sectional area at the large end of the log.
* ``a_2`` = sectional area at the small end of the log.
* ``l`` = log length.

# Examples

```julia-repl
julia> smalian(1.2u"m", 27.7u"cm", 22.3u"cm")
0.05959192856814871 m^3

# Any length unit, even mixed
julia> smalian(120.0u"cm", 277.0u"mm", 22.3u"cm")
0.05959192856814871 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
function smalian(l::Length, d1::Length, d2::Length)
  l <= zero(l) && throw(DomainError(l, "Log length must be greater than zero."))
  a1 = sectionalarea(d1)
  a2 = sectionalarea(d2)
  v = ((a1 + a2) / 2) * l
  inreferencevolume(v, l)
end

"""
    smalian(h::AbstractVector{<:Length}, d::AbstractVector{<:Length})

Calculates the volume of the measured bole (``v_m``) using Smalian's method, from the heights of the measurements (absolute positions) and the diameters at the limits of the sections.

# Arguments
- `h::AbstractVector{<:Length}`: Heights of the measurements from the ground, in increasing order. Each pair of consecutive heights limits a section.
- `d::AbstractVector{<:Length}`: Diameters measured at the heights `h`.

# Returns
- `Quantity`: The volume of the measured bole, the sum of the volumes of its `length(h) - 1` sections, in cubic feet `ft^3` when the diameters are given in imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
Each section is cubed by Smalian's formula, with its length the difference between consecutive heights:

```math
v_m = \\sum_{j=2}^{n} \\frac{a_{j-1} + a_j}{2} (h_j - h_{j-1})
```

Where:

* ``a_j`` = sectional area at the height ``h_j``.
* ``n`` = number of measurements along the bole.

# Examples

```julia-repl
julia> h = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3] .* u"m";

julia> d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm";

julia> smalian(h, d)
0.3190694175969075 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
function smalian(h::AbstractVector{<:Length}, d::AbstractVector{<:Length})
  checklengths(:h => h, :d => d)
  length(h) >= 2 || throw(ArgumentError("At least two measurements are required."))
  sum(smalian(h[j] - h[j-1], d[j-1], d[j]) for j in 2:length(h))
end

"""
    smalian(l::Length, d::AbstractVector{<:Length})
    smalian(l::AbstractVector{<:Length}, d::AbstractMatrix{<:Length})

Calculates the volume of a log (``v_a``) using Smalian's method with relative positions: the log is divided into sections of equal length and the diameters are measured at their limits (for example at 0, 10, ..., 100 % of the length). Only the length of the log is annotated, not the heights of the measurements.

# Arguments
- `l::Length`: Length of the log, from the first to the last diameter.
- `d::AbstractVector{<:Length}`: Diameters at the limits of the equal sections, in order from the base (at least 2): ``n`` diameters limit ``n - 1`` sections.

For many logs, as annotated in a field sheet, a log per row:
- `l::AbstractVector{<:Length}`: The length of each log.
- `d::AbstractMatrix{<:Length}`: The diameters, a row per log (in the order of `l`) and a column per relative position. A `DataFrame` of diameters becomes this matrix with `Matrix(df)`.

# Returns
- `Quantity`: The volume of the log; with many logs, a `Vector` with the volume of each one, in the order of the rows of `d`. In cubic feet `ft^3` when the diameters are given in imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
With ``n`` diameters there are ``n - 1`` sections of length ``l / (n - 1)``, each one cubed by Smalian's formula:

```math
v_a = \\sum_{j=2}^{n} \\frac{a_{j-1} + a_j}{2} \\frac{l}{n - 1}
```

With two diameters it is the volume of a single section, `smalian(l, d1, d2)`.

# Examples

```julia-repl
# One log of 7.10 m, with the diameters at 0, 10, ..., 100 % of its length
julia> d = [81.5, 74.5, 72.9, 69.5, 67.2, 66.2, 65.8, 64.9, 64.9, 64.8, 65.3] .* u"cm";

julia> smalian(7.10u"m", d)
2.6208212537838596 m^3

# The field sheet: the length of each log and its diameters, a log per row
julia> l = [7.10, 7.67, 7.62] .* u"m";

julia> d = [81.5 74.5 72.9 69.5 67.2 66.2 65.8 64.9 64.9 64.8 65.3;
            67.2 63.7 63.5 62.7 62.0 61.3 61.4 61.7 61.7 59.5 59.4;
            61.1 60.1 60.2 59.8 58.6 58.6 58.3 59.4 58.7 57.7 57.7] .* u"cm";

julia> smalian(l, d)
3-element Vector{Quantity{Float64, 𝐋^3, Unitful.FreeUnits{(m^3,), 𝐋^3, nothing}}}:
 2.6208212537838596 m^3
 2.323398671705035 m^3
 2.0894795083931927 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
function smalian(l::Length, d::AbstractVector{<:Length})
  length(d) >= 2 || throw(ArgumentError("At least two diameters are required, the limits of a section."))
  ls = l / (length(d) - 1)
  sum(smalian(ls, d[j-1], d[j]) for j in 2:length(d))
end

# Many logs of a field sheet: the length of each log and a row of `d` each
function smalian(l::AbstractVector{<:Length}, d::AbstractMatrix{<:Length})
  checklengths(:l => l, :d => eachrow(d))
  smalian.(l, eachrow(d))
end

# Huber: diameters at the middles of the sections

"""
    huber(l::Length, d12::Length)

Calculates the volume of a single log (``v_a``) using Huber's method.

# Arguments
- `l::Length`: Log length.
- `d12::Length`: Diameter at the exact midpoint of the log (``d_{1/2}``).

# Returns
- `Quantity`: The volume of the log in cubic feet `ft^3` when the diameter is given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
The volume is the sectional area at the middle of the log times its length:

```math
v_a = a_{1/2} l
```

Where:

* ``a_{1/2}`` = sectional area at the midpoint of the log length.
* ``l`` = log length.

# Examples

```julia-repl
julia> huber(1.2u"m", 24.8u"cm")
0.057966154369916 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.2.
"""
function huber(l::Length, d12::Length)
  l <= zero(l) && throw(DomainError(l, "Log length must be greater than zero."))
  a12 = sectionalarea(d12)
  v = a12 * l
  inreferencevolume(v, l)
end

"""
    huber(l::Length, d::AbstractVector{<:Length})
    huber(l::AbstractVector{<:Length}, d::AbstractMatrix{<:Length})

Calculates the volume of a log (``v_a``) using Huber's method with relative positions: the log is divided into sections of equal length and the diameter is measured at the middle of each one (for example at 10, 30, 50, 70 and 90 % of the length, for 5 sections). It is the methodology of Hohenadl. Only the length of the log is annotated, not the heights of the measurements.

# Arguments
- `l::Length`: Length of the log.
- `d::AbstractVector{<:Length}`: Diameters at the middles of the equal sections, in order from the base (at least 1): ``n`` diameters, ``n`` sections.

For many logs, as annotated in a field sheet, a log per row:
- `l::AbstractVector{<:Length}`: The length of each log.
- `d::AbstractMatrix{<:Length}`: The diameters, a row per log (in the order of `l`) and a column per relative position. A `DataFrame` of diameters becomes this matrix with `Matrix(df)`.

# Returns
- `Quantity`: The volume of the log; with many logs, a `Vector` with the volume of each one, in the order of the rows of `d`. In cubic feet `ft^3` when the diameters are given in imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
With ``n`` diameters there are ``n`` sections of length ``l / n``, each one cubed by Huber's formula:

```math
v_a = \\frac{l}{n} \\sum_{j=1}^{n} a_j
```

With one diameter it is the volume of a single section, `huber(l, d12)`.

# Examples

```julia-repl
# The 15.8 m of bole above a stump of 0.1 m, in 10 sections, with the diameter at the middle of each one
julia> d = [24.0, 20.5, 19.7, 18.6, 17.7, 15.8, 11.5, 8.0, 5.9, 1.5] .* u"cm";

julia> huber(15.8u"m", d)
0.3135257003685299 m^3

# The field sheet: the diameters at 10, 30, 50, 70 and 90 % of each log, the middles of 5 sections
julia> l = [7.10, 7.67, 7.62] .* u"m";

julia> d = [74.5 69.5 66.2 64.9 64.8;
            63.7 62.7 61.3 61.7 59.5;
            60.1 59.8 58.6 59.4 57.7] .* u"cm";

julia> huber(l, d)
3-element Vector{Quantity{Float64, 𝐋^3, Unitful.FreeUnits{(m^3,), 𝐋^3, nothing}}}:
 2.5845149042118982 m^3
 2.3004237231802587 m^3
 2.0922223119877246 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.4.
"""
function huber(l::Length, d::AbstractVector{<:Length})
  isempty(d) && throw(ArgumentError("At least one diameter is required, the middle of a section."))
  ls = l / length(d)
  sum(huber(ls, x) for x in d)
end

function huber(l::AbstractVector{<:Length}, d::AbstractMatrix{<:Length})
  checklengths(:l => l, :d => eachrow(d))
  huber.(l, eachrow(d))
end

# Newton: limit, middle, limit

"""
    newton(l::Length, d1::Length, d12::Length, d2::Length)

Calculates the volume of a single log (``v_a``) using Newton's method.

# Arguments
- `l::Length`: Log length.
- `d1::Length`: Diameter at the large end of the log (base).
- `d12::Length`: Diameter at the exact midpoint of the log (``d_{1/2}``).
- `d2::Length`: Diameter at the small end of the log (top).

# Returns
- `Quantity`: The volume of the log in cubic feet `ft^3` when the diameters are given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
Newton's formula (based on Simpson's rule) weights the sectional areas of the two ends and of the middle:

```math
v_a = \\frac{a_1 + 4a_{1/2} + a_2}{6} l
```

Where:

* ``a_1`` = sectional area at the large end of the log.
* ``a_{1/2}`` = sectional area at the midpoint of the log length.
* ``a_2`` = sectional area at the small end of the log.
* ``l`` = log length.

# Examples

```julia-repl
julia> newton(1.2u"m", 27.7u"cm", 24.8u"cm", 22.3u"cm")
0.05850807910266023 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.3.
"""
function newton(l::Length, d1::Length, d12::Length, d2::Length)
  l <= zero(l) && throw(DomainError(l, "Log length must be greater than zero."))
  a1 = sectionalarea(d1)
  a12 = sectionalarea(d12)
  a2 = sectionalarea(d2)
  v = ((a1 + 4 * a12 + a2) / 6) * l
  inreferencevolume(v, l)
end

"""
    artificialformfactor(v::Volume, H::Length, D::Length)

Calculates the artificial form factor (``f``), the ratio of the volume of the tree to the volume of a cylinder with the diameter at breast height and the total height of the tree.

# Arguments
- `v::Volume`: The volume of the tree. Must be positive.
- `H::Length`: The total height of the tree.
- `D::Length`: The diameter at breast height.

# Returns
- `Float64`: The dimensionless artificial form factor.

# Mathematical basis

```math
f = \\frac{v}{v_{cil}}, \\qquad v_{cil} = \\frac{\\pi D^2}{4} H
```

# Examples

```julia-repl
julia> artificialformfactor(0.325118u"m^3", 15.9u"m", 22.3u"cm")
0.5235332664111264
```
"""
function artificialformfactor(v::Volume, H::Length, D::Length)
  v <= zero(v) && throw(DomainError(v, "Volume must be positive."))
  NoUnits(v / cylindervolume(H, D))
end

"""
    barkfactor(d::AbstractVector{<:Length}, E::AbstractVector{<:Length})

Calculates the bark factor (``k_b``), the proportion of the diameter that is wood, used to estimate the volume without bark.

# Arguments
- `d::AbstractVector{<:Length}`: Diameters with bark. Must be non-negative (a zero is valid, for example the tip of the tree) and their sum must be greater than zero.
- `E::AbstractVector{<:Length}`: Bark thicknesses, one side of the stem, at the same measurements, so that the diameter without bark is ``d_s = d - 2E``. Must be non-negative and have the same length as `d`. The units may be different from those of `d`.

# Returns
- `Float64`: The dimensionless bark factor.

# Mathematical basis

```math
k_b = 1 - \\frac{2 \\sum E}{\\sum d}
```

# Examples

```julia-repl
julia> d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm";

julia> E = [1.8, 1.7, 1.55, 1.2, 1.0, 0.7, 0.6, 0.4, 0.1] .* u"cm";

julia> barkfactor(d, E)
0.8684593023255813
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
function barkfactor(d::AbstractVector{<:Length}, E::AbstractVector{<:Length})
  checklengths(:d => d, :E => E)
  any(x -> x < zero(x), d) && throw(DomainError("Diameters must be non-negative."))
  any(x -> x < zero(x), E) && throw(DomainError("Bark thickness must be non-negative."))
  sumd = sum(d)
  sumd > zero(sumd) || throw(DomainError("The sum of the diameters must be greater than zero."))
  1 - 2 * NoUnits(sum(E) / sumd)
end

"""
    barkpercentage(v::Volume, vs::Volume)

Calculates the percentage of bark (``p_b``) of the volume of a tree or a log: the share of the volume with bark that is bark.

# Arguments
- `v::Volume`: Volume with bark. Must be positive.
- `vs::Volume`: Volume without bark. Must be non-negative and not larger than `v`.

# Returns
- `Float64`: The percentage of bark, between 0 and 100.

# Mathematical basis

```math
p_b = \\frac{v - v_s}{v} \\times 100
```

# Examples

```julia-repl
julia> barkpercentage(0.319069u"m^3", 0.240002u"m^3")
24.780533364256634
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
function barkpercentage(v::Volume, vs::Volume)
  v > zero(v) || throw(DomainError(v, "The volume with bark must be positive."))
  (zero(vs) <= vs <= v) || throw(DomainError(vs, "The volume without bark must be between zero and the volume with bark."))
  100 * NoUnits((v - vs) / v)
end

"""
    cubage(H::Length, D::Length, h::AbstractVector{<:Length}, d::AbstractVector{<:Length})
    cubage(H::Length, D::Length, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length})

Calculates the rigorous volume (cubage) of a felled tree from the diameters measured along the bole at absolute heights: the stump, the measured sections and the tip, and the artificial form factor. With the bark thickness `E`, the same volumes without bark, the volume of the bark, the bark factor and the percentage of bark.

The sections between the measurements are cubed by Smalian's method ([`smalian`](@ref)). The stump is the cylinder from the ground to the first measurement ([`cylindervolume`](@ref)) and the tip is the cone from the last measurement to the total height ([`conevolume`](@ref)). `D` and `H` are the annotated values: the height of the diameter at breast height is a convention that varies by country, so `D` is never read from the profile.

For logs measured at relative positions (equal sections), only the volume of the log exists: see [`smalian`](@ref) and [`huber`](@ref) with the length of the log.

# Arguments
- `H::Length`: Total height of the tree. Not lower than the last height of `h`.
- `D::Length`: Diameter at breast height, with bark. Must be positive.
- `h::AbstractVector{<:Length}`: Heights of the measurements from the ground, in increasing order. The first one is the height of the stump.
- `d::AbstractVector{<:Length}`: Diameters with bark at the heights `h`.
- `E::AbstractVector{<:Length}`: Bark thicknesses at the heights `h`, one side of the stem, so that the diameter without bark is ``d_s = d - 2E``.

`H` and `D` may also be vectors with a value per row, as in a table where they are repeated in every row of the tree: they must be the same in every row. For many trees in the same vectors, see the method with `id`.

# Returns
- `DataFrame`: A row with the volumes in `ft^3` when the diameters are imperial and in `m^3` otherwise. First the columns with bark:
  - `v`: total volume, ``v = v_t + v_m + v_p``.
  - `vt`: volume of the stump.
  - `vm`: commercial volume, the measured sections.
  - `vp`: volume of the tip.
  - `H`, `D`: total height and diameter at breast height, as annotated.
  - `f`: artificial form factor ([`artificialformfactor`](@ref)).

  Then, with `E`, the same volumes without bark (the suffix `s` of Silva et al., 2022) and the bark:
  - `vs`, `vts`, `vms`, `vps`: total volume, stump, commercial volume and tip without bark.
  - `vb`: volume of the bark, `v - vs`.
  - `kb`: bark factor ([`barkfactor`](@ref)).
  - `pb`: percentage of bark ([`barkpercentage`](@ref)).

# Mathematical basis

```math
v = v_t + v_m + v_p \\qquad
v_t = a_1 h_1 \\qquad
v_m = \\sum_{j=2}^{n} \\frac{a_{j-1} + a_j}{2} (h_j - h_{j-1}) \\qquad
v_p = \\frac{a_n (H - h_n)}{3}
```

Without bark, the same with ``d_s = d - 2E``, and ``v_b = v - v_s``.

# Examples

```julia-repl
julia> h = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3] .* u"m";

julia> d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm";

julia> cubage(15.9u"m", 22.3u"cm", h, d)
1×7 DataFrame
 Row │ v             vt              vm            vp              H          D          f
     │ Quantity…     Quantity…       Quantity…     Quantity…       Quantity…  Quantity…  Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 0.325118 m^3  0.00602628 m^3  0.319069 m^3  2.26195e-5 m^3     15.9 m    22.3 cm  0.523534

julia> E = [1.8, 1.7, 1.55, 1.2, 1.0, 0.7, 0.6, 0.4, 0.1] .* u"cm";

julia> cubage(15.9u"m", 22.3u"cm", h, d, E)
1×14 DataFrame
 Row │ v             vt              vm            vp              H          D          f         vs           vts             vms           vps            vb             kb        pb
     │ Quantity…     Quantity…       Quantity…     Quantity…       Quantity…  Quantity…  Float64   Quantity…    Quantity…       Quantity…     Quantity…      Quantity…      Float64   Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 0.325118 m^3  0.00602628 m^3  0.319069 m^3  2.26195e-5 m^3     15.9 m    22.3 cm  0.523534  0.24458 m^3  0.00456167 m^3  0.240002 m^3  1.5708e-5 m^3  0.0805388 m^3  0.868459  24.7722
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
function cubage(H::Length, D::Length, h::AbstractVector{<:Length}, d::AbstractVector{<:Length})
  D > zero(D) || throw(DomainError(D, "The diameter at breast height must be positive."))
  H >= h[end] || throw(DomainError(H, "The total height must not be lower than the last measured height."))
  vm = smalian(h, d)
  vt = cylindervolume(h[1], d[1])
  vp = conevolume(H - h[end], d[end])
  v = vt + vm + vp
  DataFrame(v=v, vt=vt, vm=vm, vp=vp, H=H, D=D, f=artificialformfactor(v, H, D))
end

function cubage(H::Length, D::Length, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length})
  checklengths(:h => h, :d => d, :E => E)
  # diameters without bark, ds = d - 2E
  ds = d .- 2 .* E
  any(x -> x < zero(x), ds) && throw(DomainError("Twice the bark thickness exceeds the diameter at one or more points."))
  cb = cubage(H, D, h, d)
  # the same partition (stump, sections, tip) with the diameters without bark
  cs = cubage(H, D, h, ds)
  # after the columns with bark: the same volumes without bark, then the bark itself
  insertcols!(cb, :vs => cs.v, :vts => cs.vt, :vms => cs.vm, :vps => cs.vp,
    :vb => cb.v - cs.v, :kb => barkfactor(d, E), :pb => barkpercentage.(cb.v, cs.v))
end

# D and H repeated in the rows of the tree, as in the tables: they must be the same in every row
function _treevalue(x::AbstractVector, name::Symbol)
  allequal(x) || throw(ArgumentError("$name must be the same in every row of the tree (got $(join(unique(x), ", ")))."))
  first(x)
end

cubage(H::AbstractVector{<:Length}, D::AbstractVector{<:Length}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}) =
  cubage(_treevalue(H, :H), _treevalue(D, :D), h, d)

cubage(H::AbstractVector{<:Length}, D::AbstractVector{<:Length}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length}) =
  cubage(_treevalue(H, :H), _treevalue(D, :D), h, d, E)

"""
    cubage(id::AbstractVector, H::AbstractVector{<:Length}, D::AbstractVector{<:Length}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length})
    cubage(id::AbstractVector, H::AbstractVector{<:Length}, D::AbstractVector{<:Length}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length})

Calculates the rigorous volume of many felled trees stacked in the same vectors, as in a table with a row per measurement, told apart by `id`: [`cubage`](@ref) applied to each tree, with or without the bark thickness `E`.

# Arguments
- `id::AbstractVector`: The tree of each row. The rows of a tree are its measurements, in increasing order of height.
- `H`, `D`: Total height and diameter at breast height, repeated in every row of the tree (they must be the same in all of them).
- `h`, `d`, `E`: Heights, diameters with bark and bark thicknesses of the measurements, as in [`cubage`](@ref).

All the vectors must have the same length.

# Returns
- `DataFrame`: A row per tree, in the order in which the trees first appear, with the tree `id` as the first column and then the columns of [`cubage`](@ref).

# Examples

```julia-repl
julia> trees = vcat(
           DataFrame(tree="A", h=[0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3] .* u"m",
               d=[27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm", D=22.3u"cm", H=15.9u"m"),
           DataFrame(tree="B", h=[0.35, 0.95, 1.30, 2.50, 3.70, 4.90, 6.10, 7.30, 8.50, 9.70, 10.90, 12.10] .* u"m",
               d=[19.6, 15.9, 14.3, 12.8, 12.6, 11.7, 10.5, 9.2, 7.2, 5.0, 2.9, 1.1] .* u"cm", D=14.3u"cm", H=12.53u"m"));

julia> cubage(trees.tree, trees.H, trees.D, trees.h, trees.d)
2×8 DataFrame
 Row │ id      v             vt              vm            vp              H          D          f
     │ String  Quantity…     Quantity…       Quantity…     Quantity…       Quantity…  Quantity…  Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ A       0.325118 m^3  0.00602628 m^3  0.319069 m^3  2.26195e-5 m^3     15.9 m    22.3 cm  0.523534
   2 │ B       0.111269 m^3   0.0105601 m^3  0.100695 m^3  1.36214e-5 m^3    12.53 m    14.3 cm  0.55292
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
Floriano, E. P. (2025). *Dendrometria*, 2nd edition, Table 2, p. 84.
"""
function cubage(id::AbstractVector, H::AbstractVector{<:Length}, D::AbstractVector{<:Length}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length})
  checklengths(:id => id, :H => H, :D => D, :h => h, :d => d)
  trees = groupby(DataFrame(; id, H, D, h, d), :id; sort=false)
  combine(t -> cubage(t.H, t.D, t.h, t.d), trees)
end

function cubage(id::AbstractVector, H::AbstractVector{<:Length}, D::AbstractVector{<:Length}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length})
  checklengths(:id => id, :H => H, :D => D, :h => h, :d => d, :E => E)
  trees = groupby(DataFrame(; id, H, D, h, d, E), :id; sort=false)
  combine(t -> cubage(t.H, t.D, t.h, t.d, t.E), trees)
end
