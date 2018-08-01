module WhiskerVisualizer

using GLVisualize, GLAbstraction, Reactive, GeometryTypes, Colors, GLWindow, VideoIO, OpenEphysLoader
import GLVisualize: widget, mm, play_slider, labeled_slider

include("types.jl")
include("gui.jl")
include("plotting.jl")
include("parsers.jl")

end
