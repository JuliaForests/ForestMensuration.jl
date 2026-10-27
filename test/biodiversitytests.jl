@testset "biodiversity" begin
  species = ["A", "B", "A", "C", "B", "A"]
  plots = [1, 1, 2, 2, 3, 3]

  @testset "Community Matrix" begin
    mat = communitymatrix(plots, species)
    @test size(mat) == (3, 4)
    @test mat.A == [1, 1, 1]
    @test mat.B == [1, 0, 1]
    @test mat.C == [0, 1, 0]
    @test_throws DimensionMismatch communitymatrix([1, 2], ["A"])
  end

  @testset "Alpha Diversity" begin
    divVector = diversity([3, 2, 1])
    @test divVector.richness[1] == 3
    @test divVector.abundance[1] == 6
    @test isapprox(divVector.shannon[1], 1.0114, atol=1e-4)
    @test isapprox(divVector.simpson[1], 0.611111, atol=1e-4)
    @test isapprox(divVector.invsimpson[1], 2.57143, atol=1e-4)
    @test isapprox(divVector.jevenness[1], 0.92062, atol=1e-4)
    @test isapprox(divVector.berger[1], 0.5, atol=1e-4)
    @test isapprox(divVector.chao1[1], 3.5, atol=1e-4)
    divSpecies = diversity(species)
    @test divSpecies.richness[1] == 3
    @test divSpecies.abundance[1] == 6
    mat = communitymatrix(plots, species)
    divMat = diversity(mat)
    @test size(divMat) == (4, 9)
    @test divMat.plots[end] == "pooled"
    @test divMat.richness[1] == 2
    @test divMat.richness[2] == 2
    divWrap = diversity(plots, species)
    @test size(divWrap) == (4, 9)
  end

  @testset "Beta Diversity (Distance & Similarity)" begin
    mat = communitymatrix(plots, species)

    @testset "Jaccard" begin
      dist = floristicdistance(mat, method="jaccard")
      sim = floristicsimilarity(mat, method="jaccard")
      @test isapprox(dist[3, "1"], 0.0, atol=1e-4)
      @test isapprox(sim[3, "1"], 1.0, atol=1e-4)
      @test isapprox(dist[2, "1"], 0.666666, atol=1e-4)
      @test isapprox(sim[2, "1"], 0.333333, atol=1e-4)
    end

    @testset "Sorensen" begin
      dist = floristicdistance(mat, method="sorensen")
      sim = floristicsimilarity(mat, method="sorensen")
      @test isapprox(dist[3, "1"], 0.0, atol=1e-4)
      @test isapprox(dist[2, "1"], 0.5, atol=1e-4)
      @test isapprox(sim[2, "1"], 0.5, atol=1e-4)
    end

    @testset "Bray-Curtis" begin
      dist = floristicdistance(mat, method="braycurtis")
      sim = floristicsimilarity(mat, method="braycurtis")
      @test isapprox(dist[3, "1"], 0.0, atol=1e-4)
      @test isapprox(dist[2, "1"], 0.5, atol=1e-4)
      @test isapprox(sim[2, "1"], 0.5, atol=1e-4)
    end

    @testset "Wrapper Methods & Errors" begin
      distWrap = floristicdistance(mat, method="jaccard")
      @test size(distWrap) == (3, 4)
      @test_throws ArgumentError floristicdistance(mat, method="invalid")
    end
  end
end
