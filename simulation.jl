using Random
using YAML
using Logging
using Statistics
using Base
include("functions.jl")

# defining logger
logger = SimpleLogger(stdout, Logging.Info)
global_logger(logger)

@info "Initializating simulation parameters..."

# ARGS manager
directory, parameters_file = initial_parameters_manager(ARGS)
params = YAML.load_file(parameters_file)

# setting parameters
N       = Int(params["number"])
k_max   = params["k_max"]
exp_gt  = params["exp_gt"]
c       = params["c"]
F0      = params["F0"]
save    = params["save"]
preci   = params["preci"]
k_eps	= params["k_eps"]

# computing other parameters
gatau   = 10^(-exp_gt)
lambda  = exp(-gatau)
T       = 1.0/gatau

# defining auxiliar variables
v_2m_   = zeros(N)
v_2m    = zeros(N)
eps     = 10000
t       = 0

@info "parameters are: $params"

for (k, v) in params
    println("$(k): $(v)")
end

# creating moments CSV file
mom_file = joinpath(directory, "momento2_$(k_eps).csv")
mom2 = open(mom_file, "w")

# printing headers
println(mom2, "t\t", join(1:k_max, "\t"))

# Punto de partida
V  = zeros(N, k_max)
Vn = copy(V)

# Integración
while eps > preci
    global Vn = copy(V)
    Xn = random_uniform(N)

    for i in 1:N
        V[i, 1] = lambda*V[i, 1] + F0*sqrt(gatau)*Xn[i]
        for k in 2:k_max
            V[i, k] = V[i, k]*lambda^k + c*rand()*(1 - lambda^(k-1))*Vn[i, k-1]
        end
    end

    # writing the moments
    if (t + 1) % save == 0
        for k in 1:k_max
            v_2m[k] = mean(V[:, k].^2)
        end
        println(mom2, "$t\t", join([v_2m[k] for k in 1:k_max], "\t"))
        if t > T
            global eps   = abs(v_2m[k_eps]-v_2m_[k_eps])/v_2m[k_eps]
            global v_2m_ = copy(v_2m)
        end
        println("Saving progress...")
    end

    println("iteraciones (t): ", t)
    println("progreso relativo (t*gatau): ", t*gatau)
    println("tolerancia: ", eps)
    println("vel cuadratica med escala $(k_eps): ", v_2m[k_eps])

    global t += 1
end

# Cerramos archivos
close(mom2)

