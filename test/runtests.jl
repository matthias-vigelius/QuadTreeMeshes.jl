import QuadTreeMeshes
using Base.Test
import GeometryTypes

plot = true

if plot==true
    import Plots
    Plots.plotlyjs()
end

include("TestHelpers.jl")
include("CurrentTest.jl")

#include("MeshTests.jl")
#include("QuadTreeTests.jl")
