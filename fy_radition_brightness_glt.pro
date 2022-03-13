function h5_data_get,input_file,dataset_name
  file_id=h5f_open(input_file)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end

pro FY_radition_brightness_glt
  ;对FY4KM全圆盘数据进行某波段的辐射定标和重投影
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  
  input_directory='F:\xiangmu\LST\radiation_brightness\MYD021KM\new\FY\HDF\'
  output_directory='F:\xiangmu\LST\radiation_brightness\MYD021KM\new\FY\rad13_glt_big\'
  glt_file_name='E:\yaogan_data\FullMask_Grid_4000\FullMask_Grid_4000.raw'
  band='13'
  file_name=input_directory
  ;;;;;;;;;;获得经纬度范围
;  min_lon=102
;  max_lat=32
;  max_lon=105
;  min_lat=30
  min_lon=94
  max_lat=36
  max_lon=110
  min_lat=25
  
  envi_open_file, glt_file_name, r_fid=fid
  envi_file_query,fid,dims=dims,nb=nb,nl=nl,ns=ns
  lat_data=envi_get_data(dims=dims,fid=fid,pos=0)
  lon_data=envi_get_data(dims=dims,fid=fid,pos=1)


  lon_lat_pos=where((lat_data gt min_lat) and (lat_data lt max_lat) and (lon_data gt min_lon) and (lon_data lt max_lon),pos_num)
  pos_col_line=array_indices(lon_data,lon_lat_pos)
  col_min=min(pos_col_line[0,*])
  col_max=max(pos_col_line[0,*])
  line_min=min(pos_col_line[1,*])
  line_max=max(pos_col_line[1,*])
  ;;;;;;;;;;;;;

  ;创建查找表
  out_lon=output_directory+'lon_out.tiff'
  out_lat=output_directory+'lat_out.tiff'

  input_proj=envi_proj_create(/geographic)
  out_proj=envi_proj_create(/geographic)
  
  out_name_glt=output_directory+file_basename(file_name,'.tif')+'_glt.img';rad_data_glt.img
  out_name_hdr=output_directory+file_basename(file_name,'.tif')+'_glt.hdr';rad_data_glt.img

  
  file_list=file_search(input_directory,'*.HDF',count=file_n)
  
  for i=0,file_n-1 do begin
    name=file_basename(file_list[i])
    year_str_name=strmid(name,44,4)
    month_day_str_name=strmid(name,48,4)
    time_str_name=strmid(name,52,4)
    out_tiff=output_directory+'FY'+band+'_'+year_str_name+'_'+month_day_str_name+'_'+time_str_name+'.tiff'
    
    ;8.5um灰度值
    band_data=h5_data_get(file_list[i],'NOMChannel'+band)
    size_inf=size(band_data)
    ;增益和偏移
    scale_offset=h5_data_get(file_list[i],'CALIBRATION_COEF(SCALE+OFFSET)')
    ;创建定标后的数组
    rad_cal_data=make_array(size_inf[1],size_inf[2])

    ;辐射定标数据，每一个灰度值对应一个定标值
    for data_i=0,size_inf[1]-1 do begin
      for data_j=0,size_inf[2]-1 do begin
        if band_data[data_i,data_j] eq 65535 then begin
          rad_cal_data[data_i,data_j]=0
        endif else begin
          rad_cal_data[data_i,data_j]=band_data[data_i,data_j]*scale_offset[0,long(band)-1]+scale_offset[1,long(band)-1]
        endelse
      endfor
    endfor


    ;  write_tiff,out_name,rad_cal_data,/float
    ;  print,'finish'
    ;  out_data=!null
    
    ;--------------------------------------------------------glt--------------------------------------
    
    ;file_name='E:/Desktop/真.学习资料/大二下/FY/输出数据（一级）/data.tif'
    ;out_name='E:/Desktop/真.学习资料/大二下/FY/输出数据（二级）/'+'ccccc'+'.tiff'

    write_tiff,out_lon,lon_data[col_min:col_max,line_min:line_max],/float
    write_tiff,out_lat,lat_data[col_min:col_max,line_min:line_max],/float
    envi_open_file,out_lon,r_fid=lon_fid;打开经度数据，获取经度文件id
    envi_open_file,out_lat,r_fid=lat_fid;打开纬度数据，获取纬度文件id

    envi_glt_doit,x_fid=lon_fid,y_fid=lat_fid,x_pos=0,y_pos=0,$
      i_proj=input_proj,o_proj=out_proj,pixel_size=0.05,rotation=0.0,out_name=out_name_glt,r_fid=obtained_glt_fid

    rad_data=rad_cal_data
    out_target=output_directory+'target.tiff'
    write_tiff,out_target,rad_data[col_min:col_max,line_min:line_max],/float
    envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id
    out_name_geo=output_directory+file_basename(file_list[i],'.tif')+'_georef.img'
    out_name=output_directory+file_basename(file_list[i],'.tif')+'Reprojection.tiff';作为输出路径
    ;out_name_geo_hdr=output_directory+file_basename(file_name,'.hdf')+'_georef.hdr'

    envi_georef_from_glt_doit,$
      glt_fid=obtained_glt_fid,$;指定重投影所需GLT文件信息
      fid=target_fid,pos=0,$;指定待投影数据id
      out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息
    envi_file_query,geo_fid,dims=data_dims
    target_data1=envi_get_data(fid=geo_fid,pos=0,dims=data_dims)


    inf=size(target_data1)
    target_data=make_array(inf[1],inf[2])

    target_data[*,*]=target_data1


    map_info=envi_get_map_info(fid=geo_fid)
    geo_loc=map_info.MC
    pixel_size=map_info.PS

    geo_info={$
      MODELPIXELSCALETAG:[pixel_size[0],pixel_size[1],0.0],$
      MODELTIEPOINTTAG:[0.0,0.0,0.0,geo_loc[2],geo_loc[3],0.0],$
      GTMODELTYPEGEOKEY:2,$
      GTRASTERTYPEGEOKEY:1,$
      GEOGRAPHICTYPEGEOKEY:4326,$
      GEOGLINEARUNITSGEOKEY:9001,$
      GEOGANGULARUNITSGEOKEY:9102}


    write_tiff,out_tiff,target_data,/float,geotiff=geo_info

    envi_file_mng,id=lon_fid,/remove
    envi_file_mng,id=lat_fid,/remove
    envi_file_mng,id=target_fid,/remove
    envi_file_mng,id=obtained_glt_fid,/remove
    envi_file_mng,id=geo_fid,/remove

    if file_test(output_directory+file_basename(file_list[i],'.tif')+'_georef.img') then begin
      FILE_DELETE,output_directory+file_basename(file_list[i],'.tif')+'_georef.img'
    endif
    if file_test(output_directory+file_basename(file_list[i],'.tif')+'_georef.hdr') then begin
      FILE_DELETE,output_directory+file_basename(file_list[i],'.tif')+'_georef.hdr'
    endif
    if file_test(output_directory+file_basename(file_list[i],'.tif')+'_glt.hdr') then begin
      FILE_DELETE,output_directory+file_basename(file_list[i],'.tif')+'_glt.hdr'
    endif
    if file_test(output_directory+file_basename(file_list[i],'.tif')+'_glt.img') then begin
      FILE_DELETE,output_directory+file_basename(file_list[i],'.tif')+'_glt.img'
    endif

    print,'finish' +string(i)
    
  endfor
  FILE_DELETE,out_name_glt
  FILE_DELETE,out_name_hdr
  FILE_DELETE,out_lon
  FILE_DELETE,out_lat
  FILE_DELETE,out_target
  print,'完成重投影'

end