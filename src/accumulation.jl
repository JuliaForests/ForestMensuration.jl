# Internal helper to create simulation summary table
function simulationsummary(name::Symbol, n::Int, curves::Matrix{<:AbstractFloat})
  iterations = size(curves, 2)
  # calculate statistics across iterations dims 2
  rmean = mean(curves, dims=2)[:]
  rstd = std(curves, dims=2)[:]
  # 95 percent confidence interval margin using student's t-distribution
  # fallback to 0.0 margin if only 1 iteration is provided to avoid TDist(0) error
  tVal = iterations > 1 ? quantile(TDist(iterations - 1), 0.975) : 0.0
  margin = tVal .* rstd
  return DataFrame(
    name => 1:n,
    :richness => rmean,
    :std => rstd,
    :lower => rmean .- margin,
    :upper => rmean .+ margin,
  )
end

"""
    speciesaccumulation(matrix::DataFrame; iterations=1000)

Calculates a site-based species accumulation curve (collector curve) using Monte Carlo simulation.

# Arguments
- `matrix`: A DataFrame from `communitymatrix`.
- `iterations`: Number of Monte Carlo iterations (default: 1000).

# Returns
A DataFrame with columns for plot number, mean richness, standard deviation, and 95% confidence intervals.
"""
function speciesaccumulation(matrix::DataFrame; iterations::Int=1000)
  # extract data and create boolean presence matrix
  rawdata = Matrix(matrix[:, 2:end])
  presence = rawdata .> 0
  nplots, nspecies = size(presence)
  # preallocate storage for simulation results
  curves = zeros(Float64, nplots, iterations)
  # monte carlo simulation loop
  for i in 1:iterations
    # randomize sampling order
    order = shuffle(1:nplots)
    # tracking vector for species found in this run
    found = zeros(Bool, nspecies)
    for (step, idx) in enumerate(order)
      # update found species using boolean or
      found .|= presence[idx, :]
      # record richness at this step
      curves[step, i] = count(found)
    end
  end
  return simulationsummary(:plots, nplots, curves)
end

"""
    speciesaccumulation(counts::AbstractVector{<:Real}; iterations=1000)

Calculates an individual-based rarefaction curve using Monte Carlo simulation.

# Arguments
- `counts`: A vector of species abundances.
- `iterations`: Number of Monte Carlo iterations (default: 1000).

# Returns
A DataFrame with columns for individual number, mean richness, standard deviation, and 95% confidence intervals.
"""
function speciesaccumulation(counts::AbstractVector{<:Real}; iterations::Int=1000)
  # prepare integer abundances excluding zeros
  abundances = filter(>(0), round.(Int, counts))
  totalind = sum(abundances)
  nspp = length(abundances)
  # expand counts into a vector of individual identities
  pool = Int[]
  sizehint!(pool, totalind)
  for (id, count) in enumerate(abundances)
    append!(pool, fill(id, count))
  end
  # preallocate storage
  curves = zeros(Float64, totalind, iterations)
  # monte carlo simulation loop
  for i in 1:iterations
    # randomize individuals
    randompool = shuffle(pool)
    found = zeros(Bool, nspp)
    currentrichness = 0
    # iterate through every individual
    for (step, spid) in enumerate(randompool)
      # if species not yet found add to richness
      if !found[spid]
        found[spid] = true
        currentrichness += 1
      end
      curves[step, i] = currentrichness
    end
  end
  return simulationsummary(:individuals, totalind, curves)
end

speciesaccumulation(plots::AbstractVector, species::AbstractVector; kwargs...) =
  speciesaccumulation(communitymatrix(plots, species); kwargs...)

speciesaccumulation(species::AbstractVector; kwargs...) =
  speciesaccumulation(countspecies(species); kwargs...)
