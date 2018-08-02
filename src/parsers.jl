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

function parse_ttl(io,tt,ind)
    digital=read_digital(io)

    digital_events=falses(length(tt));

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
