
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

    xy=[Point2f0(0.0,0.0) for i=1:50,j=1:length(gui.spikes_ts)]

    for i=1:length(gui.spikes_ts)
        for j=1:50
            xy[j,i] = Point2f0(j*5+200,gui.y_data[gui.spikes_ts[i]-10+j,1].*gui.y_scales[1]*2+300)
        end
    end

    lines2d = visualize(xy,:lines,thickness=1f0)
    _view(lines2d,gui.imgscreen)

end
