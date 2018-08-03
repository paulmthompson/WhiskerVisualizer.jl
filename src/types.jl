type analysis_gui
   win::GLWindow.Screen
    edit_screen::GLWindow.Screen
    viewscreen::GLWindow.Screen
    imgscreen::GLWindow.Screen
    datascreen::GLWindow.Screen
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
end
