import Plots
using RecipesBase

@recipe function f(qte::QuadTreeMeshes.QuadTreeElement)
  linecolor --> :red
  linewidth --> :2
  seriestype := :path
  bb = qte.boundingBox
  x = [bb.x, bb.x + bb.w, bb.x + bb.w, bb.x, bb.x, NaN]
  y = [bb.y, bb.y, bb.y + bb.h, bb.y + bb.h, bb.y, NaN]

  x, y
end

@recipe function f(qt::QuadTreeMeshes.QuadTree)
  linecolor --> :red
  linewidth --> :2
  seriestype := :path

  x = zeros(0)
  y = zeros(0)

  for qte in qt.elements
    bb = qte.boundingBox
    xe = [bb.x, bb.x + bb.w, bb.x + bb.w, bb.x, bb.x, NaN]
    ye = [bb.y, bb.y, bb.y + bb.h, bb.y + bb.h, bb.y, NaN]
    append!(x, xe)
    append!(y, ye)
  end

  x, y
end
