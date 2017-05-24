@testset "QuadTreeTests" begin
    @testset "Neighbour search NE" begin
      bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
      q = QuadTreeMeshes.QuadTree{Int}(bb)

      # subdivide twice
      QuadTreeMeshes.subdivide!(q, 1)
      firstElement = get_neighbour_from_index(q, 1, 2)
      QuadTreeMeshes.subdivide!(q, get(firstElement))

      # and plot it
      #filename = "subdivide_plot_4.svg"
      #Plots.plot(q)
      #Plots.savefig(filename)

      @test get(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.south)) == 5
      @test get(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.west)) == 2
      @test isnull(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.east))
      @test isnull(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.north))
      @test get(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.east)) == 3
      @test get(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.north)) == 3

      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.west)) == 2
      @test isnull(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.north))
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.east)) == 7
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.south)) == 8

      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.west)) == 6
      @test isnull(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.north))
      @test isnull(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.east))
      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.south)) == 9
      #println("$q")
    end

    @testset "Neighbour search SE" begin
      bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
      q = QuadTreeMeshes.QuadTree{Int}(bb)

      # subdivide twice
      QuadTreeMeshes.subdivide!(q, 1)
      firstElement = get_neighbour_from_index(q, 1, 4)
      QuadTreeMeshes.subdivide!(q, get(firstElement))

      # and plot it
      #filename = "subdivide_plot_3.svg"
      #Plots.plot(q)
      #Plots.savefig(filename)

      @test isnull(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.south))
      @test get(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.west)) == 4
      @test isnull(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.east))
      @test get(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.north)) == 3
      @test get(QuadTreeMeshes.find_neighbour(q, 4, QuadTreeMeshes.east)) == 5
      @test get(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.south)) == 5

      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.west)) == 4
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.north)) == 3
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.east)) == 7
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.south)) == 8

      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.west)) == 6
      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.north)) == 3
      @test isnull(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.east))
      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.south)) == 9
      #println("$q")
    end

    @testset "Neighbour search SW" begin
      bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
      q = QuadTreeMeshes.QuadTree{Int}(bb)

      # subdivide twice
      QuadTreeMeshes.subdivide!(q, 1)
      firstElement = get_neighbour_from_index(q, 1, 3)
      QuadTreeMeshes.subdivide!(q, get(firstElement))

      # and plot it
      #filename = "subdivide_plot_2.svg"
      #Plots.plot(q)
      #Plots.savefig(filename)

      @test isnull(QuadTreeMeshes.find_neighbour(q, 4, QuadTreeMeshes.south))
      @test get(QuadTreeMeshes.find_neighbour(q, 4, QuadTreeMeshes.east)) == 5
      @test isnull(QuadTreeMeshes.find_neighbour(q, 4, QuadTreeMeshes.west))
      @test get(QuadTreeMeshes.find_neighbour(q, 4, QuadTreeMeshes.north)) == 2
      @test get(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.west)) == 4
      @test get(QuadTreeMeshes.find_neighbour(q, 5, QuadTreeMeshes.north)) == 3

      @test isnull(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.west))
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.north)) == 2
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.east)) == 7
      @test get(QuadTreeMeshes.find_neighbour(q, 6, QuadTreeMeshes.south)) == 8

      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.west)) == 6
      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.north)) == 2
      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.east)) == 5
      @test get(QuadTreeMeshes.find_neighbour(q, 7, QuadTreeMeshes.south)) == 9
      #println("$q")
    end

    @testset "Neighbour search NW" begin
      bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
      q = QuadTreeMeshes.QuadTree{Int}(bb)

      # subdivide twice
      QuadTreeMeshes.subdivide!(q, 1)
      firstElement = get_neighbour_from_index(q, 1, 1)
      QuadTreeMeshes.subdivide!(q, get(firstElement))

      # and plot it
      #filename = "subdivide_plot_1.svg"
      #Plots.plot(q)
      #Plots.savefig(filename)

      @test isnull(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.north))
      @test get(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.east)) == 3
      @test isnull(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.west))
      @test get(QuadTreeMeshes.find_neighbour(q, 2, QuadTreeMeshes.south)) == 4
      @test get(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.west)) == 2
      @test get(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.south)) == 5
      @test isnull(QuadTreeMeshes.find_neighbour(q, 3, QuadTreeMeshes.north))

      #println("$q")
    end

    @testset "Random Line Subdivision" begin
    # seed rng and store seed in file
    #local seed = 338139087
    local seed = rand(UInt32)
    local fs = open("RandomLineSubdivision.seed", "w")
    write(fs, string(seed))
    close(fs)
    srand(seed)

    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    q = QuadTreeMeshes.QuadTree{Int}(bb)

    # pick random line inside bounding box
    linepos = rand(Float64, 4) * 2.0
    r1 = GeometryTypes.Point(linepos[1] + 2.0, linepos[2] + 3.0)
    r2 = GeometryTypes.Point(linepos[3] + 2.0, linepos[4] + 3.0)
    ls = GeometryTypes.LineSegment(r1, r2)
    QuadTreeMeshes.refine_line_to_level(q, ls, 6)

    # and plot it
    filename = "random_line_subdivision.svg"
    Plots.plot(q)
    Plots.plot!([r1[1], r2[1]], [r1[2], r2[2]])
    Plots.savefig(filename)

    # go through all elements and check that they either don't intersect
    # or are in the list
    for (elIndex, el) in enumerate(q.elements)
      if (!QuadTreeMeshes.has_child(q, elIndex))
        intersecting = line_intersects_rectangle(el.boundingBox, ls)
        if intersecting
          @test q.elements[elIndex].level == 6
        end
      end
    end
  end

  @testset "Random Line Intersection" begin
    # seed rng and store seed in file
    #local seed = 4196620933
    local seed = rand(UInt32)
    local fs = open("RandomLineIntersection.seed", "w")
    write(fs, string(seed))
    close(fs)
    srand(seed)

    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    q = QuadTreeMeshes.QuadTree{Int}(bb)

    # subdivide three random children
    QuadTreeMeshes.subdivide!(q, 1)
    subdivide_random!(q)
    subdivide_random!(q)
    subdivide_random!(q)

    # pick random line inside bounding box
    linepos = rand(Float64, 4) * 2.0
    r1 = GeometryTypes.Point(linepos[1] + 2.0, linepos[2] + 3.0)
    r2 = GeometryTypes.Point(linepos[3] + 2.0, linepos[4] + 3.0)
    ls = GeometryTypes.LineSegment(r1, r2)
    intersectingLeaves = QuadTreeMeshes.query_line(q, ls)

    # and plot it
    #filename = "random_line_intersection.svg"
    #Plots.plot(q)
    #Plots.plot!([r1[1], r2[1]], [r1[2], r2[2]])
    #Plots.savefig(filename)

    # go through all elements and check that they either don't intersect
    # or are in the list
    for (elIndex, el) in enumerate(q.elements)
      if (!QuadTreeMeshes.has_child(q, elIndex))
        intersecting = line_intersects_rectangle(el.boundingBox, ls)
        interPos = findfirst(intersectingLeaves, elIndex)
        if intersecting
          @test interPos > 0
          if (interPos > 0)
            deleteat!(intersectingLeaves, interPos)
          end
        else
          @test interPos == 0
        end
      end
    end
    @test size(intersectingLeaves)[1] == 0
  end

  @testset "Subdivide Level 2" begin for u in 1:4, v in 1:4 begin
    bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
    q = QuadTreeMeshes.QuadTree{Int}(bb)

    # subdivide twice
    QuadTreeMeshes.subdivide!(q, 1)
    firstElement = get_neighbour_from_index(q, 1, u)
    QuadTreeMeshes.subdivide!(q, get(firstElement))
    secondElement = get_neighbour_from_index(q, get(firstElement), v)
    QuadTreeMeshes.subdivide!(q, get(secondElement))

    # check that all levels are correctly subdivided
    # (i.e. it is balanced)
    check_subdivision_levels(q)

    # and plot it
    #filename = "subdivide_plot_$u$v.svg"
    #Plots.plot(q)
    #Plots.savefig(filename)
  end
  end
  end

  @testset "Constructor" begin

  # construct quadtree object and check that types are correct
  bb = GeometryTypes.SimpleRectangle(2.0, 3.0, 4.0, 4.0)
  q = QuadTreeMeshes.QuadTree{Int}(bb)

  @test length(q.elements) == 1
  firstEl = q.elements[1]
  @test isnull(firstEl.parent)
  @test isnull(firstEl.northWest)
  @test isnull(firstEl.northEast)
  @test isnull(firstEl.southEast)
  @test isnull(firstEl.southWest)
  @test firstEl.level == 1
  @test firstEl.index == 1
  @test firstEl.boundingBox == bb
  @test typeof(q.values) == Array{Array{Int, 1}, 1}
  @test length(q.values) == 1
  end
end
