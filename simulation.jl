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
ts      = params["ts"]

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
mom_file = joinpath(directory, "momento2.csv")
mom2 = open(mom_file, "w")
println(mom2, "t\t", join(1:k_max, "\t"))

# creating timeseries CSV file
if ts
    vel_file = joinpath(directory, "vel_t.csv")
    vel_t = open(vel_file, "w")
    println(vel_t, "t\t", join(1:k_max, "\t"))
end

# Punto de partida
V  = zeros(N, k_max)
Vn = copy(V)
Xn = random_uniform(N)

# Integración
while eps > preci
    global Vn = copy(V)
    global Xn = ulam.(Xn)

    for i in 1:N
        V[i, 1] = lambda*V[i, 1] + F0*sqrt(gatau)*Xn[i]
        for k in 2:k_max
            V[i, k] = V[i, k]*lambda^k + c*rand()*(1 - lambda^(k-1))*Vn[i, k-1]
        end
    end

    if ts
        write_timeseries(vel_t, t+1, V[1, :])
        @info "saving timeseries..."
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

    print_logs(t, gatau, eps, v_2m[k_eps], k_eps)

    global t += 1
end

# Cerramos archivos
close(mom2)

if ts
    close(vel_t)
end

# ending...
@info "Finalizado..."

