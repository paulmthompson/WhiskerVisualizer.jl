
function plot_events(gui::Visual_GUI)
    
    ctx=Gtk.getgc(gui.c2)
    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)
    
    set_source_rgb(ctx,1.0,1.0,1.0)
    for i=1:gui.event_nums
        
        move_to(ctx,1,gui.prev_events[1,i])
        
        for j=2:(gui.xscale-1)
           line_to(ctx,j,gui.prev_events[j,i]) 
            gui.prev_events[j-1,i] = gui.prev_events[j,i]
        end
        
        #line_to(ctx,gui.xscale,gui.events[i][gui.time] + gui.yoffset*i)
        gui.prev_events[gui.xscale-1,i] = gui.events[i][gui.time] * gui.yscales[i] + gui.yoffset*i
        
        stroke(ctx)
        
        move_to(ctx,gui.xscale+10,gui.yoffset*i)
        #rotate(ctx,-pi/2)
        show_text(ctx,gui.event_labels[i])
        #SpikeSorting.identity_matrix(ctx)
        
    end
    
    reveal(gui.c2)
    
end

function plot_whiskers(gui)
   
    f = open(gui.impath)
    seek(f,640*480*(gui.time-1))
    read!(f, gui.myimage)
    close(f)
    
    p=imagesc(gui.myimage')
    setattr(p.x1, draw_ticklabels=false)
    setattr(p.y1, draw_ticklabels=false)
    setattr(p.x1, draw_axis=false)
    setattr(p.x2, draw_axis=false)
    setattr(p.y1, draw_axis=false)
    setattr(p.y2, draw_axis=false)
    display(gui.c3, p)
    reveal(gui.c3)
    
end
