function get_boundary_coordinates_from_index(bndy_index::Int64, qtEl::QuadTreeMeshes.QuadTreeElement, qt::QuadTreeMeshes.QuadTree)
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

function check_leave_intersection(qt::QuadTreeMeshes.QuadTree, elIndex::QuadTreeMeshes.ElIndex, ls::GeometryTypes.Simplex{2, QuadTreeMeshes.Point}, center_vertex::Nullable{QuadTreeMeshes.vertex_index})
  qt_element = qt.elements[elIndex]
  mesh_element = get(qt.values[elIndex])

  tinterPoints = Array{QuadTreeMeshes.Point, 1}()

  sb1, sb2 = qt.vertices[qt_element.bbLeftBottomIndex], qt.vertices[qt_element.bbRightBottomIndex]
  sb1_intersects, sb1i = GeometryTypes.intersects(ls, GeometryTypes.LineSegment(sb1, sb2))
  eb1, eb2 = qt.vertices[qt_element.bbRightBottomIndex], qt.vertices[qt_element.bbRightTopIndex]
  eb1_intersects, eb1i = GeometryTypes.intersects(ls, GeometryTypes.LineSegment(eb1, eb2))
  nb1, nb2 = qt.vertices[qt_element.bbRightTopIndex], qt.vertices[qt_element.bbLeftTopIndex]
  nb1_intersects, nb1i = GeometryTypes.intersects(ls, GeometryTypes.LineSegment(nb1, nb2))
  wb1, wb2 = qt.vertices[qt_element.bbLeftBottomIndex], qt.vertices[qt_element.bbLeftTopIndex]
  wb1_intersects, wb1i = GeometryTypes.intersects(ls, GeometryTypes.LineSegment(wb1, wb2))
  if sb1_intersects
    push!(tinterPoints, sb1i)
  end
  if eb1_intersects
    push!(tinterPoints, eb1i)
  end
  if nb1_intersects
    push!(tinterPoints, nb1i)
  end
  if wb1_intersects
    push!(tinterPoints, wb1i)
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

  # sort according to distance from start
  sort!(interPoints, by = p -> dot((p-ls[1]), (p-ls[1])))

  npoints = length(interPoints)

  center_is_in_element = false
  if !isnull(center_vertex)
    vPoint = qt.vertices[get(center_vertex)]
    vpx, vpy = vPoint
    if ((vpx >= sb1[1] && vpx <= sb2[1]) && (vpy >= eb1[2] && vpy <= eb2[2]))
      # vertex is in element
      center_is_in_element = true
      @test(!isnull(mesh_element.center) && get(mesh_element.center) == get(center_vertex))
    else
      @test(isnull(mesh_element.center))
    end
  end
  if center_is_in_element
    # we must have at most two boundaries - one that starts at the center
    # and one that ends there (there might have been one deleted already though)
    @assert(length(mesh_element.boundaries) <= 2, "Element $elIndex is $mesh_element.")
    s, e = ls
    ls_starts_at_vertex = dot(s-vPoint, s-vPoint) <= 1e-10
    ls_ends_at_vertex = dot(e-vPoint, e-vPoint) <= 1e-10
    @assert((ls_starts_at_vertex && !ls_ends_at_vertex) || (!ls_starts_at_vertex && ls_ends_at_vertex))
    found = Nullable{Tuple{Int, QuadTreeMeshes.BoundaryVertex}}()
    for (bidx, b) in enumerate(mesh_element.boundaries)
      if ls_starts_at_vertex && b[1].vt == QuadTreeMeshes.Inner && b[1].vertex == get(center_vertex)
        found = Nullable{Tuple{Int, QuadTreeMeshes.BoundaryVertex}}((bidx, b[2]))
      elseif ls_ends_at_vertex && b[2].vt == QuadTreeMeshes.Inner && b[2].vertex == get(center_vertex)
        found = Nullable{Tuple{Int, QuadTreeMeshes.BoundaryVertex}}((bidx, b[1]))
      end
    end
    @assert(!isnull(found))
    foundBoundary, foundVertex = get(found)
    boundary_vertex_point = qt.vertices[foundVertex.vertex]
    @assert(length(interPoints) == 1)
    dist = boundary_vertex_point - interPoints[1]
    @test(dot(dist, dist) <= 1e-10)
    mesh_element.boundaries = deleteat!(mesh_element.boundaries, foundBoundary)
  else
    @assert(length(interPoints) <= 2)
    if length(interPoints) > 0
      if (length(interPoints) == 1)
        input_boundary = (interPoints[1], interPoints[1])
      elseif length(interPoints) == 2
        input_boundary = (interPoints[1], interPoints[2])
      end
      found = Nullable{Int}()
      for (ind, b) in enumerate(mesh_element.boundaries)
        b1, b2 = b
        b1p = qt.vertices[b1.vertex]
        b2p = qt.vertices[b2.vertex]
        db1 = b1p - input_boundary[1]
        db2 = b2p - input_boundary[2]
        if dot(db1, db1) <= 1e-10 && dot(db2, db2) <= 1e-10
          found = Nullable{Int}(ind)
        end
      end
      if isnull(found)
        print_with_color(:red, "No suitable boundaries found. Intersection points $(interPoints)\n")
        for b in mesh_element.boundaries
          b1, b2 = b
          print_with_color(:green, "$(b1.vertex) [$(qt.vertices[b1.vertex])] -> $(b2.vertex) [$(qt.vertices[b2.vertex])]\n") 
        end
      end
      @assert(!isnull(found))
      mesh_element.boundaries = deleteat!(mesh_element.boundaries, get(found))
    end
  end
