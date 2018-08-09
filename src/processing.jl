
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