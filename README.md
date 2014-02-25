##CFA L3 Audiobooks

This is an R script that was used to convert a desktop windows application to an audiobook.  The application was a study guide for the CFA Level 3 curriculum.  It contained a video of someone talking about each topic and a window with a slideshow that would auto-advance along with the video.

Since it was difficult to spend so much time in front of a PC, I wanted to be able to watch the content on my phone/tablet and listen to it in the car or the gym.  I also wanted a printout of the slides to refresh and for taking notes.  This script extracted a set of audiobooks and pdfs.  The slides from the desktop application were inserted into the audiobook as chapter book covers -- so each time the audio would move to a new chapter, the slide would change in the audiobook.

I ended up creating this script that takes the following steps:

1. reads in the XML configuration file for the application

2. scans the XML for timestamped sections of the video and images that match

3. extracts the audio from the flash video files and saves them

4. creates a POD config file for the audiobook assembly

5. assembles an audiobook for each section, assigning a slide image to serve as the 'book cover' for each chapter

6. saves a PDF version of the slides that can be printed for note taking

Required:
- the R XML package
- slideshowassembler
- ffmpeg
- ImageMagick convert

###Note

This only works if you already own the content.  I no longer have the source files and the format of the application may have changed since this was created (2010 level 3 version).

