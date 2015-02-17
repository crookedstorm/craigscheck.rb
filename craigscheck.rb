#!/usr/bin/env ruby

=begin
This is a short program to check Craigslist for whatever we are looking
for at the moment.  This should help us not miss deals while avoiding
the annoyance of having to surf through it.
=end

require 'erb'
include ERB::Util
require 'mechanize'
require 'yaml'

# Read our config
cfgset = begin
	YAML.load(File.open("craigschecker.yml"))
rescue ArgumentError => e
	puts "Could not find YAML file: #{e.message}"
end
# create the url from the config and run the search
baseurl = "http://#{cfgset[:region]}.craigslist.com"
patternuri = url_encode("#{cfgset[:pattern]}").gsub('%20',"+")
searcher = Mechanize.new{ |fakeagent|
fakeagent.user_agent_alias = 'Linux Firefox'}
cfgset[:sections].each do |i|
	craigsl_url = "#{baseurl}/search/#{i}/?query=#{patternuri}&minAsk=#{cfgset[:price][0]}&maxAsk=#{cfgset[:price][1]}"
	# access the page and parse the output
	searcher.get(craigsl_url) do |page|
		page.search("//p[@class='row']").each do |row|
			link = row.search('a')[0]
			link_href= /^http/ =~ link['href'] ? link['href'] : baseurl + link['href'] # For out of area, you need this 
    		link_text = row.search('a')[1].text  
    		city = row.search("small").text  
    		price = row.search("span[@class='price']")[0].text unless row.search("span[@class='price']")[0].nil? # nil values work poorly here
			price ||= "no price"
    		puts <<EOT
#{price} -- #{city} -- #{link_text} 
#{link_href}\n 
EOT
  		end  
	end  
end

