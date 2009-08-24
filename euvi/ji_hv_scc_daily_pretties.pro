PRO JI_HV_SCC_DAILY_PRETTIES,yyyymmdd,cam0,sc0, PNG_ONLY=png_only, nopop=nopop, imlist=imlist, $
    	    	minus30=minus30, USE_DOUBLE=use_double, histars=histars, SOURCE=source, ANAGLYPH=ANAGLYPH, DOALL=DOALL, _EXTRA=_extra
;
;+
; $Id: scc_daily_pretties.pro,v 1.30 2009/06/24 18:18:21 mcnutt Exp $
;
; Project   : STEREO SECCHI
;                   
; Name      : SCC_DAILY_PRETTIES
;               
; Purpose   : This procedure converts raw SECCHI images into "pretty" images. This routine is not
;             for everyone! People should generally use SECCHI prep for this. The intention for this 
;             routine is that it will run daily to generate a full set of 'pretty" pictures ready for
;             the web, etc.
;               
; Explanation: 
;               
; Use       : IDL> scc_daily_pretties,'YYYYMMDD','CAM','SC'
;    
; Inputs    :CAM0 = cor1, cor2, hi1, hi2, euvi
;            SC0 = 'A', 'B'
;            YYYYMMDD = date to be processed
;               
; Outputs   : JPG24 and PNG files in /net/earth/data3/secchi/images
;
; Keywords  :
;   	    /USE_DOUBLE     Use type DOUBLE images for cor2 
;   	    /PNG_ONLY Skip jpegs.
;           /NOPOP -- Don't pop up a "preview' window for each image
;	    imlist=imlist string array of images to be done
;   	    SOURCE='lz','pb' or 'rt' ; default is lz
;   	    /doall creates daily prettie for all fits file not just the missing pretties
;   	    /minus30 = changes do date to date-30 days 
;   	    /hi_stars = create hi star daily pretties.
;
; Calls from LASCO :  gif2jpeg24
;
; Common    : 
;               
; Restrictions: Need appropriate permissions to write images to disk
;               
; Side effects: 
;               
; Category    : DAILY
;               
; Prev. Hist. : None.
;
; Written     : Karl Battams, NRL/I2, MAR 2007
;               
; $Log: scc_daily_pretties.pro,v $
; Revision 1.30  2009/06/24 18:18:21  mcnutt
; sets cam_str for histars before file check and sets doall to 1 if minus30 keyword_set
;
; Revision 1.29  2009/06/12 13:32:01  secchia
; corrected final print statment if all images had allready been created
;
; Revision 1.28  2009/06/12 12:39:30  mcnutt
; added skipping variale to set yloc for scc_mkimage
;
; Revision 1.27  2009/06/12 12:20:20  mcnutt
; if daily pretty exists it will be skipped unless keyword_Set DOALL
;
; Revision 1.26  2009/05/06 20:14:21  secchib
; use SOURCE= to define what pipeline to use
;
; Revision 1.25  2009/05/06 19:12:33  nathan
; use $SECCHI for finding FITS files, not $secchi
;
; Revision 1.24  2009/04/06 21:52:44  nathan
; left in stub for /anaglyph option
;
; Revision 1.23  2009/03/30 11:50:13  mcnutt
; changed size for 256 times
;
; Revision 1.22  2009/03/24 12:12:34  mcnutt
; remove images from summary which are from the previous day
;
; Revision 1.21  2008/11/03 16:44:16  mcnutt
; removed test directory
;
; Revision 1.20  2008/11/03 16:27:33  mcnutt
; change keyword hienhance to histars to default to enhanced images
;
; Revision 1.19  2008/11/03 15:36:12  mcnutt
; added histars keyword will only write png files for enhanced hi images
;
; Revision 1.18  2008/09/25 15:45:00  nathan
; Added /USE_DOUBLE; times=3 for using scc_add_datetime; do wdel AFTER for-loop
;
; Revision 1.17  2008/09/15 20:20:11  secchia
; nr -removed /verbose from mk_image call
;
; Revision 1.16  2008/04/28 13:16:58  mcnutt
; added minus30 keyword to redo daily pretties for cor2 and HIs
;
; Revision 1.15  2008/03/31 20:08:21  nathan
; took /nologo out of mk_image call (behavior actually unchanged because /nologo had not been implemented in scc_mk_image)
;
; Revision 1.14  2008/02/27 16:42:51  mcnutt
; defines ftimes and send to scc_mk_image
;
; Revision 1.13  2008/02/15 11:44:20  mcnutt
; added startind and yloc to work with scc_mk_image as a wrapper to scc_mkframe
;
; Revision 1.12  2008/01/30 15:08:41  secchia
; nr - do not redefine inputs
;
; Revision 1.11  2008/01/23 17:44:16  secchib
; added imlist keyword
;
; Revision 1.10  2008/01/16 21:34:56  secchib
; nr - skip to next file if not found
;
; Revision 1.9  2008/01/14 19:40:57  nathan
; put timestamp on small images (bug 276)
;
; Revision 1.8  2007/11/14 14:42:05  reduce
; Add nopop k/w to stop popup windows, if desired. Karl.
;
; Revision 1.7  2007/11/13 16:05:52  nathan
; print destination filename
;
; Revision 1.6  2007/10/26 22:17:45  nathan
; added /PNG_ONLY and -p to mkdir
;
; Revision 1.5  2007/10/18 19:54:15  nathan
; fixed some more returns with cd back to orig
;
; Revision 1.4  2007/09/28 18:26:13  reduce
; EUVI bug fix. Karl
;
; Revision 1.3  2007/09/24 18:11:09  reduce
; Various changes made. Calls scc_mk_image now. Works nicely for Cor2(a). Karl
;
; Revision 1.2  2007/04/16 21:52:52  nathan
; swap secchi_prep args; rearrange summary query
;
; Revision 1.1  2007/03/28 19:12:21  reduce
; Initial Release -- Karl B
;
;-

