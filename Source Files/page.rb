
require 'rubygems'
require 'koala'
require 'date'
require 'time'
require 'json'

require 'data_mapper'
require 'dm-migrations'
require 'dm-serializer'
DataMapper.setup(:default, 'sqlite::memory:')

SELECTED_INSIGHTS = [
  "insights/page_consumptions/day",
  "insights/page_views_login/day",
  "insights/page_fans/lifetime",
  "insights/page_impressions/day",
  "insights/page_storytellers/day",
  "insights/page_fan_adds/day",
  "insights/page_impressions_unique/day"
#"insights/page_admin_num_posts/day",
#"insights/page_story_adds_unique/day",
#"insights/page_fans/lifetime"


]

class PageInsight
  include DataMapper::Resource

  property :id,                      String
  property :page_id,                 String, :key => true
  property :end_time,                String, :key => true

  SELECTED_INSIGHTS.each do |i|
    puts i.split("/")[1].to_sym
    property i.split("/")[1].to_sym, Integer
  end
end



class String
  def to_ascii_iconv
    converter = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8')
    converter.iconv(self).unpack('U*').select{ |cp| cp < 127 }.pack('U*')
  end
end

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
@config = JSON.parse(File.read(File.expand_path(File.join(File.dirname(__FILE__), "input.json"))))
@api = Koala::Facebook::API.new(@config["token"])

start_date = Date.strptime(@config['start_date'], '%m-%d-%Y')
end_date = Date.strptime(@config['end_date'], '%m-%d-%Y')+1


pages = []
SELECTED_INSIGHTS.each { |insight_page|
  @config['users'].each do |user|
    puts "#{user}---------------------"
    (start_date..end_date).each_slice(90){|s|
      puts s.first
      puts s.last
      (pages << @api.get_connections("#{user}", insight_page, {
            :since=> Time.parse(s.first.to_s).to_i,
            :until=> Time.parse(s.last.to_s).to_i,
            :limit=>0}))rescue puts "soemething went wrong above"
      sleep 3
    }
  end
}

DataMapper.finalize
DataMapper.auto_migrate!

pages.each do |report_collection|
  selected_reports = report_collection.find_all do |report|
    SELECTED_INSIGHTS.include? report["id"].gsub(/^\d+\//,'')
  end

  selected_reports.each do |report|
    ids = report["id"].split("/")

    report["values"].each do |data_point|

      record = PageInsight.first_or_create(
        :end_time => data_point["end_time"],
        :page_id => ids[0]
      )
      record.update(ids[-2].to_sym => data_point["value"].to_i)
    end
  end
end

puts PageInsight.all.to_csv

f = File.open(File.expand_path('.\page.csv',@config["save_path"]),'w')
f.puts PageInsight.all.to_csv


