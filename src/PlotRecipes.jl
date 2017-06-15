import Plots
using RecipesBase

@recipe function f(qt::QuadTreeMeshes.QuadTree)
  linecolor --> :red
  linewidth --> :2
  seriestype := :path
  grid := false

  x = zeros(0)
  y = zeros(0)

  for qte in qt.elements
    bb = QuadTreeMeshes.get_element_bounding_box(qt, qte)
    xe = [bb.x, bb.x + bb.w, bb.x + bb.w, bb.x, bb.x, NaN]
    ye = [bb.y, bb.y, bb.y + bb.h, bb.y + bb.h, bb.y, NaN]
    append!(x, xe)
    append!(y, ye)
  end

  "x" => x , "y" => y
end

@recipe function f(mesh::QuadTreeMeshes.QuadTreeMesh)
  linecolor --> :blue
  linewidth --> :2
  seriestype := :path
  grid := false

  x = zeros(0)
  y = zeros(0)

  qt = mesh.quadtree

  for triangle in mesh.triangles
    vi = triangle.vertex_indices
    v1 = qt.vertices[vi[1]]
    v2 = qt.vertices[vi[2]]
    v3 = qt.vertices[vi[3]]

    xe = [v1[1], v2[1], v3[1], v1[1], NaN]
    ye = [v1[2], v2[2], v3[2], v1[2], NaN]

    append!(x, xe)
    append!(y, ye)
  end

  x, y
end
