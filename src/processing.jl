
export clip_segment, put_together

function bandpass_filter(gui,inds,wn1,wn2)

    responsetype = Bandpass(wn1,wn2; fs=30000)
    designmethod=Butterworth(4)
    df1=digitalfilter(responsetype,designmethod)
    myfilt=DF2TFilter(df1)
    test_data=gui.y_data[inds,1];
    filt!(test_data,myfilt,test_data);
    test_data
end

function thres_ts(data,thres)

    test_data=data./maximum(data)
    spike_times=falses(length(test_data))
    spike_inds=zeros(Int64,0)
    for i=1:length(test_data)

        if abs(test_data[i])>thres
            spike_times[i]=true
            i=i+30
        end
    end
    spike_times
end

#Convolve spike timestamps with fake spike waveform of 1 ms duration
function spike_audio(spike_times)
    conv(sin.(0:pi/15:2*pi),spike_times)
end

function sort_spikes(gui,t)

    gui.s.index=0
    SpikeSorting.onlinesort!(gui.s,gui.y_data[(t-30000)+1:t,1],gui.buf,gui.spike_nums)

    gui.spikes_ts=[]
    for i=1:gui.spike_nums[1]
        push!(gui.spikes_ts,t-30000+1+gui.buf[i].inds[1])
    end
    gui.spike_nums[1]=0

    nothing
end

function get_sorted_ts(gui,t)

    gui.spikes_ts=gui.pre_sorted_ts[(gui.pre_sorted_ts.>(t-30000+1))&(gui.pre_sorted_ts.<t)]

end
function event_triggered(gui,t)

    my_events=gui.event_ts[2][((gui.event_ts[2].>(t-30000)).&(gui.event_ts[2].<t))]

    myrange=-3000:300:3000

    for k=1:length(gui.myhist)
        gui.myhist[k]=0
    end

    for i=1:length(my_events)
        for j=1:length(gui.spikes_ts)
            for k=1:length(myrange)-1
               ttt = gui.spikes_ts[j]-my_events[i]
                if (ttt > myrange[k]).&(ttt<myrange[k+1])
                   gui.myhist[k] += 1
                end
            end
        end
    end

    nothing
end

#Get the video times and analog indexes that are closest
#to t1 and t2 while also being equal to a value the slider adopts
#and being a whole second value of the mp4 video
function get_clip_times(gui,t1,t2)

    slider_step = round(Int64,gui.max_time / ((gui.max_time-100) / 1000 * 10))
    total_slider_values = 30000:slider_step:gui.max_time

    v_frame_rate = 25

    #Video Frame that is equal to a second in save video nearest to desired time
    full_frame = round(Int,gui.video_ts[t1] / v_frame_rate)

    #Corresponding index of analog channel that corresponds to video
    first_ind=findfirst(gui.video_ts./v_frame_rate .== full_frame)

    #First value of the slider that corresponds to that frame
    first_slider_value = findfirst(total_slider_values.>first_ind)

    #Video time in seconds that is closest to t2
    end_frame = round(Int,gui.video_ts[t2] / v_frame_rate)

    end_ind = findfirst(gui.video_ts./v_frame_rate .== end_frame)

    last_slider_value = findfirst(total_slider_values.>end_ind)

    clip_times(t1,t2,full_frame,end_frame,first_ind,end_ind,first_slider_value,last_slider_value)
end

function clip_segment(gui,t1,t2)

    tt = get_clip_times(gui,t1,t2)

    num_frames = tt.ts2 - tt.ts1

    #Create video clip of desired length
    run(`ffmpeg -ss $(tt.ts1) -i $(gui.vid_path) -c copy -t $(num_frames) short.mp4`)

    #Cut out corresponding audio for that second

    my_voltage = gui.y_data[tt.ind1:(tt.ind2),1]

    gui.s.index=0
    #Sort so that only spikes are left to remove crumby audio
    SpikeSorting.onlinesort!(gui.s,my_voltage,gui.buf,gui.spike_nums)

    my_audio=zeros(Float32,length(my_voltage))

    for i=1:gui.spike_nums[1]
        my_audio[gui.buf[i].inds]=my_voltage[gui.buf[1].inds]
    end

    gui.spike_nums[1]=0

    #We want the duration to be the same as the length of the video.
    #so num_frames * 100
    WAV.wavwrite(my_audio,"test.wav",Fs=div(t2-t1,num_frames))

    output_name = string(t1,"_with_audio.mp4")

    #Combine audio and video
    run(`ffmpeg -i short.mp4 -i test.wav -c:v copy -c:a aac -strict experimental $(output_name)`)

    #The above video has audio and video synchronized, but the length of the video is still a
    #Function of the length of time (t2-t1), as well as how many video frames actually represent
    #one second. to be played at 1/10 of normal speed, we want a 25 fps video to represent
    # 250 camera frames
    #If the camera is higher or lower FPS, it should be adjusted accordingly

    total_time = (t2-t1)/30000

    #How do we determine frame rate of camera?
    #Probably should calculate it roughly when we load in video data
    total_camera_time = (num_frames * 25)



    #run(`ffmpeg -i $(output_name) -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" -map "[v]" -map "[a]" out2.mp4`)


    nothing
end

function record_frames(gui,t1,t2)

    tt = get_clip_times(gui,t1,t2)

    io=GLVisualize.create_video_stream("analog.mp4",gui.win)

    total_frames = tt.s2 - tt.s1 - 1
    Reactive.set_value!(gui.p_slider.parents[1],tt.s1)
    Reactive.activate!(gui.p_slider.parents[1])

    last_time = gui.t
    GLVisualize.add_frame!(io)

    i=0
    while (i<total_frames)

        yield()

        if last_time != gui.t
            GLVisualize.add_frame!(io)
            i = i + 1
            last_time = gui.t
        end
    end

    close(io.io)

    sleep(5.0)
    #Because the video is saved at 35 fps, but the video is actually being
    #played at 30 fps, we need to change the video to be 30 fps
    run(`ffmpeg -y -i analog.mp4 -vf "setpts=0.833*PTS" -r 30 analog2.mp4`)

end

function put_together(gui,t1,t2)

    mkdir(string(t1))
    cd(string(t1))

    clip_segment(gui,t1,t2)
    resize!(gui.win,640,480)
    sleep(2.0)
    record_frames(gui,t1,t2)

    out_name = string(t1,"_with_audio.mp4")
    final_name = string(t1,".mp4")

    run(`ffmpeg -i analog2.mp4 -i $(out_name) -filter_complex hstack $(final_name)`)

    run(`rm short.mp4`)
    run(`rm $(out_name)`)
    run(`rm analog2.mp4`)
    run(`rm analog.mp4`)
    run(`rm test.wav`)
    cd("..")
    nothing
end
