# MLJFair

[![Build Status](https://travis-ci.com/ashryaagr/MLJFair.jl.svg?branch=master)](https://travis-ci.com/ashryaagr/MLJFair.jl)
[![Coverage Status](https://coveralls.io/repos/github/ashryaagr/MLJFair.jl/badge.svg)](https://coveralls.io/github/ashryaagr/MLJFair.jl)
<a href="https://slackinvite.julialang.org/">
  <img src="https://img.shields.io/badge/chat-on%20slack-orange.svg"
       alt="#mlj">
</a>
<a href="https://www.ashrya.in/MLJFair.jl/dev/">
  <img src="https://img.shields.io/badge/docs-stable-blue.svg"
       alt="Documentation">
</a>

[MLJFair](https://github.com/ashryaagr/MLJFair.jl) is a comprehensive bias audit and mitigation toolkit in julia. Extensive support and functionality provided by [MLJ](https://github.com/alan-turing-institute/MLJ.jl) has been used in this package.

# Installation
```julia
using Pkg
Pkg.activate("my_environment", shared=true)
Pkg.add("https://github.com/ashryaagr/MLJFair.jl")
Pkg.add("MLJ")
```

# What MLJFair offers over its alternatives?
- As of writing, it is the only bias audit and mitigation toolkit to support data with multi-valued protected attribute. For eg. If the protected attribute, say race has more than 2 values: "Asian", "African", "American"..so on, then MLJFair can easily handle it with normal workflow.
- Due to the support for multi-valued protected attribute, intersectional fairness can also be dealt with this toolkit. For eg. If the data has 2 protected attributes, say race and gender, then MLJFair can be used to handle it by combining the attributes like "female_american", "male_asian"...so on.
- Extensive support and functionality provided by [MLJ](https://github.com/alan-turing-institute/MLJ.jl) can be leveraged when using MLJFair.
- Tuning of models using MLJTuning from MLJ. Numerious ML models from MLJModels can be used together with MLJFair.
- It leverages the flexibility and speed of Julia to make it more efficient and easy-to-use at the same time
- Well structured and intutive design
- Extensive tests and Documentation

# Getting Started

- [Documentation](https://www.ashrya.in/MLJFair.jl/dev) is a good starting point for this package.
- To understand MLJFair, it is recommended that the user goes through the [MLJ Documentation](https://alan-turing-institute.github.io/MLJ.jl/stable/). It shall help the user in understanding the usage of machine, evaluate, etc.

# Example
Following is an introductory example of using MLJFair. Observe how easy it has become to measure and mitigate bias in Machine Learning algorithms.
```julia
using MLJFair, MLJ
X, y, ŷ = @load_toydata

julia> model = ConstantClassifier()
ConstantClassifier() @904

julia> wrappedModel = ReweighingSamplingWrapper(model, grp=:Sex)
ReweighingSamplingWrapper(
    grp = :Sex,
    classifier = ConstantClassifier(),
    noSamples = -1) @312

julia> evaluate(
          wrappedModel,
          X, y,
          measures=MetricWrappers(
              [true_positive, true_positive_rate]; grp=:Sex))
┌────────────────────┬─────────────────────────────────────────────────────────────────────────────────────┬───────────────────────────────────── ⋯
│ _.measure          │ _.measurement                                                                       │ _.per_fold                           ⋯
├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────── ⋯
│ true_positive      │ Dict{Any,Any}("M" => 2,"overall" => 4,"F" => 2)                                     │ Dict{Any,Any}[Dict("M" => 0,"overall ⋯
│ true_positive_rate │ Dict{Any,Any}("M" => 0.8333333333333334,"overall" => 0.8333333333333334,"F" => 1.0) │ Dict{Any,Any}[Dict("M" => 4.99999999 ⋯
└────────────────────┴─────────────────────────────────────────────────────────────────────────────────────┴───────────────────────────────────── ⋯
```

# Components
MLJFair is divided into following components

### FairTensor
It is a 3D matrix of values of TruePositives, False Negatives, etc for each group. It greatly helps in optimization and removing the redundant calculations.

### Measures

#### CalcMetrics

| Name | Metric Instances |
|-----|-------------|
| True Positive | truepositive,  true_positive
| True Negative | truenegative, true_negative
| False Positive | falsepositive, false_positive
| False Negative | falsenegative, false_negative
| True Positive Rate | truepositive_rate, true_positive_rate, tpr, recall, sensitivity, hit_rate
| True Negative Rate | truenegative_rate, true_negative_rate, tnr, specificity, selectivity
| False Positive Rate | falsepositive_rate, false_positive_rate, fpr, fallout
| False Negative Rate | falsenegative_rate, false_negative_rate, fnr, miss_rate
| False Discovery Rate | falsediscovery_rate, false_discovery_rate, fdr
| Precision | positivepredictive_value, positive_predictive_value, ppv
| Negative Predictive Value | negativepredictive_value, negative_predictive_value, npv

#### FairMetrics

| Name | Formula | Value for Custom function (func)
|-----|-------------|----------------|
| disparity | metric(Gᵢ)/metric(RefGrp) ∀ i| func(metric(Gᵢ), metric(RefGrp)) ∀ i
| parity | [ (1-ϵ) <= dispariy_value[i] <= 1/(1-ϵ) ∀ i ] | [ func(disparity_value[i]) ∀ i ]

#### BoolMetrics [WIP]
These metrics shall use either parity or shall have custom implementation to return boolean values

| Metric | Aliases |
|-----|-------------|
| Demographic Parity | DemographicParity

### Fairness Algorithms
These algorithms are wrappers. These help in mitigating bias and improve fairness.

| Algorithm Name | Metric Optimised | Supports Multi-valued protected attribute | Type | Reference |
|----------------|------------------|-------------------------------------------|------|-----------|
| Reweighing | General | :heavy_check_mark: |  Preprocessing | [Kamiran and Calders, 2012](http://doi.org/10.1007/s10115-011-0463-8)
| Reweighing-Sampling | General | :heavy_check_mark: | Preprocessing | [Kamiran and Calders, 2012](http://doi.org/10.1007/s10115-011-0463-8)
| Equalized Odds Algorithm | Equalized Odds | :heavy_check_mark: | Postprocessing | [Hardt et al., 2016](https://papers.nips.cc/paper/6374-equality-of-opportunity-in-supervised-learning)
| LinProg Algorithm | Any metric | :heavy_check_mark: | Postprocessing | Our own algorithm
| Meta-Fair algorithm[WIP] | Any metric | :heavy_check_mark: | Inprocessing | [Celis et al.. 2018](https://arxiv.org/abs/1806.06055)
