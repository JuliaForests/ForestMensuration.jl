# ForestMensuration Package:

Documentation for [ForestMensuration](https://github.com/JuliaForests/ForestMensuration.jl).

**ForestMensuration.jl** is a Julia package that offers a comprehensive suite of functions for dendrometric calculations. With a focus on simplicity and efficiency, it streamlines complex forestry computations through an intuitive interface. Key features include:

- **Tree Volume (Cubage)**: `cubage` gives the volume of the whole tree from the diameters measured at absolute heights: the stump, the sections by Smalian's method and the tip, and the form factor, with and without bark, for one tree or many trees told apart by an identifier. Logs measured at relative positions (equal sections, as in the field sheets and in Hohenadl's methodology) give only the volume of the log: `smalian` and `huber` with the length of the log, for one log or a sheet with a log per row. Nothing is interpolated.
- **Forest Inventory Sampling**: All 14 sampling designs — simple, stratified, systematic, cluster/two-stage, horizontal point/Bitterlich, horizontal line (Strand), Prodan, 3P, and successive-occasions — each generic to any number of strata/clusters/plots. Provided by [ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl), re-exported here.
- **Stand Structure**: `standmetrics` gives the number of trees, the basal area, the mean and quadratic mean diameters and their coefficient of variation per hectare, and, with the species and the plots of the trees, the horizontal structure and the phytosociological indices (importance value index) of each species. The Weise, central basal area, dominant and Hohenadl diameters are available one by one.
- **Frequency and Diametric Tables**: Generate detailed frequency and diameter distribution tables to support comprehensive data analysis.
- **Native Forest Biodiversity**: Diversity indices, floristic similarity and species accumulation curves for native and mixed forest inventories.

Whether you are conducting research or managing forestry operations, **ForestMensuration.jl** simplifies the process of analyzing dendrometric data, enabling you to perform sophisticated calculations with minimal effort.

```@meta
CurrentModule = ForestMensuration
```

## Installation

The ForestMensuration package is available through the Julia package system and can be added by running Pkg.add("ForestMensuration") or by directly downloading it from the GitHub page:

```julia-repl-repl
pkg> add https://github.com/JuliaForests/ForestMensuration.jl
```

## About the Author

I am Marcos Daniel da Silva, a Forest Engineer with a strong interest in forest mensuration and data analysis. I developed the ForestMensuration.jl package as part of my final course project in Forest Engineering at the Federal University of Santa Maria campus Frederico Westphalen (UFSM), under the guidance of Prof. Dr. Rafaelo Balbinot (UFSM) and Prof. Dr. Alexandre Behling (UFPR). This package represents my dedication to providing accessible tools for forestry professionals and researchers, aiming to simplify complex dendrometric calculations and forest inventory analyses using the Julia programming language.

For more details, please feel free to connect with me on [LinkedIn](https://www.linkedin.com/in/marcosdanieldasilva/?locale=en_US) or by e-mail: [marcosdasilva@5a.tec.br](mailto:marcosdasilva@5a.tec.br).

This package is supported and encouraged by [5A Inteligência e Engenharia](https://5a.tec.br/).

You can also access my final course work through the UFSM repository: [Forestmensuration.jl: Uma Introdução à Aplicações em Julia](https://repositorio.ufsm.br/handle/1/31917?show=full).
