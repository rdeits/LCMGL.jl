using BinDeps

@BinDeps.setup

deps = [
    glib = library_dependency("glib", aliases = ["libglib-2.0-0", "libglib-2.0", "libglib-2.0.so.0"])
    lcm = library_dependency("lcm", aliases=["liblcm", "liblcm.1"], depends=[glib])
    lcmgl_client = library_dependency("bot2-lcmgl-client", aliases=["libbot2-lcmgl-client", "libbot2-lcmgl-client.1"], depends=[lcm])
]

prefix = joinpath(BinDeps.depsdir(lcmgl_client), "usr")
pkg_config_dirs = AbstractString[]
include_dirs = AbstractString[]
@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "glib", glib, os=:Darwin)
    push!(pkg_config_dirs, joinpath(Homebrew.prefix(), "lib", "pkgconfig"))
    push!(include_dirs, joinpath(Homebrew.prefix(), "include"))
end

provides(AptGet, Dict("libglib2.0-dev" => glib))
provides(Yum,
    Dict("glib" => glib))

libbot_dirname = "libbot-cc8d228b50847c4c55e6963b8ee95c237287547f"
provides(Sources,
    URI("https://github.com/RobotLocomotion/libbot/archive/cc8d228b50847c4c55e6963b8ee95c237287547f.zip"),
    lcmgl_client,
    unpacked_dir=libbot_dirname)
provides(Sources,
    URI("https://github.com/lcm-proj/lcm/releases/download/v1.3.1/lcm-1.3.1.zip"),
    lcm)

# provides(BuildProcess, Dict(Autotools(libtarget="lcm/liblcm.la", include_dirs=include_dirs, pkg_config_dirs=pkg_config_dirs) => lcm))
#
provides(SimpleBuild,
    (@build_steps begin
        GetSources(lcm)
        @build_steps begin
            ChangeDirectory(joinpath(BinDeps.depsdir(lcm), "src", "lcm-1.3.1"))
            `./configure --prefix=$(prefix) --with-java=no --with-python=no --with-lua=no`
            MakeTargets(".", [])
            MakeTargets(".", ["install"])
        end
    end), lcm)

pkg_config_path = join(pkg_config_dirs, ":")
include_path = join(include_dirs, ":")
env = Dict{ASCIIString, ASCIIString}("PKG_CONFIG_PATH"=>pkg_config_path, "INCLUDE_PATH"=>include_path)

provides(SimpleBuild,
    (@build_steps begin
        GetSources(lcmgl_client)
        @build_steps begin
            MakeTargets(joinpath(BinDeps.depsdir(lcmgl_client), "src", libbot_dirname), ["BUILD_PREFIX=$(prefix)"], env=env)
            @osx_only begin
                `install_name_tool -change $(joinpath(prefix, "lib", "liblcm.1.dylib")) "@loader_path/liblcm.1.dylib" $(joinpath(prefix, "lib", "libbot2-lcmgl-client.1.dylib"))`
            end
        end
    end), lcmgl_client)

@BinDeps.install Dict(:lcm => :liblcm, "bot2-lcmgl-client" => :libbot2_lcmgl_client)
