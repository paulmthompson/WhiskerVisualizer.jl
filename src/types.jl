type analysis_gui
   win::GLWindow.Screen
    edit_screen::GLWindow.Screen
    viewscreen::GLWindow.Screen
    imgscreen::GLWindow.Screen
    datascreen::GLWindow.Screen
    gamma::Float32
    cov1::Array{GeometryTypes.Point{2,Float32},2}
end
