import QuadTreeMeshes
using Base.Test
import GeometryTypes

plot = false

if plot==true
    import Plots
    Plots.plotlyjs()
end

include("TestHelpers.jl")
include("CurrentTest.jl")

#include("QuadTreeTests.jl")
