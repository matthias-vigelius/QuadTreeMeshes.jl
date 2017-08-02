@enum Boundary None=1 Sides=2 Center=3
@enum VertexType Inner=1 Outer=2
@enum InnerBoundaryPos  nnw = 1 nne = 2 nee = 3 see =4 sse = 5 ssw = 6 sww = 7 nww = 8 n = 9 s = 10 w = 11 e = 12

type BoundaryVertex
  vt::VertexType # needed
  quadrant::POS
  boundary::InnerBoundaryPos # needed
  crossing_dir::Bool # positive: crossing in positive direction (left->right, bottom->top)
  vertex::vertex_index #needed
end

const BoundaryVertices = Array{Tuple{BoundaryVertex, BoundaryVertex}, 1}

type MeshElement
  triangle_indices::Array{triangle_index, 1}
  boundary_type::Boundary
  boundaries::BoundaryVertices
  center::Nullable{vertex_index}
end

type Triangle
  vertex_indices::Array{vertex_index, 1}
end

# these provide indices into the connectors array for each inner template
# bit patterns give the occupation of the edge mid points (boundaries are
# always occupied)
inner_templates = [
  [[1, 5, 13], [5,9,13]], # 0000
  [[1, 3, 13], [13, 3, 9], [3, 5, 9]], # 0001 - south
  [[1, 11, 13], [1, 11, 5], [5, 11, 9]], # 0010 - north
  [[1, 3, 13], [3, 11, 13], [3, 5, 11], [11, 5, 9]], # 0011 - sn
  [[1, 5, 7], [1, 7, 13], [13, 7, 9]], # 0100 - east
  [[1, 5, 7], [1, 7, 15], [7, 9, 13], [15, 7, 13]], # 0101
  [[1, 5, 7], [7, 9, 11], [1, 11, 13], [1, 7, 11]], # 0110
  [[1, 3, 7], [1, 7, 15], [15, 7, 11], [15, 11, 13], [11, 7, 9]], # 0111
  [[1, 5, 15], [5, 15, 9], [15, 9, 13]], # 1000 - west
  [[1, 3, 15], [3, 5, 9], [15, 9, 13], [3, 9, 15]], # 1001
  [[1, 11, 13], [1, 3, 11], [3, 5, 11], [5, 9, 11]], # 1010
  [[1, 3, 15], [3, 11, 15], [3, 5, 11], [5, 9, 11], [15, 11, 13]], # 1011
  [[1, 3, 13], [3, 5, 7], [7, 9, 13], [3, 7, 13]], # 1100
  [[1, 3, 15], [3, 5, 7], [3, 7, 15], [15, 7, 9], [15, 9, 13]], # 1101
  [[1, 11, 13], [1, 3, 11], [3, 5, 7], [3, 7, 11], [7, 9, 11]], # 1110
  [[1, 3, 15], [3, 5, 7], [15, 3, 11], [15, 11, 13], [3, 7, 11], [7, 9, 11]], # 1111
]

type QuadTreeMesh
  quadtree::QuadTree{MeshElement}
  triangles::Array{Triangle, 1}

  function QuadTreeMesh(bb::GeometryTypes.SimpleRectangle{Float64})
    quadtree = QuadTree{MeshElement}(bb)
    triangles = Array{Triangle, 1}()
    new(quadtree, triangles)
  end

end

