using Test
using Unitful
using DataFrames
using ForestMensuration

# The data of the tests are the tables of the book of Machado & Figueiredo Filho (2003), Chapter 5:
# MACHADO, S. A.; FIGUEIREDO FILHO, A. Dendrometria. Curitiba: Ed. dos Autores, 2003. 309 p.
#
# Tables 5.1 (Smalian), 5.2 (Huber) and 5.3 (Newton) are the same tree. The field columns are the diameters with
# bark (d c/c) and without bark (d s/c) in cm; the office columns are the cross-sectional areas (g c/c and g s/c) in m².

# Table 5.1: heights and diameters of Smalian's method (the sections are limited by the measurements)
const H51 = [0.1, 1.3, 3.3, 5.3, 7.3, 9.3, 11.3, 13.3, 15.3]u"m"
const D51 = [27.7, 22.3, 20.3, 18.8, 17.5, 14.3, 9.5, 6.0, 1.2]u"cm"
const DS51 = [24.1, 18.9, 17.2, 16.4, 15.5, 12.9, 8.3, 5.2, 1.0]u"cm"
const G51 = [0.0603, 0.0391, 0.0324, 0.0278, 0.0241, 0.0161, 0.0071, 0.0028, 0.0001]u"m^2"
const GS51 = [0.0456, 0.0281, 0.0232, 0.0211, 0.0189, 0.0131, 0.0054, 0.0021, 0.00008]u"m^2"
const E51 = (D51 .- DS51) ./ 2    # the bark thickness, since ds = d - 2E

# Table 5.3: limit, middle, limit, ..., limit, of Huber's and Newton's methods
const H53 = [0.1, 0.7, 1.3, 2.3, 3.3, 4.3, 5.3, 6.3, 7.3, 8.3, 9.3, 10.3, 11.3, 12.3, 13.3, 14.3, 15.3]u"m"
const D53 = [27.7, 24.8, 22.3, 20.7, 20.3, 19.4, 18.8, 18.1, 17.5, 17.0, 14.3, 11.5, 9.5, 7.6, 6.0, 4.5, 1.2]u"cm"
const DS53 = [24.1, 21.4, 18.9, 17.6, 17.2, 16.8, 16.4, 16.0, 15.5, 15.0, 12.9, 10.1, 8.3, 6.6, 5.2, 3.9, 1.0]u"cm"
const G53 = [0.0603, 0.0483, 0.0391, 0.0337, 0.0324, 0.0296, 0.0278, 0.0257, 0.0241, 0.0227, 0.0161, 0.0104, 0.0071, 0.0045, 0.0028, 0.0016, 0.0001]u"m^2"
const GS53 = [0.0456, 0.0360, 0.0281, 0.0243, 0.0232, 0.0222, 0.0211, 0.0201, 0.0189, 0.0177, 0.0131, 0.0080, 0.0054, 0.0034, 0.0021, 0.0012, 0.00008]u"m^2"

# Table 5.4: Hohenadl's method, 10 sections of 1.58 m (15.8 m of bole above the stump of 0.1 m, for a total height of 15.9 m), the diameters at the middle of each one.
# The first diameter is printed as 24.0 cm, but its area of 0.0468 m² is that of 24.4 cm: the printed value is kept here.
const D54 = [24.0, 20.5, 19.7, 18.6, 17.7, 15.8, 11.5, 8.0, 5.9, 1.5]u"cm"
const G54 = [0.0468, 0.0330, 0.0305, 0.0272, 0.0246, 0.0196, 0.0104, 0.0050, 0.0027, 0.0002]u"m^2"
const GS54 = [0.0346, 0.0241, 0.0224, 0.0209, 0.0194, 0.0154, 0.0080, 0.0040, 0.0020, 0.0001]u"m^2"

# The diameter at breast height (22.3 cm) and the total height (15.9 m) of the tree of 5.1 to 5.3.
const HTOTAL = 15.9u"m"
# The 10 sections of Table 5.4 are the bole above the stump of 0.1 m: 15.9 - 0.1 = 15.8 m, so (H / 10) = 1.58 m
const HBOLE = 15.8u"m"

# The tree of Table 2 of FLORIANO, E. P. Dendrometria, 2nd edition, 2025 (Section 6.2): a stump of 0.35 m, 11 sections
# of different lengths and a tip, cubed by Huber, Smalian and Newton. The book totals include the stump and the tip.
# The limits of the sections (h, d), the diameters at their middles (dm) and the total height and the diameter at breast height.
const HF = [0.35, 0.95, 1.30, 2.50, 3.70, 4.90, 6.10, 7.30, 8.50, 9.70, 10.90, 12.10]u"m"
const DF = [19.6, 15.9, 14.3, 12.8, 12.6, 11.7, 10.5, 9.2, 7.2, 5.0, 2.9, 1.1]u"cm"
const DMF = [16.5, 14.8, 13.4, 12.9, 11.9, 11.2, 9.6, 8.2, 5.9, 3.8, 1.8]u"cm"
const HTF = 12.53u"m"
const DBHF = 14.3u"cm"
const DBH = 22.3u"cm"

