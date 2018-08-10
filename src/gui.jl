export make_gui, add_callbacks, add_spikes, add_video, add_ttl_cov

const pause_cmd = pipeline(`echo 'set pause yes'`,`socat - /tmp/mpvsocket`)

function make_gui(mypath)

    window = glscreen()

    description = """
    Usage of the play slider widget
    """
    #Create screens

    editarea, viewarea = y_partition(window.area, 20)
    edit_screen = Screen(window, area = editarea)
    viewscreen = Screen(
        window, name = :viewscreen,
        area = viewarea
    )
    dataarea, imgarea = x_partition(viewarea,50)
    imgscreen = Screen(viewscreen, area = imgarea)
    datascreen = Screen(viewscreen, area = dataarea)

    vid_path = string(mypath,filter(x->contains(x,".mp4"),readdir(mypath))[1])

    max_time=10000

    #Y data is the covariate of interest
    y_data = rand(1f0:100f0,max_time,3)

    analysis_gui(window,edit_screen,viewscreen,imgscreen,datascreen,0.2f0,Point2f0[Point2f0(i*5,0.0)  for i=1:500,j=1:3],
    vid_path,mypath,y_data,max_time,ones(Float32,3),zeros(Int64,max_time),0,100,1,zeros(Int64,0))
end

function add_spikes(gui,channel_num)

    spike_path = get_spike_path(gui.folder_path,channel_num)
    io_spike = open(spike_path,"r");

    spikes = SampleArray(Float32,io_spike);
    spikes = Array(spikes)

    gui.y_data=zeros(Float32,length(spikes),3)

    gui.y_data[:,1]=spikes
    gui.max_time=length(spikes)

    close(io_spike)
    nothing
end

function add_video(gui,channel_num)

    event_path = string(gui.folder_path, "all_channels.events")
    io_event = open(event_path,"r");

    spike_path = get_spike_path(gui.folder_path,1)
    io_spike = open(spike_path,"r")
    times=TimeArray(Int64,io_spike);

    xx=parse_ttl(io_event,times,channel_num)

    gui.video_ts=xx[3]
    gui.start_time=times[1]

    #If i seek to the last frame, mpv crashes, so set to second to last frame
    gui.video_ts[gui.video_ts.==gui.video_ts[end]]=gui.video_ts[end]-1;

    #Error checking here with mpv socket?
    #May need to try and sleep if mpv is not open yet
    stdout, stdin, process = readandwrite(`mpv --hr-seek=always --input-ipc-server=/tmp/mpvsocket --quiet --osdlevel=0 $(gui.vid_path)`)
    sleep(1.0)
    run(pause_cmd)

    close(io_spike)
    close(io_event)
    nothing
end

function add_ttl_cov(gui,channel_num,cov_num)

    event_path = string(gui.folder_path, "all_channels.events")
    io_event = open(event_path,"r");

    spike_path = get_spike_path(gui.folder_path,1)
    io_spike = open(spike_path,"r")
    times=TimeArray(Int64,io_spike);

    xx=parse_ttl(io_event,times,channel_num)

    gui.y_data[:,cov_num] = xx[2]

    close(io_spike)
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
    slowdown = 10
    #max_time = 10000000

    #Let's make the slider only move in increments of the ADC, or multiples of 1/30000 seconds
    slider_step = round(Int64,gui.max_time / ((gui.max_time-100) / 1000 * 10))
    total_slider_values = 30000:slider_step:gui.max_time
    iconsize = 8mm
    play_viz, slider_value = play_slider(
        gui.edit_screen, iconsize, total_slider_values
    )
    #Each slider value change sends a signal to covariate plotter
    #100 points are plotted on the x axis.
    #The time scale dictates how far in the future we can visualize
    #For instance, 100 / 30000 = is only 3 ms
    #We want to see the previous points as time advances, so these should always be some multiple of the slowdown
    time_scale=1;
    my_animation = map(slider_value) do t

        DAQ_rate = 30000
        camera_frame_rate = 500 #Don't actually need this since we have the frame number
        video_frame_rate = 25
        #Because the video is not continuous, at T we should
        #find the total frame count at that index and use that instead

            frame_num = gui.video_ts[round(Int,t)]
            gui.t = round(Int,t)
            if gui.current_frame != frame_num
                gui.current_frame = frame_num
                run(myseek(frame_num / video_frame_rate))
            end

            plot_lines(gui,t)

        gui.cov1
    end

    gamma_slider, gamma_slider_s = labeled_slider(0.0f0:.1f0:1.0f0,gui.edit_screen)

    change_gamma = map(gamma_slider_s) do t
       gui.gamma = t
    end

    controls = Pair[
        "play" => play_viz,
        "gamma" => gamma_slider,
    ]

    _view(visualize(my_animation, :lines,thickness=5f0), gui.datascreen)
    _view(visualize(
        controls,
        text_scale = 4mm,
        width = 8*iconsize
    ), gui.edit_screen, camera = :fixed_pixel)

end

myseek(x)=pipeline(`echo seek $x absolute`,`socat - /tmp/mpvsocket`)

set_gamma(x)=pipeline(`echo set gamma $x`,`socat - /tmp/mpvsocket`)

set_brightness(x)=pipeline(`echo set brightness $x`,`socat - /tmp/mpvsocket`)