"""
    triangulate_leave(qt::QuadTree, elIndex::ElIndex)

Triangulates a leave from `qt`.

# Remarks

* If the leave is not cut by any constraint, it is triangulated according to
  one of six templates
* If the leave contains a constraint vertex, the triangulation is star-shaped
* If the leave is cut but a constraint, it is triangulated according to one of
  18 boundary templates
"""
function triangulate_leave(mesh::QuadTreeMesh, elIndex::ElIndex)

  qt = mesh.quadtree
  qtEl = qt.elements[elIndex]
  @assert(!has_child(qt, elIndex))
  @assert(isnull(qt.values[elIndex]))

  # get vertices of quadtree leave
  # first fill in corner points then half-points
  leave_vertex_indices = zeros(vertex_index, 16)
  leave_vertex_indices[1] = qtEl.bbLeftBottomIndex
  leave_vertex_indices[5] = qtEl.bbRightBottomIndex
  leave_vertex_indices[9] = qtEl.bbRightTopIndex
  leave_vertex_indices[13] = qtEl.bbLeftTopIndex

  shape_index = 0
  neighbour = find_neighbour(qt, elIndex, south)
  if (!isnull(neighbour) && has_child(qt, get(neighbour)))
    shape_index = shape_index + 1
    leave_vertex_indices[3] = get_half_vertex(qt, elIndex, get(neighbour), south)
  end
  neighbour = find_neighbour(qt, elIndex, east)
  if (!isnull(neighbour) && has_child(qt, get(neighbour)))
    shape_index = shape_index + 4
    leave_vertex_indices[7] = get_half_vertex(qt, elIndex, get(neighbour), east)
  end
  neighbour = find_neighbour(qt, elIndex, north)
  if (!isnull(neighbour) && has_child(qt, get(neighbour)))
    shape_index = shape_index + 2
    leave_vertex_indices[11] = get_half_vertex(qt, elIndex, get(neighbour), north)
  end
  neighbour = find_neighbour(qt, elIndex, west)
  if (!isnull(neighbour) && has_child(qt, get(neighbour)))
    shape_index = shape_index + 8
    leave_vertex_indices[15] = get_half_vertex(qt, elIndex, get(neighbour), west)
  end


  # add triangulation templates to triangle list
  templates = inner_templates[shape_index + 1]
  triangle_indices = Array{Int64, 1}()
  for t in templates
    template = [leave_vertex_indices[t[1]], leave_vertex_indices[t[2]], leave_vertex_indices[t[3]]]
    triangle = Triangle(template)
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
  end

  # create new mesh element and add to list
  new_mesh_element = MeshElement(triangle_indices, None, Nullable{vertex_index}(), Nullable{vertex_index}(), Nullable{vertex_index}())
  qt.values[elIndex] = Nullable{QuadTreeMeshes.MeshElement}(new_mesh_element)
end

function get_boundary_vertex_dir(vertex::Point, rt::Point, lb::Point)
  # determine tolerance
  dx, dy = rt - lb

  # shape index bit pattern is wens
  if abs(vertex[2] - rt[2]) < 0.1 * dx
    return 11, 2
  end
  if abs(vertex[2] - lb[2]) < 0.1 * dx
    return 3, 1
  end
  if abs(vertex[1] - lb[1]) < 0.1 * dx
    return 15, 8
  end
  if abs(vertex[1] - rt[1]) < 0.1 * dx
    return 7, 4
  end

  @assert(false)
end

# TODO: corner cases: - constraint along element boundary - vertex at half point - vertex in center


function get_inner_boundary_pos_from_coordinate(vertex::Point, rt::Point, lb::Point)
  # determine tolerance
  dx, dy = rt - lb

  isTop = false
  isLeft = false
  isBottom = false
  isRight = false
  dyt = abs(vertex[2] - rt[2])
  dyb = abs(vertex[2] - lb[2])
  if dyt < 0.1 * dx
    isTop = true
  elseif dyb < 0.1 * dx
    isBottom = true
  end
  dxl = abs(vertex[1] - lb[1])
  dxr = abs(vertex[1] - rt[1]) 
  if dxl < 0.1 * dx
    isLeft = true
  elseif dxr < 0.1 * dx
    isRight = true
  end
  if isTop 
    if dxl < 0.5 * dx
      return nnw
    else
      return nne
    end
  elseif isBottom
    if dxl < 0.5 * dx
      return ssw
    else
      return sse
    end
  elseif isLeft
    if dyt < 0.5 * dy
      return nww
    else
      return sww
    end
  elseif isRight
    if dyt < 0.5 * dy
      return nee
    else
      return see
    end
  else
    @assert(false)
  end
end

