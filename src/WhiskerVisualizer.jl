module WhiskerVisualizer

using GLVisualize, GLAbstraction, Reactive, GeometryTypes, Colors, GLWindow,
OpenEphysLoader, WAV, DSP, MAT, SpikeSorting
import GLVisualize: widget, mm, play_slider, labeled_slider

include("types.jl")
include("gui.jl")
include("plotting.jl")
include("parsers.jl")
include("saving_loading.jl")
include("processing.jl")

end
