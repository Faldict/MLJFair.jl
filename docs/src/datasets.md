# Fairness Datasets

To make it easy to try algorithms and metrics on various datasets, MLJFair shall be providing with the popular fairness datasets.

These datasets can be easily accesses using macros.

## German Credit Dataset
```@docs
@load_german
```
```@repl datasets
using MLJFair
X, y = @load_german;
```

## Toy Data
This is a 10 row dataset that was used by authors of Reweighing Algorithm.

```@docs
@load_toydata
@load_toyfairtensor
```

```@repl datasets
X, y, ŷ = @load_toydata;
ft = @load_toyfairtensor
```

## Other Datasets
You can try working with the vast range of datasets available through OpenML.
Refer [MLJ's OpenML documentation](https://alan-turing-institute.github.io/MLJ.jl/v0.9/openml_integration/) for the OpenML API.
The id to be passed to OpenML.load can be found through [OpenML site](https://www.openml.org/search?type=data)
```@repl
using MLJBase, MLJFair;
using DataFrames
data = OpenML.load(1480); # load Indian Liver Patient Dataset
df = DataFrame(data) ;
y, X = unpack(df, ==(:Class), name->true); # Unpack the data into features and target
y = coerce(y, Multiclass); # Specifies that the target y is of type Multiclass. It is othewise a string.
coerce!(X, :V2 => Multiclass, Count => Continuous); # Specifying which columns are Multiclass in nature. Converting from Count to Continuous enables use of more models.
```
If you notice, the target y is either 1 or 2. But MLJFair supports only binary attributes. This shall be changed in future and we will support any 2 values which will be compared on the basis of levels.
So, to proceed further, you need to map the values to binary.
```
y = map(y) do η
    η == "1" ? true : false
end;
```

### Helper Functions
```@docs
MLJFair.ensure_download
```
