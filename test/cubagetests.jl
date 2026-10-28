using Test
using Unitful
using DataFrames
using ForestMensuration

# The data of the tests are the tables of the book of Machado & Figueiredo Filho (2003), Chapter 5:
# MACHADO, S. A.; FIGUEIREDO FILHO, A. Dendrometria. Curitiba: Ed. dos Autores, 2003. 309 p.
#
# Tables 5.1 (Smalian), 5.2 (Huber) and 5.3 (Newton) are the same tree. The field columns are the diameters with
# bark (d c/c) and without bark (d s/c) in cm; the office columns are the sectional areas (g c/c and g s/c) in m².

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
const DS54 = [21.0, 17.5, 16.9, 16.3, 15.7, 14.0, 10.1, 7.1, 5.0, 1.3]u"cm"
const G54 = [0.0468, 0.0330, 0.0305, 0.0272, 0.0246, 0.0196, 0.0104, 0.0050, 0.0027, 0.0002]u"m^2"
const GS54 = [0.0346, 0.0241, 0.0224, 0.0209, 0.0194, 0.0154, 0.0080, 0.0040, 0.0020, 0.0001]u"m^2"

# The diameter at breast height (22.3 cm) and the total height (15.9 m) of the tree of 5.1 to 5.3.
const HTOTAL = 15.9u"m"
const DBH = 22.3u"cm"
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

# A field sheet of logs measured at relative positions: the length of each log and its 11 diameters at 0, 10, ..., 100 %
const LSHEET = [7.10, 7.67, 7.62]u"m"
const DSHEET = [81.5 74.5 72.9 69.5 67.2 66.2 65.8 64.9 64.9 64.8 65.3;
  67.2 63.7 63.5 62.7 62.0 61.3 61.4 61.7 61.7 59.5 59.4;
  61.1 60.1 60.2 59.8 58.6 58.6 58.3 59.4 58.7 57.7 57.7]u"cm"

# The volume of the sections by the areas of the office columns, as in the book
booksmalian(h, g) = sum((g[j-1] + g[j]) / 2 * (h[j] - h[j-1]) for j in 2:length(h))

