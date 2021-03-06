# Jags


[![Jags](http://pkg.julialang.org/badges/Jags_0.3.svg)](http://pkg.julialang.org/?pkg=Jags&ver=0.3)
[![Jags](http://pkg.julialang.org/badges/Jags_0.4.svg)](http://pkg.julialang.org/?pkg=Jags&ver=0.4)

## Purpose

A package to use Jags (as an external program) from Julia.

For more info on Jags, please go to <http://mcmc-jags.sourceforge.net>.

For more info on Mamba, please go to <http://mambajl.readthedocs.org/en/latest/>.

This version will be kept as the Github branch Jags-j0.4-v0.3.0. Branch Jags-j0.3-v0.2.0 runs on Julia 0.3.x.


## What's new

### Version 0.3.0

1. Updated for Julia 0.4. Julia 0.4 and upwards only.
2. Removed Compat with 0.3.

### Version 0.2.0

1. Added badges for Julia package listing
2. Exported JAGS_HOME in Jags.jl
3. Updated for to also run Julia 0.4 pre-releases

### Version 0.1.5

1. Updated .travis.yml
2. The runtests.jl script now prints package version

### Version 0.1.4

1. Allowed JAGS_HOME and JULIA_SVG_BROWSER to be set from either ~/.juliarc.jl or as an evironment variable. Updated README accordingly.

### Version 0.1.3

1. Removed upper bound on Julia in REQUIRE. 

### Version 0.1.2

1. Fix for access to environment variables on Windows.

### Version 0.1.1

1. Stores Jags's input & output files in a subdirectory of the working directory.
2. Added Bones2 example.

### Version 0.1.0

The two most important features introduced in version 0.1.0 are:

1. Using Mamba to display and diagnose simulation results. The call to jags() to sample now returns a Mamba Chains object (previously it returned a dictionary). 
2. Added the ability to specify RNGs in the initializations file for running simulations in parallel.

### Version 0.0.4

1. Added the ability to start multiple Jags scripts in parallel.

### Version 0.0.3 and earlier

1. Parsing structure for input arguments to Stan.
2. Single process execution of a Jags simulations.
3. Read created output files by Jags back into Julia.


## Requirements

This version of the Jags.jl package assumes that: 

1. Jags is installed and the jags binary is on $PATH. The variable JAGS_HOME is currently initialized either from ~/.juliarc.jl or from an environment variable JAGS_HOME. JAGS_HOME currently only used in runtests.jl to disable attempting to run tests that need the Jags executable on $PATH.

2. Mamba (see <https://github.com/brian-j-smith/Mamba.jl>) is installed.

3. DataArrays (see <https://github.com/JuliaStats/DataArrays.jl>) is installed.

4. On OSX, all Jags-j03-v0.2.0 examples check the environment variable JULIA_SVG_BROWSER to automatically display (in a browser) the simulation results (after creating .svg files), e.g. on my system I have exported JULIA_SVG_BROWSER="Google Chrome.app". For other platforms the final lines in the Examples/xxxx.jl files may need to be adjusted (or removed). In any case, on all platforms, both a .svg and a .pdf file will be created and left behind in the working directory.

JAGS_HOME and JULIA_SVG_BROWSER can also be defined in ~/.juliarc.jl.

This version of the package has primarily been tested on Mac OSX 10.10, Julia 0.3.3, Jags 3.4.0 and Mamba 0.4.3. A limited amount of testing has taken place on other platforms by other users of the package (see note 1 in the 'To Do' section below).

To test and run the examples:

**julia >** ``Pkg.test("Jags")``


## A walk through example

As in the Jags.jl setting, the Jags program consumes and produces files in a 'tmp' subdirectory of the current directory, it is useful to control the current working directory and restore the original directory at the end of the script.
```
using Compat, Mamba, Jags

old = pwd()
ProjDir = Pkg.dir("Jags", "Examples", "Line1")
cd(ProjDir)
```
Variable `line` holds the model which will be writtten to a file named `$(model.name).bugs` in the 'tmp' subdirectory. The value of model.name is set later on, see the call to Jagsmodel() below.
```
line = "
model {
  for (i in 1:n) {
        mu[i] <- alpha + beta*(x[i] - x.bar);
        y[i]   ~ dnorm(mu[i],tau);
  }
  x.bar   <- mean(x[]);
  alpha    ~ dnorm(0.0,1.0E-4);
  beta     ~ dnorm(0.0,1.0E-4);
  tau      ~ dgamma(1.0E-3,1.0E-3);
  sigma   <- 1.0/sqrt(tau);
}
"
```
Next, define which variables should be monitored (if => true).
```
monitors = (ASCIIString => Bool)[
  "alpha" => true,
  "beta" => true,
  "tau" => true,
  "sigma" => true,
]
```
The next step is to create and initialize a Jagsmodel:
```
jagsmodel = Jagsmodel(
  name="line1", 
  model=line,
  monitor=monitors,
  #ncommands=1, nchains=4,
  #deviance=true, dic=true, popt=true,
  pdir=ProjDir);

println("\nJagsmodel that will be used:")
jagsmodel |> display
```
Notice that by default a single command with 4 chains is created. It is possible to run each of the 4 chains in a separate process which has advantages. Using the Bones example as a testcase, on my machine running 1 command simulating a single chain takes 6 seconds, 4 (parallel) commands each simulating 1 chain takes about 9 seconds and a single command simulating 4 chains takes about 25 seconds. Of course this is dependent on the number of available cores and assumes the drawing of samples takes a reasonable chunk of time vs. running a command in a new shell.

Running chains in separate commands does need additional data to be passed in through the initialization data and is demonstrated in Examples/Line2. Some more details are given below.

If nchains is set to 1, this is updated in Jagsmodel() if dic and/or popt is requested. Jags needs minimally 2 chains to compute those.

The input data for the line example is in below data dictionary using the @Compat macro for compatibility between Julia v0.3 and v0.4:
```
data = @Compat.Dict(
  "x" => [1, 2, 3, 4, 5],
  "y" => [1, 3, 3, 3, 5],
  "n" => 5
)

println("Input observed data dictionary:")
data |> display
```
Next define an array of dictionaries with initial values for parameters. If the array of dictionaries has not enough elements, the elements will be recycled for chains/commands:
```
inits = [
  @Compat.Dict("alpha" => 0,"beta" => 0,"tau" => 1),
  @Compat.Dict("alpha" => 1,"beta" => 2,"tau" => 1),
  @Compat.Dict("alpha" => 3,"beta" => 3,"tau" => 2),
  @Compat.Dict("alpha" => 5,"beta" => 2,"tau" => 5)
]
inits = map((x)->convert(Dict{ASCIIString, Any}, x), inits)

println("\nInput initial values dictionary:")
inits |> display
println()
```
Run the mcmc simulation, passing in the model, the data, the initial values and the working directory. If 'inits' is a single dictionary, it needs to be passed in as '[inits]', see the Bones example. 
```
sim = jags(jagsmodel, data, inits, ProjDir)
describe(sim)
println()
```
Below Mamba.jl based tools are available to diagnose and plot the simulation results:
```
###### Brooks, Gelman and Rubin Convergence Diagnostic
try
  gelmandiag(sim1, mpsrf=true, transform=true) |> display
catch e
  #println(e)
  gelmandiag(sim, mpsrf=false, transform=true) |> display
end

###### Geweke Convergence Diagnostic
gewekediag(sim) |> display

###### Highest Posterior Density Intervals
hpd(sim) |> display

###### Cross-Correlations
cor(sim) |> display

###### Lag-Autocorrelations
autocor(sim) |> display

###### Plotting
p = plot(sim, [:trace, :mean, :density, :autocor], legend=true);
draw(p, nrow=4, ncol=4, filename="$(jagsmodel.name)-summaryplot", fmt=:svg)
draw(p, nrow=4, ncol=4, filename="$(jagsmodel.name)-summaryplot", fmt=:pdf)

###### Below will only work on OSX, please adjust for your environment.
###### JULIA_SVG_BROWSER is set from the environment variable JULIA_SVG_BROWSER
@osx ? if length(JULIA_SVG_BROWSER) > 0
        for i in 1:3
          isfile("$(jagsmodel.name)-summaryplot-$(i).svg") &&
            run(`open -a $(JULIA_SVG_BROWSER) "$(jagsmodel.name)-summaryplot-$(i).svg"`)
        end
      end : println()
```
## Running a Jags script, some details

Jags.jl really only consists of 2 functions, Jagsmodel() and jags().

Jagsmodel() is used to define and set up the basic structure to run a simulation.
The full signature of Jagsmodel() is:
```
function Jagsmodel(;
  name="Noname", 
  model="", 
  ncommands=1,
  nchains=4,
  adapt=1000,
  update=10000,
  thin=10,
  monitor=Dict(), 
  deviance=false,
  dic=false,
  popt=false,
  updatejagsfile=true,
  pdir=pwd())
```
All arguments are keyword arguments and have default values, although usually at least the name and model arguments will be provided.

After a Jagsmodel has been created, the workhorse function jags() is called to run the simulation, passing in the Jagsmodel, the data and the initialization for the chains.

As Jags needs quite a few input files and produces several output files, these are all stored in a subdirectory of the working directory, typically called 'tmp'.

The full signature of jags() is:
```
function jags(
  model::Jagsmodel,
  data::Dict{ASCIIString, Any}=Dict{ASCIIString, Any}(),
  init::Array{Dict{ASCIIString, Any}, 1} = Dict{ASCIIString, Any}[],
  ProjDir=pwd();
  updatedatafile::Bool=true,
  updateinitfiles::Bool=true
  )
```
All parameters to compile and run the Jags script are implicitly passed in through the model argument.

The Line2 example shows how to run multiple Jags simulations in parallel. The most simple case, e.g. 4 commands, each with a single chain, can be initialized with an 'inits' like shown below:
```
inits = [
  @Compat.Dict("alpha" => 0,"beta" => 0,"tau" => 1,".RNG.name" => "base::Wichmann-Hill"),
  @Compat.Dict("alpha" => 1,"beta" => 2,"tau" => 1,".RNG.name" => "base::Marsaglia-Multicarry"),
  @Compat.Dict("alpha" => 3,"beta" => 3,"tau" => 2,".RNG.name" => "base::Super-Duper"),
  @Compat.Dict("alpha" => 5,"beta" => 2,"tau" => 5,".RNG.name" => "base::Mersenne-Twister")
]
```
The first entry in the 'inits' array will be passed into the first chain in the first command process, the second entry to the second process, etc. A second chain in the first command would be initialized with the second entry, etc. 


## To do

More features will be added as requested by users and as time permits. Please file an issue/comment/request.

The ability to resume a simulation will e looked at for version 0.2.x.

**Note 1:** In order to support platforms other than OS X, help is needed to test on such platforms.
