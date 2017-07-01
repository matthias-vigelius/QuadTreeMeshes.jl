import GeometryTypes

@enum DIR north=1 west=2 south=3 east=4
@enum POS northWest=1 northEast=2 southWest=3 southEast=4

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

  bbLeftBottomIndex::vertex_index
  bbRightBottomIndex::vertex_index
  bbLeftTopIndex::vertex_index
  bbRightTopIndex::vertex_index
end

type QuadTree{T}

  elements::Array{QuadTreeElement, 1}
  values::Array{Nullable{T}, 1}
  vertices::Array{Point, 1}

  function QuadTree(bb::GeometryTypes.SimpleRectangle{Float64})
    @assert GeometryTypes.width(bb) == GeometryTypes.height(bb)
    @assert GeometryTypes.width(bb) > 0
    @assert GeometryTypes.height(bb) > 0
    bl = Point(GeometryTypes.origin(bb))
    br = bl + GeometryTypes.width(bb) * GeometryTypes.Vec(1.0,0.0)
    tr = br + GeometryTypes.height(bb) * GeometryTypes.Vec(0.0,1.0)
    tl = bl + GeometryTypes.height(bb) * GeometryTypes.Vec(0.0,1.0)
    initialVertices = Array{Point, 1}()
    push!(initialVertices, bl)
    push!(initialVertices, br)
    push!(initialVertices, tl)
    push!(initialVertices, tr)
    root = QuadTreeElement(
      Nullable{Int}(),
      Nullable{Int}(),
      Nullable{Int}(),
      Nullable{Int}(),
      Nullable{Int}(),
      1,
      1,
      1, 2, 3, 4
    )
    new([root], [Nullable{T}()], initialVertices)
  end
end

function has_child(qt::QuadTree, elIndex::ElIndex)
  return !isnull(qt.elements[elIndex].northWest)
end

function push_new_element!{T}(qt::QuadTree{T}, bbbl::vertex_index, bbbr::vertex_index, bbtl::vertex_index, bbtr::vertex_index, newLevel::Int, newIndex::Int, elIndex::Int)
  nwEl = QuadTreeElement(
    Nullable{Int}(elIndex),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    Nullable{Int}(),
    newLevel,
    newIndex,
    bbbl, bbbr, bbtl, bbtr
  )
  push!(qt.elements, nwEl)
  push!(qt.values, Nullable{T}())
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
    find_neighbour(qt::QuadTree, elIndex::ElIndex, dir::DIR)

Computes the index of the neigbour in direction `dir`.
"""
function find_neighbour(qt::QuadTree, eli::ElIndex, dir::DIR)
  if isnull(qt.elements[eli].parent)
    return Nullable{ElIndex}()
  end

  pos::POS = get_leave_dir(qt, eli)
  elp = qt.elements[eli].parent

  if dir == north
    if pos == southWest
      return (qt.elements[get(elp)].northWest)
    end
    if pos == southEast
      return (qt.elements[get(elp)].northEast)
    end

    neighbour = find_neighbour(qt, get(elp), north)
    if isnull(neighbour)
      return Nullable{ElIndex}()
    end

    if !has_child(qt, get(neighbour))
      return neighbour
    end
    if pos == northEast
      return qt.elements[get(neighbour)].southEast
    end
    if pos == northWest
      return qt.elements[get(neighbour)].southWest
    end
  end

  if dir == south
    if pos == northWest
      return (qt.elements[get(elp)].southWest)
    end
    if pos == northEast
      return (qt.elements[get(elp)].southEast)
    end

    neighbour = find_neighbour(qt, get(elp), south)
    if isnull(neighbour)
      return Nullable{ElIndex}()
    end

    if !has_child(qt, get(neighbour))
      return neighbour
    end
    if pos == southEast
      return qt.elements[get(neighbour)].northEast
    end
    if pos == southWest
      return qt.elements[get(neighbour)].northWest
    end
  end

  if dir == west
    if pos == northEast
      return (qt.elements[get(elp)].northWest)
    end
    if pos == southEast
      return (qt.elements[get(elp)].southWest)
    end

    neighbour = find_neighbour(qt, get(elp), west)
    if isnull(neighbour)
      return Nullable{ElIndex}()
    end

    if !has_child(qt, get(neighbour))
      return neighbour
    end
    if pos == northWest
      return qt.elements[get(neighbour)].northEast
    end
    if pos == southWest
      return qt.elements[get(neighbour)].southEast
    end
  end

  if dir == east
    if pos == northWest
      return (qt.elements[get(elp)].northEast)
    end
    if pos == southWest
      return (qt.elements[get(elp)].southEast)
    end

    neighbour = find_neighbour(qt, get(elp), east)
    if isnull(neighbour)
      return Nullable{ElIndex}()
    end

    if !has_child(qt, get(neighbour))
      return neighbour
    end
    if pos == northEast
      return qt.elements[get(neighbour)].northWest
    end
    if pos == southEast
      return qt.elements[get(neighbour)].southWest
    end
  end
end

"""
   get_half_vertex(qt::QuadTree, elIndex::Int, neighbour::ElIndex, dir::DIR)

