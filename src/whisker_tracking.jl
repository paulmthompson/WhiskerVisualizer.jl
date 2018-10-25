
export load_wt_janelia, parse_wt_janelia, add_wt_a

function load_wt_janelia(gui,vid_name,data_name)

    meas=matread(string(gui.folder_path,data_name))

    gui.vid_path = string(gui.folder_path,vid_name)

    gui.tif=load(gui.vid_path);

    parse_wt_janelia(gui,meas)

    nothing
end

function parse_wt_janelia(gui,xx)
   gui.whiskers=[Whisker() for i=1:size(gui.tif,3), j=1:2]

    for i=1:length(xx["whiskers"]["x"])

        wid = xx["measurements"]["label"][i]+1
        t = xx["whiskers"]["time"][i]+1

        if (wid<size(gui.whiskers,2)+1)&(wid>0)

            pos_x = xx["whiskers"]["x"][i]
            pos_y = 480 - xx["whiskers"]["y"][i]

            gui.whiskers[t,wid].pos = [Point2f0(pos_x[j],pos_y[j]) for j=1:length(pos_x)]

            gui.whiskers[t,wid].ang = xx["measurements"]["angle"][i]
        end
    end

    nothing
end

function add_wt_a(gui,wnum,cnum)


    gui.y_data=zeros(Float32,size(gui.tif,3),3)

    for i=1:size(gui.whiskers,1)
       gui.y_data[i,cnum] = gui.whiskers[i,wnum].ang
    end

    #Find first nonzero value, calculate mean of after values and set first values equal to it
    f_ind = findfirst(gui.y_data[:,cnum] .!= 0.0)

    if f_ind>1
        mymean = mean(gui.y_data[f_ind:end,cnum])
        gui.y_data[1:(f_ind-1),cnum] = mymean
    end

    #Interpolate between missing slider_values
    data_inds=find(gui.y_data[:,cnum].!=0.0);
    mydata=gui.y_data[data_inds,cnum];

    itp=interpolate((data_inds,),mydata,Gridded(Linear()))

    for i=1:size(gui.y_data,1)
        gui.y_data[i,cnum]=itp[i]
        gui.y_data[i,cnum] = gui.y_data[i,cnum] * -1
    end

    gui.y_data[:,cnum] = gui.y_data[:,cnum] - mean(gui.y_data[:,cnum])

    nothing
end

function add_wt_callbacks(gui)



end
