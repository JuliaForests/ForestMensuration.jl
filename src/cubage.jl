"""
    CubingMethod

Abstract type of the methods of rigorous cubage. They differ in where the diameters of each section of the bole are measured: [`Smalian`](@ref), [`Huber`](@ref) and [`Newton`](@ref). The method is the first argument of [`cubage`](@ref).
"""
abstract type CubingMethod end

"""
    Smalian <: CubingMethod

Smalian's method: the diameters are measured at the ends of each section, and the volume of a section is its length times the mean of the cross-sectional areas of its two ends ([`smalian`](@ref)). Every measurement is the end of one section and the beginning of the next.
"""
abstract type Smalian <: CubingMethod end

"""
    Huber <: CubingMethod

Huber's method: the diameter is measured at the middle of each section, and the volume of a section is its length times the cross-sectional area at its middle ([`huber`](@ref)). The measurements alternate between the limit of a section and its middle, starting and ending at a limit (limit, middle, limit, middle, ..., limit). The diameters at the limits are not used, except the first one (top of the stump) and the last one (base of the tip). With equal sections, measured at the middles, it is the volume of the methodology of Hohenadl (see [`cubage`](@ref) with the length of the log).
"""
abstract type Huber <: CubingMethod end

"""
    Newton <: CubingMethod

Newton's method: the diameter is measured at both ends and at the middle of each section, and the volume of a section is its length times the weighted mean ``(a_1 + 4 a_m + a_2) / 6`` of the cross-sectional areas ([`newton`](@ref)). The measurements alternate between the limit of a section and its middle, starting and ending at a limit, as in Huber's method, but here the diameters at the limits are used too.
"""
abstract type Newton <: CubingMethod end

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
The method assumes the log resembles a frustum of a paraboloid. The volume is calculated
by averaging the cross-sectional areas of the two ends and multiplying by the length:

```math
v_a = \\frac{a_1 + a_2}{2} l

```

Where:

* ``a_1`` = cross-sectional area at the large end of the log.
* ``a_2`` = cross-sectional area at the small end of the log.
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
  a1 = basalarea(d1)
  a2 = basalarea(d2)
  v = ((a1 + a2) / 2) * l
  inreferencevolume(v, d1)
end

"""
    smalian(h::AbstractVector{<:Length}, d::AbstractVector{<:Length})

Calculates the total bole volume (``v``) from a continuous profile of cumulative heights.

# Arguments

* `h::AbstractVector{<:Length}`: Vector of cumulative heights from the base of the tree.
* `d::AbstractVector{<:Length}`: Vector of diameters corresponding to each height.

# Returns

* `Quantity`: The total volume of the bole in cubic feet `ft^3` when the diameters are
  given in imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis

The total volume is the sum of the volumes of all individual sections, where each section is
calculated using Smalian's method. The length of each section is the difference between
consecutive cumulative heights:

```math
v = \\sum_{j=2}^{n} \\frac{a_{j-1} + a_j}{2} (h_j - h_{j-1})

```

Where:

* ``a_j`` = cross-sectional area at cumulative height ``h_j``.
* ``h_j`` = cumulative height at measurement position ``j``.
* ``n`` = total number of measurement points along the bole.

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
  length(h) == length(d) || throw(DimensionMismatch("Height and diameter vectors must have the same length."))
  sum(_sections(Smalian, h, d))
end

"""
    smalian(l::Length, d::AbstractVector{<:Length})

Calculates the volume of a log (``v``) using Smalian's method with the relative method: the log is divided into equal sections, and the diameters are measured at their ends. Only the length of the log and the diameters matter, not the heights of the measurements: it has no stump, no tip and no form factor.

# Arguments
- `l::Length`: Commercial length of the log, from the first to the last diameter.
- `d::AbstractVector{<:Length}`: Vector of diameters measured at equal intervals along the log, in order (including the base and the top), one more than the number of sections. A closing diameter of zero at the tip is accepted and contributes no area.

# Returns
- `Quantity`: The total volume in cubic feet `ft^3` when the diameters are given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis
When a bole is divided into sections of equal length, Smalian's formula can be mathematically factored to improve performance. The constant section length is multiplied by the sum of the intermediate cross-sectional areas and the average of the two end areas:

```math
v = \\frac{l}{n} \\left( \\frac{a_1 + a_{n+1}}{2} + \\sum_{j=2}^{n} a_j \\right)

```

Where:

* ``l`` = commercial length of the log.
* ``n`` = number of equal-length sections.
* ``a_j`` = cross-sectional area at measurement position ``j``.

# Examples


# Examples

```julia-repl
julia> d = [22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm";
julia> smalian(14.0u"m", d)
0.2594774890287588 m^3

```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.

"""
function smalian(l::Length, d::AbstractVector{<:Length})
  l <= zero(l) && throw(DomainError(l, "Total length must be greater than zero."))
  nsections = length(d) - 1
  nsections < 1 && throw(ArgumentError("Diameter vector must have at least two measurements."))
  lsec = l / nsections
  aends = (basalarea(d[begin]) + basalarea(d[end])) / 2
  amid = sum(basalarea, @view d[2:(end-1)])
  v = (aends + amid) * lsec
  inreferencevolume(v, d[begin])
end

"""
    huber(l::Length, d12::Length)

