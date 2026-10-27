using ForestMensuration
using Test
using DataFrames
using Random
using Statistics
using Unitful

using ForestMensuration:
  arithmeticmeandiameter, quadraticmeandiameter, weisediameter, centralbasalareadiameter,
  dominantdiameter, hohenaldiameters, dominanttreecount
# Define shared values for tests
@testset "ForestMensuration.jl" begin
  include("cubagetests.jl")
  include("statisticstests.jl")
  include("standmetricstests.jl")
  include("ecologytests.jl")
end
