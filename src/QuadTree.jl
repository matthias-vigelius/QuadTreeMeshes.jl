import GeometryTypes

typealias ElIndex Int
typealias Point GeometryTypes.Point{2, Float64}

type QuadTreeElement
  "Index to parent element"
  parent::Nullable{Int}
  "Index to child element"
  northWest::Nullable{Int}
  "Index to child element"
  northEast::Nullable{Int}
  "Index to child element"
  southWest::Nullable{Int}
  "Index to child element"
  southEast::Nullable{Int}
  "Subdivision level (one-based)"
  level::Int
  "Own Index"
  index::Int
  "Bounding box"
  boundingBox::GeometryTypes.SimpleRectangle{Float64}
end

type QuadTree{T}

  elements::Array{QuadTreeElement, 1}
  values::Array{Array{T, 1}, 1}

  function QuadTree(bb::GeometryTypes.SimpleRectangle{Float64})
    @assert GeometryTypes.width(bb) == GeometryTypes.height(bb)
    root = QuadTreeElement(
      Nullable{Int}(),
      Nullable{Int}(),
      Nullable{Int}(),
      Nullable{Int}(),
      Nullable{Int}(),
      1,
      1,
      bb
    )
    new([root], [[]])
  end
end

function has_child(qt::QuadTree, elIndex::ElIndex)
  return !isnull(qt.elements[elIndex].northWest)
end

function push_new_element!(qt::QuadTree, newBB::GeometryTypes.SimpleRectangle, newLevel::Int, newIndex::Int, elIndex::Int)
  nwEl = QuadTreeElement(
    Nullable{Int}(elIndex),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    newLevel,
    newIndex,
    newBB
  )
  push!(qt.elements, nwEl)
  push!(qt.values, [])
end

function get_children(qt::QuadTree, elIndex::Int)
  qtEl = qt.elements[elIndex]
  if isnull(qtEl.northWest)
    children = Nullable{Array{Int, 1}}()
  else
    children = Nullable{Array{Int, 1}}(
                [get(qtEl.northWest),
                get(qtEl.northEast),
                get(qtEl.southWest),
                get(qtEl.southEast)])
  end
  return children
end

"""
    subdivide(qt::QuadTree, elIndex::Int)

Subdivides quadtree element denoted by `elIndex`.

# Remarks
* If necessary, its neighbours are subdivided as well in order to balance the
  tree.
* The element needs to be a leave, i.e. it cannot have any children.
"""
function subdivide!(qt::QuadTree, elIndex::Int)
  qtEl = qt.elements[elIndex]
  @assert(isnull(qtEl.northWest))
  @assert(isnull(qtEl.northEast))
  @assert(isnull(qtEl.southWest))
  @assert(isnull(qtEl.southEast))

  # get center point of bounding box and create new children
  bb = qtEl.boundingBox
  width = GeometryTypes.width(bb)
  newWidth = 0.5*width
  bbCenter = GeometryTypes.origin(bb) + newWidth * GeometryTypes.Vec(1.0,1.0)
  newLevel = qtEl.level + 1
  newIndex = length(qt.elements) + 1

  # northWest
  nwBB = GeometryTypes.SimpleRectangle(GeometryTypes.Vec(bbCenter - newWidth * GeometryTypes.Vec(1.0,0.0)),
                                 newWidth * GeometryTypes.Vec(1.0,1.0))
  push_new_element!(qt, nwBB, newLevel, newIndex, elIndex)
  qtEl.northWest = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  # northEast
  nwBB = GeometryTypes.SimpleRectangle(GeometryTypes.Vec(bbCenter),
                                 newWidth * GeometryTypes.Vec(1.0,1.0))
  push_new_element!(qt, nwBB, newLevel, newIndex, elIndex)
  qtEl.northEast = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  # southWest
  nwBB = GeometryTypes.SimpleRectangle(GeometryTypes.Vec(GeometryTypes.origin(bb)),
                                 newWidth * GeometryTypes.Vec(1.0,1.0))
  push_new_element!(qt, nwBB, newLevel, newIndex, elIndex)
  qtEl.southWest = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  # northWest
  nwBB = GeometryTypes.SimpleRectangle(GeometryTypes.Vec(bbCenter - newWidth * GeometryTypes.Vec(0.0,1.0)),
                                 newWidth * GeometryTypes.Vec(1.0,1.0))
  push_new_element!(qt, nwBB, newLevel, newIndex, elIndex)
  qtEl.southEast = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  # look at this parent's neighbors and check if they need subdiving
  # we only admit a difference in 1 to neighbour's subdivision level
  # that means we need to subdivide parent's neighbour if it has
  # no children
  par = qtEl.parent
  if (!isnull(par))
    parpar = (qt.elements[get(par)]).parent
    if (!isnull(parpar))
      children = get_children(qt, get(parpar))
      if !isnull(children)
        for child in get(children)
          if (child != elIndex) && (!has_child(qt, child))
            subdivide!(qt, child)
          end
        end
      end
    end
  end
end

function query(qt::QuadTree, testFunction, curElIndex::ElIndex, els::Array{ElIndex, 1})
  curEl = qt.elements[curElIndex]
  if !testFunction(curEl.boundingBox)
    return els
  end

  children = get_children(qt, curElIndex)
  if (!isnull(children))
    ch = get(children)
    nw = query(qt, testFunction, ch[1], Array{ElIndex, 1}())
    ne = query(qt, testFunction, ch[2], Array{ElIndex, 1}())
    sw = query(qt, testFunction, ch[3], Array{ElIndex, 1}())
    se = query(qt, testFunction, ch[4], Array{ElIndex, 1}())

    return vcat(els, nw, ne, sw, se)
  end

  return vcat(els, [curElIndex])
end


function query_line(qt::QuadTree, ls::GeometryTypes.LineSegment{Point})
  # taken from
  # http://stackoverflow.com/questions/99353/how-to-test-if-a-line-segment-intersects-an-axis-aligned-rectange-in-2d
  function line_intersects_rectangle(r::GeometryTypes.SimpleRectangle{Float64})
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

  return query(qt, line_intersects_rectangle, 1, Array{ElIndex, 1}())
end

function refine_line_to_level(qt::QuadTree, ls::GeometryTypes.LineSegment{Point}, targetLevel::Int)
  function filtFunc(eli::ElIndex)
    throwout = !has_child(qt, eli) && qt.elements[eli].level < targetLevel
    return !has_child(qt, eli) && qt.elements[eli].level < targetLevel
  end

  leaves = query_line(qt, ls)
  filter!(filtFunc, leaves)
  while(!isempty(leaves))
    for li in leaves
      if (!has_child(qt, li) && qt.elements[li].level < targetLevel)
        subdivide!(qt, li)
      end
    end
    leaves = query_line(qt, ls)
    filter!(filtFunc, leaves)
  end
end
