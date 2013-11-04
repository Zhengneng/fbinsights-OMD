
require 'rubygems'
require 'koala'
require 'date'
require 'time'
require 'json'

class String
  def to_ascii_iconv
    converter = Iconv.new('ASCII//IGNORE//TRANSLIT', 'UTF-8')
    converter.iconv(self).unpack('U*').select{ |cp| cp < 127 }.pack('U*')
  end
end


OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

#TOKEN = 'AAACEdEose0cBALeHQFROM0m3gtcmJDjGX8ncbBYLZCjEXm3EZB8kfG45LIcxNBgOvya18oxttefWunRogRlXyjUuOvZCEdLAc43ZBQUC51peNpyPVkZBg'

#@api = Koala::Facebook::API.new(TOKEN)
#@config = JSON.parse(File.read(File.expand_path(File.join(File.dirname(__FILE__), "in3.json"))))

@config = JSON.parse(File.read(File.expand_path(File.join(File.dirname(__FILE__), "input.json"))))
@api = Koala::Facebook::API.new(@config["token"])


@api_counter = 0

def api_wait
  @api_counter += 1
  puts "api call # #{@api_counter}"
  sleep 1

  if @api_counter == 60
    sleep 5
    @api_counter = 0
  end
end

#start_date = Time.parse((Date.strptime(@config['start_date'], '%m-%d-%Y')).to_s).to_i
#end_date = Time.parse((Date.strptime(@config['end_date'], '%m-%d-%Y')+1).to_s).to_i
start_date = Date.strptime(@config['start_date'], '%m-%d-%Y')
end_date = Date.strptime(@config['end_date'], '%m-%d-%Y')
#puts Time.parse(start_date.to_s).to_i
#puts Time.parse(end_date.to_s).to_i
#throw :done
#property_id(s) created_date(s) created_time(s) message(s)  type(pg)  caption(pg) description(pg) name(pg)  link(pg)  picture comments(s) likes(s)  impressions(s)  feedback (calc) shares (n/a)
output = []
output << ['property_id',
  'created_date',
  'created_time',
  'message',
  'type',
  'caption',
  'description',
  'name',
  'link',
  'picture',
  'comments',
  'likes',
  'impressions',
  'unique_impressions',
  'stories',
  'storytellers',
  'shares']

#@config['users'] = ["8655621413"]
#@config['users'] = ["5943153747"]
#property_id(s) created_date(s) created_time(s) message(s)  type(pg)  caption(pg) description(pg) name(pg)  link(pg)  picture comments(s) likes(s)  impressions(s)  feedback (calc) shares (n/a)

since = Time.parse(start_date.to_s)
posts = []
@config['users'].each do |user|
  #puts
  puts "------#{user}-->"
  #sleep 5
  data = @api.get_connections(user,"posts",{
      :until=> Time.parse((end_date+1).to_s).to_i,
      :limit=>0}
  )
  api_wait
  #sleep 3
  posts.concat(data)#10150569729933357
  while Time.parse(data[-1]['created_time'])>since #and since > Time.parse(data[-1]['created_time']) #Time.parse(post['created_time'])
    #puts  "loop"
    #puts "#{Time.parse(data[0]['created_time'])}>#{since}"
  #  puts  "--------------------"
    #puts JSON.pretty_generate(data[0])
    #puts  "xxxxxxxxxxxxxxxxxxxxxxx"
    #puts data
    #puts data.next_page_params.inspect
    data = data.next_page
    break if data.empty?
    api_wait
    #puts data.inspect
    #puts posts.class
    #puts data.class
    posts.concat(data)
  end
end

#throw :eeee

puts posts.size
posts.each_with_index do |post, index|
  #puts post
  #puts index
  #puts 'loop2'
  #print "[#{index}]"
  #$stdout.flush
  row = []
  #puts Time.parse(post['created_time'])
  row << post["id"]

  row_date = Time.parse(post['created_time'])
  next if row_date < since
  puts "[#{index}]   #{row_date}"
  
  row << row_date.strftime("%Y-%m-%d")
  row << row_date.strftime("%H:%M:%S")
