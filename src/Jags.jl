module Jags

  using DataArrays, Mamba
  
  #### Includes ####
  
  include("jagsmodel.jl")
  include("jagscode.jl")
  
  if !isdefined(Main, :Stanmodel)
    include("utilities.jl")
  end
  
  if !isdefined(Main, :JAGS_HOME)
    JAGS_HOME = ""
    try
      JAGS_HOME = ENV["JAGS_HOME"]
    catch e
      println("Environment variable JAGS_HOME not found.")
      JAGS_HOME = ""
    end
  end
  if !isdefined(Main, :JULIA_SVG_BROWSER)
    JULIA_SVG_BROWSER = ""
    try
      JULIA_SVG_BROWSER = ENV["JULIA_SVG_BROWSER"]
    catch e
      println("Environment variable JULIA_SVG_BROWSER not found.")
      JULIA_SVG_BROWSER = ""
    end
  end

  #### Exports ####
  
  export
  # From Jags.jl
    JAGS_HOME,
    JULIA_SVG_BROWSER,
    
  # From jagsmodel.jl
    Jagsmodel,
    
  # From jagscode.jl
    jags
  
  #### Deprecated ####
  
  include("deprecated.jl")

end # module
