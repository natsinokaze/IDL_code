pro to_jpg
  ;将tiff格式文件转换为jpg格式（包含22%拉伸）
  in_file_blue='E:\Users\桌面\Learn\gcsj4\data\LC81270402018014LGN00\LC08_L1TP_127040_20180114_20180120_01_T1_B3.TIF'
  in_file_green='E:\Users\桌面\Learn\gcsj4\data\LC81270402018014LGN00\LC08_L1TP_127040_20180114_20180120_01_T1_B4.TIF'
  in_file_red='E:\Users\桌面\Learn\gcsj4\data\LC81270402018014LGN00\LC08_L1TP_127040_20180114_20180120_01_T1_B5.TIF'
  ;input_file='E:\Users\桌面\Learn\gcsj4\data\rad\LC81270412013208LGN01\tiff\LC81270412013208LGN01.tiff'
  out_file='E:\Users\桌面\Learn\gcsj4\data\rad\LC81270402018014LGN00\jpg\'
  ;file_list=file_search(in_file,'*.tiff',count=file_n)
  ;print, file_list
  ;for file_i=0, file_n-1 do begin
    ;data=read_tiff(file_list[file_i],geotiff=geo_info)
    out_jpge=out_file+file_basename(in_file_blue,'.tiff')+'.jpg'

    ;print, size(data)
;    all_band=read_tiff(input_file) 
;    band1=reform(all_band[0,*,*]);蓝
;    band2=reform(all_band[1,*,*]);绿
;    band3=reform(all_band[2,*,*]);红
 
    band1=read_tiff(in_file_blue);蓝
    band2=read_tiff(in_file_green);绿
    band3=read_tiff(in_file_red);红
    
    
    band_size=size(band1)
    out_band=uintarr(3,band_size[1], band_size[2])
    out_band[0,*,*]=band3;红
    out_band[1,*,*]=band2;绿
    out_band[2,*,*]=band1;蓝
    out_band=((out_band ge 0) and (out_band le 65535))*out_band
    help,out_band
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    data_a=n_elements(band3)
    fillval_pos=where(band3 eq 65535, count)
    fillval_per=float(count)/float(data_a)
    min_pos=long(0.02*data_a)
    max_pos=long((1-fillval_per-0.02)*data_a)
    ;max_pos=long(1*data_a)
    band3_sort=sort(band3)
    band3_sort_minpos=band3_sort[min_pos]
    band3_sort_maxpos=band3_sort[max_pos]
    band3_min=band3[band3_sort_minpos]
    band3_max=band3[band3_sort_maxpos]
    ;;;;;;;;;;;;;;;;;;;;;
    data_a=n_elements(band2)
    fillval_pos=where(band2 eq 65535, count)
    fillval_per=float(count)/float(data_a)
    min_pos=long(0.02*data_a)
    max_pos=long((1-fillval_per-0.02)*data_a)
    
    band2_sort=sort(band2)
    band2_sort_minpos=band2_sort[min_pos]
    band2_sort_maxpos=band2_sort[max_pos]
    band2_min=band2[band2_sort_minpos]
    band2_max=band2[band2_sort_maxpos]
    ;;;;;;;;;;;;;;;;;;;;;
    data_a=n_elements(band1)
    fillval_pos=where(band1 eq 65535, count)
    fillval_per=float(count)/float(data_a)
    min_pos=long(0.02*data_a)
    max_pos=long((1-fillval_per-0.02)*data_a)
    
    band1_sort=sort(band1)
    band1_sort_minpos=band1_sort[min_pos]
    band1_sort_maxpos=band1_sort[max_pos]
    band1_min=band1[band1_sort_minpos]
    band1_max=band1[band1_sort_maxpos]

    jpeg_band=bytarr(3, band_size[1], band_size[2])
    jpeg_band[0,*,*]=bytscl(out_band[0,*,*], min=band3_min, max=band3_max)
    jpeg_band[1,*,*]=bytscl(out_band[1,*,*], min=band2_min, max=band2_max)
    jpeg_band[2,*,*]=bytscl(out_band[2,*,*], min=band1_min, max=band1_max)
    ;print,jpeg_band[0,500:2000,1500:2000]
    ;print, jpeg_band
    write_jpeg, out_jpge, jpeg_band, true=1, order=1
  ;endfor
  print,"finish"
end