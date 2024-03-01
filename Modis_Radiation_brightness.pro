function hdf4_data_get,file_name,sds_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  return,data
end

function hdf4_attdata_get,file_name,sds_name,att_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  att_index=hdf_sd_attrfind(sds_id,att_name)
  hdf_sd_attrinfo,sds_id,att_index,data=att_data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  return,att_data
end

pro Modis_Radiation_brightness
  ;对MOD021KM或者MYD021KM数据进行某波段的辐射定标
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init,/no_status_window


  input_directory='F:\xiangmu\LST\radiation_brightness\MYD021KM\hdf\'
  output_directory='F:\xiangmu\LST\radiation_brightness\MYD021KM\band32\tiff\'
  type='MYD'
  input_band='32'
  file_list=file_search(input_directory,'*.hdf',count=file_n)
  
  ;获取输入波段的scale和offset
  all_band_str=hdf4_attdata_get(file_list[0],'EV_1KM_Emissive','band_names');获得的是个字符串
  str_long=(strlen(all_band_str)+1)/3
  all_band=strarr(str_long)
  all_band=STRSPLIT(all_band_str, ',',/EXTRACT)
  
  all_scale=hdf4_attdata_get(file_list[0],'EV_1KM_Emissive','radiance_scales')
  all_offsets=hdf4_attdata_get(file_list[0],'EV_1KM_Emissive','radiance_offsets')
  band_pos=where(all_band eq input_band)
  scale=all_scale[band_pos]
  offset=all_offsets[band_pos]
  
  target_lat_min=0.0
  target_lat_max=90.0
  target_lon_min=0.0
  target_lon_max=180.0
  
  for i=0,file_n-1 do begin
    data=hdf4_data_get(file_list[i],'EV_1KM_Emissive')
    data=data[*,*,band_pos]*scale[0]+offset[0]
    out_tiff=output_directory+file_basename(file_list[i],'.hdf')+'.tiff';获取输出文件的名称
    
    start_time=systime(1)
    modis_lon_data=hdf4_data_get(file_list[i],'Longitude');获取经度信息
    modis_lat_data=hdf4_data_get(file_list[i],'Latitude');获取纬度信息)

    modis_target_data=data

    target_data_size=size(modis_target_data)
    modis_lon_data=congrid(modis_lon_data,target_data_size[1],target_data_size[2],/interp)
    modis_lat_data=congrid(modis_lat_data,target_data_size[1],target_data_size[2],/interp);核心！！！！
    
    pos=where((modis_lon_data ge target_lon_min) and (modis_lon_data le target_lon_max) and $
      (modis_lat_data ge target_lat_min) and (modis_lat_data le target_lat_max),pos_n)
    if pos_n eq 0 then continue
    pos_col_line=array_indices(modis_lon_data,pos)
    col_min=min(pos_col_line[0,*])
    col_max=max(pos_col_line[0,*])
    line_min=min(pos_col_line[1,*])
    line_max=max(pos_col_line[1,*])

    out_lon=output_directory+'lon_out.tiff'
    out_lat=output_directory+'lat_out.tiff'
    out_target=output_directory+'target.tiff'

    write_tiff,out_lon,modis_lon_data[col_min:col_max,line_min:line_max],/float
    write_tiff,out_lat,modis_lat_data[col_min:col_max,line_min:line_max],/float
    write_tiff,out_target,modis_target_data[col_min:col_max,line_min:line_max],/float

    envi_open_file,out_lon,r_fid=lon_fid;打开经度数据，获取经度文件id
    envi_open_file,out_lat,r_fid=lat_fid;打开纬度数据，获取纬度文件id
    envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id

    out_name_glt=output_directory+file_basename(file_list[i],'.hdf')+'_glt.img'
    out_name_glt_hdr=output_directory+file_basename(file_list[i],'.hdf')+'_glt.hdr'
    input_proj=envi_proj_create(/geographic)
    output_proj=envi_proj_create(/geographic)
    envi_glt_doit,$
      x_fid=lon_fid,y_fid=lat_fid,x_pos=0,y_pos=0,i_proj=input_proj,$;指定创建GLT所需输入数据信息
      o_proj=output_proj,pixel_size=0.01,rotation=0.0,out_name=out_name_glt,r_fid=obtained_glt_fid;指定输出GLT文件信息;注意分辨率！！！！！！！！！！！！！

    out_name_geo=output_directory+file_basename(file_list[i],'.hdf')+'_georef.img'
    out_name_geo_hdr=output_directory+file_basename(file_list[i],'.hdf')+'_georef.hdr'
    envi_georef_from_glt_doit,$
      glt_fid=obtained_glt_fid,$;指定重投影所需GLT文件信息
      fid=target_fid,pos=0,$;指定待投影数据id
      out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息

    envi_file_query,geo_fid,dims=data_dims
    target_data=envi_get_data(fid=geo_fid,pos=0,dims=data_dims)

    map_info=envi_get_map_info(fid=geo_fid)
    geo_loc=map_info.MC
    pixel_size=map_info.PS

    geo_info={$
      MODELPIXELSCALETAG:[pixel_size[0],pixel_size[1],0.0],$;x、y、z方向的像元分辨率
      MODELTIEPOINTTAG:[0.0,0.0,0.0,geo_loc[2],geo_loc[3],0.0],$;坐标转换信息，前三个0.0代表栅格图像上的第0,0,0个像元位置（z方向一般不存在），后面-180.0代表x方向第0个位置对应的经度是-180.0度，90.0代表y方向第0个位置对应的纬度是90.0度
      GTMODELTYPEGEOKEY:2,$;代表经纬度单位
      GTRASTERTYPEGEOKEY:1,$;代表栅格图像
      GEOGRAPHICTYPEGEOKEY:4326,$
      GEOGLINEARUNITSGEOKEY:9001,$
      GEOGANGULARUNITSGEOKEY:9102}

    caldat,julday(1,1,2018)+61,month,day,year
    
    file_name=file_basename(file_list[i],'.hdf')
    year=strmid(file_name,10,4)
     date=long(strmid(file_name,14,3))
    caldat,julday(1,1,year)-1+date,month,day,year
    month=strcompress(string(month),/remove_all)
    day=strcompress(string(day),/remove_all)
    year=strcompress(string(year),/remove_all)
    time=strmid(file_name,18,4)
    out_tiff=output_directory+type+input_band+'_'+year+'_'+month+'_'+day+'_'+time+'.tiff';获取输出文件的名称
    print,year+'_'+month+'_'+day+'_'+time+'.tiff'
    write_tiff,out_tiff,target_data,/float,geotiff=geo_info
    
    envi_file_mng,id=lon_fid,/remove
    envi_file_mng,id=lat_fid,/remove
    envi_file_mng,id=target_fid,/remove
    envi_file_mng,id=obtained_glt_fid,/remove
    envi_file_mng,id=geo_fid,/remove
    file_delete,[out_lon,out_lat,out_target,out_name_glt,out_name_glt_hdr,out_name_geo,out_name_geo_hdr]

    end_time=systime(1)
    print,end_time-start_time
  endfor
  envi_batch_exit,/no_confirm
  
  
end
