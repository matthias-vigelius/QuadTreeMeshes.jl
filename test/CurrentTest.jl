@testset "Triangulate boundary template north south" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    mesh = QuadTreeMeshes.QuadTreeMesh(bb)
    q = mesh.quadtree

    # add north-south vertices
    push!(q.vertices, QuadTreeMeshes.Point(2.1, 7.0))
    vnIndex = length(q.vertices)
    push!(q.vertices, QuadTreeMeshes.Point(2.7, 3.0))
    vsIndex = length(q.vertices)

    # triangulate NW element
    QuadTreeMeshes.triangulate_boundary_leave(mesh, 1, vnIndex, vsIndex)
    @test size(mesh.triangles) == (4,)

    # get triangulation
    @test !isnull(q.values[1])
    mesh_element = get(q.values[1])
    @test mesh_element.triangle_indices == [1,2,3,4]
    @test mesh.triangles[1].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([1,6,3])
    @test mesh.triangles[2].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([6,5,3])
    @test mesh.triangles[3].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([6,2,5])
    @test mesh.triangles[4].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([5,2,4])

    # plot triangulation
    filename = "triangulate_bndy_leave_ns.svg"
    Plots.plot(mesh)
    Plots.savefig(filename)
  end
