@testset "standmetrics by species" begin
  species = ["A", "B", "A", "C", "B", "A"]
  plots = [1, 1, 2, 2, 3, 3]
  D = [10.0, 15.0, 12.0, 20.0, 14.0, 11.0] * u"cm"
  area = 0.3u"ha"
  result = standmetrics(species, plots, D, area)
  @test size(result) == (3, 15)
  @test names(result) == ["species", "n", "g", "N", "G", "Dm", "Dg", "CD", "plots", "RDe", "RDo", "AF", "RF", "VC", "IVI"]
  # the totals over the species are the n, g, N and G of the stand, as the stand gives them
  stand = standmetrics(D, area)
  @test sum(result.n) == stand.n[1]
  @test sum(result.g) ≈ stand.g[1]
  @test sum(result.N) ≈ stand.N[1]
  @test sum(result.G) ≈ stand.G[1]
  @test result.species == ["A", "B", "C"]
  @test result.n == [3, 2, 1]
  @test result.plots == [3, 2, 1]
  # the mean diameters of each species, and a single tree, which has no standard deviation
  @test ustrip.(result.Dm) ≈ [11.0, 14.5, 20.0]
  @test ustrip.(result.Dg) ≈ [sqrt((100 + 144 + 121) / 3), sqrt((225 + 196) / 2), 20.0]
  @test isnan(result.CD[3])
  @test isapprox(result.AF, [100.0, 66.6667, 33.3333], atol=1e-4)
  @test isapprox(result.RDe, [50.0, 33.3333, 16.6667], atol=1e-4)
  @test isapprox(result.RDo, [30.7757, 35.4975, 33.7268], atol=1e-4)
  @test isapprox(result.RF, [50.0, 33.3333, 16.6667], atol=1e-4)
  @test isapprox(result.VC, [80.7757, 68.8308, 50.3935], atol=1e-4)
  @test isapprox(result.IVI, [43.5919, 34.0547, 22.3534], atol=1e-4)
  @test isapprox(sum(result.RDe), 100.0, atol=1e-5)
  @test isapprox(sum(result.RDo), 100.0, atol=1e-5)
  @test isapprox(sum(result.RF), 100.0, atol=1e-5)
  @test_throws DimensionMismatch standmetrics(["A"], [1, 2], [10.0u"cm"], area)
end
