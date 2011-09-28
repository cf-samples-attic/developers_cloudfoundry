require 'rubygems'
require 'sinatra'
require 'json'

enable :sessions

configure do
  
end

before do
  @title = "Sample App"
  
end

get '/' do
  haml :index
end


