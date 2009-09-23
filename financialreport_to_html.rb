#!/usr/bin/env ruby -wKU

# financialreport_to_html.rb
# 
# Converts iTunes Connect Financial Reports (tab-separated text files) to HTML.
# Written by Ole Begemann, September 2009.
# http://oleb.net/blog/2009/09/formatting-itunes-connect-financial-reports
#
# License: you can do whatever you want with this. The author provides no warranty.


# Read settings from config file (YAML)
require 'yaml'
settings = YAML::load_file('financialreport_to_html_settings.yaml')
fields = []

# Parse command line options
require 'optparse'

# This hash will hold all of the options parsed from the command-line by OptionParser.
options = {}
optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top of the help screen.
  opts.banner = "Usage: financialreport_to_html.rb [options] file1 file2 ..."
  
  options[:overwrite] = false
  opts.on('-o', '--overwrite', 'Overwrite output files if they exist') do
    options[:overwrite] = true
  end
  
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

# Parse the command-line. Remember there are two forms of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

# Exit if no file names are given on the command line
if ARGV.empty?
  puts optparse.help
  exit
end

# Loop through all files and process them
ARGV.each do |input_filename|
  
  unless File.file?(input_filename)
    puts "Error: #{input_filename} is not a file or does not exist."
    next
  end
  
  File.open(input_filename, 'r') do |input_file|

    html = ""
    html << <<-EOF
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
    <html>
    <head>
      <meta http-equiv="Content-type" content="text/html;charset=UTF-8">
      <title>Apple Financial Report: #{File.basename(input_filename)}</title>
      <style type="text/css">
         body, table {
           font: 11pt Helvetica, Arial, sans-serif;
           width: 90%;
         }
         body {
           margin: 1em;
           padding: 0;
           color: black;
         }
         h1 {
           font-size: 130%;
         }
         table {
           border-collapse: collapse;
         }
         tr {
           border-bottom: 1px solid black;
         }
         th, td {
           padding: 0.1cm 0.2cm;
         }
         @page {
           margin: 5cm;
         }
      </style>
    </head>

    <body>
      <h1>Apple Financial Report: #{File.basename(input_filename)}</h1>
      <table>
        <thead>
        <tr>
    EOF

    # First line: headings
    fields = []
    first_line = input_file.gets
    field_names = first_line.split("\t")
    field_names.each do |field_name|
      # Attach config data to fields array in order of appearance in the file 
      # (or an empty hash if field is not listed or nil in config file)
      current_field = settings[field_name] || {}
      fields << current_field
      unless current_field['exclude']
        html << <<-EOF
            <th>#{current_field['heading'] || field_name}</th>
        EOF
      end
    end

    html << <<-EOF
        </tr>
        </thead>
        <tbody>
    EOF

    # Other lines: data
    partner_share_currency = ""
    while ((line = input_file.gets) !~ /^Total_Amount/)
      field_values = line.split("\t")
      html << <<-EOF
          <tr>
      EOF
      field_values.each_with_index do |field_value, index|
        current_field = fields[index]
        unless current_field['exclude']
          case current_field['type']
            when 'date'
              field_value = Date::parse(field_value, true).to_s
              field_style = "text-align: right; white-space: nowrap;"
            when 'integer'
              field_style = "text-align: right;"
            when 'currency'
              field_style = "text-align: right;"
              field_value = "%.2f" % field_value.to_f
          end
          html << <<-EOF
              <td style="#{field_style}">#{field_value}</td>
          EOF
          
          # Store partner share currency for later use in Total Amount line
          if current_field['total_amount_currency']
            partner_share_currency = field_value
          end
        end
      end
      html << <<-EOF
          </tr>
      EOF
    end

    html << <<-EOF
        </tbody>
      </table>
    EOF

    # Last line: Total amount
    total_amount = line.gsub(/Total_Amount:([-0-9.]+)/, '\1').to_f
    total_amount_output = "Total Amount: #{"%.2f" % total_amount} #{partner_share_currency}"
    html << <<-EOF
      <p style="font-weight: bold;">#{total_amount_output}</p>
    EOF

    html << <<-EOF
    </body>  
    EOF

    # Write HTML to output file
    output_filename = input_filename.chomp(File.extname(input_filename)) + ".html"
    if (!options[:overwrite] && File.exists?(output_filename))
      puts "Skipping #{output_filename}, file exists. Use --overwrite to override."
      next
    end
    output_file = File.new(output_filename, "w")
    output_file.puts html
    output_file.close

  end

end
