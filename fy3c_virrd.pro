function h5_att_get,file_name,att_name
  file_id=h5f_open(file_name)
  att_id=h5a_open_name(file_id,att_name)
  att_data=h5a_read(att_id)
  h5a_close,att_id
  h5f_close,file_id
  return,att_data
end

function h5_data_get,file_name,dataset_name
  file_id=h5f_open(file_name)
  dataset_id=h5d_open(file_id,dataset_name)
  data=h5d_read(dataset_id)
  h5d_close,dataset_id
  h5f_close,file_id
  return,data
  data=!null
end

pro FY3C_VIRRD
  
  file_name='E:\FY3C_VIRRD_30A0_L2_LST_MLT_HAM_20181226_POAD_1000M_MS.HDF'
  output_directory='D:\out\LST-DAY\'
  dir_test=file_test(output_directory,/directory)
  if dir_test eq 0 then begin
    file_mkdir,output_directory
  endif
  out_name=output_directory+file_basename(file_name,'.HDF')+'.tiff'

  dataset_name='VIRR_1Km_LST'
  left_T_x_data='Left-Top X'
  right_T_x_data='Right-Top X'
  left_T_y_data='Left-Top Y'
  right_T_y_data='Right-Top Y'
  
  data_temp=h5_data_get(file_name,dataset_name)
  data_temp=data_temp*0.1
  left_top_x=h5_att_get(file_name,left_T_x_data)
  right_top_x=h5_att_get(file_name,right_T_x_data)
  left_top_y=h5_att_get(file_name,left_T_y_data)
  right_top_y=h5_att_get(file_name,right_T_y_data)
  ;print,left_top_x,right_top_x,left_top_y,right_top_y
  write_tiff,'D:\out\LST-DAY\test.tif',data_temp,/float;,geotiff=geo_info
  data_size=size(data_temp)
  
  resolution=(right_top_x-left_top_x)/(data_size[1])
  print,resolution
  data1=data_temp
  data_size=size(data1)
  proj_x=fltarr(data_size[1],data_size[2])
  proj_y=fltarr(data_size[1],data_size[2])
  for col_i=0,data_size[1]-1 do begin
    proj_x[col_i,*]=left_top_x+(resolution*col_i)
  endfor
  for line_i=0,data_size[2]-1 do begin
    proj_y[*,line_i]=left_top_y-(resolution*line_i)
  endfor
  proj_x=proj_x*1000
  proj_y=proj_y*1000
  
  sin_prj=map_proj_init('Hammer',/gctp)
  geo_loc=map_proj_inverse(proj_x,proj_y,map_structure=sin_prj)
  geo_x=geo_loc[0,*]
  geo_y=geo_loc[1,*]
  ;print,geo_x
  lon_min=min(geo_x)
  lon_max=max(geo_x)
  lat_min=min(geo_y)
  lat_max=max(geo_y)
  print,lon_min
  geo_resolution=0.009
  data_box_geo_col=ceil((lon_max-lon_min)/geo_resolution)
  data_box_geo_line=ceil((lat_max-lat_min)/geo_resolution)
  data_box_geo=dblarr(data_box_geo_col,data_box_geo_line)
  data_box_geo[*,*]=-9999.0
  data_box_geo_col_pos=floor((geo_x-lon_min)/geo_resolution)
  data_box_geo_line_pos=floor((lat_max-geo_y)/geo_resolution)
  data_box_geo[data_box_geo_col_pos,data_box_geo_line_pos]=data1

  data_box_geo_out=fltarr(data_box_geo_col,data_box_geo_line)
  for data_box_geo_col_i=1,data_box_geo_col-2 do begin
    for data_box_geo_line_i=1,data_box_geo_line-2 do begin
      if data_box_geo[data_box_geo_col_i,data_box_geo_line_i] eq -9999.0 then begin
        temp_window=data_box_geo[data_box_geo_col_i-1:data_box_geo_col_i+1,data_box_geo_line_i-1:data_box_geo_line_i+1]
        temp_window=(temp_window gt 0.0)*temp_window
        temp_window_sum=total(temp_window)
        temp_window_num=total(temp_window gt 0.0)
        if (temp_window_num gt 3) then begin
          data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=temp_window_sum/temp_window_num
        endif
      endif else begin
       data_box_geo_out[data_box_geo_col_i,data_box_geo_line_i]=data_box_geo[data_box_geo_col_i,data_box_geo_line_i]
         endelse
       endfor
     endfor
   
  geo_info={$
    modelpixelscaletag:[geo_resolution,geo_resolution,0.0],$
    modeltiepointtag:[0.0,0.0,0.0,lon_min,lat_max,0.0],$
    gtmodeltypegeokey:2,$;1,投影坐标系统，2，地理纬度——经度系统，3，地心（x，y）系统
    gtrastertypegeokey:1,$
    geographictypegeokey:4326,$
    geogcitationgeokey:'gcs_wgs_1984',$
    geogangularunitsgeokey:9102,$
    geogsemimajoraxisgeokey:6378137.0,$
    geoginvflatteninggeokey:298.25722}
  result_name=output_directory+file_basename(file_name,'.HDF')+'.tiff'
  write_tiff,result_name,data_box_geo_out,/float,geotiff=geo_info

end
