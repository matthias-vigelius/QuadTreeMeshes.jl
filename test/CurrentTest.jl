
  @testset "Neighbour search NE" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    q = QuadTreeMeshes.QuadTree{Int}(bb)

    # subdivide twice
    QuadTreeMeshes.subdivide!(q, 1, subdivideFunc)
    firstElement = get_neighbour_from_index(q, 1, 2)
    QuadTreeMeshes.subdivide!(q, get(firstElement), subdivideFunc)

    # and plot it
    #filename = "subdivide_plot_4.svg"
    #Plots.plot(q)
    #Plots.savefig(filename)

    @test get(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.south)) == 5
    @test get(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.west)) == 2
    @test isnull(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.east))
    @test isnull(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.north))
    @test get(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.east)) == 3
    @test get(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.north)) == 3

    @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.west)) == 2
    @test isnull(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.north))
    @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.east)) == 7
    @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.south)) == 8

    @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.west)) == 6
    @test isnull(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.north))
    @test isnull(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.east))
    @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.south)) == 9
    #println("$q")
  end
