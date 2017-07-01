module QuadTreeMeshes

import GeometryTypes
import FixedSizeArrays

const ElIndex = Int
const Point = GeometryTypes.Point{2, Float64}
const triangle_index = Int
const vertex_index = Int


# package code goes here
include("QuadTree.jl")
include("Meshes.jl")
include("PlotRecipes.jl")

end # module
