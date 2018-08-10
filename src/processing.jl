
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
