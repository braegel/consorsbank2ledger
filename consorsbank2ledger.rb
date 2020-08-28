#!/usr/bin/env ruby
# coding: utf-8
require 'pdf/reader'
fulltext = ""

def parsentries(fulltext)
  entries = Array.new

  textarray=fulltext.split(/\n/)
#  pp textarray
  textarray.each_with_index do | line,index|
    if /^[A-Z].*[-\+]$/ =~ line
      entry = Array.new
      i=0
      while textarray[index+i] != "" || i<=2 do
        if textarray[index+i] != ""
          entry << textarray[index+i]
        end
        i=i+1
      end
      entries << entry
    end
  end
  entries
end

def entries2ledger(entries)
# identified types    
# DAUERAUFTRAG
# EFFEKTEN
# EURO-UEBERW.
# KAPST1 GUTS.
# SOLZ 1
# SOLZ 1 GUTS.
# ZINS/DIVID.
  entries.each do |entry|
#    pp entry
    entry_type=entry.first.scan(/^.*?  /).first[..-3].sub(/ NR\..*/,"").to_s
    case entry_type
    when "EFFEKTEN"
      pp entry
    else
      puts "ERROR: unknown entry_type '#{entry_type}'"
      pp entry
      exit
    end
  end
end

reader = PDF::Reader.new(ARGV.first)
reader.pages.each do |page|
  fulltext=fulltext+page.text
end

#puts fulltext

# TODO parseyear

entries=parsentries(fulltext)
entries2ledger(entries)