Calculates the volume of a single log (``v_a``) using Huber's method.

# Arguments

* `l::Length`: Log length.
* `d12::Length`: Diameter at the exact midpoint of the log (``d_{1/2}``).

# Returns

* `Quantity`: The volume of the log in cubic feet `ft^3` when the diameter is given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis

The method assumes the log resembles a paraboloid frustum. The volume is calculated
by taking the cross-sectional area at the log's midpoint and multiplying by its length:

```math
v_a = a_{1/2} l

```

Where:

* ``a_{1/2}`` = cross-sectional area at the midpoint of the log length.
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
  a12 = basalarea(d12)
  v = a12 * l
  inreferencevolume(v, d12)
end

"""
    newton(l::Length, d1::Length, d12::Length, d2::Length)

Calculates the volume of a single log (``v_a``) using Newton's method.

# Arguments

* `l::Length`: Log length.
* `d1::Length`: Diameter at the large end of the log (base).
* `d12::Length`: Diameter at the exact midpoint of the log (``d_{1/2}``).
* `d2::Length`: Diameter at the small end of the log (top).

# Returns

* `Quantity`: The volume of the log in cubic feet `ft^3` when the diameters are given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis

Newton's formula (based on Simpson's rule) is the most accurate of the standard
log scaling methods. It calculates volume by weighting the cross-sectional areas:

```math
v_a = \\frac{a_1 + 4a_{1/2} + a_2}{6} l

```

Where:

* ``a_1`` = cross-sectional area at the large end of the log.
* ``a_{1/2}`` = cross-sectional area at the midpoint of the log length.
* ``a_2`` = cross-sectional area at the small end of the log.
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
  a1 = basalarea(d1)
  a12 = basalarea(d12)
  a2 = basalarea(d2)
  v = ((a1 + 4 * a12 + a2) / 6) * l
  inreferencevolume(v, d1)
end

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
The volume of a cylinder is the product of its cross-sectional area and its height:

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
  v = basalarea(d) * h
  inreferencevolume(v, d)
end

"""
    conevolume(h::Length, d::Length)

Calculates the volume of a cone, used to estimate the volume of the tip of the tree (``v_p``).

# Arguments

* `h::Length`: The height of the cone (the tip length ``h_p``). Must be non-negative.
* `d::Length`: The diameter at the base of the cone. Must be non-negative; a bole whose last measured diameter is already zero yields a tip volume of zero.

# Returns

* `Quantity`: The volume of the cone in cubic feet `ft^3` when the diameter is given in
  imperial units, and in cubic meters `m^3` otherwise.

# Mathematical basis

The volume of a cone is exactly one-third the volume of a cylinder with the same base area and height:

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

"""
    artificialformfactor(v::Volume, H::Length, D::Length)

Calculates the artificial form factor (``f``), representing the ratio of total volume to a reference cylinder based on the diameter at breast height.

# Arguments
- `v::Volume`: The total rigorous volume of the tree.
- `H::Length`: The total height of the tree.
- `D::Length`: Diameter at breast height.

# Returns
- `Float64`: The dimensionless artificial form factor.

# Mathematical basis

```math
f = \\frac{v}{v_{cil}}, \\qquad v_{cil} = \\frac{\\pi D^2}{4} H

```
"""
function artificialformfactor(v::Volume, H::Length, D::Length)
  v <= zero(v) && throw(DomainError(v, "Volume must be positive."))
  vcil = cylindervolume(H, D)
  f = v / vcil
  ustrip(uconvert(NoUnits, f))
end

