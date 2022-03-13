;function MapGrid_Labels, orientation, location, fractional, defaultlabel
;  if (location eq 0) then $
;    return, orientation ? 'Equator' : 'Prime Meridian'
;  degree = '!M' + string(176b) ; Use the Math symbol
;  label = string(abs(location),format='(F0.2)') + degree
;  suffix = orientation ? ((location lt 0) ? 'S' : 'N') : $
;    ((location lt 0) ? 'W' : 'E')
;  return, label + suffix
;end
pro mean_row_column
  ;对8个站点所有日期进行FY数据的对应并取平均值绘制折线图和散点图（输出一个折线图和一个csv文件、各站点散点图）
  input_fy_dir='F:\xiangmu\LST\fy-站点\fy\fy_glt_setnull_buchong\'
  input_csv_dir='F:\xiangmu\LST\fy-站点\zhandian\all\'
  input_zdpos_dir='F:\xiangmu\LST\fy-站点\八个站点位置.csv'
  output_zhexiantu_dir='F:\xiangmu\LST\fy-站点\平均折线图\'
  output_sandiantu_dir='F:\xiangmu\LST\fy-站点\平均散点图\'
  output_csv_dir='F:\xiangmu\LST\fy-站点\平均散点图\csv\'
  fy_list=file_search(input_fy_dir,'*.tiff',count=time_n)
  date_list=file_search(input_csv_dir,'*.csv',count=date_n)
  zd_info=read_csv(input_zdpos_dir, COUNT=zd_num)
  zd_data=zd_info.(1)
  lat_data=zd_info.(2)
  lon_data=zd_info.(3)
  date=file_basename(date_list,'.csv')


  zd_csv_info=make_array(zd_num,date_n,24)

  output_zd_num1=0
  output_zd_num2=0
  output_zd_num3=0
  for date_i=0,date_n-1 do begin;遍历所有日期
    csv_data=read_csv(date_list[date_i])
    for zd_i=0,zd_num-1 do begin;遍历所有站点
      for time_i=0,24-1 do begin;遍历所有小时
        zd_csv_info[zd_i,date_i,time_i]=csv_data.(time_i+1)[zd_i]
      endfor
    endfor

    ;    for ct_i=0,zd_num-1 do begin
    ;      plot1 = PLOT(zd_csv_info[ct_i,date_i,*], "r4D-", TITLE="LST")
    ;      ww=string(output_zd_num1)
    ;      plot1.save,output_zhexiantu_dir+'\站点\'+ww.Compress()+'.png',/border ;/border表示自动裁除散点图外的多余白边
    ;      plot1.close
    ;      output_zd_num1=output_zd_num1+1
    ;      print,output_zd_num1
    ;    endfor
  endfor


  ;---------------------获取FY数据对应站点的地表温度----------------------
  fy_zd_info=make_array(zd_num,date_n,24,value=!values.F_NAN)
  for date_i=0,date_n-1 do begin;遍历所有日期
    print,date_i

    index=where(strmid(file_basename(fy_list),0,8) eq date[date_i]);进行日期的对应
    if index[0] eq -1 then continue

    ;获取前一天日期
    year=long(strmid(date[date_i],0,4))
    month=long(strmid(date[date_i],4,2))
    day=long(strmid(date[date_i],6,2))
    jul_day=julday(month,day,year)
    jul_day_yes=jul_day-1
    CALDAT, jul_day_yes, Month_yes, Day_yes, Year_yes
    year_yes=string(year_yes)
    if month_yes lt 10 then begin
      month_yes='0'+string(month_yes)
    endif else begin
      month_yes=string(month_yes)
    endelse
    if day_yes lt 10 then begin
      day_yes='0'+string(day_yes)
    endif else begin
      day_yes=string(day_yes)
    endelse

    yesterday=year_yes.compress()+month_yes.compress()+day_yes.compress()
    print,yesterday
    index_today_yesterday=where(strmid(file_basename(fy_list),0,8) eq date[date_i] or strmid(file_basename(fy_list),0,8) eq yesterday)

    index_size=size(index_today_yesterday)

    for ii=0,24-1 do begin
      for index_i=0,index_size[1]-1 do begin;遍历所有小时
        hour_data=strmid(file_basename(fy_list[index_today_yesterday]),8,2)
        date_data=strmid(file_basename(fy_list[index_today_yesterday]),0,8)
        year_data=strmid(file_basename(fy_list[index_today_yesterday]),0,4)
        month_data=strmid(file_basename(fy_list[index_today_yesterday]),4,2)
        day_data=strmid(file_basename(fy_list[index_today_yesterday]),6,2)
        fy_julday=julday(month_data,day_data,year_data)

        hour_data=hour_data+8

        yesterday_hour_pos=where(hour_data gt 23)
        hour_data[yesterday_hour_pos]=hour_data[yesterday_hour_pos]-24

        date_data=long(date_data)
        fy_julday[yesterday_hour_pos]=fy_julday[yesterday_hour_pos]+1


        for zd_i=0,zd_num-1 do begin;对8个站点分别赋值
          fy_data=read_tiff(fy_list[index_today_yesterday[index_i]], geotiff=geo_info)
          resolution_n=geo_info.(0)
          resolution=resolution_n[0]
          start_data=geo_info.(1)
          start_lon=start_data[3]
          start_lat=start_data[4]
          ;输入待定点坐标
          zuobiao=[lat_data[zd_i],lon_data[zd_i]]
          lon=zuobiao[0]
          lat=zuobiao[1]
          ;输出得到的行列数
          row=(lon-start_lon)/resolution
          column=(start_lat-lat)/resolution

          if long(hour_data[index_i]) eq ii and fy_julday[index_i] eq jul_day then begin
            fy_zd_info[zd_i,date_i,ii]=fy_data[row,column]
          endif
        endfor
      endfor
    endfor


    ;    for ct_i=0,zd_num-1 do begin
    ;      plot2 = PLOT(fy_zd_info[ct_i,date_i,*], "r4D-", TITLE="FY_LST")
    ;
    ;      ww=string(output_zd_num2)
    ;      plot2.save,output_zhexiantu_dir+'\FY4A\'+ww.Compress()+'.png',/border ;/border表示自动裁除散点图外的多余白边
    ;      plot2.close
    ;      output_zd_num2=output_zd_num2+1
    ;      print,output_zd_num2
    ;    endfor
  endfor
  ;print,fy_zd_info
  fy_zd_info=fy_zd_info-273.15
  FY_reduce_ZD=fy_zd_info-zd_csv_info
  
  zd_mean=make_array(24)
  fy_mean=make_array(24)
     
      for hour=0,24-1 do begin
        ZD_mean[hour]=mean(zd_csv_info[*,*,hour],/nan)
        fy_mean[hour]=mean(fy_zd_info[*,*,hour],/nan)
      endfor 
  FY_reduce_ZD=fy_mean-zd_mean
  
  ;-------------将各日期所有站点的数据输出------------