end

function subdividefunc(x)
  #println("$x")
end

function onlinesegment(
  xi::QuadTreeMeshes.Point,
  x1::QuadTreeMeshes.Point,
  x2::QuadTreeMeshes.Point)
    if (xi ≈ x1) || (xi ≈ x2)
      return true
    end
    local d1i = normalize(xi - x1)
    local di2 = normalize(x2 - xi)
    return d1i ≈ di2
end

function orientation(v1::QuadTreeMeshes.Point, v2::QuadTreeMeshes.Point, v3::QuadTreeMeshes.Point)
  local xa = v1[1]
  local ya = v1[2]
  local xb = v2[1]
  local yb = v2[2]
  local xc = v3[1]
  local yc = v3[2]

  local det = (xa*yb - xa*yc - xb*ya + xb*yc + xc*ya - xc*yb)
  if abs(det) <= 1e-10
    return 0
  elseif det > 0.
    return 1
  else
    return 2
  end
end
"""
    pointsintersect(p1::QuadTreeMeshes.Point, q1::QuadTreeMeshes.Point, p2::QuadTreeMeshes.Point, q2::QuadTreeMeshes.Point)

Checks if line segments given by their end points intersect.

# Remarks
* Taken from geeksforgeeks.org/check-if-two-given-line-segments-intersect
"""
function pointsintersect(p1::QuadTreeMeshes.Point, q1::QuadTreeMeshes.Point, p2::QuadTreeMeshes.Point, q2::QuadTreeMeshes.Point)
  local o1 = orientation(p1,q1,p2)
  local o2 = orientation(p1,q1,q2)
  local o3 = orientation(p2,q2,p1)
  local o4 = orientation(p2,q2,q1)
  if (o1 != o2 && o3 != o4)
    return true
  elseif (o1 == 0 && onlinesegment(p2, p1, q1))
    return true
  elseif (o2 == 0 && onlinesegment(q2, p1, q1))
    return true
  elseif (o3 == 0 && onlinesegment(p1, p2, q2))
    return true
  elseif (o4 == 0 && onlinesegment(q1, p2, q2))
    return true
  else
    return false
  end
end

