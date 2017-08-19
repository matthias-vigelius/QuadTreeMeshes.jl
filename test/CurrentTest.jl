@testset "Update boundaries" begin for b1index in 1:16, b2index in 9:16 begin
    q1 = floor((b1index - 1)/4)
    q2 = floor((b2index - 1)/4)

    if q1 != q2
      #b1index = 1
      #b2index = 9

      print_with_color(:yellow, "------------------Testing ($(b1index), $(b2index))\n")
      # add boundaries to single element
      bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
      mesh = QuadTreeMeshes.QuadTreeMesh(bb)
      qt = mesh.quadtree
      qtEl = qt.elements[1]

      # add boundary vertices
      push!(qt.vertices, QuadTreeMeshes.Point(get_boundary_coordinates_from_index(b1index, qtEl, qt)))
      vb1Index = length(qt.vertices)
      push!(qt.vertices, QuadTreeMeshes.Point(get_boundary_coordinates_from_index(b2index, qtEl, qt)))
      vb2Index = length(qt.vertices)

      QuadTreeMeshes.triangulate_boundary_leave(mesh, 1, vb1Index, vb2Index)
      mesh_element = get(qt.values[1])

      if plot==true
        filename = "triangulate_bndy_leave.html"
        Plots.plot(qt)
        Plots.plot!(mesh, boundaries_only=true)
        Plots.savefig(filename)
      end

      # subdivide new element
      QuadTreeMeshes.subdivide!(qt, 1, QuadTreeMeshes.OnChildrenCreated)

      b1, b2 = qt.vertices[vb1Index], qt.vertices[vb2Index]
      b1b2s = GeometryTypes.LineSegment(b1, b2)

      function check_child_element(elIndex::QuadTreeMeshes.ElIndex)
        check_leave_intersection(qt, elIndex, b1b2s, Nullable{Int64}())
        # check that there a no boundary intersections left
        @test(length(get(qt.values[elIndex]).boundaries) == 0)
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

