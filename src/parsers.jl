export check_camera_alignment, master_parse

function read_digital(io::IOStream)
    seekend(io)
    myend=position(io)
    println(myend)
    seek(io,1024)

    #Each event is 16 bytes

    myevents= [zeros(Int64,0) for i=1:8]

    while position(io)<(myend-16)
        t = read(io,Int64) #Timestamp
        read(io,Int16) #Sample position within buffer
        e_type = read(io,UInt8) #uint8 event type (all the events that are saved have type TTL = 3 ; Network Event = 5)
        read(io,UInt8) #uint8 processor ID (the processor this event originated from)
        e_id = read(io,UInt8) #uint8 event ID (code associated with this event, usually 1 or 0)
        channel = read(io,UInt8) #uint8 event channel (the channel this event is associated with)
        read(io,UInt16) #One uint16 recording number (version 0.2 and higher)
        if e_type == 3
            push!(myevents[channel+1],t)
        end
    end
    myevents
end

#Change open ephys files into a different MAT file for each unit with
#1) Analog trace, video ttls, and laser ttls
function master_parse(folder_path,video_chan,laser_chan)

    event_path = string(folder_path, "all_channels.events")
    io_event = open(event_path,"r");

    spike_path = get_spike_path(folder_path,1)
    io_spike = open(spike_path,"r")
    spikes = SampleArray(Float32,io_spike);
    spikes = Array(spikes)

    close(io_spike)

    io_spike = open(spike_path,"r")
    times=TimeArray(Int64,io_spike);

    digital=read_digital(io_event)

    video_ts=digital[video_chan][1:2:end] - times[1]
    laser_ts=digital[laser_chan][1:2:end] - times[1]

    close(io_spike)
    close(io_event)

    file=matopen(string(folder_path,"spikes.mat"),"w")
    write(file,"spikes",spikes)
    write(file,"video_ts",video_ts)
    write(file,"laser_ts",laser_ts)
    close(file)
    nothing
end

function parse_ttl(io,tt,ind)
    digital=read_digital(io)

    #Array of bools that is true during a TTL event, and false when no TTL is present
    digital_events=falses(length(tt));

    #Array where each index corresponds to the total number of TTL digital_events
    #Up to that point.
    digital_time=zeros(Int64,length(tt))

    states=falses
    states_t=digital[ind][1]
    states_i=1
    states_totals=0

    states_array=zeros(Int64,0)

    for i=2:length(tt)

        #If this is when a digital event occurs
        if states_t == tt[i]

            #Change the state
            digital_events[i] = !digital_events[i-1]

            #If we went high
            if digital_events[i]
                states_totals+=1
                push!(states_array,tt[i])
            end

            if length(digital[ind])<(states_i+1)

            else
                states_i=states_i+1

                #new time to look for is
                states_t=digital[ind][states_i]
            end

        else
            digital_events[i] = digital_events[i-1]
        end

        digital_time[i]=states_totals
    end
    (states_array,digital_events,digital_time)
end

function check_camera_alignment(gui)

    xx=read(`mediainfo --Output="Video;%FrameCount%" $(gui.vid_path)`)

    video_frames=parse(Int64,convert(String,xx[1:(end-1)]))
    if gui.video_ts[end]+1 == video_frames
        println("Exposure event totals match frames in video file")
    else
        println("ERROR: frame counts do not match")
    end
    nothing
end

function get_backup_timestamps(backup_path)

	xx=open(backup_path,"r")

	ephys_times=zeros(Int64,0)
	camera_frames=zeros(Int32,0)
	seek(xx,0)
	while (!eof(xx))
    		push!(ephys_times,read(xx, Int64))
    		push!(camera_frames,read(xx, Int32))
	end
	close(xx)
	(ephys_times,camera_frames)
end
