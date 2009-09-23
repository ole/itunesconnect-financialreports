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


# Setup ERB template. All local variables can be used in the template.
require 'erb'
template_filename = 'financialreport_to_html_template.html.erb'
unless File.file?(template_filename)
  puts "Error: ERB template #{template_filename} does not exist."
  exit
end
template_text = File.read(template_filename)
template = ERB.new(template_text, nil, '>')



# Loop through all files and process them
ARGV.each do |input_filename|
  
  unless File.file?(input_filename)
    puts "Error: #{input_filename} is not a file or does not exist."
    next
  end
  
  File.open(input_filename, 'r') do |input_file|

    page_title = "Apple Financial Report: #{File.basename(input_filename)}"

    # First line: headings
    column_headers = []
    fields = []
    first_line = input_file.gets
    field_names = first_line.split("\t")
    field_names.each do |field_name|
      field_name.strip!
      
      # Attach config data to fields array in order of appearance in the file 
      # (or an empty hash if field is not listed or nil in config file)
      current_field = settings[field_name] || {}
      fields << current_field
      
      # Store column headers
      column_headers << (current_field['heading'] || field_name) unless current_field['exclude']
    end

    # Other lines: data
    data_rows = []
    total_amount_currency = ""
    while (line = input_file.gets)
      # Skip if line is empty or contains only whitespace characters (such as a line of empty tabs)
      next if line =~ /^\s*$/
      
      # Detect Totals row at the bottom of the table.
      # Current format: Total_Amount:32.68
      # Old format (pre-Feb 2009): \t\t\t\t\t\tTotal\t32.68 AUD\t...
      break if (line =~ /^Total_Amount/) || (line =~ /^\s*Total\t/)
      
      # Else: we have a data row => start processing
      row = []
      field_values = line.split("\t")
      field_values.each_with_index do |field_value, index|
        field_value.strip!
        field_data = { :value => field_value }
        current_field = fields[index]
        unless current_field['exclude']
          # Modify field data according to current field settings
          case current_field['type']
            when 'date'
              field_data[:value] = Date::parse(field_value, true).to_s
              field_data[:style] = "text-align: right; white-space: nowrap;"
            when 'integer'
              field_data[:style] = "text-align: right;"
            when 'currency'
              field_data[:style] = "text-align: right;"
              field_data[:value] = "%.2f" % field_value.to_f
          end
          row << field_data
        end
        
        # Store partner share currency for later use in Total Amount line
        if current_field['total_amount_currency']
          total_amount_currency = field_value
        end
      end

      data_rows << row
    end

    # Last line: Total amount
    if line =~ /^Total_Amount/
      total_amount_str = line.gsub(/Total_Amount:([-0-9,.]+)/, '\1')
      total_amount_str.gsub!(",", "")
    elsif line =~ /^\s*Total\t/
      total_amount_str = line.gsub(/^\s*Total\s*([-0-9,.]+).*$/, '\1')
      total_amount_str.gsub!(",", "")
    end
    total_amount = total_amount_str.to_f
    
    # Write HTML to output file
    output_filename = input_filename.chomp(File.extname(input_filename)) + ".html"
    if (!options[:overwrite] && File.exists?(output_filename))
      puts "Skipping #{output_filename}, file exists. Use --overwrite to override."
      next
    end
    output_file = File.new(output_filename, "w")
    output_file.puts template.result(binding)
    output_file.close
  end

end
