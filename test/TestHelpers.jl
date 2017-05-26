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
      bb = curNode.boundingBox
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
