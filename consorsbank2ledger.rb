#!/usr/bin/env ruby
# coding: utf-8
require 'pdf/reader'
require 'date'
require 'ibanizator'
fulltext = ""

$account_instrument_sell = "Einnahmen:Wertpapierverkaeufe"
$account_instrument_buy = "Ausgaben:Wertpapierkaeufe"
$account_prefix ="Besitzposten:Privatvermoegen:Umlaufvermoegen:LiquideMittel:Consorsbank:"

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

def entries2ledger(entries,statement_data)
  def format_ledger(entrydata,statement_data)
    pp entrydata
    print "#{entrydata[:date].strftime("%Y/%m/%d")}=#{entrydata[:valuta].strftime("%Y/%m/%d")} "
    puts entrydata[:ledgerline]
    puts "    #{$account_prefix}#{statement_data[:iban]}\t#{entrydata[:value].to_s.gsub('.',',')} #{statement_data[:currency]}"
    puts "    #{entrydata[:toaccount]}"
    entrydata.each do |key,value|
      puts "      ; #{key}: #{value}"
    end
  end

# identified types    
# DAUERAUFTRAG
# EFFEKTEN
# EURO-UEBERW.
# KAPST1 GUTS.
# SOLZ 1
# SOLZ 1 GUTS.
# ZINS/DIVID.
  entries.each do |entry|
    entrydata={}
#    pp entry
    entry_type=entry.first.scan(/^.*?  /).first[..-3].sub(/ NR\..*/,"").to_s
    entrydata.merge!(entrytype: entry_type)
    case entry_type
    when "EFFEKTEN"
      if result=/EFFEKTEN NR\.(\d+) +(\d\d\.\d\d)\. +(\d+) +(\d\d\.\d\d)\. +([\w\.\,]+)([+-])/.match(entry[0])
        entrydata.merge!(effektennr: result[1])
        entrydata.merge!(date: Date.strptime(result[2],'%d.%m'))
        entrydata.merge!(pnnnr: result[3])
        entrydata.merge!(valuta: Date.strptime(result[4],'%d.%m'))
        value = result[5].to_s.gsub('.', '').gsub(',','.').to_f
        if result[6] == '-'
          value=value*-1
        end
        entrydata.merge!(value: value)
        if result=/WP-ABRECHNUNG (\d+)/.match(entry[1])
          entrydata.merge!(wpabrechnung: result[1])
        end
        if result=/ +(\w+) +WKN: (\w{6})/.match(entry[2])
          entrydata.merge!(buysell: result[1])
          entrydata.merge!(wkn: result[2])
        end
        if result=/ +(.+)/.match(entry[3])
          entrydata.merge!(instrument: result[1])
        end
        entrydata.merge!(ledgerline: "#{entrydata[:buysell]} #{entrydata[:instrument]}")
        if entrydata[:buysell] == "Verkauf"
          entrydata.merge!(toaccount: $account_instrument_sell)
        elsif entrydata[:buysell] == "Kauf"
          entrydata.merge!(toaccount: $account_instrument_buy)
        end
      else
        puts "ERROR: could not parse '#entry[0]'"
        exit
      end
    else
      puts "ERROR: unknown entry_type '#{entry_type}'"
#      pp entry
      exit
    end
    format_ledger(entrydata,statement_data)
#    pp entrydata
  end
end

def parse_general_statement_data(fulltext)
  date=Date.new
  iban=nil
  currency=nil
#  pp fulltext
  fulltext.split(/\n/).each do |line|
    result=/Datum +([\d\.]+)/.match(line)
    if result
      date=Date.strptime((result[1]),'%d.%m.%y')
    end
    result=/IBAN +(.+)/.match(line)
    if result
      if Ibanizator.iban_from_string(result[1]).valid?
        iban=Ibanizator.iban_from_string(result[1])
      else
        puts "ERROR: Invalid IBAN found : '#{result[1]}'"
        exit
      end
    end
    result=/Kontowährung +(\w{3})/.match(line)
    if result
      currency=result[1]
    end
  end
  {date: date, iban: iban, currency: currency}
end

# MAIN

reader = PDF::Reader.new(ARGV.first)
reader.pages.each do |page|
  fulltext=fulltext+page.text
end

#puts fulltext

statement_data=parse_general_statement_data(fulltext)
#pp statement_data
entries=parsentries(fulltext)
entries2ledger(entries,statement_data)
