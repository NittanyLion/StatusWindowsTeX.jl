# StatusWindowsTeX.jl

[![Build Status](https://github.com/NittanyLion/StatusWindowsTeX.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/NittanyLion/StatusWindowsTeX.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
![authored by: JP](authored_by.svg)

[StatusWindows.jl](https://github.com/NittanyLion/StatusWindows.jl) with
real TeX math, in one `using`.

```julia
using StatusWindowsTeX

p = Panel(width = 280, height = 200, x = 60, y = 60)

draw!(p) do c
    heading!(c, "estimates")
    math!(c, raw"\hat{\beta} = (X^TX)^{-1}X^Ty")
    math!(c, L"\frac{\alpha}{\beta} + \sqrt{x^2}")
    math!(c, raw"\sum_{i=1}^{n} x_i^2")
end

run!(p, refresh = 1.0)
```

That is the whole package. `using StatusWindowsTeX` does exactly what

```julia
using StatusWindows, MathTeXEngine
```

does, and nothing more: every name either of those exports is re-exported
here, and there is no code of its own.


## Why it exists

StatusWindows can typeset real TeX — fractions, radicals, limits stacked
over big operators — through
[MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl). But
MathTeXEngine is a **weak dependency** of StatusWindows: installing
StatusWindows does not install it, and `math!` throws a helpful error until
you load it yourself. That keeps StatusWindows light for people who only
want a panel of numbers, at the price of one extra line for everyone who
wants math.

This package is that line, made installable. Add it and you get both
packages, version-resolved together; load it and both are loaded, which is
what activates StatusWindows's `StatusWindowsMathTeXExt` extension and turns
`math!` into the real thing. The extension triggers on the two packages, not
on this one, so `using StatusWindows, MathTeXEngine` keeps working for
anyone who has never heard of StatusWindowsTeX.

Because MathTeXEngine is re-exported too, its own API is available as well —
`L"..."` from LaTeXStrings, `texparse`, `generate_tex_elements` and the
rest — should you want to go below `math!`.


## What is *not* here

Everything about panels, widgets, colors, styling, printing to files and
headless machines is documented in
[StatusWindows.jl](https://NittanyLion.github.io/StatusWindows.jl/stable/);
this package changes none of it. In particular the headless story is
unchanged: `using StatusWindowsTeX` touches no window system, and a script
that lands on a server gets an inert panel and runs to the end.


## Installation

```julia
using Pkg
Pkg.add("StatusWindowsTeX")
```

Requires Julia 1.10 or later, like StatusWindows itself.


## Disclaimer

This package was written with significant assistance from Claude.
