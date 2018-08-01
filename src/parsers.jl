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
