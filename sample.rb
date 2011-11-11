require 'rubygems'
require 'sinatra'
require 'json'
require 'cfmeta'

enable :sessions

configure do
  
end

before do
  @title = "Developers"
  @canonical_url = request.url
  @fb_app_id = ENV['facebook_app_id']
end

get '/' do
  haml :index
end


