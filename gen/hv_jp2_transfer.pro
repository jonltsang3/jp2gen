;
; Program to transfer files from the outgoing directory to a remote
; location.  The program first forms a list of the subdirectories and
; files, moves those files to the remote location, and then deletes
; those files from the outgoing directory.
;
;
PRO HV_JP2_TRANSFER,nickname,trasnfer_details = transfer_details
  progname = 'hv_jp2_transfer'
;
  if NOT(KEYWORD_SET(transfer_details)) THEN BEGIN
     transfer_details = ' -e ssh -l ireland@delphi.nascom.nasa.gov:/var/www/jp2/v0.8/inc/test_transfer/'
  endif 
;
  storage = HV_STORAGE(nickname = nickname)
;
; Get a list of the JP2 files and their subdirectories in the outgoing directory
;
  sdir = storage.outgoing
  a = file_list(find_all_dir(sdir),'*.jp2')

  if not(isarray(a)) then begin
     print,'No files to transfer'
  endif else begin
     n = n_elements(a)
     b = a
     for i = 0, n-1 do begin
        b[i] = strmid(a[i],strlen(sdir),strlen(a[i])-strlen(sdir)) 
     endfor
;
; Connect to the remote machine and transfer files plus their structure
;
     cd,sdir,current = old_dir
;
; Open connection to the remote machine and start transferring
;
     for i = 0, n-1 do begin
        spawn,'rsync -Ravxz --exclude "*.DS_Store" ' + $
              b[i] + ' ' + $
              transfer_details
     endfor
;
; Remove files from the outgoing that have been transferred
;
     for i = 0, n-1 do begin
        spawn,'rm -f ' + b[i]
     endfor
     cd,old_dir

  endelse

  return
end
