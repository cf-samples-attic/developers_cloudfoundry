require 'rubygems'
require 'sinatra'
require 'json'

enable :sessions

configure do
  
end

before do
  @title = "Sample App"
  hash = JSON.parse ENV['VMC_APP_INSTANCE']
  @canonical_url = "http://#{hash['uris'].first}"
end

get '/' do
  haml :index
end


