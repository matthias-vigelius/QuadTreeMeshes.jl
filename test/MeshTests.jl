@testset "Update boundaries with vertices" begin for b2index=1:16 begin for b1index = 1:16 for evpos = 1:4 begin begin
    if b1index == b2index
      continue
    end

    vpos = QuadTreeMeshes.POS(evpos)

    #print_with_color(:yellow, "------------------Testing ($(b1index), $(b2index), $vpos)\n")
    # add boundaries to single element
    x0, y0 = 2.0, 3.0
    dx, dy = 4.0, 4.0
    bb = GeometryTypes.SimpleRectangle(x0, y0, dx, dy)
    mesh = QuadTreeMeshes.QuadTreeMesh(bb)
    qt = mesh.quadtree
    qtEl = qt.elements[1]

    # add boundary vertices
    push!(qt.vertices, QuadTreeMeshes.Point(get_boundary_coordinates_from_index(b1index, qtEl, qt)))
    vb1Index = length(qt.vertices)
    push!(qt.vertices, QuadTreeMeshes.Point(get_boundary_coordinates_from_index(b2index, qtEl, qt)))
    vb2Index = length(qt.vertices)

    # add center vertex (center of child bounding box)
    elBB = QuadTreeMeshes.get_element_bounding_box(qt, 1)
    vx = elBB.x + 0.25 * elBB.w + ((vpos == QuadTreeMeshes.northEast || vpos == QuadTreeMeshes.southEast) ? 1 : 0) * 0.5 * elBB.w 
    vy = elBB.y + 0.25 * elBB.h + ((vpos == QuadTreeMeshes.northWest || vpos == QuadTreeMeshes.northEast) ? 1 : 0) * 0.5 * elBB.h 
    vPoint = QuadTreeMeshes.Point(vx, vy)

    push!(qt.vertices, vPoint)
    vindex = length(qt.vertices)

    QuadTreeMeshes.triangulate_boundary_leave_with_vertex(mesh, 1, vb1Index, vb2Index, vindex)
    mesh_element = get(qt.values[1])

    if plot==true
      filename = "triangulate_bndy_leave.html"
      Plots.plot(qt)
      Plots.plot!(mesh)
      Plots.plot!(mesh, boundaries_only=true)
      Plots.savefig(filename)
    end

    # subdivide new element
    QuadTreeMeshes.subdivide!(qt, 1, QuadTreeMeshes.OnChildrenCreated)

    # compute intersection points of boundary with bounding box
    b1, b2 = qt.vertices[vb1Index], qt.vertices[vb2Index]
    v = qt.vertices[vindex]
    b1vs = GeometryTypes.LineSegment(b1, v)
    vb2s = GeometryTypes.LineSegment(v, b2)

    # check all child elements
    function check_child_element(elIndex::QuadTreeMeshes.ElIndex)
      check_leave_intersection(qt, elIndex, b1vs, Nullable{Int64}(vindex))
      check_leave_intersection(qt, elIndex, vb2s, Nullable{Int64}(vindex))
      # check that there a no boundary intersections left
      @test(length(get(qt.values[elIndex]).boundaries) == 0)
    end

    check_child_element(get(qtEl.northWest))
    check_child_element(get(qtEl.northEast))
    check_child_element(get(qtEl.southWest))
    check_child_element(get(qtEl.southEast))
end
end
end
end
end
end
end

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
    #filename = "triangulate_leave_0100.svg"
    #Plots.plot(mesh)
    #Plots.savefig(filename)
end

@testset "Triangulate template 1000" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    mesh = QuadTreeMeshes.QuadTreeMesh(bb)
    q = mesh.quadtree

    # subdivide NW twice
    QuadTreeMeshes.subdivide!(q, 1, subdividefunc)
    firstElement = get_neighbour_from_index(q, 1, 1)
    QuadTreeMeshes.subdivide!(q, get(firstElement), subdividefunc)

    # triangulate NE element
    ne_element = get(get_neighbour_from_index(q, 1, 2))
    QuadTreeMeshes.triangulate_leave(mesh, ne_element)
    @test size(mesh.triangles) == (3,)

    # get triangulation
    @test !isnull(q.values[ne_element])
    mesh_element = get(q.values[ne_element])
    @test mesh_element.triangle_indices == [1,2,3]
    @test mesh.triangles[1].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([5,9,14])
    @test mesh.triangles[2].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([9,14,4])
    @test mesh.triangles[3].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([14,4,6])

    # plot triangulation
    #filename = "triangulate_leave_1000.svg"
    #Plots.plot(mesh)
    #Plots.savefig(filename)
end

@testset "Triangulate template 0010" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    mesh = QuadTreeMeshes.QuadTreeMesh(bb)
    q = mesh.quadtree

    # subdivide NE twice
    QuadTreeMeshes.subdivide!(q, 1, subdividefunc)
    firstElement = get_neighbour_from_index(q, 1, 2)
    QuadTreeMeshes.subdivide!(q, get(firstElement), subdividefunc)

    # triangulate SE element
    ne_element = get(get_neighbour_from_index(q, 1, 4))
    QuadTreeMeshes.triangulate_leave(mesh, ne_element)
    @test size(mesh.triangles) == (3,)

    # get triangulation
    @test !isnull(q.values[ne_element])
    mesh_element = get(q.values[ne_element])
    @test mesh_element.triangle_indices == [1,2,3]
    @test mesh.triangles[1].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([7,12,5])
    @test mesh.triangles[2].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([7,12,2])
    @test mesh.triangles[3].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([2,12,9])

    # plot triangulation
    #filename = "triangulate_leave_0010.svg"
    #Plots.plot(mesh)
    #Plots.savefig(filename)
  end

  @testset "Triangulate template 0001" begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    mesh = QuadTreeMeshes.QuadTreeMesh(bb)
    q = mesh.quadtree

    # subdivide SE twice
    QuadTreeMeshes.subdivide!(q, 1, subdividefunc)
    firstElement = get_neighbour_from_index(q, 1, 4)
    QuadTreeMeshes.subdivide!(q, get(firstElement), subdividefunc)

    # triangulate NE element
    ne_element = get(get_neighbour_from_index(q, 1, 2))
    QuadTreeMeshes.triangulate_leave(mesh, ne_element)
    @test size(mesh.triangles) == (3,)

    # get triangulation
    @test !isnull(q.values[ne_element])
    mesh_element = get(q.values[ne_element])
    @test mesh_element.triangle_indices == [1,2,3]
    @test mesh.triangles[1].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([5,11,6])
    @test mesh.triangles[2].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([6,11,4])
    @test mesh.triangles[3].vertex_indices == FixedSizeArrays.Vec{3, QuadTreeMeshes.vertex_index}([11,9,4])

    # plot triangulation
    #filename = "triangulate_leave_0001.svg"
    #Plots.plot(mesh)
    #Plots.savefig(filename)
  end

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
    #filename = "triangulate_leave_0000.svg"
    #Plots.plot(mesh)
    #Plots.savefig(filename)
  end
