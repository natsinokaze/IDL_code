PRO export_quick_image,input_file=input_file,out_jpg=out_jpg
  COMPILE_OPT IDL2
  e=envi(/headless)
  ;input_file为输入影像的路径
  raster=e.OpenRaster(input_file)
  ;进行RGB线性拉伸
  Task = ENVITask('LinearPercentStretchRaster');LinearPercentStretchRaster
  Task.INPUT_RASTER = raster
  Task.PERCENT=[2.0]
  Task.Execute
  outraster=Task.OUTPUT_RASTER
  data=outraster.GetData()
  lookup1=indgen(256)
  lookup1[0]=255
  lookup=[[lookup1],[lookup1],[lookup1]]
  data=outraster.GetData(BANDS=[2,1,0]);如果是单波段的影像这边Data=outraster.GetData(BANDS=0)
  I=image(data,MARGIN=0,rgb_table=lookup,/buffer,/order,DIMENSIONS=[6400,6400]);dimensions=[rows,columns]
  I.BACKGROUND_COLOR=[0,0,0]
  ;out_jpg为输出快视图的路径
  I.save,out_jpg
END
pro dat_to_jpg
  input_files='E:\Users\桌面\Learn\gcsj4\data\rad\LC81270402020196LGN00\LC81270402020196LGN00.dat'
  out_jpgs='E:\Users\桌面\Learn\gcsj4\data\rad\LC81270402020196LGN00\jpg\LC81270402020196LGN00.jpg'

  export_quick_image,input_file=input_files,out_jpg=out_jpgs
  ;  COMPILE_OPT IDL2
  ;  e=envi(/headless)
  ;  ;input_file为输入影像的路径
  ;  raster=e.OpenRaster(input_file)
  ;  ;进行RGB线性拉伸
  ;  Task = ENVITask('LinearPercentStretchRaster')
  ;  Task.INPUT_RASTER = raster
  ;  Task.PERCENT=[2.0]
  ;  Task.Execute
  ;  outraster=Task.OUTPUT_RASTER
  ;  data=outraster.GetData()
  ;  lookup1=indgen(256)
  ;  lookup1[0]=255
  ;  lookup=[[lookup1],[lookup1],[lookup1]]
  ;  data=outraster.GetData(BANDS=[2,1,0]);如果是单波段的影像这边Data=outraster.GetData(BANDS=0)
  ;  I=image(data,MARGIN=0,rgb_table=lookup,/buffer,/order);dimensions=[rows,columns]
  ;  I.BACKGROUND_COLOR=[255,255,255]
  ;  ;out_jpg为输出快视图的路径
  ;  I.save,out_jpg

end