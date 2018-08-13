
export clip_segment

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

function clip_segment(gui,t1,t2)

    v_frame_rate = 25

    #Video Frame that is equal to a second in save video nearest to desired time
    full_frame = round(Int,gui.video_ts[t1] / v_frame_rate)

    #Corresponding index of analog channel that corresponds to video
    first_ind=findfirst(gui.video_ts./v_frame_rate .== full_frame)

    #Video time in seconds that is closest to t2
    end_frame = round(Int,gui.video_ts[t2] / v_frame_rate)

    end_ind = findfirst(gui.video_ts./v_frame_rate .== end_frame)

    num_frames = end_frame - full_frame

    #Create video clip of desired length
    run(`ffmpeg -ss $full_frame -i $(gui.vid_path) -c copy -t $(num_frames) output.mp4`)

    #Cut out corresponding audio for that second

    my_voltage = gui.y_data[first_ind:(end_ind),1]

    println(first_ind)
    println(end_ind)

    gui.s.index=0
    #Sort so that only spikes are left to remove crumby audio
    SpikeSorting.onlinesort!(gui.s,my_voltage,gui.buf,gui.spike_nums)

    my_audio=zeros(Float32,length(my_voltage))

    for i=1:gui.spike_nums[1]
        my_audio[gui.buf[i].inds]=my_voltage[gui.buf[1].inds]
    end

    gui.spike_nums[1]=0

    WAV.wavwrite(my_audio,"test.wav",Fs=div(30000,10))


    output_name = string(t1,".mp4")

    #Combine audio and video
    run(`ffmpeg -i output.mp4 -i test.wav -c:v copy -c:a aac -strict experimental $(output_name)`)

    #Remove temp video
    run(`rm output.mp4`)

    nothing
end

function record_frames(gui,t1,t2)

    #Find the total number of frames between t1 and t2
    slider_step = round(Int64,gui.max_time / ((gui.max_time-100) / 1000 * 10))
    total_slider_values = 30000:slider_step:gui.max_time

    first_slider_value = findfirst(total_slider_values.>t1)

    last_slider_value = findfirst(total_slider_values.>t2)


    total_frames = last_slider_value-first_slider_value

    io=GLVisualize.create_video_stream("myout.mkv",gui.win)

    Reactive.set_value!(gui.p_slider.parents[1],first_slider_value)
    Reactive.activate!(gui.p_slider.parents[1])

    for i=1:total_frames
    
        yield()
        GLVisualize.add_frame!(io)
    end

    close(io.io)

end
