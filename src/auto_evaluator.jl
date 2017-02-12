export 
    AutoLevelSetEvaluator,
    evaluate_parameters!

const HARD_BRAKE_INDEX = 4

function build_generators_evaluator(flags)
    feature_dim = 0
    flags["num_scenarios"] = 1
    flags["num_monte_carlo_runs"] = 5
    flags["prime_time"] = 1.
    flags["sampling_period"] = .1
    flags["sampling_time"] = 5.

    # roadway
    roadway = gen_stadium_roadway(flags["num_lanes"], 
        length = flags["roadway_length"], 
        radius = flags["roadway_radius"])

    # scene
    scene = Scene(flags["max_num_vehicles"])
    scene_gen = HeuristicSceneGenerator(
        flags["min_num_vehicles"], 
        flags["max_num_vehicles"], 
        flags["min_base_speed"],
        flags["max_base_speed"],
        flags["min_vehicle_length"],
        flags["max_vehicle_length"],
        flags["min_vehicle_width"], 
        flags["max_vehicle_width"],
        flags["min_init_dist"])

    # behavior
    context = IntegratedContinuous(flags["sampling_period"], 1)
    params = [get_aggressive_behavior_params(
                            lon_σ = flags["lon_accel_std_dev"], 
                            lat_σ = flags["lat_accel_std_dev"], 
                            response_time = flags["response_time"]), 
                        get_passive_behavior_params(
                            lon_σ = flags["lon_accel_std_dev"], 
                            lat_σ = flags["lat_accel_std_dev"], 
                            response_time = flags["response_time"]),
                        get_normal_behavior_params(
                            lon_σ = flags["lon_accel_std_dev"], 
                            lat_σ = flags["lat_accel_std_dev"], 
                            response_time = flags["response_time"])]
                weights = WeightVec([.3,.3,.4])
    behavior_gen = PredefinedBehaviorGenerator(context, params, weights)

    # evaluator
    max_num_scenes = Int(ceil(
        (flags["prime_time"] + flags["sampling_time"]) / flags["sampling_period"]))
    rec = SceneRecord(max_num_scenes, flags["sampling_period"], 
        flags["max_num_vehicles"])
    features = Array{Float64}(feature_dim, flags["max_num_vehicles"])
    targets = Array{Float64}(flags["target_dim"], flags["max_num_vehicles"])
    agg_targets = Array{Float64}(flags["target_dim"], flags["max_num_vehicles"])
    ext = EmptyExtractor()
    eval = MonteCarloEvaluator(
        ext, 
        flags["num_monte_carlo_runs"], 
        context, 
        flags["prime_time"], 
        flags["sampling_time"],
        flags["veh_idx_can_change"], 
        rec, 
        features, 
        targets, 
        agg_targets)

    return (roadway, scene_gen, behavior_gen, eval)
end

type AutoLevelSetEvaluator <: LevelSetEvaluator
    roadway::Roadway
    scene_gen::SceneGenerator
    behavior_gen::BehaviorGenerator
    eval::Evaluator
    scene::Scene
    models::Dict{Int, DriverModel}
    function AutoLevelSetEvaluator(
            roadway::Roadway,
            scene_gen::SceneGenerator,
            behavior_gen::BehaviorGenerator,
            eval::Evaluator,
            scene = Scene(),
            models = Dict{Int, DriverModel}())
        new(roadway, scene_gen, behavior_gen, eval, scene, models)
    end
end

"""
Description:
    - alternate constructor directly from flags
"""
function AutoLevelSetEvaluator()
    parse_flags!(FLAGS, ARGS)
    roadway, scene_gen, behavior_gen, eval = build_generators_evaluator(FLAGS)
    return AutoLevelSetEvaluator(roadway, scene_gen, behavior_gen, eval)
end

function update_parameters!(lseval::AutoLevelSetEvaluator, lon_σ::Float64, 
        lat_σ::Float64)
    for params in lseval.behavior_gen.params
        params.idm.σ = lon_σ
        params.lat.σ = lat_σ
    end
end

"""
Description:
    - Run simulations to evaluate the probability of a hard brake given the 
        parameter values

Args:
    - lse: automotive level set estimator
    - params: array of parameter values at which to evaluate the target value
        params[1] = standard deviation of longitudinal acceleration (lon_σ)
            - min: 0. m/s^2
            - max: 2. m/s^2 
        params[1] = standard deviation of lateral acceleration (lat_σ)
            - min: 0. m/s^2
            - max: 2. m/s^2
    - seed: random seed from which to generate the scene

Returns:
    - value of the target (hard brake probability)
        - min: 0.
        - max: 1.
"""
function evaluate_parameters!(lse::AutoLevelSetEvaluator, 
        params::Array{Float64}, seed::Int = 1)
    update_parameters!(lse, params[1], params[2])
    reset!(lse.scene_gen, lse.scene, lse.roadway, seed)
    reset!(lse.behavior_gen, lse.models, lse.scene, seed)
    evaluate!(lse.eval, lse.scene, lse.models, lse.roadway, seed)
    return mean(lse.eval.agg_targets, 2)[HARD_BRAKE_INDEX]
end