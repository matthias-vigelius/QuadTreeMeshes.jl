@testset "Update boundaries" begin for b1index in 1:16, b2index in 1:16 begin
    q1 = floor((b1index - 1)/4)
    q2 = floor((b2index - 1)/4)

    if q1 != q2
      #b1index = 1
      #b2index = 9

      #println("------------------Testing ($(b1index), $(b2index))")
      # add boundaries to single element
      bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
      mesh = QuadTreeMeshes.QuadTreeMesh(bb)
      qt = mesh.quadtree
      qtEl = qt.elements[1]

      function get_boundary_coordinates_from_index(bndy_index::Int64)
        # get quad tree element

        if bndy_index <= 4
          b1, b2 = qtEl.bbLeftBottomIndex, qtEl.bbRightBottomIndex
        elseif bndy_index <= 8
          b1, b2 = qtEl.bbRightBottomIndex, qtEl.bbRightTopIndex
        elseif bndy_index <= 12
          b1, b2 = qtEl.bbRightTopIndex, qtEl.bbLeftTopIndex
        else
          b1, b2 = qtEl.bbLeftTopIndex, qtEl.bbLeftBottomIndex
        end

        inner_index = (bndy_index - 1) % 4
        x1, x2 = qt.vertices[b1], qt.vertices[b2]
        ds = x2 - x1
        pos = x1 + ds * (0.125 + inner_index * 0.25)

        return pos
      end

      # add boundary vertices
      push!(qt.vertices, QuadTreeMeshes.Point(get_boundary_coordinates_from_index(b1index)))
      vb1Index = length(qt.vertices)
      push!(qt.vertices, QuadTreeMeshes.Point(get_boundary_coordinates_from_index(b2index)))
      vb2Index = length(qt.vertices)
      QuadTreeMeshes.triangulate_boundary_leave(mesh, 1, vb1Index, vb2Index)
      mesh_element = get(qt.values[1])
      mesh_element.in_boundary = Nullable{QuadTreeMeshes.vertex_index}(vb1Index)
      mesh_element.out_boundary = Nullable{QuadTreeMeshes.vertex_index}(vb2Index)
      #println("$(qt.vertices[vb1Index]), $(qt.vertices[vb2Index])")

      # subdivide new element
      QuadTreeMeshes.subdivide!(qt, 1, QuadTreeMeshes.OnChildrenCreated)

      function check_child_element(elIndex::QuadTreeMeshes.ElIndex)
        qt_element = qt.elements[elIndex]
        mesh_element = get(qt.values[elIndex])

        # compute intersection points of boundary with bounding box
        b1, b2 = qt.vertices[vb1Index], qt.vertices[vb2Index]
        bls = GeometryTypes.LineSegment(b1, b2)

        tinterPoints = Array{QuadTreeMeshes.Point, 1}()

        sb1, sb2 = qt.vertices[qt_element.bbLeftBottomIndex], qt.vertices[qt_element.bbRightBottomIndex]
        sb_intersects, sbi = GeometryTypes.intersects(bls, GeometryTypes.LineSegment(sb1, sb2))
        #println("$(sb_intersects), $(sbi)")
        eb1, eb2 = qt.vertices[qt_element.bbRightBottomIndex], qt.vertices[qt_element.bbRightTopIndex]
        eb_intersects, ebi = GeometryTypes.intersects(bls, GeometryTypes.LineSegment(eb1, eb2))
        #println("$(eb_intersects), $(ebi)")
        nb1, nb2 = qt.vertices[qt_element.bbRightTopIndex], qt.vertices[qt_element.bbLeftTopIndex]
        nb_intersects, nbi = GeometryTypes.intersects(bls, GeometryTypes.LineSegment(nb1, nb2))
        #println("$(nb_intersects), $(nbi)")
        wb1, wb2 = qt.vertices[qt_element.bbLeftBottomIndex], qt.vertices[qt_element.bbLeftTopIndex]
        wb_intersects, wbi = GeometryTypes.intersects(bls, GeometryTypes.LineSegment(wb1, wb2))
        #println("$(wb_intersects), $(wbi)")
        if sb_intersects
          push!(tinterPoints, sbi)
        end
        if eb_intersects
          push!(tinterPoints, ebi)
        end
        if nb_intersects
          push!(tinterPoints, nbi)
        end
        if wb_intersects
          push!(tinterPoints, wbi)
        end

        # remove duplicates
        interPoints = Array{QuadTreeMeshes.Point, 1}()
        for tp in tinterPoints
          found = false
          for p in interPoints
            if !found && dot((p-tp), (p-tp)) < 1e-10
              found = true
            end
          end
          if !found
            push!(interPoints, tp)
          end
        end

        npoints = length(interPoints)
        @assert(npoints == 0 || npoints == 1 || npoints == 2)
        if npoints == 2
          if vecnorm(interPoints[1] - b1) < vecnorm(interPoints[2] - b1)
            ip1 = interPoints[1]
            ip2 = interPoints[2]
          else
            ip1 = interPoints[2]
            ip2 = interPoints[1]
          end
          @assert(!isnull(mesh_element.in_boundary))
          @assert(!isnull(mesh_element.out_boundary))
          ib, ob = qt.vertices[get(mesh_element.in_boundary)], qt.vertices[get(mesh_element.out_boundary)]
          @test(vecnorm(ip1 - ib) < 1e-10)
          @test(vecnorm(ip2 - ob) < 1e-10)
          @test(isnull(mesh_element.center))
        elseif npoints == 1
          # it is just touching the corner
          ip1 = interPoints[1]
          @assert(!isnull(mesh_element.in_boundary))
          @assert(!isnull(mesh_element.out_boundary))
          @test(get(mesh_element.in_boundary) == get(mesh_element.out_boundary))
          ib, ob = qt.vertices[get(mesh_element.in_boundary)], qt.vertices[get(mesh_element.out_boundary)]
          @test(vecnorm(ip1 - ib) < 1e-10)
          @test(vecnorm(ip1 - ob) < 1e-10)
          @test(isnull(mesh_element.center))
        else
          @test(isnull(mesh_element.in_boundary))
          @test(isnull(mesh_element.out_boundary))
          @test(isnull(mesh_element.center))
        end
      end

      # check all child elements
      check_child_element(get(qtEl.northWest))
      check_child_element(get(qtEl.northEast))
      check_child_element(get(qtEl.southWest))
      check_child_element(get(qtEl.southEast))
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
