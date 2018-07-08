type Visual_GUI
    win::Gtk.GtkWindowLeaf
    c1::Gtk.GtkCanvasLeaf #Spikes
    c2::Gtk.GtkCanvasLeaf #Analog and Digital
    c3::Gtk.GtkCanvasLeaf #Video
    event_nums::Int64
    events::Array{Array{Float64,1},1}
    event_ts::Array{Array{Int64,1},1}
    event_ts_i::Array{Int64,1}
    prev_events::Array{Float64,2}
    prev_events_i::Int64
    time::Int64
    xscale::Int64
    yoffset::Int64
    yscales::Array{Float64,1}
    event_labels::Array{String,1}
    impath::String
    myimage::Array{UInt8,2}
end

