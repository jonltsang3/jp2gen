;
; Write the HVS file for a LASCO C2 image
;
; 2009-05-26.  Added error log file for data files with bad header information
;
;
FUNCTION JI_LAS_C2_WRITE_HVS2,filename,rootdir,ld
;
;
;
  progname = 'JI_LAS_C2_WRITE_HVS2'
;
  oidm = ji_hv_oidm2('C2')
  observatory = oidm.observatory
  instrument = oidm.instrument
  detector = oidm.detector
  measurement = oidm.measurement
;
  observation =  observatory + '_' + instrument + '_' + detector + '_' + measurement
;
; Proceed if input is a structure
;
  if is_struct(ld) then begin
     cimg = ld.cimg
     hd = ld.header
;
; Get the components of the observation time
;
     date_obs = hd.date_obs
     yy = strmid(date_obs,0,4)
     mm = strmid(date_obs,5,2)
     dd = strmid(date_obs,8,2)

     time_obs = hd.time_obs
     hh = strmid(time_obs,0,2)
     mmm = strmid(time_obs,3,2)
     ss = strmid(time_obs,6,2)

     obs_time = yy + '_' + mm + '_' + dd + '_' + hh + mmm + ss
;
; shift the byte values so zero may be reserved for transparency
;
     minval=1.0
     maxval=255.0
     min_in = min(cimg,max = max_in)
     image_new = 0b * cimg
     image_new = byte( (cimg - min_in)/float(max_in-min_in)*(maxval-minval) + minval)
     loadct,3
     tvlct,r,g,b,/get
;
; remove the central coronagraph data and set it to zero so it is
; transparent
;
     sz = size(image_new,/dim)
     sunc = GET_SUN_CENTER(hd, /NOCHECK,full=sz(1))
     arcs = GET_SEC_PIXEL(hd, full=sz(1))
     yymmdd = UTC2YYMMDD(STR2UTC(date_obs + ' ' + time_obs))
     solar_ephem,yymmdd,radius=radius,/soho
     asolr = radius*3600
     r_sun = asolr/arcs
     r_occ = 2.3                ; C2 occulter inner radius in solar radii
     r_occ_out = 8.0            ; C2 occulter outer radius in solar radii
     alpha_mask = 1.0 + 0.0*image_new  ; transparency mask: 0 = transparent, 1 = not transparent
;
; block out the inner occulting disk
;
     xim = sz(0)/2.0
     yim = sz(1)/2.0

     a = xim - sunc.xcen
     b = yim - sunc.ycen
     if (abs(hd.crota1) ge 170.0) then begin
        image_new = circle_mask(image_new, xim+a, yim+b, 'LT', r_occ*r_sun, mask=0)
        alpha_mask = circle_mask(alpha_mask, xim+a, yim+b, 'LT', r_occ*r_sun, mask=0)
     endif else begin
        image_new = circle_mask(image_new, xim-a, yim-b, 'LT', r_occ*r_sun, mask=0)
        alpha_mask = circle_mask(alpha_mask, xim-a, yim-b, 'LT', r_occ*r_sun, mask=0)
     endelse
;
; remove the outer corner areas which have no data
;
     if (abs(hd.crota1) ge 170.0) then begin
        image_new = circle_mask(image_new, xim+a, yim+b, 'GT', r_occ_out*r_sun, mask=0)
        alpha_mask = circle_mask(alpha_mask, xim+a, yim+b, 'GT', r_occ_out*r_sun, mask=0)
     endif else begin
        image_new = circle_mask(image_new, xim-a, yim-b, 'GT', r_occ_out*r_sun, mask=0)
        alpha_mask = circle_mask(alpha_mask, xim-a, yim-b, 'GT', r_occ_out*r_sun, mask=0)
     endelse       
;
; add the tag_name 'R_SUN' to the header information
;
     hd = add_tag(hd,observatory,'hv_observatory')
     hd = add_tag(hd,instrument,'hv_instrument')
     hd = add_tag(hd,detector,'hv_detector')
     hd = add_tag(hd,measurement,'hv_measurement')
     hd = add_tag(hd,'wavelength','hv_measurement_type')
     hd = add_tag(hd,yy + '-' + mm + '-' + dd + 'T' + hd.time_obs + 'Z','hv_date_obs')
     hd = add_tag(hd,2,'hv_opacity_group')
;     hd = add_tag(hd,r_sun,'hv_original_rsun')
;     hd = add_tag(hd,hd.cdelt1,'hv_original_cdelt1')
;     hd = add_tag(hd,hd.cdelt2,'hv_original_cdelt2')
;     hd = add_tag(hd,hd.crpix1,'hv_original_crpix1')
;     hd = add_tag(hd,hd.crpix2,'hv_original_crpix2')
;     hd = add_tag(hd,hd.naxis1,'hv_original_naxis1')
;     hd = add_tag(hd,hd.naxis2,'hv_original_naxis2')
     hd = add_tag(hd,hd.crota1,'hv_crota1')
     hd = add_tag(hd,1,'hv_centering')
     hd = add_tag(hd,r_occ,'hv_rocc_inner')
     hd = add_tag(hd,r_occ_out,'hv_rocc_outer')
     hd = add_tag(hd,progname,'hv_source_program')
;
; Active Helioviewer tags have a "hva_" tag, change the nature of the
; final output, and are not stored in the final JP2 file
;
     hd = add_tag(hd,alpha_mask,'hva_alpha_transparency')
;
; check the tags to make sure we have sufficient information to
; actually write a JP2 file
;
     err_hd = intarr(4)
     err_report = ''
     if (hd.cdelt1 le 0.0) then begin
        err_hd[0] = 1
        err_report = err_report + 'original CDELT1 &lt;=0, replacing with a default value to enable continued processing:'
        hd.hv_original_cdelt1 = 11.4
     endif
     if (hd.cdelt2 le 0.0) then begin
        err_hd[1] = 1
        err_report = err_report + 'original CDELT1 &lt;=0, replacing with a default value to enable continued processing:'
        hd.hv_original_cdelt2 = 11.4
     endif
     if (hd.crpix1 le 0.0) then begin
        err_hd[2] = 1
        err_report = err_report + 'original CRPIX1 &lt;=0, replacing with a default value to enable continued processing:'
        hd.hv_original_crpix1 = 512.0
     endif
     if (hd.crpix2 le 0.0) then begin
        err_hd[3] = 1
        err_report = err_report + 'original CRPIX2 &lt;=0, replacing with a default value to enable continued processing:'
        hd.hv_original_crpix2 = 512.0
     endif
     if total(err_hd gt 0) then begin
        hd = add_tag(hd,'Warning ' + err_report,'hv_error_report')
     endif
;
; HVS file
;
     hvs = {img:image_new, red:r, green:g, blue:b, header:hd,$
            observatory:observatory,instrument:instrument,detector:detector,measurement:measurement,$
            yy:yy, mm:mm, dd:dd, hh:hh, mmm:mmm, ss:ss}
;
; Write an error file if required.
;
     if total(err_hd gt 0) then begin
        outfile = JI_HV_ERR_REPORT(err_report,filename, hvs = hvs,name = obs_time + '_' + observation)
     endif
;
; Write a JP2 or HVS file
;
        JI_WRITE_LIST_JP2,hvs,rootdir
        outfile = rootdir + obs_time + '_' + observation + '.hvs.jp2'
        print,progname + ': Writing to ' + outfile
  endif else begin
     outfile = JI_HV_ERR_REPORT('JP2 file not written due to problem with FITS file: ',filename,name = 'lasco_c2')
  endelse
  return,outfile
end