; ****************************************************************************************************************************
; ****************************************************************************************************************************
; ******************************** FIRST WE DO ALL THE PREP AND GENERATE A FILE LIST... **************************************
; ****************************************************************************************************************************
; ****************************************************************************************************************************

stime=systime(1)

date=yyyymmdd ;date get changed of minus30 keyword set

IF ~keyword_set(imlist) then begin

; initial setup
IF (datatype(date) NE 'STR') THEN BEGIN
    PRINT,'Input date must be a string E.G. 20061223'
    RETURN
ENDIF

if getenv('SECCHI_PNG') EQ '' THEN BEGIN
    PRINT,''
    PRINT,'ERROR!! $SECCHI_PNG environment variable is not set!'
    PRINT,''
    return
endif

if getenv('SECCHI_JPG') EQ '' THEN BEGIN
    PRINT,''
    PRINT,'ERROR!! $SECCHI_JPG environment variable is not set!'
    PRINT,''
    return
endif

IF keyword_set(SOURCE) THEN src=strlowcase(source) ELSE src='lz'

cam=strlowcase(cam0)
sc=strcompress(strlowcase(sc0),/remove_all)

use_p0=0
tdir='img'
cor_flag=0 
CASE cam OF
    'cor1':  BEGIN
        s=getenv('secchi')+'/'+src+'/L0/'+sc+'/seq/cor1/'
        cor_flag=0
        cam_str='cor1'
        tdir='seq'
;        PRINT,'Pretty picture processing is not yet implemented for COR1. Sorry...'
;        RETURN
    END
    'cor2':  BEGIN
        IF keyword_set(USE_DOUBLE) THEN BEGIN
	    s=getenv('secchi')+'/'+src+'/L0/'+sc+'/img/cor2/' 
	ENDIF ELSE BEGIN 
	    s=GETENV('SECCHI_P0')+'/'+sc+'/cor2/'
	    tdir='pol'
	    use_p0=1
	ENDELSE   
        cor_flag=1 
        cam_str='cor'
        loadct,1
    END
    'hi1':  BEGIN
        s=getenv('secchi')+'/'+src+'/L0/'+sc+'/img/hi_1/'
        cam_str='hi'
        loadct,3
    END
    'hi2':  BEGIN
        s=getenv('secchi')+'/'+src+'/L0/'+sc+'/img/hi_2/'
        cam_str='hi'
        loadct,1
    END
    'euvi':  BEGIN
        s=getenv('secchi')+'/'+src+'/L0/'+sc+'/img/euvi/'
        cam_str='euvi' 
    END
    ELSE:  BEGIN
        PRINT,'Unrecognized telescope code: '+cam
        RETURN
    END