"""
    barkfactor(d::AbstractVector{<:Length}, E::AbstractVector{<:Length})

Calculates the bark factor (``k_b``), used to estimate the volume without bark.

The bark factor is calculated considering the ratio of twice the bark thickness
to total diameter. The function automatically handles and converts any combination of length units.

# Arguments

* `d::AbstractVector{<:Length}`: A vector of diameters at breast height. The diameters must be non-negative values (a zero is valid, e.g. the tip of the tree) and their sum must be greater than zero.
* `E::AbstractVector{<:Length}`: A vector of bark thicknesses (``E``, one side of the stem; the diameter without bark is ``d_s = d - 2E``). The bark thicknesses must be non-negative values.

# Returns

* `Float64`: The dimensionless bark factor, representing the proportion of the diameter without bark.

# Mathematical basis

The bark factor estimates the ratio of the diameter without bark to the diameter over bark across the sampled stand:

```math
k_b = 1 - \\frac{2 \\sum E}{\\sum d}

```

Where:

* ``E`` = bark thickness, so that ``d_s = d - 2E``.
* ``d`` = diameter over bark.

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
  any(x -> x < zero(x), d) && throw(DomainError("Diameters must be non-negative."))
  any(x -> x < zero(x), E) && throw(DomainError("Bark thickness must be non-negative."))
  sumd = sum(d)
  sume = sum(E)
  sumd > zero(sumd) || throw(DomainError("The sum of the diameters must be greater than zero."))
  ratio = uconvert(NoUnits, sume / sumd)
  1 - 2 * ratio
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
  vb = v - vs
  ratio = uconvert(NoUnits, vb / v)
  100 * ratio
end

# The relative method: a log of length `l` divided into equal sections, whose diameters are in order. By the method:
# Smalian, at the ends of the sections; Huber, at their middles (it is Hohenadl's method); Newton, limit, middle, limit, ...
_equalsections(::Type{<:Smalian}, l, d) = smalian(l, d)

function _equalsections(::Type{<:Huber}, l, d)
  isempty(d) && throw(ArgumentError("Diameter vector cannot be empty."))
  return sum(huber(l / length(d), x) for x in d)
end

function _equalsections(::Type{<:Newton}, l, d)
  _checklimitsandmiddles(Newton, d)
  nsections = (length(d) - 1) ÷ 2
  return sum(newton(l / nsections, d[j-1], d[j], d[j+1]) for j in 2:2:(length(d)-1))
end

# Many logs, a row of the matrix each: `l` has a length per log, `d` the diameters at the same positions
function _logs(method, l, d)
  size(d, 1) == length(l) || throw(DimensionMismatch("The table d must have a row per length in l."))
  return DataFrame(vm=[_equalsections(method, l[i], @view(d[i, :])) for i in eachindex(l)])
end

# Volume of every section of the bole, from the first measurement to the last, each one by the method
function _sections(::Type{<:Smalian}, h, d)
  return [smalian(h[j] - h[j-1], d[j-1], d[j]) for j in 2:length(h)]
end

function _sections(::Type{<:Huber}, h, d)
  _checklimitsandmiddles(Huber, h)
  return [huber(h[j+1] - h[j-1], d[j]) for j in 2:2:(length(h)-1)]
end

function _sections(::Type{<:Newton}, h, d)
  _checklimitsandmiddles(Newton, h)
  return [newton(h[j+1] - h[j-1], d[j-1], d[j], d[j+1]) for j in 2:2:(length(h)-1)]
end

# Huber's and Newton's methods read the measurements as limit, middle, limit, ..., limit
function _checklimitsandmiddles(method, h)
  n = length(h)
  (isodd(n) && n >= 3) ||
    throw(ArgumentError("The $(nameof(method)) method needs an odd number, at least 3, of measurements: the limit of a section, its middle, the next limit, and so on, ending at a limit."))
end

# Positions whose diameters enter the calculation (the others are only heights)
_diameternodes(::Type{<:CubingMethod}, n) = 1:n
_diameternodes(::Type{<:Huber}, n) = vcat(1, 2:2:(n-1), n)

# `value` is a single value, or one value per tree
_pick(value, i) = value isa AbstractVector ? value[i] : value

# The profile of a tree in plain floats, in the unit of the first element of each vector: heights,
# diameters with bark, bark thicknesses and diameters without bark (the last two are `nothing` without bark)
function _profile(h, d, E)
  length(h) == length(d) || throw(DimensionMismatch("Vectors h and d must have the same length."))
  E === nothing || length(E) == length(h) || throw(DimensionMismatch("Vectors h, d, and E must have the same length."))
  length(h) >= 2 || throw(ArgumentError("At least 2 measurements are required."))
  uh = unit(h[begin])
  ud = unit(d[begin])
  hwork = float.(uconvert.(uh, h))
  dwork = float.(uconvert.(ud, d))
  ework = E === nothing ? nothing : float.(uconvert.(ud, E))
  # the diameter without bark; a negative one means the bark data are inconsistent
  dswork = ework === nothing ? nothing : dwork .- 2 .* ework
  dswork === nothing || !any(x -> x < zero(x), dswork) || throw(DomainError("Twice the bark thickness exceeds the diameter at one or more points."))
  return hwork, dwork, ework, dswork
end

# The bark factor from the diameters that the method measures
function _barkfactor(method, d, E)
  nodes = _diameternodes(method, length(d))
  return barkfactor(d[nodes], E[nodes])
end

# The three parts of the volume of a tree of total height `H`: the stump (the cylinder of the first
# measured diameter, from the ground to the first height), the commercial part (the measured sections,
# since the profile runs up to the commercial height) and the tip (the cone above the last
# measurement, when it is below `H`). The same partition serves the diameters with and without bark.
function _partition(method, h, d, H)
  vt = cylindervolume(h[begin], d[begin])
  vm = sum(_sections(method, h, d))
  vp = H > h[end] ? conevolume(H - h[end], d[end]) : zero(vt)
  return vt, vm, vp
end

# Volume of the measured sections of one tree, and the bark factor if the bark is given
function _measured(method, h, d, E)
  hwork, dwork, ework, dswork = _profile(h, d, E)
  # the measured profile runs up to the commercial height, so its sections are the commercial volume
  vm = sum(_sections(method, hwork, dwork))
  ework === nothing && return DataFrame(vm=vm)
  vms = sum(_sections(method, hwork, dswork))
  return DataFrame(vm=vm, vms=vms, vb=vm - vms, kb=_barkfactor(method, dwork, ework), pb=barkpercentage(vm, vms))
end

# Rigorous cubage of the whole tree: stump, commercial part (the measured sections) and tip (the cone
# above the last measurement), with bark and, if `E` is given, also without bark. Nothing is interpolated.
function _treevolume(method, h, d, E, D, H)
  hwork, dwork, ework, dswork = _profile(h, d, E)
  uh = unit(h[begin])
  ud = unit(d[begin])
  Hval = float(uconvert(uh, H))
  Dval = float(uconvert(ud, D))
  Dval > zero(Dval) || throw(DomainError(D, "The diameter at breast height must be positive."))
  Hval >= hwork[end] || throw(DomainError(H, "The total height must not be lower than the last measured height."))

  # With Smalian's method, a last diameter of zero is the apex of the tree, not the end of a
  # measured section: it is dropped, so that the tip is the cone from the last real measurement
  # up to `H` (Smalian would overestimate that last section)
  if method <: Smalian && iszero(dwork[end])
    pop!(hwork)
    pop!(dwork)
    ework === nothing || (pop!(ework); pop!(dswork))
    length(hwork) >= 2 || throw(ArgumentError("At least 2 measurements are required, not counting a zero diameter at the apex."))
  end

  vt, vm, vp = _partition(method, hwork, dwork, Hval)
  hm = hwork[end]
  v = vt + vm + vp
  f = artificialformfactor(v, Hval, Dval)

  ework === nothing && return DataFrame(v=v, vt=vt, vm=vm, vp=vp, hm=hm, D=Dval, H=Hval, f=f)

  # The same partition with the diameters without bark
  vts, vms, vps = _partition(method, hwork, dswork, Hval)
  vs = vts + vms + vps
  kb = _barkfactor(method, dwork, ework)
  return DataFrame(v=v, vs=vs, vb=v - vs, kb=kb, vt=vt, vts=vts, vm=vm, vms=vms, vp=vp, vps=vps, hm=hm, D=Dval, H=Hval, f=f)
end

# Many trees stacked in the same vectors, told apart by `id`: `compute` cubes one tree from its rows
# (and from the row of the first measurement, to pick a value per tree)
function _stacked(compute, id, h, d, E, perrow)
  length(id) == length(h) == length(d) || throw(DimensionMismatch("Vectors id, h, and d must have the same length."))
  E === nothing || length(E) == length(id) || throw(DimensionMismatch("Vectors id, h, d, and E must have the same length."))
  for (name, value) in perrow
    value isa AbstractVector && length(value) != length(id) &&
      throw(DimensionMismatch("Vector keyword argument $name must have the same length as the main data vectors."))
  end
  results = DataFrame()
  for treeid in unique(id)
    idx = findall(x -> x == treeid, id)
    treetable = compute(@view(h[idx]), @view(d[idx]), E === nothing ? nothing : @view(E[idx]), idx[begin])
    insertcols!(treetable, 1, :id => treeid)
    append!(results, treetable)
  end
  return results
end

"""
    cubage(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}; id=nothing)

