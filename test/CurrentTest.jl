@testset "Update boundaries with vertices" begin for b1index in 1:1, b2index in 4:4 begin, vpos in 1:4 begin
    q1 = floor((b1index - 1)/4)
    q2 = floor((b2index - 1)/4)

    if q1 != q2
      #b1index = 1
      #b2index = 9

      #println("------------------Testing ($(b1index), $(b2index))")
      # add boundaries to single element
      x0, y0 = 2.0, 3.0
      dx, dy = 4.0, 4.0
      bb = GeometryTypes.SimpleRectangle(x0, y0, dx, dy)
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

      # add center vertex (center of child bounding box)
      childEl = get_children(qt, 1)[vpos]
      childBB = get_element_bounding_box(qt, childEl)
      vx = childBB.x + 0.5 * childBB.w
      vy = childBB.y + 0.5 * childBB.h
      vPoint = QuadTreeMeshes.Point(x, y)

      push!(qt.vertices, vPoint)
      vindex = length(qt.vertices)

      QuadTreeMeshes.triangulate_boundary_leave_with_vertex(mesh, 1, vb1Index, vb2Index, vindex)
      mesh_element = get(qt.values[1])
      #TODO: I don't think we need crossing_dir or boundary_pos
      bv1 = QuadTreeMeshes.BoundaryVertex(Outer, northWest, northWest, false, vb1Index)
      bv2 = QuadTreeMeshes.BoundaryVertex(Outer, northWest, northWest, false, vb2Index)
      vv  = QuadTreeMeshes.BoundaryVertex(Innter, vpos, northWest, false, vindex)
      push!(mesh_element.boundaries, (bv1, vv))
      push!(mesh_element.boundaries, (vv, bv1))

      # subdivide new element
      QuadTreeMeshes.subdivide!(qt, 1, QuadTreeMeshes.OnChildrenCreated)

      # compute intersection points of boundary with bounding box
      b1, b2 = qt.vertices[vb1Index], qt.vertices[vb2Index]
      v = qt.vertices[vindex]
      b1vs = GeometryTypes.LineSegment(b1, v)
      vb2s = GeometryTypes.LineSegment(v, b2)

      # check all child elements
      function check_child_element(elIndex::QuadTreeMeshes.ElIndex)
        check_leave_intersection(qt, elIndex, b1vs)
        check_leave_intersection(qt, elIndex, v2bs)
        # check that there a no boundary intersections left
        @test(length(qt.values[elIndex].boundaries) == 0)
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
