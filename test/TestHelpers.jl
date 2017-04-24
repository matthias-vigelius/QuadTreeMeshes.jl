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

  QuadTreeMeshes.subdivide!(qt, elIndex)
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
    if (!isnull(curNode.northWest))
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
        intersects, ip = GeometryTypes.intersects(curSeg, testSeg)
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
