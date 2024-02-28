module SpaceSplitMakieExt

using SpaceSplit
using Meshes
using Makie

function Meshes.viz(bvh::BVH)
    f = SpaceSplit.fuse(bvh)
    for i in 1:length(f)
        if i == 1
            viz(f[i]; showfacets=true, alpha=0, segmentsize=2)
        else
            viz!(f[i]; showfacets=true, alpha=0, segmentsize=2 * 0.6^(i - 1))
        end
    end
    return current_figure()
end

end