# The volume of the sections by the areas of the office columns, as in the book
bookvolume(::Type{Smalian}, h, g) = sum((g[j-1] + g[j]) / 2 * (h[j] - h[j-1]) for j in 2:length(h))
bookvolume(::Type{Huber}, h, g) = sum(g[j] * (h[j+1] - h[j-1]) for j in 2:2:(length(h)-1))
bookvolume(::Type{Newton}, h, g) = sum((g[j-1] + 4 * g[j] + g[j+1]) / 6 * (h[j+1] - h[j-1]) for j in 2:2:(length(h)-1))

@testset "cubage.jl" begin
  @testset "The tables of the book" begin
    # the office columns of the book are the cross-sectional areas of the field columns, rounded to 4 decimals
    @test all(abs.(ustrip.(u"m^2", basalarea.(D51)) .- ustrip.(G51)) .< 5e-5)
    @test all(abs.(ustrip.(u"m^2", basalarea.(DS51)) .- ustrip.(GS51)) .< 5e-5)
    @test all(abs.(ustrip.(u"m^2", basalarea.(D53)) .- ustrip.(G53)) .< 5e-5)
    @test all(abs.(ustrip.(u"m^2", basalarea.(DS53)) .- ustrip.(GS53)) .< 5e-5)
    @test count(abs.(ustrip.(u"m^2", basalarea.(D54)) .- ustrip.(G54)) .< 5e-5) == 9   # all but the first, see above
  end

  @testset "Volume helpers" begin
    # the stump of the tree of Table 5.1: 0.1 m high with 27.7 cm of diameter, g = 0.0603 m² (the area of the book times 0.1 m)
    @test ustrip(u"m^3", cylindervolume(0.1u"m", 27.7u"cm")) ≈ 0.00603 atol = 1e-4
    # the tip, a cone with the last diameter, 1.2 cm, up to the total height of 15.9 m
    @test conevolume(0.6u"m", 1.2u"cm") ≈ cylindervolume(0.6u"m", 1.2u"cm") / 3
    @test ustrip(u"m^3", conevolume(0.6u"m", 1.2u"cm")) ≈ 0.0001 * 0.6 / 3 atol = 1e-5

    # k_b = 1 - 2 ΣE / Σd = Σds / Σd, with the diameters of Table 5.1
    @test barkfactor(D51, E51) ≈ sum(ustrip.(DS51)) / sum(ustrip.(D51))
    @test barkfactor(D51, E51) ≈ 0.8684593023255813

    # a zero diameter (tip of the tree) is valid; only negative diameters, or all-zero ones, are errors
    @test barkfactor([D51; 0.0u"cm"], [E51; 0.0u"cm"]) ≈ barkfactor(D51, E51)
    @test_throws DomainError barkfactor([-D51[1]; D51[2:end]], E51)
    @test_throws DomainError barkfactor([0.0, 0.0]u"cm", [0.0, 0.0]u"cm")
    @test_throws DomainError barkfactor(D51, [-E51[1]; E51[2:end]])

    # p_b = 100 (v - vs) / v; volumes in different units are compared correctly
    @test barkpercentage(0.319069u"m^3", 0.240002u"m^3") ≈ 24.7805 atol = 1e-3
    @test barkpercentage(319.069u"dm^3", 0.240002u"m^3") ≈ barkpercentage(0.319069u"m^3", 0.240002u"m^3")
    @test barkpercentage(0.3u"m^3", 0.3u"m^3") == 0.0
    @test barkpercentage(0.3u"m^3", 0.0u"m^3") == 100.0
    @test_throws DomainError barkpercentage(0.0u"m^3", 0.0u"m^3")
    @test_throws DomainError barkpercentage(0.3u"m^3", 0.4u"m^3")
    @test_throws DomainError barkpercentage(0.3u"m^3", -0.1u"m^3")

    # zero is a legitimate stump height / tip diameter, not a domain error
    @test cylindervolume(0.0u"m", D51[1]) == 0.0u"m^3"
    @test conevolume(1.0u"m", 0.0u"cm") == 0.0u"m^3"
    @test_throws DomainError cylindervolume(-1.0u"m", D51[1])
    @test_throws DomainError conevolume(1.0u"m", -1.0u"cm")
  end

  @testset "Section methods" begin
    # the first section of the tree of Tables 5.1 to 5.3, from 0.1 m to 1.3 m: l = 1.2 m
    # Smalian: (g 0.0603 + g 0.0391) / 2 · 1.2
    @test ustrip(u"m^3", smalian(1.2u"m", 27.7u"cm", 22.3u"cm")) ≈ (0.0603 + 0.0391) / 2 * 1.2 atol = 1e-4
    # Huber, Table 5.2: v1 = g(0.7) · l1 = 0.0483 · 1.2 = 0.0580 m³
    @test ustrip(u"m^3", huber(1.2u"m", 24.8u"cm")) ≈ 0.0580 atol = 1e-4
    # the second section, from 1.3 m to 3.3 m: v2 = g(2.3) · l2 = 0.0337 · 2 = 0.0674 m³
    @test ustrip(u"m^3", huber(2.0u"m", 20.7u"cm")) ≈ 0.0674 atol = 2e-4
    # Newton: (g 0.0603 + 4 · 0.0483 + 0.0391) / 6 · 1.2
    @test ustrip(u"m^3", newton(1.2u"m", 27.7u"cm", 24.8u"cm", 22.3u"cm")) ≈ (0.0603 + 4 * 0.0483 + 0.0391) / 6 * 1.2 atol = 1e-4
    @test_throws DomainError smalian(-1.2u"m", 27.7u"cm", 22.3u"cm")
    @test_throws DomainError huber(0.0u"m", 24.8u"cm")
    @test_throws DomainError newton(-1.2u"m", 27.7u"cm", 24.8u"cm", 22.3u"cm")

    # unit normalisation: results must stay coherent (m^3) when length and diameter
    # units differ, instead of leaking a composite unit like `cm m^2`
    @test unit(smalian(120.0u"cm", 27.7u"cm", 22.3u"cm")) == u"m^3"
    @test smalian(120.0u"cm", 277.0u"mm", 22.3u"cm") ≈ smalian(1.2u"m", 27.7u"cm", 22.3u"cm")
    @test unit(huber(1200.0u"mm", 24.8u"cm")) == u"m^3"
    @test huber(1200.0u"mm", 24.8u"cm") ≈ huber(1.2u"m", 24.8u"cm")
    @test unit(newton(4.0u"ft", 27.7u"cm", 24.8u"cm", 22.3u"cm")) == u"m^3"

    # imperial diameters keep results in cubic feet
    @test unit(smalian(4.0u"ft", 11.0u"inch", 9.0u"inch")) == u"ft^3"
    @test unit(huber(4.0u"ft", 10.0u"inch")) == u"ft^3"
    @test unit(newton(4.0u"ft", 11.0u"inch", 10.0u"inch", 9.0u"inch")) == u"ft^3"
    @test ustrip(u"m^3", smalian(uconvert(u"ft", 1.2u"m"), uconvert(u"inch", 27.7u"cm"), uconvert(u"inch", 22.3u"cm"))) ≈
          ustrip(u"m^3", smalian(1.2u"m", 27.7u"cm", 22.3u"cm"))

    # every section of Table 5.1 against the values printed in the book (they use the areas rounded to 4 decimals, hence the tolerance)
    book_sections = [0.0596, 0.0715, 0.0602, 0.0519, 0.0402, 0.0232, 0.0099, 0.0029]
    sections = [ustrip(u"m^3", smalian(H51[j] - H51[j-1], D51[j-1], D51[j])) for j in 2:9]
    @test all(abs.(sections .- book_sections) .< 2e-4)
    @test sum(sections[2:end]) ≈ 0.2598 atol = 1e-3          # v2 to v8
    @test sum(sections) + ustrip(u"m^3", conevolume(0.6u"m", 1.2u"cm")) ≈ 0.31942 atol = 5e-4   # v1 + ... + v8 + vp, the book leaves out the stump
    @test ustrip(u"m^3", smalian(H51[2] - H51[1], DS51[1], DS51[2])) ≈ 0.0442 atol = 1e-4   # without bark
    @test ustrip(u"m^3", smalian(H51[3] - H51[2], DS51[2], DS51[3])) ≈ 0.0513 atol = 1e-4

    # the whole bole by Smalian's method, Table 5.1 (the sum of the volumes of the sections of the book, 0.3191 m³)
    @test ustrip(u"m^3", smalian(H51, D51)) ≈ ustrip(u"m^3", bookvolume(Smalian, H51, G51)) atol = 1e-3
    @test_throws DimensionMismatch smalian(H51, D51[1:8])


    # Hohenadl, Table 5.4: v = (H / 10) Σg = 1.58 · 0.2000 = 0.3160 m³ (0.3135 m³ with the diameter as printed, see above)
    @test ustrip(u"m^3", cubage(Huber, HBOLE, D54).vm[1]) ≈ 1.58 * sum(ustrip.(G54)) atol = 3e-3
    @test ustrip(u"m^3", cubage(Huber, HBOLE, [24.4u"cm"; D54[2:end]]).vm[1]) ≈ 1.58 * sum(ustrip.(G54)) atol = 1e-3
    @test ustrip(u"m^3", cubage(Huber, HBOLE, [21.0, 17.5, 16.9, 16.3, 15.7, 14.0, 10.1, 7.1, 5.0, 1.3]u"cm").vm[1]) ≈ 1.58 * sum(ustrip.(GS54)) atol = 1e-3
    @test_throws DomainError cubage(Huber, 0.0u"m", D54)
    @test_throws ArgumentError cubage(Huber, HBOLE, typeof(D54)())
  end

  @testset "Form factors" begin
    # the tree of Table 5.1, with the volume of Smalian's method, up to 15.3 m 
    v = smalian(H51, D51)

    @test artificialformfactor(v, HTOTAL, DBH) ≈ ustrip(NoUnits, v / (π / 4 * DBH^2 * HTOTAL)) atol = 1e-9

    # lengths must carry units: a plain number is an error, not an assumed unit
    @test_throws MethodError artificialformfactor(0.3191, 16.0, 22.3)
  end

  @testset "Cubage: volume of the measured sections" begin
    # Smalian: every measurement is the end of a section; the stump and the tip are not measured
    r = cubage(Smalian, H51, D51)
    @test isa(r, DataFrame)
    @test names(r) == ["vm"]
    @test r.vm[1] ≈ smalian(H51, D51)
    @test ustrip(u"m^3", r.vm[1]) ≈ ustrip(u"m^3", bookvolume(Smalian, H51, G51)) atol = 1e-3

    # the same with the diameters without bark of the book
    @test ustrip(u"m^3", cubage(Smalian, H51, DS51).vm[1]) ≈ ustrip(u"m^3", bookvolume(Smalian, H51, GS51)) atol = 1e-3

    # a zero diameter is taken as measured: nothing is dropped or interpolated here
    @test cubage(Smalian, [H51; HTOTAL], [D51; 0.0u"cm"]).vm[1] ≈ smalian([H51; HTOTAL], [D51; 0.0u"cm"])

    # Huber: the middles of the sections (the limits are only heights), Tables 5.2 and 5.3
    rh = cubage(Huber, H53, D53)
    @test ustrip(u"m^3", rh.vm[1]) ≈ ustrip(u"m^3", bookvolume(Huber, H53, G53)) atol = 1e-3
    @test ustrip(u"m^3", cubage(Huber, H53, DS53).vm[1]) ≈ ustrip(u"m^3", bookvolume(Huber, H53, GS53)) atol = 1e-3
    @test rh.vm[1] ≈ huber(1.2u"m", D53[2]) + sum(huber(2.0u"m", D53[j]) for j in 4:2:16)
    limits_changed = copy(D53)
    limits_changed[3:2:15] .= 99.0u"cm"
    @test cubage(Huber, H53, limits_changed).vm[1] ≈ rh.vm[1]   # the limits in between are not used

    # Newton: the ends and the middle of each section
    rn = cubage(Newton, H53, D53)
    @test ustrip(u"m^3", rn.vm[1]) ≈ ustrip(u"m^3", bookvolume(Newton, H53, G53)) atol = 1e-3
    @test ustrip(u"m^3", cubage(Newton, H53, DS53).vm[1]) ≈ ustrip(u"m^3", bookvolume(Newton, H53, GS53)) atol = 1e-3
    @test rn.vm[1] ≈ newton(1.2u"m", D53[1], D53[2], D53[3]) + sum(newton(2.0u"m", D53[j-1], D53[j], D53[j+1]) for j in 4:2:16)

    # Huber and Newton need the limit, middle, ..., limit layout
    @test_throws ArgumentError cubage(Huber, H53[1:16], D53[1:16])
    @test_throws ArgumentError cubage(Newton, H53[1:2], D53[1:2])

    # at least two measurements, with the same length, and with units
    @test_throws ArgumentError cubage(Smalian, H51[1:1], D51[1:1])
    @test_throws DimensionMismatch cubage(Smalian, H51, D51[1:8])
    @test_throws MethodError cubage(Smalian, ustrip.(H51), ustrip.(D51))

    # imperial diameters keep results in cubic feet
    @test unit(cubage(Smalian, uconvert.(u"ft", H51), uconvert.(u"inch", D51)).vm[1]) == u"ft^3"

    # many trees stacked in the same vectors: the tree with bark and the tree without bark of the tables
    ids = repeat([1, 2], inner=9)
    stacked = cubage(Smalian, [H51; H51], [D51; DS51]; id=ids)
    @test names(stacked) == ["id", "vm"]
    @test stacked.id == [1, 2]
    @test stacked.vm[1] ≈ smalian(H51, D51)
    @test stacked.vm[2] ≈ smalian(H51, DS51)
    @test_throws DimensionMismatch cubage(Smalian, [H51; H51], [D51; DS51]; id=ids[1:9])
  end

  @testset "Cubage: bark" begin
    r = cubage(Smalian, H51, D51, E51)
    @test names(r) == ["vm", "vms", "vb", "kb", "pb"]
    @test r.vm[1] ≈ cubage(Smalian, H51, D51).vm[1]
    # the diameter without bark is d - 2E: the volume without bark is the volume of the profile of the book without bark
    @test r.vms[1] ≈ cubage(Smalian, H51, DS51).vm[1]
    @test ustrip(u"m^3", r.vms[1]) ≈ ustrip(u"m^3", bookvolume(Smalian, H51, GS51)) atol = 1e-3
    @test r.vb[1] ≈ r.vm[1] - r.vms[1]
    @test r.kb[1] ≈ 1 - 2 * sum(ustrip.(E51)) / sum(ustrip.(D51))
    @test r.kb[1] ≈ barkfactor(D51, E51)
    @test r.pb[1] ≈ 100 * ustrip(NoUnits, r.vb[1] / r.vm[1])
    @test r.pb[1] ≈ barkpercentage(r.vm[1], r.vms[1])
    # with the volumes of the book (Table 5.1), the bark is a quarter of the volume with bark
    @test r.pb[1] ≈ 100 * (1 - ustrip(bookvolume(Smalian, H51, GS51)) / ustrip(bookvolume(Smalian, H51, G51))) atol = 0.5

    # Huber measures the diameters of the first limit, of the middles and of the last limit: only those enter the bark factor
    E53 = (D53 .- DS53) ./ 2
    used = [1; 2:2:16; 17]
    @test cubage(Huber, H53, D53, E53).kb[1] ≈ 1 - 2 * sum(ustrip.(E53[used])) / sum(ustrip.(D53[used]))
    @test cubage(Huber, H53, D53, E53).vms[1] ≈ cubage(Huber, H53, DS53).vm[1]
    @test cubage(Newton, H53, D53, E53).vms[1] ≈ cubage(Newton, H53, DS53).vm[1]

    # a bark thickness whose double exceeds the diameter is rejected
    @test_throws DomainError cubage(Smalian, H51, D51, [20.0u"cm"; E51[2:end]])
    @test_throws DimensionMismatch cubage(Smalian, H51, D51, E51[1:8])

    # stacked trees
    ids = repeat([1, 2], inner=9)
    stacked = cubage(Smalian, [H51; H51], [D51; D51], [E51; E51]; id=ids)
    @test names(stacked) == ["id", "vm", "vms", "vb", "kb", "pb"]
    @test stacked.vms[2] ≈ r.vms[1]
    @test stacked.pb[2] ≈ r.pb[1]
  end

  @testset "Relative method: equal sections of a log" begin
    # Smalian with equal sections, Table 5.1: v2 to v8 are 7 sections of 2 m, from 1.3 m to 15.3 m (0.2598 m³ in the book)
    d_equal = D51[2:end]
    v28 = smalian(14.0u"m", d_equal)
    @test ustrip(u"m^3", v28) ≈ 0.2598 atol = 1e-3
    @test v28 ≈ smalian(H51[2:end], d_equal)                        # the same as with the heights of the measurements
    @test ustrip(u"m^3", v28) ≈ ustrip(u"m^3", cubage(Smalian, H51[2:end], d_equal).vm[1])
    # the generic formula of the book: l [(g1 + gn) / 2 + g2 + ... + g(n-1)]
    @test ustrip(u"m^3", v28) ≈ 2.0 * ((0.0391 + 0.0001) / 2 + sum([0.0324, 0.0278, 0.0241, 0.0161, 0.0071, 0.0028])) atol = 1e-3

    # a log is a log: only its length and the diameters in order matter, not the positions
    @test smalian(14.0u"m", d_equal) ≈ smalian(1400.0u"cm", d_equal)
    @test_throws DomainError smalian(0.0u"m", d_equal)
    @test_throws ArgumentError smalian(14.0u"m", d_equal[1:1])

    # without bark, and the bark of the log, with the thickness of the bark: ds = d - 2E
    ds_equal = DS51[2:end]
    e_equal = E51[2:end]
    vs = smalian(14.0u"m", d_equal .- 2 .* e_equal)
    @test vs ≈ smalian(14.0u"m", ds_equal)
    @test barkpercentage(v28, vs) ≈ 100 * ustrip(NoUnits, (v28 - vs) / v28)

    # many logs: the length of each one and a row of diameters (a log per row, as in the field sheets)
    lengths = [14.0, 14.0]u"m"
    d_rows = [ustrip.(d_equal)'; ustrip.(ds_equal)'] .* u"cm"
    volumes = smalian.(lengths, eachrow(d_rows))
    @test volumes[1] ≈ v28
    @test volumes[2] ≈ vs

    # Hohenadl, Table 5.4: 10 sections of the 15.8 m of bole above the stump, the diameters at their middles
    @test cubage(Huber, HBOLE, D54).vm[1] ≈ HBOLE / 10 * sum(basalarea.(D54))
    ds54 = [21.0, 17.5, 16.9, 16.3, 15.7, 14.0, 10.1, 7.1, 5.0, 1.3]u"cm"
    @test ustrip(u"m^3", cubage(Huber, HBOLE, ds54).vm[1]) ≈ 1.58 * sum(ustrip.(GS54)) atol = 1e-3
    @test cubage(Huber, lengths, [ustrip.(D54)'; ustrip.(ds54)'] .* u"cm").vm[2] ≈ cubage(Huber, 14.0u"m", ds54).vm[1]

    # logs of a field sheet, a log per row: its length and the 11 diameters at 0, 10, ..., 100 % of it
    L = [7.10, 7.67, 7.62]u"m"
    D_sheet = [81.5 74.5 72.9 69.5 67.2 66.2 65.8 64.9 64.9 64.8 65.3;
      67.2 63.7 63.5 62.7 62.0 61.3 61.4 61.7 61.7 59.5 59.4;
      61.1 60.1 60.2 59.8 58.6 58.6 58.3 59.4 58.7 57.7 57.7]u"cm"
    ids = ["A", "B", "C"]
    logs = cubage(Smalian, L, D_sheet)
    @test names(logs) == ["vm"]
    @test nrow(logs) == 3
    @test ustrip.(u"m^3", logs.vm) ≈ [2.620821254, 2.323398672, 2.089479508] atol = 1e-8
    @test cubage(Smalian, L[1], D_sheet[1, :]).vm[1] ≈ logs.vm[1]
    @test logs.vm[1] ≈ smalian(L[1], D_sheet[1, :])

    # the same from a table as it is read from the file: the units are in the headers, the diameters are its columns
    sheet = DataFrame("log" => ids, "l (m)" => [7.10, 7.67, 7.62])
    for j in 1:11
      sheet[!, "d$(j - 1) (cm)"] = ustrip.(u"cm", D_sheet[:, j])
    end
    sheet = parseunits(sheet)
    from_table = cubage(Smalian, sheet.l, sheet[:, 3:end])
    @test from_table.vm ≈ logs.vm
    @test cubage(Smalian, sheet.l, select(sheet, r"^d\d")).vm ≈ logs.vm
    # the logs can be of the same tree or of different ones: the identifiers stay in the table, beside the result
    beside = hcat(select(sheet, :log), from_table)
    @test names(beside) == ["log", "vm"]

    # the method says where the diameters were measured. Huber's, at the middles of equal sections, is Hohenadl's
    D_mid = D_sheet[:, 2:2:10]
    hlogs = cubage(Huber, L, D_mid)
    @test names(hlogs) == ["vm"]
    @test hlogs.vm[1] ≈ cubage(Huber, L[1], D_mid[1, :]).vm[1]
    @test hlogs.vm[1] ≈ L[1] / 5 * sum(basalarea.(D_mid[1, :]))
    @test cubage(Huber, sheet.l, sheet[:, [4, 6, 8, 10, 12]]).vm ≈ hlogs.vm
    # Newton's, limit, middle, limit, ...: with 2 sections, the sum of Newton's of each section
    d_newton = [81.5, 74.5, 72.9, 69.5, 67.2]u"cm"
    @test cubage(Newton, 7.10u"m", d_newton).vm[1] ≈ newton(3.55u"m", d_newton[1], d_newton[2], d_newton[3]) + newton(3.55u"m", d_newton[3], d_newton[4], d_newton[5])
    @test_throws ArgumentError cubage(Newton, 7.10u"m", d_newton[1:4])   # not limit, middle, ..., limit

    # errors: a length per row
    @test_throws DimensionMismatch cubage(Smalian, L[1:2], D_sheet)
    @test_throws DimensionMismatch cubage(Huber, L[1:2], sheet[:, 3:end])
    # lengths and diameters must carry units
    @test_throws MethodError cubage(Smalian, [7.10, 7.67, 7.62], D_sheet)
    @test_throws MethodError cubage(Smalian, L, ustrip.(D_sheet))

    # the heights are an input of `cubage`, which is the absolute method: fractions are not heights
    @test_throws MethodError cubage(Smalian, [0.0, 0.5, 1.0], [27.7, 17.5, 1.2]u"cm")
    @test_throws MethodError cubage(Smalian, [0.0, 0.5, 1.0], [27.7, 17.5, 1.2]u"cm"; H=HBOLE)
  end

  @testset "Tree volume: stump, commercial part and tip" begin
    r = treevolume(Smalian, H51, D51; D=DBH, H=HTOTAL)
    @test isa(r, DataFrame)
    @test names(r) == ["v", "vt", "vm", "vp", "hm", "D", "H", "f"]

    # the stump is a cylinder, the sections are Smalian's, and the tip is a cone above the last measurement
    stump = cylindervolume(H51[1], D51[1])
    cone = conevolume(HTOTAL - H51[end], D51[end])
    @test r.v[1] ≈ stump + smalian(H51, D51) + cone
    @test r.v[1] ≈ r.vt[1] + r.vm[1] + r.vp[1]
    @test r.vt[1] ≈ stump
    # it extends `cubage`: the measured sections are its commercial part when the whole bole is commercial
    @test r.vm[1] ≈ cubage(Smalian, H51, D51).vm[1]
    @test r.vp[1] ≈ cone
    @test r.hm[1] ≈ 15.3u"m"

    # `D` and `H` are the annotated values, never read from the profile: another `D` changes only `f`
    @test r.D[1] == DBH
    @test r.H[1] == HTOTAL
    @test r.f[1] ≈ r.v[1] / (π / 4 * DBH^2 * HTOTAL)
    other = treevolume(Smalian, H51, D51; D=25.0u"cm", H=HTOTAL)
    @test other.v[1] ≈ r.v[1]
    @test other.f[1] ≈ r.f[1] * (22.3 / 25.0)^2

    # no tip when the last measurement is the total height
    atop = treevolume(Smalian, H51, D51; D=DBH, H=15.3u"m")
    @test atop.vp[1] == 0.0u"m^3"
    @test atop.v[1] ≈ stump + smalian(H51, D51)

    # with Smalian, a last diameter of zero is the apex, not a measured section: the tip stays the cone
    withapex = treevolume(Smalian, [H51; HTOTAL], [D51; 0.0u"cm"]; D=DBH, H=HTOTAL)
    @test withapex.v[1] ≈ r.v[1]
    @test withapex.hm[1] ≈ 15.3u"m"
    @test_throws ArgumentError treevolume(Smalian, [0.1, 1.3]u"m", [27.7, 0.0]u"cm"; D=DBH, H=HTOTAL)

    # `D` and `H` are required, and checked
    @test_throws UndefKeywordError treevolume(Smalian, H51, D51; H=HTOTAL)
    @test_throws UndefKeywordError treevolume(Smalian, H51, D51; D=DBH)
    @test_throws DomainError treevolume(Smalian, H51, D51; D=DBH, H=15.0u"m")   # lower than the last measurement
    @test_throws DomainError treevolume(Smalian, H51, D51; D=0.0u"cm", H=HTOTAL)
    @test_throws ArgumentError treevolume(Smalian, H51[1:1], D51[1:1]; D=DBH, H=HTOTAL)

    # lengths must carry units: a plain number is an error, not an assumed unit
    @test_throws MethodError treevolume(Smalian, ustrip.(H51), ustrip.(D51); D=DBH, H=HTOTAL)
    @test_throws Unitful.DimensionError treevolume(Smalian, H51, D51; D=22.3, H=HTOTAL)

    # imperial diameters keep results in cubic feet
    imperial = treevolume(Smalian, uconvert.(u"ft", H51), uconvert.(u"inch", D51); D=uconvert(u"inch", DBH), H=uconvert(u"ft", HTOTAL))
    @test unit(imperial.v[1]) == u"ft^3"
    @test uconvert(u"m^3", imperial.v[1]) ≈ r.v[1]
  end

  @testset "Tree volume: Huber and Newton" begin
    # limit, middle, limit, ..., limit: the sections of Table 5.3 (the first of 1.2 m, then of 2 m)
    stump = cylindervolume(H53[1], D53[1])
    cone = conevolume(HTOTAL - H53[end], D53[end])

    huber_df = treevolume(Huber, H53, D53; D=DBH, H=HTOTAL)
    @test huber_df.v[1] ≈ stump + cubage(Huber, H53, D53).vm[1] + cone
    @test huber_df.vt[1] ≈ stump
    @test huber_df.vp[1] ≈ cone
    @test huber_df.hm[1] ≈ 15.3u"m"
    @test ustrip(u"m^3", huber_df.vm[1]) ≈ ustrip(u"m^3", bookvolume(Huber, H53, G53)) atol = 1e-3

    newton_df = treevolume(Newton, H53, D53; D=DBH, H=HTOTAL)
    @test newton_df.v[1] ≈ stump + cubage(Newton, H53, D53).vm[1] + cone

    # Huber uses the first limit (stump) and the last one (base of the tip), but not the limits in between
    changed = copy(D53)
    changed[3] = 99.0u"cm"
    @test treevolume(Huber, H53, changed; D=DBH, H=HTOTAL).v[1] ≈ huber_df.v[1]
    @test treevolume(Newton, H53, changed; D=DBH, H=HTOTAL).v[1] != newton_df.v[1]

    # the measurements must be limit, middle, ..., limit
    @test_throws ArgumentError treevolume(Huber, H53[1:16], D53[1:16]; D=DBH, H=HTOTAL)
  end

  @testset "Tree volume: the commercial volume is the measured one" begin
    # the measured profile runs up to the commercial height: `vm` is what `cubage` gives, for every method
    for (method, h, d) in ((Smalian, H51, D51), (Huber, H53, D53), (Newton, H53, D53))
      r = treevolume(method, h, d; D=DBH, H=HTOTAL)
      @test r.vm[1] ≈ cubage(method, h, d).vm[1]
      @test r.hm[1] ≈ h[end]
      @test r.vp[1] ≈ conevolume(HTOTAL - h[end], d[end])
      @test r.v[1] ≈ cylindervolume(h[1], d[1]) + r.vm[1] + r.vp[1]
    end
  end

  @testset "Tree volume: the tree of Floriano (2025), Table 2" begin
    # limit, middle, limit, ...: the limits of the sections and the middles in between
    hm = (HF[1:(end-1)] .+ HF[2:end]) ./ 2
    hn = [HF[1]; vec([hm'; HF[2:end]'])]
    dn = [DF[1]; vec([DMF'; DF[2:end]'])]

    # the totals of the book, stump and tip included (the sections of the book have 5 decimals, hence the tolerance)
    smalian_tree = treevolume(Smalian, HF, DF; D=DBHF, H=HTF)
    huber_tree = treevolume(Huber, hn, dn; D=DBHF, H=HTF)
    newton_tree = treevolume(Newton, hn, dn; D=DBHF, H=HTF)
    @test ustrip(u"m^3", smalian_tree.v[1]) ≈ 0.11127 atol = 1e-4
    @test ustrip(u"m^3", huber_tree.v[1]) ≈ 0.10717 atol = 1e-4
    @test ustrip(u"m^3", newton_tree.v[1]) ≈ 0.10854 atol = 1e-4

    # the stump (0.01056 m³, a cylinder of 0.35 m) and the tip (0.00001 m³, a cone of 0.43 m) are the same in the three methods
    for r in (smalian_tree, huber_tree, newton_tree)
      @test ustrip(u"m^3", r.vt[1]) ≈ 0.01056 atol = 1e-5
      @test ustrip(u"m^3", r.vp[1]) ≈ 0.00001 atol = 1e-5
      @test r.v[1] ≈ r.vt[1] + r.vm[1] + r.vp[1]
      @test r.hm[1] ≈ 12.10u"m"
    end

    # the first section, from 0.35 m to 0.95 m, by the three methods (0.01501, 0.01283 and 0.01356 m³ in the book)
    @test ustrip(u"m^3", smalian(0.60u"m", DF[1], DF[2])) ≈ 0.01501 atol = 2e-5
    @test ustrip(u"m^3", huber(0.60u"m", DMF[1])) ≈ 0.01283 atol = 2e-5
    @test ustrip(u"m^3", newton(0.60u"m", DF[1], DMF[1], DF[2])) ≈ 0.01356 atol = 2e-5

    # Newton's is the most precise: Huber's is 1.26 % lower and Smalian's 2.52 % higher (the book)
    @test 100 * ustrip(NoUnits, huber_tree.v[1] / newton_tree.v[1] - 1) ≈ -1.26 atol = 0.05
    @test 100 * ustrip(NoUnits, smalian_tree.v[1] / newton_tree.v[1] - 1) ≈ 2.52 atol = 0.05
  end

  @testset "Tree volume: bark, relative positions, wide layout and many trees" begin
    # bark
    r = treevolume(Smalian, H51, D51, E51; D=DBH, H=HTOTAL)
    @test names(r) == ["v", "vs", "vb", "kb", "vt", "vts", "vm", "vms", "vp", "vps", "hm", "D", "H", "f"]
    @test r.v[1] ≈ r.vt[1] + r.vm[1] + r.vp[1]
    @test r.vs[1] ≈ r.vts[1] + r.vms[1] + r.vps[1]
    @test r.vb[1] ≈ r.v[1] - r.vs[1]
    @test r.v[1] ≈ treevolume(Smalian, H51, D51; D=DBH, H=HTOTAL).v[1]
    @test r.vs[1] ≈ treevolume(Smalian, H51, DS51; D=DBH, H=HTOTAL).v[1]
    @test r.kb[1] ≈ cubage(Smalian, H51, D51, E51).kb[1]
    @test r.vms[1] ≈ cubage(Smalian, H51, D51, E51).vms[1]

    # a last diameter of zero (with its bark) is the apex and is dropped, as without bark
    withapex = treevolume(Smalian, [H51; HTOTAL], [D51; 0.0u"cm"], [E51; 0.0u"cm"]; D=DBH, H=HTOTAL)
    @test withapex.v[1] ≈ r.v[1]
    @test withapex.vs[1] ≈ r.vs[1]
    @test withapex.kb[1] ≈ r.kb[1]

    # a bark thickness whose double exceeds the diameter is rejected
    @test_throws DomainError treevolume(Smalian, H51, D51, [20.0u"cm"; E51[2:end]]; D=DBH, H=HTOTAL)
    @test_throws UndefKeywordError treevolume(Smalian, H51, D51, E51; H=HTOTAL)

    # many trees stacked with `id`: each tree gives the result of the single-tree method
    ids = repeat([1, 2], inner=9)
    h2 = [H51; H51]
    d2 = [D51; DS51]
    D2 = repeat([22.3, 18.9], inner=9) .* u"cm"
    H2 = fill(HTOTAL, 18)
    stacked = treevolume(Smalian, h2, d2; D=D2, H=H2, id=ids)
    @test names(stacked) == ["id", "v", "vt", "vm", "vp", "hm", "D", "H", "f"]
    @test stacked.id == [1, 2]
    @test stacked.v[1] ≈ treevolume(Smalian, H51, D51; D=22.3u"cm", H=HTOTAL).v[1]
    @test stacked.v[2] ≈ treevolume(Smalian, H51, DS51; D=18.9u"cm", H=HTOTAL).v[1]
    with_bark = treevolume(Smalian, h2, d2, [E51; E51]; D=D2, H=H2, id=ids)
    @test names(with_bark)[1:2] == ["id", "v"]
    # `D` and `H` are required, and a vector must have one value per row
    @test_throws UndefKeywordError treevolume(Smalian, h2, d2; H=H2, id=ids)
    @test_throws DimensionMismatch treevolume(Smalian, h2, d2; D=D2[1:9], H=H2, id=ids)
    @test_throws DimensionMismatch treevolume(Smalian, h2, d2; D=D2, H=H2, id=ids[1:9])
  end
end