function triangulate_boundary_leave(mesh::QuadTreeMesh, elIndex::ElIndex, bnd1Index::vertex_index, bnd2Index::vertex_index)
  qt = mesh.quadtree
  qtEl = qt.elements[elIndex]
  @assert(!has_child(qt, elIndex))
  @assert(isnull(qt.values[elIndex]))

  # get vertices of quadtree leave
  # fill in corner points
  leave_vertex_indices = zeros(vertex_index, 18)
  leave_vertex_indices[1] = qtEl.bbLeftBottomIndex
  leave_vertex_indices[5] = qtEl.bbRightBottomIndex
  leave_vertex_indices[9] = qtEl.bbRightTopIndex
  leave_vertex_indices[13] = qtEl.bbLeftTopIndex
  leave_vertex_indices[17] = bnd1Index
  leave_vertex_indices[18] = bnd2Index

  # boundary leaves cannot have half-grid points
  neighbour = find_neighbour(qt, elIndex, south)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))
  neighbour = find_neighbour(qt, elIndex, north)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))
  neighbour = find_neighbour(qt, elIndex, west)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))
  neighbour = find_neighbour(qt, elIndex, east)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))

  rt = qt.vertices[qtEl.bbRightTopIndex]
  lb = qt.vertices[qtEl.bbLeftBottomIndex]

  # we pretend bnd1 indices are at half grid points -
  # this only concerns the topology
  bnd1Pos, bnd1Shape = get_boundary_vertex_dir(qt.vertices[bnd1Index], rt, lb)
  bnd2Pos, bnd2Shape = get_boundary_vertex_dir(qt.vertices[bnd2Index], rt, lb)
  @assert(bnd1Shape != bnd2Shape) # TODO: this is a special corner case..

  leave_vertex_indices[bnd1Pos] = bnd1Index
  leave_vertex_indices[bnd2Pos] = bnd2Index
  shape_index = bnd1Shape + bnd2Shape

  # add triangulation templates to triangle list
  templates = inner_templates[shape_index + 1]
  triangle_indices = Array{Int64, 1}()
  for t in templates
    template = [leave_vertex_indices[t[1]], leave_vertex_indices[t[2]], leave_vertex_indices[t[3]]]
    triangle = Triangle(template)
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
  end

  # we need to classify the boundary vertices from that triangulation
  # we do not check if the given vertex is actually *on* the boundary
  # we just assume it is
  pos1 = get_inner_boundary_pos_from_coordinate(qt.vertices[bnd1Index], rt, lb)
  pos2 = get_inner_boundary_pos_from_coordinate(qt.vertices[bnd2Index], rt, lb)
  bv1 = BoundaryVertex(Outer, northWest, pos1, true, bnd1Index)
  bv2 = BoundaryVertex(Outer, northWest, pos2, true, bnd2Index)

  # create new mesh element and add to list
  new_mesh_element = MeshElement(triangle_indices, Sides, [(bv1, bv2)], Nullable{vertex_index}())
  qt.values[elIndex] = Nullable{MeshElement}(new_mesh_element)
end

function get_vertex_pos_on_boundary(cp::Point, bd::Point)
  if bd[1] < cp[1]
    if bd[2] < cp[2]
      return northWest
    else
      return southWest
    end
  else
    if bd[2] < cp[2]
      return northEast
    else
      return southEast
    end
  end
end

