require 'erubi'
require 'dotenv/load' unless ENV["CI"]
require 'twitter'
require 'nokogiri'

require 'open-uri'
require 'net/http'

url = "https://inciweb.nwcg.gov/incident/7246"
uri = URI.parse(url)
response = Net::HTTP.get_response(uri).body
response= Nokogiri::HTML(response)
@acreage = response.css(".table-incident")[1].css("tr")[1].css("td").last.text.split(" ").first
@personnel = response.css(".table-incident")[1].css("tr")[0].css("td").last.text
@cause = response.css(".table-incident")[0].css("tr")[2].css("td").last.text


client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["CONSUMER_API_KEY"]
  config.consumer_secret     = ENV["CONSUMER_SECRET"]
  config.access_token        = ENV["ACCESS_TOKEN"]
  config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
end

unless ENV["NO_UPDATE_FEED"]
  trusted_accounts = %w[
    NWSAlbuquerque jesse_proctor Bewickwren SWCCNewsNotes RioFernandoFD CarsonNF taosnews
  ]

  tweets_to_feature = trusted_accounts.map do |acct| 
    client.search("from:#{acct} Luna OR #LunaFire").to_a
  end.flatten.sort_by(&:created_at).reverse

  @feed_items = tweets_to_feature.take(24).map do |tweet|
    client.oembed(tweet.id).html
  end

  featured_photos = [1318705945069846533, 1318708284979859456]
  @featured = featured_photos.map do |tweet|
    client.oembed(tweet).html
  end
else
  @feed_items = []
  @featured = []
end

src = File.read('index.html.erb')
final = eval(Erubi::Engine.new(src).src)

File.write("dist/index.html", final)
