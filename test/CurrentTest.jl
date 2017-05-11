  @testset "Neighbour search NW" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    q = QuadTreeMeshes.QuadTree{Int}(bb)

    # subdivide twice
    QuadTreeMeshes.subdivide!(q, 1)
    firstElement = get_neighbour_from_index(q, 1, 1)
    QuadTreeMeshes.subdivide!(q, get(firstElement))

    # and plot it
    #filename = "subdivide_plot_1.svg"
    #Plots.plot(q)
    #Plots.savefig(filename)

    @test isnull(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.north))
    @test get(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.east)) == 3
    @test isnull(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.west))
    @test get(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.south)) == 4
    println("$q")


  end
end
