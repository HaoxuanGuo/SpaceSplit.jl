module SpaceSplit

using Meshes
using MLStyle
using DataStructures

struct Tile{T}
    triangle::Triangle{3,T}
    # TODO: a reference to the volume
end

struct BVH{T}
    left::Union{BVH{T},Tile{T}}
    right::Union{BVH{T},Tile{T}}
    boundary::Box{3,T}
end

function Base.show(io::IO, bvh::BVH{T}) where {T}
    function count_depth(bvh::Union{BVH{T},Tile{T}}) where {T}
        @match bvh begin
            ::Tile => 1
            _      => count_depth(bvh.left) + count_depth(bvh.right)
        end
    end
    return print(io, "<$(typeof(bvh)) with $(count_depth(bvh)) tiles>")
end

function BVH(tiles::Vector{Tile{T}}; pivot_dimension=1) where {T}
    boundary = boundingbox(map(tile -> tile.triangle, tiles))
    sorted_tiles =
        sort(tiles; by=x -> (x.triangle |> centroid |> coordinates)[pivot_dimension])
    mid = (sorted_tiles |> length) ÷ 2
    left_tiles = sorted_tiles[begin:mid]
    right_tiles = sorted_tiles[(mid + 1):end]
    new_pivot_dimension = pivot_dimension % 3 + 1
    left = @match left_tiles |> length begin
        1 => left_tiles[1]
        _ => BVH(left_tiles; pivot_dimension=new_pivot_dimension)
    end
    right = @match right_tiles |> length begin
        1 => right_tiles[1]
        _ => BVH(right_tiles; pivot_dimension=new_pivot_dimension)
    end
    return BVH(left, right, boundary)
end

struct Hit{T}
    tile::Tile{T}
    hit::Point{3,T}
end

function hit(ray::Ray{3,T}, tile::Tile{T}) where {T}
    res = ray ∩ tile.triangle
    return @match res begin
        nothing => Hit{T}[]
        _       => [Hit(tile, res)]
    end
end

function hit(ray::Ray{3,T}, bvh::BVH{T}) where {T}
    if bvh.boundary ∩ ray |> isnothing
        return Hit{T}[]
    end
    return (hit(ray, bvh.left), hit(ray, bvh.right)) |> x -> reduce(vcat, x; init=Hit{T}[])
end

function fuse(bvh::BVH)
    q = Deque{Any}()
    res = []
    push!(q, (bvh, 1))
    while !isempty(q)
        node = popfirst!(q)
        if length(res) < node[2]
            push!(res, [])
        end
        if node[1] isa Tile
            push!(res[node[2]], node[1].triangle |> discretize)
        else
            push!(res[node[2]], node[1].boundary |> boundary)
            push!(q, (node[1].left, node[2] + 1))
            push!(q, (node[1].right, node[2] + 1))
        end
    end
    return map(x -> reduce(merge, x), res)
end

export Tile, BVH, hit

end # module SpaceSplit