Calculates the commercial volume (``v_m``) of felled trees: the volume of the part that was actually measured, the sections between the measurements of the diameters along the bole. The measurement of a tree runs up to its commercial height, so the measured sections are the commercial volume. The `method` tells how the bole was sectioned and measured: [`Smalian`](@ref), [`Huber`](@ref) or [`Newton`](@ref), and each section is cubed by it ([`smalian`](@ref), [`huber`](@ref), [`newton`](@ref)).

The stump and the tip are not measured, they are modeled (a cylinder and a cone), and they need the total height of the tree: they are part of [`treevolume`](@ref), which extends this function with them and with the form factor. Nothing is interpolated here: the volume uses only the measured diameters.

# Absolute and relative lengths

The books classify the methods by the length of the sections: **absolute**, in Huber's, Smalian's and Newton's methods, with the positions annotated in meters (in practice at 0.10, 0.30 and 1.30 m and then every 1 or 2 m), and **relative**, with equal sections whose length is the commercial length of the log divided by their number. This function is the absolute one, with the heights annotated. The relative one needs no heights, only the length `l` of the log and the diameters, in order, so it is `cubage(method, l, d)` with the length of the log instead of the heights, with no stump, tip or form factor. The measurement is the methodology of Hohenadl (equal sections), and the calculation is the formula of the method: Smalian's for the diameters at the ends, Huber's for the diameters at the middles, Newton's for both (see the methods with the length of the log).

* `cubage(method, h, d)`: absolute heights `h` of the measurements of one tree. With `id`, many trees stacked in the same vectors.
* `cubage(method, h, d, E)`: the same, with the bark thickness `E`, for the volumes with and without bark.

# Arguments
- `method`: The cubing method, [`Smalian`](@ref), [`Huber`](@ref) or [`Newton`](@ref). It decides how the measurements are read: with Smalian's method every measurement is the end of a section; with Huber's and Newton's the measurements alternate between the limit of a section and its middle, from a limit to a limit (see each type).
- `h::AbstractVector{<:Length}`: Cumulative heights of the measurements from the ground, in increasing order.
- `d::AbstractVector{<:Length}`: Diameters with bark at each height of `h`.
- `id`: Vector of tree identifiers, with the same length as `h` and `d`, to cube many trees at once. The measurements of a tree are the rows with its identifier, in order.