Returns the vertex index of the half-grid point of element `elIndex` in
direction `dir`.
"""
function get_half_vertex(qt::QuadTree, elIndex::Int, neighbour::ElIndex, dir::DIR)
  neighbourEl = qt.elements[neighbour]
  if dir == north
    seChild = qt.elements[get(neighbourEl.southEast)]
    swChild = qt.elements[get(neighbourEl.southWest)]
    assert(seChild.bbLeftBottomIndex == swChild.bbRightBottomIndex)
    return seChild.bbLeftBottomIndex
  elseif dir == south
    neChild = qt.elements[get(neighbourEl.northEast)]
    nwChild = qt.elements[get(neighbourEl.northWest)]
    assert(nwChild.bbRightTopIndex == neChild.bbLeftTopIndex)
    return nwChild.bbRightTopIndex
  elseif dir == west
    neChild = qt.elements[get(neighbourEl.northEast)]
    seChild = qt.elements[get(neighbourEl.southEast)]
    assert(neChild.bbRightBottomIndex == seChild.bbRightTopIndex)
    return neChild.bbRightBottomIndex
  elseif dir == east
    nwChild = qt.elements[get(neighbourEl.northWest)]
    swChild = qt.elements[get(neighbourEl.southWest)]
    assert(nwChild.bbLeftBottomIndex == swChild.bbLeftTopIndex)
    return nwChild.bbLeftBottomIndex
  end
end

"""
    get_new_center(qt::QuadTree, elIndex::Int, dir::DIR)

If the boundary in direction `dir` is currently undivided, it adds a new
vertex at its center and returns its index. If the boundary is divided and
that vertex hence exists, it only returns its index.
"""
function get_new_center(qt::QuadTree, elIndex::Int, dir::DIR)

  # get vertex indices of requested boundary line
  if dir == north
    v1, v2 = qt.elements[elIndex].bbLeftTopIndex, qt.elements[elIndex].bbRightTopIndex
  elseif dir == south
    v1, v2 = qt.elements[elIndex].bbLeftBottomIndex, qt.elements[elIndex].bbRightBottomIndex
  elseif dir == west
    v1, v2 = qt.elements[elIndex].bbLeftBottomIndex, qt.elements[elIndex].bbLeftTopIndex
  elseif  dir == east
    v1, v2 = qt.elements[elIndex].bbRightBottomIndex, qt.elements[elIndex].bbRightTopIndex
  end

  # check if neighbour is there and if it is divided
  neighbour = find_neighbour(qt, elIndex, dir)
  if (isnull(neighbour) || !has_child(qt, get(neighbour)))
    newCenter = 0.5*(qt.vertices[v1] + qt.vertices[v2])
    push!(qt.vertices, newCenter)
    return length(qt.vertices)
  end

  # need to return center index
  return get_half_vertex(qt, elIndex, get(neighbour), dir)
end

"""
    subdivide!(qt::QuadTree, elIndex::Int, childrenCreated)

Subdivides quadtree element denoted by `elIndex`.

# Remarks
* If necessary, its neighbours are subdivided as well in order to balance the
  tree.
