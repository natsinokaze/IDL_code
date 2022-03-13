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
pro modis11_L2_glt
  ;进行MOD11_L2或MYD11_L2的LST数据集重投影
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  
  Modis_directory='F:\xiangmu\LST\LST_L2\MYD11_L2\HDF\'
  output_directory='F:\xiangmu\LST\LST_L2\MYD11_L2\LST_tiff\'
  type='MOD'
  modis_list=file_search(Modis_directory,'*.hdf',count=file_n)
  
  for i=0,file_n-1 do begin
    modis_lon_data=hdf4_data_get(modis_list[i],'Longitude')
    modis_lat_data=hdf4_data_get(modis_list[i],'Latitude')

    data=hdf4_data_get(modis_list[i],'LST')
    scale=hdf4_attdata_get(modis_list[i],'LST','scale_factor')

    modis_target_data=data*scale[0]
    target_data_size=size(modis_target_data)

    modis_lon_data=congrid(modis_lon_data,target_data_size[1],target_data_size[2],/interp)
    modis_lat_data=congrid(modis_lat_data,target_data_size[1],target_data_size[2],/interp)

    ;  pos=where((modis_lon_data ge 115.0) and (modis_lon_data le 118.0) and (modis_lat_data ge 39.0) and (modis_lat_data le 42.0),count)
    ;  if count eq 0 then return
    ;  data_size=size(modis_target_data)
    ;  data_col=data_size[1]
    ;  pos_col=pos mod data_col
    ;  pos_line=pos/data_col
    ;  col_min=min(pos_col)
    ;  col_max=max(pos_col)
    ;  line_min=min(pos_line)
    ;  line_max=max(pos_line)

    out_lon=output_directory+'lon_out.tiff'
    out_lat=output_directory+'lat_out.tiff'
    out_target=output_directory+'target.tiff'
    write_tiff,out_lon,modis_lon_data,/float
    write_tiff,out_lat,modis_lat_data,/float
    write_tiff,out_target,modis_target_data,/float

    envi_open_file,out_lon,r_fid=x_fid;打开经度数据，获取经度文件id
    envi_open_file,out_lat,r_fid=y_fid;打开纬度数据，获取纬度文件id
    envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id

    out_name_glt=output_directory+file_basename(modis_list[i],'.hdf')+'_glt.img'
    out_name_glt_hdr=output_directory+file_basename(modis_list[i],'.hdf')+'_glt.hdr'
    i_proj=envi_proj_create(/geographic)
    o_proj=envi_proj_create(/geographic)
    envi_glt_doit,$
      i_proj=i_proj,x_fid=x_fid,y_fid=y_fid,x_pos=0,y_pos=0,$;指定创建GLT所需输入数据信息
      o_proj=o_proj,pixel_size=pixel_size,rotation=0.0,out_name=out_name_glt,r_fid=glt_fid;指定输出GLT文件信息

    out_name_geo=output_directory+file_basename(modis_list[i],'.hdf')+'_georef.img'
    out_name_geo_hdr=output_directory+file_basename(modis_list[i],'.hdf')+'_georef.hdr'
    envi_georef_from_glt_doit,$
      glt_fid=glt_fid,$;指定重投影所需GLT文件信息
      fid=target_fid,pos=0,$;指定待投影数据id
      out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息

    envi_file_query,geo_fid,dims=data_dims
    target_data=envi_get_data(fid=geo_fid,pos=0,dims=data_dims)

    map_info=envi_get_map_info(fid=geo_fid)
    geo_loc=map_info.(1)
    px_size=map_info.(2)

    geo_info={$
      MODELPIXELSCALETAG:[px_size[0],px_size[1],0.0],$
      MODELTIEPOINTTAG:[0.0,0.0,0.0,geo_loc[2],geo_loc[3],0.0],$
      GTMODELTYPEGEOKEY:2,$
      GTRASTERTYPEGEOKEY:1,$
      GEOGRAPHICTYPEGEOKEY:4326,$
      GEOGCITATIONGEOKEY:'GCS_WGS_1984',$
      GEOGANGULARUNITSGEOKEY:9102,$
      GEOGSEMIMAJORAXISGEOKEY:6378137.0,$
      GEOGINVFLATTENINGGEOKEY:298.25722}

    file_name=file_basename(modis_list[i],'.hdf')
    year=strmid(file_name,10,4)
    date=long(strmid(file_name,14,3))
    caldat,julday(1,1,year)-1+date,month,day,year
    if month lt 10 then begin
      month='0'+strcompress(string(month),/remove_all)
    endif else begin
      month=strcompress(string(month),/remove_all)
    endelse
    
    if dat lt 10 then begin
      day='0'+strcompress(string(day),/remove_all)
    endif else begin
      day=strcompress(string(day),/remove_all)
    endelse
    year=strcompress(string(year),/remove_all)
    time=strmid(file_name,18,4)
    out_tiff=output_directory+type+'_'+year+'_'+month+'_'+day+'_'+time+'.tiff';获取输出文件的名称
    print,out_tiff
    write_tiff,out_tiff,target_data,/float,geotiff=geo_info

    envi_file_mng,id=x_fid,/remove
    envi_file_mng,id=y_fid,/remove
    envi_file_mng,id=target_fid,/remove
    envi_file_mng,id=glt_fid,/remove
    envi_file_mng,id=geo_fid,/remove
    file_delete,[out_lon,out_lat,out_target,out_name_glt,out_name_glt_hdr,out_name_geo,out_name_geo_hdr]
    print,i
  endfor
  envi_batch_exit,/no_confirm 

end