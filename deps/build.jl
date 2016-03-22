using BinDeps

@BinDeps.setup

deps = [
    java6 = library_dependency("java-6-openjdk", os=:Linux)
    gobject = library_dependency("gobject", aliases = ["libgobject-2.0-0", "libgobject-2.0", "libgobject-2_0-0", "libgobject-2.0.so.0"])
    lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[gobject, java6])
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
                      "openjdk-6-jdk" => java6))

provides(Sources, Dict(
    URI("https://github.com/RobotLocomotion/libbot/archive/cc8d228b50847c4c55e6963b8ee95c237287547f.zip") => lcmgl_client,
    URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.0/lcm-1.3.0.zip") => lcm
    ))

provides(BuildProcess,
    Dict(
    Autotools(libtarget="src/liblcm.la") => lcm
    ))

prefix = joinpath(BinDeps.depsdir(lcmgl_client), "..")

provides(SimpleBuild,
    (@build_steps begin
        GetSources(lcmgl_client)
        @build_steps begin
            MakeTargets(joinpath(BinDeps.depsdir(lcmgl_client)), ["BUILD_PREFIX=$(prefix)"])
        end
    end), lcmgl_client)

@BinDeps.install Dict(:lcm => :liblcm, "bot2-lcmgl-client" => :libbot2_lcmgl_client)
