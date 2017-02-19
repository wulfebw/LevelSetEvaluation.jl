export 
    LevelSetEvaluator,
    evaluate_parameters!,
    build_evaluator

abstract LevelSetEvaluator

evaluate_parameters!(evaluator::LevelSetEvaluator, params::Array{Float64}, scenario_seed::Int, simulation_seed::Int) = error("not implemented")

function build_evaluator(evaluator_type::String)
    if evaluator_type == "auto"
        return AutoLevelSetEvaluator()
    else
        throw(ArgumentError("invalid evaluator_type $(evaluator_type)"))
    end
end