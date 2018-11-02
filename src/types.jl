type Whisker
    pos::Array{GeometryTypes.Point2f0,1}
    ang::Float64
    phase::Float64
    amp::Float64
end

type analysis_gui
    win::GLWindow.Screen
    edit_screen::GLWindow.Screen
    viewscreen::GLWindow.Screen
    imgscreen::GLWindow.Screen
    datascreen::GLWindow.Screen
    timescreen::GLWindow.Screen
    sliderscreen::GLWindow.Screen
    gamma::Float32
    cov1::Array{GeometryTypes.Point{2,Float32},2}
    vid_path::String
    folder_path::String
    y_data::Array{Float32,2}
    max_time::Int64
    y_scales::Array{Float32,1}
    video_ts::Array{Int64,1}
    current_frame::Int64
    t::Int64
    start_time::Int64
    spikes_ts::Array{Int64,1}
    s::Sorting
    buf::Array{SpikeSorting.Spike,2}
    spike_nums::Array{Int64,1}
    show_spikes::Bool
    spikes::Array{GeometryTypes.Point{2,Float32},2}
    p_slider::Reactive.Signal{Int64}
    event_ts::Array{Array{Int64,1},1}
    myhist::Array{Int64,1}
    slider_values::StepRange{Int64,Int64}
    tif::Array{ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}},3}
    whiskers::Array{Whisker,2}
    pre_sorted::Bool
    pre_sorted_ts::Array{Int64,1}
end

type clip_times
    t1::Int64
    t2::Int64
    ts1::Int64
    ts2::Int64
    ind1::Int64
    ind2::Int64
    s1::Int64
    s2::Int64
end


Whisker()=Whisker(zeros(GeometryTypes.Point2f0,0),0.0,0.0,0.0)
