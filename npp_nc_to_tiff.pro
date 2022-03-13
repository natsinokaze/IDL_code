function h5_data_get,input_file,dataset_name
  file_id=h5f_open(input_file)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end
pro NPP_nc_to_tiff
  ;将NC文件转为TIFF
  compile_opt idl2
  envi, /restore_base_save_files
  envi_batch_init

  ;input_dir='E:\用户\桌面\data\nc\'
  input_dir='F:\xiangmu\NPP\LST\2020_huodian\NC\'
  output_dir='F:\xiangmu\NPP\LST\2020_huodian\TIFF_diedai10\'
  type='NPP_LST'
  for_i=10;用于设置迭代次数
  
  min_lon=99.5;西昌市
  max_lat=29.5
  max_lon=104
  min_lat=25.8
;  min_lon=99.5;木里市
;  max_lat=29.5
;  max_lon=102
;  min_lat=27.5
;  
;  min_lon=-9999
;  max_lat=9999
;  max_lon=9999
;  min_lat=-9999
  
  file_list=file_search(input_dir,'*.nc')
  ncfile_num=n_elements(file_list)
  file_name=output_dir


  ;创建查找表
  out_lon=output_dir+'lon_out.tif'
  out_lat=output_dir+'lat_out.tif'

  input_proj=envi_proj_create(/geographic)
  out_proj=envi_proj_create(/geographic)
  out_name_glt=output_dir+file_basename(file_name)+'_glt.img';rad_data_glt.img
  out_name_hdr=output_dir+file_basename(file_name)+'_glt.hdr';rad_data_glt.img

  ;构建for循环，依次处理NC文件
  for i = 0,ncfile_num - 1 do begin
    ;打开NC文件
    LST_data=h5_data_get(file_list[i],'VIIRS_Swath_LSTE/Data Fields/LST')
    lst_data=lst_data*0.02
    yuanshi_data=lst_data*0.02
    QC_data=h5_data_get(file_list[i],'VIIRS_Swath_LSTE/Data Fields/QC')
    data_size=size(QC_data)
    window_data=make_array(3,3);用于存放3*3内非0个数
    
    lon_data=h5_data_get(file_list[i],'VIIRS_Swath_LSTE/Geolocation Fields/longitude')
    lat_data=h5_data_get(file_list[i],'VIIRS_Swath_LSTE/Geolocation Fields/latitude')

    lon_lat_pos=where((lat_data gt min_lat) and (lat_data lt max_lat) and (lon_data gt min_lon) and (lon_data lt max_lon),pos_num)
    IF lon_lat_pos[0] eq -1 then continue
      
    pos_col_line=array_indices(lon_data,lon_lat_pos)
    col_min=min(pos_col_line[0,*])
    col_max=max(pos_col_line[0,*])
    line_min=min(pos_col_line[1,*])
    line_max=max(pos_col_line[1,*])
    
    for diedai_i=0,for_i-1 do begin
      for col_i=0,data_size[1]-1 do begin
        for lin_j=0,data_size[2]-1 do begin
          if col_i gt col_min and col_i lt col_max and lin_j gt line_min and lin_j lt line_max then begin
            if QC_data[col_i,lin_j] eq 7 and col_i gt 1 and lin_j gt 1 and col_i lt data_size[1]-1 and lin_j lt data_size[2]-1 then begin
              window_data[*,*]=lst_data[col_i-1:col_i+1,lin_j-1:lin_j+1]
              pos=where(window_data ne 0,num)
              if num ne 0 then begin
                lst_data[col_i,lin_j]=total(window_data[pos])*1.0/num
              endif
              window_data=make_array(3,3)
            endif          
          endif       
        endfor
      endfor
    endfor
    
    write_tiff,out_lon,lon_data[col_min:col_max,line_min:line_max],/float
    write_tiff,out_lat,lat_data[col_min:col_max,line_min:line_max],/float
    envi_open_file,out_lon,r_fid=lon_fid;打开经度数据，获取经度文件id
    envi_open_file,out_lat,r_fid=lat_fid;打开纬度数据，获取纬度文件id

    envi_glt_doit,x_fid=lon_fid,y_fid=lat_fid,x_pos=0,y_pos=0,$
      i_proj=input_proj,o_proj=out_proj,pixel_size=0.008,rotation=0.0,out_name=out_name_glt,r_fid=obtained_glt_fid
    

    out_target=output_dir+'target.tif'
    write_tiff,out_target,Lst_data[col_min:col_max,line_min:line_max],/float
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
    year=strmid(file_name,7,4)
    date=long(strmid(file_name,11,3))
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
    time=strmid(file_name,15,4)
    out_tiff=output_dir+type+'_'+year+'_'+month+'_'+day+'_'+time+'.tiff';获取输出文件的名称

    write_tiff,out_tiff,target_data,/float,geotiff=geo_info

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
