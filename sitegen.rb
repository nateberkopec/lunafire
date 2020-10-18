require 'erubi'
require 'dotenv/load'
require 'twitter'

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["CONSUMER_API_KEY"]
  config.consumer_secret     = ENV["CONSUMER_SECRET"]
  config.access_token        = ENV["ACCESS_TOKEN"]
  config.access_token_secret = ENV["ACCESS_TOKEN_SECRET"]
end

unless ENV["NO_UPDATE_FEED"]
  trusted_accounts = %w[
    NWSAlbuquerque jesse_proctor Bewickwren SWCCNewsNotes RioFernandoFD CarsonNF
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

File.write("index.html", final)
