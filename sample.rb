require 'rubygems'
require 'sinatra'
require 'json'
require 'vmc/client'
require 'rack-flash'


require_relative 'lib/app'
require_relative 'lib/cf_mongoid'

include CloudFoundry

enable :sessions
use Rack::Flash

configure do
  @@target = "api.cloudfoundry.com"
  CloudFoundry::Mongo.config
end

before do

  # Example of how to only allow https
  #unless (ENV['bypass_ssl'] && request.secure?)
  #  halt 401, 'This website can only be accessed over SSL'
  #end

  @title = "Gallery"
  @canonical_url = request.url
  @fb_app_id = ENV['facebook_app_id']

  if (session[:auth_token] && !session[:email])
    @vmcclient = VMC::Client.new(@@target, session[:auth_token])
    begin
      if (info = @vmcclient.info)
        session[:email] = info['user']
      end
    rescue
      session.delete :auth_token
    end
  end
end

post '/login' do
  email = params[:email]
  password = params[:password]

  if (email && password)
    @vmcclient = VMC::Client.new(@@target)
    begin
      @vmcclient.login(email, password)
      session[:auth_token] = @vmcclient.auth_token
      session[:email] = email
    rescue Exception => ex
      flash[:error] =  "Login Failed"
    end
  else
    flash[:error] = "Fill out the form"
  end
  redirect '/'
end

get '/logout' do
  session.delete :auth_token
  session.delete :email
  redirect '/'
end

get '/' do
  #TODO: Get from mongo db
  @links = {}
  @links['Ruby'] = {:display_name => "Ruby Box.net", :url => "/apps/boxnet-ruby"}
  @links['Spring'] = {:display_name => "Spring Box.net", :url => "/apps/boxnet-spring"}

  haml :index

end

post '/apps/:app_name/new_copy' do |app_name|
  @app_name = app_name
  build_app if app_name ==  "boxnet-ruby"
end

get '/apps/:app_name/new_copy' do |app_name|
  @app_name = app_name
  build_app if app_name ==  "boxnet-ruby"
end

def build_app
  # Find the app if its browsable
  @app = App.new
  @app.display_name = "Box.net Ruby Sample"
  @app.app_urls = ["rub-sam.cloudfoundry.com"]
  @title = @app.display_name
  @app.description = "A starter Box.net application which showcases accessing files and folders as well as sharing."
  @thumb_url = "http://veederline.com.au/wp-content/uploads/2011/07/digital_pub_box_net.jpg"
  # Avatar, name, description

  # GitHub Location
  @app.git_repo =  "https://github.com/ciberch/sinatra-cloudfoundry-basic-website"
  @zip_url = "#{@app.git_repo}/zipball/master"

  parts =  @app.app_urls.first.split('.')
  @new_name = parts[0] + rand(9999).to_i.to_s
  if session[:email]
    @new_name = parts[0] + session[:email].gsub('@', '.')
  end
  #services

  #env vars
  @env_vars = {}
  @env_vars['Box API Key'] = "wewewewkejnweh34823u4b3r3jhb45k43j5lk45mt34knmt5k34ltml3453l4"

  haml :new_copy
end

post '/apps/boxnet-ruby/do_copy' do

end