* The element needs to be a leave, i.e. it cannot have any children.
* `childrenCreated(qt::QuadTree, el::QuadTreeElement)` will be called for each cell that was subdivided
"""
function subdivide!(qt::QuadTree, elIndex::Int, childrenCreated)
  qtEl = qt.elements[elIndex]
  @assert(isnull(qtEl.northWest))
  @assert(isnull(qtEl.northEast))
  @assert(isnull(qtEl.southWest))
  @assert(isnull(qtEl.southEast))

  # we need a new center point
  bl = qt.vertices[qtEl.bbLeftBottomIndex]
  br = qt.vertices[qtEl.bbRightBottomIndex]
  tl = qt.vertices[qtEl.bbLeftTopIndex]
  tr = qt.vertices[qtEl.bbRightTopIndex]
  newCenter = 0.25*(bl+br+tl+tr)
  push!(qt.vertices, newCenter)
  newCenterIndex = length(qt.vertices)

  # get boundary center points
  northCenterIndex = get_new_center(qt, elIndex, north)
  southCenterIndex = get_new_center(qt, elIndex, south)
  westCenterIndex = get_new_center(qt, elIndex, west)
  eastCenterIndex = get_new_center(qt, elIndex, east)

  newLevel = qtEl.level + 1
  newIndex = length(qt.elements) + 1

  # northWest
  push_new_element!(qt, westCenterIndex, newCenterIndex, qtEl.bbLeftTopIndex, northCenterIndex, newLevel, newIndex, elIndex)
  qtEl.northWest = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  # northEast
  push_new_element!(qt, newCenterIndex, eastCenterIndex, northCenterIndex, qtEl.bbRightTopIndex, newLevel, newIndex, elIndex)
  qtEl.northEast = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  # southWest
  push_new_element!(qt, qtEl.bbLeftBottomIndex, southCenterIndex, westCenterIndex, newCenterIndex, newLevel, newIndex, elIndex)
  qtEl.southWest = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  # southEast
  push_new_element!(qt, southCenterIndex, qtEl.bbRightBottomIndex, newCenterIndex, eastCenterIndex, newLevel, newIndex, elIndex)
  qtEl.southEast = Nullable{Int}(newIndex)
  newIndex = newIndex + 1

  childrenCreated(qt, elIndex)

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
            subdivide!(qt, child, childrenCreated)
          end
        end
      end
    end
  end
end

function get_element_bounding_box(qt::QuadTree, qtEl::QuadTreeElement)
  bl = qt.vertices[qtEl.bbLeftBottomIndex]
  tr = qt.vertices[qtEl.bbRightTopIndex]
  width = (tr - bl)[1]
  height = (tr - bl)[2]
  bb = GeometryTypes.SimpleRectangle(bl[1], bl[2], width, height)

  return bb
end

function get_element_bounding_box(qt::QuadTree, elIndex::ElIndex)
  qtEl = qt.elements[elIndex]

  return get_element_bounding_box(qt, qtEl)
end

function query(qt::QuadTree, testFunction, curElIndex::ElIndex, els::Array{ElIndex, 1})
  if !testFunction(get_element_bounding_box(qt, curElIndex))
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

function refine_line_to_level(
  qt::QuadTree,
  ls::GeometryTypes.LineSegment{Point},
  targetLevel::Int,
  childrenCreated)
  function filtFunc(eli::ElIndex)
    throwout = !has_child(qt, eli) && qt.elements[eli].level < targetLevel
    return !has_child(qt, eli) && qt.elements[eli].level < targetLevel
  end

  leaves = query_line(qt, ls)
  filter!(filtFunc, leaves)
  while(!isempty(leaves))
    for li in leaves
      if (!has_child(qt, li) && qt.elements[li].level < targetLevel)
        subdivide!(qt, li, childrenCreated)
      end
    end
    leaves = query_line(qt, ls)
    filter!(filtFunc, leaves)
  end
end

"""
    get_element_dir(qt::QuadTree, el::ElIndex)

Gets the relative position of the leave wrt parent.

#Remarks
# If the element is the root element, it returns `northWest`
"""
function get_leave_dir(qt::QuadTree, eli::ElIndex)
  el = qt.elements[eli]
  if (isnull(el.parent))
    return northWest
  end
  elp = qt.elements[get(el.parent)]

  if (!isnull(elp.northWest) && get(elp.northWest) == eli)
    return northWest
  end
  if (!isnull(elp.northEast) && get(elp.northEast) == eli)
    return northEast
  end
  if (!isnull(elp.southWest) && get(elp.southWest) == eli)
    return southWest
  end
  if (!isnull(elp.southEast) && get(elp.southEast) == eli)
    return southEast
  end
  error("Quadtree corruption: cannot locate element $eli in parent node.")
end
