
function make_gui()
    grid = Grid()
    
    top_grid = Grid()
    bottom_grid = Grid()
    
    #Spikes
    c1 = Canvas()
    @guarded draw(c1) do widget
        ctx = Gtk.getgc(c1)
        set_source_rgb(ctx,0.0,0.0,0.0)
        SpikeSorting.clear_c2(c1,1)
    end
    show(c1)
    setproperty!(c1,:hexpand,true)
    
    #Analog and Digital Channels
    c2 = Canvas()
    @guarded draw(c2) do widget
        ctx = Gtk.getgc(c2)
        set_source_rgb(ctx,0.0,0.0,0.0)
        paint(ctx)
    end
    show(c2)
    setproperty!(c2,:hexpand,true)
    setproperty!(c2,:vexpand,true)
    
    #Video
    c3 = Canvas(640,480)
    @guarded draw(c3) do widget
        ctx = Gtk.getgc(c3)
        set_source_rgb(ctx,0.0,0.0,0.0)
        paint(ctx)
    end
    show(c3)
    
    top_grid[1,1] = c1
    top_grid[2,1] = Canvas(20,480)
    top_grid[3,1] = c3
    
    divider_c = Canvas(-1,20)
    setproperty!(divider_c,:hexpand,true)
    
    bottom_grid[1,1] = divider_c
    bottom_grid[1,2] = c2
    
    grid[1,1] = top_grid
    grid[1,2] = bottom_grid
    
    win = Window(grid,"Visualizer") |> showall
    
    sleep(5.0)
    
    events = [rand(Float64,10000) for i=1:3]
    
    events_ts = [collect(1:10000) for i=1:3]
    
    myimage=zeros(UInt8,640,480)
    
    p=imagesc(myimage')
    #setattr(p.x1, draw_ticklabels=false)
    #setattr(p.y1, draw_ticklabels=false)
    #setattr(p.x1, draw_axis=false)
    #setattr(p.x2, draw_axis=false)
    #setattr(p.y1, draw_axis=false)
    #setattr(p.y2, draw_axis=false)
    display(c3, p)
    #reveal(c3)
    #hold(true)
    
    Visual_GUI(win,c1,c2,c3,3,events,events_ts,ones(Int64,3),zeros(Float64,1000,8),1,1,1000,50,ones(Float64,8),["" for i=1:8],"",myimage)
end

function display(c::Gtk.Canvas, pc::Winston.PlotContainer)
    Gtk.@guarded Gtk.draw(c) do widget
        ctx = Gtk.getgc(c)
        Cairo.set_source_rgb(ctx, 1, 1, 1)
        Cairo.paint(ctx)
        try
            Winston.page_compose(pc, Gtk.cairo_surface(c))
        catch e
            println("Error!")
        end
    end
end


