
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