`h` and `d` must carry units; any length unit may be used (imperial included), even mixed.

# Returns
- `DataFrame`: A row per tree (with the tree `id` as the first column, if given), with the commercial volume `vm`, in `ft^3` when the diameters are imperial and in `m^3` otherwise.

# Mathematical basis

The volume is the sum of the volumes of the ``s`` sections, each one by the method:

```math
v_m = \\sum_{k=1}^{s} v_k
```

with ``v_k = \\frac{a_{k} + a_{k+1}}{2} l_k`` in Smalian's method, ``v_k = a_m l_k`` in Huber's and ``v_k = \\frac{a_k + 4 a_m + a_{k+1}}{6} l_k`` in Newton's, where ``a`` is the cross-sectional area at the ends or at the middle (``m``) of the section and ``l_k`` is its length.

# Examples

```julia-repl
julia> h = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3] .* u"m";
julia> d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm";

# Smalian: every measurement is the end of a section
julia> cubage(Smalian, h, d)
1×1 DataFrame
 Row │ vm
     │ Quantity…
─────┼──────────────
   1 │ 0.319069 m^3

# Huber and Newton read the measurements as limit, middle, limit, middle, limit
julia> hn = [0.1, 0.7, 1.3, 2.3, 3.3, 4.3, 5.3, 6.3, 7.3, 8.3, 9.3, 10.3, 11.3, 12.3, 13.3, 14.3, 15.3] .* u"m";
julia> dn = [27.7, 24.8, 22.3, 20.7, 20.3, 19.4, 18.8, 18.1, 17.5, 17.0, 14.3, 11.5, 9.5, 7.6, 6.0, 4.5, 1.2] .* u"cm";
julia> cubage(Huber, hn, dn)
1×1 DataFrame
 Row │ vm
     │ Quantity…
─────┼──────────────
   1 │ 0.314276 m^3

julia> cubage(Newton, hn, dn)
1×1 DataFrame
 Row │ vm
     │ Quantity…
─────┼──────────────
   1 │ 0.315874 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Tables 5.1 to 5.3.

"""
cubage(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}; id=nothing) =
  id === nothing ? _measured(method, h, d, nothing) : _stacked((hi, di, Ei, i) -> _measured(method, hi, di, Ei), id, h, d, nothing, ())

"""
    cubage(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length}; id=nothing)

Calculates the commercial volume of felled trees, with bark and without bark, from the diameters measured along the bole and the bark thickness at each measurement. It is [`cubage`](@ref) calculated twice, once with the diameters with bark and once with the diameters without bark.

# Arguments
- `method`: The cubing method, [`Smalian`](@ref), [`Huber`](@ref) or [`Newton`](@ref).
- `h::AbstractVector{<:Length}`: Cumulative heights of the measurements from the ground, in increasing order.
- `d::AbstractVector{<:Length}`: Diameters with bark at each height of `h`.
- `E::AbstractVector{<:Length}`: Bark thicknesses at each height of `h` (``E``, one side of the stem; the diameter without bark is ``d_s = d - 2E``). Must be non-negative.
- `id`: Vector of tree identifiers, as in the method without bark.

A `DomainError` is raised if twice the bark thickness exceeds the diameter at any measurement.

# Returns
- `DataFrame`: A row per tree (with the tree `id` as the first column, if given). Following Silva et al. (2022), the suffix `s` marks the quantities without bark.
  - `vm`, `vms`: commercial volume with bark and without bark.
  - `vb`: volume of the bark (`vm - vms`).
  - `kb`: bark factor.
  - `pb`: percentage of bark, the share of the volume with bark that is bark ([`barkpercentage`](@ref)).

# Mathematical basis

```math
d_s = d - 2E \\qquad
v_b = v_m - v_{m,s} \\qquad
k_b = 1 - \\frac{2 \\sum E}{\\sum d} \\qquad
p_b = \\frac{v_b}{v_m} \\times 100
```

The bark factor is the proportion of the diameter that is wood, over the measured diameters. In Huber's method only the diameters at the middles, at the first limit and at the last limit are measured, and only those enter the bark factor.

# Examples

```julia-repl
julia> h = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3] .* u"m";
julia> d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm";
julia> E = [1.8, 1.7, 1.55, 1.2, 1.0, 0.7, 0.6, 0.4, 0.1] .* u"cm";
julia> cubage(Smalian, h, d, E)
1×5 DataFrame
 Row │ vm            vms           vb             kb        pb
     │ Quantity…     Quantity…     Quantity…      Float64   Float64
─────┼──────────────────────────────────────────────────────────────
   1 │ 0.319069 m^3  0.240002 m^3  0.0790673 m^3  0.868459  24.7806
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
cubage(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length}; id=nothing) =
  id === nothing ? _measured(method, h, d, E) : _stacked((hi, di, Ei, i) -> _measured(method, hi, di, Ei), id, h, d, E, ())

