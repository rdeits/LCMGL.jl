using BinDeps

@BinDeps.setup

deps = [
    java6 = library_dependency("openjdk-6-jdk", os=:Linux)
    gobject = library_dependency("gobject", aliases = ["libgobject-2.0-0", "libgobject-2.0", "libgobject-2_0-0", "libgobject-2.0.so.0"])
    lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[gobject])
    lcmgl_client = library_dependency("bot2-lcmgl-client", aliases=["libbot2-lcmgl-client"], depends=[lcm])
]

@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "glib", gobject, os=:Darwin)
end

provides(AptGet, Dict("libglib2.0-dev" => gobject,
                      "openjdk-6-jdk" => java6
                      ))

provides(Sources, Dict(
    URI("https://github.com/RobotLocomotion/libbot/archive/cc8d228b50847c4c55e6963b8ee95c237287547f.zip") => lcmgl_client,
    URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.0/lcm-1.3.0.zip") => lcm
    ))

provides(BuildProcess,
    Dict(
    Autotools(libtarget="src/liblcm.la") => lcm
    ))

prefix = joinpath(BinDeps.depsdir(lcmgl_client), "..")
lcmgl_args = ["BUILD_PREFIX=$(prefix)"]
@osx_only
    include_path = joinpath(Homebrew.prefix(), "include")
    library_path = joinpath(Homebrew.prefix(), "lib")
    lcmgl_args = vcat(lcmgl_args, ["INCLUDE_PATH=$INCLUDE_PATH:$(include_path)", "LIBRARY_PATH=$LIBRARY_PATH:$(library_path)"])
end


provides(SimpleBuild,
    (@build_steps begin
        GetSources(lcmgl_client)
        @build_steps begin
            MakeTargets(joinpath(BinDeps.depsdir(lcmgl_client)), lcmgl_args)
        end
    end), lcmgl_client)

@BinDeps.install Dict(:lcm => :liblcm, "bot2-lcmgl-client" => :libbot2_lcmgl_client)
