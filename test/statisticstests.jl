@testset "dendrometrics and distributiontables" begin
  @testset "Dendrometric Averages Function Tests" begin

    @testset "Basal Area Tests" begin
      dStandard = 30.0u"cm"
      expectedBasalArea = 0.07068583470577035
      @test basalarea(dStandard) |> ustrip ≈ expectedBasalArea atol = 1e-6
      dZero = 0.0u"cm"
      @test basalarea(dZero) == 0.0u"m^2"
      @test_throws DomainError basalarea(-dStandard)
    end

    diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm"
    plotArea = 0.05u"ha"

    @testset "Diameter Metrics Tests" begin
      @test arithmeticmeandiameter(diameters) |> ustrip ≈ 17.25 atol = 1e-4
      @test quadraticmeandiameter(diameters) |> ustrip ≈ 17.779904 atol = 1e-6
      @test weisediameter(diameters) |> ustrip ≈ 18.0 atol = 1e-4
      @test centralbasalareadiameter(diameters) |> ustrip ≈ 19.5 atol = 1e-6
      @test dominantdiameter(diameters, plotArea) |> ustrip ≈ 21.10687 atol = 1e-4
      hohenadl = hohenaldiameters(diameters)
      @test hohenadl.Dl |> ustrip ≈ 12.708524 atol = 1e-6
      @test hohenadl.Du |> ustrip ≈ 21.791475 atol = 1e-6

      # a plot too small for the dominant-tree standard returns NaN, but the result
      # must still carry the diameter unit so DataFrame columns stay type-consistent
      dNaN = dominantdiameter(diameters, 0.0u"ha")
      @test isnan(dNaN)
      @test unit(dNaN) == u"cm"
      @test unit(dominantdiameter(ustrip.(diameters) * u"inch", 0.0u"ac")) == u"inch"
    end

    @testset "DataFrame standmetrics Tests" begin
      dfStand = standmetrics(diameters, plotArea) .|> ustrip
      @test names(dfStand) == ["n", "g", "N", "G", "Dm", "Dg", "CD"]
      @test dfStand.n[1] == 10
      @test dfStand.g[1] ≈ 0.248284 atol = 1e-6
      @test dfStand.N[1] ≈ 200.0 atol = 1e-4
      @test dfStand.G[1] ≈ 4.96568 atol = 1e-5
      @test dfStand.Dm[1] ≈ 17.25 atol = 1e-4
      @test dfStand.Dg[1] ≈ 17.7799 atol = 1e-4
      @test dfStand.CD[1] ≈ 26.3274 atol = 1e-4

      # Dg and g come from the mean and the standard deviation: they equal the direct calculation
      @test dfStand.Dg[1] ≈ ustrip(quadraticmeandiameter(diameters))
      @test dfStand.g[1] ≈ ustrip(sum(basalarea, diameters))

      # a single tree has no standard deviation: Dg is its diameter and CD is NaN
      dfOne = standmetrics([20.0]u"cm", plotArea)
      @test dfOne.Dg[1] == dfOne.Dm[1] == 20.0u"cm"
      @test isnan(dfOne.CD[1])

      # results follow the unit of the input diameters, not a hardcoded one
      dfStandInch = standmetrics(ustrip.(diameters) * u"inch", ustrip(plotArea) * u"ac")
      @test unit(dfStandInch.Dm[1]) == u"inch"
      @test unit(dfStandInch.g[1]) == u"ft^2"
      @test unit(dfStandInch.N[1]) == u"ac^-1"
    end
  end

  @testset "Frequency Tables Function Tests" begin
    # Test Data
    diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]
    species = ["Oak", "Oak", "Oak", "Oak", "Oak", "Pine", "Pine", "Pine", "Pine", "Pine"]
    data = DataFrame(species=species, diameters=diameters)

    # Test 1: Standard Case
    result_df = frequencytable(diameters, 2)
    @test isa(result_df, DataFrame)

    # Expected results for the test data
    expected_df = DataFrame(
      LI=[10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0],
      Xi=[11.0, 13.0, 15.0, 17.0, 19.0, 21.0, 23.0, 25.0],
      LS=[12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0],
      fi=[1, 2, 1, 1, 2, 1, 1, 1],
      Fi=[1, 3, 4, 5, 7, 8, 9, 10],
      fri=[10.0, 20.0, 10.0, 10.0, 20.0, 10.0, 10.0, 10.0],
      Fri=[10.0, 30.0, 40.0, 50.0, 70.0, 80.0, 90.0, 100.0],
    )

    # Compare the result with expected values
    @test size(result_df) == size(expected_df)

    for col in names(expected_df)
      @test result_df[!, col] == expected_df[!, col]
    end

    # a value belongs to the class [LI, LS) that holds it: 11.5 is in 10-12, and 12.0 in 12-14
    edges = frequencytable([11.5, 12.0, 13.5], 2)
    @test edges.LI == [10.0, 12.0]
    @test edges.fi == [1, 2]

    # the classes between the smallest and the largest value are all listed, the empty ones with frequency zero
    gaps = frequencytable([1.0, 7.0], 2)
    @test gaps.LI == [0.0, 2.0, 4.0, 6.0]
    @test gaps.fi == [1, 0, 0, 1]
    @test gaps.Fi == [1, 1, 1, 2]
    @test gaps.Fri == [50.0, 50.0, 50.0, 100.0]
    # a value on a limit is not sent down by floating-point noise
    @test frequencytable([0.3], 0.1).LI ≈ [0.3]

    # Test 2: Invalid Class Width (Negative)
    @test_throws DomainError frequencytable(diameters, -2)

    # Test 3: Invalid Class Width (Zero)
    @test_throws DomainError frequencytable(diameters, 0)

    # Test 4: Verify Cumulative Frequencies
    @test result_df.Fi[end] == sum(result_df.fi)
    @test result_df.Fri[end] == 100.0

    # Test 5: Check if total frequency equals number of data points
    total_frequency = sum(result_df.fi)
    @test total_frequency == length(diameters)

    @testset "with units" begin
      # a unitful sample keeps its unit in the class limits, and a bare class width
      # is interpreted in that same unit
      result_df_u = frequencytable(diameters * u"cm", 2u"cm")
      @test ustrip.(result_df_u.LI) == expected_df.LI
      @test ustrip.(result_df_u.Xi) == expected_df.Xi
      @test ustrip.(result_df_u.LS) == expected_df.LS
      @test unit(result_df_u.LI[1]) == u"cm"

      # a unitful sample needs a unitful class width: no mixing
      @test_throws MethodError frequencytable(diameters * u"cm", 2)

      # frequencytable is not diameter-specific: any unitful variable works, e.g. heights
      result_df_h = frequencytable(diameters * u"m", 2u"m")
      @test unit(result_df_h.LI[1]) == u"m"
      @test ustrip.(result_df_h.LI) == expected_df.LI

      # auto class width also respects the sample's unit
      auto_u = frequencytable(diameters * u"cm")
      auto_plain = frequencytable(diameters)
      @test ustrip.(auto_u.LI) == auto_plain.LI
      @test unit(auto_u.LI[1]) == u"cm"
    end

    @testset "grouped" begin
      result_df_g = frequencytable(:species, :diameters, data)
      @test isa(result_df_g, DataFrame)

      dataU = DataFrame(species=species, diameters=diameters * u"cm")
      result_df_gu = frequencytable(:species, :diameters, dataU)
      @test ustrip.(result_df_gu.LI) == result_df_g.LI
      @test unit(result_df_gu.LI[1]) == u"cm"

      result_df_gu_hi = frequencytable(:species, :diameters, 2u"cm", dataU)
      @test unit(result_df_gu_hi.LI[1]) == u"cm"
    end
  end

  @testset "Diametric Table Function Tests" begin
    # Test Data
    diameters = [10.5, 12.0, 13.5, 15.0, 16.5, 18.0, 19.5, 21.0, 22.5, 24.0]u"cm"
    species = ["Oak", "Oak", "Oak", "Oak", "Oak", "Pine", "Pine", "Pine", "Pine", "Pine"]
    data = DataFrame(species=species, diameters=diameters)

    # Test 1: Standard Case
    result_df = diametrictable(diameters, 2u"cm", plotarea=0.05u"ha")
    @test isa(result_df, DataFrame)

    # Expected results for the test data
    expected_df = DataFrame(
      LI=[10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0],
      Xi=[11.0, 13.0, 15.0, 17.0, 19.0, 21.0, 23.0, 25.0],
      LS=[12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0],
      fi=[1, 2, 1, 1, 2, 1, 1, 1],
      Fi=[1, 3, 4, 5, 7, 8, 9, 10],
      fri=[10.0, 20.0, 10.0, 10.0, 20.0, 10.0, 10.0, 10.0],
      Fri=[10.0, 30.0, 40.0, 50.0, 70.0, 80.0, 90.0, 100.0],
      g=[0.00950332, 0.0132732, 0.0176715, 0.022698, 0.0283529, 0.0346361, 0.0415476, 0.0490874],
      ng=[0.00950332, 0.0265465, 0.0176715, 0.022698, 0.0567057, 0.0346361, 0.0415476, 0.0490874],
      Ng=[0.00950332, 0.0360498, 0.0537212, 0.0764192, 0.133125, 0.167761, 0.209309, 0.258396],
      Ni=[20.0, 40.0, 20.0, 20.0, 40.0, 20.0, 20.0, 20.0],
      NFi=[20.0, 60.0, 80.0, 100.0, 140.0, 160.0, 180.0, 200.0],
      Gi=[0.190066, 0.530929, 0.353429, 0.45396, 1.13411, 0.692721, 0.830951, 0.981748],
      GFi=[0.190066, 0.720996, 1.07442, 1.52838, 2.6625, 3.35522, 4.18617, 5.16792],
    )

    # Compare the result with expected values
    @test size(result_df) == size(expected_df)

    # like Dm/Dg/... elsewhere in the package, diametrictable always returns unitful
    # quantities even when called with plain numbers, so strip units before comparing
    for col in names(expected_df)
      @test all(isapprox.(ustrip.(result_df[!, col]), expected_df[!, col], atol=1e-5))
    end

    # Test 2: Invalid Class Width (Negative)
    @test_throws DomainError diametrictable(diameters, -2u"cm")

    # Test 3: Invalid Class Width (Zero)
    @test_throws DomainError diametrictable(diameters, 0u"cm")

    # Test 4: Invalid Plot Area (Negative)
    @test_throws DomainError diametrictable(diameters, 2u"cm", plotarea=-0.05u"ha")

    # Test 5: Diameters with Negative Values
    @test_throws DomainError diametrictable(-diameters, 2u"cm")

    # Test 6: Diameters with Zero Values
    @test_throws DomainError diametrictable([0, 10.5, 12.0]u"cm", 2u"cm")

    # Test 7: Check if cumulative ng equals sum of ng
    @test ustrip(result_df.Ng[end]) ≈ ustrip(sum(result_df.ng)) atol = 1e-5

    # Test 8: Check if cumulative Gi equals sum of Gi
    @test ustrip(result_df.GFi[end]) ≈ ustrip(sum(result_df.Gi)) atol = 1e-5

    @testset "with units" begin
      # diameters and class width as quantities, plot area as a quantity in m^2
      result_df_u = diametrictable(diameters, 2u"cm", plotarea=500u"m^2")
      for col in names(expected_df)
        @test all(isapprox.(ustrip.(result_df_u[!, col]), expected_df[!, col], atol=1e-5))
      end
      @test unit(result_df_u.LI[1]) == u"cm"
      @test unit(result_df_u.g[1]) == u"m^2"
      @test unit(result_df_u.Ni[1]) == u"ha^-1"

      # mixing a unitful diameter vector with a bare class width and plot area is an error
      @test_throws MethodError diametrictable(diameters, 2, plotarea=0.05)

      # a plot exactly one reference area wide needs no expansion, so those columns
      # are omitted instead of being a redundant copy of fi/ng
      result_df_default = diametrictable(diameters, 2u"cm")
      @test "Ni" ∉ names(result_df_default)
      @test "NFi" ∉ names(result_df_default)
      @test "Gi" ∉ names(result_df_default)
      @test "GFi" ∉ names(result_df_default)
      @test ncol(result_df_default) == ncol(result_df) - 4

      # imperial diameters expand per acre and report areas in ft^2
      imperial = diametrictable([4.0, 5.0, 6.0, 7.0]u"inch", 1u"inch", plotarea=0.1u"ac")
      @test unit(imperial.g[1]) == u"ft^2"
      @test unit(imperial.Ni[1]) == u"ac^-1"
    end

    @testset "grouped with units" begin
      dataU = DataFrame(species=species, diameters=diameters)
      result_df_gu = diametrictable(:species, :diameters, dataU, plotarea=0.05u"ha")
      @test unit(result_df_gu.LI[1]) == u"cm"
      @test unit(result_df_gu.g[1]) == u"m^2"

      result_df_gu_hi = diametrictable(:species, :diameters, 3u"cm", dataU, plotarea=0.05u"ha")
      @test unit(result_df_gu_hi.LI[1]) == u"cm"
    end
  end

end
