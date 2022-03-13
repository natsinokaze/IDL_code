pro sl_sg
  ;进行通过shp文件进行四川省裁剪
  COMPILE_OPT idl2
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT,/NO_STATUS_WINDOW
  
  input_directory='F:\xiangmu\LST\day_LST_new\test\FY4A_GLT\'
  file_list=file_search(input_directory,'*.tiff')
  file_num=n_elements(file_list)
  
  ;infile='E:\Desktop\xiangmu\FY4A四川省风云温度验证\贵州-2019-tiff\LST_DISK_20190801000000_20190801001459.tiff'
  ;outfile='E:\Desktop\xiangmu\DATA\FY3_BEIJING_HFII_DAY_200808031211_Mercator_Sub.dat'
  shpfile='E:\yaogan_data\shp_file\Sichuan_city_wgs84.shp'

  
  for dir_num=0,file_num-1 do begin
    infile=file_list[dir_num]
    outfile='F:\xiangmu\LST\day_LST_new\test\FY4A_sichuan_dat\'+file_basename(file_list[dir_num],'.tiff')+'_sichuan.dat'
    envi_open_file,infile,r_fid=tfid
    envi_file_query,tfid,dims=dims,ns=ns,nl=nl,nb=nb
    oproj=envi_get_projection(fid=tfid)
    iproj=envi_proj_create(/geographic)

    oshp=obj_new('IDLffShape',shpfile)
    oshp->GetProperty,n_Entities=n_ent,attribute_info=attr_info,n_attributes=n_attr,Entity_type=ent_type
    roi_ids=lonarr(n_ent)
    for i=0,n_ent-1 do begin
      entity=oshp->GetEntity(i)
      if ptr_valid(entity.parts) ne 0 then begin
        tempLon=reform((*entity.vertices)[0,*])
        tempLat=reform((*entity.vertices)[1,*])
        envi_convert_projection_coordinates, $
          tempLon,tempLat,iproj, $
          xmap,ymap,oproj
        envi_convert_file_coordinates, $
          tfid,xf,yf,xmap,ymap
        roi_ids[i]=envi_create_roi(ns=ns,nl=nl)
        envi_define_roi,roi_ids[i],xpts=xf,ypts=yf,/polygon
      endif

      if i eq 0 then begin
        xmin=round(min(xf,max=xmax))
        ymin=round(min(yf,max=ymax))
      endif else begin
        xmin=xmin<round(min(xf))
        xmax=xmax>round(max(xf))
        ymin=ymin<round(min(yf))
        ymax=ymax>round(max(yf))
      endelse
      oshp->DestroyEntity,entity
    endfor
    obj_destroy,oshp
    xmin=xmin>0
    xmax=xmax<ns
    ymin=ymin>0
    ymax=ymax<nl

    dims=[-1,xmin,xmax,ymin,ymax]
    envi_doit,'envi_subset_via_roi_doit', $
      fid=tfid, $
      dims=dims, $
      ns=ns,nl=nl, $
      pos=indgen(nb), $
      background=0, $
      roi_ids=roi_ids, $
      proj=oproj, $
      out_name=outfile
    envi_file_mng,id=tfid,/remove
    ;envi_file_mng,id=rfid,/remove
    envi_delete_rois,/all
  endfor
  
  

end