using LevelSetEvaluation

"""
Description:
    - This example creates an automotive level set estimator, and uses it to evaluate the impact of two input variables (noise in the longitudinal and lateral acceleration) on an output variable (number of hard brakes).
"""

lse = build_evaluator("auto")
num_runs = 5
param_1_values = linspace(0., 2., num_runs)
param_2_values = linspace(0, .5, num_runs)
targets = zeros(num_runs, num_runs)
for (i, x1) in enumerate(param_1_values)
    for (j, x2) in enumerate(param_2_values)
        tic()
        targets[i, j] = evaluate_parameters!(lse, [x1,x2], 1, 1)
        print(@sprintf("input: (%03f, %03f)\toutput: %05f\t", x1, x2, targets[i,j]))
        toc()
    end
end
println(reshape(targets, (num_runs, num_runs)))