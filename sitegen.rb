require 'erubi'
require 'dotenv/load' unless ENV["CI"]
require 'twitter'
require 'nokogiri'

require 'open-uri'
require 'net/http'

url = "https://www.fireweatheravalanche.org/wildfire/incident/155594/new-mexico/luna-fire?fbclid=IwAR0GP3NzRT1iLwvhucMHhKUz3xBrtySKYdIS9h5DL1MFcpIX5NlawRP9Cwo-fire"
uri = URI.parse(url)
response = Net::HTTP.get_response(uri).body
response= Nokogiri::HTML(response)
@acreage = response.css(".facts .fact")[1].css(".highlight").text

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

  @feed_items = tweets_to_feature.map do |tweet|
    client.oembed(tweet.id).html
  end
else
  @feed_items = []
end

src = File.read('index.html.erb')
final = eval(Erubi::Engine.new(src).src)

File.write("dist/index.html", final)