"""
    cubage(method::Type{<:CubingMethod}, l::Length, d::AbstractVector{<:Length})
    cubage(method::Type{<:CubingMethod}, l::AbstractVector{<:Length}, d::AbstractDataFrame)
    cubage(method::Type{<:CubingMethod}, l::AbstractVector{<:Length}, d::AbstractMatrix{<:Length})

Calculates the commercial volume of logs by the relative method: the log is divided into equal sections and the diameters are measured at the same relative positions of every log (0, 10, ..., 100 % of its length, for example), so only the length `l` of the log and the diameters, in order, are needed. It is told apart from the absolute method by the type of the second argument: a length (`l::Length`, or the lengths of the logs) instead of the heights of the measurements. There is no total height, stump, tip or form factor.

# Measurement and calculation

The relative method is a way of **measuring** (the methodology): the log is divided into equal sections, and the diameters are taken at the same relative positions of every log. When the diameters are taken at the middles of 5 or 10 equal sections it is the methodology of Hohenadl (Machado & Figueiredo Filho, 2003), whose volume is the length of a section times the sum of the areas at their middles. That volume is calculated by the **formula** that matches where the diameters were measured, and the `method` is that formula:

* [`Smalian`](@ref): the diameters at the ends of the sections (0, 10, ..., 100 % of the length, in the field sheets), calculated by Smalian's formula, the mean of the areas of the two ends ([`smalian`](@ref)`(l, d)`).
* [`Huber`](@ref): the diameters at the middles of the sections (10, 30, 50, 70, 90 %, for 5 sections), calculated by Huber's formula, the area at the middle. With equal sections this is the volume of Hohenadl's methodology, so there is no `Hohenadl` method: it is the measurement, not another formula.
* [`Newton`](@ref): the diameters at the ends and at the middles of the sections (limit, middle, limit, ..., limit), calculated by Newton's formula.

# Arguments
- `method`: The cubing method, [`Smalian`](@ref), [`Huber`](@ref) or [`Newton`](@ref).
- `l`: The length of the log, or the lengths of many logs, one per row of `d`.
- `d`: The diameters with bark, in order: a vector for one log, or for many logs the columns of the table (a `DataFrame` such as `sheet[:, 3:end]`) or a matrix, a row per log and a column per position. The columns carry units: with the units in the headers, `name (unit)`, `parseunits` attaches them to the whole sheet.

# Returns
- `DataFrame`: A row per log, in the same order as the rows of `d`, with the commercial volume `vm`. There is no identifier argument: the logs can be of the same tree or of different trees, so the identifier columns stay in the table and are placed beside the result: `hcat(select(sheet, :tree, :log), cubage(Smalian, sheet.l, sheet[:, 4:end]))`.

# Examples

```julia-repl
# A field sheet, as it is read from the file: the units are in the headers
julia> sheet = DataFrame("log" => ["1A", "1B", "1C"], "l (m)" => [7.10, 7.67, 7.62],
         "d0 (cm)" => [81.5, 67.2, 61.1], "d1 (cm)" => [74.5, 63.7, 60.1], "d2 (cm)" => [72.9, 63.5, 60.2],
         "d3 (cm)" => [69.5, 62.7, 59.8], "d4 (cm)" => [67.2, 62.0, 58.6], "d5 (cm)" => [66.2, 61.3, 58.6],
         "d6 (cm)" => [65.8, 61.4, 58.3], "d7 (cm)" => [64.9, 61.7, 59.4], "d8 (cm)" => [64.9, 61.7, 58.7],
         "d9 (cm)" => [64.8, 59.5, 57.7], "d10 (cm)" => [65.3, 59.4, 57.7]);
julia> sheet = parseunits(sheet);

# the lengths and the 11 diameters at 0, 10, ..., 100 % of each log, with the log beside the volumes
julia> hcat(select(sheet, :log), cubage(Smalian, sheet.l, sheet[:, 3:end]))
3×2 DataFrame
 Row │ log     vm
     │ String  Quantity…
─────┼─────────────────────
   1 │ 1A      2.62082 m^3
   2 │ 1B       2.3234 m^3
   3 │ 1C      2.08948 m^3

# one log, as vectors
julia> cubage(Smalian, sheet.l[1], Vector(sheet[1, 3:end]))
1×1 DataFrame
 Row │ vm
     │ Quantity…
─────┼─────────────
   1 │ 2.62082 m^3

# the diameters at 10, 30, 50, 70 and 90 % are the middles of 5 equal sections: Hohenadl's method
julia> hcat(select(sheet, :log), cubage(Huber, sheet.l, sheet[:, [4, 6, 8, 10, 12]]))
3×2 DataFrame
 Row │ log     vm
     │ String  Quantity…
─────┼─────────────────────
   1 │ 1A      2.58451 m^3
   2 │ 1B      2.30042 m^3
   3 │ 1C      2.09222 m^3
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.4.
"""
cubage(method::Type{<:CubingMethod}, l::Length, d::AbstractVector{<:Length}) = DataFrame(vm=_equalsections(method, l, d))

cubage(method::Type{<:CubingMethod}, l::AbstractVector{<:Length}, d::AbstractMatrix{<:Length}) = _logs(method, l, d)

cubage(method::Type{<:CubingMethod}, l::AbstractVector{<:Length}, d::AbstractDataFrame) = _logs(method, l, Matrix(d))

