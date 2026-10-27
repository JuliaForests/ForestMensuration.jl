@testset "species accumulation" begin
  Random.seed!(42)
  species = ["A", "B", "A", "C", "B", "A"]
  plots = [1, 1, 2, 2, 3, 3]
  mat = communitymatrix(plots, species)

  @testset "Plot-based Accumulation" begin
    accPlots = speciesaccumulation(mat, iterations=50)
    @test size(accPlots) == (3, 5)
    @test accPlots.plots == [1, 2, 3]
    @test accPlots.richness[end] == 3.0
    @test issorted(accPlots.richness)
  end

  @testset "Individual-based Accumulation" begin
    counts = [3, 2, 1]
    accInd = speciesaccumulation(counts, iterations=50)
    @test size(accInd) == (6, 5)
    @test accInd.individuals == [1, 2, 3, 4, 5, 6]
    @test accInd.richness[end] == 3.0
    @test issorted(accInd.richness)
  end

  @testset "Wrappers" begin
    accWrapPlots = speciesaccumulation(plots, species, iterations=10)
    @test size(accWrapPlots) == (3, 5)
    accWrapInd = speciesaccumulation(species, iterations=10)
    @test size(accWrapInd) == (6, 5)
  end
end
