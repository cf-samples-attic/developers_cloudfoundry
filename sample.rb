require 'rubygems'
require 'sinatra'
require 'json'
require 'vmc/client'
require 'rack-flash'

require_relative 'lib/CloudFoundry/mongoid'
require_relative 'lib/CloudFoundry/app_info'
require_relative 'lib/CloudFoundry/app'

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

  if (session[:auth_token] && @vmcclient.nil? )
    @vmcclient = VMC::Client.new(@@target, session[:auth_token])
    unless session[:email]
      begin
        if (info = @vmcclient.info)
          session[:email] = info['user']
        end
      rescue
        session.delete :auth_token
      end
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
  @links = {}
  #temp code
  @links['Ruby'] = {:display_name => "Ruby Box.net", :url => "/apps/box-rebuilt-ruby" }

  haml :index

end

get '/apps/:app_name/get_copy' do |app_name|
  @app_name = app_name

  @sample_app_info = nil
  #temp code
  if app_name ==  "box-rebuilt-ruby"
    @sample_app_info = boxapp
  end

  halt unless @sample_app_info

  @sample_app_info.env_vars.each do |k,v|
    @sample_app_info.env_vars[k] = params[k]
  end

  @title = @sample_app_info.display_name
  @thumb_url = "http://veederline.com.au/wp-content/uploads/2011/07/digital_pub_box_net.jpg"

  parts =  @sample_app_info.app_urls.first.split('.')
  @new_name = parts[0] + rand(9999).to_i.to_s

  if session[:email]
    a,b = session[:email].split '@'
    @new_name = parts[0] + "-#{@sample_app_info.git_commit}-" + a
  end
  #services

  haml :new_copy
end

post '/apps/:app_name/deploy' do |app_name|
  #temp code
  @sample_app_info = nil
  if app_name ==  "box-rebuilt-ruby"
    @sample_app_info = boxapp
  end

  if ( @sample_app_info && session[:email] && params[:new_name])
    #begin
      @app_info = @sample_app_info.clone
      @app_info.app_urls = []

      @app_info.display_name = params[:new_name]

      # Set all the env vars
      @app_info.env_vars.each do |var_name, val|
        @app_info.env_vars[var_name] = params[var_name]
      end

      app = CloudFoundry::App.new(@vmcclient, @app_info)
      app.create unless (app.exists?)
      app.copy_code
      app.start

      # give it a little time
      sleep 2

      redirect "http://#{@app_info.app_urls.first}"

    #rescue Exception => ex
    #  puts "Error #{ex} pushing app"
    #end
  else
    flash[:notice] ="Missing required fields"
    redirect "/apps/#{app_name}/new_copy"
  end
end

#temporary
def boxapp
  app = AppInfo.new({
    :display_name => "Box.net Ruby Sample",
    :app_urls => ["box-rebuilt.cloudfoundry.com"],
    :framework => 'sinatra',
    :description => "A starter Box.net application which showcases accessing files and folders as well as sharing.",
    :git_repo => "https://github.com/seanrose/box-rebuilt",
    :git_commit => "3e26a2f",
    :git_branch => 'master',
    :env_vars => {'BOX_API_KEY' => 'enter your key here'}
  })
end