function triangulate_boundary_leave_with_vertex(mesh::QuadTreeMesh, elIndex::ElIndex, bnd1Index::vertex_index, bnd2Index::vertex_index, vIndex::vertex_index)
  qt = mesh.quadtree
  qtEl = qt.elements[elIndex]
  @assert(!has_child(qt, elIndex))
  @assert(isnull(qt.values[elIndex]))

  # TODO:
  # - get center point and determine position of boundary points
  # - create triangles nw - v - ne or nw - v - b/v - ne - b
  #   and accordingly for all other segments
  # TODO: what about two boundary vertices on same element? disallow for now.

  # TODO: remove for production
  # boundary leaves cannot have half-grid points
  neighbour = find_neighbour(qt, elIndex, south)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))
  neighbour = find_neighbour(qt, elIndex, north)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))
  neighbour = find_neighbour(qt, elIndex, west)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))
  neighbour = find_neighbour(qt, elIndex, east)
  assert(isnull(neighbour) || !has_child(qt, get(neighbour)))

  # get center point and determine position of boundary leave
  rt = qt.vertices[qtEl.bbRightTopIndex]
  lb = qt.vertices[qtEl.bbLeftBottomIndex]
  c = 0.5 * (rt + lb)
  bd1pos = get_vertex_pos_on_boundary(c, qt.vertices[bnd1Index])
  bd2pos = get_vertex_pos_on_boundary(c, qt.vertices[bnd2Index])

  triangle_indices = Array{Int64, 1}()
  @assert(bd1pos != northWest || bd2pos != northWest)
  if bd1pos != northWest && bd2pos != northWest
      triangle = Triangle([qtEl.bbLeftTopIndex, vIndex, qtEl.bbRightTopIndex])
      push!(mesh.triangles, triangle)
      push!(triangle_indices, length(mesh.triangles))
  else
    if bd1pos == northWest
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle([qtEl.bbLeftTopIndex, vIndex, bdIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
    triangle = Triangle([qtEl.bbRightTopIndex, bdIndex, vIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
  end
  @assert(bd1pos != northEast || bd2pos != northEast)
  if bd1pos != northEast && bd2pos != northEast
      triangle = Triangle([qtEl.bbLeftTopIndex, vIndex, qtEl.bbRightTopIndex])
      push!(mesh.triangles, triangle)
      push!(triangle_indices, length(mesh.triangles))
  else
    if bd1pos == northEast
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle([qtEl.bbLeftTopIndex, vIndex, bdIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
    triangle = Triangle([qtEl.bbRightTopIndex, bdIndex, vIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
  end
  @assert(bd1pos != southWest || bd2pos != southWest)
  if bd1pos != southWest && bd2pos != southWest
      triangle = Triangle([qtEl.bbLeftBottomIndex, vIndex, qtEl.bbRightBottomIndex])
      push!(mesh.triangles, triangle)
      push!(triangle_indices, length(mesh.triangles))
  else
    if bd1pos == southWest
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle([qtEl.bbLeftBottomIndex, vIndex, bdIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
    triangle = Triangle([qtEl.bbRightBottomIndex, bdIndex, vIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
  end
  @assert(bd1pos != southEast || bd2pos != southEast)
  if bd1pos != southEast && bd2pos != southEast
      triangle = Triangle([qtEl.bbLeftBottomIndex, vIndex, qtEl.bbRightBottomIndex])
      push!(mesh.triangles, triangle)
      push!(triangle_indices, length(mesh.triangles))
  else
    if bd1pos == southEast
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle([qtEl.bbLeftBottomIndex, vIndex, bdIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
    triangle = Triangle([qtEl.bbRightBottomIndex, bdIndex, vIndex])
    push!(mesh.triangles, triangle)
    push!(triangle_indices, length(mesh.triangles))
  end

  # create new mesh element and add to list
  pos2 = get_inner_boundary_pos_from_coordinate(qt.vertices[bnd1Index], rt, lb)
  nbvv = BoundaryVertex(Inner, northWest, nnw, true, vIndex)
  nbv1 = BoundaryVertex(Outer, northWest, pos2, true, bnd1Index)

  new_mesh_element = MeshElement(triangle_indices, Center, [(nbvv, nbv1)], Nullable{vertex_index}(bnd2Index))
  qt.values[elIndex] = Nullable{QuadTreeMeshes.MeshElement}(new_mesh_element)
end

type LeaveBoundarySegments
  nnw_segment::GeometryTypes.Simplex{2, Point}
  nne_segment::GeometryTypes.Simplex{2, Point}
  nee_segment::GeometryTypes.Simplex{2, Point}
  see_segment::GeometryTypes.Simplex{2, Point}
  sse_segment::GeometryTypes.Simplex{2, Point}
  ssw_segment::GeometryTypes.Simplex{2, Point}
  sww_segment::GeometryTypes.Simplex{2, Point}
  nww_segment::GeometryTypes.Simplex{2, Point}
  n_segment::GeometryTypes.Simplex{2, Point}
  s_segment::GeometryTypes.Simplex{2, Point}
  w_segment::GeometryTypes.Simplex{2, Point}
  e_segment::GeometryTypes.Simplex{2, Point}

  function LeaveBoundarySegments(qt::QuadTree, elIndex::ElIndex)
    qt_element = qt.elements[elIndex]

    # new children
    nw_element = qt.elements[get(qt_element.northWest)]
    ne_element = qt.elements[get(qt_element.northEast)]
    sw_element = qt.elements[get(qt_element.southWest)]
    se_element = qt.elements[get(qt_element.southEast)]

    # all relevant vertices
    nw_vertex = qt_element.bbLeftTopIndex
    n_vertex = nw_element.bbRightTopIndex
    ne_vertex = ne_element.bbRightTopIndex
    e_vertex = ne_element.bbRightBottomIndex
    se_vertex = se_element.bbRightBottomIndex
    s_vertex = se_element.bbLeftBottomIndex
    sw_vertex = sw_element.bbLeftBottomIndex
    w_vertex = sw_element.bbLeftTopIndex
    c_vertex = nw_element.bbRightBottomIndex

    # create segments - make sure they always point in positive x/y dir
    nnw_segment = GeometryTypes.LineSegment(qt.vertices[nw_vertex], qt.vertices[n_vertex])
    nne_segment = GeometryTypes.LineSegment(qt.vertices[n_vertex], qt.vertices[ne_vertex])
    nee_segment = GeometryTypes.LineSegment(qt.vertices[e_vertex], qt.vertices[n_vertex])
    see_segment = GeometryTypes.LineSegment(qt.vertices[se_vertex], qt.vertices[e_vertex])
    sse_segment = GeometryTypes.LineSegment(qt.vertices[s_vertex], qt.vertices[se_vertex])
    ssw_segment = GeometryTypes.LineSegment(qt.vertices[sw_vertex], qt.vertices[s_vertex])
    sww_segment = GeometryTypes.LineSegment(qt.vertices[sw_vertex], qt.vertices[w_vertex])
    nww_segment = GeometryTypes.LineSegment(qt.vertices[w_vertex], qt.vertices[nw_vertex])
    n_segment = GeometryTypes.LineSegment(qt.vertices[c_vertex], qt.vertices[n_vertex])
    s_segment = GeometryTypes.LineSegment(qt.vertices[s_vertex], qt.vertices[c_vertex])
    w_segment = GeometryTypes.LineSegment(qt.vertices[w_vertex], qt.vertices[c_vertex])
    e_segment = GeometryTypes.LineSegment(qt.vertices[c_vertex], qt.vertices[e_vertex])

    new(nnw_segment, nne_segment, nee_segment, see_segment, sse_segment, ssw_segment, sww_segment, nww_segment, n_segment, s_segment, w_segment, e_segment)
  end
end

function intersect(ls1::GeometryTypes.LineSegment, ls2::GeometryTypes.LineSegment)
  # parametric solution - https://gamedev.stackexchange.com/questions/44720/line-intersection-from-parametric-equation
  # returns parameter of first line segment
  s1, e1 = ls1
  s2, e2 = ls2
  s1x, s1y = s1
  s2x, s2y = s2
  e1x, e1y = e1
  e2x, e2y = e2
  # ls1 = a + t b (0 <= t <= 1)
  ax=s1x
  ay=s1y
  b = e1 - s1
  bx, by = b
  cx=s2x
  cy=s2y
  d = e2 - s2
  dx, dy = d
  if ((dx*by-dy*bx) == 0) || ((bx*dy-by*dx) == 0)
    return false, 0, Point(0.,0.), false
  end

  u=(bx*(cy-ay) + by*(ax-cx))/(dx*by-dy*bx)
  t=(dx*(ay-cy) + dy*(cx-ax))/(bx*dy-by*dx)

  if u >= 0 && u <= 1 && t >= 0 && t <= 1
    # get intersection point and intersection dir
    p = Point(ax + t * bx, ay + t * by)
    s = (dx != 0 && bx > 0) || (dy != 0 && by > 0)
    #TODO: I don't think we need the direction
    return true, t, p, s
  else
    return false, 0, Point(0.,0.), true
  end
end

function fill_if_intersects(ls1::GeometryTypes.LineSegment, ls2::GeometryTypes.LineSegment, isp::Array{Tuple{Float64, Point, Bool, InnerBoundaryPos}, 1}, ibp::InnerBoundaryPos)
  i, t, p, s = intersect(ls1, ls2)
  if i
    push!(isp, (t, p, s, ibp))
  end
end

function intersect_with_leave(lbs::LeaveBoundarySegments, ls::GeometryTypes.Simplex{2, Point})
  # get all intersections with all relevant boundary segments
  isp = Array{Tuple{Float64, Point, Bool, InnerBoundaryPos}, 1}()
  fill_if_intersects(ls, lbs.nnw_segment, isp, nnw)
  fill_if_intersects(ls, lbs.nne_segment, isp, nne)
  fill_if_intersects(ls, lbs.nee_segment, isp, nee)
  fill_if_intersects(ls, lbs.see_segment, isp, see)
  fill_if_intersects(ls, lbs.sse_segment, isp, sse)
  fill_if_intersects(ls, lbs.ssw_segment, isp, ssw)
  fill_if_intersects(ls, lbs.sww_segment, isp, sww)
  fill_if_intersects(ls, lbs.nww_segment, isp, nww)
  fill_if_intersects(ls, lbs.n_segment, isp, n)
  fill_if_intersects(ls, lbs.s_segment, isp, s)
  fill_if_intersects(ls, lbs.w_segment, isp, w)
  fill_if_intersects(ls, lbs.e_segment, isp, e)

  # sort them according to distance from start point
  sort!(isp, lt = (is1, is2) -> return is1[1] < is2[1])

  return isp
end

function get_quadrant_from_boundary_position(qt::QuadTree, elIndex::ElIndex, intersectionPoint::BoundaryVertex)
  if intersectionPoint.vt == Outer
    ips = intersectionPoint.boundary
    if ips == nnw || ips == nww
      return (northWest, northWest)
    elseif ips == nne || ips == nee
      return (northEast, northEast)
    elseif ips == sse || ips == see
      return (southEast, southEast)
    elseif ips == ssw || ips == sww
      return (southWest, southWest)
    elseif ips == n
      return (northWest, northEast)
    elseif ips == s
      return (southWest, southEast)
    elseif ips == w
      return (northWest, southWest)
    elseif ips == e
      return (northEast, southEast)
    end
  elseif intersectionPoint.vt == Inner
    vpp = qt.vertices[intersectionPoint.vertex]
    pos = get_child_position_from_coordinate(qt, elIndex, vpp)
    return (pos, pos)
  end
end

# we assume that the members of isp have corrrect boundary, vertex_type, crossing_dir
function forward_boundaries_to_leaves(qt::QuadTree, parent_element::ElIndex, isp::Array{BoundaryVertex})
    #      * for first intersection: assert that second intersection is in same quadrant and fill in structure in child
    #      * for second intersection: assert that third intersection is in same quadrant and fill in structure in child
    #      * etc.. until last pair was found
    @assert(length(isp) >= 2)
    curSecondIdx = 2
    firstIsp = isp[1]
    while curSecondIdx <= length(isp)
      println("$(curSecondIdx), $(length(isp))")
      secondIsp = isp[curSecondIdx]

      # intersection points can belong to two quadrants (if it's on an inner boundary)
      # but at least one of the options should match
      firstPos = get_quadrant_from_boundary_position(qt, parent_element, firstIsp)
      secondPos = get_quadrant_from_boundary_position(qt, parent_element, secondIsp)
      if firstPos[1] == secondPos[1]
        pos = firstPos[1]
      elseif firstPos[2] == secondPos[2]
        pos = firstPos[2]
      else
        @assert(false)
      end

      # create boundary vertices from intersection points and create a new empty leave
      leaveIndex = get_leave_from_pos(qt, parent_element, pos)
      leave = get(qt.values[leaveIndex])
      bv1 = BoundaryVertex(firstIsp.vt, pos, firstIsp.boundary, firstIsp.crossing_dir, firstIsp.vertex)
      bv2 = BoundaryVertex(secondIsp.vt, pos, secondIsp.boundary, secondIsp.crossing_dir, firstIsp.vertex)
      push!(leave.boundaries, (bv1, bv2))
      if (firstIsp.vt == Inner)
        leave.center = Nullable{vertex_index}(firstIsp.vertex)
        leave.boundary_type = Center
      elseif  secondIsp.vt == Inner
        leave.boundary_type = Center
        leave.center = Nullable{vertex_index}(secondIsp.vertex)
      else
        leave.boundary_type = Sides
      end

      firstIsp = secondIsp
      curSecondIdx += 1
    end
end

function propagate_intersections(qt::QuadTree, parent_element::ElIndex, bndy::Tuple{BoundaryVertex, BoundaryVertex})
  lbs = LeaveBoundarySegments(qt, parent_element) # TODO: can probably pull that out of the function
  b1, b2 = bndy
  ls1p1 = qt.vertices[b1.vertex]
  ls1p2 = qt.vertices[b2.vertex]
  ls1 = GeometryTypes.Simplex{2, Point}(ls1p1, ls1p2)
  isps = intersect_with_leave(lbs, ls1)

  # transform intersection points into BoundaryVertex
  allBoundaries = Array{BoundaryVertex, 1}()
  if b1.vt == Inner
    startIndex = 1
    push!(allBoundaries, b1)
  else
    # ignore first intersection point
    startIndex = 2
    push!(allBoundaries, b1)
  end
  for isp in isps[startIndex:length(isps)-1]
    # create vertex and make it into an boundary vertex
    push!(qt.vertices, isp[2])
    newVertexIndex = length(qt.vertices)
    nbv = BoundaryVertex(Outer, northWest, isp[4], isp[3], newVertexIndex)
    push!(allBoundaries,nbv)
  end
  # if second boundary is an inner vertex, push last vertex and inner
  # otherwise just push second vertex
  if b2.vt == Inner
    # push last vertex and end with inner
    push!(allBoundaries, b2)
    push!(allBoundaries,nbv)
  else
    push!(allBoundaries, b2)
  end

  forward_boundaries_to_leaves(qt, parent_element, allBoundaries)
end

"""
  OnChildrenCreated(qt::QuadTree, elIndex::ElIndex)

Will be called when quadtree element `elIndex` is subdivided. This method examines
the element for boundaries and constraint vertices and propagates them to the
children if necessary.

# Remarks
* A constraint vertex is moved into the corresponding child element
* If a boundary is present, it is intersected with the bounding boxes of the inner
  elements and the intersection vertices are stored in the child elements.
"""
function OnChildrenCreated(qt::QuadTree, elIndex::ElIndex)

  mesh_element = get(qt.values[elIndex])
  qt_element = qt.elements[elIndex]

  # create empty leaves for all children
  qt.values[get(qt_element.northWest)] = MeshElement(Array{triangle_index, 1}(), None, BoundaryVertices(), Nullable{vertex_index}())
  qt.values[get(qt_element.northEast)] = MeshElement(Array{triangle_index, 1}(), None, BoundaryVertices(), Nullable{vertex_index}())
  qt.values[get(qt_element.southWest)] = MeshElement(Array{triangle_index, 1}(), None, BoundaryVertices(), Nullable{vertex_index}())
  qt.values[get(qt_element.southEast)] = MeshElement(Array{triangle_index, 1}(), None, BoundaryVertices(), Nullable{vertex_index}())

  for bnd in mesh_element.boundaries
    propagate_intersections(qt, elIndex, bnd)
  end
end
