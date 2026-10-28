"""
    communitymatrix(plots::AbstractVector, species::AbstractVector)

Transforms raw list data into a presence-absence or abundance matrix.
Rows represent plots and columns represent species.

# Arguments
- `plots`: A vector of plots identifiers for each observation.
- `species`: A vector of species names corresponding to each observation.

# Returns
A DataFrame with plots as rows and species counts as columns. Missing values are filled with zeros.
"""
function communitymatrix(plots::AbstractVector, species::AbstractVector)
  checklengths(:plots => plots, :species => species)
  # create temporary dataframe
  df = DataFrame(plots=plots, s=species)
  # count occurrences per species per plot
  # equivalent to r table function
  grouped = combine(groupby(df, [:plots, :s]), nrow => :n)
  # pivot to wide format
  # fill missing values with zero
  wide = unstack(grouped, :plots, :s, :n, fill=0)
  # ensure missing values are treated as zeros if unstack leaves any
  return coalesce.(wide, 0)
end

"""
    diversity(n::AbstractVector{<:Real})

Calculates diversity indices from a vector of species abundances (counts).

# Arguments
- `n`: A vector of non-negative real numbers representing species abundances.

# Returns
A DataFrame containing the following diversity indices:
- `richness`: Number of species with abundance > 0.
- `abundance`: Total number of individuals.
- `shannon`: Shannon-Wiener diversity index.
- `simpson`: Simpson diversity index (1 - lambda).
- `invsimpson`: Inverse Simpson index (1 / lambda).
- `jevenness`: Pielou's evenness index (Shannon / log(richness)).
- `berger`: Berger-Parker dominance index (max abundance / total abundance).
- `chao1`: Chao1 richness estimator.
"""
function diversity(n::AbstractVector{<:Real})
  abundances = filter(>(0), n)
  s = length(abundances)
  # handle empty data
  if s == 0
    return DataFrame(
      richness=0, abundance=0, shannon=0.0, simpson=0.0,
      invsimpson=0.0, jevenness=0.0, berger=0.0, chao1=0.0,
    )
  end
  total = sum(abundances)
  p = abundances ./ total
  shannon = -sum(p .* log.(p))
  lambda = sum(abs2, p)
  simpson = 1.0 - lambda
  invsimpson = 1.0 / lambda
  jevenness = s > 1 ? shannon / log(s) : 0.0
  berger = maximum(abundances) / total
  f1 = count(==(1), abundances)
  f2 = count(==(2), abundances)
  chao1 = f2 > 0 ? s + (f1^2) / (2 * f2) : s + (f1 * (f1 - 1)) / 2

  return DataFrame(
    richness=s,
    abundance=total,
    shannon=shannon,
    simpson=simpson,
    invsimpson=invsimpson,
    jevenness=jevenness,
    berger=berger,
    chao1=chao1,
  )
end

# internal helper to count species abundances
countspecies(species::AbstractVector) = collect(values(countmap(species)))

"""
    diversity(species::AbstractVector)

Calculates diversity indices directly from a list of species names (pooled data).

# Arguments
- `species`: A vector of species identifiers (e.g., strings or symbols).

# Returns
A DataFrame with diversity indices as described in `diversity(n)`.
"""
diversity(species::AbstractVector) = countspecies(species) |> diversity

"""
    diversity(matrix::DataFrame)

Calculates diversity indices for each plot in a community matrix and adds a pooled result.

# Arguments
- `matrix`: A DataFrame from `communitymatrix`, with plots as rows and species as columns.

# Returns
A DataFrame with diversity indices for each plot, plus a row for pooled data across all plots.
"""
function diversity(matrix::DataFrame)
  plots = matrix[!, 1]
  rawdata = Matrix(matrix[:, 2:end])
  div = vcat([diversity(row) for row in eachrow(rawdata)]...)
  insertcols!(div, 1, :plots => plots)
  pooled = sum(rawdata, dims=1)[:] |> diversity
  insertcols!(pooled, 1, :plots => "pooled")
  return vcat(div, pooled)
