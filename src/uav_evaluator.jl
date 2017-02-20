export 
    UAVLevelSetEvaluator,
    evaluate_parameters!

const CONFLICT_DISTANCE = 250

type UAVLevelSetEvaluator <: LevelSetEvaluator
    env::Environment
    num_encounters::Int64
    function UAVLevelSetEvaluator(num_encounters::Int64 = 500)
        env = build_environment()
        new(env, num_encounters)
    end
end

function update_parameters!(lse::UAVLevelSetEvaluator, psi_std::Float64, 
        theta_std::Float64)
    lse.env.uavs[1].sensor_psi_std = psi_std
    lse.env.uavs[1].sensor_theta_std = theta_std
    return lse
end

function set_seeds!(lse::UAVLevelSetEvaluator, scenario_seed::Int64, 
        simulation_seed::Int64)
    srand(lse.env.rng, scenario_seed)
    srand(lse.env.dynamics.rng, scenario_seed)
    srand(lse.env.uavs[1].rng, simulation_seed)
    srand(lse.env.uavs[2].rng, simulation_seed)
    return lse
end

function analyze(encounters::Array{Encounter})
    conflict_count = 0
    for e in encounters
        for horizontal_distance in e.min_horizontal_dists
            if horizontal_distance < CONFLICT_DISTANCE
                conflict_count += 1
                break
            end
        end
    end
    return conflict_count / length(encounters)
end

"""
Description:
    - Run simulations to evaluate the probability of an nmac for given parameters

Args:
    - lse: uavs level set evaluator
    - params: array of parameter values at which to evaluate the target value
        params[1] = standard deviation of relative heading sensor (psi_std)
            - min: 0. rad
            - max: pi / 2 rad
        params[1] = standard deviation of relative angle sensor (theta_std)
            - min: 0. rad
            - max: pi / 2 rad
    - scenario_seed: random seed from which to generate the scenario
    - simulation_seed: random seed to use for simulating the scenario

Returns:
    - value of the target (nmac probability)
        - min: 0.
        - max: 1.
"""
function evaluate_parameters!(lse::UAVLevelSetEvaluator, params::Array{Float64},
        scenario_seed::Int = 1, simulation_seed::Int = 1)
    update_parameters!(lse, params[1], params[2])
    set_seeds!(lse, scenario_seed, simulation_seed)
    encounters = simulate_encounters(lse.env, lse.num_encounters)
    p_nmac = analyze(encounters)
    return p_nmac
end
