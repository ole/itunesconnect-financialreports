iTunesConnect to HTML
=====================

A Ruby script to convert the plain text Financial Reports Apple provides to
App Store developers in iTunes Connect to pretty HTML tables.

Works with Apple's current (as of June 2010) file format and the previous versions
(pre-Jun 2010 and pre-Feb 2009). Also works with new All Terrotories (Single File)
download (July 2018).


Usage
-----

itunesconnect2html.rb [options] file1 file2 ...
    -o, --overwrite                  Overwrite output files if they exist

fileX are the plain text files as downloaded from iTunes Connect.

Example: ./itunesconnect2html.rb reports/2009/08/*.txt
Result: The script will create a corresponding .html file for each .txt file
  in the same directory as the .txt files.


Configuration
-------------

itunesconnect2html_template.html.erb is the template used to format the data.
  You can customize this to your liking. All local variables from the script
  can be used in this file inside of <% %> and <%= %> blocks.

itunesconnect2html_settings.yaml can be used to exclude certain colums from
  the output or configure their format. The column headers from the .txt file
  form the keys. Options for each field include:
    exclude: true -- excludes this column from the output. Default is false.
    heading: ABC  -- sets the header for this column in the output to ABC.
      Default is the text from the input file.
    type: integer | date | currency -- formats output values as integers
      (right-justified), ISO date (YYYY-MM-DD) or currency (right-justified
      with 2 decimal places), respectively. All other columns are treated 
      as strings.
    total_amount_currency: true -- This is a special key that should be 
      included in the "Partner Share Currency" column config. It is used to 
      identify the currency of the Total Amount row.
  See the .yaml file for examples.


Credits and License
-------------------

Written by Ole Begemann, September 2009.
Copyright 2009-2010 Ole Begemann.
http://oleb.net/blog/2009/09/formatting-itunes-connect-financial-reports

License: You can do whatever you want with this. The author provides no 
warranty. If you publish this code or modifications of this code, a credit
to the original author is highly appreciated.
