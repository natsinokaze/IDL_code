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
function hdf4_caldata_get,file_name,sds_name,scale_name,offset_name
  sd_id=hdf_sd_start(file_name,/read)
  sds_index=hdf_sd_nametoindex(sd_id,sds_name)
  sds_id=hdf_sd_select(sd_id,sds_index)
  hdf_sd_getdata,sds_id,data
  att_index=hdf_sd_attrfind(sds_id,scale_name)
  hdf_sd_attrinfo,sds_id,att_index,data=scale_data
  att_index=hdf_sd_attrfind(sds_id,offset_name)
  hdf_sd_attrinfo,sds_id,att_index,data=offset_data
  hdf_sd_endaccess,sds_id
  hdf_sd_end,sd_id
  data_size=size(data)
  data_ref=fltarr(data_size[1],data_size[2],data_size[3])
  for layer_i=0,data_size[3]-1 do begin
    data_ref[*,*,layer_i]=scale_data[layer_i]*(data[*,*,layer_i]-offset_data[layer_i])
  endfor
  data=!null
  return,data_ref
end

pro modis_35_021
  ;进行Modis数据辐射定标已经除去云区
  compile_opt idl2
  envi,/restore_base_save_files
  envi_batch_init
  
  input_021_directory='F:\xiangmu\LST\radiation_brightness\MYD021KM\new\Modis\HDF_chengdu';原始数据路径
  input_35_directory='F:\xiangmu\LST\radiation_brightness\MYD021KM\new\Modis\MYD35_L2\HDF_chengdu\';云掩膜数据路径
  type='MOD';卫星型号
  input_band='31';处理波段数
  output_directory='F:\xiangmu\LST\radiation_brightness\MYD021KM\new\Modis_chengdu_nocloud\31_TIFF\'
  
  file_021_list=file_search(input_021_directory,'*.hdf',count=file_n)
  file_35_list=file_search(input_35_directory,'*.hdf',count=file_n)
  
;  for i=0,file_n-1 do begin
;    print,file_basename(file_021_list[i])
;    print,file_basename(file_35_list[i])
;    print,'---------------------'
;  endfor
  
;  modis_file='F:\xiangmu\LST\radiation_brightness\MYD021KM\new\Modis\HDF_chengdu\MYD021KM.A2019223.0610.061.2019223191644.hdf'
;  
;  cloud_file='F:\xiangmu\LST\radiation_brightness\MYD021KM\new\Modis\MYD35_L2\HDF_chengdu\MYD35_L2.A2019223.0610.061.2019223191821.hdf'
  
  
  
  all_band_str=hdf4_attdata_get(file_021_list[0],'EV_1KM_Emissive','band_names');获得的是个字符串
  str_long=(strlen(all_band_str)+1)/3;获取该数据集含有的波段数量
  all_band=strarr(str_long)
  all_band=STRSPLIT(all_band_str, ',',/EXTRACT)

  all_scale=hdf4_attdata_get(file_021_list[0],'EV_1KM_Emissive','radiance_scales')
  all_offsets=hdf4_attdata_get(file_021_list[0],'EV_1KM_Emissive','radiance_offsets')
  

  for i=0,file_n-1 do begin
    modis_lon_data=hdf4_data_get(file_021_list[i],'Longitude')
    modis_lat_data=hdf4_data_get(file_021_list[i],'Latitude')
    
    data=hdf4_data_get(file_021_list[i],'EV_1KM_Emissive')
    band_pos=where(all_band eq input_band)
    scale=all_scale[band_pos]
    offset=all_offsets[band_pos]
    data=(data[*,*,band_pos]-offset[0])*scale[0]

    cloud_data=hdf4_data_get(file_35_list[i],'Cloud_Mask')
    cloud_0=cloud_data[*,*,0]
    cloud_0=(cloud_0 ge 0)*cloud_0+(cloud_0 lt 0)*(128+abs(cloud_0))
    cloud_0_size=size(cloud_0)

    cloud_binary=bytarr(cloud_0_size[1],cloud_0_size[2],8)
    for cloud_i=0,7 do begin
      cloud_binary[*,*,cloud_i]=cloud_0 mod 2
      cloud_0=cloud_0/2
    endfor

    cloud_result=(cloud_binary[*,*,0] eq 1) and (cloud_binary[*,*,1] eq 0) and (cloud_binary[*,*,2] eq 0)

    modis_target_data=data
    modis_target_data=data*(cloud_result eq 0)
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

    out_name_glt=output_directory+file_basename(file_021_list[i],'.hdf')+'_glt.img'
    out_name_glt_hdr=output_directory+file_basename(file_021_list[i],'.hdf')+'_glt.hdr'
    i_proj=envi_proj_create(/geographic)
    o_proj=envi_proj_create(/geographic)
    envi_glt_doit,$
      i_proj=i_proj,x_fid=x_fid,y_fid=y_fid,x_pos=0,y_pos=0,$;指定创建GLT所需输入数据信息
      o_proj=o_proj,pixel_size=pixel_size,rotation=0.0,out_name=out_name_glt,r_fid=glt_fid;指定输出GLT文件信息

    out_name_geo=output_directory+file_basename(file_021_list[i],'.hdf')+'_georef.img'
    out_name_geo_hdr=output_directory+file_basename(file_021_list[i],'.hdf')+'_georef.hdr'
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
      
    file_name=file_basename(file_021_list[i],'.hdf')
    year=strmid(file_name,10,4)
    date=long(strmid(file_name,14,3))
    caldat,julday(1,1,year)-1+date,month,day,year
    if month lt 10 then begin
      month='0'+strcompress(string(month),/remove_all)
    endif else begin
      month=strcompress(string(month),/remove_all)
    endelse
    
    if day lt 10 then begin
      day='0'+strcompress(string(day),/remove_all)
    endif else begin
      day=strcompress(string(day),/remove_all)
    endelse
    
    year=strcompress(string(year),/remove_all)
    time=strmid(file_name,18,4)
    out_tiff=output_directory+type+input_band+'_'+year+'_'+month+'_'+day+'_'+time+'.tiff';获取输出文件的名称
    
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