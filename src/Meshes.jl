type MeshElement
  triangle_indices::Array{triangle_index, 1}

  #boundary_element::Bool
  #vertex::Nullable{vertex_index}
  #line_intersection1::Nullable{Point}
  #line_intersection2::Nullable{Point}
  #snapped_intersection1::Nullable{Int}
  #snapped_intersection2::Nullable{Int}

  """
  Encodes the occupied grid and half-grid connectors as a binary
  to match the template.
  """
  connector_positions::Int
  connectors::FixedSizeArrays.FixedVector{16, vertex_index}
end

type Triangle
  vertex_indices::Array{vertex_index, 1}
end

# these provide indices into the connectors array for each inner template
# bit patterns give the occupation of the edge mid points (boundaries are
# always occupied)
inner_templates = [
  [[1, 5, 13]], # 0000
  [[1, 3, 13], [13, 3, 9], [3, 5, 9]], # 0001
  [[1, 11, 13], [1, 11, 5], [5, 11, 9]], # 0010
  [[1, 5, 15], [5, 9, 11], [15, 11, 3], [5, 11, 15]], # 0011
  [[1, 5, 7], [1, 7, 13], [13, 7, 9]], # 0100
  [[1, 5, 7], [1, 7, 15], [7, 9, 13], [15, 7, 13]], # 0101
  [[1, 5, 7], [7, 9, 11], [1, 11, 13], [1, 7, 11]], # 0110
  [[1, 3, 7], [1, 7, 15], [15, 7, 11], [15, 11, 13], [11, 7, 9]], # 0111
  [[1, 5, 15], [5, 15, 9], [15, 9, 13]], # 1000
  [[1, 3, 15], [3, 5, 9], [15, 9, 13], [3, 9, 15]], # 1001
  [[1, 11, 13], [1, 3, 11], [3, 5, 11], [5, 9, 11]], # 1010
  [[1, 3, 15], [3, 11, 15], [3, 5, 11], [5, 9, 11], [15, 11, 13]], # 1011
  [[1, 3, 13], [3, 5, 7], [7, 9, 13], [3, 7, 13]], # 1100
  [[1, 3, 15], [3, 5, 7], [3, 7, 15], [15, 7, 9], [15, 9, 13]], # 1101
  [[1, 11, 13], [1, 3, 11], [3, 5, 7], [3, 7, 11], [7, 9, 11]], # 1110
  [[1, 3, 15], [3, 5, 7], [15, 3, 11], [15, 11, 13], [3, 7, 11], [7, 9, 11]], # 1111
]

type QuadTreeMesh
  quadTree::QuadTree{Nullable{MeshElement}}
end

# TODO
# - add mesh type containing vertex_indices
# - constructor creates mesh element from quadtree element (adding vertices)
# - quadtree should reference mesh elements
# - only children should have mesh elements - so maybe type is a nullable{MeshElement}.. if child is created, null the parent
