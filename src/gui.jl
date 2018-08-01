
function make_gui()

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

    analysis_gui(window,edit_screen,viewscreen,imgscreen,datascreen,0.2f0,Point2f0[Point2f0(i*5,0.0)  for i=1:100,j=1:3])
end

function add_callbacks(gui)

    #values needed to load images and plot it
    impath = "/Users/wanglab/Dropbox/Neuro/Trigeminal/Data/071818/whiskers_071818.mp4"
    xoff = 100;
    yoff = 100;

    myimage32 = [Gray(rand()) for i=1:480,j=1:640]
    #myimage=zeros(UInt8,640,480)

    #Y data is the covariate of interest
    y_data = rand(1f0:100f0,100000000,3)

    #slider is used to start and stop animation, as well as drag to certain point
    #Play slider renders at 30 fps
    #Our DAQ records at 30000, so we can roughly control our speed of playback by how far
    #advance in time with each frame in that 30 fps
    #For instance, if we play just 1 data point per frame, that would be 30000 / 30 = 1/1000 of real time
    #Lets slow down to 1/10 of normal
    slowdown = 10
    max_time = 10000000

    total_slider_values = linspace(1, max_time, max_time / 1000 * slowdown)
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

        #Since this is automatically advancing, we can slow things down here if we wish
        #By only plotting if a certain number of frames have passed
        #If we want to speed things up, we could alternatively change more than 1 point on the axis by adding
        #Points from between the previous slider value and current slider value.

        for mycov=1:3
            for i=1:99
                gui.cov1[i,mycov] = Point2f0(i*5+xoff,gui.cov1[i+1,mycov][2])
            end
            gui.cov1[100,mycov] = Point2f0(500+xoff,y_data[round(Int,t),mycov]+yoff*mycov)
        end
        gui.cov1
    end

    #Slider value is also send to image plotter that loads new frame and plots it
    my_image = map(slider_value) do t

        f = VideoIO.openvideo(impath)
        #get_frame(f,round(Int,t))
        DAQ_rate = 30000
        camera_frame_rate = 500
        video_frame_rate = 25
        seek(f,t/DAQ_rate * camera_frame_rate / video_frame_rate)
        myimage = read(f)
        close(f)

        for i=1:640
            for j=1:480
                myimage32[j,i]=myimage[j,i]
                myimage32[j,i]=myimage32[j,i]+gui.gamma
            end
        end
        myimage32
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
    _view(visualize(my_image),gui.imgscreen)
    _view(visualize(
        controls,
        text_scale = 4mm,
        width = 8*iconsize
    ), gui.edit_screen, camera = :fixed_pixel)

end