end

"""
    diversity(plots::AbstractVector, species::AbstractVector)

Wrapper that transforms raw lists into a community matrix and calculates diversity indices.

# Arguments
- `plots`: A vector of plot identifiers.
- `species`: A vector of species names.

# Returns
A DataFrame with diversity indices for each plot and pooled data.
"""
diversity(plots::AbstractVector, species::AbstractVector) = communitymatrix(plots, species) |> diversity

# Internal function to calculate ecological dissimilarity distance between plots.
function dissimilarity(matrix::DataFrame; method::String="jaccard")
  plots = matrix[!, 1]
  nplots = length(plots)
  rawdata = Matrix(matrix[:, 2:end])
  isbinary = method == "jaccard" || method == "sorensen"
  binarydata = isbinary ? (rawdata .> 0) : nothing
  result = zeros(Float64, nplots, nplots)

  for i in 1:nplots
    for j in i:nplots
      if i != j
        dist = 0.0

        if method == "jaccard"
          # jaccard dissimilarity = 1 - (a / union)
          p1 = binarydata[i, :]
          p2 = binarydata[j, :]
          a = count(p1 .& p2)
          b = count(p1)
          c = count(p2)
          unionval = b + c - a
          sim = unionval > 0 ? a / unionval : 0.0
          dist = 1.0 - sim

        elseif method == "sorensen"
          # sorensen dissimilarity = 1 - (2a / total)
          p1 = binarydata[i, :]
          p2 = binarydata[j, :]
          a = count(p1 .& p2)
          total = count(p1) + count(p2)
          sim = total > 0 ? (2 * a) / total : 0.0
          dist = 1.0 - sim

        elseif method == "braycurtis"
          # bray curtis dissimilarity
          # sum(|u-v|) / sum(u+v)
          v1 = rawdata[i, :]
          v2 = rawdata[j, :]
          diffsum = sum(abs.(v1 .- v2))
          totalsum = sum(v1 .+ v2)
          dist = totalsum > 0 ? diffsum / totalsum : 0.0

        else
          throw(ArgumentError("method must be jaccard, sorensen or braycurtis"))
        end
        # symmetric fill
        result[i, j] = dist
        result[j, i] = dist
      end
    end
  end

  dfout = DataFrame(result, :auto)
  rename!(dfout, string.(plots))
  insertcols!(dfout, 1, :plots => plots)

  return dfout
end

"""
    floristicdistance(matrix::DataFrame; method::String="jaccard")

Calculates ecological dissimilarity distance between plots.
Master function for dissimilarities supporting binary and quantitative data.

# Arguments
- `matrix`: DataFrame generated by communitymatrix.
- `method`: "jaccard", "sorensen", or "braycurtis".

# Returns
DataFrame with symmetric dissimilarity matrix.
"""
floristicdistance(matrix::DataFrame; method::String="jaccard") = dissimilarity(matrix; method=method)

floristicdistance(plots::AbstractVector, species::AbstractVector) = communitymatrix(plots, species) |> floristicdistance

"""
    floristicsimilarity(matrix::DataFrame; method::String="jaccard")

Calculates ecological similarity between plots.
Wrapper function that inverts the result of floristicdistance.
Similarity = 1 - distance.

# Arguments
- `matrix`: DataFrame generated by communitymatrix.
- `method`: "jaccard", "sorensen", or "braycurtis".

# Returns
DataFrame with symmetric similarity matrix.
"""
function floristicsimilarity(matrix::DataFrame; method::String="jaccard")
  fd = dissimilarity(matrix; method=method)
  fd[:, 2:end] .= 1 .- fd[:, 2:end]
  return fd
end

floristicsimilarity(plots::AbstractVector, species::AbstractVector) = communitymatrix(plots, species) |> floristicsimilarity
