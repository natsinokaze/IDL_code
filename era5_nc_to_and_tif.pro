pro era5_nc_to_and_tif
  ;将era5的NC文件转为TIFF文件（包括重投影）
  compile_opt idl2
  envi, /restore_base_save_files
  envi_batch_init

  input_dir='F:\yanjiusheng\Evapotranspiration\SEBS_data\ERA5\original\'
  output_dir='F:\yanjiusheng\Evapotranspiration\SEBS_data\ERA5\ERA5_u10\'
  type='u10'
  file_list=file_search(input_dir,'*.nc')
  ncfile_i=n_elements(file_list)


  ;构建for循环，依次处理NC文件
  for i = 0,ncfile_i - 1 do begin
    ;打开NC文件
    ID_Nc_File = ncdf_open(file_list[i], /nowrite)

    NCDF_LIST, file_list[i], /VARIABLES, /DIMENSIONS, /GATT, /VATT

    lon_id = NCDF_VARID(ID_Nc_File, 'longitude');经度
    NCDF_VARGET, ID_Nc_File, lon_id, lon_arr
    lat_id = NCDF_VARID(ID_Nc_File, 'latitude');纬度
    NCDF_VARGET, ID_Nc_File, lat_id, lat_arr
;    t2m_id = NCDF_VARID(ID_Nc_File, 't2m');空气温度
;    NCDF_VARGET, ID_Nc_File, t2m_id, t2m_arr
;    d2m_id = NCDF_VARID(ID_Nc_File, 'd2m');露点温度
;    NCDF_VARGET, ID_Nc_File, d2m_id, d2m_arr
;    t2m_id = NCDF_VARID(ID_Nc_File, 't2m');空气温度
;    NCDF_VARGET, ID_Nc_File, t2m_id, t2m_arr
;    slhf_id = NCDF_VARID(ID_Nc_File, 'slhf');地表潜热
;    NCDF_VARGET, ID_Nc_File, slhf_id, slhf_arr
;    sshf_id = NCDF_VARID(ID_Nc_File, 'sshf');地表显热
;    NCDF_VARGET, ID_Nc_File, slhf_id, slhf_arr
;    time_id = NCDF_VARID(ID_Nc_File, 'time');时间
;    NCDF_VARGET, ID_Nc_File, time_id, time_arr
    
    target_id=NCDF_VARID(ID_NC_File,type)
    Ncdf_VARGET,ID_NC_FILE,TARGET_ID,target_arr
    
    time_id=NCDF_VARID(ID_NC_File,'time')
    Ncdf_VARGET,ID_NC_FILE,time_ID,time_arr
    days=time_arr/24
    hours=time_arr mod 24
    caldat, julday(1,1,1900)+ days ,m,d,y
    print,m,d,y
    
    ncdf_attget,ID_Nc_File,target_id,'scale_factor',scale
    ncdf_attget,ID_Nc_File,target_id,'add_offset',offset
    
    help,lon_arr,lat_arr,target_arr
    lat_i=size(lat_arr)
    lon_i=size(lon_arr)
    lat_arr=reform(lat_arr,1,lat_i[1])
    lon_arr=reform(lon_arr,lon_i[1],1)
    
    out_lon=output_dir+'lon_out.tiff'
    out_lat=output_dir+'lat_out.tiff'
    ;print,slhf_arr[*,*,0]

    lon_size=size(lon_arr)
    lat_size=size(lat_arr)
    

    lat_2dim=make_array(lon_size[1],lat_size[2])
    lon_2dim=make_array(lon_Size[1],lat_size[2])
    
    for a=0,lat_size[2]-1 do begin
      lon_2dim[*,a]=lon_arr[*,0]  
    endfor
    for a=0,lon_size[1]-1 do begin
      lat_2dim[a,*]=lat_arr
    endfor

    
    file_name=file_basename(file_list[i])
    print,file_name
    input_proj=envi_proj_create(/geographic)
    out_proj=envi_proj_create(/geographic)
    out_name_glt=output_dir+file_basename(file_name,'.nc')+'_glt.img';rad_data_glt.img
    out_name_hdr=output_dir+file_basename(file_name,'.nc')+'_glt.hdr';rad_data_glt.img

    write_tiff,out_lon,lon_2dim,/float
    write_tiff,out_lat,lat_2dim,/float
    ;  envi_open_file, glt_file_name, r_fid=fid
    ;  envi_file_query,fid,dims=dims,nb=nb,nl=nl,ns=ns
    
    data_size=size(target_arr)  
    
    for j=0,data_size[3]-1 do begin
      year=y[j]
      year=string(year)
      year=year.compress()
      month=m[j]
      month=string(month)
      month=month.compress()
      day=d[j]
      day=string(day)
      day=day.compress()
      hour=hours[j]
      if hour lt 10 then begin
        hour=string(hour)
        hour='0'+hour.compress()
      endif else begin
        hour=string(hour)
        hour=hour.compress()
      endelse
      
      
      envi_open_file,out_lon,r_fid=lon_fid;打开经度数据，获取经度文件id
      envi_open_file,out_lat,r_fid=lat_fid;打开纬度数据，获取纬度文件id

      envi_glt_doit,x_fid=lon_fid,y_fid=lat_fid,x_pos=0,y_pos=0,$
        i_proj=input_proj,o_proj=out_proj,pixel_size=0.05,rotation=0.0,out_name=out_name_glt,r_fid=obtained_glt_fid

      ;co2_data=co2_arr

      out_target=output_dir+'target.tiff'

      deal_data=target_arr[*,*,j]*scale+offset
       
      write_tiff,out_target,reform(deal_data),/float
      envi_open_file,out_target,r_fid=target_fid;打开目标数据，获取目标文件id
      out_name_geo=output_dir+file_basename(file_list[i],'.nc')+'_georef.img'
      out_name=output_dir+file_basename(file_list[i],'.nc')+'Reprojection.tiff';作为输出路径
      ;out_name_geo_hdr=output_dir+file_basename(file_name,'.hdf')+'_georef.hdr'

      envi_georef_from_glt_doit,$
        glt_fid=obtained_glt_fid,$;指定重投影所需GLT文件信息
        fid=target_fid,pos=0,$;指定待投影数据id
        out_name=out_name_geo,r_fid=geo_fid;指定输出重投影文件信息
      envi_file_query,geo_fid,dims=data_dims
      target_data1=envi_get_data(fid=geo_fid,pos=0,dims=data_dims)

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

      write_tiff,output_dir+type+'_'+year+'_'+month+'_'+day+'_'+hour+'_00'+'.tiff',target_data1,/float,geotiff=geo_info

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
      print,'finsish_j'+string(j)
      
    endfor
    


    print,i
  endfor
  FILE_DELETE,output_dir+'lat_out.tiff'
  FILE_DELETE,output_dir+'lon_out.tiff'
  FILE_DELETE,output_dir+'target.tiff'
  FILE_DELETE,output_dir+file_basename(file_list[0],'.nc')+'_georef.img'
  FILE_DELETE,output_dir+file_basename(file_list[0],'.nc')+'_georef.hdr'
  FILE_DELETE,output_dir+file_basename(file_list[0],'.nc')+'_glt.hdr'
  FILE_DELETE,output_dir+file_basename(file_list[0],'.nc')+'_glt.img'
  ;关闭
  envi_batch_exit
end
