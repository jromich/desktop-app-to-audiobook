################################################################################
# Create audiobooks from training videos.  Uses the config file timestamps
# to assign each powerpoint slide to be a 'book cover' per chapter.
#
# The end result is an audiobook that contains the audio from the movies and
# has slides from the application shown as the audiobook chapter book covers.
#
# This script requires the R XML package, slideshow assembler, ffmpeg, and
# convert from imagemagick
#
################################################################################


library(XML)

options(digits.secs=2)

kv <- function(key, value, filename){
  ## append a key value pair to a file
  cat(key,"=",value,"\n",sep="",file=filename, append=T)
}

k <- function(string, filename){
  ## append string to a file
  cat(string,"\n",sep="",file=filename, append=T)
}


writePOD <- function(audiofile, chapterDF, bookname, bookfile){
  ## creates an POD audiobook configuration file used by slideshowassembler

  if(file.exists(bookfile)) file.remove(bookfile)
  k("[Podcast]",bookfile)
  kv("altfolder1", ".", bookfile)
  kv("basename", bookname, bookfile)
  kv("audiofile", audiofile, bookfile)
  #kv("shownotes", ".", bookfile)
  kv("artwork", chapterDF$Image[1], bookfile)
  kv("imgwidth", 400, bookfile)
  kv("imgheight", 300, bookfile)
  kv("editpointcount", nrow(chapterDF), bookfile)

  for (i in 1:nrow(chapterDF)){
    k(paste("\n[Editpoint_",i,"]",sep=""), bookfile)
    kv("start", chapterDF$Start[i], bookfile)
    kv("chapter", chapterDF$ChapterName[i], bookfile)
    kv("image", chapterDF$Image[i], bookfile)
  }

  k("[metadata]", bookfile)
  kv("\n©nam", bookname, bookfile)
  kv("©ART", "Schweser CFA", bookfile)
  kv("©alb", "CFA L3 2010 Videos", bookfile)
  kv("©gen", "Podcast", bookfile)
}

# find all video files
setwd("d:/cfa videos")
filenames <- list.files(path=".",pattern="flv$",recursive=T)
xmlfiles <- paste(dirname(dirname(filenames)),"/commands.xml",sep="")

getName <- function(a){
  ## find segment name in xml file
  doc <- xmlInternalTreeParse(a, useInternalNodes = TRUE)
  root <- xmlRoot(doc)
  xmlAttrs(root)[["Name"]]
}

getChapterDF <- function(a){
  ## Extract data.frame from xml file and determine:
  ## - name of the chapter
  ## - start/stop timestamp of each slide
  ## - image name and path file for each slide

  doc <- xmlInternalTreeParse(a, useInternalNodes = TRUE)
  root <- xmlRoot(doc)
  nodes <- getNodeSet(doc, "//Slide")
  x <- data.frame(do.call(rbind, lapply(nodes, xmlAttrs)), stringsAsFactors=F)
  x <- x[!duplicated(x$SlideID),]

  imgName <- lapply(as.numeric(x$SlideID), function(slideid) {paste("slide",slideid+1,".jpg",sep="")})
  imgPath <- unlist(lapply(imgName, function(img) list.files(path=dirname(a),pattern=img,recursive=T, full.names=T)))
  x <- data.frame(Start=x$Time, Image=unlist(imgPath), stringsAsFactors=F)
  b <- readLines(paste(dirname(dirname(a)),"/config.xml",sep=""), warn=F)
  b <- gsub(" & "," and ", b)

  configdoc <- xmlInternalTreeParse(b, useInternalNodes = TRUE)
  configroot <- xmlRoot(configdoc)
  confignodes <- getNodeSet(configroot, "//String[@key='Label']")
  label <- unlist( lapply(confignodes, xmlValue))

  startTime <- strptime("1/1/01 0:00:00.000", "%d/%m/%y %H:%M:%OS")
  x$Start <- sapply(as.numeric(x$Start), function(tm) format(startTime + tm, "%H:%M:%OS"))
  x$ChapterName <- paste(1:nrow(x),label[1:nrow(x)],sep=" ")
  x
}

# get segment names and clean up
segmentNames <- sapply(xmlfiles, getName)
segmentNames <- gsub("Level 3 Class","CFA_L3-",segmentNames)
segmentNames <- gsub(" ([0-9])$"," 0\\1",segmentNames)
segmentNames <- gsub(" ([0-9]) "," 0\\1 ",segmentNames)
segmentNames <- gsub(" - Segment ","-",segmentNames)
segmentNames <- gsub(" ","",segmentNames)

# create names for the output audio files
titles <- paste("D:/cfa/schweseraudio2010/",segmentNames,".m4a",sep="")
rows <- 1:length(titles)
titles <- titles[rows]
filenames <- filenames[rows]

## create m4a files
for (i in 1:length(filenames)){
  cat("\n\n******** file:",titles[i],"*********\n\n")
  x <- paste("\"C:/Program Files/WinFF/ffmpeg.exe\" -i ", filenames[i]," -vn -acodec libfaac  -ab 48kb  -ac 2 -ar 44100  ", titles[i], sep="")
  system(x)
}

#titlesb <- gsub("m4a$","m4b",titles)
#for (i in 1:length(titles)) file.rename(titlesb[i],titles[i])
#titles <- titlesb

bookfiles <- paste(segmentNames,".POD",sep="")

# assemble audiobook files and pdfs
for (i in 1:length(filenames)){
  cat("\n\n******** file:",bookfiles[i],"*********\n\n")
  chapterDF <- getChapterDF(xmlfiles[i])
  writePOD(titles[i], chapterDF, segmentNames[i], bookfiles[i])
  x <- paste("\"C:/Program Files/Slideshow Assembler/SSA.exe\" ", bookfiles[i], sep="")
  system(x)
  file.remove(bookfiles[i])

  # print pdf version of slides
  x <- paste("C:/cygwin/bin/convert.exe -adjoin -density 100 ", paste(chapterDF$Image, collapse=" "), paste(segmentNames[i], ".pdf",sep=""), sep=" ")
  system(x)
}

# rename to m4b
filesto <- gsub("POD$","m4b",bookfiles)
filesfrom <- gsub("POD$","m4a",bookfiles)
for (i in 1:length(titles)) file.rename(filesfrom[i], filesto[i])




