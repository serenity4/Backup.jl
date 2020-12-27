struct BackupConfig
    target::String
    dst::String
    id::Int
    backups::Vector{Int}
end

BackupConfig(target::AbstractString, dst::AbstractString, backups::AbstractVector{Int}) = BackupConfig(target, dst, isempty(backups) ? 1 : last(backups) + 1, backups)
BackupConfig(target::AbstractString, dst::AbstractString) = BackupConfig(target, dst, existing_backups(dst))

backup_path(dst, id) = joinpath(dst, string(id))

function flags(config::BackupConfig)
    _flags = ["-a", "--delete", "--one-file-system", "--info=progress2", "--no-inc-recursive"]
    !isempty(config.backups) && push!(_flags, string("--link-dest=", backup_path(config.dst, last(config.backups))))
    _flags
end

function make_backup(config::BackupConfig; confirm::Bool = true)
    dst = backup_path(config.dst, string(config.id))
    src = config.target

    includes = joinpath.(src, ["home", "etc", "snap", "var"])
    excludes = joinpath.(src, ["var/log"])

    cmd = `sudo rsync $(flags(config)) --exclude=$excludes $includes $dst/`
    println("The following command will be run: ", crayon"#aacc22", string(cmd), RESET)

    if confirm
        await_confirmation(true; msg=string("Ready to back up ", crayon"#aa77bb", src, RESET, " to ", crayon"#aabbff", dst, RESET, ". Continue?")) || return
    end

    @info "Creating backup of $src at $dst"
    mkpath(dst)
    try
        run(cmd)
    catch e
        # exit code 24 indicates that some files vanished before transfer; it is likely to happen if there is user activity during transfer and is considered fine
        !(e isa ProcessFailedException && first(e.procs).exitcode ≠ 24) && rethrow(e)
    end
end

function existing_backups(dst::AbstractString)
    !isdir(dst) && return Int[]
    parse.(Int, filter(x -> !isnothing(match(r"^\d+$", x)), readdir(dst)))
end
