#
#
# Script cobbled together from
# 
# http://stackoverflow.com/questions/862173/how-to-download-a-file-using-python-in-a-smarter-way
#
# and
#
# Dive Into Python 5.4
#
# Scrapes all the JP2 files from LMSAL webspace and writes them to local subdirectories
#
# TODO: check for files already downloaded so we don't download them twice.
# Solution: check for a text db file, if JP2 file is not in the list, download it, and update list.  should be simple
#
#

from os.path import basename
from urlparse import urlsplit
import shutil
import urllib2
import urllib
from sgmllib import SGMLParser
import os, time

class URLLister(SGMLParser):
	def reset(self):
		SGMLParser.reset(self)
		self.urls = []

	def start_a(self, attrs):
		href = [v for k, v in attrs if k=='href']
		if href:
			self.urls.extend(href)

def change2hv(z):
	os.system('chmod -R 775 ' + z)
	os.system('chown -R ireland:helioviewer ' + z)



def download(url, fileName=None, storage=None):
    def getFileName(url,openUrl):
        if 'Content-Disposition' in openUrl.info():
            # If the response has Content-Disposition, try to get filename from it
            cd = dict(map(
                lambda x: x.strip().split('=') if '=' in x else (x.strip(),''),
                openUrl.info().split(';')))
            if 'filename' in cd:
                filename = cd['filename'].strip("\"'")
                if filename: return filename
        # if no filename was found above, parse it out of the final URL.
        return basename(urlsplit(openUrl.url)[2])

    r = urllib2.urlopen(urllib2.Request(url))
    try:
        fileName = fileName or getFileName(url,r)
        fileName = storage + fileName
        with open(fileName, 'wb') as f:
            shutil.copyfileobj(r,f)
    finally:
        r.close()
    change2hv(fileName)

#download('http://sdowww.lmsal.com/sdomedia/hv_jp2kwrite/v0.8/jp2/AIA/94/2010/06/18/2010_06_18__00_00_20_135__SDO_AIA_AIA_94.jp2')

# Local root - presumed to be created
local_root = '/home/ireland/JP2Gen_from_LMSAL/v0.8/'

# The location of where the data will be stored
local_storage = local_root + 'jp2/AIA'
try:
	os.makedirs(local_storage)
	change2hv(local_storage)
except:
	print 'Directory already exists'

# The location of where the databases are stored
dbloc = local_root + 'db/AIA/'
try:
	os.makedirs(dbloc)
	change2hv(local_storage)
except:
	print 'Directory already exists'


# root of where the data is
remote_root = "http://sdowww.lmsal.com/sdomedia/hv_jp2kwrite/v0.8/jp2/AIA"

# wavelength array - constant
wavelength = ['94','131','171','193','211','304','335','1600','1700','4500']

# repeat starts here
while 1:

	# get today's date in UT

	yyyy = time.strftime('%Y',time.gmtime())
	mm = time.strftime('%m',time.gmtime())
	dd = time.strftime('%d',time.gmtime())
	
        #yyyy = '2010'
	#mm = '06'
	#dd = '23'

	Today = yyyy + '/' + mm + '/' + dd

        # go through each wavelength
	for wave in wavelength:
		# create the local JP2 subdirectory required
		local_keep = local_storage + '/' + wave + '/' + Today + '/'
		try:
			os.makedirs(local_keep)
			change2hv(local_storage)
			change2hv(local_storage + '/' + wave)
			change2hv(local_storage + '/' + wave + '/' + yyyy)
			change2hv(local_storage + '/' + wave + '/' + yyyy + '/' + mm)
			change2hv(local_storage + '/' + wave + '/' + yyyy + '/' + mm + '/' + dd)
		except:
			print 'Directory already exists: '+ local_keep

		# create the database subdirectory for this wavelength
		dbSubdir = dbloc + '/' + wave + '/' + Today
		try:
	      		os.makedirs(dbSubdir)
		except:
			print 'Directory already exists: '+ dbSubdir

		# create the database filename
		dbFileName = yyyy + '_' + mm + '_' + dd + '__AIA__' + wave + '__db.csv'    

		# read in the database file for this wavelength and today.
		try:
			file = open(dbSubdir + '/' + dbFileName,'r')
			jp2list = file.readlines()
			print 'Read database file '+ dbSubdir + '/' + dbFileName
		except:
			file = open(dbSubdir + '/' + dbFileName,'w')
			jp2list = ['This file first created '+time.ctime()+'\n\n']
			file.write(jp2list[0])
			print 'Created database file '+ dbSubdir + '/' + dbFileName
		finally:
			file.close()

		# calculate the remote directory
		remote_location = remote_root + '/' + wave + '/' + Today + '/'

		# open the remote location and get the file list
		usock = urllib.urlopen(remote_location)
		parser = URLLister()
		parser.feed(usock.read())
		usock.close()
		parser.close()
		# check which files are new

		for url in parser.urls:
			if url.endswith('.jp2'):
				if not url + ',\n' in jp2list:
					print 'reading ' + remote_location + url
					download(remote_location + url, storage = local_keep)
					# update database file with new files
					jp2list.extend(url + ',\n')
				else:
					print 'File already transferred ' + url
		print 'Writing updated ' + dbSubdir + '/' + dbFileName
		file = open(dbSubdir + '/' + dbFileName,'w')
		file.writelines(jp2list)
		file.close()
