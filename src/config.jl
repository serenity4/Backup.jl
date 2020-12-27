function save_config(d::AbstractDict)
    open(config_path, "w+") do io
        for (key, val) ∈ d
            !isnothing(val) && write(io, string(key, " ", val))
        end
    end
end

const config_types = Dict(
    :dst => String,
    :target => String,
)

const config_path = joinpath(homedir(), ".backup_config_jl")

function read_config()
    !isfile(config_path) && return DefaultDict(() -> nothing)
    options = filter(!isempty, split(readchomp(config_path), '\n'))
    d = DefaultDict(() -> nothing)
    map(options) do opt
        items = split(opt)
        length(items) > 1 || @warn "Skipping unknown configuration entry \"$opt\"."
        key = lowercase(first(items))
        val = join(items[2:end])
        sym = Symbol(key)

        d[sym] = config_types[sym](val)
    end
    d
end
