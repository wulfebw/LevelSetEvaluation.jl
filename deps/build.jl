try
    Pkg.clone("https://github.com/tawheeler/AutomotiveDrivingModels.jl.git")
catch e
    println("Exception when cloning AutomotiveDrivingModels.jl while building AutoRisk: $(e)")  
end