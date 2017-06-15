@testset "Triangulate template 0100" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    mesh = QuadTreeMeshes.QuadTreeMesh(bb)
    q = mesh.quadtree

    # subdivide NE twice
    QuadTreeMeshes.subdivide!(q, 1, subdividefunc)
    firstElement = get_neighbour_from_index(q, 1, 2)
    QuadTreeMeshes.subdivide!(q, get(firstElement), subdividefunc)

    # triangulate NW element
    ne_element = get(get_neighbour_from_index(q, 1, 1))
    QuadTreeMeshes.triangulate_leave(mesh, ne_element)
    @test size(mesh.triangles) == (3,)

    # get triangulation
    @test !isnull(q.values[ne_element])
    mesh_element = get(q.values[ne_element])
    @test mesh_element.triangle_indices == [1,2,3]
    @test mesh.triangles[1].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([8,5,13])
    @test mesh.triangles[2].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([8,13,3])
    @test mesh.triangles[3].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([3,13,6])

    # plot triangulation
    filename = "triangulate_leave_0100.svg"
    Plots.plot(mesh)
    Plots.savefig(filename)
  end
