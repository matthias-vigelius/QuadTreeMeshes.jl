type MeshElement
  triangle_indices::Array{triangle_index, 1}

  #boundary_element::Bool
  #vertex::Nullable{vertex_index}
  #line_intersection1::Nullable{Point}
  #line_intersection2::Nullable{Point}
  #snapped_intersection1::Nullable{Int}
  #snapped_intersection2::Nullable{Int}
end

type Triangle
  vertex_indices::FixedSizeArrays.Vec{3, vertex_index}
end

# these provide indices into the connectors array for each inner template
# bit patterns give the occupation of the edge mid points (boundaries are
# always occupied)
inner_templates = [
  [[1, 5, 13], [5,9,13]], # 0000
  [[1, 3, 13], [13, 3, 9], [3, 5, 9]], # 0001 - south
  [[1, 11, 13], [1, 11, 5], [5, 11, 9]], # 0010 - north
  [[1, 5, 15], [5, 9, 11], [15, 11, 3], [5, 11, 15]], # 0011
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
  new_mesh_element = MeshElement(indices)
  qt.values[elIndex] = Nullable{QuadTreeMeshes.MeshElement}(new_mesh_element)
end