"""
    treevolume(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}; D, H, id=nothing)

Calculates the rigorous volume (cubage) of the whole of felled trees: it extends [`cubage`](@ref), which gives the commercial volume, the one that was measured, with the stump, the tip and the artificial form factor. The bole is partitioned into stump, commercial and tip volumes. It needs the diameter at breast height `D` and the total height `H` of each tree.

The commercial volume is the measured sections: the diameters are measured up to the commercial height, as in the books, so there is no minimum diameter to give. The stump and the tip are not measured, they are modeled. `D` and `H` are always the annotated values, never read from the profile or interpolated on it: the height at which the diameter at breast height is measured is not the same in every country (1.30 m, 1.37 m in the USA), and a measurement is not assumed to sit at a standard height. The stump is a cylinder ([`cylindervolume`](@ref)) and, when the last measurement is below the total height, the tip is a cone ([`conevolume`](@ref)). Nothing is interpolated.

The measurements are absolute heights, as in [`cubage`](@ref) (with `id` for many trees stacked in the same vectors), and also exist with the bark thickness `E` after `d`. The relative method (equal sections of a log) has no total height and no form factor: use [`cubage`](@ref)`(method, l, d)` with the length of the log.

# Arguments
- `method`: The cubing method, [`Smalian`](@ref), [`Huber`](@ref) or [`Newton`](@ref), as in [`cubage`](@ref).
- `h::AbstractVector{<:Length}`: Cumulative heights of the measurements from the ground, in increasing order. The first one is the height of the stump.
- `d::AbstractVector{<:Length}`: Diameters with bark at each height of `h`. With Smalian's method, a last diameter of zero is the apex of the tree: it is dropped and the tip is the cone up to `H`.
- `D::Length`: Diameter at breast height, as annotated. Required.
- `H::Length`: Total height of the tree (or length of the log), as annotated. Required, and not lower than the last height of `h`. A last measurement below `H` leaves a tip, which is cubed as a cone with the last measured diameter as its base.
- `id`: Vector of tree identifiers, with the same length as `h` and `d`, to cube many trees at once. `D` and `H` can then be a vector with a value per row (the value of the first row of each tree is used, so a column of the data can be passed directly).

All lengths must carry units; any length unit may be used (imperial included), even mixed.

# Returns
- `DataFrame`: A row per tree (with the tree `id` as the first column, if given). Volumes are in `ft^3` when the diameters are imperial and in `m^3` otherwise.
  - `v`: total volume, ``v = v_t + v_m + v_p``.
  - `vt`: volume of the stump.
  - `vm`: commercial volume, the measured sections (the same as [`cubage`](@ref)).
  - `vp`: volume of the tip, the cone above the last measurement (zero when it is at `H`).
  - `hm`: commercial height, the height of the last measurement.
  - `D`: diameter at breast height, as annotated.
  - `H`: total height, as annotated.
  - `f`: artificial form factor.

# Partition of the bole

The total volume is the stump, the sections and the tip, the usual formula of rigorous cubage:

```math
v = v_t + v_m + v_p \\qquad
v_t = a_1 h_1 \\qquad
v_m = \\sum_{k=1}^{s} v_k \\qquad
v_p = \\frac{a_n (H - h_n)}{3}
```

where ``a_1 h_1`` is the cylinder of the stump, ``v_k`` is the volume of section ``k`` by the method (``k = 1, \\dots, s``), and ``a_n`` is the cross-sectional area at the last measurement ``h_n`` (the cone exists only when ``h_n < H``). The tip is the part above the commercial height. The artificial form factor is ``f = v / (\\frac{\\pi D^2}{4} H)`` ([`artificialformfactor`](@ref)).

# Examples

```julia-repl
# The tree of Table 2 of Floriano (2025): the heights (m) and the diameters with bark (cm) of the limits of the
# sections, the stump measured first, the diameter at breast height and the total height
julia> h = [0.35, 0.95, 1.30, 2.50, 3.70, 4.90, 6.10, 7.30, 8.50, 9.70, 10.90, 12.10] .* u"m";
julia> d = [19.6, 15.9, 14.3, 12.8, 12.6, 11.7, 10.5, 9.2, 7.2, 5.0, 2.9, 1.1] .* u"cm";

# Smalian: the stump is a cylinder, the sections are measured and the tip is the cone above 12.10 m, up to H
julia> treevolume(Smalian, h, d; D=14.3u"cm", H=12.53u"m")
1×8 DataFrame
 Row │ v             vt             vm            vp              hm         D          H          f
     │ Quantity…     Quantity…      Quantity…     Quantity…       Quantity…  Quantity…  Quantity…  Float64
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 0.111269 m^3  0.0105601 m^3  0.100695 m^3  1.36214e-5 m^3     12.1 m    14.3 cm    12.53 m  0.55292

# Huber and Newton: the middle of each section is measured too (limit, middle, limit, ...)
julia> dm = [16.5, 14.8, 13.4, 12.9, 11.9, 11.2, 9.6, 8.2, 5.9, 3.8, 1.8] .* u"cm";
julia> hm = (h[1:end-1] .+ h[2:end]) ./ 2;
julia> hn = [h[1]; vec([hm'; h[2:end]'])];
julia> dn = [d[1]; vec([dm'; d[2:end]'])];
julia> treevolume(Huber, hn, dn; D=14.3u"cm", H=12.53u"m")
1×8 DataFrame
 Row │ v            vt             vm             vp              hm         D          H          f
     │ Quantity…    Quantity…      Quantity…      Quantity…       Quantity…  Quantity…  Quantity…  Float64
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 0.10717 m^3  0.0105601 m^3  0.0965966 m^3  1.36214e-5 m^3     12.1 m    14.3 cm    12.53 m  0.532552

julia> treevolume(Newton, hn, dn; D=14.3u"cm", H=12.53u"m")
1×8 DataFrame
 Row │ v             vt             vm             vp              hm         D          H          f
     │ Quantity…     Quantity…      Quantity…      Quantity…       Quantity…  Quantity…  Quantity…  Float64
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 0.108537 m^3  0.0105601 m^3  0.0979629 m^3  1.36214e-5 m^3     12.1 m    14.3 cm    12.53 m  0.539341
```

The totals `v` are the ones of the book: 0.11127 (Smalian), 0.10717 (Huber) and 0.10854 m³ (Newton).

# References
Floriano, E. P. (2025). *Dendrometria*, 2nd edition, Table 2, p. 84.

"""
treevolume(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}; D, H, id=nothing) =
  id === nothing ? _treevolume(method, h, d, nothing, D, H) :
  _stacked((hi, di, Ei, i) -> _treevolume(method, hi, di, Ei, _pick(D, i), _pick(H, i)), id, h, d, nothing, (:D => D, :H => H))

