PRO dattotif
  ;将dat文件转换为tiff文件
  e = ENVI()
  inpath = 'F:\xiangmu\LST\LST_L2\FY_afternoon\TIFF_cd_dat\'
  output_file='F:\xiangmu\LST\LST_L2\FY_afternoon\TIFF_cd_tiff\'
  file_list=file_search(inpath,'*.dat')
  n = n_elements(file_list)
  file_search=file_search(inpath,'*.dat',count = num,/test_regular)
  for i = 0,num-1 do begin ; 利用for循环实现批量转换
    raster1 = e.OpenRaster(file_search[i]) ; 读入文件
    aotname=file_search[i]
    fname=file_basename(aotname,'*.dat');;;;（7为.dat文件名长度，不包含‘.dat’）
    filepath_output = output_file +file_basename(file_list[i],'.dat')+'.tiff' ; 输出文件路径
    raster1.Export, filepath_output, 'TIFF' ; 输出为tiff格式
    Print,'finished'+'_'+strcompress(string(i),/remove_all)
  endfor
end