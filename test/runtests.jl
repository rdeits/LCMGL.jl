using LCMGL
using Base.Test

for i = 1:1e4
    LCMGLClient("test") do lcmgl
        color(lcmgl, rand(4)...)
        sphere(lcmgl, rand(3), 0.1, 20, 20)
        switch_buffer(lcmgl)
    end
end

lcmgl = LCMGLClient("test")
for i = 1:10
    color(lcmgl, rand(4)...)
    sphere(lcmgl, rand(3), 0.1, 20, 20)
    switch_buffer(lcmgl)
end

for i = 1:10
	color(lcmgl, 1, 1, 1)
	gl_begin(lcmgl, LCMGL.LINES)
	vertex(lcmgl, rand(3)...)
	vertex(lcmgl, rand(3)...)
	gl_end(lcmgl)
	switch_buffer(lcmgl)
end

