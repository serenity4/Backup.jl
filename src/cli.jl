const s = ArgParseSettings()

@add_arg_table s begin
    "make"
        help = "Make a system backup."
        action = :command
    "delete"
        help = "Delete a previous backup."
        action = :command
    "list"
        help = "List all backups."
        action = :command
    "config"
        help = "Edit configuration."
        action = :command
end

@add_arg_table! s["make"] begin
    "target"
        help = "Directory to back up."
        required = true
    "-d", "--dst"
        help = "Directory where the backup will be stored."
        default = nothing
    "-n", "--no-confirm"
        help = "Do not prompt for confirmation."
        action = :store_true
end

@add_arg_table s["delete"] begin
    "id"
        help = "Backup number to delete."
        required = true
        arg_type = Int
end

@add_arg_table s["list"] begin
    "-d", "--dst"
        help = "Directory containing the backups."
        default = nothing
end

@add_arg_table s["config"] begin
    "-d", "--dst"
        help = "Set the directory in which backups will be managed."
end

function await_confirmation(default; msg="Confirm?")
    prompt = string(msg * " (", crayon"green", default ? 'Y' : 'y', RESET, '/', crayon"red", !default ? 'N' : 'n', RESET, ')')
    println(prompt)
    try
        while true
            answer = strip(readline(), [' ', '\n'])
            isempty(answer) && return default
            if lowercase(answer) ∉ ["y", "n"]
                println("Answer not understood. ", prompt)
            elseif answer == "y"
                return true
            else
                @info "Operation aborted."
                return false
            end
        end
    catch e
        if e isa InterruptException
            @info "Operation aborted."
            exit(0)
        else
            rethrow(e)
        end
    end
end