function line_intersects_line(ls1::GeometryTypes.LineSegment{QuadTreeMeshes.Point}, ls2::GeometryTypes.LineSegment{QuadTreeMeshes.Point})
  return pointsintersect(ls1[1], ls1[2], ls2[1], ls2[2])
end

function line_intersects_rectangle(r::GeometryTypes.SimpleRectangle{Float64}, ls::GeometryTypes.LineSegment{QuadTreeMeshes.Point})
  ((x1, y1), (x2, y2)) = ls
  xbl, ybl, xtr, ytr = r.x, r.y, r.x + r.w, r.y + r.h
  f(x, y) = (y2 - y1) * x + (x1 - x2) * y + (x2 * y1 - x1 * y2)
  s1 = f(xbl, ybl)
  s2 = f(xbl, ytr)
  s3 = f(xtr, ybl)
  s4 = f(xtr, ytr)
  if (s1>0 && s2>0 && s3>0 && s4>0) || (s1<0 && s2<0 && s3<0 && s4<0)
    return false
  end
  if (x1 > xtr && x2 > xtr)
    return false
  end
  if (x1 < xbl && x2 < xbl)
    return false
  end
  if (y1 > ytr && y2 > ytr)
    return false
  end
  if (y1 < ybl && y2 < ybl)
    return false
  end
  return true
end


function subdivide_random!(qt::QuadTreeMeshes.QuadTree)
  elIndex = rand(1:size(qt.elements, 1))
  while (QuadTreeMeshes.has_child(qt, elIndex))
    elIndex = rand(1:size(qt.elements, 1))
  end

  QuadTreeMeshes.subdivide!(qt, elIndex, subdividefunc)
end

function get_neighbour_from_index(qt::QuadTreeMeshes.QuadTree, elIndex::Int, neighIndex::Int)
  el = qt.elements[elIndex]
  if (neighIndex == 1)
    return el.northWest
  end
  if (neighIndex == 2)
    return el.northEast
  end
  if (neighIndex == 3)
    return el.southWest
  end
  if (neighIndex == 4)
    return el.southEast
  end
end

function check_subdivision_levels(qt::QuadTreeMeshes.QuadTree)
  segments = Array{GeometryTypes.LineSegment{GeometryTypes.Point{2, Float64}},1}()

  # collect all boundary edges of leaves
  for curNode in qt.elements
    if (isnull(curNode.northWest))
      bb = QuadTreeMeshes.get_element_bounding_box(qt, curNode)
      push!(segments, GeometryTypes.LineSegment(GeometryTypes.Point{2, Float64}(bb.x, bb.y), GeometryTypes.Point{2,Float64}(bb.x + bb.w, bb.y)))
      push!(segments, GeometryTypes.LineSegment(GeometryTypes.Point{2, Float64}(bb.x + bb.w, bb.y), GeometryTypes.Point{2, Float64}(bb.x + bb.w, bb.y + bb.h)))
      push!(segments, GeometryTypes.LineSegment(GeometryTypes.Point{2, Float64}(bb.x, bb.y), GeometryTypes.Point{2, Float64}(bb.x, bb.y + bb.h)))
      push!(segments, GeometryTypes.LineSegment(GeometryTypes.Point{2, Float64}(bb.x, bb.y + bb.h), GeometryTypes.Point{2, Float64}(bb.x + bb.w, bb.y + bb.h)))
    end
  end

  # intersecting boundary edges need to have at least one endpoint in common
  while !isempty(segments)
    curSeg = pop!(segments)

    for testSeg in segments
      r0, r1 = testSeg
      t0, t1 = curSeg
      # check if they are parallel and instersect
      if (dot((r0 - r1), (t0-t1))) != 0
        intersects = line_intersects_line(curSeg, testSeg)
        if intersects
          @test isapprox(r0, t0) || isapprox(r0, t1) || isapprox(r1, t0) || isapprox(r1, t1)
          if !(isapprox(r0, t0) || isapprox(r0, t1) || isapprox(r1, t0) || isapprox(r1, t1))
            @assert(false)
          end
        end
      end
    end
  end
end