;      fy_temp=REFORM(fy_zd_info[*,csv_date_i,*])
;      zd_temp=REFORM(zd_csv_info[*,csv_date_i,*])
      write_csv,output_zhexiantu_dir+'/CSV/FY/'+'fy_tem_MEAN'+'.csv',fy_mean
      write_csv,output_zhexiantu_dir+'/CSV/ZD/'+'zd_tem_MEAN'+'.csv',zd_mean




  ;-------------------出折线图---------------
    x_title='Time(h)'
    y_title='Temperature(°C)'

        plot3 = PLOT(fy_reduce_zd,xrange=[0,24],symbol='Star',color='green',SYM_FILLED=1,xtitle=x_title,ytitle=y_title,thick=3,name='Temperature Deviation', TITLE="LST")
        plot3_2=PLOT(fy_mean, symbol='Star',color='red',SYM_FILLED=1,thick=3,name='FY4A Product Temperature',/overplot);FY
        plot3_3=PLOT(zd_mean,symbol='Star', color='blue',SYM_FILLED=1,thick=3,name='Station Temperature',/overplot);站点
        mylegend=legend(target=[plot3,plot3_2,plot3_3],/RELATIVE,POSITION=[0.6,0.88],font_size=8,font_name='Times')
        ww=string(output_zd_num3)
        plot3.save,output_zhexiantu_dir+'所有站点均值'+'.png',/border
        plot3.close
        output_zd_num3=output_zd_num3+1
        print,output_zd_num3

  

  csv_info=make_array(zd_num,9);10个指标
  yangben_num=make_array(zd_num)
  ;-------------出散点图-------------------
  std_x=[250,320]
  std_y=[250,320]
  x_title='Station LST(K)'
  y_title='FY4A LST(K)'
  for zd_i=0,zd_num-1 do begin

    temp_fy=fy_mean
    temp_zd=zd_mean
    effective_pos=where(temp_fy gt 0)
    temp_fy=temp_fy[effective_pos]+273.15
    temp_zd=temp_zd[effective_pos]+273.15
    r=correlate(temp_zd,temp_fy)
    myplot=scatterplot(temp_zd,temp_fy,xrange=[250,320],yrange=[250,320],symbol='o',xtitle=x_title,ytitle=y_title,sym_size=0.4,SYM_FILL_COLOR='BLACK',SYM_FILLED=1)
    sdt_lineplot4=plot(std_x,std_y,thick=1,color='black',name="Y=X",font_name='Times',/overplot);font_name为设置字体格式（整幅图）
    fit_line=linfit(temp_zd,temp_fy)
    fit_x=[250,320]
    fit_y=fit_line[1]*fit_x+fit_line[0]
    sdt_lineplot2=plot(fit_x,fit_y,/overplot,thick=3,color='blue',linestyle=2,name='Y='+string(fit_line[1],format='(F0.3)')$
      +'X'+'+'+string(fit_line[0],format='(F0.3)')+', R='+string(r,format='(F0.3)'))
    mylegend2=legend(target=[sdt_lineplot2,sdt_lineplot4],/RELATIVE,POSITION=[0.98,0.18],font_size=12,font_name='Times')
    myplot.save,output_sandiantu_dir+zd_data[zd_i]+'.png',/border ;/border表示自动裁除散点图外的多余白边
    myplot.close

    n1=n_elements(temp_zd)
    yangben_num[zd_i]=n1
    ;-----------进行指标计算------
    ;平均误差
    aver_sg=total(temp_fy-temp_zd)/n1
    csv_info[zd_i,0]=aver_sg
    print,'平均误差：'+ string(aver_sg)
    ;绝对平均误差
    abs_average_sg=total(abs(temp_fy-temp_zd))/n1
    csv_info[zd_i,1]=abs_average_sg
    print, '绝对平均误差：'+string(abs_average_sg)

    ;平均相对误差
    ;k=n_elements(temp_zd)
    relative_sg=total((temp_fy-temp_zd)/temp_zd)/n_elements(temp_zd)*100
    csv_info[zd_i,2]=relative_sg
    print,'平均相对误差：'+string(relative_sg)
    ;绝对平均相对误差
    abs_relative_sg=total(abs(temp_fy-temp_zd)/temp_zd)/n_elements(temp_zd)*100
    csv_info[zd_i,3]=abs_relative_sg
    print,'绝对平均相对误差：'+string(abs_relative_sg)
    ;均方根误差
    rmse_sg=sqrt(total((temp_fy-temp_zd)^2)/float(n1))
    csv_info[zd_i,4]=rmse_sg
    print, '均方根误差:'+string(rmse_sg)
    ;相关系数
    r_sg=correlate(temp_fy,temp_zd)
    csv_info[zd_i,5]=r_sg
    print,'相关系数'+string(r_sg)
    ;方差
    var_sg=variance(temp_fy)
    csv_info[zd_i,6]=var_sg
    print,'方差：'+string(var_sg)
    ;标准差
    std_sg=stddev(temp_fy)
    csv_info[zd_i,7]=std_sg
    print,'标准差：'+string(std_sg)
    ;协方差
    cor_sg=CORRELATE(temp_fy,temp_zd,/COVARIANCE)
    csv_info[zd_i,8]=cor_sg
    print,'协方差：'+string(cor_sg)
    print,'---------------------------'

  endfor
  write_csv,output_csv_dir+'站点指标.csv',csv_info
  ;write_csv,output_csv_dir+'站点样本个数.csv',yangben_num

end