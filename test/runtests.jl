# Deliberately the only `using` of a package under test: the whole point of
# StatusWindowsTeX is that this one line brings MathTeXEngine along and
# activates StatusWindows's math extension. Nothing below may add a
# `using MathTeXEngine` of its own, or the test would no longer prove that.
using StatusWindowsTeX
using Test
using Aqua

# Cairo is StatusWindows's dependency, not this package's. Reaching it
# through StatusWindows keeps the test target honest about what the bundle
# itself depends on (Aqua checks that).
using StatusWindows: Cairo, Canvas

# Same headless discipline as StatusWindows: draw into a bare image surface,
# never open a window, so this runs on CI with no display at all.
function testcanvas(w = 240, h = 160)
    buf = zeros(UInt32, w, h)
    surface = Cairo.CairoImageSurface(buf, Cairo.FORMAT_ARGB32; flipxy = false)
    return buf, Canvas(Cairo.CairoContext(surface), Style(), w, h)
end

painted(buf) = count(!=(0), buf)

# Public names of a module, minus the module's own name.
exported(m::Module) = filter(!=(nameof(m)), names(m))

@testset "StatusWindowsTeX.jl" begin

    @testset "Aqua" begin
        Aqua.test_all(StatusWindowsTeX)
    end

    @testset "one using loads the chain" begin
        # The reason this package exists: `using StatusWindowsTeX` alone must
        # leave StatusWindows's MathTeXEngine extension loaded.
        @test Base.get_extension(StatusWindows, :StatusWindowsMathTeXExt) !== nothing

        # Both halves are really there, as packages, not just as names.
        @test StatusWindowsTeX.StatusWindows isa Module
        @test StatusWindowsTeX.MathTeXEngine isa Module
        @test isdefined(Main, :MathTeXEngine)     # re-exported, so usable directly

        # StatusWindows promises that loading it touches no window system.
        # Bundling must not quietly break that promise.
        @test !StatusWindows.GLFW.isinitialized()
    end

    @testset "everything is re-exported, and from one place" begin
        for m in (StatusWindows, MathTeXEngine), n in exported(m)
            @test n in names(StatusWindowsTeX)
            @test getfield(StatusWindowsTeX, n) === getfield(m, n)
        end

        # A name exported by both would be ambiguous through the bundle. If
        # this ever fails, one of them has grown a clashing export and the
        # bundle has to stop re-exporting it.
        @test isempty(intersect(exported(StatusWindows), exported(MathTeXEngine)))

        # The names people will actually type.
        @test :Panel in names(StatusWindowsTeX)
        @test :math! in names(StatusWindowsTeX)
        @test :mathwidth in names(StatusWindowsTeX)
        @test Symbol("@L_str") in names(StatusWindowsTeX)

        # The bundle adds no names of its own. Reexport also exports the two
        # module names, so `MathTeXEngine.texparse` works after the one using.
        @test exported(StatusWindowsTeX) ⊆ union(exported(StatusWindows), exported(MathTeXEngine),
                                                  [:StatusWindows, :MathTeXEngine])
    end

    @testset "math! is the real one" begin
        buf, c = testcanvas()
        y, px = c.y, painted(buf)
        math!(c, raw"\frac{\alpha}{\beta} + \sqrt{x^2}")
        @test c.y > y
        @test painted(buf) > px

        # A fraction needs vertical room that a bare symbol does not; the
        # stub would have thrown long before getting here.
        _, c2 = testcanvas()
        tall = let y0 = c2.y; math!(c2, raw"\frac{\alpha}{\beta}"); c2.y - y0 end
        _, c3 = testcanvas()
        flat = let y0 = c3.y; math!(c3, raw"\alpha"); c3.y - y0 end
        @test tall > flat

        @test mathwidth(c, raw"\sum_{i=1}^{n} x_i^2") > mathwidth(c, "x")

        # LaTeXStrings' L"..." rides along with MathTeXEngine, and its
        # `$...$` delimiters are understood.
        _, c4 = testcanvas()
        y4 = c4.y
        @test math!(c4, L"\hat{\beta} = (X^TX)^{-1}X^Ty") === c4
        @test c4.y > y4
        @test mathwidth(c4, L"\frac{1}{2}") ≈ mathwidth(c4, raw"\frac{1}{2}")

        # And the poor man's path is untouched by all this.
        @test poormansmath!(c, "\\sigma^2") === c
    end

    @testset "render to file through the bundle" begin
        mktempdir() do dir
            for ext in ("pdf", "svg", "png")
                path = joinpath(dir, "panel." * ext)
                out = render(path; width = 300, height = 160) do c
                    heading!(c, "estimates")
                    math!(c, raw"\hat{\beta} = (X^TX)^{-1}X^Ty")
                    kv!(c, "n", 1024)
                end
                @test out == path
                @test filesize(path) > 0
            end
        end
    end

    @testset "headless panels stay inert" begin
        # A script written for a desktop must still run to the end on a
        # server when it loads the bundle instead of StatusWindows.
        withenv("DISPLAY" => ":0", "JULIA_GLFW_PLATFORM" => "null") do
            p = @test_logs (:warn, r"JULIA_GLFW_PLATFORM=null") Panel()
            @test !isactive(p)
            @test draw!(c -> math!(c, raw"\alpha"), p) === p
            @test run!(p) === nothing
            @test close(p) === nothing
        end
    end
end
