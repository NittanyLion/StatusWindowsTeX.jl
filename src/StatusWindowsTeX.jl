"""
    StatusWindowsTeX

`using StatusWindowsTeX` is `using StatusWindows, MathTeXEngine` in one line.

StatusWindows keeps MathTeXEngine as a weak dependency, so its `math!` only
works once MathTeXEngine has been loaded as well. This package is the
convenient spelling of that: a strong dependency on both, re-exported, and
nothing else. Loading it loads the two packages, which fires the
`StatusWindowsMathTeXExt` extension in StatusWindows; there is no glue code
here and there must never be any. See `AGENTS.md` for why.
"""
module StatusWindowsTeX

using Reexport

@reexport using StatusWindows
@reexport using MathTeXEngine

end # module
