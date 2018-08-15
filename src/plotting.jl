
function get_frame(f,frame)

    stream = f.avin.video_info[1].stream
    stream_info = f.avin.video_info[1]
    seek_stream_index = stream_info.stream_index0

    #timeBase = stream.time_base.num * VideoIO.AV_TIME_BASE / f.avin.video_info[1].codec_ctx.time_base.den
    timeBase = stream.time_base.num * VideoIO.AV_TIME_BASE / 500

    VideoIO.av_seek_frame(f.avin.apFormatContext[1],0,round(Int64,frame),VideoIO.AVSEEK_FLAG_ANY | VideoIO.AVSEEK_FLAG_FRAME)
    #VideoIO.avcodec_flush_buffers(f.pVideoCodecContext)
    #while !VideoIO.have_frame(f)
            #idx = VideoIO.pump(f.avin)
            #idx == f.stream_index0 && break
            #idx == -1 && throw(EOFError())
    #end
    #VideoIO.reset_frame_flag!(f)
    nothing
end

function plot_spikes(gui)

    gui.spikes=[Point2f0(0.0,0.0) for i=1:50,j=1:length(gui.spikes_ts)+1]

    for i=1:length(gui.spikes_ts)
        for j=1:50
            gui.spikes[j,i] = Point2f0(j*5+200,gui.y_data[gui.spikes_ts[i]-10+j,1].*gui.y_scales[1]+300)
        end
    end

    for j=1:50
        gui.spikes[j,end] = Point2f0(j*5+200,gui.s.thres*gui.y_scales[1]+300)
    end
    nothing
end

function plot_lines(gui,t)

    xoff = 0;
    yoff = 100;

    #Since this is automatically advancing, we can slow things down here if we wish
    #By only plotting if a certain number of frames have passed
    #If we want to speed things up, we could alternatively change more than 1 point on the axis by adding
    #Points from between the previous slider value and current slider value.

    #For example, if we are at real time, 1000 data points pass every frame (30 fps)
    #If we are 1/10 real time, then 100
    #1/100 real time then 10 data point every frame
    #1/1000 real time then 1 data point every frame

    #We have 500 data points on the x axis.
    #However long our t_duration is, should be flushed completely after that amount
    #of data has been processed. At 1/10 real time, we are passing 3000 every second
    #So 30000, or one second means that 30000 / 30 = 1000 points per frame updated

    #First, our total number of points should be closest whole number
    #Points / (# frames for data)
    # 600 / (300)  = 16 or 480 points total

    increment = 2
    total_points = 500
    remainder_points = total_points - increment

    p_per_frame = 100

    for mycov=1:3

        for i=1:remainder_points
            gui.cov1[i,mycov] = Point2f0(i+xoff,gui.cov1[i+increment,mycov][2])
        end

        x_inds = linspace(1,p_per_frame,increment+1)
        for i=1:increment

            x_point = remainder_points+i+xoff


            l_bound = t-p_per_frame + round(Int64,x_inds[i])
            r_bound = t-p_per_frame + round(Int64,x_inds[i+1])-1

            min_y = minimum(gui.y_data[l_bound:r_bound,mycov])
            max_y = maximum(gui.y_data[l_bound:r_bound,mycov])

            if (abs(min_y)>max_y)
                y_val = min_y
            else
                y_val = max_y
            end

            y_point = y_val*gui.y_scales[mycov]+yoff*mycov

            gui.cov1[i+remainder_points,mycov] = Point2f0(x_point,y_point)
        end

    end
end
