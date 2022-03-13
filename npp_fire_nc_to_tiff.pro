function h5_data_get,input_file,dataset_name
  file_id=h5f_open(input_file)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end
pro npp_fire_nc_to_tiff
  ;将NC文件转为TIFF
  compile_opt idl2
  envi, /restore_base_save_files
  envi_batch_init
  ;input_dir='E:\用户\桌面\data\nc\'
  input_dir='F:\xiangmu\NPP\Fire_375\NC\'
  output_dir='F:\xiangmu\NPP\Fire_375\TIFF\'
  type='NPP_fire'
  file_list=file_search(input_dir,'*.nc',count=file_n)
  ncfile_num=n_elements(file_list)
  file_name=output_dir
  
  out_lon=output_dir+'lon_out.tif'
  out_lat=output_dir+'lat_out.tif'
  input_proj=envi_proj_create(/geographic)
  out_proj=envi_proj_create(/geographic)
  out_name_glt=output_dir+file_basename(file_name)+'_glt.img';rad_data_glt.img
  out_name_hdr=output_dir+file_basename(file_name)+'_glt.hdr';rad_data_glt.img
  
  for i=0,file_n-1 do begin
    ID_Nc_File = ncdf_open(file_list[i], /NOWRITE )
    ;if h5_data_get(file_list[i],'Fire Pixels/FP_latitude') ne !NULL then begin

    fire_lat_arr=h5_data_get(file_list[i],'Fire Pixels/FP_latitude')
    fire_lon_arr=h5_data_get(file_list[i],'Fire Pixels/FP_longitude')
    

    lon_data=make_array(1,n_elements(fire_lat_arr))
    lon_data[0,*]=fire_lon_arr[*]
    lat_data=make_array(1,n_elements(fire_lon_arr))
    lat_data[0,*]=fire_lat_arr[*]
    fire_data=make_array(1,n_elements(fire_lat_arr),value=1)
    
    write_tiff,out_lon,lon_data,/float
    write_tiff,out_lat,lat_data,/float
    envi_open_file,out_lon,r_fid=lon_fid;打开经度数据，获取经度文件id
    envi_open_file,out_lat,r_fid=lat_fid;打开纬度数据，获取纬度文件id

    envi_glt_doit,x_fid=lon_fid,y_fid=lat_fid,x_pos=0,y_pos=0,$
      i_proj=input_proj,o_proj=out_proj,pixel_size=0.008,rotation=0.0,out_name=out_name_glt,r_fid=obtained_glt_fid


    out_target=output_dir+'target.tif'
    write_tiff,out_target,fire_data,/float
    envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id
    out_name_geo=output_dir+file_basename(file_list[i],'.tif')+'_georef.img'

    ;out_name_geo_hdr=output_dir+file_basename(file_name,'.hdf')+'_georef.hdr'

    envi_georef_from_glt_doit,$
      glt_fid=obtained_glt_fid,$;指定重投影所需GLT文件信息
      fid=target_fid,pos=0,$;指定待投影数据id
      out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息
    envi_file_query,geo_fid,dims=data_dims
    target_data1=envi_get_data(fid=geo_fid,pos=0,dims=data_dims)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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

    file_name=file_basename(file_list[i],'.nc')
    year=strmid(file_name,13,4)
;    date=long(strmid(file_name,17,3))
;    caldat,julday(1,1,year)-1+date,month,day,year
;    if month lt 10 then begin
;      month='0'+strcompress(string(month),/remove_all)
;    endif else begin
;      month=strcompress(string(month),/remove_all)
;    endelse
;
;    if day lt 10 then begin
;      day='0'+strcompress(string(day),/remove_all)
;    endif else begin
;      day=strcompress(string(day),/remove_all)
;    endelse
;
;    year=strcompress(string(year),/remove_all)
;    time=strmid(file_name,15,4)
    month=strmid(file_name,17,2)
    day=strmid(file_name,19,2)
    time=strmid(file_name,21,4)
    out_tiff=output_dir+type+'_'+year+'_'+month+'_'+day+'_'+time+'.tiff';获取输出文件的名称

    write_tiff,out_tiff,target_data,geotiff=geo_info

    envi_file_mng,id=lon_fid,/remove
    envi_file_mng,id=lat_fid,/remove
    envi_file_mng,id=target_fid,/remove
    envi_file_mng,id=obtained_glt_fid,/remove
    envi_file_mng,id=geo_fid,/remove

    if file_test(output_dir+file_basename(file_list[i],'.tif')+'_georef.img') then begin
      FILE_DELETE,output_dir+file_basename(file_list[i],'.tif')+'_georef.img'
    endif
    if file_test(output_dir+file_basename(file_list[i],'.tif')+'_georef.hdr') then begin
      FILE_DELETE,output_dir+file_basename(file_list[i],'.tif')+'_georef.hdr'
    endif
    if file_test(output_dir+file_basename(file_list[i],'.tif')+'_glt.hdr') then begin
      FILE_DELETE,output_dir+file_basename(file_list[i],'.tif')+'_glt.hdr'
    endif
    if file_test(output_dir+file_basename(file_list[i],'.tif')+'_glt.img') then begin
      FILE_DELETE,output_dir+file_basename(file_list[i],'.tif')+'_glt.img'
    endif


    print,i
    
  endfor
  FILE_DELETE,out_name_glt
  FILE_DELETE,out_name_hdr
  FILE_DELETE,out_lon
  FILE_DELETE,out_lat
  FILE_DELETE,out_target
  print,'完成重投影'
  ;关闭
  envi_batch_exit
end