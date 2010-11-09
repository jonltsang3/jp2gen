;
; Write the HVS file for a LASCO C2 image
;
; 2009-05-26.  Added error log file for data files with bad header information
;
;
FUNCTION HV_LAS_C2_WRITE_HVS2,dir,ld,details = details
  progname = 'HV_LAS_C2_WRITE_HVS2'
;
  observatory = details.observatory
  instrument = details.instrument
  detector = details.detector
  measurement = details.details[0].measurement
;
  observation =  observatory + '_' + instrument + '_' + detector + '_' + measurement
;
; get general information
;
  ginfo = CALL_FUNCTION('hvs_gen')
;
; Proceed if input is a structure with a 2d image in it
;
  ld_ok = 0
  IF is_struct(ld) then begin
     nd = n_elements(size(ld.cimg,/dim))
     if nd eq 2 then begin
        ld_ok = 1
     ENDIF
  ENDIF

  if (ld_ok eq 1) then begin
     cimg = ld.cimg
     hd = ld.header
;
; Apply the gamma correction
;
     IF HV_USING_QUICKLOOK_PROCESSING(details.called_by) THEN BEGIN
        cimg = max(cimg)*(cimg/max(cimg))^details.ql_gamma_correction
     ENDIF ELSE BEGIN
        cimg = max(cimg)*(cimg/max(cimg))^details.gamma_correction
     ENDELSE
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
     milli = strmid(time_obs,9,3)
     obs_time = yy + '_' + mm + '_' + dd + '_' + hh + mmm + ss + '.' + milli
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
;     alpha_mask = 1.0 + 0.0*image_new  ; transparency mask: 0 =
;     transparent, 1 = not transparent
;
; Quicklook files seem to be have the SOHO roll included in them, so
; no need to take care of the rotation
;
     using_quicklook = HV_USING_QUICKLOOK_PROCESSING(details.called_by)
     if using_quicklook then begin
;        answer = HV_LASCO_HANDLE_QUICKLOOK(image_new,hd,sunc)
;        rotate_by_this = 0.0
;        rotate_by_this = get_soho_roll(date_obs + ' ' + time_obs)
;        imtemp = image_new
;        image_new = 0.0*image_new
;        image_new = rot(imtemp,rotate_by_this, 1, sunc.xcen,sunc.ycen,/pivot)
;        image_new = rotate(imtemp,2)
;        aa = sunc.xcen - sz[0]/2.0 ; difference between array centre and sun centre
;        bb = sunc.ycen - sz[1]/2.0 ; difference between array centre and sun centre
;        sunc.xcen = sz[0]/2.0 - aa ; sun centre appears to be in a different place
;        sunc.ycen = sz[1]/2.0 - bb ; 
;        hd.crpix1 = sunc.xcen
;        hd.crpix2 = sunc.ycen
;        print,progname + ': quicklook FITS files.'
        aa = sunc.xcen - sz[0]/2.0 ; difference between array centre and sun centre
        bb = sunc.ycen - sz[1]/2.0 ; difference between array centre and sun centre
        sunc.xcen = sz[0]/2.0 - aa ; sun centre appears to be in a different place
        sunc.ycen = sz[1]/2.0 - bb ; 
        ;hd.crpix1 = sunc.xcen
        ;hd.crpix2 = sunc.ycen
        rotate_by_this = get_soho_roll(hd.date_obs + ' ' + hd.time_obs)
        if (abs(rotate_by_this) ge 170.0) then begin
           image_new = rotate(image_new,2)
        endif
     endif else begin
        rotate_by_this = hd.crota1
        print,progname + ': using archived FITS files.'
     endelse
;
; block out the inner occulting disk
;
     xim = sz(0)/2.0
     yim = sz(1)/2.0

     a = xim - sunc.xcen
     b = yim - sunc.ycen
;     if (abs(hd.crota1) ge 170.0) then begin
     if (abs(rotate_by_this) ge 170.0) then begin
        image_new = circle_mask(image_new, xim+a, yim+b, 'LT', r_occ*r_sun, mask=0)
;        alpha_mask = circle_mask(alpha_mask, xim+a, yim+b, 'LT', r_occ*r_sun, mask=0)
     endif else begin
        image_new = circle_mask(image_new, xim-a, yim-b, 'LT', r_occ*r_sun, mask=0)
;        alpha_mask = circle_mask(alpha_mask, xim-a, yim-b, 'LT', r_occ*r_sun, mask=0)
     endelse
;
; remove the outer corner areas which have no data
;
;     if (abs(hd.crota1) ge 170.0) then begin
     if (abs(rotate_by_this) ge 170.0) then begin
        image_new = circle_mask(image_new, xim+a, yim+b, 'GT', r_occ_out*r_sun, mask=0)
