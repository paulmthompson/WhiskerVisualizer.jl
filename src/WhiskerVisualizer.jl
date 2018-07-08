module WhiskerVisualizer

using Gtk.ShortNames, Cairo, SpikeSorting, Winston

#Change colormap to grayscale for imagesc
#Need to reverse
colormap("grays")
Winston.colormap(reverse(Winston._current_colormap))

include("types.jl")
include("gui.jl")
include("plotting.jl")

end
