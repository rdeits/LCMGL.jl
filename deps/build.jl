using BinDeps

@BinDeps.setup

deps = [
    java6 = library_dependency("openjdk-6-jdk", aliases=["jvm/java-6-openjdk-amd64/lib/amd64/jli/libjli"], os=:Linux)
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
    URI("https://github.com/RobotLocomotion/lcm-pod/archive/8dba206f3403f01048b73ce10b6a17da58280fbe.zip") => lcm
    ))

prefix = joinpath(BinDeps.depsdir(lcmgl_client), "..")
pods_args = ["BUILD_PREFIX=$(prefix)"]
@osx_only begin
    pkg_config_path = joinpath(Homebrew.prefix(), "lib", "pkgconfig")
    pods_args = vcat(pods_args, ["PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:$(pkg_config_path)"])
end

provides(SimpleBuild,
    (@build_steps begin
        GetSources(lcm)
        @build_steps begin
            MakeTargets(joinpath(BinDeps.depsdir(lcm)), pods_args)
        end
    end), lcm)

provides(SimpleBuild,
    (@build_steps begin
        GetSources(lcmgl_client)
        @build_steps begin
            MakeTargets(joinpath(BinDeps.depsdir(lcmgl_client)), pods_args)
        end
    end), lcmgl_client)

@BinDeps.install Dict(:lcm => :liblcm, "bot2-lcmgl-client" => :libbot2_lcmgl_client)
