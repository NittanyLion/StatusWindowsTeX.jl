# Working on StatusWindowsTeX.jl

A convenience bundle: `using StatusWindowsTeX` is `using StatusWindows,
MathTeXEngine`. The whole package is `src/StatusWindowsTeX.jl`, which
re-exports those two and nothing else.

## Why it is shaped this way

StatusWindows has `math!` as a stub that throws until MathTeXEngine is
loaded; the real method lives in StatusWindows's package extension
`StatusWindowsMathTeXExt`, triggered by MathTeXEngine (and
FreeTypeAbstraction, which MathTeXEngine depends on and therefore brings
along). Julia's extension machinery is one-directional: an extension loads
*when* its triggers are loaded, but nothing in `[weakdeps]` can ever *cause*
a package to load. So "load StatusWindows and get math" cannot be expressed
inside StatusWindows without making MathTeXEngine a strong dependency,
which StatusWindows deliberately does not do: MathTeXEngine is heavy, and
most panels show numbers, not formulas.

This package is the other option: a registered package that strong-depends
on both, so that adding it installs both and loading it loads both, which
fires the extension. The alternative, making MathTeXEngine a strong
dependency of StatusWindows that only its extension imports, was rejected
for the same weight reason, so the bundle is the opt-in.

## Things that will bite you

**Keep it empty.** Any glue between StatusWindows and MathTeXEngine belongs
in StatusWindows's extension, where it works for `using StatusWindows,
MathTeXEngine` as well. Code that only exists here would silently be
missing for those users. If you find yourself adding a function, you are
in the wrong repository.

**This package must never become an extension trigger.** StatusWindows
triggers on `["MathTeXEngine", "FreeTypeAbstraction"]`, not on
StatusWindowsTeX, and any other package wanting StatusWindows+MathTeXEngine
glue should do the same. If something triggered on StatusWindowsTeX instead,
`using StatusWindows, MathTeXEngine` would silently lack the glue even
though both packages are present, and every such package would need to know
this bundle exists. Do not offer it as a trigger and do not accept it as one.

**`[compat]` is the only maintenance.** The `MathTeXEngine` bound here must
stay inside the bound StatusWindows gives it under its own `[compat]`
(currently `0.6.9`), or the resolver will refuse to install the bundle. When
StatusWindows moves, move this. CompatHelper opens the pull requests; read
them against StatusWindows's `Project.toml` before merging.

**FreeTypeAbstraction is not a dependency here, on purpose.** It is one of
the extension's two triggers, but it reaches the session as MathTeXEngine's
own strong dependency. If MathTeXEngine ever dropped it, the extension in
StatusWindows would need rethinking anyway; do not paper over that here.

**The test suite is headless and must stay so.** Tests draw into a bare
Cairo image surface — no window, no GL context — exactly as StatusWindows's
do, and CI runs with no X server. Do not add a test that opens a window.

**Tests reach Cairo through StatusWindows.** `using StatusWindows: Cairo`
rather than `using Cairo`, because Cairo is not a dependency of this
package and must not become one just to be tested with; Aqua's stale-deps
check would object, and rightly.

**The first line of `test/runtests.jl` is the test.** `using
StatusWindowsTeX` has to be the only package `using` that touches
StatusWindows or MathTeXEngine, otherwise the suite no longer proves that
the bundle alone activates the extension.

**There is no `test/Project.toml`.** Test dependencies come from
`[targets] test` in the top-level `Project.toml`; if a stray
`test/Project.toml` appears, delete it.

## Conventions

- American spelling in code, comments and prose.
- Run `julia --project=. -e 'using Pkg; Pkg.test()'`.
- Versions: bump the patch version for compat-only changes; there is
  nothing else to release.
