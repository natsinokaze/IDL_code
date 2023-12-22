PRO lon_lat_to_values
  ;输入经纬度，输出该经纬度对应tiff数据的行列号以及该经纬度上对应的值
  ;LOAD FUNCTIONS' MODULES OF ENVI
  COMPILE_OPT IDL2
  ENVI,/RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ;define the path
  imagePath = 'F:\benke\xiangmu\FY4B\data\summer\zhibiao\zb1_ndci\small\ndci_data\20220601_1200_rad_glt_ndci.tif'
  ;open HJ image

  ENVI_OPEN_FILE,imagePath,r_fid = fid
  ENVI_FILE_QUERY, fid, dims=dims;some parameters will be used to get data
  ;get the projection information

  image_proj = ENVI_GET_PROJECTION(fid = fid)
  ;create a geographic projection, can express the latitude and longtitude

  geo_proj = ENVI_PROJ_CREATE(/geo)
  ;convert input lat and long to coordinate under image projection
  ;NOTED:In the WGS-84, X is longtude, Y is latitude.
  longtude=103
  latitude=35
  ENVI_CONVERT_PROJECTION_COORDINATES,longtude,latitude,geo_proj,image_x,image_y,image_proj
  ;read metadata from image
  mapinfo=ENVI_GET_MAP_INFO(fid=fid)

  ;help,mapinfo;query the mapinfo structure, understand the MC is corner coordinate,PS is pixel Size
  ;print,mapinfo.MC[3]
  ;print,mapinfo.PS
  ;
  ;Geolocation of UpperLeft
  ;
  ULlat=mapinfo.MC[3];Y is latitude
  ULlon=mapinfo.MC[2];X is longtude ULlat和ULlon为左上角的经纬度坐标

  ;2. Pixel Size
  Xsize=mapinfo.PS[0]
  Ysize=mapinfo.PS[1]
  ;calculate the row and column according to x,y
  sample = FIX(ABS((image_x- ULlon)/Xsize));abs is determin the positive value, fix is get integer number
  line = FIX(ABS((image_y - ULlat)/Ysize)) ;确定行列的核心公式
  ;print,thisRow,thisColumn
  ;get data via row and column
  DN_data= ENVI_GET_DATA(fid = fid,dims = dims,pos = 0)
  ;help,DN_data
  ;get_data
  dn = DN_data[sample,line]
  ;write to file
  PRINT,dn
  ;Exit ENVI
  ENVI_BATCH_EXIT

end