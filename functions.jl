# -------------- script of useful (or not) functions --------------- #
ulam(xn) = 1 - 2*xn^2

function random_uniform(N, a=-1., b=1.)
    random_array = a .+ (b - a) .* rand(N)
    return random_array
end

function initial_parameters_manager(args)
    if length(args) == 0
        parameters_file = "initial_parameters.yml"
        directory = ""
    elseif length(args) == 1
        parameters_file = args[1]
        directory = dirname(parameters_file)
    elseif length(args) == 2
        parameters_file = args[1]
        directory = dirname(with_path_sep(args[2]))
        if directory != dirname(parameters_file)
            new_params_file = joinpath(directory, basename(parameters_file))
            if !isdir(directory)
                mkdir(directory)
            end
            if isfile(new_params_file)
                rm(new_params_file)
            end
            cp(parameters_file, new_params_file)
        end
    else
        println("Use as: julia simulation.jl <nombre_del_archivo.yml> <nombre_de_la_carpeta>")
        exit(1)
    end
    return directory, parameters_file
end

function with_path_sep(dir::AbstractString)
    # Verificar si el directorio ya termina con un separador de ruta
    if dir[end] == "/"
        new_dir = dir
    else
        new_dir = joinpath(dir, "")
    end
    return new_dir
end
