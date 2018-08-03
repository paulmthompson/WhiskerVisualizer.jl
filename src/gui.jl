export make_gui, add_callbacks, add_spikes, add_video, add_ttl_cov

const pause_cmd = pipeline(`echo 'set pause yes'`,`socat - /tmp/mpvsocket`)

const mpv_active = true;

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
    vid_path,mypath,y_data,max_time,ones(Float32,3),zeros(Int64,max_time),0,100)
end

function add_spikes(gui,channel_num)

    spike_path = spike_path = get_spike_path(gui.folder_path,channel_num)
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

    spike_path = get_spike_path(gui.folder_path,channel_num)
    io_spike = open(spike_path,"r")
    times=TimeArray(Int64,io_spike);

    xx=parse_ttl(io_event,times,channel_num)

    gui.video_ts=xx[3]

    if mpv_active
        stdout, stdin, process = readandwrite(`mpv --hr-seek=always --input-ipc-server=/tmp/mpvsocket --quiet --osdlevel=0 $(gui.vid_path)
`)
        run(pause_cmd)
    end

    close(io_spike)
    close(io_event)
    nothing
end

function add_ttl_cov(gui,channel_num,cov_num)

    event_path = string(gui.folder_path, "all_channels.events")
    io_event = open(event_path,"r");

    spike_path = get_spike_path(gui.folder_path,channel_num)
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

    #values needed to load images and plot it
    xoff = 100;
    yoff = 100;

    myimage32 = [Gray(rand()) for i=1:480,j=1:640]

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
    total_slider_values = 100:slider_step:gui.max_time
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

        if mpv_active
            frame_num = gui.video_ts[round(Int,t)]
            gui.t = round(Int,t)
            if gui.current_frame != frame_num
                gui.current_frame = frame_num
                run(myseek(frame_num / video_frame_rate))
            end
        end
        #Since this is automatically advancing, we can slow things down here if we wish
        #By only plotting if a certain number of frames have passed
        #If we want to speed things up, we could alternatively change more than 1 point on the axis by adding
        #Points from between the previous slider value and current slider value.

        #For example, if we are at real time, 1000 data points pass every frame (30 fps)
        #If we are 1/10 real time, then 100
        #1/100 real time then 10 data point every frame
        #1/1000 real time then 1 data point every frame

        #Consequently, at 1/10 real time, we are missing quite a few data points, and can't see spikes

        for mycov=1:3

            #We should first store recent data

            #Then plot the data with appropriate sampling based on the timebase
            #=
            for i=1:99
                gui.cov1[i,mycov] = Point2f0(i*5+xoff,gui.cov1[i+1,mycov][2])
            end
            gui.cov1[100,mycov] = Point2f0(500+xoff,gui.y_data[round(Int,t),mycov]*gui.y_scales[mycov]+yoff*mycov)
            =#

            #With each frame, we update 25/500 points on the line
            #That means that the total time displayed is 66.6 ms
            #We would lose spike resolution after this, so maybe would
            #be good to have a spike raster?
            for i=1:475
                gui.cov1[i,mycov] = Point2f0(i+xoff,gui.cov1[i+25,mycov][2])
            end

            xinds=4:4:100
            for i=1:25
                gui.cov1[i+475,mycov] = Point2f0(475+i+xoff,gui.y_data[round(Int,t-100+xinds[i]),mycov]*gui.y_scales[mycov]+yoff*mycov)
            end


        end
        gui.cov1
    end

    #Slider value is also send to image plotter that loads new frame and plots it
    if !mpv_active
        my_image = map(slider_value) do t

            video_frame_rate = 25

            frame_num = gui.video_ts[round(Int,t)]
            gui.t = round(Int,t)
            if gui.current_frame != frame_num
                gui.current_frame = frame_num
                f = VideoIO.openvideo(gui.vid_path)

                seek(f,frame_num / video_frame_rate)
                myimage = read(f)

                for i=1:640
                    for j=1:480
                        myimage32[j,i]=myimage[j,i]
                        myimage32[j,i]=myimage32[j,i]+gui.gamma
                    end
                end
                close(f)
            end

            myimage32
        end
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
    if !mpv_active
        _view(visualize(my_image),gui.imgscreen)
    end
    _view(visualize(
        controls,
        text_scale = 4mm,
        width = 8*iconsize
    ), gui.edit_screen, camera = :fixed_pixel)

end

myseek(x)=pipeline(`echo seek $x absolute`,`socat - /tmp/mpvsocket`)

set_gamma(x)=pipeline(`echo set gamma $x`,`socat - /tmp/mpvsocket`)

set_brightness(x)=pipeline(`echo set brightness $x`,`socat - /tmp/mpvsocket`)