ENDCASE

; Check files exist
PRINT,''
PRINT,'###### SEACHING FOR DATA... ######'
PRINT,''
CD,s,curr=orig
f=file_search(date+'/*fts')
sz=size(f)
IF (sz(0) EQ 0)  THEN BEGIN
    PRINT,''
    PRINT,'No directory for '+cam+' telescope on '+date
    PRINT,'Did you use the correct date format? (YYYYMMDD)'
    PRINT,''
    CD,orig
    RETURN
ENDIF

; change date to date-30
if keyword_set(minus30)then begin
   ut30=anytim2utc(date)
   ut30.mjd=ut30.mjd-30
   date=utc2yymmdd(ut30,/yyyy)
   doall=1
endif

; Use this date format for scc_read_summary
dt2=strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6,2)

; generate file list
PRINT,''
PRINT,'###### READING SUMMARY FILE... ######'
PRINT,''
summary=scc_read_summary(DATE=dt2,SPACECRAFT=sc,TELESCOPE=cam,TOTALB=use_p0, TYPE=tdir, SOURCE=source, _EXTRA=_extra) 

IF datatype(summary) NE 'INT' THEN BEGIN  ;remove images form previous day with date obs on current day. (needed for EUVIB (2008-01-08 - 2008-01-25)
   dates=long(strmid(summary.filename,0,8))
   dodate=long(strmid(dt2,0,4)+strmid(dt2,5,2)+strmid(dt2,8,2))
   tdo=where(dates eq dodate)
   summary=summary(tdo)
ENDIF

PRINT,'Found a total of ',strcompress(n_elements(summary)),' files for the day.'

IF datatype(summary) EQ 'INT' THEN BEGIN
    CD,orig
    RETURN
ENDIF

; summary file query
PRINT,''
PRINT,'###### COMPILING FILE LIST... ######'
PRINT,''
IF (cam EQ 'euvi') THEN good = where(summary.DEST EQ 'SSR1' and (summary.compr EQ 'ICER5' or summary.compr EQ 'ICER6' or summary.compr EQ 'ICER4') and summary.XSIZE GE 1024) ELSE $
IF ((cam EQ 'hi1') OR (cam EQ 'hi2')) THEN good = where(summary.DEST EQ 'SSR1' and summary.XSIZE EQ 1024 and summary.YSIZE EQ 1024) ELSE $
    	    	    	good = where(summary.VALUE EQ 1001 and summary.XSIZE GE 1024 and summary.YSIZE GE 1024 and summary.PROG NE 'Dark')
IF (cam EQ 'cor1') THEN good = where(summary.DEST EQ 'SSR1' and summary.osnum EQ 1476 and summary.value EQ 0)

if n_elements(good) EQ 1 then begin
    print,'ERROR: Could not find any/enough good images for the day...'
    cd,orig
    return
endif else files=summary[good].FILENAME 

n=n_elements(files)
PRINT,'Found a total of ',strcompress(n),' appropriate files for the day.'          
path=s+date+'/'
CD,path
;stop
datedir=date

endif ;end if ~keyword_set(imlist)

; ****************************************************************************************************************************
; ****************************************************************************************************************************
; ******************************* HERE'S WHERE WE ACTUALLY MAKE THE PRETTY IMAGES... ****************************************
; ****************************************************************************************************************************
; ****************************************************************************************************************************
if keyword_set(imlist) then files=imlist
n=n_elements(files)
first = 1
types=['jpg','png']

if (strmid(files[0],strlen(files[0])-1,1) NE 's') then files=files+'s'

;set for mkframe
startind = 0 ;
ftimes=strarr(n)
skipping=0

FOR i=0,n-1 DO BEGIN
print,i
yloc=i
  if keyword_set(files) then begin
    cam=strlowcase(strmid(files(i),strpos(files(i),'.')-3,2))
    sc=strlowcase(strmid(files(i),strpos(files(i),'.')-1,1))
    slashes=strsplit(files(i),'/')
    datedir=strmid(files(i),slashes(n_elements(slashes)-1),8)
    if i gt 0 then if(strmid(files(i),0,slashes(n_elements(slashes)-1)) ne imgdir) then first=1 else first=first+1
    imgdir=strmid(files(i),0,slashes(n_elements(slashes)-1))
    outfilen=strmid(files(i),slashes(n_elements(slashes)-1),strlen(files(i))-slashes(n_elements(slashes)-1)) 
    CASE cam OF
      'c1':  BEGIN
        cor1_flag=1
        cam_str='cor1'
;        PRINT,'Pretty picture processing is not yet implemented for COR1. Sorry...'
;        RETURN
      END
      'c2':  BEGIN
        cor_flag=1 
        cam_str='cor'
        loadct,1
      END
      'h1':  BEGIN
        cor_flag=0 
        cam_str='hi'
        loadct,3
      END
      'h2':  BEGIN
        cor_flag=0 
        cam_str='hi'
        loadct,1
      END
      'eu':  BEGIN
        cor_flag=0
        cam_str='euvi' 
      END
      ELSE:  BEGIN
        PRINT,'Unrecognized telescope code: '+cam
        RETURN
      END
     ENDCASE
     if i gt 0 then if(strmid(files(i),0,strlen(files(i))-26) ne strmid(files(i-1),0,strlen(files(i-1))-26)) then first=1
   endif

    if keyword_set(histars) then cam_str=cam_str+'_stars'


   check=file_search(getenv('SECCHI_PNG') + '/' + sc + '/' + cam_str + '/' + datedir+'/512/'+strmid(outfilen,0,15)+'*')

   if skipping eq 1 then yloc=0
   if check(0) ne '' and ~keyword_set(doall) then skipping=1 else skipping=0
   if check(0) ne '' and ~keyword_set(doall) then goto, nextfile

   if first eq 1 then yloc=0
    
    ; Just print statement stuff...
    f1=strcompress(string(i+1),/remove_all)
    ff=strcompress(string(n),/remove_all)
    PRINT,''
    PRINT,'###### PROCESSING FILE ',f1,' OF ',ff,'... ######
    PRINT,''

    ;if not cor_flag then secchi_prep,files[i],hdr,im,outsize=1024,/color_on,/smask_on,/calimg_off,/rotate_on,/precommcorrect else begin
    ;    dat=sccreadfits(files[i],hdr)
    ;    im=scc_mk_image_cor(dat,hdr,/domask)
    ;endelse  
    
    IF keyword_set(ANAGLYPH) THEN BEGIN
    ; only make 1024x1024
    
	if cam_str NE 'euvi' then BEGIN
    	    message,'Anaglyphs for EUVI only; exitting.',/info
	    return
	ENDIF ELSE BEGIN
	    fileb=files(i)
	    strput,fileb,'B',strpos(files(i),'A')
            afile=sccfindfits(files(i))
	    bfile=sccfindfits(fileb)
	    if afile ne '' and bfile ne '' then begin
	    ; get A-B pair and call scc_stereopair.pro
	      im=scc_stereopair( afile, bfile ,/ANAGLYPH,/secchiprep,outsize=1024,smask_on=1,/automax)

              dummy = sccreadfits(afile, outhdr, /nodata)
    	      wave=outhdr.WAVELNTH
    	      wave=strmid(strcompress(wave,/remove_all),0,2)
   
    
        ; Compile and check the directory structure
           path = getenv('SECCHI_PNG') + '/anaglyph/' + cam_str +'/1024/' + datedir +'/'
            
        ; make the directories we want to use...
           ;if first then begin 
            if not file_exist(path) then begin
                PRINT,'Making directory...'
                cmd='mkdir -p '+path
                spawn,cmd
            endif
          ;endif
        
        ; now get filenames...
    	   if ~keyword_set(imlist) then outfilen=files[i]
    	   fn=strmid(trim(outfilen),0,16)+wave+'AB.png'
	
    	   outfile=path+fn
    	   write_png,outfile,im
        ENDIF  
      ENDELSE

    ENDIF ELSE BEGIN
    im=scc_mk_image(files[i],yloc,startind,ftimes,outsize=1024,/nodatetime,outhdr=outhdr,nopop=nopop,/full,histars=histars,_EXTRA=_extra) 
    
    IF im[0] LT 0 THEN goto, nextfile
    
    PRINT,''
    PRINT,'###### REFORMATTING IMAGE DATA... ######
    PRINT,''
    

        im256=rebin(im,256,256)
	im256=scc_add_datetime(im256,outhdr,color=255, /ADDCAM,MVI=1)

        im=scc_add_datetime(im,outhdr,color=255, /ADDCAM,MVI=3)
        im512=rebin(im,512,512)

    ; get color table
    tvlct,r,g,b,/get
    
    if keyword_set(histars) then png_only=1
      
    IF keyword_set(PNG_ONLY) THEN pngonly=1 ELSE BEGIN
    	pngonly=0
	; make jpeg24 images
	GIF2JPG24,im,r,g,b,jpgimg
	GIF2JPG24,im512,r,g,b,jpgimg512
	GIF2JPG24,im256,r,g,b,jpgimg256
    ENDELSE
    
    if cam_str EQ 'euvi' then BEGIN
            wave=outhdr.WAVELNTH
            wave=strmid(strcompress(wave,/remove_all),0,2)
    endif else wave='tb'
        ;stop
   
    FOR k=pngonly,1 DO BEGIN ; we'll loop twice; once for jpeg, once for png
    
        ; Compile and check the directory structure
        if k EQ 0 then path = getenv('SECCHI_JPG') + '/' + sc + '/' + cam_str + '/' + datedir else $
            path = getenv('SECCHI_PNG') + '/' + sc + '/' + cam_str + '/' + datedir
            
        ; make the directories we want to use...
        if first then begin 
            if not file_exist(path) then begin
                PRINT,'Making directories...'
                cmd='mkdir -p '+path
                spawn,cmd
                cmd='mkdir -p '+path+'/256'
                spawn,cmd
                cmd='mkdir -p '+path+'/512'
                spawn,cmd
                cmd='mkdir -p '+path+'/1024'
                spawn,cmd
            endif
        endif
        
        ; now get filenames...
       if ~keyword_set(imlist) then outfilen=files[i]
       if cor_flag then fn=strmid(strcompress(outfilen,/remove_all),0,16)+wave+strmid(strcompress(outfilen,/remove_all),19,4)+types[k] else $
            fn=strmid(strcompress(outfilen,/remove_all),0,16)+wave+strmid(strcompress(outfilen,/remove_all),18,4)+types[k]
	
;stop        
        if k EQ 0 THEN BEGIN ; DO JPEGS
            PRINT,''
            PRINT,'###### WRITING JPEGs... ######
            PRINT,path,'/*/',fn
            outfile=path+'/256/'+fn
            WRITE_JPEG, outfile,jpgimg256,TRUE=3
            outfile=path+'/512/'+fn
            WRITE_JPEG, outfile,jpgimg512,TRUE=3
            outfile=path+'/1024/'+fn
            WRITE_JPEG, outfile,jpgimg,TRUE=3
        ENDIF ELSE BEGIN  ; DO PNGS
            PRINT,''
            PRINT,'###### WRITING PNGs... ######
            PRINT,path,'/*/',fn
            outfile=path+'/256/'+fn
            write_png,outfile,im256,r,g,b
            outfile=path+'/512/'+fn
            write_png,outfile,im512,r,g,b
            outfile=path+'/1024/'+fn
            write_png,outfile,im,r,g,b
        ENDELSE

    ENDFOR  ; end the 'k' loop
    ENDELSE ; NOT anaglyph
    first=0 ; don't need to mkdir's any more
    nextfile:

ENDFOR

    wdel, /ALL	    ; DELETES ALL OPEN WINDOWS!!! (including pixmaps)

if ~keyword_set(imlist)then cd,orig

ftime=systime(1)
tot_time=strcompress(string((ftime-stime)/60),/remove_all)
if datatype(ff) ne 'UND' then begin
  PRINT,''
  PRINT,'#########################################################
  PRINT,'TOTAL PROCESSING TIME FOR ',ff,' FILES: ',tot_time,' MINS.'
  PRINT,'#########################################################
  PRINT,''
ENDIF ELSE begin
  PRINT,''
  PRINT,'#####################################################################################
  PRINT,'ALL FILES EXIST TO REDO DAILY PRETTIES CALL SCC_DAILY_PRETTIES WITH KEYWORD /DOALL'
  PRINT,'#####################################################################################
  PRINT,''
ENDELSE

END
