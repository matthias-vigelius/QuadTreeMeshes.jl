@enum Boundary None=1 Sides=2 Center=3

type MeshElement
  triangle_indices::Array{triangle_index, 1}

  boundary_type::Boundary

  center::Nullable{vertex_index}
  in_boundary::Nullable{vertex_index}
  out_boundary::Nullable{vertex_index}
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
  indices = Array{Int64, 1}()
  for t in templates
    template = [leave_vertex_indices[t[1]], leave_vertex_indices[t[2]], leave_vertex_indices[t[3]]]
    triangle = Triangle(template)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
  end

  # create new mesh element and add to list
  new_mesh_element = MeshElement(indices, None, Nullable{vertex_index}(), Nullable{vertex_index}(), Nullable{vertex_index}())
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
  indices = Array{Int64, 1}()
  for t in templates
    template = [leave_vertex_indices[t[1]], leave_vertex_indices[t[2]], leave_vertex_indices[t[3]]]
    triangle = Triangle(template)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
  end

  # create new mesh element and add to list
  new_mesh_element = MeshElement(indices, Sides, Nullable{vertex_index}(), Nullable{vertex_index}(bnd1Index), Nullable{vertex_index}(bnd2Index))
  qt.values[elIndex] = Nullable{QuadTreeMeshes.MeshElement}(new_mesh_element)
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

  triangleIndices = Array{Int64, 1}()
  @assert(bd1Pos != northWest || bd2pos != northWest)
  if bd1pos != northWest && bd2pos != northWest
      triangle = Triangle(qtEl.bbLeftTopIndex, vIndex, qtEl.bbRightTopIndex)
      push!(mesh.triangles, triangle)
      push!(indices, length(mesh.triangles))
  else
    if bd1pos == northWest
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle(qtEl.bbLeftTopIndex, vIndex, bdIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
    triangle = Triangle(qtEl.bbRightTopIndex, bdIndex, vIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
  end
  @assert(bd1Pos != northEast || bd2pos != northEast)
  if bd1pos != northEast && bd2pos != northEast
      triangle = Triangle(qtEl.bbLeftTopIndex, vIndex, qtEl.bbRightTopIndex)
      push!(mesh.triangles, triangle)
      push!(indices, length(mesh.triangles))
  else
    if bd1pos == northEast
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle(qtEl.bbLeftTopIndex, vIndex, bdIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
    triangle = Triangle(qtEl.bbRightTopIndex, bdIndex, vIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
  end
  @assert(bd1Pos != southWest || bd2pos != southWest)
  if bd1pos != southWest && bd2pos != southWest
      triangle = Triangle(qtEl.bbLeftBottomIndex, vIndex, qtEl.bbRightBottomIndex)
      push!(mesh.triangles, triangle)
      push!(indices, length(mesh.triangles))
  else
    if bd1pos == southWest
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle(qtEl.bbLeftBottomIndex, vIndex, bdIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
    triangle = Triangle(qtEl.bbRightBottomIndex, bdIndex, vIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
  end
  @assert(bd1Pos != southEast || bd2pos != southEast)
  if bd1pos != southEast && bd2pos != southEast
      triangle = Triangle(qtEl.bbLeftBottomIndex, vIndex, qtEl.bbRightBottomIndex)
      push!(mesh.triangles, triangle)
      push!(indices, length(mesh.triangles))
  else
    if bd1pos == southEast
      bdIndex = bnd1Index
    else
      bdIndex = bnd2Index
    end
    triangle = Triangle(qtEl.bbLeftBottomIndex, vIndex, bdIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
    triangle = Triangle(qtEl.bbRightBottomIndex, bdIndex, vIndex)
    push!(mesh.triangles, triangle)
    push!(indices, length(mesh.triangles))
  end

  # create new mesh element and add to list
  new_mesh_element = MeshElement(indices, Center, Nullable{vertex_index}(vIndex), Nullable{vertex_index}(bnd1Index), Nullable{vertex_index}(bnd2Index))
  qt.values[elIndex] = Nullable{QuadTreeMeshes.MeshElement}(new_mesh_element)
end

type BoundaryVertices
  # Bool:
  # for west and east boundaries: true = from south to north is outgoing
  # for north and south boundaries: true = from west to east is outgoing
  # indices for outer boundaries
  nnw_index::Nullable{Tuple{vertex_index, Bool}}
  nne_index::Nullable{Tuple{vertex_index, Bool}}
  nee_index::Nullable{Tuple{vertex_index, Bool}}
  see_index::Nullable{Tuple{vertex_index, Bool}}
  sse_index::Nullable{Tuple{vertex_index, Bool}}
  ssw_index::Nullable{Tuple{vertex_index, Bool}}
  sww_index::Nullable{Tuple{vertex_index, Bool}}
  nww_index::Nullable{Tuple{vertex_index, Bool}}

  # indices for inner boundary vertices
  nc_index::Nullable{Tuple{vertex_index, Bool}}
  wc_index::Nullable{Tuple{vertex_index, Bool}}
  ec_index::Nullable{Tuple{vertex_index, Bool}}
  sc_index::Nullable{Tuple{vertex_index, Bool}}

  # indices for center vertices
  nw_index::Nullable{vertex_index}
  ne_index::Nullable{vertex_index}
  sw_index::Nullable{vertex_index}
  se_index::Nullable{vertex_index}
end

BoundaryVertices() = BoundaryVertices(
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{Tuple{vertex_index, Bool}}(),
  Nullable{vertex_index}(),
  Nullable{vertex_index}(),
  Nullable{vertex_index}(),
  Nullable{vertex_index}()
  )

function find_intersection(qt::QuadTree, vertex_1::vertex_index, vertex_2::vertex_index, test_vertex_1::vertex_index, test_vertex_2::vertex_index)
  # get line segment from vertices
  element_segment = GeometryTypes.LineSegment(qt.vertices[vertex_1], qt.vertices[vertex_2])

  test_segment = GeometryTypes.LineSegment(qt.vertices[test_vertex_1], qt.vertices[test_vertex_2])
  does_intersect, intersection = GeometryTypes.intersects(element_segment, test_segment)
  if (!does_intersect)
    return Nullable{Tuple{vertex_index, Bool}}()
  end

  # check if intersection point is one of the vertices
  d1 = intersection - qt.vertices[vertex_1]
  d2 = intersection - qt.vertices[vertex_2]
  #println("$(intersection), $(qt.vertices[vertex_1]), $(qt.vertices[vertex_2])")
  if dot(d1,d1) < 1e-10
    intersection_vertex = vertex_1
  elseif dot(d2,d2) < 1e-10
    intersection_vertex = vertex_2
  else
    push!(qt.vertices, intersection)
    intersection_vertex = length(qt.vertices)
  end

  # we need to determine intersection direction
  # note that test segments are axis-aligned and only have positive components
  dir_vertex_segment = (element_segment[2] - element_segment[1])
  dir_test_segment = (test_segment[2] - test_segment[1])
  #      TODO dot(dir_vertex_segment, dir_test_segment) > 0
  if dir_vertex_segment[1] * dir_test_segment[2] > 0
    return Nullable{Tuple{vertex_index, Bool}}((intersection_vertex, true))
  elseif dir_vertex_segment[1] * dir_test_segment[2] < 0
    return Nullable{Tuple{vertex_index, Bool}}((intersection_vertex, false))
  end
  if dir_vertex_segment[2] * dir_test_segment[1] > 0
    return Nullable{Tuple{vertex_index, Bool}}((intersection_vertex, true))
  elseif dir_vertex_segment[2] * dir_test_segment[1] < 0
    return Nullable{Tuple{vertex_index, Bool}}((intersection_vertex, false))
  end

  # we should never get here
  @assert(false)
  return Nullable{Tuple{vertex_index, Bool}}()
end

function get_boundary_structure(qt::QuadTree, elIndex::ElIndex, toVertex::Bool)
  qt_element = qt.elements[elIndex]
  mesh_element = get(qt.values[elIndex])

  bv = BoundaryVertices()

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

  # determine boundary line segment
  if !isnull(mesh_element.center)
    center_vertex = get(mesh_element.center)
    center_position = qt.vertices[mesh_element.center]
    if (center_position[1] <  (qt.vertices[n_vertex])[1])
      if (center_position[2] <  (qt.vertices[c_vertex])[2])
        bv.sw_index = Nullable{vertex_index}(center_vertex)
      else
        bv.nw_index = Nullable{vertex_index}(center_vertex)
      end
    else
      if (center_position[2] <  (qt.vertices[c_vertex])[2])
        bv.se_index = Nullable{vertex_index}(center_vertex)
      else
        bv.ne_index = Nullable{vertex_index}(center_vertex)
      end
      #TODO: what about equality..
    end

    if toVertex
      in_boundary = mesh_element.in_boundary
      out_boundary = mesh_element.center
    else
      in_boundary = mesh_element.center
      out_boundary = mesh_element.out_boundary
    end
  else
    in_boundary = mesh_element.in_boundary
    out_boundary = mesh_element.out_boundary
  end

  # compute intersection position for all bounding box segments of inner children
  bv.nnw_index = find_intersection(qt, nw_vertex, n_vertex, get(in_boundary), get(out_boundary))
  bv.nne_index = find_intersection(qt, n_vertex, ne_vertex, get(in_boundary), get(out_boundary))
  bv.nee_index = find_intersection(qt, e_vertex, ne_vertex, get(in_boundary), get(out_boundary))
  bv.see_index = find_intersection(qt, se_vertex, e_vertex, get(in_boundary), get(out_boundary))
  bv.sse_index = find_intersection(qt, s_vertex, se_vertex, get(in_boundary), get(out_boundary))
  bv.ssw_index = find_intersection(qt, sw_vertex, s_vertex, get(in_boundary), get(out_boundary))
  bv.sww_index = find_intersection(qt, sw_vertex, w_vertex, get(in_boundary), get(out_boundary))
  bv.nww_index = find_intersection(qt, w_vertex, nw_vertex, get(in_boundary), get(out_boundary))

  bv.nc_index = find_intersection(qt, c_vertex, n_vertex, get(in_boundary), get(out_boundary))
  bv.wc_index = find_intersection(qt, w_vertex, c_vertex, get(in_boundary), get(out_boundary))
  bv.ec_index = find_intersection(qt, c_vertex, e_vertex, get(in_boundary), get(out_boundary))
  bv.sc_index = find_intersection(qt, s_vertex, c_vertex, get(in_boundary), get(out_boundary))

  return bv
end

function update_boundary_from_index(test_index::Nullable{Tuple{vertex_index, Bool}}, relevant_in_boundary::Nullable{vertex_index}, relevant_out_boundary::Nullable{vertex_index}, invert_direction::Bool)
  if !isnull(test_index)
    bi, dir = get(test_index)
    if (invert_direction)
      dir = !dir
    end
    if dir
      @assert(isnull(relevant_in_boundary) || get(relevant_in_boundary) == bi)
      return Nullable{vertex_index}(bi), relevant_out_boundary
    else
      @assert(isnull(relevant_out_boundary) || get(relevant_out_boundary) == bi)
      return relevant_in_boundary, Nullable{vertex_index}(bi)
    end
  end

  return relevant_in_boundary, relevant_out_boundary
end

function update_child(qt::QuadTree, elIndex::ElIndex, boundaries::BoundaryVertices)
  leave_dir = get_leave_dir(qt, elIndex)

  relevant_in_boundary = Nullable{vertex_index}()
  relevant_out_boundary = Nullable{vertex_index}()
  relevant_vertex = Nullable{vertex_index}()

  #println("$boundaries")
  if leave_dir == northWest
    #println("Updating north west")
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.nnw_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.nww_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.wc_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.nc_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_vertex = boundaries.nw_index
  elseif leave_dir == northEast
    #println("Updating north east")
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.nne_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.nee_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.ec_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.nc_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_vertex = boundaries.ne_index
  elseif leave_dir == southWest
    #println("Updating south west")
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.ssw_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.sww_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.wc_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.sc_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_vertex = boundaries.sw_index
  elseif leave_dir == southEast
    #println("Updating south east")
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.sse_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.see_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.ec_index, relevant_in_boundary, relevant_out_boundary, true)
    relevant_in_boundary, relevant_out_boundary = update_boundary_from_index(boundaries.sc_index, relevant_in_boundary, relevant_out_boundary, false)
    relevant_vertex = boundaries.se_index
  end

  # create new element containing only the boundaries
  new_mesh_element = MeshElement(Array{triangle_index, 1}(), None, relevant_vertex, relevant_in_boundary, relevant_out_boundary)
  qt.values[elIndex] = Nullable(new_mesh_element)
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

  if isnull(mesh_element.center)
    bs = get_boundary_structure(qt, elIndex, false)
    update_child(qt, get(qt_element.northWest), bs)
    update_child(qt, get(qt_element.northEast), bs)
    update_child(qt, get(qt_element.southWest), bs)
    update_child(qt, get(qt_element.southEast), bs)
  else
    bs = get_boundary_structure(qt, elIndex, true)
    update_child(qt, get(qt_element.northWest), bs)
    update_child(qt, get(qt_element.northEast), bs)
    update_child(qt, get(qt_element.southWest), bs)
    update_child(qt, get(qt_element.southEast), bs)
    bs = get_boundary_structure(qt, elIndex, false)
    update_child(qt, get(qt_element.northWest), bs)
    update_child(qt, get(qt_element.northEast), bs)
    update_child(qt, get(qt_element.southWest), bs)
    update_child(qt, get(qt_element.southEast), bs)
  end
end