;        alpha_mask = circle_mask(alpha_mask, xim+a, yim+b, 'GT', r_occ_out*r_sun, mask=0)
     endif else begin
        image_new = circle_mask(image_new, xim-a, yim-b, 'GT', r_occ_out*r_sun, mask=0)
;        alpha_mask = circle_mask(alpha_mask, xim-a, yim-b, 'GT', r_occ_out*r_sun, mask=0)
     endelse  
;
; add the tag_name 'R_SUN' to the header information
;
     hd = add_tag(hd,observatory,'hv_observatory')
     hd = add_tag(hd,instrument,'hv_instrument')
     hd = add_tag(hd,detector,'hv_detector')
     hd = add_tag(hd,measurement,'hv_measurement')
     hd = add_tag(hd,rotate_by_this,'hv_rotation')
     hd = add_tag(hd,r_occ,'hv_rocc_inner')
     hd = add_tag(hd,r_occ_out,'hv_rocc_outer')
     hd = add_tag(hd,progname,'hv_source_program') 
;
; Active Helioviewer tags have a "hva_" tag, change the nature of the
; final output, and are not stored in the final JP2 file
;
;     hd = add_tag(hd,alpha_mask,'hva_alpha_transparency')

;
; Old tags
;
;     hd = add_tag(hd,'wavelength','hv_measurement_type')
;     hd = add_tag(hd,yy + '-' + mm + '-' + dd + 'T' + hd.time_obs + 'Z','hv_date_obs')
;     hd = add_tag(hd,2,'hv_opacity_group')
;     hd = add_tag(hd,r_sun,'hv_original_rsun')
;     hd = add_tag(hd,hd.cdelt1,'hv_original_cdelt1')
;     hd = add_tag(hd,hd.cdelt2,'hv_original_cdelt2')
;     hd = add_tag(hd,hd.crpix1,'hv_original_crpix1')
;     hd = add_tag(hd,hd.crpix2,'hv_original_crpix2')
;     hd = add_tag(hd,hd.naxis1,'hv_original_naxis1')
;     hd = add_tag(hd,hd.naxis2,'hv_original_naxis2')
;;      hd = add_tag(hd,1,'hv_centering')

;
; check the tags to make sure we have sufficient information to
; actually write a JP2 file
;
     err_hd = intarr(4)
     err_report = ''
     if (hd.cdelt1 le 0.0) then begin
        err_hd[0] = 1
        err_report = err_report + 'original CDELT1 &lt;=0, replacing with a default value to enable continued processing:'
        hd.cdelt1 = 11.4
     endif
     if (hd.cdelt2 le 0.0) then begin
        err_hd[1] = 1
        err_report = err_report + 'original CDELT1 &lt;=0, replacing with a default value to enable continued processing:'
        hd.cdelt2 = 11.4
     endif
     if (hd.crpix1 le 0.0) then begin
        err_hd[2] = 1
        err_report = err_report + 'original CRPIX1 &lt;=0, replacing with a default value to enable continued processing:'
        hd.crpix1 = 512.0
     endif
     if (hd.crpix2 le 0.0) then begin
        err_hd[3] = 1
        err_report = err_report + 'original CRPIX2 &lt;=0, replacing with a default value to enable continued processing:'
        hd.crpix2 = 512.0
     endif
;
; Write the JP2
;
     if total(err_hd gt 0) then begin
        hd = add_tag(hd,'Warning ' + err_report,'hv_error_report')
        log_comment = log_comment + ' : ' + err_report
     endif else begin
        err_report = ''
     endelse
;
; Detect if this is a quicklook file
;
     if have_tag(details,'local_quicklook') then begin
        qlyn = strpos(dir,details.local_quicklook)
        if qlyn ne -1 then begin
           hd = add_tag(hd,'TRUE','HV_QUICKLOOK')
           print,progname + ': using quicklook data.'
        endif
     endif else begin
        print,progname + ': no local quicklook tag detected in details structure.  Assuming data arises from non-quicklook FITS files.'
     endelse
;
; HVS file
;
     hvsi = {dir:dir,$
             fitsname:hd.filename,$
             header:hd,$
             details: details,$
             comment:err_report,$
             measurement:measurement,$
             yy:yy,$
             mm:mm,$
             dd:dd,$
             hh:hh,$
             mmm:mmm,$
             ss:ss,$
             milli:milli}
     hvs = {img:image_new,hvsi:hvsi}

     HV_MAKE_JP2,hvs,jp2_filename = jp2_filename,already_written = already_written

;     HV_WRITE_LIST_JP2,hvs, jp2_filename = jp2_filename,already_written = already_written
;     if not(already_written) then begin
;        HV_LOG_WRITE,hvs.hvsi, log_comment + ' : wrote ' + jp2_filename
;     endif else begin
;        jp2_filename = ginfo.already_written
;     endelse
  endif else begin
     print,'Something funny with this LASCO C2 fits file'
     jp2_filename = ginfo.MinusOneString
  endelse
  return,jp2_filename
end