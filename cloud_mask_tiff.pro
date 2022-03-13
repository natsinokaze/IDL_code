function hdf4_data_get,file_name,sds_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  return,data
end

pro cloud_mask_tiff
  ;对Modis云掩膜产品数据进行提取
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  in_file='F:\xiangmu\LST\radiation_brightness\MOD021KM\new\Modis\MOD35_L2\HDF\'
  output_directory='F:\xiangmu\LST\radiation_brightness\MOD021KM\new\Modis\MOD35_L2\TIFF\'
  type='MOD'
  
  file_list=file_search(in_file+'*.hdf')
  for i=0, n_elements(file_list)-1 do begin
    cm_data=hdf4_data_get(file_list[i],'Cloud_Mask')
    array=cm_data[*,*,0]
    array=(array ge 0)*array+(array lt 0)*(abs(array)+128)
    cm_data=!null
    array_size=size(array)
    array_binary=bytarr(array_size[1],array_size[2],8)
    
    for array_i=0,7 do begin
      array_binary[*,*, array_i]=array mod 2
      array=array/2.0
    endfor
    
    cloud_mask=array_binary[*,*, 0] eq 1 and array_binary[*,*, 1] eq 0 and array_binary[*,*, 2] eq 0
    cloud_mask=cloud_mask eq 0
    ;print, cloud_mask
    ;out_tiff=output_directory+file_basename(file_list[i],'.HDF')+'.tiff'
    modis_lon=hdf4_data_get(file_list[i], 'Longitude')
    modis_lat=hdf4_data_get(file_list[i],  'Latitude')

    modis_lon=congrid(modis_lon,array_size[1],array_size[2],/interp);将经纬度数据扩容至指定的范围大小,内插
    modis_lat=congrid(modis_lat,array_size[1],array_size[2],/interp)
    ;-----------------------------------------------------------------------------
    out_lon=output_directory+'lon_out.tiff'
    out_lat=output_directory+'lat_out.tiff'
    out_target=output_directory+'target.tiff'

    write_tiff,out_lon,modis_lon,/float
    write_tiff,out_lat,modis_lat,/float
    write_tiff,out_target,cloud_mask,/float

    envi_open_file,out_lon,r_fid=lon_fid;打开经度数据，获取经度文件id
    envi_open_file,out_lat,r_fid=lat_fid;打开纬度数据，获取纬度文件id
    envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id

    out_name_glt=output_directory+file_basename(file_list[i],'.hdf')+'_glt.img'
    out_name_glt_hdr=output_directory+file_basename(file_list[i],'.hdf')+'_glt.hdr'
    input_proj=envi_proj_create(/geographic)
    output_proj=envi_proj_create(/geographic)
    envi_glt_doit,$
      x_fid=lon_fid,y_fid=lat_fid,x_pos=0,y_pos=0,i_proj=input_proj,$;指定创建GLT所需输入数据信息
      o_proj=output_proj,pixel_size=0.01,rotation=0.0,out_name=out_name_glt,r_fid=obtained_glt_fid;指定输出GLT文件信息

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
      
    file_name=file_basename(file_list[i],'.hdf')
    year=strmid(file_name,10,4)
    date=long(strmid(file_name,14,3))
    caldat,julday(1,1,year)-1+date,month,day,year
    month=strcompress(string(month),/remove_all)
    day=strcompress(string(day),/remove_all)
    year=strcompress(string(year),/remove_all)
    time=strmid(file_name,18,4)
    out_tiff=output_directory+TYPE+'_'+year+'_'+month+'_'+day+'_'+time+'.tiff';获取输出文件的名称
    print,year+'_'+month+'_'+day+'_'+time+'.tiff'
    write_tiff,out_tiff,target_data,/float,geotiff=geo_info  
      
    write_tiff,out_tiff,target_data,/float,geotiff=geo_info    
    envi_file_mng,id=lon_fid,/remove
    envi_file_mng,id=lat_fid,/remove
    envi_file_mng,id=target_fid,/remove
    envi_file_mng,id=obtained_glt_fid,/remove
    envi_file_mng,id=geo_fid,/remove
    file_delete,[out_lon,out_lat,out_target,out_name_glt,out_name_glt_hdr]

    end_time=systime(1)

    envi_batch_exit,/no_confirm
   endfor
   
   
  print,'输出完成‘
end