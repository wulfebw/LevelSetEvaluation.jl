__precompile__(true)
module LevelSetEvaluation


using Reexport
@reexport using AutoRisk
# manually include an AutoRisk config script
include(joinpath(Pkg.dir("AutoRisk"), "scripts", "collection", 
    "heuristic_dataset_config.jl"))

include("level_set_evaluator.jl")
include("auto_evaluator.jl")

end # module
