#!/usr/bin/env julia

function install(package)
    code = if package.local_path !== nothing
        "Pkg.add(; path=$local_path)"
    elseif package.version !== nothing
        "Pkg.add(; name=$(package.name), version=$(package.version))"
    else
        "Pkg.add(; name=$(package.name))"
    end

    julia = Base.julia_cmd()
    pipeline(`$julia -e 'using Pkg; $code`)
    return nothing
end

function import_package(package)
    @eval using $(package.name)
    return nothing
end

const PHASES = Dict(
    "all" => [install, import_package],
    "install" => [install],
    "import" => [import_package]
)

function main()
    if length(ARGS) < 2 || length(ARGS) > 4
        throw(ArgumentError("Usage: $(@__FILE__) [--local file | --version version] phase package_name"))
    end

    local_path = nothing
    version = nothing

    if ARGS[1] == "--local"
        pop!(ARGS)
        local_path = pop!(ARGS)
    elseif ARGS[1] == "--version"
        pop!(ARGS)
        version = pop!(ARGS)
    end

    phase = pop!(ARGS)
    package_name = pop!(ARGS)
    if !(phase in keys(PHASES))
        println("Unknown phase $(phase) specified.")
        exit(1)
    end

    package = (; name=package_name, version=version, local_path=local_path)

    for phase in PHASES[phase]
        phase(package)
    end
    return nothing
end

main()