@testset "cubage.jl" begin
  @testset "The tables of the book" begin
    # the office columns of the book are the sectional areas of the field columns, rounded to 4 decimals
    @test all(abs.(ustrip.(u"m^2", sectionalarea.(D51)) .- ustrip.(G51)) .< 5e-5)
    @test all(abs.(ustrip.(u"m^2", sectionalarea.(DS51)) .- ustrip.(GS51)) .< 5e-5)
    @test all(abs.(ustrip.(u"m^2", sectionalarea.(D53)) .- ustrip.(G53)) .< 5e-5)
    @test all(abs.(ustrip.(u"m^2", sectionalarea.(DS53)) .- ustrip.(GS53)) .< 5e-5)
    @test count(abs.(ustrip.(u"m^2", sectionalarea.(D54)) .- ustrip.(G54)) .< 5e-5) == 9   # all but the first, see above
  end

  @testset "Geometry: cylinder and cone" begin
    # the stump of the tree of Table 5.1: 0.1 m high with 27.7 cm of diameter, g = 0.0603 m²
    @test ustrip(u"m^3", cylindervolume(0.1u"m", 27.7u"cm")) ≈ 0.00603 atol = 1e-4
    # the tip, a cone with the last diameter, 1.2 cm, up to the total height of 15.9 m
    @test conevolume(0.6u"m", 1.2u"cm") ≈ cylindervolume(0.6u"m", 1.2u"cm") / 3
    @test ustrip(u"m^3", conevolume(0.6u"m", 1.2u"cm")) ≈ 0.0001 * 0.6 / 3 atol = 1e-5

    # zero is a legitimate stump height / tip diameter, not a domain error
    @test cylindervolume(0.0u"m", D51[1]) == 0.0u"m^3"
    @test conevolume(1.0u"m", 0.0u"cm") == 0.0u"m^3"
    @test_throws DomainError cylindervolume(-1.0u"m", D51[1])
    @test_throws DomainError conevolume(1.0u"m", -1.0u"cm")
    # the height decides the system of the volume
    @test unit(cylindervolume(1.0u"ft", 30.0u"cm")) == u"ft^3"
    @test unit(conevolume(1.0u"m", 12.0u"inch")) == u"m^3"
  end

  @testset "A section: Smalian, Huber and Newton" begin
    # the first section of the tree of Tables 5.1 to 5.3, from 0.1 m to 1.3 m: l = 1.2 m
    @test ustrip(u"m^3", smalian(1.2u"m", 27.7u"cm", 22.3u"cm")) ≈ (0.0603 + 0.0391) / 2 * 1.2 atol = 1e-4
    # Huber, Table 5.2: v1 = g(0.7) · l1 = 0.0483 · 1.2 = 0.0580 m³; the second section, v2 = 0.0337 · 2 = 0.0674 m³
    @test ustrip(u"m^3", huber(1.2u"m", 24.8u"cm")) ≈ 0.0580 atol = 1e-4
    @test ustrip(u"m^3", huber(2.0u"m", 20.7u"cm")) ≈ 0.0674 atol = 2e-4
    @test ustrip(u"m^3", newton(1.2u"m", 27.7u"cm", 24.8u"cm", 22.3u"cm")) ≈ (0.0603 + 4 * 0.0483 + 0.0391) / 6 * 1.2 atol = 1e-4
    @test_throws DomainError smalian(-1.2u"m", 27.7u"cm", 22.3u"cm")
    @test_throws DomainError huber(0.0u"m", 24.8u"cm")
    @test_throws DomainError newton(-1.2u"m", 27.7u"cm", 24.8u"cm", 22.3u"cm")

    # units: the result is coherent (m^3), whatever the units of the length and the diameters
    @test unit(smalian(120.0u"cm", 27.7u"cm", 22.3u"cm")) == u"m^3"
    @test smalian(120.0u"cm", 277.0u"mm", 22.3u"cm") ≈ smalian(1.2u"m", 27.7u"cm", 22.3u"cm")
    @test huber(1200.0u"mm", 24.8u"cm") ≈ huber(1.2u"m", 24.8u"cm")
    # the length of the log decides the system of the volume
    @test unit(newton(4.0u"ft", 27.7u"cm", 24.8u"cm", 22.3u"cm")) == u"ft^3"
    @test unit(smalian(1.2u"m", 11.0u"inch", 9.0u"inch")) == u"m^3"
    # imperial diameters give cubic feet
    @test unit(smalian(4.0u"ft", 11.0u"inch", 9.0u"inch")) == u"ft^3"
    @test unit(huber(4.0u"ft", 10.0u"inch")) == u"ft^3"
    @test unit(newton(4.0u"ft", 11.0u"inch", 10.0u"inch", 9.0u"inch")) == u"ft^3"

    # the first section of the tree of Floriano (2025), from 0.35 m to 0.95 m (0.01501, 0.01283 and 0.01356 m³ in the book)
    @test ustrip(u"m^3", smalian(0.60u"m", DF[1], DF[2])) ≈ 0.01501 atol = 2e-5
    @test ustrip(u"m^3", huber(0.60u"m", DMF[1])) ≈ 0.01283 atol = 2e-5
    @test ustrip(u"m^3", newton(0.60u"m", DF[1], DMF[1], DF[2])) ≈ 0.01356 atol = 2e-5
  end

  @testset "Smalian with absolute heights" begin
    # every section of Table 5.1 against the values printed in the book (areas rounded to 4 decimals, hence the tolerance)
    book_sections = [0.0596, 0.0715, 0.0602, 0.0519, 0.0402, 0.0232, 0.0099, 0.0029]
    sections = [ustrip(u"m^3", smalian(H51[j] - H51[j-1], D51[j-1], D51[j])) for j in 2:9]
    @test all(abs.(sections .- book_sections) .< 2e-4)

    # the measured bole is the sum of its sections (0.3191 m³ in the book), with and without bark
    @test smalian(H51, D51) ≈ sum(smalian(H51[j] - H51[j-1], D51[j-1], D51[j]) for j in 2:9)
    @test ustrip(u"m^3", smalian(H51, D51)) ≈ ustrip(u"m^3", booksmalian(H51, G51)) atol = 1e-3
    @test ustrip(u"m^3", smalian(H51, DS51)) ≈ ustrip(u"m^3", booksmalian(H51, GS51)) atol = 1e-3

    @test_throws DimensionMismatch smalian(H51, D51[1:8])
    @test_throws ArgumentError smalian(H51[1:1], D51[1:1])
    @test_throws MethodError smalian(ustrip.(H51), ustrip.(D51))
  end

  @testset "Relative positions: Smalian" begin
    # Table 5.1: v2 to v8 are 7 sections of 2 m, from 1.3 m to 15.3 m (0.2598 m³ in the book)
    d_equal = D51[2:end]
    v28 = smalian(14.0u"m", d_equal)
    @test ustrip(u"m^3", v28) ≈ 0.2598 atol = 1e-3
    @test v28 ≈ smalian(H51[2:end], d_equal)    # the same as with the heights of the measurements
    # the formula of the book: l [(g1 + gn) / 2 + g2 + ... + g(n-1)]
    @test ustrip(u"m^3", v28) ≈ 2.0 * ((0.0391 + 0.0001) / 2 + sum([0.0324, 0.0278, 0.0241, 0.0161, 0.0071, 0.0028])) atol = 1e-3

    # two diameters are a single section
    @test smalian(1.2u"m", [27.7, 22.3]u"cm") ≈ smalian(1.2u"m", 27.7u"cm", 22.3u"cm")
    # only the length of the log matters, in any unit
    @test smalian(14.0u"m", d_equal) ≈ smalian(1400.0u"cm", d_equal)
    @test_throws DomainError smalian(0.0u"m", d_equal)
    @test_throws ArgumentError smalian(14.0u"m", d_equal[1:1])

    # the field sheet, a log per row: the volume of each log
    volumes = smalian(LSHEET, DSHEET)
    @test volumes isa AbstractVector
    @test ustrip.(u"m^3", volumes) ≈ [2.620821254, 2.323398672, 2.089479508] atol = 1e-8
    @test volumes[2] ≈ smalian(LSHEET[2], DSHEET[2, :])

    # the same from a table as it is read from the file: the units in the headers, the diameters are its columns
    sheet = DataFrame("log" => ["1A", "1B", "1C"], "l (m)" => ustrip.(LSHEET))
    for j in 1:11
      sheet[!, "d$(10 * (j - 1)) (cm)"] = ustrip.(u"cm", DSHEET[:, j])
    end
    sheet = parseunits(sheet)
    sheet.vm = smalian(sheet.l, Matrix(sheet[:, r"^d"]))
    @test sheet.vm ≈ volumes

    # a length per row, and units
    @test_throws DimensionMismatch smalian(LSHEET[1:2], DSHEET)
    @test_throws MethodError smalian([7.10, 7.67, 7.62], DSHEET)
    @test_throws MethodError smalian(LSHEET, ustrip.(DSHEET))
    @test unit(smalian(uconvert(u"ft", 14.0u"m"), uconvert.(u"inch", d_equal))) == u"ft^3"
  end

  @testset "Relative positions: Huber (Hohenadl)" begin
    # Table 5.4: v = (H / 10) Σg = 1.58 · 0.2000 = 0.3160 m³ (0.3135 m³ with the diameter as printed, see above)
    @test huber(HBOLE, D54) ≈ HBOLE / 10 * sum(sectionalarea.(D54))
    @test ustrip(u"m^3", huber(HBOLE, D54)) ≈ 1.58 * sum(ustrip.(G54)) atol = 3e-3
    @test ustrip(u"m^3", huber(HBOLE, [24.4u"cm"; D54[2:end]])) ≈ 1.58 * sum(ustrip.(G54)) atol = 1e-3
    @test ustrip(u"m^3", huber(HBOLE, DS54)) ≈ 1.58 * sum(ustrip.(GS54)) atol = 1e-3

    # one diameter is a single section
    @test huber(1.2u"m", [24.8u"cm"]) ≈ huber(1.2u"m", 24.8u"cm")
    @test_throws DomainError huber(0.0u"m", D54)
    @test_throws ArgumentError huber(HBOLE, typeof(D54)())

    # the field sheet: the diameters at 10, 30, 50, 70 and 90 % are the middles of 5 sections
    d_middles = DSHEET[:, 2:2:10]
    volumes = huber(LSHEET, d_middles)
    @test volumes[1] ≈ LSHEET[1] / 5 * sum(sectionalarea.(d_middles[1, :]))
    @test volumes[3] ≈ huber(LSHEET[3], d_middles[3, :])
    @test_throws DimensionMismatch huber(LSHEET[1:2], d_middles)
  end

  @testset "Form factor and bark" begin
    v = 0.325118u"m^3"
    @test artificialformfactor(v, HTOTAL, DBH) ≈ ustrip(NoUnits, v / (π / 4 * DBH^2 * HTOTAL))
    @test artificialformfactor(v, HTOTAL, DBH) ≈ 0.5235332664111264
    @test_throws DomainError artificialformfactor(0.0u"m^3", HTOTAL, DBH)
    @test_throws MethodError artificialformfactor(0.3191, 16.0, 22.3)

    # k_b = 1 - 2 ΣE / Σd = Σds / Σd, with the diameters of Table 5.1
    @test barkfactor(D51, E51) ≈ sum(ustrip.(DS51)) / sum(ustrip.(D51))
    @test barkfactor(D51, E51) ≈ 0.8684593023255813
    @test barkfactor(D51, uconvert.(u"mm", E51)) ≈ barkfactor(D51, E51)
    # a zero diameter (tip of the tree) is valid; only negative diameters, or all-zero ones, are errors
    @test barkfactor([D51; 0.0u"cm"], [E51; 0.0u"cm"]) ≈ barkfactor(D51, E51)
    @test_throws DomainError barkfactor([-D51[1]; D51[2:end]], E51)
    @test_throws DomainError barkfactor([0.0, 0.0]u"cm", [0.0, 0.0]u"cm")
    @test_throws DomainError barkfactor(D51, [-E51[1]; E51[2:end]])
    @test_throws DimensionMismatch barkfactor(D51, E51[1:8])

    # p_b = 100 (v - vs) / v; volumes in different units are compared correctly
    @test barkpercentage(0.319069u"m^3", 0.240002u"m^3") ≈ 24.7805 atol = 1e-3
    @test barkpercentage(319.069u"dm^3", 0.240002u"m^3") ≈ barkpercentage(0.319069u"m^3", 0.240002u"m^3")
    @test barkpercentage(0.3u"m^3", 0.3u"m^3") == 0.0
    @test barkpercentage(0.3u"m^3", 0.0u"m^3") == 100.0
    @test_throws DomainError barkpercentage(0.0u"m^3", 0.0u"m^3")
    @test_throws DomainError barkpercentage(0.3u"m^3", 0.4u"m^3")
    @test_throws DomainError barkpercentage(0.3u"m^3", -0.1u"m^3")
  end

  @testset "Cubage of a tree" begin
    r = cubage(HTOTAL, DBH, H51, D51)
    @test r isa DataFrame
    @test names(r) == ["v", "vt", "vm", "vp", "H", "D", "f"]

    # the stump is a cylinder, the sections are Smalian's, and the tip is a cone above the last measurement
    stump = cylindervolume(H51[1], D51[1])
    cone = conevolume(HTOTAL - H51[end], D51[end])
    @test r.vt[1] ≈ stump
    @test r.vm[1] ≈ smalian(H51, D51)
    @test r.vp[1] ≈ cone
    @test r.v[1] ≈ r.vt[1] + r.vm[1] + r.vp[1]
    # the book: the sections plus the tip, 0.31942 m³ (the stump is left out)
    @test ustrip(u"m^3", r.vm[1] + r.vp[1]) ≈ 0.31942 atol = 5e-4

    # `D` and `H` are the annotated values: another `D` changes only `f`
    @test r.D[1] == DBH
    @test r.H[1] == HTOTAL
    @test r.f[1] ≈ artificialformfactor(r.v[1], HTOTAL, DBH)
    other = cubage(HTOTAL, 25.0u"cm", H51, D51)
    @test other.v[1] ≈ r.v[1]
    @test other.f[1] ≈ r.f[1] * (22.3 / 25.0)^2

    # no tip when the last measurement is the total height
    atop = cubage(15.3u"m", DBH, H51, D51)
    @test atop.vp[1] == 0.0u"m^3"
    @test atop.v[1] ≈ stump + smalian(H51, D51)

    # the tree of Floriano (2025), Table 2: the book total by Smalian, 0.11127 m³, with the stump (0.01056 m³) and the tip (0.00001 m³)
    floriano = cubage(HTF, DBHF, HF, DF)
    @test ustrip(u"m^3", floriano.v[1]) ≈ 0.11127 atol = 1e-4
    @test ustrip(u"m^3", floriano.vt[1]) ≈ 0.01056 atol = 1e-5
    @test ustrip(u"m^3", floriano.vp[1]) ≈ 0.00001 atol = 1e-5
    # with the same stump and tip, the sections by Huber's and Newton's formulas give the other totals of the book
    vh = floriano.vt[1] + sum(huber(HF[j] - HF[j-1], DMF[j-1]) for j in 2:length(HF)) + floriano.vp[1]
    vn = floriano.vt[1] + sum(newton(HF[j] - HF[j-1], DF[j-1], DMF[j-1], DF[j]) for j in 2:length(HF)) + floriano.vp[1]
    @test ustrip(u"m^3", vh) ≈ 0.10717 atol = 1e-4
    @test ustrip(u"m^3", vn) ≈ 0.10854 atol = 1e-4

    # errors: the total height below the last measurement, a zero diameter at breast height, plain numbers
    @test_throws DomainError cubage(15.0u"m", DBH, H51, D51)
    @test_throws DomainError cubage(HTOTAL, 0.0u"cm", H51, D51)
    @test_throws DimensionMismatch cubage(HTOTAL, DBH, H51, D51[1:8])
    @test_throws ArgumentError cubage(HTOTAL, DBH, H51[1:1], D51[1:1])
    @test_throws MethodError cubage(15.9, 22.3, ustrip.(H51), ustrip.(D51))

    # imperial measurements give cubic feet
    imperial = cubage(uconvert(u"ft", HTOTAL), uconvert(u"inch", DBH), uconvert.(u"ft", H51), uconvert.(u"inch", D51))
    @test unit(imperial.v[1]) == u"ft^3"
    @test uconvert(u"m^3", imperial.v[1]) ≈ r.v[1]
  end

  @testset "Cubage of a tree with bark" begin
    r = cubage(HTOTAL, DBH, H51, D51, E51)
    # first the columns with bark, then the same volumes without bark, then the bark
    @test names(r) == ["v", "vt", "vm", "vp", "H", "D", "f", "vs", "vts", "vms", "vps", "vb", "kb", "pb"]
    @test r[:, 1:7] == cubage(HTOTAL, DBH, H51, D51)

    # without bark, the diameters are d - 2E: the profile of the book without bark
    withoutbark = cubage(HTOTAL, DBH, H51, DS51)
    @test r.vs[1] ≈ withoutbark.v[1]
    @test r.vts[1] ≈ withoutbark.vt[1]
    @test r.vms[1] ≈ withoutbark.vm[1]
    @test r.vps[1] ≈ withoutbark.vp[1]
    @test r.vs[1] ≈ r.vts[1] + r.vms[1] + r.vps[1]
    @test ustrip(u"m^3", r.vms[1]) ≈ ustrip(u"m^3", booksmalian(H51, GS51)) atol = 1e-3

    @test r.vb[1] ≈ r.v[1] - r.vs[1]
    @test r.kb[1] ≈ barkfactor(D51, E51)
    @test r.pb[1] ≈ barkpercentage(r.v[1], r.vs[1])

    # a bark thickness whose double exceeds the diameter is rejected, and a thickness per measurement is required
    @test_throws DomainError cubage(HTOTAL, DBH, H51, D51, [20.0u"cm"; E51[2:end]])
    @test_throws DimensionMismatch cubage(HTOTAL, DBH, H51, D51, E51[1:8])
  end

  @testset "Cubage with H and D repeated in the rows of the tree" begin
    Hrows = fill(HTOTAL, 9)
    Drows = fill(DBH, 9)
    @test cubage(Hrows, Drows, H51, D51) == cubage(HTOTAL, DBH, H51, D51)
    @test cubage(Hrows, Drows, H51, D51, E51) == cubage(HTOTAL, DBH, H51, D51, E51)
    # the same value in every row: a different one is an error of the table
    wrong = copy(Hrows)
    wrong[4] = 19.5u"m"
    @test_throws ArgumentError cubage(wrong, Drows, H51, D51)
    @test_throws ArgumentError cubage(Hrows, [Drows[1:8]; 25.0u"cm"], H51, D51, E51)
  end

  @testset "Cubage of many trees with id" begin
    # the tree of Table 5.1 (A) and the tree of Floriano (2025) (B), a row per measurement
    trees = vcat(
      DataFrame(tree="A", h=H51, d=D51, E=E51, D=DBH, H=HTOTAL),
      DataFrame(tree="B", h=HF, d=DF, E=DF ./ 20, D=DBHF, H=HTF))
    r = cubage(trees.tree, trees.H, trees.D, trees.h, trees.d)
    @test names(r) == ["id", "v", "vt", "vm", "vp", "H", "D", "f"]
    @test r.id == ["A", "B"]
    @test r[1, Not(:id)] == cubage(HTOTAL, DBH, H51, D51)[1, :]
    @test r[2, Not(:id)] == cubage(HTF, DBHF, HF, DF)[1, :]

    rb = cubage(trees.tree, trees.H, trees.D, trees.h, trees.d, trees.E)
    @test names(rb) == ["id"; names(cubage(HTOTAL, DBH, H51, D51, E51))]
    @test rb[1, Not(:id)] == cubage(HTOTAL, DBH, H51, D51, E51)[1, :]
    @test rb.v == r.v

    # the trees stay in the order in which they first appear
    swapped = vcat(trees[trees.tree.=="B", :], trees[trees.tree.=="A", :])
    @test cubage(swapped.tree, swapped.H, swapped.D, swapped.h, swapped.d).id == ["B", "A"]

    # every vector with a value per row, and H and D the same in every row of a tree
    @test_throws DimensionMismatch cubage(trees.tree[1:9], trees.H, trees.D, trees.h, trees.d)
    wrong = copy(trees.H)
    wrong[2] = 19.5u"m"
    @test_throws ArgumentError cubage(trees.tree, wrong, trees.D, trees.h, trees.d)
  end
end
