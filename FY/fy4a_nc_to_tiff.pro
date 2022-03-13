pro fy4a_nc_to_tiff
  ;将NC文件转为TIFF和DAT文件
  compile_opt idl2
  envi, /restore_base_save_files
  envi_batch_init

  ;input_file='H:\FY4A_QQ\1.yuanshi_QPE\FY4A-_AGRI--_N_DISK_1047E_L2-_QPE-_MULT_NOM_20200330000000_20200330001459_4000M_V0001.NC'
  input_dir='F:\xiangmu\jiangshui\FY4A\NC\'
  file_list=file_search(input_dir,'*.NC')
  ncfile_num=n_elements(file_list)


  ;构建for循环，依次处理NC文件
  for i = 0,ncfile_num - 1 do begin
    ;打开NC文件
    ID_Nc_File = ncdf_open(file_list[i], /write)

    ;查看NC文件的指定变量'QPE'
    QPE_id = NCDF_VARID(ID_Nc_File, 'Precipitation')
    NCDF_LIST, file_list[i], /VARIABLES, /DIMENSIONS, /GATT, /VATT
    NCDF_VARGET, ID_Nc_File, QPE_id, QPE_arr
    dimensions = size(QPE_arr,/dimensions)

    NC_File_Basename = file_basename(file_list[i], '.NC')
    Date = strmid(NC_File_Basename,44,14)
    Out_Path = 'F:\xiangmu\jiangshui\FY4A\TIFF\'

    ;写成envi标准格式文件
    envi_write_envi_file, CTL_arr, $
      INTERLEAVE = 0, $ ;存储方式设置为BSQ
      nb = 1, $ ;波段数量为1
      nl = dimensions[1], $
      ns = dimensions[0], $
      out_name = Out_path + Date + '_QPE.dat',$
      r_fid = fid


    out_name = Out_path + Date + '_QPE.tiff'
    write_tiff,out_name,QPE_arr,/float
    print,i
  endfor
  ;关闭
  envi_batch_exit
end
