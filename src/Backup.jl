module Backup

using ArgParse
using DataStructures
using Crayons

const RESET = crayon"reset"

include("config.jl")
include("core.jl")
include("cli.jl")

function get_value(config, args, key; required=true, msg=nothing)
    val = something(args[key], config[Symbol(key)], Some(nothing))
    required && isnothing(val) && error(isnothing(msg) ? "Value required for '$key', but not found in configuration. Please provide it as an argument, or edit your configuration." : msg)
    val
end

function override!(config, args, key)
    val = get_value(config, args, key)
    if !isnothing(val)
        config[Symbol(key)] = val
    end
end

function main()
    args = parse_args(s)
    config = read_config()
    cmd = args["%COMMAND%"]
    cmd_args = args[cmd]
    _get_value(x; kwargs...) = get_value(config, cmd_args, x; kwargs...)
    if cmd == "make"
        config = BackupConfig(
            _get_value("target"),
            _get_value("dst"),
        )
        confirm = !cmd_args["no-confirm"]
        make_backup(config; confirm)
    elseif cmd == "list"
        dst = _get_value("dst")
        backups = existing_backups(dst)
        if isempty(backups)
            println("No backups found.")
            exit(0)
        else
            println("Existing backups:")
        end

        map(backups) do id
            path = backup_path(dst, id)
            println(crayon"cyan", lpad(id, 4), RESET, " ───→ ", crayon"#ffddaa", path, RESET, "    ", String(readchomp(`stat -c %y $path`)))
            
        end
    elseif cmd == "config"
        override!(config, cmd_args, "dst")
        save_config(config)
    end
end

export
        BackupConfig,
        backup,
        main

end
