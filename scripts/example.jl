using LevelSetEvaluation

"""
Description:
    - This example creates an automotive level set estimator, and uses it to evaluate the impact of two input variables (noise in the longitudinal and lateral acceleration) on an output variable (number of hard brakes).
"""

function grid_evaluation!(lse::LevelSetEvaluator, params_1::Vector{Float64}, 
        params_2::  Vector{Float64})
    num_runs = length(params_1)
    targets = zeros(num_runs, num_runs)
    for (i, x1) in enumerate(params_1)
        for (j, x2) in enumerate(params_2)
            tic()
            targets[i, j] = evaluate_parameters!(lse, [x1,x2], 2, 1)
            print(@sprintf("input: (%03f, %03f)\toutput: %05f\t", x1, x2, targets[i,j]))
            toc()
        end
    end
    return targets
end

# auto
# auto_lse = build_evaluator("auto")
# num_runs = 2
# param_1_values = collect(linspace(0., 2., num_runs))
# param_2_values = collect(linspace(0, .5, num_runs))
# targets = grid_evaluation!(auto_lse, param_1_values, param_2_values)
# println(reshape(targets, (num_runs, num_runs)))

# uav
uav_lse = build_evaluator("uav")
num_runs = 5
param_1_values = collect(linspace(0., pi / 2, num_runs))
param_2_values = collect(linspace(0, pi / 2, num_runs))
targets = grid_evaluation!(uav_lse, param_1_values, param_2_values)
println(reshape(targets, (num_runs, num_runs)))