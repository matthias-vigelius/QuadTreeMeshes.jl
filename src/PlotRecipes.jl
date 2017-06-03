import Plots
using RecipesBase

@recipe function f(qt::QuadTreeMeshes.QuadTree)
  linecolor --> :red
  linewidth --> :2
  seriestype := :path

  x = zeros(0)
  y = zeros(0)

  for qte in qt.elements
    bb = QuadTreeMeshes.get_element_bounding_box(qt, qte)
    xe = [bb.x, bb.x + bb.w, bb.x + bb.w, bb.x, bb.x, NaN]
    ye = [bb.y, bb.y, bb.y + bb.h, bb.y + bb.h, bb.y, NaN]
    append!(x, xe)
    append!(y, ye)
  end

  x, y
end
