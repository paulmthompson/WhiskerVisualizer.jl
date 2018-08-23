export make_gui, add_callbacks, add_spikes, add_video, add_ttl_cov, add_labels, add_times

function make_gui(mypath)

    window = glscreen()

    description = """
    Usage of the play slider widget
    """
    #Create screens

    editarea, viewarea = y_partition(window.area, 20)
    edit_screen = Screen(window, area = editarea)
    viewscreen = Screen(window, name = :viewscreen,area = viewarea)

    dataarea, imgarea = x_partition(viewarea,50)
    imgscreen = Screen(viewscreen, area = imgarea)
    datascreen = Screen(viewscreen, area = dataarea)

    slider_area, time_area = x_partition(editarea,50)
    slider_screen = Screen(edit_screen, area=slider_area)
    time_screen = Screen(edit_screen, area=time_area)

    vid_path = string(mypath,filter(x->contains(x,".mp4"),readdir(mypath))[1])

    max_time=10000

    #Y data is the covariate of interest
    y_data = rand(1f0:100f0,max_time,3)

    detect=DetectNeg();
    cluster=ClusterTemplate();
    align=AlignMin();
    feature=FeatureTime();
    reduce=ReductionNone();
    thres=ThresholdMeanN();
    num_channels=1;

    s=create_multi(detect,cluster,align,feature,reduce,thres,1,48,Float32);
    buf=Spike[Spike() for i=1:10000,j=1:1];
    nums=zeros(Int64,1)
    s[1].thres=-1.0

    tif = Array{ColorTypes.Gray{FixedPointNumbers.Normed{UInt8,8}},3}(0,0,0)
    whiskers=[Whisker() for i=1:1, j=1:1]

    analysis_gui(window,edit_screen,viewscreen,imgscreen,datascreen,time_screen, slider_screen,
    0.2f0,
    Point2f0[Point2f0(i*5,0.0)  for i=1:500,j=1:3],
    vid_path,mypath,y_data,max_time,ones(Float32,3),zeros(Int64,max_time),0,100,
    1,zeros(Int64,0),s[1],buf,nums,false,[Point2f0(0.0,0.0) for i=1:50,j=1:4],
    Reactive.Signal(1),[zeros(Int64,0) for i=0:0],zeros(Int64,length(-3000:300:3000)-1),1:10:10000,tif,whiskers)
end

function add_spikes(gui,channel_num)

    spike_path = get_spike_path(gui.folder_path,channel_num)
    io_spike = open(spike_path,"r");

    spikes = SampleArray(Float32,io_spike);
    spikes = Array(spikes)

    gui.y_data=zeros(Float32,length(spikes),3)

    gui.y_data[:,1]=spikes
    #gui.max_time=length(spikes)

    close(io_spike)
    nothing
end

function add_times(gui,channel_num)

    spike_path = get_spike_path(gui.folder_path,channel_num)
    io_spike = open(spike_path,"r")
    times=TimeArray(Int64,io_spike);

    gui.start_time=times[1]
    gui.max_time=length(times)

    slider_step = round(Int64,gui.max_time / ((gui.max_time-100) / 1000 * 10))
    gui.slider_values = 30000:slider_step:gui.max_time

    close(io_spike)

    nothing
end

function add_video(gui,channel_num)

    event_path = string(gui.folder_path, "all_channels.events")
    io_event = open(event_path,"r");

    xx=parse_ttl(io_event,channel_num,gui.start_time,gui.max_time)

    gui.video_ts=xx[3]

    #If i seek to the last frame, mpv crashes, so set to second to last frame
    gui.video_ts[gui.video_ts.==gui.video_ts[end]]=gui.video_ts[end]-1;

    stdout, stdin, process = mpv_open(gui.vid_path)
    sleep(1.0)
    run(pause_cmd)

    close(io_event)
    nothing
end

function add_ttl_cov(gui,channel_num,cov_num)

    event_path = string(gui.folder_path, "all_channels.events")
    io_event = open(event_path,"r");

    xx=parse_ttl(io_event,channel_num,gui.start_time,gui.max_time)

    gui.y_data[:,cov_num] = xx[2]

    push!(gui.event_ts,xx[1]-gui.start_time)

    close(io_event)
nothing


    nothing
end

function get_spike_path(folder_path,channel_num)

    adc_channels=filter(x->contains(x,".continuous"),readdir(folder_path))

    spike_path=string(folder_path,adc_channels[channel_num])

    spike_path
end


function add_callbacks(gui)

    #slider is used to start and stop animation, as well as drag to certain point
    #Play slider renders at 30 fps
    #Our DAQ records at 30000, so we can roughly control our speed of playback by how far
    #advance in time with each frame in that 30 fps
    #For instance, if we play just 1 data point per frame, that would be 30000 / 30 = 1/1000 of real time
    #Lets slow down to 1/10 of normal

    iconsize = 8mm
    play_viz, slider_value = play_slider(
        gui.sliderscreen, iconsize, gui.slider_values
    )
    #Each slider value change sends a signal to covariate plotter
    #100 points are plotted on the x axis.
    #The time scale dictates how far in the future we can visualize
    #For instance, 100 / 30000 = is only 3 ms
    #We want to see the previous points as time advances, so these should always be some multiple of the slowdown
    time_scale=1;
    my_animation = map(slider_value) do t

        video_frame_rate = 25 #We should calculate this
        #Because the video is not continuous, at T we should
        #find the total frame count at that index and use that instead

            frame_num = gui.video_ts[round(Int,t)]
            gui.t = round(Int,t)
            if gui.current_frame != frame_num
                gui.current_frame = frame_num
                run(myseek(frame_num / video_frame_rate))
            end

            plot_lines(gui,t,increment=2,p_per_frame=100)

        gui.cov1
    end

    my_spikes = map(slider_value) do t

        if gui.show_spikes
            sort_spikes(gui,t)
            event_triggered(gui,t)
            plot_spikes(gui)
        end

        gui.spikes
    end

    my_colors = map(my_spikes) do t

        waveform_color=[RGBA(0f0, 0f0, 1f0,1f0) for i=1:(size(t,2)-3)*size(t,1)]

        thres_color = [RGBA(0f0, 0f0, 0f0,1f0) for i=1:size(t,1)*3]

        [waveform_color; thres_color]
    end

    my_time = map(slider_value) do t

        minutes = div(t, 30000 * 60)
        seconds = round((t- minutes*60*30000)/30000,2)

        mystring=string("              ", minutes,"m ",seconds,"s")
    end

    gamma_slider, gamma_slider_s = labeled_slider(0.0f0:.1f0:1.0f0,gui.sliderscreen)

    change_gamma = map(gamma_slider_s) do t
       gui.gamma = t
    end

    controls = Pair[
        "play" => play_viz,
        "gamma" => gamma_slider,
    ]

    gui.p_slider=slider_value

    _view(visualize(my_animation, :lines,thickness=2f0), gui.datascreen)
    _view(visualize(my_spikes, :lines, thickness=1f0,color = my_colors), gui.imgscreen)
    _view(visualize(
        controls,
        text_scale = 4mm,
        width = 8*iconsize
    ), gui.sliderscreen, camera = :fixed_pixel)
    _view(visualize(my_time, color=RGBA(0f0,0f0,0f0)),gui.timescreen)

end

function add_labels(points,labels,myscreen)

    mypoints = GeometryTypes.Point2f0[points[i] for i=1:length(points)]

    (mytext,mywidths)=GLVisualize.annotated_text(mypoints,labels)

    _view(mytext,myscreen)
end
