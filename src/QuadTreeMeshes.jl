module QuadTreeMeshes

import GeometryTypes
import FixedSizeArrays

typealias ElIndex Int
typealias Point GeometryTypes.Point{2, Float64}
typealias triangle_index Int
typealias vertex_index Int


# package code goes here
include("QuadTree.jl")
include("PlotRecipes.jl")
include("Meshes.jl")

end # module