#puts (post["message"] || post["story"]).to_ascii_iconv rescue nil
  row << ((post["message"] || post["story"]).to_ascii_iconv rescue nil)
  #puts row
  row << (post["type"]rescue nil)
    if row[-1] == "question"
      row[-1] = "poll"
      votes = 0
      poll = @api.get_object(post["object_id"])
      api_wait
      poll["options"]["data"].each do|question|
        votes += question["votes"].to_i
      end
      post["comments"]["count"] = votes.to_s
    end
    if row[-1] == "photo"
      #puts post
    end
  row << (post["caption"]rescue nil)
  row << (post["description"]rescue nil)
  row << (post["name"]rescue nil)
  row << (post["link"]rescue nil)
  row << (post["picture"]rescue nil)
  row <<  (post["comments"]["count"]rescue nil)
  row <<  (post["likes"]["count"]rescue nil)
  row << (@api.get_object("#{post["id"]}/insights/post_impressions/lifetime")[0]["values"][0]["value"] rescue nil)
api_wait
  row << (@api.get_object("#{post["id"]}/insights/post_impressions_unique/lifetime")[0]["values"][0]["value"] rescue nil)
api_wait
  row << (@api.get_object("#{post["id"]}/insights/post_stories/lifetime")[0]["values"][0]["value"] rescue nil)
api_wait
row << (@api.get_object("#{post["id"]}/insights/post_storytellers/lifetime")[0]["values"][0]["value"] rescue nil)
  api_wait
  row <<  (post["shares"]["count"] rescue nil)
  #puts row
  output << row
  #puts row
end
#puts output

#
#
#
#(start_date..end_date).each_slice(10) do |period|
#  @config['users'].each do |user|
#    puts
#    puts "start:#{period[0]} end:#{period[-1]} for: #{user}-->"
#    sleep 5
#    posts = @api.get_connections(user,"posts",{
#        :since=> Time.parse(period[0].to_s).to_i,
#        :until=> Time.parse((period[-1]+1).to_s).to_i,
#        :limit=>0}
#    )
#    posts.each_with_index do |post, index|
#      sleep 1
#      print "[#{index}]"
#      $stdout.flush
#      row = []
#      #puts Time.parse(post['created_time'])
#      row << post["id"]
#
#      row_date = Time.parse(post['created_time'])
#
#      row << row_date.strftime("%Y-%m-%d")
#      row << row_date.strftime("%H:%M:%S")
#
#      row << ((post["message"] || post["story"]).to_ascii_iconv rescue nil)
#      #puts row
#      row << (post["type"]rescue nil)
#        if row[-1] == "question"
#          row[-1] = "poll"
#          votes = 0
#          poll = @api.get_object(post["object_id"])
#          poll["options"]["data"].each do|question|
#            votes += question["votes"].to_i
#          end
#          post["comments"]["count"] = votes.to_s
#        end
#        if row[-1] == "photo"
#          #puts post
#        end
#      row << (post["caption"]rescue nil)
#      row << (post["description"]rescue nil)
#      row << (post["name"]rescue nil)
#      row << (post["link"]rescue nil)
#      row << (post["picture"]rescue nil)
#      row <<  (post["comments"]["count"]rescue nil)
#      row <<  (post["likes"]["count"]rescue nil)
#      row << (@api.get_object("#{post["id"]}/insights/post_impressions/lifetime")[0]["values"][0]["value"] rescue nil)
#      row <<  (post["shares"]["count"] rescue nil)
#      #puts row
#      output << row
#    end
#  end
#end
#puts output
f = File.open(File.expand_path('.\output.html',@config["save_path"]),'w')
f.write('<table>')
output.each{|line|
  #puts line
  f.write('<tr>')
  line.each{|cell|
    f.write('<td>')
    f.write(cell)
    f.write('</td>')
  }
  f.write('</tr>')
}
f.write('</table>')
f.close