"""
    treevolume(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length}; D, H, id=nothing)

Calculates the rigorous volume (cubage) of the whole of felled trees, with bark and without bark, from the diameters measured along the bole and the bark thickness at each measurement. The partition into stump, commercial and tip volumes and the sections are those of the method without bark ([`treevolume`](@ref)), calculated twice: once with the diameters with bark and once with the diameters without bark.

# Arguments
- `method`, `h`, `d`, `D`, `H`, `id`: As in the method without bark. `D` is the diameter at breast height with bark.
- `E::AbstractVector{<:Length}`: Bark thicknesses at each height of `h` (``E``, one side of the stem; the diameter without bark is ``d_s = d - 2E``). Must be non-negative.

A `DomainError` is raised if twice the bark thickness exceeds the diameter at any measurement.

# Returns
- `DataFrame`: A row per tree (with the tree `id` as the first column, if given). Following Silva et al. (2022), the suffix `s` marks the quantities without bark.
  - `v`, `vs`: total volume with bark and without bark.
  - `vb`: volume of the bark (`v - vs`).
  - `kb`: bark factor.
  - `vt`, `vts`: volume of the stump with bark and without bark.
  - `vm`, `vms`: commercial volume with bark and without bark.
  - `vp`, `vps`: volume of the tip, the cone above the last measurement, with bark and without bark.
  - `hm`: commercial height, the height of the last measurement.
  - `D`: diameter at breast height with bark, as annotated.
  - `H`: total height, as annotated.
  - `f`: artificial form factor (with bark).

# Mathematical basis

```math
d_s = d - 2E \\qquad
v = v_t + v_m + v_p \\qquad
v_s = v_{t,s} + v_{m,s} + v_{p,s} \\qquad
v_b = v - v_s \\qquad
k_b = 1 - \\frac{2 \\sum E}{\\sum d}
```

# Examples

```julia-repl
julia> using DataFrames

julia> h = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3] .* u"m";
julia> d = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2] .* u"cm";
julia> E = [1.8, 1.7, 1.55, 1.2, 1.0, 0.7, 0.6, 0.4, 0.1] .* u"cm";
julia> cb = treevolume(Smalian, h, d, E; D=22.3u"cm", H=15.9u"m");

# Volume with bark, without bark, of the bark itself, and the bark factor
julia> select(cb, :v, :vs, :vb, :kb, :D, :H)
1×6 DataFrame
 Row │ v             vs           vb             kb        D          H
     │ Quantity…     Quantity…    Quantity…      Float64   Quantity…  Quantity…
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ 0.325118 m^3  0.24458 m^3  0.0805388 m^3  0.868459    22.3 cm     15.9 m

# Partition with bark
julia> select(cb, :vt, :vm, :vp, :hm)
1×4 DataFrame
 Row │ vt              vm            vp              hm
     │ Quantity…       Quantity…     Quantity…       Quantity…
─────┼─────────────────────────────────────────────────────────
   1 │ 0.00602628 m^3  0.319069 m^3  2.26195e-5 m^3     15.3 m
```

# References
Machado, S. A. & Figueiredo Filho, A. (2003). *Dendrometria*. Curitiba: Ed. dos Autores, Table 5.1, p. 233.
"""
treevolume(method::Type{<:CubingMethod}, h::AbstractVector{<:Length}, d::AbstractVector{<:Length}, E::AbstractVector{<:Length}; D, H, id=nothing) =
  id === nothing ? _treevolume(method, h, d, E, D, H) :
  _stacked((hi, di, Ei, i) -> _treevolume(method, hi, di, Ei, _pick(D, i), _pick(H, i)), id, h, d, E, (:D => D, :H => H))
