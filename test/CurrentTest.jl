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

      # add center vertex
      x = ((vpos - 1) % 2)
      y = (vpos - 1)/2
      vPoint = QuadTreeMeshes.Point(x * dx, y * dy) * 0.5 + QuadTreeMeshes.Point(x0 + 0.25 * dx, y0 + 0.25 * dy)
      push!(qt.vertices, vPoint)
      vindex = length(qt.vertices)

      QuadTreeMeshes.triangulate_boundary_leave_with_vertex(mesh, 1, vb1Index, vb2Index, vindex)
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
        v = qt.vertices[vindex]
        b1vs = GeometryTypes.LineSegment(b1, v)
        vb2s = GeometryTypes.LineSegment(v, b2)

        tinterPoints = Array{QuadTreeMeshes.Point, 1}()

        sb1, sb2 = qt.vertices[qt_element.bbLeftBottomIndex], qt.vertices[qt_element.bbRightBottomIndex]
        sb1_intersects, sb1i = GeometryTypes.intersects(b1vs, GeometryTypes.LineSegment(sb1, sb2))
        sb2_intersects, sb2i = GeometryTypes.intersects(vb2s, GeometryTypes.LineSegment(sb1, sb2))
        #println("$(sb_intersects), $(sbi)")
        eb1, eb2 = qt.vertices[qt_element.bbRightBottomIndex], qt.vertices[qt_element.bbRightTopIndex]
        eb1_intersects, eb1i = GeometryTypes.intersects(b1vs, GeometryTypes.LineSegment(eb1, eb2))
        eb2_intersects, eb2i = GeometryTypes.intersects(vb2s, GeometryTypes.LineSegment(eb1, eb2))
        #println("$(eb_intersects), $(ebi)")
        nb1, nb2 = qt.vertices[qt_element.bbRightTopIndex], qt.vertices[qt_element.bbLeftTopIndex]
        nb1_intersects, nb1i = GeometryTypes.intersects(b1vs, GeometryTypes.LineSegment(nb1, nb2))
        nb2_intersects, nb2i = GeometryTypes.intersects(vb2s, GeometryTypes.LineSegment(nb1, nb2))
        #println("$(nb_intersects), $(nbi)")
        wb1, wb2 = qt.vertices[qt_element.bbLeftBottomIndex], qt.vertices[qt_element.bbLeftTopIndex]
        wb1_intersects, wb1i = GeometryTypes.intersects(b1vs, GeometryTypes.LineSegment(wb1, wb2))
        wb2_intersects, wb2i = GeometryTypes.intersects(vb2s, GeometryTypes.LineSegment(wb1, wb2))
        #println("$(wb_intersects), $(wbi)")
        if sb1_intersects
          push!(tinterPoints, sb1i)
        end
        if sb2_intersects
          push!(tinterPoints, sb2i)
        end
        if eb1_intersects
          push!(tinterPoints, eb1i)
        end
        if eb2_intersects
          push!(tinterPoints, eb2i)
        end
        if nb1_intersects
          push!(tinterPoints, nb1i)
        end
        if nb2_intersects
          push!(tinterPoints, nb12)
        end
        if wb1_intersects
          push!(tinterPoints, wb1i)
        end
        if wb2_intersects
          push!(tinterPoints, wb2i)
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
        @assert(npoints <= 4)
        vpx, vpy = vPoint
        if (vpx >= sb1[1] && vpx <= sb2[1])
          && (vpy >= eb1[2] && vpy <= eb2[2])
          # vertex is in element
          @test(!isnull(mesh_element.center) && get(mesh_element.center) == vindex)
        else
          @test(isnull(mesh_element.center))
        end
        if npoints == 1
          # it is just touching the corner
          ip1 = interPoints[1]
          @assert(!isnull(mesh_element.in_boundary))
          @assert(!isnull(mesh_element.out_boundary))
          @test(get(mesh_element.in_boundary) == get(mesh_element.out_boundary))
          ib, ob = qt.vertices[get(mesh_element.in_boundary)], qt.vertices[get(mesh_element.out_boundary)]
          @test(vecnorm(ip1 - ib) < 1e-10)
          @test(vecnorm(ip1 - ob) < 1e-10)
          @test(isnull(mesh_element.center))
        elseif npoints == 2
          # check if interpPoints[1] is on direct line from b1 to vPoint
          db1i = interPoints[1]-b1
          div = vPoint-interPoints[1]
          db1v = vPoint-b1
          if (dot(db1i, db1i) + dot(div, div) - dot(db1v, db1v)) <= 0
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
        elseif npoints == 3
          # todo hmm..
        elseif npoints == 4
          # in the four intersection case we make sure it is flagged dirty
          # todo: need test where we subdivide dirty elements
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
end
