pro set_65533_to_
  input_directory='F:\xiangmu\LST\fy-站点\fy\fy_glt\buchong\'
  output_directory='F:\xiangmu\LST\fy-站点\fy\fy_glt_setnull_buchong\'
  
  file_list=file_search(input_directory,'*.tiff')
  file_n=n_elements(file_list)
  
  for i=0,file_n-1 do begin
    data=read_tiff(file_list[i],geotiff=geo_info)
    data_size=size(data)
    
    for lin_i=0,data_size[1]-1 do begin
      for col_i=0,data_size[2]-1 do begin
        if data[lin_i,col_i] eq 65533 or data[lin_i,col_i] eq 0 or data[lin_i,col_i] eq -1 or data[lin_i,col_i] eq -9999 then begin
          data[lin_i,col_i]= !values.F_NAN
        endif
      endfor
    endfor
    write_tiff,output_directory+file_basename(file_list[i],'.tiff')+'_setnull.tiff',data,/float,geotiff=geo_info
  endfor
end