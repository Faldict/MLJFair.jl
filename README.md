# MLJFair

[MLJFair](https://github.com/ashryaagr/MLJFair.jl) is a bias audit and mitigation toolkit in julia and is supported by MLJ Ecosystem.
It is being developed as a part of JSOC 2020 Program sponsored by JuliaComputing.

# Installation
```julia
julia> Pkg.add("https://github.com/ashryaagr/MLJFair.jl")
```

# Components
It shall be divided into following components
- FairTensor
- Measures [WIP]
  - CalcMetrics
  - BoolMetrics
- Algorithms [Shall be implemented after Measures]
  - Preprocessing Algorithms
  - InProcessing Algorithms
  - PostProcessing Algorithms

It currently has only fairness metrics[WIP].

# Getting Started
- [Examples and tutorials](https://github.com/ashryaagr/MLJFair.jl/tree/master/examples) are a good starting point.
- Documentation is also available for this package.
