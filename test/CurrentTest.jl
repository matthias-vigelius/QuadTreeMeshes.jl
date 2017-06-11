
  @testset "Triangulate template 0000" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    mesh = QuadTreeMeshes.QuadTreeMesh(bb)
    q = mesh.quadtree

    # triangulate first and only element
    QuadTreeMeshes.triangulate_leave(mesh, 1)
    @test size(mesh.triangles) == (2,)

    # get triangulation
    @test !isnull(q.values[1])
    mesh_element = get(q.values[1])
    @test mesh_element.triangle_indices == [1,2]
    @test mesh.triangles[1].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([1,2,3])
    @test mesh.triangles[2].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([2,4,3])

    # plot triangulation
    filename = "triangulate_leave_0000.svg"
    Plots.plot(mesh)
    Plots.savefig(filename)


  end
